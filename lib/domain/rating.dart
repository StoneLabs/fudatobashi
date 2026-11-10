import 'dart:math' as math;

import '../config/config.dart';
import 'card_stats.dart';
import 'rank_ladder.dart';

/// The Elo-style rating.
///
/// Performance comes from the *projected 100-card time*: the sum over all 100
/// cards of each card's expected time (misses and unseen cards count as
/// [StatsTuning.unknownMs]; both orientations weighted equally, inverted
/// defaulting to upright × 1.25 when never practised). It is mapped as
/// `P = 600 · log2(1000 s / T)`, and the displayed rating moves toward P after
/// each session: `R += K · (P − R)`.
abstract final class Rating {
  static double fromSeconds(double t) =>
      RatingModel.pointsPerDoubling * math.log(RatingModel.referenceSeconds / t) / math.ln2;
  static double toSeconds(double r) => RatingModel.referenceSeconds / math.pow(2, r / RatingModel.pointsPerDoubling);

  /// [rating]'s class, the next one and how far toward it (see
  /// [RankLadder.progress]).
  static ClassProgress classProgress(double rating) => RankLadder.progress(rating, floor: RatingModel.noviceFloor);

  /// Expected ms of one card, both orientations averaged.
  static double cardExpectedMs(CardStats upright, CardStats inverted) {
    final u = upright.expectedMs(unknownMs: StatsTuning.unknownMs);
    final v = inverted.seen
        ? inverted.expectedMs(unknownMs: StatsTuning.unknownMs)
        : math.min(StatsTuning.unknownMs, u * RatingModel.invertedPrior);
    return (u + v) / 2;
  }

  /// Projected random-orientation 100-card time, ms.
  static double projectedMs(CardStats Function(ItemKey) stats) {
    var t = 0.0;
    for (var id = 1; id <= 100; id++) {
      t += cardExpectedMs(stats(ItemKey(id, false)), stats(ItemKey(id, true)));
    }
    return t;
  }

  static double performance(double projectedMs) => fromSeconds(projectedMs / 1000);

  /// Elo-style smoothing toward the latest performance.
  static double update(double? current, double performance, int sessionsSoFar) {
    if (current == null) return performance;
    return current + share(sessionsSoFar) * (performance - current);
  }

  /// The share of the way to its performance a ranked run moves the rating
  /// after [sessionsSoFar] rated runs.
  static double share(int sessionsSoFar) =>
      sessionsSoFar < RatingModel.provisionalSessions ? RatingModel.provisionalK : RatingModel.establishedK;
}
