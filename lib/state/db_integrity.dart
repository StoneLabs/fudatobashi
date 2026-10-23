import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../db/database.dart';
import '../db/fsrs_rows.dart';
import '../domain/ankiren_rating.dart';
import '../domain/card_stats.dart';
import '../domain/play_session.dart';
import '../domain/rating.dart';
import '../domain/side_trips.dart';
import '../domain/trainer.dart';

/// One independent integrity check: a cheap [detect] that only reads, and a
/// [repair] that runs, in one transaction, only when something was detected.
/// A repair must leave nothing for [detect] to find again.
class IntegrityCheck {
  const IntegrityCheck(this.name, this.detect, this.repair);

  final String name;
  final Future<bool> Function(AppDatabase db) detect;
  final Future<void> Function(AppDatabase db) repair;
}

/// Checks the saved data for impossible states on every start, before it is
/// used, and repairs what it finds. A clean database costs one read per check
/// and no writes. A check that throws is logged and skipped; it never blocks
/// the start.
///
/// To add a check, write a detect and a repair and append an
/// [IntegrityCheck] to [checks].
abstract final class DbIntegrity {
  static final checks = <IntegrityCheck>[
    IntegrityCheck('impossible times', _hasImpossibleTimes, _repairImpossibleTimes),
    IntegrityCheck('orphaned side-trip answers', _hasOrphanedAnswers, _deleteOrphanedAnswers),
    IntegrityCheck('side-trip ratings', _hasBrokenSideTripRatings, _replaySideTripRatings),
    IntegrityCheck('orphaned day cards', _hasOrphanedDayCards, _deleteOrphanedDayCards),
  ];

  static Future<void> run(AppDatabase db) async {
    final repaired = <String>[];
    for (final check in checks) {
      try {
        if (!await check.detect(db)) continue;
        await db.transaction(() => check.repair(db));
        repaired.add(check.name);
      } catch (e, st) {
        debugPrint('Integrity check "${check.name}" failed: $e\n$st');
      }
    }
    if (repaired.isNotEmpty) debugPrint('Database integrity: repaired ${repaired.join(', ')}');
  }

  /// Runs recorded before touch and frame times were put on one clock (see
  /// `PointerClock`) came out at or below zero on iOS and macOS, stored as
  /// 0 µs, with run clocks negative or too short.
  ///
  /// * A run whose clock is no measurement, or whose every swipe has an
  ///   impossible time, loses its clock (so it is no personal best) and its
  ///   rating; the ratings of the ranked runs after it are replayed.
  /// * A correct swipe with an impossible time loses its FSRS grade (it was
  ///   taken for a lightning-fast answer), and its card's FSRS state is
  ///   replayed from the grades left.
  ///
  /// Experience is rebuilt from the history on load, so it follows.
  static Future<bool> _hasImpossibleTimes(AppDatabase db) async {
    final found = await db.customSelect(
      """
      SELECT EXISTS (
        SELECT 1 FROM attempts WHERE response_us <= 0 AND grade IS NOT NULL AND grade != ?
      ) OR EXISTS (
        SELECT 1 FROM runs r
        WHERE (r.clock_us <= 0
               OR (EXISTS (SELECT 1 FROM attempts a WHERE a.run_id = r.id)
                   AND NOT EXISTS (SELECT 1 FROM attempts a WHERE a.run_id = r.id AND a.response_us > 0)))
          AND (r.clock_us IS NOT NULL OR r.rating IS NOT NULL)
      ) AS found
      """,
      variables: [Variable.withInt(fsrs.Rating.again.value)],
    ).getSingle();
    return found.read<bool>('found');
  }

  static Future<void> _repairImpossibleTimes(AppDatabase db) async {
    final trainer = (await (db.select(db.keyValues)..where((k) => k.key.equals('trainer'))).getSingleOrNull())?.value;
    final config = trainer == null
        ? const TrainerConfig()
        : TrainerConfig.fromJson(jsonDecode(trainer) as Map<String, dynamic>);
    final attempts = await (db.select(db.attempts)
          ..orderBy([(a) => OrderingTerm.asc(a.at), (a) => OrderingTerm.asc(a.id)]))
        .get();
    await _runs(db, attempts);
    await _grades(db, attempts, Trainer.schedulerFor(config));
  }

  static Future<void> _runs(AppDatabase db, List<AttemptRow> attempts) async {
    final timed = <int, bool>{};
    for (final a in attempts) {
      timed[a.runId] = (timed[a.runId] ?? false) || Attempt.isValidTime(a.responseUs);
    }
    final runs = await (db.select(db.runs)
          ..orderBy([(r) => OrderingTerm.asc(r.startedAt), (r) => OrderingTerm.asc(r.id)]))
        .get();
    final bad = {
      for (final r in runs)
        if ((r.clockUs != null && r.clockUs! <= 0) || timed[r.id] == false) r.id,
    };
    if (bad.isEmpty) return;
    await (db.update(db.runs)..where((r) => r.id.isIn(bad)))
        .write(const RunsCompanion(clockUs: Value(null), rating: Value(null), performance: Value(null)));

    final rated = [for (final r in runs) if (r.rating != null) r];
    final first = rated.indexWhere((r) => bad.contains(r.id));
    if (first < 0) return;
    var rating = first == 0 ? null : rated[first - 1].rating;
    var kept = first;
    for (final r in rated.skip(first)) {
      if (bad.contains(r.id)) continue;
      rating = Rating.update(rating, r.performance!, kept++);
      await (db.update(db.runs)..where((x) => x.id.equals(r.id))).write(RunsCompanion(rating: Value(rating)));
    }
  }

