import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';
import 'review_parts.dart';

/// A 暗記練 game's Overview, its summary reopened: a hero (a ranked game's
/// points, any other game's right first taps), three tiles, where the first
/// taps landed, then down to the floor the memorise time (ranked) or the
/// game against the last one with the same setup.
class AnkirenOverviewTab extends StatelessWidget {
  const AnkirenOverviewTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final overview = _Overview(s, review);
    return ReviewColumn(
      fill: game.scored ? _MemoriseTime(review) : _SameSetup(review),
      fillMinHeight: 0,
      children: [
        ReviewHero(overview.hero(), metrics: ReviewHeroLayout.ankirenMetrics),
        TileBand(overview.tiles(), spec: ReviewTileLayout.spec, minHeight: ReviewLayout.tileHeight),
        _FirstTapMix(review),
      ],
    );
  }
}

/// What a game's Overview shows above its panels.
class _Overview {
  _Overview(this.s, this.review);

  final S s;
  final AnkirenReview review;

  AnkirenGameRecord get game => review.game;
  int get cards => game.cards.length;

  SummaryHero hero() => game.scored ? _points() : _firstTaps();

  List<SummaryTile> tiles() => game.scored
      ? [_firstTapTile(), _ratingTile(), xpTile(s, review.xp)]
      : [_foundTile(), _medianTile(), if (game.custom) _strikesTile() else xpTile(s, review.xp)];

  /// A ranked game: its points, the bar the card points and what being
  /// ready early added; a best stamped with the best before.
  SummaryHero _points() {
    final score = game.score!, recall = game.recall, early = score - recall;
    final best = review.bestBefore;
    final stamp = review.isBest && best != null
        ? RunStamp(s.ankirenBestRankedStamp, sub: s.reviewUpFrom(best.score!), fontSize: RunStampStyle.heroFont)
        : null;
    return SummaryHero(
      banner: s.ankirenPointsLabel.toUpperCase(),
      body: HeroFigure(groupDigits(score),
          unit: s.ankirenOfMax(groupDigits(game.maxScore ?? score)),
          top: ReviewHeroLayout.pointsTop,
          size: ReviewHeroLayout.pointsFont),
      bar: [
        BarPart(Palette.land, recall, done: true),
        BarPart(Palette.sun, early, done: true),
        BarPart(Palette.paper, math.max(0, (game.maxScore ?? score) - score)),
      ],
      labels: [
        BarLabel(
            early > 0
                ? s.reviewPointsMade(groupDigits(recall), groupDigits(early))
                : s.reviewCardPoints(groupDigits(recall)),
            runOn: true),
      ],
      fallbackLabels: [BarLabel(s.reviewCardPoints(groupDigits(recall)))],
      pose: stamp == null ? TobiPose.relaxed : TobiPose.cheering,
      stamp: stamp,
      stampOnTop: true,
    );
  }

  /// Any other game: the cards found on the first tap, stamped cleared or
  /// failed (a level) or not scored (custom); the bar a level's strikes, or
  /// the memorise time used.
  SummaryHero _firstTaps() {
    final level = game.level;
    final cleared = AnkirenLadder.clears(completed: game.completed, strikes: game.strikes);
    final sub = game.custom ? s.ankirenCustom : level == null ? null : s.ankirenLevelTag(level);
    final stamp = game.custom
        ? RunStamp(s.ankirenNotScored, sub: sub, color: AnkirenReviewStyle.muted)
        : cleared
            ? RunStamp(s.historyCleared, sub: sub)
            : RunStamp(s.historyFailed, sub: sub, color: AnkirenReviewStyle.muted);
    return SummaryHero(
      banner: s.ankirenFirstTapFact.toUpperCase(),
      body: HeroCount('${game.firstTaps}',
          label: s.ankirenOfMax(cards), note: s.reviewRightCardFirst, metrics: ReviewHeroLayout.ankirenMetrics),
      bar: level == null ? _memorisedBar() : _strikesBar(),
      labels: level == null ? _memorisedLabels() : _strikesLabels(cleared),
      pose: cleared && !game.custom ? TobiPose.cheering : TobiPose.standard,
      stamp: stamp,
      stampOnTop: true,
      color: game.custom ? AnkirenReviewStyle.customFill : Palette.paper,
    );
  }

  /// A part a strike up to the strikes that fail a level, pink when taken.
  List<BarPart> _strikesBar() => [
        for (var i = 0; i < AnkirenTuning.strikesOut; i++) BarPart(i < game.strikes ? Palette.pink : Palette.paper, 1),
      ];

