import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';
import '../db/database.dart';
import '../domain/card_mask.dart';
import '../domain/card_stats.dart';
import '../domain/masking.dart';
import '../domain/play_session.dart';
import '../domain/rating.dart';
import '../domain/trainer.dart';
import '../domain/xp.dart';
import 'play_config.dart';
import 'settings.dart';
import 'xp_history.dart';

/// What a finished run changed (for the results screen).
class SessionReport {
  SessionReport({
    required this.sessionId,
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
  });

  final int? sessionId;
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

  bool get personalBest => total != null && (previousBest == null || total! < previousBest!);
}

/// A training session ready to play, with the scheduler's reasoning.
class PlannedRun {
  PlannedRun(this.cards, this.picks, this.unlockedBefore, this.newPoems);
  final List<CardRef> cards;
  final List<TrainingPick> picks;

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

/// All persistent progress: attempts, training state, rating, history and
/// settings. Loaded once at startup; the UI listens for changes.
class Progress extends ChangeNotifier {
  Progress._(this.db, this.trainer, this._log, this.sessions, this.ratingPoints, this._settings, this.rating,
      this._islandsCelebrated, this._freePracticeUnlocked);

  final AppDatabase db;
  final Trainer trainer;
  final Map<ItemKey, List<AttemptRec>> _log;
  final List<Session> sessions;
  final List<RatingPoint> ratingPoints;
  AppSettings _settings;
  double? rating;
  final _statsCache = <ItemKey, CardStats>{};
  final _missesCache = <int, int>{};

  /// Unlocked while planning a run and not yet part of a recorded one (for
  /// the islands a run reaches).
  final _unreported = <ItemKey>[];
  final Set<int> _islandsCelebrated;

  /// Free practice has opened once, so it stays open (see [freePractice]).
  bool _freePracticeUnlocked;

  /// The most recent run, kept in memory for the debug page's timing view.
  PlaySession? lastRun;

  AppSettings get settings => _settings;

  /// Experience so far, rebuilt from the recorded history on first use.
  XpLedger get xp => _xp ??= XpHistory.ledgerOf(this);
  XpLedger? _xp;

  static Future<Progress> open(AppDatabase db) async {
    final kv = {for (final r in await db.select(db.keyValues).get()) r.key: r.value};
    Map<String, dynamic> json(String k) => kv[k] == null ? {} : jsonDecode(kv[k]!) as Map<String, dynamic>;

    final items = Trainer.freshItems();
    for (final r in await db.select(db.items).get()) {
      final k = ItemKey(r.poemId, r.inverted);
      items[k] = ItemState(
        k,
        unlocked: r.unlocked,
        unlockedAt: r.unlockedAt,
        card: r.fsrs == null ? null : ItemState.cardFromJson(r.fsrs!),
        maskLevel: r.maskLevel,
      );
    }
    final trainer = Trainer(
      config: TrainerConfig.fromJson(json('trainer')),
      items: items,
      goalLevel: int.tryParse(kv['goalLevel'] ?? '') ?? 0,
    );

    final sessions = await (db.select(db.sessions)..orderBy([(s) => OrderingTerm.asc(s.startedAt)])).get();
    final configOf = {for (final s in sessions) s.id: _configOf(s)};

    final log = <ItemKey, List<AttemptRec>>{};
    final rows = await (db.select(db.attempts)..orderBy([(a) => OrderingTerm.asc(a.at), (a) => OrderingTerm.asc(a.id)])).get();
    for (final a in rows) {
      (log[ItemKey(a.poemId, a.inverted)] ??= []).add(_rec(a, configOf[a.sessionId] ?? _orphanRun));
    }
    final points = await (db.select(db.ratingPoints)..orderBy([(r) => OrderingTerm.asc(r.at)])).get();
    // A rating stored as NaN (from a 0 µs sample, before those stopped
    // counting as timed) falls back to the last good rating point.
    final stored = double.tryParse(kv['rating'] ?? '');
    final rating = stored == null || stored.isFinite ? stored : points.lastOrNull?.rating;
    final progress = Progress._(
      db,
      trainer,
      log,
      sessions,
      points,
      AppSettings.fromJson(json('settings')),
      rating,
      {...((jsonDecode(kv['islandsCelebrated'] ?? '[]') as List).cast<int>())},
      kv[_freePracticeKey] == 'true',
    );
    await progress._latchFreePractice(DateTime.now());
    return progress;
  }

  /// Stands in for the session of an attempt whose session row is missing.
  static const _orphanRun = PlayConfig(mode: PlayMode.free);
  static const _freePracticeKey = 'freePracticeUnlocked';

