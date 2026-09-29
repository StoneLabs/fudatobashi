import '../config/config.dart';

/// Where a run's experience came from, in the order the XP page lists it.
enum XpSource { correct, missed, speed, reviews, newCards, clear, daily, best, island, graduation }

/// One swipe of a recorded run, as experience sees it.
class XpSwipe {
  const XpSwipe({
    required this.poemId,
    required this.correct,
    required this.clean,
    required this.us,
    required this.graded,
  });

  final int poemId;
  final bool correct;

  /// Its time is a clean measurement: an undone swipe, or the redo after
  /// one, never is.
  final bool clean;
  final int us;

  /// FSRS graded it: a due card, or a miss.
  final bool graded;
}

/// A recorded run, as experience sees it.
class XpRun {
  const XpRun({
    required this.sessionId,
    required this.startedAt,
    required this.setup,
    required this.total,
    required this.goalMs,
    required this.counts,
    required this.swipes,
    this.islands = 0,
    this.graduated = false,
  });

  final int sessionId;
  final DateTime startedAt;

  /// Runs with the same setup race each other for a personal best.
  final String setup;

  /// Null when the run was ended early.
  final Duration? total;

  /// The goal time per card when the run was played.
  final double goalMs;

  /// The run feeds training (its first meetings are new cards).
  final bool counts;
  final List<XpSwipe> swipes;

  /// Islands the run completed.
  final int islands;

  /// The run learned the journey's last card.
  final bool graduated;
}

/// One line of a run's experience: [count] things (cards, streak days,
/// islands; 1 for a one-off bonus) worth [xp] in all.
class XpPart {
  const XpPart(this.source, this.count, this.xp);
  final XpSource source;
  final int count;
  final int xp;
}

/// The experience one run earned, line by line.
class XpAward {
  const XpAward(this.parts);

  /// Only the sources that earned something, in [XpSource] order.
  final List<XpPart> parts;

  int get total => parts.fold(0, (sum, p) => sum + p.xp);
}

/// A player level, and how far into it an XP total is.
class XpLevel {
  const XpLevel(this.level, this.into, this.span);

  /// 1 at the start.
  final int level;

  /// XP earned since reaching [level].
  final int into;

  /// XP [level] takes to get through.
  final int span;

  double get fraction => into / span;
  int get toNext => span - into;
}

/// The level curve: each level takes [XpTuning.levelStep] more XP than the
/// one before it.
abstract final class XpCurve {
  /// XP it takes to get through [level].
  static int span(int level) => XpTuning.firstLevel + XpTuning.levelStep * (level - 1);

  /// Total XP at which [level] is reached.
  static int reach(int level) {
    final n = level - 1;
    return XpTuning.firstLevel * n + XpTuning.levelStep * n * (n - 1) ~/ 2;
  }

  static XpLevel of(int total) {
    var level = 1;
    while (reach(level + 1) <= total) {
      level++;
    }
    return XpLevel(level, total - reach(level), span(level));
  }
}

/// What a run did to the player's experience.
class XpGain {
  const XpGain({required this.before, required this.award});

  /// Total XP before the run.
  final int before;
  final XpAward award;

  int get after => before + award.total;
  XpLevel get levelBefore => XpCurve.of(before);
  XpLevel get levelAfter => XpCurve.of(after);
  int get levelsGained => levelAfter.level - levelBefore.level;
}

/// Every run's experience, added up oldest first: which cards were already
/// met, the best time per setup and the streak of days all depend on the
/// runs before.
class XpLedger {
  XpLedger();

  /// The ledger of [runs], in the order they were played.
  factory XpLedger.of(Iterable<XpRun> runs) {
    final ledger = XpLedger();
    for (final r in [...runs]..sort(_played)) {
      ledger.add(r);
    }
    return ledger;
  }

  static int _played(XpRun a, XpRun b) {
    final t = a.startedAt.compareTo(b.startedAt);
    return t != 0 ? t : a.sessionId.compareTo(b.sessionId);
  }

  int _total = 0;
  bool _graduated = false;
  final _met = <int>{};
  final _best = <String, Duration>{};
  DateTime? _lastDay;
  int _streak = 0;

  int get total => _total;
  XpLevel get level => XpCurve.of(_total);

  /// A recorded run already graduated (it happens once).
  bool get graduated => _graduated;

  /// Adds [run], played after every run added so far, and returns what it
  /// earned.
  XpGain add(XpRun run) {
    final gain = XpGain(before: _total, award: _score(run));
    _total = gain.after;
    _graduated |= run.graduated;
    return gain;
  }

  XpAward _score(XpRun run) {
    var correct = 0, missed = 0, fast = 0, speedXp = 0, reviews = 0, fresh = 0;
    for (final s in run.swipes) {
      final isNew = run.counts && _met.add(s.poemId);
      if (isNew) fresh++;
      if (!s.correct) {
        if (s.clean) missed++;
        continue;
      }
      correct++;
      if (s.graded && !isNew) reviews++;
      if (!s.clean) continue;
      final bonus = s.us <= run.goalMs * 1000 * XpTuning.blazingRatio
          ? XpTuning.speedBlazing
          : s.us <= run.goalMs * 1000
              ? XpTuning.speedAtGoal
              : 0;
      if (bonus > 0) fast++;
      speedXp += bonus;
    }

    final day = DateTime(run.startedAt.year, run.startedAt.month, run.startedAt.day);
    final last = _lastDay;
    final firstToday = last == null || day.isAfter(last);
    if (firstToday) {
      _streak = last != null && DateTime(last.year, last.month, last.day + 1) == day ? _streak + 1 : 1;
      _lastDay = day;
    }

    final total = run.total;
    final previous = _best[run.setup];
    final best = total != null && previous != null && total < previous;
    if (total != null && (previous == null || total < previous)) _best[run.setup] = total;

    final streakDays = (_streak - 1).clamp(0, XpTuning.streakCapDays);
    return XpAward([
      for (final p in [
        XpPart(XpSource.correct, correct, correct * XpTuning.perCorrect),
        XpPart(XpSource.missed, missed, missed * XpTuning.perMiss),
        XpPart(XpSource.speed, fast, speedXp),
        XpPart(XpSource.reviews, reviews, reviews * XpTuning.perReview),
        XpPart(XpSource.newCards, fresh, fresh * XpTuning.perNewCard),
        XpPart(XpSource.clear, 1, total != null ? XpTuning.clear : 0),
        XpPart(XpSource.daily, _streak, firstToday ? XpTuning.daily + streakDays * XpTuning.perStreakDay : 0),
        XpPart(XpSource.best, 1, best ? XpTuning.personalBest : 0),
        XpPart(XpSource.island, run.islands, run.islands * XpTuning.perIsland),
        XpPart(XpSource.graduation, 1, run.graduated ? XpTuning.graduation : 0),
      ])
        if (p.xp > 0) p,
    ]);
  }
}