  List<BarLabel> _strikesLabels(bool cleared) => [
        BarLabel(s.ankirenStrikes(game.strikes)),
        BarLabel(s.reviewUnderClears(AnkirenTuning.strikesOut),
            part: AnkirenTuning.strikesOut - 1, end: true, color: cleared ? Palette.inkSoft : null),
      ];

  List<BarPart> _memorisedBar() => [
        BarPart(Palette.sea, game.memorised.inMilliseconds),
        BarPart(Palette.paper, math.max(0, (game.memorise - game.memorised).inMilliseconds)),
      ];

  List<BarLabel> _memorisedLabels() =>
      [BarLabel(s.reviewMemorisedOf(formatMinutes(game.memorised), formatMinutes(game.memorise)))];

  SummaryTile _firstTapTile() => SummaryTile(
        label: s.ankirenFirstTapFact.toUpperCase(),
        big: TileFigure('${game.firstTaps}', unit: '/$cards'),
        note: s.reviewRightCardFirst,
        color: Palette.landSoft,
      );

  SummaryTile _ratingTile() {
    final before = review.ratingBefore, after = game.rating;
    if (after == null) {
      return SummaryTile(label: s.ratingLabel, big: const TileFigure(missingTime), note: '', color: Palette.pinkSoft);
    }
    final band = s.className(AnkirenReview.classProgress(after).band);
    if (before == null) {
      return SummaryTile(
          label: s.ratingLabel, big: TileFigure('${after.round()}'), note: band, color: Palette.pinkSoft);
    }
    return SummaryTile(
      label: s.ratingLabel,
      big: TileFigure(signedPoints(after - before)),
      note: '${before.round()} → ${after.round()} · $band',
      color: Palette.pinkSoft,
    );
  }

  SummaryTile _foundTile() {
    final missed = cards - game.found;
    return SummaryTile(
      label: s.ankirenFoundFact.toUpperCase(),
      big: TileFigure('${game.found}', unit: '/$cards'),
      note: missed == 0 ? s.reviewEveryCard : s.summaryMissedCount(missed),
      color: Palette.landSoft,
    );
  }

  SummaryTile _medianTile() {
    final median = game.medianFindMs;
    return SummaryTile(
      label: s.ankirenMedianFact.toUpperCase(),
      big: median == null ? const TileFigure(missingTime) : TileFigure(formatSeconds(median), unit: ' s'),
      note: s.summaryFound(game.found),
      color: Palette.seaSoft,
    );
  }

  SummaryTile _strikesTile() => SummaryTile(
        label: s.ankirenStrikesFact.toUpperCase(),
        big: TileFigure('${game.strikes}'),
        note: s.reviewWrongTaps,
        color: Palette.pinkSoft,
      );
}

/// This game's first taps by tier, over the earlier games' with the same
/// setup (a custom game's last one).
class _FirstTapMix extends StatelessWidget {
  const _FirstTapMix(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final last = review.last;
    return ReviewSlab(
      title: s.ankirenMixTitle,
      sub: s.sub?.ankirenMixTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TierMixBar(label: s.ankirenThisGame, sub: s.ankirenCardsCount(game.cards.length), mix: game.mix),
        if (!game.custom && review.peers.isNotEmpty)
          TierMixBar(
              label: s.ankirenUsual,
              sub: s.ankirenGamesAtLevel(review.peers.length, game.level),
              mix: review.usualMix)
        else if (last != null)
          TierMixBar(label: s.shortDate(last.startedAt), sub: s.ankirenSameSetup, mix: last.mix),
        const TierLegend(),
      ]),
    );
  }
}

/// The memorise time used out of the time allowed, the earlier games' as
/// ticks, and what being ready early paid.
class _MemoriseTime extends StatelessWidget {
  const _MemoriseTime(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final allowed = game.memorise;
    final early = allowed - game.memorised;
    double share(Duration d) =>
        allowed == Duration.zero ? 0 : (d.inMilliseconds / allowed.inMilliseconds).clamp(0.0, 1.0);
    const end = TextStyle(fontWeight: Weights.bold, fontSize: ReviewLayout.captionFont);
    final used = [
      s.ankirenMemoUsed(formatMinutes(game.memorised)),
      if (early > Duration.zero) s.ankirenMemoEarly(early.inSeconds),
    ].join(' · ');
    return ReviewSlab(
      title: s.ankirenMemoTitle,
      sub: s.sub?.ankirenMemoTitle,
      note: s.ankirenMemoAllowed(formatMinutes(allowed)),
      flatBottom: true,
      expands: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ShareBar(share(game.memorised), ticks: [for (final g in review.peers) share(g.memorised)]),
        const SizedBox(height: Gaps.tight),
        Row(children: [
          Text(formatMinutes(Duration.zero), style: end),
          Expanded(
            child: Text(used,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: Weights.black, fontSize: ReviewLayout.captionFont)),
          ),
          Text(formatMinutes(allowed), style: end),
        ]),
        const SizedBox(height: Gaps.small),
        Text(
          [
            if (game.earlyFactor > 1) '${s.ankirenMemoPays(game.earlyFactor.toStringAsFixed(2))}.',
            if (review.peers.isNotEmpty)
              s.ankirenMemoTicks([for (final g in review.peers) formatMinutes(g.memorised)].join(', ')),
          ].join(' '),
          style: ReviewTextStyle.caption.copyWith(color: Palette.ink),
        ),
      ]),
    );
  }
}

