import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_review.dart';
import '../../domain/karafuda.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// What a ranked game did to its trip's rating, as a tile.
SummaryTile ankirenRatingTile(S s, AnkirenReview review) {
  final before = review.ratingBefore, after = review.game.rating;
  if (after == null) {
    return SummaryTile(label: s.ratingLabel, big: const TileFigure(missingTime), note: '', color: Palette.pinkSoft);
  }
  final band = s.className(AnkirenReview.classProgress(after).band);
  if (before == null) {
    return SummaryTile(label: s.ratingLabel, big: TileFigure('${after.round()}'), note: band, color: Palette.pinkSoft);
  }
  return SummaryTile(
    label: s.ratingLabel,
    big: TileFigure(signedPoints(after - before)),
    note: '${before.round()} → ${after.round()} · $band',
    color: Palette.pinkSoft,
  );
}

/// Where a tap landed, as a small chip in its tier's colour.
class TierChip extends StatelessWidget {
  const TierChip(this.place, {super.key});
  final TapProximity place;

  @override
  Widget build(BuildContext context) => ReviewChip(S.of(context).ankirenChip(place),
      fill: AnkirenReviewStyle.tierFill[place.index], ink: AnkirenReviewStyle.tierText[place.index]);
}

/// A call's taps (see [AnkirenCardTry]) in order, first → second, each in
/// its tier's colour and named by what it hit: the tier, the からふだ
/// button, or on a からふだ call a card (a tap on the other side).
class TierChips extends StatelessWidget {
  const TierChips(this.call, {super.key});
  final AnkirenCardTry call;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Wrap(
      spacing: Gaps.tight,
      runSpacing: Gaps.tight,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, place) in call.taps.indexed) ...[
          if (i > 0) const Text('→', style: TextStyle(fontWeight: Weights.black, fontSize: ReviewTableStyle.chipFont)),
          ReviewChip(name(s, call, i), fill: AnkirenReviewStyle.tierFill[place.index], ink: AnkirenReviewStyle.tierText[place.index]),
        ],
      ],
    );
  }

  /// What [call]'s tap [i] hit, as its chip names it.
  static String name(S s, AnkirenCardTry call, int i) => call.tapped.elementAtOrNull(i) == Karafuda.button
      ? s.karafudaChip
      : call.karafuda
          ? s.karafudaChipCard
          : s.ankirenChip(call.taps[i]);
}

/// A call's kimariji in a table, and for a からふだ call, which has no place
/// on the field, a tag under it saying so.
class CallName extends StatelessWidget {
  const CallName(this.call, {super.key});
  final AnkirenCardTry call;

  @override
  Widget build(BuildContext context) => TaggedCell(ReviewTable.cell(kimarijiFor(context, call.poemId), strong: true),
      call.karafuda ? S.of(context).karafudaChip : null, KarafudaStyle.tag);
}

/// A share of a card's points: 1, 0.4, 0.15 or 0.
String shareText(double share) => share == share.roundToDouble() ? '${share.round()}' : '$share';

/// The [tiers]' colours and names, every tier's by default.
class TierLegend extends StatelessWidget {
  const TierLegend({super.key, this.tiers = TapProximity.values});
  final List<TapProximity> tiers;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ChartLegend([
      for (final place in tiers)
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
