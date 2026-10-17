part of '../config.dart';

/// How one kind of simulated player (`SyntheticLearner`) learns: response
/// times, how memories of cards fade and grow, and how it mixes cards up.
/// Each value notes its source; "guess" marks the ones to calibrate against
/// real players.
class LearnerProfile {
  const LearnerProfile({
    required this.firstMs,
    required this.firstPerKanaMs,
    required this.floorMs,
    required this.floorPerKanaMs,
    required this.practiceExponent,
    required this.firstStability,
    required this.recallGrowth,
    required this.cardSpread,
    required this.mixUpRate,
    required this.lookAlikeRate,
    required this.lookAlikeFadeDays,
    required this.slipRate,
    required this.rushSlipRate,
  });

  /// First-sight response time, ms, plus this much per extra kimariji kana.
  final double firstMs;
  final double firstPerKanaMs;

  /// Practised-to-the-limit response time, ms, plus this much per extra kana.
  final double floorMs;
  final double floorPerKanaMs;

  /// Power law of practice: after n repetitions the gap to the floor is
  /// (1 + n)^-[practiceExponent] of the first one.
  final double practiceExponent;

  /// Memory stability (the gap after which recall falls to 90%) of a card
  /// just introduced and answered once.
  final Duration firstStability;

  /// Stability gain from a correct recall at recall chance R:
  /// S × ([SyntheticLearnerTuning.massedGrowth] + recallGrowth ×
  /// (e^([SyntheticLearnerTuning.spacingGrowth] × (1 − R)) − 1)), so a recall
  /// after a long gap does far more than one minutes later.
  final double recallGrowth;

  /// How differently single cards stick: the σ of a log-normal factor on
  /// each card's first stability.
  final double cardSpread;

  /// Chance of mixing a card just met (or relearned after a miss) up with
  /// the cards met around it, kept by [SyntheticLearnerTuning.mixUpKept]
  /// with each correct answer.
  final double mixUpRate;

  /// Chance of taking a card for one of its 友札 once it has met that 友札,
  /// fading by e over [lookAlikeFadeDays] days with a correct answer.
  final double lookAlikeRate;
  final double lookAlikeFadeDays;

  /// Miss chance on a card it does remember: any time, plus [rushSlipRate]
  /// when answering faster than its usual pace for the card
  /// ([SyntheticLearnerTuning.rushRatio]).
  final double slipRate;
  final double rushSlipRate;
}

/// The synthetic player (`SyntheticLearner`) behind the pacing simulations,
/// the debug page's Simulation and dev-mode demo data.
abstract final class SyntheticLearnerTuning {
  /// Picks up cards fast, and they stick.
  static const LearnerProfile quick = LearnerProfile(
    firstMs: 3000, // guess
    firstPerKanaMs: 300, // guess
    floorMs: 600, // guess
    floorPerKanaMs: 80, // guess
    practiceExponent: 0.6, // power law of practice: 0.2–0.6 (Newell & Rosenbloom 1981)
    firstStability: Duration(minutes: 90), // guess
    recallGrowth: 22, // FSRS-6 defaults: ~16 for a card first failed (D 7), ~25 at D 5
    cardSpread: 0.5, // guess
    mixUpRate: 0.2, // guess
    lookAlikeRate: 0.1, // guess
    lookAlikeFadeDays: 3, // guess
    slipRate: 0.01, // easy choice-reaction tasks: 1–3% errors
    rushSlipRate: 0.03, // guess
  );

  /// The player the pace curve is tuned for (and the demo data's).
  static const LearnerProfile average = LearnerProfile(
    firstMs: 3400, // guess
    firstPerKanaMs: 350, // guess
    floorMs: 700, // guess
    floorPerKanaMs: 90, // guess
    practiceExponent: 0.5, // power law of practice: 0.2–0.6 (Newell & Rosenbloom 1981)
    firstStability: Duration(hours: 1), // guess
    recallGrowth: 16, // FSRS-6 defaults: ~16 for a card first failed (D 7)
    cardSpread: 0.6, // guess
    mixUpRate: 0.25, // guess
    lookAlikeRate: 0.15, // guess
    lookAlikeFadeDays: 5, // guess
    slipRate: 0.015, // easy choice-reaction tasks: 1–3% errors
    rushSlipRate: 0.04, // guess
  );

