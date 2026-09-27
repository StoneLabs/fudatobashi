import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import 'buttons.dart';
import 'pressable.dart';
import 'seeded_random.dart';

/// The spiky outline of a shout balloon.
@immutable
class ShoutSpec {
  const ShoutSpec({this.spikes = 28, this.outer = 8, this.inner = 3, this.roundness = 5, this.seed = 11});

  final int spikes;

  /// How far spikes reach out and notches cut in, px.
  final double outer, inner;

  /// Superellipse exponent: higher is boxier.
  final double roundness;
  final int seed;

  @override
  bool operator ==(Object other) =>
      other is ShoutSpec &&
      other.spikes == spikes &&
      other.outer == outer &&
      other.inner == inner &&
      other.roundness == roundness &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(spikes, outer, inner, roundness, seed);
}

/// Shout outlines, cached per spec and size.
abstract final class ShoutPath {
  static final _cache = <(ShoutSpec, Size), Path>{};

  static Path of(ShoutSpec spec, Size size) => _cache[(spec, size)] ??= _build(spec, size);

  static Path _build(ShoutSpec o, Size size) {
    final w = size.width, h = size.height;
    final r = SeededRandom(o.seed);
    final cx = w / 2, cy = h / 2;
    final rx = w / 2 - o.outer - ShoutStyle.edgeRoom, ry = h / 2 - o.outer - ShoutStyle.edgeRoom;
    final e = 2 / o.roundness;
    double pw(double v) => v.sign * math.pow(v.abs(), e);
    final pts = <Offset>[
      for (var i = 0; i <= ShoutStyle.samples; i++)
        () {
          final t = i / ShoutStyle.samples * math.pi * 2;
          return Offset(cx + rx * pw(math.cos(t)), cy + ry * pw(math.sin(t)));
        }(),
    ];
    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum[i - 1] + (pts[i] - pts[i - 1]).distance);
    }
    final perimeter = cum.last;
    final n = o.spikes * 2;
    final path = Path();
    var j = 0;
    for (var k = 0; k < n; k++) {
      final target = (k + r.next() * ShoutStyle.jitter) / n * perimeter;
      while (j < cum.length - 1 && cum[j] < target) {
        j++;
      }
      final p = pts[j];
      var nx = p.dx - cx, ny = (p.dy - cy) * (rx / ry);
      final l = math.sqrt(nx * nx + ny * ny);
      if (l > 0) {
        nx /= l;
        ny /= l;
      }
      final m = k.isEven
          ? o.outer * (ShoutStyle.outerMin + r.next() * ShoutStyle.outerRange)
          : -o.inner * (ShoutStyle.innerMin + r.next() * ShoutStyle.innerRange);
      final q = Offset(p.dx + nx * m, p.dy + ny * m);
      k == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    return path..close();
  }
}

/// Paints a shout balloon filling its box.
class ShoutPainter extends CustomPainter {
  const ShoutPainter(this.spec, {this.fill = Palette.pink, this.stroke = ShoutStyle.stroke});
  final ShoutSpec spec;
  final Color fill;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ShoutPath.of(spec, size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Palette.ink
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(ShoutPainter old) => old.spec != spec || old.fill != fill || old.stroke != stroke;
}

/// The big call to action: a spiky pink shout balloon with display lettering
/// and an arrow. Pressing it darkens the ink and squeezes the balloon.
class ShoutButton extends StatelessWidget {
  const ShoutButton({
    super.key,
    required this.label,
    required this.onTap,
    this.spec = const ShoutSpec(),
    this.color = Palette.pink,
    this.pressedColor = Palette.pinkDeep,
    this.fontSize = ShoutStyle.font,
    this.arrow = true,
  });

  final String label;
  final VoidCallback? onTap;
  final ShoutSpec spec;
  final Color color;
  final Color pressedColor;
  final double fontSize;
  final bool arrow;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      drop: 0,
      scale: Press.shoutScale,
      turn: Tilt.pressShout,
      semanticLabel: label,
      builder: (context, pressed) => CustomPaint(
        painter: ShoutPainter(
          spec,
          fill: pressed ? pressedColor : color,
          stroke: pressed ? ShoutStyle.strokePressed : ShoutStyle.stroke,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontFamily: Fonts.display,
                    fontSize: fontSize,
                    letterSpacing: ShoutStyle.tracking * fontSize,
                    color: Palette.ink,
                    height: 1,
                  ),
                ),
              ),
              if (arrow) ...[
                const SizedBox(width: ShoutStyle.gap),
                const MangaIcon(IconArt.arrow, size: ShoutStyle.icon, strokeWidth: ShoutStyle.iconStroke),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
