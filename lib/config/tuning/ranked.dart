part of '../config.dart';

/// The Elo-style rating model (see `Rating`).
abstract final class RatingModel {
  /// Assumed slowdown for the inverted side of a card never practised
  /// inverted, relative to its upright expected time.
  static const double invertedPrior = 1.25;

  /// Rating points per doubling of the projected 100-card time (log2 scale).
  static const double pointsPerDoubling = 600;

  /// Reference time (s): performance is 0 at this 100-card time.
  static const double referenceSeconds = 1000;

  /// Where 入門's progress toward the first class starts (入門 has no
  /// threshold): the rating at [referenceSeconds].
  static const double noviceFloor = 0;

  /// Smoothing K while still building confidence (the first
  /// [provisionalSessions] ranked runs after placement).
  static const double provisionalK = 0.5;

  /// Smoothing K once established.
  static const double establishedK = 0.25;
  static const int provisionalSessions = 10;
}

/// Ranked runs (ランク戦, all-known mode): the only runs that move the
/// rating (see `RankedScore`).
abstract final class RankedTuning {
  /// Cards in a ranked run (and in the graduation exam): every card once.
  static const int cards = 100;

  /// Added to a run's clock time for each miss or card marked wrong.
  static const int missPenaltyMs = 10000;

  /// A scored run left early (an exam try) counts every card left as a
  /// miss that took at least this long, or the run's own pace so far when
  /// slower.
  static const double forfeitCardMs = StatsTuning.unknownMs;

  /// The performance a forfeit (a ranked run left early) plays at, however
  /// far it got, so quitting never beats finishing.
  static const double forfeitPerformance = 0;
}

/// The rating page after a run (`RatingOverlay`).
abstract final class RatingScreenTuning {
  /// Shown only when a run raised the displayed (rounded) rating by at
  /// least this many points.
  static const int minGain = 1;

  /// Rating points spanned by the track of a class without a lower bound
  /// (入門, up to the next class) or an upper one (the top class, up from
  /// its own threshold).
  static const double openSpan = 400;
}
