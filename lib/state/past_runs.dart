import 'dart:convert';

import 'package:drift/drift.dart';

import '../config/config.dart';
import '../db/database.dart';
import '../domain/card_stats.dart';
import '../domain/day_window.dart';
import '../domain/rating.dart';
import '../domain/run_review.dart';
import '../domain/side_trips.dart';
import '../domain/xp.dart';
import 'play_config.dart';
import 'progress.dart';
import 'xp_history.dart';

/// Keys of a run's stored meta (`Sessions.meta`) that History reads.
abstract final class RunMeta {
  /// Cards the run was planned with (more than were swiped when it ended
  /// early).
  static const plannedKey = 'planned';

  /// Its clock, ms: the total, or the time so far when it ended early.
  static const clockKey = 'clockMs';

  /// Played in all-known mode.
  static const allKnownKey = 'allKnown';

  /// An exam try's Tobi: his time as each card went, ms.
  static const tobiLineKey = 'tobiLineMs';

  static const missesKey = 'misses';
  static const scoredKey = 'scoredMs';
  static const tobiKey = 'tobiMs';
  static const passedKey = 'passed';
  static const placementKey = 'placement';
  static const dayDoneKey = 'dayDone';
}

/// Which page History opens for a run: the 100-card one, with the time
/// against earlier runs and the rating, or the training one.
enum RunView { hundred, training }

/// A recorded run as History shows it, read off its session row.
class PastRun {
  PastRun(this.session, this.config) : _meta = jsonDecode(session.meta) as Map<String, dynamic>;

  final Session session;
  final PlayConfig config;
  final Map<String, dynamic> _meta;

  int get id => session.id;
  PlayMode get mode => config.mode;
  DateTime get startedAt => session.startedAt;
  bool get completed => session.completed;

  /// Cards swiped (a card missed in training and swiped again counts
  /// twice), and cards planned.
  int get cards => session.cardCount;
  int get planned => _meta[RunMeta.plannedKey] as int? ?? cards;

  /// Ranked and the exam: timed with a penalty for each miss.
  bool get scored => mode == PlayMode.ranked || mode == PlayMode.exam;
  int get penaltyMs => switch (mode) {
        PlayMode.exam => ExamTuning.missPenaltyMs,
        PlayMode.ranked => RankedTuning.missPenaltyMs,
        _ => 0,
      };

  RunView get view =>
      scored || (mode == PlayMode.free && planned == RankedTuning.cards) ? RunView.hundred : RunView.training;

  /// The clock: the total, or the time so far of a run ended early.
  Duration? get clock => Progress.totalOf(session) ?? _ms(RunMeta.clockKey);

  /// A scored run's time, penalties included.
  Duration? get scoredTime => _ms(RunMeta.scoredKey);

  /// The time it is listed and graphed by: the scored time for ranked and
  /// the exam, the clock for the rest.
  Duration? get time => scored ? scoredTime : clock;

  /// Misses counted for the scored time (a forfeit's cards left included).
  int? get scoredMisses => _meta[RunMeta.missesKey] as int?;

  bool get forfeit => mode == PlayMode.ranked && !completed;
  bool get placement => _meta[RunMeta.placementKey] == true;
  bool get allKnown => _meta[RunMeta.allKnownKey] == true || mode == PlayMode.ranked;

  /// An exam try: Tobi's time, his time as each card went, and whether the
  /// player beat him.
  Duration? get tobi => _ms(RunMeta.tobiKey);
  List<double>? get tobiLine => (_meta[RunMeta.tobiLineKey] as List?)?.map((v) => (v as num).toDouble()).toList();
  bool get passed => _meta[RunMeta.passedKey] == true;

  /// It finished journey mode's set for the day.
  bool get dayDone => _meta[RunMeta.dayDoneKey] == true;

  /// The goal time per card when it was played.
  double? get goalMs => (_meta['goalMs'] as num?)?.toDouble();

  /// Runs History compares with each other: ranked with ranked, the exam
  /// with the exam, 100-card free play with 100-card free play.
  bool sameKind(PastRun other) => other.mode == mode && other.view == view;

  Duration? _ms(String key) => switch (_meta[key]) {
        final int ms when ms > 0 => Duration(milliseconds: ms),
        _ => null,
      };
}

/// How active a practice day was, for History's last 7 days.
enum DayActivity {
  /// Nothing played.
  none,

  /// Some play: part of the day's set, a run outside it, or a 暗記練 game.
  some,

  /// The day's set done, or any swipe in all-known mode.
  done,
}

/// A ranked run's rating: before it (null for placement), after it, and
/// the performance it played at.
typedef RunRating = ({double? before, double after, double performance});

/// Everything a run page shows beyond the run's own row.
class RunDetail {
  RunDetail({
    required this.run,
    required this.swipes,
    required this.timeline,
    required this.references,
    required this.usualMs,
    this.tobi,
    this.xp,
    this.rating,
    this.rankedRuns = const [],
    this.best = false,
  });

  final PastRun run;
  final List<RunSwipe> swipes;
  final RunTimeline timeline;

  /// The latest earlier runs of the same kind, for a 100-card run.
  final List<RunTimeline> references;

  /// Each card's usual time before the run, by `ItemKey.id`.
  final Map<int, double> usualMs;

  /// An exam try's Tobi.
  final RunTimeline? tobi;
  final XpGain? xp;
  final RunRating? rating;

  /// Ranked runs up to this one, oldest first, with their ratings.
  final List<(PastRun, RunRating)> rankedRuns;

  /// Its time is the best of every run of the same kind so far.
  final bool best;

  late final RunCards cards = RunCards(swipes);

  /// The time graph's bottom.
  double get graphBottom => timeline.bottomWith(run.view == RunView.hundred ? references : const []);
}

