import 'package:flutter/material.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import '../render/skin_view.dart';
import 'properties_form.dart';
import 'widgets.dart';

class RightColumn extends StatelessWidget {
  const RightColumn({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final scene = controller.scene;
    return Column(
      children: [
        SizedBox(
          height: Cfg.cornersHeight,
          child: Panel(
            title: 'Corners',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final z in Cfg.cornerZooms)
                Padding(
                  padding: const EdgeInsets.only(left: Cfg.chipGap),
                  child: PickChip(
                    width: Cfg.zoomChipWidth,
                    label: '$z\u00d7',
                    selected: controller.settings.cornerZoom == z,
                    onTap: () => controller.setCornerZoom(z),
                  ),
                ),
            ]),
            child: Expanded(
              child: scene == null ? const SizedBox.shrink() : CornersView(scene: scene, zoom: controller.settings.cornerZoom),
            ),
          ),
        ),
        const SizedBox(height: Cfg.panelGap),
        Expanded(
          child: Panel(
            title: 'Properties',
            child: Expanded(
              child: Column(
                children: [
                  if (controller.diskChange != null) _DiskChangeBar(controller: controller),
                  Expanded(child: PropertiesForm(controller: controller)),
                  const SizedBox(height: 6),
                  _SaveBar(controller: controller),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiskChangeBar extends StatelessWidget {
  const _DiskChangeBar({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x33F0B45A),
      padding: const EdgeInsets.all(6),
      child: Row(children: [
        const Expanded(child: Text('skin.json changed on disk', style: TextStyle(fontSize: Cfg.labelFontSize))),
        TextButton(onPressed: controller.loadFromDisk, child: const Text('Load from disk')),
        TextButton(onPressed: controller.keepMine, child: const Text('Keep mine')),
      ]),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.controller});

  final EditorController controller;

  Future<void> _revert(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revert to the saved file?'),
        content: const Text('Your unsaved changes are removed. Undo brings them back.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Revert')),
        ],
      ),
    );
    if (ok == true) controller.revert();
  }

  @override
  Widget build(BuildContext context) {
    final open = controller.skin != null;
    return Row(children: [
      if (controller.dirty) ...[
        const Icon(Icons.circle, size: Cfg.tierDotSize, color: Cfg.unsavedColor),
        const SizedBox(width: 6),
        const Text('Unsaved', style: TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.unsavedColor)),
      ],
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.settings_backup_restore, size: Cfg.toolIconSize),
        tooltip: 'Revert to the saved file',
        onPressed: open && controller.dirty ? () => _revert(context) : null,
      ),
      IconButton(
        icon: const Icon(Icons.undo, size: Cfg.toolIconSize),
        tooltip: 'Undo (Ctrl+Z)',
        onPressed: controller.canUndo ? controller.undo : null,
      ),
      IconButton(
        icon: const Icon(Icons.redo, size: Cfg.toolIconSize),
        tooltip: 'Redo (Ctrl+Shift+Z or Ctrl+Y)',
        onPressed: controller.canRedo ? controller.redo : null,
      ),
      const SizedBox(width: 4),
      Tooltip(
        message: 'Save (Ctrl+S)',
        child: FilledButton(onPressed: open ? controller.save : null, child: const Text('Save')),
      ),
    ]);
  }
}
