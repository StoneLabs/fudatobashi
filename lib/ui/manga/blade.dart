import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// [child] cut in two along a blade ([spec]), [progress] of the way apart:
/// whole at 0, then the halves sliding apart along the cut and away from
/// it, turning and fading, gone at 1.
class BladeSplit extends StatelessWidget {
  const BladeSplit(this.spec, {super.key, required this.progress, required this.child});

  final BladeSpec spec;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    if (t <= 0) return child;
    if (t >= 1) return const SizedBox.shrink();
    final (along, across) = spec.axes;
    final fade = ((t - spec.fadeFrom) / (1 - spec.fadeFrom)).clamp(0.0, 1.0);
    return Opacity(
      opacity: 1 - fade,
      child: Stack(fit: StackFit.expand, children: [
        for (final side in [-1.0, 1.0])
          Transform.translate(
            offset: (along * spec.slide + across * spec.gap) * side * t,
            child: Transform.rotate(
              angle: side * t * spec.turnDeg * math.pi / 180,
              child: ClipPath(clipper: _HalfClipper(spec, side), child: child),
            ),
          ),
      ]),
    );
  }
}

/// The box on one [side] of the blade's line: -1 above it, 1 below.
class _HalfClipper extends CustomClipper<Path> {
  const _HalfClipper(this.spec, this.side);
  final BladeSpec spec;
  final double side;

  @override
  Path getClip(Size size) {
    final (along, across) = spec.axes;
    final reach = size.longestSide * 2;
    final from = spec.from - along * reach;
    final to = spec.to + along * reach;
    final away = across * reach * side;
    return Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy)
      ..lineTo(to.dx + away.dx, to.dy + away.dy)
      ..lineTo(from.dx + away.dx, from.dy + away.dy)
      ..close();
  }

  @override
  bool shouldReclip(_HalfClipper old) => old.spec != spec || old.side != side;
}

/// The blade's streak ([spec]), [drawn] of the way from its start: a paper
/// lens with an ink edge round a sun core, widest toward its head.
class BladePainter extends CustomPainter {
  const BladePainter(this.spec, this.drawn);
  final BladeSpec spec;
  final double drawn;

  @override
  void paint(Canvas canvas, Size size) {
    final from = spec.from;
    final head = Offset.lerp(from, spec.to, drawn)!;
    final widest = Offset.lerp(from, head, spec.widest)!;
    final (_, across) = spec.axes;
    Path lens(double width) {
      final bulge = across * width;
      return Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(widest.dx + bulge.dx, widest.dy + bulge.dy, head.dx, head.dy)
        ..quadraticBezierTo(widest.dx - bulge.dx, widest.dy - bulge.dy, from.dx, from.dy)
        ..close();
    }

    final blade = lens(spec.width);
    canvas
      ..drawPath(
          blade,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = spec.outline
            ..strokeJoin = StrokeJoin.round
            ..color = Palette.ink)
      ..drawPath(blade, Paint()..color = Palette.paper)
      ..drawPath(lens(spec.width * spec.core), Paint()..color = Palette.sun);
  }

  @override
  bool shouldRepaint(BladePainter old) => old.spec != spec || old.drawn != drawn;
}
