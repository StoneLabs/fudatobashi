import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../domain/rating.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'history_widgets.dart';
import 'ikkiuchi_parts.dart';
import 'review_parts.dart';

/// A 一騎打ち match's Overview: the card margin as the hero, the cards left
/// on each side beside it, the cards each took as its bar and the result
/// stamped with Tobi's rating; three tiles (the match time, the faults, and
/// a ranked match's rating or a free one's median take); the cards Tobi
/// took that the player reached too; then down to the floor the match
/// against the last one with the same setup.
class IkkiuchiOverviewTab extends StatelessWidget {
  const IkkiuchiOverviewTab(this.review, {super.key});
  final IkkiuchiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewColumn(
      fill: _SameSetup(review),
      fillMinHeight: 0,
      children: [
        ReviewHero(_hero(s), metrics: IkkiuchiHistoryStyle.heroMetrics),
        TileBand(_tiles(s), spec: ReviewTileLayout.spec, minHeight: ReviewLayout.tileHeight),
        if (review.beaten.isNotEmpty) _Beaten(review),
      ],
    );
  }

  /// The margin, the bar each one's takes and, for a match given up, the
  /// cards left; Tobi shocked by a win, fired up by his own, standing by
  /// for a match given up.
  SummaryHero _hero(S s) {
    final match = review.match;
    final result = match.result;
    final takes = ikkiuchiTakesBar(s, match);
    return SummaryHero(
      banner: s.ikkiuchiMargin.toUpperCase(),
      body: HeroCount(signedPoints(match.margin),
          label: '${match.playerLeft}–${match.opponentLeft}',
          note: s.ikkiuchiLeftCaption,
          metrics: IkkiuchiHistoryStyle.heroMetrics),
      bar: takes.bar,
      labels: takes.labels,
      pose: ikkiuchiPoseFor(result),
      stamp: RunStamp(s.ikkiuchiResult(result),
          sub: s.ikkiuchiTobiAt(match.setup.opponentRating.round()),
          color: result == IkkiuchiResult.won ? Palette.pinkDeep : HistoryRunStyle.muted,
          fontSize: RunStampStyle.heroFont),
      stampOnTop: true,
    );
  }

  List<SummaryTile> _tiles(S s) {
    final match = review.match;
    final after = review.ratingAfter;
    final median = match.medianTake(IkkiuchiSide.player), tobi = match.medianTake(IkkiuchiSide.opponent);
    return [
      SummaryTile(
        label: s.ikkiuchiMatchTime.toUpperCase(),
        big: TileFigure(formatMinutes(review.matchTime)),
        note: s.ikkiuchiReadCount(match.reads.length),
      ),
      SummaryTile(
        label: s.ikkiuchiFaultsLabel.toUpperCase(),
        big: TileFigure('${match.playerFaults}'),
        note: s.ikkiuchiTobiTimes(match.opponentFaults),
      ),
      if (match.ranked)
        ratingTile(s.ikkiuchiRatingLabel.toUpperCase(),
            before: review.ratingBefore,
            after: after,
            band: after == null ? '' : s.className(Rating.bandOf(after)))
      else
        SummaryTile(
          label: s.ikkiuchiMedianTake.toUpperCase(),
          big: median == null ? const TileFigure(missingTime) : TileFigure(secondsOf(median), unit: ' s'),
          note: tobi == null ? '' : s.ikkiuchiTobiSeconds(secondsOf(tobi)),
        ),
    ];
  }
}

/// The cards Tobi took that the player reached too, their slowest first,
/// each with the player's time.
class _Beaten extends StatelessWidget {
  const _Beaten(this.review);
  final IkkiuchiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      title: s.ikkiuchiBeatenTitle,
      sub: s.sub?.ikkiuchiBeatenTitle,
      note: s.ikkiuchiBeatenNote,
      mark: Palette.pink,
      child: SummaryCards([
        for (final r in review.beaten.take(IkkiuchiHistoryStyle.shownCards))
          SummaryCard(r.poemId, ms: msOf(r.playerTake!)),
      ]),
    );
  }
}

