part of '../config.dart';

/// The dev-mode play overlay (`PlayDebugOverlay`).
abstract final class DebugOverlayStyle {
  static const Duration refresh = Duration(milliseconds: 400);
  static const double fontSize = 11;
  static const Color textColor = Color(0xFFB6FF9C);
  static const double lineHeight = 1.4;
  static const Color background = Color(0xB0000000);
  static const double radius = 6;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);

  /// A table readout: its labels dimmer than the values, the line starting
  /// each part brighter, the gap between a label and its value, and between
  /// tables side by side.
  static const Color labelColor = Color(0xFF8FBF80);
  static const Color headColor = Color(0xFFFFE08A);
  static const double columnGap = 10;
  static const double tableGap = 16;
}

/// The full version name shown in Settings on iOS, macOS and Windows, which
/// only get a plain number from the platform. The build scripts and CI pass it
/// as `--dart-define=BUILD_NAME=...`.
abstract final class VersionDefine {
  static const String key = 'BUILD_NAME';
  static const String buildName = String.fromEnvironment(key);
}

/// The hidden developer-mode unlock (tapping the About version).
abstract final class DevModeTuning {
  static const int tapsRequired = 25;

  /// Below this many taps left, a countdown toast appears.
  static const int countdownFrom = 3;

  /// Once unlocked, Settings scrolls down to the new Developer section.
  static const Duration revealScroll = Duration(milliseconds: 450);
}

/// Settings › Developer › "Preview celebrations": the spec mock's numbers.
abstract final class CelebrationPreviewTuning {
  /// The island completed (the mock's 3rd).
  static const int island = 2;

  /// The rank-up from `Rating.bands[rankFrom]` (F上級) to the next class:
  /// from [rankBelow] points under its threshold to [rankAbove] over it.
  static const int rankFrom = 2;
  static const double rankBelow = 58;
  static const double rankAbove = 14;

  /// "Preview rating": [ratingInto] points into the same class, gaining
  /// [ratingGain].
  static const double ratingInto = 250;
  static const double ratingGain = 26;

  /// The personal best: [cards] cards averaging [averageUs], spread evenly
  /// [spreadUs] apart, [total] in all against a [previousBest].
  static const int cards = 20;
  static const int averageUs = 642000;
  static const int spreadUs = 20000;
  static const total = Duration(milliseconds: 14906);
  static const previousBest = Duration(milliseconds: 15380);

  /// The run's XP, one line per source (count, XP), starting [levelShort]
  /// XP short of the level after [level].
  static const List<(XpSource, int, int)> xp = [
    (XpSource.correct, 27, 270),
    (XpSource.missed, 3, 6),
    (XpSource.speed, 15, 110),
    (XpSource.reviews, 9, 45),
    (XpSource.newCards, 3, 75),
    (XpSource.clear, 1, 20),
    (XpSource.daily, 5, 90),
    (XpSource.best, 1, 100),
    (XpSource.island, 1, 10000),
    (XpSource.graduation, 1, 1000),
  ];
  static const int level = 7;
  static const int levelShort = 1500;

  /// "Preview XP": a typical round's XP, landing [roundInto] XP into
  /// [level] before it and reaching no new level.
  static const List<(XpSource, int, int)> xpRound = [
    (XpSource.correct, 28, 280),
    (XpSource.missed, 2, 4),
    (XpSource.speed, 12, 85),
    (XpSource.reviews, 8, 40),
    (XpSource.clear, 1, 20),
    (XpSource.daily, 3, 70),
  ];
  static const int roundInto = 150;

  /// "Preview AnkiRen XP": a ranked 暗記練 game's XP, one line per source
  /// (count, XP), landing [ankirenRoundInto] XP into [ankirenLevel] and
  /// reaching no new level, or starting [ankirenLevelShort] XP short of the
  /// next and reaching it.
  static const List<(XpSource, int, int)> ankirenXp = [
    (XpSource.firstTap, 12, 960),
    (XpSource.nearMiss, 3, 100),
    (XpSource.missed, 1, 2),
    (XpSource.speed, 15, 320),
    (XpSource.clear, 1, 20),
    (XpSource.ranked, 1, 50),
    (XpSource.best, 1, 200),
  ];
  static const int ankirenLevel = 40;
  static const int ankirenRoundInto = 60;
  static const int ankirenLevelShort = 1000;

  /// 暗記練's rating page: [ankirenInto] points into `Rating.bands[ankirenClass]`
  /// (E下級), moving [ankirenMove]; a breakthrough or a fall crosses its
  /// threshold by [ankirenCross]. Placement: the games' scores, the rating
  /// after the second and after the third, and the game played after
  /// placement.
  static const int ankirenClass = 3;
  static const double ankirenInto = 60;
  static const double ankirenMove = 58;
  static const double ankirenCross = 24;
  static const List<int> ankirenPlacementScores = [612, 845, 903];
  static const double ankirenPlacing = 1010;
  static const double ankirenPlaced = 1180;
  static const int ankirenGame = 9;

  /// Today's set done (the mock's day): the bar's looks for reviews, new
  /// cards and misses, over [dayRounds] runs, with [dayNewCards] new cards,
  /// [dayMisses] misses fixed and a goal streak of [dayStreak] days.
  static const int dayReviewLooks = 22;
  static const int dayNewLooks = 16;
  static const int dayExtraLooks = 6;
  static const int dayRounds = 2;
  static const int dayNewCards = 4;
  static const int dayMisses = 6;
  static const int dayStreak = 5;
}

/// The developer page's figures for Tobi's exam time.
abstract final class DebugTuning {
  /// Draws of `TobiPace` the average and spread are taken over, from [tobiSeed].
  static const int tobiSamples = 2000;
  static const int tobiSeed = 1;
}
