import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/teiichi.dart';
import '../../domain/teiichi_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../l10n/teiichi_review_strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';
import 'karafuda_panel.dart';
import 'review_parts.dart';

/// [setup] in a line: its cards and rows, and its からふだ when it called any.
String teiichiSetupText(S s, TeiichiSetup setup) => [
      s.teiichiSetupLine(setup.cards, setup.rows),
      if (setup.karafuda > 0) s.karafudaCount(setup.karafuda),
    ].join(' · ');

/// A 定位置 game's Overview, its results reopened: a ranked game's points or
/// forfeit, or a hero of the cards found with the first tap, stamped when
/// it ended early, cleared or failed its level, was custom or set the best
/// placing time; three tiles (the placing time, and a ranked game's first
/// taps and rating, or else the wrong taps or strikes and the median find,
/// a level game's XP in place of the median);
/// the cards slowest to place and those never placed; how its からふだ went
/// when it called any; then down to the floor the game against the last one
/// with the same setup. The hero and the median count the cards dealt
/// alone, as the results do.
class TeiichiOverviewTab extends StatelessWidget {
  const TeiichiOverviewTab(this.review, {super.key});
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewColumn(
      fill: _SameSetup(review),
      fillMinHeight: 0,
      children: [
        ReviewHero(_hero(s), metrics: ReviewHeroLayout.ankirenMetrics),
        TileBand(_tiles(s), spec: ReviewTileLayout.spec, minHeight: ReviewLayout.tileHeight),
        if (review.game.placed.isNotEmpty) _SlowestToPlace(review.game),
        if (review.game.unplaced.isNotEmpty) _Unplaced(review.game),
        if (review.game.recall.karafuda.isNotEmpty) KarafudaPanel(review.game.recall),
      ],
    );
  }

  SummaryHero _hero(S s) => review.game.ranked ? _points(s) : _firstTaps(s);

  /// A ranked game: its points, the placing time where 暗記練 says the top
  /// score, the bar its finds, what the placing time added and its
  /// からふだ's points; a forfeit, which counts as 0, saying so.
  SummaryHero _points(S s) {
    final game = review.game;
    final recall = game.recall;
    final bar = _foundBar(game);
    final labels = _foundLabels(s, game);
    if (game.forfeit) {
      return SummaryHero(
        banner: s.ankirenPointsLabel.toUpperCase(),
        body: HeroWord(s.historyForfeit, metrics: ReviewHeroLayout.metrics),
        bar: bar,
        labels: labels,
        pose: TobiPose.shocked,
      );
    }
    final score = recall.score!;
    final karafuda = review.recall.karafuda.points;
    final finds = recall.recall - karafuda;
    final bonus = score - recall.recall;
    final best = review.recall.bestBefore;
    final stamp = review.recall.isBest && best != null
        ? RunStamp(s.ankirenBestRankedStamp, sub: s.reviewUpFrom(best.score!), fontSize: RunStampStyle.heroFont)
        : null;
    return SummaryHero(
      banner: s.ankirenPointsLabel.toUpperCase(),
      body: HeroFigure(groupDigits(score),
          unit: s.teiichiPlacedIn(formatMinutes(game.placing)),
          top: ReviewHeroLayout.pointsTop,
          size: ReviewHeroLayout.pointsFont),
      bar: score == 0
          ? [BarPart(Palette.paper, 1)]
          : [
              BarPart(Palette.land, finds, done: true),
              BarPart(Palette.sun, bonus, done: true),
              BarPart(KarafudaStyle.bar, karafuda, done: true),
            ],
      labels: [
        if (finds > 0) BarLabel(s.summaryFinds(groupDigits(finds))),
        if (bonus > 0) BarLabel(s.teiichiBonusBar(groupDigits(bonus)), part: 1),
        if (karafuda > 0) BarLabel(s.karafudaPoints(groupDigits(karafuda)), part: 2),
      ],
      fallbackLabels: [BarLabel(s.reviewCardPoints(groupDigits(recall.recall)))],
      pose: stamp == null ? TobiPose.relaxed : TobiPose.cheering,
      stamp: stamp,
      stampOnTop: true,
    );
  }

  /// The first-tap finds, the cards found later and the rest, of all dealt.
  static List<BarPart> _foundBar(TeiichiGameRecord game) => [
        BarPart(Palette.land, game.recall.firstTaps, done: true),
        BarPart(Palette.sun, game.recall.found - game.recall.firstTaps, done: true),
        BarPart(Palette.pink, game.dealt - game.recall.found),
      ];

  static List<BarLabel> _foundLabels(S s, TeiichiGameRecord game) {
    final firstTaps = game.recall.firstTaps;
    final late = game.recall.found - firstTaps;
    final missed = game.dealt - game.recall.found;
    return [
      BarLabel(s.teiichiFirstTapBar(firstTaps)),
      if (late > 0) BarLabel(s.summaryFoundLate(late), part: 1, end: true),
      if (missed > 0) BarLabel(s.summaryMissedCount(missed), part: 2, end: true),
    ];
  }

  /// Any other game: the cards found with the first tap.
  SummaryHero _firstTaps(S s) {
    final game = review.game;
    final recall = game.recall;
    final cards = game.dealt;
    final firstTaps = recall.firstTaps;
    final best = review.bestBefore;
    final setup = teiichiSetupText(s, game.setup);
    final level = game.level;
    final levelTag = level == null ? null : s.ankirenLevelTag(level);
    final stamp = !game.completed
        ? RunStamp(s.endedEarly, sub: game.custom ? s.ankirenCustom : levelTag, color: AnkirenReviewStyle.muted)
        : level != null
            ? game.cleared
                ? RunStamp(s.historyCleared, sub: levelTag)
                : RunStamp(s.historyFailed, sub: levelTag, color: AnkirenReviewStyle.muted)
            : game.custom
                ? RunStamp(s.ankirenCustom, sub: setup, color: AnkirenReviewStyle.muted)
                : review.isBest
                    ? RunStamp(s.teiichiBestStamp, sub: best == null ? null : s.teiichiBestWas(formatMinutes(best)))
                    : null;
    return SummaryHero(
      banner: s.ankirenFirstTapFact.toUpperCase(),
      body: HeroCount('$firstTaps',
          label: s.ankirenOfMax(cards), note: s.reviewRightCardFirst, metrics: ReviewHeroLayout.ankirenMetrics),
      bar: _foundBar(game),
      labels: _foundLabels(s, game),
      pose: review.isBest || game.cleared || firstTaps == cards ? TobiPose.cheering : TobiPose.standard,
      stamp: stamp,
      stampOnTop: true,
      color: game.custom ? AnkirenReviewStyle.customFill : Palette.paper,
    );
  }

  List<SummaryTile> _tiles(S s) {
    final game = review.game;
    if (game.ranked) {
      return [
        SummaryTile(
          label: s.teiichiPlacingLabel,
          big: TileFigure(formatMinutes(game.placing)),
          note: game.forfeit ? s.historyForfeit : s.teiichiBonusNote(game.bonusPercent),
        ),
        SummaryTile(
          label: s.ankirenFirstTapFact.toUpperCase(),
          big: TileFigure('${game.recall.firstTaps}', unit: '/${game.dealt}'),
          note: s.reviewRightCardFirst,
          color: Palette.landSoft,
        ),
        ankirenRatingTile(s, review.recall),
      ];
    }
    final best = review.bestBefore;
    final median = game.recall.medianFindMs;
    final wrongKarafuda = game.recall.karafuda.where((c) => c.wrongTaps > 0).length;
    return [
      SummaryTile(
        label: s.teiichiPlacingLabel,
        big: TileFigure(formatMinutes(game.placing)),
        note: review.isBest
            ? s.teiichiNewBest
            : !game.counts
                ? s.teiichiNotCounted
                : best == null
                    ? s.teiichiNoBest
                    : s.teiichiBestThen(formatMinutes(best)),
      ),
      if (game.level != null)
        SummaryTile(
          label: s.ankirenStrikesFact.toUpperCase(),
          big: TileFigure('${game.strikes}'),
          note: s.reviewUnderClears(AnkirenTuning.strikesOut),
        )
      else
        SummaryTile(
          label: s.teiichiWrongTaps,
          big: TileFigure('${game.wrongTaps}'),
          note: game.wrongTaps == 0
              ? s.summaryNone
              : wrongKarafuda > 0
                  ? s.teiichiWrongOnKarafuda(game.wrongCards, wrongKarafuda)
                  : s.teiichiWrongOn(game.wrongCards),
        ),
      if (game.level != null)
        xpTile(s, review.xp)
      else
        SummaryTile(
          label: s.ankirenMedianFact.toUpperCase(),
          big: median == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(median), unit: ' s'),
          note: s.summaryFound(game.recall.found),
        ),
    ];
  }
}

