import 'package:flutter/material.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import 'skin_dialogs.dart';

/// Asks which parts of the open skin to copy to the other skins of its family, then does it.
Future<void> applyToFamilyDialog(BuildContext context, EditorController c) async {
  if (c.skin == null) return;
  if (c.familyMates.isEmpty) {
    c.setStatus('This skin has no family mates. Give skins the same family name in the Item section first.', error: true);
    return;
  }
  if (!await resolveUnsaved(context, c, action: 'copy it to the family') || !context.mounted) return;
  await showDialog<void>(context: context, builder: (_) => _FamilyDialog(controller: c));
}

class _FamilyDialog extends StatefulWidget {
  const _FamilyDialog({required this.controller});

  final EditorController controller;

  @override
  State<_FamilyDialog> createState() => _FamilyDialogState();
}

class _FamilyDialogState extends State<_FamilyDialog> {
  final what = FamilyCopy();
  bool busy = false;

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        value: value,
        title: Text(label),
        onChanged: (v) => setState(() => onChanged(v ?? false)),
      );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return AlertDialog(
      title: const Text('Apply to family'),
      content: SizedBox(
        width: Cfg.dialogWidth,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Copies from ${c.selected} to ${c.familyMates.length} other skins: ${c.familyMates.join(', ')}. They are saved at once. Image files are not copied.'),
          const SizedBox(height: 8),
          _check('Text colours', what.text, (v) => what.text = v),
          _check('Pattern placement', what.pattern, (v) => what.pattern = v),
          _check('Float range', what.float, (v) => what.float = v),
          if (c.customInfo != null) _check('${c.shaderName} numbers (skins on the same shader only)', what.values, (v) => what.values = v),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  setState(() => busy = true);
                  await c.applyToFamily(what);
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Apply and save'),
        ),
      ],
    );
  }
}
