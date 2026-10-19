import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config.dart';

/// The first folder at or above [start] that holds a pubspec.yaml, or null.
Directory? findProjectRoot(Directory start) {
  var dir = start.absolute;
  while (true) {
    if (File(p.join(dir.path, Cfg.projectFileName)).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// Writes [text] to [file] through a temporary file in the same folder.
Future<void> writeAtomic(File file, String text) => writeAtomicBytes(file, utf8.encode(text));

/// Writes [bytes] to [file] through a temporary file in the same folder, so a watcher never sees half a file.
Future<void> writeAtomicBytes(File file, List<int> bytes) async {
  final temp = File(p.join(file.parent.path, '.${p.basename(file.path)}.tmp'));
  await temp.writeAsBytes(bytes);
  await temp.rename(file.path);
}

/// Moves [entity] to the trash when `gio` can, else deletes it. True when it went to the trash.
Future<bool> moveToTrash(FileSystemEntity entity) async {
  var trashed = false;
  try {
    final r = await Process.run(Cfg.trashCommand, [...Cfg.trashArguments, entity.path]);
    trashed = r.exitCode == 0 && !entity.existsSync();
  } catch (_) {
    trashed = false;
  }
  if (entity.existsSync()) entity.deleteSync(recursive: true);
  return trashed;
}