  static AttemptRec _rec(AttemptRow a, PlayConfig run) => AttemptRec(
        at: a.at,
        us: a.responseUs,
        miss: a.outcome == Outcome.dontKnow.index || a.wrong || a.undone,
        clean: !a.tainted && !a.undone,
        deckSize: a.deckSize,
        mode: run.mode,
        countsForSrs: run.countsForSrs,
        maskLevel: a.maskLevel,
        grade: a.grade,
        sessionId: a.sessionId,
      );

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

  /// Misses (wrong, "don't know" or undone) recorded in one session — for
  /// the History tab.
  int missesIn(int sessionId) => _missesCache[sessionId] ??=
      _log.values.expand((a) => a).where((a) => a.sessionId == sessionId && a.miss).length;

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
    int? best;
    for (final s in sessions) {
      if (!s.completed || s.totalUs == null) continue;
      if (_configOf(s).historyKey != c.historyKey) continue;
      if (best == null || s.totalUs! < best) best = s.totalUs;
    }
    return best == null ? null : Duration(microseconds: best);
  }

  PlayConfig configOf(Session s) => _configOf(s);

  static PlayConfig _configOf(Session s) {
    final meta = jsonDecode(s.meta) as Map<String, dynamic>;
    return PlayConfig(
      mode: PlayMode.values[s.mode],
      setIds: (jsonDecode(s.setIds) as List).cast<String>(),
      cardIds: (meta['cardIds'] as List?)?.cast<int>(),
      maskLevel: meta['maskLevel'] as int? ?? 0,
    );
  }

