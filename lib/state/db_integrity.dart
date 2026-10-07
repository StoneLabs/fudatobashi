import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../db/database.dart';
import '../domain/card_stats.dart';
import '../domain/play_session.dart';
import '../domain/rating.dart';
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
  /// 0 µs, with run totals negative or too short.
  ///
  /// * A run whose total is no measurement, or whose every swipe has an
  ///   impossible time, loses its total (so it is no personal best) and its
  ///   rating point; the rating is replayed from the points after it.
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
        SELECT 1 FROM sessions s
        WHERE (s.total_us <= 0
               OR (EXISTS (SELECT 1 FROM attempts a WHERE a.session_id = s.id)
                   AND NOT EXISTS (SELECT 1 FROM attempts a WHERE a.session_id = s.id AND a.response_us > 0)))
          AND (s.total_us IS NOT NULL OR EXISTS (SELECT 1 FROM rating_points r WHERE r.session_id = s.id))
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
      timed[a.sessionId] = (timed[a.sessionId] ?? false) || Attempt.isValidTime(a.responseUs);
    }
    final bad = {
      for (final s in await db.select(db.sessions).get())
        if ((s.totalUs != null && s.totalUs! <= 0) || timed[s.id] == false) s.id,
    };
    if (bad.isEmpty) return;
    await (db.update(db.sessions)..where((s) => s.id.isIn(bad))).write(const SessionsCompanion(totalUs: Value(null)));

    final points = await (db.select(db.ratingPoints)
          ..orderBy([(r) => OrderingTerm.asc(r.at), (r) => OrderingTerm.asc(r.id)]))
        .get();
    final first = points.indexWhere((p) => bad.contains(p.sessionId));
    if (first < 0) return;
    var rating = first == 0 ? null : points[first - 1].rating;
    var kept = first;
    for (final p in points.skip(first)) {
      if (bad.contains(p.sessionId)) {
        await (db.delete(db.ratingPoints)..where((r) => r.id.equals(p.id))).go();
        continue;
      }
      rating = Rating.update(rating, p.performance, kept++);
      await (db.update(db.ratingPoints)..where((r) => r.id.equals(p.id)))
          .write(RatingPointsCompanion(rating: Value(rating)));
    }
    if (rating == null) {
      await (db.delete(db.keyValues)..where((k) => k.key.equals('rating'))).go();
    } else {
      await db.into(db.keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: 'rating', value: '$rating'));
    }
  }

  static Future<void> _grades(AppDatabase db, List<AttemptRow> attempts, fsrs.Scheduler scheduler) async {
    final taken = {
      for (final a in attempts)
        if (a.grade != null && a.grade != fsrs.Rating.again.value && !Attempt.isValidTime(a.responseUs)) a.id,
    };
    if (taken.isEmpty) return;
    await (db.update(db.attempts)..where((a) => a.id.isIn(taken))).write(const AttemptsCompanion(grade: Value(null)));

    final cards = {
      for (final a in attempts)
        if (taken.contains(a.id)) ItemKey(a.poemId, a.inverted),
    };
    for (final key in cards) {
      final item = ItemState(key);
      for (final a in attempts) {
        if (a.grade == null || taken.contains(a.id) || ItemKey(a.poemId, a.inverted) != key) continue;
        final grade = fsrs.Rating.values.firstWhere((r) => r.value == a.grade);
        item.card = scheduler.reviewCard(item.card, grade, reviewDateTime: a.at.toUtc()).card;
      }
      await (db.update(db.items)
            ..where((i) => i.poemId.equals(key.poemId) & i.inverted.equals(key.inverted)))
          .write(ItemsCompanion(fsrs: Value(item.reviewed ? item.fsrsJson : null)));
    }
  }
}
