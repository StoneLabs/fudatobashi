import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_xp.dart';
import 'play_session.dart';

/// Where a game's experience came from: the main game's runs ([XpRun]) and
/// 暗記練's games ([AnkirenXpRun]) each list their own, sharing those that
/// mean the same.
enum XpSource {
  correct,
  missed,
  speed,
  reviews,
  newCards,
  clear,
  daily,
  best,
  island,
  graduation,

  /// Journey mode: the run that finished today's set.
  dayDone,

  /// 暗記練: cards found with the first tap, and cards whose taps missed
  /// but landed near enough to earn part of a find.
  firstTap,
  nearMiss,

  /// 暗記練: a ranked game played to the end.
  ranked,

  /// 暗記練: the ranked game that finished placement.
  placement,
}

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

  /// Correct, clean and a valid time (see [Attempt.isValidTime]): it can earn
  /// a speed bonus.
  bool get timed => correct && clean && Attempt.isValidTime(us);
}

/// A recorded run, as experience sees it.
class XpRun {
  const XpRun({
    required this.sessionId,
    required this.startedAt,
    required this.setup,
    required this.completed,
    required this.total,
    required this.goalMs,
    required this.counts,
    required this.swipes,
    this.islands = 0,
    this.graduated = false,
    this.day,
    this.dayDone = false,
  });

  final int sessionId;
  final DateTime startedAt;

  /// Runs with the same setup race each other for a personal best.
  final String setup;

  /// The run was played to its last card.
  final bool completed;

  /// Null when the run was ended early, or its time is no measurement.
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

  /// The practice day it was played on (a UTC midnight); by default the
  /// calendar date it started.
  final DateTime? day;

  /// The run finished today's set.
  final bool dayDone;
}

/// One line of a run's experience: [count] things (cards, streak days,
/// islands; 1 for a one-off bonus) worth [xp] in all.
class XpPart {
  const XpPart(this.source, this.count, this.xp);
  final XpSource source;
  final int count;
  final int xp;
}

/// The experience one game earned, line by line.
class XpAward {
  const XpAward(this.parts);

  /// Only the sources that earned something, in the order the XP page
  /// lists them.
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

/// The level curve: getting through level L takes [XpTuning.levelBase] × √L
/// XP, so each level asks a little more than the last, ever more gently.
abstract final class XpCurve {
  /// XP it takes to get through [level].
  static int span(int level) => (XpTuning.levelBase * math.sqrt(level)).round();

  /// Total XP at which each level is reached, from level 1, grown as needed.
  static final _reach = [0, 0];

  /// Total XP at which [level] is reached.
  static int reach(int level) {
    while (_reach.length <= level) {
      _reach.add(_reach.last + span(_reach.length - 1));
    }
    return _reach[level];
  }

  static XpLevel of(int total) {
    var level = 1;
    while (reach(level + 1) <= total) {
      level++;
    }
    return XpLevel(level, total - reach(level), span(level));
  }
}

/// What a game did to the player's experience.
class XpGain {
  const XpGain({required this.before, required this.award});

  /// Total XP before the game.
  final int before;
  final XpAward award;

  int get after => before + award.total;
  XpLevel get levelBefore => XpCurve.of(before);
  XpLevel get levelAfter => XpCurve.of(after);
  int get levelsGained => levelAfter.level - levelBefore.level;
}

/// Every game's experience, added up oldest first: the main game's runs
/// ([add]) and 暗記練's games ([addAnkiren]) into one total. Which cards were
/// already met, the best time per setup and the streak of days depend on
/// the runs before; 暗記練's bests and placement on its games before
/// ([AnkirenXp]). The daily bonus and its streak are the main game's.
class XpLedger {
  XpLedger();

  /// The ledger of [runs] and [ankiren], each game in the order played (a
  /// run before a 暗記練 game started at the same moment).
  factory XpLedger.of(Iterable<XpRun> runs, [Iterable<AnkirenXpRun> ankiren = const []]) {
    final games = [
      for (final r in runs) (at: r.startedAt, kind: 0, id: r.sessionId, add: (XpLedger l) => l.add(r)),
      for (final g in ankiren) (at: g.startedAt, kind: 1, id: g.runId, add: (XpLedger l) => l.addAnkiren(g)),
    ]..sort((a, b) {
        final t = a.at.compareTo(b.at);
        if (t != 0) return t;
        return a.kind != b.kind ? a.kind.compareTo(b.kind) : a.id.compareTo(b.id);
      });
    final ledger = XpLedger();
    for (final g in games) {
      g.add(ledger);
    }
    return ledger;
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

  final _ankiren = AnkirenXp();

  /// Adds [run], played after every game added so far, and returns what it
  /// earned.
  XpGain add(XpRun run) {
    final gain = _gain(_score(run));
    _graduated |= run.graduated;
    return gain;
  }

  /// Adds 暗記練 game [game], played after every game added so far, and
  /// returns what it earned.
  XpGain addAnkiren(AnkirenXpRun game) => _gain(_ankiren.score(game));

  XpGain _gain(XpAward award) {
    final gain = XpGain(before: _total, award: award);
    _total = gain.after;
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
      if (!s.timed) continue;
      final bonus = s.us <= run.goalMs * 1000 * XpTuning.blazingRatio
          ? XpTuning.speedBlazing
          : s.us <= run.goalMs * 1000
              ? XpTuning.speedAtGoal
              : 0;
      if (bonus > 0) fast++;
      speedXp += bonus;
    }

    final day = run.day ?? DateTime.utc(run.startedAt.year, run.startedAt.month, run.startedAt.day);
    final last = _lastDay;
    final firstToday = last == null || day.isAfter(last);
    if (firstToday) {
      _streak = last != null && DateTime.utc(last.year, last.month, last.day + 1) == day ? _streak + 1 : 1;
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
        XpPart(XpSource.clear, 1, run.completed ? XpTuning.clear : 0),
        XpPart(XpSource.dayDone, 1, run.dayDone ? XpTuning.dayDone : 0),
        XpPart(XpSource.daily, _streak, firstToday ? XpTuning.daily + streakDays * XpTuning.perStreakDay : 0),
        XpPart(XpSource.best, 1, best ? XpTuning.personalBest : 0),
        XpPart(XpSource.island, run.islands, run.islands * XpTuning.perIsland),
        XpPart(XpSource.graduation, 1, run.graduated ? XpTuning.graduation : 0),
      ])
        if (p.xp > 0) p,
    ]);
  }
}
