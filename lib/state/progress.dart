import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';
import '../db/database.dart';
import '../db/fsrs_rows.dart';
import '../domain/ankiren_game.dart';
import '../domain/card_mask.dart';
import '../domain/card_stats.dart';
import '../domain/day_window.dart';
import '../domain/masking.dart';
import '../domain/play_session.dart';
import '../domain/ranked.dart';
import '../domain/rating.dart';
import '../domain/side_trips.dart';
import '../domain/step_plan.dart';
import '../domain/tab_locks.dart';
import '../domain/today_set.dart';
import '../domain/trainer.dart';
import '../domain/xp.dart';
import 'db_integrity.dart';
import 'play_config.dart';
import 'settings.dart';
import 'side_trips.dart';
import 'xp_history.dart';

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
  });

  final int? runId;
  final PlayMode mode;

  /// A ranked run's or an exam try's time with its penalties (see
  /// [RankedScore]); null for other runs.
  final RankedScore? score;

  /// Tobi's time in an exam try.
  final Duration? tobi;

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

  bool get personalBest => total != null && (previousBest == null || total! < previousBest!);
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

/// All persistent progress: attempts, training state, rating, history and
/// settings. Loaded once at startup; the UI listens for changes.
class Progress extends ChangeNotifier {
  Progress._(this.db, this.trainer, this._log, this.runs, this._settings, this._islandCompletions,
      this._freePracticeUnlocked, this._tabsSeenLocked, this._sideTripsTabOpened, this._sideTripsOpened,
      this._sideTripsSeenLocked, this.sideTrips)
      : rating = _ratingAfter(runs);

  final AppDatabase db;
  final Trainer trainer;
  final Map<ItemKey, List<AttemptRec>> _log;

  /// Every recorded run, oldest first.
  final List<RunRow> runs;
  AppSettings _settings;

  /// The rating: the latest ranked run's; null before the first (placement).
  double? rating;
  final _statsCache = <ItemKey, CardStats>{};
  Map<int, ({int cards, int misses})>? _runCounts;

  /// Unlocked while planning a run and not yet part of a recorded one (for
  /// the islands a run reaches).
  final _unreported = <ItemKey>[];

  /// The islands counted as complete, by island.
  final Map<int, IslandCompletionRow> _islandCompletions;

  /// Free practice has opened once, so it stays open (see [freePractice]).
  bool _freePracticeUnlocked;

  /// Tabs the player has seen locked whose opening is still to be
  /// celebrated (see [tabLock]).
  final Set<LockedTab> _tabsSeenLocked;

  /// The Side Trips tab has opened once, so it stays open (see [tabLock]).
  bool _sideTripsTabOpened;

  /// Side trips that have opened once, so they stay open (see
  /// [sideTripsHub]).
  final Set<SideTrip> _sideTripsOpened;

  /// Side trips the player has seen locked on the hub whose opening is
  /// still to be shown.
  final Set<SideTrip> _sideTripsSeenLocked;

  /// The side trips' recorded games and ratings.
  final SideTrips sideTrips;

  /// When the latest exam try began.
  DateTime? _examLastTry;
  bool _examIntroShown = false;
  bool _switchBannerCollapsed = false;

  /// The most recent run, kept in memory for the debug page's timing view.
  PlaySession? lastRun;

  /// Every stored practice day by number, the latest of them, and its set
  /// (journey mode, once built).
  final _days = <int, DayRow>{};
  DayRow? _day;
  TodaySet? _today;

  AppSettings get settings => _settings;

  /// Experience so far, rebuilt from the recorded history on first use.
  XpLedger get xp => _xp ??= XpHistory.ledgerOf(this);
  XpLedger? _xp;

  static Future<Progress> open(AppDatabase db) async {
    await DbIntegrity.run(db);
    final kv = {for (final r in await db.select(db.keyValues).get()) r.key: r.value};
    Map<String, dynamic> json(String k) => kv[k] == null ? {} : jsonDecode(kv[k]!) as Map<String, dynamic>;

    final items = Trainer.freshItems();
    for (final r in await db.select(db.items).get()) {
      final item = ItemStateRow.of(r);
      items[item.key] = item;
    }
    final trainer = Trainer(
      config: TrainerConfig.fromJson(json('trainer')),
      items: items,
      goalLevel: int.tryParse(kv['goalLevel'] ?? '') ?? 0,
    );

    final runs = await (db.select(db.runs)
          ..orderBy([(r) => OrderingTerm.asc(r.startedAt), (r) => OrderingTerm.asc(r.id)]))
        .get();
    final configOf = {for (final r in runs) r.id: _configOf(r)};

    final log = <ItemKey, List<AttemptRec>>{};
    final rows = await (db.select(db.attempts)..orderBy([(a) => OrderingTerm.asc(a.at), (a) => OrderingTerm.asc(a.id)])).get();
    for (final a in rows) {
      (log[ItemKey(a.poemId, a.inverted)] ??= []).add(_rec(a, configOf[a.runId] ?? _orphanRun));
    }
    var settings = AppSettings.fromJson(json('settings'));
    // Players from before the tour existed have found their way around.
    if (!json('settings').containsKey('toured') && runs.isNotEmpty) settings = settings.copyWith(toured: true);
    trainer.dayStartHour = settings.dayStartHour;
    final progress = Progress._(
      db,
      trainer,
      log,
      runs,
      settings,
      {for (final c in await db.select(db.islandCompletions).get()) c.island: c},
      kv[_freePracticeKey] == 'true',
      {
        for (final name in (jsonDecode(kv[_tabsSeenLockedKey] ?? '[]') as List).cast<String>())
          ?LockedTab.values.asNameMap()[name],
      },
      kv[_sideTripsTabKey] == 'true',
      {
        for (final name in (jsonDecode(kv[_sideTripsKey] ?? '[]') as List).cast<String>())
          ?SideTrip.values.asNameMap()[name],
      },
      {
        for (final name in (jsonDecode(kv[_sideTripsSeenLockedKey] ?? '[]') as List).cast<String>())
          ?SideTrip.values.asNameMap()[name],
      },
      await SideTrips.load(db),
    );
    for (final d in await db.select(db.days).get()) {
      progress._days[d.day] = d;
    }
    progress._day = progress._days.values.fold<DayRow?>(null, (a, d) => a == null || d.day > a.day ? d : a);
    progress._examLastTry = DateTime.tryParse(kv[_examLastTryKey] ?? '');
    progress._examIntroShown = kv[_examIntroShownKey] == 'true';
    if (DateTime.tryParse(kv[_rankedRunningKey] ?? '') case final startedAt?) {
      await progress._forfeitUnrecorded(startedAt);
    }
    await progress._loadToday();
    if (settings.onboarded && !progress._allKnown) await progress.refreshToday();
    await progress._latchFreePractice(DateTime.now());
    await progress._latchSideTrips(DateTime.now());
    return progress;
  }

