import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../config.dart';
import '../io/editor_controller.dart';
import '../io/l10n_store.dart';
import '../model/skin.dart' show tiers;

/// Asks what to do with unsaved edits of the open skin. True when it is fine to go on.
Future<bool> resolveUnsaved(BuildContext context, EditorController c, {String action = 'continue'}) async {
  if (!c.dirty) return true;
  final choice = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Unsaved changes'),
      content: Text('${c.selected} has unsaved changes. Save them before you $action?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, 'discard'), child: const Text('Discard')),
        FilledButton(onPressed: () => Navigator.pop(context, 'save'), child: const Text('Save')),
      ],
    ),
  );
  if (choice == 'save') await c.save();
  return choice != null && !c.dirty || choice == 'discard';
}

Future<void> newSkinDialog(BuildContext context, EditorController c) async {
  if (c.root == null || !await resolveUnsaved(context, c, action: 'add a skin') || !context.mounted) return;
  await showDialog<void>(context: context, builder: (_) => _NewSkinDialog(controller: c));
}

Future<void> duplicateSkinDialog(BuildContext context, EditorController c, SkinEntry e) async {
  if (c.root == null || !await resolveUnsaved(context, c, action: 'duplicate a skin') || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _SkinDialog(
      controller: c,
      title: 'Duplicate ${e.key}',
      confirm: 'Duplicate',
      keyText: '${e.folder}_copy',
      en: '${e.name} copy',
      ja: c.l10n.name('ja', e.folder) ?? '',
      run: (key, en, ja) => c.duplicateSkin(e.folder, key, en, ja),
    ),
  );
}

Future<void> renameSkinDialog(BuildContext context, EditorController c, String folder) async {
  if (c.root == null) return;
  if (c.selected == folder && !await resolveUnsaved(context, c, action: 'rename it') || !context.mounted) return;
  final keys = [for (final l in Cfg.l10nLanguages) '${L10nStore.keyFor(folder)} in $l.json'];
  await showDialog<void>(
    context: context,
    builder: (_) => _SkinDialog(
      controller: c,
      title: 'Rename $folder',
      confirm: 'Rename',
      keyText: folder,
      keyOnly: true,
      note: 'This changes the folder name, the key in skin.json and the l10n keys (${keys.join(', ')}).',
      run: (key, _, _) => c.renameSkin(folder, key),
    ),
  );
}

Future<void> deleteSkinDialog(BuildContext context, EditorController c, SkinEntry e) async {
  final path = p.join(c.root!.path, e.folder);
  final keys = c.l10n.available ? '${L10nStore.keyFor(e.folder)} in ${Cfg.l10nLanguages.map((l) => '$l.json').join(' and ')}' : 'none';
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Delete ${e.key}?'),
      content: SizedBox(
        width: Cfg.dialogWidth,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Folder: $path'),
          const SizedBox(height: 8),
          Text('L10n keys removed: $keys'),
          const SizedBox(height: 8),
          const Text('The folder is moved to the trash if possible, otherwise it is deleted.'),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ),
  );
  if (ok == true) await c.deleteSkin(e.folder);
}

typedef _Run = Future<String?> Function(String key, String en, String ja);

class _SkinDialog extends StatefulWidget {
  const _SkinDialog({
    required this.controller,
    required this.title,
    required this.confirm,
    required this.keyText,
    required this.run,
    this.en = '',
    this.ja = '',
    this.keyOnly = false,
    this.note,
  });

  final EditorController controller;
  final String title, confirm, keyText, en, ja;
  final bool keyOnly;
  final String? note;
  final _Run run;

  @override
  State<_SkinDialog> createState() => _SkinDialogState();
}

class _SkinDialogState extends State<_SkinDialog> {
  late final key = TextEditingController(text: widget.keyText);
  late final en = TextEditingController(text: widget.en);
  late final ja = TextEditingController(text: widget.ja);
  String? error;
  bool busy = false;

