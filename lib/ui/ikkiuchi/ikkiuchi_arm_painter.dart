import 'dart:math' as math;
import 'dart:ui';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_strike.dart';

/// Draws Tobi's arm (一騎打ち) on a canvas in board dp: one ink line from his
/// shoulder to a white fist in his pen, and a strike's wind lines and smear
/// afterimages.
abstract final class IkkiuchiArmPainter {
  /// The arm at move time [tau] from the shoulder [shoulder], [k] dp a Tobi
  /// unit, in [alpha].
  static void paintArm(Canvas canvas, IkkiuchiArmMove arm, double tau, Vec shoulder, double k, {double alpha = 1}) =>
      _paintArm(canvas, arm, arm.armPoints(tau, shoulder), tau, k, alpha);

  static void _paintArm(Canvas canvas, IkkiuchiArmMove arm, List<Vec> points, double tau, double k, double alpha) {
    final pen = IkkiuchiArmStyle.pen * k;
    final stroke = Paint()
      ..color = IkkiuchiArmStyle.ink.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width(points, k)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_smooth(points), stroke);
    final scale = arm.fistScale(tau);
    if (scale <= _fistShown) return;
    final hand = points.last;
    final vel = arm.handVelocity(tau);
    final stretch = math.min(vel.length / IkkiuchiArmStyle.fistStretchSpeed, IkkiuchiArmStyle.fistStretchMax);
    final r = arm.fist * scale;
    final oval = Rect.fromCenter(
        center: Offset.zero, width: 2 * r * (1 + stretch), height: 2 * r / (1 + stretch * IkkiuchiArmStyle.fistNarrow));
    canvas
      ..save()
      ..translate(hand.x, hand.y)
      ..rotate(math.atan2(vel.y, vel.x))
      ..drawOval(oval, Paint()..color = IkkiuchiArmStyle.fistFill.withValues(alpha: alpha))
      ..drawOval(
          oval,
          stroke
            ..strokeWidth = pen * IkkiuchiArmStyle.fistPen)
      ..restore();
  }

  // A fist shrunk under this share of its size isn't drawn.
  static const _fistShown = 0.02;

  /// The pen for an arm along [points]: a long arm thins.
  static double _width(List<Vec> points, double k) {
    var length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += points[i].distanceTo(points[i - 1]);
    }
    final thin = math.pow(IkkiuchiArmStyle.restLength * k / math.max(length, 1), IkkiuchiArmStyle.thinPower);
    return IkkiuchiArmStyle.pen * k * thin.clamp(IkkiuchiArmStyle.thinMin, IkkiuchiArmStyle.thinMax);
  }

  /// A smooth line through [points]: quadratic curves through their midpoints.
  static Path _smooth(List<Vec> points) {
    final path = Path()..moveTo(points.first.x, points.first.y);
    for (var i = 1; i < points.length - 1; i++) {
      final m = points[i].lerp(points[i + 1], 0.5);
      path.quadraticBezierTo(points[i].x, points[i].y, m.x, m.y);
    }
    return path..lineTo(points.last.x, points.last.y);
  }

  /// Wind lines: tapered ink streaks tracing where the fist and the arm
  /// have just been, inked by how fast they went. The row sweep's run along
  /// the card's edges, [cardHalf] from its middle.
  static void paintWind(Canvas canvas, IkkiuchiStrike strike, double tau, Vec shoulder, double k, double cardHalf) {
    if (strike.handSpeed(tau) < IkkiuchiArmStyle.windMinSpeed &&
        strike.handSpeed(tau - IkkiuchiArmStyle.windOnAfter) < IkkiuchiArmStyle.windMinSpeed) {
      return;
    }
    final sweep = strike.move == IkkiuchiMove.sweep;
    final span = sweep ? IkkiuchiArmStyle.sweepWindow : IkkiuchiArmStyle.windWindow;
    const n = IkkiuchiArmStyle.windSamples;
    final path = <Vec>[];
    var top = 0.0;
    for (var i = 0; i < n; i++) {
      final ti = tau - span * (1 - i / (n - 1));
      path.add(strike.handAt(ti));
      top = math.max(top, strike.handSpeed(ti));
    }
    final ink = ((top - IkkiuchiArmStyle.windMinSpeed) / (IkkiuchiArmStyle.windFullSpeed - IkkiuchiArmStyle.windMinSpeed))
        .clamp(0.0, 1.0);
    if (ink <= 0) return;
    final r = strike.fist;
    final offsets = sweep
        ? [
            -(cardHalf + IkkiuchiArmStyle.sweepGap),
            cardHalf + IkkiuchiArmStyle.sweepGap,
            -(cardHalf + IkkiuchiArmStyle.sweepGapOuter),
          ]
        : [for (final o in IkkiuchiArmStyle.windOffsets) o * r];
    final widths = sweep ? IkkiuchiArmStyle.sweepWidths : IkkiuchiArmStyle.windWidths;
    final paint = Paint()..color = IkkiuchiArmStyle.ink.withValues(alpha: ink);
    for (final (li, o) in offsets.indexed) {
      final pts = [
        for (var i = 0; i < n; i++) path[i] + _normal(path, i) * o,
      ];
      final shown = pts.sublist(li == offsets.length - 1 ? IkkiuchiArmStyle.windCut : 1, n - 2);
      _ribbon(canvas, shown, [
        for (var i = 0; i < shown.length; i++)
          widths[li] * math.pow(math.sin(math.pi * (i + 0.5) / shown.length), IkkiuchiArmStyle.windTaper),
      ], paint);
    }
    if (sweep) return;
    paint.color = IkkiuchiArmStyle.ink.withValues(alpha: ink * IkkiuchiArmStyle.armWindInk);
    final lag = strike.lagAt(tau);
    const m = IkkiuchiArmStyle.armWindSamples;
    for (final u in IkkiuchiArmStyle.armWindUs) {
      final behind = lag * math.pow(1 - u, IkkiuchiArmTuning.lagPower);
      final pts = [
        for (var i = 0; i < m; i++)
          shoulder + (strike.handAt(tau - IkkiuchiArmStyle.armWindow * (1 - i / (m - 1)) - behind) - shoulder) * u,
      ];
      if (pts.last.distanceTo(pts.first) < IkkiuchiArmStyle.armWindMin) continue;
      const shown = IkkiuchiArmStyle.armWindShown;
      _ribbon(canvas, pts.sublist(0, shown), [
        for (var i = 0; i < shown; i++) IkkiuchiArmStyle.armWindWidth * math.sin(math.pi * (i + 0.5) / m),
      ], paint);
    }
  }

  /// The smear swing's afterimages: a faint swoosh between the arm now and
  /// a moment ago, and ghost arms with their fists along the arc.
  static void paintSmear(Canvas canvas, IkkiuchiStrike strike, double tau, Vec shoulder, double k) {
    final amount = strike.smearAt(tau);
    if (amount <= 0) return;
    final now = strike.armPoints(tau, shoulder);
    final back = strike.armPoints(tau - IkkiuchiArmStyle.smearBack, shoulder);
    final swoosh = Path()..moveTo(now.first.x, now.first.y);
    for (final p in now) {
      swoosh.lineTo(p.x, p.y);
    }
    for (final p in back.reversed) {
      swoosh.lineTo(p.x, p.y);
    }
    canvas.drawPath(swoosh..close(), Paint()..color = IkkiuchiArmStyle.ink.withValues(alpha: IkkiuchiArmStyle.smearSwoosh * amount));
    for (final (dt, ink) in IkkiuchiArmStyle.smearGhosts) {
      _paintArm(canvas, strike, strike.armPoints(tau - dt, shoulder), tau - dt, k, ink * amount);
    }
  }

  /// The way across a path at its [i]th point.
  static Vec _normal(List<Vec> path, int i) =>
      (path[math.min(path.length - 1, i + 1)] - path[math.max(0, i - 1)]).unit.perp;

  /// A brush stroke along [points], [widths] across at each.
  static void _ribbon(Canvas canvas, List<Vec> points, List<double> widths, Paint paint) {
    if (points.length < 2) return;
    final left = <Vec>[], right = <Vec>[];
    for (var i = 0; i < points.length; i++) {
      final nrm = _normal(points, i) * (widths[i] / 2);
      left.add(points[i] + nrm);
      right.add(points[i] - nrm);
    }
    final path = Path()..moveTo(left.first.x, left.first.y);
    for (final p in [...left.skip(1), ...right.reversed]) {
      path.lineTo(p.x, p.y);
    }
    canvas.drawPath(path..close(), paint);
  }
}
