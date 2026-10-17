part of 'progress.dart';

/// What a finished run changed (for the results screen).
class SessionReport {
  SessionReport({
    required this.runId,
    required this.completed,
    required this.total,
    required this.attempts,
    required this.previousBest,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.goalRaised,
    this.newCards = const [],
    this.islandsReached = const [],
    this.islandsCompleted = const [],
    this.xp,
    this.graduated = false,
    this.dayDone,
    this.mode = PlayMode.free,
    this.score,
    this.tobi,
    this.weakBefore,
    this.weakAfter,
  });

  final int? runId;
  final PlayMode mode;

  /// A ranked run's or an exam try's time with its penalties (see
  /// [RankedScore]); null for other runs.
  final RankedScore? score;

  /// Tobi's time in an exam try.
  final Duration? tobi;

  /// 苦手: cards with a weak side before and after the drill.
  final int? weakBefore, weakAfter;

  /// A ranked run left before its last card.
  bool get forfeit => mode == PlayMode.ranked && !completed;

  /// This ranked run set the first rating.
  bool get placement => mode == PlayMode.ranked && ratingBefore == null && ratingAfter != null;

  /// An exam try played to the end faster than Tobi.
  bool get passed => mode == PlayMode.exam && completed && score != null && tobi != null && score!.scored < tobi!;

  /// The run was played to its last card.
  final bool completed;

  /// Null when the run was ended early, or its time is no measurement.
  final Duration? total;
  final List<Attempt> attempts;

  /// Best total for the same setup before this run (null if first).
  final Duration? previousBest;
  final double? ratingBefore;
  final double? ratingAfter;
  final bool goalRaised;

  /// Cards swiped for the first time in this run (journey training), in
  /// order of first appearance.
  final List<int> newCards;

  /// Islands whose first card was unlocked by this run (journey mode).
  final List<int> islandsReached;

  /// Islands completed (all cards solid) for the first time by this run.
  final List<int> islandsCompleted;

  /// Experience earned (tracked runs only).
  final XpGain? xp;

  /// This run learned the journey's 100th card (once ever).
  final bool graduated;

  /// This run finished today's set (journey mode).
  final DayDone? dayDone;

  /// 苦手 drills differ run to run, so they have none.
  bool get personalBest =>
      mode != PlayMode.nigate && total != null && (previousBest == null || total! < previousBest!);
}

/// Today's set as the run that finished it saw it.
class DayDone {
  const DayDone({
    required this.date,
    required this.bar,
    required this.rounds,
    required this.newCards,
    required this.missesFixed,
    required this.goalStreak,
    required this.xp,
  });

  /// The day (a UTC midnight).
  final DateTime date;

  /// The set's bar, all done.
  final SetBar bar;

  /// Training runs the set took.
  final int rounds;
  final int newCards;

  /// Misses on the set's cards, each answered right again since.
  final int missesFixed;

  /// Days in a row with the set done, today included.
  final int goalStreak;
  final int xp;

  /// Looks the set took.
  int get looks => bar.total;
}

/// One of Home's week stamps.
class WeekStamp {
  const WeekStamp({required this.date, required this.done, required this.missed, required this.today});

  /// The day (a UTC midnight).
  final DateTime date;

  /// Today's set was done; the day passed with the set not done.
  final bool done, missed;
  final bool today;
}

/// A training session ready to play, with the scheduler's reasoning.
class PlannedRun {
  PlannedRun(this.cards, this.picks, this.unlockedBefore, this.newPoems, {this.planner, this.ofSet = false});
  final List<CardRef> cards;
  final List<TrainingPick> picks;

  /// The run plays today's set (journey mode, before the day is done).
  final bool ofSet;

  /// Replans the run as it is played (journey: looks spaced in steps, see
  /// [StepPlan]); null for a fixed queue.
  final RunPlanner? planner;

  /// Cards unlocked right before this run.
  final List<ItemKey> unlockedBefore;

  /// Journey mode: cards the player meets for the first time in this run.
  /// Each is introduced with its page right before its first appearance.
  final Set<int> newPoems;
}

/// Whether free practice (始める) is open (see [Progress.freePractice]).
class FreePracticeAccess {
  const FreePracticeAccess({required this.open, required this.remembered});

  final bool open;

  /// Cards well remembered right now (journey mode, while still locked).
  final int remembered;

  /// Cards still to remember before it opens.
  int get needed => math.max(0, FreePracticeTuning.unlockRemembered - remembered);
}

/// The graduation exam's standing (see [Progress.exam]): it opens once
/// every card has been swiped, then allows one try per
/// [ExamTuning.cooldown] until it is passed.
class ExamAccess {
  const ExamAccess({required this.cardsLeft, required this.cooldown, required this.passed});

  /// Cards never swiped yet.
  final int cardsLeft;

  /// Time until the next try, while the last one is too recent.
  final Duration? cooldown;
  final bool passed;

  bool get open => cardsLeft == 0;
  bool get canStart => open && cooldown == null && !passed;
}
