import 'dart:math' as math;

import '../config/config.dart';

/// 暗記練's own rating, on the main rating's scale and bands (`Rating.bands`).
///
/// Each level has a difficulty rating ([AnkirenRatingModel.levelRatings]);
/// a ranked game plays the highest level the rating has reached, capped by
/// the known cards ([levelFor]). A game at level L with score fraction p
/// (`AnkirenScore.fraction`) performs at
/// `P = levelRatings[L] + weight × s × (p − par)`, with s =
/// [AnkirenRatingModel.placementStretch] during placement and 1 after, so a
/// game at par holds the level. The rating then moves toward it:
/// `R' = max(start, R + K × (P − R))`, K = [AnkirenRatingModel.placementK]
/// for the first [AnkirenRatingModel.placementGames] ranked games (a strong
/// player climbs most of the ladder in them), then
/// [AnkirenRatingModel.establishedK]. Level 0's rating is both the start and
/// the floor.
abstract final class AnkirenRating {
  static double get start => AnkirenRatingModel.levelRatings.first;

  /// Whether the next ranked game, after [gamesSoFar], still places.
  static bool isPlacement(int gamesSoFar) => gamesSoFar < AnkirenRatingModel.placementGames;

  /// The level a ranked game plays at [rating], at most [maxLevel] (see
  /// `AnkirenLevels.maxLevelFor`).
  static int levelFor(double rating, {required int maxLevel}) {
    final reached = AnkirenRatingModel.levelRatings.lastIndexWhere((r) => r <= rating);
    return reached.clamp(0, maxLevel);
  }

  /// The rating at which ranked games move up from [level], or null at the
  /// top level.
  static double? nextLevelAt(int level) {
    const ratings = AnkirenRatingModel.levelRatings;
    return level + 1 < ratings.length ? ratings[level + 1] : null;
  }

  static double performance(int level, double fraction, {required bool placement}) {
    final stretch = placement ? AnkirenRatingModel.placementStretch : 1.0;
    return AnkirenRatingModel.levelRatings[level] +
        AnkirenRatingModel.weight * stretch * (fraction - AnkirenRatingModel.par);
  }

  static double update(double current, double performance, int gamesSoFar) {
    final k = isPlacement(gamesSoFar) ? AnkirenRatingModel.placementK : AnkirenRatingModel.establishedK;
    return math.max(start, current + k * (performance - current));
  }
}
