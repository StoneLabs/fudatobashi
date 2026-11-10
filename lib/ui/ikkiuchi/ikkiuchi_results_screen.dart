import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../domain/rating.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../../state/scope.dart';
import '../history/history_widgets.dart';
import '../history/ikkiuchi_match_page.dart';
import '../history/ikkiuchi_parts.dart';
import '../history/review_parts.dart';
import '../play/time_format.dart';
import '../results/celebrations.dart';
import '../results/results_frame.dart';
import '../results/run_summary.dart';

/// A 一騎打ち match's results, on the run summary: how it ended, as its
/// result moment said it, with each one's takes along the bar and Tobi as
/// it left him; the faults and the median takes, each beside Tobi's, and a
/// ranked match's rating, or else the experience it earned; the player's
/// fastest takes and the cards Tobi took that they reached too; then
/// Review game, which opens the match's History page on its field, beside
/// Back to 一騎打ち. A recorded match's celebrations play over it first
/// ([ResultsFrame]). A guest's match saved nothing: no Review game, and
/// Back to 一騎打ち takes the whole row.
class IkkiuchiResultsScreen extends StatelessWidget {
  const IkkiuchiResultsScreen({super.key, required this.match, this.report});

  /// The match: as stored when it was recorded, else as played.
  final IkkiuchiMatchRecord match;

  /// What recording it did; null when nothing was recorded (a guest's).
  final IkkiuchiReport? report;

  bool get _saved => match.id != null;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final report = this.report;
    final review = IkkiuchiReview(match, _saved ? ProgressScope.of(context).ikkiuchi.matches : const [], xp: report?.xp);
    return ResultsFrame(
      celebrations: report == null ? const [] : xpCelebrations(report.xp),
      child: RunSummary(
        title: s.hallName,
        sub: [
          s.other.hallName,
          _saved ? ikkiuchiKindLabel(s, match) : s.ikkiuchiGuestMode,
          s.ikkiuchiTobiAt(match.setup.opponentRating.round()),
        ].join(' · ').toUpperCase(),
        untracked: !_saved,
        hero: _hero(s),
        tiles: _tiles(s, review),
        rows: _rows(s, review),
        actions: Row(children: [
          if (_saved) ...[
            Expanded(
              child: SizedBox(
                height: SummaryActionLayout.home.height,
                child: SummaryBoxButton(
                  icon: IconArt.history,
                  label: s.ikkiuchiReviewMatch,
                  onTap: () => unawaited(openIkkiuchiMatch(context, match, tab: IkkiuchiMatchPage.fieldTab)),
                ),
              ),
            ),
            const SizedBox(width: SummaryActionLayout.gap),
          ],
          Expanded(child: SummaryShout(s.ikkiuchiBackToPage.toUpperCase(), onTap: () => Navigator.of(context).pop())),
        ]),
      ),
    );
  }

  /// The result moment's lettering over its line, outlined with focus
  /// lines for a win; each one's takes as the bar, Tobi as it left him.
  SummaryHero _hero(S s) {
    final result = match.result;
    final won = result == IkkiuchiResult.won;
    final takes = ikkiuchiTakesBar(s, match);
    return SummaryHero(
      banner: s.ikkiuchiResultLabel.toUpperCase(),
      body: HeroWord(
        won ? s.ikkiuchiBeatTobi : s.ikkiuchiTobiWins,
        outlined: won,
        sub: Text(s.ikkiuchiResultLine(result, match.margin.abs())),
      ),
      bar: takes.bar,
      labels: takes.labels,
      pose: ikkiuchiPoseFor(result),
      burst: won ? SummaryHeroLayout.burst : null,
    );
  }

  /// The player's faults and median take, each with Tobi's as its note;
  /// then a ranked match's rating, or the experience a free one earned.
  List<SummaryTile> _tiles(S s, IkkiuchiReview review) {
    final you = match.medianTake(IkkiuchiSide.player), tobi = match.medianTake(IkkiuchiSide.opponent);
    return [
      SummaryTile(
        label: s.ikkiuchiFaultsLabel.toUpperCase(),
        big: TileFigure('${match.playerFaults}'),
        note: s.ikkiuchiTobiTimes(match.opponentFaults),
      ),
      SummaryTile(
        label: s.ikkiuchiMedianTake.toUpperCase(),
        big: you == null ? const TileFigure(missingTime) : TileFigure(secondsOf(you), unit: ' s'),
        note: tobi == null ? '' : s.ikkiuchiTobiSeconds(secondsOf(tobi)),
      ),
      if (match.ranked) _ratingTile(s, review) else rewardTile(s, report?.xp),
    ];
  }

  /// The rating after a ranked match and how it moved; while placing, the
  /// new estimate and how far placement has got; for the match that ends
  /// placement, the first rating and its class.
  SummaryTile _ratingTile(S s, IkkiuchiReview review) {
    final before = review.ratingBefore, after = review.ratingAfter;
    final label = s.ikkiuchiRatingLabel.toUpperCase();
    if (before == null || after == null) return SummaryTile(label: label, big: const TileFigure(missingTime), note: '');
    final placement = review.placementMatch;
    if (placement != null && !review.endedPlacement) {
      return SummaryTile(
        label: s.ikkiuchiNewEstimate.toUpperCase(),
        big: TileFigure('${after.round()}'),
        note: s.ikkiuchiPlacing(placement, IkkiuchiReview.placementMatches),
      );
    }
    final band = s.className(Rating.bandOf(after));
    if (review.endedPlacement) {
      return SummaryTile(label: s.ikkiuchiFirstRating.toUpperCase(), big: TileFigure('${after.round()}'), note: band);
    }
    return SummaryTile(
      label: label,
      big: TileFigure(signedPoints(after - before)),
      note: '${before.round()} → ${after.round()} · $band',
    );
  }

  /// The player's fastest takes and the cards Tobi took that they reached
  /// too, each with the player's time; a line when they took and reached
  /// none; and a guest's note.
  List<Widget> _rows(S s, IkkiuchiReview review) {
    final fastest = review.fastestTakes, beaten = review.beaten;
    List<SummaryCard> cards(List<IkkiuchiReadLog> reads) => [
          for (final r in reads) SummaryCard(r.poemId, ms: msOf(r.playerTake!)),
        ];
    return [
      ...shelfRows([
        CardShelf(s.ikkiuchiFastestTitle, Palette.land, s.ikkiuchiTookCount(match.takenBy(IkkiuchiSide.player)),
            cards(fastest)),
        CardShelf(s.ikkiuchiBeatenTitle, Palette.pink, s.ikkiuchiBeatenNote, cards(beaten)),
      ]),
      if (fastest.isEmpty && beaten.isEmpty) SummaryNote(s.ikkiuchiNoTakes),
      if (!_saved) SummaryNote(s.ikkiuchiGuestNote),
    ];
  }
}
