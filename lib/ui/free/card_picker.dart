import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/deck_selection.dart';
import '../manga/manga.dart';
import 'picker_widgets.dart';

/// Free practice's card picker: every card as its kimariji, island by island
/// in kana order; a tap toggles a card, an island's header toggles all of it.
class CardPickerScreen extends StatelessWidget {
  const CardPickerScreen({super.key, required this.deck});
  final DeckSelection deck;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PickerScaffold(
      deck: deck,
      title: s.pickCards,
      hint: s.pickCardsHint,
      body: ListenableBuilder(
        listenable: deck,
        builder: (context, _) => ListView(
          children: [
            for (final group in initialGroups) ...[
              _IslandSection(deck: deck, name: group, ids: _byKimariji(fudaSets['initial:$group'].poemIds)),
              const SizedBox(height: FreePracticeLayout.sectionGap),
            ],
          ],
        ),
      ),
    );
  }

  static List<int> _byKimariji(List<int> ids) =>
      [...ids]..sort((a, b) => poems[a].kimariji.compareTo(poems[b].kimariji));
}

class _IslandSection extends StatelessWidget {
  const _IslandSection({required this.deck, required this.name, required this.ids});
  final DeckSelection deck;
  final String name;
  final List<int> ids;

  @override
  Widget build(BuildContext context) {
    final known = deck.knownOf(ids).length;
    final picked = ids.where(deck.contains).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          onTap: known == 0 ? null : () => deck.toggleGroup(ids),
          semanticLabel: name,
          scale: 1,
          builder: (context, _) => Row(children: [
            if (known > 0) ...[CoverageBox(deck.coverageOf(ids)), const SizedBox(width: Gaps.small)],
            Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: FreePracticeLayout.sectionFont,
                      color: known == 0 ? Palette.mute : Palette.ink)),
            ),
            const SizedBox(width: Gaps.small),
            Pill('$picked/$known'),
          ]),
        ),
        const SizedBox(height: Gaps.small),
        Wrap(
          spacing: FreePracticeLayout.chipGap,
          runSpacing: FreePracticeLayout.chipGap,
          children: [
            for (final id in ids)
              CardChip(
                poem: poems[id],
                picked: deck.contains(id),
                known: deck.known.contains(id),
                onTap: () => deck.toggleCard(id),
              ),
          ],
        ),
      ],
    );
  }
}
