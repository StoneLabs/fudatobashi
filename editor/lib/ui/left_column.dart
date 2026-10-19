import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import '../io/skin_textures.dart';
import '../render/thumbnail_cache.dart';
import 'lighting_panel.dart';
import 'shortcuts_sheet.dart';
import 'skin_dialogs.dart';
import 'texture_actions.dart';
import 'widgets.dart';

class LeftColumn extends StatelessWidget {
  const LeftColumn({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: Cfg.scrollbarGutter),
      child: Column(
        children: [
          _SkinsPanel(controller: controller),
          const SizedBox(height: Cfg.panelGap),
          _TexturesPanel(controller: controller),
          const SizedBox(height: Cfg.panelGap),
          LightingPanel(controller: controller),
        ],
      ),
    );
  }
}

Future<String?> _contextMenu(BuildContext context, Offset at, List<(String, String)> items) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(at & Size.zero, Offset.zero & overlay.size),
    items: [for (final (value, label) in items) PopupMenuItem(value: value, child: Text(label))],
  );
}

class _SkinsPanel extends StatefulWidget {
  const _SkinsPanel({required this.controller});

  final EditorController controller;

  @override
  State<_SkinsPanel> createState() => _SkinsPanelState();
}

class _SkinsPanelState extends State<_SkinsPanel> {
  final _filter = TextEditingController();
  final Set<String> _closedFamilies = {};

  EditorController get controller => widget.controller;

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _menu(BuildContext context, Offset at, SkinEntry e) async {
    final choice = await _contextMenu(context, at, const [
      ('new', 'New skin…'),
      ('duplicate', 'Duplicate…'),
      ('rename', 'Rename…'),
      ('delete', 'Delete…'),
    ]);
    if (!context.mounted) return;
    switch (choice) {
      case 'new':
        await newSkinDialog(context, controller);
      case 'duplicate':
        await duplicateSkinDialog(context, controller, e);
      case 'rename':
        await renameSkinDialog(context, controller, e.folder);
      case 'delete':
        await deleteSkinDialog(context, controller, e);
    }
  }

