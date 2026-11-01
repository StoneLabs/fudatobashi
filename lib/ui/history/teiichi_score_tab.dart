import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi_review.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_review_strings.dart';
import '../play/time_format.dart';
import 'ankiren_score_tab.dart';
import 'review_parts.dart';

/// A ranked 定位置 game's Score: how the points add up, with the placing
/// time's factor where 暗記練's has being ready early, or that a forfeit
/// counts as 0; the card points part by part, the cards never placed among
/// them; and what the game did to 定位置's rating.
class TeiichiScoreTab extends StatelessWidget {
  const TeiichiScoreTab(this.review, {super.key});
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final recall = review.recall;
    final before = recall.ratingBefore, after = game.recall.rating;
    return ReviewColumn(children: [
      if (game.forfeit)
        ReviewSlab(
          title: s.reviewSumTitle,
          sub: s.sub?.reviewSumTitle,
          color: Palette.seaSoft,
          flatTop: true,
          child: Text(s.teiichiForfeitPoints, style: ReviewTextStyle.caption.copyWith(color: Palette.ink)),
        )
      else
        ScoreSum(
          firstRight: game.recall.firstRight,
          factor: game.scoreFactor,
          factorLabel: s.teiichiEqPlaced(formatMinutes(game.placing)),
          other: game.recall.recall - game.recall.firstRight,
          score: game.recall.score!,
        ),
      ScoreParts(recall, more: [
        if (game.unplaced.isNotEmpty) (s.teiichiPartUnplaced, (cards: game.unplaced.length, points: 0)),
      ]),
      if (before != null && after != null)
        RatingHero(recall, head: s.tripRatingBand(SideTrip.teiichi), before: before, after: after),
    ]);
  }
}