  @override
  void dispose() {
    key.dispose();
    en.dispose();
    ja.dispose();
    super.dispose();
  }

  String? get problem => key.text == widget.keyText && widget.keyOnly ? 'Enter a different key' : widget.controller.validateKey(key.text);

  Future<void> _submit() async {
    if (problem != null || busy) return;
    setState(() => busy = true);
    final result = await widget.run(key.text, en.text, ja.text);
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        busy = false;
        error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = key.text.isEmpty ? null : problem ?? error;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: Cfg.dialogWidth,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.note != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(widget.note!)),
          TextField(
            controller: key,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Key', errorText: shown),
            onChanged: (_) => setState(() => error = null),
            onSubmitted: (_) => _submit(),
          ),
          if (!widget.keyOnly) ...[
            TextField(controller: en, decoration: const InputDecoration(labelText: 'English name'), onSubmitted: (_) => _submit()),
            TextField(controller: ja, decoration: const InputDecoration(labelText: 'Japanese name (optional)'), onSubmitted: (_) => _submit()),
            if (!widget.controller.l10n.available)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('There is no l10n folder, so the names will not be saved.', style: TextStyle(color: Cfg.unsavedColor)),
              ),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: problem == null && !busy ? _submit : null, child: Text(widget.confirm)),
      ],
    );
  }
}

class _NewSkinDialog extends StatefulWidget {
  const _NewSkinDialog({required this.controller});

  final EditorController controller;

  @override
  State<_NewSkinDialog> createState() => _NewSkinDialogState();
}

class _NewSkinDialogState extends State<_NewSkinDialog> {
  final key = TextEditingController(), en = TextEditingController(), ja = TextEditingController();
  String shader = Cfg.standardShader, tier = Cfg.newSkinTier;
  String? error;
  bool busy = false;

  EditorController get c => widget.controller;

  @override
  void dispose() {
    key.dispose();
    en.dispose();
    ja.dispose();
    super.dispose();
  }

  String? get problem => c.validateKey(key.text);

  Future<void> _submit() async {
    if (problem != null || busy) return;
    setState(() => busy = true);
    final result = await c.createSkin(key.text, en.text, ja.text, tier, shader);
    if (!mounted) return;
    if (result == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        busy = false;
        error = result;
      });
    }
  }

  Widget _choice(String label, String value, List<String> items, ValueChanged<String> onChanged) => Row(children: [
        SizedBox(width: Cfg.dialogLabelWidth, child: Text(label)),
        DropdownButton<String>(
          value: value,
          items: [for (final t in items) DropdownMenuItem(value: t, child: Text(t))],
          onChanged: (v) => setState(() => onChanged(v ?? value)),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final shown = key.text.isEmpty ? null : problem ?? error;
    return AlertDialog(
      title: const Text('New skin'),
      content: SizedBox(
        width: Cfg.dialogWidth,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: key,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Key (folder name)', errorText: shown),
            onChanged: (_) => setState(() => error = null),
            onSubmitted: (_) => _submit(),
          ),
          TextField(controller: en, decoration: const InputDecoration(labelText: 'English name'), onSubmitted: (_) => _submit()),
          TextField(controller: ja, decoration: const InputDecoration(labelText: 'Japanese name'), onSubmitted: (_) => _submit()),
          const SizedBox(height: 8),
          _choice('Tier', tier, tiers, (v) => tier = v),
          _choice('Shader', shader, {Cfg.standardShader, ...c.shaders.names}.toList(), (v) => shader = v),
          const SizedBox(height: 8),
          const Text('The new folder has no images yet, so it looks like Vanilla. Put colour.png and the other files in it, or use Replace in the texture pane.',
              style: TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor)),
          if (!c.l10n.available)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('There is no l10n folder, so the names will not be saved.', style: TextStyle(color: Cfg.unsavedColor)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: problem == null && !busy ? _submit : null, child: const Text('Create')),
      ],
    );
  }
}
