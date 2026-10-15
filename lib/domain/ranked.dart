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

/// Tobi's side of a graduation exam try: his time, drawn from
/// [ExamTuning.tobiMinMs]–[ExamTuning.tobiMaxMs], and when each of his
/// cards goes, jittered around an even pace but adding up to his time.
class TobiPace {
  TobiPace(this.total, this.cardEnds) : assert(cardEnds.isNotEmpty);

  factory TobiPace.draw(math.Random rng, {int cards = RankedTuning.cards}) {
    final totalMs = ExamTuning.tobiMinMs + rng.nextInt(ExamTuning.tobiMaxMs - ExamTuning.tobiMinMs + 1);
    final weights = [for (var i = 0; i < cards; i++) 1 + ExamTuning.tobiJitter * (rng.nextDouble() * 2 - 1)];
    final sum = weights.fold<double>(0, (a, w) => a + w);
    var at = 0.0;
    final ends = <Duration>[];
    for (final w in weights) {
      at += totalMs * w / sum;
      ends.add(Duration(microseconds: (at * 1000).round()));
    }
    ends[ends.length - 1] = Duration(milliseconds: totalMs);
    return TobiPace(Duration(milliseconds: totalMs), ends);
  }

  final Duration total;

  /// When each of his cards is swiped away, from the start.
  final List<Duration> cardEnds;

  /// Cards Tobi has swiped by [elapsed].
  int doneAt(Duration elapsed) {
    var n = 0;
    while (n < cardEnds.length && cardEnds[n] <= elapsed) {
      n++;
    }
    return n;
  }
}
