import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/rating.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/srs_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/scope.dart';
import '../history/history_widgets.dart';
import '../history/run_page.dart';
import '../history/run_xp_tab.dart';
import '../manga/manga.dart';
import '../results/celebrations.dart';
import '../results/rank_up_overlay.dart';
import '../stats/stats_page.dart';
import 'rank_badges.dart';
import 'ranked_runs.dart';

/// The rank page: the rating over the ranked runs, the class ladder (spec
/// phone 9) and the latest ranked runs. The ladder's nine class rungs are
/// coloured from white 入門 up through pink, yellow, green, sea and violet
/// to a solid-ink A級, with the player's own rung tagged YOU, the next
/// threshold tagged NEXT (with a rank-up preview alongside it), every class
/// already passed stamped CLEAR and every one still ahead locked. Before
/// the first ranked run there is no YOU rung and no history.
class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final rating = progress.placed ? progress.currentRating : null;
    final band = rating == null ? null : Rating.bandOf(rating);
    final next = rating == null ? null : Rating.nextBand(rating);
    final bandIndex = band == null ? -1 : Rating.bands.indexOf(band);
    final history = progress.rankedHistory;
    return StatsPage(
      title: s.rank,
      sub: s.other.rank,
      trailing: rating == null ? null : _RatingReadout(rating),
      body: StatsPageList(children: [
        if (rating == null) ...[
          NarrationBox(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(s.rankedUnplacedLine,
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: RankLockLayout.noteFont)),
            ),
          ),
          const SizedBox(height: HistoryRunStyle.sectionGap),
        ],
        if (history.length > 1)
          HistorySection(
            title: s.rankRatingTitle,
            sub: s.sub?.rankRatingTitle,
            note: s.runSoFar(history.length),
            child: RunPanel(gap: false, children: [RatingChart([for (final (_, r) in history) r.after])]),
          ),
        HistorySection(
          title: s.rankClassesTitle,
          sub: s.sub?.rankClassesTitle,
          child: Column(children: [
            for (final (i, rungBand) in Rating.bands.reversed.indexed) ...[
              if (i > 0) const SizedBox(height: RankLayout.rungGap),
              _Rung(
                band: rungBand,
                currentBand: band,
                rating: rating,
                nextThreshold: next?.minRating,
                isYou: rungBand == band,
                isNext: next != null && rungBand == next,
                isCleared: band != null && Rating.bands.indexOf(rungBand) < bandIndex,
                isLocked: band != null && Rating.bands.indexOf(rungBand) > bandIndex,
                isTop: rungBand.id == 'A',
              ),
            ],
          ]),
        ),
        if (history.isNotEmpty)
          HistorySection(
            title: s.runRankedTitle,
            sub: s.sub?.runRankedTitle,
            child: RunPanel(gap: false, children: [RankedRunsTable(history, onOpen: (run) => openRun(context, run))]),
          ),
      ]),
    );
  }
}

/// The rating, beside the title.
class _RatingReadout extends StatelessWidget {
  const _RatingReadout(this.rating);
  final double rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          s.ratingLabel,
          style: const TextStyle(
            fontWeight: Weights.black,
            fontSize: RankLayout.ratingLabelFont,
            letterSpacing: RankLayout.ratingLabelTracking * RankLayout.ratingLabelFont,
          ),
        ),
        Text(
          rating.round().toString(),
          style: const TextStyle(
              fontFamily: Fonts.display, fontSize: RankLayout.ratingFont, height: TypeScale.displayLineHeight),
        ),
      ],
    );
  }
}

class _Rung extends StatelessWidget {
  const _Rung({
    required this.band,
    required this.currentBand,
    required this.rating,
    required this.nextThreshold,
    required this.isYou,
    required this.isNext,
    required this.isCleared,
    required this.isLocked,
    required this.isTop,
  });

  final RankBand band;

