part of '../config.dart';

/// History's run page, Speed tab (see `RunSpeed`).
abstract final class RunSpeedTuning {
  /// Cards in a block of the pace chart, and in the fastest stretch.
  static const int blockCards = 10;

  /// A right swipe over this many times the goal counts as slow on the
  /// card strip.
  static const double slowRatio = 1.5;
}

/// History's run page, Rating and XP tab.
abstract final class RunRatingTuning {
  /// The latest ranked runs listed under the rating chart.
  static const int tableRuns = 10;

  /// How wide the class bar is when a class has no upper or lower bound,
  /// in rating points.
  static const double openSpan = 400;
}

/// History's 暗記練 game page (see `AnkirenReview`): the cards it lists as
/// kept misplacing.
abstract final class AnkirenReviewTuning {
  /// A card is listed once it was dealt this often, at most this many rows.
  static const int misplacedMinDealt = 2;
  static const int misplacedRows = 4;

  /// Below this share found with the first tap, its row is marked.
  static const double misplacedMarkBelow = 0.5;
}

/// History's run page (see `RunTimeline`, `RunCards`).
abstract final class RunReviewTuning {
  /// The time graph's bottom is never past this many times the run's own
  /// time, so its line fills at least 1 / this of the height.
  static const double graphReach = 2;

  /// Earlier runs of the same kind the time graph measures against.
  static const int references = 10;

  /// Slowest and fastest cards shown on the Cards tab.
  static const int shownCards = 3;

  /// A card's usual time: the median of its last this many right swipes
  /// before the run.
  static const int usualWindow = 10;
}
