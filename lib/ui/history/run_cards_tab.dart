import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/run_review.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import '../torifuda/torifuda_painter.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// A run page's Cards tab: every swipe's speed and, in the training view,
/// its counts; then the slowest and fastest cards side by side, the
/// misses, and the button to practise them.
class RunCardsTab extends StatelessWidget {
  const RunCardsTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cards = detail.cards;
    final numbers = cardNumbers(detail.swipes);
    final practise = cards.practise;
    final training = detail.run.view == RunView.training;
    return ReviewColumn(children: [
      SwipeSpeedSection(detail),
      if (training) ...[
        TrainingCounts(detail),
        ReviewCaption(s.runTrainingNote),
      ],
      SlantRow(
        cut: ReviewLayout.cut,
        gap: ReviewLayout.gap,
        padding: ReviewCardStyle.shelfPadding,
        colors: const [Palette.pinkSoft, Palette.landSoft],
        children: [
          _Shelf(title: s.runSlowest, swipes: cards.slowest, numbers: numbers, timeColor: HistoryRunStyle.behind),
          _Shelf(title: s.runFastest, swipes: cards.fastest, numbers: numbers, timeColor: HistoryRunStyle.ahead),
        ],
      ),
      ReviewSlab(
        title: s.runMissesTitle,
        sub: s.sub?.runMissesTitle,
        note: s.runMissesCount(cards.misses.length, detail.run.cards),
        mark: Palette.pink,
        flatBottom: true,
        child: cards.misses.isEmpty
            ? ReviewText(s.runNoMisses)
            : Wrap(
                spacing: ReviewCardStyle.gap,
                runSpacing: ReviewCardStyle.gap,
                children: [
                  for (final m in cards.misses)
                    SizedBox(
                      width: ReviewCardStyle.width,
                      child: SwipeCard(m, number: numbers[m], timeColor: HistoryRunStyle.behind, missed: true),
                    ),
                ],
              ),
      ),
      if (practise.isNotEmpty) ...[
        ReviewShout(
          label: s.runPractise(practise.length),
          icon: IconArt.refresh,
          onTap: () => startCardsPlay(context, practise),
        ),
        ReviewCaption(s.reviewPractiseNote),
      ],
    ]);
  }
}

/// Each swipe's card number in the run (1-based, undone swipes skipped).
Map<RunSwipe, int> cardNumbers(List<RunSwipe> swipes) {
  final numbers = <RunSwipe, int>{};
  var n = 0;
  for (final w in swipes) {
    if (!w.undone) numbers[w] = ++n;
  }
  return numbers;
}

/// The slowest or fastest cards side by side under their label.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.swipes, required this.numbers, required this.timeColor});

  final String title;
  final List<RunSwipe> swipes;
  final Map<RunSwipe, int> numbers;
  final Color timeColor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShelfLabel(title),
          const SizedBox(height: ReviewLayout.shelfGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < RunReviewTuning.shownCards; i++) ...[
                if (i > 0) const SizedBox(width: ReviewCardStyle.shelfCardGap),
                Expanded(
                  child: i < swipes.length
                      ? SwipeCard(swipes[i], number: numbers[swipes[i]], timeColor: timeColor)
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ],
      );
}

/// A small card of a run: the torifuda, its time in a chip, its kimariji
/// and its number in the run, ↓ when it was upside-down; ringed pink, its
/// time crossed, when [missed].
class SwipeCard extends StatelessWidget {
  const SwipeCard(this.swipe, {super.key, this.number, required this.timeColor, this.missed = false});
  final RunSwipe swipe;
  final int? number;
  final Color timeColor;
  final bool missed;

  @override
  Widget build(BuildContext context) {
    final number = this.number;
    const small = TextStyle(fontWeight: Weights.bold, fontSize: ReviewCardStyle.numberFont, color: Palette.inkSoft);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: missed ? Border.all(color: Palette.pink, width: ReviewCardStyle.missRing) : null,
          ),
          child: TorifudaCard(poem: poems[swipe.poemId], inverted: swipe.inverted, showNumber: false),
        ),
        const SizedBox(height: ReviewCardStyle.chipGap),
        DecoratedBox(
          decoration: BoxDecoration(
            color: missed ? Palette.pinkSoft : Palette.paper,
            border: Border.all(color: Palette.ink, width: ReviewCardStyle.chipBorder),
          ),
          child: Padding(
            padding: ReviewCardStyle.chipPadding,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${missed ? '× ' : ''}${formatSeconds(swipe.ms)}s',
                  maxLines: 1,
                  style: TextStyle(
                      fontFamily: Fonts.display, fontSize: ReviewCardStyle.chipFont, height: 1, color: timeColor)),
            ),
          ),
        ),
        const SizedBox(height: ReviewCardStyle.nameGap),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(kimarijiFor(context, swipe.poemId),
              maxLines: 1,
              style: const TextStyle(fontWeight: Weights.black, fontSize: ReviewCardStyle.nameFont, height: 1)),
        ),
        if (number != null) ...[
          const SizedBox(height: ReviewCardStyle.numberGap),
          Text('#$number${swipe.inverted ? ' ↓' : ''}', maxLines: 1, style: small),
        ],
      ],
    );
  }
}

/// Every swipe's time as a bar, misses pink, with the goal.
class SwipeSpeedSection extends StatelessWidget {
  const SwipeSpeedSection(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final swipes = [for (final w in detail.swipes) if (!w.undone) w];
    final goal = detail.run.goalMs;
    final n = swipes.length;
    final step = RunChartStyle.cardSteps.firstWhere((v) => n / v <= RunChartStyle.maxXTicks, orElse: () => 25);
    return ReviewSlab(
      title: s.runSpeedTitle,
      sub: s.sub?.runSpeedTitle,
      note: s.runSpeedNote,
      flatTop: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        BarChart(
          height: detail.run.view == RunView.training ? RunChartStyle.shortBarChartHeight : RunChartStyle.barChartHeight,
          bars: [
            for (final w in swipes)
              ChartBar(w.ms.clamp(0, double.infinity),
                  color: w.miss
                      ? Palette.pink
                      : w.ms <= goal
                          ? RunTabsStyle.paceUnderGoal
                          : Palette.ink),
          ],
          guide: goal,
          xLabels: {0: '1', for (var c = step; c <= n; c += step) c - 1: '$c'},
        ),
        ChartLegend([
          (const LegendMark.box(RunTabsStyle.paceUnderGoal), s.runPaceUnderGoal),
          (const LegendMark.box(Palette.ink), s.legendOverGoal),
          (const LegendMark.box(Palette.pink), s.legendMiss),
          (const LegendMark.line(Palette.sun), s.legendGoal(formatSeconds(goal))),
        ]),
      ]),
    );
  }
}

/// The training view's counts: swipes, different cards, cards that came
/// back and due reviews.
class TrainingCounts extends StatelessWidget {
  const TrainingCounts(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final swipes = [for (final w in detail.swipes) if (!w.undone) w];
    final cards = {for (final w in swipes) (w.poemId, w.inverted)};
    return CountTiles([
      CountTile('${swipes.length}', s.runSwipesFact, icon: IconArt.arrow, color: Palette.sunSoft),
      CountTile('${cards.length}', s.runDifferentCards, icon: IconArt.cards, color: Palette.seaSoft),
      CountTile('${swipes.length - cards.length}', s.runCameBack, icon: IconArt.refresh, color: Palette.orangeSoft),
      CountTile('${swipes.where((w) => w.graded && !w.miss).length}', s.runDueReviews,
          icon: IconArt.check, color: Palette.landSoft),
    ]);
  }
}
