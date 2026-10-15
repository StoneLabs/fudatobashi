import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ankiren_review.dart';
import '../../l10n/ankiren_review_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../play/time_format.dart';
import 'ankiren_widgets.dart';
import 'history_widgets.dart';

/// A 暗記練 game's Overview: its headline (D30, or D41 for a custom game),
/// where its first taps landed (D31), then the memorise time (D32) or, for
/// a custom game, the last game with the same setup (D42).
class AnkirenOverviewTab extends StatelessWidget {
  const AnkirenOverviewTab(this.review, {super.key});
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final game = review.game;
    return RunTabList(children: [
      if (game.scored) _ScoredHeadline(review) else _CustomHeadline(review),
      const SizedBox(height: HistoryRunStyle.sectionGap),
      _FirstTapMix(review),
      if (game.scored) _MemoriseTime(review) else _SameSetup(review),
    ]);
  }
}

/// D30: the points, a best's stamp, and the game's facts.
class _ScoredHeadline extends StatelessWidget {
  const _ScoredHeadline(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final level = game.level!;
    final before = review.ratingBefore, after = game.rating;
    final best = review.bestBefore;
    final xp = review.xp?.award.total ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AnkirenHeadline(
        label: s.ankirenPointsLabel,
        big: '${game.score}',
        of: s.ankirenOfMax(game.maxScore ?? 0),
        stamp: review.isBest ? AnkirenStamp(s.ankirenBestStamp(level), s.other.ankirenBestStamp(level)) : null,
        facts: [
          Fact('${game.firstTaps}/${game.cards.length}', s.ankirenFirstTapFact),
          Fact(formatMinutes(game.memorised), s.ankirenMemorisedFact),
          if (before != null && after != null) Fact(ratingChangeText(after - before), s.runRatingFact),
          if (xp > 0) Fact('+$xp', s.runXpFact),
        ],
      ),
      UnderLine([
        if (review.isBest && best != null) s.ankirenUpFrom(best.score!),
        if (after != null) s.ankirenClassLine(AnkirenReview.classProgress(after).band.label),
      ]),
    ]);
  }
}

/// D41: a custom game's first-tap finds, found cards, memorise time and
/// median find, stamped as not scored.
class _CustomHeadline extends StatelessWidget {
  const _CustomHeadline(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final median = game.medianFindMs;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AnkirenHeadline(
        label: s.ankirenRightFirstLabel,
        big: '${game.firstTaps}',
        of: s.ankirenOfMax(game.cards.length),
        fill: AnkirenReviewStyle.customFill,
        stamp: AnkirenStamp(s.ankirenNotScored, s.other.ankirenNotScored, color: AnkirenReviewStyle.muted),
        facts: [
          Fact('${game.found}/${game.cards.length}', s.ankirenFoundFact),
          Fact(formatMinutes(game.memorised), s.ankirenMemorisedOf(formatMinutes(game.memorise))),
          Fact(median == null ? missingTime : '${formatSeconds(median)}s', s.ankirenMedianFact),
        ],
      ),
      UnderLine([s.ankirenCustomUnscored]),
    ]);
  }
}

/// D31: this game's first taps by tier, over the earlier games' with the
/// same setup (a custom game's last one).
class _FirstTapMix extends StatelessWidget {
  const _FirstTapMix(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final last = review.last;
    return HistorySection(
      title: s.ankirenMixTitle,
      sub: s.other.ankirenMixTitle,
      child: ReviewPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TierMixBar(label: s.ankirenThisGame, sub: s.ankirenCardsCount(game.cards.length), mix: game.mix),
          if (game.level case final level? when review.peers.isNotEmpty)
            TierMixBar(
                label: s.ankirenUsual, sub: s.ankirenGamesAtLevel(review.peers.length, level), mix: review.usualMix)
          else if (last != null)
            TierMixBar(label: s.shortDate(last.startedAt), sub: s.ankirenSameSetup, mix: last.mix),
          const TierLegend(),
        ]),
      ),
    );
  }
}

