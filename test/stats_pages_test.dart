import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/stats_history.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/history/run_page.dart';
import 'package:fudatobashi/ui/home/today_box.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/rank/rank_screen.dart';
import 'package:fudatobashi/ui/rank/ranked_runs.dart';
import 'package:fudatobashi/ui/stats/practice_calendar.dart';
import 'package:fudatobashi/ui/stats/srs_screen.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['RENDER_SCREENS'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screens/stats_pages/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

const _phones = [Size(384, 832), Size(360, 780)];

/// The Stats header's links, the rank page, the SRS page with its Pro
/// table, and the practice calendar from History and Home, after a seeded
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

  Future<void> onPhone(WidgetTester tester, Progress p, Size size, double fontScale) async {
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(size);
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
  Future<void> scrollThrough(WidgetTester tester, String name) async {
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 12; i++) {
      await _capture(tester, '${name}_$i');
      final before = tester.state<ScrollableState>(list).position.pixels;
      await tester.drag(list, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      if (tester.state<ScrollableState>(list).position.pixels == before) break;
    }
  }

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    for (final size in _phones) {
      for (final fontScale in [1.0, 1.3]) {
        final tag = '${lang}_${size.width.round()}_$fontScale';

        testWidgets('journey: locked Rank, the SRS page and its Pro table ($tag)', (tester) async {
          final p = await seeded(tester, lang, ranked: false);
          await onPhone(tester, p, size, fontScale);
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
          await scrollThrough(tester, 'srs_$tag');

          await tap(tester, find.text(s.srsPro));
          expect(find.byType(SrsCardTable), findsOneWidget);
          expect(find.text('${s.srsColRecall} ▲'), findsOneWidget);
          await _capture(tester, 'srs_pro_$tag');
          await tap(tester, find.text(s.srsColLapses));
          expect(find.text('${s.srsColLapses} ▲'), findsOneWidget);
          await tap(tester, find.text('${s.srsColLapses} ▲'));
          expect(find.text('${s.srsColLapses} ▼'), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('journey: the calendar opens from History and from Home ($tag)', (tester) async {
          final p = await seeded(tester, lang, ranked: false);
          await onPhone(tester, p, size, fontScale);
          final today = p.dayAt().date;
          await tap(tester,
              find.descendant(of: find.byType(TodayBox), matching: find.text(s.weekdayLetter(today.weekday))).first);
          expect(find.byType(PracticeCalendarScreen), findsOneWidget);
          await scrollThrough(tester, 'calendar_journey_$tag');
          await back(tester, s);
          expect(find.byType(PracticeCalendarScreen), findsNothing);

          await tap(tester, find.text(s.history));
          await tap(tester, find.text(s.historyStreak));
          expect(find.byType(PracticeCalendarScreen), findsOneWidget);
          expect(find.text(s.monthTitle(today), findRichText: true), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('all-known: Rank replaces SRS, with history and the calendar from Home ($tag)', (tester) async {
          final p = await seeded(tester, lang, ranked: true);
          expect(p.rankedHistory, isNotEmpty);
          await onPhone(tester, p, size, fontScale);

          await tap(tester, find.text(s.streakKeep));
          expect(find.byType(PracticeCalendarScreen), findsOneWidget);
          await back(tester, s);

          await tap(tester, find.text(s.stats));
          expect(find.text(s.srs), findsNothing);
          await tap(tester, find.text(s.rank));
          expect(find.byType(RankScreen), findsOneWidget);
          expect(find.byType(RatingChart), p.rankedHistory.length > 1 ? findsOneWidget : findsNothing);
          await _capture(tester, 'rank_top_$tag');
          await tester.dragUntilVisible(find.text(s.youTag), find.byType(Scrollable).first, const Offset(0, -200));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          await scrollThrough(tester, 'rank_$tag');
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
      await scrollThrough(tester, 'rank_unplaced_$lang');
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
}
