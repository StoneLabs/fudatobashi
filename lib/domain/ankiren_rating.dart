import 'dart:math' as math;

import '../config/config.dart';

/// 暗記練's own rating, on the main rating's scale and bands (`Rating.bands`).
///
/// Every ranked game plays the same setup (`AnkirenSetup.ranked`), so one
/// line maps a game's final score F (`AnkirenScore.total`) to its
/// performance: `P = slope × (F − zero)` ([AnkirenRatingModel]). The first
/// [AnkirenRatingModel.placementGames] ranked games place the rating at the
/// mean of their performances; after them each game moves it toward its
/// own: `R' = R + K × (P − R)`, K = [AnkirenRatingModel.establishedK]. It
/// never drops below [start].
abstract final class AnkirenRating {
  static const double start = AnkirenRatingModel.start;

  /// Whether the next ranked game, after [gamesSoFar], still places.
  static bool isPlacement(int gamesSoFar) => gamesSoFar < AnkirenRatingModel.placementGames;

  /// The performance of a ranked game that scored [score].
  static double performance(int score) => AnkirenRatingModel.slope * (score - AnkirenRatingModel.zero);

  /// The score that performs at [rating].
  static double scoreFor(double rating) => AnkirenRatingModel.zero + rating / AnkirenRatingModel.slope;

  /// The rating after a ranked game that performed at [performance], when
  /// the rated games before it performed at [earlier] (oldest first) and
  /// left the rating at [current].
  static double update(double current, double performance, List<double> earlier) {
    final next = isPlacement(earlier.length)
        ? (earlier.fold(0.0, (sum, p) => sum + p) + performance) / (earlier.length + 1)
        : current + AnkirenRatingModel.establishedK * (performance - current);
    return math.max(start, next);
  }
}
