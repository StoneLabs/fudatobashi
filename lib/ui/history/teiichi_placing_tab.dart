import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/teiichi_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_review_strings.dart';
import '../../l10n/teiichi_strings.dart';
import 'ankiren_field_tab.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// A 定位置 game's Placing: the layout as placed at true scale, each card
/// numbered in the order it was placed, the slowest to place marked; then
/// each card's placing time in that order.
class TeiichiPlacingTab extends StatelessWidget {
  const TeiichiPlacingTab(this.review, {super.key});
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final placed = game.placed;
    final order = {for (final (i, p) in placed.indexed) p.poemId: i + 1};
    final slow = {for (final p in game.slowest.take(TeiichiReviewStyle.slowest)) p.poemId};
    final every = placed.length > AnkirenReviewStyle.allLabelsUpTo ? AnkirenReviewStyle.labelEvery : 1;
    final slowLegend = ChartLegend([(const LegendMark.box(TeiichiReviewStyle.slowFill), s.teiichiSlowestPlace)]);
    return ReviewColumn(children: [
      ReviewSlab(
        title: s.teiichiLayoutTitle,
        sub: s.sub?.teiichiLayoutTitle,
        note: s.teiichiLayoutNote,
        flatTop: true,
        flatBottom: placed.isEmpty,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ReviewField(
            field: game.field,
            trueSlots: TeiichiTuning.rowSlots,
            label: s.teiichiLayoutLabel,
            card: (id) => FieldWordCard(
              id,
              fill: slow.contains(id) ? TeiichiReviewStyle.slowFill : Palette.paper,
              color: Palette.ink,
              foot: switch (order[id]) {
                final n? => _Order(n),
                null => null,
              },
            ),
          ),
          if (slow.isNotEmpty) slowLegend,
        ]),
      ),
      if (placed.isNotEmpty)
        ReviewSlab(
          title: s.teiichiTimesTitle,
          sub: s.sub?.teiichiTimesTitle,
          note: s.ankirenSeconds,
          flatBottom: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            BarChart(
              bars: [
                for (final p in placed)
                  ChartBar(p.time.inMicroseconds / Duration.microsecondsPerMillisecond,
                      color: slow.contains(p.poemId) ? TeiichiReviewStyle.slowFill : TeiichiReviewStyle.barFill),
              ],
              steps: TeiichiReviewStyle.barStepsMs,
              xLabels: {
                for (var i = 0; i < placed.length; i++)
                  if (i == 0 || (i + 1) % every == 0) i: '${i + 1}',
              },
            ),
            slowLegend,
            const SizedBox(height: Gaps.panel),
            Text(s.teiichiTimesCaption, style: ReviewTextStyle.caption),
          ]),
        ),
    ]);
  }
}

/// A card's place in the placing order, in paper on an ink strip at its
/// foot.
class _Order extends StatelessWidget {
  const _Order(this.n);
  final int n;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Palette.ink,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('$n',
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: const TextStyle(
                  fontWeight: Weights.black, fontSize: TeiichiReviewStyle.orderFont, height: 1, color: Palette.paper)),
        ),
      );
}
