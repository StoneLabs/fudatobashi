import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/day_window.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/step_plan.dart';
import 'package:fudatobashi/migrations/migrations.dart';
import 'package:fudatobashi/migrations/v1_to_v2.dart';
import 'package:fudatobashi/state/play_config.dart';

/// The schema of version 1 (before the side trips' tables), as that
/// version's `AppDatabase` created it.
const _v1Schema = [
  'CREATE TABLE "sessions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "started_at" INTEGER NOT NULL, '
      '"mode" INTEGER NOT NULL, "set_ids" TEXT NOT NULL DEFAULT \'[]\', "orientation" INTEGER NOT NULL, '
      '"card_count" INTEGER NOT NULL, "total_us" INTEGER NULL, '
      '"completed" INTEGER NOT NULL CHECK ("completed" IN (0, 1)), "meta" TEXT NOT NULL DEFAULT \'{}\')',
  'CREATE TABLE "attempts" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"session_id" INTEGER NOT NULL REFERENCES sessions (id), "seq" INTEGER NOT NULL, "poem_id" INTEGER NOT NULL, '
      '"inverted" INTEGER NOT NULL CHECK ("inverted" IN (0, 1)), "mask_level" INTEGER NOT NULL DEFAULT 0, '
      '"response_us" INTEGER NOT NULL, "outcome" INTEGER NOT NULL, '
      '"wrong" INTEGER NOT NULL DEFAULT 0 CHECK ("wrong" IN (0, 1)), '
      '"tainted" INTEGER NOT NULL DEFAULT 0 CHECK ("tainted" IN (0, 1)), '
      '"undone" INTEGER NOT NULL DEFAULT 0 CHECK ("undone" IN (0, 1)), "deck_size" INTEGER NOT NULL, '
      '"at" INTEGER NOT NULL, "grade" INTEGER NULL)',
  'CREATE TABLE "items" ("poem_id" INTEGER NOT NULL, "inverted" INTEGER NOT NULL CHECK ("inverted" IN (0, 1)), '
      '"unlocked" INTEGER NOT NULL DEFAULT 0 CHECK ("unlocked" IN (0, 1)), "unlocked_at" INTEGER NULL, '
      '"fsrs" TEXT NULL, "mask_level" INTEGER NOT NULL DEFAULT 0, PRIMARY KEY ("poem_id", "inverted"))',
  'CREATE TABLE "rating_points" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "at" INTEGER NOT NULL, '
      '"rating" REAL NOT NULL, "performance" REAL NOT NULL, "projected_ms" INTEGER NOT NULL, '
      '"session_id" INTEGER NULL)',
  'CREATE TABLE "key_values" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"))',
  'CREATE INDEX attempts_poem ON attempts (poem_id, inverted)',
  'CREATE INDEX attempts_session ON attempts (session_id)',
];

/// A version 1 install: a finished training run with its attempts and an
/// island it completed, a free run ended early, a reviewed item, the old
/// rating and stored values.
const _v1Rows = [
  "INSERT INTO sessions VALUES (1, 1790000000, 2, '[]', 0, 2, 30000000, 1, "
      "'{\"maskLevel\":0,\"goalMs\":2500.0,\"islandsCompleted\":[0]}')",
  "INSERT INTO sessions VALUES (2, 1790100000, 0, '[\"all\"]', 0, 5, NULL, 0, "
      "'{\"maskLevel\":1,\"goalMs\":3000.0,\"cardIds\":[5,6]}')",
  'INSERT INTO attempts VALUES (1, 1, 0, 12, 0, 0, 900000, 0, 0, 0, 0, 2, 1790000001, 4)',
  'INSERT INTO attempts VALUES (2, 1, 1, 34, 1, 0, 1200000, 1, 0, 0, 0, 2, 1790000002, 1)',
  "INSERT INTO items VALUES (12, 0, 1, 1789990000, '{\"cardId\":24,\"state\":2,\"step\":null,"
      "\"stability\":11.5,\"difficulty\":4.25,\"due\":\"2026-10-17T23:15:17.762Z\","
      "\"lastReview\":\"2026-10-05T23:15:17.762Z\"}', 0)",
  'INSERT INTO items VALUES (34, 1, 0, NULL, NULL, 0)',
  'INSERT INTO rating_points VALUES (1, 1790000003, 412.5, 412.5, 120000, 1)',
  "INSERT INTO key_values VALUES ('rating', '412.5')",
  "INSERT INTO key_values VALUES ('islandsCelebrated', '[0,1]')",
  "INSERT INTO key_values VALUES ('trainer', '{\"learningMode\":\"journey\",\"goalsMs\":[3000,2500]}')",
];

