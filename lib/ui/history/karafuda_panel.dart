import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import '../results/karafuda_summary.dart';
import '../results/run_summary.dart';
import 'review_parts.dart';

/// How a recorded game's からふだ went, for a game that called any: how many
/// were called and how they were answered (right first, pressed after a
/// card was tapped, or not pressed), the cards tapped on them, the presses
/// of the button on the field cards' calls, and the median press, which
/// the find times leave out; then the からふだ as the results show them.
class KarafudaPanel extends StatelessWidget {
  const KarafudaPanel(this.game, {super.key});
  final AnkirenGameRecord game;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tally = game.karafudaTally;
    final median = game.medianPressMs;
    return ReviewSlab(
      title: s.karafuda,
      sub: s.sub?.karafuda,
      note: s.karafudaCalled(tally.called),
      mark: KarafudaStyle.accent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ValueLine(s.karafudaRowRightFirst, '${tally.right}'),
        ValueLine(s.karafudaRowLate, '${tally.late}'),
        ValueLine(s.karafudaRowMissed, '${tally.missed}'),
        ValueLine(s.karafudaRowTouched, '${tally.touched}'),
        ValueLine(s.karafudaRowPressedOnCards, '${tally.wrongPresses}'),
        ValueLine(s.karafudaRowMedian, median == null ? missingTime : '${formatSeconds(median)}s'),
        const SizedBox(height: Gaps.panel),
        SummaryCards(KarafudaSummary.cards(s, [
          for (final c in game.karafuda) (poemId: c.poemId, found: c.found, wrongTaps: c.wrongTaps),
        ])),
      ]),
    );
  }
}
