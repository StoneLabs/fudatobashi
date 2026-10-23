import 'dart:convert';

import 'package:drift/drift.dart';

/// The key value that holds the ids of the notices an upgrade queued and
/// the player has not dismissed yet, a JSON list in the order queued.
const noticesKey = 'migrationNotices';

/// Queues the notice [id] (see `MigrationNotice`) for the next start's Home.
Future<void> queueNotice(GeneratedDatabase db, String id) async {
  final row = await db
      .customSelect('SELECT value FROM key_values WHERE key = ?', variables: [Variable<String>(noticesKey)])
      .getSingleOrNull();
  final ids = row == null ? <String>[] : (jsonDecode(row.read<String>('value')) as List).cast<String>();
  if (ids.contains(id)) return;
  await db.customStatement(
      'INSERT OR REPLACE INTO key_values (key, value) VALUES (?, ?)', [noticesKey, jsonEncode([...ids, id])]);
}