/// D32: the memorise time used out of the time allowed, the earlier games'
/// as ticks, and what being ready early paid.
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
    const small = TextStyle(fontWeight: Weights.bold, fontSize: HistoryRunStyle.noteFont);
    final used = [
      s.ankirenMemoUsed(formatMinutes(game.memorised)),
      if (early > Duration.zero) s.ankirenMemoEarly(early.inSeconds),
    ].join(' · ');
    return HistorySection(
      title: s.ankirenMemoTitle,
      sub: s.other.ankirenMemoTitle,
      note: s.ankirenMemoAllowed(formatMinutes(allowed)),
      child: ReviewPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ShareBar(share(game.memorised), ticks: [for (final g in review.peers) share(g.memorised)]),
          const SizedBox(height: Gaps.tight),
          Row(children: [
            Text(formatMinutes(Duration.zero), style: small),
            Expanded(
              child: Text(used,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.noteFont)),
            ),
            Text(formatMinutes(allowed), style: small),
          ]),
          if (game.earlyFactor > 1) HistoryCaption(s.ankirenMemoPays(game.earlyFactor.toStringAsFixed(2))),
          if (review.peers.isNotEmpty)
            HistoryCaption(s.ankirenMemoTicks([for (final g in review.peers) formatMinutes(g.memorised)].join(', '))),
        ]),
      ),
    );
  }
}

/// D42: a custom game against the last one with the same setup.
class _SameSetup extends StatelessWidget {
  const _SameSetup(this.review);
  final AnkirenReview review;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final game = review.game;
    final last = review.last;
    return HistorySection(
      title: s.ankirenSetupTitle,
      sub: s.other.ankirenSetupTitle,
      note: s.ankirenSetupNote(game.perSide),
      child: last == null
          ? ReviewPanel(child: ReviewTable.cell(s.ankirenSetupFirst))
          : ReviewPanel(child: _sameSetupTable(s, game, last)),
    );
  }

  static Widget _sameSetupTable(S s, AnkirenGameRecord game, AnkirenGameRecord last) {
    final more = game.firstTaps - last.firstTaps;
    final now = game.medianFindMs, then = last.medianFindMs;
    final faster = now == null || then == null ? null : then - now;
    String time(double? ms) => ms == null ? missingTime : '${formatSeconds(ms)}s';
    Widget good(String text, bool better) =>
        ReviewTable.cell(text, color: better ? HistoryRunStyle.ahead : null);
    return ReviewTable(
      head: ['', s.ankirenColThis, s.shortDate(last.startedAt), ''],
      widths: const {3: FlexColumnWidth()},
      rows: [
        ReviewRow([
          ReviewTable.cell(s.ankirenRowFirstTap, strong: true),
          good('${game.firstTaps}/${game.cards.length}', more > 0),
          ReviewTable.cell('${last.firstTaps}/${last.cards.length}'),
          ReviewTable.cell(more > 0
              ? s.ankirenMoreFirst(more)
              : more < 0
                  ? s.ankirenFewerFirst(-more)
                  : s.ankirenSameFirst),
        ]),
        ReviewRow([
          ReviewTable.cell(s.ankirenRowMedian, strong: true),
          good(time(now), (faster ?? 0) > 0),
          ReviewTable.cell(time(then)),
          ReviewTable.cell(switch (faster) {
            null => missingTime,
            final d when d >= 0 => s.ankirenFaster(formatSeconds(d)),
            final d => s.ankirenSlower(formatSeconds(-d)),
          }),
        ]),
        ReviewRow([
          ReviewTable.cell(s.ankirenRowMemorised, strong: true),
          ReviewTable.cell(formatMinutes(game.memorised)),
          ReviewTable.cell(formatMinutes(last.memorised)),
          ReviewTable.cell(s.ankirenMemoOf(formatMinutes(game.memorise), formatMinutes(last.memorise))),
        ]),
      ],
    );
  }
}
