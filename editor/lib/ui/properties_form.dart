import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../io/editor_controller.dart';
import '../model/shader_info.dart' show Param, ShaderInfo;
import '../model/skin.dart';
import 'family_dialog.dart';
import 'skin_dialogs.dart';
import 'form_parts.dart';
import 'widgets.dart';

/// The skin.json form: Item, Pattern placement (when the skin has pattern.png), Text colours and
/// A skin on a custom shader also gets that shader's numbers, from its annotations.
class PropertiesForm extends StatefulWidget {
  const PropertiesForm({super.key, required this.controller});

  final EditorController controller;

  @override
  State<PropertiesForm> createState() => _PropertiesFormState();
}

class _PropertiesFormState extends State<PropertiesForm> {
  final ScrollController _scroll = ScrollController();
  String? _shownSkin;

  EditorController get c => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Flutter on Linux moves a few pixels per wheel notch. One notch moves [Cfg.wheelStep] here.
  void _wheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scroll.hasClients) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      final dy = (e as PointerScrollEvent).scrollDelta.dy;
      final delta = dy.abs() >= Cfg.wheelNotchThreshold ? dy.sign * Cfg.wheelStep : dy;
      final pos = _scroll.position;
      _scroll.jumpTo((pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent));
    });
  }

  void _toggle(String group) {
    setState(() {
      final closed = c.settings.closedSections;
      if (!closed.remove(group)) closed.add(group);
    });
    c.settings.save();
  }

  /// A different skin starts at the top of the form.
  void _scrollToTopOnNewSkin() {
    if (c.selected == _shownSkin) return;
    _shownSkin = c.selected;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    _scrollToTopOnNewSkin();
    if (c.skin == null) return const Center(child: Text('No skin selected'));
    final custom = c.customInfo;
    final sections = <Widget>[
      _itemSection(),
      if (c.hasPattern) _patternSection(),
      _section('Text colours', textFields),
      if (custom != null) ...[
        for (final q in custom.placements) _placementSection(q),
        for (final g in custom.groups) _section('${custom.title}: $g', [for (final q in custom.inGroup(g)) fieldOf(q)]),
        if (custom.randoms.isNotEmpty) _randomSection(custom),
      ],
    ];
    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(right: Cfg.scrollbarGutter),
        children: [Listener(onPointerSignal: _wheel, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections))],
      ),
    );
  }

  Widget _frame(String title, List<Widget> rows, {String? note}) {
    final open = !c.settings.closedSections.contains(title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title, note: note, expanded: open, onToggle: () => _toggle(title)),
        if (open) ...rows,
      ],
    );
  }

  Widget _section(String title, List<SkinField> fields, {List<Widget> after = const []}) => _frame(title, [
        for (final f in fields) KeyedSubtree(key: ValueKey('${c.selected}/${f.path}'), child: _FieldRow(controller: c, field: f)),
        ...after,
      ]);

  /// The pattern's ranges, and where this seed put the card on the sheet.
  Widget _patternSection() {
    final w = c.scene?.draws.placements[patternKey];
    const muted = TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor);
    return _section('Pattern placement', patternFields, after: [
      if (w != null)
        FormRow(
          label: 'This seed',
          help: 'Where the seed put the card on the sheet.',
          child: Text('x ${w.x.toStringAsFixed(3)}   y ${w.y.toStringAsFixed(3)}   ${w.rotation.toStringAsFixed(1)}\u00b0', style: muted),
        ),
    ]);
  }

  Widget _placementSection(Param q) {
    final draws = c.scene?.draws.placements[q.key];
    final given = readPath(c.skin!, 'placements.${q.key}');
    final map = given is Map ? given : const {};
    String span(Object? v) => v is List && v.length == 2 ? '${_fmt(v[0] as num)} to ${_fmt(v[1] as num)}' : '-';
    Widget row(String label, String text) => FormRow(label: label, child: Text(text, style: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor)));
    return _frame('Placement: ${q.label}', [
      row('X', '${span(map['x'])}${draws == null ? '' : '   now ${draws.x.toStringAsFixed(3)}'}'),
      row('Y', '${span(map['y'])}${draws == null ? '' : '   now ${draws.y.toStringAsFixed(3)}'}'),
      row('Rotation', '${span(map['rotation'])}${draws == null ? '' : '   now ${draws.rotation.toStringAsFixed(2)}\u00b0'}'),
      row('Scale', '${map['scale'] ?? '-'}'),
    ]);
  }

  Widget _randomSection(ShaderInfo info) {
    final rows = <Widget>[];
    final draws = c.scene?.draws.random ?? const {};
    for (final q in info.randoms) {
      final given = readPath(c.skin!, 'random.${q.key}');
      final map = given is Map ? given : const {};
      for (final comp in randomComponents(q)) {
        final v = map[comp];
        final range = v is List && v.length == 2 ? '${_fmt(v[0] as num)} to ${_fmt(v[1] as num)}' : '-';
        rows.add(FormRow(label: '${q.label} $comp', help: q.help, child: Text(range, style: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor))));
      }
      final drawn = draws[q.key];
      if (drawn != null) {
        rows.add(FormRow(label: 'This seed', child: Text(drawn.map((e) => e.toStringAsFixed(2)).join(', '), style: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor))));
      }
    }
    return _frame('Random', rows);
  }

  Widget _itemSection() => _frame('Item', [
        for (final f in itemFields) KeyedSubtree(key: ValueKey('${c.selected}/${f.path}'), child: _FieldRow(controller: c, field: f)),
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
          child: Wrap(spacing: 6, runSpacing: 4, children: [
            OutlinedButton(onPressed: () => duplicateSkinDialog(context, c, c.skins.firstWhere((e) => e.folder == c.selected)), child: const Text('Duplicate skin\u2026')),
            OutlinedButton(onPressed: () => deleteSkinDialog(context, c, c.skins.firstWhere((e) => e.folder == c.selected)), child: const Text('Delete skin\u2026')),
            OutlinedButton(onPressed: () => applyToFamilyDialog(context, c), child: const Text('Apply to family\u2026')),
            if (c.familyUndoCount > 0) OutlinedButton(onPressed: c.undoFamilyApply, child: Text('Undo family apply (${c.familyUndoCount} skins)')),
          ]),
        ),
      ]);
}

