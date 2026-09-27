import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// An oval speech balloon with a tail. [tail] places the tail's root in the
/// box (-1..1 on each axis); [tailTurn] rotates it, degrees, so the point
/// faces the speaker (45° points straight down).
class SpeechBalloon extends StatelessWidget {
  const SpeechBalloon({
    super.key,
    required this.child,
    this.tail = const Alignment(0, 1),
    this.tailTurn = BalloonStyle.tailDown,
    this.padding = EdgeInsets.zero,
    this.color = Palette.paper,
    this.border = Strokes.control,
  });

  final Widget child;
  final Alignment tail;
  final double tailTurn;
  final EdgeInsets padding;
  final Color color;
  final double border;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BalloonPainter(tail, tailTurn, color, border),
      child: Padding(
        padding: padding,
        child: Center(
          child: DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: Weights.black, height: BalloonStyle.lineHeight, color: Palette.ink),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BalloonPainter extends CustomPainter {
  _BalloonPainter(this.tail, this.turn, this.color, this.border);
  final Alignment tail;
  final double turn;
  final Color color;
  final double border;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = (Offset.zero & size).deflate(border / 2);
    final fill = Paint()..color = color;
    final ink = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = border;
    canvas.drawOval(oval, fill);
    canvas.drawOval(oval, ink);

    // A small square whose bottom and right borders form the point, as in
    // the spec's CSS; its fill hides the oval's outline where they overlap.
    const t = BalloonStyle.tail;
    const skew = BalloonStyle.tailSkew * math.pi / 180;
    canvas.save();
    final root = tail.withinRect(Offset.zero & size);
    canvas.translate(root.dx, root.dy - BalloonStyle.tailLift);
    canvas.rotate(turn * math.pi / 180);
    canvas.transform(Matrix4.skew(skew, skew).storage);
    const box = Rect.fromLTWH(-t / 2, -t / 2, t, t);
    canvas.drawRect(box, fill);
    final e = border / 2;
    canvas.drawPath(
      Path()
        ..moveTo(box.left, box.bottom - e)
        ..lineTo(box.right - e, box.bottom - e)
        ..lineTo(box.right - e, box.top),
      ink..strokeJoin = StrokeJoin.miter,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BalloonPainter old) =>
      old.tail != tail || old.turn != turn || old.color != color || old.border != border;
}
