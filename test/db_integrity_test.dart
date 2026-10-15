import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/db/fsrs_rows.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_rating.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/step_plan.dart';
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

  /// A run on day [d] with its [swipes], ranked when it has a [rating].
  Future<int> run(AppDatabase db, int d, int? clockUs, List<Swipe> swipes,
      {double? rating, double? performance}) async {
    final id = await db.into(db.runs).insert(RunsCompanion.insert(
          mode: rating == null ? PlayMode.training : PlayMode.ranked,
          startedAt: day(d),
          endedAt: day(d, 59),
          day: 20260900 + d,
          allKnown: rating != null,
          goalMs: 3000,
          setIds: Value(jsonEncode(rating == null ? const [] : const ['all'])),
          planned: swipes.length,
          clockUs: Value(clockUs),
          completed: true,
          scoredMs: Value(rating == null ? null : 0),
          rating: Value(rating),
          performance: Value(performance),
        ));
    for (final (i, (poemId, us, dontKnow, grade)) in swipes.indexed) {
      await db.into(db.attempts).insert(AttemptsCompanion.insert(
            runId: id,
            seq: i,
            poemId: poemId,
            inverted: false,
            responseUs: us,
            outcome: dontKnow ? Outcome.dontKnow : Outcome.known,
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

  Future<void> item(AppDatabase db, int poemId, fsrs.Card card) =>
      db.into(db.items).insert((ItemState(ItemKey(poemId, false), unlocked: true, card: card)).row);

  /// Every table the repair may write, as text.
  Future<String> dump(AppDatabase db) async => [
        await db.select(db.runs).get(),
        await db.select(db.attempts).get(),
        await db.select(db.items).get(),
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

  test('runs with impossible times lose their clocks, ratings and FSRS grades; valid data stays', () async {
    final db = AppDatabase(NativeDatabase.memory());
    const easy = fsrs.Rating.easy, good = fsrs.Rating.good, again = fsrs.Rating.again;

    // A: a good run. B: negative clock, every time 0 µs (old iOS). D: a
    // positive but too short clock, every time 0 µs. E: a good run with one
    // 0 µs answer among valid ones (a touch timestamped before the reveal).
    // Each is ranked, the rating moved toward its performance.
    final ratings = <double>[];
    double rate(double performance) {
      ratings.add(Rating.update(ratings.lastOrNull, performance, ratings.length));
      return ratings.last;
    }

    final a = await run(db, 1, 30000000, [(1, 900000, false, easy), (2, 1200000, false, good), (3, 900000, false, easy)],
        rating: rate(300), performance: 300);
    final b = await run(db, 3, -126534000000, [(1, 0, false, easy), (4, 0, false, easy), (2, 0, true, again)],
        rating: rate(250), performance: 250);
    final d = await run(db, 4, 2000000, [(3, 0, false, null)], rating: rate(250), performance: 250);
    final e = await run(db, 5, 40000000, [(5, 1100000, false, good), (6, 0, false, easy)],
        rating: rate(320), performance: 320);
    await item(db, 1, replay(1, [(easy, 1, 0), (easy, 3, 0)]));
    await item(db, 2, replay(2, [(good, 1, 1), (again, 3, 2)]));
    await item(db, 3, replay(3, [(easy, 1, 2)]));
    await item(db, 4, replay(4, [(easy, 3, 1)]));
    await item(db, 5, replay(5, [(good, 5, 0)]));
    await item(db, 6, replay(6, [(easy, 5, 1)]));

    final runsBefore = {for (final r in await db.select(db.runs).get()) r.id: r};
    final attemptsBefore = await db.select(db.attempts).get();
    final itemsBefore = {for (final i in await db.select(db.items).get()) i.poemId: i};

    final p = await Progress.open(db);

    final runs = {for (final r in await db.select(db.runs).get()) r.id: r};
    expect([for (final id in [a, b, d, e]) runs[id]!.clockUs], [30000000, null, null, 40000000]);
    expect(runs[a], runsBefore[a]);
    expect(runs.values.every((r) => r.completed), isTrue, reason: 'still played to the end');
    expect(p.bestFor(const PlayConfig(mode: PlayMode.ranked)), const Duration(seconds: 30));

    final attempts = await db.select(db.attempts).get();
    expect([for (final x in attempts) x.responseUs], [for (final x in attemptsBefore) x.responseUs]);
    expect([for (final x in attempts) x.grade], [4, 3, 4, null, null, 1, null, 3, null],
        reason: 'only correct answers with impossible times lose their grade; a miss is still a miss');

    final items = {for (final i in await db.select(db.items).get()) i.poemId: i};
    for (final id in [2, 3, 5]) {
      expect(items[id], itemsBefore[id], reason: 'card $id had no impossible grade');
    }
    expect(items[4]!.fsrsState, isNull, reason: 'its only review was impossible');
    expect(items[6]!.fsrsState, isNull);
    expect(items[1]!.unlocked, isTrue);
    final repaired = ItemStateRow.of(items[1]!).card;
    final expected = replay(1, [(easy, 1, 0)]);
    expect(
      [repaired.state, repaired.step, repaired.stability, repaired.difficulty, repaired.lastReview],
      [expected.state, expected.step, expected.stability, expected.difficulty, expected.lastReview],
    );
    expect(p.trainer.items[ItemKey(1, false)]!.card.stability, expected.stability, reason: 'loaded repaired');
    final ofCard1 = [for (final x in attempts) if (x.poemId == 1) x];
    expect([for (final x in ofCard1) x.fsrsStability], [expected.stability, null],
        reason: 'the review left keeps its state after it; the impossible one has none');
    expect(ofCard1.first.fsrsRecall, isNull, reason: 'the first review has no recall chance before it');

    expect([for (final id in [a, b, d, e]) runs[id]!.rating != null], [true, false, false, true]);
    expect(runs[a]!.rating, ratings.first, reason: 'ratings before the first bad run are untouched');
    expect(runs[e]!.rating, Rating.update(ratings.first, 320, 1));
    expect(p.rating, runs[e]!.rating);
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
    await run(db, 1, 30000000, [(1, 900000, false, good), (2, 1200000, true, fsrs.Rating.again)],
        rating: 300, performance: 300);
    await item(db, 1, replay(1, [(good, 1, 0)]));
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
    expect((await db.select(db.runs).get()).singleWhere((r) => r.id == bad).clockUs, isNull);
    await db.close();
  });

  group('side trips', () {
    Future<int> trip(AppDatabase db, int d, {bool ranked = true, double? performance, double? rating}) =>
        db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
              game: SideTrip.ankiren,
              startedAt: day(d),
              endedAt: day(d, 59),
              day: 20260900 + d,
              ranked: ranked,
              level: const Value(0),
              score: const Value(900),
              maxScore: const Value(1200),
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

  test('cards of a missing day are deleted; a day with its cards stays', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.into(db.days).insert(DaysCompanion.insert(day: const Value(20261014), startsAt: day(1), endsAt: day(2)));
    for (final d in [20261014, 20261013]) {
      await db.into(db.dayCards).insert(DayCardsCompanion.insert(day: d, poemId: 1, inverted: false, kind: StepKind.review));
    }
    await DbIntegrity.run(db);
    expect([for (final c in await db.select(db.dayCards).get()) c.day], [20261014]);
    expect(await writesDuring(db, () => DbIntegrity.run(db)), isEmpty);
    await db.close();
  });
}