/// A version 2 install on top: days starting at 6, a practice day with its
/// set, a run on it, and two side-trip games, one ended early.
const _v2Rows = [
  "INSERT INTO key_values VALUES ('settings', '{\"dayStartHour\":6}')",
  'INSERT INTO days VALUES (20260930, 1790740800, 1790827200, 1790741000, 3, 0, 1, 1790750000)',
  'INSERT INTO day_cards VALUES (20260930, 12, 0, 0)',
  'INSERT INTO day_cards VALUES (20260930, 34, 1, 1)',
  "INSERT INTO sessions VALUES (3, 1790741100, 2, '[]', 0, 1, 5000000, 1, "
      "'{\"maskLevel\":0,\"goalMs\":3000.0,\"day\":20260930,\"dayDone\":true}')",
  'INSERT INTO attempts VALUES (3, 3, 0, 12, 0, 0, 800000, 0, 0, 0, 0, 1, 1790741105, 3)',
  "INSERT INTO side_trip_runs VALUES (1, 'ankiren', 1790200000, 1, 1, 2, 80, 100, 1, 520.0, 530.0, "
      "'{\"perSide\":4}')",
  'INSERT INTO side_trip_answers VALUES (1, 1, 0, 12, 0, 900000, 1790200010, 0, 900000, NULL)',
  'INSERT INTO side_trip_answers VALUES (2, 1, 1, 34, 2, NULL, 1790200030, 5, 400000, 1)',
  "INSERT INTO side_trip_runs VALUES (2, 'ankiren', 1790300000, 0, NULL, 1, NULL, NULL, 0, NULL, NULL, '{}')",
  'INSERT INTO side_trip_answers VALUES (3, 2, 0, 56, 0, NULL, 1790300020, NULL, NULL, NULL)',
];

