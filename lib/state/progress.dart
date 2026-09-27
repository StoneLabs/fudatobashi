import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/fuda_sets.dart';
import '../data/poem.dart';
import '../db/database.dart';
import '../domain/card_mask.dart';
import '../domain/card_stats.dart';
import '../domain/masking.dart';
import '../domain/play_session.dart';
import '../domain/rating.dart';
import '../domain/trainer.dart';
import 'play_config.dart';
import 'settings.dart';

/// What a finished run changed (for the results screen).
class SessionReport {
  SessionReport({
    required this.sessionId,
    required this.total,
    required this.attempts,
    required this.previousBest,
    required this.ratingBefore,
    required this.ratingAfter,
    required this.unlocked,
    required this.goalRaised,
  });

  final int? sessionId;
  final Duration? total;
  final List<Attempt> attempts;

  /// Best total for the same setup before this run (null if first).
  final Duration? previousBest;
  final double? ratingBefore;
  final double? ratingAfter;
  final List<ItemKey> unlocked;
  final bool goalRaised;

  bool get personalBest => total != null && (previousBest == null || total! < previousBest!);
}

/// A training session ready to play, with the scheduler's reasoning.
class PlannedRun {
  PlannedRun(this.cards, this.picks, this.unlockedBefore);
  final List<CardRef> cards;
  final List<TrainingPick> picks;

  /// Cards unlocked right before this run (celebrate first).
  final List<ItemKey> unlockedBefore;
}

/// All persistent progress: attempts, training state, rating, history and
/// settings. Loaded once at startup; the UI listens for changes.
class Progress extends ChangeNotifier {
  Progress._(this.db, this.trainer, this._log, this.sessions, this.ratingPoints, this._settings, this.rating);

  final AppDatabase db;
  final Trainer trainer;
  final Map<ItemKey, List<AttemptRec>> _log;
  final List<Session> sessions;
  final List<RatingPoint> ratingPoints;
  AppSettings _settings;
  double? rating;
  final _statsCache = <ItemKey, CardStats>{};

  /// The most recent run, kept in memory for the debug page's timing view.
  PlaySession? lastRun;

  AppSettings get settings => _settings;

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

