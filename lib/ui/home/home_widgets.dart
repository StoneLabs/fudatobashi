import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/rating.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';
import '../manga/svg_path.dart';

enum PipState { learned, next, locked }

/// A row of little torifuda, one per card of an island.
class CardPips extends StatelessWidget {
  const CardPips(this.pips, {super.key});

  final List<PipState> pips;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final n = pips.length;
      final fit = (box.maxWidth - HomeLayout.pipGap * (n - 1)) / n;
      final w = fit < HomeLayout.pipWidth ? fit : HomeLayout.pipWidth;
      final h = w * HomeLayout.pipHeight / HomeLayout.pipWidth;
      return Row(
        children: [
          for (final (i, p) in pips.indexed) ...[
            if (i > 0) const SizedBox(width: HomeLayout.pipGap),
            SizedBox(width: w, height: h, child: _Pip(p)),
          ],
        ],
      );
    });
  }
}

class _Pip extends StatelessWidget {
  const _Pip(this.state);
  final PipState state;

  @override
  Widget build(BuildContext context) => switch (state) {
        PipState.learned => DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.cardFrame,
              border: Border.all(color: Palette.ink, width: Strokes.control),
              borderRadius: BorderRadius.circular(HomeLayout.pipRadius),
            ),
            child: const Padding(
              padding: EdgeInsets.all(HomeLayout.pipInset - Strokes.control / 2),
              child: ColoredBox(color: Palette.cardPaper),
            ),
          ),
        PipState.next => const DashedBox(
            color: Palette.sun,
            dash: Strokes.fineDash,
            radius: HomeLayout.pipRadius,
            child: SizedBox.expand(),
          ),
        PipState.locked => const DashedBox(
            dash: Strokes.fineDash,
            radius: HomeLayout.pipRadius,
            child: SizedBox.expand(),
          ),
      };
}

/// The streak as 正 tally marks: five days make one 正. Shows the last two
/// characters; today's newest stroke is pink, strokes still to come are faint.
class TallyMarks extends StatelessWidget {
  const TallyMarks(this.days, {super.key});

  final int days;

  @override
  Widget build(BuildContext context) =>
      SizedBox.fromSize(size: Tally.box, child: CustomPaint(painter: _TallyPainter(days)));
}

class _TallyPainter extends CustomPainter {
  _TallyPainter(this.days);
  final int days;

  @override
  void paint(Canvas canvas, Size size) {
    final per = Tally.strokes.length;
    final firstGroup = math.max(0, (days - 1) ~/ per - 1);
    final s = size.width / Tally.box.width;
    canvas.save();
    canvas.scale(s);
    for (var g = 0; g < 2; g++) {
      final group = firstGroup + g;
      for (var k = 0; k < per; k++) {
        final n = group * per + k + 1;
        final path = SvgPath.parse(Tally.strokes[k]).shift(Offset(g * Tally.glyphAdvance, 0));
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        if (n <= days) {
          paint
            ..color = n == days ? Palette.pink : Palette.ink
            ..strokeWidth = n == days ? Tally.latestStroke : Tally.stroke;
          canvas.drawPath(path, paint);
        } else {
          paint
            ..color = Palette.ink.withValues(alpha: Tally.ghostOpacity)
            ..strokeWidth = Tally.ghostStroke;
          canvas.drawPath(Dashes.of(path, Tally.ghostDash), paint);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TallyPainter old) => old.days != days;
}

/// The class (級) on a yellow sticker: "F上" big, "級" small.
class RankSticker extends StatelessWidget {
  const RankSticker(this.band, {super.key});

  final RankBand band;

  @override
  Widget build(BuildContext context) {
    const suffix = '級';
    final main = band.label.endsWith(suffix) ? band.label.substring(0, band.label.length - 1) : band.label;
    return Sticker(
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: main, style: const TextStyle(fontSize: HomeLayout.classFont)),
          if (main != band.label)
            const TextSpan(text: suffix, style: TextStyle(fontSize: HomeLayout.classSuffixFont)),
        ]),
        style: const TextStyle(fontFamily: Fonts.display, height: 1),
      ),
    );
  }
}

/// Progress toward the next class.
class RatingBar extends StatelessWidget {
  const RatingBar(this.fraction, {super.key});

  final double fraction;

  @override
  Widget build(BuildContext context) => Container(
        width: HomeLayout.ratingBarWidth,
        height: HomeLayout.ratingBarHeight,
        decoration: BoxDecoration(
          color: Palette.paper,
          border: Border.all(color: Palette.ink, width: Strokes.label),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          heightFactor: 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.pink,
              border: Border(right: BorderSide(color: Palette.ink, width: Strokes.label)),
            ),
          ),
        ),
      );
}

/// A small black "UNTRACKED" label.
class UntrackedLabel extends StatelessWidget {
  const UntrackedLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => InkTag(
        text,
        fontSize: HomeLayout.untrackedFont,
        tracking: HomeLayout.untrackedTracking,
        padding: HomeLayout.untrackedPadding,
      );
}
