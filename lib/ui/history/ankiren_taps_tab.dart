import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'review_parts.dart';

/// A 暗記練 game's Taps: one panel of every call in the order asked, its
/// からふだ named so, where its taps landed, its find (or press) time and,
/// for a scored game, its speed bonus and points; under it how the points
/// add up, or the [caption] given, and for a game with からふだ how they
/// count.
class AnkirenTapsTab extends StatelessWidget {
  const AnkirenTapsTab(this.review, {super.key, this.caption});
  final AnkirenReview review;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final scored = game.scored;
    final karafuda = game.karafuda.length;
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
        note: karafuda == 0 ? s.ankirenTapsNote(game.cards.length) : s.karafudaTapsNote(game.calls.length, karafuda),
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
              for (final (i, c) in game.calls.indexed)
                ReviewRow(
                  [
                    ReviewTable.cell('${i + 1}'),
                    CallName(c),
                    c.taps.isEmpty ? ReviewTable.cell(s.ankirenNoTap) : TierChips(c),
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
                  ReviewTable.cell('${game.calls.fold(0, (n, c) => n + c.speed)}', strong: true),
                  ReviewTable.cell('${game.recall}', strong: true),
                ], total: true),
            ],
          ),
          const SizedBox(height: Gaps.panel),
          Text(caption ?? (scored ? s.ankirenTapsCaption : s.ankirenTapsCaptionCustom), style: ReviewTextStyle.caption),
          if (karafuda > 0) ...[
            const SizedBox(height: Gaps.small),
            Text(s.karafudaCaption, style: ReviewTextStyle.caption),
          ],
        ]),
      ),
      children: const [],
    );
  }
}
