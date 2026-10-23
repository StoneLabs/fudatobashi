import 'package:drift/drift.dart';

import 'notices.dart';

/// The notice that tells a player with 暗記練 games that the rank was reset.
const ankirenReworkNotice = 'ankirenRework';

/// Schema 3 → 4: ranked 暗記練 now has one fixed setup and no level, so every
/// game stored as ranked at a level becomes a free-play game at that level,
/// with its rating and performance cleared. The rating and placement are
/// worked out from the ranked games, so nothing else holds them. Only ranked
/// games have points, so every other game loses its score. A player with
/// any 暗記練 game is told about the reset.
Future<void> v3ToV4(Migrator m) async {
  final db = m.database;
  final played = await db.customSelect('SELECT EXISTS (SELECT 1 FROM side_trip_runs) AS found').getSingle();
  await db.customStatement(
      "UPDATE side_trip_runs SET ranked = 0, rating = NULL, performance = NULL "
      "WHERE game = 'ankiren' AND ranked = 1 AND level IS NOT NULL");
  await db.customStatement(
      "UPDATE side_trip_runs SET score = NULL, max_score = NULL WHERE game = 'ankiren' AND ranked = 0");
  if (played.read<bool>('found')) await queueNotice(db, ankirenReworkNotice);
}
