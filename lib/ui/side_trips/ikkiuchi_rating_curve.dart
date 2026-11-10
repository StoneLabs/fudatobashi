import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_rating.dart';
import '../../domain/rank_ladder.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';

/// A ranked mode's rating after each of its last ranked matches
/// ([ratings], oldest first), on a line in the app's chart style: an ink
/// line with small ringed dots, the latest match a diamond in the mode's
/// [tone] colour, the ground under the line in its halftone, and the class
/// lines in its range dashed and named. Each of
/// [IkkiuchiModeTuning.curveMatches] matches has its slot from the left, so
/// a short line ends early and a note in the rest says it grows. The
/// caption left of the floor says how many matches it shows. It fills the
/// room it is given.
class IkkiuchiRatingCurve extends StatelessWidget {
  const IkkiuchiRatingCurve(this.ratings, {super.key, required this.tone});

  final List<double> ratings;
  final IkkiuchiModeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return CustomPaint(
      size: Size.infinite,
      painter: _CurvePainter(
        ratings,
        tone: tone,
        caption: s.ikkiuchiCurveLast(ratings.length),
        grows: ratings.length < IkkiuchiModeTuning.curveMatches ? s.ikkiuchiCurveGrows : null,
        classLabel: (band) => '${s.className(band)} ${band.minRating.round()}',
        scaler: MediaQuery.textScalerOf(context),
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
    );
  }
}

/// While the player is being placed in a mode: the curve's room, dashed,
/// saying on one line, shrinking to fit, that the curve comes once
/// placement is over.
class IkkiuchiCurveNote extends StatelessWidget {
  const IkkiuchiCurveNote({super.key});

  @override
  Widget build(BuildContext context) => DashedBox(
        ink: IkkiuchiPageLayout.lightRule,
        border: IkkiuchiPageLayout.curveNoteBorder,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: IkkiuchiPageLayout.curveNotePadding),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                Phrases.span(S.of(context).ikkiuchiCurveLater),
                maxLines: 1,
                style: const TextStyle(
                  fontWeight: Weights.bold,
                  fontSize: IkkiuchiPageLayout.curveNoteFont,
                  color: IkkiuchiPageLayout.captionInk,
                ),
              ),
            ),
          ),
        ),
      );
}

/// While the player is being placed in a mode, once a placement match is
/// played: the estimate at the start and after each of them ([path]), in
/// the curve's style, each placement match in its own slot from the left
/// after the start's. The line dashed while an estimate, the start and the
/// matches before the latest small ringed dots, the latest a paper
/// diamond, and the class lines in its range dashed from where the floor
/// starts, so that their names left of them stay clear; a name kept up by
/// the caption past the middle of its line's slot, or crowding the name
/// under it, is left out. The caption left of the floor says it is an
/// estimate. It fills the room it is given.
class IkkiuchiPlacementCurve extends StatelessWidget {
  const IkkiuchiPlacementCurve(this.path, {super.key});

  final List<double> path;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return CustomPaint(
      size: Size.infinite,
      painter: _PlacementPainter(
        path,
        caption: s.ikkiuchiCurveEstimate,
        classLabel: (band) => '${s.className(band)} ${band.minRating.round()}',
        scaler: MediaQuery.textScalerOf(context),
      ),
    );
  }
}

class _PlacementPainter extends CustomPainter {
  _PlacementPainter(this.path, {required this.caption, required this.classLabel, required this.scaler});

  final List<double> path;
  final String caption;
  final String Function(RankBand band) classLabel;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    const style = IkkiuchiPageLayout.curve;
    final scale = IkkiuchiCurveScale(path, size, style, slots: IkkiuchiRating.placementMatches + 1);
    final ink = IkkiuchiCurveInk(canvas, scaler);
    final h = size.height;
    final points = [for (final (i, r) in path.indexed) scale.at(i, r)];

