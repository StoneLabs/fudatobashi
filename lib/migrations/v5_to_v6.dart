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
      '"started_at" INTEGER NOT NULL, "ended_at" INTEGER NOT NULL, "per_side" INTEGER NOT NULL, '
      '"memorise_ms" INTEGER NOT NULL, "tobi_rating" REAL NOT NULL, "result" TEXT NOT NULL, '
      '"player_left" INTEGER NOT NULL, "tobi_left" INTEGER NOT NULL, "player_faults" INTEGER NOT NULL, '
      '"tobi_faults" INTEGER NOT NULL)',
  'CREATE TABLE "ikkiuchi_reads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"match_id" INTEGER NOT NULL REFERENCES ikkiuchi_matches (id), "seq" INTEGER NOT NULL, '
      '"poem_id" INTEGER NOT NULL, "karafuda" INTEGER NOT NULL CHECK ("karafuda" IN (0, 1)), "taker" TEXT NULL, '
      '"tied" INTEGER NOT NULL CHECK ("tied" IN (0, 1)), "player_faults" INTEGER NOT NULL, '
      '"tobi_faults" INTEGER NOT NULL, "player_us" INTEGER NULL, "tobi_us" INTEGER NULL)',
  'CREATE INDEX ikkiuchi_reads_match ON ikkiuchi_reads (match_id)',
];
