part of '../config.dart';

/// When the side trips (寄り道, `SideTripUnlocks`) open in journey mode: once
/// this many cards are well remembered at once, free practice's counter;
/// from then on they stay open for good. All-known mode opens them all.
abstract final class SideTripTuning {
  /// The Side Trips tab.
  static const int tabRemembered = 25;

  /// 暗記練, its ranked games and free play together; ranked always has
  /// enough known cards to deal from by then.
  static const int ankirenRemembered = 50;
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
