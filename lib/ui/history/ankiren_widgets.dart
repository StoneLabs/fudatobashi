import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import 'run_charts.dart';

/// Where a tap landed, as a small chip in its tier's colour.
class TierChip extends StatelessWidget {
  const TierChip(this.place, {super.key});
  final TapProximity place;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AnkirenReviewStyle.tierFill[place.index],
          border: Border.all(color: Palette.ink, width: Strokes.hairline),
        ),
        child: Padding(
          padding: AnkirenReviewStyle.chipPadding,
          child: Text(S.of(context).ankirenChip(place),
              maxLines: 1,
              style: TextStyle(
                  fontWeight: Weights.black,
                  fontSize: AnkirenReviewStyle.chipFont,
                  color: AnkirenReviewStyle.tierText[place.index])),
        ),
      );
}

/// A tap's chips in order, first → second.
class TierChips extends StatelessWidget {
  const TierChips(this.taps, {super.key});
  final List<TapProximity> taps;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: Gaps.tight,
        runSpacing: Gaps.tight,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, place) in taps.indexed) ...[
            if (i > 0)
              const Text('→', style: TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.chipFont)),
            TierChip(place),
          ],
        ],
      );
}

/// A share of a card's points: 1, 0.4, 0.15 or 0.
String shareText(double share) => share == share.roundToDouble() ? '${share.round()}' : '$share';

/// Every tier's colour and name.
class TierLegend extends StatelessWidget {
  const TierLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ChartLegend([
      for (final place in TapProximity.values)
        (LegendMark.box(AnkirenReviewStyle.tierFill[place.index]), s.ankirenTier(place).replaceAll('\u200b', '')),
    ]);
  }
}

/// One row of first taps by tier: a [label] and [sub] on the left, the
/// tiers' counts as one stacked bar.
class TierMixBar extends StatelessWidget {
  const TierMixBar({super.key, required this.label, required this.sub, required this.mix});
  final String label, sub;
  final Map<TapProximity, int> mix;

