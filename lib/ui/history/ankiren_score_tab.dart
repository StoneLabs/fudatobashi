import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/strings.dart';
import '../results/run_summary.dart';
import 'ankiren_widgets.dart';
import 'review_parts.dart';

/// A ranked 暗記練 game's Score & XP: how the points add up ([ScoreSum]),
/// the card points part by part ([ScoreParts]), what the game did to
/// 暗記練's rating ([RatingHero]), and the XP it earned.
class AnkirenScoreTab extends StatelessWidget {
  const AnkirenScoreTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final before = review.ratingBefore, after = review.game.rating;
    final s = S.of(context);
    final game = review.game;
    final early = (game.memorise - game.memorised).inSeconds;
    return ReviewColumn(children: [
      ScoreSum(
        firstRight: game.firstRight,
        factor: game.earlyFactor,
        factorLabel: early > 0 ? s.ankirenEqEarly(early) : s.ankirenEqOnTime,
        other: game.recall - game.firstRight,
        score: game.score!,
      ),
      ScoreParts(review),
      if (before != null && after != null)
        RatingHero(review, head: s.ankirenRatingHead.toUpperCase(), before: before, after: after),
      ...xpParts(s, review.xp),
    ]);
  }
}

/// First-tap points × their [factor] + the [other] points = the [score].
class ScoreSum extends StatelessWidget {
  const ScoreSum({
    super.key,
    required this.firstRight,
    required this.factor,
    required this.factorLabel,
    required this.other,
    required this.score,
  });

  final int firstRight, other, score;
  final double factor;
  final String factorLabel;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
            Flexible(child: term('$firstRight', s.ankirenEqFirstRight)),
            sign('×'),
            Flexible(child: term(factor.toStringAsFixed(2), factorLabel)),
            sign('+'),
            Flexible(child: term('$other', s.ankirenEqOther)),
            sign('='),
            term('$score', s.ankirenEqPoints, result: true),
          ]),
    );
  }
}

/// The card points part by part, the からふだ's apart when the game called
/// any, any [more] rows of the trip's own, and their total over every call.
class ScoreParts extends StatelessWidget {
  const ScoreParts(this.review, {super.key, this.more = const []});
  final AnkirenReview review;
  final List<(String, AnkirenScorePart)> more;

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
          if (game.karafuda.isNotEmpty) part(s.karafudaPart, review.karafuda),
          for (final (label, p) in more) part(label, p),
          ReviewRow([
            ReviewTable.cell(s.ankirenRowCardPoints, strong: true),
            ReviewTable.cell('${game.calls.length}', strong: true),
            ReviewTable.cell('${game.recall}', strong: true),
          ], total: true),
        ],
      ),
    );
  }
}

/// A trip's rating as a hero under its [head]: the rating before, what this
/// game played like and the rating after, over the class it stands in as
/// the bar, the rating before as a tick.
class RatingHero extends StatelessWidget {
  const RatingHero(this.review, {super.key, required this.head, required this.before, required this.after});
  final AnkirenReview review;
  final String head;
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
        banner: head,
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
          BarLabel(
              next == null
                  ? name
                  : '$name · ${s.ankirenClassAt(next.pointsLeft(after), next, r(next.minRating))}',
              keep: true),
        ],
        pose: null,
      ),
    );
  }
}
