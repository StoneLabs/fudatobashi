import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// A ranked mode's rating after each of its last ranked matches
/// ([ratings], oldest first), on a line in the app's chart style: an ink
/// line with small ringed dots, the latest match a diamond in the mode's
/// [tone] colour, the ground under the line in its halftone, and the class
/// lines in its range dashed and named. Each of
/// [IkkiuchiModeTuning.curveMatches] matches has its slot from the left, so
/// a short line ends early and a note in the rest says it grows. The
/// caption left of the floor says how many matches it shows.
class IkkiuchiRatingCurve extends StatelessWidget {
  const IkkiuchiRatingCurve(this.ratings, {super.key, required this.tone});

  final List<double> ratings;
  final IkkiuchiModeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: IkkiuchiPageLayout.curveHeight,
      child: CustomPaint(
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
      ),
    );
  }
}

/// While the player is being placed in a mode: the curve's room, dashed,
/// saying the curve comes once placement is over.
class IkkiuchiCurveNote extends StatelessWidget {
  const IkkiuchiCurveNote({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: IkkiuchiPageLayout.curveHeight,
        child: DashedBox(
          ink: IkkiuchiPageLayout.lightRule,
          border: IkkiuchiPageLayout.curveNoteBorder,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: IkkiuchiPageLayout.curveNotePadding),
              child: Text.rich(
                Phrases.span(S.of(context).ikkiuchiCurveLater),
                textAlign: TextAlign.center,
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

  static const _label = TextStyle(
      fontFamily: Fonts.ui, fontWeight: Weights.black, fontSize: IkkiuchiPageLayout.curveLabelFont, height: 1);

  /// [text] in [style], laid out on one line.
  TextPainter _text(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();

  /// Paints [text] with its start at [x] (or its middle, [centred]) and its
  /// baseline at [baseline].
  void _paintText(Canvas canvas, TextPainter text, double x, double baseline, {bool centred = false}) {
    final top = baseline - text.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    text.paint(canvas, Offset(centred ? x - text.width / 2 : x, top));
    text.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.isEmpty) return;
    const l = IkkiuchiPageLayout.curveLabelRoom, inset = IkkiuchiPageLayout.curveInset;
    final w = size.width, h = size.height;
    final least = ratings.reduce(math.min), most = ratings.reduce(math.max);
    final pad = math.max(IkkiuchiPageLayout.curveMinPad, (most - least) * IkkiuchiPageLayout.curveRangeShare);
    final lo = least - pad, hi = most + pad;
    final right = w - inset;
    Offset at(int i, double r) => Offset(
          l + (right - l) * i / (IkkiuchiModeTuning.curveMatches - 1),
          IkkiuchiPageLayout.curveTop + (h - IkkiuchiPageLayout.curveTop) * (hi - r) / (hi - lo),
        );
    final points = [for (final (i, r) in ratings.indexed) at(i, r)];

    if (points.length > 1) {
      final ground = Path()..moveTo(points.first.dx, h);
      for (final p in points) {
        ground.lineTo(p.dx, p.dy);
      }
      ground
        ..lineTo(points.last.dx, h)
        ..close();
      canvas.drawPath(ground, Screentone.paint(tone.tone, pixelRatio));
    }

    final captionBaseline = h - IkkiuchiPageLayout.captionDrop;
    _paintText(
        canvas,
        _text(caption,
            _label.copyWith(color: IkkiuchiPageLayout.captionInk, letterSpacing: IkkiuchiPageLayout.captionTracking)),
        0,
        captionBaseline);

    final classLine = Paint()
      ..color = IkkiuchiPageLayout.classLine
      ..strokeWidth = IkkiuchiPageLayout.classLineWidth;
    for (final band in Rating.bands) {
      final r = band.minRating;
      if (!r.isFinite || r <= lo || r >= hi) continue;
      final y = at(0, r).dy;
      for (var x = 0.0; x < w; x += Strokes.dash[0] + Strokes.dash[1]) {
        canvas.drawLine(Offset(x, y), Offset(math.min(w, x + Strokes.dash[0]), y), classLine);
      }
      final baseline =
          math.min(y - IkkiuchiPageLayout.classLabelLift, captionBaseline - IkkiuchiPageLayout.classLabelClear);
      _paintText(canvas, _text(classLabel(band), _label.copyWith(color: IkkiuchiPageLayout.classLabelInk)), 0, baseline);
    }

    final floorY = h - IkkiuchiPageLayout.curveFloor / 2;
    canvas.drawLine(
        Offset(l - inset, floorY),
        Offset(w, floorY),
        Paint()
          ..color = Palette.ink
          ..strokeWidth = IkkiuchiPageLayout.curveFloor);

    if (points.length > 1) {
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          line,
          Paint()
            ..color = Palette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = IkkiuchiPageLayout.curveLine
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }

    final ring = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = IkkiuchiPageLayout.curveRing;
    for (final p in points.take(points.length - 1)) {
      canvas.drawCircle(p, IkkiuchiPageLayout.curveDot, Paint()..color = Palette.paper);
      canvas.drawCircle(p, IkkiuchiPageLayout.curveDot, ring);
    }
    final last = points.last;
    const d = IkkiuchiPageLayout.curveMark;
    final diamond = Path()
      ..moveTo(last.dx, last.dy - d)
      ..lineTo(last.dx + d, last.dy)
      ..lineTo(last.dx, last.dy + d)
      ..lineTo(last.dx - d, last.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = tone.deep);
    canvas.drawPath(diamond, ring);

    if (grows case final grows?) {
      _paintText(
        canvas,
        _text(
            grows,
            const TextStyle(
                fontFamily: Fonts.ui,
                fontWeight: Weights.bold,
                fontSize: IkkiuchiPageLayout.growsFont,
                height: 1,
                color: IkkiuchiPageLayout.captionInk)),
        (last.dx + right) / 2 + d,
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