  /// Stands in for the session of an attempt whose session row is missing.
  static const _orphanRun = PlayConfig(mode: PlayMode.free);
  static const _freePracticeKey = 'freePracticeUnlocked';
  static const _tabsSeenLockedKey = 'tabsSeenLocked';
  static const _sideTripsTabKey = 'sideTripsTabUnlocked';
  static const _sideTripsKey = 'sideTripsUnlocked';
  static const _sideTripsSeenLockedKey = 'sideTripsSeenLocked';
  static const _rankedRunningKey = 'rankedRunning';
  static const _examLastTryKey = 'examLastTry';
  static const _examIntroShownKey = 'examIntroShown';

  static AttemptRec _rec(AttemptRow a, PlayConfig run) => AttemptRec(
        at: a.at,
        us: CardTime.of(a.responseUs, a.commitUs),
        miss: a.outcome == Outcome.dontKnow || a.wrong || a.undone,
        clean: !a.tainted && !a.undone,
        deckSize: a.deckSize,
        mode: run.mode,
        countsForSrs: run.countsForSrs,
        maskLevel: a.maskLevel,
        grade: a.grade,
        runId: a.runId,
        undone: a.undone,
      );

  static double? _ratingAfter(List<RunRow> runs) => [for (final r in runs) ?r.rating].lastOrNull;

  // ---------------------------------------------------------------- reads

  /// Training view of a card's statistics: the one the trainer's scheduler,
  /// FSRS unlocking and the displayed rating are built from. Only runs that
  /// count (修行, and free practice at its default) feed it; customised free
  /// play and 苦手 never do (see [AttemptRec.countsForSrs]).
  CardStats stats(ItemKey k) =>
      _statsCache[k] ??= CardStats([for (final a in _log[k] ?? const []) if (a.countsForSrs) a]);

  Map<ItemKey, CardStats> get allStats => {for (final k in trainer.items.keys) k: stats(k)};

  /// Every attempt on a card, in every mode — for history and per-card charts
  /// (unlike [stats], which only counts training attempts).
  List<AttemptRec> attemptsOf(ItemKey k) => _log[k] ?? const [];

  /// Display-only statistics over every attempt on a card, in every mode
  /// (unlike [stats], which only counts training attempts). Not cached: for
  /// occasional UI use, not the training/rating hot path.
  CardStats displayStats(ItemKey k) => CardStats(_log[k] ?? const []);

  /// Misses (wrong, "don't know" or undone) recorded in run [runId].
  int missesIn(int runId) => _countsOf(runId).misses;

  /// Cards swiped in run [runId], undone swipes left out (a card missed in
  /// training and swiped again counts twice).
  int cardsIn(int runId) => _countsOf(runId).cards;

  ({int cards, int misses}) _countsOf(int runId) {
    final counts = _runCounts ??= () {
      final byRun = <int, ({int cards, int misses})>{};
      for (final a in _log.values.expand((a) => a)) {
        final id = a.runId;
        if (id == null) continue;
        final c = byRun[id] ?? (cards: 0, misses: 0);
        byRun[id] = (cards: c.cards + (a.undone ? 0 : 1), misses: c.misses + (a.miss ? 1 : 0));
      }
      return byRun;
    }();
    return counts[runId] ?? (cards: 0, misses: 0);
  }

  double get projectedMs => Rating.projectedMs(stats);

  List<IslandProgress> get islands => trainer.islands(fudaSets, allStats);

  /// Whether a single-island run may start: journey mode gates it on every
  /// card of the island being uncovered, all-known mode has nothing left to
  /// unlock.
  bool isIslandPlayable(IslandProgress island) =>
      trainer.config.learningMode == LearningMode.allKnown || island.unlocked == island.total;

  /// The displayed rating, or the current performance before the first run.
  double get currentRating => rating ?? Rating.performance(projectedMs);

  RankBand get band => Rating.bandOf(currentRating);

  /// Unlocked items due for review now.
  int dueCount([DateTime? now]) {
    final at = now ?? DateTime.now();
    return trainer.unlocked.where((s) => trainer.isDue(s.key, at)).length;
  }

  /// Unlocked items never played yet.
  int get freshCount => trainer.unlocked.where((s) => !stats(s.key).seen).length;

  /// Played items still slower than the current goal (misses count as slow).
  int get slowCount => trainer.unlocked.where((s) {
        final st = stats(s.key);
        return st.seen && st.expectedMs() > trainer.goalMs;
      }).length;

  /// Average (training-only) EWMA response time over unlocked upright items,
  /// as of [asOf]. Early on, only a handful of cards are unlocked, so rank and
  /// rating barely move even as the player gets much faster on what they do
  /// know; this gives beginners something that visibly improves run to run.
  double? knownCardSpeedAt(DateTime asOf) {
    final samples = <double?>[
      for (final s in trainer.unlocked)
        if (!s.key.inverted)
          CardStats([for (final a in _log[s.key] ?? const []) if (a.countsForSrs && !a.at.isAfter(asOf)) a]).ewmaMs
    ].whereType<double>().toList();
    return samples.isEmpty ? null : samples.reduce((a, b) => a + b) / samples.length;
  }

  /// The known-card speed right now.
  double? get knownCardSpeedMs => knownCardSpeedAt(DateTime.now());

  /// The known-card speed [StatsTuning.knownSpeedTrendDays] days ago, to
  /// compare against [knownCardSpeedMs] for a trend indicator.
  double? get knownCardSpeedTrendAgo =>
      knownCardSpeedAt(DateTime.now().subtract(const Duration(days: StatsTuning.knownSpeedTrendDays)));

  /// Best completed total for runs with the same setup.
  Duration? bestFor(PlayConfig c) {
    Duration? best;
    for (final r in runs) {
      final total = totalOf(r);
      if (total == null || _configOf(r).historyKey != c.historyKey) continue;
      if (best == null || total < best) best = total;
    }
    return best;
  }

  /// Run [r]'s clock, while it is a measurement.
  static Duration? clockOf(RunRow r) => switch (r.clockUs) {
        final int us when us > 0 => Duration(microseconds: us),
        _ => null,
      };

  /// Run [r]'s total time; null when it was ended early or its time is no
  /// measurement.
  static Duration? totalOf(RunRow r) => r.completed ? clockOf(r) : null;

  PlayConfig configOf(RunRow r) => _configOf(r);

  static PlayConfig _configOf(RunRow r) => PlayConfig(
        mode: r.mode,
        setIds: (jsonDecode(r.setIds) as List).cast<String>(),
        cardIds: r.cardIds == null ? null : (jsonDecode(r.cardIds!) as List).cast<int>(),
        maskLevel: r.maskLevel,
      );

  /// Days (see [dayOf]) with at least one tracked run.
  Set<DateTime> get practiceDays => {for (final r in runs) dayOf(r)};

  /// The practice day run [r] was played on (a UTC midnight).
  DateTime dayOf(RunRow r) => DayWindow.dateOf(r.day);

  /// Ranked runs that moved the rating, oldest first.
  Iterable<RunRow> get ratedRuns => runs.where((r) => r.rating != null);

  /// The ranked run that placed the player: the first to move the rating.
  bool isPlacement(RunRow r) => r.rating != null && ratedRuns.first.id == r.id;

  /// The islands journey run [runId] completed (and celebrated).
  List<int> islandsCompletedBy(int runId) => [
        for (final c in _islandCompletions.values)
          if (c.runId == runId) c.island,
      ]..sort();

