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
import '../results/celebration_overlays.dart';
import '../results/celebrations.dart';

/// The rank ladder (spec phone 9): nine class rungs, coloured from white
/// 入門 up through pink, yellow, green, sea and violet to a solid-ink A級,
/// with the player's own rung tagged YOU, the next threshold tagged NEXT
/// (with a rank-up preview alongside it), and every class already passed
/// stamped CLEAR.
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
                child: ListView.separated(
                  itemCount: ladder.length,
                  separatorBuilder: (_, _) => const SizedBox(height: RankLayout.rungGap),
                  itemBuilder: (context, i) {
                    final rungBand = ladder[i];
                    return _Rung(
                      band: rungBand,
                      currentBand: band,
                      rating: rating,
                      nextThreshold: next?.minRating,
                      isYou: rungBand == band,
                      isNext: next != null && rungBand == next,
                      isCleared: Rating.bands.indexOf(rungBand) < bandIndex,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: RankLayout.topBarHeight,
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

/// Fill, texture and text colour for one rung, a step of the ladder's colour
/// progression: flat white for 入門/F下級, then pink, yellow, green, a
/// lighter and then a bolder sea, a bold violet and finally solid ink.
({Color color, ToneSpec? tone, Color text}) _rungStyle(String bandId) => switch (bandId) {
      'F+' => (color: Palette.pink, tone: Tones.pink, text: Palette.ink),
      'E-' => (color: Palette.sun, tone: null, text: Palette.ink),
      'E+' => (color: Palette.land, tone: null, text: Palette.ink),
      'D' => (color: Palette.seaSoft, tone: Tones.sea, text: Palette.ink),
      'C' => (color: Palette.sea, tone: Tones.seaDeep, text: Palette.ink),
      'B' => (color: Palette.violet, tone: null, text: Palette.paper),
      'A' => (color: Palette.ink, tone: null, text: Palette.paper),
      _ => (color: Palette.paper, tone: null, text: Palette.ink), // 入門, F下級
    };

class _Rung extends StatelessWidget {
  const _Rung({
    required this.band,
    required this.currentBand,
    required this.rating,
    required this.nextThreshold,
    required this.isYou,
    required this.isNext,
    required this.isCleared,
    required this.isTop,
  });

  final RankBand band;
  final RankBand currentBand;
  final double rating;
  final double? nextThreshold;
  final bool isYou, isNext, isCleared, isTop;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final style = _rungStyle(band.id);
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
                    _ClassBadge(band, accent: isTop),
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
              child: Center(child: _ClearStamp(s.clearStamp)),
            ),
          if (isYou) ...[
            const Placed(RankLayout.tobiPlacement, child: Tobi(pose: TobiPose.fired)),
            if (nextThreshold != null)
              Placed(
                RankLayout.balloonPlacement,
                child: SpeechBalloon(
                  tail: RankLayout.balloonTail,
                  tailTurn: RankLayout.balloonTailTurn,
                  padding: RankLayout.balloonPadding,
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

/// A rotated, pink-outlined stamp on every class already passed (spec's
/// `.stamp`).
class _ClearStamp extends StatelessWidget {
  const _ClearStamp(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: RankLayout.stampTurn * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper.withValues(alpha: 0.85),
            border: Border.all(color: Palette.pinkDeep, width: Strokes.button),
            borderRadius: BorderRadius.circular(RankLayout.stampRadius),
          ),
          child: Padding(
            padding: RankLayout.stampPadding,
            child: Text(label,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: RankLayout.stampFont, color: Palette.pinkDeep)),
          ),
        ),
      );
}

/// The rung's own class badge: white, or sun-coloured on A級 (spec's `.rn`,
/// skew art aside — see [Sticker]).
class _ClassBadge extends StatelessWidget {
  const _ClassBadge(this.band, {required this.accent});
  final RankBand band;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    const suffix = '級';
    final main = band.label.endsWith(suffix) ? band.label.substring(0, band.label.length - 1) : band.label;
    return Sticker(
      tilt: 0,
      color: accent ? Palette.sun : Palette.paper,
      padding: RankLayout.badgePadding,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: main, style: const TextStyle(fontSize: RankLayout.badgeFont)),
          if (main != band.label) const TextSpan(text: suffix, style: TextStyle(fontSize: RankLayout.badgeSuffixFont)),
        ]),
        style: const TextStyle(fontFamily: Fonts.display, height: 1, color: Palette.ink),
      ),
    );
  }
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
