import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/deck_selection.dart';
import '../manga/manga.dart';
import 'picker_widgets.dart';

/// The 友札 sets free practice offers: the confusable sets (as on the card
/// page's 間違えやすい友札 row) with at least two cards the player knows.
List<FudaSet> offeredLookAlikes(DeckSelection deck) => [
      for (final set in fudaSets.ofKind(FudaSetKind.confusable))
        if (deck.knownOf(set.poemIds).length >= 2) set,
    ];

/// Free practice's 友札 picker: one row per set, its cards as kimariji chips;
/// a tap adds or drops the whole set.
class LookAlikePickerScreen extends StatelessWidget {
  const LookAlikePickerScreen({super.key, required this.deck});
  final DeckSelection deck;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sets = offeredLookAlikes(deck);
    return PickerScaffold(
      deck: deck,
      title: s.pickLookAlikes,
      hint: s.pickLookAlikesHint,
      body: sets.isEmpty
          ? Align(
              alignment: Alignment.topCenter,
              child: DashedBox(
                padding: FreePracticeLayout.setRowPadding,
                child: Text(s.noLookAlikes,
                    style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body)),
              ),
            )
          : ListenableBuilder(
              listenable: deck,
              builder: (context, _) => ListView.separated(
                itemCount: sets.length,
                separatorBuilder: (_, _) => const SizedBox(height: Gaps.panel),
                itemBuilder: (context, i) => _SetRow(deck: deck, set: sets[i]),
              ),
            ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.deck, required this.set});
  final DeckSelection deck;
  final FudaSet set;

  @override
  Widget build(BuildContext context) {
    final coverage = deck.coverageOf(set.poemIds);
    return Pressable(
      onTap: () => deck.toggleGroup(set.poemIds),
      scale: Press.panelScale,
      turn: 0,
      semanticLabel: set.label,
      builder: (context, _) => MangaPanel(
        border: Strokes.control,
        color: coverage == Coverage.none ? Palette.paper : Palette.sunSoft,
        padding: FreePracticeLayout.setRowPadding,
        child: Row(children: [
          CoverageBox(coverage),
          const SizedBox(width: Gaps.inner),
          Expanded(
            child: Wrap(
              spacing: FreePracticeLayout.chipGap,
              runSpacing: FreePracticeLayout.chipGap,
              children: [
                for (final id in [...set.poemIds]..sort((a, b) => poems[a].kimariji.compareTo(poems[b].kimariji)))
                  CardChip(poem: poems[id], picked: deck.contains(id), known: deck.known.contains(id), small: true),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
