import 'dart:math' as math;

import '../config/config.dart';

/// One ranked match as the rating reads it: the rating the opponent played
/// at, and whether the player won (a match given up is a loss).
typedef IkkiuchiRatedMatch = ({double opponentRating, bool won});

/// The player's 一騎打ち rating, from their ranked matches in the order
/// played ([IkkiuchiRankedTuning]).
///
/// The first [IkkiuchiRankedTuning.placementMatches] place it, played
/// against an opponent at [start]: a match performs
/// [IkkiuchiRankedTuning.performanceSpread] above the opponent's rating
/// when won and as far below when lost, and the rating after each is the
/// mean of the performances so far. The player is unrated until the last
/// of them. Then the opponent plays at the player's rating, held within the
/// ratings Tobi plays at, and each match moves it Elo-style:
/// `R' = R + K × (S − E)`, S 1 for a win and 0 for a loss, E the expected
/// score ([expected]), K = [IkkiuchiRankedTuning.k].
abstract final class IkkiuchiRating {
  static const double start = IkkiuchiRankedTuning.start;

  /// Whether the next ranked match, after [played] of them, still places.
  static bool isPlacement(int played) => played < IkkiuchiRankedTuning.placementMatches;

  /// The rating the opponent plays the next ranked match at, after [played]
  /// ranked matches that left the player's rating at [rating].
  static double opponentFor({required int played, required double? rating}) =>
      (isPlacement(played) || rating == null ? start : rating).clamp(IkkiuchiTuning.ratingMin, IkkiuchiTuning.ratingMax);

  /// The player's expected score, 0 to 1, at [rating] against an opponent
  /// at [opponent]: a half when even.
  static double expected(double rating, double opponent) =>
      1 / (1 + math.pow(10, (opponent - rating) / IkkiuchiRankedTuning.eloScale));

  /// What [match] performed at, for placement.
  static double performance(IkkiuchiRatedMatch match) =>
      match.opponentRating + (match.won ? 1 : -1) * IkkiuchiRankedTuning.performanceSpread;

  /// The rating after [match], when the ranked matches before it were
  /// [earlier], oldest first, and left the rating at [rating].
  static double after(IkkiuchiRatedMatch match, {required List<IkkiuchiRatedMatch> earlier, required double? rating}) {
    if (isPlacement(earlier.length) || rating == null) {
      final placing = [...earlier, match];
      return placing.fold(0.0, (sum, m) => sum + performance(m)) / placing.length;
    }
    return rating + IkkiuchiRankedTuning.k * ((match.won ? 1 : 0) - expected(rating, match.opponentRating));
  }
}
