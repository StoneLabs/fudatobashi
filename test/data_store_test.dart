// Backup, restore and the safe start (`DataStore`): the backup file name,
// a backup restored, an old schema upgraded on restore, files turned away
// untouched, the safety copies and their pruning, the recovery screen and
// Start fresh. The system's file dialogs are stood in for.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/l10n/data_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/migrations/migrations.dart';
import 'package:fudatobashi/state/backups.dart';
import 'package:fudatobashi/state/crash_log.dart';
import 'package:fudatobashi/state/data_store.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app_root.dart';
import 'package:fudatobashi/ui/recovery/recovery_screen.dart';
import 'package:sqlite3/sqlite3.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

class _Dialogs implements FileDialogs {
  final saved = <(String, Uint8List)>[];
  File? picked;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    saved.add((fileName, bytes));
    return true;
  }

  @override
  Future<File?> pick() async => picked;
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('a backup is offered as fudatobashi_backup_yyMMdd-HHmm.sqlite in local time', () {
    expect(backupFileName(DateTime(2026, 10, 16, 14, 32)), 'fudatobashi_backup_261016-1432.sqlite');
    expect(backupFileName(DateTime(2027, 1, 5, 9, 7, 59)), 'fudatobashi_backup_270105-0907.sqlite');
  });

  test('the tables checked for the current schema are the database\'s own', () {
    final db = AppDatabase(NativeDatabase.memory());
    expect(latestSchemaVersion, db.schemaVersion);
    expect(schemaTables[latestSchemaVersion], {for (final t in db.allTables) t.actualTableName});
  });

  test('the crash log keeps errors newest last, under its cap', () async {
    final log = CrashLog(File('${Directory.systemTemp.createTempSync('crash_log_').path}/crash.txt'));
    await log.record(StateError('first'), StackTrace.current);
    await log.record('x' * (CrashLogTuning.maxChars * 2), null);
    await log.record(StateError('last'), null);
    final text = await log.read();
    expect(text.length, lessThanOrEqualTo(CrashLogTuning.maxChars));
    expect(text, contains('last'));
    expect(text, isNot(contains('first')));
    await log.clear();
    expect(await log.read(), isEmpty);
  });

  group('DataStore', () {
    late Directory root;
    late _Dialogs dialogs;
    late DataStore store;
    setUp(() {
      root = Directory.systemTemp.createTempSync('data_store_');
      dialogs = _Dialogs();
      store = DataStore(
        DataPaths(
          database: File('${root.path}/documents/fudatobashi.sqlite')..parent.createSync(),
          support: Directory('${root.path}/support'),
          temp: Directory('${root.path}/temp')..createSync(),
        ),
        dialogs: dialogs,
        connect: NativeDatabase.new,
      );
    });
    tearDown(() async {
      if (store.state case DataOpened(:final progress)) await progress.db.close();
      root.deleteSync(recursive: true);
    });

    Progress opened() => (store.state as DataOpened).progress;
    File fileIn(String name) => File('${root.path}/$name');
    File sqliteFile(String name, {required int version, required List<String> sql}) {
      final file = fileIn(name);
      sqlite3.open(file.path)
        ..userVersion = version
        ..execute(sql.join(';'))
        ..close();
      return file;
    }



    test('a backup restores the data it was made from, after a safety copy of the data replaced', () async {
      await store.start();
      await opened().updateSettings(opened().settings.copyWith(language: 'ja'));
      expect(await store.backUp(), isTrue);
      final (name, bytes) = dialogs.saved.single;
      expect(name, startsWith(DataFileTuning.exportPrefix));
      final backup = fileIn('backup.sqlite')..writeAsBytesSync(bytes);

      await opened().resetAllData();
      expect(opened().settings.language, DefaultSettings.language);
      await store.restore(backup);
      expect(opened().settings.language, 'ja');
      expect(store.takeNotice(), DataNotice.restored);

      final copy = store.copies().single;
      expect(copy.kind, CopyKind.restore);
      final kept = sqlite3.open(copy.file.path, mode: OpenMode.readOnly);
      expect(kept.select("SELECT COUNT(*) AS c FROM key_values WHERE key = 'settings' AND value LIKE '%\"ja\"%'").first['c'],
          0, reason: 'the copy holds the data as it was before the restore');
      kept.close();
    });

    test('a backup from schema 2 (v1.3.0) is upgraded as it is restored', () async {
      await store.start();
      final backup = File('test/past_db/v1.3.0_journey.sqlite').copySync(fileIn('old.sqlite').path);
      final expected = jsonDecode(File('test/past_db/v1.3.0_journey.json').readAsStringSync()) as Map<String, dynamic>;
      expect(checkBackup(backup), 2);
      await store.restore(backup);
      final progress = opened();
      expect(progress.runs.length, (expected['rows'] as Map)['sessions']);
      expect((await progress.db.customSelect('PRAGMA user_version').getSingle()).data.values.single, 3);
    });

    test('a file that is no backup, a newer one or another schema is turned away and nothing changes', () async {
      await store.start();
      await opened().updateSettings(opened().settings.copyWith(language: 'ja'));
      final before = store.state;
      final files = {
        fileIn('notes.txt')..writeAsStringSync('not a database at all'): BackupProblem.notBackup,
        fileIn('damaged.sqlite')..writeAsBytesSync([...ascii.encode('SQLite format 3\u0000'), ...List.filled(200, 7)]):
            BackupProblem.damaged,
        sqliteFile('newer.sqlite', version: 4, sql: ['CREATE TABLE runs (id INTEGER)']): BackupProblem.tooNew,
        sqliteFile('other.sqlite', version: 3, sql: ['CREATE TABLE notes (id INTEGER)']): BackupProblem.notBackup,
        sqliteFile('unversioned.sqlite', version: 0, sql: ['CREATE TABLE runs (id INTEGER)']): BackupProblem.notBackup,
      };
      for (final MapEntry(key: file, value: problem) in files.entries) {
        await expectLater(store.restore(file),
            throwsA(isA<BackupRejected>().having((e) => e.problem, 'problem', problem)), reason: file.path);
      }
      expect(store.state, same(before));
      expect(opened().settings.language, 'ja');
      expect(await opened().db.customSelect('SELECT 1').get(), hasLength(1), reason: 'the data is still open');
      expect(store.copies(), isEmpty);
    });

    test('a safety copy is made before an upgrade at start, and only the latest copies are kept', () async {
      File('test/past_db/v1.3.0_fresh.sqlite').copySync(store.paths.database.path);
      await store.start();
      expect(store.state, isA<DataOpened>());
      final copy = store.copies().single;
      expect(copy.kind, CopyKind.update);
      final old = sqlite3.open(copy.file.path, mode: OpenMode.readOnly);
      expect(old.userVersion, 2);
      old.close();

      final dir = store.paths.backups;
      for (var day = 1; day <= DataFileTuning.keptCopies + 2; day++) {
        File('${dir.path}/restore_2601${day.toString().padLeft(2, '0')}-120000.sqlite').writeAsStringSync('$day');
      }
      final aside = File('${dir.path}/setAside_250101-120000.sqlite')..writeAsStringSync('kept');
      store.folder.prune();
      final left = store.copies().where((c) => c.kind != CopyKind.setAside).toList();
      expect(left, hasLength(DataFileTuning.keptCopies));
      expect(left.first.file.path, copy.file.path, reason: 'newest first');
      expect(aside.existsSync(), isTrue, reason: 'files set aside are never pruned');
    });

    test('the oldest copy in a full backups folder can be restored', () async {
      await store.start();
      await opened().updateSettings(opened().settings.copyWith(language: 'ja'));
      await store.backUp();
      final dir = store.paths.backups..createSync(recursive: true);
      final oldest = File('${dir.path}/update_250101-120000.sqlite')..writeAsBytesSync(dialogs.saved.single.$2);
      for (var day = 2; day <= DataFileTuning.keptCopies; day++) {
        File('${dir.path}/update_2501${day.toString().padLeft(2, '0')}-120000.sqlite').writeAsStringSync('$day');
      }
      await opened().resetAllData();
      await store.restore(oldest);
      expect(store.state, isA<DataOpened>());
      expect(opened().settings.language, 'ja');
      expect(store.copies(), hasLength(DataFileTuning.keptCopies));
    });

    test('data from a newer app fails to open instead of being stamped with this version', () async {
      sqliteFile('documents/fudatobashi.sqlite', version: 4, sql: ['CREATE TABLE runs (id INTEGER)']);
      await store.start();
      expect(store.state, isA<DataFailed>());
      final raw = sqlite3.open(store.paths.database.path, mode: OpenMode.readOnly);
      expect(raw.userVersion, 4);
      raw.close();
    });

    test('Start fresh moves the file that failed aside and opens new data', () async {
      store.paths.database.writeAsStringSync('garbage that is no database');
      await store.start();
      expect(store.state, isA<DataFailed>());
      expect(await store.saveDataFile(), isTrue);
      expect(utf8.decode(dialogs.saved.single.$2), 'garbage that is no database');

      await store.startFresh();
      expect(store.state, isA<DataOpened>());
      final aside = store.copies().single;
      expect(aside.kind, CopyKind.setAside);
      expect(aside.file.readAsStringSync(), 'garbage that is no database');
    });


    testWidgets('data that fails to open shows the recovery screen', (tester) async {
      await tester.runAsync(() async {
        store.paths.database.writeAsStringSync('garbage that is no database');
        await store.start();
      });
      await tester.pumpWidget(AppRoot(store: store));
      await tester.pump(const Duration(milliseconds: 100));
      const s = S('en');
      expect(find.byType(RecoveryScreen), findsOneWidget);
      expect(find.text(s.recoveryTitle), findsOneWidget);
      expect(find.text(s.recoverySave), findsOneWidget);
      expect(find.text(s.restoreBackup), findsOneWidget);
      expect(find.text(s.startFresh), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });
  });
}
