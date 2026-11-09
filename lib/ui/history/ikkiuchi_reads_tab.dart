import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import 'ikkiuchi_parts.dart';
import 'review_parts.dart';

/// A 一騎打ち match's Every read: one panel of every read in order, its
/// card (tagged when a からふだ), the side it lay on, who took it (a tie
/// named so), and each player's time from the deciding sound with their
/// faults under it, the taker's in black; the rows Tobi took marked, and
/// both medians under them.
class IkkiuchiReadsTab extends StatelessWidget {
  const IkkiuchiReadsTab(this.review, {super.key});
  final IkkiuchiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final match = review.match;
    final reads = match.reads;
    Widget time(Duration? take, int faults, {required bool strong}) => TaggedCell(
          ReviewTable.cell(take == null ? missingTime : '${secondsOf(take)}s', strong: strong),
          faults == 0 ? null : s.ikkiuchiFaultCount(faults),
          HistoryRunStyle.behind,
          end: true,
        );
    Widget median(IkkiuchiSide side) => ReviewTable.cell(
        switch (match.medianTake(side)) {
          final d? => '${secondsOf(d)}s',
          null => missingTime,
        },
        strong: true);
    return ReviewColumn(
      fillMinHeight: 0,
      fill: ReviewSlab(
        title: s.ikkiuchiReadsTitle,
        sub: s.sub?.ikkiuchiReadsTitle,
        note: s.ikkiuchiReadsNote(reads.length),
        flatTop: true,
        flatBottom: true,
        expands: true,
        child: reads.isEmpty
            ? Text(s.ikkiuchiNoReads, style: ReviewTextStyle.caption)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ReviewTable(
                  leading: 4,
                  inkHead: true,
                  stretch: 3,
                  head: [
                    s.ikkiuchiColNumber,
                    s.ikkiuchiColCard,
                    s.ikkiuchiColSide,
                    s.ikkiuchiColTaken,
                    s.ikkiuchiYou,
                    s.ikkiuchiTobi,
                  ],
                  rows: [
                    for (final (i, r) in reads.indexed)
                      ReviewRow(
                        [
                          ReviewTable.cell('${i + 1}'),
                          TaggedCell(ReviewTable.cell(kimarijiFor(context, r.poemId), strong: true),
                              r.karafuda ? s.ikkiuchiKarafuda : null, KarafudaStyle.tag),
                          ReviewTable.cell(switch (r.cardSide) {
                            IkkiuchiSide.player => s.ikkiuchiOwnSide,
                            IkkiuchiSide.opponent => s.ikkiuchiTheirSide,
                            null => '',
                          }),
                          _taken(s, r),
                          time(r.playerTake, r.playerFaults, strong: r.taker == IkkiuchiSide.player),
                          time(r.opponentTake, r.opponentFaults, strong: r.taker == IkkiuchiSide.opponent),
                        ],
                        marked: r.taker == IkkiuchiSide.opponent,
                      ),
                    ReviewRow([
                      const SizedBox(),
                      ReviewTable.cell(s.ikkiuchiMedianRow, strong: true),
                      const SizedBox(),
                      const SizedBox(),
                      median(IkkiuchiSide.player),
                      median(IkkiuchiSide.opponent),
                    ], total: true),
                  ],
                ),
                const SizedBox(height: Gaps.panel),
                Text(s.ikkiuchiReadsCaption, style: ReviewTextStyle.caption),
              ]),
      ),
      children: const [],
    );
  }

  /// Who took [read], as a chip: the player, Tobi, or both at once; a dash
  /// for one no one took.
  static Widget _taken(S s, IkkiuchiReadLog read) => switch (read.taker) {
        _ when read.tied => ReviewChip(s.ikkiuchiTied, fill: Palette.sun, ink: Palette.ink),
        IkkiuchiSide.player => ReviewChip(s.ikkiuchiYou, fill: Palette.land, ink: Palette.ink),
        IkkiuchiSide.opponent => ReviewChip(s.ikkiuchiTobi, fill: Palette.pink, ink: Palette.ink),
        null => ReviewTable.cell(missingTime, color: HistoryRunStyle.muted),
      };
}
