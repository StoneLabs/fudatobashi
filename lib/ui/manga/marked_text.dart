import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// One line of [text] with its first [marked] characters marked as found: a
/// marker behind their lower part (see [TextMarkStyle]). Cut short with an
/// ellipsis when it doesn't fit.
class MarkedText extends StatelessWidget {
  const MarkedText(this.text, {super.key, required this.style, this.marked = 0});

  final String text;
  final TextStyle style;
  final int marked;

  @override
  Widget build(BuildContext context) {
    final span = TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style));
    final scaler = MediaQuery.textScalerOf(context);
    final label = Text.rich(span, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, textScaler: scaler);
    if (marked <= 0) return label;
    return CustomPaint(
      painter: _MarkPainter(span, marked.clamp(0, text.length), scaler, Directionality.of(context)),
      child: label,
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.span, this.marked, this.scaler, this.direction);

  final TextSpan span;
  final int marked;
  final TextScaler scaler;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final text = TextPainter(text: span, textDirection: direction, textScaler: scaler, maxLines: 1, ellipsis: '…')
      ..layout(maxWidth: size.width);
    final paint = Paint()..color = TextMarkStyle.color;
    for (final box in text.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: marked))) {
      final height = box.bottom - box.top;
      canvas.drawRect(
        Rect.fromLTRB(box.left - TextMarkStyle.reach, box.top + height * TextMarkStyle.top,
            box.right + TextMarkStyle.reach, box.top + height * TextMarkStyle.bottom),
        paint,
      );
    }
    text.dispose();
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.span != span || old.marked != marked || old.scaler != scaler || old.direction != direction;
}
