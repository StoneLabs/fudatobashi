import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_rating.dart';
import '../../domain/rating.dart';
import '../../domain/ankiren_score.dart';
import '../play/time_format.dart';
import 'debug_common.dart';

/// A ranked game's total over the time each right card took to find, played
/// in full and ready early with the set time left, with some cards wrong
/// ([AnkirenToolsTuning.wrongCardPoints] each, no speed bonus). The class
/// borders are dashed lines at the scores that reach them.
class AnkirenRankedGraph extends StatefulWidget {
  const AnkirenRankedGraph({super.key});

  @override
  State<AnkirenRankedGraph> createState() => _AnkirenRankedGraphState();
}

class _AnkirenRankedGraphState extends State<AnkirenRankedGraph> {
  static const _setup = AnkirenSetup.ranked();
  double _timeLeft = AnkirenToolsTuning.timeLeftStart.inSeconds.toDouble();
  double _wrong = 0;

  _Line _line(Color color, Duration timeLeft) {
    final wrong = _wrong.round();
    final share = timeLeft.inMicroseconds / _setup.memorise.inMicroseconds;
    return _Line(color, [
      for (
        var ms = AnkirenToolsTuning.responseMin.inMilliseconds;
        ms <= AnkirenToolsTuning.responseMax.inMilliseconds;
        ms += AnkirenToolsTuning.curveStepMs
      )
        Offset(
          ms / 1000,
          AnkirenScore.totalOf(
            (_setup.cards - wrong) * (AnkirenTuning.cardPoints + AnkirenScore.speedBonus(ms * 1000)) +
                wrong * AnkirenToolsTuning.wrongCardPoints,
            share,
          ).toDouble(),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = Duration(seconds: _timeLeft.round());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DebugSlider(
          label: 'time left ${formatMinutes(timeLeft)} of ${formatMinutes(_setup.memorise)}',
          value: _timeLeft,
          min: 0,
          max: _setup.memorise.inSeconds.toDouble(),
          divisions: _setup.memorise.inSeconds ~/ AnkirenToolsTuning.timeLeftStep.inSeconds,
          onChanged: (v) => setState(() => _timeLeft = v),
        ),
        DebugSlider(
          label: 'cards wrong ${_wrong.round()} of ${_setup.cards}',
          value: _wrong,
          min: 0,
          max: _setup.cards.toDouble(),
          divisions: _setup.cards,
          onChanged: (v) => setState(() => _wrong = v),
        ),
        SizedBox(
          height: AnkirenToolsStyle.graphHeight,
          child: CustomPaint(
            painter: _LinesPainter([_line(Palette.mute, Duration.zero), _line(Palette.seaDeep, timeLeft)]),
          ),
        ),
        Text(
          'x: time of each right card (s) · y: points · grey: played in full · blue: ready early · '
          'a wrong card = ${AnkirenToolsTuning.wrongCardPoints} · dashed: class borders',
          style: debugMono,
        ),
      ],
    );
  }
}

class _Line {
  const _Line(this.color, this.points);

  final Color color;
  final List<Offset> points;
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.lines);

  final List<_Line> lines;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = AnkirenToolsStyle.graphMargin.deflateRect(Offset.zero & size);
    final xMax = AnkirenToolsTuning.responseMax.inSeconds.toDouble();
    const yMax = AnkirenToolsTuning.graphYMax;
    Offset at(Offset p) => Offset(plot.left + plot.width * p.dx / xMax, plot.bottom - plot.height * p.dy / yMax);
    final grid = Paint()..color = Palette.desk;
    const label = TextStyle(fontSize: AnkirenToolsStyle.axisFont, color: Palette.mute, fontFamily: AnkirenDebugStyle.mono);

    void text(String s, Offset anchor, {required Alignment align}) {
      final tp = TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, anchor - Offset(tp.width * (align.x + 1) / 2, tp.height * (align.y + 1) / 2));
    }

    for (var i = 0; i <= AnkirenToolsTuning.yDivisions; i++) {
      final y = plot.bottom - plot.height * i / AnkirenToolsTuning.yDivisions;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      text('${(yMax * i / AnkirenToolsTuning.yDivisions).round()}',
          Offset(plot.left - AnkirenToolsStyle.axisLabelGap, y),
          align: Alignment.centerRight);
    }
    for (var x = 0.0; x <= xMax; x += AnkirenToolsTuning.responseTick.inSeconds) {
      final px = at(Offset(x, 0)).dx;
      canvas.drawLine(Offset(px, plot.top), Offset(px, plot.bottom), grid);
      text('${x.round()} s', Offset(px, plot.bottom + AnkirenToolsStyle.axisLabelGap), align: Alignment.topCenter);
    }
    _paintClasses(canvas, plot, at, text);
    for (final line in lines) {
      final path = Path();
      for (final (i, p) in line.points.indexed) {
        final o = at(p);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AnkirenToolsStyle.lineStroke
          ..color = line.color,
      );
    }
  }

  /// A dashed line at the score of each class border that fits, labelled
  /// at the right edge; a label too near the one above moves down.
  void _paintClasses(
    Canvas canvas,
    Rect plot,
    Offset Function(Offset) at,
    void Function(String, Offset, {required Alignment align}) text,
  ) {
    final paint = Paint()
      ..strokeWidth = AnkirenToolsStyle.classStroke
      ..color = Palette.mute.withValues(alpha: AnkirenToolsStyle.classOpacity);
    final borders = [
      for (final band in Rating.bands.skip(1))
        if (AnkirenRating.scoreFor(band.minRating) case final score when score <= AnkirenToolsTuning.graphYMax)
          (band.labelEn, at(Offset(0, score)).dy),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    var labelTop = double.negativeInfinity;
    for (final (name, y) in borders) {
      for (var x = plot.left; x < plot.right; x += AnkirenToolsStyle.classDash + AnkirenToolsStyle.classDashGap) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + AnkirenToolsStyle.classDash, plot.right), y), paint);
      }
      final labelY = math.max(y, labelTop + AnkirenToolsStyle.classLabelHeight);
      labelTop = labelY;
      text(name, Offset(plot.right + AnkirenToolsStyle.axisLabelGap, labelY), align: Alignment.centerLeft);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => true;
}
