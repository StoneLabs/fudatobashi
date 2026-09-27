import 'dart:math' as math;

import 'card_stats.dart';

/// A class (級) band of the rating ladder.
class RankBand {
  const RankBand(this.id, this.label, this.labelEn, this.maxSeconds);

  final String id;

  /// e.g. "F下級". The 上/下 split echoes 上の句 / 下の句.
  final String label;
  final String labelEn;

  /// Projected random-orientation 100-card time needed, seconds
  /// (null for the unranked band).
  final double? maxSeconds;

  double get minRating => maxSeconds == null ? double.negativeInfinity : Rating.fromSeconds(maxSeconds!);
}

/// The Elo-style rating.
///
/// Performance comes from the *projected 100-card time*: the sum over all 100
/// cards of each card's expected time (misses and unseen cards count as
/// [unknownMs]; both orientations weighted equally, inverted defaulting to
/// upright × 1.25 when never practised). It is mapped as
/// `P = 600 · log2(1000 s / T)`, and the displayed rating moves toward P after
/// each session: `R += K · (P − R)`.
///
/// This reproduces the original app's anchors: 50 cards at 2 s + 50 unseen =
/// 400 s (F), 100 × 1.5 s = 150 s (E), and 90 / 60 / 52 / 48 s (D / C / B / A).
abstract final class Rating {
  static const double unknownMs = 6000;
  static const double invertedPrior = 1.25;

  static const bands = [
    RankBand('nyumon', '入門', 'Novice', null),
    RankBand('F-', 'F下級', 'F lower', 400),
    RankBand('F+', 'F上級', 'F upper', 245),
    RankBand('E-', 'E下級', 'E lower', 150),
    RankBand('E+', 'E上級', 'E upper', 116),
    RankBand('D', 'D級', 'D', 90),
    RankBand('C', 'C級', 'C', 60),
    RankBand('B', 'B級', 'B', 52),
    RankBand('A', 'A級', 'A', 48),
  ];

  static double fromSeconds(double t) => 600 * math.log(1000 / t) / math.ln2;
  static double toSeconds(double r) => 1000 / math.pow(2, r / 600);

  static RankBand bandOf(double rating) =>
      bands.lastWhere((b) => rating >= b.minRating, orElse: () => bands.first);

  static RankBand? nextBand(double rating) {
    final i = bands.indexOf(bandOf(rating));
    return i + 1 < bands.length ? bands[i + 1] : null;
  }

  /// Expected ms of one card, both orientations averaged.
  static double cardExpectedMs(CardStats upright, CardStats inverted) {
    final u = upright.expectedMs(unknownMs: unknownMs);
    final v = inverted.seen
        ? inverted.expectedMs(unknownMs: unknownMs)
        : math.min(unknownMs, u * invertedPrior);
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
    final k = sessionsSoFar < 10 ? 0.5 : 0.25;
    return current + k * (performance - current);
  }
}
