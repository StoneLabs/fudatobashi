import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_rating.dart';
import '../../domain/rating.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';
import '../manga/seeded_random.dart';
import '../results/celebration_chrome.dart';
import '../results/celebrations.dart';
import '../side_trips/ikkiuchi_rating_curve.dart';
import 'ikkiuchi_rank_timeline.dart';

/// Where the rank change page's plot, [size], puts this match: the last
/// match's point ([tip]) and this one's ([next]); while placing on the
/// placement chart, after that on the mode's rating curve.
class IkkiuchiRankPlotPoints {
  factory IkkiuchiRankPlotPoints(IkkiuchiRankChange change, Size size) {
    if (change.placing) {
      final chart = IkkiuchiRankChart(change.path, size);
      final n = change.placement.length;
      return IkkiuchiRankPlotPoints._(chart.at(n - 1, change.before), chart.at(n, change.after));
    }
    final scale = rankCurveScale(change, size);
    final n = change.curve.length - 1;
    return IkkiuchiRankPlotPoints._(scale.at(n - 1, change.before), scale.at(n, change.after));
  }

  const IkkiuchiRankPlotPoints._(this.tip, this.next);

  final Offset tip, next;

  /// The point [share] of the way from [tip] to [next].
  Offset along(double share) => Offset.lerp(tip, next, share)!;
}

/// The rank change page's curve over a plot of [size]: the mode's curve
/// with this match, the box's foot kept clear under it.
IkkiuchiCurveScale rankCurveScale(IkkiuchiRankChange change, Size size) => IkkiuchiCurveScale(
    change.curve, Size(size.width, size.height - IkkiuchiRankLayout.plotFoot), IkkiuchiRankLayout.curve);

/// The placement chart over a plot of [size]: the estimates of [path]
/// (the start, then after each placement match) between the chart's
/// ratings, each match's slot from the left, the axis at the foot.
class IkkiuchiRankChart {
  IkkiuchiRankChart(this.path, this.size)
      : low = math.min(IkkiuchiRankLayout.chartLow, path.reduce(math.min) - IkkiuchiRankLayout.chartPad),
        high = math.max(IkkiuchiRankLayout.chartHigh, path.reduce(math.max) + IkkiuchiRankLayout.chartPad);

  final List<double> path;
  final Size size;
  final double low, high;

  double get floor => size.height - IkkiuchiRankLayout.chartAxis;

  /// Where placement match [i]'s slot (0 the start) stands.
  double xOf(int i) {
    const left = IkkiuchiRankLayout.chartLabelRoom + IkkiuchiRankLayout.chartLeft;
    final right = size.width - IkkiuchiRankLayout.chartRight;
    return left + (right - left) * i / IkkiuchiRating.placementMatches;
  }

  double yOf(double rating) =>
      IkkiuchiRankLayout.chartTop + (floor - IkkiuchiRankLayout.chartTop) * (high - rating) / (high - low);

  Offset at(int i, double rating) => Offset(xOf(i), yOf(rating));

  /// The classes whose lines fall inside the chart, lowest first.
  Iterable<RankBand> get bands =>
      Rating.bands.where((b) => b.minRating.isFinite && b.minRating > low && b.minRating < high);
}

/// The rank change page's plot at [elapsed] into the page ([timeline]):
/// the mode's rating curve with this match running to its place, or while
/// placing the placement chart. It fills its room.
class IkkiuchiRankPlot extends StatelessWidget {
  const IkkiuchiRankPlot(this.timeline, {super.key, required this.elapsed, required this.tone});

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final IkkiuchiModeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final words = _PlotWords(
      classLabel: (band) => '${s.className(band)} ${band.minRating.round()}',
      caption: s.ikkiuchiCurveLast(timeline.change.curve.length),
      start: s.ikkiuchiRankStart,
      here: s.ikkiuchiRankHere,
      won: s.ikkiuchiSlotWon,
      lost: s.ikkiuchiSlotLost,
      latin: !s.ja,
    );
    return CustomPaint(
      size: Size.infinite,
      painter: timeline.placing
          ? _ChartPainter(timeline, elapsed, tone, words, MediaQuery.textScalerOf(context),
              MediaQuery.devicePixelRatioOf(context))
          : _CurvePainter(timeline, elapsed, tone, words, MediaQuery.textScalerOf(context),
              MediaQuery.devicePixelRatioOf(context)),
    );
  }
}

