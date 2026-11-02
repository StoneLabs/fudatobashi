import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// [child], a play screen, with dev mode's scoring [readout] in room of its
/// own, above it in portrait and beside it in [landscape], so it never hides
/// a card. The readout scales down should it not fit.
class ReadoutFrame extends StatelessWidget {
  const ReadoutFrame({super.key, required this.readout, required this.landscape, required this.child});

  final Widget readout;
  final bool landscape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shown = Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.section, Gaps.small, Gaps.section, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.topLeft, child: readout),
      ),
    );
    return landscape
        ? Row(children: [
            SizedBox(width: AnkirenPlayLayout.readoutColumn, child: shown),
            Expanded(child: child),
          ])
        : Column(children: [
            SizedBox(height: AnkirenPlayLayout.readoutStrip, child: shown),
            Expanded(child: child),
          ]);
  }
}
