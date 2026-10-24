import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'review_parts.dart';

/// A 暗記練 game's Taps: one panel of every card in the order asked, where
/// its taps landed, its find time and, for a scored game, its speed bonus
/// and points.
class AnkirenTapsTab extends StatelessWidget {
  const AnkirenTapsTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final scored = game.scored;
    Widget find(AnkirenCardTry c) => switch ((c.found, c.shown, c.findMs)) {
          (false, _, _) => ReviewTable.cell(missingTime),
          (true, true, _) => ReviewTable.cell(s.ankirenShown, strong: true, color: HistoryRunStyle.behind),
          (true, false, final ms?) => ReviewTable.cell('${formatSeconds(ms)}s'),
          (true, false, null) => ReviewTable.cell(missingTime),
        };
    return ReviewColumn(
      fillMinHeight: 0,
      fill: ReviewSlab(
        title: s.ankirenTapsTitle,
        sub: s.sub?.ankirenTapsTitle,
        note: s.ankirenTapsNote(game.cards.length),
        flatTop: true,
        flatBottom: true,
        expands: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ReviewTable(
            leading: 3,
            inkHead: true,
            head: [
              s.ankirenColNumber,
              s.ankirenColCard,
              s.ankirenColFirstSecond,
              s.ankirenColFind,
              if (scored) ...[s.ankirenColSpeed, s.ankirenColPts],
            ],
            stretch: 2,
            rows: [
              for (final (i, c) in game.cards.indexed)
                ReviewRow(
                  [
                    ReviewTable.cell('${i + 1}'),
                    ReviewTable.cell(kimarijiFor(context, c.poemId), strong: true),
                    c.taps.isEmpty ? ReviewTable.cell(s.ankirenNoTap) : TierChips(c.taps),
                    find(c),
                    if (scored) ...[
                      ReviewTable.cell(c.speed > 0 ? '+${c.speed}' : '', color: HistoryRunStyle.ahead),
                      ReviewTable.cell('${c.points}', strong: true),
                    ],
                  ],
                  marked: !c.firstTry,
                ),
              if (scored)
                ReviewRow([
                  const SizedBox(),
                  ReviewTable.cell(s.ankirenTotal, strong: true),
                  const SizedBox(),
                  const SizedBox(),
                  ReviewTable.cell('${review.speed.points}', strong: true),
                  ReviewTable.cell('${game.recall}', strong: true),
                ], total: true),
            ],
          ),
          const SizedBox(height: Gaps.panel),
          Text(scored ? s.ankirenTapsCaption : s.ankirenTapsCaptionCustom, style: ReviewTextStyle.caption),
        ]),
      ),
      children: const [],
    );
  }
}
