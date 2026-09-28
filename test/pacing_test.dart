import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/journey_simulator.dart';
import 'package:fudatobashi/state/progress.dart';

/// Upright cards unlocked at the end of each simulated day, and the island
/// events the run reports announced.
class Journey {
  final unlockedByDay = <int>[];
  final reached = <int>{};
  final completed = <int>{};

  /// Unlocked after [days] days of practice.
  int after(int days) => unlockedByDay[days - 1];

  /// Days of practice until every card was unlocked, or null.
  int? get daysToAll {
    final i = unlockedByDay.indexOf(100);
    return i < 0 ? null : i + 1;
  }
}

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Progress> open(LearningPace pace, int seed) async {
    final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await progress.updateTrainerConfig(TrainerConfig(pace: pace));
    // FSRS fuzzes intervals with its own unseeded Random.
    progress.trainer.scheduler = fsrs.Scheduler.customRandom(
      math.Random(seed),
      desiredRetention: progress.trainer.config.desiredRetention,
    );
    return progress;
  }

  int uprightUnlocked(Progress p) => p.trainer.unlocked.where((s) => !s.key.inverted).length;

  Future<Journey> simulate(LearningPace pace, {required int roundsPerDay, required int days, required int seed}) async {
    final progress = await open(pace, seed);
    final journey = Journey();
    final sim = JourneySimulator(
      progress,
      seed: seed,
      onReport: (r) {
        journey.reached.addAll(r.islandsReached);
        journey.completed.addAll(r.islandsCompleted);
      },
    );
    for (var d = 0; d < days; d++) {
      await sim.day(DateTime(2026, 9, 1 + d), rounds: roundsPerDay);
      journey.unlockedByDay.add(uprightUnlocked(progress));
    }
    await progress.db.close();
    return journey;
  }

  group('pace curve', () {
    test('starts with the first island, is front-loaded and ends on time', () {
      for (final pace in LearningPace.values) {
        final days = pace.profile.daysToAll;
        final curve = [for (var d = 0; d < days; d++) pace.targetUnlocked(d, 100)];
        expect(curve.first, greaterThanOrEqualTo(7), reason: '$pace day 0');
        for (var d = 1; d < days; d++) {
          expect(curve[d], greaterThanOrEqualTo(curve[d - 1]));
        }
        expect(curve[days ~/ 2 - 1], greaterThan(50), reason: '$pace halfway');
        expect(curve.last, 100);
        expect(curve[days - 2], lessThan(100));
      }
    });
  });

  group('simulated learner', () {
    for (final seed in [1, 2, 3]) {
      test(
        'month pace, 3 rounds of 30 a day: ~30 after a week, ~60 after two, all by day 28-30 (seed $seed)',
        () async {
          final j = await simulate(LearningPace.month, roundsPerDay: 3, days: 30, seed: seed);
          expect(j.after(7), inInclusiveRange(25, 35), reason: '${j.unlockedByDay}');
          expect(j.after(14), inInclusiveRange(50, 70), reason: '${j.unlockedByDay}');
          expect(j.daysToAll, inInclusiveRange(28, 30), reason: '${j.unlockedByDay}');
          for (var i = 1; i < j.unlockedByDay.length; i++) {
            expect(j.unlockedByDay[i], greaterThanOrEqualTo(j.unlockedByDay[i - 1]));
          }
          expect(j.reached.length, initialGroups.length);
          expect(j.completed, isNotEmpty);
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      test('sprint pace, 6 rounds of 30 a day: all by day 15-17 (seed $seed)', () async {
        final j = await simulate(LearningPace.sprint, roundsPerDay: 6, days: 17, seed: seed);
        expect(j.daysToAll, inInclusiveRange(15, 17), reason: '${j.unlockedByDay}');
      }, timeout: const Timeout(Duration(minutes: 2)));
    }

    test('sprint pace on a light routine falls behind its curve (readiness holds it back)', () async {
      final j = await simulate(LearningPace.sprint, roundsPerDay: 2, days: 15, seed: 1);
      expect(j.after(15), lessThan(100), reason: '${j.unlockedByDay}');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('learn next cards', () {
    test('unlocks the next batch even when not ready, and the round drills it', () async {
      final progress = await open(LearningPace.month, 1);
      final day0 = DateTime(2026, 9, 1, 9);
      final first = await progress.planTraining(rng: math.Random(1), now: day0);
      expect(first.unlockedBefore.map((k) => poems[k.poemId].kimariji), ['む', 'す', 'め']);
      expect(progress.readiness.ready, isFalse);

      final pulled = await progress.learnNextCards(rng: math.Random(2), now: day0);
      expect(pulled.unlockedBefore.map((k) => poems[k.poemId].kimariji), ['ふ', 'さ', 'ほ']);
      for (final k in pulled.unlockedBefore) {
        expect(pulled.picks.where((p) => p.key == k).length, greaterThanOrEqualTo(TrainingTuning.newCardMinTimed));
      }
      final r = progress.readiness;
      expect(r.shaky, 6);
      expect(r.latestBatch, pulled.unlockedBefore.map((k) => k.poemId));
      expect(r.underPractised.length, 3);
      await progress.db.close();
    });

    test('pulling ahead of the curve pauses auto-unlocks until the curve catches up', () async {
      final progress = await open(LearningPace.month, 1);
      final day0 = DateTime(2026, 9, 1, 9);
      await progress.planTraining(now: day0);
      while (uprightUnlocked(progress) < 20) {
        await progress.learnNextCards(now: day0);
      }
      final status = progress.paceStatus(day0);
      expect(status.hold, UnlockHold.aheadOfPace);
      expect(status.nextPaceDay, greaterThan(0));
      expect((await progress.planTraining(now: day0)).unlockedBefore, isEmpty);
      await progress.db.close();
    });

    test('is not offered in all-known mode', () async {
      final progress = await open(LearningPace.month, 1);
      expect(progress.canLearnMore, isTrue);
      await progress.setLearningMode(LearningMode.allKnown);
      expect(progress.canLearnMore, isFalse);
      await progress.db.close();
    });
  });
}