/// The match against the last one with the same setup, or on its own
/// when it is the first: how it ended, the cards taken, the faults, the
/// median take, and for a ranked match Tobi's rating.
class _SameSetup extends StatelessWidget {
  const _SameSetup(this.review);
  final IkkiuchiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      title: s.ikkiuchiSameSetup,
      sub: s.sub?.ikkiuchiSameSetup,
      note: s.ikkiuchiPerSideOf(review.match.setup.perSide),
      flatBottom: true,
      expands: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_table(s, review.match, review.last)]),
    );
  }

  static Widget _table(S s, IkkiuchiMatchRecord match, IkkiuchiMatchRecord? last) {
    String result(IkkiuchiMatchRecord m) => '${s.ikkiuchiResult(m.result)} ${signedPoints(m.margin)}';
    String taken(IkkiuchiMatchRecord m) => '${m.takenBy(IkkiuchiSide.player)}';
    String median(IkkiuchiMatchRecord m) => switch (m.medianTake(IkkiuchiSide.player)) {
          final d? => '${secondsOf(d)}s',
          null => missingTime,
        };
    String tobi(IkkiuchiMatchRecord m) => '${m.setup.opponentRating.round()}';
    Widget label(String text) => ReviewTable.cell(text, strong: true);
    Widget note(String text) =>
        Padding(padding: const EdgeInsets.only(left: ReviewTableStyle.noteGap), child: ReviewTable.cell(text));
    if (last == null) {
      return ReviewTable(
        head: ['', s.ikkiuchiColThis, ''],
        starts: const {2},
        rows: [
          ReviewRow([label(s.ikkiuchiResultLabel), ReviewTable.cell(result(match)), note(s.ikkiuchiSetupFirst)]),
          ReviewRow([label(s.ikkiuchiRowTaken), ReviewTable.cell(taken(match)), const SizedBox()]),
          ReviewRow([label(s.ikkiuchiFaultsLabel), ReviewTable.cell('${match.playerFaults}'), const SizedBox()]),
          ReviewRow([label(s.ikkiuchiMedianTake), ReviewTable.cell(median(match)), const SizedBox()]),
          if (match.ranked) ReviewRow([label(s.ikkiuchiTobiRating), ReviewTable.cell(tobi(match)), const SizedBox()]),
        ],
      );
    }
    final more = match.takenBy(IkkiuchiSide.player) - last.takenBy(IkkiuchiSide.player);
    final fewer = last.playerFaults - match.playerFaults;
    final (now, then) = (match.medianTake(IkkiuchiSide.player), last.medianTake(IkkiuchiSide.player));
    final sooner = now == null || then == null ? null : msOf(shownTime(then) - shownTime(now));
    final same = sooner != null && formatSeconds(sooner.abs()) == formatSeconds(0);
    Widget good(String text, bool better) =>
        ReviewTable.cell(text, strong: better, color: better ? HistoryRunStyle.ahead : null);
    return ReviewTable(
      head: ['', s.ikkiuchiColThis, s.shortDate(last.startedAt), ''],
      starts: const {3},
      rows: [
        ReviewRow([
          label(s.ikkiuchiResultLabel),
          good(result(match), match.margin > last.margin),
          ReviewTable.cell(result(last)),
          const SizedBox(),
        ]),
        ReviewRow([
          label(s.ikkiuchiRowTaken),
          good(taken(match), more > 0),
          ReviewTable.cell(taken(last)),
          note(more > 0
              ? s.ikkiuchiMoreTaken(more)
              : more < 0
                  ? s.ikkiuchiFewerTaken(-more)
                  : s.ikkiuchiSame),
        ]),
        ReviewRow([
          label(s.ikkiuchiFaultsLabel),
          good('${match.playerFaults}', fewer > 0),
          ReviewTable.cell('${last.playerFaults}'),
          note(fewer > 0
              ? s.ikkiuchiFewerFaults(fewer)
              : fewer < 0
                  ? s.ikkiuchiMoreFaults(-fewer)
                  : s.ikkiuchiSame),
        ]),
        ReviewRow([
          label(s.ikkiuchiMedianTake),
          good(median(match), sooner != null && !same && sooner > 0),
          ReviewTable.cell(median(last)),
          note(switch (sooner) {
            null => missingTime,
            _ when same => s.ikkiuchiSame,
            final d when d > 0 => s.ikkiuchiFaster(formatSeconds(d)),
            final d => s.ikkiuchiSlower(formatSeconds(-d)),
          }),
        ]),
        if (match.ranked)
          ReviewRow([
            label(s.ikkiuchiTobiRating),
            ReviewTable.cell(tobi(match)),
            ReviewTable.cell(tobi(last)),
            const SizedBox(),
          ]),
      ],
    );
  }
}
