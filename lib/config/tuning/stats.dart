part of '../config.dart';

/// `CardStats`: how recent response times and misses are summarised.
abstract final class StatsTuning {
  /// Attempts at which the EWMA's weight on an old sample halves.
  static const int ewmaHalfLifeAttempts = 5;

  /// `1 - 2^(-1/ewmaHalfLifeAttempts)`, precomputed since `dart:math`'s `pow`
  /// is not a const function.
  static const double ewmaAlpha = 0.12944943670387588;

  /// Minimum timed attempts before a card can be judged "solid".
  static const int solidMinTimed = 3;

  /// Attempts window "solid" is judged over: all correct, median within goal.
  static const int solidWindow = 5;

  /// Default window for `missRate`.
  static const int missWindowDefault = 10;

  /// Assumed time (ms) for a miss or an unseen card, in expected-time and
  /// rating projections.
  static const double unknownMs = 6000;

  /// How far back `Progress.knownCardSpeedTrendAgo` looks, to compare against
  /// `Progress.knownCardSpeedMs`.
  static const int knownSpeedTrendDays = 7;

  /// The archipelago map (Stats): fewer training attempts than this and a
  /// card's dot is hollow ("too few attempts to judge") instead of coloured
  /// by speed.
  static const int mapHollowMinTries = 5;

  /// TOP SPEED (card detail): the fast end of a card's recent times, this
  /// percentile of its last [topSpeedWindow] timed attempts. Steadier than
  /// the single best time, which one lucky swipe sets for good.
  static const double topSpeedPercentile = 5;
  static const int topSpeedWindow = 100;
}

/// The island detail and card detail screens (`lib/ui/stats/island_screen.dart`,
/// `lib/ui/stats/card_detail_screen.dart`).
abstract final class CardDetailTuning {
  /// Attempts shown in the island row's per-card sparkline.
  static const int sparklineTail = 12;

  /// A card due within this many days shows "in Nd" instead of a full date.
  static const int dueSoonDays = 6;
}

/// Fixed ranges of the FSRS model, for display.
abstract final class FsrsScale {
  /// FSRS difficulty runs from 1 to this.
  static const int difficultyMax = 10;
}

/// The card detail's attempt chart (`AttemptChart` in
/// `lib/ui/stats/stats_charts.dart`).
abstract final class AttemptChartTuning {
  /// The rolling averages (avg5, avg10, avg50): each line starts once its
  /// window of timed attempts is full.
  static const int shortAverage = 5;
  static const int midAverage = 10;
  static const int longAverage = 50;

  /// The band: these percentiles of the last [bandWindow] timed attempts,
  /// drawn from the [bandMinCount]th timed attempt on.
  static const double bandLow = 5;
  static const double bandHigh = 95;
  static const int bandWindow = 20;
  static const int bandMinCount = 10;

  /// The ms axis: the dots' range widened by these margins, then rounded out
  /// to the smallest of [axisSteps] that needs at most [maxGridLines]
  /// gridlines (doubling the largest step if none does).
  static const double axisPadBelowMs = 60;
  static const double axisPadAboveMs = 40;
  static const List<int> axisSteps = [50, 100, 200, 250, 500, 1000, 2000, 5000];
  static const int maxGridLines = 5;
}

/// The SRS page (`lib/ui/stats/srs_screen.dart`).
abstract final class SrsTuning {
  /// A card swiped fewer times than this is "New".
  static const int newBelowSwipes = 3;

  /// Days the time and speed charts show, today included.
  static const int chartDays = 14;

  /// Days the known-cards trend looks back over.
  static const int trendDays = 7;

  /// A card's typical time: the median of its last this many right swipes.
  static const int typicalWindow = 10;

  /// A recall chance under this is marked in the card table.
  static const double lowRecall = 0.8;
}

/// The practice calendar's shades: swipes in a day for a usual day and
/// for a lot.
abstract final class CalendarTuning {
  static const int usualSwipes = 30;
  static const int lotSwipes = 100;
}
