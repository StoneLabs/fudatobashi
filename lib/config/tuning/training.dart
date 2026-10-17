part of '../config.dart';

/// The spaced-repetition trainer: `TrainerConfig` defaults, the session
/// planner's scoring weights, and `PlaySession`'s in-training requeue policy.
abstract final class TrainingTuning {
  static const int defaultBatchSize = 3;

  /// Cards in a 修行 round: journey mode, and all-known mode (a player who
  /// knows every card gets a longer round).
  static const int defaultSessionLength = 30;
  static const int allKnownSessionLength = 50;

  /// A correct answer at or under this time, ms, is graded Easy, whatever
  /// the goal.
  static const int defaultEasyMs = 300;

  /// Debug page range of [defaultEasyMs], ms.
  static const int easyMsMin = 100;
  static const int easyMsMax = 1000;
  static const int easyMsStep = 50;

  /// Time / goal at or below which a correct answer is graded Good (else Hard).
  static const double defaultGoodRatio = 1.5;
  static const double defaultDesiredRetention = 0.9;

  /// FSRS stability (days) needed, together with being solid, to count as
  /// mastered.
  static const double defaultMasteryStabilityDays = 2;

  /// Goal ladder: projected 100-card time (ms), loosest to tightest.
  static const List<int> defaultGoalsMs = [3000, 2500, 2000, 1500, 1200, 1000, 800, 600];

  /// Share of a session reserved for due reviews.
  static const double dueShare = 0.6;

  /// Scheduling weight of a new card: never seen, or seen but with fewer than
  /// [newCardMinTimed] timed attempts.
  static const double freshWeight = 6;

  /// Timed attempts that end a card's "new" status. The next batch also waits
  /// until every card of the latest batch has this many.
  static const int newCardMinTimed = 3;

  /// Share of a session that new cards' reserved slots may fill.
  static const double newCardMaxShare = 0.5;

  /// A run opens with this many swipes of known cards before a new card's
  /// first appearance (when that many are in the session).
  static const int newCardHoldBack = 5;

  /// Clamp on the ewma/goal "slowness" ratio used in the scheduling weight.
  static const double slownessClampMin = 0.3;
  static const double slownessClampMax = 4.0;

  /// Extra scheduling weight per unit of recent miss rate.
  static const double missWeightFactor = 3;

  /// Days since last seen after which the recency boost stops growing.
  static const double recencyCapDays = 2;

  /// Extra scheduling weight for unlocked-but-not-yet-solid cards.
  static const double unsolidWeightMultiplier = 2;

  /// Scheduling weight for solid cards kept only for maintenance.
  static const double maintenanceWeightMultiplier = 0.5;

  /// How many of the most recent picks a card must clear before it may repeat.
  static const int recentRepeatWindow = 3;

  /// A session queue may grow at most this much beyond its planned length
  /// (training's in-session requeue after a miss).
  static const double requeueCapGrowth = 1.5;

  /// Default gap, in cards, before a requeued card reappears.
  static const int requeueGap = 4;
}

/// One journey pace: how many days it targets for all 100 cards, how many
/// new cards it may auto-unlock in one day (catching up after days off), and
/// the daily practice it is built for: [dailyRounds] training rounds, which a
/// capable player needs to keep up (the pacing simulations' routine). With
/// more than [pauseNewOver] reviews in today's set, Home asks whether to
/// pause today's new cards.
class PaceProfile {
  const PaceProfile({
    required this.daysToAll,
    required this.dailyAutoCap,
    required this.dailyRounds,
    required this.pauseNewOver,
  });
  final int daysToAll;
  final int dailyAutoCap;
  final int dailyRounds;
  final int pauseNewOver;
}

/// Journey pacing: when new cards arrive (`Trainer.unlockEarned`,
/// `Trainer.paceStatus`).
///
/// A new batch auto-unlocks when the player is ready (most unlocked cards are
/// solid and the latest batch has been practised) and the unlocked count is
/// behind the pace curve. So the goal is flexible: a capable player on the
/// pace's routine keeps up with the curve, while one who keeps forgetting is
/// held back until the cards they have are solid. Home's "Learn ahead"
/// pulls cards in ahead of the curve (see [LearnAheadTuning]).
abstract final class PaceTuning {
  static const LearningPace defaultPace = LearningPace.month;
  static const PaceProfile month = PaceProfile(daysToAll: 28, dailyAutoCap: 10, dailyRounds: 3, pauseNewOver: 75);
  static const PaceProfile sprint = PaceProfile(daysToAll: 15, dailyAutoCap: 16, dailyRounds: 6, pauseNewOver: 150);