  /// Slow to get quick and forgetful: the pace must stretch for them.
  static const LearnerProfile slow = LearnerProfile(
    firstMs: 4200, // guess
    firstPerKanaMs: 450, // guess
    floorMs: 1000, // guess
    floorPerKanaMs: 120, // guess
    practiceExponent: 0.4, // power law of practice: 0.2–0.6 (Newell & Rosenbloom 1981)
    firstStability: Duration(minutes: 30), // guess
    recallGrowth: 10, // FSRS-6 defaults: ~16 for a card first failed (D 7), ~8 at D 9
    cardSpread: 0.7, // guess
    mixUpRate: 0.4, // guess
    lookAlikeRate: 0.25, // guess
    lookAlikeFadeDays: 7, // guess
    slipRate: 0.03, // easy choice-reaction tasks: 1–3% errors
    rushSlipRate: 0.05, // guess
  );

  /// Recall at a gap equal to the memory's stability (FSRS's definition).
  static const double stabilityRecall = 0.9;

  /// Recall after a gap t at stability S: (1 + f × t / S)^-forgettingDecay,
  /// f set so that recall is [stabilityRecall] at t = S. 1 is FSRS v4's
  /// curve, steeper than FSRS-6's whole-deck 0.2, which is flattened by
  /// cards that differ.
  static const double forgettingDecay = 1;

  /// Stability growth from a recall minutes after the last look (FSRS-6
  /// same-day reviews: ×1.3 for a one-day memory).
  static const double massedGrowth = 1.2;

  /// How steeply recall growth rises as the recall chance falls (FSRS-6
  /// default w10).
  static const double spacingGrowth = 1.0178;

  /// Share of stability kept after forgetting a card (FSRS-6 defaults:
  /// 20–50% of a 1–10 day memory).
  static const double lapseKept = 0.3;

  /// Share of the mix-up chance left after each correct answer (guess).
  static const double mixUpKept = 0.6;

  /// Spread (σ) of log response times (choice reaction times vary by
  /// 20–30%).
  static const double timeNoise = 0.25;

  /// An answer quicker than this share of the usual time is a rush (guess).
  static const double rushRatio = 0.8;

  /// Upside-down cards are this much slower (guess).
  static const double invertedFactor = 1.2;

  /// Share of practice (repetitions) kept overnight, and after forgetting
  /// (guess).
  static const double overnightRepsKept = 0.85;
  static const double forgottenRepsKept = 0.5;

  /// Practice counted for a missed answer, against 1 for a correct one.
  static const double missRep = 0.5;

  /// Gap between two cards' wall-clock timestamps beyond the response time.
  static const Duration cardGap = Duration(milliseconds: 250);

  /// Swipe duration from the response (finger moving) to the commit.
  static const Duration responseToCommit = Duration(milliseconds: 80);
  static const Duration commitToNextReveal = Duration(milliseconds: 120);

  /// A simulated day's rounds are spread between these local hours, each
  /// starting up to [roundStartJitterMinutes] late.
  static const int firstRoundHour = 8;
  static const int lastRoundHour = 21;
  static const int roundStartJitterMinutes = 40;
}

/// The debug Simulation page (`simulatePace`): a journey played by a
/// simulated learner, day by day, on a throwaway database.
abstract final class SimulationTuning {
  static const int defaultDays = 30;
  static const int minDays = 7;
  static const int maxDays = 60;

  /// The learner's and planner's seed. With FSRS's interval fuzz off, a
  /// rerun replays exactly.
  static const int seed = 1;

  /// Local hour at which a simulated day's set is looked at (any hour of
  /// the day's practice window).
  static const int setCheckHour = 12;

  /// Time between one simulated sitting's end and the next one's start.
  static const Duration sittingGap = Duration(hours: 2);

  /// Safety stop on the sittings a simulated day plays to finish its set.
  static const int maxSittingsPerDay = 20;

  /// Dev-tools simulation: the chance a simulated day is skipped entirely.
  static const double skipDayShare = 0.2;

  /// Dev-tools simulation: the shares of days played in 1, 2, 3 and 4 runs.
  static const List<double> runShares = [0.6, 0.2, 0.1, 0.1];
}

/// Dev-mode demo data (`seedDemoData`): a journey player's recent history,
/// simulated day by day through the real training path.
abstract final class DemoDataTuning {
  /// Days simulated, ending yesterday.
  static const int days = 21;

  /// A free-play run happens every this many simulated days.
  static const int freeRunEvery = 3;
  static const int freeCards = 10;

  /// Fixed default seed, so seeding the same device twice (and this
  /// feature's own test) reproduces the same journey.
  static const int seed = 1179;

  /// The ranked demo (all-known mode), which has no training: days are
  /// skipped at [SimulationTuning.skipDayShare]; the others have 1, 2 or 3
  /// ranked runs by these shares.
  static const List<double> rankedRunShares = [0.5, 0.3, 0.2];

  /// Every this many days, a day with ranked runs ends in a 苦手 run at
  /// [practiceHour] (and every [freeRunEvery] days, in a free-play run).
  static const int rankedWeakEvery = 2;
  static const int practiceHour = 22;
}
