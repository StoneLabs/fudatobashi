import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import '../model/skin.dart';
import '../model/skin_loader.dart';
import 'image_check.dart';

/// Where a slot's image comes from.
enum SlotSource { own, shared, flat }

/// What the editor knows about one image slot of the open skin.
class SlotState {
  SlotState(this.slot, this.ownFile);

  final Slot slot;

  /// `<slot>.png` in the skin folder, whether or not it exists.
  final File ownFile;

  /// The file the image was read from: [ownFile] or the slot's shared file.
  File? file;
  SlotSource source = SlotSource.flat;
  bool loading = false;
  ui.Image? image;
  DateTime? loadedAt;
  String? error;

  /// Counts load starts. A decode that finishes under an older number is dropped.
  int revision = 0;
  Timer? timer;
}

/// Loads the open skin's images and keeps them current as the files change. Images are never
/// disposed here: a scene that is still painted may hold one, and it is freed once nothing does.
class SkinTextures extends ChangeNotifier {
  SkinTextures({required this.onMessage});

  /// Called with a line for the status bar.
  final void Function(String message, {bool error}) onMessage;

  Directory? _root;

  /// The slots of the open skin, in the order the texture list shows them.
  Map<String, SlotState> states = {};

  Map<String, ui.Image> get images => {
        for (final s in states.values)
          if (s.image != null) s.slot.name: s.image!,
      };

  /// Points the slots at a skin folder and loads every file there is.
  void open(Directory root, Directory skinDir, List<Slot> slots) {
    for (final s in states.values) {
      s.timer?.cancel();
      s.revision++;
    }
    _root = root;
    states = {for (final slot in slots) slot.name: SlotState(slot, File(p.join(skinDir.path, slot.fileName)))};
    for (final s in states.values) {
      unawaited(_load(s, announce: false));
    }
    notifyListeners();
  }

  /// A file in the skins folder was added, changed or deleted.
  void fileEvent(String path, {required bool removed}) {
    final changed = p.normalize(File(path).absolute.path);
    for (final s in states.values) {
      final watched = [s.ownFile, if (s.slot.sharedFile != null && _root != null) File(p.join(_root!.path, s.slot.sharedFile!))];
      if (!watched.any((f) => p.normalize(f.absolute.path) == changed)) continue;
      s.timer?.cancel();
      s.timer = Timer(removed ? Cfg.deleteGrace : Cfg.textureReloadDebounce, () => _load(s, announce: true));
    }
  }

  /// Loads the slot again now, for example after the editor wrote its file.
  Future<void> reload(String slot) async {
    final s = states[slot];
    if (s != null) await _load(s, announce: false);
  }

  Future<void> _load(SlotState s, {required bool announce}) async {
    final root = _root;
    if (root == null) return;
    final revision = ++s.revision;
    final file = slotFile(root, s.ownFile.parent, s.slot);
    if (file == null) {
      s
        ..file = null
        ..source = SlotSource.flat
        ..image = null
        ..loadedAt = null
        ..error = null
        ..loading = false;
      if (announce) onMessage('${s.slot.fileName} is gone; ${s.slot.name} uses ${s.slot.defaultNote}');
      notifyListeners();
      return;
    }
    final name = p.basename(file.path);
    final watch = Stopwatch()..start();
    s.loading = true;
    notifyListeners();
    Object? lastError;
    for (var attempt = 0; attempt <= Cfg.decodeRetryDelays.length; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Cfg.decodeRetryDelays[attempt - 1]);
        if (revision != s.revision) return;
      }
      try {
        final bytes = await _readStable(file);
        final problem = incompleteReason(bytes);
        if (problem != null) throw problem;
        final image = await decodeImage(bytes);
        if (revision != s.revision) return;
        s
          ..file = file
          ..source = p.equals(file.path, s.ownFile.path) ? SlotSource.own : SlotSource.shared
          ..image = image
          ..loadedAt = DateTime.now()
          ..error = null
          ..loading = false;
        notifyListeners();
        if (announce) onMessage('$name reloaded (${watch.elapsedMilliseconds} ms)');
        return;
      } catch (e) {
        lastError = e;
      }
    }
    if (revision != s.revision) return;
    s
      ..loading = false
      ..error = '$lastError';
    onMessage('$name could not be loaded: $lastError (keeping the last good image)', error: true);
    notifyListeners();
  }

  /// Reads the file, and starts over if it changed while it was read.
  Future<Uint8List> _readStable(File file) async {
    for (var i = 0; i < Cfg.stableReadTries; i++) {
      final before = await file.stat();
      final bytes = await file.readAsBytes();
      final after = await file.stat();
      if (before.size == after.size && before.modified == after.modified && bytes.length == after.size) {
        return bytes;
      }
    }
    throw 'the file keeps changing';
  }

  @override
  void dispose() {
    for (final s in states.values) {
      s.timer?.cancel();
      s.revision++;
    }
    super.dispose();
  }
}