  @override
  Widget build(BuildContext context) {
    final parts = [for (final MapEntry(key: place, value: n) in mix.entries) if (n > 0) (place, n)];
    return Padding(
      padding: const EdgeInsets.only(bottom: AnkirenReviewStyle.mixRowGap),
      child: Row(children: [
        SizedBox(
          width: AnkirenReviewStyle.mixLabelWidth,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                maxLines: 1,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: AnkirenReviewStyle.mixLabelFont,
                    height: AnkirenReviewStyle.mixLabelHeight)),
            Text(sub,
                maxLines: 1,
                style: const TextStyle(
                    fontWeight: Weights.bold, fontSize: AnkirenReviewStyle.mixSubFont, color: Palette.inkSoft)),
          ]),
        ),
        const SizedBox(width: Gaps.small),
        Expanded(
          child: Container(
            height: AnkirenReviewStyle.mixBarHeight,
            decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: Strokes.label)),
            child: Row(children: [
              for (final (i, (place, n)) in parts.indexed)
                Expanded(
                  flex: n,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AnkirenReviewStyle.tierFill[place.index],
                      border: i == 0 ? null : const Border(left: BorderSide(width: AnkirenReviewStyle.mixRule)),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('$n',
                            style: TextStyle(
                                fontSize: AnkirenReviewStyle.mixCountFont,
                                fontWeight: Weights.black,
                                color: AnkirenReviewStyle.tierText[place.index])),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// One row of a [ReviewTable]: its cells, [marked] in pink, or the
/// [total] under a heavier rule.
class ReviewRow {
  const ReviewRow(this.cells, {this.marked = false, this.total = false});
  final List<Widget> cells;
  final bool marked, total;
}

/// A table of a 暗記練 tab: a head row in small tracked capitals over an
/// ink rule (or, with [inkHead], in paper on ink), then [rows] on grey
/// rules; columns after [leading] are right-aligned numbers, but for the
/// notes in [starts]. The [stretch] column takes the room left and every
/// other one is as wide as its cells; without it the leading columns are,
/// and the rest share the room.
class ReviewTable extends StatelessWidget {
  const ReviewTable({
    super.key,
    required this.head,
    required this.rows,
    this.stretch,
    this.leading = 1,
    this.starts = const {},
    this.inkHead = false,
  });
  final List<String> head;
  final List<ReviewRow> rows;
  final int? stretch;
  final int leading;
  final Set<int> starts;
  final bool inkHead;

  /// A cell's text: [strong] in black, [color] for a value that stands out.
  static Widget cell(String text, {bool strong = false, Color? color}) => Text(text,
      style: ReviewTableStyle.cell.copyWith(fontWeight: strong ? Weights.black : null, color: color));

  @override
  Widget build(BuildContext context) {
    const rule = BorderSide(color: ReviewTableStyle.ruleColor, width: ReviewTableStyle.rule);
    const heavy = BorderSide(width: ReviewTableStyle.heavyRule);
    Widget pad(int i, Widget child, {EdgeInsets padding = ReviewTableStyle.cellPadding}) => Padding(
          padding: padding,
          child: Align(
            alignment: i < leading || starts.contains(i) ? Alignment.centerLeft : Alignment.centerRight,
            child: child,
          ),
        );
    TableColumnWidth width(int i) => switch (stretch) {
          final at? => i == at ? const FlexColumnWidth() : const IntrinsicColumnWidth(),
          null => i < leading ? const IntrinsicColumnWidth() : const IntrinsicColumnWidth(flex: 1),
        };
    return Table(
      columnWidths: {for (var i = 0; i < head.length; i++) i: width(i)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration:
              inkHead ? const BoxDecoration(color: Palette.ink) : const BoxDecoration(border: Border(bottom: heavy)),
          children: [
            for (final (i, h) in head.indexed)
              pad(
                i,
                Text(h.toUpperCase(),
                    maxLines: 1,
                    style: inkHead ? ReviewTableStyle.head.copyWith(color: Palette.paper) : ReviewTableStyle.head),
                padding: inkHead ? ReviewTableStyle.inkHeadPadding : ReviewTableStyle.headPadding,
              ),
          ],
        ),
        for (final (i, r) in rows.indexed)
          TableRow(
            decoration: BoxDecoration(
              color: r.marked ? ReviewTableStyle.marked : null,
              border: Border(top: r.total ? heavy : i == 0 && inkHead ? BorderSide.none : rule),
            ),
            children: [for (final (i, c) in r.cells.indexed) pad(i, c)],
          ),
      ],
    );
  }
}

/// A bar filled [used] of the way in [color], with [ticks] marking other
/// shares (the earlier games' memorise times) past its edges.
class ShareBar extends StatelessWidget {
  const ShareBar(this.used, {super.key, this.color = Palette.pink, this.ticks = const []});
  final double used;
  final Color color;
  final List<double> ticks;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AnkirenReviewStyle.memoBarHeight + 2 * AnkirenReviewStyle.memoTickOut,
        width: double.infinity,
        child: CustomPaint(painter: _ShareBarPainter(used.clamp(0.0, 1.0), color, ticks)),
      );
}

class _ShareBarPainter extends CustomPainter {
  _ShareBarPainter(this.used, this.color, this.ticks);
  final double used;
  final Color color;
  final List<double> ticks;

  @override
  void paint(Canvas canvas, Size size) {
    const out = AnkirenReviewStyle.memoTickOut;
    final bar = Rect.fromLTRB(0, out, size.width, size.height - out);
    canvas.drawRect(bar, Paint()..color = Palette.paper);
    canvas.drawRect(Rect.fromLTWH(0, bar.top, bar.width * used, bar.height), Paint()..color = color);
    final tick = Paint()..strokeWidth = AnkirenReviewStyle.memoTick;
    for (final t in ticks) {
      final x = (t * size.width).clamp(AnkirenReviewStyle.memoTick / 2, size.width - AnkirenReviewStyle.memoTick / 2);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), tick);
    }
    canvas.drawRect(
        bar.deflate(Strokes.label / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = Strokes.label);
  }

  @override
  bool shouldRepaint(_ShareBarPainter old) => old.used != used || old.color != color || old.ticks != ticks;
}
