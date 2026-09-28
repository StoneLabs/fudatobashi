import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/rating.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../rank/rank_badges.dart';
import 'celebration_chrome.dart';
import 'celebrations.dart';

/// "Rank up" (昇級!!, spec phone 9's spread): two pages slide together
/// across the gutter. The old class is struck off and stamped CLEAR on the
/// left page, the new one slams down on the right with a jolt, Tobi cheers,
/// the rating counts up, and the next class's 100-card time shows how far
/// is left to go.
class RankUpOverlay extends StatelessWidget {
  const RankUpOverlay({super.key, required this.data, required this.onNext});
  final RankUpCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EntranceStage(
      length: RankUpMotion.length,
      child: CelebrationChrome(
        color: Palette.paper,
        onNext: onNext,
        backdrop: [
          const _Spread(),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: OutlinedText(
                  RankUpLayout.title,
                  style: TextStyle(fontFamily: Fonts.display, fontSize: RankUpLayout.titleFont, color: Palette.paper, height: 1),
                  outline: Palette.ink,
                  outlineWidth: RankUpLayout.titleOutline,
                ),
              ),
            ),
            const SizedBox(height: RankUpLayout.bandGap),
            Entrance(
              RankUpMotion.band,
              child: CelebrationBand(s.rankUpBand,
                  inset: RankUpLayout.bandInset,
                  fontSize: RankUpLayout.bandFont,
                  tracking: RankUpLayout.bandTracking,
                  padding: RankUpLayout.bandPadding,
                  turnDeg: RankUpLayout.bandTurnDeg),
            ),
            Expanded(
              child: Row(children: [
                Expanded(child: Entrance(RankUpMotion.before, child: _OldClass(data.before))),
                Expanded(child: _NewClass(data.after)),
              ]),
            ),
            Center(child: Entrance(RankUpMotion.rate, child: _RatingCount(before: data.ratingBefore, after: data.ratingAfter))),
            const SizedBox(height: RankUpLayout.sectionGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Entrance(RankUpMotion.next, child: _NextClass(rating: data.ratingAfter)),
                const SizedBox(height: RankUpLayout.sectionGap),
                Entrance(
                  RankUpMotion.actions,
                  child: CelebrationCta(
                    label: s.onward,
                    sub: s.other.onward,
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

/// The two pages and the gutter between them: sea tone and speed lines on
/// the left, sun glow and boiling focus lines on the right, sliding in from
/// either side.
class _Spread extends StatelessWidget {
  const _Spread();

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Row(children: [
          Expanded(
            child: _SlideIn(
              from: -1,
              child: const StaticArt([FillLayer(Palette.seaSoft), ToneLayer(Tones.sea), SpeedLinesLayer(RankUpLayout.leftSpeed)]),
            ),
          ),
          Expanded(
            child: _SlideIn(
              from: 1,
              child: ClipRect(
                child: Stack(fit: StackFit.expand, children: [
                  const StaticArt([
                    RadialLayer(
                        center: RankUpLayout.rightGlowAt, colors: RankUpLayout.rightGlowColors, stops: RankUpLayout.rightGlowStops),
                    ToneLayer(Tones.pink, fadeAngle: RankUpLayout.rightToneAngle, fadeStops: RankUpLayout.rightToneStops),
                  ]),
                  BoilingLines(RankUpLayout.rightFocus, frames: NewCardMotion.linesFrames, step: NewCardMotion.linesStep),
                ]),
              ),
            ),
          ),
        ]),
        const Center(
          child: SizedBox(
            width: RankUpLayout.gutterWidth,
            height: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: RankUpLayout.gutterColors, stops: RankUpLayout.gutterStops),
              ),
            ),
          ),
        ),
      ]);
}

/// A page sliding in by its own width from the side [from] (-1 left, 1
/// right).
class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.from, required this.child});
  final double from;
  final Widget child;

  @override
  Widget build(BuildContext context) => EntranceBuilder(
        RankUpMotion.pages,
        child: child,
        builder: (context, t, child) => FractionalTranslation(translation: Offset(from * (1 - t), 0), child: child),
      );
}

/// BEFORE / NOW over a page's class.
class _PageLabel extends StatelessWidget {
  const _PageLabel(this.text, {required this.dark});
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: dark ? Palette.ink : Palette.paper,
        child: Padding(
          padding: RankUpLayout.pageLabelPadding,
          child: Text(text,
              style: TextStyle(
                  fontWeight: Weights.black,
                  fontSize: RankUpLayout.pageLabelFont,
                  letterSpacing: RankUpLayout.pageLabelTracking * RankUpLayout.pageLabelFont,
                  color: dark ? Palette.paper : Palette.ink)),
        ),
      );
}

