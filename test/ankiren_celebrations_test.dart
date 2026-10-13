// 暗記練's celebrations after a game: the shared XP and level-up pages, the
// rating page in every moment (placement, the reveal, a rise, a hold, a
// fall, a breakthrough into the rank-up, a fall into a lower class) and the
// rank-up for 暗記練's own rank. Each fits phones 360, 384 and 412 dp wide
// at font scale 1.0 and 1.3, in English and Japanese; the results screen
// plays them for ranked, free and placement games, and none for the test
// game.
//
// With RENDER_SCREENS=1 it also renders the pages at 1080 × 2340 px, with
// real fonts and art, to .scratchpad/ankiren_celebrations/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_rating.dart';
import 'package:fudatobashi/domain/ankiren_xp.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/stats_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/side_trips.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_rating_overlay.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_results_screen.dart';
import 'package:fudatobashi/ui/debug/celebration_preview.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/results/celebration_chrome.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';
import 'package:fudatobashi/ui/results/level_up_overlay.dart';
import 'package:fudatobashi/ui/results/rank_up_overlay.dart';
import 'package:fudatobashi/ui/results/xp_overlay.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_vector_art.dart';

/// A phone: its size in dp and its pixels per dp (all 1080 × 2340 px),
/// with a 28 dp status bar and a 48 dp navigation bar.
typedef _Phone = ({String name, Size size, double dpr});

const _narrow = (name: '360', size: Size(360, 780), dpr: 3.0);
const _users = (name: '384', size: Size(384, 832), dpr: 2.8125);
const _wide = (name: '412', size: Size(1080 / 2.625, 2340 / 2.625), dpr: 2.625);
const _phones = [_narrow, _users, _wide];
const _statusBar = 28.0, _navBar = 48.0;

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

class _HeardSounds extends Sounds {
  final played = <Sfx>[];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}

final _eLower = Rating.bands[3].minRating;

/// The rating page's moments, each with its ratings and game.
final _moments = <AnkirenRatingMoment, AnkirenRatingCelebration>{
  AnkirenRatingMoment.placing: AnkirenRatingCelebration(AnkirenRating.start, 820, game: 1, placementScores: const [612]),
  AnkirenRatingMoment.placed: const AnkirenRatingCelebration(1010, 1180, game: 3, placementScores: [612, 845, 903]),
  AnkirenRatingMoment.up: AnkirenRatingCelebration(_eLower + 60, _eLower + 118, game: 9),
  AnkirenRatingMoment.held: AnkirenRatingCelebration(_eLower + 60, _eLower + 60.2, game: 9),
  AnkirenRatingMoment.down: AnkirenRatingCelebration(_eLower + 120, _eLower + 84, game: 9),
  AnkirenRatingMoment.rankUp: AnkirenRatingCelebration(_eLower - 40, _eLower + 22, game: 9),
  AnkirenRatingMoment.rankDown: AnkirenRatingCelebration(_eLower + 18, _eLower - 26, game: 9),
};

