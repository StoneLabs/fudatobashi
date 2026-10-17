import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/synthetic_learner.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/pace_simulation.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

/// A simulated journey, day by day, and where it stood after the last day.
class Journey {
  Journey(this.days, {required this.solidAtEnd, required this.islands});

  final List<SimulatedDay> days;

  /// Share of the unlocked cards solid after the last day.
  final double solidAtEnd;
  final List<IslandProgress> islands;

  /// Upright cards unlocked after [day] days of practice.
  int after(int day) => days[day - 1].unlocked;

  /// Days of practice until every card was unlocked, or null.
  int? get daysToAll {
    final i = days.indexWhere((d) => d.unlocked == d.total);
    return i < 0 ? null : i + 1;
  }

  /// Share of new cards missed the first time they came back on a later day.
  double get newCardsMissedNextTime =>
      days.fold(0, (n, d) => n + d.newCardCheckMisses) / days.fold(0, (n, d) => n + d.newCardChecks);

  /// FSRS reviews (due cards and misses) a day, on average.
  double get reviewsPerDay => days.fold(0, (n, d) => n + d.reviews) / days.length;

  /// The most cards due as a day began.
  int get mostDue => days.fold(0, (n, d) => math.max(n, d.dueAtStart));
}

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Progress> open(LearningPace pace) async {
    final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await progress.updateTrainerConfig(TrainerConfig(pace: pace));
    progress.trainer.fuzzing = false;
    return progress;
  }

  int uprightUnlocked(Progress p) => p.trainer.unlocked.where((s) => !s.key.inverted).length;

  /// [days] of [learner] finishing each day's set, from 1 September.
  Future<Journey> simulate(
    LearningPace pace, {
    LearnerKind learner = LearnerKind.average,
    required int days,
    required int seed,
  }) async {
    final sim = await PaceSimulation.open(
      learner: learner,
      pace: pace,
      seed: seed,
      start: DateTime(2026, 9, 1),
    );
    final played = [for (var d = 0; d < days; d++) await sim.nextDay()];
    final journey = Journey(played, solidAtEnd: sim.progress.readiness.solidFraction, islands: sim.progress.islands);
    await sim.close();
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

  // Pinned to the synthetic learners of `SyntheticLearnerTuning`, which forget
  // within the day, mix up 友札 and slip: the pace's outcomes for believable
  // players.
  group('simulated learner', () {
    for (final seed in [1, 2, 3]) {
      test(
        'month pace, set finished each day: 28-38 after a week, 56-68 after two, all 100 by day 30 (seed $seed)',
        () async {
          final j = await simulate(LearningPace.month, days: 30, seed: seed);
          final unlocked = [for (final d in j.days) d.unlocked];
          expect(j.after(7), inInclusiveRange(28, 38), reason: '$unlocked');
          expect(j.after(14), inInclusiveRange(56, 68), reason: '$unlocked');
          expect(j.after(30), inInclusiveRange(95, 100), reason: '$unlocked');
          for (var i = 1; i < unlocked.length; i++) {
            expect(unlocked[i], greaterThanOrEqualTo(unlocked[i - 1]));
          }
          expect(j.islands.where((i) => i.reached).length, greaterThanOrEqualTo(initialGroups.length - 2));
          expect(j.islands.where((i) => i.complete), isNotEmpty);
          expect(j.newCardsMissedNextTime, inInclusiveRange(0.5, 0.75), reason: 'more than half');
          expect(j.reviewsPerDay, inInclusiveRange(45, 65));
          expect(j.mostDue, lessThanOrEqualTo(40), reason: 'no backlog builds up');
          expect(j.days.every((d) => d.dayDone), isTrue, reason: 'every day plays its set to the end');
        },
        timeout: const Timeout(Duration(minutes: 2)),
      );

      test('sprint pace, set finished each day: all 100 by day 17 (seed $seed)', () async {
        final j = await simulate(LearningPace.sprint, days: 17, seed: seed);
        expect(j.after(17), inInclusiveRange(95, 100), reason: '${[for (final d in j.days) d.unlocked]}');
        expect(j.newCardsMissedNextTime, inInclusiveRange(0.4, 0.8));
        expect(j.reviewsPerDay, inInclusiveRange(65, 85));
        expect(j.mostDue, lessThanOrEqualTo(55));
        expect(j.days.every((d) => d.dayDone), isTrue, reason: 'every day plays its set to the end');
      }, timeout: const Timeout(Duration(minutes: 2)));
    }

    // The goal is flexible: a capable player on the pace's routine gets there
    // in time, and one who keeps forgetting still gets the day's new cards
    // (the pause popup, not the morning, offers to slow down).
    for (final pace in LearningPace.values) {
      final days = pace.profile.daysToAll;
      test('a quick learner on the $pace routine reaches all 100 in time, and forgets few new cards', () async {
        final j = await simulate(pace, learner: LearnerKind.quick, days: days + 2, seed: 1);
        expect(j.daysToAll, inInclusiveRange(days, days + 1), reason: '${[for (final d in j.days) d.unlocked]}');
        expect(j.newCardsMissedNextTime, inInclusiveRange(0.45, 0.7));
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('a slow, forgetful learner on the $pace routine still gets the new cards each day', () async {
        final j = await simulate(pace, learner: LearnerKind.slow, days: days, seed: 1);
        expect(j.after(days), inInclusiveRange(95, 100), reason: '${[for (final d in j.days) d.unlocked]}');
        expect(j.solidAtEnd, greaterThanOrEqualTo(0.15), reason: 'a sixth or more of what they have is solid');
        expect(j.newCardsMissedNextTime, greaterThan(0.2));
      }, timeout: const Timeout(Duration(minutes: 2)));
    }

    test('a rerun replays exactly', () async {
      List<List<Object?>> run(Journey j) => [
            for (final d in j.days)
              [d.unlocked, d.swipes, d.reviews, d.misses, d.forgotToday, d.lookAlikes, d.slips, d.dueAtStart, d.rating],
          ];
      final first = await simulate(LearningPace.month, days: 8, seed: 4);
      final again = await simulate(LearningPace.month, days: 8, seed: 4);
      expect(run(again), run(first));
      expect(first.days.fold(0, (n, d) => n + d.forgotToday + d.lookAlikes + d.slips), greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('learn ahead cards', () {
    test('unlocks the next batch even when not ready, and the round drills it', () async {
      final progress = await open(LearningPace.month);
      final day0 = DateTime(2026, 9, 1, 9);
      final first = await progress.planTraining(rng: math.Random(1), now: day0);
      expect(first.unlockedBefore.map((k) => poems[k.poemId].kimariji).take(3), ['む', 'す', 'め']);
      expect(first.unlockedBefore.length, greaterThanOrEqualTo(LearningPace.month.targetUnlocked(0, 100)),
          reason: "the morning brings day 0's new cards");
      expect(progress.readiness.ready, isFalse);

      final next = progress.trainer.nextBatch(poems, fudaSets);
      final pulled = await progress.learnAheadCards(rng: math.Random(2), now: day0);
      expect(pulled.unlockedBefore.map((k) => k.poemId), next);
      for (final k in pulled.unlockedBefore) {
        expect(pulled.picks.where((p) => p.key == k).length, TodaySetTuning.newLooks, reason: "in today's set");
      }
      final r = progress.readiness;
      expect(r.shaky, first.unlockedBefore.length + next.length);
      expect(r.latestBatch, next);
      expect(r.underPractised.length, next.length);
      await progress.db.close();
    });

    test('pulling ahead of the curve pauses auto-unlocks until the curve catches up', () async {
      final progress = await open(LearningPace.month);
      final day0 = DateTime(2026, 9, 1, 9);
      await progress.planTraining(now: day0);
      while (uprightUnlocked(progress) < 20) {
        await progress.learnAheadCards(now: day0);
      }
      final status = progress.paceStatus(day0);
      expect(status.hold, UnlockHold.aheadOfPace);
      expect(status.nextPaceDay, greaterThan(0));
      expect((await progress.planTraining(now: day0)).unlockedBefore, isEmpty);
      await progress.db.close();
    });

    test('is not offered in all-known mode', () async {
      final progress = await open(LearningPace.month);
      expect(progress.canLearnMore, isTrue);
      await progress.setLearningMode(LearningMode.allKnown);
      expect(progress.canLearnMore, isFalse);
      await progress.db.close();
    });
  });
  test('the debug Simulation plays a learner day by day in the background, on its own database', () async {
    final heard = <int>[];
    final days = await simulatePace(
      learner: LearnerKind.quick,
      pace: LearningPace.month,
      days: 4,
      onDay: (d) => heard.add(d.day),
    );
    expect(heard, [1, 2, 3, 4]);
    expect(days.map((d) => d.target), [for (var d = 0; d < 4; d++) LearningPace.month.targetUnlocked(d, 100)]);
    expect(days.first.dayDone, isTrue, reason: "day 0's set fits the routine");
    for (final d in days) {
      expect(d.setCards, greaterThan(0));
      expect(d.swipes,
          greaterThanOrEqualTo(math.min(d.setLooks, LearningPace.month.profile.dailyRounds * TrainingTuning.defaultSessionLength)));
      expect(d.reviews, inInclusiveRange(1, d.swipes));
      expect(d.recall, inInclusiveRange(0.5, 1));
      expect(d.forgotToday + d.lookAlikes + d.slips, lessThanOrEqualTo(d.misses));
      expect(d.newCardCheckMisses, lessThanOrEqualTo(d.newCardChecks));
    }
    expect(days.first.newCardChecks, 0, reason: 'nothing was met on an earlier day');
    expect(days.skip(1).fold(0, (n, d) => n + d.newCardChecks), greaterThan(0));
    expect(days.last.unlocked, days.fold<int>(0, (n, d) => n + d.newCards));
    expect(days.last.rating, isNull, reason: 'training never moves the rating');
  }, timeout: const Timeout(Duration(minutes: 1)));

  group("Home's Learn ahead", () {
    /// A training round at [at] answering each of [ids] [times] times,
    /// correctly and fast, or [miss]ing them all.
    Future<void> drill(Progress p, Iterable<int> ids, DateTime at,
        {int times = TodaySetTuning.newLooks, bool miss = false}) async {
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
      final progress = await open(LearningPace.month);
      final day0 = DateTime(2026, 9, 1, 9);
      await progress.planTraining(now: day0);
      expect(progress.learnAhead(day0).lock, LearnAheadLock.shaky, reason: 'the first batch is not learned yet');

      await learnAll(progress, day0);
      expect(progress.paceStatus(day0).hold, UnlockHold.aheadOfPace, reason: "today's new cards came on their own");
      final ahead = progress.learnAhead(day0);
      expect(ahead.lock, LearnAheadLock.none);
      expect(ahead.shaky, 0);
      expect(progress.learnAhead(day0.add(const Duration(days: 1))).lock, isNot(LearnAheadLock.none),
          reason: "tomorrow's reviews and new cards come first");

      final before = uprightUnlocked(progress);
      final pulled = await progress.learnAheadCards(now: day0);
      expect(pulled.unlockedBefore, isNotEmpty);
      expect(uprightUnlocked(progress), before + pulled.unlockedBefore.length);
      expect(progress.learnAhead(day0).lock, LearnAheadLock.shaky, reason: 'the pulled batch is new');
      await progress.db.close();
    });

    test('a fresh miss or a due review locks it again', () async {
      final progress = await open(LearningPace.month);
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
      final progress = await open(LearningPace.month);
      for (final s in progress.trainer.items.values) {
        s.unlocked = true;
      }
      expect(progress.learnAhead().lock, LearnAheadLock.allUnlocked);
      await progress.db.close();
    });
  });
}
