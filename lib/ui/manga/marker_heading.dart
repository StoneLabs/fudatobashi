import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../history/history_widgets.dart';

/// A section heading in the run pages' marker style, as on Help and credits.
class MarkerHeading extends StatelessWidget {
  const MarkerHeading(this.title, this.sub, {super.key});

  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: HistoryHeading(
          title: title,
          sub: sub,
          accent: MarkerHeadingStyle.color,
          titleFont: MarkerHeadingStyle.titleFont,
          subFont: MarkerHeadingStyle.subFont,
        ),
      );
}
