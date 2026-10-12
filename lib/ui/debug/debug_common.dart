import 'package:flutter/material.dart';

import '../../config/design.dart';

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
