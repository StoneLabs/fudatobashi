import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;

import '../config.dart';
import 'skin.dart';

class LoadedSkin {
  LoadedSkin(this.dir, this.json);
  final Directory dir;
  final Map<String, dynamic> json;
}

/// Every sub-folder of [root] that holds a skin.json, sorted by name.
/// Folders starting with `_` or `.` are shared data, not skins.
Future<List<LoadedSkin>> scanSkins(Directory root) async {
  final skins = <LoadedSkin>[];
  final dirs = await root.list().where((e) => e is Directory).cast<Directory>().toList();
  dirs.sort((a, b) => a.path.compareTo(b.path));
  for (final dir in dirs) {
    final name = p.basename(dir.path);
    if (name.startsWith('_') || name.startsWith('.')) continue;
    final file = File(p.join(dir.path, Cfg.skinFileName));
    if (!file.existsSync()) continue;
    try {
      skins.add(LoadedSkin(dir, jsonDecode(await file.readAsString()) as Map<String, dynamic>));
    } catch (_) {
      continue;
    }
  }
  return skins;
}

/// Decodes an image file. [maxWidth] shrinks wider images, keeping their shape.
Future<ui.Image> decodeImage(Uint8List bytes, {int? maxWidth}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final shrink = maxWidth != null && descriptor.width > maxWidth;
  final codec = await descriptor.instantiateCodec(targetWidth: shrink ? maxWidth : null, targetHeight: shrink ? (descriptor.height * maxWidth / descriptor.width).round() : null);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
  }
}

/// The file a slot reads: the skin's own `<slot>.png`, else the slot's shared file, else null.
File? slotFile(Directory skinsRoot, Directory skinDir, Slot slot) {
  final own = File(p.join(skinDir.path, slot.fileName));
  if (own.existsSync()) return own;
  final shared = slot.sharedFile;
  if (shared == null) return null;
  final file = File(p.join(skinsRoot.path, shared));
  return file.existsSync() ? file : null;
}

/// Loads every slot that has a readable file. Slots without one are left out and get their flat default.
Future<Map<String, ui.Image>> loadSkinImages(Directory skinsRoot, Directory skinDir, List<Slot> slots, {int? maxWidth}) async {
  final out = <String, ui.Image>{};
  for (final slot in slots) {
    final file = slotFile(skinsRoot, skinDir, slot);
    if (file == null) continue;
    try {
      out[slot.name] = await decodeImage(await file.readAsBytes(), maxWidth: maxWidth);
    } catch (_) {
      continue;
    }
  }
  return out;
}

/// An image the engine reads, such as the layout map or the wear sheet; null when missing.
Future<ui.Image?> loadEngineImage(Directory skinsRoot, String relative) async {
  final file = File(p.join(skinsRoot.path, relative));
  if (!file.existsSync()) return null;
  try {
    return await decodeImage(await file.readAsBytes());
  } catch (_) {
    return null;
  }
}
