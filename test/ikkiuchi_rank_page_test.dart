// 一騎打ち's rank change page after a ranked match (mock B): its timeline
// (the count eased over about 3 s, slow, fast, slow; its ticks thinned to
// a least spacing; the sounds in step with the motion), which page each
// recorded match gives, the pages after a match in order (the XP first,
// the rank page for a ranked match only), and that every moment fits the
// user's phone at text size 1 and 1.1, a narrow one and a tall one, in
// both languages, with the button clear of the navigation bar.
//
// With RENDER_SCREENS=1 it renders each moment's key frames to
// build/screens/ikkiuchi_rank/ (the end at 1.1 and on the tall phone too,
// English for the rank up and the first class), and the tick times of a
// +14 and a +62 count to build/screens/ikkiuchi_rank/ticks.txt.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_rating.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/ikkiuchi_records.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/debug/celebration_preview.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_rank_overlay.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_rank_timeline.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/results/celebration_chrome.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_card_pages.dart' show loadAppFonts;
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

class _HeardSounds extends Sounds {
  final played = <Sfx>[];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}

/// A rated match in [mode] from [before] by [gain] points, won when it
/// gains.
IkkiuchiRankChange _rated(double before, double gain, {IkkiuchiMode mode = IkkiuchiMode.bullet}) => IkkiuchiRankChange(
      mode: mode,
      result: gain > 0 ? IkkiuchiResult.won : IkkiuchiResult.lost,
      margin: 3,
      tobi: before,
      before: before,
      after: before + gain,
      curve: [before - 20, before - 8, before, before + gain],
    );

IkkiuchiRankTimeline _timeline(IkkiuchiRankChange change) => IkkiuchiRankTimeline(IkkiuchiRankCelebration(change));

/// The gaps between [ticks], in ms.
List<int> _gaps(List<Duration> ticks) => [for (var i = 1; i < ticks.length; i++) (ticks[i] - ticks[i - 1]).inMilliseconds];

/// Each moment's key frames, as mock B shows them: when, from the page's
/// start.
Map<String, Duration> _frames(IkkiuchiRankTimeline t) {
  const ms = Duration(milliseconds: 1);
  return switch (t.moment) {
    IkkiuchiRankMoment.up => {'start': t.chipPopAt + ms * 100, 'mid': t.runAt + ms * 1300},
    IkkiuchiRankMoment.down => {'start': ms * 800, 'mid': t.chipFlyAt + ms * 150},
    IkkiuchiRankMoment.rankUp => {
        'start': t.chipFlyAt + ms * 250,
        'strain': t.gateAt + ms * 500,
        'break': t.breakAt + ms * 260,
        'slash': t.cutAt + ms * 340,
        'slam': t.impactAt + ms * 230,
      },
    IkkiuchiRankMoment.rankDown => {'start': ms * 900, 'crack': t.crackAt + ms * 290, 'fall': t.crackAt + ms * 730},
    IkkiuchiRankMoment.placing => {'start': ms * 800, 'mid': t.runAt + ms * 2000},
    IkkiuchiRankMoment.placed => {
        'start': t.chipFlyAt + ms * 150,
        'suspense': t.suspenseAt + ms * 550,
        'reveal': t.revealAt + ms * 300,
        'slam': t.impactAt + ms * 240,
      },
  };
}

