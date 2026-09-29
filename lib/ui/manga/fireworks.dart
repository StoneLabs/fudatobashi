import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'seeded_random.dart';

/// Fireworks bursting on loop (the graduation page): each of
/// [FireworksStyle.bursts] throws a ring of ink-outlined streaks that fly
/// out, droop and fade, laid out in the spec's box and scaled to the actual
/// one. Under reduced motion every burst hangs still mid-bloom.
class Fireworks extends StatefulWidget {
  const Fireworks({super.key});

  @override
  State<Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<Fireworks> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) => _time.value = elapsed.inMicroseconds / 1e6);
  final _time = ValueNotifier<double?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _ticker.isActive) {
      _ticker.stop();
      _time.value = null;
    }
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
        child: RepaintBoundary(child: CustomPaint(size: Size.infinite, painter: _FireworksPainter(_time))),
      );
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.time) : super(repaint: time);

  /// Seconds since the fireworks started, or null to hold them still.
  final ValueListenable<double?> time;

  /// Each burst's sparks as (direction, reach) pairs, fixed per seed.
  static final List<List<(Offset, double)>> _sparks = [
    for (final b in FireworksStyle.bursts)
      () {
        final r = SeededRandom(b.seed);
        return [
          for (var i = 0; i < FireworksStyle.sparks; i++)
            () {
              final a = (i + r.next() * 0.5) * 2 * math.pi / FireworksStyle.sparks;
              return (Offset(math.cos(a), math.sin(a)), FireworksStyle.minRadius + r.next() * FireworksStyle.radiusRange);
            }(),
        ];
      }(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Bursts keep their spot on the page; their size follows its width.
    final scale = size.width / FireworksStyle.specWidth;
    final spot = Offset(scale, size.height / FireworksStyle.specHeight);
    final now = time.value;
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = Palette.ink;
    for (final (k, b) in FireworksStyle.bursts.indexed) {
      final double age;
      if (now == null) {
        age = FireworksStyle.stillAt;
      } else {
        final since = now - b.delay;
        if (since < 0) continue;
        age = (since % b.period) / FireworksStyle.life;
        if (age >= 1) continue;
      }
      final spread = 1 - math.pow(1 - age, 3).toDouble();
      final fade = age < FireworksStyle.fadeFrom ? 1.0 : (1 - age) / (1 - FireworksStyle.fadeFrom);
      final center = b.center.scale(spot.dx, spot.dy);
      final streaks = Path();
      final dots = Path();
      for (final (dir, reach) in _sparks[k]) {
        final head = center + (dir * reach * spread + Offset(0, FireworksStyle.droop * age * age)) * scale;
        final tail = center + dir * reach * spread * (1 - FireworksStyle.streak) * scale;
        streaks
          ..moveTo(tail.dx, tail.dy)
          ..lineTo(head.dx, head.dy);
        dots.addOval(Rect.fromCircle(center: head, radius: FireworksStyle.dot * (1 - age * 0.5) * scale));
      }
      final color = b.color.withValues(alpha: fade);
      final outline = ink..color = Palette.ink.withValues(alpha: fade);
      canvas.drawPath(streaks, outline..strokeWidth = (FireworksStyle.streakWidth + 2 * FireworksStyle.outline) * scale);
      canvas.drawPath(
        streaks,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = FireworksStyle.streakWidth * scale
          ..color = color,
      );
      canvas.drawPath(dots, Paint()..color = color);
      canvas.drawPath(dots, outline..strokeWidth = FireworksStyle.outline * scale);
      if (age < FireworksStyle.flashShare) {
        final flash = _star(center, FireworksStyle.flashSize * (1 - age / FireworksStyle.flashShare) * scale);
        canvas.drawPath(flash, Paint()..color = Palette.paper);
        canvas.drawPath(flash, outline..strokeWidth = FireworksStyle.outline * scale);
      }
    }
  }

  static Path _star(Offset c, double size) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final r = i.isEven ? size / 2 : size / 8;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.time != time;
}