  /// The pace curve: (share of the pace's days elapsed, share of all cards
  /// expected unlocked), linearly interpolated. Front-loaded, since the
  /// one-kana island and the first islands are the easiest.
  static const List<(double, double)> curve = [(0, 0.06), (0.25, 0.31), (0.5, 0.6), (1, 1)];

  /// Share of unlocked upright cards that must be solid before more arrive.
  static const double readySolidFraction = 0.8;

  /// Journey days the debug page's pace table looks ahead of today.
  static const int debugLookaheadDays = 3;
}

/// Home's "Learn ahead" (`Trainer.learnAhead`), for players who learn
/// faster than their pace: it opens only once the unlocked cards are well
/// remembered (`Trainer.wellRemembered`) and the pace has no new cards left
/// for today, and it brings in no more than [maxNewCardsPerDay] a day.
abstract final class LearnAheadTuning {
  /// Latest attempts a remembered card is judged over: at most this share of
  /// them missed.
  static const int recentWindow = 5;
  static const double maxRecentMissRate = 0.2;

  /// A quick card's latest this many timed answers take [quickMs] or less on
  /// average.
  static const int speedWindow = 3;
  static const double quickMs = 3000;

  /// Learn ahead opens once at least this share (%) of the unlocked cards
  /// are quick as well as remembered; every one must be remembered.
  static const int minQuickPercent = 90;

  /// New cards a day may bring in all, the morning's and Learn ahead's.
  static const int maxNewCardsPerDay = 20;
}

/// Journey's today's set (`TodaySet`) and the runs that play it (`StepPlan`):
/// every card in the set needs a few looks today, counted in cards rather
/// than minutes, and a miss brings a card back until it is answered right a
/// few times in a row. The day starts at a local hour of the player's choice.
abstract final class TodaySetTuning {
  static const int defaultDayStartHour = 4;
  static const int firstDayStartHour = 0;
  static const int lastDayStartHour = 9;

  /// Moving the day start later never makes a day shorter than this.
  static const Duration shortestDay = Duration(hours: 12);

  /// Correct looks a card needs today: a due review, and a new card.
  static const int reviewLooks = 2;
  static const int newLooks = 4;

  /// After a miss, correct answers in a row that settle the card for today.
  static const int relearnLooks = 2;

  /// Cards shown before a card comes back: after a new card's 1st, 2nd and
  /// 3rd correct look (the last repeats), after a review's correct look,
  /// after a miss and then each correct look in a row (the last repeats),
  /// and between the picks of one card in a batch of 30.
  static const List<int> newGaps = [3, 8, 20];
  static const List<int> reviewGaps = [20];
  static const List<int> relearnGaps = [4, 12];
  static const int batchGap = 4;

  /// A new card's first look comes at least this many cards after the
  /// previous new card's, while reviews are left to show in between.
  static const int newSpacing = 4;

  /// The morning's guess at the extra looks misses will add: the recent miss
  /// rate over this many training swipes (this rate without any), times the
  /// set's looks, at least [missGuessMin].
  static const int missGuessWindow = 200;
  static const double missGuessDefault = 1 / 12;
  static const int missGuessMin = 1;

  /// Days on Home's week stamps.
  static const int weekDays = 7;
}

/// 苦手 (`WeakCards`, `StepPlan.forWeak`): which card sides are weak, and the
/// drill that works on them. A side is weak when it was missed lately or its
/// expected time is over [lineRatio] × the player's usual card time (the
/// median of every played side's), so a player who knows every card still
/// has weak ones: the slow ones.
abstract final class WeakTuning {
  static const double lineRatio = 1.25;

  /// A miss among a side's latest this many attempts makes it weak.
  static const int recentMissLooks = 3;

  /// Weak sides a drill works on, worst first.
  static const int targets = 8;

  /// Answers in a row under the line that clear a weak side, and the most
  /// looks it gets in one drill before it is left for the next one.
  static const int clearLooks = 2;
  static const int maxLooks = 4;

  /// Cards shown before a weak side comes back: after a miss or a slow
  /// answer, then after each fast one in a row (the last repeats).
  static const List<int> gaps = [3, 6];

  /// One quick card the player already does well comes after every this
  /// many weak sides, and [fillers] of them wait in between when every weak
  /// side left still has to wait its gap.
  static const int anchorEvery = 2;
  static const int fillers = 12;

  /// A drill ends after this many swipes at most.
  static const int maxSwipes = 40;
}

/// Free practice (始める): locked in journey mode until this many cards are
/// well remembered at once (`Trainer.wellRemembered`); from then on it stays
/// open for good.
abstract final class FreePracticeTuning {
  static const int unlockRemembered = 50;
}
