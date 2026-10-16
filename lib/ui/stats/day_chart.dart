import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// One line of a [DayLineChart]: a value per day, null for none.
class ChartLine {
  const ChartLine(
    this.values, {
    this.color = Palette.ink,
    this.stroke = RunChartStyle.lineStroke,
    this.dash,
    this.fill,
    this.dots = false,
  });

  final List<double?> values;
  final Color color;
  final double stroke;

  /// On and off lengths of a dashed line; solid when null.
  final List<double>? dash;

  /// The area under the line.
  final Color? fill;

  /// A ringed dot on each day.
  final bool dots;
}

/// A ringed dot with a label at day [index] of a [DayLineChart].
class ChartMark {
  const ChartMark(this.index, this.value, this.label, {this.color = Palette.paper, this.labelColor = Palette.ink});
  final int index;
  final double value;
  final String label;
  final Color color, labelColor;
}

/// Values per day over gridlines at [ticks] from [lo] to [hi], with day
/// labels under some days ([xLabels], by index), a dotted rule at [today]
/// and labelled [marks].
class DayLineChart extends StatelessWidget {
  const DayLineChart({
    super.key,
    required this.lines,
    required this.lo,
    required this.hi,
    required this.ticks,
    required this.format,
    this.xLabels = const {},
    this.marks = const [],
    this.today,
    this.height = SrsLayout.chartHeight,
  });

  final List<ChartLine> lines;
  final double lo, hi;
  final List<double> ticks;
  final String Function(double value) format;
  final Map<int, String> xLabels;
  final List<ChartMark> marks;
  final int? today;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(size: Size.infinite, painter: _DayLinePainter(this, MediaQuery.textScalerOf(context))),
      );
}

class _DayLinePainter extends CustomPainter {
  _DayLinePainter(this.chart, this.scaler);
  final DayLineChart chart;
  final TextScaler scaler;

  TextPainter _label(String text, {Color color = Palette.ink}) => TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(fontFamily: Fonts.ui, fontSize: RunChartStyle.labelFont, fontWeight: Weights.black, color: color)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final days = chart.lines.fold(0, (n, l) => math.max(n, l.values.length));
    if (days < 2) return;
    final widest = chart.ticks.map((t) => _label(chart.format(t)).width).fold(0.0, math.max);
    final xRow = chart.xLabels.isEmpty ? 0.0 : _label('0').height + RunChartStyle.labelGap;
    final plot = Rect.fromLTRB(widest + RunChartStyle.labelGap, RunChartStyle.labelGap + SrsLayout.chartTopPad,
        size.width - RunChartStyle.plotRightPad, size.height - xRow);
    double x(int i) => plot.left + plot.width * i / (days - 1);
    double y(double v) => plot.bottom - plot.height * ((v - chart.lo) / (chart.hi - chart.lo)).clamp(0.0, 1.0);

    final grid = Paint()
      ..color = ChartStyle.grid
      ..strokeWidth = ChartStyle.gridStroke;
    for (final t in chart.ticks) {
      canvas.drawLine(Offset(plot.left, y(t)), Offset(plot.right, y(t)), grid);
      final l = _label(chart.format(t));
      l.paint(canvas, Offset(plot.left - RunChartStyle.labelGap - l.width, y(t) - l.height / 2));
    }
    for (final MapEntry(key: i, value: text) in chart.xLabels.entries) {
      final l = _label(text, color: i == chart.today ? Palette.ink : HistoryRunStyle.muted);
      l.paint(canvas, Offset((x(i) - l.width / 2).clamp(0.0, size.width - l.width), plot.bottom + RunChartStyle.labelGap));
    }
    if (chart.today case final t?) {
      final rule = Paint()
        ..color = Palette.ink
        ..strokeWidth = Strokes.hairline / 2;
      _dashed(canvas, Offset(x(t), plot.top), Offset(x(t), plot.bottom), rule, Strokes.fineDash);
    }

    for (final line in chart.lines.where((l) => l.fill != null)) {
      final pts = [for (final (i, v) in line.values.indexed) if (v != null) Offset(x(i), y(v))];
      if (pts.length < 2) continue;
      canvas.drawPath(
        Path()
          ..moveTo(pts.first.dx, plot.bottom)
          ..addPolygon(pts, false)
          ..lineTo(pts.last.dx, plot.bottom)
          ..close(),
        Paint()..color = line.fill!,
      );
    }
    for (final line in chart.lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      Offset? last;
      for (final (i, v) in line.values.indexed) {
        final p = v == null ? null : Offset(x(i), y(v));
        if (last != null && p != null) {
          if (line.dash case final dash?) {
            _dashed(canvas, last, p, paint, dash);
          } else {
            canvas.drawLine(last, p, paint);
          }
        }
        last = p;
      }
      if (line.dots) {
        for (final (i, v) in line.values.indexed) {
          if (v != null) _dot(canvas, Offset(x(i), y(v)), Palette.paper, line.color, SrsLayout.chartDot);
        }
      }
    }
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, Paint()..strokeWidth = Strokes.label);

    for (final m in chart.marks) {
      final p = Offset(x(m.index), y(m.value));
      _dot(canvas, p, m.color, Palette.ink, SrsLayout.chartMark);
      final l = _label(m.label, color: m.labelColor);
      final right = p.dx + SrsLayout.chartMark + RunChartStyle.labelGap;
      final dx = right + l.width <= plot.right ? right : p.dx - SrsLayout.chartMark - RunChartStyle.labelGap - l.width;
      final below = p.dy + SrsLayout.chartMark;
      final dy = below + l.height <= plot.bottom ? below : p.dy - SrsLayout.chartMark - l.height;
      l.paint(canvas, Offset(dx.clamp(0.0, size.width - l.width), dy));
    }
  }

  static void _dot(Canvas canvas, Offset p, Color fill, Color ring, double r) {
    canvas.drawCircle(p, r, Paint()..color = fill);
    canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = Strokes.hairline);
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Paint paint, List<double> dash) {
    final length = (b - a).distance;
    if (length == 0) return;
    for (var t = 0.0; t < length; t += dash[0] + dash[1]) {
      canvas.drawLine(Offset.lerp(a, b, t / length)!, Offset.lerp(a, b, math.min(1, (t + dash[0]) / length))!, paint);
    }
  }

  @override
  bool shouldRepaint(_DayLinePainter old) => old.chart != chart || old.scaler != scaler;
}