/// A game without points against the last one with the same setup, or on
/// its own when it is the first.
class _SameSetup extends StatelessWidget {
  const _SameSetup(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    return ReviewSlab(
      title: s.ankirenSetupTitle,
      sub: s.sub?.ankirenSetupTitle,
      note: game.custom
          ? s.ankirenSetupNote(game.perSide)
          : game.level == null
              ? null
              : s.historyFreeLevel(game.level!),
      flatBottom: true,
      expands: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _table(s, game, review.last),
        if (game.custom) ...[
          const SizedBox(height: Gaps.panel),
          Text(s.ankirenCustomUnscored, style: ReviewTextStyle.caption.copyWith(color: Palette.ink)),
        ],
      ]),
    );
  }

  static Widget _table(S s, AnkirenGameRecord game, AnkirenGameRecord? last) {
    String time(double? ms) => ms == null ? missingTime : '${formatSeconds(ms)}s';
    final now = game.medianFindMs;
    if (last == null) {
      return ReviewTable(
        head: ['', s.ankirenColThis, ''],
        rows: [
          ReviewRow([
            ReviewTable.cell(s.ankirenRowFirstTap, strong: true),
            ReviewTable.cell('${game.firstTaps}/${game.cards.length}'),
            Padding(
                padding: const EdgeInsets.only(left: ReviewTableStyle.noteGap),
                child: ReviewTable.cell(s.ankirenSetupFirst)),
          ]),
          ReviewRow([
            ReviewTable.cell(s.ankirenRowMedian, strong: true),
            ReviewTable.cell(time(now)),
            const SizedBox(),
          ]),
          ReviewRow([
            ReviewTable.cell(s.ankirenRowMemorised, strong: true),
            ReviewTable.cell(formatMinutes(game.memorised)),
            Padding(
                padding: const EdgeInsets.only(left: ReviewTableStyle.noteGap),
                child: ReviewTable.cell(s.ankirenOfMax(formatMinutes(game.memorise)))),
          ]),
        ],
        starts: const {2},
      );
    }
    final more = game.firstTaps - last.firstTaps;
    final then = last.medianFindMs;
    final faster = now == null || then == null ? null : then - now;
    Widget good(String text, bool better) =>
        ReviewTable.cell(text, strong: better, color: better ? HistoryRunStyle.ahead : null);
    Widget note(String text) =>
        Padding(padding: const EdgeInsets.only(left: ReviewTableStyle.noteGap), child: ReviewTable.cell(text));
    return ReviewTable(
      head: ['', s.ankirenColThis, s.shortDate(last.startedAt), ''],
      starts: const {3},
      rows: [
        ReviewRow([
          ReviewTable.cell(s.ankirenRowFirstTap, strong: true),
          good('${game.firstTaps}/${game.cards.length}', more > 0),
          ReviewTable.cell('${last.firstTaps}/${last.cards.length}'),
          note(more > 0
              ? s.ankirenMoreFirst(more)
              : more < 0
                  ? s.ankirenFewerFirst(-more)
                  : s.ankirenSame),
        ]),
        ReviewRow([
          ReviewTable.cell(s.ankirenRowMedian, strong: true),
          good(time(now), (faster ?? 0) > 0),
          ReviewTable.cell(time(then)),
          note(switch (faster) {
            null => missingTime,
            final d when formatSeconds(d.abs()) == formatSeconds(0) => s.ankirenSame,
            final d when d > 0 => s.ankirenFaster(formatSeconds(d)),
            final d => s.ankirenSlower(formatSeconds(-d)),
          }),
        ]),
        ReviewRow([
          ReviewTable.cell(s.ankirenRowMemorised, strong: true),
          ReviewTable.cell(formatMinutes(game.memorised)),
          ReviewTable.cell(formatMinutes(last.memorised)),
          note(s.ankirenMemoOf(formatMinutes(game.memorise), formatMinutes(last.memorise))),
        ]),
      ],
    );
  }
}
