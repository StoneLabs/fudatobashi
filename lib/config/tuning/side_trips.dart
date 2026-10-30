part of '../config.dart';

/// When the side trips (寄り道, `SideTripUnlocks`) open in journey mode; from
/// then on they stay open for good. All-known mode opens them all.
abstract final class SideTripTuning {
  /// The Side Trips tab: this many cards well remembered at once, free
  /// practice's counter.
  static const int tabRemembered = 25;

  /// 暗記練's free play: this many cards seen (`Progress.knownCards`); its
  /// ranked games need more (`RankedLock`).
  static const int ankirenSeen = 50;

  /// 定位置: this many cards seen, enough for its usual game of
  /// `TeiichiTuning.cards`.
  static const int teiichiSeen = 25;
}

/// How a swipe turns the Side Trips tab's ring of islands (`SideTripRing`).
abstract final class SideTripRingTuning {
  /// A drag across this share of the screen's width turns the ring one
  /// step, so the entries ride under the finger.
  static const double dragPerStep = 1;

  /// A release at least this fast, px/s, turns on to the next step in its
  /// direction; a slower one settles on the nearest.
  static const double flingSpeed = 320;

  /// Under reduced motion nothing follows the finger: a swipe at least
  /// this long, px (or a fling), turns the ring a step.
  static const double stillSwipe = 48;
}
