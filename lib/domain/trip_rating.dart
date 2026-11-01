import 'dart:math' as math;

import '../config/config.dart';

/// A side trip's own rating, on the main rating's scale and bands
/// (`Rating.bands`). Each trip's ranked games play one fixed setup, so a
/// game's final score maps straight to its performance: the score over
/// [pointsPerRating], which is all that differs between the trips.
///
/// The first [AnkirenRatingModel.placementGames] ranked games place the
/// rating at the mean of their performances; after them each game moves it
/// toward its own: `R' = R + K × (P − R)`, K =
/// [AnkirenRatingModel.establishedK]. [start] is only the rating before any
/// ranked game.
class TripRating {
  const TripRating(this.pointsPerRating);

  /// 暗記練's, on `AnkirenScore.total`.
  static const ankiren = TripRating(AnkirenRatingModel.pointsPerRating);

  /// 定位置's, on `TeiichiScore.total`.
  static const teiichi = TripRating(TeiichiRatingModel.pointsPerRating);

  static const double start = AnkirenRatingModel.start;

  final double pointsPerRating;

  /// Whether the next ranked game, after [gamesSoFar], still places.
  static bool isPlacement(int gamesSoFar) => gamesSoFar < AnkirenRatingModel.placementGames;

  /// The performance of a ranked game that scored [score], never negative.
  double performance(int score) => math.max(0, score) / pointsPerRating;

  /// The score that performs at [rating].
  double scoreFor(double rating) => rating * pointsPerRating;

  /// The rating after a ranked game that performed at [performance], when
  /// the rated games before it performed at [earlier] (oldest first) and
  /// left the rating at [current].
  static double update(double current, double performance, List<double> earlier) =>
      isPlacement(earlier.length)
          ? (earlier.fold(0.0, (sum, p) => sum + p) + performance) / (earlier.length + 1)
          : current + AnkirenRatingModel.establishedK * (performance - current);
}
