import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../history/history_widgets.dart';

/// A section heading in the run pages' marker style, as on Help and credits.
/// The marker is [MarkerHeadingStyle.color] unless the page gives its own
/// [color]. When the other-language [sub] doesn't fit beside the title, it
/// takes a line and a marker of its own.
class MarkerHeading extends StatelessWidget {
  const MarkerHeading(this.title, this.sub, {super.key, this.color = MarkerHeadingStyle.color});

  final String title;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sub = this.sub;
    HistoryHeading heading(String title, String? sub, double font) => HistoryHeading(
          title: title,
          sub: sub,
          accent: color,
          titleFont: font,
          subFont: MarkerHeadingStyle.subFont,
        );
    if (sub == null) return Semantics(header: true, child: heading(title, null, MarkerHeadingStyle.titleFont));
    return Semantics(
      header: true,
      child: LayoutBuilder(builder: (context, constraints) {
        final style = DefaultTextStyle.of(context).style.copyWith(fontWeight: Weights.black);
        final line = TextPainter(
          text: TextSpan(style: style, children: [
            TextSpan(text: title, style: const TextStyle(fontSize: MarkerHeadingStyle.titleFont)),
            TextSpan(text: '  $sub', style: const TextStyle(fontSize: MarkerHeadingStyle.subFont)),
          ]),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final fits = line.width + HistoryRunStyle.titleMarkReach <= constraints.maxWidth;
        line.dispose();
        if (fits) return heading(title, sub, MarkerHeadingStyle.titleFont);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          heading(title, null, MarkerHeadingStyle.titleFont),
          const SizedBox(height: MarkerHeadingStyle.subLineGap),
          heading(sub, null, MarkerHeadingStyle.subFont),
        ]);
      }),
    );
  }
}
