// The run summary of every kind of game, from games played through the real
// progress: each lays out on the user's phone with no layout error and
// shows what it is about. With RENDER_SCREENS=1 each is also written to
// build/screens/ as results_redo_NN_<kind>.
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/exam_strings.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/summary_strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/side_trips.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_results_screen.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/exam/exam_lost_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/time_format.dart';
import 'package:fudatobashi/ui/results/results_screen.dart';
import 'package:fudatobashi/ui/results/run_summary.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';
import 'package:fudatobashi/ui/torifuda/glyph_atlas.dart';

import 'test_ankiren.dart';
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

const _training = PlayConfig(mode: PlayMode.training);
const _ranked = PlayConfig(mode: PlayMode.ranked);
const _exam = PlayConfig(mode: PlayMode.exam);

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
    if (renderScreens) await GlyphAtlas.load();
    await CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
  });

  // A player in [mode] who has taken the tour.
  Future<Progress> player(WidgetTester tester, {LearningMode mode = LearningMode.journey, String lang = 'en'}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
      await p.setLearningMode(mode);
    });
    p.trainer.fuzzing = false;
    return p;
  }

  // Plays [cards] the way the play screen does, [ms] a card (and [slowMs]
  // for those [slow] picks), missing the swipes at [missAt], and leaving
  // after [stopAfter] swipes when given.
  PlaySession play(List<CardRef> cards,
      {RunPlanner? planner,
      int ms = 900,
      Set<int> missAt = const {},
      int? stopAfter,
      bool Function(CardRef card)? slow,
      int slowMs = 2500,
      DateTime? at}) {
    final session = PlaySession(cards, planner: planner);
    var t = const Duration(seconds: 100);
    while (!session.finished && (stopAfter == null || session.swipes.length < stopAfter)) {
      final card = session.current!;
      session.revealed(t);
      t += Duration(milliseconds: (slow?.call(card) ?? false) ? slowMs : ms + session.swipes.length % 7 * 40);
      final miss = missAt.contains(session.swipes.length);
      session.commit(responseTs: t, commitTs: t, outcome: miss ? Outcome.dontKnow : Outcome.known, at: at);
      t += const Duration(milliseconds: 100);
    }
    return session;
  }

  Future<SessionReport> record(WidgetTester tester, Progress p, PlaySession session, PlayConfig config,
      {Duration? tobi, DateTime? at}) async {
    late SessionReport report;
    await tester.runAsync(
        () async => report = await p.recordRun(session, config, at ?? DateTime.now(), now: at, tobi: tobi));
    return report;
  }

  Future<PlannedRun> plan(WidgetTester tester, Progress p) async {
    late PlannedRun run;
    await tester.runAsync(() async => run = await p.planTraining(rng: math.Random(1)));
    return run;
  }

  // Shows [screen] on the user's phone as its summary first appears, before
  // any celebration comes in over it.
  Future<void> show(WidgetTester tester, Progress p, Widget screen, String name) async {
    useScreen(tester, usersPhone);
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMangaTheme(),
          builder: withUiFont,
          home: screen,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byType(RunSummary), findsOneWidget);
    await captureScreen(tester, name, lang: p.settings.language);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  group('Training', () {
    testWidgets('01: a run of today\'s set, with more of the set to go', (tester) async {
      final p = await player(tester);
      final first = await plan(tester, p);
      await record(tester, p, play(first.cards, planner: first.planner, stopAfter: first.cards.length ~/ 3), _training);
      final second = await plan(tester, p);
      final report = await record(
          tester, p, play(second.cards, planner: second.planner, stopAfter: second.cards.length ~/ 3, missAt: {2, 5}), _training);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: _training), 'results_redo_01_training_set_left');
      expect(find.text(s.summaryTodaysSet), findsOneWidget);
      expect(find.text(s.summaryCardsLeft(2)), findsOneWidget);
      expect(find.text(s.summaryMissed), findsOneWidget);
      await close(tester);
    });

    testWidgets('02: the run that finishes the set', (tester) async {
      final p = await player(tester);
      final run = await plan(tester, p);
      final report = await record(tester, p, play(run.cards, planner: run.planner), _training);
      expect(report.dayDone, isNotNull);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: _training), 'results_redo_02_training_done');
      expect(find.text(s.summaryDone), findsWidgets);
      expect(find.text(s.summaryNewToday), findsOneWidget);
      expect(find.text(s.summaryStreak), findsOneWidget);
      await close(tester);
    });

    testWidgets('03: early in the day, in Japanese', (tester) async {
      final p = await player(tester, lang: 'ja');
      final run = await plan(tester, p);
      final report =
          await record(tester, p, play(run.cards, planner: run.planner, stopAfter: run.cards.length ~/ 5, missAt: {3}), _training);
      await show(tester, p, ResultsScreen(report: report, config: _training), 'results_redo_03_training');
      expect(find.text(const S('ja').summaryTodaysSet), findsOneWidget);
      await close(tester);
    });

    testWidgets('04: free play, beside today\'s set', (tester) async {
      final p = await player(tester);
      final run = await plan(tester, p);
      await record(tester, p, play(run.cards, planner: run.planner, stopAfter: run.cards.length ~/ 4), _training);
      final known = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds].take(30);
      for (final id in known) {
        p.trainer.items[ItemKey(id, false)]!.unlocked = true;
      }
      final config = const FreePracticeSetup().config;
      final report = await record(tester, p, play([for (final id in known) CardRef(id)], missAt: {4, 19}), config);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: config), 'results_redo_04_free_play');
      expect(find.text(s.summaryThisRun), findsOneWidget);
      expect(find.text(s.summaryTodayLabel), findsOneWidget);
      await close(tester);
    });
  });

  group('Other practice', () {
    // A player who knows every card, the first [slow] of them [slowMs] a card.
    Future<Progress> knowsAll(WidgetTester tester, {required int slow, int slowMs = 2500}) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await record(tester, p,
          play([for (final q in poems.all) CardRef(q.id)], slow: (c) => c.poemId <= slow, slowMs: slowMs, ms: 800), _ranked);
      return p;
    }

    testWidgets('05: weak cards, some still to drill', (tester) async {
      final p = await knowsAll(tester, slow: 7, slowMs: 1550);
      final drill = p.weakDrill(rng: math.Random(5));
      var n = 0;
      final session = play(drill.cards, planner: drill.planner, ms: 500, slow: (_) => n++ % 3 == 0, slowMs: 1600);
      final report = await record(tester, p, session, drill.config);
      final before = report.weakBefore!, left = report.weakAfter!;
      expect(report.weakSidesBefore!.containsAll(report.weakSidesAfter!), isTrue, reason: 'no card turned weak');
      expect([before, left], [7, 4]);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: drill.config), 'results_redo_05_weak_left');
      expect(find.text(s.weakLeftLabel), findsOneWidget);
      expect(find.text(s.summaryWeakLeft(left)), findsOneWidget);
      expect(find.text(s.weakLeftWas(before)), findsOneWidget);
      expect(find.text(s.summaryCleared(before - left)), findsOneWidget);
      expect(find.text(s.summaryStillWeak(left)), findsOneWidget);
      await close(tester);
    });

    testWidgets('06: weak cards, none left', (tester) async {
      final p = await knowsAll(tester, slow: 5);
      final drill = p.weakDrill(rng: math.Random(6));
      final played = await record(tester, p, play(drill.cards, planner: drill.planner, ms: 450), drill.config);
      // Speed moves slowly over many swipes; this is the drill that clears the last of them.
      final report = SessionReport(
        runId: played.runId,
        completed: true,
        total: played.total,
        attempts: played.attempts,
        previousBest: null,
        ratingBefore: null,
        ratingAfter: null,
        goalRaised: false,
        xp: played.xp,
        mode: PlayMode.nigate,
        weakSidesBefore: played.weakSidesBefore,
        weakSidesAfter: const {},
      );
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: drill.config), 'results_redo_06_weak_cleared');
      expect(find.text(s.summaryClear), findsWidgets);
      expect(find.text(s.summaryNoWeakLeft), findsOneWidget);
      await close(tester);
    });

    testWidgets('07: practice in all-known mode', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      final config = const FreePracticeSetup().config;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final due = [for (var id = 91; id <= 98; id++) CardRef(id)];
      await record(tester, p, play(due, at: yesterday), config, at: yesterday);
      for (final card in due) {
        p.trainer.items[ItemKey(card.poemId, false)]!.card.due = yesterday;
      }
      final today = [for (var id = 1; id <= 50; id++) CardRef(id, inverted: id % 3 == 0)];
      final report = await record(tester, p, play(today, missAt: {7, 30}), config);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: config), 'results_redo_07_all_known');
      expect(find.text(s.summaryDueToday), findsOneWidget);
      await close(tester);
    });
  });

  group('Timed', () {
    List<CardRef> all() => [for (final q in poems.all) CardRef(q.id, inverted: q.id.isEven)];

    testWidgets('08 and 09: the first ranked run places the rating; the next moves it', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      final placement = await record(tester, p, play(all(), ms: 2400, missAt: {12, 61}), _ranked);
      expect(placement.placement, isTrue);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: placement, config: _ranked), 'results_redo_09_placement');
      expect(find.text(s.summaryPlacement), findsOneWidget);
      expect(find.text(s.rankedScoredTime.toUpperCase()), findsOneWidget);
      await close(tester);
      final again = await record(tester, p, play(all(), ms: 2100, missAt: {40, 88}), _ranked);
      await show(tester, p, ResultsScreen(report: again, config: _ranked), 'results_redo_08_ranked');
      expect(find.text(s.summaryRanked), findsOneWidget);
      expect(find.text(s.summaryRatingUp), findsOneWidget);
      await close(tester);
    });

    testWidgets('10: a ranked run left early', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await record(tester, p, play(all(), ms: 2000), _ranked);
      final report = await record(tester, p, play(all(), ms: 2300, missAt: {9, 20, 31}, stopAfter: 37), _ranked);
      expect(report.forfeit, isTrue);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: _ranked), 'results_redo_10_forfeit');
      expect(find.text(s.historyForfeit), findsOneWidget);
      expect(find.text(s.summaryCountsAsZero), findsOneWidget);
      await close(tester);
    });

    testWidgets('11: the exam passed', (tester) async {
      final p = await player(tester);
      final report = await record(tester, p, play(all(), ms: 2850, missAt: {50}), _exam, tobi: const Duration(minutes: 5, seconds: 23));
      expect(report.passed, isTrue);
      const s = S('en');
      await show(tester, p, ResultsScreen(report: report, config: _exam), 'results_redo_11_exam_passed');
      expect(find.text(s.summaryPassed), findsWidgets);
      await close(tester);
    });

    testWidgets('12: the exam lost', (tester) async {
      final p = await player(tester);
      await tester.runAsync(() => p.noteExamStarted(DateTime.now()));
      final report =
          await record(tester, p, play(all(), ms: 3200, missAt: {20, 70}), _exam, tobi: const Duration(minutes: 5, seconds: 23));
      expect(report.passed, isFalse);
      const s = S('en');
      await show(tester, p, ExamLostScreen(report: report, config: _exam), 'results_redo_12_exam_lost');
      expect(find.text(s.examLostTitle), findsOneWidget);
      expect(find.text(s.summaryNextTryLabel), findsOneWidget);
      expect(find.textContaining(RegExp(r'^5\d:\d\d$')), findsOneWidget, reason: 'the hour counting down');
      await close(tester);
    });
  });

  group('AnkiRen', () {
    Future<AnkirenReport> recordGame(WidgetTester tester, Progress p, AnkirenGame game) async {
      late AnkirenReport report;
      await tester.runAsync(() async => report = await p.recordAnkiren(game, startedAt: DateTime.now()));
      return report;
    }

    Future<void> clearUpTo(WidgetTester tester, Progress p, int level) async {
      for (var l = 0; l < level; l++) {
        await recordGame(tester, p, playAnkiren(AnkirenSetup.forLevel(l), strikes: true));
      }
    }

    testWidgets('13: a ranked game', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      for (var i = 0; i < 3; i++) {
        await recordGame(tester, p, playAnkiren(const AnkirenSetup.ranked(), ms: 1400, seed: i));
      }
      final game = playAnkiren(const AnkirenSetup.ranked(),
          ms: 900, seed: 7, wrongAt: {4, 15}, giveUpAt: {30}, memorised: const Duration(minutes: 9));
      final report = await recordGame(tester, p, game);
      final score = game.score!;
      expect(score.early, greaterThan(0));
      const s = S('en');
      await show(tester, p, AnkirenResultsScreen(game: game, report: report, player: AnkirenPlayer.owner),
          'results_redo_13_ankiren_ranked');
      expect(find.text(s.ankirenScoreLabel), findsOneWidget);
      expect(find.text(s.ankirenScoreOf(groupDigits(11250))), findsOneWidget, reason: '50 cards × 150 points × 1.5');
      expect(find.text(s.summaryEarly(groupDigits(score.early))), findsOneWidget);
      await close(tester);
    });

    testWidgets('14: a free level cleared', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await clearUpTo(tester, p, 3);
      final game = playAnkiren(AnkirenSetup.forLevel(3), strikes: true, wrongAt: {2}, giveUpAt: {6});
      final report = await recordGame(tester, p, game);
      expect(game.cleared, isTrue);
      const s = S('en');
      await show(tester, p, AnkirenResultsScreen(game: game, report: report, player: AnkirenPlayer.owner),
          'results_redo_14_ankiren_cleared');
      expect(find.text(s.summaryClear), findsWidgets);
      expect(find.text(s.summaryLevels), findsOneWidget);
      await close(tester);
    });

    testWidgets('15: a free level failed', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await clearUpTo(tester, p, 3);
      final game = playAnkiren(AnkirenSetup.forLevel(3), strikes: true, wrongAt: {1, 4, 7}, giveUpAt: {9, 11});
      final report = await recordGame(tester, p, game);
      expect([game.completed, game.cleared], [true, false]);
      const s = S('en');
      await show(tester, p, AnkirenResultsScreen(game: game, report: report, player: AnkirenPlayer.owner),
          'results_redo_15_ankiren_failed');
      expect(find.text(s.summaryFailed), findsOneWidget);
      expect(find.text(s.summaryNotFirstTap), findsOneWidget);
      await close(tester);
    });

    testWidgets('16: a guest\'s game', (tester) async {
      final p = await player(tester);
      final game = playAnkiren(AnkirenSetup.forLevel(0));
      const s = S('en');
      await show(tester, p, AnkirenResultsScreen(game: game, report: null, player: AnkirenPlayer.guest),
          'results_redo_16_ankiren_guest');
      expect(find.text(s.untrackedTag), findsOneWidget);
      expect(find.textContaining(s.ankirenGuestNote, findRichText: true), findsOneWidget);
      await close(tester);
    });
  });

  test('the focus lines keep off the box they are told to keep clear', () {
    const spec = SummaryHeroLayout.burst;
    final path = FocusLines.path(spec, spec.box);
    final clear = spec.clear!.deflate(6);
    for (var x = clear.left; x < clear.right; x += 2) {
      for (var y = clear.top; y < clear.bottom; y += 2) {
        expect(path.contains(Offset(x, y)), isFalse, reason: '($x, $y)');
      }
    }
  });
}
