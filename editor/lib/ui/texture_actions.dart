import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import '../io/editor_controller.dart';

/// Opens a file dialog and makes the chosen image the skin's file for [slot].
Future<void> chooseTextureFile(BuildContext context, EditorController c, String slot) async {
  final dir = c.skinDir;
  if (dir == null) return;
  final picked = await openFile(
    acceptedTypeGroups: [XTypeGroup(label: 'Images', extensions: Cfg.imageExtensions)],
    initialDirectory: dir.path,
  );
  if (picked == null || !context.mounted) return;
  await useTexturePath(context, c, slot, picked.path);
}

/// Makes the image at [path] the skin's `<slot>.png`, after asking when that replaces a file.
Future<void> useTexturePath(BuildContext context, EditorController c, String slot, String path) async {
  final dir = c.skinDir;
  if (dir == null) return;
  final source = File(path.trim());
  if (!source.existsSync()) {
    c.setStatus('There is no file at ${source.path}', error: true);
    return;
  }
  if (!Cfg.imageExtensions.contains(p.extension(source.path).replaceFirst('.', '').toLowerCase())) {
    c.setStatus('${p.basename(source.path)} is not an image (${Cfg.imageExtensions.join(', ')})', error: true);
    return;
  }
  final target = File(p.join(dir.path, '$slot${Cfg.imageSuffix}'));
  final same = p.equals(p.normalize(source.absolute.path), p.normalize(target.absolute.path));
  if (!same && target.existsSync()) {
    final ok = await _confirm(context, 'Replace $slot${Cfg.imageSuffix}?', 'The skin already has $slot${Cfg.imageSuffix}. It goes to the trash and ${p.basename(source.path)} takes its place.', 'Replace');
    if (!ok) return;
  }
  await c.setSlotFile(slot, source);
}

/// Asks, then moves the skin's `<slot>.png` to the trash so the slot uses its default.
Future<void> clearTextureFile(BuildContext context, EditorController c, String slot) async {
  final ok = await _confirm(context, 'Clear $slot${Cfg.imageSuffix}?', 'The file goes to the trash and the skin uses the default for $slot.', 'Clear');
  if (ok) await c.clearSlotFile(slot);
}

Future<bool> _confirm(BuildContext context, String title, String text, String action) async {
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: Cfg.dialogWidth, child: Text(text)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return ok == true;
}