    final captionBaseline = ink.caption(caption, h);
    final labelHeight = scaler.scale(IkkiuchiPageLayout.curveLabelFont);
    final lines = [for (final band in scale.bands) (band, scale.yOf(band.minRating))];
    double? named;
    for (final (i, (band, y)) in lines.indexed) {
      ink.classLine(y, scale.floorStart, size.width);
      final baseline = ink.labelBaseline(y, captionBaseline);
      final above = i + 1 < lines.length ? lines[i + 1].$2 : null;
      final inSlot = above == null || baseline - labelHeight / 2 > above;
      if (inSlot && (named == null || named - baseline >= labelHeight)) {
        ink.classLabel(classLabel(band), y, captionBaseline);
        named = baseline;
      }
    }
    ink.floor(scale, h);
    ink.line(points, style.line, dash: IkkiuchiPageLayout.placementDash);
    ink.dots(points.take(points.length - 1), style);
    ink.diamond(points.last, style.mark, Palette.paper, IkkiuchiPageLayout.placementMarkRing);
  }

  @override
  bool shouldRepaint(_PlacementPainter old) =>
      !listEquals(old.path, path) || old.caption != caption || old.scaler != scaler;
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(
    this.ratings, {
    required this.tone,
    required this.caption,
    required this.grows,
    required this.classLabel,
    required this.scaler,
    required this.pixelRatio,
  });

  final List<double> ratings;
  final IkkiuchiModeTone tone;
  final String caption;
  final String? grows;
  final String Function(RankBand band) classLabel;
  final TextScaler scaler;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.isEmpty) return;
    const style = IkkiuchiPageLayout.curve;
    final scale = IkkiuchiCurveScale(ratings, size, style);
    final ink = IkkiuchiCurveInk(canvas, scaler);
    final h = size.height;
    final points = [for (final (i, r) in ratings.indexed) scale.at(i, r)];

    if (points.length > 1) ink.ground(points, h, tone.tone, pixelRatio);
    final captionBaseline = ink.caption(caption, h);
    for (final band in scale.bands) {
      final y = scale.yOf(band.minRating);
      ink.classLine(y, 0, size.width);
      ink.classLabel(classLabel(band), y, captionBaseline);
    }
    ink.floor(scale, h);
    if (points.length > 1) ink.line(points, style.line);
    ink.dots(points.take(points.length - 1), style);
    final last = points.last;
    ink.diamond(last, style.mark, tone.deep, style.markRing);

    if (grows case final grows?) {
      ink.text(
        grows,
        const TextStyle(
            fontFamily: Fonts.ui,
            fontWeight: Weights.bold,
            fontSize: IkkiuchiPageLayout.growsFont,
            height: 1,
            color: IkkiuchiPageLayout.captionInk),
        (last.dx + scale.right) / 2 + style.mark,
        h - IkkiuchiPageLayout.growsDrop,
        centred: true,
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      !listEquals(old.ratings, ratings) ||
      old.tone != tone ||
      old.caption != caption ||
      old.grows != grows ||
      old.scaler != scaler ||
      old.pixelRatio != pixelRatio;
}

/// Where a ranked mode's rating curve, drawn by [style] on a canvas of
/// [size], puts its matches: the [ratings]' range padded by the style,
/// from [lo] at the foot to [hi] at the style's top, and each of [slots]
/// matches ([IkkiuchiModeTuning.curveMatches] unless given) in its own
/// slot from the left.
class IkkiuchiCurveScale {
  factory IkkiuchiCurveScale(Iterable<double> ratings, Size size, IkkiuchiCurveStyle style,
      {int slots = IkkiuchiModeTuning.curveMatches}) {
    final least = ratings.reduce(math.min), most = ratings.reduce(math.max);
    final pad = math.max(style.minPad, (most - least) * style.rangeShare);
    return IkkiuchiCurveScale._(size, style, least - pad, most + pad, slots);
  }

  IkkiuchiCurveScale._(this.size, this.style, this.lo, this.hi, this.slots);

  final Size size;
  final IkkiuchiCurveStyle style;
  final double lo, hi;
  final int slots;

  /// Where the last slot sits.
  double get right => size.width - style.inset;

  /// Where the floor starts: the style's inset left of the first slot.
  double get floorStart => style.labelRoom - style.inset;

  /// Match [i]'s point at [rating].
  Offset at(int i, double rating) =>
      Offset(style.labelRoom + (right - style.labelRoom) * i / (slots - 1), yOf(rating));

  double yOf(double rating) => style.top + (size.height - style.top) * (hi - rating) / (hi - lo);

  /// The classes whose lines fall inside the range, lowest first.
  Iterable<RankBand> get bands =>
      RankLadder.bands.where((b) => b.minRating.isFinite && b.minRating > lo && b.minRating < hi);
}

/// The rating curve's ink on [canvas], its words scaled by [scaler]: what
/// the 一騎打ち page's curve is drawn with, for any page that draws one.
class IkkiuchiCurveInk {
  const IkkiuchiCurveInk(this.canvas, this.scaler);

  final Canvas canvas;
  final TextScaler scaler;

  static const _label = TextStyle(
      fontFamily: Fonts.ui, fontWeight: Weights.black, fontSize: IkkiuchiPageLayout.curveLabelFont, height: 1);

  /// Paints [text] in [style] on one line, its start at [x] (or its
  /// middle, [centred]) and its baseline at [baseline].
  void text(String text, TextStyle style, double x, double baseline, {bool centred = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final top = baseline - painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(canvas, Offset(centred ? x - painter.width / 2 : x, top));
    painter.dispose();
  }

  /// The ground under the line through [points], down to [floor], in [tone].
  void ground(List<Offset> points, double floor, ToneSpec tone, double pixelRatio) {
    final ground = Path()..moveTo(points.first.dx, floor);
    for (final p in points) {
      ground.lineTo(p.dx, p.dy);
    }
    ground
      ..lineTo(points.last.dx, floor)
      ..close();
    canvas.drawPath(ground, Screentone.paint(tone, pixelRatio));
  }

  /// The [caption] left of the floor at [floor]; returns its baseline.
  double caption(String caption, double floor) {
    final baseline = floor - IkkiuchiPageLayout.captionDrop;
    text(caption, _label.copyWith(color: IkkiuchiPageLayout.captionInk, letterSpacing: IkkiuchiPageLayout.captionTracking),
        0, baseline);
    return baseline;
  }

  /// A dashed class line at [y] from [from] to [to], [width] wide in [color].
  void classLine(double y, double from, double to,
      {Color color = IkkiuchiPageLayout.classLine, double width = IkkiuchiPageLayout.classLineWidth}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    for (var x = from; x < to; x += Strokes.dash[0] + Strokes.dash[1]) {
      canvas.drawLine(Offset(x, y), Offset(math.min(to, x + Strokes.dash[0]), y), paint);
    }
  }

  /// A class line's [name] over its line at [y], kept clear of the caption
  /// on [captionBaseline] ([labelBaseline]), in [color].
  void classLabel(String name, double y, double captionBaseline, {Color color = IkkiuchiPageLayout.classLabelInk}) =>
      text(name, _label.copyWith(color: color), 0, labelBaseline(y, captionBaseline));

  /// Where the name of a class line at [y] stands, kept clear of the
  /// caption on [captionBaseline].
  double labelBaseline(double y, double captionBaseline) =>
      math.min(y - IkkiuchiPageLayout.classLabelLift, captionBaseline - IkkiuchiPageLayout.classLabelClear);

  /// The floor under the curve of [scale], at [floor].
  void floor(IkkiuchiCurveScale scale, double floor) {
    final y = floor - IkkiuchiPageLayout.curveFloor / 2;
    canvas.drawLine(
        Offset(scale.floorStart, y),
        Offset(scale.size.width, y),
        Paint()
          ..color = Palette.ink
          ..strokeWidth = IkkiuchiPageLayout.curveFloor);
  }

  /// The ink line through [points], [width] wide, in [dash] when given.
  void line(List<Offset> points, double width, {List<double>? dash}) {
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        dash == null ? line : Dashes.of(line, dash),
        Paint()
          ..color = Palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
  }

  /// A ringed paper dot at each of [points].
  void dots(Iterable<Offset> points, IkkiuchiCurveStyle style) {
    final ring = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.ring;
    for (final p in points) {
      canvas.drawCircle(p, style.dot, Paint()..color = Palette.paper);
      canvas.drawCircle(p, style.dot, ring);
    }
  }

  /// A diamond at [at] reaching [reach] each way, filled [color] and
  /// ringed [ring] wide.
  void diamond(Offset at, double reach, Color color, double ring) {
    final diamond = Path()
      ..moveTo(at.dx, at.dy - reach)
      ..lineTo(at.dx + reach, at.dy)
      ..lineTo(at.dx, at.dy + reach)
      ..lineTo(at.dx - reach, at.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = color);
    canvas.drawPath(
        diamond,
        Paint()
          ..color = Palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring);
  }
}
