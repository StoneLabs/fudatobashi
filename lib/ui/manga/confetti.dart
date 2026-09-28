import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'seeded_random.dart';

/// Confetti raining down on loop (the island-complete page), laid out in the
/// spec's 390 px wide box and scaled to the actual width. Under reduced
/// motion the pieces hang still mid-fall.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({super.key});

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) => _time.value = elapsed.inMicroseconds / 1e6);
  final _time = ValueNotifier<double>(Confetti.maxDelay);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ClipRect(child: CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_time))),
      );
}

class _Piece {
  _Piece(this.left, this.color, this.drift, this.duration, this.delay, this.turns, this.size, this.round);
  final double left;
  final Color color;
  final double drift, duration, delay, turns;
  final Size size;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.time) : super(repaint: time);
  final ValueListenable<double> time;

  static final List<_Piece> _pieces = () {
    final r = SeededRandom(Confetti.seed);
    return [
      for (var k = 0; k < Confetti.count; k++)
        _Piece(
          r.next() * (Confetti.specWidth - Confetti.minSize.width),
          Confetti.colors[k % Confetti.colors.length],
          (r.next() - 0.5) * Confetti.drift,
          Confetti.minDuration + r.next() * Confetti.durationRange,
          r.next() * Confetti.maxDelay,
          Confetti.minTurns + r.next() * Confetti.turnsRange,
          Size(Confetti.minSize.width + r.next() * Confetti.sizeRange.width,
              Confetti.minSize.height + r.next() * Confetti.sizeRange.height),
          k % Confetti.roundEvery == 0,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / Confetti.specWidth);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Confetti.stroke
      ..color = Palette.ink;
    for (final p in _pieces) {
      final t = time.value - p.delay;
      if (t < 0) continue;
      final phase = (t % p.duration) / p.duration;
      canvas.save();
      canvas.translate(p.left + p.drift * phase + p.size.width / 2, -p.size.height + Confetti.fall * phase);
      canvas.rotate(p.turns * 2 * math.pi * phase);
      final rect = Rect.fromCenter(center: Offset.zero, width: p.size.width, height: p.size.height);
      final fill = Paint()..color = p.color;
      if (p.round) {
        canvas.drawOval(rect, fill);
        canvas.drawOval(rect, ink);
      } else {
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, ink);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.time != time;
}
