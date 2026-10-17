import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../history/history_widgets.dart';

/// A section heading in the run pages' marker style, as on Help and credits.
/// The marker is [MarkerHeadingStyle.color] unless the page gives its own
/// [color].
class MarkerHeading extends StatelessWidget {
  const MarkerHeading(this.title, this.sub, {super.key, this.color = MarkerHeadingStyle.color});

  final String title;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: HistoryHeading(
          title: title,
          sub: sub,
          accent: color,
          titleFont: MarkerHeadingStyle.titleFont,
          subFont: MarkerHeadingStyle.subFont,
        ),
      );
}