/// The plot's words, in the page's language.
class _PlotWords {
  const _PlotWords({
    required this.classLabel,
    required this.caption,
    required this.start,
    required this.here,
    required this.won,
    required this.lost,
    required this.latin,
  });

  final String Function(RankBand band) classLabel;
  final String caption, start, here, won, lost;
  final bool latin;
}

/// The swell of a point landing at [at]: [swell] at once, dying out.
double _landed(Duration elapsed, Duration at, double swell) =>
    elapsed < at ? 0 : swell * (1 - Curves.easeOutCubic.transform(progressIn(elapsed, at, IkkiuchiRankMotion.landPulse)));

abstract class _PlotPainter extends CustomPainter {
  _PlotPainter(this.timeline, this.elapsed, this.tone, this.words, this.scaler, this.pixelRatio);

  final IkkiuchiRankTimeline timeline;
  final Duration elapsed;
  final IkkiuchiModeTone tone;
  final _PlotWords words;
  final TextScaler scaler;
  final double pixelRatio;

  IkkiuchiRankChange get change => timeline.change;

  /// The diamond's swell as the chip of a win reaches it.
  double get chipSwell => timeline.won
      ? beatAt(elapsed, [timeline.chipLandAt], IkkiuchiRankMotion.chipSwell) * IkkiuchiRankLayout.chipSwell
      : 0;

  /// Ink strokes flying out from [at], [f] of the way through, [size] times
  /// the usual reach.
  void burst(Canvas canvas, Offset at, double f, {double size = 1}) {
    if (f <= 0 || f >= 1) return;
    const n = IkkiuchiRankLayout.burstStrokes;
    final r = SeededRandom(IkkiuchiRankLayout.burstSeed);
    final paint = Paint()
      ..color = Palette.ink.withValues(alpha: 1 - f)
      ..strokeWidth = IkkiuchiRankLayout.burstStroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final a = i / n * 2 * math.pi + (r.next() - 0.5) * IkkiuchiRankLayout.burstJitter;
      final r0 = (IkkiuchiRankLayout.burstFrom + IkkiuchiRankLayout.burstReach * f) * size;
      final r1 = r0 + (IkkiuchiRankLayout.burstReach * (1 - f) + IkkiuchiRankLayout.burstEnd) * size;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(at + dir * r0, at + dir * r1, paint);
    }
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      old.elapsed != elapsed || old.timeline != timeline || old.scaler != scaler || old.pixelRatio != pixelRatio;
}

/// The mode's rating curve with this match's point running from the last
/// match's to its place: the guide in its slot until it lands, the class
/// line it crosses straining, breaking or cracking, the diamond swelling
/// at the landing, the heartbeats and the break.
class _CurvePainter extends _PlotPainter {
  _CurvePainter(super.timeline, super.elapsed, super.tone, super.words, super.scaler, super.pixelRatio);

