import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/run_review.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import '../torifuda/torifuda_painter.dart';
import 'history_widgets.dart';

/// A run page's Cards tab: the slowest and fastest cards (D16), the misses
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
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _CardShelf(
              title: s.runSlowest,
              sub: s.other.runSlowest,
              swipes: cards.slowest,
              numbers: numbers,
              timeColor: HistoryRunStyle.behind,
            ),
          ),
          const SizedBox(width: Gaps.panel),
          Expanded(
            child: _CardShelf(
              title: s.runFastest,
              sub: s.other.runFastest,
              swipes: cards.fastest,
              numbers: numbers,
              timeColor: HistoryRunStyle.ahead,
            ),
          ),
        ],
      ),
      const SizedBox(height: HistoryRunStyle.sectionGap),
      HistorySection(
        title: s.runMissesTitle,
        sub: s.other.runMissesTitle,
        note: s.runMissesCount(cards.misses.length, detail.run.cards),
        child: MangaPanel(
          padding: HistoryRunStyle.chartPadding,
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
        SizedBox(
          height: HistoryRunStyle.practiseHeight,
          child: ShoutButton(
            label: s.runPractise(practise.length),
            sub: s.runPractiseSub,
            onTap: () => startCardsPlay(context, practise),
          ),
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

class _CardShelf extends StatelessWidget {
  const _CardShelf({
    required this.title,
    required this.sub,
    required this.swipes,
    required this.numbers,
    required this.timeColor,
  });

  final String title, sub;
  final List<RunSwipe> swipes;
  final Map<RunSwipe, int> numbers;
  final Color timeColor;

  @override
  Widget build(BuildContext context) => MangaPanel(
        padding: HistoryRunStyle.chartPadding,
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
                style: TextStyle(fontFamily: Fonts.display, fontSize: TypeScale.small, color: timeColor)),
          ),
          if (number != null)
            Text('#$number${swipe.inverted ? ' ↓' : ''}',
                style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.labelFont)),
        ],
      );
}
