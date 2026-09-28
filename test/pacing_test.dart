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
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/synthetic_learner.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/journey_simulator.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

/// Upright cards unlocked at the end of each simulated day, and the island
/// events the run reports announced.
class Journey {
  final unlockedByDay = <int>[];

  /// Share of the unlocked cards solid after the last day.
  late double solidAtEnd;
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

  /// [days] of [learner] playing [roundsPerDay] rounds a day (by default the
  /// routine [pace] is built for).
  Future<Journey> simulate(
    LearningPace pace, {
    LearnerKind learner = LearnerKind.average,
    int? roundsPerDay,
    required int days,
    required int seed,
  }) async {
    final progress = await open(pace, seed);
    final journey = Journey();
    final sim = JourneySimulator(
      progress,
      seed: seed,
      learner: learner,
      onReport: (r) {
        journey.reached.addAll(r.islandsReached);
        journey.completed.addAll(r.islandsCompleted);
      },
    );
    for (var d = 0; d < days; d++) {
      await sim.day(DateTime(2026, 9, 1 + d), rounds: roundsPerDay ?? pace.profile.dailyRounds);
      journey.unlockedByDay.add(uprightUnlocked(progress));
    }
    journey.solidAtEnd = progress.readiness.solidFraction;
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
          final j = await simulate(LearningPace.month, days: 30, seed: seed);
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

      test('sprint pace, 6 rounds of 30 a day: all by day 15-16 (seed $seed)', () async {
        final j = await simulate(LearningPace.sprint, days: 16, seed: seed);
        expect(j.daysToAll, inInclusiveRange(15, 16), reason: '${j.unlockedByDay}');
      }, timeout: const Timeout(Duration(minutes: 2)));
    }

    // The goal is flexible: a capable player on the pace's routine gets there
    // in time, one who keeps forgetting is held back until their cards are
    // solid instead of being flooded with new ones.
    for (final pace in LearningPace.values) {
      final days = pace.profile.daysToAll;
      test('a quick learner on the $pace routine reaches all 100 in time', () async {
        final j = await simulate(pace, learner: LearnerKind.quick, days: days + 2, seed: 1);
        expect(j.daysToAll, inInclusiveRange(days, days + 1), reason: '${j.unlockedByDay}');
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('a slow, forgetful learner on the $pace routine is held back, not flooded', () async {
        final j = await simulate(pace, learner: LearnerKind.slow, days: days, seed: 1);
        expect(j.after(days), inInclusiveRange(30, 75), reason: '${j.unlockedByDay}');
        expect(j.solidAtEnd, greaterThanOrEqualTo(0.6), reason: 'most of what they have is solid');
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
  group("Home's Learn next (learn ahead)", () {
    /// A training round at [at] answering each of [ids] [times] times,
    /// correctly and fast, or [miss]ing them all.
    Future<void> drill(Progress p, Iterable<int> ids, DateTime at,
        {int times = StatsTuning.solidMinTimed, bool miss = false}) async {
      final session = PlaySession([for (var i = 0; i < times; i++) ...ids.map(CardRef.new)]);
      var t = Duration.zero;
      while (!session.finished) {
        session.revealed(t);
        t += const Duration(milliseconds: 900);
        session.commit(
            responseTs: t, commitTs: t, outcome: miss ? Outcome.dontKnow : Outcome.known, at: at);
      }
      await p.recordRun(session, const PlayConfig(mode: PlayMode.training), at, now: at);
    }

    List<int> unlockedIds(Progress p) => [for (final s in p.trainer.unlocked) if (!s.key.inverted) s.key.poemId];

    /// Drills every unlocked card at [at] until all are well remembered; each
    /// round's report brings in the next batch while the pace is behind.
    Future<void> learnAll(Progress p, DateTime at) async {
      for (var round = 0; p.learnAhead(at).lock == LearnAheadLock.shaky; round++) {
        expect(round, lessThan(10));
        await drill(p, unlockedIds(p), at);
      }
    }

    test('opens only once every card is well remembered and the pace has no new cards left today', () async {
      final progress = await open(LearningPace.month, 1);
      final day0 = DateTime(2026, 9, 1, 9);
      await progress.planTraining(now: day0);
      expect(progress.learnAhead(day0).lock, LearnAheadLock.shaky, reason: 'the first batch is not learned yet');

      await learnAll(progress, day0);
      expect(progress.paceStatus(day0).hold, UnlockHold.aheadOfPace, reason: "today's new cards came on their own");
      final ahead = progress.learnAhead(day0);
      expect(ahead.lock, LearnAheadLock.none);
      expect(ahead.shaky, 0);
      expect(progress.learnAhead(day0.add(const Duration(days: 1))).lock, LearnAheadLock.newCardsPending,
          reason: "tomorrow's new cards come first");

      final before = uprightUnlocked(progress);
      final pulled = await progress.learnNextCards(now: day0);
      expect(pulled.unlockedBefore, isNotEmpty);
      expect(uprightUnlocked(progress), before + pulled.unlockedBefore.length);
      expect(progress.learnAhead(day0).lock, LearnAheadLock.shaky, reason: 'the pulled batch is new');
      await progress.db.close();
    });

    test('a fresh miss or a due review locks it again', () async {
      final progress = await open(LearningPace.month, 1);
      final day0 = DateTime(2026, 9, 1, 9);
      await progress.planTraining(now: day0);
      await learnAll(progress, day0);
      expect(progress.learnAhead(day0).open, isTrue);
      expect(progress.learnAhead(day0.add(const Duration(days: 30))).lock, LearnAheadLock.shaky,
          reason: 'reviews have fallen due');

      await drill(progress, [unlockedIds(progress).first], day0, times: 1, miss: true);
      final ahead = progress.learnAhead(day0);
      expect(ahead.lock, LearnAheadLock.shaky);
      expect(ahead.shaky, 1);
      await progress.db.close();
    });

    test('has nothing to offer once every card is unlocked', () async {
      final progress = await open(LearningPace.month, 1);
      for (final s in progress.trainer.items.values) {
        s.unlocked = true;
      }
      expect(progress.learnAhead().lock, LearnAheadLock.allUnlocked);
      await progress.db.close();
    });
  });
}
