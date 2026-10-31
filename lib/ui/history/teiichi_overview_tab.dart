import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/teiichi.dart';
import '../../domain/teiichi_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/ankiren_strings.dart';
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

/// A 定位置 game's Overview, its results reopened: a hero of the cards
/// found with the first tap, stamped when it ended early, was custom or set
/// the best placing time; three tiles (the placing time against the best
/// then, the wrong taps and the median find); the cards slowest to place;
/// how its からふだ went when it called any; then down to the floor the
/// game against the last one with the same setup. The hero and the median
/// count the laid-out cards alone, as the results do.
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
        if (review.game.recall.karafuda.isNotEmpty) KarafudaPanel(review.game.recall),
      ],
    );
  }

  SummaryHero _hero(S s) {
    final game = review.game;
    final recall = game.recall;
    final cards = recall.cards.length;
    final firstTaps = recall.firstTaps;
    final late = recall.found - firstTaps;
    final missed = cards - recall.found;
    final best = review.bestBefore;
    final setup = teiichiSetupText(s, game.setup);
    final stamp = !game.completed
        ? RunStamp(s.endedEarly, sub: game.custom ? s.ankirenCustom : null, color: AnkirenReviewStyle.muted)
        : game.custom
            ? RunStamp(s.ankirenCustom, sub: setup, color: AnkirenReviewStyle.muted)
            : review.isBest
                ? RunStamp(s.teiichiBestStamp, sub: best == null ? null : s.teiichiBestWas(formatMinutes(best)))
                : null;
    return SummaryHero(
      banner: s.ankirenFirstTapFact.toUpperCase(),
      body: HeroCount('$firstTaps',
          label: s.ankirenOfMax(cards), note: s.reviewRightCardFirst, metrics: ReviewHeroLayout.ankirenMetrics),
      bar: [
        BarPart(Palette.land, firstTaps, done: true),
        BarPart(Palette.sun, late, done: true),
        BarPart(Palette.pink, missed),
      ],
      labels: [
        BarLabel(s.teiichiFirstTapBar(firstTaps)),
        if (late > 0) BarLabel(s.summaryFoundLate(late), part: 1, end: true),
        if (missed > 0) BarLabel(s.summaryMissedCount(missed), part: 2, end: true),
      ],
      pose: review.isBest || firstTaps == cards ? TobiPose.cheering : TobiPose.standard,
      stamp: stamp,
      stampOnTop: true,
      color: game.custom ? AnkirenReviewStyle.customFill : Palette.paper,
    );
  }

  List<SummaryTile> _tiles(S s) {
    final game = review.game;
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
      SummaryTile(
        label: s.teiichiWrongTaps,
        big: TileFigure('${game.wrongTaps}'),
        note: game.wrongTaps == 0
            ? s.summaryNone
            : wrongKarafuda > 0
                ? s.teiichiWrongOnKarafuda(game.wrongCards, wrongKarafuda)
                : s.teiichiWrongOn(game.wrongCards),
      ),
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
    String firstTaps(TeiichiGameRecord g) => '${g.recall.firstTaps}/${g.recall.cards.length}';
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
