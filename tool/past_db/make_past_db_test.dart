// Copied into an old release by make_past_db.sh and run there, so it only
// uses API that every release has.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/state/demo_data.dart';
import 'package:fudatobashi/state/progress.dart';

import 'past_db_json.dart';

/// Settings changed from their defaults in the journey dump.
const _changedBatchSize = 7;
const _changedRetention = 0.85;

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final out = Directory(Platform.environment['PAST_DB_OUT']!)..createSync(recursive: true);
  final tag = Platform.environment['PAST_DB_TAG']!;

  Future<File> fresh(String name) async {
    final f = File('${out.path}/${tag}_$name.sqlite');
    if (f.existsSync()) f.deleteSync();
    return f;
  }

  test('fresh', () async {
    final f = await fresh('fresh');
    final db = AppDatabase(NativeDatabase(f));
    await Progress.open(db);
    await writePastDbJson(db, f, {});
    await db.close();
  });

  test('journey', () async {
    final f = await fresh('journey');
    final db = AppDatabase(NativeDatabase(f));
    final progress = await Progress.open(db);
    await seedDemoData(progress);
    final config = progress.trainer.config;
    await progress.updateTrainerConfig(config.copyWith(batchSize: _changedBatchSize, desiredRetention: _changedRetention));
    final changed = progress.trainer.config;
    await writePastDbJson(db, f, {'batchSize': changed.batchSize, 'desiredRetention': changed.desiredRetention});
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