    final log = <ItemKey, List<AttemptRec>>{};
    final rows = await (db.select(db.attempts)..orderBy([(a) => OrderingTerm.asc(a.at), (a) => OrderingTerm.asc(a.id)])).get();
    for (final a in rows) {
      (log[ItemKey(a.poemId, a.inverted)] ??= []).add(_rec(a));
    }
    final sessions = await (db.select(db.sessions)..orderBy([(s) => OrderingTerm.asc(s.startedAt)])).get();
    final points = await (db.select(db.ratingPoints)..orderBy([(r) => OrderingTerm.asc(r.at)])).get();
    return Progress._(
      db,
      trainer,
      log,
      sessions,
      points,
      AppSettings.fromJson(json('settings')),
      double.tryParse(kv['rating'] ?? ''),
    );
  }

  static AttemptRec _rec(AttemptRow a) => AttemptRec(
        at: a.at,
        us: a.responseUs,
        miss: a.outcome == Outcome.dontKnow.index || a.wrong || a.undone,
        clean: !a.tainted && !a.undone,
        deckSize: a.deckSize,
        maskLevel: a.maskLevel,
        grade: a.grade,
        sessionId: a.sessionId,
      );

  // ---------------------------------------------------------------- reads

  CardStats stats(ItemKey k) => _statsCache[k] ??= CardStats(_log[k] ?? const []);

  Map<ItemKey, CardStats> get allStats => {for (final k in trainer.items.keys) k: stats(k)};

  List<AttemptRec> attemptsOf(ItemKey k) => _log[k] ?? const [];

  double get projectedMs => Rating.projectedMs(stats);

  RankBand get band => Rating.bandOf(rating ?? Rating.performance(projectedMs));

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
      orientation: CardOrientation.values[s.orientation],
      maskLevel: meta['maskLevel'] as int? ?? 0,
    );
  }

  /// Days (local dates) with at least one tracked run.
  Set<DateTime> get practiceDays => {
        for (final s in sessions) DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day),
      };

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

  List<CardRef> freeDeck(PlayConfig c, {math.Random? rng}) {
    rng ??= math.Random();
    final ids = fudaSets.union(c.setIds)..shuffle(rng);
    return [for (final id in ids) _ref(id, _invertedFor(c.orientation, rng), c.maskLevel, rng)];
  }

  /// 苦手: the cards with the worst expected time (misses count as slow).
  List<CardRef> nigateDeck(PlayConfig c, {math.Random? rng}) {
    rng ??= math.Random();
    final seen = [for (final k in trainer.items.keys) if (stats(k).seen) k]
      ..sort((a, b) => stats(b).expectedMs().compareTo(stats(a).expectedMs()));
    final keys = seen.take(settings.nigateCount).toList()..shuffle(rng);
    return [for (final k in keys) _ref(k.poemId, k.inverted, c.maskLevel, rng)];
  }

  /// 修行: unlock what was earned, then plan a session.
  Future<PlannedRun> planTraining({math.Random? rng}) async {
    rng ??= math.Random();
    final now = DateTime.now();
    final fresh = trainer.unlockEarned(poems, fudaSets, allStats, now);
    if (fresh.isNotEmpty) await _saveItems(fresh);
    final picks = trainer.planSession(allStats, now, rng);
    final cards = [
      for (final p in picks) _ref(p.key.poemId, p.key.inverted, trainer.items[p.key]!.maskLevel, rng),
    ];
    return PlannedRun(cards, picks, fresh);
  }

  static bool _invertedFor(CardOrientation o, math.Random rng) => switch (o) {
        CardOrientation.random => rng.nextBool(),
        CardOrientation.upright => false,
        CardOrientation.inverted => true,
      };

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
    notifyListeners();
  }

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
  Future<SessionReport> recordRun(PlaySession run, PlayConfig config, DateTime startedAt) async {
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
        unlocked: const [],
        goalRaised: false,
      );
    }

    final all = [
      for (final a in run.undone) (a, true),
      for (final a in run.attempts) (a, false),
    ]..sort((x, y) => x.$1.at.compareTo(y.$1.at));

    final sessionId = await db.transaction(() async {
      final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
            startedAt: startedAt,
            mode: config.mode.index,
            setIds: Value(jsonEncode(config.setIds)),
            orientation: config.orientation.index,
            cardCount: run.cards.length,
            totalUs: Value(run.finished ? run.total?.inMicroseconds : null),
            completed: run.finished,
            meta: Value(jsonEncode({'maskLevel': config.maskLevel, 'goalMs': trainer.goalMs})),
          ));
      final touched = <ItemKey>{};
      for (var i = 0; i < all.length; i++) {
        final (a, undone) = all[i];
        final key = ItemKey(a.card.poemId, a.card.inverted);
        final rec = AttemptRec(
          at: a.at,
          us: a.responseUs,
          miss: a.isMiss || undone,
          clean: !a.tainted && !undone,
          deckSize: a.deckSize,
          maskLevel: a.card.mask.hidden.isEmpty ? 0 : config.maskLevel,
          sessionId: id,
        );
        final grade = trainer.review(key, rec);
        final stored = AttemptRec(
          at: rec.at,
          us: rec.us,
          miss: rec.miss,
          clean: rec.clean,
          deckSize: rec.deckSize,
          maskLevel: rec.maskLevel,
          grade: grade?.value,
          sessionId: id,
        );
        (_log[key] ??= []).add(stored);
        _statsCache.remove(key);
        touched.add(key);
        await db.into(db.attempts).insert(AttemptsCompanion.insert(
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
      await _saveItems(touched);
      return id;
    });

    sessions.add((await (db.select(db.sessions)..where((s) => s.id.equals(sessionId))).getSingle()));

    // Rating.
    final before = rating;
    final projected = projectedMs;
    final perf = Rating.performance(projected);
    rating = Rating.update(rating, perf, ratingPoints.length);
    await _put('rating', rating!.toString());
    await db.into(db.ratingPoints).insert(RatingPointsCompanion.insert(
          at: DateTime.now(),
          rating: rating!,
          performance: perf,
          projectedMs: projected.round(),
          sessionId: Value(sessionId),
        ));
    ratingPoints.add(RatingPoint(
      id: 0,
      at: DateTime.now(),
      rating: rating!,
      performance: perf,
      projectedMs: projected.round(),
      sessionId: sessionId,
    ));

    // Unlocks and goal ladder.
    final fresh = trainer.unlockEarned(poems, fudaSets, allStats, DateTime.now());
    if (fresh.isNotEmpty) await _saveItems(fresh);
    var goalRaised = false;
    if (trainer.readyForNextGoal(poems, fudaSets, allStats)) {
      trainer.goalLevel++;
      goalRaised = true;
      await _put('goalLevel', '${trainer.goalLevel}');
    }

    notifyListeners();
    return SessionReport(
      sessionId: sessionId,
      total: run.finished ? run.total : null,
      attempts: run.attempts,
      previousBest: previousBest,
      ratingBefore: before,
      ratingAfter: rating,
      unlocked: fresh,
      goalRaised: goalRaised,
    );
  }

  /// Deletes everything (settings are kept).
  Future<void> resetProgress() async {
    await db.transaction(() async {
      await db.delete(db.attempts).go();
      await db.delete(db.sessions).go();
      await db.delete(db.items).go();
      await db.delete(db.ratingPoints).go();
      await (db.delete(db.keyValues)..where((k) => k.key.isIn(['rating', 'goalLevel']))).go();
    });
    _log.clear();
    _statsCache.clear();
    sessions.clear();
    ratingPoints.clear();
    rating = null;
    trainer.items
      ..clear()
      ..addAll(Trainer.freshItems());
    trainer.goalLevel = 0;
    notifyListeners();
  }
}
