import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'seeded_random.dart';

/// A shadow with gloom lines (縦線) hanging in it ([spec]), come [reach]
/// of the way down from the top (0–1).
class GloomPainter extends CustomPainter {
  const GloomPainter(this.spec, this.reach);

  final GloomSpec spec;
  final double reach;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Rect.fromLTWH(0, 0, size.width, size.height * spec.reach * reach);
    canvas.drawRect(
      shade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: spec.colors,
        ).createShader(shade),
    );
    final r = SeededRandom(spec.seed);
    final lines = Path();
    for (var i = 0; i < spec.count; i++) {
      final x = r.next() * size.width;
      final length = size.height * (spec.shortest + r.next() * (spec.longest - spec.shortest)) * reach;
      final half = (spec.thinnest + r.next() * (spec.thickest - spec.thinnest)) / 2;
      lines
        ..moveTo(x - half, 0)
        ..lineTo(x + half, 0)
        ..lineTo(x, length)
        ..close();
    }
    canvas.drawPath(lines, Paint()..color = spec.line);
  }

  @override
  bool shouldRepaint(GloomPainter old) => old.spec != spec || old.reach != reach;
}