/// A tall phone: the user's width, more height.
const _tallPhone = Screen('384 tall', Size(384, 900), 2.8125);

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final real = sounds;
  late _HeardSounds heard;
  setUp(() => sounds = heard = _HeardSounds());
  tearDown(() => sounds = real);
  setUpAll(() async {
    await loadAppFonts();
    final loader = FontLoader('Reggae')
      ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/ReggaeOne-Regular.ttf').readAsBytesSync())));
    await loader.load();
  });

  group('the timeline', () {
    test('the count runs about 3 s, eased in and out, a rank up waiting at the line', () {
      for (final moment in IkkiuchiRankMoment.values) {
        final t = _timeline(ikkiuchiRankPreview(moment));
        expect(t.moment, moment);
        final wait = t.ranksUp ? IkkiuchiRankMotion.breakAfter : Duration.zero;
        expect(t.landAt - t.runAt, IkkiuchiRankMotion.run + wait, reason: moment.name);
        expect(IkkiuchiRankMotion.run, const Duration(seconds: 3));
        expect(t.shareAt(t.runAt), 0);
        expect(t.shareAt(t.landAt), 1);
        expect(t.shownAt(t.length), t.change.after.round());
      }
      final t = _timeline(_rated(2000, 60));
      double moved(int from, int to) =>
          t.shareAt(t.runAt + Duration(milliseconds: to)) - t.shareAt(t.runAt + Duration(milliseconds: from));
      expect(moved(0, 500), lessThan(0.1), reason: 'slow at the start');
      expect(moved(1250, 1750), greaterThan(0.4), reason: 'fast in the middle');
      expect(moved(2500, 3000), lessThan(0.1), reason: 'slow into the landing');
    });

    test('a rank up stops on the class line, strains there and breaks through', () {
      final t = _timeline(ikkiuchiRankPreview(IkkiuchiRankMoment.rankUp));
      final line = t.change.to.minRating;
      expect(t.ratingAt(t.gateAt), closeTo(line, 0.01));
      expect(t.ratingAt(t.breakAt - const Duration(milliseconds: 1)), closeTo(line, 0.01), reason: 'held');
      expect(t.ratingAt(t.breakAt + const Duration(milliseconds: 200)), greaterThan(line), reason: 'through');
      expect(t.cutAt, greaterThan(t.landAt), reason: 'the impact frame comes once it has landed');
    });

    test('a tick for each point passed: slow, fast, slow, never closer than the spacing', () {
      for (final gain in [14.0, 62.0, -22.0, 300.0]) {
        final t = _timeline(_rated(2000, gain));
        final ticks = t.ticks;
        final gaps = _gaps(ticks);
        expect(gaps.every((g) => g >= IkkiuchiRankMotion.tickSpacing.inMilliseconds), isTrue, reason: '$gain: $gaps');
        expect(t.landAt - ticks.last, greaterThanOrEqualTo(IkkiuchiRankMotion.tickSpacing), reason: 'clear of the landing');
        if (gain.abs() < 100) {
          expect(ticks.first - t.runAt, greaterThan(const Duration(milliseconds: 200)), reason: 'it starts slowly');
        }
        if (gain.abs() < 20) expect(ticks.length, gain.abs(), reason: 'every point passed');
        final fastest = gaps.reduce((a, b) => a < b ? a : b);
        expect(gaps.first, greaterThan(fastest), reason: '$gain: slower at the start, $gaps');
        expect(gaps.last, greaterThan(fastest), reason: '$gain: slower at the end, $gaps');
      }
      final rush = _gaps(_timeline(_rated(2000, 62)).ticks);
      expect(rush.where((g) => g < 80).length, greaterThan(5), reason: 'the middle is thinned to the spacing');
    });

    test('the sounds: the points, the ticks and the landing; the strain, the break and the slam; ガーン!!', () {
      List<Sfx> at(IkkiuchiRankTimeline t, Duration when) => [
            for (final (sfx, time) in t.sounds)
              if (time == when) sfx,
          ];
      final up = _timeline(ikkiuchiRankPreview(IkkiuchiRankMoment.up));
      expect(at(up, up.chipPopAt), [Sfx.xpPop]);
      expect(at(up, up.chipFlyAt), [Sfx.cardFlick]);
      expect(at(up, up.landAt), [Sfx.ratingUp]);
      expect(up.sounds.where((c) => c.$1 == Sfx.ratingTick).length, up.ticks.length);
      expect(up.chipPopAt, lessThan(up.runAt), reason: 'a win takes the points first');

      final down = _timeline(ikkiuchiRankPreview(IkkiuchiRankMoment.down));
      expect(at(down, down.landAt), [Sfx.stamp]);
      expect(down.chipPopAt, greaterThan(down.landAt), reason: 'a loss gives them after');

      final rankUp = _timeline(ikkiuchiRankPreview(IkkiuchiRankMoment.rankUp));
      for (final beat in rankUp.strainBeats) {
        expect(at(rankUp, beat), contains(Sfx.ratingStrain));
      }
      expect(at(rankUp, rankUp.breakAt), [Sfx.ratingBreak]);
      expect(at(rankUp, rankUp.landAt), [Sfx.ratingUp]);
      expect(at(rankUp, rankUp.slashAt), [Sfx.cardFlick]);
      expect(at(rankUp, rankUp.impactAt), [Sfx.stamp, Sfx.rankUp]);
      expect(
          rankUp.sounds.where((c) => c.$1 == Sfx.ratingTick && c.$2 > rankUp.gateAt && c.$2 < rankUp.breakAt), isEmpty,
          reason: 'no tick while it strains');

      final rankDown = _timeline(ikkiuchiRankPreview(IkkiuchiRankMoment.rankDown));
      expect(at(rankDown, rankDown.shockAt), [Sfx.ankirenWrong]);
      expect(at(rankDown, rankDown.thudAt), [Sfx.stamp]);

      final placing = _timeline(ikkiuchiRankPreview(IkkiuchiRankMoment.placing));
      expect(placing.sounds.where((c) => c.$1 == Sfx.stamp).length, 1, reason: 'the landing and the slot stamp as one');

      final placed = _timeline(ikkiuchiRankPreview(IkkiuchiRankMoment.placed));
      expect([for (final b in placed.suspenseBeats) ...at(placed, b)], everyElement(Sfx.ratingStrain));
      expect(at(placed, placed.revealAt), [Sfx.ratingBreak]);
      expect(at(placed, placed.impactAt), [Sfx.stamp, Sfx.rankUp]);

      final sorted = [for (final (_, time) in placed.sounds) time];
      expect(sorted, [...sorted]..sort(), reason: 'in order');
    });

    test('every moment ends at rest with its button in', () {
      for (final moment in IkkiuchiRankMoment.values) {
        final t = _timeline(ikkiuchiRankPreview(moment));
        expect(t.length, greaterThan(t.ctaAt + IkkiuchiRankMotion.cta), reason: moment.name);
        expect(t.ctaAt, greaterThan(t.landAt), reason: moment.name);
      }
    });
  });

  group('after a match', () {
    IkkiuchiMatchRecord played(IkkiuchiSetup setup, {required bool won, bool completed = true}) {
      final at = DateTime(2026, 11, 10, 9);
      return IkkiuchiMatchRecord(
        setup: setup,
        startedAt: at,
        endedAt: at.add(const Duration(minutes: 10)),
        completed: completed,
        playerLeft: won ? 0 : 4,
        opponentLeft: won ? 4 : 0,
        reads: const [],
      );
    }

    test('each ranked match reports its rank change: placement, the first class, then the rating', () async {
      final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      const mode = IkkiuchiMode.blitz;
      final wins = [true, true, false, true, true, false];
      final moments = <IkkiuchiRankMoment>[];
      for (final (i, won) in wins.indexed) {
        final report = await p.recordIkkiuchi(played(p.ikkiuchi.of(mode).rankedSetup(rows: 2), won: won));
        final rank = report.rank!;
        expect(rank.mode, mode);
        expect(rank.margin, 4);
        moments.add(IkkiuchiRankCelebration(rank).moment);
        if (i < IkkiuchiRating.placementMatches) {
          expect(rank.placement, wins.take(i + 1).toList());
          expect(rank.path.length, i + 2);
          expect(rank.after, rank.path.last);
          expect(rank.tobi, rank.before, reason: 'Tobi at exactly the estimate');
        } else {
          expect(rank.curve.last, rank.after);
          expect(rank.curve[rank.curve.length - 2], rank.before);
        }
      }
      expect(moments.take(4), [
        IkkiuchiRankMoment.placing,
        IkkiuchiRankMoment.placing,
        IkkiuchiRankMoment.placing,
        IkkiuchiRankMoment.placed,
      ]);
      expect(moments.skip(4).map((m) => m == IkkiuchiRankMoment.up || m == IkkiuchiRankMoment.rankUp), [true, false]);
      final givenUp = await p.recordIkkiuchi(played(p.ikkiuchi.of(mode).rankedSetup(rows: 2), won: true, completed: false));
      expect(givenUp.rank!.result, IkkiuchiResult.gaveUp);
      expect(givenUp.rank!.won, isFalse, reason: 'given up is a loss');
    });

    test('the XP first, then the rank page for a ranked match; a free match has only the XP', () async {
      final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      List<Type> types(List<Celebration> list) => [for (final c in list) c.runtimeType];
      final ranked = await p.recordIkkiuchi(played(p.ikkiuchi.of(IkkiuchiMode.rapid).rankedSetup(rows: 3), won: true));
      expect(types(ikkiuchiCelebrationsFor(ranked)).last, IkkiuchiRankCelebration);
      expect(types(ikkiuchiCelebrationsFor(ranked)).first, XpCelebration);
      final free = await p.recordIkkiuchi(played(IkkiuchiSetup.firstFree, won: true));
      expect(free.rank, isNull);
      expect(types(ikkiuchiCelebrationsFor(free)), everyElement(isNot(IkkiuchiRankCelebration)));
      expect(types(ikkiuchiCelebrationsFor(free)), [XpCelebration]);
      final levelling = IkkiuchiReport(
        match: ranked.match,
        xp: XpGain(before: XpCurve.reach(2) - 10, award: const XpAward([XpPart(XpSource.taken, 4, 800)])),
        rank: ranked.rank,
      );
      expect(types(ikkiuchiCelebrationsFor(levelling)), [XpCelebration, LevelUpCelebration, IkkiuchiRankCelebration]);
    });
  });

  // A player in [lang].
  Future<Progress> open(WidgetTester tester, String lang) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
    });
    return p;
  }

  Widget app(Progress p, Widget home) => RepaintBoundary(
        key: screenKey,
        child: ProgressScope(
          progress: p,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildMangaTheme(),
            builder: (context, child) => DefaultTextStyle(style: Theme.of(context).textTheme.bodyMedium!, child: child!),
            home: home,
          ),
        ),
      );

  // Shows [change]'s page on [phone] at [fontScale].
  Future<void> show(WidgetTester tester, Progress p, IkkiuchiRankChange change, Screen phone,
      {double fontScale = 1}) async {
    useScreen(tester, phone, fontScale: fontScale);
    await tester.pumpWidget(app(p, Scaffold(body: IkkiuchiRankOverlay(data: IkkiuchiRankCelebration(change), onNext: () {}))));
  }

  // Plays the page shown from [from] to [until], in steps as on a phone.
  Future<void> advance(WidgetTester tester, {Duration from = Duration.zero, required Duration until}) async {
    var at = from;
    while (at < until) {
      final step = until - at < const Duration(milliseconds: 50) ? until - at : const Duration(milliseconds: 50);
      await tester.pump(step);
      at += step;
    }
  }

  group('fits', () {
    for (final moment in IkkiuchiRankMoment.values) {
      for (final lang in ['ja', 'en']) {
        testWidgets('${moment.name} ($lang)', (tester) async {
          final p = await open(tester, lang);
          final s = S(lang);
          final change = ikkiuchiRankPreview(moment);
          final t = _timeline(change);
          for (final phone in [usersPhone, narrowTallPhone, _tallPhone]) {
            for (final fontScale in [1.0, 1.1]) {
              var at = Duration.zero;
              await show(tester, p, change, phone, fontScale: fontScale);
              for (final stop in [..._frames(t).values, t.length]) {
                await advance(tester, from: at, until: stop);
                at = stop;
                expect(tester.takeException(), isNull, reason: '${phone.name} $fontScale ${stop.inMilliseconds} ms');
              }
              final cta = tester.getRect(find.byType(CelebrationCta));
              expect(cta.bottom, lessThanOrEqualTo(phone.size.height - phone.bars.bottom - IkkiuchiRankLayout.bottomGap + 0.5),
                  reason: '${phone.name} $fontScale: clear of the navigation bar');
              expect(cta.height, greaterThanOrEqualTo(IkkiuchiRankLayout.ctaHeight));
              expect(tester.getRect(find.byType(IkkiuchiRankOverlay)).height, phone.size.height);
              await tester.pumpWidget(const SizedBox());
            }
          }
          await show(tester, p, change, usersPhone);
          await advance(tester, until: t.length);
          expect(find.text('${change.after.round()}'), findsWidgets, reason: 'counted to the new rating');
          final cta = switch (moment) {
            IkkiuchiRankMoment.placing => s.onward,
            _ when change.won => s.ratingCta,
            _ => s.ikkiuchiRankNextTime,
          };
          expect(find.descendant(of: find.byType(CelebrationCta), matching: find.text(cta)), findsOneWidget);
          if (moment == IkkiuchiRankMoment.rankUp) expect(find.text(s.ikkiuchiRankUpSticker), findsOneWidget);
          if (moment == IkkiuchiRankMoment.rankDown) expect(find.text(s.ikkiuchiRankDownSticker), findsOneWidget);
          if (moment == IkkiuchiRankMoment.placed) expect(find.text(s.newBadge), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    testWidgets('given up shows 棄権, and the dev previews play every moment in each mode', (tester) async {
      final p = await open(tester, 'ja');
      final s = S('ja');
      final down = ikkiuchiRankPreview(IkkiuchiRankMoment.down);
      final givenUp = IkkiuchiRankChange(
          mode: down.mode,
          result: IkkiuchiResult.gaveUp,
          margin: 0,
          tobi: down.tobi,
          before: down.before,
          after: down.after,
          curve: down.curve);
      await show(tester, p, givenUp, usersPhone);
      await advance(tester, until: _timeline(givenUp).length);
      expect(find.text(s.ikkiuchiResult(IkkiuchiResult.gaveUp)), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      for (final mode in IkkiuchiMode.values) {
        useScreen(tester, usersPhone);
        await tester.pumpWidget(app(
          p,
          Scaffold(
            body: Builder(
              builder: (context) =>
                  TextButton(onPressed: () => previewIkkiuchiRank(context, mode: mode), child: const Text('go')),
            ),
          ),
        ));
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pump(Motion.route);
        final pages = tester.widget<CelebrationSequence>(find.byType(CelebrationSequence)).pages;
        expect([for (final c in pages) (c as IkkiuchiRankCelebration).moment], IkkiuchiRankMoment.values);
        expect(pages.every((c) => (c as IkkiuchiRankCelebration).change.mode == mode), isTrue);
        await tester.pump(_timeline((pages.first as IkkiuchiRankCelebration).change).length);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(CelebrationCta));
        await tester.pump(ResultsLayout.overlayFade);
        expect(heard.played, contains(Sfx.ratingTick));
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('renders', skip: !renderScreens, () {
    Future<void> capture(WidgetTester tester, String screen, {required String lang, String? variant}) async {
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump();
      await tester.pump();
      await captureScreen(tester, 'ikkiuchi_rank/$screen', lang: lang, variant: variant);
    }

    for (final moment in IkkiuchiRankMoment.values) {
      testWidgets(moment.name, (tester) async {
        final change = ikkiuchiRankPreview(moment);
        final t = _timeline(change);
        final english = moment == IkkiuchiRankMoment.rankUp || moment == IkkiuchiRankMoment.placed;
        for (final lang in ['ja', if (english) 'en']) {
          final p = await open(tester, lang);
          for (final (phone, fontScale, frames) in [
            (usersPhone, 1.0, lang == 'ja'),
            (usersPhone, 1.1, false),
            (_tallPhone, 1.0, false),
          ]) {
            if (lang == 'en' && phone != usersPhone) continue;
            final tag = phone == _tallPhone ? '_tall' : '';
            var at = Duration.zero;
            await show(tester, p, change, phone, fontScale: fontScale);
            if (frames) {
              for (final MapEntry(key: name, value: stop) in _frames(t).entries) {
                await advance(tester, from: at, until: stop);
                at = stop;
                await capture(tester, moment.name, lang: lang, variant: name);
              }
            }
            await advance(tester, from: at, until: t.length);
            await capture(tester, moment.name, lang: lang, variant: 'end$tag');
            await tester.pumpWidget(const SizedBox());
          }
        }
      });
    }

    test('the ticks of a +14 and a +62 count', () {
      final lines = <String>[
        'Tick times (ms from the start of the count), the gap to the one before in brackets.',
        'Count ${IkkiuchiRankMotion.run.inMilliseconds} ms on a cubic ease in and out, '
            'ticks no closer than ${IkkiuchiRankMotion.tickSpacing.inMilliseconds} ms.',
      ];
      for (final gain in [14.0, 62.0]) {
        final t = _timeline(_rated(2596, gain));
        final ticks = [for (final at in t.ticks) (at - t.runAt).inMilliseconds];
        lines
          ..add('')
          ..add('+${gain.round()}: ${ticks.length} ticks, landing at ${(t.landAt - t.runAt).inMilliseconds}')
          ..add([for (final (i, at) in ticks.indexed) i == 0 ? '$at' : '$at (${at - ticks[i - 1]})'].join(', '));
      }
      File('build/screens/ikkiuchi_rank/ticks.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('${lines.join('\n')}\n');
    });
  });
}