  @override
  void paint(Canvas canvas, Size size) {
    const style = IkkiuchiRankLayout.curve;
    final t = timeline, e = elapsed;
    final scale = rankCurveScale(change, size);
    final ink = IkkiuchiCurveInk(canvas, scaler);
    final floor = scale.size.height;
    final history = change.curve.sublist(0, change.curve.length - 1);
    final points = [for (final (i, r) in history.indexed) scale.at(i, r)];
    final ends = IkkiuchiRankPlotPoints(change, size);
    final share = t.shareAt(e);
    final head = ends.along(share);
    final line = share > 0 ? [...points, head] : points;

    if (line.length > 1) ink.ground(line, floor, tone.tone, pixelRatio);
    if (e < t.landAt) {
      final x = ends.next.dx;
      final ink = Paint()
        ..color = IkkiuchiRankLayout.guideInk.withValues(
            alpha: IkkiuchiRankLayout.guideInk.a *
                progressIn(e, IkkiuchiRankMotion.box.end, IkkiuchiRankMotion.guideIn))
        ..strokeWidth = Strokes.hairline;
      const dash = IkkiuchiRankLayout.guideDash;
      for (var y = style.top - IkkiuchiRankLayout.guideOver; y < floor; y += dash[0] + dash[1]) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(floor, y + dash[0])), ink);
      }
    }
    final captionBaseline = ink.caption(words.caption, floor);

    final crossed = t.ranksUp ? change.to : (t.ranksDown ? change.from : null);
    final gateX = t.gateShare == null ? 0.0 : ends.along(t.gateShare!).dx;
    for (final band in scale.bands) {
      final y = scale.yOf(band.minRating);
      final gate = band == crossed;
      final reached = gate && e >= t.gateAt;
      final broken = gate && t.ranksUp && e >= t.breakAt;
      final cracked = gate && t.ranksDown && e >= t.crackAt;
      final straining = reached && t.ranksUp && !broken;
      if (broken || cracked) {
        final gap = broken ? IkkiuchiRankLayout.breakGap : IkkiuchiRankLayout.crackGap;
        ink.classLine(y, 0, gateX - gap);
        ink.classLine(y, gateX + gap, size.width);
      } else if (straining) {
        final swell = beatAt(e, t.strainBeats, IkkiuchiRankMotion.beatPulse);
        ink.classLine(y, 0, size.width,
            color: Palette.ink, width: IkkiuchiRankLayout.strainWidth + IkkiuchiRankLayout.strainSwell * swell);
      } else {
        ink.classLine(y, 0, size.width);
      }
      ink.classLabel(words.classLabel(band), y, captionBaseline,
          color: reached ? Palette.ink : IkkiuchiPageLayout.classLabelInk);
      if (broken) {
        burst(canvas, Offset(gateX, y), progressIn(e, t.breakAt, IkkiuchiRankMotion.burst),
            size: IkkiuchiRankLayout.breakBurst);
        _star(canvas, Offset(gateX, y), Entrances.bouncy.transform(progressIn(e, t.breakAt, IkkiuchiRankMotion.starPop)));
      }
    }
    ink.floor(scale, floor);
    if (line.length > 1) ink.line(line, style.line);
    ink.dots(share > 0 ? points : points.take(points.length - 1), style);

    var swell = 1 + _landed(e, t.landAt, IkkiuchiRankLayout.landSwell) + chipSwell;
    if (t.ranksUp) {
      swell += IkkiuchiRankLayout.strainSwellMark * beatAt(e, t.strainBeats, IkkiuchiRankMotion.beatPulse);
      if (e >= t.breakAt) {
        swell += IkkiuchiRankLayout.breakSwell *
            (1 - Curves.easeOutCubic.transform(progressIn(e, t.breakAt, IkkiuchiRankMotion.breakPulse)));
      }
    }
    final mark = share > 0 ? head : points.last;
    ink.diamond(mark, style.mark * swell, tone.deep, style.markRing);
    if (t.moment == IkkiuchiRankMoment.up) burst(canvas, mark, progressIn(e, t.landAt, IkkiuchiRankMotion.burst));
  }

  /// The ink star where the line broke through, [f] of the way popped in.
  void _star(Canvas canvas, Offset at, double f) {
    if (f <= 0) return;
    const n = IkkiuchiRankLayout.starPoints;
    final star = Path();
    for (var i = 0; i < 2 * n; i++) {
      final a = i / (2 * n) * 2 * math.pi - math.pi / 2;
      final r = (i.isOdd ? IkkiuchiRankLayout.starInner : IkkiuchiRankLayout.starOuter) * f;
      final p = at + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas
      ..drawPath(star, Paint()..color = Palette.sun)
      ..drawPath(
          star,
          Paint()
            ..color = Palette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = IkkiuchiRankLayout.starStroke
            ..strokeJoin = StrokeJoin.round);
  }
}

/// The placement chart: the estimate after each placement match over its
/// slot, dashed while an estimate, this match's step running to its place
/// and its slot stamped; the matches to come as quiet columns with their
/// step. Once the class shows the line turns solid, the class's band fills
/// and ここから marks where the rating curve starts.
class _ChartPainter extends _PlotPainter {
  _ChartPainter(super.timeline, super.elapsed, super.tone, super.words, super.scaler, super.pixelRatio);

  TextStyle _display(double size, Color color) =>
      TextStyle(fontFamily: Fonts.display, fontSize: size, height: 1, color: color);
  TextStyle _black(double size, Color color) =>
      TextStyle(fontFamily: Fonts.ui, fontWeight: Weights.black, fontSize: size, height: 1, color: color);