  static Future<void> _grades(AppDatabase db, List<AttemptRow> attempts, fsrs.Scheduler scheduler) async {
    final taken = {
      for (final a in attempts)
        if (a.grade != null && a.grade != fsrs.Rating.again.value && !Attempt.isValidTime(a.responseUs)) a.id,
    };
    if (taken.isEmpty) return;
    await (db.update(db.attempts)..where((a) => a.id.isIn(taken))).write(const AttemptsCompanion().withReview(null));

    final cards = {
      for (final a in attempts)
        if (taken.contains(a.id)) ItemKey(a.poemId, a.inverted),
    };
    for (final key in cards) {
      final stored = await (db.select(db.items)
            ..where((i) => i.poemId.equals(key.poemId) & i.inverted.equals(key.inverted)))
          .getSingleOrNull();
      final item = ItemState(key, unlocked: stored?.unlocked ?? false, unlockedAt: stored?.unlockedAt);
      for (final a in attempts) {
        if (a.grade == null || taken.contains(a.id) || ItemKey(a.poemId, a.inverted) != key) continue;
        final grade = fsrs.Rating.fromValue(a.grade!);
        final at = a.at.toUtc();
        final recall = item.reviewed ? Trainer.recallOf(item.card, scheduler, at) : null;
        item.card = scheduler.reviewCard(item.card, grade, reviewDateTime: at).card;
        await (db.update(db.attempts)..where((x) => x.id.equals(a.id)))
            .write(const AttemptsCompanion().withReview(grade, recall: recall, card: item.card));
      }
      await db.into(db.items).insertOnConflictUpdate(item.row);
    }
  }

  /// Answers of a side-trip game that is no longer stored: nothing reads
  /// them, so they go.
  static Future<bool> _hasOrphanedAnswers(AppDatabase db) async {
    final found = await db.customSelect(
      '''
      SELECT EXISTS (
        SELECT 1 FROM side_trip_answers a WHERE NOT EXISTS (SELECT 1 FROM side_trip_runs r WHERE r.id = a.run_id)
      ) AS found
      ''',
    ).getSingle();
    return found.read<bool>('found');
  }

  static Future<void> _deleteOrphanedAnswers(AppDatabase db) async {
    final runs = db.selectOnly(db.sideTripRuns)..addColumns([db.sideTripRuns.id]);
    await (db.delete(db.sideTripAnswers)..where((a) => a.runId.isNotInQuery(runs))).go();
  }

  /// A card of a day's set whose day is gone.
  static Future<bool> _hasOrphanedDayCards(AppDatabase db) async {
    final found = await db.customSelect(
      '''
      SELECT EXISTS (
        SELECT 1 FROM day_cards c WHERE NOT EXISTS (SELECT 1 FROM days d WHERE d.day = c.day)
      ) AS found
      ''',
    ).getSingle();
    return found.read<bool>('found');
  }

  static Future<void> _deleteOrphanedDayCards(AppDatabase db) async {
    final days = db.selectOnly(db.days)..addColumns([db.days.day]);
    await (db.delete(db.dayCards)..where((c) => c.day.isNotInQuery(days))).go();
  }

  /// A ranked side-trip game has no level, and stores its performance and
  /// the trip's rating after it, both finite, or neither (its game was
  /// dropped from the rating). SQLite keeps an infinity, and stores NaN as
  /// null.
  ///
  /// A ranked game with a level becomes a free game at it, without a
  /// rating. From the first ranked game of a trip that breaks the rest,
  /// its ratings are replayed from the stored performances in order; a game
  /// whose performance is no number is dropped from the rating.
  static Future<bool> _hasBrokenSideTripRatings(AppDatabase db) async {
    final found = await db.customSelect(
      '''
      SELECT EXISTS (
        SELECT 1 FROM side_trip_runs
        WHERE ranked AND (level IS NOT NULL OR (performance IS NULL) != (rating IS NULL)
                          OR abs(performance) = 9e999 OR abs(rating) = 9e999)
      ) AS found
      ''',
    ).getSingle();
    return found.read<bool>('found');
  }

  static Future<void> _replaySideTripRatings(AppDatabase db) async {
    await (db.update(db.sideTripRuns)..where((r) => r.ranked & r.level.isNotNull())).write(
        const SideTripRunsCompanion(ranked: Value(false), rating: Value(null), performance: Value(null)));
    final ranked = await (db.select(db.sideTripRuns)
          ..where((r) => r.ranked)
          ..orderBy([(r) => OrderingTerm.asc(r.id)]))
        .get();
    bool sound(SideTripRun r) =>
        r.performance == null ? r.rating == null : r.performance!.isFinite && (r.rating?.isFinite ?? false);
    const dropped = SideTripRunsCompanion(rating: Value(null), performance: Value(null));
    for (final trip in SideTrip.values) {
      final (start, update) = switch (trip) {
        SideTrip.ankiren => (AnkirenRating.start, AnkirenRating.update),
      };
      final runs = [
        for (final r in ranked)
          if (r.game == trip) r,
      ];
      final first = runs.indexWhere((r) => !sound(r));
      if (first < 0) continue;
      final kept = [for (final r in runs.take(first)) if (r.rating != null) r];
      var rating = kept.lastOrNull?.rating ?? start;
      final performances = [for (final r in kept) r.performance!];
      for (final r in runs.skip(first)) {
        final performance = r.performance;
        final SideTripRunsCompanion replayed;
        if (performance == null || !performance.isFinite) {
          replayed = dropped;
        } else {
          rating = update(rating, performance, performances);
          performances.add(performance);
          replayed = SideTripRunsCompanion(rating: Value(rating));
        }
        await (db.update(db.sideTripRuns)..where((x) => x.id.equals(r.id))).write(replayed);
      }
    }
  }
}
