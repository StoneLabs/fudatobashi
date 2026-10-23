import 'dart:math' as math;

import '../config/config.dart';

/// 暗記練's own rating, on the main rating's scale and bands (`Rating.bands`).
///
/// Every ranked game plays the same setup (`AnkirenSetup.ranked`), so a
/// game's final score (`AnkirenScore.total`) maps straight to its
/// performance: the score over [AnkirenRatingModel.pointsPerRating]. The
/// first [AnkirenRatingModel.placementGames] ranked games place the rating at
/// the mean of their performances; after them each game moves it toward its
/// own: `R' = R + K × (P − R)`, K = [AnkirenRatingModel.establishedK].
/// [start] is only the rating before any ranked game.
abstract final class AnkirenRating {
  static const double start = AnkirenRatingModel.start;

  /// Whether the next ranked game, after [gamesSoFar], still places.
  static bool isPlacement(int gamesSoFar) => gamesSoFar < AnkirenRatingModel.placementGames;

  /// The performance of a ranked game that scored [score], never negative.
  static double performance(int score) => math.max(0, score) / AnkirenRatingModel.pointsPerRating;

  /// The score that performs at [rating].
  static double scoreFor(double rating) => rating * AnkirenRatingModel.pointsPerRating;

  /// The rating after a ranked game that performed at [performance], when
  /// the rated games before it performed at [earlier] (oldest first) and
  /// left the rating at [current].
  static double update(double current, double performance, List<double> earlier) =>
      isPlacement(earlier.length)
          ? (earlier.fold(0.0, (sum, p) => sum + p) + performance) / (earlier.length + 1)
          : current + AnkirenRatingModel.establishedK * (performance - current);
}
