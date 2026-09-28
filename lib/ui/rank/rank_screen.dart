import 'dart:math' as math;

import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/rating.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import 'rank_badges.dart';
import '../results/celebrations.dart';
import '../results/rank_up_overlay.dart';

/// The rank ladder (spec phone 9): nine class rungs, coloured from white
/// 入門 up through pink, yellow, green, sea and violet to a solid-ink A級,
/// with the player's own rung tagged YOU (and scrolled into view), the next
/// threshold tagged NEXT (with a rank-up preview alongside it), every class
/// already passed stamped CLEAR and every one still ahead locked.
class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final rating = progress.currentRating;
    final band = Rating.bandOf(rating);
    final next = Rating.nextBand(rating);
    final bandIndex = Rating.bands.indexOf(band);
    final ladder = [for (var i = Rating.bands.length - 1; i >= 0; i--) Rating.bands[i]];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              _TopBar(rating: rating),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: _Ladder(
                  length: ladder.length,
                  focus: ladder.indexOf(band),
                  rung: (i) {
                    final rungBand = ladder[i];
                    final rungIndex = Rating.bands.indexOf(rungBand);
                    return _Rung(
                      band: rungBand,
                      currentBand: band,
                      rating: rating,
                      nextThreshold: next?.minRating,
                      isYou: rungBand == band,
                      isNext: next != null && rungBand == next,
                      isCleared: rungIndex < bandIndex,
                      isLocked: rungIndex > bandIndex,
                      isTop: rungBand.id == 'A',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rungs in a scrolling list that opens with rung [focus] centred.
class _Ladder extends StatefulWidget {
  const _Ladder({required this.length, required this.focus, required this.rung});
  final int length;
  final int focus;
  final Widget Function(int index) rung;

  @override
  State<_Ladder> createState() => _LadderState();
}

class _LadderState extends State<_Ladder> {
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  /// Rungs have a fixed height, so the offset centring [focus] is known
  /// before the first layout.
  double _offsetCentring(double viewport) {
    const step = RankLayout.rungHeight + RankLayout.rungGap;
    final content = widget.length * step - RankLayout.rungGap;
    final centred = widget.focus * step - (viewport - RankLayout.rungHeight) / 2;
    return centred.clamp(0.0, math.max(0.0, content - viewport));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        _scroll ??= ScrollController(initialScrollOffset: _offsetCentring(box.maxHeight));
        return ListView.separated(
          controller: _scroll,
          itemCount: widget.length,
          separatorBuilder: (_, _) => const SizedBox(height: RankLayout.rungGap),
          itemBuilder: (context, i) => widget.rung(i),
        );
      });
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return IntrinsicHeight(
      child: Row(
        children: [
          InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: Gaps.section),
          Expanded(child: ScreenTitle(s.rank, sub: s.other.rank)),
          Column(
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
          ),
        ],
      ),
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
  final RankBand currentBand;
  final double rating;
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
            onTap: () => _openRankUpPreview(context, before: currentBand, after: band, ratingBefore: rating),
          ),
        ]),
      if (isYou) _YouTag(label: s.youTag, rating: rating.round()),
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
              padding: RankLayout.rungPadding,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: style.text),
                child: Row(
                  children: [
                    ClassBadge(band, color: isTop ? Palette.sun : Palette.paper),
                    if (isLocked) ...[
                      const SizedBox(width: RankLayout.lockGap),
                      MangaIcon(IconArt.lock, size: RankLayout.lockIcon, color: style.text),
                    ],
                    const Spacer(),
                    if (markers.isNotEmpty)
                      // `FittedBox` guards the rare case of two markers
                      // stacking on one rung (A級 that is also the player's
                      // own class): squeezed to fit rather than overflowing.
                      Flexible(
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
          if (isYou) ...[
            const Placed(RankLayout.tobiPlacement, child: Tobi(pose: TobiPose.fired)),
            if (nextThreshold != null)
              Placed(
                RankLayout.balloonPlacement,
                child: SpeechBalloon(
                  speaker: RankLayout.balloonSpeaker,
                  child: NumberedText(
                    s.toGoTemplate,
                    [(nextThreshold! - rating).ceil()],
                    style: const TextStyle(fontSize: RankLayout.balloonFont),
                    numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: RankLayout.balloonFont + 2),
                  ),
                ),
              ),
          ],
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
      builder: (context) => RankUpOverlay(
        data: RankUpCelebration(before, after, ratingBefore, after.minRating),
        onNext: () => Navigator.of(context).pop(),
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
