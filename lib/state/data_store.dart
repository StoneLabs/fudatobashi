import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config/config.dart';
import '../db/database.dart';
import 'backups.dart';
import 'crash_log.dart';
import 'progress.dart';

/// Where the app keeps its files.
class DataPaths {
  const DataPaths({required this.database, required this.support, required this.temp});

  final File database;

  /// App-private: the backups folder, the crash log.
  final Directory support;
  final Directory temp;

  Directory get backups => Directory('${support.path}/${DataFileTuning.backupsFolder}');
  File get crashLog => File('${support.path}/${CrashLogTuning.fileName}');
  File get failNextStart => File('${support.path}/${DataFileTuning.failNextStartFile}');

  static Future<DataPaths> resolve() async => DataPaths(
        database: File(
            '${(await getApplicationDocumentsDirectory()).path}/${DataFileTuning.databaseName}${DataFileTuning.extension}'),
        support: await getApplicationSupportDirectory(),
        temp: await getTemporaryDirectory(),
      );
}

/// The system's save and open dialogs (behind an interface so tests can
/// stand in for them).
abstract interface class FileDialogs {
  /// Asks where to save [bytes], offering [fileName]; false when cancelled.
  Future<bool> save(String fileName, Uint8List bytes);

  /// Asks for a file to open; null when cancelled.
  Future<File?> pick();
}

/// `file_picker`: the Storage Access Framework on Android, the desktop's
/// own dialogs elsewhere. A picked file is read into [temp] first, as on
/// Android it is no local file.
class SystemFileDialogs implements FileDialogs {
  const SystemFileDialogs(this.temp);

  final Directory temp;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async =>
      await FilePicker.saveFile(fileName: fileName, bytes: bytes) != null;

  @override
  Future<File?> pick() async {
    final picked = await FilePicker.pickFile();
    if (picked == null) return null;
    await temp.create(recursive: true);
    return File('${temp.path}/${DataFileTuning.databaseName}_picked${DataFileTuning.extension}')
        .writeAsBytes(await picked.readAsBytes(), flush: true);
  }
}

/// How the data stands: open, or failed to open.
sealed class DataState {
  const DataState();
}

class DataOpened extends DataState {
  const DataOpened(this.progress);
  final Progress progress;
}

class DataFailed extends DataState {
  const DataFailed(this.error);
  final String error;
}

/// What the app tells the player once it has started over.
enum DataNotice { restored, restoreFailed }

/// A backup passed its check but could not be opened; the data is as it was.
class RestoreFailed implements Exception {
  const RestoreFailed(this.error);
  final String error;

  @override
  String toString() => error;
}

/// The data file as a whole: opening it at start (with a safety copy before
/// an upgrade), backing it up, restoring a backup and starting fresh. Each
/// of these ends in a new [state], which the app starts over from.
class DataStore extends ChangeNotifier {
  DataStore(this.paths, {required this.dialogs, QueryExecutor Function(File file)? connect})
      : _connect = connect ?? _connectFile;

  final DataPaths paths;
  final FileDialogs dialogs;
  final QueryExecutor Function(File file) _connect;
  DataState? _state;
  DataNotice? _notice;

  static QueryExecutor _connectFile(File file) => driftDatabase(
        name: DataFileTuning.databaseName,
        native: DriftNativeOptions(databasePath: () async => file.path),
      );

  DataState get state => _state!;

