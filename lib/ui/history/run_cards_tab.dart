import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/run_review.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import '../torifuda/torifuda_painter.dart';
import 'history_widgets.dart';
import 'run_charts.dart';

/// A run page's Cards tab: every swipe's speed (D14) and, in the training
/// view, its counts; then the slowest and fastest cards (D16), the misses
/// (D15), and a button to practise them (D17).
class RunCardsTab extends StatelessWidget {
  const RunCardsTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cards = detail.cards;
    final numbers = cardNumbers(detail.swipes);
    final practise = cards.practise;
    return RunTabList(children: [
      SwipeSpeedSection(detail),
      if (detail.run.view == RunView.training) ...[
        TrainingFacts(detail),
        const SizedBox(height: HistoryRunStyle.sectionGap),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _CardShelf(
              title: s.runSlowest,
              sub: s.sub?.runSlowest,
              swipes: cards.slowest,
              numbers: numbers,
              timeColor: HistoryRunStyle.behind,
              fill: Palette.pinkSoft,
            ),
          ),
          const SizedBox(width: Gaps.panel),
          Expanded(
            child: _CardShelf(
              title: s.runFastest,
              sub: s.sub?.runFastest,
              swipes: cards.fastest,
              numbers: numbers,
              timeColor: HistoryRunStyle.ahead,
              fill: Palette.landSoft,
            ),
          ),
        ],
      ),
      const SizedBox(height: HistoryRunStyle.sectionGap),
      HistorySection(
        title: s.runMissesTitle,
        sub: s.sub?.runMissesTitle,
        note: s.runMissesCount(cards.misses.length, detail.run.cards),
        child: MangaPanel(
          padding: HistoryRunStyle.chartPadding,
          shadow: HistoryRunStyle.panelShadow,
          child: cards.misses.isEmpty
              ? Text(s.runNoMisses, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.body))
              : Wrap(
                  spacing: Gaps.small,
                  runSpacing: Gaps.small,
                  children: [
                    for (final m in cards.misses)
                      SizedBox(
                        width: HistoryRunStyle.cardWidth,
                        child: SwipeCard(m, number: numbers[m], timeColor: HistoryRunStyle.behind, missed: true),
                      ),
                  ],
                ),
        ),
      ),
      if (practise.isNotEmpty) ...[
        const SizedBox(height: Gaps.panel),
        HistoryButton(
          icon: IconArt.refresh,
          label: s.runPractise(practise.length),
          sub: s.runPractiseSub,
          onTap: () => startCardsPlay(context, practise),
        ),
        HistoryCaption(s.runPractiseNote),
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

/// D16: the slowest or fastest cards side by side in a tinted panel.
class _CardShelf extends StatelessWidget {
  const _CardShelf({
    required this.title,
    required this.sub,
    required this.swipes,
    required this.numbers,
    required this.timeColor,
    required this.fill,
  });

  final String title;
  final String? sub;
  final List<RunSwipe> swipes;
  final Map<RunSwipe, int> numbers;

  /// The times' colour, and the panel's light tint to match.
  final Color timeColor, fill;

  @override
  Widget build(BuildContext context) => MangaPanel(
        color: fill,
        padding: HistoryRunStyle.chartPadding,
        shadow: HistoryRunStyle.panelShadow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrackedLabel(title, sub: sub),
            const SizedBox(height: Gaps.small),
            Row(
              children: [
                for (final (i, w) in swipes.indexed) ...[
                  if (i > 0) const SizedBox(width: Gaps.tight),
                  Expanded(child: SwipeCard(w, number: numbers[w], timeColor: timeColor)),
                ],
                for (var i = swipes.length; i < RunReviewTuning.shownCards; i++) ...[
                  const SizedBox(width: Gaps.tight),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],
        ),
      );
}

/// A small card of a run: the torifuda, its time and its number in the
/// run, ↓ when it was upside-down; ringed pink when [missed].
class SwipeCard extends StatelessWidget {
  const SwipeCard(this.swipe, {super.key, this.number, required this.timeColor, this.missed = false});
  final RunSwipe swipe;
  final int? number;
  final Color timeColor;
  final bool missed;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: missed ? Border.all(color: Palette.pink, width: Strokes.control) : null,
            ),
            child: TorifudaCard(poem: poems[swipe.poemId], inverted: swipe.inverted, showNumber: false),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${formatSeconds(swipe.ms)}s',
                style: TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small, color: timeColor)),
          ),
          if (number != null)
            Text('#$number${swipe.inverted ? ' ↓' : ''}',
                style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.labelFont)),
        ],
      );
}

/// D14: every swipe's time as a bar, misses pink, with the goal.
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
    return HistorySection(
      title: s.runSpeedTitle,
      sub: s.sub?.runSpeedTitle,
      note: s.runSpeedNote,
      child: MangaPanel(
        padding: HistoryRunStyle.chartPadding,
        shadow: HistoryRunStyle.panelShadow,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BarChart(
            bars: [
              for (final w in swipes)
                ChartBar(w.ms.clamp(0, double.infinity),
                    color: w.miss
                        ? Palette.pink
                        : goal != null && w.ms <= goal
                            ? RunTabsStyle.paceUnderGoal
                            : Palette.ink),
            ],
            guide: goal,
            xLabels: {0: '1', for (var c = step; c <= n; c += step) c - 1: '$c'},
          ),
          ChartLegend([
            if (goal != null) ...[
              (const LegendMark.box(RunTabsStyle.paceUnderGoal), s.runPaceUnderGoal),
              (const LegendMark.box(Palette.ink), s.legendOverGoal),
            ] else
              (const LegendMark.box(Palette.ink), s.legendRight),
            (const LegendMark.box(Palette.pink), s.legendMiss),
            if (goal != null) (const LegendMark.line(Palette.sun), s.legendGoal(formatSeconds(goal))),
          ]),
        ]),
      ),
    );
  }
}

/// The training view's counts: swipes, different cards, cards that came
/// back and due reviews.
class TrainingFacts extends StatelessWidget {
  const TrainingFacts(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final swipes = [for (final w in detail.swipes) if (!w.undone) w];
    final cards = {for (final w in swipes) (w.poemId, w.inverted)};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      StatChips([
        StatChip('${swipes.length}', s.runSwipesFact, icon: IconArt.arrow, color: Palette.sun, fill: Palette.sunSoft),
        StatChip('${cards.length}', s.runDifferentCards, icon: IconArt.cards, color: Palette.sea, fill: Palette.seaSoft),
        StatChip('${swipes.length - cards.length}', s.runCameBack,
            icon: IconArt.refresh, color: Palette.orange, fill: Palette.orangeSoft),
        StatChip('${swipes.where((w) => w.graded && !w.miss).length}', s.runDueReviews,
            icon: IconArt.check, color: Palette.land, fill: Palette.landSoft),
      ]),
      HistoryCaption(s.runTrainingNote),
    ]);
  }
}