  /// The very first swipe ever recorded, for My Profile's "first swipe"
  /// line — null with no history yet.
  DateTime? get firstSwipeAt {
    DateTime? earliest;
    for (final attempts in _log.values) {
      for (final a in attempts) {
        if (earliest == null || a.at.isBefore(earliest)) earliest = a.at;
      }
    }
    return earliest;
  }

  int get streak => daysInRow(practiceDays.contains);

  /// Days in a row, up to today (or yesterday while today isn't yet), that
  /// [counts].
  int daysInRow(bool Function(DateTime day) counts, [DateTime? now]) {
    var d = dayAt(now).date;
    if (!counts(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (counts(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  // ---------------------------------------------------------------- today

  /// The practice day [now] falls in (see [DayWindow]): the latest stored
  /// day while it lasts, then the one after it.
  DayWindow dayAt([DateTime? now]) {
    now ??= DateTime.now();
    final last = _day;
    if (last != null) {
      final w = _windowOf(last);
      if (w.contains(now)) return w;
      if (!now.isBefore(w.end)) return DayWindow.after(w, now, settings.dayStartHour);
    }
    return DayWindow.at(now, settings.dayStartHour);
  }

  static DayWindow _windowOf(DayRow d) => DayWindow(DayWindow.dateOf(d.day), d.startsAt, d.endsAt);

  /// Journey mode's set for the day [now] falls in, once built (see
  /// [refreshToday]).
  TodaySet? todaySet([DateTime? now]) {
    final set = _today;
    return set != null && set.window.contains(now ?? DateTime.now()) ? set : null;
  }

  /// Today's set is missing or from an earlier day ([refreshToday] builds
  /// it).
  bool get todayStale => !simulating && !_allKnown && todaySet() == null;

  /// A simulation is replaying past days through this progress (dev
  /// mode's demo data): nothing may build today's set meanwhile, or the
  /// replayed days would come after it and find no set of their own.
  bool simulating = false;

  /// Stores the day [now] falls in, if it is new.
  Future<DayRow> _storeDay(DateTime now) async {
    final w = dayAt(now);
    final known = _days[w.number];
    if (known != null) return known;
    final row = DayRow(
      day: w.number,
      startsAt: w.start,
      endsAt: w.end,
      missGuess: 0,
      newPaused: false,
      pauseAsked: false,
    );
    await db.into(db.days).insert(row, mode: InsertMode.insertOrIgnore);
    _days[w.number] = row;
    if (_day == null || w.number > _day!.day) {
      _day = row;
      _today = null;
    }
    return row;
  }

  Future<void> _updateDay(DayRow row) async {
    await db.update(db.days).replace(row);
    _days[row.day] = row;
    if (_day?.day == row.day) _day = row;
  }

  /// Journey mode: builds the set for the day [now] falls in, the first time
  /// it is needed that day. The morning's new cards are unlocked with it;
  /// returns them.
  Future<List<ItemKey>> refreshToday([DateTime? now]) async {
    now ??= DateTime.now();
    final day = await _storeDay(now);
    if (_allKnown || day.day != _day?.day) return const [];
    if (day.builtAt != null) {
      if (_today?.window.date != DayWindow.dateOf(day.day)) await _loadToday();
      return const [];
    }
    final fresh = trainer.unlockForToday(poems, fudaSets, allStats, now);
    if (fresh.isNotEmpty) {
      await _saveItems(fresh);
      _unreported.addAll(fresh);
    }
    final window = _windowOf(day);
    final kinds = {
      for (final s in trainer.unlocked)
        if (!s.reviewed) s.key: StepKind.newCard else if (s.card.due.isBefore(window.end)) s.key: StepKind.review,
    };
    await _storeSetCards(day.day, kinds);
    final recent = [
      for (final k in trainer.items.keys)
        for (final a in _log[k] ?? const <AttemptRec>[]) if (a.mode == PlayMode.training) a,
    ]..sort((a, b) => a.at.compareTo(b.at));
    final base = kinds.values.fold(0, (n, k) => n + CardSteps.forSet(k).base);
    await _updateDay(day.copyWith(
      builtAt: Value(now),
      missGuess: TodaySet.guessMisses(
        base,
        [for (final a in recent.skip(math.max(0, recent.length - TodaySetTuning.missGuessWindow))) a.miss],
      ),
    ));
    _today = _replay(_day!, kinds);
    notifyListeners();
    return fresh;
  }

  Future<void> _storeSetCards(int day, Map<ItemKey, StepKind> kinds) => db.batch((b) {
        for (final e in kinds.entries) {
          b.insert(
            db.dayCards,
            DayCardsCompanion.insert(day: day, poemId: e.key.poemId, inverted: e.key.inverted, kind: e.value),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

  /// Loads the latest day's set, if it was built.
  Future<void> _loadToday() async {
    final day = _day;
    if (day == null || day.builtAt == null) {
      _today = null;
      return;
    }
    final rows = await (db.select(db.dayCards)..where((c) => c.day.equals(day.day))).get();
    _today = _replay(day, {for (final r in rows) ItemKey(r.poemId, r.inverted): r.kind});
  }

  /// [day]'s set with its progress, replayed from the day's training swipes.
  TodaySet _replay(DayRow day, Map<ItemKey, StepKind> kinds) {
    final window = _windowOf(day);
    return TodaySet.replay(
      window: window,
      kinds: kinds,
      looks: {
        for (final k in kinds.keys)
          k: [
            for (final a in _log[k] ?? const <AttemptRec>[])
              if (a.mode == PlayMode.training && window.contains(a.at)) a.miss,
          ],
      },
      missGuess: day.missGuess,
      newPaused: day.newPaused,
      pauseAsked: day.pauseAsked,
      doneAt: day.doneAt,
    );
  }

  /// Home asks once a day whether to pause the new cards: today's set has
  /// more reviews than the pace's [PaceProfile.pauseNewOver] and new cards
  /// not started yet.
  bool pauseOffered([DateTime? now]) {
    final set = todaySet(now);
    return set != null &&
        !set.pauseAsked &&
        !set.done &&
        set.reviews > trainer.config.pace.profile.pauseNewOver &&
        _pausable(set).isNotEmpty;
  }

  /// Today's new cards not looked at yet.
  List<ItemKey> _pausable(TodaySet set) => [
        for (final e in set.steps.entries)
          if (e.value.kind == StepKind.newCard && e.value.looks == 0) e.key,
      ];

  /// The pause question was answered: [pause] takes today's new cards not
  /// started yet out of the set and locks them again until a later day.
  Future<void> answerPause({required bool pause, DateTime? now}) async {
    final set = todaySet(now);
    final day = _day;
    if (set == null || day == null) return;
    if (pause) {
      final keys = _pausable(set);
      for (final k in keys) {
        trainer.items[k]!
          ..unlocked = false
          ..unlockedAt = null;
      }
      _unreported.removeWhere(keys.contains);
      await _saveItems(keys);
      await (db.delete(db.dayCards)
            ..where((c) => c.day.equals(day.day))
            ..where((c) => c.kind.equalsValue(StepKind.newCard)))
          .go();
      await _storeSetCards(day.day, {for (final e in set.kinds.entries) if (!keys.contains(e.key)) e.key: e.value});
    }
    await _updateDay(day.copyWith(pauseAsked: true, newPaused: _day!.newPaused || pause));
    await _loadToday();
    notifyListeners();
  }

  /// Days in a row with today's set done, up to today (or yesterday while
  /// today's isn't yet).
  int goalStreak([DateTime? now]) => daysInRow(setDoneOn, now);

  /// Journey mode's set for practice day [day] was done.
  bool setDoneOn(DateTime day) => _days[DayWindow.numberOf(day)]?.doneAt != null;

  /// The last [TodaySetTuning.weekDays] days, today last: whose set was
  /// done, and which passed without it (since the first day with a set).
  List<WeekStamp> weekStamps([DateTime? now]) {
    final today = dayAt(now).date;
    final firstSet = _days.values.where((d) => d.builtAt != null).map((d) => d.day).fold<int?>(
          null,
          (a, n) => a == null || n < a ? n : a,
        );
    return [
      for (var i = TodaySetTuning.weekDays - 1; i >= 0; i--)
        () {
          final date = today.subtract(Duration(days: i));
          final n = DayWindow.numberOf(date);
          final done = _days[n]?.doneAt != null;
          return WeekStamp(
            date: date,
            done: done,
            missed: i > 0 && !done && firstSet != null && n >= firstSet,
            today: i == 0,
          );
        }(),
    ];
  }

  // ---------------------------------------------------------------- decks

  /// The cards the player knows: free practice's default deck, and all its
  /// pickers may choose from. Every card in all-known mode.
  Set<int> get knownCards => {
        for (final p in poems.all)
          if (trainer.config.learningMode == LearningMode.allKnown || knows(p.id)) p.id,
      };

  /// The cards of a free-play or guest run, sorted: [PlayConfig.cardIds]
  /// (only those still known), or its sets.
  List<int> freeDeckIds(PlayConfig c) {
    final picked = c.cardIds;
    if (picked != null) return knownCards.intersection({...picked}).toList()..sort();
    if (c.isKnownDeck) return knownCards.toList()..sort();
    return fudaSets.union(c.setIds);
  }

  /// Free practice's run for [setup]. A hand-picked deck holding every known
  /// card is the default deck again, so it counts.
  PlayConfig freePracticeRun(FreePracticeSetup setup) {
    final picked = setup.cardIds;
    if (picked == null || !knownCards.every(picked.contains)) return setup.config;
    return FreePracticeSetup(maskLevel: setup.maskLevel).config;
  }

  /// A free-play or guest run's deck, once each, shuffled. Free play turns a
  /// card over only when its reversed item is unlocked, like 修行 does; a
  /// guest gets either way up at random.
  List<CardRef> freeDeck(PlayConfig c, {math.Random? rng}) {
    final random = rng ?? math.Random();
    final ids = freeDeckIds(c)..shuffle(random);
    bool inverted(int id) =>
        (c.mode == PlayMode.guest || trainer.items[ItemKey(id, true)]!.unlocked) && random.nextBool();
    return [for (final id in ids) _ref(id, inverted(id), c.maskLevel, random)];
  }

  /// 苦手: the cards with the worst expected time (misses count as slow).
  List<CardRef> nigateDeck(PlayConfig c, {math.Random? rng}) {
    rng ??= math.Random();
    final seen = [for (final k in trainer.items.keys) if (stats(k).seen) k]
      ..sort((a, b) => stats(b).expectedMs().compareTo(stats(a).expectedMs()));
    final keys = seen.take(settings.nigateCount).toList()..shuffle(rng);
    return [for (final k in keys) _ref(k.poemId, k.inverted, c.maskLevel, rng)];
  }

  /// Readiness for new cards (journey mode).
  Readiness get readiness => trainer.readiness(poems, fudaSets, allStats);

  PaceStatus paceStatus([DateTime? now]) => trainer.paceStatus(poems, fudaSets, allStats, now ?? DateTime.now());

  /// Whether Home's "Learn ahead" is open, and why not. With today's set,
  /// it waits for the set's new cards, and a card settled today counts as
  /// reviewed.
  LearnAhead learnAhead([DateTime? now]) {
    now ??= DateTime.now();
    final set = todaySet(now);
    return trainer.learnAhead(poems, fudaSets, allStats, now,
        settled: _settled(now), newPending: set?.newPending);
  }

  /// Cards settled in today's set: reviewed today, though FSRS may still
  /// hold them in its short learning steps.
  Set<ItemKey> _settled(DateTime now) => todaySet(now)?.doneKeys ?? const {};

  /// Journey mode with cards still locked: "Learn ahead" is on offer.
  bool get canLearnMore =>
      trainer.config.learningMode == LearningMode.journey && trainer.nextBatch(poems, fudaSets).isNotEmpty;

  // ---------------------------------------------- ranked and the exam

  /// A ranked run has placed the player on the ladder.
  bool get placed => rating != null;

  /// Ranked runs recorded, forfeits included.
  int get rankedRuns => runs.where((r) => r.mode == PlayMode.ranked).length;

  /// A ranked run of all 100 cards, shuffled, each either way up at random,
  /// with nothing hidden.
  List<CardRef> rankedDeck({math.Random? rng}) {
    final random = rng ?? math.Random();
    final ids = [for (final p in poems.all) p.id]..shuffle(random);
    return [for (final id in ids) CardRef(id, inverted: random.nextBool())];
  }

  /// Marks a ranked run as under way, so one the app never got to record
  /// still counts as a forfeit on the next start.
  Future<void> noteRankedStarted(DateTime at) => _put(_rankedRunningKey, at.toIso8601String());

  /// The graduation exam has been passed (it happens once).
  bool get graduated => xp.graduated;

  /// Journey mode's graduation exam: whether it is open, and what keeps a
  /// try from starting now.
  ExamAccess exam([DateTime? now]) {
    final left = poems.all.where((p) => attemptsOf(ItemKey(p.id, false)).isEmpty && attemptsOf(ItemKey(p.id, true)).isEmpty);
    final last = _examLastTry;
    final wait = last == null ? Duration.zero : last.add(ExamTuning.cooldown).difference(now ?? DateTime.now());
    return ExamAccess(
      cardsLeft: left.length,
      cooldown: wait > Duration.zero ? wait : null,
      passed: graduated,
    );
  }

  /// A try at the exam begins: the next one waits [ExamTuning.cooldown]
  /// from now, however this one ends.
  Future<void> noteExamStarted(DateTime at) async {
    _examLastTry = at;
    await _put(_examLastTryKey, at.toIso8601String());
    notifyListeners();
  }

  /// Tobi's word on Home pointing at the exam strip, due once, as the exam
  /// first opens on the journey.
  bool get examIntroDue => !_allKnown && !graduated && !_examIntroShown && exam().open;

  Future<void> noteExamIntroShown() async {
    _examIntroShown = true;
    await _put(_examIntroShownKey, 'true');
    notifyListeners();
  }

  /// Developer mode: Tobi's word on the exam strip shows again (once the
  /// exam is open).
  Future<void> replayExamIntro() async {
    _examIntroShown = false;
    await _drop(_examIntroShownKey);
    notifyListeners();
  }

  /// Developer mode: the next exam try may start right away.
  Future<void> clearExamCooldown() async {
    _examLastTry = null;
    await _drop(_examLastTryKey);
    notifyListeners();
  }

  /// Developer mode: as if the exam was never passed. The graduation mark
  /// leaves every run, so the ledger (graduation XP, levels) rebuilds without
  /// it, and the exam's intro and cooldown start over.
  Future<void> debugUndoExamPass() async {
    await (db.update(db.runs)..where((r) => r.graduated)).write(const RunsCompanion(graduated: Value(false)));
    for (var i = 0; i < runs.length; i++) {
      if (runs[i].graduated) runs[i] = runs[i].copyWith(graduated: false);
    }
    _xp = null;
    _examLastTry = null;
    _examIntroShown = false;
    await _drop(_examLastTryKey);
    await _drop(_examIntroShownKey);
    notifyListeners();
  }

  /// Developer mode: back to unplaced, so the next ranked run places again.
  /// The ranked runs stay, without their ratings.
  Future<void> debugClearRating() async {
    await (db.update(db.runs)..where((r) => r.rating.isNotNull() | r.performance.isNotNull()))
        .write(const RunsCompanion(rating: Value(null), performance: Value(null)));
    for (var i = 0; i < runs.length; i++) {
      if (runs[i].rating != null || runs[i].performance != null) {
        runs[i] = runs[i].copyWith(rating: const Value(null), performance: const Value(null));
      }
    }
    rating = null;
    _xp = null;
    notifyListeners();
  }

  /// Journey Home's banner after the exam is passed, offering all-known mode.
  bool get switchBannerShown => !_allKnown && graduated;

  /// Whether the banner is folded into its small button. Kept in memory
  /// only, so the banner is open again at the next start.
  bool get switchBannerCollapsed => _switchBannerCollapsed;

  void collapseSwitchBanner() => _setSwitchBannerCollapsed(true);

  void expandSwitchBanner() => _setSwitchBannerCollapsed(false);

  void _setSwitchBannerCollapsed(bool collapsed) {
    if (_switchBannerCollapsed == collapsed) return;
    _switchBannerCollapsed = collapsed;
    notifyListeners();
  }

  /// Every card already unlocked: switching journey → all-known has nothing
  /// left to warn about.
  bool get allCardsUnlocked => trainer.nextBatch(poems, fudaSets).isEmpty;

  /// 修行: unlock what was earned, then plan a session: in journey mode the
  /// rest of today's set, or a batch once the day is done.
  Future<PlannedRun> planTraining({math.Random? rng, DateTime? now}) async {
    now ??= DateTime.now();
    final morning = _allKnown ? const <ItemKey>[] : await refreshToday(now);
    final fresh = trainer.unlockEarned(poems, fudaSets, allStats, now, batches: _allKnown);
    if (fresh.isNotEmpty) await _saveItems(fresh);
    return _plan([...morning, ...fresh], rng ?? math.Random(), now);
  }

  /// "Learn ahead": unlocks the next batch now, ignoring pace and
  /// readiness, then plans a session that includes it.
  Future<PlannedRun> learnAheadCards({math.Random? rng, DateTime? now}) async {
    now ??= DateTime.now();
    if (!_allKnown) await refreshToday(now);
    final fresh = trainer.unlockNextBatch(poems, fudaSets, now);
    if (fresh.isNotEmpty) {
      await _saveItems(fresh);
      final set = todaySet(now), day = _day;
      if (set != null && !set.done && day != null) {
        await _storeSetCards(day.day, {...set.kinds, for (final k in fresh) k: StepKind.newCard});
        await _loadToday();
      }
      notifyListeners();
    }
    return _plan(fresh, rng ?? math.Random(), now);
  }

  PlannedRun _plan(List<ItemKey> fresh, math.Random rng, DateTime now) {
    _unreported.addAll(fresh.where((k) => !_unreported.contains(k)));
    final stats = allStats;
    if (_allKnown) {
      final picks = trainer.planSession(stats, now, rng);
      final cards = [
        for (final p in picks) CardRef(p.key.poemId, inverted: p.key.inverted),
      ];
      return PlannedRun(cards, picks, fresh, const {});
    }
    final set = todaySet(now);
    final known = {for (final p in poems.all) if (knows(p.id)) p.id};
    final seed = rng.nextInt(1 << 30);
    final StepPlan plan;
    final ofSet = set != null && !set.done && set.steps.values.any((s) => !s.done);
    if (ofSet) {
      final start = {for (final e in set.steps.entries) if (!e.value.done) e.key: e.value.copy()};
      final order = {
        for (final (i, id) in Trainer.learningBatches(poems, fudaSets, trainer.config.batchSize).expand((b) => b).indexed)
          id: i,
      };
      plan = StepPlan.forSet(
        start: start,
        reviews: [for (final k in start.keys) if (start[k]!.kind == StepKind.review) k]..shuffle(rng),
        newCards: [for (final k in start.keys) if (start[k]!.kind == StepKind.newCard) k]
          ..sort((a, b) => a.inverted != b.inverted
              ? (a.inverted ? 1 : -1)
              : (order[a.poemId] ?? 0).compareTo(order[b.poemId] ?? 0)),
        fillers: [
          for (final s in trainer.unlocked)
            if (!start.containsKey(s.key) && known.contains(s.key.poemId)) s.key,
        ],
        knownBefore: known,
        twinsOf: fudaSets.tomofuda,
        seed: seed,
      );
    } else {
      plan = StepPlan.forBatch(
        picks: [for (final p in trainer.planSession(stats, now, rng)) p.key],
        knownBefore: known,
        twinsOf: fudaSets.tomofuda,
        seed: seed,
      );
    }
    final refs = <ItemKey, CardRef>{};
    CardRef ref(ItemKey k) => refs[k] ??= CardRef(k.poemId, inverted: k.inverted);
    ItemKey keyOf(CardRef c) => ItemKey(c.poemId, c.inverted);
    final keys = plan.cards;
    return PlannedRun(
      [for (final k in keys) ref(k)],
      [
        for (final k in keys)
          TrainingPick(
            k,
            !stats[k]!.seen ? PickReason.fresh : (trainer.isDue(k, now) ? PickReason.due : PickReason.repeat),
            1,
          ),
      ],
      fresh,
      {for (final k in keys) if (Trainer.isNewPoem(stats, k.poemId)) k.poemId},
      ofSet: ofSet,
      planner: (swipes, next) => [
        for (final k in plan.upcoming([for (final a in swipes) (keyOf(a.card), a.isMiss)],
            next: next == null ? null : keyOf(next)))
          ref(k),
      ],
    );
  }

  /// Unlocked and met before: the player knows this card (not a new card
  /// still waiting for its introduction).
  bool knows(int poemId) => trainer.items[ItemKey(poemId, false)]?.unlocked == true && _metBefore(poemId);

  /// Trained before in either orientation (see [Trainer.isNewPoem]).
  bool _metBefore(int poemId) => stats(ItemKey(poemId, false)).seen || stats(ItemKey(poemId, true)).seen;

  /// Free practice is open in all-known mode, and in journey mode once
  /// [FreePracticeTuning.unlockRemembered] cards have been well remembered
  /// at the same time (latched: a bad day never locks it again).
  FreePracticeAccess freePractice([DateTime? now]) {
    if (_freePracticeUnlocked || trainer.config.learningMode == LearningMode.allKnown) {
      return const FreePracticeAccess(open: true, remembered: FreePracticeTuning.unlockRemembered);
    }
    now ??= DateTime.now();
    final remembered = trainer.wellRememberedCount(allStats, now, settled: _settled(now));
    return FreePracticeAccess(open: remembered >= FreePracticeTuning.unlockRemembered, remembered: remembered);
  }

  /// Stores the free-practice latch the first time [freePractice] is open.
  Future<void> _latchFreePractice(DateTime now) async {
    if (_freePracticeUnlocked || !freePractice(now).open) return;
    _freePracticeUnlocked = true;
    await _put(_freePracticeKey, 'true');
  }

  bool get _allKnown => trainer.config.learningMode == LearningMode.allKnown;

  /// The Side Trips tab: each side trip's lock and standing. The trips open
  /// in all-known mode, and in journey mode as cards are well remembered
  /// (latched like [freePractice]: a bad day never locks them again).
  SideTripsHub sideTripsHub([DateTime? now]) => SideTripsHub.of(
        allKnown: _allKnown,
        remembered: _sideTripsRemembered(now ?? DateTime.now()),
        latched: _sideTripsOpened,
        standings: {
          for (final trip in SideTrip.values) trip: sideTrips.standingOf(trip, known: knownCards.length),
        },
      );

  /// Cards well remembered at once, for the side trips' locks; 0 once
  /// the tab and every trip are open, with no lock left to count toward.
  int _sideTripsRemembered(DateTime now) =>
      _allKnown || (_sideTripsTabOpened && _sideTripsOpened.containsAll(SideTrip.values))
          ? 0
          : trainer.wellRememberedCount(allStats, now, settled: _settled(now));

  /// Stores the side-trip latches for the tab and every trip open now.
  Future<void> _latchSideTrips(DateTime now) async {
    final remembered = _sideTripsRemembered(now);
    if (!_sideTripsTabOpened &&
        SideTripUnlocks.tabLock(allKnown: _allKnown, remembered: remembered, latched: false) == null) {
      _sideTripsTabOpened = true;
      await _put(_sideTripsTabKey, 'true');
    }
    final open = sideTripsHub(now).openTrips;
    if (_sideTripsOpened.containsAll(open)) return;
    _sideTripsOpened.addAll(open);
    await _put(_sideTripsKey, jsonEncode([for (final t in _sideTripsOpened) t.name]));
  }

  /// For tests that visit History and Stats without playing their way
  /// there: no tab is ever locked.
  @visibleForTesting
  bool tabsAlwaysOpen = false;

  /// What keeps [tab] locked for now, or null once it is open.
  TabLock? tabLock(LockedTab tab) => tabsAlwaysOpen
      ? null
      : TabLock.of(
        tab,
        mode: trainer.config.learningMode,
        rounds: runs.length,
        finishedRounds: runs.where((r) => r.completed).length,
        islandFinished: _islandCompletions.isNotEmpty || islands.any((i) => i.complete),
        remembered: _sideTripsRemembered(DateTime.now()),
        sideTripsLatched: _sideTripsTabOpened,
      );

  /// Tabs shown locked whose opening is still to be celebrated.
  Set<LockedTab> get tabsSeenLocked => Set.unmodifiable(_tabsSeenLocked);

  /// [tabs] have been shown locked.
  Future<void> noteTabsSeenLocked(Iterable<LockedTab> tabs) async {
    final before = _tabsSeenLocked.length;
    _tabsSeenLocked.addAll(tabs);
    if (_tabsSeenLocked.length != before) await _saveTabsSeenLocked();
  }

  /// [tabs] have opened, and their opening has been celebrated.
  Future<void> noteTabsOpened(Iterable<LockedTab> tabs) async {
    final before = _tabsSeenLocked.length;
    _tabsSeenLocked.removeAll(tabs);
    if (_tabsSeenLocked.length != before) await _saveTabsSeenLocked();
  }

  Future<void> _saveTabsSeenLocked() =>
      _put(_tabsSeenLockedKey, jsonEncode([for (final t in _tabsSeenLocked) t.name]));

  /// Side trips shown locked on the hub whose opening is still to be shown.
  Set<SideTrip> get sideTripsSeenLocked => Set.unmodifiable(_sideTripsSeenLocked);

  /// [trips] have been shown locked on the hub.
  Future<void> noteSideTripsSeenLocked(Iterable<SideTrip> trips) async {
    final before = _sideTripsSeenLocked.length;
    _sideTripsSeenLocked.addAll(trips);
    if (_sideTripsSeenLocked.length != before) await _saveSideTripsSeenLocked();
  }

  /// [trips] have opened, and their opening has been shown.
  Future<void> noteSideTripsOpened(Iterable<SideTrip> trips) async {
    final before = _sideTripsSeenLocked.length;
    _sideTripsSeenLocked.removeAll(trips);
    if (_sideTripsSeenLocked.length != before) await _saveSideTripsSeenLocked();
  }

  Future<void> _saveSideTripsSeenLocked() =>
      _put(_sideTripsSeenLockedKey, jsonEncode([for (final t in _sideTripsSeenLocked) t.name]));

  CardRef _ref(int poemId, bool inverted, int maskLevel, math.Random rng) => CardRef(
        poemId,
        inverted: inverted,
        mask: maskLevel == 0
            ? CardMask.none
            : Masking.maskFor(poems, poemId, maskLevel, rng, style: settings.maskStyle),
      );

  // ---------------------------------------------------------------- writes

  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    trainer.dayStartHour = s.dayStartHour;
    await _put('settings', jsonEncode(s.toJson()));
    notifyListeners();
  }

  Future<void> updateTrainerConfig(TrainerConfig c) async {
    trainer.updateConfig(c);
    await _put('trainer', jsonEncode(c.toJson()));
    await _latchFreePractice(DateTime.now());
    await _latchSideTrips(DateTime.now());
    notifyListeners();
  }

  /// First-launch choice (and the Settings switch): journey or all known,
  /// and the journey's pace.
  Future<void> setLearningMode(LearningMode mode, {LearningPace? pace}) async {
    await updateTrainerConfig(trainer.config.copyWith(
      learningMode: mode,
      pace: pace,
      reverseMode: mode == LearningMode.allKnown ? ReverseMode.mixed : trainer.config.reverseMode,
    ));
    final fresh = trainer.unlockEarned(poems, fudaSets, allStats, DateTime.now(), batches: _allKnown);
    if (fresh.isNotEmpty) await _saveItems(fresh);
    await updateSettings(settings.copyWith(onboarded: true));
    if (!_allKnown) await refreshToday();
  }

  Future<void> setLearningPace(LearningPace pace) => updateTrainerConfig(trainer.config.copyWith(pace: pace));

  /// Settings' journey → all-known switch (behind its own warning): unlocks
  /// every card for good, and silently marks every island as already
  /// complete, so a later switch back to journey shows a finished map (not
  /// one still stuck mid-consolidation) with nothing left to celebrate.
  Future<void> switchToAllKnown() async {
    await setLearningMode(LearningMode.allKnown);
    await _markIslands([for (final i in islands) i.index], DateTime.now());
    _unreported.clear();
    notifyListeners();
  }

  /// Whether island [index]'s completion has already been marked, by a real
  /// completion or [switchToAllKnown]'s silent one: `JourneyState` treats it
  /// as done even before its cards are individually solid.
  bool islandMarked(int index) => _islandCompletions.containsKey(index);

  /// Counts [islands] as complete from [at], those not already: completed by
  /// journey run [runId], or marked without one.
  Future<void> _markIslands(Iterable<int> islands, DateTime at, {int? runId}) async {
    final rows = [
      for (final i in islands)
        if (!_islandCompletions.containsKey(i)) IslandCompletionRow(island: i, at: at, runId: runId),
    ];
    if (rows.isEmpty) return;
    await db.batch((b) => b.insertAll(db.islandCompletions, rows, mode: InsertMode.insertOrIgnore));
    for (final r in rows) {
      _islandCompletions[r.island] = r;
    }
  }

  Future<void> _drop(String k) => (db.delete(db.keyValues)..where((r) => r.key.equals(k))).go();

  Future<void> _put(String k, String v) =>
      db.into(db.keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: k, value: v));

  Future<void> _saveItems(Iterable<ItemKey> keys) => db.batch((b) {
        for (final k in keys) {
          b.insert(db.items, trainer.items[k]!.row, mode: InsertMode.insertOrReplace);
        }
      });

  /// Stores a finished (or ended early) run and updates training, and for a
  /// ranked run the rating: one left early is a forfeit, recorded even
  /// before its first swipe. Guest runs only produce a report.
  /// [now] is when the run ended (demo-data seeding backdates it); [tobi] is
  /// Tobi's time in an exam try, and [tobiLine] his time as each card went.
  Future<SessionReport> recordRun(PlaySession run, PlayConfig config, DateTime startedAt,
      {DateTime? now, Duration? tobi, List<Duration>? tobiLine}) async {
    now ??= DateTime.now();
    final previousBest = bestFor(config);
    lastRun = run;
    if (config.mode == PlayMode.ranked) await _drop(_rankedRunningKey);
    if (!config.tracked || (run.attempts.isEmpty && config.mode != PlayMode.ranked)) {
      return SessionReport(
        runId: null,
        completed: run.finished,
        total: run.total,
        attempts: run.attempts,
        previousBest: previousBest,
        ratingBefore: rating,
        ratingAfter: rating,
        goalRaised: false,
        mode: config.mode,
      );
    }

    final ledger = xp;
    final journey = !_allKnown;
    final day = await _storeDay(startedAt);
    final score = !config.scored
        ? null
        : RankedScore.of(run, run.total ?? run.elapsed,
            penaltyMs: config.mode == PlayMode.exam ? ExamTuning.missPenaltyMs : RankedTuning.missPenaltyMs);
    final passed = config.mode == PlayMode.exam && run.finished && tobi != null && score!.scored < tobi;
    final graduated = journey && passed && !ledger.graduated;
    final before = rating;
    final forfeit = config.mode == PlayMode.ranked && !run.finished;
    final rated = config.mode == PlayMode.ranked ? _rated(forfeit ? null : score) : null;
    final newCards = config.mode == PlayMode.training && journey
        ? {for (final a in run.attempts) if (!_metBefore(a.card.poemId)) a.card.poemId}.toList()
        : const <int>[];
    final all = [
      for (final a in run.undone) (a, true),
      for (final a in run.attempts) (a, false),
    ]..sort((x, y) => x.$1.at.compareTo(y.$1.at));
    final clock = run.total ?? run.elapsed;

    final runId = await db.transaction(() async {
      final id = await db.into(db.runs).insert(RunsCompanion.insert(
            mode: config.mode,
            startedAt: startedAt,
            endedAt: now!,
            day: day.day,
            allKnown: !journey,
            setIds: Value(jsonEncode(config.setIds)),
            cardIds: Value(config.cardIds == null ? null : jsonEncode(config.cardIds)),
            maskLevel: Value(config.maskLevel),
            goalMs: trainer.goalMs.round(),
            planned: run.cards.length,
            completed: run.finished,
            clockUs: Value(clock > Duration.zero ? clock.inMicroseconds : null),
            scoredMs: Value(forfeit ? null : score?.scored.inMilliseconds),
            rating: Value(rated?.rating),
            performance: Value(rated?.performance),
            tobiMs: Value(tobi?.inMilliseconds),
            tobiLine: Value(tobiLine == null ? null : jsonEncode([for (final t in tobiLine) t.inMilliseconds])),
            graduated: Value(graduated),
          ));
      final touched = <ItemKey>{};
      final rows = <AttemptsCompanion>[];
      for (var i = 0; i < all.length; i++) {
        final (a, undone) = all[i];
        final key = ItemKey(a.card.poemId, a.card.inverted);
        final item = trainer.items[key]!;
        final rec = AttemptRec(
          at: a.at,
          us: a.cardUs,
          miss: a.isMiss || undone,
          clean: !a.tainted && !undone,
          deckSize: a.deckSize,
          mode: config.mode,
          countsForSrs: config.countsForSrs,
          maskLevel: a.card.mask.hidden.isEmpty ? 0 : config.maskLevel,
          runId: id,
          undone: undone,
        );
        final recall = item.reviewed ? trainer.retrievability(key, a.at) : null;
        // Only a run that counts feeds FSRS; see `PlayConfig.countsForSrs`.
        final grade = !rec.countsForSrs
            ? null
            : journey
                ? _reviewByDay(key, rec)
                : trainer.review(key, rec);
        (_log[key] ??= []).add(rec.withGrade(grade?.value));
        _statsCache.remove(key);
        touched.add(key);
        rows.add(AttemptsCompanion.insert(
          runId: id,
          seq: i,
          poemId: key.poemId,
          inverted: key.inverted,
          maskLevel: Value(rec.maskLevel),
          outcome: a.outcome,
          wrong: Value(a.wrong),
          tainted: Value(a.tainted),
          undone: Value(undone),
          deckSize: a.deckSize,
          at: a.at,
          revealAtUs: Value(a.revealAtUs),
          responseUs: a.responseUs,
          commitUs: Value(a.commitUs),
        ).withReview(grade, recall: recall, card: item.card));
      }
      await db.batch((b) => b.insertAll(db.attempts, rows));
      await _saveItems(touched);
      return id;
    });

    runs.add(await _runRow(runId));
    _runCounts = null;
    if (rated != null) rating = rated.rating;

    // Unlocks, islands and goal ladder.
    final reachedBefore = {
      for (final s in trainer.unlocked)
        if (!s.key.inverted && !_unreported.contains(s.key)) Trainer.islandOf(poems[s.key.poemId]),
    };
    final earned = trainer.unlockEarned(poems, fudaSets, allStats, now, batches: _allKnown);
    if (config.mode == PlayMode.training) _unreported.clear();
    final after = islands;
    final reached = [for (final i in after) if (i.reached && !reachedBefore.contains(i.index)) i.index];
    final completed = [for (final i in after) if (i.complete && !islandMarked(i.index)) i.index];
    await _markIslands(completed, now, runId: journey ? runId : null);
    if (earned.isNotEmpty) await _saveItems(earned);
    var goalRaised = false;
    if (trainer.readyForNextGoal(poems, fudaSets, allStats)) {
      trainer.goalLevel++;
      goalRaised = true;
      await _put('goalLevel', '${trainer.goalLevel}');
    }
    await _latchFreePractice(now);
    await _latchSideTrips(now);
    final dayDone = journey ? await _noteDayDone(config, now) : null;
    if (dayDone != null) {
      await (db.update(db.runs)..where((r) => r.id.equals(runId))).write(const RunsCompanion(dayDone: Value(true)));
      runs.last = runs.last.copyWith(dayDone: true);
    }
    final xpGain = ledger.add(XpHistory.latestRunOf(this, runs.last));

    notifyListeners();
    return SessionReport(
      runId: runId,
      completed: run.finished,
      total: run.total,
      attempts: run.attempts,
      previousBest: previousBest,
      ratingBefore: before,
      ratingAfter: rating,
      goalRaised: goalRaised,
      newCards: newCards,
      islandsReached: journey ? reached : const [],
      islandsCompleted: journey ? completed : const [],
      xp: xpGain,
      graduated: graduated,
      dayDone: dayDone,
      mode: config.mode,
      score: score,
      tobi: tobi,
    );
  }

  Future<RunRow> _runRow(int id) => (db.select(db.runs)..where((r) => r.id.equals(id))).getSingle();

  /// The rating a ranked run with [score] leaves, and the performance of its
  /// scored time (a forfeit, with no [score]: [RankedTuning.forfeitPerformance]):
  /// the rating moves toward it, or straight to it for the first (placement).
  ({double rating, double performance}) _rated(RankedScore? score) {
    final performance =
        score == null ? RankedTuning.forfeitPerformance : Rating.performance(score.scored.inMilliseconds.toDouble());
    return (rating: Rating.update(rating, performance, ratedRuns.length), performance: performance);
  }

  /// A ranked run that never got recorded (the app closed mid-run) is a
  /// forfeit. When it ended is not known: it is stored as ending as it
  /// started.
  Future<void> _forfeitUnrecorded(DateTime startedAt) async {
    final rated = _rated(null);
    final day = await _storeDay(startedAt);
    final id = await db.into(db.runs).insert(RunsCompanion.insert(
          mode: PlayMode.ranked,
          startedAt: startedAt,
          endedAt: startedAt,
          day: day.day,
          allKnown: true,
          setIds: Value(jsonEncode(const ['all'])),
          goalMs: trainer.goalMs.round(),
          planned: RankedTuning.cards,
          completed: false,
          rating: Value(rated.rating),
          performance: Value(rated.performance),
        ));
    runs.add(await _runRow(id));
    rating = rated.rating;
    await _drop(_rankedRunningKey);
  }

  /// Journey mode's FSRS rule: grades by the day the attempt falls in (see
  /// [Trainer.review]), so only the day's first look at a card, and every
  /// miss, is a review.
  fsrs.Rating? _reviewByDay(ItemKey key, AttemptRec a) {
    final window = dayAt(a.at);
    final firstToday = !(_log[key] ?? const <AttemptRec>[])
        .reversed
        .takeWhile((x) => !x.at.isBefore(window.start))
        .any((x) => x.countsForSrs);
    return trainer.review(key, a, dayEnd: window.end, firstToday: firstToday);
  }

  /// After a journey run: today's set is replayed, and once every card of it
  /// is settled (an empty set: once a training run is played) the day is
  /// done, which this returns the first time.
  Future<DayDone?> _noteDayDone(PlayConfig config, DateTime now) async {
    final day = _day;
    if (day == null || day.builtAt == null) return null;
    final set = _replay(day, _today?.kinds ?? const {});
    _today = set;
    if (set.done || !(set.settled || (set.steps.isEmpty && config.mode == PlayMode.training))) return null;
    await _updateDay(day.copyWith(doneAt: Value(now)));
    final done = _today = _replay(_day!, set.kinds);
    final date = done.window.date;
    return DayDone(
      date: date,
      bar: done.bar,
      rounds: runs.where((r) => r.mode == PlayMode.training && dayOf(r) == date).length,
      newCards: done.newCards,
      missesFixed: done.misses,
      goalStreak: goalStreak(now),
      xp: XpTuning.dayDone,
    );
  }

  /// Stores a 暗記練 game once it is over, ranked or free, moves its rating
  /// for a ranked one (see [SideTrips.recordAnkiren]) and adds up the
  /// experience it earned.
  Future<AnkirenReport> recordAnkiren(
    AnkirenGame game, {
    required DateTime startedAt,
    Map<String, Object?> meta = const {},
  }) async {
    final ledger = xp;
    final day = await _storeDay(startedAt);
    final report = await sideTrips.recordAnkiren(db, game, startedAt: startedAt, day: day.day, meta: meta);
    final gain = ledger.addAnkiren(XpHistory.ankirenRunOf(sideTrips, sideTrips.runs.last));
    notifyListeners();
    return AnkirenReport(
      ratingBefore: report.ratingBefore,
      ratingAfter: report.ratingAfter,
      rankedGames: report.rankedGames,
      xp: gain,
    );
  }

  /// Deletes everything (settings are kept).
  Future<void> resetProgress() async {
    await db.transaction(() async {
      await db.delete(db.attempts).go();
      await db.delete(db.islandCompletions).go();
      await db.delete(db.runs).go();
      await db.delete(db.items).go();
      await db.delete(db.sideTripAnswers).go();
      await db.delete(db.sideTripRuns).go();
      await db.delete(db.dayCards).go();
      await db.delete(db.days).go();
      await (db.delete(db.keyValues)
            ..where((k) => k.key.isIn([
                  'goalLevel',
                  _freePracticeKey,
                  _tabsSeenLockedKey,
                  _sideTripsTabKey,
                  _sideTripsKey,
                  _sideTripsSeenLockedKey,
                  _rankedRunningKey,
                  _examLastTryKey,
                  _examIntroShownKey,
                ])))
          .go();
    });
    _log.clear();
    _statsCache.clear();
    runs.clear();
    _runCounts = null;
    rating = null;
    _islandCompletions.clear();
    _freePracticeUnlocked = false;
    _tabsSeenLocked.clear();
    _sideTripsTabOpened = false;
    _sideTripsOpened.clear();
    _sideTripsSeenLocked.clear();
    sideTrips.clear();
    _unreported.clear();
    _days.clear();
    _day = null;
    _today = null;
    trainer.items
      ..clear()
      ..addAll(Trainer.freshItems());
    trainer.goalLevel = 0;
    _examLastTry = null;
    _examIntroShown = false;
    _switchBannerCollapsed = false;
    _xp = null;
    notifyListeners();
  }

  /// Settings' Reset all data: everything [resetProgress] deletes plus the
  /// learning setup and every setting, as on a fresh install, so the app
  /// starts over at the language picker.
  Future<void> resetAllData() async {
    await db.delete(db.keyValues).go();
    _settings = const AppSettings();
    trainer.updateConfig(const TrainerConfig());
    lastRun = null;
    await resetProgress();
  }
}
