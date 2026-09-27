import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'time_format.dart';

/// The previous card's kimariji as a speech chip: yellow, blue once marked
/// wrong, 「開始」 with no time before the first card. Tapping toggles the
/// previous card wrong. Bumps briefly whenever its content changes.
class KimarijiChip extends StatefulWidget {
  const KimarijiChip({super.key, required this.text, this.timeMs, required this.wrong, this.onTap});

  final String text;
  final double? timeMs;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  State<KimarijiChip> createState() => _KimarijiChipState();
}

class _KimarijiChipState extends State<KimarijiChip> with SingleTickerProviderStateMixin {
  late final _bump = AnimationController(vsync: this, duration: PlayLayout.chipBumpDuration);

  @override
  void didUpdateWidget(KimarijiChip old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.wrong != widget.wrong || old.timeMs != widget.timeMs) _bump.forward(from: 0);
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.wrong ? Palette.sea : Palette.sun;
    final textColor = widget.wrong ? Palette.paper : Palette.ink;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bump,
        builder: (context, child) {
          final e = Curves.easeOut.transform(1 - _bump.value);
          final scale = 1 + (PlayLayout.chipBumpScale - 1) * e;
          return Transform.scale(alignment: Alignment.centerLeft, scale: scale, child: child);
        },
        child: CustomPaint(
          painter: _ChipPainter(color),
          child: SizedBox(
            height: PlayLayout.chipHeight,
            child: Padding(
              padding: PlayLayout.chipPadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '「',
                          style: TextStyle(
                              fontFamily: Fonts.ui,
                              fontWeight: Weights.medium,
                              fontSize: PlayLayout.chipBracketFont,
                              color: textColor,
                              height: 1)),
                      TextSpan(
                          text: widget.text,
                          style: TextStyle(fontFamily: Fonts.display, fontSize: PlayLayout.chipKanaFont, color: textColor, height: 1)),
                      TextSpan(
                          text: '」',
                          style: TextStyle(
                              fontFamily: Fonts.ui,
                              fontWeight: Weights.medium,
                              fontSize: PlayLayout.chipBracketFont,
                              color: textColor,
                              height: 1)),
                    ]),
                  ),
                  if (widget.timeMs != null) ...[
                    const SizedBox(width: PlayLayout.chipGap),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: formatChipSeconds(widget.timeMs!),
                          style: TextStyle(
                              fontFamily: Fonts.display, fontSize: PlayLayout.chipTimeFont, color: textColor, height: 1)),
                      TextSpan(
                          text: 's',
                          style: TextStyle(
                              fontFamily: Fonts.display,
                              fontSize: PlayLayout.chipTimeUnitFont,
                              color: textColor,
                              height: 1)),
                    ])),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPainter extends CustomPainter {
  _ChipPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(PlayLayout.chipRadius));
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.control
        ..color = Palette.ink,
    );
    // The tail: a small rotated square, its top-left border forming the point.
    canvas.save();
    canvas.translate(PlayLayout.chipTailAt.dx, size.height - Strokes.control / 2);
    canvas.rotate(45 * math.pi / 180);
    final t = PlayLayout.chipTail;
    final box = Rect.fromLTWH(-t.width / 2, -t.height / 2, t.width, t.height);
    canvas.drawRect(box, Paint()..color = color);
    final e = Strokes.control / 2;
    canvas.drawPath(
      Path()
        ..moveTo(box.left, box.bottom - e)
        ..lineTo(box.right - e, box.bottom - e)
        ..lineTo(box.right - e, box.top),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.control
        ..strokeJoin = StrokeJoin.miter
        ..color = Palette.ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChipPainter old) => old.color != color;
}
