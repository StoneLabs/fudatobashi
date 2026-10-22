// Journey Home's today box and the hero under it, in each state of the day
// (morning, part done with misses, done, a big day, new cards paused), the
// week stamps, and the pause sheet: asked once, and yes takes today's new
// cards out. Home, with Learn ahead beside the hero's narration, fits phones
// 360, 384 and 412 dp wide at font scale 1.0 and 1.3, in English and
// Japanese, three-digit days included.
//
// With RENDER_SCREENS=1 it also renders Home in each state, and the pause
// sheet, to build/screens/daily_set/.
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/vector_art.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/learn_ahead_button.dart';
import 'package:fudatobashi/ui/home/today_box.dart';
import 'package:fudatobashi/ui/home/training_hero.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

/// Today's set first thing in the morning, played part way with misses,
/// done, a day of more reviews than the pace's pause threshold (not asked
/// yet), and such a day with its new cards paused.
enum _Day { morning, partDone, done, big, paused }

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

/// Plays [run] from [at] the way the play screen does, answering right
/// except on the swipes at [missAt]; ends it after [stopAfter] swipes when
/// given.
Future<void> _play(Progress p, PlannedRun run, DateTime at, {Set<int> missAt = const {}, int? stopAfter}) async {
  final session = PlaySession(run.cards, planner: run.planner);
  var t = const Duration(seconds: 100);
  var wall = at;
  while (!session.finished && (stopAfter == null || session.swipes.length < stopAfter)) {
    session.revealed(t);
    t += const Duration(milliseconds: 900);
    wall = wall.add(const Duration(seconds: 2));
    final miss = missAt.contains(session.swipes.length);
    session.commit(responseTs: t, commitTs: t, outcome: miss ? Outcome.dontKnow : Outcome.known, at: wall);
    t += const Duration(milliseconds: 100);
  }
  await p.recordRun(session, const PlayConfig(mode: PlayMode.training), at, now: wall);
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

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

  /// Days back from today that the player trained and finished the set;
  /// the day between the first two passed without.
  const played = [5, 3, 2, 1];

  // A journey player in [lang] with [played] behind them and today's set
  // at [day].
  Future<Progress> player(WidgetTester tester, _Day day, {String lang = 'en'}) async {
    late Progress p;
    await tester.runAsync(() async {
      final now = DateTime.now();
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateTrainerConfig(const TrainerConfig());
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true, onboarded: true));
      p.trainer.fuzzing = false;
      for (final back in played) {
        final at = now.subtract(Duration(days: back));
        await _play(p, await p.planTraining(rng: math.Random(back), now: at), at);
      }
      if (day == _Day.big || day == _Day.paused) {
        // More cards due today than the pace's threshold, and a few new.
        final yesterday = now.subtract(const Duration(days: 1)).toUtc();
        final locked = [for (final s in p.trainer.items.values) if (!s.unlocked) s];
        final over = p.trainer.config.pace.profile.pauseNewOver;
        for (final s in locked.take(over + 1)) {
          s
            ..unlocked = true
            ..card = s.card.copyWith(lastReview: yesterday, due: yesterday);
        }
        for (final s in locked.skip(over + 1).take(3)) {
          s.unlocked = true;
        }
      }
      final run = await p.planTraining(rng: math.Random(9), now: now);
      switch (day) {
        case _Day.morning || _Day.big:
          break;
        case _Day.partDone:
          await _play(p, run, now, missAt: {1, 6}, stopAfter: 14);
        case _Day.done:
          await _play(p, run, now, missAt: {3});
        case _Day.paused:
          await p.answerPause(pause: true, now: now);
      }
    });
    return p;
  }

  // Shows [p]'s Home on [phone] at [fontScale].
  Future<void> showHome(WidgetTester tester, Progress p, Screen phone, {double fontScale = 1}) async {
    useScreen(tester, phone, fontScale: fontScale);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Lets the database work started by a tap finish, then the frames after.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump(Motion.sheet * 2);
  }

  Finder inBox(Finder f) => find.descendant(of: find.byType(TodayBox), matching: f);

  // The bar's segments, left to right, by colour.
  List<Color> segments(WidgetTester tester) => [
        for (final b in tester.widgetList<ColoredBox>(inBox(find.byType(ColoredBox))))
          if (b.color != Palette.ink) b.color,
      ];

  // The legend has a cell labelled [label], with its swatch and no number
  // after it.
  void expectCell(WidgetTester tester, String label) {
    final cell = find.ancestor(of: inBox(find.text(label)), matching: find.byType(Row)).first;
    expect(find.descendant(of: cell, matching: find.byType(Text)), findsOneWidget, reason: '$label: the label only');
  }

  String balloon(WidgetTester tester) => tester.widget<TrainingHero>(find.byType(TrainingHero)).balloon;

  void expectNarration(WidgetTester tester, String template, int value) {
    final narration =
        tester.widget<NumberedText>(find.descendant(of: find.byType(NarrationBox), matching: find.byType(NumberedText)));
    expect(narration.template, template);
    expect(narration.values, [value]);
  }

  // The box keeps its height, everything in it stays inside it, and Home
  // lays out without errors.
  void expectBoxFits(WidgetTester tester, Screen phone, String why) {
    expect(tester.takeException(), isNull, reason: why);
    final box = tester.getRect(find.byType(TodayBox));
    expect(box.height, moreOrLessEquals(TodayBoxLayout.height), reason: why);
    expect(box.left, moreOrLessEquals(Gaps.gutter), reason: why);
    expect(box.right, moreOrLessEquals(phone.size.width - Gaps.gutter), reason: why);
    final inside = box.deflate(Strokes.panel - 0.5);
    for (final text in inBox(find.byType(RichText)).evaluate()) {
      final r = tester.getRect(find.byWidget(text.widget));
      final what = (text.widget as RichText).text.toPlainText();
      expect(inside.contains(r.topLeft) && inside.contains(r.bottomRight), isTrue, reason: '$why: "$what" $r in $box');
    }
  }

  // Learn ahead sits in the hero beside the narration, which still shows
  // whole.
  void expectHeroFits(WidgetTester tester, String why) {
    final hero = tester.getRect(find.byType(TrainingHero));
    final narration = tester.getRect(find.byType(NarrationBox));
    final ahead = tester.getRect(find.byType(LearnAheadButton));
    expect(hero.contains(ahead.topLeft) && hero.contains(ahead.bottomRight), isTrue, reason: '$why: $ahead in $hero');
    expect(ahead.left, greaterThan(narration.right), reason: '$why: beside the narration');
    expect((ahead.center.dy - narration.center.dy).abs(), lessThan(1), reason: '$why: level with the narration');
    final text = find.descendant(of: find.byType(NarrationBox), matching: find.byType(RichText));
    expect(tester.renderObject<RenderParagraph>(text).didExceedMaxLines, isFalse, reason: '$why: the narration shows whole');
  }

  // The pause sheet and Tobi over it show whole, between the system bars.
  void expectSheetFits(WidgetTester tester, S s, Screen phone, String why) {
    expect(tester.takeException(), isNull, reason: why);
    final sheet = tester.getRect(find.ancestor(of: find.text(s.pauseBody), matching: find.byType(MangaPanel)));
    final tobi = tester.getRect(find.byWidgetPredicate((w) => w is Tobi && w.pose == TobiPose.relaxed));
    for (final r in [sheet, tobi]) {
      expect(r.top, greaterThanOrEqualTo(phone.bars.top), reason: why);
      expect(r.bottom, lessThanOrEqualTo(phone.size.height - phone.bars.bottom + 0.5), reason: why);
      expect(r.left, greaterThanOrEqualTo(0), reason: why);
      expect(r.right, lessThanOrEqualTo(phone.size.width), reason: why);
    }
  }

  group('the box', () {
    testWidgets('in the morning: nothing green yet, room for misses, and the hero says what is left', (tester) async {
      final p = await player(tester, _Day.morning);
      await showHome(tester, p, usersPhone);
      const s = S('en');
      final set = p.todaySet()!;
      final bar = set.bar;
      expect(bar.done, 0);
      expect(segments(tester), isNot(contains(Palette.land)));
      expect(segments(tester).last, Palette.pink, reason: "the morning's guess at the misses");
      expect(inBox(find.text(s.todayLabel)), findsOneWidget);
      expect(inBox(find.text('${bar.total}')), findsOneWidget);
      expectCell(tester, s.todayMisses);
      expect(inBox(find.text('本日完了')), findsNothing);
      if (set.reviews > 0) expectCell(tester, s.todayReviews(set.reviews, TodaySetTuning.reviewLooks));
      if (set.newCards > 0) expectCell(tester, s.todayNew(set.newCards, TodaySetTuning.newLooks));
      expectCell(tester, s.todayDone);
      expect(inBox(find.textContaining('/', findRichText: true)), findsNothing, reason: 'no done / total count');
      expect(balloon(tester), s.heroTodaySet);
      expectNarration(tester, s.todayLeft, bar.left);
      expect(bar.left, lessThan(bar.total), reason: "what is left counts no guessed misses, like Play's counter");
      expectBoxFits(tester, usersPhone, 'morning');
    });

    testWidgets('part done with misses: green from the left', (tester) async {
      final p = await player(tester, _Day.partDone);
      await showHome(tester, p, usersPhone);
      const s = S('en');
      final set = p.todaySet()!;
      final bar = set.bar;
      expect(set.misses, 2);
      expect(bar.done, inInclusiveRange(10, 14), reason: "14 swipes, a 友札 after a miss may be outside the set");
      expect(segments(tester).first, Palette.land);
      expect(segments(tester), hasLength(greaterThan(1)));
      expectCell(tester, s.todayMisses);
      expectCell(tester, s.todayDone);
      expect(inBox(find.textContaining('/', findRichText: true)), findsNothing, reason: 'no done / total count');
      expect(balloon(tester), s.heroKeepItUp);
      expectNarration(tester, s.todayLeft, bar.left);
      expectBoxFits(tester, usersPhone, 'part done');
    });

    testWidgets('done: a solid green bar under the 本日完了 hanko, no legend, and runs of 30 after', (tester) async {
      final p = await player(tester, _Day.done);
      await showHome(tester, p, usersPhone);
      const s = S('en');
      expect(segments(tester), [Palette.land]);
      expect(inBox(find.text('本日完了')), findsOneWidget);
      final stamp = tester.getRect(inBox(find.text('本日完了')));
      final box = tester.getRect(find.byType(TodayBox));
      expect(stamp.center.dx, moreOrLessEquals(box.center.dx, epsilon: 1));
      final barTop =
          box.top + HomeLayout.progressPadding.top + HomeLayout.mapCut + TodayBoxLayout.headerHeight + TodayBoxLayout.sectionGap;
      final legendBottom = barTop + TodayBoxLayout.barHeight + TodayBoxLayout.sectionGap + TodayBoxLayout.legendHeight;
      expect(stamp.center.dy, moreOrLessEquals((barTop + legendBottom) / 2, epsilon: 2), reason: 'over the bar');
      final header = tester.getRect(inBox(find.text(s.todayCardsInRun)));
      final hanko = tester.getRect(find.ancestor(of: inBox(find.text('本日完了')), matching: find.byType(Transform)).first);
      final tilt = hanko.width / 2 * math.sin(-TodayBoxLayout.doneStampTurn * math.pi / 180);
      expect(hanko.top - tilt, greaterThan(header.bottom), reason: 'clear of the header');
      for (final label in [s.todayDone, s.todayMisses, s.todayNoReviews]) {
        expect(inBox(find.text(label)), findsNothing, reason: 'no legend under the hanko: $label');
      }
      expect(balloon(tester), s.heroKeepGoing);
      expectNarration(tester, s.todayDoneExtra, p.trainer.config.sessionLength);
      expectBoxFits(tester, usersPhone, 'done');
    });

    testWidgets('week stamps: a check for each done day, dashed for the day missed, today ringed', (tester) async {
      for (final day in [_Day.morning, _Day.done]) {
        final p = await player(tester, day);
        await showHome(tester, p, usersPhone);
        const s = S('en');
        final week = tester.widget<TodayBox>(find.byType(TodayBox)).week;
        final today = day == _Day.done ? 'v' : 'o';
        expect([for (final w in week) w.done ? 'v' : (w.missed ? 'x' : (w.today ? 'o' : '-'))].join(), '-vxvvv$today');
        expect(inBox(find.byWidgetPredicate((w) => w is VectorArtBox && w.art == IconArt.check)),
            findsNWidgets(week.where((w) => w.done).length));
        expect(inBox(find.byType(DashedBox)), findsOneWidget);
        final todayLetter = tester.widget<Text>(inBox(find.text(s.weekdayLetter(week.last.date.weekday))).last);
        expect(todayLetter.style!.color, Palette.pinkDeep);
        expect(week.last.date.weekday, p.dayAt().date.weekday);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('new cards paused: no yellow part, and the legend says so', (tester) async {
      final p = await player(tester, _Day.paused);
      await showHome(tester, p, usersPhone);
      const s = S('en');
      final set = p.todaySet()!;
      expect((set.newPaused, set.newCards), (true, 0));
      expect(segments(tester), isNot(contains(Palette.sun)));
      expect(inBox(find.text(s.todayNewPaused)), findsOneWidget);
      expect(find.text(s.pauseYes), findsNothing, reason: 'already asked');
      expectBoxFits(tester, usersPhone, 'paused');
    });
  });

  group('the pause sheet', () {
    for (final lang in ['en', 'ja']) {
      testWidgets('shows once on a big day, and yes takes the new cards out ($lang)', (tester) async {
        final p = await player(tester, _Day.big, lang: lang);
        final s = S(lang);
        final reviews = p.todaySet()!.reviews;
        expect(p.pauseOffered(), isTrue);
        expect(p.todaySet()!.newCards, isPositive);
        await showHome(tester, p, usersPhone);
        await tester.pump(Motion.sheet);
        expect(find.text(s.pauseTitle(reviews)), findsOneWidget);
        // The other language shows under it in Japanese mode only.
        final other = s.ja ? findsOneWidget : findsNothing;
        expect(find.text(s.other.pauseTitle(reviews)), other, reason: 'the other language under it');
        expect(find.text(s.other.pauseYes), other);
        expectSheetFits(tester, s, usersPhone, lang);
        await tester.runAsync(() => tester.tap(find.text(s.pauseYes)));
        await settle(tester);
        expect(find.text(s.pauseTitle(reviews)), findsNothing);
        final set = p.todaySet()!;
        expect((set.newPaused, set.newCards, set.pauseAsked), (true, 0, true));
        expect(inBox(find.text(s.todayNewPaused)), findsOneWidget);
        expect(p.pauseOffered(), isFalse);

        await tester.pumpWidget(const SizedBox());
        await showHome(tester, p, usersPhone);
        await tester.pump(Motion.sheet);
        expect(find.text(s.pauseTitle(reviews)), findsNothing, reason: 'asked once a day');
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('keep keeps the new cards, and it is not asked again', (tester) async {
      final p = await player(tester, _Day.big);
      const s = S('en');
      final fresh = p.todaySet()!.newCards;
      await showHome(tester, p, usersPhone);
      await tester.pump(Motion.sheet);
      await tester.runAsync(() => tester.tap(find.text(s.pauseNo)));
      await settle(tester);
      expect(find.text(s.pauseNo), findsNothing);
      final set = p.todaySet()!;
      expect((set.newPaused, set.newCards, set.pauseAsked), (false, fresh, true));
      expect(p.pauseOffered(), isFalse);
    });

    testWidgets('not while the tour is on', (tester) async {
      final p = await player(tester, _Day.big);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(toured: false)));
      await showHome(tester, p, usersPhone);
      await tester.pump(Motion.sheet);
      expect(find.text(const S('en').pauseYes), findsNothing);
      expect(p.pauseOffered(), isTrue);
    });
  });

  testWidgets('a stale day: Home builds the new set', (tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true, onboarded: true));
    });
    expect(p.todayStale, isTrue);
    await showHome(tester, p, usersPhone);
    await settle(tester);
    expect(p.todayStale, isFalse);
    final set = p.todaySet()!;
    expect(inBox(find.text('${set.bar.total}')), findsOneWidget);
  });

  group('fits', () {
    for (final lang in ['en', 'ja']) {
      for (final day in _Day.values) {
        testWidgets('${day.name} ($lang) on every phone and font scale', (tester) async {
          final p = await player(tester, day, lang: lang);
          final s = S(lang);
          if (day == _Day.big || day == _Day.paused) {
            expect(p.todaySet()!.bar.total, greaterThanOrEqualTo(100), reason: 'a three-digit day');
          }
          for (final phone in [narrowPhone, usersPhone, widePhone]) {
            for (final fontScale in [1.0, 1.3]) {
              final why = '${day.name} ${phone.name} $lang $fontScale';
              await showHome(tester, p, phone, fontScale: fontScale);
              expectBoxFits(tester, phone, why);
              expectHeroFits(tester, why);
              if (day == _Day.big) {
                await tester.pump(Motion.sheet);
                expectSheetFits(tester, s, phone, why);
              }
              await tester.pumpWidget(const SizedBox());
            }
          }
        });
      }
    }
  });

  group('renders', skip: !renderScreens, () {
    for (final lang in ['en', 'ja']) {
      for (final (phone, fontScale) in [(usersPhone, 1.0), (narrowPhone, 1.3)]) {
        testWidgets('home_${phone.name}_${lang}_$fontScale', (tester) async {
          for (final day in _Day.values) {
            final p = await player(tester, day, lang: lang);
            await showHome(tester, p, phone, fontScale: fontScale);
            if (day == _Day.big) await tester.pump(Motion.sheet);
            await captureScreen(tester, 'daily_set/${day == _Day.big ? 'pause_sheet' : 'home_${day.name}'}', lang: lang);
            await tester.pumpWidget(const SizedBox());
          }
        });
      }
    }
  });
}
