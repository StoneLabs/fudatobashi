import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_rating.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/db_integrity.dart';

import 'test_ankiren.dart';

/// One swipe as an older version stored it.
typedef Swipe = (int poemId, int us, bool dontKnow, fsrs.Rating? grade);

/// The integrity check on start, here its repair of runs recorded while touch
/// and frame times were on different clocks (iOS and macOS): every time stored
/// as 0 µs, totals negative or too short.
void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final scheduler = Trainer.schedulerFor(const TrainerConfig());
  DateTime day(int d, [int second = 0]) => DateTime(2026, 9, d, 10, 0, second);

  Future<int> run(AppDatabase db, int d, int? totalUs, List<Swipe> swipes) async {
    final id = await db.into(db.sessions).insert(SessionsCompanion.insert(
          startedAt: day(d),
          mode: PlayMode.training.index,
          orientation: 0,
          cardCount: swipes.length,
          totalUs: Value(totalUs),
          completed: true,
        ));
    for (final (i, (poemId, us, dontKnow, grade)) in swipes.indexed) {
      await db.into(db.attempts).insert(AttemptsCompanion.insert(
            sessionId: id,
            seq: i,
            poemId: poemId,
            inverted: false,
            responseUs: us,
            outcome: (dontKnow ? Outcome.dontKnow : Outcome.known).index,
            deckSize: swipes.length,
            at: day(d, i),
            grade: Value(grade?.value),
          ));
    }
    return id;
  }

  /// A card's FSRS state after [reviews] (grade, day, second), as `Trainer.review` left it.
  fsrs.Card replay(int poemId, List<(fsrs.Rating, int, int)> reviews) {
    var card = ItemState(ItemKey(poemId, false)).card;
    for (final (grade, d, second) in reviews) {
      card = scheduler.reviewCard(card, grade, reviewDateTime: day(d, second).toUtc()).card;
    }
    return card;
  }

  Future<void> item(AppDatabase db, int poemId, fsrs.Card card) {
    final state = ItemState(ItemKey(poemId, false))..card = card;
    return db.into(db.items).insert(ItemsCompanion.insert(
          poemId: poemId,
          inverted: false,
          unlocked: const Value(true),
          fsrs: Value(state.fsrsJson),
        ));
  }

  /// Every table the repair may write, as text.
  Future<String> dump(AppDatabase db) async => [
        await db.select(db.sessions).get(),
        await db.select(db.attempts).get(),
        await db.select(db.items).get(),
        await db.select(db.ratingPoints).get(),
        await (db.select(db.keyValues)..where((k) => k.key.equals('rating'))).get(),
      ].join('\n');

  /// The tables written to while [action] runs.
  Future<Set<String>> writesDuring(AppDatabase db, Future<void> Function() action) async {
    final written = <String>{};
    final sub = db.tableUpdates().listen((u) => written.addAll(u.map((t) => t.table)));
    await action();
    await pumpEventQueue();
    await sub.cancel();
    return written;
  }

  test('runs with impossible times lose their totals, rating points and FSRS grades; valid data stays', () async {
    final db = AppDatabase(NativeDatabase.memory());
    const easy = fsrs.Rating.easy, good = fsrs.Rating.good, again = fsrs.Rating.again;

    // A: a good run. B: negative total, every time 0 µs (old iOS). D: a
    // positive but too short total, every time 0 µs. E: a good run with one
    // 0 µs answer among valid ones (a touch timestamped before the reveal).
    final a = await run(db, 1, 30000000, [(1, 900000, false, easy), (2, 1200000, false, good), (3, 900000, false, easy)]);
    final b = await run(db, 3, -126534000000, [(1, 0, false, easy), (4, 0, false, easy), (2, 0, true, again)]);
    final d = await run(db, 4, 2000000, [(3, 0, false, null)]);
    final e = await run(db, 5, 40000000, [(5, 1100000, false, good), (6, 0, false, easy)]);
    await item(db, 1, replay(1, [(easy, 1, 0), (easy, 3, 0)]));
    await item(db, 2, replay(2, [(good, 1, 1), (again, 3, 2)]));
    await item(db, 3, replay(3, [(easy, 1, 2)]));
    await item(db, 4, replay(4, [(easy, 3, 1)]));
    await item(db, 5, replay(5, [(good, 5, 0)]));
    await item(db, 6, replay(6, [(easy, 5, 1)]));

    final ratings = <double>[];
    for (final (session, perf, d) in [(a, 300.0, 1), (b, 250.0, 3), (d, 250.0, 4), (e, 320.0, 5)]) {
      ratings.add(Rating.update(ratings.lastOrNull, perf, ratings.length));
      await db.into(db.ratingPoints).insert(RatingPointsCompanion.insert(
          at: day(d, 59), rating: ratings.last, performance: perf, projectedMs: 0, sessionId: Value(session)));
    }
    await db.into(db.keyValues).insert(KeyValuesCompanion.insert(key: 'rating', value: '${ratings.last}'));

    final sessionsBefore = await db.select(db.sessions).get();
    final attemptsBefore = await db.select(db.attempts).get();
    final itemsBefore = {for (final i in await db.select(db.items).get()) i.poemId: i};

    final p = await Progress.open(db);

    final sessions = {for (final s in await db.select(db.sessions).get()) s.id: s};
    expect([for (final id in [a, b, d, e]) sessions[id]!.totalUs], [30000000, null, null, 40000000]);
    expect([sessions[a], sessions[e]], [for (final s in sessionsBefore) if (s.id == a || s.id == e) s]);
    expect(sessions.values.every((s) => s.completed), isTrue, reason: 'still played to the end');
    expect(p.bestFor(const PlayConfig(mode: PlayMode.training, setIds: [])), const Duration(seconds: 30));

    final attempts = await db.select(db.attempts).get();
    expect([for (final x in attempts) x.responseUs], [for (final x in attemptsBefore) x.responseUs]);
    expect([for (final x in attempts) x.grade], [4, 3, 4, null, null, 1, null, 3, null],
        reason: 'only correct answers with impossible times lose their grade; a miss is still a miss');

    final items = {for (final i in await db.select(db.items).get()) i.poemId: i};
    for (final id in [2, 3, 5]) {
      expect(items[id], itemsBefore[id], reason: 'card $id had no impossible grade');
    }
    expect(items[4]!.fsrs, isNull, reason: 'its only review was impossible');
    expect(items[6]!.fsrs, isNull);
    final repaired = ItemState.cardFromJson(items[1]!.fsrs!);
    final expected = replay(1, [(easy, 1, 0)]);
    expect(
      [repaired.state, repaired.step, repaired.stability, repaired.difficulty, repaired.lastReview],
      [expected.state, expected.step, expected.stability, expected.difficulty, expected.lastReview],
    );
    expect(p.trainer.items[ItemKey(1, false)]!.card.stability, expected.stability, reason: 'loaded repaired');

    final points = await db.select(db.ratingPoints).get();
    expect([for (final x in points) x.sessionId], [a, e]);
    expect(points.first.rating, ratings.first, reason: 'points before the first bad run are untouched');
    expect(points.last.rating, Rating.update(ratings.first, 320, 1));
    expect(p.rating, points.last.rating);
    expect(p.stats(const ItemKey(6, false)).timed, isEmpty);

    // A second run finds nothing and writes nothing.
    final repairedState = await dump(db);
    final writes = await writesDuring(db, () => DbIntegrity.run(db));
    expect(writes, isEmpty);
    expect(await dump(db), repairedState);
    await db.close();
  });

  test('an install without impossible times is left exactly as it was', () async {
    final db = AppDatabase(NativeDatabase.memory());
    const good = fsrs.Rating.good;
    final a = await run(db, 1, 30000000, [(1, 900000, false, good), (2, 1200000, true, fsrs.Rating.again)]);
    await item(db, 1, replay(1, [(good, 1, 0)]));
    await db.into(db.ratingPoints).insert(RatingPointsCompanion.insert(
        at: day(2), rating: 300, performance: 300, projectedMs: 0, sessionId: Value(a)));
    final before = await dump(db);
    expect(await writesDuring(db, () => DbIntegrity.run(db)), isEmpty);
    await Progress.open(db);
    expect(await dump(db), before);
    await db.close();
  });

  test('an empty database passes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await writesDuring(db, () => DbIntegrity.run(db)), isEmpty);
    await db.close();
  });

  test('a check that throws is skipped and the others still run', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final bad = await run(db, 1, -5, [(1, 0, false, null)]);
    final checks = DbIntegrity.checks.toList();
    DbIntegrity.checks
      ..clear()
      ..add(IntegrityCheck('broken', (_) async => throw StateError('boom'), (_) async {}))
      ..addAll(checks);
    addTearDown(() => DbIntegrity.checks
      ..clear()
      ..addAll(checks));
    await DbIntegrity.run(db);
    expect((await db.select(db.sessions).get()).singleWhere((s) => s.id == bad).totalUs, isNull);
    await db.close();
  });

  group('side trips', () {
    Future<int> trip(AppDatabase db, int d, {bool ranked = true, double? performance, double? rating}) =>
        db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
              game: SideTrip.ankiren.name,
              startedAt: day(d),
              ranked: ranked,
              level: const Value(0),
              cardCount: 8,
              score: 900,
              maxScore: 1200,
              completed: true,
              rating: Value(rating),
              performance: Value(performance),
            ));

    Future<void> answer(AppDatabase db, int runId) => db.into(db.sideTripAnswers).insert(
        SideTripAnswersCompanion.insert(runId: runId, seq: 0, poemId: 1, wrongTaps: 0, responseUs: const Value(900000), at: day(1)));

    Future<String> dumpTrips(AppDatabase db) async =>
        [await db.select(db.sideTripRuns).get(), await db.select(db.sideTripAnswers).get()].join('\n');

    test('answers of a missing game are deleted; ratings that are no number are replayed', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final placed = AnkirenRating.update(AnkirenRating.start, 1300, 0);
      final a = await trip(db, 1, performance: 1300, rating: placed);
      final b = await trip(db, 2, performance: double.infinity, rating: double.infinity);
      final c = await trip(db, 3, ranked: false);
      final d = await trip(db, 4, performance: 1500, rating: double.nan);
      final e = await trip(db, 5, performance: 1200, rating: 9999);
      await answer(db, a);
      await answer(db, 99);
      expect((await db.select(db.sideTripRuns).get()).singleWhere((r) => r.id == d).rating, isNull,
          reason: 'SQLite stores NaN as null');

      final p = await Progress.open(db);

      expect([for (final x in await db.select(db.sideTripAnswers).get()) x.runId], [a]);
      final runs = {for (final r in await db.select(db.sideTripRuns).get()) r.id: r};
      expect([runs[a]!.performance, runs[a]!.rating], [1300, placed], reason: 'games before the first bad one stay');
      expect([runs[b]!.performance, runs[b]!.rating], [null, null], reason: 'no performance: dropped from the rating');
      expect([runs[c]!.performance, runs[c]!.rating], [null, null]);
      final rd = AnkirenRating.update(placed, 1500, 1);
      expect([runs[d]!.performance, runs[d]!.rating], [1500, rd]);
      expect(runs[e]!.rating, AnkirenRating.update(rd, 1200, 2));
      expect(p.sideTrips.ratingOf(SideTrip.ankiren), runs[e]!.rating);
      expect(p.sideTrips.rankedGames(SideTrip.ankiren), 3);

      final repaired = await dumpTrips(db);
      expect(await writesDuring(db, () => DbIntegrity.run(db)), isEmpty);
      expect(await dumpTrips(db), repaired);
      await db.close();
    });

    test('recorded games, ranked and free, are left exactly as they were', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true)), startedAt: day(1));
      await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(1), endAfter: 2), startedAt: day(2));
      final before = await dumpTrips(db);
      expect(await writesDuring(db, () => DbIntegrity.run(db)), isEmpty);
      expect(await dumpTrips(db), before);
      await db.close();
    });
  });
}
