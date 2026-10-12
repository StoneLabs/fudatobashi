import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_level.dart';

const debugMono = TextStyle(fontFamily: 'monospace', fontSize: 12, fontFeatures: [FontFeature.tabularFigures()]);

/// A key and its value on one line.
class DebugKV extends StatelessWidget {
  const DebugKV(this.k, this.v, {super.key});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 170,
          child: Text(k, style: debugMono.copyWith(color: Colors.grey)),
        ),
        Expanded(child: SelectableText(v, style: debugMono)),
      ],
    ),
  );
}

/// A developer sub-page: the app bar and the safe area every debug page shares.
class DebugScaffold extends StatelessWidget {
  const DebugScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.paper,
    appBar: AppBar(
      backgroundColor: Palette.paper,
      foregroundColor: Palette.ink,
      title: Text(
        title,
        style: const TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular),
      ),
    ),
    body: SafeArea(child: child),
  );
}

/// A labelled slider.
class DebugSlider extends StatelessWidget {
  const DebugSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: debugMono),
      Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
    ],
  );
}

/// One chip per 暗記練 level.
class DebugLevelChips extends StatelessWidget {
  const DebugLevelChips({super.key, required this.level, required this.onChanged});

  final int level;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AnkirenToolsStyle.gap,
    children: [
      for (var l = 0; l <= AnkirenLevels.top; l++)
        ChoiceChip(
          label: Text('$l', style: debugMono),
          selected: l == level,
          onSelected: (_) => onChanged(l),
        ),
    ],
  );
}
