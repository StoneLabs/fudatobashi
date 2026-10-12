import 'package:drift/drift.dart';

/// Schema 1 → 2: the side trips' games (寄り道) and their answers.
Future<void> v1ToV2(Migrator m) async {
  for (final sql in const [
    'CREATE TABLE "side_trip_runs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "game" TEXT NOT NULL, '
        '"started_at" INTEGER NOT NULL, "ranked" INTEGER NOT NULL CHECK ("ranked" IN (0, 1)), "level" INTEGER NULL, '
        '"card_count" INTEGER NOT NULL, "score" INTEGER NOT NULL, "max_score" INTEGER NOT NULL, '
        '"completed" INTEGER NOT NULL CHECK ("completed" IN (0, 1)), "rating" REAL NULL, "performance" REAL NULL, '
        '"meta" TEXT NOT NULL DEFAULT \'{}\')',
    'CREATE TABLE "side_trip_answers" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        '"run_id" INTEGER NOT NULL REFERENCES side_trip_runs (id), "seq" INTEGER NOT NULL, '
        '"poem_id" INTEGER NOT NULL, "wrong_taps" INTEGER NOT NULL, "response_us" INTEGER NULL, '
        '"at" INTEGER NOT NULL)',
    'CREATE INDEX side_trip_answers_run ON side_trip_answers (run_id)',
  ]) {
    await m.database.customStatement(sql);
  }
}
