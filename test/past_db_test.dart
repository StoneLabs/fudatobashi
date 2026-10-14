import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/state/progress.dart';

/// The release check for upgrades: opens a database dump from each shipped version
/// (made by tool/past_db/make_past_db.sh) with this build.
void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final dumps = Directory('test/past_db')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sqlite'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final dump in dumps) {
    final name = dump.uri.pathSegments.last;
    test(name, () async {
      final temp = Directory.systemTemp.createTempSync('past_db_');
      final file = dump.copySync('${temp.path}/$name');
      final expected = jsonDecode(File(dump.path.replaceAll(RegExp(r'\.sqlite$'), '.json')).readAsStringSync()) as Map<String, dynamic>;
      final db = AppDatabase(NativeDatabase(file));
      try {
        // The first query runs the migrations.
        await db.validateDatabaseSchema();

        Future<int> count(String sql) async => (await db.customSelect(sql).getSingle()).read<int>('c');
        final tables = {
          for (final r in await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get()) r.read<String>('name')
        };
        for (final entry in (expected['rows'] as Map<String, dynamic>).entries) {
          if (!tables.contains(entry.key)) continue;
          expect(await count('SELECT COUNT(*) AS c FROM "${entry.key}"'), entry.value, reason: 'rows in ${entry.key}');
        }
        expect(await count('SELECT COUNT(*) AS c FROM items WHERE unlocked = 1'), expected['unlockedItems'], reason: 'unlocked items');
        final trainer = (await db.customSelect("SELECT value FROM key_values WHERE key = 'trainer'").get())
            .map((r) => jsonDecode(r.read<String>('value')) as Map<String, dynamic>)
            .firstOrNull;
        for (final setting in (expected['settings'] as Map<String, dynamic>).entries) {
          expect(trainer?[setting.key], setting.value, reason: 'setting ${setting.key}');
        }

        // The start-up load, after the counts as it writes a few values of its own.
        await Progress.open(db);
      } catch (e, s) {
        fail('Upgrading $name failed: $e\n$s');
      } finally {
        await db.close();
        temp.deleteSync(recursive: true);
      }
    });
  }
}
