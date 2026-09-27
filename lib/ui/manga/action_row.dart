import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'buttons.dart';
import 'vector.dart';

/// A row action button: an icon, a bold label and a small caption
/// underneath (e.g. ひとつ前 / UNDO). Used for the play chrome and results.
class ActionRowButton extends StatelessWidget {
  const ActionRowButton({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.color = Palette.paper,
    this.textColor = Palette.ink,
  });

  final VectorArt icon;
  final String label;
  final String sub;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => InkButton(
        onTap: onTap,
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: ButtonMetrics.rowPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MangaIcon(icon, size: ButtonMetrics.rowIcon, color: textColor),
            const SizedBox(width: ButtonMetrics.rowGap),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button, color: textColor)),
                Text(sub,
                    style: TextStyle(
                        fontWeight: Weights.black,
                        fontSize: TypeScale.tiny,
                        letterSpacing: TagStyle.tracking * TypeScale.tiny,
                        color: textColor)),
              ],
            ),
          ],
        ),
      );
}
