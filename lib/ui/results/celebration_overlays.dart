import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';
import 'celebrations.dart';

/// Full-screen chrome shared by every celebration: a colour, optional art,
/// tap-anywhere-to-skip, and a primary CTA pinned near the bottom.
class _OverlayChrome extends StatelessWidget {
  const _OverlayChrome({
    required this.color,
    required this.onNext,
    required this.cta,
    required this.child,
    this.art = const [],
  });

  final Color color;
  final VoidCallback onNext;
  final String cta;
  final Widget child;
  final List<ArtLayer> art;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onNext,
        child: ColoredBox(
          color: color,
          child: Stack(fit: StackFit.expand, children: [
            if (art.isNotEmpty) StaticArt(art),
            child,
            Positioned(
              left: Gaps.gutter,
              right: Gaps.gutter,
              bottom: Gaps.section,
              child: SizedBox(
                height: PlayLayout.buttonRowHeight,
                child: InkButton(
                  color: Palette.pink,
                  onTap: onNext,
                  child: Text(cta, style: const TextStyle(fontFamily: Fonts.display, fontSize: TypeScale.title)),
                ),
              ),
            ),
          ]),
        ),
      );
}

/// A new card (or several) unlocked: the card itself, and its 友札 twin.
class NewCardOverlay extends StatelessWidget {
  const NewCardOverlay({super.key, required this.data, required this.onNext});
  final NewCardCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final poem = poems[data.poemId];
    return _OverlayChrome(
      color: Palette.seaDeep,
      onNext: onNext,
      cta: s.bringItOn,
      art: const [BurstLayer(BurstSpec(
          box: Size(390, 844), center: Offset(195, 350), count: 220, innerMin: 190, innerMax: 250, width: 4.5,
          seed: 8, color: Palette.paper))],
      child: Stack(children: [
        Align(
          alignment: const Alignment(0, -0.72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: SizedBox(
              height: 96,
              child: ShoutButton(label: s.newCard, onTap: null, color: Palette.paper, arrow: false, fontSize: 22),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.44),
          child: InkTag(s.newCardBand),
        ),
        Align(
          alignment: const Alignment(0, -0.02),
          child: SizedBox(
            width: ResultsLayout.newCardWidth,
            child: TorifudaCard(poem: poem),
          ),
        ),
        Positioned(
          left: Gaps.gutter,
          right: Gaps.gutter,
          bottom: PlayLayout.buttonRowHeight + Gaps.section * 3,
          child: MangaPanel(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                OutlinedText(poem.kimariji,
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.newCardKimarijiFont, color: Palette.pink),
                    outline: Palette.ink,
                    outlineWidth: 7),
                const SizedBox(width: Gaps.panel),
                Text(s.kimarijiLabel, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.tiny)),
              ]),
              const SizedBox(height: Gaps.tight),
              Text('#${poem.id} · ${poem.author}',
                  style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.newCardMetaFont)),
              if (data.twins.isNotEmpty) ...[
                const SizedBox(height: Gaps.tight),
                Text(s.twinOf(poems[data.twins.first].kimariji),
                    style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.newCardTipFont)),
              ],
            ]),
          ),
        ),
        const Placed(ResultsLayout.newCardTobi, child: Tobi(pose: TobiPose.shocked)),
      ]),
    );
  }
}

/// A newly unlocked card looks alike to one already known: shown right
/// after that card's [NewCardOverlay].
class ConfusableWarningOverlay extends StatelessWidget {
  const ConfusableWarningOverlay({super.key, required this.data, required this.onNext});
  final ConfusableWarningCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ids = [data.poemId, ...data.knownSiblings.take(ResultsLayout.confusableMaxSiblings)];
    return _OverlayChrome(
      color: Palette.sun,
      onNext: onNext,
      cta: s.gotIt,
      child: Stack(children: [
        Align(alignment: const Alignment(0, -0.62), child: InkTag(s.lookAlikeBand)),
        Align(
          alignment: const Alignment(0, -0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: Text(s.mixUpWarning,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.confusableTitleFont, height: 1.1)),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.02),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (i, id) in ids.indexed) ...[
              if (i > 0) const SizedBox(width: Gaps.section),
              _ConfusableCard(poemId: id, isNew: i == 0),
            ],
          ]),
        ),
        const Placed(ResultsLayout.confusableTobi, child: Tobi(pose: TobiPose.pointing)),
      ]),
    );
  }
}

class _ConfusableCard extends StatelessWidget {
  const _ConfusableCard({required this.poemId, required this.isNew});
  final int poemId;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (isNew) ...[
        InkTag(s.newBadge, color: Palette.pink),
        const SizedBox(height: Gaps.tight),
      ],
      SizedBox(width: ResultsLayout.confusableCardWidth, child: TorifudaCard(poem: poems[poemId])),
      const SizedBox(height: Gaps.tight),
      Text(poems[poemId].kimariji, style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.confusableKimarijiFont)),
    ]);
  }
}

