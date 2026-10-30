import 'package:flutter/widgets.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'figure_layout.dart';

/// A picture in a desk-grey panel with a hard shadow, the shadow inside
/// the picture's own width.
class FigurePanel extends StatelessWidget {
  const FigurePanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: GuideLayout.shadowRoom, bottom: GuideLayout.shadowRoom),
        child: MangaPanel(
          color: Palette.desk,
          shadow: const Offset(GuideLayout.shadowRoom, GuideLayout.shadowRoom),
          padding: FigureFile.panelPadding,
          child: child,
        ),
      );
}
