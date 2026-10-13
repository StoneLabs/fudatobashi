import 'dart:math' as math;

import '../config/config.dart';
import '../data/fuda_sets.dart';
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

/// Why a [SyntheticLearner] missed a card.
enum MissCause {
  /// Forgotten since an earlier look the same day, or mixed up with the
  /// cards met around it.
  forgotToday,

  /// Forgotten since an earlier day, or never met.
  forgot,

  /// Taken for one of its 友札.
  lookAlike,

  /// Remembered, but answered wrong: a lapse of attention, more often in a
  /// rush.
  slip,
}

/// One swipe of a [SyntheticLearner]: its response time and, for a miss,
/// why.
class LearnerAnswer {
  const LearnerAnswer(this.ms, [this.miss]);

  final double ms;
  final MissCause? miss;

  bool get missed => miss != null;
}

/// A simulated player for pacing tests, the debug Simulation and dev-mode
/// demo data (see [SyntheticLearnerTuning]). It answers one swipe at a time
/// and keeps its own memory of every card: a card fades from the moment it
/// is met, grows stronger with each correct recall (most after a long gap),
/// loses most of its strength when forgotten, gets mixed up with the cards
/// met around it and with its 友札, and slips now and then, more often in a
/// rush. Answers get faster with practice, slowly and noisily.
class SyntheticLearner {
  SyntheticLearner(this.rng, {this.kind = LearnerKind.average});

  final math.Random rng;
  final LearnerKind kind;

  /// What it remembers of each poem, whichever way up it is shown.
  final _memory = <int, _Memory>{};

  /// How practised it is at each card in each orientation (speed).
  final _practice = <ItemKey, _Practice>{};

  /// Days until recall of [poemId] falls to
  /// [SyntheticLearnerTuning.stabilityRecall], or null before it is met.
  double? stabilityOf(int poemId) => _memory[poemId]?.stability;

  /// Answers [key] at [at]. [introduced]: the app showed the card's
  /// introduction just before, as it does on a new card's first swipe.
  LearnerAnswer answer(Poem poem, ItemKey key, DateTime at, {bool introduced = false}) {
    final m = _memory[poem.id];
    final recall = m == null ? 0.0 : _recall(at.difference(m.last), m.stability);
    final noise = math.exp(SyntheticLearnerTuning.timeNoise * _gaussian());
    final rushed = noise < SyntheticLearnerTuning.rushRatio;
    final miss = _missCause(poem.id, m, at, recall, introduced: introduced, rushed: rushed);
    final ms = _usualMs(poem, key, at, miss) * noise;
    _remember(poem.id, m, at, recall, miss);
    return LearnerAnswer(ms, miss);
  }

  MissCause? _missCause(
    int poemId,
    _Memory? m,
    DateTime at,
    double recall, {
    required bool introduced,
    required bool rushed,
  }) {
    final p = kind.profile;
    if (m == null) {
      if (!introduced) return MissCause.forgot;
    } else {
      final mixUp = p.mixUpRate * math.pow(SyntheticLearnerTuning.mixUpKept, m.recalls);
      if (rng.nextDouble() > recall * (1 - mixUp)) {
        return _sameDay(m.last, at) ? MissCause.forgotToday : MissCause.forgot;
      }
      if (rng.nextDouble() < _lookAlikeChance(poemId, m)) return MissCause.lookAlike;
    }
    return rng.nextDouble() < p.slipRate + (rushed ? p.rushSlipRate : 0) ? MissCause.slip : null;
  }

  /// The learner's usual time for [key], ms, at its practice so far, which
  /// this answer then adds to.
  double _usualMs(Poem poem, ItemKey key, DateTime at, MissCause? miss) {
    final p = kind.profile;
    final practice = _practice.putIfAbsent(key, _Practice.new);
    if (practice.last != null && !_sameDay(practice.last!, at)) {
      practice.reps *= SyntheticLearnerTuning.overnightRepsKept;
    }
    if (miss == MissCause.forgot || miss == MissCause.forgotToday) {
      practice.reps *= SyntheticLearnerTuning.forgottenRepsKept;
    }
    final extraKana = poem.kimariji.length - 1;
    final first = p.firstMs + p.firstPerKanaMs * extraKana;
    final floor = p.floorMs + p.floorPerKanaMs * extraKana;
    final usual = floor + (first - floor) * math.pow(1 + practice.reps, -p.practiceExponent);
    practice
      ..reps += miss == null ? 1 : SyntheticLearnerTuning.missRep
      ..last = at;
    return usual * (key.inverted ? SyntheticLearnerTuning.invertedFactor : 1);
  }

  /// Updates the memory of [poemId] after an answer at [at]. Every answer
  /// shows the card, so the gap restarts; only a correct recall strengthens
  /// it, and forgetting weakens it to what is left, but never below a fresh
  /// look at the card.
  void _remember(int poemId, _Memory? m, DateTime at, double recall, MissCause? miss) {
    final p = kind.profile;
    if (m == null) {
      final ease = math.exp(p.cardSpread * _gaussian());
      _memory[poemId] = _Memory(ease, _days(p.firstStability) * ease, at);
      return;
    }
    switch (miss) {
      case null:
        m.stability *= SyntheticLearnerTuning.massedGrowth +
            p.recallGrowth * (math.exp(SyntheticLearnerTuning.spacingGrowth * (1 - recall)) - 1);
        m.recalls++;
        if (m.lastGoodDay == null || !_sameDay(m.lastGoodDay!, at)) {
          m.goodDays++;
          m.lastGoodDay = at;
        }
      case MissCause.forgot || MissCause.forgotToday:
        m
          ..stability = math.max(_days(p.firstStability) * m.ease, m.stability * SyntheticLearnerTuning.lapseKept)
          ..recalls = 0;
      case MissCause.lookAlike || MissCause.slip:
        break;
    }
    m.last = at;
  }

  /// Recall chance after [gap] at [stability] days.
  static double _recall(Duration gap, double stability) {
    const decay = SyntheticLearnerTuning.forgettingDecay;
    final f = math.pow(SyntheticLearnerTuning.stabilityRecall, -1 / decay) - 1;
    return math.pow(1 + f * _days(gap) / stability, -decay).toDouble();
  }

  double _lookAlikeChance(int poemId, _Memory m) {
    final p = kind.profile;
    final metTwin = fudaSets.tomofuda(poemId).any(_memory.containsKey);
    return metTwin ? p.lookAlikeRate * math.exp(-m.goodDays / p.lookAlikeFadeDays) : 0;
  }

  /// A standard normal draw (Box–Muller).
  double _gaussian() => math.sqrt(-2 * math.log(1 - rng.nextDouble())) * math.cos(2 * math.pi * rng.nextDouble());

  static double _days(Duration d) => d.inMilliseconds / Duration.millisecondsPerDay;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Memory {
  _Memory(this.ease, this.stability, this.last);

  /// How well this card sticks for this learner (1 = typical).
  final double ease;

  /// Days until recall falls to [SyntheticLearnerTuning.stabilityRecall].
  double stability;
  DateTime last;

  /// Correct answers since it was met or last forgotten.
  int recalls = 0;

  /// Days with a correct answer.
  int goodDays = 0;
  DateTime? lastGoodDay;
}

class _Practice {
  double reps = 0;
  DateTime? last;
}
