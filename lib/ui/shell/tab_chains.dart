import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';

/// A locked tab's cover: two chains crossed over the tile and a padlock
/// bobbing over its icon. Once [breaking], the padlock rattles, its shackle
/// flips open and everything falls away, then [onBroken]; under reduced
/// motion it simply goes.
class TabChains extends StatefulWidget {
  const TabChains({super.key, this.breaking = false, this.onBroken});

  final bool breaking;
  final VoidCallback? onBroken;

  @override
  State<TabChains> createState() => _TabChainsState();
}

class _TabChainsState extends State<TabChains> with SingleTickerProviderStateMixin {
  late final _break = AnimationController(vsync: this, duration: TabLockStyle.breakTime);
  bool _snapped = false;

  @override
  void initState() {
    super.initState();
    _break.addListener(_onBreakTick);
    if (widget.breaking) WidgetsBinding.instance.addPostFrameCallback((_) => _startBreak());
  }

  @override
  void didUpdateWidget(TabChains old) {
    super.didUpdateWidget(old);
    if (widget.breaking && !old.breaking) _startBreak();
  }

  @override
  void dispose() {
    _break.dispose();
    super.dispose();
  }

  void _startBreak() {
    if (!mounted || _break.isAnimating || _break.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _snap();
      widget.onBroken?.call();
      return;
    }
    _break.forward().whenComplete(() => widget.onBroken?.call());
  }

  void _onBreakTick() {
    if (!_snapped && _break.value >= TabLockStyle.snapAt) _snap();
  }

  void _snap() {
    _snapped = true;
    playSound(context, Sfx.ratingBreak);
    if (ProgressScope.read(context).settings.haptics) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _break,
            builder: (context, _) => _break.value > 0
                ? CustomPaint(size: Size.infinite, painter: _ChainsPainter(breakT: _break.value, bob: 0))
                : IdleLoop(
                    builder: (context, elapsed, _) => CustomPaint(
                      size: Size.infinite,
                      painter: _ChainsPainter(
                        breakT: 0,
                        bob: elapsed.inMicroseconds / TabLockStyle.bobPeriod.inMicroseconds * 2 * math.pi,
                      ),
                    ),
                  ),
          ),
        ),
      );
}

class _ChainsPainter extends CustomPainter {
  _ChainsPainter({required this.breakT, required this.bob});

  /// How far the break has got, 0 (whole) to 1 (gone).
  final double breakT;

  /// The idle bob's phase, radians.
  final double bob;

  /// Seconds since the snap, 0 before it.
  double get _fall => math.max(0, breakT - TabLockStyle.snapAt) * TabLockStyle.breakTime.inMicroseconds / 1e6;

  double get _fade => breakT <= TabLockStyle.snapAt ? 1 : 1 - (breakT - TabLockStyle.snapAt) / (1 - TabLockStyle.snapAt);

  @override
  void paint(Canvas canvas, Size size) {
    final center = TabLockStyle.lockAt.alongSize(size);
    const reach = TabLockStyle.chainReach;
    for (final (from, to) in [
      (const Offset(-reach, -reach), Offset(size.width + reach, size.height + reach)),
      (Offset(size.width + reach, -reach), Offset(-reach, size.height + reach)),
    ]) {
      _chainHalf(canvas, from, center);
      _chainHalf(canvas, to, center);
    }
    _padlock(canvas, center);
    if (breakT > TabLockStyle.snapAt) _sparks(canvas, center);
  }

