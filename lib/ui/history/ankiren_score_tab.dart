import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/strings.dart';
import '../results/run_summary.dart';
import 'ankiren_widgets.dart';
import 'review_parts.dart';

/// A ranked 暗記練 game's Score & XP: how the points add up, the card
/// points part by part, what the game did to 暗記練's rating, and the XP
/// it earned.
class AnkirenScoreTab extends StatelessWidget {
  const AnkirenScoreTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final before = review.ratingBefore, after = review.game.rating;
    return ReviewColumn(children: [
      _ScoreSum(review),
      _ScoreParts(review),
      if (before != null && after != null) _RatingHero(review, before: before, after: after),
      ...xpParts(S.of(context), review.xp),
    ]);
  }
}

/// First-tap points × being ready early + the other points = the points.
class _ScoreSum extends StatelessWidget {
  const _ScoreSum(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final early = (game.memorise - game.memorised).inSeconds;
    Widget term(String value, String label, {bool result = false}) => DecoratedBox(
          decoration: result
              ? BoxDecoration(color: Palette.sun, border: Border.all(color: Palette.ink, width: Strokes.label))
              : const BoxDecoration(),
          child: Padding(
            padding: result ? AnkirenReviewStyle.resultPadding : AnkirenReviewStyle.termPadding,
            child: Column(children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    maxLines: 1,
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenReviewStyle.sumFont, height: 1)),
              ),
              const SizedBox(height: AnkirenReviewStyle.termGap),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: Weights.black, fontSize: AnkirenReviewStyle.sumLabelFont, height: 1.15)),
            ]),
          ),
        );
    Widget sign(String text) => Padding(
          padding: AnkirenReviewStyle.sumSignPadding,
          child: Text(text,
              style: const TextStyle(
                  fontWeight: Weights.black, fontSize: AnkirenReviewStyle.sumSignFont, color: Palette.inkSoft)),
        );
    return ReviewSlab(
      title: s.reviewSumTitle,
      sub: s.sub?.reviewSumTitle,
      color: Palette.seaSoft,
      flatTop: true,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: term('${game.firstRight}', s.ankirenEqFirstRight)),
            sign('×'),
            Flexible(
                child:
                    term(game.earlyFactor.toStringAsFixed(2), early > 0 ? s.ankirenEqEarly(early) : s.ankirenEqOnTime)),
            sign('+'),
            Flexible(child: term('${game.recall - game.firstRight}', s.ankirenEqOther)),
            sign('='),
            term('${game.score}', s.ankirenEqPoints, result: true),
          ]),
    );
  }
}

/// The card points part by part, and their total.
class _ScoreParts extends StatelessWidget {
  const _ScoreParts(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    ReviewRow part(String label, AnkirenScorePart p) =>
        ReviewRow([ReviewTable.cell(label), ReviewTable.cell('${p.cards}'), ReviewTable.cell('${p.points}')]);
    return ReviewSlab(
      child: ReviewTable(
        head: [s.ankirenColFor, s.ankirenColCards, s.ankirenColPoints],
        stretch: 0,
        rows: [
          part(s.ankirenPartRight(AnkirenTuning.cardPoints), review.rightFirst),
          part(s.ankirenPartSpeed(AnkirenTuning.speedMax), review.speed),
          part(s.ankirenPartNear, review.nearFirst),
          part(s.ankirenPartSecond(shareText(AnkirenTuning.tapWeights.last)), review.secondTaps),
          ReviewRow([
            ReviewTable.cell(s.ankirenRowCardPoints, strong: true),
            ReviewTable.cell('${game.cards.length}', strong: true),
            ReviewTable.cell('${game.recall}', strong: true),
          ], total: true),
        ],
      ),
    );
  }
}

/// 暗記練's rating as a hero: the rating before, what this game played like
/// and the rating after, over the class it stands in as the bar, the
/// rating before as a tick.
class _RatingHero extends StatelessWidget {
  const _RatingHero(this.review, {required this.before, required this.after});
  final AnkirenReview review;
  final double before, after;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final played = review.game.performance ?? after;
    final progress = AnkirenReview.classProgress(after);
    final band = progress.band, next = progress.next;
    final then = AnkirenReview.classProgress(before);
    final name = s.className(band);
    String r(double v) => '${v.round()}';
    return ReviewHero(
      height: ReviewHeroLayout.ankirenRatingHeight,
      metrics: ReviewHeroLayout.ankirenRatingMetrics,
      SummaryHero(
        banner: s.ankirenRatingHead.toUpperCase(),
        body: Padding(
          padding: const EdgeInsets.only(top: ReviewHeroLayout.ankirenLinesTop),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ValueLine(s.ankirenPreviousRating, r(before)),
            ValueLine(s.ankirenPlayedLike, r(played)),
            ValueLine(s.ankirenNewRating, r(after), badge: ChangeBadge(after - before), total: true),
          ]),
        ),
        bar: [BarPart(Palette.sea, progress.fraction), BarPart(Palette.paper, 1 - progress.fraction)],
        ticks: [if (then.band.id == band.id) then.fraction],
        labels: [
          BarLabel(next == null
              ? name
              : '$name · ${s.ankirenClassAt((next.minRating - after).ceil(), next, r(next.minRating))}'),
        ],
        pose: null,
      ),
    );
  }
}