/// A 暗記練 game's XP: every 暗記練 source, crossing a level from [into]
/// XP into level 7.
XpGain _ankirenGain({int into = 150}) => XpGain(
      before: XpCurve.reach(7) + into,
      award: XpAward([
        XpPart(XpSource.firstTap, 12, 12 * AnkirenXp.cardXp(3)),
        XpPart(XpSource.secondTap, 3,
            3 * (AnkirenXp.cardXp(3) * AnkirenTuning.firstTapCredit[TapProximity.row]!).round()),
        const XpPart(XpSource.missed, 2, 2 * AnkirenXpTuning.perMiss),
        const XpPart(XpSource.speed, 12, 310),
        const XpPart(XpSource.clear, 1, AnkirenXpTuning.clear),
        const XpPart(XpSource.ranked, 1, AnkirenXpTuning.ranked),
        const XpPart(XpSource.best, 1, AnkirenXpTuning.personalBest),
        const XpPart(XpSource.placement, 1, AnkirenXpTuning.placement),
      ]),
    );

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
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  // An all-known player in [lang].
  Future<Progress> open(WidgetTester tester, String lang) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.setLearningMode(LearningMode.allKnown);
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
    });
    return p;
  }

  void onPhone(WidgetTester tester, _Phone phone, double fontScale) {
    final bars = FakeViewPadding(top: _statusBar * phone.dpr, bottom: _navBar * phone.dpr);
    tester.view
      ..devicePixelRatio = phone.dpr
      ..physicalSize = phone.size * phone.dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Widget app(Progress p, Widget home, {GlobalKey<NavigatorState>? navigator}) => RepaintBoundary(
        key: const ValueKey('screen'),
        child: ProgressScope(
          progress: p,
          child: MaterialApp(
            navigatorKey: navigator,
            debugShowCheckedModeBanner: false,
            theme: buildMangaTheme(),
            builder: (context, child) => DefaultTextStyle(style: Theme.of(context).textTheme.bodyMedium!, child: child!),
            home: home,
          ),
        ),
      );

  // Shows [page] full screen on [phone] at [fontScale], [settle] into it.
  Future<void> showPage(WidgetTester tester, Progress p, Widget page, _Phone phone,
      {double fontScale = 1, Duration settle = Duration.zero}) async {
    onPhone(tester, phone, fontScale);
    await tester.pumpWidget(app(p, Scaffold(body: page)));
    await tester.pump(settle);
  }

  // [f] shows whole, inside the gutters, between the system bars.
  void expectShown(WidgetTester tester, Finder f, _Phone phone) {
    final r = tester.getRect(f);
    expect(r.left, greaterThanOrEqualTo(Gaps.gutter - 0.5), reason: '$f');
    expect(r.right, lessThanOrEqualTo(phone.size.width - Gaps.gutter + 0.5), reason: '$f');
    expect(r.top, greaterThanOrEqualTo(_statusBar - 0.5), reason: '$f');
    expect(r.bottom, lessThanOrEqualTo(phone.size.height - _navBar + 0.5), reason: '$f');
  }

  // [f] shows whole on screen, between the system bars.
  void expectOnScreen(WidgetTester tester, Finder f, _Phone phone) {
    final r = tester.getRect(f);
    expect(r.left, greaterThanOrEqualTo(0), reason: '$f');
    expect(r.right, lessThanOrEqualTo(phone.size.width), reason: '$f');
    expect(r.top, greaterThanOrEqualTo(_statusBar - 0.5), reason: '$f');
    expect(r.bottom, lessThanOrEqualTo(phone.size.height - _navBar + 0.5), reason: '$f');
  }

  // The class written on the flag; null for the veiled flag's mark.
  Finder cloth(RankBand? band) => find.byKey(ValueKey(band?.id ?? AnkirenRatingLayout.veiled));

  group('the pages after a game', () {
    AnkirenReport report({double? before, double? after, int games = 0, XpGain? xp}) =>
        AnkirenReport(ratingBefore: before, ratingAfter: after, rankedGames: games, xp: xp);
    final earned = XpGain(before: 0, award: const XpAward([XpPart(XpSource.firstTap, 1, 70)]));
    final levelling = XpGain(before: XpCurve.reach(2) - 10, award: const XpAward([XpPart(XpSource.firstTap, 4, 280)]));
    List<Type> types(List<Celebration> list) => [for (final c in list) c.runtimeType];

    test('free play: the XP, and the level-up when it reaches one; nothing earned shows nothing', () {
      expect(types(ankirenCelebrationsFor(report(xp: earned))), [XpCelebration]);
      expect(types(ankirenCelebrationsFor(report(xp: levelling))), [XpCelebration, LevelUpCelebration]);
      expect(ankirenCelebrationsFor(report(xp: XpGain(before: 0, award: const XpAward([])))), isEmpty);
    });

    test('a ranked game: the XP, then the rating page in its moment', () {
      AnkirenRatingMoment momentOf(double before, double after, int games) =>
          (ankirenCelebrationsFor(report(before: before, after: after, games: games, xp: earned)).last
                  as AnkirenRatingCelebration)
              .moment;
      expect(momentOf(400, 900, 1), AnkirenRatingMoment.placing);
      expect(momentOf(900, 950, 2), AnkirenRatingMoment.placing);
      expect(momentOf(950, 1000, AnkirenRatingModel.placementGames), AnkirenRatingMoment.placed);
      expect(momentOf(_eLower + 10, _eLower + 30, 5), AnkirenRatingMoment.up);
      expect(momentOf(_eLower + 10, _eLower + 10.3, 5), AnkirenRatingMoment.held);
      expect(momentOf(_eLower + 30, _eLower + 10, 5), AnkirenRatingMoment.down);
      expect(momentOf(_eLower + 10, _eLower - 10, 5), AnkirenRatingMoment.rankDown);
      final placement =
          ankirenCelebrationsFor(report(before: 400, after: 900, games: 1, xp: earned), placementScores: [420]);
      expect(types(placement), [XpCelebration, AnkirenRatingCelebration]);
      expect((placement.last as AnkirenRatingCelebration).placementScores, [420]);
    });

    test('a ranked game breaking into a higher class adds 暗記練\'s own rank-up', () {
      final list = ankirenCelebrationsFor(report(before: _eLower - 10, after: _eLower + 10, games: 7, xp: earned));
      expect(types(list), [XpCelebration, AnkirenRatingCelebration, RankUpCelebration]);
      expect(
        list.last,
        isA<RankUpCelebration>()
            .having((c) => c.trip, 'trip', SideTrip.ankiren)
            .having((c) => c.before, 'before', Rating.bands[2])
            .having((c) => c.after, 'after', Rating.bands[3]),
      );
      expect(types(ankirenCelebrationsFor(report(before: _eLower + 10, after: _eLower - 10, games: 7))),
          [AnkirenRatingCelebration],
          reason: 'a fall into a lower class has no rank-up, and a forfeit earns no XP');
    });

    test('the main run shares the XP pages', () {
      expect(types(xpCelebrations(levelling)), [XpCelebration, LevelUpCelebration]);
      expect(xpCelebrations(null), isEmpty);
    });
  });

  group('fits', () {
    for (final MapEntry(key: moment, value: data) in _moments.entries) {
      for (final lang in ['en', 'ja']) {
        testWidgets('the rating page, ${moment.name} ($lang)', (tester) async {
          final p = await open(tester, lang);
          final s = S(lang);
          final t = AnkirenRatingTimeline(data);
          expect(t.moment, moment);
          for (final phone in _phones) {
            for (final fontScale in [1.0, 1.3]) {
              final stops = [
                t.moveAt + (t.moveEnd - t.moveAt) ~/ 2,
                if (t.reveals) t.revealAt + AnkirenRatingMotion.flashHold,
                t.breaksThrough ? t.strainEnd : t.length,
              ];
              var at = Duration.zero;
              await showPage(tester, p, AnkirenRatingOverlay(data: data, onNext: () {}), phone, fontScale: fontScale);
              for (final stop in stops) {
                await tester.pump(stop - at);
                at = stop;
                expect(tester.takeException(), isNull, reason: '${phone.name} dp, $fontScale, ${at.inMilliseconds} ms');
              }
              expectOnScreen(tester, find.byType(Tobi), phone);
              if (!t.breaksThrough) {
                expectShown(tester, find.byType(CelebrationCta), phone);
              }
              await tester.pumpWidget(const SizedBox());
            }
          }
          final end = t.breaksThrough ? t.strainEnd : t.length;
          await showPage(tester, p, AnkirenRatingOverlay(data: data, onNext: () {}), _users, settle: end);
          switch (moment) {
            case AnkirenRatingMoment.placing:
              expect(cloth(null), findsWidgets, reason: 'the class is not known yet');
              expect(cloth(Rating.bandOf(data.after)), findsNothing);
              expect(find.text('${data.after.round()}'), findsNothing, reason: 'the rating stays hidden');
              expect(find.text(s.ankirenPlacementLeft(2).replaceAll('{0}', '2'), findRichText: true), findsOneWidget);
            case AnkirenRatingMoment.placed:
              expect(cloth(Rating.bandOf(data.after)), findsOneWidget, reason: 'the first class shows');
              expect(find.text('${data.after.round()}'), findsWidgets);
              expect(find.text(s.newBadge), findsOneWidget);
            case AnkirenRatingMoment.rankUp:
              expect(find.text('${Rating.bands[3].minRating.round()}'), findsWidgets, reason: 'at the finial');
            default:
              expect(find.text('${data.after.round()}'), findsWidgets, reason: 'counted to the new rating');
              expect(cloth(Rating.bandOf(data.after)), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    testWidgets('the ends of the ladder: 入門 from the start, and the top class without a next one', (tester) async {
      final top = Rating.bands.last.minRating;
      final cases = [
        const AnkirenRatingCelebration(560, 610, game: 5),
        const AnkirenRatingCelebration(620, 560, game: 5),
        const AnkirenRatingCelebration(560, 700, game: 3, placementScores: [120, 180, 240]),
        AnkirenRatingCelebration(top + 40, top + 90, game: 12),
        AnkirenRatingCelebration(top - 20, top + 30, game: 12),
      ];
      for (final lang in ['en', 'ja']) {
        final p = await open(tester, lang);
        final s = S(lang);
        for (final data in cases) {
          final t = AnkirenRatingTimeline(data);
          await showPage(tester, p, AnkirenRatingOverlay(data: data, onNext: () {}), _narrow,
              fontScale: 1.3, settle: t.breaksThrough ? t.strainEnd : t.length);
          expect(tester.takeException(), isNull, reason: '${data.moment.name} ${data.after}');
          if (Rating.bandOf(data.after) == Rating.bands.first) {
            expect(t.track.floor, AnkirenRating.start, reason: '入門 stands on the start');
          }
          if (Rating.bandOf(data.after) == Rating.bands.last && !t.breaksThrough) {
            expect(find.text(s.topClassNote), findsOneWidget);
            expect(find.text(s.topClassChase), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    for (final lang in ['en', 'ja']) {
      testWidgets('the shared XP and level-up pages list 暗記練\'s lines ($lang)', (tester) async {
        final p = await open(tester, lang);
        final s = S(lang);
        final gain = _ankirenGain(into: XpCurve.span(7) - 200);
        expect(gain.levelsGained, greaterThan(0));
        final timeline = XpTimeline(gain);
        for (final phone in _phones) {
          for (final fontScale in [1.0, 1.3]) {
            await showPage(tester, p, XpOverlay(gain: gain, onNext: () {}), phone,
                fontScale: fontScale, settle: timeline.length);
            expect(tester.takeException(), isNull, reason: '${phone.name} dp, $fontScale');
            for (final source in [XpSource.firstTap, XpSource.secondTap, XpSource.ranked, XpSource.placement]) {
              expect(find.text(s.xpSource(source)), findsOneWidget);
            }
            expect(find.text('+${gain.award.total}'), findsWidgets);
            expectShown(tester, find.byType(CelebrationCta), phone);
            await showPage(tester, p, LevelUpOverlay(gain: gain, onNext: () {}), phone,
                fontScale: fontScale, settle: LevelUpMotion.length);
            expect(tester.takeException(), isNull, reason: '${phone.name} dp, $fontScale');
            expect(find.text('${gain.levelAfter.level}'), findsWidgets);
            await tester.pumpWidget(const SizedBox());
          }
        }
      });

      testWidgets('暗記練\'s rank-up names its ladder and the points left ($lang)', (tester) async {
        final p = await open(tester, lang);
        final s = S(lang);
        final (before, after) = (_eLower - 40, _eLower + 22);
        final data = RankUpCelebration(Rating.bands[2], Rating.bands[3], before, after, trip: SideTrip.ankiren);
        for (final phone in _phones) {
          for (final fontScale in [1.0, 1.3]) {
            await showPage(tester, p, RankUpOverlay(data: data, onNext: () {}), phone,
                fontScale: fontScale, settle: RankUpMotion.length + const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull, reason: '${phone.name} dp, $fontScale');
            expect(find.text(s.ankirenRankUpBand), findsOneWidget);
            expect(find.text(s.rankUpBand), findsNothing);
            final points = (Rating.bands[4].minRating - after).ceil();
            expect(find.byWidgetPredicate((w) => w is NumberedText && w.values.single == points), findsOneWidget);
            expect(find.text(s.nextClassTarget, findRichText: true), findsNothing, reason: 'no 100-card time');
            await tester.pumpWidget(const SizedBox());
          }
        }
      });
    }
  });

  group('plays', () {
    // Records [game] for [p], then shows its results over an empty screen.
    Future<AnkirenReport> results(WidgetTester tester, Progress p, AnkirenSetup setup,
        {bool tracked = true, int? endAfter, int ms = 600}) async {
      final game = playAnkiren(setup, ms: ms, endAfter: endAfter);
      late AnkirenReport? report;
      if (tracked) {
        await tester.runAsync(() async => report = await p.recordAnkiren(game, startedAt: DateTime.now()));
      } else {
        report = null;
      }
      onPhone(tester, _users, 1);
      await tester.pumpWidget(app(p, AnkirenResultsScreen(game: game, report: report, tracked: tracked)));
      await tester.pump();
      return report ?? const AnkirenReport(ratingBefore: null, ratingAfter: null);
    }

    Future<void> tapThrough(WidgetTester tester) async {
      await tester.tapAt(const Offset(200, 300));
      await tester.pump();
      await tester.pump(ResultsLayout.overlayFade);
      await tester.pump();
    }

    // Taps past the XP page, and the level-up when [report] reached one.
    Future<void> pastXp(WidgetTester tester, AnkirenReport report) async {
      expect(find.byType(XpOverlay), findsOneWidget);
      await tapThrough(tester);
      if (report.xp!.levelsGained > 0) {
        expect(find.byType(LevelUpOverlay), findsOneWidget);
        await tapThrough(tester);
      }
    }

    testWidgets('a ranked placement game: its XP, then its slot of ランク判定, then the results', (tester) async {
      final p = await open(tester, 'en');
      final report = await results(tester, p, AnkirenSetup.forLevel(0, ranked: true));
      expect(find.byType(CelebrationSequence), findsNothing, reason: 'the results show first');
      await tester.pump(ResultsLayout.overlayStagger);
      expect(find.text(const S('en').xpSource(XpSource.ranked)), findsOneWidget);
      await pastXp(tester, report);
      final page = tester.widget<AnkirenRatingOverlay>(find.byType(AnkirenRatingOverlay));
      expect(page.data.moment, AnkirenRatingMoment.placing);
      expect(page.data.placementScores, [p.sideTrips.runs.single.score]);
      await tapThrough(tester);
      await tester.pump(ResultsLayout.overlayFade);
      await tester.pump();
      expect(find.byType(CelebrationSequence), findsNothing, reason: 'tapped through, as after a run');
      expect(find.text(const S('en').again), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the third ranked game reveals the first class', (tester) async {
      final p = await open(tester, 'en');
      await tester.runAsync(() async {
        for (var i = 0; i < AnkirenRatingModel.placementGames - 1; i++) {
          await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true), ms: 700), startedAt: DateTime.now());
        }
      });
      final level = p.sideTripsHub()[SideTrip.ankiren].rankedLevel!;
      final report = await results(tester, p, AnkirenSetup.forLevel(level, ranked: true));
      await tester.pump(ResultsLayout.overlayStagger);
      expect(find.text(const S('en').xpSource(XpSource.placement)), findsOneWidget, reason: 'placement done');
      await pastXp(tester, report);
      final page = tester.widget<AnkirenRatingOverlay>(find.byType(AnkirenRatingOverlay));
      expect(page.data.moment, AnkirenRatingMoment.placed);
      expect(page.data.placementScores, [for (final r in p.sideTrips.runs) r.score]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a custom game: the cards found and missed in place of a score, and no XP', (tester) async {
      const s = S('en');
      final p = await open(tester, 'en');
      const custom = AnkirenSetup.custom(perSide: 4, memorise: Duration(minutes: 1));
      final report = await results(tester, p, custom, endAfter: 6);
      await tester.pump(ResultsLayout.overlayStagger * 2);
      expect(report.xp!.award.parts, isEmpty);
      expect(find.byType(CelebrationSequence), findsNothing, reason: 'nothing earned, nothing to celebrate');
      expect([s.endedEarly, s.ankirenFoundOf(8), s.ankirenMissed(2), s.ankirenCustomNote].map(find.text),
          everyElement(findsOneWidget));
      expect(find.text(s.ankirenScoreLabel), findsNothing);
      await tester.pumpWidget(const SizedBox());

      await results(tester, p, custom);
      expect([s.ankirenFoundLabel, s.ankirenMissed(0)].map(find.text), everyElement(findsOneWidget));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a free game shows its XP and no rating page; the test game shows nothing', (tester) async {
      final p = await open(tester, 'en');
      final report = await results(tester, p, AnkirenSetup.forLevel(1));
      await tester.pump(ResultsLayout.overlayStagger);
      await pastXp(tester, report);
      await tester.pump(ResultsLayout.overlayFade);
      await tester.pump();
      expect(find.byType(CelebrationSequence), findsNothing);
      expect(find.byType(AnkirenRatingOverlay), findsNothing);
      await tester.pumpWidget(const SizedBox());

      await results(tester, p, AnkirenSetup.forLevel(1), tracked: false);
      await tester.pump(ResultsLayout.overlayStagger * 2);
      expect(find.byType(CelebrationSequence), findsNothing, reason: 'nothing recorded, nothing earned');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the pages play upright, even after a game in landscape, and let go once done', (tester) async {
      final requests = <List<String>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') requests.add([...call.arguments as List]);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final p = await open(tester, 'en');
      final report = await results(tester, p, AnkirenSetup.forLevel(1));
      expect(requests, [
        ['DeviceOrientation.portraitUp'],
      ]);
      await tester.pump(ResultsLayout.overlayStagger);
      await pastXp(tester, report);
      await tester.pump(ResultsLayout.overlayFade);
      await tester.pump();
      expect(find.byType(CelebrationSequence), findsNothing);
      expect(requests.last, isEmpty, reason: 'free to turn again');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a forfeit earns no XP: only the rating page plays', (tester) async {
      final p = await open(tester, 'en');
      final report = await results(tester, p, AnkirenSetup.forLevel(0, ranked: true), endAfter: 1);
      expect(report.xp!.award.total, 0);
      await tester.pump(ResultsLayout.overlayStagger);
      expect(find.byType(XpOverlay), findsNothing);
      expect(find.byType(AnkirenRatingOverlay), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a breakthrough strains at the finial and cuts to 暗記練\'s rank-up by itself', (tester) async {
      final p = await open(tester, 'en');
      final data = _moments[AnkirenRatingMoment.rankUp]!;
      final t = AnkirenRatingTimeline(data);
      var done = false;
      final pages = [
        data,
        RankUpCelebration(Rating.bandOf(data.before), Rating.bandOf(data.after), data.before, data.after,
            trip: SideTrip.ankiren),
      ];
      await showPage(tester, p, CelebrationSequence(pages: pages, onDone: () => done = true), _users,
          settle: t.moveEnd + AnkirenRatingMotion.strain ~/ 2);
      expect(heard.played, contains(Sfx.ratingStrain));
      expect(find.byType(RankUpOverlay), findsNothing);
      await tester.pump(t.cutAt - t.moveEnd - AnkirenRatingMotion.strain ~/ 2 + const Duration(milliseconds: 20));
      expect(heard.played.last, Sfx.ratingBreak);
      expect(find.byType(RankUpOverlay), findsOneWidget, reason: 'handed over at the flash');
      expect(find.text(const S('en').ankirenRankUpBand), findsOneWidget);
      await tester.pump(RankUpMotion.length);
      expect(tester.takeException(), isNull);
      expect(done, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a fall into a lower class relabels the flag as it sinks past the line', (tester) async {
      final p = await open(tester, 'en');
      final data = _moments[AnkirenRatingMoment.rankDown]!;
      final t = AnkirenRatingTimeline(data);
      expect(t.track.lines, [Rating.bands[3]], reason: 'the pole shows the line it sinks past');
      await showPage(tester, p, CelebrationSequence(pages: [data], onDone: () {}), _users, settle: t.moveAt);
      expect(cloth(Rating.bands[3]), findsOneWidget);
      var at = t.moveAt;
      while (t.ratingAt(at) >= _eLower) {
        at += const Duration(milliseconds: 50);
      }
      await tester.pump(at - t.moveAt + AnkirenRatingMotion.relabel);
      expect(cloth(Rating.bands[2]), findsOneWidget, reason: 'the class it sank into');
      expect(heard.played, isEmpty, reason: 'no clicks on the way down');
      await tester.pump(t.length);
      expect(heard.played, [Sfx.ankirenFlip], reason: 'one soft flap as it lands');
      expect(find.text(const S('en').ankirenNextTime), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the reveal: stamp, drumroll, the fanfare as the class shows, a click as it counts', (tester) async {
      final p = await open(tester, 'en');
      final data = _moments[AnkirenRatingMoment.placed]!;
      final t = AnkirenRatingTimeline(data);
      await showPage(tester, p, CelebrationSequence(pages: [data], onDone: () {}), _users,
          settle: t.revealAt - const Duration(milliseconds: 20));
      expect(cloth(Rating.bandOf(data.after)), findsNothing, reason: 'still veiled');
      expect(heard.played.where((s) => s == Sfx.ratingStrain), hasLength(AnkirenRatingMotion.beats.length));
      expect(heard.played, isNot(contains(Sfx.rankUp)));
      await tester.pump(const Duration(milliseconds: 40));
      expect(heard.played, containsAllInOrder([Sfx.stamp, Sfx.rankUp]));
      await tester.pump(t.length - t.revealAt);
      expect(cloth(Rating.bandOf(data.after)), findsOneWidget);
      expect(heard.played.where((s) => s == Sfx.ratingTick), isNotEmpty);

      await tester.pumpWidget(const SizedBox());
      heard.played.clear();
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(effectSounds: false)));
      await showPage(tester, p, CelebrationSequence(pages: [data], onDone: () {}), _users, settle: t.length);
      expect(heard.played, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('under reduced motion every moment starts at rest and waits for a tap', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await open(tester, 'en');
      for (final MapEntry(key: moment, value: data) in _moments.entries) {
        var advanced = false;
        await showPage(tester, p, AnkirenRatingOverlay(data: data, onNext: () => advanced = true), _users,
            settle: const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
        final shown = switch (moment) {
          AnkirenRatingMoment.placing => null,
          AnkirenRatingMoment.rankUp => Rating.bandOf(data.before),
          _ => Rating.bandOf(data.after),
        };
        expect(cloth(shown), findsOneWidget, reason: moment.name);
        if (moment != AnkirenRatingMoment.placing && moment != AnkirenRatingMoment.rankUp) {
          expect(find.text('${data.after.round()}'), findsWidgets, reason: moment.name);
        }
        await tester.pump(const Duration(seconds: 8));
        expect(advanced, isFalse, reason: '${moment.name}: nothing moves on by itself');
        await tester.tap(find.byType(CelebrationCta));
        expect(advanced, isTrue);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('dev previews', () {
    // Opens [preview] from a button, on the user's phone.
    Future<void> preview(WidgetTester tester, Progress p, void Function(BuildContext) preview) async {
      onPhone(tester, _users, 1);
      await tester.pumpWidget(app(
        p,
        Scaffold(body: Builder(builder: (context) => TextButton(onPressed: () => preview(context), child: const Text('go')))),
      ));
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(Motion.route);
    }

    testWidgets('AnkiRen XP plays alone, or into the level-up', (tester) async {
      final p = await open(tester, 'en');
      await preview(tester, p, previewAnkirenXp);
      final sequence = tester.widget<CelebrationSequence>(find.byType(CelebrationSequence));
      expect([for (final c in sequence.pages) c.runtimeType], [XpCelebration]);
      expect((sequence.pages.single as XpCelebration).gain.award.parts.map((p) => p.source), contains(XpSource.firstTap));
      await tester.pumpWidget(const SizedBox());
      await preview(tester, p, (context) => previewAnkirenXp(context, levelUp: true));
      expect([for (final c in tester.widget<CelebrationSequence>(find.byType(CelebrationSequence)).pages) c.runtimeType],
          [XpCelebration, LevelUpCelebration]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('every moment of the rating page plays, a breakthrough into the rank-up', (tester) async {
      final p = await open(tester, 'en');
      for (final moment in AnkirenRatingMoment.values) {
        await preview(tester, p, (context) => previewAnkirenRating(context, moment));
        final pages = tester.widget<CelebrationSequence>(find.byType(CelebrationSequence)).pages;
        expect((pages.first as AnkirenRatingCelebration).moment, moment);
        expect(pages.length, moment == AnkirenRatingMoment.rankUp ? 2 : 1, reason: moment.name);
        await tester.pump(AnkirenRatingTimeline(pages.first as AnkirenRatingCelebration).length);
        expect(tester.takeException(), isNull, reason: moment.name);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('renders', skip: Platform.environment['RENDER_SCREENS'] != '1', () {
    Future<void> capture(WidgetTester tester, _Phone phone, String name) async {
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump();
      await tester.pump();
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: phone.dpr);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('.scratchpad/ankiren_celebrations/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    for (final MapEntry(key: moment, value: data) in _moments.entries) {
      for (final lang in ['en', 'ja']) {
        testWidgets('rating_${moment.name}_$lang', (tester) async {
          final p = await open(tester, lang);
          final t = AnkirenRatingTimeline(data);
          final stops = {
            'mid': t.moveAt + (t.moveEnd - t.moveAt) ~/ 2,
            if (t.reveals || t.breaksThrough) 'suspense': t.moveEnd + AnkirenRatingMotion.beats[2],
            if (t.reveals) 'reveal': t.revealAt + AnkirenRatingMotion.flashHold + AnkirenRatingMotion.flashOut ~/ 3,
            'end': t.breaksThrough ? t.strainEnd - const Duration(milliseconds: 10) : t.length,
          };
          for (final phone in [_narrow, _users]) {
            for (final fontScale in [1.0, 1.3]) {
              if (phone == _narrow && fontScale == 1) continue;
              final tag = phone == _users && fontScale == 1 ? '' : '_${phone.name}_$fontScale';
              await showPage(tester, p, AnkirenRatingOverlay(data: data, onNext: () {}), phone, fontScale: fontScale);
              var at = Duration.zero;
              for (final MapEntry(key: stop, value: until) in stops.entries) {
                // Played through in steps, as on a phone.
                while (at < until) {
                  final step = until - at < const Duration(milliseconds: 50) ? until - at : const Duration(milliseconds: 50);
                  await tester.pump(step);
                  at += step;
                }
                if (tag.isEmpty || stop == 'end') await capture(tester, phone, 'rating_${moment.name}_$lang${tag}_$stop');
              }
              await tester.pumpWidget(const SizedBox());
            }
          }
        });
      }
    }

    testWidgets('ladder_ends', (tester) async {
      final p = await open(tester, 'en');
      final top = Rating.bands.last.minRating;
      final cases = {
        'novice_up': const AnkirenRatingCelebration(560, 610, game: 5),
        'novice_placed': const AnkirenRatingCelebration(560, 700, game: 3, placementScores: [120, 180, 240]),
        'top_up': AnkirenRatingCelebration(top + 40, top + 90, game: 12),
      };
      for (final MapEntry(key: name, value: data) in cases.entries) {
        await showPage(tester, p, AnkirenRatingOverlay(data: data, onNext: () {}), _users,
            settle: AnkirenRatingTimeline(data).length);
        await capture(tester, _users, 'ladder_$name');
        await tester.pumpWidget(const SizedBox());
      }
    });

    for (final lang in ['en', 'ja']) {
      testWidgets('shared_$lang', (tester) async {
        final p = await open(tester, lang);
        final gain = _ankirenGain(into: XpCurve.span(7) - 200);
        await showPage(tester, p, XpOverlay(gain: gain, onNext: () {}), _users, settle: XpTimeline(gain).length);
        await capture(tester, _users, 'xp_$lang');
        await showPage(tester, p, XpOverlay(gain: gain, onNext: () {}), _narrow,
            fontScale: 1.3, settle: XpTimeline(gain).length);
        await capture(tester, _narrow, 'xp_${lang}_360_1.3');
        await showPage(tester, p, LevelUpOverlay(gain: gain, onNext: () {}), _users, settle: LevelUpMotion.length);
        await capture(tester, _users, 'level_up_$lang');
        final data = _moments[AnkirenRatingMoment.rankUp]!;
        await showPage(
            tester,
            p,
            RankUpOverlay(
                data: RankUpCelebration(Rating.bandOf(data.before), Rating.bandOf(data.after), data.before, data.after,
                    trip: SideTrip.ankiren),
                onNext: () {}),
            _users,
            settle: RankUpMotion.length + const Duration(milliseconds: 100));
        await capture(tester, _users, 'rank_up_$lang');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