  /// The chain from [end] to [center]; after the snap it is flung out
  /// along itself and falls.
  void _chainHalf(Canvas canvas, Offset end, Offset center) {
    final along = end - center;
    final dir = along / along.distance;
    final t = _fall;
    final shift = dir * TabLockStyle.fling * t + Offset(0, TabLockStyle.gravity * t * t / 2);
    canvas.save();
    canvas.translate(shift.dx, shift.dy);
    if (t > 0) {
      canvas.translate(end.dx, end.dy);
      canvas.rotate(dir.dx.sign * TabLockStyle.chainSpin * t);
      canvas.translate(-end.dx, -end.dy);
    }
    final links = (along.distance / TabLockStyle.link).floor();
    final angle = math.atan2(dir.dy, dir.dx);
    final fill = Paint()..color = TabLockStyle.steel.withValues(alpha: _fade);
    final shine = Paint()..color = TabLockStyle.steelLight.withValues(alpha: _fade);
    final ink = Paint()
      ..color = Palette.ink.withValues(alpha: _fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = TabLockStyle.linkStroke;
    for (var i = links - 1; i >= 0; i--) {
      final c = center + dir * (TabLockStyle.link * (i + 0.5));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      final flat = i.isEven;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: TabLockStyle.linkLength,
        height: flat ? TabLockStyle.linkWidth : TabLockStyle.linkEdge,
      );
      final link = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
      canvas.drawRRect(link, fill);
      if (flat) canvas.drawRRect(link.deflate(TabLockStyle.linkShineInset), shine);
      canvas.drawRRect(link, ink);
      canvas.restore();
    }
    canvas.restore();
  }

  void _padlock(Canvas canvas, Offset center) {
    final t = _fall;
    var at = center + Offset(0, TabLockStyle.bob * math.sin(bob));
    var turn = TabLockStyle.rockDeg * math.pi / 180 * math.sin(bob / 2);
    if (breakT > 0 && breakT < TabLockStyle.snapAt) {
      final seconds = breakT * TabLockStyle.breakTime.inMicroseconds / 1e6;
      at += Offset(TabLockStyle.rattle * math.sin(2 * math.pi * TabLockStyle.rattleHz * seconds), 0);
    }
    if (t > 0) {
      at += Offset(0, TabLockStyle.gravity * t * t / 2);
      turn += TabLockStyle.spin * t;
    }
    final alpha = _fade;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(turn);
    const body = TabLockStyle.lockBody;
    final ink = Paint()
      ..color = Palette.ink.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = TabLockStyle.shackleWidth
      ..strokeCap = StrokeCap.round;
    // The shackle, pivoting on its right leg as it flips open.
    const r = TabLockStyle.shackle;
    canvas.save();
    if (t > 0) {
      canvas.translate(r, -body.height / 2);
      canvas.rotate(-TabLockStyle.shackleOpenDeg * math.pi / 180);
      canvas.translate(-r, body.height / 2 - r / 2);
    }
    final shackle = Path()
      ..moveTo(-r, -body.height / 2)
      ..lineTo(-r, -body.height / 2 - r / 2)
      ..arcToPoint(Offset(r, -body.height / 2 - r / 2), radius: const Radius.circular(r))
      ..lineTo(r, -body.height / 2);
    canvas.drawPath(shackle, ink);
    canvas.restore();
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: body.width, height: body.height),
      const Radius.circular(TabLockStyle.lockRadius),
    );
    canvas.drawRRect(rect, Paint()..color = Palette.sun.withValues(alpha: alpha));
    canvas.drawRRect(rect, ink..strokeWidth = Strokes.label);
    canvas.drawCircle(Offset.zero, TabLockStyle.keyhole, Paint()..color = Palette.ink.withValues(alpha: alpha));
    canvas.restore();
  }

  void _sparks(Canvas canvas, Offset center) {
    final u = ((breakT - TabLockStyle.snapAt) / (1 - TabLockStyle.snapAt)).clamp(0.0, 1.0);
    final ease = Curves.easeOut.transform(u);
    final paint = Paint()
      ..color = Palette.ink.withValues(alpha: 1 - u)
      ..strokeWidth = TabLockStyle.sparkWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < TabLockStyle.sparks; i++) {
      final a = 2 * math.pi * i / TabLockStyle.sparks;
      final dir = Offset(math.cos(a), math.sin(a));
      final inner = TabLockStyle.sparkFrom + (TabLockStyle.sparkReach - TabLockStyle.sparkFrom) * ease;
      canvas.drawLine(center + dir * inner, center + dir * (inner + TabLockStyle.sparkLength * (1 - ease)), paint);
    }
  }

  @override
  bool shouldRepaint(_ChainsPainter old) => old.breakT != breakT || old.bob != bob;
}