DateTime _at(int seconds) => DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  AppDatabase install(int version, List<String> sql) => AppDatabase(NativeDatabase.memory(setup: (raw) {
        for (final s in sql) {
          raw.execute(s);
        }
        raw.userVersion = version;
      }));

  Future<Map<String, String>> schemaOf(AppDatabase db) async => {
        for (final row in await db.customSelect('SELECT name, sql FROM sqlite_master WHERE sql IS NOT NULL').get())
          row.read<String>('name'): row.read<String>('sql'),
      };

  test('a version 1 database keeps what version 3 can hold', () async {
    final db = install(1, [..._v1Schema, ..._v1Rows]);

    final runs = await db.select(db.runs).get();
    expect([
      for (final r in runs)
        (r.id, r.mode, r.endedAt, r.allKnown, r.cardIds, r.maskLevel, r.goalMs, r.planned, r.completed, r.clockUs)
    ], [
      (1, PlayMode.training, _at(1790000002), false, null, 0, 2500, 2, true, 30000000),
      (2, PlayMode.free, _at(1790100000), false, '[5,6]', 1, 3000, 5, false, null),
    ]);
    expect([for (final r in runs) (r.setIds, r.scoredMs, r.rating, r.graduated, r.dayDone)],
        [('[]', null, null, false, false), ('["all"]', null, null, false, false)]);
    final windows = [for (final r in runs) DayWindow.at(r.startedAt, TodaySetTuning.defaultDayStartHour)];
    expect([for (final r in runs) r.day], [for (final w in windows) w.number]);
    expect([for (final d in await db.select(db.days).get()) (d.day, d.startsAt, d.endsAt, d.builtAt)],
        unorderedEquals([for (final w in windows.toSet()) (w.number, w.start, w.end, null)]));

    final attempts = await db.select(db.attempts).get();
    expect([for (final a in attempts) (a.runId, a.poemId, a.inverted, a.outcome, a.responseUs, a.grade)],
        [(1, 12, false, Outcome.known, 900000, 4), (1, 34, true, Outcome.dontKnow, 1200000, 1)]);
    expect([for (final a in attempts) (a.revealAtUs, a.commitUs, a.fsrsRecall, a.fsrsState, a.fsrsDue)],
        everyElement((null, null, null, null, null)));

    final items = await db.select(db.items).get();
    expect([for (final i in items) (i.poemId, i.unlocked, i.unlockedAt, i.fsrsState, i.fsrsStep)],
        [(12, true, _at(1789990000), fsrs.State.review, null), (34, false, null, null, null)]);
    expect([items.first.fsrsStability, items.first.fsrsDifficulty, items.first.fsrsDue, items.first.fsrsLastReview],
        [11.5, 4.25, DateTime.utc(2026, 10, 17, 23, 15, 17).toLocal(), DateTime.utc(2026, 10, 5, 23, 15, 17).toLocal()]);

    expect([for (final c in await db.select(db.islandCompletions).get()) (c.island, c.at, c.runId)],
        [(0, _at(1790000002), 1), (1, _at(1790000002), null)]);
    expect([for (final kv in await db.select(db.keyValues).get()) kv.key], ['trainer'],
        reason: 'the old rating is dropped');

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);
    expect(await db.select(db.sideTripRuns).get(), isEmpty);
    expect(await db.select(db.sideTripAnswers).get(), isEmpty);

    final fresh = AppDatabase(NativeDatabase.memory());
    expect(await schemaOf(db), await schemaOf(fresh), reason: 'an upgraded install has a new install\'s schema');
    await fresh.close();

    final run = await db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
        game: SideTrip.ankiren,
        startedAt: DateTime(2026, 10, 12),
        endedAt: DateTime(2026, 10, 12),
        day: 20261012,
        ranked: false,
        completed: true));
    await db.into(db.sideTripAnswers).insert(SideTripAnswersCompanion.insert(
        runId: run, seq: 0, poemId: 12, wrongTaps: 1, at: DateTime(2026, 10, 12)));
    expect((await db.select(db.sideTripRuns).getSingle()).score, isNull, reason: 'a custom game has no score');
    final answer = await db.select(db.sideTripAnswers).getSingle();
    expect([answer.responseUs, answer.firstTap, answer.firstTapUs, answer.secondTap], [null, null, null, null]);
    await db.close();
  });

  test('a version 2 database keeps its days, side trips and day cards', () async {
    final db = install(2, [..._v1Schema, ...v2Tables, ..._v1Rows, ..._v2Rows]);
    const hour = 6;

    final run = await (db.select(db.runs)..where((r) => r.id.equals(3))).getSingle();
    expect((run.day, run.endedAt, run.dayDone, run.clockUs), (20260930, _at(1790741105), true, 5000000));
    final day = await (db.select(db.days)..where((d) => d.day.equals(20260930))).getSingle();
    expect((day.startsAt, day.builtAt, day.missGuess, day.pauseAsked, day.doneAt),
        (_at(1790740800), _at(1790741000), 3, true, _at(1790750000)));
    expect([for (final c in await db.select(db.dayCards).get()) (c.poemId, c.kind)],
        [(12, StepKind.review), (34, StepKind.newCard)]);

    final games = await db.select(db.sideTripRuns).get();
    expect([for (final g in games) (g.game, g.endedAt, g.day, g.ranked, g.level, g.score, g.completed, g.meta)], [
      (SideTrip.ankiren, _at(1790200030), DayWindow.at(_at(1790200000), hour).number, false, 1, null, true,
          '{"perSide":4}'),
      (SideTrip.ankiren, _at(1790300020), DayWindow.at(_at(1790300000), hour).number, false, null, null, false, '{}'),
    ]);
    final days = {for (final d in await db.select(db.days).get()) d.day: d};
    for (final g in games) {
      final w = DayWindow.at(g.startedAt, hour);
      expect((days[g.day]?.startsAt, days[g.day]?.endsAt), (w.start, w.end), reason: 'the day row of game ${g.id}');
    }
    expect([for (final g in games) (g.rating, g.performance)], [(null, null), (null, null)],
        reason: 'the ranked game with a level lost its rating');
    expect([for (final kv in await db.select(db.keyValues).get()) kv.key], containsAll(['migrationNotices']),
        reason: 'a player with 暗記練 games is told');
    expect([
      for (final a in await db.select(db.sideTripAnswers).get())
        (a.runId, a.gaveUp, a.responseUs, a.firstTap, a.firstTapCard, a.firstTapUs, a.secondTap, a.secondTapCard)
    ], [
      (1, false, 900000, TapProximity.card, null, 900000, null, null),
      (1, true, null, TapProximity.otherSide, null, 400000, TapProximity.neighbour, null),
      (2, false, null, null, null, null, null, null),
    ]);
    await db.close();
  });

  test('one upgrade step leads from every version to the next, up to the current one', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(migrationSteps, hasLength(db.schemaVersion - 1),
        reason: 'versions 1 to ${db.schemaVersion} need ${db.schemaVersion - 1} steps');
    await db.close();
  });

  test('an upgrade cut short leaves the database as it was', () async {
    final dir = await Directory.systemTemp.createTemp('fudatobashi_migration');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/app.sqlite');
    // A version 1 install with a stray side_trip_answers table: the upgrade
    // creates side_trip_runs, then fails on it.
    late ({int version, Set<String> tables}) seen;
    AppDatabase open() => AppDatabase(NativeDatabase(file, setup: (raw) {
          if (raw.userVersion == 0) {
            for (final sql in [..._v1Schema, ..._v1Rows, 'CREATE TABLE side_trip_answers (id INTEGER)']) {
              raw.execute(sql);
            }
            raw.userVersion = 1;
          }
          seen = (
            version: raw.userVersion,
            tables: {for (final row in raw.select("SELECT name FROM sqlite_master WHERE type = 'table'")) row['name'] as String},
          );
        }));

    for (var attempt = 0; attempt < 2; attempt++) {
      final db = open();
      await expectLater(db.select(db.runs).get(), throwsA(isA<SqliteException>()));
      await db.close();
    }
    expect(seen.version, 1);
    expect(seen.tables, isNot(contains('side_trip_runs')), reason: 'the failed upgrade was rolled back');
    expect(seen.tables, containsAll(['sessions', 'attempts', 'items', 'rating_points', 'key_values']));
  });
}
