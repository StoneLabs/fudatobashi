import 'package:drift/drift.dart';

/// Schema 4 → 5: 定位置's games keep where each card was placed from the
/// stack, and how long that took.
Future<void> v4ToV5(Migrator m) async {
  for (final sql in v5Tables) {
    await m.database.customStatement(sql);
  }
}

/// The table version 5 added, as it created it.
const v5Tables = [
  'CREATE TABLE "teiichi_placings" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"run_id" INTEGER NOT NULL REFERENCES side_trip_runs (id), "seq" INTEGER NOT NULL, '
      '"poem_id" INTEGER NOT NULL, "placing_us" INTEGER NOT NULL)',
  'CREATE INDEX teiichi_placings_run ON teiichi_placings (run_id)',
];
