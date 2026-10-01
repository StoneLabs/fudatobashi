import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/deck_selection.dart';
import '../manga/manga.dart';

/// The frame of free practice's pickers: a back button, the title and the
/// picked count, a hint, the picker itself, and All / None / Done at thumb
/// reach. Rebuilds whenever [deck] changes.
class PickerScaffold extends StatelessWidget {
  const PickerScaffold({
    super.key,
    required this.deck,
    required this.title,
    required this.hint,
    required this.body,
  });

  final DeckSelection deck;
  final String title, hint;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: ListenableBuilder(
            listenable: deck,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: HeaderStyle.topGap),
                Row(children: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                  const SizedBox(width: Gaps.small),
                  Expanded(child: ScreenTitle(title)),
                  const SizedBox(width: Gaps.small),
                  InkTag('${deck.count}/${deck.known.length}',
                      color: deck.isDefault ? Palette.land : Palette.ink,
                      textColor: deck.isDefault ? Palette.ink : Palette.paper),
                ]),
                const SizedBox(height: Gaps.small),
                Text(hint,
                    style: const TextStyle(fontWeight: Weights.bold, fontSize: FreePracticeLayout.hintFont)),
                const SizedBox(height: Gaps.section),
                Expanded(child: body),
                const SizedBox(height: Gaps.section),
                Row(children: [
                  Expanded(child: _FooterButton(s.selectAll, onTap: deck.isDefault ? null : deck.selectAll)),
                  const SizedBox(width: Gaps.panel),
                  Expanded(child: _FooterButton(s.selectNone, onTap: deck.count == 0 ? null : deck.clear)),
                  const SizedBox(width: Gaps.panel),
                  Expanded(
                    flex: 2,
                    child: _FooterButton(s.done, color: Palette.pink, onTap: () => Navigator.maybePop(context)),
                  ),
                ]),
                const SizedBox(height: Gaps.section),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton(this.label, {required this.onTap, this.color = Palette.paper});
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FreePracticeLayout.footerMinHeight),
        child: InkButton(
          onTap: onTap,
          color: onTap == null ? Palette.desk : color,
          semanticLabel: label,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: const TextStyle(fontWeight: Weights.black, fontSize: FreePracticeLayout.footerFont)),
          ),
        ),
      );
}

/// A card as its kimariji: sun when in the deck, paper when left out, and
/// greyed (not tappable) when the player hasn't learned it yet.
class CardChip extends StatelessWidget {
  const CardChip({super.key, required this.poem, required this.picked, required this.known, this.onTap, this.small = false});

  final Poem poem;
  final bool picked, known;
  final VoidCallback? onTap;

  /// The 友札 picker's compact chips, inside a tappable row.
  final bool small;

  @override
  Widget build(BuildContext context) {
    final label = kimarijiFor(context, poem.id);
    final chip = Container(
      constraints: small ? null : const BoxConstraints(minHeight: FreePracticeLayout.chipMinHeight),
      padding: small ? FreePracticeLayout.chipSmallPadding : FreePracticeLayout.chipPadding,
      decoration: BoxDecoration(
        color: !known ? Palette.desk : (picked ? Palette.sun : Palette.paper),
        border: Border.all(color: known ? Palette.ink : Palette.mute, width: Strokes.label),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: Fonts.display,
          fontSize: small ? FreePracticeLayout.chipSmallFont : FreePracticeLayout.chipFont,
          color: known ? Palette.ink : Palette.mute,
          height: TypeScale.displayLineHeight,
        ),
      ),
    );
    if (onTap == null) return Semantics(label: label, selected: picked, child: chip);
    return Semantics(
      selected: picked,
      child: Pressable(onTap: known ? onTap : null, semanticLabel: label, builder: (context, _) => chip),
    );
  }
}

/// How much of an island or 友札 set is in the deck: a ticked, half-filled or
/// empty box.
class CoverageBox extends StatelessWidget {
  const CoverageBox(this.coverage, {super.key});
  final Coverage coverage;

  @override
  Widget build(BuildContext context) => Container(
        width: FreePracticeLayout.coverageBox,
        height: FreePracticeLayout.coverageBox,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: coverage == Coverage.none ? Palette.paper : Palette.sun,
          border: Border.all(color: Palette.ink, width: Strokes.control),
        ),
        child: switch (coverage) {
          Coverage.all => MangaIcon(IconArt.check, size: FreePracticeLayout.coverageIcon, strokeWidth: Strokes.button),
          Coverage.some => SizedBox.fromSize(
              size: FreePracticeLayout.coverageDash, child: const ColoredBox(color: Palette.ink)),
          Coverage.none => null,
        },
      );
}