String _fmt(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.expanded, required this.onToggle, this.note});

  final String title;
  final String? note;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: SizedBox(
        height: Cfg.sectionHeaderHeight,
        child: Row(children: [
          Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 18, color: Cfg.mutedColor),
          const SizedBox(width: 2),
          Text(title, style: const TextStyle(color: Cfg.accentColor, fontWeight: FontWeight.bold)),
          if (note != null) ...[const SizedBox(width: 8), Text(note!, style: const TextStyle(fontSize: Cfg.smallFontSize, color: Cfg.mutedColor))],
        ]),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.controller, required this.field});

  final EditorController controller;
  final SkinField field;

  @override
  Widget build(BuildContext context) {
    final f = field;
    if (f.kind == FieldKind.skinName) return _nameRow(f);
    final value = f.kind == FieldKind.skinKey ? controller.selected! : controller.valueOf(f);
    final label = f.label;
    Widget body;
    switch (f.kind) {
      case FieldKind.integer || FieldKind.number:
        final min = f.min ?? 0, max = f.max ?? 1;
        final decimals = f.kind == FieldKind.integer ? 0 : stepDecimals(f.step);
        body = max - min > Cfg.sliderMaxRange
            ? NumberBox(value: (value as num).toDouble(), decimals: decimals, suffix: f.unit, width: numberBoxWidth(min, max, decimals, suffix: f.unit != null), onChanged: (v) => controller.setField(f, v))
            : SliderRow(
                value: (value as num).toDouble(),
                min: min,
                max: max,
                decimals: decimals,
                suffix: f.unit,
                onChanged: (v) => controller.setField(f, v),
              );
      case FieldKind.numbers:
        final list = (value as List).map((e) => (e as num).toDouble()).toList();
        final dec = stepDecimals(f.step);
        body = Row(children: [
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: i < f.labels.length ? f.labels[i] : '${i + 1}',
                child: NumberBox(value: list[i], decimals: dec, width: numberBoxWidth(f.min ?? 0, f.max ?? 1, dec), onChanged: (v) => controller.setField(f, [...list]..[i] = v)),
              ),
            ),
        ]);
      case FieldKind.range:
        final r = (value as List).map((e) => (e as num).toDouble()).toList();
        final d = stepDecimals(f.step);
        final min = f.min ?? 0, max = f.max ?? 1;
        void set(double a, double b) => controller.setField(f, [a, b]);
        body = Row(children: [
          NumberBox(value: r[0], decimals: d, suffix: f.unit, width: numberBoxWidth(min, max, d, suffix: f.unit != null), onChanged: (v) => set(v, r[1] < v ? v : r[1])),
          Expanded(
            child: SliderTheme(
              data: compactSlider(context),
              child: RangeSlider(
                values: RangeValues(r[0].clamp(min, max), r[1].clamp(min, max)),
                min: min,
                max: max,
                onChanged: (v) => set(v.start, v.end),
              ),
            ),
          ),
          NumberBox(value: r[1], decimals: d, suffix: f.unit, width: numberBoxWidth(min, max, d, suffix: f.unit != null), onChanged: (v) => set(r[0] > v ? v : r[0], v)),
        ]);
      case FieldKind.boolean:
        body = Transform.scale(
          scale: 0.7,
          alignment: Alignment.centerLeft,
          child: Switch(
            value: value as bool,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => controller.setField(f, v),
          ),
        );
      case FieldKind.choice:
        body = FormDropdown(
          value: f.choices.contains(value) ? value as String : null,
          items: f.choices,
          onChanged: (v) => controller.setField(f, v),
        );
      case FieldKind.shader:
        body = FormDropdown(
          value: value as String,
          items: {...controller.shaders.names, value}.toList(),
          onChanged: (v) => controller.setField(f, v),
        );
      case FieldKind.color:
        body = HexField(value: value as String, onChanged: (v) => controller.setField(f, v));
      case FieldKind.palette:
        final colours = (value as List).cast<String>();
        body = Row(children: [
          for (var i = 0; i < colours.length; i++)
            _PaletteSwatch(
              hex: colours[i],
              label: i < f.labels.length ? f.labels[i] : null,
              onChanged: (v) => controller.setField(f, [...colours]..[i] = v),
            ),
        ]);
      case FieldKind.skinKey:
        body = Row(children: [
          Expanded(child: Text(value as String, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.mutedColor))),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, Cfg.formRowHeight - 4), padding: const EdgeInsets.symmetric(horizontal: 8)),
            onPressed: () => renameSkinDialog(context, controller, value),
            child: const Text('Rename…', style: TextStyle(fontSize: Cfg.labelFontSize)),
          ),
        ]);
      case FieldKind.skinName:
        body = const SizedBox.shrink();
      case FieldKind.text:
        body = FormTextBox(value: (value as String?) ?? '', onChanged: (v) => controller.setField(f, v));
    }
    return FormRow(label: label, help: f.help, child: body);
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.hex, required this.onChanged, this.label});

  final String hex;
  final String? label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: label == null ? hex : '$label  $hex',
        child: InkWell(
          onTap: () async {
            final result = await showDialog<String>(context: context, barrierDismissible: false, builder: (_) => _HexDialog(value: hex));
            if (result != null) onChanged(result);
          },
          child: Container(
            width: Cfg.formSwatchSize + 6,
            height: Cfg.formSwatchSize,
            decoration: BoxDecoration(color: parseHex(hex) ?? Colors.transparent, border: Border.all(color: Cfg.mutedColor)),
          ),
        ),
      ),
    );
  }
}

