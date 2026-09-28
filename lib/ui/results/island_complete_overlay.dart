import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import 'celebration_chrome.dart';

/// "Island complete" (制覇!!): the island planted with a flag on every card,
/// confetti raining, and the next island rising from the sea.
class IslandCompleteOverlay extends StatelessWidget {
  const IslandCompleteOverlay({
    super.key,
    required this.islandIndex,
    required this.islandsDone,
    required this.cardsUnlocked,
    required this.onNext,
  });

  final int islandIndex;
  final int islandsDone;
  final int cardsUnlocked;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final island = archipelago.islands[islandIndex];
    final next = islandIndex + 1 < archipelago.islands.length ? archipelago.islands[islandIndex + 1] : null;
    return EntranceStage(
      length: IslandCompleteMotion.rising.end,
      child: CelebrationChrome(
        color: IslandCompleteLayout.sea,
        onNext: onNext,
        art: const [SeaLayer(IslandCompleteLayout.seaSeed)],
        backdrop: const [
          Entrance(
            IslandCompleteMotion.lines,
            child: Opacity(
              opacity: IslandCompleteLayout.focusOpacity,
              child: StaticArt([BurstLayer(IslandCompleteLayout.focus)]),
            ),
          ),
          CelebrationGlow(
            at: IslandCompleteLayout.glowAt,
            size: IslandCompleteLayout.glowSize,
            colors: IslandCompleteLayout.glowColors,
            stops: IslandCompleteLayout.glowStops,
          ),
          FractionallySizedBox(
            alignment: Alignment.topCenter,
            heightFactor: IslandCompleteLayout.confettiShare,
            child: ConfettiRain(),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: IslandCompleteLayout.topGap),
            const Entrance(
              IslandCompleteMotion.title,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: OutlinedText(
                  IslandCompleteLayout.title,
                  style: TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: IslandCompleteLayout.titleFont,
                      color: Palette.paper,
                      height: 1),
                  outline: Palette.ink,
                  outlineWidth: IslandCompleteLayout.titleOutline,
                ),
              ),
            ),
            Entrance(
              IslandCompleteMotion.band,
              child: CelebrationBand(s.islandCompleteBand,
                  inset: IslandCompleteLayout.bandInset,
                  fontSize: IslandCompleteLayout.bandFont,
                  tracking: IslandCompleteLayout.bandTracking,
                  padding: IslandCompleteLayout.bandPadding,
                  turnDeg: IslandCompleteLayout.bandTurnDeg),
            ),
            const SizedBox(height: IslandCompleteLayout.subGap),
            Entrance(
              IslandCompleteMotion.sub,
              child: Center(
                child: _Label(
                  border: IslandCompleteLayout.subBorder,
                  padding: IslandCompleteLayout.subPadding,
                  child: NumberedText(
                    '${island.name} · ${s.cardsLearnedOf}',
                    [island.sites.length, island.sites.length],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: IslandCompleteLayout.subFont),
                  ),
                ),
              ),
            ),
            Expanded(child: _Conquered(island: island)),
            if (next != null) Entrance(IslandCompleteMotion.next, child: _NextIsland(island: next)),
            const SizedBox(height: IslandCompleteLayout.lineGap),
            Entrance(
              IslandCompleteMotion.actions,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                  child: _Label(
                    border: IslandCompleteLayout.lineBorder,
                    padding: IslandCompleteLayout.linePadding,
                    child: next == null
                        ? Text(s.allIslandsDone,
                            style: const TextStyle(fontWeight: Weights.black, fontSize: IslandCompleteLayout.lineFont))
                        : NumberedText(
                            s.islandProgress,
                            [islandsDone, archipelago.islands.length, cardsUnlocked, poems.all.length],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: Weights.bold, fontSize: IslandCompleteLayout.lineFont),
                          ),
                  ),
                ),
                const SizedBox(height: IslandCompleteLayout.lineGap),
                CelebrationCta(
                  label: s.setSail,
                  sub: s.other.setSail,
                  onTap: onNext,
                  height: IslandCompleteLayout.actionHeight,
                  fontSize: IslandCompleteLayout.ctaFont,
                  subFontSize: IslandCompleteLayout.ctaSubFont,
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

/// White caption box with an ink border.
class _Label extends StatelessWidget {
  const _Label({required this.border, required this.padding, required this.child});
  final double border;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.paper,
          border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: border)),
        ),
        child: Padding(padding: padding, child: child),
      );
}

