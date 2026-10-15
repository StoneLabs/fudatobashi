import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../rank/rank_badges.dart';
import 'celebration_chrome.dart';
import 'celebrations.dart';
import 'rank_up_overlay.dart';

/// "Rank decided" (ランク決定!!) after the first ranked run, in the rank-up
/// page's timing: the first class slams down in its rung colour with a
/// burst of focus lines and a jolt, Tobi cheers, the rating counts up, and
/// the next class shows how far is left to go.
class PlacementOverlay extends StatelessWidget {
  const PlacementOverlay({super.key, required this.data, required this.onNext});
  final PlacementCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EntranceStage(
      length: RankUpMotion.length,
      child: CelebrationChrome(
        color: Palette.paper,
        onNext: onNext,
        art: const [
          RadialLayer(center: PlacementLayout.glowAt, colors: PlacementLayout.glowColors, stops: PlacementLayout.glowStops),
          ToneLayer(Tones.pink, fadeAngle: PlacementLayout.toneAngle, fadeStops: PlacementLayout.toneStops),
        ],
        backdrop: [
          BoilingLines(PlacementLayout.focus, frames: NewCardMotion.linesFrames, step: NewCardMotion.linesStep),
          EntranceBuilder(
            RankUpMotion.burst,
            builder: (context, t, _) => t > 0 ? const ConfettiRain() : const SizedBox.shrink(),
          ),
        ],
        child: Jolt(
          RankUpMotion.jolt,
          reach: RankUpMotion.joltReach,
          steps: RankUpMotion.joltSteps,
          seed: RankUpMotion.joltSeed,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: RankUpLayout.topGap),
            const Entrance(
              RankUpMotion.title,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Gaps.gutter),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: OutlinedText(
                    PlacementLayout.title,
                    style:
                        TextStyle(fontFamily: Fonts.display, fontSize: PlacementLayout.titleFont, color: Palette.paper, height: 1),
                    outline: Palette.ink,
                    outlineWidth: PlacementLayout.titleOutline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: RankUpLayout.bandGap),
            Entrance(
              RankUpMotion.band,
              child: CelebrationBand(s.placementBand,
                  inset: RankUpLayout.bandInset,
                  fontSize: RankUpLayout.bandFont,
                  tracking: RankUpLayout.bandTracking,
                  padding: RankUpLayout.bandPadding,
                  turnDeg: RankUpLayout.bandTurnDeg),
            ),
            Expanded(child: _Stamp(data)),
            Center(child: Entrance(RankUpMotion.rate, child: _RatingCount(data.rating))),
            const SizedBox(height: RankUpLayout.sectionGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Entrance(RankUpMotion.next, child: NextClassPanel(rating: data.rating)),
                const SizedBox(height: RankUpLayout.sectionGap),
                Entrance(
                  RankUpMotion.actions,
                  child: CelebrationCta(
                    label: s.ratingCta,
                    sub: s.sub?.ratingCta,
                    onTap: onNext,
                    height: RankUpLayout.actionHeight,
                    fontSize: RankUpLayout.ctaFont,
                    subFontSize: RankUpLayout.ctaSubFont,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: Gaps.section),
          ]),
        ),
      ),
    );
  }
}

/// The first class stamped down in its rung colour with focus lines
/// bursting out from behind it, ドドン!!, and Tobi hopping for joy.
class _Stamp extends StatelessWidget {
  const _Stamp(this.data);
  final PlacementCelebration data;

  @override
  Widget build(BuildContext context) {
    final style = rungStyle(data.band.id);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Entrance(
            RankUpMotion.sfx,
            child: Transform.rotate(
              angle: RankUpLayout.sfxTurnDeg * math.pi / 180,
              child: const SfxText(RankUpLayout.sfx,
                  size: RankUpLayout.sfxFont, seed: RankUpLayout.sfxSeed, outline: NewCardLayout.sfxOutline),
            ),
          ),
          Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            const Positioned.fill(
              child: ImpactBurst(
                RankUpMotion.burst,
                burst: RankUpLayout.impactBurst,
                size: RankUpLayout.impactSize,
                fromScale: RankUpLayout.impactFromScale,
                toScale: RankUpLayout.impactToScale,
              ),
            ),
            Entrance(
              RankUpMotion.stamp,
              child: Transform.rotate(
                angle: RankUpLayout.newTurnDeg * math.pi / 180,
                child: ClassBadge(data.band,
                    color: style.color,
                    textColor: style.text,
                    fontSize: PlacementLayout.classFont,
                    suffixSize: PlacementLayout.classSuffixFont,
                    padding: RankUpLayout.newPadding,
                    border: RankUpLayout.newBorder),
              ),
            ),
          ]),
          const SizedBox(height: RankUpLayout.tobiGap),
          SizedBox.fromSize(
            size: PlacementLayout.tobi,
            child: const Entrance(
              RankUpMotion.tobi,
              child: Hop(
                height: RankUpMotion.hopHeight,
                period: RankUpMotion.hopPeriod,
                airShare: RankUpMotion.hopAirShare,
                child: Tobi(pose: TobiPose.cheering),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// "RATING 442", counting up from zero. The box keeps the final width while
/// counting.
class _RatingCount extends StatelessWidget {
  const _RatingCount(this.rating);
  final double rating;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontFamily: Fonts.display, fontSize: RankUpLayout.rateFont, height: 1.1);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Palette.paper,
        border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: RankUpLayout.rateBorder)),
      ),
      child: Padding(
        padding: RankUpLayout.ratePadding,
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(S.of(context).ratingLabel,
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: PlacementLayout.rateLabelFont,
                  letterSpacing: PlacementLayout.rateLabelTracking * PlacementLayout.rateLabelFont)),
          const SizedBox(width: RankUpLayout.rateGap),
          Stack(alignment: Alignment.centerRight, children: [
            Opacity(opacity: 0, child: Text('${rating.round()}', style: style)),
            EntranceBuilder(
              RankUpMotion.count,
              builder: (context, t, _) => Text('${lerpDouble(0, rating, t)!.round()}', style: style),
            ),
          ]),
        ]),
      ),
    );
  }
}
