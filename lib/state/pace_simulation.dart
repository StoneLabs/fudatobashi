import 'dart:isolate';

import 'package:drift/native.dart';

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';
import '../db/database.dart';
import '../domain/synthetic_learner.dart';
import '../domain/trainer.dart';
import 'journey_simulator.dart';
import 'progress.dart';

/// One simulated day of a journey, as it ended.
class SimulatedDay {
  const SimulatedDay({
    required this.day,
    required this.unlocked,
    required this.target,
    required this.total,
    required this.newCards,
    required this.swipes,
    required this.reviews,
    required this.misses,
    required this.dueAtStart,
    required this.rating,
  });

  /// 1 on the first day.
  final int day;

  /// Upright cards unlocked by the end of the day, the pace's target, and
  /// all there are.
  final int unlocked, target, total;

  /// Cards unlocked during the day.
  final int newCards;

  /// Training swipes, how many of them FSRS graded (due cards and misses),
  /// and how many missed.
  final int swipes, reviews, misses;

  /// Cards due for review as the day began.
  final int dueAtStart;
  final double? rating;

  double get recall => swipes == 0 ? 1 : 1 - misses / swipes;
}

/// Plays [days] days of a [learner] on [pace]'s daily routine through the
/// real trainer ([JourneySimulator]: plan, play, record), reporting each day
/// to [onDay] as it ends. It runs in a background isolate on a throwaway
/// in-memory database, so the player's own progress is never touched and the
/// UI stays smooth.
Future<List<SimulatedDay>> simulatePace({
  required LearnerKind learner,
  required LearningPace pace,
  required int days,
  int seed = SimulationTuning.seed,
  void Function(SimulatedDay day)? onDay,
}) async {
  final port = ReceivePort();
  await Isolate.spawn(
    _simulate,
    (port.sendPort, poems, learner, pace, days, seed),
    onError: port.sendPort,
    onExit: port.sendPort,
  );
  final out = <SimulatedDay>[];
  try {
    await for (final message in port) {
      if (message is SimulatedDay) {
        out.add(message);
        onDay?.call(message);
      } else if (message is List) {
        throw StateError('Simulation failed: ${message.first}\n${message.last}');
      } else {
        break;
      }
    }
  } finally {
    port.close();
  }
  return out;
}

Future<void> _simulate((SendPort, Poems, LearnerKind, LearningPace, int, int) setup) async {
  final (send, allPoems, learner, pace, days, seed) = setup;
  poems = allPoems;
  fudaSets = FudaSets(allPoems);
  final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
  await progress.updateTrainerConfig(TrainerConfig(pace: pace));
  var swipes = 0, misses = 0;
  final sim = JourneySimulator(progress, seed: seed, learner: learner, onReport: (r) {
    swipes += r.attempts.length;
    misses += r.attempts.where((a) => a.isMiss).length;
  });
  final trainer = progress.trainer;
  int upright() => trainer.unlocked.where((s) => !s.key.inverted).length;
  int graded() => trainer.items.keys.fold(0, (n, k) => n + progress.attemptsOf(k).where((a) => a.grade != null).length);

  final total = trainer.items.length ~/ 2;
  final today = DateTime.now();
  for (var d = 0; d < days; d++) {
    final date = DateTime(today.year, today.month, today.day + d);
    final morning = date.add(const Duration(hours: SyntheticLearnerTuning.firstRoundHour));
    final due = trainer.unlocked.where((s) => trainer.isDue(s.key, morning)).length;
    final (unlockedBefore, gradedBefore) = (upright(), graded());
    swipes = misses = 0;
    await sim.day(date, rounds: pace.profile.dailyRounds);
    send.send(SimulatedDay(
      day: d + 1,
      unlocked: upright(),
      target: pace.targetUnlocked(d, total),
      total: total,
      newCards: upright() - unlockedBefore,
      swipes: swipes,
      reviews: graded() - gradedBefore,
      misses: misses,
      dueAtStart: due,
      rating: progress.rating,
    ));
  }
  await progress.db.close();
}
