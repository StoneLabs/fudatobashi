import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'seeded_random.dart';

/// Focus lines (集中線): wedges converging on a point. The geometry depends on
/// the spec and the box size and is cached per pair.
abstract final class FocusLines {
  static final _cache = <(BurstSpec, Size), Path>{};

  static Path path(BurstSpec spec, Size size) => _cache[(spec, size)] ??= _build(spec, size);

  static Path _build(BurstSpec o, Size size) {
    final cx = o.center.dx * size.width / o.box.width;
    final cy = o.center.dy * size.height / o.box.height;
    final r = SeededRandom(o.seed);
    final reach = [
          Offset(cx, cy),
          Offset(size.width - cx, cy),
          Offset(cx, size.height - cy),
          Offset(size.width - cx, size.height - cy),
        ].map((d) => d.distance).reduce(math.max) +
        LineStyle.focusOverreach;
    final path = Path();
    final step = math.pi * 2 / o.count;
    for (var i = 0; i < o.count; i++) {
      final a = i * step + (r.next() - 0.5) * step * LineStyle.focusJitter;
      final r0 = o.innerMin +
          r.next() *
              (o.innerMax - o.innerMin) *
              (r.next() < LineStyle.focusLongChance ? LineStyle.focusLongFactor : 1);
      final hw = (LineStyle.focusBaseWidth + r.next() * o.width * (r.next() < LineStyle.focusThickChance ? 2 : 1)) /
          reach;
      path
        ..moveTo(cx + math.cos(a) * r0, cy + math.sin(a) * r0)
        ..lineTo(cx + math.cos(a - hw) * reach, cy + math.sin(a - hw) * reach)
        ..lineTo(cx + math.cos(a + hw) * reach, cy + math.sin(a + hw) * reach)
        ..close();
    }
    return path;
  }
}

/// Horizontal speed lines.
abstract final class SpeedLines {
  static final _cache = <(SpeedLinesSpec, Size), Path>{};

  static Path path(SpeedLinesSpec spec, Size size) => _cache[(spec, size)] ??= _build(spec, size);

  static Path _build(SpeedLinesSpec o, Size size) {
    final w = size.width, h = size.height;
    final r = SeededRandom(o.seed);
    final path = Path();
    for (var i = 0; i < o.count; i++) {
      final y = r.next() * h;
      final len = w * (LineStyle.speedMinLength + r.next() * (1 - LineStyle.speedMinLength));
      final th = LineStyle.speedMinThickness + r.next() * LineStyle.speedThicknessRange;
      if (o.fromEdge) {
        path
          ..moveTo(w - len, y)
          ..lineTo(w, y - th)
          ..lineTo(w, y + th)
          ..close();
      } else {
        final x0 = w - len * (LineStyle.streakStartMin + r.next() * LineStyle.streakStartRange);
        final x1 = x0 - len * LineStyle.streakSpan;
        path
          ..moveTo(x0, y)
          ..lineTo(x1, y - th)
          ..lineTo(x1 - LineStyle.speedTaper, y + th)
          ..close();
      }
    }
    return path;
  }
}

/// Paints a focus-line burst filling its box.
class FocusLinesPainter extends CustomPainter {
  const FocusLinesPainter(this.spec);
  final BurstSpec spec;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(FocusLines.path(spec, size), Paint()..color = spec.color);

  @override
  bool shouldRepaint(FocusLinesPainter old) => old.spec != spec;
}

/// Paints speed lines filling its box.
class SpeedLinesPainter extends CustomPainter {
  const SpeedLinesPainter(this.spec);
  final SpeedLinesSpec spec;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(SpeedLines.path(spec, size), Paint()..color = spec.color);

  @override
  bool shouldRepaint(SpeedLinesPainter old) => old.spec != spec;
}
