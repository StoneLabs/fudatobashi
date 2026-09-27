import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import 'home_screen.dart';
import 'home_widgets.dart';
import 'journey_state.dart';
import 'training_hero.dart';

/// Home in journey mode (spec phone 2): the archipelago map as the progress
/// bar, the current island's cards, and the Training hero.
class JourneyHome extends StatelessWidget {
  const JourneyHome({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final s = S.of(context);
    final journey = JourneyState.of(progress);
    final due = progress.dueCount();
    final narration = due == 0
        ? Text(s.caughtUp)
        : NumberedText(
            s.reviewsAndNew,
            [due, progress.freshCount],
            numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: NarrationStyle.number),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _JourneyMap(journey)),
        const SizedBox(height: Gaps.panel),
        SizedBox(height: HomeLayout.progressHeight, child: _IslandProgress(journey)),
        const SizedBox(height: Gaps.panel),
        SizedBox(
          height: HomeLayout.journeyHeroHeight,
          child: TrainingHero(
            size: HeroSize.compact,
            narration: narration,
            balloon: journey.finished ? s.keepGoing : s.finishIsland(journey.island.name),
          ),
        ),
        const SizedBox(height: Gaps.section),
        const FreeAndGuestRow(),
      ],
    );
  }
}

class _JourneyMap extends StatelessWidget {
  const _JourneyMap(this.journey);
  final JourneyState journey;

  List<IslandStyle> _styles(S s) {
    final cur = journey.current;
    return [
      for (final isl in archipelago.islands)
        if (journey.done(isl.index))
          IslandStyle(
            flag: true,
            sites: {for (final site in isl.sites) site.poemId: const SiteMark.tree()},
            plate: IslandPlate(name: isl.name, background: Palette.land, fontSize: MapStyle.plateFont),
          )
        else if (isl.index == cur)
          IslandStyle(
            pulse: true,
            sites: {
              for (final site in isl.sites)
                site.poemId: journey.unlocked.contains(site.poemId)
                    ? const SiteMark.tree()
                    : journey.upNext.contains(site.poemId)
                        ? const SiteMark.pending(Palette.sun)
                        : const SiteMark.pending(),
            },
            plate: IslandPlate(
              name: isl.name,
              background: Palette.pink,
              chip: '${journey.island.unlocked}/${journey.island.total}',
              emphasis: true,
            ),
          )
        else if (isl.index < cur)
          IslandStyle(sites: {
            for (final site in isl.sites)
              if (journey.unlocked.contains(site.poemId)) site.poemId: const SiteMark.tree(),
          })
        else
          IslandStyle(
            look: IslandLook.shoal,
            plate: isl.index - cur <= JourneyView.platesAhead
                ? IslandPlate(
                    name: isl.name,
                    dashed: true,
                    chip: isl.index == cur + 1 ? s.nextChip : '${isl.sites.length}',
                    chipBackground: isl.index == cur + 1 ? Palette.sun : Palette.paper,
                  )
                : null,
          ),
    ];
  }

  /// The slice of the map shown: full width, as tall as the panel's aspect
  /// allows, with the current island a little below the middle.
  Rect _viewport(Size panel) {
    final map = archipelago.size;
    final h = map.width * panel.height / panel.width;
    if (h >= map.height) return Offset.zero & map;
    final c = archipelago.islands[journey.current].center;
    final top = (c.dy - h * JourneyView.focus).clamp(0.0, map.height - h);
    return Rect.fromLTWH(0, top, map.width, h);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const count = TextStyle(fontFamily: Fonts.display, fontSize: HomeLayout.mapCountNumber);
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, HomeLayout.mapCut)),
      child: LayoutBuilder(builder: (context, box) {
        return Stack(
          fit: StackFit.expand,
          children: [
            IslandMap(
              styles: _styles(s),
              viewport: _viewport(box.biggest),
              route: IslandRoute(journey.current),
              boat: IslandMap.boatPosition(archipelago.islands, journey.current),
              seaSeed: JourneyView.seaSeed,
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: Backdrops.mapFogHeight,
              child: IgnorePointer(child: _Fog()),
            ),
            Positioned(
              left: HomeLayout.mapLabelInsets.left,
              top: HomeLayout.mapLabelInsets.top,
              child: InkBanner(s.journeyBanner, fontSize: HomeLayout.mapBannerFont),
            ),
            Positioned(
              left: HomeLayout.mapLabelInsets.left,
              top: HomeLayout.mapCountTop,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.paper,
                  border: Border.all(color: Palette.ink, width: Strokes.label),
                ),
                child: Padding(
                  padding: HomeLayout.mapCountPadding,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: HomeLayout.mapCountFont, fontWeight: Weights.bold),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      NumberedText(s.islandOf, [journey.current + 1, journey.islands.length], numberStyle: count),
                      const Text(' · '),
                      NumberedText(s.cardsOf, [journey.cardsUnlocked, poems.all.length], numberStyle: count),
                    ]),
                  ),
                ),
              ),
            ),
            Positioned(
              right: HomeLayout.mapLabelInsets.right,
              top: HomeLayout.mapLabelInsets.top + Strokes.label,
              child: DashedBox(
                border: Strokes.label,
                padding: HomeLayout.mapMistPadding,
                child: Text(
                  journey.islandsAhead == 0 ? s.allIslandsReached : s.islandsAhead(journey.islandsAhead),
                  style: const TextStyle(fontSize: HomeLayout.mapMistFont, fontWeight: Weights.black),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Fog extends StatelessWidget {
  const _Fog();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [for (final a in Backdrops.mapFogAlpha) Palette.paper.withValues(alpha: a)],
            stops: Backdrops.mapFogStops,
          ),
        ),
      );
}

class _IslandProgress extends StatelessWidget {
  const _IslandProgress(this.journey);
  final JourneyState journey;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final island = journey.island;
    final shape = archipelago.islands[journey.current];
    return MangaPanel(
      padding: HomeLayout.progressPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(island.name,
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: HomeLayout.islandTitle, height: 1)),
              const SizedBox(width: Gaps.panel),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Palette.pink,
                  border: Border.all(color: Palette.ink, width: Strokes.label),
                ),
                child: Padding(
                  padding: HomeLayout.nowPadding,
                  child: Text(
                    s.now,
                    style: const TextStyle(
                      fontSize: HomeLayout.nowFont,
                      fontWeight: Weights.black,
                      letterSpacing: TagStyle.tracking * HomeLayout.nowFont,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              NumberedText(
                s.learnedOf,
                [island.unlocked, island.total],
                style: const TextStyle(fontSize: HomeLayout.learnedFont, fontWeight: Weights.black),
                numberStyle: const TextStyle(
                    fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: HomeLayout.learnedNumber),
              ),
            ],
          ),
          const SizedBox(height: HomeLayout.pipTop),
          CardPips([
            for (final site in shape.sites)
              journey.unlocked.contains(site.poemId)
                  ? PipState.learned
                  : journey.upNext.contains(site.poemId)
                      ? PipState.next
                      : PipState.locked,
          ]..sort((a, b) => a.index.compareTo(b.index))),
          if (progress.knownCardSpeedMs != null) ...[
            const SizedBox(height: HomeLayout.knownSpeedGap),
            KnownSpeedTag(ms: progress.knownCardSpeedMs, weekAgoMs: progress.knownCardSpeedTrendAgo),
          ],
        ],
      ),
    );
  }
}
