import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/run_strings.dart';
import 'package:fudatobashi/l10n/run_tab_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/history/run_overview_tab.dart';
import 'package:fudatobashi/ui/history/run_rating_tab.dart';
import 'package:fudatobashi/ui/history/run_speed_tab.dart';
import 'package:fudatobashi/ui/history/run_xp_tab.dart';
import 'package:fudatobashi/ui/manga/theme.dart';
import 'package:fudatobashi/ui/play/time_format.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

/// The Speed, Rating and XP tabs of History's run page, on real recorded
/// runs of every kind.
void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final render = Platform.environment['RENDER_SCREENS'] == '1';

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('Joka', ['YujiSyuku-Joka.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  final all = [for (final p in poems.all) CardRef(p.id, inverted: p.id % 3 == 0)];

  /// [cards] at times that wander around [ms], a "don't know" at each of
  /// [misses], the first [stopAfter] only when given.
  PlaySession play(DateTime at, List<CardRef> cards, int ms, {Set<int> misses = const {}, int? stopAfter}) {
    final s = PlaySession(cards);
    var t = const Duration(seconds: 100);
    for (var i = 0; i < (stopAfter ?? cards.length); i++) {
      s.revealed(t);
      t += Duration(milliseconds: ms + (i * 7919) % 1100 - 450 + (i ~/ 10 == 6 ? 700 : 0));
      s.commit(
          responseTs: t, commitTs: t, outcome: misses.contains(i) ? Outcome.dontKnow : Outcome.known, at: at.add(t));
      t += const Duration(milliseconds: 120);
    }
    return s;
  }

  final day = DateTime(2026, 10, 1, 9);

  /// Every kind of run, played a day apart, by name.
  Future<(Progress, Map<String, PastRun>)> record(WidgetTester tester, {required bool ja}) async {
    late Progress p;
    final ids = <String, int>{};
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: ja ? 'ja' : 'en', languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.allKnown);
      Future<void> run(String name, PlaySession Function(DateTime at) session, PlayConfig config, int dayN,
          {Duration? tobi}) async {
        final at = day.add(Duration(days: dayN));
        final report = await p.recordRun(session(at), config, at, now: at.add(const Duration(minutes: 5)), tobi: tobi);
        ids[name] = report.runId!;
      }

      await run('training', (at) => play(at, all.take(30).toList(), 1800, misses: {4, 20}),
          const PlayConfig(mode: PlayMode.training), 0);
      await run('free', (at) => play(at, all, 1600, misses: {7, 50}),
          PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: [for (final c in all) c.poemId]), 1);
      await run('exam', (at) => play(at, all, 1500, misses: {3}), const PlayConfig(mode: PlayMode.exam), 2,
          tobi: const Duration(minutes: 5));
      const ranked = PlayConfig(mode: PlayMode.ranked);
      await run('placement', (at) => play(at, all, 2000, misses: {1, 2, 60}), ranked, 3);
      await run('forfeit', (at) => play(at, all, 1900, misses: {5}, stopAfter: 37), ranked, 4);
      await run('ranked', (at) => play(at, all, 1300, misses: {10, 70}), ranked, 5);
    });
    return (p, {for (final r in p.pastRuns) if (ids.entries.where((e) => e.value == r.id).firstOrNull case final e?) e.key: r});
  }

  void onPhone(WidgetTester tester, {required double width, required double fontScale}) {
    const dpr = 2.0;
    tester.view
      ..devicePixelRatio = dpr
      ..physicalSize = Size(width, render ? 2400 : 832) * dpr;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> show(WidgetTester tester, Progress p, Widget tab, String shot) async {
    await tester.pumpWidget(ProgressScope(
      progress: p,
      child: MaterialApp(
          theme: buildMangaTheme(),
          home: RepaintBoundary(key: const ValueKey('screen'), child: Scaffold(body: tab))),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull, reason: shot);
    if (!render) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/screens/run_tabs/$shot.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';
    for (final (width, fontScale) in [(384.0, 1.0), (384.0, 1.3), (360.0, 1.3), (360.0, 1.0)]) {
      final setup = '$lang, ${width.round()} dp, font scale $fontScale';
      final shot = '${lang}_${width.round()}_${(fontScale * 10).round()}';

      testWidgets('the Speed, Rating and XP tabs show every kind of run ($setup)', (tester) async {
        final s = S(lang);
        final (p, runs) = await record(tester, ja: ja);
        onPhone(tester, width: width, fontScale: fontScale);
        Future<RunDetail> detailOf(String name) async =>
            (await tester.runAsync(() => p.loadRunDetail(runs[name]!)))!;

        final ranked = await detailOf('ranked');
        expect(ranked.rating!.before, isNotNull);
        await show(tester, p, RunSpeedTab(ranked), 'speed_ranked_$shot');
        expect(find.textContaining(s.runThirdsTitle, findRichText: true), findsOneWidget);
        expect(find.text(s.runSwipeTimesPenalty(10)), findsOneWidget);
        await show(tester, p, RunRatingTab(ranked), 'rating_ranked_$shot');
        expect(find.text(s.runRatingBefore), findsOneWidget);
        expect(find.text(s.runNewRating), findsOneWidget);
        expect(find.text(s.runSoFar(3)), findsOneWidget);
        expect(find.text(s.runXpTotal), findsOneWidget);

        final placement = await detailOf('placement');
        expect(placement.rating!.before, isNull);
        await show(tester, p, RunRatingTab(placement), 'rating_placement_$shot');
        expect(find.textContaining(s.runPlacementShout), findsOneWidget);
        expect(find.text(s.rankUnplaced), findsOneWidget);

        final forfeit = await detailOf('forfeit');
        expect(forfeit.run.forfeit, isTrue);
        expect(forfeit.rating!.performance, RankedTuning.forfeitPerformance);
        expect(forfeit.run.time, isNull, reason: 'a forfeit has no scored time');
        await show(tester, p, RunRatingTab(forfeit), 'rating_forfeit_$shot');
        expect(find.text(s.runForfeitText(37)), findsOneWidget);
        expect(find.text(s.historyForfeit), findsOneWidget, reason: "the table's scored column");
        expect(find.text('${RankedTuning.forfeitPerformance.round()}'), findsWidgets);
        await show(tester, p, RunOverviewTab(forfeit), 'overview_forfeit_$shot');
        expect(find.text(s.historyForfeit), findsOneWidget, reason: 'in place of the time');
        expect(find.textContaining(s.runClockLine(formatTenths(forfeit.run.clock!), forfeit.run.scoredMisses!)), findsNothing);
        await show(tester, p, RunSpeedTab(forfeit), 'speed_forfeit_$shot');
        expect(find.text(s.runSpeedForfeit(37)), findsOneWidget);

        final free = await detailOf('free');
        expect(free.run.view, RunView.hundred);
        await show(tester, p, RunSpeedTab(free), 'speed_free_$shot');
        expect(find.text(s.runSwipeTimesOnly), findsOneWidget);
        await show(tester, p, RunRatingTab(free), 'rating_free_$shot');
        expect(find.text(s.notForRank), findsOneWidget);
        expect(find.text(s.runFreeNoRank), findsOneWidget);

        final exam = await detailOf('exam');
        expect(exam.run.passed, isTrue);
        await show(tester, p, RunRatingTab(exam), 'rating_exam_$shot');
        expect(find.textContaining(s.runExamWonText), findsOneWidget);

        final training = await detailOf('training');
        expect(training.run.view, RunView.training);
        await show(tester, p, RunXpTab(training), 'xp_training_$shot');
        expect(find.text(s.runTrainingNoRank), findsOneWidget);
        expect(find.byType(XpPanel), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
