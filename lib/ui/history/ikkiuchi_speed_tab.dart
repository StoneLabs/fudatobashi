import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'ikkiuchi_parts.dart';
import 'review_parts.dart';
import 'run_charts.dart';

/// A 一騎打ち match's Speed: the player's time on every field card read,
/// coloured by who took it, Tobi's median across; both medians with the
/// takes and faults under them; the times by kimariji length, Tobi's as the
/// tick; and the player's fastest takes.
class IkkiuchiSpeedTab extends StatelessWidget {
  const IkkiuchiSpeedTab(this.review, {super.key});
  final IkkiuchiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final match = review.match;
    final reads = review.fieldReads;
    final every = reads.length > IkkiuchiHistoryStyle.allLabelsUpTo ? IkkiuchiHistoryStyle.labelEvery : 1;
    final you = match.medianTake(IkkiuchiSide.player), tobi = match.medianTake(IkkiuchiSide.opponent);
    final fastest = review.fastestTakes;
    SummaryTile median(String label, Duration? time, IkkiuchiSide side, int faults, Color color) => SummaryTile(
          label: label.toUpperCase(),
          big: time == null ? const TileFigure(missingTime) : TileFigure(secondsOf(time), unit: ' s'),
          note: s.ikkiuchiTakesFaults(match.takenBy(side), faults),
          color: color,
        );
    return ReviewColumn(children: [
      ReviewSlab(
        title: s.ikkiuchiTakesTitle,
        sub: s.sub?.ikkiuchiTakesTitle,
        note: s.ikkiuchiSeconds,
        flatTop: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          BarChart(
            bars: [for (final r in reads) ChartBar(_barMs(r), color: _colorOf(r))],
            guide: tobi == null ? null : msOf(tobi),
            guideColor: Palette.seaDeep,
            format: (ms) => formatSeconds(ms, 1),
            xLabels: {
              for (var i = 0; i < reads.length; i++)
                if (i == 0 || (i + 1) % every == 0) i: '${i + 1}',
            },
          ),
          ChartLegend([
            (const LegendMark.box(Palette.land), s.ikkiuchiYouTook),
            (const LegendMark.box(Palette.pink), s.ikkiuchiTobiTook),
            (const LegendMark.box(Palette.sun), s.ikkiuchiTied),
            (const LegendMark.guide(Palette.seaDeep), s.ikkiuchiTobiMedian),
          ]),
          const SizedBox(height: Gaps.panel),
          Text(s.ikkiuchiTakesCaption, style: ReviewTextStyle.caption),
        ]),
      ),
      TileBand([
        median(s.ikkiuchiYourMedian, you, IkkiuchiSide.player, match.playerFaults, Palette.landSoft),
        median(s.ikkiuchiTobiMedian, tobi, IkkiuchiSide.opponent, match.opponentFaults, Palette.pinkSoft),
      ], spec: ReviewTileLayout.spec, minHeight: ReviewTileLayout.sidesHeight),
      if ((you, tobi) case (final you?, final tobi?))
        switch (shownTime(tobi) - shownTime(you)) {
          final gap when gap.isNegative => ReviewCaption(s.ikkiuchiSlowerThanTobi(secondsOf(-gap))),
          final gap => ReviewCaption(s.ikkiuchiFasterThanTobi(secondsOf(gap))),
        },
      ReviewSlab(
        title: s.ikkiuchiByLength,
        sub: s.sub?.ikkiuchiByLength,
        note: s.ikkiuchiTickTobi,
        child: LengthRows([
          for (final l in review.byKimariji((id) => poems[id].kimariji.length))
            (
              label: s.ikkiuchiKimarijiLength(l.length),
              note: s.ikkiuchiLengthNote(l.read, l.took),
              ms: l.player == null ? null : math.max(0, msOf(l.player!)),
              tickMs: l.opponent == null ? null : msOf(l.opponent!),
            ),
        ]),
      ),
      if (fastest.isNotEmpty)
        ReviewSlab(
          title: s.ikkiuchiFastestTitle,
          sub: s.sub?.ikkiuchiFastestTitle,
          mark: Palette.land,
          child: SummaryCards([
            for (final r in fastest.take(IkkiuchiHistoryStyle.shownCards))
              SummaryCard(r.poemId, ms: msOf(r.playerTake!)),
          ]),
        ),
    ]);
  }

  /// The player's time on [read]: none when they never reached it, a
  /// sliver when they reached it before the deciding sound.
  static double _barMs(IkkiuchiReadLog read) => switch (read.playerTake) {
        null => 0,
        final take => math.max(msOf(take), IkkiuchiHistoryStyle.earlyTakeMs),
      };

  /// Who took [read]: the player, Tobi, both at once, or no one.
  static Color _colorOf(IkkiuchiReadLog read) => switch (read.taker) {
        _ when read.tied => Palette.sun,
        IkkiuchiSide.player => Palette.land,
        IkkiuchiSide.opponent => Palette.pink,
        null => Palette.paper,
      };
}
