import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/karafuda.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../play/time_format.dart';
import 'run_summary.dart';

/// One からふだ call as a summary shows it: its card, and how it was
/// answered.
typedef KarafudaShown = ({int poemId, bool found, int wrongTaps});

/// What a game's summary shows of its からふだ, for a game that called any:
/// a row of the card panel ([row]) whose note says how many were right
/// first, and for a scored game the [points] they earned (their part of the
/// score bar, in the row's colour), with the からふだ not pressed first,
/// tagged as cards are (a tap on a card on one makes the press a later
/// tap), or else all of them. A press on a card's call shows on that card,
/// in the cards' rows.
abstract final class KarafudaSummary {
  static String note(S s, KarafudaTally tally, {int? points}) => [
        s.karafudaRightOf(tally.right, tally.called),
        if (points != null) s.karafudaPointsNote(groupDigits(points)),
      ].join(' · ');

  static Widget row(S s, KarafudaTally tally, Iterable<KarafudaShown> calls, {int? points}) {
    final wrong = [
      for (final c in calls)
        if (!c.found)
          SummaryCard(c.poemId, tag: s.summaryMissedTag, tagColor: Palette.pink)
        else if (c.wrongTaps > 0)
          SummaryCard(c.poemId, tag: s.summaryTapTag(c.wrongTaps + 1)),
    ];
    return SummaryRow(
      heading: s.karafuda,
      accent: KarafudaStyle.accent,
      note: note(s, tally, points: points),
      child: SummaryCards(wrong.isNotEmpty ? wrong : [for (final c in calls) SummaryCard(c.poemId)]),
    );
  }
}