  /// Null, as is [rating], while the player has no rank.
  final RankBand? currentBand;
  final double? rating;
  final double? nextThreshold;
  final bool isYou, isNext, isCleared, isLocked, isTop;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final style = rungStyle(band.id);
    final markers = <Widget>[
      if (isTop) _TopClassNote(s.topClassNote),
      if (isNext)
        Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          _NextTag(label: s.nextChip, threshold: nextThreshold!.round()),
          const SizedBox(width: RankLayout.previewGap),
          _PreviewButton(
            label: s.previewRankUp,
            onTap: () => _openRankUpPreview(context, before: currentBand!, after: band, ratingBefore: rating!),
          ),
        ]),
      if (isYou)
        Row(mainAxisSize: MainAxisSize.min, children: [
          _YouTag(label: s.youTag, rating: rating!.round()),
          if (nextThreshold != null) ...[
            const SizedBox(width: RankLayout.balloonGap),
            SizedBox.fromSize(
              size: RankLayout.balloonSize,
              child: SpeechBalloon(
                speaker: RankLayout.balloonSpeaker,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: NumberedText(
                    s.toGoTemplate,
                    [(nextThreshold! - rating!).ceil()],
                    style: const TextStyle(fontSize: RankLayout.balloonFont),
                    numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: RankLayout.balloonFont + 2),
                  ),
                ),
              ),
            ),
          ],
        ]),
    ];

    return SizedBox(
      height: RankLayout.rungHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: MangaPanel(
              color: style.color,
              tone: style.tone,
              padding: RankLayout.rungPadding + EdgeInsets.only(right: isYou ? RankLayout.tobiRoom : 0),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: style.text),
                child: Row(
                  children: [
                    ClassBadge(band, color: isTop ? Palette.sun : Palette.paper),
                    if (isLocked) ...[
                      const SizedBox(width: RankLayout.lockGap),
                      MangaIcon(IconArt.lock, size: RankLayout.lockIcon, color: style.text),
                    ],
                    const SizedBox(width: RankLayout.markerGap),
                    if (markers.isNotEmpty)
                      // `FittedBox` guards the rare case of two markers
                      // stacking on one rung (A級 that is also the player's
                      // own class): squeezed to fit rather than overflowing.
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final (i, m) in markers.indexed) ...[
                                if (i > 0) const SizedBox(height: Gaps.tight),
                                m,
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isCleared)
            Positioned(
              right: RankLayout.stampRight,
              top: 0,
              bottom: 0,
              child: Center(child: ClearStamp(s.clearStamp)),
            ),
          if (isYou) const Placed(RankLayout.tobiPlacement, child: Tobi(pose: TobiPose.fired)),
        ],
      ),
    );
  }
}

void _openRankUpPreview(
  BuildContext context, {
  required RankBand before,
  required RankBand after,
  required double ratingBefore,
}) {
  Navigator.push(
    context,
    MangaRoute<void>(
      builder: (context) => Scaffold(
        body: RankUpOverlay(
          data: RankUpCelebration(before, after, ratingBefore, after.minRating),
          onNext: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}

/// The permanent "TOP CLASS" caption on A級, regardless of the player's own
/// position (spec's `.rung-note`).
class _TopClassNote extends StatelessWidget {
  const _TopClassNote(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontWeight: Weights.black,
          fontSize: RankLayout.topNoteFont,
          letterSpacing: RankLayout.topNoteTracking * RankLayout.topNoteFont,
          color: Palette.sun,
        ),
      );
}

/// The next class's threshold rating (spec's `.next-tag`).
class _NextTag extends StatelessWidget {
  const _NextTag({required this.label, required this.threshold});
  final String label;
  final int threshold;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
        child: Padding(
          padding: RankLayout.tagPadding,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: RankLayout.tagLabelFont,
                    letterSpacing: RankLayout.tagLabelTracking * RankLayout.tagLabelFont,
                    color: Palette.ink)),
            const SizedBox(width: Gaps.tight),
            Text('$threshold', style: const TextStyle(fontFamily: Fonts.display, fontSize: RankLayout.tagNumberFont, color: Palette.ink)),
          ]),
        ),
      );
}

/// The player's own class and rounded rating (spec's `.you`).
class _YouTag extends StatelessWidget {
  const _YouTag({required this.label, required this.rating});
  final String label;
  final int rating;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
        child: Padding(
          padding: RankLayout.tagPadding,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: RankLayout.tagLabelFont,
                    letterSpacing: RankLayout.tagLabelTracking * RankLayout.tagLabelFont,
                    color: Palette.ink)),
            Text('$rating', style: const TextStyle(fontFamily: Fonts.display, fontSize: RankLayout.tagNumberFont, color: Palette.ink)),
          ]),
        ),
      );
}

/// The rank-up preview entry point, next to the NEXT tag.
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
            child: Padding(
              padding: RankLayout.previewPadding,
              child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: RankLayout.previewFont)),
            ),
          ),
        ),
      );
}
