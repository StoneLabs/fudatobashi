import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/card_stats.dart';

/// A plain polyline of recent response times, no axes or labels (the island
/// list's per-card sparkline).
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.valuesMs, this.color = Palette.sea});

  final List<double> valuesMs;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ChartStyle.sparklineWidth,
        height: ChartStyle.sparklineHeight,
        child: CustomPaint(painter: _SparklinePainter(valuesMs, color)),
      );
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    if (values.length == 1) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), ChartStyle.dotRadius, Paint()..color = color);
      return;
    }
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final span = hi - lo < 1e-6 ? 1.0 : hi - lo;
    double x(int i) => size.width * i / (values.length - 1);
    double y(double v) => size.height - (v - lo) / span * size.height;
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartStyle.lineStroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => !listEquals(old.values, values) || old.color != color;
}

/// The chart series a viewer can toggle on the card detail screen: three
/// rolling averages and the p5–p95 band.
enum ChartSeries { avg5, avg10, avg50, band }

/// Bridges a filtered list of attempts and the [CardStats] built from them:
/// which index into [attempts] each entry of `stats.timed` (and so each
/// point of `stats.rollingMean(...)`) corresponds to, so dots (every
/// attempt, including misses) and lines (timed attempts only) can share one
/// chronological X axis. Callers must build [stats] from this exact
/// [attempts] list so the two stay aligned.
class AttemptChartData {
  AttemptChartData(this.attempts, this.stats)
      : timedXs = [for (final (i, a) in attempts.indexed) if (a.timed) i];

  final List<AttemptRec> attempts;
  final CardStats stats;
  final List<int> timedXs;

  /// Index into [attempts] of the best (fastest) timed attempt, if any.
  int? get bestX {
    final best = stats.bestMs;
    if (best == null) return null;
    final j = stats.timed.indexOf(best);
    return j < 0 ? null : timedXs[j];
  }
}

/// Every attempt as a dot in ms (a distinct marker for a miss), a shaded
/// p5–p95 band, the 5/10/50 rolling averages, and a star at the best time —
/// the Kana Islands chart, "in ink" (spec phone 8).
class AttemptChart extends StatelessWidget {
  const AttemptChart({super.key, required this.data, required this.visible});

  final AttemptChartData data;
  final Set<ChartSeries> visible;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _AttemptChartPainter(data, visible));
}

class _AttemptChartPainter extends CustomPainter {
  _AttemptChartPainter(this.data, this.visible);
  final AttemptChartData data;
  final Set<ChartSeries> visible;

  @override
  void paint(Canvas canvas, Size size) {
    final attempts = data.attempts;
    if (attempts.isEmpty) return;
    final n = attempts.length;
    final stats = data.stats;
    final showBand = visible.contains(ChartSeries.band) && stats.timed.isNotEmpty;
    final p5 = showBand ? stats.percentile(stats.timed.length, 5) : null;
    final p95 = showBand ? stats.percentile(stats.timed.length, 95) : null;

    var lo = attempts.map((a) => a.ms).reduce(math.min);
    var hi = attempts.map((a) => a.ms).reduce(math.max);
    if (p5 != null) lo = math.min(lo, p5);
    if (p95 != null) hi = math.max(hi, p95);
    if (hi - lo < 1e-6) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * ChartStyle.axisPad;
    lo -= pad;
    hi += pad;

    double x(int i) => n <= 1 ? size.width / 2 : size.width * i / (n - 1);
    double y(double v) => size.height - (v - lo) / (hi - lo) * size.height;

    if (p5 != null && p95 != null) {
      canvas.drawRect(
        Rect.fromLTRB(0, y(p95), size.width, y(p5)),
        Paint()..color = Palette.desk.withValues(alpha: ChartStyle.bandOpacity),
      );
    }

    void drawSeries(ChartSeries series, List<double> values, Color color) {
      if (!visible.contains(series) || values.length < 2) return;
      final path = Path();
      for (var j = 0; j < values.length; j++) {
        final p = Offset(x(data.timedXs[j]), y(values[j]));
        if (j == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ChartStyle.lineStroke
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }

    drawSeries(ChartSeries.avg5, stats.rollingMean(5), Palette.seaDeep);
    drawSeries(ChartSeries.avg10, stats.rollingMean(10), Palette.pink);
    drawSeries(ChartSeries.avg50, stats.rollingMean(50), Palette.violet);

    for (var i = 0; i < n; i++) {
      final a = attempts[i];
      final p = Offset(x(i), y(a.ms));
      if (a.miss) {
        _drawMiss(canvas, p);
      } else {
        canvas.drawCircle(p, ChartStyle.dotRadius, Paint()..color = Palette.sea);
        canvas.drawCircle(
          p,
          ChartStyle.dotRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ChartStyle.dotStroke
            ..color = Palette.ink,
        );
      }
    }

    final bestX = data.bestX;
    if (bestX != null) _drawStar(canvas, Offset(x(bestX), y(stats.bestMs!)));
  }

  void _drawMiss(Canvas canvas, Offset p) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ChartStyle.missStroke
      ..strokeCap = StrokeCap.round
      ..color = Palette.pinkDeep;
    const h = ChartStyle.missSize;
    canvas.drawLine(p - const Offset(h, h), p + const Offset(h, h), paint);
    canvas.drawLine(p + const Offset(-h, h), p + const Offset(h, -h), paint);
  }

  void _drawStar(Canvas canvas, Offset c) {
    const r = ChartStyle.bestStarRadius;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? r : r * 0.45;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Palette.sun);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartStyle.bestStarStroke
        ..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_AttemptChartPainter old) =>
      !identical(old.data.attempts, data.attempts) || !setEquals(old.visible, visible);
}

