part of '../config.dart';

/// Experience (XP, `XpLedger`): effort rewarded on every tracked run, apart
/// from the rating's measure of skill. Derived from the recorded history, so
/// a change here re-scores every past run too.
abstract final class XpTuning {
  static const int perCorrect = 10;

  /// A card swiped away as "don't know" or marked wrong (undone swipes earn
  /// nothing: their redo is what counts).
  static const int perMiss = 2;

  /// Extra for a correct, cleanly timed swipe at or under the goal time of
  /// its run, more at or under [blazingRatio] of it.
  static const int speedAtGoal = 5;
  static const int speedBlazing = 10;
  static const double blazingRatio = 0.75;

  /// Extra for a due review answered correctly (FSRS graded it).
  static const int perReview = 5;

  /// A card met for the first time in a run that counts.
  static const int perNewCard = 25;

  /// A run played to its last card.
  static const int clear = 20;

  /// The first run of a day, plus [perStreakDay] for each day of the streak
  /// before it, up to [streakCapDays].
  static const int daily = 100;
  static const int perStreakDay = 10;
  static const int streakCapDays = 10;

  /// A completed run faster than the best before it with the same setup.
  static const int personalBest = 200;

  /// A weak side cleared in a 苦手 drill (it has no personal best).
  static const int weakCleared = 15;
  static const int perIsland = 10000;

  /// Finishing today's set (journey mode), once a day.
  static const int dayDone = 1000;

  /// Passing the graduation exam, the end of the journey.
  static const int graduation = 100000;

  /// A ranked run played to its last card, and on top of it the first one,
  /// which places the player on the ladder.
  static const int ranked = 500;
  static const int placement = 1000;

  /// Every try at the graduation exam.
  static const int exam = 300;

  /// Total XP to reach level L: [levelScale] × (L − 1)^[levelExponent].
  /// Fitted on the simulated journeys (research/design): about level 3
  /// after a first day of 100 swipes and about level 60 at graduation.
  /// Each level asks a little more than the last, so levels never run away.
  static const double levelScale = 5500;
  static const double levelExponent = 1.1;
}
