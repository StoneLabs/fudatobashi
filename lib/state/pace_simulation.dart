import 'dart:isolate';

import 'package:drift/native.dart';

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';
import '../db/database.dart';
import '../domain/card_stats.dart';
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
    required this.forgotToday,
    required this.lookAlikes,
    required this.slips,
    required this.newCardChecks,
    required this.newCardCheckMisses,
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

  /// Of the misses: cards forgotten since an earlier look the same day,
  /// taken for a 友札, and slips on a card the learner remembered (the rest
  /// were forgotten since an earlier day).
  final int forgotToday, lookAlikes, slips;

  /// Cards met on an earlier day and seen again today for the first time
  /// since, and how many of them were missed.
  final int newCardChecks, newCardCheckMisses;

  /// Cards due for review as the day began.
  final int dueAtStart;
  final double? rating;

  double get recall => swipes == 0 ? 1 : 1 - misses / swipes;
}

/// A journey played day by day by a [SyntheticLearner] on [pace]'s daily
/// routine, through the real trainer ([JourneySimulator]: plan, play,
/// record) on a throwaway in-memory database. Every random source is seeded
/// and FSRS's interval fuzz is off, so a rerun replays exactly.
class PaceSimulation {
  PaceSimulation._(this.progress, this.pace, this._start, this._rounds, LearnerKind learner, int seed) {
    _sim = JourneySimulator(progress, seed: seed, learner: learner, onAnswer: _onAnswer);
  }

  /// Starts a journey on the local day of [start] (by default today), with
  /// [roundsPerDay] training rounds a day (by default the pace's routine).
  static Future<PaceSimulation> open({
    required LearnerKind learner,
    required LearningPace pace,
    int seed = SimulationTuning.seed,
    DateTime? start,
    int? roundsPerDay,
  }) async {
    final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await progress.updateTrainerConfig(TrainerConfig(pace: pace));
    progress.trainer.fuzzing = false;
    final from = start ?? DateTime.now();
    return PaceSimulation._(
      progress,
      pace,
      DateTime(from.year, from.month, from.day),
      roundsPerDay ?? pace.profile.dailyRounds,
      learner,
      seed,
    );
  }

  final Progress progress;
  final LearningPace pace;
  final DateTime _start;
  final int _rounds;
  late final JourneySimulator _sim;
  var _day = 0;

  /// When each upright card was first answered, until its first look on a
  /// later day.
  final _metAt = <int, DateTime>{};
  final _checked = <int>{};

  var _swipes = 0, _misses = 0, _forgotToday = 0, _lookAlikes = 0, _slips = 0, _checks = 0, _checkMisses = 0;

  void _onAnswer(ItemKey key, DateTime at, LearnerAnswer answer) {
    _swipes++;
    if (answer.missed) _misses++;
    switch (answer.miss) {
      case MissCause.forgotToday:
        _forgotToday++;
      case MissCause.lookAlike:
        _lookAlikes++;
      case MissCause.slip:
        _slips++;
      case MissCause.forgot || null:
        break;
    }
    if (key.inverted || _checked.contains(key.poemId)) return;
    final met = _metAt.putIfAbsent(key.poemId, () => at);
    if (Trainer.daysBetween(met, at) == 0) return;
    _checked.add(key.poemId);
    _checks++;
    if (answer.missed) _checkMisses++;
  }

  /// Plays the next day and reports how it ended.
  Future<SimulatedDay> nextDay() async {
    final trainer = progress.trainer;
    int upright() => trainer.unlocked.where((s) => !s.key.inverted).length;
    int graded() =>
        trainer.items.keys.fold(0, (n, k) => n + progress.attemptsOf(k).where((a) => a.grade != null).length);

    final total = trainer.items.length ~/ 2;
    final date = DateTime(_start.year, _start.month, _start.day + _day);
    final morning = date.add(const Duration(hours: SyntheticLearnerTuning.firstRoundHour));
    final due = trainer.unlocked.where((s) => trainer.isDue(s.key, morning)).length;
    final (unlockedBefore, gradedBefore) = (upright(), graded());
    _swipes = _misses = _forgotToday = _lookAlikes = _slips = _checks = _checkMisses = 0;
    await _sim.day(date, rounds: _rounds);
    _day++;
    return SimulatedDay(
      day: _day,
      unlocked: upright(),
      target: pace.targetUnlocked(_day - 1, total),
      total: total,
      newCards: upright() - unlockedBefore,
      swipes: _swipes,
      reviews: graded() - gradedBefore,
      misses: _misses,
      forgotToday: _forgotToday,
      lookAlikes: _lookAlikes,
      slips: _slips,
      newCardChecks: _checks,
      newCardCheckMisses: _checkMisses,
      dueAtStart: due,
      rating: progress.rating,
    );
  }

  Future<void> close() => progress.db.close();
}

/// Plays [days] days of a [learner] on [pace]'s daily routine
/// ([PaceSimulation]), reporting each day to [onDay] as it ends. It runs in
/// a background isolate on a throwaway in-memory database, so the player's
/// own progress is never touched and the UI stays smooth.
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
  final sim = await PaceSimulation.open(learner: learner, pace: pace, seed: seed);
  for (var d = 0; d < days; d++) {
    send.send(await sim.nextDay());
  }
  await sim.close();
}