  /// Days (local dates) with at least one tracked run.
  Set<DateTime> get practiceDays => {
        for (final s in sessions) DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day),
      };

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

  int get streak {
    final days = practiceDays;
    var d = DateTime.now();
    d = DateTime(d.year, d.month, d.day);
    if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (days.contains(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
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

  /// Whether Home's "Learn ahead" is open, and why not.
  LearnAhead learnAhead([DateTime? now]) => trainer.learnAhead(poems, fudaSets, allStats, now ?? DateTime.now());

  /// Journey mode with cards still locked: "Learn ahead" is on offer.
  bool get canLearnMore =>
      trainer.config.learningMode == LearningMode.journey && trainer.nextBatch(poems, fudaSets).isNotEmpty;

  /// Every card already unlocked: switching journey → all-known has nothing
  /// left to warn about.
  bool get allCardsUnlocked => trainer.nextBatch(poems, fudaSets).isEmpty;

  /// 修行: unlock what was earned, then plan a session.
  Future<PlannedRun> planTraining({math.Random? rng, DateTime? now}) async {
    now ??= DateTime.now();
    final fresh = trainer.unlockEarned(poems, fudaSets, allStats, now);
    if (fresh.isNotEmpty) await _saveItems(fresh);
    return _plan(fresh, rng ?? math.Random(), now);
  }

  /// "Learn ahead": unlocks the next batch now, ignoring pace and
  /// readiness, then plans a session that includes it.
  Future<PlannedRun> learnAheadCards({math.Random? rng, DateTime? now}) async {
    now ??= DateTime.now();
    final fresh = trainer.unlockNextBatch(poems, fudaSets, now);
    if (fresh.isNotEmpty) {
      await _saveItems(fresh);
      notifyListeners();
    }
    return _plan(fresh, rng ?? math.Random(), now);
  }

  PlannedRun _plan(List<ItemKey> fresh, math.Random rng, DateTime now) {
    _unreported.addAll(fresh);
    final stats = allStats;
    final picks = trainer.planSession(stats, now, rng);
    final cards = [
      for (final p in picks) _ref(p.key.poemId, p.key.inverted, trainer.items[p.key]!.maskLevel, rng),
    ];
    final newPoems = trainer.config.learningMode == LearningMode.journey
        ? {for (final p in picks) if (Trainer.isNewPoem(stats, p.key.poemId)) p.key.poemId}
        : <int>{};
    return PlannedRun(cards, picks, fresh, newPoems);
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
    final remembered = trainer.wellRememberedCount(allStats, now ?? DateTime.now());
    return FreePracticeAccess(open: remembered >= FreePracticeTuning.unlockRemembered, remembered: remembered);
  }

  /// Stores the free-practice latch the first time [freePractice] is open.
  Future<void> _latchFreePractice(DateTime now) async {
    if (_freePracticeUnlocked || !freePractice(now).open) return;
    _freePracticeUnlocked = true;
    await _put(_freePracticeKey, 'true');
  }

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
    await _put('settings', jsonEncode(s.toJson()));
    notifyListeners();
  }

  Future<void> updateTrainerConfig(TrainerConfig c) async {
    trainer.updateConfig(c);
    await _put('trainer', jsonEncode(c.toJson()));
    await _latchFreePractice(DateTime.now());
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
    final fresh = trainer.unlockEarned(poems, fudaSets, allStats, DateTime.now());
    if (fresh.isNotEmpty) await _saveItems(fresh);
    await updateSettings(settings.copyWith(onboarded: true));
  }

  Future<void> setLearningPace(LearningPace pace) => updateTrainerConfig(trainer.config.copyWith(pace: pace));

  /// Settings' journey → all-known switch (behind its own warning): unlocks
  /// every card for good, and silently marks every island as already
  /// complete, so a later switch back to journey shows a finished map (not
  /// one still stuck mid-consolidation) with nothing left to celebrate.
  Future<void> switchToAllKnown() async {
    await setLearningMode(LearningMode.allKnown);
    _islandsCelebrated.addAll(islands.map((i) => i.index));
    await _put('islandsCelebrated', jsonEncode(_islandsCelebrated.toList()..sort()));
    _unreported.clear();
    notifyListeners();
  }

  /// Whether island [index]'s completion has already been marked, by a real
  /// completion or [switchToAllKnown]'s silent one: `JourneyState` treats it
  /// as done even before its cards are individually solid.
  bool islandMarked(int index) => _islandsCelebrated.contains(index);

  Future<void> _put(String k, String v) =>
      db.into(db.keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: k, value: v));

  Future<void> _saveItems(Iterable<ItemKey> keys) async {
    await db.batch((b) {
      for (final k in keys) {
        final s = trainer.items[k]!;
        b.insert(
          db.items,
          ItemsCompanion.insert(
            poemId: k.poemId,
            inverted: k.inverted,
            unlocked: Value(s.unlocked),
            unlockedAt: Value(s.unlockedAt),
            fsrs: Value(s.reviewed ? s.fsrsJson : null),
            maskLevel: Value(s.maskLevel),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Stores a finished (or ended early) run and updates training and rating.
  /// Guest runs only produce a report.
  /// [now] is when the run ended (demo-data seeding backdates it).
  Future<SessionReport> recordRun(PlaySession run, PlayConfig config, DateTime startedAt, {DateTime? now}) async {
    now ??= DateTime.now();
    final previousBest = bestFor(config);
    lastRun = run;
    if (!config.tracked || run.attempts.isEmpty) {
      return SessionReport(
        sessionId: null,
        total: run.finished ? run.total : null,
        attempts: run.attempts,
        previousBest: previousBest,
        ratingBefore: rating,
        ratingAfter: rating,
        goalRaised: false,
      );
    }

    final ledger = xp;
    final newCards = config.mode == PlayMode.training && trainer.config.learningMode == LearningMode.journey
        ? {for (final a in run.attempts) if (!_metBefore(a.card.poemId)) a.card.poemId}.toList()
        : const <int>[];
    final all = [
      for (final a in run.undone) (a, true),
      for (final a in run.attempts) (a, false),
    ]..sort((x, y) => x.$1.at.compareTo(y.$1.at));

    final sessionId = await db.transaction(() async {
      final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
            startedAt: startedAt,
            mode: config.mode.index,
            setIds: Value(jsonEncode(config.setIds)),
            orientation: 0,
            cardCount: run.cards.length,
            totalUs: Value(run.finished ? run.total?.inMicroseconds : null),
            completed: run.finished,
            meta: Value(jsonEncode({
              'maskLevel': config.maskLevel,
              'goalMs': trainer.goalMs,
              if (config.cardIds != null) 'cardIds': config.cardIds,
            })),
          ));
      final touched = <ItemKey>{};
      final rows = <AttemptsCompanion>[];
      for (var i = 0; i < all.length; i++) {
        final (a, undone) = all[i];
        final key = ItemKey(a.card.poemId, a.card.inverted);
        final rec = AttemptRec(
          at: a.at,
          us: a.responseUs,
          miss: a.isMiss || undone,
          clean: !a.tainted && !undone,
          deckSize: a.deckSize,
          mode: config.mode,
          countsForSrs: config.countsForSrs,
          maskLevel: a.card.mask.hidden.isEmpty ? 0 : config.maskLevel,
          sessionId: id,
        );
        // Only a run that counts feeds FSRS; see `PlayConfig.countsForSrs`.
        final grade = rec.countsForSrs ? trainer.review(key, rec) : null;
        final stored = AttemptRec(
          at: rec.at,
          us: rec.us,
          miss: rec.miss,
          clean: rec.clean,
          deckSize: rec.deckSize,
          mode: rec.mode,
          countsForSrs: rec.countsForSrs,
          maskLevel: rec.maskLevel,
          grade: grade?.value,
          sessionId: id,
        );
        (_log[key] ??= []).add(stored);
        _statsCache.remove(key);
        touched.add(key);
        rows.add(AttemptsCompanion.insert(
              sessionId: id,
              seq: i,
              poemId: key.poemId,
              inverted: key.inverted,
              maskLevel: Value(rec.maskLevel),
              responseUs: a.responseUs,
              outcome: a.outcome.index,
              wrong: Value(a.wrong),
              tainted: Value(a.tainted),
              undone: Value(undone),
              deckSize: a.deckSize,
              at: a.at,
              grade: Value(grade?.value),
            ));
      }
      await db.batch((b) => b.insertAll(db.attempts, rows));
      await _saveItems(touched);
      return id;
    });

    sessions.add((await (db.select(db.sessions)..where((s) => s.id.equals(sessionId))).getSingle()));

    // Rating: only a run that counts moves it. `stats()` already leaves the
    // others out, so the projected performance would be unchanged anyway —
    // but re-running the smoothing update would still nudge `rating` another
    // step toward that same performance, which is exactly the leak
    // `countsForSrs` is meant to prevent.
    final before = rating;
    if (config.countsForSrs) {
      final projected = projectedMs;
      final perf = Rating.performance(projected);
      rating = Rating.update(rating, perf, ratingPoints.length);
      await _put('rating', rating!.toString());
      await db.into(db.ratingPoints).insert(RatingPointsCompanion.insert(
            at: now,
            rating: rating!,
            performance: perf,
            projectedMs: projected.round(),
            sessionId: Value(sessionId),
          ));
      ratingPoints.add(RatingPoint(
        id: 0,
        at: now,
        rating: rating!,
        performance: perf,
        projectedMs: projected.round(),
        sessionId: sessionId,
      ));
    }

    // Unlocks, islands and goal ladder.
    final reachedBefore = {
      for (final s in trainer.unlocked)
        if (!s.key.inverted && !_unreported.contains(s.key)) Trainer.islandOf(poems[s.key.poemId]),
    };
    final earned = trainer.unlockEarned(poems, fudaSets, allStats, now);
    if (config.mode == PlayMode.training) _unreported.clear();
    final after = islands;
    final reached = [for (final i in after) if (i.reached && !reachedBefore.contains(i.index)) i.index];
    final completed = [
      for (final i in after)
        if (i.complete && !_islandsCelebrated.contains(i.index)) i.index,
    ];
    if (completed.isNotEmpty) {
      _islandsCelebrated.addAll(completed);
      await _put('islandsCelebrated', jsonEncode(_islandsCelebrated.toList()..sort()));
    }
    if (earned.isNotEmpty) await _saveItems(earned);
    var goalRaised = false;
    if (trainer.readyForNextGoal(poems, fudaSets, allStats)) {
      trainer.goalLevel++;
      goalRaised = true;
      await _put('goalLevel', '${trainer.goalLevel}');
    }
    await _latchFreePractice(now);
    final journey = trainer.config.learningMode == LearningMode.journey;
    final graduated = journey && !ledger.graduated && poems.all.every((p) => knows(p.id));
    sessions.last = await XpHistory.noteMilestones(db, sessions.last,
        islands: journey ? completed : const [], graduated: graduated);
    final xpGain = ledger.add(XpHistory.latestRunOf(this, sessions.last));

    notifyListeners();
    return SessionReport(
      sessionId: sessionId,
      total: run.finished ? run.total : null,
      attempts: run.attempts,
      previousBest: previousBest,
      ratingBefore: before,
      ratingAfter: rating,
      goalRaised: goalRaised,
      newCards: newCards,
      islandsReached: trainer.config.learningMode == LearningMode.journey ? reached : const [],
      islandsCompleted: trainer.config.learningMode == LearningMode.journey ? completed : const [],
      xp: xpGain,
      graduated: graduated,
    );
  }

  /// Deletes everything (settings are kept).
  Future<void> resetProgress() async {
    await db.transaction(() async {
      await db.delete(db.attempts).go();
      await db.delete(db.sessions).go();
      await db.delete(db.items).go();
      await db.delete(db.ratingPoints).go();
      await (db.delete(db.keyValues)
            ..where((k) => k.key.isIn(['rating', 'goalLevel', 'islandsCelebrated', _freePracticeKey])))
          .go();
    });
    _log.clear();
    _statsCache.clear();
    sessions.clear();
    ratingPoints.clear();
    rating = null;
    _islandsCelebrated.clear();
    _freePracticeUnlocked = false;
    _unreported.clear();
    trainer.items
      ..clear()
      ..addAll(Trainer.freshItems());
    trainer.goalLevel = 0;
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
