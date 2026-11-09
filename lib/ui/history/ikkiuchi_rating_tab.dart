import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../results/run_summary.dart';
import 'review_parts.dart';

/// A 一騎打ち match's Rating & XP: what a ranked match did to the rating
/// (or, for a free match, that it leaves it alone), then the experience it
/// earned and where it came from.
class IkkiuchiRatingTab extends StatelessWidget {
  const IkkiuchiRatingTab(this.review, {super.key});
  final IkkiuchiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final before = review.ratingBefore, after = review.ratingAfter;
    return ReviewColumn(children: [
      if (before != null && after != null)
        _RatingHero(review, before: before, after: after)
      else
        NoRatingPanel(banner: s.ikkiuchiFree, headline: s.ikkiuchiNoRank, line: s.ikkiuchiOnlyRanked),
      ...xpParts(s, review.xp),
    ]);
  }
}

/// The rating as a hero: the rating [before], Tobi's, the result and the
/// rating [after] with its change; the class it stands in as the bar, the
/// rating before as a tick when it was in the same class. While placing,
/// the estimate's lines over the placement as the bar; the match that ends
/// placement gives the first rating.
class _RatingHero extends StatelessWidget {
  const _RatingHero(this.review, {required this.before, required this.after});
  final IkkiuchiReview review;
  final double before, after;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final match = review.match;
    final placement = review.placementMatch;
    final placing = placement != null && !review.endedPlacement;
    String r(double v) => '${v.round()}';
    return ReviewHero(
      height: IkkiuchiHistoryStyle.ratingHeight,
      metrics: IkkiuchiHistoryStyle.ratingMetrics,
      SummaryHero(
        banner: s.ikkiuchiRatingHead.toUpperCase(),
        body: Padding(
          padding: const EdgeInsets.only(top: IkkiuchiHistoryStyle.linesTop),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ValueLine(placement == null ? s.ikkiuchiPreviousRating : s.ikkiuchiPreviousEstimate, r(before)),
            ValueLine(s.ikkiuchiTobiRating, r(match.setup.opponentRating)),
            ValueLine(s.ikkiuchiResultLabel, s.ikkiuchiResult(match.result)),
            ValueLine(
              placing
                  ? s.ikkiuchiNewEstimate
                  : review.endedPlacement
                      ? s.ikkiuchiFirstRating
                      : s.ikkiuchiNewRating,
              r(after),
              badge: ChangeBadge(after - before),
              total: true,
            ),
          ]),
        ),
        bar: placing
            ? [
                BarPart(Palette.sea, placement),
                BarPart(Palette.paper, IkkiuchiReview.placementMatches - placement),
              ]
            : _classBar(),
        ticks: placing ? const [] : _ticks(),
        labels: placing
            ? [
                BarLabel(s.ikkiuchiPlacing(placement, IkkiuchiReview.placementMatches)),
                BarLabel(s.ikkiuchiPlacedIn(IkkiuchiReview.placementMatches - placement), part: 1, end: true),
              ]
            : [BarLabel(_classLabel(s), keep: true)],
        pose: null,
      ),
    );
  }

  List<BarPart> _classBar() {
    final at = IkkiuchiReview.classProgress(after).fraction;
    return [BarPart(Palette.sea, at), BarPart(Palette.paper, 1 - at)];
  }

  List<double> _ticks() {
    final now = IkkiuchiReview.classProgress(after), then = IkkiuchiReview.classProgress(before);
    return [if (then.band.id == now.band.id) then.fraction];
  }

  /// The class the rating stands in, and how far the next one is.
  String _classLabel(S s) {
    final progress = IkkiuchiReview.classProgress(after);
    final name = s.className(progress.band);
    final next = progress.next;
    if (next == null) return name;
    return '$name · ${s.ikkiuchiClassAt((next.minRating - after).ceil(), next, '${next.minRating.round()}')}';
  }
}
