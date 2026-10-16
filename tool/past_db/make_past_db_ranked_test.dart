// Made for releases from 2.0.0 on (earlier ones have no ranked demo seed):
// the dump of an all-known player with ranked runs, ratings and forfeits.
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

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final out = Directory(Platform.environment['PAST_DB_OUT']!)..createSync(recursive: true);
  final tag = Platform.environment['PAST_DB_TAG']!;

  test('ranked', () async {
    final f = File('${out.path}/${tag}_ranked.sqlite');
    if (f.existsSync()) f.deleteSync();
    final db = AppDatabase(NativeDatabase(f));
    final progress = await Progress.open(db);
    await seedRankedDemoData(progress);
    await writePastDbJson(db, f, {});
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 10)));
}