/// The class left behind: struck off with a pink bar, then stamped CLEAR
/// like a passed rung on the ladder.
class _OldClass extends StatelessWidget {
  const _OldClass(this.band);
  final RankBand band;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.only(right: RankUpLayout.clearOffset.dx, bottom: RankUpLayout.clearOffset.dy),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _PageLabel(s.beforeBandLabel, dark: false),
            const SizedBox(height: RankUpLayout.pageLabelGap),
            Stack(clipBehavior: Clip.none, children: [
              ClassBadge(band,
                  textColor: Palette.mute,
                  fontSize: RankUpLayout.oldFont,
                  suffixSize: RankUpLayout.oldSuffixFont,
                  padding: RankUpLayout.oldPadding),
              const Positioned(
                left: -RankUpLayout.strikeOverhangLeft,
                right: -RankUpLayout.strikeOverhangRight,
                top: 0,
                bottom: 0,
                child: Center(child: _Strike()),
              ),
              Positioned(
                right: -RankUpLayout.clearOffset.dx,
                bottom: -RankUpLayout.clearOffset.dy,
                child: Entrance(RankUpMotion.clear, child: ClearStamp(s.clearStamp)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// The pink bar striking the old class off, drawn from the left.
class _Strike extends StatelessWidget {
  const _Strike();

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: RankUpLayout.strikeTurnDeg * math.pi / 180,
        child: EntranceBuilder(
          RankUpMotion.strike,
          builder: (context, t, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: t.clamp(0.0, 1.0),
            child: SizedBox(
              height: RankUpLayout.strikeHeight,
              child: Visibility(
                visible: t > 0,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.pink,
                    border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: RankUpLayout.strikeBorder)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// The class reached: stamped down in its rung colour with a burst of
/// focus lines, ドドン!!, and Tobi hopping for joy.
class _NewClass extends StatelessWidget {
  const _NewClass(this.band);
  final RankBand band;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final style = rungStyle(band.id);
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
          Entrance(RankUpMotion.now, child: _PageLabel(s.nowBandLabel, dark: true)),
          const SizedBox(height: RankUpLayout.pageLabelGap),
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
                child: ClassBadge(band,
                    color: style.color,
                    textColor: style.text,
                    fontSize: RankUpLayout.newFont,
                    suffixSize: RankUpLayout.newSuffixFont,
                    padding: RankUpLayout.newPadding,
                    border: RankUpLayout.newBorder),
              ),
            ),
          ]),
          const SizedBox(height: RankUpLayout.tobiGap),
          SizedBox.fromSize(
            size: RankUpLayout.tobi,
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

/// "1638 → 1651 +13": the new rating counts up from the old one, then the
/// gain pops out. The box keeps the final width while counting.
class _RatingCount extends StatelessWidget {
  const _RatingCount({required this.before, required this.after});
  final double? before;
  final double after;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final from = before ?? Rating.bandOf(after).minRating;
    const style = TextStyle(fontFamily: Fonts.display, fontSize: RankUpLayout.rateFont, height: 1.1);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Palette.paper,
        border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: RankUpLayout.rateBorder)),
      ),
      child: Padding(
        padding: RankUpLayout.ratePadding,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${before?.round() ?? s.newBadge} → ', style: style),
          Stack(alignment: Alignment.centerRight, children: [
            Opacity(opacity: 0, child: Text('${after.round()}', style: style)),
            EntranceBuilder(
              RankUpMotion.count,
              builder: (context, t, _) => Text('${lerpDouble(from, after, t)!.round()}', style: style),
            ),
          ]),
          if (before != null) ...[
            const SizedBox(width: RankUpLayout.rateGap),
            Entrance(
              RankUpMotion.gain,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Palette.pink,
                  border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: RankUpLayout.gainBorder)),
                ),
                child: Padding(
                  padding: RankUpLayout.gainPadding,
                  child: Text('+${(after - before!).round()}',
                      style: const TextStyle(fontWeight: Weights.black, fontSize: RankUpLayout.gainFont)),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// What's next: the next class, the 100-card time it asks for, and a bar
/// filling up to how far the player already is toward it (or the top of the
/// ladder).
class _NextClass extends StatelessWidget {
  const _NextClass({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final band = Rating.bandOf(rating);
    final next = Rating.nextBand(rating);
    final floor = band.minRating.isFinite ? band.minRating : 0.0;
    final shown = next ?? band;
    final style = rungStyle(shown.id);
    const bold = TextStyle(fontWeight: Weights.black);
    const number = TextStyle(fontFamily: Fonts.display, fontWeight: Weights.regular);
    return MangaPanel(
      shape: const PanelShape(topLeft: RankUpLayout.nextCut),
      padding: RankUpLayout.nextPadding,
      child: Row(children: [
        ClassBadge(shown,
            color: style.color,
            textColor: style.text,
            fontSize: RankUpLayout.nextBadgeFont,
            suffixSize: RankUpLayout.nextBadgeSuffixFont),
        const SizedBox(width: RankUpLayout.nextGap),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (next == null) ...[
              Text(s.topClassReached, style: const TextStyle(fontFamily: Fonts.display, fontSize: RankUpLayout.nextTargetFont)),
              Text(s.topClassChase, style: const TextStyle(fontWeight: Weights.bold, fontSize: RankUpLayout.nextNoteFont)),
            ] else ...[
              InkTag(s.nextClassBand, fontSize: RankUpLayout.nextTagFont),
              const SizedBox(height: Gaps.tight),
              NumberedText(
                s.nextClassTarget,
                [_seconds(next.maxSeconds!)],
                style: bold.copyWith(fontSize: RankUpLayout.nextTargetFont),
                numberStyle: number,
              ),
              const SizedBox(height: RankUpLayout.barGap),
              EntranceBuilder(
                RankUpMotion.fill,
                builder: (context, t, _) => _Bar((rating - floor) / (next.minRating - floor) * t),
              ),
              const SizedBox(height: RankUpLayout.barGap),
              NumberedText(
                s.nextClassPace,
                [Rating.toSeconds(rating).toStringAsFixed(1), (next.minRating - rating).ceil()],
                style: bold.copyWith(fontSize: RankUpLayout.nextNoteFont, fontWeight: Weights.bold),
                numberStyle: number,
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  /// Whole seconds as they are, anything finer to a tenth.
  static String _seconds(double s) => s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);
}

/// A full-width bar filled [fraction] of the way in pink.
class _Bar extends StatelessWidget {
  const _Bar(this.fraction);
  final double fraction;

  @override
  Widget build(BuildContext context) => Container(
        height: RankUpLayout.barHeight,
        decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.label)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          heightFactor: 1,
          child: const ColoredBox(color: Palette.pink),
        ),
      );
}
