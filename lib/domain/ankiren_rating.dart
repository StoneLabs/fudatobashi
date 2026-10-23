import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_field.dart';
import 'ankiren_level.dart';
import 'ankiren_score.dart';
import 'rating.dart';

/// 暗記練's own rating, on the main rating's scale and bands (`Rating.bands`).
///
/// Every ranked game plays the same setup (`AnkirenSetup.ranked`), so one
/// curve maps a game's final score F (`AnkirenScore.total`) to its
/// performance P. From the lower anchor's score up it is the line
/// `P = slope × (F − zero)` through the two games [AnkirenRatingModel]
/// anchors to class lines; below it, the straight line from zero points to
/// the lower anchor, so P is never negative. The first
/// [AnkirenRatingModel.placementGames] ranked games place the rating at the
/// mean of their performances; after them each game moves it toward its
/// own: `R' = R + K × (P − R)`, K = [AnkirenRatingModel.establishedK].
/// [start] is only the rating before any ranked game.
abstract final class AnkirenRating {
  static const double start = AnkirenRatingModel.start;

  /// Whether the next ranked game, after [gamesSoFar], still places.
  static bool isPlacement(int gamesSoFar) => gamesSoFar < AnkirenRatingModel.placementGames;

  /// The score of the game that performs at the [AnkirenRatingModel.highBand]
  /// line, and of the one at the [AnkirenRatingModel.lowBand] line.
  static final int _cards = const AnkirenSetup.ranked().cards;
  static final int _highScore = _anchorScore(
    firstRight: _cards,
    firstTap: AnkirenRatingModel.highFirstTap,
    otherTaps: const [],
  );
  static final int _lowScore = _anchorScore(
    firstRight: (_cards * AnkirenRatingModel.lowFirstShare).round(),
    firstTap: AnkirenRatingModel.lowFirstTap,
    otherTaps: AnkirenRatingModel.lowOtherTaps,
  );

  static int _anchorScore({
    required int firstRight,
    required Duration firstTap,
    required List<TapProximity> otherTaps,
  }) =>
      firstRight * (AnkirenTuning.cardPoints + AnkirenScore.speedBonus(firstTap.inMicroseconds)) +
      (_cards - firstRight) * AnkirenScore.pointsOf(otherTaps, null);

  static double _lineOf(String id) => Rating.bands.firstWhere((b) => b.id == id).minRating;

  /// Rating points per score point, and the score that performs at zero.
  static final double slope =
      (_lineOf(AnkirenRatingModel.highBand) - _lineOf(AnkirenRatingModel.lowBand)) / (_highScore - _lowScore);
  static final double zero = _highScore - _lineOf(AnkirenRatingModel.highBand) / slope;

  static final double _lowRating = _lineOf(AnkirenRatingModel.lowBand);

  /// The score of the lower anchor, where the curve turns toward zero.
  static double get lowScore => _lowScore.toDouble();

  /// The performance of a ranked game that scored [score].
  static double performance(int score) =>
      score >= _lowScore ? slope * (score - zero) : math.max(0, score) * _lowRating / _lowScore;

  /// The score that performs at [rating].
  static double scoreFor(double rating) =>
      rating >= _lowRating ? zero + rating / slope : rating * _lowScore / _lowRating;

  /// The rating after a ranked game that performed at [performance], when
  /// the rated games before it performed at [earlier] (oldest first) and
  /// left the rating at [current].
  static double update(double current, double performance, List<double> earlier) =>
      isPlacement(earlier.length)
          ? (earlier.fold(0.0, (sum, p) => sum + p) + performance) / (earlier.length + 1)
          : current + AnkirenRatingModel.establishedK * (performance - current);
}
