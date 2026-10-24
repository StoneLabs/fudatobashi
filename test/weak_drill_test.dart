// 苦手: which sides are weak, how the drill spaces and clears them, when it
// ends, what it grades, the Home badge and its Results.
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/step_plan.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/weak_cards.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/results/results_screen.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
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
    await _loadFont('ZenKaku', ['ZenKakuGothicNew-Bold.ttf', 'ZenKakuGothicNew-Black.ttf']);
  });

  final at = DateTime.utc(2026, 10, 1);
  AttemptRec rec(int ms, {bool miss = false}) =>
      AttemptRec(at: at, us: ms * 1000, miss: miss, clean: true, deckSize: 10, mode: PlayMode.ranked);
  CardStats times(List<int> ms, {bool missLast = false}) =>
      CardStats([for (final t in ms) rec(t), if (missLast) rec(0, miss: true)]);

  group('which sides are weak', () {
    test('slow sides and sides missed lately, worst first; the line follows the usual time', () {
      final stats = {
        for (var id = 1; id <= 20; id++) ItemKey(id, false): times([800, 800, 800]),
        const ItemKey(21, false): times([1500, 1500, 1500]),
        const ItemKey(22, false): times([2500, 2500, 2500]),
        const ItemKey(23, false): times([700, 700], missLast: true),
        const ItemKey(23, true): times([3000]),
        const ItemKey(24, false): CardStats.empty,
      };
      final weak = WeakCards.of(stats);
      expect(weak.usualMs, closeTo(800, 1));
      expect(weak.lineMs, closeTo(800 * WeakTuning.lineRatio, 1));
      expect(weak.sides, [const ItemKey(23, true), const ItemKey(22, false), const ItemKey(23, false), const ItemKey(21, false)]);
      expect(weak.cards, 3, reason: 'both sides of 23 are one card');
      expect(weak.quick.length, 20);
      expect(weak.quick, isNot(contains(const ItemKey(24, false))), reason: 'never played');
    });

    test('a player who knows every card still has weak cards: the slow ones', () {
      final rng = math.Random(1);
      final stats = {
        for (var id = 1; id <= 100; id++) ItemKey(id, false): times([for (var i = 0; i < 5; i++) 600 + rng.nextInt(1400)]),
      };
      expect(stats.values.every((s) => s.missRate() == 0), isTrue);
      expect(WeakCards.of(stats).sides, isNotEmpty);
    });
  });

  group('the drill plan', () {
    const targets = [ItemKey(1, false), ItemKey(2, false), ItemKey(3, false), ItemKey(4, false)];
    StepPlan plan() => StepPlan.forWeak(
          targets: targets,
          lookAlikes: {targets[0]: const ItemKey(10, false)},
          anchors: [for (var id = 20; id < 23; id++) ItemKey(id, false)],
          fillers: [for (var id = 30; id < 42; id++) ItemKey(id, false)],
          knownBefore: {for (var id = 1; id <= 100; id++) id},
          twinsOf: (_) => const [],
        );

    /// Plays [plan] answering with [again] (a miss or a slow answer).
    List<ItemKey> run(StepPlan plan, bool Function(ItemKey key, int look) again) {
      final swipes = <(ItemKey, bool)>[];
      final looks = <ItemKey, int>{};
      while (true) {
        final next = plan.upcoming(swipes);
        if (next.isEmpty || swipes.length > 200) break;
        final key = next.first;
        final look = looks[key] = (looks[key] ?? 0) + 1;
        swipes.add((key, again(key, look)));
      }
      return [for (final s in swipes) s.$1];
    }

    test('it opens with a quick card and puts the look-alike right after its target', () {
      final cards = plan().cards;
      expect(cards.first, const ItemKey(20, false));
      expect(cards.indexOf(const ItemKey(10, false)), cards.indexOf(targets[0]) + 1);
    });

    test('a weak side comes back after a gap, never next', () {
      final order = run(plan(), (k, look) => targets.contains(k) && look < 3);
      for (final t in targets) {
        final at = [for (final (i, k) in order.indexed) if (k == t) i];
        for (var i = 1; i < at.length; i++) {
          expect(at[i] - at[i - 1] - 1, greaterThanOrEqualTo(WeakTuning.gaps.first), reason: '$t at $at');
        }
      }
    });

    test('two fast answers in a row clear a side; one never fast stops at the most looks', () {
      final order = run(plan(), (k, _) => k == targets[1]);
      int looks(ItemKey k) => order.where((x) => x == k).length;
      expect(looks(targets[0]), WeakTuning.clearLooks);
      expect(looks(targets[1]), WeakTuning.maxLooks);
      expect(order.where((k) => k.poemId >= 30).toSet().length, order.where((k) => k.poemId >= 30).length,
          reason: 'each filler once');
    });

    test('cleared means the last looks were fast in a row', () {
      expect(WeakCards.cleared([false, true, true]), isTrue);
      expect(WeakCards.cleared([true, false]), isFalse);
      expect(WeakCards.cleared([true]), isFalse);
    });
  });

  group('a drill in the app', () {
    Future<Progress> allKnown({required int slow}) async {
      final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.setLearningMode(LearningMode.allKnown);
      final session = PlaySession([for (final q in poems.all) CardRef(q.id)]);
      var t = const Duration(seconds: 100);
      for (final q in poems.all) {
        session.revealed(t);
        t += Duration(milliseconds: q.id <= slow ? 2500 : 800);
        session.commit(responseTs: t, commitTs: t, outcome: Outcome.known);
      }
      await p.recordRun(session, const PlayConfig(mode: PlayMode.ranked), DateTime.now());
      return p;
    }

    /// Plays [drill] to its end, answering every card with [answer]
    /// (null: a miss).
    Future<SessionReport> play(Progress p, ({List<CardRef> cards, PlayConfig config, RunPlanner planner}) drill,
        int? Function(CardRef card) answer) {
      final session = PlaySession(drill.cards, planner: drill.planner);
      var t = const Duration(seconds: 100);
      while (!session.finished) {
        final ms = answer(session.current!);
        session.revealed(t);
        t += Duration(milliseconds: ms ?? 900);
        session.commit(responseTs: t, commitTs: t, outcome: ms == null ? Outcome.dontKnow : Outcome.known);
      }
      return p.recordRun(session, drill.config, DateTime.now());
    }

    test('the badge counts the cards of the drill\'s pool', () async {
      final p = await allKnown(slow: 12);
      expect(p.weakCards.cards, 12);
      final drill = p.weakDrill(rng: math.Random(2));
      expect(drill.config.targets.length, WeakTuning.targets);
      expect([for (final id in drill.config.targets) ItemKey.fromId(id).poemId].every((id) => id <= 12), isTrue);
      expect(drill.config.goalMs, closeTo(800 * WeakTuning.lineRatio, 1));
    });

    test('it ends after the most swipes when nothing is ever answered right', () async {
      final p = await allKnown(slow: 30);
      final report = await play(p, p.weakDrill(rng: math.Random(3)), (_) => null);
      expect(report.attempts.length, WeakTuning.maxSwipes);
    });

    test('only misses grade FSRS: a correct answer on a due card is no review', () async {
      final p = await allKnown(slow: 12);
      final later = DateTime.now().add(const Duration(days: 30));
      final due = [for (final id in [1, 2, 3, 4]) ItemKey(id, false)];
      expect(due.every((k) => p.trainer.isDue(k, later)), isTrue);
      final session = PlaySession([for (final k in due) CardRef(k.poemId)]);
      var t = const Duration(seconds: 100);
      for (final (i, _) in due.indexed) {
        session.revealed(t);
        t += const Duration(milliseconds: 700);
        session.commit(responseTs: t, commitTs: t, outcome: i.isEven ? Outcome.known : Outcome.dontKnow, at: later);
      }
      await p.recordRun(session, PlayConfig(mode: PlayMode.nigate, goalMs: 1000, targets: [for (final k in due) k.id]),
          later);
      final grades = [for (final k in due) p.attemptsOf(k).last.grade];
      expect(grades, [null, fsrs.Rating.again.value, null, fsrs.Rating.again.value]);
      expect(p.stats(due[0]).all.length, 2, reason: 'speed statistics take every swipe, as in 修行');
    });

    test('cleared cards earn XP and Results; no personal best', () async {
      final p = await allKnown(slow: 12);
      final drill = p.weakDrill(rng: math.Random(4));
      final report = await play(p, drill, (_) => 500);
      final cleared = WeakCards.drill(
          report.attempts, {for (final id in drill.config.targets) ItemKey.fromId(id)}, drill.config.goalMs!.toDouble());
      expect(cleared.where((s) => s.cleared).length, WeakTuning.targets);
      expect(report.personalBest, isFalse);
      final parts = {for (final x in report.xp!.award.parts) x.source: x};
      expect(parts[XpSource.weakCleared]?.xp, WeakTuning.targets * XpTuning.weakCleared);
      expect(parts.containsKey(XpSource.best), isFalse);
      expect(report.weakBefore, 12);
      expect(report.weakAfter, lessThanOrEqualTo(12), reason: 'speed moves slowly, over many swipes');
    });

    for (final (width, scale) in [(384.0, 1.0), (384.0, 1.3), (360.0, 1.3)]) {
      for (final ja in [false, true]) {
        testWidgets('Results fit (${width.round()} dp, font scale $scale, ${ja ? 'ja' : 'en'})', (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          late Progress p;
          late SessionReport report;
          late PlayConfig config;
          await tester.runAsync(() async {
            p = await allKnown(slow: 12);
            await p.updateSettings(p.settings.copyWith(language: ja ? 'ja' : 'en', languagePicked: true));
            final drill = p.weakDrill(rng: math.Random(5));
            config = drill.config;
            var n = 0;
            report = await play(p, drill, (_) => n++ % 3 == 0 ? null : 500);
          });
          await tester.binding.setSurfaceSize(Size(width, 832));
          await tester.pumpWidget(ProgressScope(progress: p, child: MaterialApp(home: ResultsScreen(report: report, config: config))));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          final s = S(ja ? 'ja' : 'en');
          expect(find.text(s.weakLeftLabel), findsOneWidget);
          expect(find.text(s.weakLeftWas(report.weakBefore!)), report.weakAfter == 0 ? findsNothing : findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