class _HexDialog extends StatefulWidget {
  const _HexDialog({required this.value});

  final String value;

  @override
  State<_HexDialog> createState() => _HexDialogState();
}

class _HexDialogState extends State<_HexDialog> {
  late String _hex = widget.value;

  @override
  Widget build(BuildContext context) {
    final valid = parseHex(_hex) != null;
    return AlertDialog(
      title: const Text('Colour'),
      content: SizedBox(
        width: Cfg.dialogWidth / 2,
        child: HexField(value: widget.value, onChanged: (v) => setState(() => _hex = v)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: valid ? () => Navigator.pop(context, _hex) : null, child: const Text('OK')),
      ],
    );
  }
}

extension on _FieldRow {
  Widget _nameRow(SkinField f) {
    final lang = f.path.split('.').last;
    final file = '$lang.json';
    final l10n = controller.l10n;
    if (!l10n.available) {
      if (lang != Cfg.l10nLanguages.first) return const SizedBox.shrink();
      return _L10nMissing(controller: controller);
    }
    final value = lang == 'en' ? controller.nameEn : controller.nameJa;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FormRow(
        label: f.label,
        help: f.help,
        child: FormTextBox(value: value, onChanged: (v) => controller.setName(lang, v)),
      ),
      if (value.isEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 20 + Cfg.formLabelWidth),
          child: Text('Missing in $file', style: const TextStyle(fontSize: Cfg.smallFontSize, color: Cfg.unsavedColor)),
        ),
    ]);
  }
}

class _L10nMissing extends StatelessWidget {
  const _L10nMissing({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final path = controller.l10n.folderPath;
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 3, bottom: 3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          path == null
              ? 'No project folder (pubspec.yaml) found above the skins folder, so the names cannot be saved.'
              : 'There is no l10n folder at $path, so the names cannot be saved.',
          style: const TextStyle(fontSize: Cfg.labelFontSize, color: Cfg.unsavedColor),
        ),
        if (path != null)
          TextButton(onPressed: controller.createL10nFiles, child: const Text('Create en.json and ja.json')),
      ]),
    );
  }
}