/// The completed island, a flag on every card and tide rings around it,
/// with ドドーン!! and Tobi cheering beside it.
class _Conquered extends StatelessWidget {
  const _Conquered({required this.island});
  final IslandShape island;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final side = math.min(box.maxWidth * IslandCompleteLayout.islandShare, box.maxHeight);
        return Stack(clipBehavior: Clip.none, children: [
          Center(
            child: SizedBox.square(
              dimension: side,
              child: Entrance(IslandCompleteMotion.island, child: _FlaggedIsland(island: island)),
            ),
          ),
          Positioned(
            left: IslandCompleteLayout.sfxAt.dx,
            top: IslandCompleteLayout.sfxAt.dy,
            child: Entrance(
              IslandCompleteMotion.sfx,
              child: Transform.rotate(
                angle: IslandCompleteLayout.sfxTurnDeg * math.pi / 180,
                child: const SfxText(IslandCompleteLayout.sfx,
                    size: IslandCompleteLayout.sfxFont, seed: IslandCompleteLayout.sfxSeed, outline: NewCardLayout.sfxOutline),
              ),
            ),
          ),
          const Placed(
            IslandCompleteLayout.tobi,
            child: Entrance(IslandCompleteMotion.tobi, child: Tobi(pose: TobiPose.cheering)),
          ),
        ]);
      });
}

/// [island] with a flag on every card, fitted to the box by its bounds
/// grown by [IslandCompleteLayout.islandPad], its tide rings spilling past
/// the box rather than being cut off by it.
class _FlaggedIsland extends StatelessWidget {
  const _FlaggedIsland({required this.island});
  final IslandShape island;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final fitted = island.bounds.inflate(IslandCompleteLayout.islandPad);
        final scale = math.min(box.maxWidth / fitted.width, box.maxHeight / fitted.height);
        final view = fitted.expandToInclude(IslandMap.tideReach(island));
        final origin = Offset(box.maxWidth - fitted.width * scale, box.maxHeight - fitted.height * scale) / 2 +
            (view.topLeft - fitted.topLeft) * scale;
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: origin.dx,
            top: origin.dy,
            width: view.width * scale,
            height: view.height * scale,
            child: IslandMap(
              styles: [
                for (final isl in archipelago.islands)
                  if (isl.index == island.index)
                    IslandStyle(pulse: true, sites: {for (final site in isl.sites) site.poemId: const SiteMark.flag()})
                  else
                    const IslandStyle(look: IslandLook.hidden),
              ],
              viewport: view,
              fit: BoxFit.contain,
              sea: false,
            ),
          ),
        ]);
      });
}

/// The next island rising out of the sea, with its name and first cards.
class _NextIsland extends StatelessWidget {
  const _NextIsland({required this.island});
  final IslandShape island;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sites = island.sites;
    return MangaPanel(
      shape: const PanelShape(topLeft: IslandCompleteLayout.nextCut),
      color: Palette.seaSoft,
      tone: Tones.sea,
      padding: IslandCompleteLayout.nextPadding,
      child: Row(children: [
        SizedBox.fromSize(
          size: IslandCompleteLayout.nextArt,
          child: Entrance(
            IslandCompleteMotion.rising,
            child: IslandMap(
              styles: [
                for (final isl in archipelago.islands)
                  isl.index == island.index ? const IslandStyle(pulse: true) : const IslandStyle(look: IslandLook.hidden),
              ],
              viewport: IslandMap.tideReach(island),
              fit: BoxFit.contain,
              sea: false,
              tideColor: Palette.paper,
            ),
          ),
        ),
        const SizedBox(width: IslandCompleteLayout.nextGap),
        Expanded(
          child: _Label(
            border: IslandCompleteLayout.nextBoxBorder,
            padding: IslandCompleteLayout.nextBoxPadding,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              InkTag(s.nextIslandBand, fontSize: IslandCompleteLayout.nextTagFont),
              Text(island.name,
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: IslandCompleteLayout.nextNameFont, height: 1.1)),
              if (sites.length > 1)
                Text(s.nextIslandNote(sites.length, poems[sites[0].poemId].kimariji, poems[sites[1].poemId].kimariji),
                    style: const TextStyle(fontWeight: Weights.bold, fontSize: IslandCompleteLayout.nextNoteFont)),
            ]),
          ),
        ),
      ]),
    );
  }
}
