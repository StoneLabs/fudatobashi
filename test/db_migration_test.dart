import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/migrations/migrations.dart';

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

/// A version 1 install with one run in it: a session, its attempts, an item,
/// a rating point and a stored value.
const _v1Rows = [
  "INSERT INTO sessions VALUES (1, 1790000000, 0, '[]', 0, 2, 30000000, 1, '{\"maskLevel\":0}')",
  'INSERT INTO attempts VALUES (1, 1, 0, 12, 0, 0, 900000, 0, 0, 0, 0, 2, 1790000001, 4)',
  'INSERT INTO attempts VALUES (2, 1, 1, 34, 1, 0, 1200000, 1, 0, 0, 0, 2, 1790000002, 1)',
  "INSERT INTO items VALUES (12, 0, 1, 1789990000, '{\"state\":2}', 0)",
  'INSERT INTO rating_points VALUES (1, 1790000003, 412.5, 412.5, 120000, 1)',
  "INSERT INTO key_values VALUES ('rating', '412.5')",
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  AppDatabase v1Install() => AppDatabase(NativeDatabase.memory(setup: (raw) {
        for (final sql in [..._v1Schema, ..._v1Rows]) {
          raw.execute(sql);
        }
        raw.userVersion = 1;
      }));

  Future<Map<String, String>> schemaOf(AppDatabase db) async => {
        for (final row in await db.customSelect('SELECT name, sql FROM sqlite_master WHERE sql IS NOT NULL').get())
          row.read<String>('name'): row.read<String>('sql'),
      };

  test('a version 1 database keeps every row and gains the side trips\' tables', () async {
    final db = v1Install();

    final sessions = await db.select(db.sessions).get();
    expect([for (final s in sessions) (s.id, s.cardCount, s.totalUs, s.completed, s.meta)],
        [(1, 2, 30000000, true, '{"maskLevel":0}')]);
    final attempts = await db.select(db.attempts).get();
    expect([for (final a in attempts) (a.sessionId, a.poemId, a.inverted, a.responseUs, a.grade)],
        [(1, 12, false, 900000, 4), (1, 34, true, 1200000, 1)]);
    final items = await db.select(db.items).get();
    expect([for (final i in items) (i.poemId, i.unlocked, i.fsrs)], [(12, true, '{"state":2}')]);
    final points = await db.select(db.ratingPoints).get();
    expect([for (final r in points) (r.rating, r.sessionId)], [(412.5, 1)]);
    final values = await db.select(db.keyValues).get();
    expect([for (final k in values) (k.key, k.value)], [('rating', '412.5')]);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 2);
    expect(await db.select(db.sideTripRuns).get(), isEmpty);
    expect(await db.select(db.sideTripAnswers).get(), isEmpty);

    final fresh = AppDatabase(NativeDatabase.memory());
    expect(await schemaOf(db), await schemaOf(fresh), reason: 'an upgraded install has a new install\'s schema');
    await fresh.close();

    final run = await db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
        game: 'ankiren', startedAt: DateTime(2026, 10, 12), ranked: true, cardCount: 8, score: 900, maxScore: 1200,
        completed: true));
    await db.into(db.sideTripAnswers).insert(SideTripAnswersCompanion.insert(
        runId: run, seq: 0, poemId: 12, wrongTaps: 1, at: DateTime(2026, 10, 12)));
    expect((await db.select(db.sideTripAnswers).getSingle()).responseUs, isNull);
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
      await expectLater(db.select(db.sessions).get(), throwsA(isA<SqliteException>()));
      await db.close();
    }
    expect(seen.version, 1);
    expect(seen.tables, isNot(contains('side_trip_runs')), reason: 'the failed upgrade was rolled back');
    expect(seen.tables, containsAll(['sessions', 'attempts', 'items', 'rating_points', 'key_values']));
  });
}
