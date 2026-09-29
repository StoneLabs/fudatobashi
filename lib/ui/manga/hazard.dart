import 'dart:ui';

import '../../config/design.dart';

/// Sun and ink hazard stripes (the yellow-and-black of warning tape) at 45°
/// across [area], each [stripe] px wide, slid along by [shift] px so they
/// can march. Paints the whole rect: clip to the shape first.
void paintHazardStripes(Canvas canvas, Rect area, {required double stripe, double shift = 0}) {
  canvas.drawRect(area, Paint()..color = Palette.sun);
  final rise = area.height;
  final stripes = Path();
  for (var x = area.left - rise - 2 * stripe + shift % (2 * stripe); x < area.right; x += 2 * stripe) {
    stripes
      ..moveTo(x, area.bottom)
      ..lineTo(x + rise, area.top)
      ..lineTo(x + rise + stripe, area.top)
      ..lineTo(x + stripe, area.bottom)
      ..close();
  }
  canvas.drawPath(stripes, Paint()..color = Palette.ink);
}