  /// The notice for the new start, once.
  DataNotice? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }
  BackupFolder get folder => BackupFolder(paths.backups);

  Future<void> start() async => _set(await _open(copyBeforeUpgrade: true));

  void _set(DataState state) {
    _state = state;
    notifyListeners();
  }

  Future<DataState> _open({required bool copyBeforeUpgrade}) async {
    AppDatabase? db;
    try {
      if (await paths.failNextStart.exists()) {
        await paths.failNextStart.delete();
        throw StateError('Failed on purpose (developer mode: Fail the next start).');
      }
      db = AppDatabase(_connect(paths.database), copyBeforeUpgrade ? _copyBeforeUpgrade : null);
      return DataOpened(await Progress.open(db).timeout(DataFileTuning.openTimeout));
    } catch (e, stack) {
      unawaited(CrashLog.instance?.record(e, stack));
      try {
        await db?.close().timeout(DataFileTuning.closeTimeout);
      } catch (_) {}
      return DataFailed('$e');
    }
  }

  Future<void> _copyBeforeUpgrade(AppDatabase db, int from) async {
    await _snapshot(db, folder.newFile(CopyKind.update));
    folder.prune();
  }

  /// A consistent copy of the open database, never a byte copy of it.
  static Future<void> _snapshot(AppDatabase db, File to) => db.customStatement('VACUUM INTO ?', [to.path]);

  /// Offers a snapshot of the open data to save; false when cancelled.
  Future<bool> backUp() async {
    final temp = File('${paths.temp.path}/${DataFileTuning.databaseName}_export${DataFileTuning.extension}');
    if (await temp.exists()) await temp.delete();
    await _snapshot((state as DataOpened).progress.db, temp);
    try {
      return await dialogs.save(backupFileName(DateTime.now()), await temp.readAsBytes());
    } finally {
      await temp.delete();
    }
  }

  /// Offers the data file as it is (it failed to open); false when cancelled.
  Future<bool> saveDataFile() async =>
      dialogs.save(backupFileName(DateTime.now()), await paths.database.readAsBytes());

  /// The automatic copies and set-aside files, newest first.
  List<BackupCopy> copies() => folder.copies();

  /// Replaces the data with [backup] (any older schema is upgraded) after a
  /// safety copy of the current data; throws [BackupRejected] before
  /// changing anything, or [RestoreFailed] once it has put everything back.
  Future<void> restore(File backup) async {
    checkBackup(backup);
    final current = await _setCurrentAside();
    await _place(backup);
    final next = await _open(copyBeforeUpgrade: false);
    if (next is DataFailed) {
      if (current != null) {
        await _place(current);
      } else {
        await _removeDatabase();
      }
      _notice = DataNotice.restoreFailed;
      _set(await _open(copyBeforeUpgrade: false));
      throw RestoreFailed(next.error);
    }
    _notice = DataNotice.restored;
    _set(next);
  }

  /// Moves the data file aside, never deleting it, and opens new data.
  Future<void> startFresh() async {
    if (_state case DataOpened(:final progress)) await progress.db.close();
    await _moveAside();
    _set(await _open(copyBeforeUpgrade: true));
  }

  /// The next start fails on purpose, to show the recovery screen.
  Future<void> failNextStart() => paths.failNextStart.create(recursive: true);

  /// Keeps the current data in the backups folder and lets go of it:
  /// open data as a snapshot, a file that failed to open as it is.
  Future<File?> _setCurrentAside() async {
    if (_state case DataOpened(:final progress)) {
      final copy = folder.newFile(CopyKind.restore);
      await _snapshot(progress.db, copy);
      await progress.db.close();
      folder.prune();
      return copy;
    }
    return _moveAside();
  }

  static const _sidecars = ['-journal', '-wal', '-shm'];

  Future<File?> _moveAside() async {
    if (!await paths.database.exists()) return null;
    final to = folder.newFile(CopyKind.setAside);
    for (final suffix in ['', ..._sidecars]) {
      final file = File('${paths.database.path}$suffix');
      if (!await file.exists()) continue;
      try {
        await file.rename('${to.path}$suffix');
      } on FileSystemException {
        await file.copy('${to.path}$suffix');
        await file.delete();
      }
    }
    return to;
  }

  Future<void> _removeDatabase() async {
    for (final suffix in ['', ..._sidecars]) {
      final file = File('${paths.database.path}$suffix');
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _place(File source) async {
    await _removeDatabase();
    await paths.database.parent.create(recursive: true);
    final incoming = await source.copy('${paths.database.path}.incoming');
    await incoming.rename(paths.database.path);
  }
}
