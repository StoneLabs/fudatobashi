import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// The ground a replayed field lies on, inside an ink border.
class FieldGround extends StatelessWidget {
  const FieldGround({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: FieldReviewStyle.ground,
          border: Border.all(color: Palette.ink, width: Strokes.label),
        ),
        child: child,
      );
}

/// One card of a reviewed field: its kimariji in [color] on [fill],
/// outlined heavier when [current], with a [foot] under the word.
class FieldWordCard extends StatelessWidget {
  const FieldWordCard(this.poemId,
      {super.key, required this.fill, required this.color, this.current = false, this.foot});
  final int poemId;
  final Color fill, color;
  final bool current;
  final Widget? foot;

  @override
  Widget build(BuildContext context) {
    final foot = this.foot;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
            color: Palette.ink, width: current ? FieldReviewStyle.highlight : FieldReviewStyle.cardBorder),
      ),
      child: Padding(
        padding: FieldReviewStyle.cardPadding,
        child: foot == null
            ? FieldWord(poemId, color: color)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: FieldWord(poemId, color: color)),
                foot,
              ]),
      ),
    );
  }
}

/// A card's kimariji down the card in [color], shrunk to fit it: kana a
/// letter a line, romaji turned along the card.
class FieldWord extends StatelessWidget {
  const FieldWord(this.poemId, {super.key, required this.color});
  final int poemId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = kimarijiFor(context, poemId);
    final kana = text.runes.any((r) => r >= _kanaStart);
    final word = Text(kana ? text.split('').join('\n') : text,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: Weights.black, fontSize: FieldReviewStyle.cardFont, height: 1, color: color));
    return Center(
      child: FittedBox(fit: BoxFit.scaleDown, child: kana ? word : RotatedBox(quarterTurns: 1, child: word)),
    );
  }

  /// Where the kana blocks start: romaji, macrons and all, sits below.
  static const _kanaStart = 0x3040;
}

/// The band across a replayed field: their side up (when it shows), yours
/// down.
class FieldBand extends StatelessWidget {
  const FieldBand({super.key, required this.their, required this.yours});
  final String? their;
  final String yours;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: Weights.black, fontSize: FieldReviewStyle.bandFont, color: Palette.paper);
    final their = this.their;
    return ColoredBox(
      color: Palette.ink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.small),
        child: Row(children: [
          if (their != null) ...[Text('${their.toUpperCase()} ↑', style: style), const Spacer()],
          Text('${yours.toUpperCase()} ↓', style: style),
        ]),
      ),
    );
  }
}

/// An arrow of a step across a replayed field, [from] a point [to]
/// another, in [color], dashed when [dashed].
typedef StepArrow = ({Offset from, Offset to, Color color, bool dashed});

/// A step's numbered badge on the [card] it marks.
typedef StepBadge = ({Rect card, int number});

/// A step's marks over a replayed field: its [arrows] in order, each bowed
/// toward the field's middle with its head at its end, then its [badges]
/// over them, each at its card's top right, the later ones on a card left
/// of the earlier.
class StepMarks extends CustomPainter {
  StepMarks({required this.arrows, required this.badges});
  final List<StepArrow> arrows;
  final List<StepBadge> badges;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.center(Offset.zero);
    for (final a in arrows) {
      _arrow(canvas, a, middle);
    }
    final onCard = <Rect, int>{};
    for (final b in badges) {
      final before = onCard.update(b.card, (n) => n + 1, ifAbsent: () => 0);
      const r = FieldReviewStyle.marker / 2;
      TapBadge.draw(canvas, b.card.topRight + Offset(-r - before * FieldReviewStyle.marker, r), b.number,
          size: FieldReviewStyle.marker);
    }
  }

  static void _arrow(Canvas canvas, StepArrow a, Offset middle) {
    final line = Paint()
      ..color = a.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = FieldReviewStyle.arrowStroke;
    final (from, to) = (a.from, a.to);
    final d = to - from;
    final normal = Offset(-d.dy, d.dx) * FieldReviewStyle.arrowBend;
    final halfway = from + d / 2;
    final control = (halfway + normal - middle).distance <= (halfway - normal - middle).distance
        ? halfway + normal
        : halfway - normal;
    final shaft = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
    canvas.drawPath(a.dashed ? Dashes.of(shaft, FieldReviewStyle.laterDash) : shaft, line);
    final back = (control - to).direction;
    const spread = FieldReviewStyle.arrowSpread;
    const head = FieldReviewStyle.arrowHead;
    canvas.drawPath(
      Path()
        ..moveTo(to.dx + head * math.cos(back + spread), to.dy + head * math.sin(back + spread))
        ..lineTo(to.dx, to.dy)
        ..lineTo(to.dx + head * math.cos(back - spread), to.dy + head * math.sin(back - spread)),
      line,
    );
  }

  @override
  bool shouldRepaint(StepMarks old) => !listEquals(old.arrows, arrows) || !listEquals(old.badges, badges);
}

