// History's run review of every kind of run and 暗記練 game, from games
// played through the real progress: each tab lays out on the user's phone
// with no layout error and shows what it is about. With RENDER_SCREENS=1
// each is also written to build/screens/ as run_review_NN_<what>.
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:fudatobashi/l10n/ankiren_review_strings.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/run_strings.dart';
import 'package:fudatobashi/l10n/run_tab_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/summary_strings.dart';
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/history/ankiren_game_page.dart';
import 'package:fudatobashi/ui/history/run_page.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
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
const _s = S('en');

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
  Future<Progress> player(WidgetTester tester, {LearningMode mode = LearningMode.journey}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true));
      await p.setLearningMode(mode);
    });
    p.trainer.fuzzing = false;
    return p;
  }

  // Plays [cards] the way the play screen does, about [ms] a card (and
  // [slowMs] for those [slow] picks), missing the swipes at [missAt], and
  // leaving after [stopAfter] swipes when given.
  PlaySession play(List<CardRef> cards,
      {RunPlanner? planner,
      int ms = 900,
      int seed = 1,
      Set<int> missAt = const {},
      int? stopAfter,
      bool Function(CardRef card)? slow,
      int slowMs = 2500,
      DateTime? at}) {
    final rng = math.Random(seed);
    final session = PlaySession(cards, planner: planner);
    var t = const Duration(seconds: 100);
    while (!session.finished && (stopAfter == null || session.swipes.length < stopAfter)) {
      final card = session.current!;
      session.revealed(t);
      final base = (slow?.call(card) ?? false) ? slowMs : ms;
      t += Duration(milliseconds: (base * (0.7 + 0.6 * rng.nextDouble())).round());
      final miss = missAt.contains(session.swipes.length);
      session.commit(responseTs: t, commitTs: t, outcome: miss ? Outcome.dontKnow : Outcome.known, at: at);
      t += const Duration(milliseconds: 100);
    }
    return session;
  }

  Future<PastRun> record(WidgetTester tester, Progress p, PlaySession session, PlayConfig config,
      {DateTime? at, Duration? tobi, List<Duration>? tobiLine}) async {
    late int id;
    await tester.runAsync(() async {
      final when = at ?? DateTime.now();
      id = (await p.recordRun(session, config, when, now: when, tobi: tobi, tobiLine: tobiLine)).runId!;
    });
    return p.pastRuns.firstWhere((r) => r.id == id);
  }

  Future<SideTripRun> game(WidgetTester tester, Progress p, AnkirenGame game, DateTime at) async {
    await tester.runAsync(() => p.recordAnkiren(game, startedAt: at));
    return p.ankirenRuns.firstWhere((r) => r.startedAt == at);
  }

  List<CardRef> all({int seed = 0}) =>
      [for (final q in poems.all) CardRef(q.id, inverted: (q.id + seed) % 3 == 0)]..shuffle(math.Random(seed));

  // Opens [page] on the user's phone.
  Future<void> open(WidgetTester tester, Progress p, Widget page) async {
    useScreen(tester, usersPhone);
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMangaTheme(),
          builder: withUiFont,
          home: page,
        ),
      ),
    ));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // Shows the tab labelled [label].
  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // Scrolls the open tab until [text] is [below] the top of the tab.
  Future<void> scrollTo(WidgetTester tester, Finder text, {double below = 30}) async {
    final scrollable = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where((s) => s.position.axis == Axis.vertical && tester.getTopLeft(find.byWidget(s.widget)).dx.abs() < 1)
        .first;
    final top = tester.getTopLeft(find.byWidget(scrollable.widget)).dy;
    final at = tester.getTopLeft(text).dy;
    scrollable.position.jumpTo(scrollable.position.pixels + at - top - below);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> shot(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull, reason: name);
    await captureScreen(tester, 'run_review_$name');
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  group('Practice runs', () {
    testWidgets('01-04: a training run, its Overview, Cards and XP', (tester) async {
      final p = await player(tester);
      final plan = await tester.runAsync(() => p.planTraining(rng: math.Random(1)));
      final run = await record(
          tester, p, play(plan!.cards, planner: plan.planner, stopAfter: 30, missAt: {4, 11, 17}, ms: 1500), _training);
      expect(run.dayDone, isFalse);
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.summaryThisRun), findsOneWidget);
      expect(find.text(_s.runGraphTitle), findsOneWidget);
      expect(find.textContaining(_s.runTotalLine('')), findsNothing, reason: 'practice runs vary in length');
      await shot(tester, '01_training');
      await tab(tester, _s.runTabCards);
      expect(find.text(_s.runSpeedTitle), findsOneWidget);
      expect(find.text(_s.runTrainingNote), findsOneWidget);
      await shot(tester, '03_training_cards');
      await tab(tester, _s.runTabXp);
      expect(find.text(_s.runTrainingNoRank), findsOneWidget);
      await shot(tester, '04_training_xp');
      await close(tester);
    });

    testWidgets("02: the training run that finished the day's set", (tester) async {
      final p = await player(tester);
      final plan = await tester.runAsync(() => p.planTraining(rng: math.Random(1)));
      final run = await record(tester, p, play(plan!.cards, planner: plan.planner, ms: 1300), _training);
      expect(run.dayDone, isTrue);
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.summaryDone), findsWidgets);
      await shot(tester, '02_training_done');
      await close(tester);
    });

    testWidgets('05: free play of fewer than 100 cards', (tester) async {
      final p = await player(tester);
      final plan = await tester.runAsync(() => p.planTraining(rng: math.Random(1)));
      await record(tester, p, play(plan!.cards, planner: plan.planner, stopAfter: 6), _training);
      final known = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds].take(20);
      for (final id in known) {
        p.trainer.items[ItemKey(id, false)]!.unlocked = true;
      }
      final run = await record(tester, p, play([for (final id in known) CardRef(id)], missAt: {6, 15}, ms: 1350),
          const FreePracticeSetup().config);
      expect(run.view, RunView.training);
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.summaryFree), findsOneWidget);
      await shot(tester, '05_free_play');
      await close(tester);
    });

    testWidgets('06: a weak cards drill', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await record(tester, p, play(all(), slow: (c) => c.poemId <= 8, slowMs: 2600, ms: 800), _ranked,
          at: DateTime.now().subtract(const Duration(days: 1)));
      final drill = p.weakDrill(rng: math.Random(5));
      final run = await record(tester, p, play(drill.cards, planner: drill.planner, ms: 1900, missAt: {0, 2}), drill.config);
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.summaryWeak), findsOneWidget);
      await shot(tester, '06_weak');
      await close(tester);
    });
  });

  group('Ranked', () {
    // Five ranked runs, then a forfeit, from Oct 19.
    Future<(Progress, List<PastRun>)> ranked(WidgetTester tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      final runs = <PastRun>[];
      for (final (i, (ms, misses)) in [
        (1050, {8, 57}),
        (1000, {33}),
        (1020, {12, 77}),
        (960, {40}),
        (880, {70}),
      ].indexed) {
        runs.add(await record(tester, p, play(all(seed: i), ms: ms, seed: i, missAt: misses), _ranked,
            at: DateTime(2026, 10, 19 + i, i == 0 ? 20 : 18)));
      }
      runs.add(await record(tester, p, play(all(seed: 9), ms: 900, seed: 9, missAt: {11}, stopAfter: 37), _ranked,
          at: DateTime(2026, 10, 24, 10)));
      return (p, runs);
    }

    testWidgets('07-12: a ranked run, every tab', (tester) async {
      final (p, runs) = await ranked(tester);
      final run = runs[4];
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.runFastestKind.toUpperCase()), findsOneWidget);
      await shot(tester, '07_ranked');
      await tab(tester, _s.runTabCards);
      await shot(tester, '08_hundred_cards');
      await tab(tester, _s.runTabSpeed);
      expect(find.textContaining(_s.runThirdsTitle, findRichText: true), findsOneWidget);
      await shot(tester, '09_speed');
      await scrollTo(tester, find.textContaining(_s.runKimarijiTitle, findRichText: true));
      await shot(tester, '10_speed_scrolled');
      await tab(tester, _s.runTabRating);
      expect(find.text(_s.runSoFar(5)), findsOneWidget);
      await shot(tester, '11_ranked_rating');
      await tab(tester, _s.runTabSwipes);
      await scrollTo(tester, find.text('51'), below: 60);
      await shot(tester, '12_swipes_scrolled');
      await close(tester);
    });

    testWidgets('13-14: the placement run', (tester) async {
      final (p, runs) = await ranked(tester);
      await open(tester, p, RunPage(run: runs[0]));
      expect(find.text(_s.historyPlaced.toUpperCase()), findsOneWidget);
      await shot(tester, '13_placement');
      await tab(tester, _s.runTabRating);
      expect(find.text(_s.rankUnplaced), findsOneWidget);
      await shot(tester, '14_placement_rating');
      await close(tester);
    });

    testWidgets('15-17: a forfeit', (tester) async {
      final (p, runs) = await ranked(tester);
      final run = runs[5];
      expect(run.forfeit, isTrue);
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.historyForfeit), findsOneWidget);
      await shot(tester, '15_forfeit');
      await tab(tester, _s.runTabSpeed);
      expect(find.text(_s.runSpeedForfeit(37)), findsOneWidget);
      await shot(tester, '16_forfeit_speed');
      await tab(tester, _s.runTabRating);
      expect(find.text(_s.runForfeitText(37)), findsOneWidget);
      await shot(tester, '17_forfeit_rating');
      await close(tester);
    });
  });

  testWidgets('18-19: 100-card free play', (tester) async {
    final p = await player(tester, mode: LearningMode.allKnown);
    final config = PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: [for (final q in poems.all) q.id]);
    late PastRun run;
    for (final (i, ms) in [950, 905, 863].indexed) {
      run = await record(tester, p, play(all(seed: i), ms: ms, seed: i, missAt: {3 + 40 * i}), config,
          at: DateTime(2026, 10, 21 + i, 19));
    }
    expect(run.view, RunView.hundred);
    await open(tester, p, RunPage(run: run));
    await shot(tester, '18_free_hundred');
    await tab(tester, _s.runTabRating);
    expect(find.text(_s.runFreeNoRank), findsOneWidget);
    await shot(tester, '19_free_hundred_rating');
    await close(tester);
  });

  group('Exam', () {
    List<Duration> tobiLine(Duration total) => [for (var i = 1; i <= 100; i++) total * i ~/ 100];

    testWidgets('20, 22: the exam won', (tester) async {
      final p = await player(tester);
      const tobi = Duration(minutes: 3, seconds: 38);
      final run = await record(tester, p, play(all(), ms: 1800, missAt: {64}), _exam,
          at: DateTime(2026, 10, 23, 20), tobi: tobi, tobiLine: tobiLine(tobi));
      expect(run.passed, isTrue);
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.runExamWon.toUpperCase()), findsWidgets);
      await shot(tester, '20_exam_won');
      await tab(tester, _s.runTabRating);
      expect(find.text(_s.notForRank), findsOneWidget);
      await shot(tester, '22_exam_rating');
      await close(tester);
    });

    testWidgets('21: the exam lost', (tester) async {
      final p = await player(tester);
      const tobi = Duration(minutes: 3, seconds: 38);
      final run = await record(tester, p, play(all(), ms: 2080, missAt: {23, 81}), _exam,
          at: DateTime(2026, 10, 22, 20), tobi: tobi, tobiLine: tobiLine(tobi));
      expect(run.passed, isFalse);
      await open(tester, p, RunPage(run: run));
      expect(find.text(_s.runExamLost), findsOneWidget);
      await shot(tester, '21_exam_lost');
      await close(tester);
    });
  });

  group('AnkiRen', () {
    testWidgets('23-27: a ranked game, every tab', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      const ranked = AnkirenSetup.ranked();
      await game(tester, p, playAnkiren(ranked, seed: 2, ms: 1200, wrongAt: {0, 2}), DateTime(2026, 10, 20, 11));
      await game(tester, p, playAnkiren(ranked, seed: 3, ms: 1100, wrongAt: {5}), DateTime(2026, 10, 21, 11));
      final run = await game(
          tester,
          p,
          playAnkiren(ranked, seed: 4, ms: 900, wrongAt: {3, 7, 9}, memorised: const Duration(minutes: 14, seconds: 12)),
          DateTime(2026, 10, 22, 11));
      await open(tester, p, AnkirenGamePage(run: run));
      expect(find.text(_s.ankirenMixTitle), findsOneWidget);
      await shot(tester, '23_ankiren_ranked');
      await tab(tester, _s.ankirenTabField);
      await tester.tap(find.text(_s.ankirenStartReview.toUpperCase()).first);
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 9; i++) {
        await tester.tap(find.bySemanticsLabel(_s.ankirenStepNext));
        await tester.pump(const Duration(milliseconds: 300));
      }
      await shot(tester, '24_ankiren_field_step');
      await tab(tester, _s.runTabCards);
      expect(find.text(_s.ankirenFindTitle), findsOneWidget);
      await shot(tester, '25_ankiren_cards');
      await tab(tester, _s.ankirenTabScore);
      expect(find.text(_s.ankirenNewRating), findsOneWidget);
      await shot(tester, '26_ankiren_score');
      await tab(tester, _s.ankirenTabTaps);
      expect(find.text(_s.ankirenTapsTitle), findsOneWidget);
      await shot(tester, '27_ankiren_taps');
      await close(tester);
    });

    testWidgets('28, 31: a free level cleared, its Overview and Field', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await game(tester, p, playAnkiren(AnkirenSetup.forLevel(3), seed: 7, strikes: true, wrongAt: {0, 1, 4}),
          DateTime(2026, 10, 23, 9));
      final run = await game(tester, p, playAnkiren(AnkirenSetup.forLevel(3), seed: 8, strikes: true, wrongAt: {3}),
          DateTime(2026, 10, 24, 9));
      await open(tester, p, AnkirenGamePage(run: run));
      expect(find.text(_s.historyCleared.toUpperCase()), findsOneWidget);
      await shot(tester, '28_ankiren_cleared');
      await tab(tester, _s.ankirenTabField);
      await shot(tester, '31_ankiren_field');
      await close(tester);
    });

    testWidgets('29: a free level failed', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await game(tester, p, playAnkiren(AnkirenSetup.forLevel(4), seed: 7, strikes: true, wrongAt: {2}),
          DateTime(2026, 10, 23, 9));
      final run = await game(tester, p, playAnkiren(AnkirenSetup.forLevel(4), seed: 9, strikes: true, wrongAt: {2, 5, 9}),
          DateTime(2026, 10, 24, 9));
      await open(tester, p, AnkirenGamePage(run: run));
      expect(find.text(_s.historyFailed.toUpperCase()), findsOneWidget);
      await shot(tester, '29_ankiren_failed');
      await close(tester);
    });

    testWidgets('30: a custom game', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      const setup = AnkirenSetup.custom(perSide: 6, memorise: Duration(minutes: 2));
      await game(tester, p, playAnkiren(setup, seed: 5, ms: 1300, wrongAt: {1}), DateTime(2026, 10, 20, 9));
      final run = await game(tester, p,
          playAnkiren(setup, seed: 6, ms: 1100, wrongAt: {2, 6}, memorised: const Duration(minutes: 1, seconds: 44)),
          DateTime(2026, 10, 24, 9));
      await open(tester, p, AnkirenGamePage(run: run));
      expect(find.text(_s.ankirenNotScored.toUpperCase()), findsOneWidget);
      await shot(tester, '30_ankiren_custom');
      await close(tester);
    });
  });
}
