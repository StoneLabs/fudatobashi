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

/// What an upgrade keeps: a query on the old schema's [table], and the one
/// on the current schema that must give the same row.
const _kept = [
  (
    table: 'sessions',
    before: 'SELECT COUNT(*), TOTAL(card_count), TOTAL(completed), TOTAL(mode = 2), TOTAL(mode = 1), '
        'TOTAL(CASE WHEN total_us > 0 THEN total_us END), COUNT(CASE WHEN total_us > 0 THEN 1 END), '
        "TOTAL(json_extract(meta, '\$.dayDone')), TOTAL(json_extract(meta, '\$.maskLevel')) FROM sessions",
    after: "SELECT COUNT(*), TOTAL(planned), TOTAL(completed), TOTAL(mode = 'training'), TOTAL(mode = 'nigate'), "
        'TOTAL(clock_us), COUNT(clock_us), TOTAL(day_done), TOTAL(mask_level) FROM runs',
  ),
  (
    table: 'attempts',
    before: 'SELECT COUNT(*), COUNT(grade), TOTAL(grade), TOTAL(outcome = 1), TOTAL(response_us), TOTAL(undone), '
        'TOTAL(wrong), TOTAL(at) FROM attempts',
    after: "SELECT COUNT(*), COUNT(grade), TOTAL(grade), TOTAL(outcome = 'dontKnow'), TOTAL(response_us), "
        'TOTAL(undone), TOTAL(wrong), TOTAL(at) FROM attempts',
  ),
  (
    table: 'items',
    before: "SELECT COUNT(*), COUNT(fsrs), TOTAL(json_extract(fsrs, '\$.state') = 2), "
        "ROUND(TOTAL(json_extract(fsrs, '\$.stability')), 6), ROUND(TOTAL(json_extract(fsrs, '\$.difficulty')), 6), "
        "TOTAL(strftime('%s', json_extract(fsrs, '\$.due'))), "
        "TOTAL(strftime('%s', json_extract(fsrs, '\$.lastReview'))) FROM items",
    after: "SELECT COUNT(*), COUNT(fsrs_state), TOTAL(fsrs_state = 'review'), ROUND(TOTAL(fsrs_stability), 6), "
        'ROUND(TOTAL(fsrs_difficulty), 6), TOTAL(fsrs_due), TOTAL(fsrs_last_review) FROM items',
  ),
  (
    table: 'key_values',
    before: "SELECT group_concat(key) FROM (SELECT key FROM key_values WHERE key NOT IN ('rating', "
        "'islandsCelebrated') ORDER BY key)",
    after: 'SELECT group_concat(key) FROM (SELECT key FROM key_values ORDER BY key)',
  ),
  (
    table: 'key_values',
    before: 'SELECT group_concat(value) FROM (SELECT DISTINCT i.value FROM key_values k, json_each(k.value) i '
        "WHERE k.key = 'islandsCelebrated' ORDER BY i.value)",
    after: 'SELECT group_concat(island) FROM (SELECT island FROM island_completions ORDER BY island)',
  ),
  (
    table: 'sessions',
    before: "SELECT COUNT(*) FROM sessions s, json_each(s.meta, '\$.islandsCompleted')",
    after: 'SELECT COUNT(run_id) FROM island_completions',
  ),
  (
    table: 'side_trip_runs',
    before: 'SELECT COUNT(*), TOTAL(score), TOTAL(completed), TOTAL(rating) FROM side_trip_runs',
    after: 'SELECT COUNT(*), TOTAL(score), TOTAL(completed), TOTAL(rating) FROM side_trip_runs',
  ),
  (
    table: 'side_trip_answers',
    before: 'SELECT COUNT(*), TOTAL(wrong_taps), TOTAL(response_us), COUNT(first_tap) FROM side_trip_answers',
    after: 'SELECT COUNT(*), TOTAL(wrong_taps), TOTAL(response_us), COUNT(first_tap) FROM side_trip_answers',
  ),
  (
    table: 'days',
    before: 'SELECT TOTAL(done_at), TOTAL(built_at), TOTAL(miss_guess) FROM days',
    after: 'SELECT TOTAL(done_at), TOTAL(built_at), TOTAL(miss_guess) FROM days',
  ),
  (
    table: 'day_cards',
    before: 'SELECT COUNT(*), TOTAL(kind = 1) FROM day_cards',
    after: "SELECT COUNT(*), TOTAL(kind = 'newCard') FROM day_cards",
  ),
];

/// Tables an upgrade renamed, and those it dropped or whose rows it changes
/// (checked with [_kept] instead).
const _renamed = {'sessions': 'runs'};
const _notCounted = {'rating_points', 'key_values'};

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
      final before = <String, List<Object?>>{};
      final db = AppDatabase(NativeDatabase(file, setup: (raw) {
        final old = {for (final r in raw.select("SELECT name FROM sqlite_master WHERE type = 'table'")) r['name']};
        for (final k in _kept) {
          if (old.contains(k.table)) before[k.after] = raw.select(k.before).first.values;
        }
      }));
      try {
        // The first query runs the migrations.
        await db.validateDatabaseSchema();

        Future<int> count(String sql) async => (await db.customSelect(sql).getSingle()).read<int>('c');
        final tables = {
          for (final r in await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get()) r.read<String>('name')
        };
        expect(tables, isNot(anyOf(contains('sessions'), contains('rating_points'))), reason: 'dropped tables');
        for (final entry in (expected['rows'] as Map<String, dynamic>).entries) {
          if (_notCounted.contains(entry.key)) continue;
          final table = _renamed[entry.key] ?? entry.key;
          expect(await count('SELECT COUNT(*) AS c FROM "$table"'), entry.value, reason: 'rows in $table');
        }
        for (final MapEntry(key: sql, value: row) in before.entries) {
          expect((await db.customSelect(sql).getSingle()).data.values.toList(), row, reason: sql);
        }
        for (final table in ['runs', 'side_trip_runs']) {
          expect(
              await count('SELECT COUNT(*) AS c FROM $table r LEFT JOIN days d ON d.day = r.day '
                  'WHERE d.day IS NULL OR r.started_at < d.starts_at OR r.started_at >= d.ends_at'),
              0,
              reason: 'every row of $table lies in its day');
        }
        expect(await count('SELECT COUNT(*) AS c FROM runs WHERE ended_at < started_at OR rating IS NOT NULL'), 0,
            reason: 'run end times and ratings');
        expect(await count('SELECT COUNT(*) AS c FROM items WHERE unlocked = 1'), expected['unlockedItems'], reason: 'unlocked items');
        final trainer = (await db.customSelect("SELECT value FROM key_values WHERE key = 'trainer'").get())
            .map((r) => jsonDecode(r.read<String>('value')) as Map<String, dynamic>)
            .firstOrNull;
        for (final setting in (expected['settings'] as Map<String, dynamic>).entries) {
          expect(trainer?[setting.key], setting.value, reason: 'setting ${setting.key}');
        }

        // The start-up load, after the counts as it writes a few values of its own.
        final progress = await Progress.open(db);
        expect(progress.xp.total > 0, progress.runs.isNotEmpty, reason: 'experience from the old runs');
        expect(progress.ratedRuns, isEmpty, reason: 'an upgraded player starts unplaced');
      } catch (e, s) {
        fail('Upgrading $name failed: $e\n$s');
      } finally {
        await db.close();
        temp.deleteSync(recursive: true);
      }
    });
  }
}
