import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_rating.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/strings.dart';
import '../rank/rank_badges.dart';
import '../side_trips/side_trip_entry.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';
import 'run_xp_tab.dart';

/// A scored 暗記練 game's Score & XP: how the score was made (D37), what it
/// did to 暗記練's rating and class (D38, ranked games only) and the XP it
/// earned (D39).
class AnkirenScoreTab extends StatelessWidget {
  const AnkirenScoreTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final before = review.ratingBefore, after = review.game.rating;
    return RunTabList(children: [
      _ScoreSum(review),
      const SizedBox(height: HistoryRunStyle.sectionGap),
      if (before != null && after != null) ...[
        _RatingPanel(review, before: before, after: after),
        const SizedBox(height: HistoryRunStyle.sectionGap),
      ],
      XpPanel(review.xp?.award.total == 0 ? null : review.xp),
    ]);
  }
}

/// D37: card points × being ready early × the level's factor = the score,
/// and the card points part by part.
class _ScoreSum extends StatelessWidget {
  const _ScoreSum(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final early = (game.memorise - game.memorised).inSeconds;
    Widget term(String value, String label, {bool result = false}) => Expanded(
          flex: result ? 1 : AnkirenReviewStyle.termFlex,
          child: DecoratedBox(
            decoration: result
                ? BoxDecoration(color: Palette.sun, border: Border.all(color: Palette.ink, width: Strokes.label))
                : const BoxDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(Gaps.tight),
              child: Column(children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenReviewStyle.sumFont)),
                ),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.sumLabelFont)),
              ]),
            ),
          ),
        );
    Widget sign(String text) => Padding(
          padding: AnkirenReviewStyle.sumSignPadding,
          child: Text(text,
              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.sumSignFont)),
        );
    String factor(double f) => f.toStringAsFixed(2);
    final shares = [
      for (final p in TapProximity.values)
        if (p != TapProximity.card) shareText(AnkirenTuning.tapShare[p]!),
    ].join(', ');
    ReviewRow part(String label, AnkirenScorePart p) =>
        ReviewRow([ReviewTable.cell(label), ReviewTable.cell('${p.cards}'), ReviewTable.cell('${p.points}')]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ReviewPanel(
        fill: AnkirenReviewStyle.sumFill,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          term('${game.recall}', s.ankirenEqCardPoints(game.maxRecall)),
          sign('×'),
          term(factor(game.earlyFactor), early > 0 ? s.ankirenEqEarly(early) : s.ankirenEqOnTime),
          sign('×'),
          term(factor(game.levelFactor), s.ankirenEqLevel(game.level!)),
          sign('='),
          term('${game.score}', s.ankirenEqPoints, result: true),
        ]),
      ),
      const SizedBox(height: Gaps.panel),
      ReviewPanel(
        child: ReviewTable(
          head: [s.ankirenColFor, s.ankirenColCards, s.ankirenColPoints],
          widths: const {0: FlexColumnWidth()},
          rows: [
            part(s.ankirenPartRight(AnkirenTuning.cardPoints), review.rightFirst),
            part(s.ankirenPartNear(shares), review.nearFirst),
            part(s.ankirenPartSecond(shareText(AnkirenTuning.tapWeights.last)), review.secondTaps),
            part(s.ankirenPartSpeed(AnkirenTuning.speedMax), review.speed),
            ReviewRow([
              ReviewTable.cell(s.ankirenRowCardPoints, strong: true),
              ReviewTable.cell('${game.cards.length}', strong: true),
              ReviewTable.cell('${game.recall}', strong: true),
            ], total: true),
          ],
        ),
      ),
    ]);
  }
}

/// D38: the rating before and after, how the game moved it, and the class
/// it stands in with the way to the next.
class _RatingPanel extends StatelessWidget {
  const _RatingPanel(this.review, {required this.before, required this.after});
  final AnkirenReview review;
  final double before, after;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final level = game.level!;
    final played = game.performance ?? after;
    final next = AnkirenRating.nextLevelAt(level);
    final progress = AnkirenReview.classProgress(after);
    final band = progress.next;
    const text = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenReviewStyle.formulaFont);
    String r(double v) => '${v.round()}';
    return ReviewPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TrackedLabel(s.ankirenRatingHead, sub: s.sub?.ankirenRatingHead),
        Row(children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${r(before)} → ${r(after)}',
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenReviewStyle.ratingFont)),
            ),
          ),
          const SizedBox(width: Gaps.panel),
          RatingChangeTag((after - before).round()),
        ]),
        const SizedBox(height: Gaps.small),
        DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: Palette.ink, width: Strokes.label)),
          child: Padding(
            padding: AnkirenReviewStyle.panelPadding,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ColoredBox(
                color: AnkirenReviewStyle.customFill,
                child: Padding(
                  padding: const EdgeInsets.all(Gaps.small),
                  child: Text('${r(before)} + ${review.k} × (${r(played)} − ${r(before)}) = ${r(after)}',
                      style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenReviewStyle.formulaFont)),
                ),
              ),
              const SizedBox(height: Gaps.small),
              Text(
                s.ankirenRatingWhy(level, r(AnkirenRatingModel.levelRatings[level]), (game.fraction * 100).round(),
                    (AnkirenRatingModel.par * 100).round(), r(played)),
                style: text,
              ),
              if (next != null) Text(s.ankirenRatingNext(level + 1, r(next)), style: text),
            ]),
          ),
        ),
        const SizedBox(height: Gaps.panel),
        Row(children: [
          ClassBadge(progress.band,
              fontSize: AnkirenReviewStyle.badgeFont, suffixSize: AnkirenReviewStyle.badgeSuffixFont),
          const SizedBox(width: AnkirenReviewStyle.barGap),
          Expanded(child: ShareBar(progress.fraction, color: Palette.sea)),
          if (band != null) ...[
            const SizedBox(width: AnkirenReviewStyle.barGap),
            ClassBadge(band, fontSize: AnkirenReviewStyle.badgeFont, suffixSize: AnkirenReviewStyle.badgeSuffixFont),
          ],
        ]),
        if (band != null)
          Padding(
            padding: const EdgeInsets.only(top: Gaps.tight),
            child: Text(s.ankirenClassAt((band.minRating - after).ceil(), band.label, r(band.minRating)),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.noteFont)),
          ),
      ]),
    );
  }
}