/// An island fully learned: the coastline flagged, the next one rising.
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
    return _OverlayChrome(
      color: const Color(0xFF3FA5FF),
      onNext: onNext,
      cta: s.setSail,
      child: Stack(children: [
        Align(
          alignment: const Alignment(0, -0.78),
          child: OutlinedText('制覇!!',
              style: const TextStyle(
                  fontFamily: Fonts.display, fontSize: ResultsLayout.islandTitleFont, color: Palette.paper, height: 1),
              outlineWidth: ResultsLayout.islandTitleOutline),
        ),
        Align(
          alignment: const Alignment(0, -0.55),
          child: InkTag(s.islandCompleteBand, fontSize: ResultsLayout.islandBandFont, color: Palette.ink, textColor: Palette.sun),
        ),
        Align(
          alignment: const Alignment(0, -0.4),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Palette.paper),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text('${island.name} · ${island.sites.length} / ${island.sites.length}',
                  style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.islandSubFont)),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.05),
          child: SizedBox(
            width: ResultsLayout.islandMapSize,
            height: ResultsLayout.islandMapSize,
            child: IslandMap(
              styles: [
                for (final isl in archipelago.islands)
                  if (isl.index == islandIndex)
                    IslandStyle(flag: true, sites: {for (final site in isl.sites) site.poemId: const SiteMark.tree()})
                  else
                    const IslandStyle(look: IslandLook.shoal),
              ],
              viewport: island.bounds.inflate(30),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          left: Gaps.gutter,
          right: Gaps.gutter,
          bottom: PlayLayout.buttonRowHeight + Gaps.section * 3,
          child: MangaPanel(
            color: Palette.seaSoft,
            tone: Tones.sea,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: next == null
                ? Text(s.allIslandsDone, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    InkTag(s.nextIslandTag(next.name)),
                    const SizedBox(height: Gaps.tight),
                    Text(next.name, style: const TextStyle(fontFamily: Fonts.display, fontSize: 22, height: 1)),
                    if (next.sites.length > 1)
                      Text(s.firstUp(poems[next.sites[0].poemId].kimariji, poems[next.sites[1].poemId].kimariji),
                          style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small)),
                  ]),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: PlayLayout.buttonRowHeight + Gaps.section * 2,
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Palette.paper),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.islandLineFont),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(s.islandsDoneOf(islandsDone, archipelago.islands.length)),
                    const Text(' · '),
                    NumberedText(s.cardsOf, [cardsUnlocked, 100]),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const Placed(ResultsLayout.islandTobi, child: Tobi(pose: TobiPose.cheering)),
      ]),
    );
  }
}

/// The band changed: a two-page spread crossing the gutter.
class RankUpOverlay extends StatelessWidget {
  const RankUpOverlay({super.key, required this.data, required this.onNext});
  final RankUpCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _OverlayChrome(
      color: Palette.paper,
      onNext: onNext,
      cta: s.onward,
      child: Stack(children: [
        Row(children: [
          Expanded(
            child: ColoredBox(
              color: Palette.seaSoft,
              child: Stack(children: [
                const Positioned.fill(child: ToneBox(Tones.sea)),
                Positioned(
                  left: 16,
                  top: 340,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.beforeBandLabel, style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.rankOldLabelFont)),
                    const SizedBox(height: Gaps.tight),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Palette.paper,
                        border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.control)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                        child: Text(data.before.label,
                            style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankOldFont, color: Palette.mute)),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          // The gutter shadow between the two pages.
          const SizedBox(
            width: 4,
            child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0x00000000), Color(0x33000000), Color(0x00000000)]),
            )),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.1),
                  radius: 1,
                  colors: [Color(0xFFFFFBE3), Color(0xFFFFE77A), Palette.sun],
                ),
              ),
              child: Stack(children: [
                Positioned(
                  left: 16,
                  top: 388,
                  right: 16,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(color: Palette.ink),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 2, 6, 3),
                        child: Text(s.nowBandLabel, style: const TextStyle(color: Palette.paper, fontWeight: Weights.black, fontSize: ResultsLayout.rankNewLabelFont)),
                      ),
                    ),
                    const SizedBox(height: Gaps.tight),
                    OutlinedText(data.after.label,
                        style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankNewFont, color: Palette.sun),
                        outlineWidth: 8),
                  ]),
                ),
                const Placed(ResultsLayout.rankTobi, child: Tobi(pose: TobiPose.cheering)),
              ]),
            ),
          ),
        ]),
        Align(
          alignment: const Alignment(0, -0.6),
          child: OutlinedText('昇級!!',
              style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankTitleFont, height: 1),
              outlineWidth: ResultsLayout.rankTitleOutline),
        ),
        Align(
          alignment: const Alignment(0, -0.36),
          child: InkTag(s.rankUpBand, fontSize: ResultsLayout.rankBandFont, color: Palette.ink, textColor: Palette.sun),
        ),
        Align(
          alignment: const Alignment(0, 0.42),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Palette.paper,
              border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.panel)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Text('${data.ratingBefore.round()} → ${data.ratingAfter.round()}',
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankRateFont)),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A tighter goal ladder rung: the player has earned a faster target.
class GoalUpOverlay extends StatelessWidget {
  const GoalUpOverlay({super.key, required this.goalMs, required this.onNext});
  final int goalMs;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return _OverlayChrome(
      color: Palette.sun,
      onNext: onNext,
      cta: s.nicePace,
      art: const [BurstLayer(BurstSpec(
          box: Size(390, 844), center: Offset(195, 380), count: 140, innerMin: 120, innerMax: 170, width: 4, seed: 15))],
      child: Stack(children: [
        Align(
          alignment: const Alignment(0, -0.3),
          child: OutlinedText(s.goalUp,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.goalTitleFont, height: 1)),
        ),
        Align(
          alignment: const Alignment(0, -0.1),
          child: InkTag(s.goalUpBand),
        ),
        Align(
          alignment: const Alignment(0, 0.06),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Palette.paper),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(s.goalUpNote(goalMs), style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.goalNoteFont)),
            ),
          ),
        ),
        const Placed(ResultsLayout.goalTobi, child: Tobi(pose: TobiPose.fired)),
      ]),
    );
  }
}
