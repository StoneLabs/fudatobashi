import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../rank/ranked_runs.dart';
import '../results/run_summary.dart';
import 'history_widgets.dart';
import 'review_parts.dart';

/// The 100-card view's Rating and XP tab: how a ranked run moved the
/// rating and where it sits among the ranked runs (or why the exam and free
/// play don't move it), then the run's experience.
class RunRatingTab extends StatelessWidget {
  const RunRatingTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = detail.rating;
    final run = detail.run;
    return ReviewColumn(children: [
      if (rating != null) ...[
        RatingHero(rating, line: rating.before == null ? s.ratingFirst : null, placed: rating.before == null),
        _RatingTiles(detail, rating),
        if (run.forfeit)
          ReviewSlab(
            color: Palette.pinkSoft,
            child: Text(s.runForfeitText(run.cards), style: ReviewTextStyle.strong),
          ),
        _RankedRuns(detail),
      ] else
        _NoRank(run),
      ...xpParts(s, detail.xp),
    ]);
  }
}

/// A rating as a hero: the number with its change, the class it stands in
/// as the bar, the rating before as a tick, and the stamp of a [placed]
/// rating.
class RatingHero extends StatelessWidget {
  const RatingHero(this.rating, {super.key, this.line, this.placed = false});
  final RunRating rating;
  final String? line;
  final bool placed;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final after = rating.after, before = rating.before;
    final band = Rating.bandOf(after), next = Rating.nextBand(after);
    final lo = band.minRating.isFinite ? band.minRating : next!.minRating - RunRatingTuning.openSpan;
    final hi = next?.minRating ?? lo + RunRatingTuning.openSpan;
    double at(double r) => ((r - lo) / (hi - lo)).clamp(0.0, 1.0);
    final name = s.className(band);
    final gap = next == null ? s.topClassNote : s.runClassGap((hi - after).ceil(), next, hi.round());
    return ReviewHero(
      height: ReviewHeroLayout.ratingHeight,
      SummaryHero(
        banner: s.ratingLabel,
        body: HeroFigure('${after.round()}', badge: before == null ? null : ChangeBadge(after - before), line: line),
        bar: [BarPart(Palette.sea, at(after)), BarPart(Palette.paper, 1 - at(after))],
        ticks: [if (before != null && before >= lo && before <= hi) at(before)],
        labels: [BarLabel(name), BarLabel(gap, part: 1, end: true)],
        fallbackLabels: [BarLabel('$name · $gap')],
        pose: null,
        stamp: placed ? RunStamp(s.runPlacementShout) : null,
        stampOnTop: true,
      ),
    );
  }
}

/// The rating before, what the run played like and the change, as tiles.
class _RatingTiles extends StatelessWidget {
  const _RatingTiles(this.detail, this.rating);
  final RunDetail detail;
  final RunRating rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final before = rating.before, after = rating.after;
    const size = ReviewTileLayout.smallFont;
    return TileBand([
      SummaryTile(
        label: s.reviewBefore.toUpperCase(),
        big: before == null
            ? TileFigure(s.rankUnplaced, size: size * SummaryTileLayout.bigSmallFont / SummaryTileLayout.bigFont)
            : TileFigure('${before.round()}', size: size),
        note: s.reviewBeforeRun,
        color: Palette.paper,
      ),
      SummaryTile(
        label: s.runColPlayedLike.toUpperCase(),
        big: TileFigure('${rating.performance.round()}', size: size),
        note: detail.run.forfeit ? s.reviewForfeitZero : s.reviewFromScored(runTimeText(s, detail.run)),
        color: Palette.seaSoft,
      ),
      if (before == null)
        SummaryTile(
          label: s.runNewRating.toUpperCase(),
          big: TileFigure('${after.round()}', size: size),
          note: s.reviewPlacedHere,
          color: Palette.sunSoft,
        )
      else
        SummaryTile(
          label: s.runColChange.toUpperCase(),
          big: TileFigure(signedPoints(after - before), size: size),
          note: s.reviewPartWay,
          color: after >= before ? Palette.landSoft : Palette.pinkSoft,
        ),
    ], spec: ReviewTileLayout.small, height: ReviewTileLayout.ratingHeight);
  }
}

/// The rating over the ranked runs with the class lines, the latest runs
/// in a table with this one marked, and what stands out about it; led, for
/// the placement, by how it placed.
class _RankedRuns extends StatelessWidget {
  const _RankedRuns(this.detail);
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final runs = detail.rankedRuns;
    final me = detail.run;
    final rating = detail.rating!;
    final verdict = _verdict(s);
    final heading = HistoryHeading(
      title: s.runRankedTitle,
      sub: s.sub?.runRankedTitle,
      note: s.runSoFar(runs.length),
      accent: HistoryRunStyle.headingMark,
      titleFont: ReviewLayout.headingFont,
    );
    final placed = rating.before == null;
    final scored = runTimeText(s, me);
    return ReviewSlab(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (placed) ...[
          ReviewText(me.forfeit
              ? s.runPlacementForfeitText(rating.performance.round())
              : s.runPlacementText(scored, rating.performance.round())),
          const SizedBox(height: Gaps.section),
        ],
        heading,
        const SizedBox(height: ReviewLayout.headingGap),
        if (runs.length > 1) ...[
          RatingChart([for (final (_, r) in runs) r.after], mine: runs.indexWhere((r) => r.$1.id == me.id)),
          const SizedBox(height: Gaps.panel),
        ],
        RankedRunsTable(runs, highlight: me.id),
        if (verdict != null) ...[
          const SizedBox(height: Gaps.panel),
          Text(verdict, style: ReviewTextStyle.strong),
        ],
      ]),
    );
  }

  /// The run's fastest-yet or highest-rating-yet line, when it is either.
  String? _verdict(S s) {
    final earlier = [for (final r in detail.rankedRuns) if (r.$1.id != detail.run.id) r];
    final time = detail.run.time, after = detail.rating!.after;
    if (earlier.isEmpty) return null;
    if (time != null && earlier.every((r) => r.$1.time == null || r.$1.time! > time)) return s.runFastestRanked;
    if (earlier.every((r) => r.$2.after < after)) return s.runBestRating;
    return null;
  }
}

/// The exam and 100-card free play don't move the rating; the exam says who
/// won.
class _NoRank extends StatelessWidget {
  const _NoRank(this.run);
  final PastRun run;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final exam = run.mode == PlayMode.exam;
    final String text;
    if (exam && run.tobi != null && run.time != null) {
      final gap = formatSeconds((run.tobi! - run.time!).inMilliseconds.abs().toDouble(), 1);
      text = run.passed ? '${s.runExamBeat(gap)} ${s.runExamWonText}' : '${s.runExamBeaten(gap)} ${s.runExamLostText}';
    } else {
      text = s.runFreeNoRank;
    }
    return ReviewSlab(
      flatTop: true,
      color: exam ? Palette.paper : Palette.seaSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkBanner((exam ? s.examRun : s.freePlay).toUpperCase(), fontSize: SummaryHeroLayout.bannerFont),
        const SizedBox(height: Gaps.panel),
        Text(s.notForRank, style: ReviewTextStyle.headline),
        const SizedBox(height: Gaps.small),
        ReviewText(text),
      ]),
    );
  }
}
