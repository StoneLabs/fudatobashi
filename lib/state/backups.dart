import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../config/config.dart';
import '../migrations/migrations.dart';

/// [at]'s local date and time as `yyMMdd-HHmm`, plus `ss` with [seconds].
String fileStamp(DateTime at, {bool seconds = false}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final t = at.toLocal();
  return '${two(t.year % 100)}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${seconds ? two(t.second) : ''}';
}

/// The file name a backup made at [at] is offered under.
String backupFileName(DateTime at) => '${DataFileTuning.exportPrefix}${fileStamp(at)}${DataFileTuning.extension}';

/// Why the app made a copy in its backups folder.
enum CopyKind {
  /// Before an app update upgraded the data.
  update,

  /// Before a backup replaced the data.
  restore,

  /// The data file that failed to open, moved aside by Start fresh or a
  /// restore.
  setAside,
}

/// A copy in the backups folder, named `<kind>_<yyMMdd-HHmmss>.sqlite`.
class BackupCopy {
  const BackupCopy(this.file, this.kind, this.at);
  final File file;
  final CopyKind kind;
  final DateTime at;

  static final _name = RegExp(r'^(\w+)_(\d\d)(\d\d)(\d\d)-(\d\d)(\d\d)(\d\d)(?:_\d+)?\.sqlite$');

  static BackupCopy? of(File file) {
    final m = _name.firstMatch(file.uri.pathSegments.last);
    final kind = m == null ? null : CopyKind.values.asNameMap()[m[1]];
    if (kind == null) return null;
    final n = [for (var i = 2; i <= 7; i++) int.parse(m![i]!)];
    return BackupCopy(file, kind, DateTime(2000 + n[0], n[1], n[2], n[3], n[4], n[5]));
  }
}

/// The app-private folder of automatic copies and set-aside files.
class BackupFolder {
  const BackupFolder(this.dir);
  final Directory dir;

  /// Every copy, newest first.
  List<BackupCopy> copies() {
    if (!dir.existsSync()) return [];
    return [
      for (final f in dir.listSync().whereType<File>()) ?BackupCopy.of(f),
    ]..sort((a, b) => b.at.compareTo(a.at));
  }

  /// A new, unused file for a copy of [kind] made now.
  File newFile(CopyKind kind) {
    dir.createSync(recursive: true);
    final base = '${dir.path}/${kind.name}_${fileStamp(DateTime.now(), seconds: true)}';
    var file = File('$base${DataFileTuning.extension}');
    for (var i = 2; file.existsSync(); i++) {
      file = File('${base}_$i${DataFileTuning.extension}');
    }
    return file;
  }

  /// Deletes all but the newest [DataFileTuning.keptCopies] automatic
  /// copies; files set aside are kept.
  void prune() {
    final automatic = copies().where((c) => c.kind != CopyKind.setAside).toList();
    for (final old in automatic.skip(DataFileTuning.keptCopies)) {
      old.file.deleteSync();
    }
  }
}

/// Why a file can't be restored.
enum BackupProblem {
  /// Not an SQLite database, or not one of this app's.
  notBackup,

  /// An SQLite file that can't be read.
  damaged,

  /// Made by a newer version of the app.
  tooNew,
}

class BackupRejected implements Exception {
  const BackupRejected(this.problem, this.detail);
  final BackupProblem problem;
  final String detail;

  @override
  String toString() => 'Backup rejected (${problem.name}): $detail';
}

/// Checks that [file] is a database of this app at a schema version it can
/// open (and upgrade), without changing it; returns the version or throws
/// [BackupRejected].
int checkBackup(File file) {
  const header = 'SQLite format 3\u0000';
  final bytes = file.openSync()..setPositionSync(0);
  final head = bytes.readSync(header.length);
  bytes.closeSync();
  if (ascii.decode(head, allowInvalid: true) != header) {
    throw const BackupRejected(BackupProblem.notBackup, 'no SQLite header');
  }
  final Database db;
  try {
    db = sqlite3.open(file.path, mode: OpenMode.readOnly);
  } on SqliteException catch (e) {
    throw BackupRejected(BackupProblem.damaged, '$e');
  }
  try {
    final check = db.select('PRAGMA quick_check').first.values.first;
    if (check != 'ok') throw BackupRejected(BackupProblem.damaged, '$check');
    final version = db.userVersion;
    if (version > latestSchemaVersion) throw BackupRejected(BackupProblem.tooNew, 'version $version');
    final expected = schemaTables[version];
    final tables = {for (final r in db.select("SELECT name FROM sqlite_master WHERE type = 'table'")) r['name']};
    if (expected == null || !tables.containsAll(expected)) {
      throw BackupRejected(BackupProblem.notBackup, 'version $version, tables $tables');
    }
    return version;
  } on SqliteException catch (e) {
    throw BackupRejected(BackupProblem.damaged, '$e');
  } finally {
    db.close();
  }
}