/// History's reading of [Progress]: runs, days and a run's details.
extension RunHistory on Progress {
  /// Every recorded run, newest first.
  List<PastRun> get pastRuns =>
      [for (final s in sessions) PastRun(s, configOf(s))]..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  /// The 暗記練 games, newest first.
  List<SideTripRun> get ankirenRuns =>
      sideTrips.runsOf(SideTrip.ankiren).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  /// The practice day a 暗記練 game was played on.
  DateTime dayOfGame(SideTripRun run) => DayWindow.at(run.startedAt, settings.dayStartHour).date;

  /// Every practice day with play, and how active it was.
  Map<DateTime, DayActivity> get dayActivity {
    final days = <DateTime, DayActivity>{};
    void note(DateTime day, DayActivity a) {
      if ((days[day]?.index ?? -1) < a.index) days[day] = a;
    }

    for (final run in pastRuns) {
      final day = dayOf(run.session);
      note(day, run.allKnown || setDoneOn(day) ? DayActivity.done : DayActivity.some);
    }
    for (final run in ankirenRuns) {
      final day = dayOfGame(run);
      note(day, setDoneOn(day) ? DayActivity.done : DayActivity.some);
    }
    return days;
  }

  /// Days in a row with any play, up to today (or yesterday while today
  /// has none yet).
  int activeStreak([DateTime? now]) {
    final days = dayActivity;
    return daysInRow((d) => (days[d] ?? DayActivity.none) != DayActivity.none, now);
  }

  /// A ranked run's rating, null for any other run.
  RunRating? ratingOf(PastRun run) {
    for (var i = 0; i < ratingPoints.length; i++) {
      final p = ratingPoints[i];
      if (p.sessionId != run.id) continue;
      return (before: i == 0 ? null : ratingPoints[i - 1].rating, after: p.rating, performance: p.performance);
    }
    return null;
  }

  /// [run]'s class before and after it moved the rating, null when the
  /// class stayed.
  (RankBand, RankBand)? classChangeOf(PastRun run) {
    final r = ratingOf(run);
    if (r == null || r.before == null) return null;
    final from = Rating.bandOf(r.before!), to = Rating.bandOf(r.after);
    return from.id == to.id ? null : (from, to);
  }

  /// Loads what [run]'s page shows.
  Future<RunDetail> loadRunDetail(PastRun run) async {
    final earlier = run.view == RunView.hundred
        ? pastRuns
            .where((r) => r.sameKind(run) && r.startedAt.isBefore(run.startedAt))
            .take(RunReviewTuning.references)
            .toList()
        : const <PastRun>[];
    final swipes = await _swipesOf([run, ...earlier]);
    final mine = swipes[run.id] ?? const [];
    final tobiLine = run.tobiLine;
    final ranked = run.mode == PlayMode.ranked
        ? [
            for (final r in pastRuns.reversed)
              if (r.mode == PlayMode.ranked && !r.startedAt.isAfter(run.startedAt))
                if (ratingOf(r) case final rating?) (r, rating),
          ]
        : const <(PastRun, RunRating)>[];
    return RunDetail(
      run: run,
      swipes: mine,
      timeline: timelineOf(run, mine),
      references: [for (final r in earlier) timelineOf(r, swipes[r.id] ?? const [])],
      usualMs: _usualBefore(run, mine),
      tobi: tobiLine == null ? null : RunTimeline([0, ...tobiLine]),
      xp: XpHistory.gainsOf(this).runs[run.id],
      rating: ratingOf(run),
      rankedRuns: ranked,
      best: _bestOfKind(run),
    );
  }

  /// [run]'s time into the run after each card, from its [swipes].
  static RunTimeline timelineOf(PastRun run, List<RunSwipe> swipes) {
    final clockMs = run.clock?.inMilliseconds.toDouble() ?? swipes.fold<double>(0, (t, s) => t + s.ms);
    return RunTimeline.of(
      swipes,
      clockMs: clockMs,
      penaltyMs: run.penaltyMs,
      cardsLeft: run.forfeit ? run.planned - run.cards : 0,
      endMs: run.scoredTime?.inMilliseconds.toDouble(),
    );
  }

  bool _bestOfKind(PastRun run) {
    final time = run.time;
    if (!run.completed || time == null) return false;
    return !pastRuns.any((r) =>
        r.sameKind(run) && r.completed && r.startedAt.isBefore(run.startedAt) && (r.time ?? time) < time);
  }

  Future<Map<int, List<RunSwipe>>> _swipesOf(List<PastRun> runs) async {
    final rows = await (db.select(db.attempts)
          ..where((a) => a.sessionId.isIn([for (final r in runs) r.id]))
          ..orderBy([(a) => OrderingTerm.asc(a.seq)]))
        .get();
    final bySession = <int, List<RunSwipe>>{};
    for (final a in rows) {
      (bySession[a.sessionId] ??= []).add(RunSwipe(
        poemId: a.poemId,
        inverted: a.inverted,
        us: a.responseUs,
        miss: a.wrong || a.undone || a.outcome != 0,
        clean: !a.tainted && !a.undone,
        at: a.at,
        undone: a.undone,
        graded: a.grade != null,
      ));
    }
    return bySession;
  }

  Map<int, double> _usualBefore(PastRun run, List<RunSwipe> swipes) {
    final usual = <int, double>{};
    for (final s in swipes) {
      final key = ItemKey(s.poemId, s.inverted);
      if (usual.containsKey(key.id)) continue;
      final before = [for (final a in attemptsOf(key)) if (a.at.isBefore(run.startedAt)) a];
      if (CardStats(before).median(RunReviewTuning.usualWindow) case final ms?) usual[key.id] = ms;
    }
    return usual;
  }
}
