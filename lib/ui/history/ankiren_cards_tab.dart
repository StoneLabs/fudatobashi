import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// A scored 暗記練 game's Cards: find times in order, against the earlier
/// ranked games, and the cards the player keeps placing wrong.
class AnkirenCardsTab extends StatelessWidget {
  const AnkirenCardsTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final cards = game.cards;
    final every = cards.length > AnkirenReviewStyle.allLabelsUpTo ? AnkirenReviewStyle.labelEvery : 1;
    return ReviewColumn(children: [
      ReviewSlab(
        title: s.ankirenFindTitle,
        sub: s.sub?.ankirenFindTitle,
        note: s.ankirenSeconds,
        flatTop: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BarChart(
            bars: [
              for (final c in cards)
                ChartBar(c.findMs ?? 0,
                    color: c.first == null ? Palette.paper : AnkirenReviewStyle.tierFill[c.first!.index]),
            ],
            format: (ms) => formatSeconds(ms, 1),
            xLabels: {
              for (var i = 0; i < cards.length; i++)
                if (i == 0 || (i + 1) % every == 0) i: '${i + 1}',
            },
          ),
          const TierLegend(),
        ]),
      ),
      _AgainstRanked(review),
      _Misplaced(review),
    ]);
  }
}

/// This game against the best, the average and the last of the earlier
/// ranked games.
class _AgainstRanked extends StatelessWidget {
  const _AgainstRanked(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final peers = review.peers;
    if (peers.isEmpty) {
      return ReviewSlab(
        title: s.ankirenRankedTitle,
        sub: s.sub?.ankirenRankedTitle,
        child: ReviewText(s.ankirenFirstRanked),
      );
    }
    final best = review.bestBefore, last = review.last;
    String seconds(double? ms) => ms == null ? missingTime : formatSeconds(ms);
    String percent(double? share) => share == null ? missingTime : '${(share * 100).round()}%';
    String minutes(double? ms) => ms == null ? missingTime : formatMinutes(Duration(milliseconds: ms.round()));
    double? mean(num? Function(AnkirenGameRecord g) of) => AnkirenReview.mean([for (final g in peers) ?of(g)]);

    /// A measure's row: this game's value, marked when [better] than the
    /// average, then the best's, the average and the last's.
    ReviewRow row(String label, String Function(AnkirenGameRecord g) text, String average, {required bool better}) =>
        ReviewRow([
          ReviewTable.cell(label, strong: true),
          ReviewTable.cell(text(game), strong: better, color: better ? HistoryRunStyle.ahead : null),
          ReviewTable.cell(best == null ? missingTime : text(best)),
          ReviewTable.cell(average),
          ReviewTable.cell(last == null ? missingTime : text(last)),
        ]);

    final score = mean((g) => g.score), share = mean((g) => g.fraction), first = mean((g) => g.firstTaps);
    final median = mean((g) => g.medianFindMs), memorised = mean((g) => g.memorised.inMilliseconds);
    final gameMedian = game.medianFindMs;
    return ReviewSlab(
      title: s.ankirenRankedTitle,
      sub: s.sub?.ankirenRankedTitle,
      note: s.ankirenGames(peers.length),
      child: ReviewTable(
        head: ['', s.ankirenColThis, s.ankirenColBest, s.ankirenColAverage, s.ankirenColLast],
        rows: [
          row(s.ankirenRowPoints, (g) => '${g.score ?? missingTime}', score?.round().toString() ?? missingTime,
              better: score != null && game.score! > score),
          row(s.ankirenRowCardPoints, (g) => percent(g.fraction), percent(share),
              better: share != null && game.fraction > share),
          row(s.ankirenRowFirstTap, (g) => '${g.firstTaps}/${g.cards.length}', first?.toStringAsFixed(1) ?? missingTime,
              better: first != null && game.firstTaps > first),
          row(s.ankirenRowMedian, (g) => seconds(g.medianFindMs), seconds(median),
              better: median != null && gameMedian != null && gameMedian < median),
          row(s.ankirenRowMemorised, (g) => formatMinutes(g.memorised), minutes(memorised), better: false),
        ],
      ),
    );
  }
}

/// This game's cards that the player keeps placing wrong over all their
/// games.
class _Misplaced extends StatelessWidget {
  const _Misplaced(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = review.misplaced;
    bool low(AnkirenMisplaced r) => r.rightFirst / r.dealt < AnkirenReviewTuning.misplacedMarkBelow;
    return ReviewSlab(
      title: s.ankirenMisplacedTitle,
      sub: s.sub?.ankirenMisplacedTitle,
      note: s.ankirenAllGames,
      mark: Palette.pink,
      flatBottom: true,
      child: rows.isEmpty
          ? ReviewText(s.ankirenMisplacedNone)
          : ReviewTable(
              head: [s.ankirenColCard, s.ankirenColDealt, s.ankirenColRightFirst, s.ankirenColUsualFirst],
              rows: [
                for (final r in rows)
                  ReviewRow(
                    [
                      ReviewTable.cell(kimarijiFor(context, r.poemId), strong: true),
                      ReviewTable.cell('${r.dealt}'),
                      ReviewTable.cell('${r.rightFirst}',
                          strong: low(r), color: low(r) ? HistoryRunStyle.behind : null),
                      if (r.usual case final place?) TierChip(place) else ReviewTable.cell(missingTime),
                    ],
                    marked: low(r),
                  ),
              ],
            ),
    );
  }
}
