import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../config.dart';
import 'project.dart';

/// The skin names in the project's `assets/l10n/<lang>.json` files, shared with the real app.
/// Edits change one entry and keep every other key, value and the key order.
class L10nStore extends ChangeNotifier {
  Directory? projectRoot;
  Directory? _dir;
  final Map<String, Map<String, dynamic>> _maps = {for (final l in Cfg.l10nLanguages) l: {}};
  final Map<String, String> _texts = {};
  StreamSubscription<WatchEvent>? _watch;
  Timer? _timer;

  /// Whether the l10n folder exists.
  bool get available => _dir != null;

  /// Where the l10n folder is or would be, or null without a project folder.
  String? get folderPath => projectRoot == null ? null : p.join(projectRoot!.path, Cfg.l10nFolder);

  static String keyFor(String skinKey) => '${Cfg.skinNamePrefix}$skinKey';

  File? _file(String lang) => _dir == null ? null : File(p.join(_dir!.path, '$lang.json'));

  /// The name of [skinKey] in [lang], or null when the file has none.
  String? name(String lang, String skinKey) {
    final v = _maps[lang]?[keyFor(skinKey)];
    return v is String ? v : null;
  }

  Future<void> attach(Directory skinsFolder) async {
    await _watch?.cancel();
    _watch = null;
    projectRoot = findProjectRoot(skinsFolder);
    final dir = folderPath == null ? null : Directory(folderPath!);
    _dir = dir != null && dir.existsSync() ? dir : null;
    for (final l in Cfg.l10nLanguages) {
      _maps[l] = {};
    }
    _texts.clear();
    await _reload(notify: false);
    if (_dir != null) _watch = DirectoryWatcher(_dir!.path).events.listen(_onEvent);
    notifyListeners();
  }

  void _onEvent(WatchEvent e) {
    if (p.basename(e.path).startsWith('.')) return;
    _timer?.cancel();
    _timer = Timer(Cfg.l10nReloadDebounce, () => _reload(notify: true));
  }

  Future<void> _reload({required bool notify}) async {
    var changed = false;
    for (final l in Cfg.l10nLanguages) {
      final file = _file(l);
      if (file == null) continue;
      final String text;
      try {
        text = file.existsSync() ? await file.readAsString() : '';
      } catch (_) {
        continue;
      }
      if (_texts[l] == text) continue;
      _texts[l] = text;
      try {
        _maps[l] = text.trim().isEmpty ? {} : Map<String, dynamic>.from(jsonDecode(text) as Map);
      } catch (_) {
        continue;
      }
      changed = true;
    }
    if (notify && changed) notifyListeners();
  }

  /// Creates the folder with an empty file per language.
  Future<void> create() async {
    final path = folderPath;
    if (path == null) throw const FileSystemException('No project folder found');
    final dir = Directory(path)..createSync(recursive: true);
    for (final l in Cfg.l10nLanguages) {
      final file = File(p.join(dir.path, '$l.json'));
      if (!file.existsSync()) await writeAtomic(file, '{}\n');
    }
    await attach(Directory(projectRoot!.path));
  }

  /// Applies [edit] to the current content of [lang].json and writes it back.
  /// The file is read again first, so changes made elsewhere are kept.
  /// Writes nothing when [edit] changes nothing.
  Future<void> edit(String lang, void Function(Map<String, dynamic> map) edit) async {
    final file = _file(lang);
    if (file == null) throw const FileSystemException('No l10n folder');
    final old = file.existsSync() ? await file.readAsString() : '';
    final map = old.trim().isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(old) as Map);
    edit(map);
    final text = '${JsonEncoder.withIndent(' ' * Cfg.jsonIndent).convert(map)}\n';
    if (text != old) await writeAtomic(file, text);
    _texts[lang] = text;
    _maps[lang] = map;
  }

  Future<void> setName(String lang, String skinKey, String value) => edit(lang, (m) => m[keyFor(skinKey)] = value);

  /// Renames the entry in place; any older entry under the new key is dropped.
  Future<void> renameKey(String from, String to) async {
    final a = keyFor(from), b = keyFor(to);
    for (final l in Cfg.l10nLanguages) {
      await edit(l, (m) {
        if (!m.containsKey(a)) return;
        final entries = m.entries.where((e) => e.key != b).toList();
        m.clear();
        for (final e in entries) {
          m[e.key == a ? b : e.key] = e.value;
        }
      });
    }
  }

  Future<void> remove(String skinKey) async {
    for (final l in Cfg.l10nLanguages) {
      await edit(l, (m) => m.remove(keyFor(skinKey)));
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
