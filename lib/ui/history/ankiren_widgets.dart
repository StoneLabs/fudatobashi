import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'history_widgets.dart';
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

/// A share of a card's points: 1, 0.6, 0.25 or 0.
String shareText(double share) => share == share.roundToDouble() ? '${share.round()}' : '$share';

/// Every tier's colour, name and share of a card's points.
class TierLegend extends StatelessWidget {
  const TierLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ChartLegend([
      for (final place in TapProximity.values)
        (
          LegendMark.box(AnkirenReviewStyle.tierFill[place.index]),
          '${s.ankirenTier(place).replaceAll('\u200b', '')} ${shareText(AnkirenTuning.tapShare[place]!)}',
        ),
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AnkirenReviewStyle.mixRowGap),
        child: Row(children: [
          SizedBox(
            width: AnkirenReviewStyle.mixLabelWidth,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.mixFont)),
              Text(sub, style: const TextStyle(fontWeight: Weights.bold, fontSize: AnkirenReviewStyle.chipFont)),
            ]),
          ),
          const SizedBox(width: Gaps.small),
          Expanded(
            child: Container(
              height: AnkirenReviewStyle.mixBarHeight,
              decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: Strokes.label)),
              child: Row(children: [
                for (final MapEntry(key: place, value: n) in mix.entries)
                  if (n > 0)
                    Expanded(
                      flex: n,
                      child: ColoredBox(
                        color: AnkirenReviewStyle.tierFill[place.index],
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('$n',
                                style: TextStyle(
                                    fontSize: AnkirenReviewStyle.mixFont,
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

/// A panel of a 暗記練 tab: an ink-ruled box.
class ReviewPanel extends StatelessWidget {
  const ReviewPanel({super.key, required this.child, this.fill = Palette.paper});
  final Widget child;
  final Color fill;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: fill, border: Border.all(color: Palette.ink, width: Strokes.label)),
        child: Padding(padding: AnkirenReviewStyle.panelPadding, child: child),
      );
}

/// One row of a [ReviewTable]: its cells, [marked] in pink, or the
/// [total] under a heavier rule.
class ReviewRow {
  const ReviewRow(this.cells, {this.marked = false, this.total = false});
  final List<Widget> cells;
  final bool marked, total;
}

/// A table of a 暗記練 tab: a small header row, then [rows]; columns
/// after [leading] are right-aligned numbers.
class ReviewTable extends StatelessWidget {
  const ReviewTable({super.key, required this.head, required this.rows, this.widths = const {}, this.leading = 1});
  final List<String> head;
  final List<ReviewRow> rows;
  final Map<int, TableColumnWidth> widths;
  final int leading;

  /// A cell's text: [strong] in black, [color] for a value that stands out.
  static Widget cell(String text, {bool strong = false, Color? color}) => Text(text,
      style: TextStyle(
          fontWeight: strong ? Weights.black : Weights.bold, fontSize: AnkirenReviewStyle.cellFont, color: color));

  @override
  Widget build(BuildContext context) {
    const rule = BorderSide(color: AnkirenReviewStyle.rule, width: Strokes.hairline);
    const heavy = BorderSide(color: Palette.ink, width: Strokes.label);
    Widget pad(int i, Widget child) => Padding(
          padding: AnkirenReviewStyle.cellPadding,
          child: Align(alignment: i < leading ? Alignment.centerLeft : Alignment.centerRight, child: child),
        );
    return Table(
      columnWidths: widths,
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: heavy)),
          children: [
            for (final (i, h) in head.indexed)
              pad(i, Text(h, style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.headFont))),
          ],
        ),
        for (final r in rows)
          TableRow(
            decoration: BoxDecoration(
              color: r.marked ? AnkirenReviewStyle.markedRow : null,
              border: Border(top: r.total ? heavy : rule),
            ),
            children: [for (final (i, c) in r.cells.indexed) pad(i, c)],
          ),
      ],
    );
  }
}

/// A game's headline: a tracked [label], the [big] number with [of] beside
/// it, a [stamp] at the top right, then its [facts].
class AnkirenHeadline extends StatelessWidget {
  const AnkirenHeadline({
    super.key,
    required this.label,
    required this.big,
    required this.of,
    required this.facts,
    this.stamp,
    this.fill = AnkirenReviewStyle.headlineFill,
  });

  final String label, big, of;
  final List<Fact> facts;
  final Widget? stamp;
  final Color fill;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: fill, border: Border.all(color: Palette.ink, width: Strokes.label)),
        child: Padding(
          padding: HistoryRunStyle.headlinePadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TrackedLabel(label),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                          text: big,
                          style: const TextStyle(
                              fontFamily: Fonts.display,
                              fontSize: HistoryRunStyle.bigFont,
                              height: TypeScale.displayLineHeight)),
                      TextSpan(
                          text: '  $of',
                          style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.body)),
                    ])),
                  ),
                ]),
              ),
              ?stamp,
            ]),
            const SizedBox(height: Gaps.small),
            LayoutBuilder(builder: (context, box) {
              final room = MediaQuery.textScalerOf(context).scale(AnkirenReviewStyle.factMinWidth);
              final fit = box.maxWidth ~/ room >= facts.length;
              return FactGrid(facts, perRow: fit ? facts.length : (facts.length + 1) ~/ 2);
            }),
          ]),
        ),
      );
}

/// A stamp on a headline: a best, or a game not scored, with its
/// other-language [sub] under it.
class AnkirenStamp extends StatelessWidget {
  const AnkirenStamp(this.text, this.sub, {super.key, this.color = Palette.pinkDeep});
  final String text;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) => Sticker(
        color: Palette.paper,
        borderColor: color,
        border: Strokes.label,
        padding: AnkirenReviewStyle.stampPadding,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.stampFont, color: color)),
          if (sub != null)
            Text(sub!.toUpperCase(),
                style: TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.stampSubFont, color: color)),
        ]),
      );
}

/// A line under a headline: facts left and right, small.
class UnderLine extends StatelessWidget {
  const UnderLine(this.parts, {super.key});
  final List<String> parts;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Gaps.small),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: Gaps.section,
          children: [
            for (final p in parts)
              Text(p, style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.noteFont)),
          ],
        ),
      );
}

/// A bar filled [used] of the way in [color], with [ticks] marking other
/// shares (the earlier games' memorise times).
class ShareBar extends StatelessWidget {
  const ShareBar(this.used, {super.key, this.color = Palette.pink, this.ticks = const []});
  final double used;
  final Color color;
  final List<double> ticks;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AnkirenReviewStyle.memoBarHeight + 2 * AnkirenReviewStyle.memoTickOut,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: AnkirenReviewStyle.memoTickOut,
              height: AnkirenReviewStyle.memoBarHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.paper,
                  border: Border.all(color: Palette.ink, width: Strokes.label),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: used.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
            for (final t in ticks)
              Positioned(
                left: (t * w - AnkirenReviewStyle.memoTick / 2).clamp(0, w - AnkirenReviewStyle.memoTick),
                top: 0,
                bottom: 0,
                width: AnkirenReviewStyle.memoTick,
                child: const ColoredBox(color: Palette.ink),
              ),
          ]);
        }),
      );
}
