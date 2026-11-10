part of '../config.dart';

/// The app's class (級) thresholds, shared by every ranked mode: the rating
/// at or above which each class is reached (入門 has none; see `RankLadder`).
abstract final class RankLadderTuning {
  static const double fLowerMinRating = 793;
  static const double fUpperMinRating = 1217;
  static const double eLowerMinRating = 1642;
  static const double eUpperMinRating = 1865;
  static const double dMinRating = 2084;
  static const double cMinRating = 2435;
  static const double bMinRating = 2559;
  static const double aMinRating = 2786;
}