  Widget _row(BuildContext context, SkinEntry s, {double indent = 0}) {
    final selected = s.folder == controller.selected;
    return GestureDetector(
      onSecondaryTapDown: (d) => _menu(context, d.globalPosition, s),
      child: InkWell(
        onTap: () async {
          if (!selected && !await resolveUnsaved(context, controller, action: 'open another skin')) return;
          await controller.selectSkin(s.folder);
        },
        child: Container(
          height: Cfg.skinRowExtent,
          color: selected ? Cfg.chipSelectedColor : null,
          padding: EdgeInsets.only(left: indent, right: 8, top: 3, bottom: 3),
          child: Row(children: [
            Container(width: Cfg.tierStripWidth, color: Cfg.tierColors[s.tier] ?? Cfg.mutedColor),
            const SizedBox(width: 8),
            ThumbnailImage(cache: controller.thumbs, cacheKey: controller.skinThumbKey(s), width: Cfg.skinThumbWidth),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(s.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Cfg.smallFontSize, color: Cfg.mutedColor)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _familyHeader(String family, int count, bool open) => InkWell(
        onTap: () => setState(() => open ? _closedFamilies.add(family) : _closedFamilies.remove(family)),
        child: SizedBox(
          height: Cfg.familyHeaderHeight,
          child: Row(children: [
            Icon(open ? Icons.expand_more : Icons.chevron_right, size: Cfg.toolIconSize),
            const SizedBox(width: 4),
            Expanded(child: Text(family, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: Cfg.labelFontSize))),
            Text('$count', style: const TextStyle(fontSize: Cfg.smallFontSize, color: Cfg.mutedColor)),
          ]),
        ),
      );

  List<Widget> _rows(BuildContext context) {
    final q = _filter.text.trim().toLowerCase();
    bool matches(SkinEntry s) => q.isEmpty || [s.name, s.key, s.family].any((t) => t.toLowerCase().contains(q));
    final sizes = <String, int>{};
    for (final s in controller.skins) {
      if (s.family.isNotEmpty) sizes[s.family] = (sizes[s.family] ?? 0) + 1;
    }
    final out = <Widget>[];
    final done = <String>{};
    for (final s in controller.skins) {
      if ((sizes[s.family] ?? 0) < 2) {
        if (matches(s)) out.add(_row(context, s));
        continue;
      }
      if (!done.add(s.family)) continue;
      final members = controller.skins.where((m) => m.family == s.family && matches(m)).toList();
      if (members.isEmpty) continue;
      final open = q.isNotEmpty || !_closedFamilies.contains(s.family);
      out.add(_familyHeader(s.family, members.length, open));
      if (open) out.addAll([for (final m in members) _row(context, m, indent: Cfg.familyIndent)]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final open = controller.skins.where((s) => s.folder == controller.selected).firstOrNull;
    final rows = _rows(context);
    return Panel(
      title: 'Skins',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _IconAction(Icons.add, 'New skin', controller.root == null ? null : () => newSkinDialog(context, controller)),
        _IconAction(Icons.copy, 'Duplicate skin', open == null ? null : () => duplicateSkinDialog(context, controller, open)),
        _IconAction(Icons.drive_file_rename_outline, 'Rename skin', open == null ? null : () => renameSkinDialog(context, controller, open.folder)),
        _IconAction(Icons.delete_outline, 'Delete skin', open == null ? null : () => deleteSkinDialog(context, controller, open)),
        _IconAction(Icons.help_outline, 'Keyboard shortcuts (F1)', () => showShortcutsSheet(context)),
        _IconAction(Icons.folder_open, 'Choose the skins folder', () async {
          final path = await getDirectoryPath(initialDirectory: controller.root?.path);
          if (path == null || !context.mounted || !await resolveUnsaved(context, controller, action: 'change folder')) return;
          await controller.setFolder(path);
        }),
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(controller.root?.path ?? 'No folder chosen', style: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor)),
          const SizedBox(height: 6),
          SizedBox(
            height: Cfg.formRowHeight + 4,
            child: TextField(
              controller: _filter,
              style: const TextStyle(fontSize: Cfg.labelFontSize),
              decoration: compactDecoration.copyWith(
                hintText: 'Filter skins',
                prefixIcon: const Icon(Icons.search, size: Cfg.toolIconSize),
                suffixIcon: _filter.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: Cfg.toolIconSize),
                        tooltip: 'Clear the filter',
                        onPressed: () => setState(_filter.clear),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: Cfg.skinsListMaxHeight),
            child: rows.isEmpty
                ? const Padding(padding: EdgeInsets.all(8), child: Text('No skins match', style: TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor)))
                : ListView(shrinkWrap: true, children: rows),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction(this.icon, this.tooltip, this.onPressed);

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: Cfg.toolIconSize),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

class _TexturesPanel extends StatelessWidget {
  const _TexturesPanel({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Images',
      child: Column(
        children: [
          for (final s in controller.textures.states.values) _SlotRow(controller: controller, state: s),
        ],
      ),
    );
  }
}

enum _SlotAction { openEditor, showFolder, choose }

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.controller, required this.state});

  final EditorController controller;
  final SlotState state;

  void _run(BuildContext context, _SlotAction action) {
    final file = state.ownFile;
    switch (action) {
      case _SlotAction.openEditor:
        unawaited(Process.run('xdg-open', [file.path]));
      case _SlotAction.showFolder:
        unawaited(Process.run('xdg-open', [file.parent.path]));
      case _SlotAction.choose:
        unawaited(chooseTextureFile(context, controller, state.slot.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (word, color) = slotStatus(state);
    final img = state.image;
    final own = state.source == SlotSource.own;
    final size = img == null ? '' : '  ${img.width}\u00d7${img.height}';
    const small = TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor);
    return Tooltip(
      message: state.slot.help,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => controller.tabs.open(state.slot.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            SizedBox(
              width: Cfg.thumbSize,
              height: Cfg.thumbSize,
              child: ClipRect(
                child: Stack(fit: StackFit.expand, children: [
                  const CustomPaint(painter: CheckerPainter()),
                  if (img != null) RawImage(image: img, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(state.slot.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: Cfg.labelFontSize)),
                  const SizedBox(width: 8),
                  Text(word, style: TextStyle(fontSize: Cfg.labelFontSize, color: color)),
                ]),
                Text(own ? 'own file$size' : 'default: ${state.slot.defaultNote}', maxLines: 1, overflow: TextOverflow.ellipsis, style: small),
              ]),
            ),
            PopupMenuButton<_SlotAction>(
              icon: const Icon(Icons.more_horiz, size: Cfg.toolIconSize),
              tooltip: 'Image actions',
              padding: EdgeInsets.zero,
              iconSize: Cfg.toolIconSize,
              onSelected: (a) => _run(context, a),
              itemBuilder: (_) => [
                PopupMenuItem(value: _SlotAction.openEditor, enabled: own, child: const Text('Open in image editor')),
                const PopupMenuItem(value: _SlotAction.showFolder, child: Text('Show in folder')),
                PopupMenuItem(value: _SlotAction.choose, child: Text(own ? 'Replace\u2026' : 'Choose file\u2026')),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

/// A word for where the slot's image comes from, and its colour.
(String, Color) slotStatus(SlotState s) {
  if (s.loading) return ('loading', Cfg.accentColor);
  if (s.error != null) return ('error', Cfg.errorColor);
  return switch (s.source) {
    SlotSource.own => ('file', Cfg.okColor),
    SlotSource.shared => ('shared', Cfg.mutedColor),
    SlotSource.flat => ('default', Cfg.mutedColor),
  };
}
