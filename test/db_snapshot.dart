// Shared by the tests that check a play wrote nothing to the database.
import 'package:fudatobashi/db/database.dart';

/// Every table's row count, and the key_values rows themselves.
Future<Map<String, Object>> dbSnapshot(AppDatabase db) async {
  final snapshot = <String, Object>{};
  for (final table in db.allTables) {
    final name = table.actualTableName;
    final count = await db.customSelect('SELECT COUNT(*) AS n FROM $name').getSingle();
    snapshot[name] = count.read<int>('n');
  }
  snapshot['key_values contents'] = {for (final row in await db.select(db.keyValues).get()) row.key: row.value};
  return snapshot;
}