  @override
  void paint(Canvas canvas, Size size) {
    final t = timeline, e = elapsed;
    final chart = IkkiuchiRankChart(change.path, size);
    final ink = IkkiuchiCurveInk(canvas, scaler);
    final n = change.placement.length;
    final steps = IkkiuchiRankedTuning.placementSteps;
    final revealed = t.placed && e >= t.revealAt;
    final old = [for (var i = 0; i < n; i++) chart.at(i, change.path[i])];
    final share = t.shareAt(e);
    final head = IkkiuchiRankPlotPoints(change, size).along(share);
    final line = share > 0 ? [...old, head] : old;
    const labelRoom = IkkiuchiRankLayout.chartLabelRoom;

    if (revealed) {
      final band = change.to, next = Rating.nextBand(change.after);
      final top = chart.yOf(math.min(next?.minRating ?? chart.high, chart.high));
      final bottom = chart.yOf(math.max(band.minRating, chart.low));
      final f = Curves.easeOutCubic.transform(progressIn(e, t.revealAt, IkkiuchiRankMotion.bandFill));
      const left = labelRoom - IkkiuchiRankLayout.bandInset;
      canvas.drawRect(Rect.fromLTRB(left, top, left + (size.width - left) * f, bottom),
          Screentone.paint(tone.tone, pixelRatio));
    }
    for (final band in chart.bands) {
      final y = chart.yOf(band.minRating);
      ink.classLine(y, 0, size.width);
      ink.text(words.classLabel(band), _black(IkkiuchiPageLayout.curveLabelFont, IkkiuchiRankLayout.chartLabelInk), 0,
          y - IkkiuchiPageLayout.classLabelLift);
    }
    for (var i = n + 1; i <= steps.length; i++) {
      final x = chart.xOf(i);
      const dash = IkkiuchiRankLayout.futureDash;
      final paint = Paint()
        ..color = IkkiuchiRankLayout.futureInk
        ..strokeWidth = Strokes.hairline;
      for (var y = IkkiuchiRankLayout.chartTop; y < chart.floor; y += dash[0] + dash[1]) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(chart.floor, y + dash[0])), paint);
      }
      ink.text('±${steps[i - 1].round()}', _display(IkkiuchiRankLayout.futureFont, IkkiuchiRankLayout.chartLabelInk), x,
          IkkiuchiRankLayout.chartTop + IkkiuchiRankLayout.futureDrop,
          centred: true);
    }
    canvas.drawLine(
        Offset(labelRoom, chart.floor + IkkiuchiPageLayout.curveFloor / 2),
        Offset(size.width, chart.floor + IkkiuchiPageLayout.curveFloor / 2),
        Paint()
          ..color = Palette.ink
          ..strokeWidth = IkkiuchiPageLayout.curveFloor);

    for (var i = 1; i < line.length; i++) {
      if (i == line.length - 1 && share < 1) continue;
      final p = line[i];
      final step = (change.path[i] - change.path[i - 1]).round();
      final up = step > 0;
      final text = '${up ? '+' : '−'}${step.abs()}';
      final style = _display(IkkiuchiRankLayout.stepFont, Palette.ink);
      if (up) {
        final w = _width(text, style);
        ink.text(text, style, p.dx - IkkiuchiRankLayout.stepGap - w, p.dy - IkkiuchiRankLayout.stepLift);
      } else {
        ink.text(text, style, p.dx + IkkiuchiRankLayout.stepGap, p.dy + scaler.scale(IkkiuchiRankLayout.stepDrop));
      }
    }

    final path = Path()..moveTo(line.first.dx, line.first.dy);
    for (final p in line.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        revealed ? path : Dashes.of(path, IkkiuchiRankLayout.chartDash),
        Paint()
          ..color = Palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = IkkiuchiRankLayout.chartLine
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    final ring = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = IkkiuchiRankLayout.chartRing;
    for (final p in share > 0 ? old : old.take(old.length - 1)) {
      canvas
        ..drawCircle(p, IkkiuchiRankLayout.chartDot, Paint()..color = Palette.paper)
        ..drawCircle(p, IkkiuchiRankLayout.chartDot, ring);
    }
    var swell = 1 + _landed(e, t.landAt, IkkiuchiRankLayout.landSwell) + chipSwell;
    if (t.placed) {
      swell += IkkiuchiRankLayout.hiddenSwell * beatAt(e, t.suspenseBeats, IkkiuchiRankMotion.beatPulse);
      if (revealed) {
        swell += IkkiuchiRankLayout.revealSwell *
            (1 - Curves.easeOutCubic.transform(progressIn(e, t.revealAt, IkkiuchiRankMotion.breakPulse)));
      }
    }
    final mark = share > 0 ? head : old.last;
    ink.diamond(mark, IkkiuchiRankLayout.chartMark * swell, revealed ? tone.deep : Palette.paper,
        IkkiuchiRankLayout.chartMarkRing);

    if (revealed) _here(canvas, size, mark, progressIn(e, t.hereAt, IkkiuchiRankMotion.here));
    _axis(canvas, chart, ink);
  }

  /// ここから over the last point, at the plot's right, [f] of the way in.
  void _here(Canvas canvas, Size size, Offset at, double f) {
    if (f <= 0) return;
    final font = IkkiuchiRankLayout.hereFont;
    final w = words.here.length * scaler.scale(font) * (words.latin ? IkkiuchiRankLayout.hereLatinShare : 1) +
        2 * IkkiuchiRankLayout.herePad;
    final h = scaler.scale(IkkiuchiRankLayout.hereHeight);
    final box = Rect.fromLTWH(size.width - w, at.dy - IkkiuchiRankLayout.hereLift - h, w, h);
    canvas.saveLayer(box.inflate(1), Paint()..color = Palette.ink.withValues(alpha: f));
    canvas.drawRect(box, Paint()..color = Palette.ink);
    final text = TextPainter(
      text: TextSpan(text: words.here, style: _black(font, Palette.paper)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    text.paint(canvas, box.center - Offset(text.width / 2, text.height / 2));
    text.dispose();
    canvas.restore();
  }

  /// The axis under the chart: 開始 and the start rating under the first
  /// point, then a slot for each placement match: played ones 勝 or 負
  /// (this match's stamped in as it lands), the next one in ink, the rest
  /// dashed.
  void _axis(Canvas canvas, IkkiuchiRankChart chart, IkkiuchiCurveInk ink) {
    final t = timeline, e = elapsed;
    final n = change.placement.length;
    final top = chart.floor + IkkiuchiRankLayout.slotTop;
    ink.text(words.start, _black(IkkiuchiRankLayout.startFont, IkkiuchiRankLayout.startInk), chart.xOf(0),
        top + scaler.scale(IkkiuchiRankLayout.startDrop),
        centred: true);
    ink.text('${IkkiuchiRating.start.round()}', _display(IkkiuchiRankLayout.startFont, IkkiuchiRankLayout.startInk),
        chart.xOf(0), chart.yOf(IkkiuchiRating.start) + scaler.scale(IkkiuchiRankLayout.startRatingDrop),
        centred: true);
    const z = IkkiuchiRankLayout.slot;
    for (var k = 1; k <= IkkiuchiRating.placementMatches; k++) {
      final centre = Offset(chart.xOf(k), top + z / 2);
      final box = Rect.fromCenter(center: centre, width: z, height: z);
      final played = k < n || (k == n && e >= t.tagAt);
      if (played) {
        final won = change.placement[k - 1];
        final stamp = k == n
            ? const StepCurve(3, Entrances.bouncy).transform(progressIn(e, t.tagAt, IkkiuchiRankMotion.slotStamp))
            : 1.0;
        canvas.save();
        canvas.translate(centre.dx, centre.dy);
        canvas.rotate(lerpDouble(-12, 0, stamp)! * math.pi / 180);
        final grow = lerpDouble(1.8, 1, stamp)!;
        canvas.scale(grow);
        final local = Rect.fromCenter(center: Offset.zero, width: z, height: z);
        canvas.saveLayer(local.inflate(z), Paint()..color = Palette.ink.withValues(alpha: (stamp / 0.2).clamp(0.0, 1.0)));
        canvas.drawRect(local, Paint()..color = won ? Palette.ink : Palette.paper);
        canvas.drawRect(
            local,
            Paint()
              ..color = Palette.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = IkkiuchiRankLayout.slotBorder);
        _centred(canvas, won ? words.won : words.lost,
            _black(IkkiuchiRankLayout.slotFont, won ? Palette.paper : IkkiuchiRankLayout.lostInk), Offset.zero);
        canvas.restore();
        canvas.restore();
        continue;
      }
      final next = k == n;
      final edge = Paint()
        ..color = next ? Palette.ink : IkkiuchiRankLayout.slotInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = next ? IkkiuchiRankLayout.nextSlotBorder : IkkiuchiRankLayout.slotBorder;
      canvas.drawRect(box, Paint()..color = Palette.paper);
      final outline = Path()..addRect(box);
      canvas.drawPath(next ? outline : Dashes.of(outline, IkkiuchiRankLayout.slotDash), edge);
      _centred(canvas, '$k', _display(IkkiuchiRankLayout.slotNumber, next ? Palette.ink : IkkiuchiRankLayout.slotInk),
          centre);
    }
  }

  void _centred(Canvas canvas, String text, TextStyle style, Offset at) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
  }

  double _width(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }
}
