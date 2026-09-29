import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/xp.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'celebration_chrome.dart';

/// "Level up" (LEVEL UP!!), right after the XP page when it reached a new
/// level: the old level is struck off, the new number slams down with a
/// jolt and ドドーン!!, Tobi hops for joy, and a bar shows the way to the
/// next one.
class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({super.key, required this.gain, required this.onNext});
  final XpGain gain;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EntranceStage(
      length: LevelUpMotion.length,
      child: CelebrationChrome(
        color: LevelUpLayout.color,
        onNext: onNext,
        art: const [
          RadialLayer(center: LevelUpLayout.glowAt, colors: LevelUpLayout.glowColors, stops: LevelUpLayout.glowStops),
          ToneLayer(Tones.pink, fadeAngle: LevelUpLayout.toneAngle, fadeStops: LevelUpLayout.toneStops),
        ],
        backdrop: [
          const BoilingLines(LevelUpLayout.focus, frames: NewCardMotion.linesFrames, step: NewCardMotion.linesStep),
          EntranceBuilder(
            LevelUpMotion.burst,
            builder: (context, t, _) => t > 0 ? const ConfettiRain() : const SizedBox.shrink(),
          ),
        ],
        child: Jolt(
          LevelUpMotion.jolt,
          reach: LevelUpMotion.joltReach,
          steps: LevelUpMotion.joltSteps,
          seed: LevelUpMotion.joltSeed,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: LevelUpLayout.topGap),
            const Entrance(
              LevelUpMotion.title,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Gaps.gutter),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: OutlinedText(
                    LevelUpLayout.title,
                    style: TextStyle(fontFamily: Fonts.display, fontSize: LevelUpLayout.titleFont, color: Palette.paper, height: 1),
                    outline: Palette.ink,
                    outlineWidth: LevelUpLayout.titleOutline,
                  ),
                ),
              ),
            ),
            Entrance(
              LevelUpMotion.band,
              child: CelebrationBand(s.levelUpBand,
                  inset: LevelUpLayout.bandInset,
                  fontSize: LevelUpLayout.bandFont,
                  tracking: LevelUpLayout.bandTracking,
                  padding: LevelUpLayout.bandPadding,
                  turnDeg: LevelUpLayout.bandTurnDeg),
            ),
            Expanded(
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: _NewLevel(gain)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Entrance(LevelUpMotion.next, child: _NextLevel(gain.levelAfter)),
                const SizedBox(height: LevelUpLayout.sectionGap),
                Entrance(
                  LevelUpMotion.actions,
                  child: CelebrationCta(
                    label: s.onward,
                    sub: s.other.onward,
                    onTap: onNext,
                    height: LevelUpLayout.actionHeight,
                    fontSize: LevelUpLayout.ctaFont,
                    subFontSize: LevelUpLayout.ctaSubFont,
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

/// The old level struck off, and the new one stamped down under it.
class _NewLevel extends StatelessWidget {
  const _NewLevel(this.gain);
  final XpGain gain;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const number = TextStyle(fontFamily: Fonts.display, fontSize: LevelUpLayout.numberFont, color: Palette.sun, height: 1);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Entrance(LevelUpMotion.from, child: _OldLevel(s.levelShort(gain.levelBefore.level))),
      const SizedBox(height: LevelUpLayout.fromGap),
      Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        const Positioned.fill(
          child: ImpactBurst(
            LevelUpMotion.burst,
            burst: LevelUpLayout.impactBurst,
            size: LevelUpLayout.impactSize,
            fromScale: LevelUpLayout.impactFromScale,
            toScale: LevelUpLayout.impactToScale,
          ),
        ),
        Entrance(
          LevelUpMotion.stamp,
          child: Transform.rotate(
            angle: LevelUpLayout.stampTurnDeg * math.pi / 180,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const OutlinedText('LV',
                  style: TextStyle(fontFamily: Fonts.display, fontSize: LevelUpLayout.lvFont, color: Palette.paper, height: 1),
                  outline: Palette.ink,
                  outlineWidth: LevelUpLayout.lvOutline),
              OutlinedText('${gain.levelAfter.level}',
                  style: number, outline: Palette.ink, outlineWidth: LevelUpLayout.numberOutline),
            ]),
          ),
        ),
        Positioned(
          left: LevelUpLayout.sfxAt.dx,
          bottom: LevelUpLayout.sfxAt.dy,
          child: Entrance(
            LevelUpMotion.sfx,
            child: Transform.rotate(
              angle: LevelUpLayout.sfxTurnDeg * math.pi / 180,
              child: const SfxText(LevelUpLayout.sfx,
                  size: LevelUpLayout.sfxFont, seed: LevelUpLayout.sfxSeed, outline: NewCardLayout.sfxOutline),
            ),
          ),
        ),
        const Placed(
          LevelUpLayout.tobi,
          child: Entrance(
            LevelUpMotion.tobi,
            child: Hop(
              height: LevelUpMotion.hopHeight,
              period: LevelUpMotion.hopPeriod,
              airShare: LevelUpMotion.hopAirShare,
              child: Tobi(pose: TobiPose.cheering),
            ),
          ),
        ),
      ]),
      if (gain.levelsGained > 1) ...[
        const SizedBox(height: LevelUpLayout.levelsGap),
        Entrance(
          LevelUpMotion.levels,
          child: InkTag(s.levelsGained(gain.levelsGained),
              fontSize: LevelUpLayout.levelsFont, color: Palette.pink, textColor: Palette.ink),
        ),
      ],
    ]);
  }
}

/// "LV 7", struck off with a pink bar drawn from the left.
class _OldLevel extends StatelessWidget {
  const _OldLevel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper,
            border: Border.all(color: Palette.ink, width: LevelUpLayout.fromBorder),
          ),
          child: Padding(
            padding: LevelUpLayout.fromPadding,
            child: Text(text,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: LevelUpLayout.fromFont, color: Palette.mute)),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Transform.rotate(
              angle: RankUpLayout.strikeTurnDeg * math.pi / 180,
              child: EntranceBuilder(
                LevelUpMotion.strike,
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
            ),
          ),
        ),
      ]);
}

/// The next level: the XP still to earn, and a bar filling to how far in
/// the player already is.
class _NextLevel extends StatelessWidget {
  const _NextLevel(this.level);
  final XpLevel level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      shape: const PanelShape(topLeft: LevelUpLayout.nextCut),
      padding: LevelUpLayout.nextPadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        InkTag(s.nextLevelBand, fontSize: LevelUpLayout.nextTagFont),
        const SizedBox(height: Gaps.tight),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(s.xpToNext(level.toNext, level.level + 1),
              style: const TextStyle(fontWeight: Weights.black, fontSize: LevelUpLayout.nextNoteFont)),
        ),
        const SizedBox(height: LevelUpLayout.barGap),
        EntranceBuilder(
          LevelUpMotion.fill,
          builder: (context, t, _) => Container(
            height: LevelUpLayout.barHeight,
            decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.label)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (level.fraction * t).clamp(0.0, 1.0),
              heightFactor: 1,
              child: const ColoredBox(color: Palette.pink),
            ),
          ),
        ),
      ]),
    );
  }
}