/// A step's number in a circle: the first filled pink, later ones
/// pink-ringed paper, like their solid and dashed arrows.
class TapBadge extends CustomPainter {
  const TapBadge(this.number);
  final int number;

  static void draw(Canvas canvas, Offset centre, int number, {required double size}) {
    final first = number == 1;
    final r = size / 2;
    canvas.drawCircle(centre, r, Paint()..color = first ? FieldReviewStyle.arrow : Palette.paper);
    canvas.drawCircle(centre, r - FieldReviewStyle.markerRing / 2, Paint()
      ..color = first ? Palette.paper : FieldReviewStyle.arrow
      ..style = PaintingStyle.stroke
      ..strokeWidth = first ? Strokes.hairline : FieldReviewStyle.markerRing);
    final label = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
            fontFamily: Fonts.ui,
            fontWeight: Weights.black,
            fontSize: size * FieldReviewStyle.markerFontShare,
            color: first ? Palette.paper : FieldReviewStyle.arrow),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, centre - Offset(label.width / 2, label.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size.center(Offset.zero), number, size: size.shortestSide);

  @override
  bool shouldRepaint(TapBadge old) => old.number != number;
}

/// The legend's mark of a step's [number]th mark: its arrow's line, solid
/// for the first and dashed after, and its badge.
class TapLegendMark extends StatelessWidget {
  const TapLegendMark(this.number, {super.key});
  final int number;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        LegendMark.line(FieldReviewStyle.arrow, dashed: number > 1),
        const SizedBox(width: Gaps.tight),
        SizedBox.square(
          dimension: FieldReviewStyle.legendMarker,
          child: CustomPaint(painter: TapBadge(number)),
        ),
      ]);
}

/// A small button back from the review to the whole field, [label] after
/// a cross.
class ShowAllButton extends StatelessWidget {
  const ShowAllButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
        child: InkButton(
          onTap: onTap,
          border: Strokes.label,
          padding: FieldReviewStyle.showAllPadding,
          semanticLabel: label,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            MangaIcon(IconArt.close, size: FieldReviewStyle.showAllIcon),
            const SizedBox(width: Gaps.tight),
            Text(label,
                maxLines: 1, style: const TextStyle(fontWeight: Weights.black, fontSize: FieldReviewStyle.showAllFont)),
          ]),
        ),
      );
}

/// A line of a [StepBox]'s table: its [label], and its [value], numbered
/// chips standing on the line's foot when [chips].
class StepRow {
  const StepRow(this.label, this.value, {this.chips = false});
  final String label;
  final Widget value;
  final bool chips;
}

/// The box stepping through a replayed field: the step's [count], the
/// kimariji of [poemId] (with a [tag] beside it, a からふだ's), then its
/// [rows], a [note] line, and back, [onShowAll] and forward, back and
/// forward faded without [onBack] or [onNext]. Every line keeps its slot,
/// so the box is as tall for every step.
class StepBox extends StatelessWidget {
  const StepBox({
    super.key,
    required this.count,
    required this.poemId,
    this.tag,
    required this.rows,
    required this.note,
    required this.backLabel,
    required this.nextLabel,
    required this.showAllLabel,
    required this.onBack,
    required this.onNext,
    required this.onShowAll,
  });

  final String count;
  final int poemId;
  final String? tag;
  final List<StepRow> rows;
  final String note, backLabel, nextLabel, showAllLabel;
  final VoidCallback? onBack, onNext;
  final VoidCallback onShowAll;

