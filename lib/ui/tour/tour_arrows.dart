import 'dart:math' as math;
import 'dart:ui' show PathMetric, lerpDouble;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../manga/seeded_random.dart';
import 'tour_layout.dart';

/// The arrow spam of one tour stop: [scribbles] stamping in one after
/// another and jabbing at the spot, boiling like hand-drawn animation, and
/// the [marquee] with its chasing bulbs and [label]. One painter, redrawn
/// each frame on its own layer; under reduced motion it is drawn once, at
/// rest.
class TourArrows extends StatefulWidget {
  const TourArrows({super.key, required this.scribbles, required this.marquee, required this.label});

  final List<Scribble> scribbles;
  final Marquee? marquee;
  final String label;

  @override
  State<TourArrows> createState() => _TourArrowsState();
}

class _TourArrowsState extends State<TourArrows> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed));
  Duration _elapsed = Duration.zero;
  bool _still = false;
  TextPainter? _label;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
    _layoutLabel();
  }

  @override
  void didUpdateWidget(TourArrows old) {
    super.didUpdateWidget(old);
    if (old.label != widget.label) _layoutLabel();
  }

  void _layoutLabel() {
    _label?.dispose();
    _label = TextPainter(
      text: TextSpan(
        text: widget.label,
        style: const TextStyle(fontFamily: Fonts.display, fontSize: TourStyle.marqueeFont, color: Palette.paper),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _label?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ArrowsPainter(
              scribbles: widget.scribbles,
              marquee: widget.marquee,
              label: _label!,
              seconds: _elapsed.inMicroseconds / 1e6,
              still: _still,
            ),
          ),
        ),
      );
}

class _ArrowsPainter extends CustomPainter {
  _ArrowsPainter({
    required this.scribbles,
    required this.marquee,
    required this.label,
    required this.seconds,
    required this.still,
  });

  final List<Scribble> scribbles;
  final Marquee? marquee;
  final TextPainter label;
  final double seconds;
  final bool still;

  static double _secs(Duration d) => d.inMicroseconds / 1e6;

  /// The marquee's outline, pointing along +x and centred on the origin,
  /// and its bulbs just inside it.
  static final Path _marquee = _arrowPath(0);
  static final List<Offset> _bulbs = _bulbSpots();

  static Path _arrowPath(double inset) {
    const l = TourStyle.marqueeLength / 2, head = TourStyle.marqueeHead;
    final hh = TourStyle.marqueeHeadHeight / 2 - inset, hb = TourStyle.marqueeBody / 2 - inset;
    // The tip moves in further than the sides, by the head's sharpness.
    final tipInset = inset / math.sin(math.atan2(TourStyle.marqueeHeadHeight / 2, head));
    final back = -l + inset, tip = l - tipInset, neck = l - head;
    return Path()
      ..moveTo(back, -hb)
      ..lineTo(neck, -hb)
      ..lineTo(neck, -hh)
      ..lineTo(tip, 0)
      ..lineTo(neck, hh)
      ..lineTo(neck, hb)
      ..lineTo(back, hb)
      ..close();
  }

  static List<Offset> _bulbSpots() {
    final spots = <Offset>[];
    for (final PathMetric m in _arrowPath(TourStyle.bulbInset).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += TourStyle.bulbPitch) {
        spots.add(m.getTangentForOffset(d)!.position);
      }
    }
    return spots;
  }

  int get _boilFrame => still ? 0 : (seconds / _secs(TourStyle.boil)).floor() % TourStyle.boilFrames;

  double _jab(int i) => still ? 0 : (1 - math.cos(2 * math.pi * seconds / _secs(TourStyle.jabPeriod) + i)) / 2;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (i, s) in scribbles.indexed) {
      final t = still ? 1.0 : ((seconds - _secs(TourStyle.scribbleStagger) * i) / _secs(TourStyle.scribbleIn)).clamp(0.0, 1.0);
      if (t > 0) _scribble(canvas, s, i, t);
    }
    if (marquee != null) _drawMarquee(canvas, marquee!);
  }

  void _scribble(Canvas canvas, Scribble s, int i, double appear) {
    final along = s.tip - s.tail;
    final dir = along / along.distance;
    final perp = Offset(-dir.dy, dir.dx);
    final r = SeededRandom(i * 31 + _boilFrame * 7 + 1);
    double wobble() => (r.next() * 2 - 1) * TourStyle.boilJitter;
    final bend = (SeededRandom(i + 101).next() * 2 - 1) * TourStyle.scribbleBend;
    final scale = lerpDouble(TourStyle.scribbleInFrom, 1, Curves.easeOut.transform(appear))!;
    canvas.save();
    final jab = dir * TourStyle.jab * _jab(i);
    canvas.translate(s.tip.dx + jab.dx, s.tip.dy + jab.dy);
    canvas.scale(scale);
    canvas.translate(-s.tip.dx, -s.tip.dy);
    final ink = Paint()
      ..color = TourStyle.scribbleInk.withValues(alpha: appear)
      ..style = PaintingStyle.stroke
      ..strokeWidth = TourStyle.scribbleWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final headTurn = TourStyle.scribbleHeadDeg * math.pi / 180;
    for (final pass in [-1.0, 1.0]) {
      final off = perp * pass * TourStyle.scribblePass;
      final from = s.tail + off + Offset(wobble(), wobble());
      final to = s.tip + off * 0.4 + Offset(wobble(), wobble());
      final mid = (from + to) / 2 + perp * bend;
      canvas.drawPath(Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy), ink);
      for (final side in [-1.0, 1.0]) {
        final back = Offset(
          -dir.dx * math.cos(headTurn) + side * dir.dy * math.sin(headTurn),
          -dir.dy * math.cos(headTurn) - side * dir.dx * math.sin(headTurn),
        );
        final end = to + back * (TourStyle.scribbleHead + wobble()) + Offset(wobble(), wobble());
        canvas.drawLine(to, end, ink);
      }
      ink.strokeWidth = TourStyle.scribbleWidthThin;
    }
    canvas.restore();
  }

  void _drawMarquee(Canvas canvas, Marquee m) {
    final dir = Offset(math.cos(m.angle), math.sin(m.angle));
    final at = m.center + dir * TourStyle.jab * _jab(0);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(m.angle);
    canvas.drawPath(_marquee, Paint()..color = TourStyle.marqueeFill);
    canvas.drawPath(
      _marquee,
      Paint()
        ..color = Palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = TourStyle.marqueeStroke
        ..strokeJoin = StrokeJoin.round,
    );
    final step = still ? 0 : (seconds / _secs(TourStyle.chase)).floor();
    final halo = Paint()..color = TourStyle.bulbHalo;
    final on = Paint()..color = TourStyle.bulbOn;
    final off = Paint()..color = TourStyle.bulbOff;
    for (final (i, b) in _bulbs.indexed) {
      final lit = (i + step) % TourStyle.chaseEvery == 0;
      if (lit) canvas.drawCircle(b, TourStyle.bulbGlow, halo);
      canvas.drawCircle(b, TourStyle.bulb, lit ? on : off);
    }
    // The label reads left to right whichever way the arrow points, and
    // only on an arrow near level.
    if (dir.dx.abs() >= math.cos(TourStyle.marqueeLabelMaxDeg * math.pi / 180)) {
      canvas.translate(-TourStyle.marqueeHead / 2, 0);
      if (dir.dx < 0) canvas.rotate(math.pi);
      label.paint(canvas, Offset(-label.width / 2, -label.height / 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArrowsPainter old) =>
      old.seconds != seconds || old.scribbles != scribbles || old.marquee != marquee || old.label != label;
}
