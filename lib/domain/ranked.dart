import 'dart:math' as math;

import '../config/config.dart';
import 'play_session.dart';

/// The time a ranked run or a graduation exam try is judged by: the clock
/// time plus a penalty for each miss.
///
/// A forfeit (a ranked run left before its last card) counts every card
/// left as a miss that took the run's pace so far, or
/// [RankedTuning.forfeitCardMs] when that is quicker, so leaving is never
/// better than missing every card left at the same pace.
class RankedScore {
  const RankedScore({
    required this.clock,
    required this.misses,
    this.cardsLeft = 0,
    this.forfeitPerCard = Duration.zero,
    this.penaltyMs = RankedTuning.missPenaltyMs,
  });

  /// [run]'s score, [clock] being its time so far (or its total once done).
  factory RankedScore.of(PlaySession run, Duration clock, {int penaltyMs = RankedTuning.missPenaltyMs}) {
    final done = run.attempts.length;
    final left = math.max(0, run.cards.length - done);
    final paceMs = done == 0 ? 0.0 : clock.inMicroseconds / 1000 / done;
    return RankedScore(
      clock: clock,
      misses: missesOf(run),
      cardsLeft: left,
      forfeitPerCard: Duration(microseconds: (math.max(paceMs, RankedTuning.forfeitCardMs) * 1000).round()),
      penaltyMs: penaltyMs,
    );
  }

  /// A forfeit with nothing recorded (the app closed mid-run): every card
  /// a slow miss.
  factory RankedScore.blank() => RankedScore(
        clock: Duration.zero,
        misses: 0,
        cardsLeft: RankedTuning.cards,
        forfeitPerCard: Duration(microseconds: (RankedTuning.forfeitCardMs * 1000).round()),
      );

  final Duration clock;

  /// Cards missed or marked wrong, an undone swipe each time.
  final int misses;

  /// Cards never swiped (a forfeit), each counted as a miss.
  final int cardsLeft;
  final Duration forfeitPerCard;
  final int penaltyMs;

  /// Misses or cards marked wrong in [run], counting each undone swipe.
  static int missesOf(PlaySession run) => run.attempts.where((a) => a.isMiss).length + run.undone.length;

  Duration get penalty => Duration(milliseconds: (misses + cardsLeft) * penaltyMs);

  /// The clock, the penalties, and a forfeit's cards left at their pace.
  Duration get scored => clock + penalty + forfeitPerCard * cardsLeft;
}

/// How one of Tobi's cards goes: at his usual pace, in a burst of quick
/// ones, or slowly, thinking it over.
enum TobiBeat { usual, quick, slow }

/// Tobi's side of a graduation exam try: when each of his cards goes, how,
/// and which of them he gets wrong. His time is his clock when his last
/// card goes, plus [ExamTuning.missPenaltyMs] for each mistake.
class TobiPace {
  TobiPace(this.cardEnds, {this.misses = const {}, this.beats = const []}) : assert(cardEnds.isNotEmpty);

  /// His time drawn from [ExamTuning.tobiMinMs]–[ExamTuning.tobiMaxMs],
  /// mistakes included, and shared out among his cards in a rhythm: mostly
  /// his usual pace, with bursts of quick cards and the odd slow one.
  factory TobiPace.draw(math.Random rng, {int cards = RankedTuning.cards}) {
    final totalMs = ExamTuning.tobiMinMs + rng.nextInt(ExamTuning.tobiMaxMs - ExamTuning.tobiMinMs + 1);
    final misses = <int>{
      for (var i = 0; i < cards; i++)
        if (rng.nextDouble() < ExamTuning.tobiMissChance) i,
    }.take(ExamTuning.tobiMaxMisses).toSet();
    final beats = <TobiBeat>[];
    while (beats.length < cards) {
      final roll = rng.nextDouble();
      if (roll < ExamTuning.tobiBurstChance) {
        final burst = ExamTuning.tobiBurstMin + rng.nextInt(ExamTuning.tobiBurstMax - ExamTuning.tobiBurstMin + 1);
        beats.addAll(List.filled(math.min(burst, cards - beats.length), TobiBeat.quick));
      } else {
        beats.add(roll < ExamTuning.tobiBurstChance + ExamTuning.tobiSlowChance ? TobiBeat.slow : TobiBeat.usual);
      }
    }
    final weights = [
      for (final beat in beats)
        switch (beat) {
          TobiBeat.quick => ExamTuning.tobiQuickWeight,
          TobiBeat.slow => ExamTuning.tobiSlowWeight,
          TobiBeat.usual => 1 + ExamTuning.tobiJitter * (rng.nextDouble() * 2 - 1),
        },
    ];
    final sum = weights.fold<double>(0, (a, w) => a + w);
    final clockMs = totalMs - misses.length * ExamTuning.missPenaltyMs;
    var at = 0.0;
    final ends = <Duration>[];
    for (final w in weights) {
      at += clockMs * w / sum;
      ends.add(Duration(microseconds: (at * 1000).round()));
    }
    ends[ends.length - 1] = Duration(milliseconds: clockMs);
    return TobiPace(ends, misses: misses, beats: beats);
  }

  /// When each of his cards is swiped away, from the start.
  final List<Duration> cardEnds;

  /// His cards that are mistakes, by index.
  final Set<int> misses;

  /// How each card goes; any not listed at his usual pace.
  final List<TobiBeat> beats;

  static const _penalty = Duration(milliseconds: ExamTuning.missPenaltyMs);

  /// When his last card goes and his clock stops.
  Duration get finish => cardEnds.last;

  /// His time: his clock at [finish] plus his mistakes' penalties.
  Duration get total => finish + _penalty * misses.length;

  TobiBeat beatOf(int i) => i < beats.length ? beats[i] : TobiBeat.usual;

  /// When card [i] comes up: as the one before it goes.
  Duration startOf(int i) => i == 0 ? Duration.zero : cardEnds[i - 1];

  /// Cards Tobi has swiped by [elapsed].
  int doneAt(Duration elapsed) {
    var n = 0;
    while (n < cardEnds.length && cardEnds[n] <= elapsed) {
      n++;
    }
    return n;
  }

  /// His mistakes by [elapsed].
  int missesAt(Duration elapsed) => misses.where((i) => cardEnds[i] <= elapsed).length;

  /// His time so far at [elapsed]: his clock, stopped at [finish], plus the
  /// penalties of his mistakes so far. It reaches [total] as he finishes.
  Duration timeAt(Duration elapsed) => (elapsed < finish ? elapsed : finish) + _penalty * missesAt(elapsed);
}
