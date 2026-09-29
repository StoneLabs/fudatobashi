import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/fuda_sets.dart';
import '../../data/islands.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/deck_selection.dart';
import '../islands/island_map.dart';
import '../manga/manga.dart';
import 'picker_widgets.dart';

/// The cards of an island, as `initialGroups` lists them.
List<int> islandCards(IslandShape island) => fudaSets['initial:${island.name}'].poemIds;

/// Free practice's island picker: the archipelago, each card a dot (sun in
/// the deck, white left out, grey not learned yet); tapping an island adds or
/// drops all of its known cards.
class IslandPickerScreen extends StatelessWidget {
  const IslandPickerScreen({super.key, required this.deck});
  final DeckSelection deck;

  IslandStyle _styleOf(IslandShape island) {
    final ids = islandCards(island);
    final known = deck.knownOf(ids).length;
    if (known == 0) return IslandStyle(look: IslandLook.shoal, plate: IslandPlate(name: island.name, dashed: true));
    final coverage = deck.coverageOf(ids);
    return IslandStyle(
      sites: {
        for (final id in ids)
          id: deck.contains(id)
              ? const SiteMark.dot(Palette.sun)
              : deck.known.contains(id)
                  ? const SiteMark.hollow()
                  : const SiteMark.dot(Palette.desk),
      },
      plate: IslandPlate(
        name: island.name,
        chip: '${ids.where(deck.contains).length}/$known',
        chipBackground: coverage == Coverage.all ? Palette.sun : Palette.paper,
        emphasis: coverage == Coverage.all,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PickerScaffold(
      deck: deck,
      title: s.pickIslands,
      hint: s.pickIslandsHint,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: MangaPanel(
            shape: const PanelShape(topLeft: Offset(0, StatsLayout.mapCut), bottomRight: Offset(0, StatsLayout.mapCut)),
            child: ListenableBuilder(
              listenable: deck,
              builder: (context, _) => IslandMap(
                styles: [for (final island in archipelago.islands) _styleOf(island)],
                viewport: Offset.zero & archipelago.size,
                fit: BoxFit.contain,
                onIslandTap: (i) => deck.toggleGroup(islandCards(archipelago.islands[i])),
              ),
            ),
          ),
        ),
        const SizedBox(height: Gaps.panel),
        Wrap(spacing: FreePracticeLayout.legendGap, runSpacing: Gaps.tight, children: [
          _LegendItem(s.legendInDeck, fill: Palette.sun),
          _LegendItem(s.legendOut, fill: Palette.paper),
          _LegendItem(s.legendUnknown, fill: Palette.desk),
        ]),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.label, {required this.fill});
  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: FreePracticeLayout.legendDot,
          height: FreePracticeLayout.legendDot,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: Palette.ink, width: MapStyle.dotStroke),
          ),
        ),
        const SizedBox(width: Gaps.tight),
        Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: FreePracticeLayout.legendFont)),
      ]);
}
