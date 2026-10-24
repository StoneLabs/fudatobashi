import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/config/vector_art.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/srs_strings.dart';
import 'package:fudatobashi/l10n/stats_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/demo_data.dart';
import 'package:fudatobashi/state/journey_simulator.dart';
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/stats_history.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/history/run_page.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';
import 'package:fudatobashi/ui/home/today_box.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/time_format.dart';
import 'package:fudatobashi/ui/rank/rank_screen.dart';
import 'package:fudatobashi/ui/rank/ranked_runs.dart';
import 'package:fudatobashi/ui/stats/card_detail_screen.dart';
import 'package:fudatobashi/ui/stats/practice_calendar.dart';
import 'package:fudatobashi/ui/stats/srs_details_screen.dart';
import 'package:fudatobashi/ui/stats/srs_screen.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

const _phones = [usersPhone, narrowPhone];

/// The Stats header's links, the rank page, the SRS page with its FSRS
/// details, and the practice calendar from History and Home, after a seeded
/// journey and a seeded all-known player with ranked runs, on two phones at
/// two font scales in both languages.
void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  Future<Progress> seeded(WidgetTester tester, String lang, {required bool ranked, bool play = true}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      if (play) ranked ? await seedRankedDemoData(p, days: 6) : await seedDemoData(p, days: 6);
      if (!play && ranked) await seedRankedDemoData(p, days: 0);
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true, onboarded: true));
      await p.noteExamIntroShown();
    });
    return p;
  }

  Future<void> onPhone(WidgetTester tester, Progress p, Screen phone, double fontScale) async {
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(phone.size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }

  Future<void> back(WidgetTester tester, S s) async {
    await tap(tester, find.bySemanticsLabel(s.back).last);
  }

  // Scrolls the page's list to its end, checking every stretch lays out.
  Future<void> scrollThrough(WidgetTester tester, String name, String lang) async {
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      await captureScreen(tester, 'stats_pages/$name', lang: lang, variant: 'step$i');
      final before = tester.state<ScrollableState>(list).position.pixels;
      await tester.drag(list, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      if (tester.state<ScrollableState>(list).position.pixels == before) break;
    }
  }

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    for (final phone in _phones) {
      for (final fontScale in [1.0, 1.3]) {
        final tag = '${lang}_${phone.name}_$fontScale';

        testWidgets('journey: locked Rank, the SRS page and its FSRS details ($tag)', (tester) async {
          final p = await seeded(tester, lang, ranked: false);
          await onPhone(tester, p, phone, fontScale);
          await tap(tester, find.text(s.stats));
          final rank = find.text(s.rank);
          expect(rank, findsOneWidget);
          expect(find.text(s.srs), findsOneWidget);
          expect(find.byWidgetPredicate((w) => w is MangaIcon && w.art == IconArt.lock), findsWidgets);

          await tap(tester, rank);
          expect(find.byType(RankScreen), findsNothing, reason: 'locked in journey mode');
          expect(find.text(s.rankLockedTitle), findsOneWidget);
          await tester.pump(const Duration(seconds: 4));

          await tap(tester, find.text(s.srs));
          expect(find.byType(SrsScreen), findsOneWidget);
          await scrollThrough(tester, 'srs', lang);

          final button = find.textContaining(s.srsDetailsButton, findRichText: true);
          expect(button, findsOneWidget, reason: 'the last thing on the page');
          expect(find.byType(SrsCardTable), findsNothing);
          await tap(tester, button);
          expect(find.byType(SrsDetailsScreen), findsOneWidget);
          expect(find.byType(SrsCardTable), findsOneWidget);
          expect(find.textContaining(s.srsDetailsTitle, findRichText: true), findsOneWidget);
          expect(find.text('${s.srsColRecall} ▲'), findsOneWidget);
          await captureScreen(tester, 'stats_pages/srs_details', lang: lang);
          await tap(tester, find.text(s.srsColLapses));
          expect(find.text('${s.srsColLapses} ▲'), findsOneWidget);
          await tap(tester, find.text('${s.srsColLapses} ▲'));
          expect(find.text('${s.srsColLapses} ▼'), findsOneWidget);
          await back(tester, s);
          expect(find.byType(SrsDetailsScreen), findsNothing);
          expect(find.byType(SrsScreen), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('journey: the calendar opens from History and from Home ($tag)', (tester) async {
          final p = await seeded(tester, lang, ranked: false);
          await onPhone(tester, p, phone, fontScale);
          final today = p.dayAt().date;
          await tap(tester,
              find.descendant(of: find.byType(TodayBox), matching: find.text(s.weekdayLetter(today.weekday))).first);
          expect(find.byType(PracticeCalendarScreen), findsOneWidget);
          await scrollThrough(tester, 'calendar_journey', lang);
          await back(tester, s);
          expect(find.byType(PracticeCalendarScreen), findsNothing);

          await tap(tester, find.text(s.history));
          await tap(tester, find.text(s.historyStreak(p.activeStreak())));
          expect(find.byType(PracticeCalendarScreen), findsOneWidget);
          Finder title(DateTime m) => find.text(s.monthTitle(m), findRichText: true);
          final thisMonth = DateTime.utc(today.year, today.month);
          final next = DateTime.utc(today.year, today.month + 1);
          expect(title(thisMonth), findsOneWidget);
          expect(title(next), findsOneWidget, reason: 'next month starts below this one');
          expect(tester.getTopLeft(title(next)).dy, greaterThan(tester.getTopLeft(title(thisMonth)).dy));
          final list = find.byType(Scrollable).first;
          for (var i = 0; i < 14; i++) {
            await tester.drag(list, const Offset(0, 600));
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
            if (i == 0) expect(title(DateTime.utc(today.year, today.month - 1)), findsOneWidget);
          }
          expect(title(thisMonth), findsNothing, reason: 'scrolled far above it');
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('all-known: Rank replaces SRS, with history and the calendar from Home ($tag)', (tester) async {
          final p = await seeded(tester, lang, ranked: true);
          expect(p.rankedHistory, isNotEmpty);
          await onPhone(tester, p, phone, fontScale);

          await tap(tester, find.byType(TallyMarks));
          expect(find.byType(PracticeCalendarScreen), findsOneWidget);
          await back(tester, s);

          await tap(tester, find.text(s.stats));
          expect(find.text(s.srs), findsNothing);
          await tap(tester, find.text(s.rank));
          expect(find.byType(RankScreen), findsOneWidget);
          expect(find.byType(RatingChart), p.rankedHistory.length > 1 ? findsOneWidget : findsNothing);
          await captureScreen(tester, 'stats_pages/rank_top', lang: lang);
          await tester.dragUntilVisible(find.text(s.youTag), find.byType(Scrollable).first, const Offset(0, -200));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          await scrollThrough(tester, 'rank', lang);
          expect(find.byType(RankedRunsTable), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    testWidgets('all-known before the first ranked run: no history, no YOU ($lang)', (tester) async {
      final p = await seeded(tester, lang, ranked: true, play: false);
      expect(p.placed, isFalse);
      await onPhone(tester, p, _phones.last, 1.3);
      await tap(tester, find.text(s.stats));
      await tap(tester, find.text(s.rank));
      expect(find.text(s.rankedUnplacedLine), findsOneWidget);
      expect(find.byType(RatingChart), findsNothing);
      expect(find.byType(RankedRunsTable), findsNothing);
      await scrollThrough(tester, 'rank_unplaced', lang);
      expect(find.text(s.youTag), findsNothing);
      expect(find.byType(RankedRunsTable), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('a ranked run row opens its run page', (tester) async {
    final p = await seeded(tester, 'en', ranked: true);
    await onPhone(tester, p, _phones.first, 1);
    const s = S('en');
    await tap(tester, find.text(s.stats));
    await tap(tester, find.text(s.rank));
    await tester.dragUntilVisible(find.byType(RankedRunsTable), find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 500));
    final first = p.rankedHistory.last.$1;
    await tap(tester, find.text(s.shortDate(first.startedAt)).first);
    expect(find.byType(RunPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the stages count every card once per side', (tester) async {
    final p = await seeded(tester, 'en', ranked: false);
    for (final inverted in [false, true]) {
      final stages = [for (final id in p.learningOrder) p.stageOf(ItemKey(id, inverted))];
      expect(stages, hasLength(poems.all.length));
    }
    expect(p.knownOn(p.playedDays()).last, p.knownCount());
  });

  testWidgets('the known chart counts from zero by the end of the day before the first played day', (tester) async {
    final p = await seeded(tester, 'en', ranked: false);
    final played = p.playedDays();
    final days = p.playedDaysFromZero();
    expect(days, [played.first.subtract(const Duration(days: 1)), ...played]);
    expect([p.knownOn(days).first, p.unlockedOn(days).first, p.paceOn(days)!.first], [0, 0, 0]);
    expect(p.knownOn(days).skip(1), p.knownOn(played));
    expect(p.unlockedOn(days).skip(1), p.unlockedOn(played));
  });

  testWidgets('the known chart has no days before play, and two on the first day', (tester) async {
    late Progress p;
    await tester.runAsync(() async => p = await Progress.open(AppDatabase(NativeDatabase.memory())));
    expect(p.playedDaysFromZero(), isEmpty);
    await tester.runAsync(() async {
      final today = p.dayAt().date;
      await JourneySimulator(p, seed: 1).finishSet(DateTime(today.year, today.month, today.day));
    });
    final days = p.playedDaysFromZero();
    expect(days, hasLength(2));
    expect([p.knownOn(days).first, p.unlockedOn(days).first, p.paceOn(days)!.first], [0, 0, 0]);
    expect(p.knownOn(days).last, p.knownCount());
    expect(p.unlockedOn(days).last, greaterThan(0));
  });

  testWidgets('the known chart has no pace in all-known mode', (tester) async {
    final p = await seeded(tester, 'en', ranked: true);
    final days = p.playedDaysFromZero();
    expect(p.paceOn(days), isNull);
    expect([p.knownOn(days).first, p.unlockedOn(days).first], [0, 0]);
  });

  test('a stability under a tenth of a day reads <0.1, not 0.0', () {
    expect([formatStability(0.012), formatStability(0.1), formatStability(7.64)], ['<0.1', '0.1', '7.6']);
  });

  testWidgets("a card missed again and again shows its stability as under a tenth of a day", (tester) async {
    late Progress p;
    await tester.runAsync(() async => p = await Progress.open(AppDatabase(NativeDatabase.memory())));
    const key = ItemKey(87, false);
    final now = DateTime.now().toUtc();
    p.trainer.items[key]!
      ..unlocked = true
      ..card = fsrs.Card(
          cardId: key.id, state: fsrs.State.relearning, step: 0, stability: 0.012, difficulty: 9.7,
          due: now.add(const Duration(minutes: 10)), lastReview: now);
    await tester.binding.setSurfaceSize(const Size(384, 1600));
    await tester.pumpWidget(ProgressScope(progress: p, child: const MaterialApp(home: CardDetailScreen(itemKey: key))));
    await tester.pump(const Duration(milliseconds: 500));
    final stability = find.ancestor(of: find.text(const S('en').stabilityLabel), matching: find.byType(Column)).first;
    expect(find.descendant(of: stability, matching: find.textContaining('<0.1', findRichText: true)), findsOneWidget);
    expect(find.descendant(of: stability, matching: find.textContaining('0.0', findRichText: true)), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