/// A small line sampling FSRS retrievability over time (the forgetting curve).
class ForgettingCurve extends StatelessWidget {
  const ForgettingCurve({super.key, required this.samples, required this.retentionGoal});

  /// Retrievability (0..1) sampled at even time steps.
  final List<double> samples;
  final double retentionGoal;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ForgettingCurvePainter(samples, retentionGoal));
}

class _ForgettingCurvePainter extends CustomPainter {
  _ForgettingCurvePainter(this.samples, this.retentionGoal);
  final List<double> samples;
  final double retentionGoal;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;
    double x(int i) => size.width * i / (samples.length - 1);
    double y(double v) => size.height * (1 - v.clamp(0, 1));

    final goalY = y(retentionGoal);
    canvas.drawLine(
      Offset(0, goalY),
      Offset(size.width, goalY),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.desk,
    );

    final path = Path()..moveTo(x(0), y(samples[0]));
    for (var i = 1; i < samples.length; i++) {
      path.lineTo(x(i), y(samples[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartStyle.lineStroke
        ..color = Palette.seaDeep,
    );
  }

  @override
  bool shouldRepaint(_ForgettingCurvePainter old) =>
      !listEquals(old.samples, samples) || old.retentionGoal != retentionGoal;
}

/// One series of a [DailyChart]: a value per day (NaN for none), drawn as a
/// line, a dashed line or bars.
class DailySeries {
  const DailySeries(this.label, this.values, this.color, {this.bars = false, this.dashed = false});

  final String label;
  final List<double> values;
  final Color color;
  final bool bars;
  final bool dashed;

  /// The largest value, 0 for none.
  double get peak => values.where((v) => v.isFinite).fold(0, math.max);
}

/// Values per day on one scale from zero to [top] (by default the largest
/// value), for the debug Simulation.
class DailyChart extends StatelessWidget {
  const DailyChart({super.key, required this.series, this.top});

  final List<DailySeries> series;
  final double? top;

  /// The value at the chart's top edge.
  double get scaleTop => top ?? math.max(1, series.fold(0.0, (m, s) => math.max(m, s.peak)));

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DailyChartPainter(series, scaleTop));
}

class _DailyChartPainter extends CustomPainter {
  _DailyChartPainter(this.series, this.top);
  final List<DailySeries> series;
  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final days = series.fold(0, (n, s) => math.max(n, s.values.length));
    if (days == 0) return;
    final step = size.width / days;
    double x(int i) => step * (i + 0.5);
    double y(double v) => size.height * (1 - (v / top).clamp(0, 1));
    final grid = Paint()
      ..strokeWidth = ChartStyle.gridStroke
      ..color = Palette.desk;
    canvas
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), grid)
      ..drawLine(Offset.zero, Offset(size.width, 0), grid);

    for (final s in series.where((s) => s.bars)) {
      final paint = Paint()..color = s.color;
      final half = step * ChartStyle.dailyBarShare / 2;
      for (final (i, v) in s.values.indexed) {
        if (v.isFinite && v > 0) canvas.drawRect(Rect.fromLTRB(x(i) - half, y(v), x(i) + half, size.height), paint);
      }
    }
    for (final s in series.where((s) => !s.bars)) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ChartStyle.lineStroke
        ..color = s.color;
      Offset? last;
      for (final (i, v) in s.values.indexed) {
        final p = v.isFinite ? Offset(x(i), y(v)) : null;
        if (last != null && p != null) s.dashed ? _dash(canvas, last, p, paint) : canvas.drawLine(last, p, paint);
        last = p;
      }
    }
  }

  static void _dash(Canvas canvas, Offset a, Offset b, Paint paint) {
    final length = (b - a).distance;
    for (var t = 0.0; t < length; t += ChartStyle.dash * 2) {
      canvas.drawLine(Offset.lerp(a, b, t / length)!, Offset.lerp(a, b, math.min(1, (t + ChartStyle.dash) / length))!, paint);
    }
  }

  @override
  bool shouldRepaint(_DailyChartPainter old) => old.series != series || old.top != top;
}
