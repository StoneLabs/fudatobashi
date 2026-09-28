import 'dart:math' as math;

import '../config/config.dart';
import '../data/poem.dart';
import 'card_stats.dart';

/// The kinds of simulated player (see [SyntheticLearnerTuning]).
enum LearnerKind {
  quick,
  average,
  slow;

  LearnerProfile get profile => switch (this) {
        LearnerKind.quick => SyntheticLearnerTuning.quick,
        LearnerKind.average => SyntheticLearnerTuning.average,
        LearnerKind.slow => SyntheticLearnerTuning.slow,
      };
}

/// A simulated player for pacing tests, the debug Simulation and dev-mode
/// demo data (see [SyntheticLearnerTuning]): slow and error-prone on a new
/// card, faster with every repetition, a little rusty after a night away,
/// and sometimes forgetting a card it has not seen for a while.
class SyntheticLearner {
  SyntheticLearner(this.rng, {this.kind = LearnerKind.average});

  final math.Random rng;
  final LearnerKind kind;
  final _memory = <ItemKey, _Memory>{};

  /// Answers [key] at [at]: its response time in ms, or a miss.
  ({double ms, bool miss}) answer(Poem poem, ItemKey key, DateTime at) {
    final p = kind.profile;
    final m = _memory.putIfAbsent(key, () => _Memory(p.initialStrengthDays));
    var forgot = false;
    if (m.last != null) {
      final gapDays = at.difference(m.last!).inMinutes / Duration.minutesPerDay;
      if (!_sameDay(m.last!, at)) {
        m.reps *= SyntheticLearnerTuning.overnightRepsKept;
        m.strengthDays = m.days == 0 ? p.initialStrengthDays : m.strengthDays * p.strengthGrowth;
        m.days++;
      }
      forgot = rng.nextDouble() > math.exp(-gapDays / m.strengthDays);
      if (forgot) m.reps *= SyntheticLearnerTuning.forgottenRepsKept;
    }
    final missRate = p.firstSightMissRate * math.exp(-m.reps / p.firstSightMissDecayReps) + p.slipRate;
    final miss = forgot || rng.nextDouble() < missRate;

    final extraKana = poem.kimariji.length - 1;
    final first = p.firstMs + p.firstPerKanaMs * extraKana;
    final floor = p.floorMs + p.floorPerKanaMs * extraKana;
    final jitter = math.pow(SyntheticLearnerTuning.timeJitter, 2 * rng.nextDouble() - 1);
    final ms =
        (floor + (first - floor) * math.exp(-m.reps / p.learnReps)) *
        jitter *
        (key.inverted ? SyntheticLearnerTuning.invertedFactor : 1);

    m
      ..reps += miss ? 0.5 : 1
      ..last = at;
    return (ms: ms, miss: miss);
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Memory {
  _Memory(this.strengthDays);

  double reps = 0;
  DateTime? last;
  double strengthDays;

  /// Distinct days practised before the current one.
  int days = 0;
}
