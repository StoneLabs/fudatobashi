import 'package:drift/drift.dart';

/// Schema 1 → 2: the side trips' games (寄り道) and their answers, and the
/// practice days with journey mode's daily sets.
Future<void> v1ToV2(Migrator m) async {
  for (final sql in v2Tables) {
    await m.database.customStatement(sql);
  }
}

/// The tables version 2 added, as it created them.
const v2Tables = [
  'CREATE TABLE "side_trip_runs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "game" TEXT NOT NULL, '
      '"started_at" INTEGER NOT NULL, "ranked" INTEGER NOT NULL CHECK ("ranked" IN (0, 1)), "level" INTEGER NULL, '
      '"card_count" INTEGER NOT NULL, "score" INTEGER NULL, "max_score" INTEGER NULL, '
      '"completed" INTEGER NOT NULL CHECK ("completed" IN (0, 1)), "rating" REAL NULL, "performance" REAL NULL, '
      '"meta" TEXT NOT NULL DEFAULT \'{}\')',
  'CREATE TABLE "side_trip_answers" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"run_id" INTEGER NOT NULL REFERENCES side_trip_runs (id), "seq" INTEGER NOT NULL, '
      '"poem_id" INTEGER NOT NULL, "wrong_taps" INTEGER NOT NULL, "response_us" INTEGER NULL, '
      '"at" INTEGER NOT NULL, "first_tap" INTEGER NULL, "first_tap_us" INTEGER NULL, "second_tap" INTEGER NULL)',
  'CREATE INDEX side_trip_answers_run ON side_trip_answers (run_id)',
  'CREATE TABLE "days" ("number" INTEGER NOT NULL, "starts_at" INTEGER NOT NULL, "ends_at" INTEGER NOT NULL, '
      '"built_at" INTEGER NULL, "miss_guess" INTEGER NOT NULL DEFAULT 0, '
      '"new_paused" INTEGER NOT NULL DEFAULT 0 CHECK ("new_paused" IN (0, 1)), '
      '"pause_asked" INTEGER NOT NULL DEFAULT 0 CHECK ("pause_asked" IN (0, 1)), "done_at" INTEGER NULL, '
      'PRIMARY KEY ("number"))',
  'CREATE TABLE "day_cards" ("day" INTEGER NOT NULL, "poem_id" INTEGER NOT NULL, '
      '"inverted" INTEGER NOT NULL CHECK ("inverted" IN (0, 1)), "kind" INTEGER NOT NULL, '
      'PRIMARY KEY ("day", "poem_id", "inverted"))',
];
