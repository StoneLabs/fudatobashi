import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';

/// A 暗記練 game's Taps (D40): every card in the order asked, where its taps
/// landed, its find time and, for a scored game, its speed bonus and
/// points.
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
    return RunTabList(children: [
      HistorySection(
        title: s.ankirenTapsTitle,
        sub: s.sub?.ankirenTapsTitle,
        note: s.ankirenTapsNote(game.cards.length),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ReviewPanel(
            child: ReviewTable(
              leading: 3,
              head: [
                s.ankirenColNumber,
                s.ankirenColCard,
                s.ankirenColFirstSecond,
                s.ankirenColFind,
                if (scored) ...[s.ankirenColSpeed, s.ankirenColPts],
              ],
              widths: const {2: FlexColumnWidth()},
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
                        ReviewTable.cell('${c.points}'),
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
          ),
          HistoryCaption(scored ? s.ankirenTapsCaption : s.ankirenTapsCaptionCustom),
        ]),
      ),
    ]);
  }
}
