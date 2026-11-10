import 'package:drift/drift.dart';

/// Schema 5 → 6: 一騎打ち's matches, each with its reads.
Future<void> v5ToV6(Migrator m) async {
  for (final sql in v6Tables) {
    await m.database.customStatement(sql);
  }
}

/// The tables version 6 added, as it created them.
const v6Tables = [
  'CREATE TABLE "ikkiuchi_matches" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"started_at" INTEGER NOT NULL, "ended_at" INTEGER NOT NULL, "day" INTEGER NOT NULL REFERENCES days (day), '
      '"ranked" INTEGER NOT NULL CHECK ("ranked" IN (0, 1)), "mode" TEXT NULL, "opponent" TEXT NOT NULL, '
      '"per_side" INTEGER NOT NULL, "rows" INTEGER NOT NULL, "memorise_ms" INTEGER NOT NULL, '
      '"memorised_ms" INTEGER NOT NULL, "opponent_rating" REAL NOT NULL, '
      '"completed" INTEGER NOT NULL CHECK ("completed" IN (0, 1)), "player_left" INTEGER NOT NULL, '
      '"opponent_left" INTEGER NOT NULL, "rating" REAL NULL, "xp" TEXT NOT NULL)',
  'CREATE TABLE "ikkiuchi_reads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"match_id" INTEGER NOT NULL REFERENCES ikkiuchi_matches (id), "seq" INTEGER NOT NULL, '
      '"poem_id" INTEGER NOT NULL, "card_side" TEXT NULL, "taker" TEXT NULL, '
      '"tied" INTEGER NOT NULL CHECK ("tied" IN (0, 1)), "player_faults" INTEGER NOT NULL, '
      '"opponent_faults" INTEGER NOT NULL, "player_take_us" INTEGER NULL, "opponent_take_us" INTEGER NULL, '
      '"field" TEXT NOT NULL, "faults" TEXT NOT NULL, "sends" TEXT NOT NULL)',
  'CREATE INDEX ikkiuchi_reads_match ON ikkiuchi_reads (match_id)',
];
