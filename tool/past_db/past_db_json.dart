// Shared by the make_past_db tests; only uses API that every release has.
import 'dart:convert';
import 'dart:io';

import 'package:fudatobashi/db/database.dart';

Future<void> writePastDbJson(AppDatabase db, File sqlite, Map<String, Object?> settings) async {
  final tables = [
    for (final r in await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name").get())
      r.read<String>('name')
  ];
  final rows = <String, int>{};
  for (final t in tables) {
    rows[t] = (await db.customSelect('SELECT COUNT(*) AS c FROM "$t"').getSingle()).read<int>('c');
  }
  final unlocked = (await db.customSelect('SELECT COUNT(*) AS c FROM items WHERE unlocked = 1').getSingle()).read<int>('c');
  final version = (await db.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version');
  final json = {'schemaVersion': version, 'rows': rows, 'unlockedItems': unlocked, 'settings': settings};
  File(sqlite.path.replaceAll(RegExp(r'\.sqlite$'), '.json')).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(json)}\n');
}