/// The cards that took longest to place, each with its placing time.
class _SlowestToPlace extends StatelessWidget {
  const _SlowestToPlace(this.game);
  final TeiichiGameRecord game;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      title: s.teiichiSlowestPlace,
      sub: s.sub?.teiichiSlowestPlace,
      mark: TeiichiReviewStyle.slowFill,
      child: SummaryCards([
        for (final p in game.slowest.take(TeiichiReviewStyle.slowest))
          SummaryCard(p.poemId, ms: p.time.inMicroseconds / Duration.microsecondsPerMillisecond),
      ]),
    );
  }
}

/// The cards never placed, which count as full misses.
class _Unplaced extends StatelessWidget {
  const _Unplaced(this.game);
  final TeiichiGameRecord game;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      title: s.teiichiUnplacedTitle,
      sub: s.sub?.teiichiUnplacedTitle,
      note: s.teiichiUnplacedPoints,
      mark: Palette.pink,
      child: SummaryCards([for (final id in game.unplaced) SummaryCard(id)]),
    );
  }
}

/// The game against the last one with the same setup, or on its own when
/// it is the first; its からふだ answered first among them when it called
/// any.
class _SameSetup extends StatelessWidget {
  const _SameSetup(this.review);
  final TeiichiReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final setup = review.game.setup;
    return ReviewSlab(
      title: s.ankirenSetupTitle,
      sub: s.sub?.ankirenSetupTitle,
      note: s.teiichiSetupLine(setup.cards, setup.rows),
      flatBottom: true,
      expands: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_table(s, review.game, review.last)]),
    );
  }

  static Widget _table(S s, TeiichiGameRecord game, TeiichiGameRecord? last) {
    String time(double? ms) => ms == null ? missingTime : '${formatSeconds(ms)}s';
    String firstTaps(TeiichiGameRecord g) => '${g.recall.firstTaps}/${g.dealt}';
    String karafuda(TeiichiGameRecord g) => '${g.recall.karafudaTally.right}/${g.recall.karafudaTally.called}';
    final karafudaCalled = game.recall.karafuda.isNotEmpty;
    final now = game.recall.medianFindMs;
    Widget note(String text) =>
        Padding(padding: const EdgeInsets.only(left: ReviewTableStyle.noteGap), child: ReviewTable.cell(text));
    if (last == null) {
      return ReviewTable(
        head: ['', s.ankirenColThis, ''],
        starts: const {2},
        rows: [
          ReviewRow([
            ReviewTable.cell(s.teiichiFormPlacing, strong: true),
            ReviewTable.cell(formatMinutes(game.placing)),
            note(s.ankirenSetupFirst),
          ]),
          ReviewRow([
            ReviewTable.cell(s.ankirenRowFirstTap, strong: true),
            ReviewTable.cell(firstTaps(game)),
            const SizedBox(),
          ]),
          if (karafudaCalled)
            ReviewRow([
              ReviewTable.cell(s.karafudaRowFirstTap, strong: true),
              ReviewTable.cell(karafuda(game)),
              const SizedBox(),
            ]),
          ReviewRow([
            ReviewTable.cell(s.teiichiFormWrongTaps, strong: true),
            ReviewTable.cell('${game.wrongTaps}'),
            const SizedBox(),
          ]),
          ReviewRow([
            ReviewTable.cell(s.ankirenRowMedian, strong: true),
            ReviewTable.cell(time(now)),
            const SizedBox(),
          ]),
        ],
      );
    }
    final faster = (last.placing - game.placing).inMilliseconds / Duration.millisecondsPerSecond;
    final quicker = faster.round();
    final more = game.recall.firstTaps - last.recall.firstTaps;
    final moreKarafuda = game.recall.karafudaTally.right - last.recall.karafudaTally.right;
    final fewer = last.wrongTaps - game.wrongTaps;
    final then = last.recall.medianFindMs;
    final sooner = now == null || then == null ? null : then - now;
    Widget good(String text, bool better) =>
        ReviewTable.cell(text, strong: better, color: better ? HistoryRunStyle.ahead : null);
    return ReviewTable(
      head: ['', s.ankirenColThis, s.shortDate(last.startedAt), ''],
      starts: const {3},
      rows: [
        ReviewRow([
          ReviewTable.cell(s.teiichiFormPlacing, strong: true),
          good(formatMinutes(game.placing), quicker > 0),
          ReviewTable.cell(formatMinutes(last.placing)),
          note(switch (quicker) {
            0 => s.ankirenSame,
            > 0 => s.ankirenFaster('$quicker'),
            _ => s.ankirenSlower('${-quicker}'),
          }),
        ]),
        ReviewRow([
          ReviewTable.cell(s.ankirenRowFirstTap, strong: true),
          good(firstTaps(game), more > 0),
          ReviewTable.cell(firstTaps(last)),
          note(more > 0
              ? s.ankirenMoreFirst(more)
              : more < 0
                  ? s.ankirenFewerFirst(-more)
                  : s.ankirenSame),
        ]),
        if (karafudaCalled)
          ReviewRow([
            ReviewTable.cell(s.karafudaRowFirstTap, strong: true),
            good(karafuda(game), moreKarafuda > 0),
            ReviewTable.cell(karafuda(last)),
            note(moreKarafuda > 0
                ? s.ankirenMoreFirst(moreKarafuda)
                : moreKarafuda < 0
                    ? s.ankirenFewerFirst(-moreKarafuda)
                    : s.ankirenSame),
          ]),
        ReviewRow([
          ReviewTable.cell(s.teiichiFormWrongTaps, strong: true),
          good('${game.wrongTaps}', fewer > 0),
          ReviewTable.cell('${last.wrongTaps}'),
          note(fewer > 0
              ? s.teiichiFewerTaps(fewer)
              : fewer < 0
                  ? s.teiichiMoreTaps(-fewer)
                  : s.ankirenSame),
        ]),
        ReviewRow([
          ReviewTable.cell(s.ankirenRowMedian, strong: true),
          good(time(now), (sooner ?? 0) > 0),
          ReviewTable.cell(time(then)),
          note(switch (sooner) {
            null => missingTime,
            final d when formatSeconds(d.abs()) == formatSeconds(0) => s.ankirenSame,
            final d when d > 0 => s.ankirenFaster(formatSeconds(d)),
            final d => s.ankirenSlower(formatSeconds(-d)),
          }),
        ]),
      ],
    );
  }
}