  /// A line's value as text.
  static Widget text(String value) => Text(value,
      maxLines: 1,
      style: const TextStyle(fontWeight: Weights.black, fontSize: StepBoxStyle.valueFont, height: 1));

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    double line(double height) => scaler.scale(height);
    final rowHeight = line(StepBoxStyle.rowLine);
    final tag = this.tag;
    // Labels sit on the line of a value's text, which is centred; chips
    // stand on the slot's foot, their words about on that line.
    TableRow row(StepRow r) => TableRow(children: [
          StepSlot(
            height: rowHeight,
            alignment: Alignment.bottomLeft,
            inset: (rowHeight - line(StepBoxStyle.valueFont)) / 2,
            child: Text(r.label.toUpperCase(),
                maxLines: 1,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: StepBoxStyle.labelFont,
                    letterSpacing: StepBoxStyle.labelTracking * StepBoxStyle.labelFont,
                    height: 1,
                    color: StepBoxStyle.label)),
          ),
          const SizedBox.shrink(),
          StepSlot(height: rowHeight, alignment: r.chips ? Alignment.bottomLeft : Alignment.centerLeft, child: r.value),
        ]);
    Widget button(VectorArt icon, String label, VoidCallback? onTap) => Opacity(
          opacity: onTap == null ? ChartStyle.dimOpacity : 1,
          child: InkIconButton(icon: icon, semanticLabel: label, onTap: onTap),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      StepSlot(height: line(StepBoxStyle.countLine), alignment: Alignment.center, child: ShelfLabel(count)),
      const SizedBox(height: StepBoxStyle.countGap),
      StepSlot(
        height: StepBoxStyle.wordLine,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(kimarijiFor(context, poemId),
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: StepBoxStyle.wordFont, height: 1)),
            if (tag != null) ...[const SizedBox(width: StepBoxStyle.tagGap), KarafudaTag(tag)],
          ],
        ),
      ),
      const SizedBox(height: StepBoxStyle.tableGap),
      Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FixedColumnWidth(StepBoxStyle.labelGap),
          2: FlexColumnWidth(),
        },
        children: [for (final r in rows) row(r)],
      ),
      StepSlot(
        height: line(StepBoxStyle.noteLine),
        child: Text(note,
            maxLines: 1,
            style: const TextStyle(
                fontWeight: Weights.bold, fontSize: StepBoxStyle.noteFont, height: 1, color: Palette.inkSoft)),
      ),
      const SizedBox(height: StepBoxStyle.buttonsGap),
      Row(children: [
        button(IconArt.back, backLabel, onBack),
        Expanded(child: Center(child: ShowAllButton(label: showAllLabel, onTap: onShowAll))),
        button(IconArt.chevron, nextLabel, onNext),
      ]),
    ]);
  }
}

/// One line of a [StepBox], [height] tall: [child] at [alignment], [inset]
/// off the bottom, shrunk to fit across.
class StepSlot extends StatelessWidget {
  const StepSlot(
      {super.key, required this.height, required this.child, this.alignment = Alignment.centerLeft, this.inset = 0});
  final double height, inset;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: Align(
            alignment: alignment,
            child: FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child),
          ),
        ),
      );
}

/// The [text] tag beside a からふだ's kimariji in a [StepBox].
class KarafudaTag extends StatelessWidget {
  const KarafudaTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: StepBoxStyle.tagFill,
          border: Border.all(color: KarafudaStyle.tag, width: Strokes.hairline),
        ),
        child: Padding(
          padding: StepBoxStyle.tagPadding,
          child: Text(text.toUpperCase(),
              maxLines: 1,
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: StepBoxStyle.tagFont,
                  letterSpacing: StepBoxStyle.tagTracking * StepBoxStyle.tagFont,
                  height: StepBoxStyle.chipHeight,
                  color: KarafudaStyle.tag)),
        ),
      );
}

/// One of [StepChips]: [text] in [ink] on [fill].
typedef StepChip = ({String text, Color fill, Color ink});

/// A step's marks in order as a [StepBox] line: each chip with its number
/// as the field's badge shows it, then [more] after them.
class StepChips extends StatelessWidget {
  const StepChips(this.chips, {super.key, this.more});
  final List<StepChip> chips;
  final String? more;

  @override
  Widget build(BuildContext context) {
    final badge = MediaQuery.textScalerOf(context).scale(StepBoxStyle.badge);
    const text =
        TextStyle(fontWeight: Weights.black, fontSize: StepBoxStyle.chipFont, height: StepBoxStyle.chipHeight);
    final more = this.more;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final (i, chip) in chips.indexed) ...[
        if (i > 0) const SizedBox(width: StepBoxStyle.chipGap),
        SizedBox.square(dimension: badge, child: CustomPaint(painter: TapBadge(i + 1))),
        const SizedBox(width: StepBoxStyle.badgeGap),
        DecoratedBox(
          decoration: BoxDecoration(color: chip.fill, border: Border.all(width: Strokes.hairline)),
          child: Padding(
            padding: StepBoxStyle.chipPadding,
            child: Text(chip.text, maxLines: 1, style: text.copyWith(color: chip.ink)),
          ),
        ),
      ],
      if (more != null) ...[
        const SizedBox(width: StepBoxStyle.chipGap),
        Text(more, maxLines: 1, style: text.copyWith(color: StepBoxStyle.label)),
      ],
    ]);
  }
}
