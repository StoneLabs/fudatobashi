import 'dart:math' as math;

import '../config/config.dart';
import 'truncated_normal.dart';

/// One ranked match as the rating reads it: the rating the opponent played
/// at, and whether the player won (a match given up is a loss).
typedef IkkiuchiRatedMatch = ({double opponentRating, bool won});

/// The player's 一騎打ち rating, from their ranked matches in the order
/// played ([IkkiuchiRankedTuning]).
///
/// The first matches place it: each against Tobi at exactly the estimate
/// so far, from [start], which a win moves up and a loss down by the next
/// of [IkkiuchiRankedTuning.placementSteps]. The player is unrated until
/// the last of them, whose estimate is the first rating. Then Tobi plays
/// each match near the player's rating ([opponentFor]), and each moves it
/// Elo-style: `R' = R + K × (S − E)`, S 1 for a win and 0 for a loss, E the
/// expected score ([expected]), K by the matches rated so far ([kAfter]).
/// The rating stays inside the ratings Tobi plays at.
abstract final class IkkiuchiRating {
  static const double start = IkkiuchiRankedTuning.start;

  /// The matches that place the rating.
  static int get placementMatches => IkkiuchiRankedTuning.placementSteps.length;

  /// Whether the next ranked match, after [played] of them, still places.
  static bool isPlacement(int played) => played < placementMatches;

  static double _held(double rating) => rating.clamp(IkkiuchiTuning.ratingMin, IkkiuchiTuning.ratingMax);

  /// The rating the opponent plays the next ranked match at, after [played]
  /// ranked matches that left the player's rating (or, while placing, the
  /// estimate) at [rating]: the estimate itself while placing; after that
  /// the rating plus a draw ([draw]) from the seed for [played].
  static double opponentFor({required int played, required double? rating}) {
    final at = rating ?? start;
    if (isPlacement(played)) return _held(at);
    return _held(at + draw(math.Random(IkkiuchiRankedTuning.drawSeed + played)));
  }

  /// How far from the player's rating Tobi plays a rated match.
  static const rankedDraw =
      TruncatedNormal(sd: IkkiuchiRankedTuning.drawSd, cutOff: IkkiuchiRankedTuning.drawCutOff);

  /// One draw of [rankedDraw] from [rng], in whole points.
  static double draw(math.Random rng) => rankedDraw.sample(rng).roundToDouble();

  /// The player's expected score, 0 to 1, at [rating] against an opponent
  /// at [opponent]: a half when even.
  static double expected(double rating, double opponent) =>
      1 / (1 + math.pow(10, (opponent - rating) / IkkiuchiRankedTuning.eloScale));

  /// K for a match after [rated] matches that moved the rating Elo-style.
  static double kAfter(int rated) => rated < IkkiuchiRankedTuning.provisionalMatches
      ? IkkiuchiRankedTuning.provisionalK
      : IkkiuchiRankedTuning.establishedK;

  /// The rating after [match], when the ranked matches before it were
  /// [earlier], oldest first, and left the rating (or the estimate) at
  /// [rating].
  static double after(IkkiuchiRatedMatch match, {required List<IkkiuchiRatedMatch> earlier, required double? rating}) {
    final at = rating ?? start;
    final played = earlier.length;
    if (isPlacement(played)) {
      return _held(at + (match.won ? 1 : -1) * IkkiuchiRankedTuning.placementSteps[played]);
    }
    final k = kAfter(played - placementMatches);
    return _held(at + k * ((match.won ? 1 : 0) - expected(at, match.opponentRating)));
  }
}
