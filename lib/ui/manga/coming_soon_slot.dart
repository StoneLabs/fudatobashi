import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'labels.dart';
import 'phrases.dart';

/// Room kept for something still to come: [line] centred in a dashed slot.
class ComingSoonSlot extends StatelessWidget {
  const ComingSoonSlot(this.line, {super.key});

  final String line;

  @override
  Widget build(BuildContext context) => DashedBox(
        color: ComingSoonStyle.fill,
        border: ComingSoonStyle.border,
        padding: ComingSoonStyle.padding,
        child: Text.rich(
          Phrases.span(line),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: Weights.black,
            fontSize: ComingSoonStyle.font,
            letterSpacing: ComingSoonStyle.font * ComingSoonStyle.tracking,
            height: ComingSoonStyle.lineHeight,
            color: Palette.inkSoft,
          ),
        ),
      );
}
