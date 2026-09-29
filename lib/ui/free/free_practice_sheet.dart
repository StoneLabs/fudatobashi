import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/islands.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/deck_selection.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';
import 'card_picker.dart';
import 'island_picker.dart';
import 'look_alike_picker.dart';

/// Home's 始める: free practice's setup sheet, then the run from its big
/// button. The setup is stored as it changes, so it is there next time.
/// Callers show the lock instead while `Progress.freePractice` is closed.
Future<void> openFreePractice(BuildContext context) async {
  final start = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: S.of(context).cancel,
    barrierColor: FreePracticeLayout.barrier,
    transitionDuration: Motion.sheet,
    pageBuilder: (_, _, _) => const FreePracticeSheet(),
    transitionBuilder: (context, animation, _, child) {
      final t = CurvedAnimation(parent: animation, curve: Motion.routeCurve);
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(t),
        child: child,
      );
    },
  );
  if (start == true && context.mounted) {
    await startFreePlay(context, ProgressScope.read(context).settings.freePractice);
  }
}

/// The deck (islands, cards, 友札 sets), 隠し字, whether the run counts, and
/// the start button.
class FreePracticeSheet extends StatefulWidget {
  const FreePracticeSheet({super.key});

  @override
  State<FreePracticeSheet> createState() => _FreePracticeSheetState();
}

class _FreePracticeSheetState extends State<FreePracticeSheet> {
  late final Progress _progress;
  late final DeckSelection _deck;
  late int _mask;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    final setup = _progress.settings.freePractice;
    _deck = DeckSelection(known: _progress.knownCards, picked: setup.cardIds);
    _mask = setup.maskLevel;
  }

  @override
  void dispose() {
    _deck.dispose();
    super.dispose();
  }

  FreePracticeSetup get _setup => FreePracticeSetup(cardIds: _deck.customIds, maskLevel: _mask);

  Future<void> _save() => _progress.updateSettings(_progress.settings.copyWith(freePractice: _setup));

  Future<void> _pick(Widget Function(DeckSelection deck) picker) async {
    await Navigator.of(context).push(MangaRoute<void>(builder: (_) => picker(_deck)));
    await _save();
  }

  void _setMask(int level) {
    setState(() => _mask = level);
    _save();
  }

  void _reset() {
    _deck.selectAll();
    _setMask(0);
  }

  Future<void> _start() async {
    await _save();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MangaPanel(
                  shape: const PanelShape(topLeft: Offset(0, FreePracticeLayout.sheetCut)),
                  padding: FreePracticeLayout.sheetPadding,
                  child: ListenableBuilder(
                    listenable: _deck,
                    builder: (context, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [InkTag(s.freeSheetTag)]),
                                const SizedBox(height: Gaps.small),
                                Text('始める',
                                    style: const TextStyle(
                                        fontFamily: Fonts.display,
                                        fontSize: FreePracticeLayout.title,
                                        height: TypeScale.displayLineHeight)),
                                const SizedBox(height: FreePracticeLayout.titleGap),
                                NumberedText(
                                  s.deckCount,
                                  [_deck.count],
                                  style: const TextStyle(
                                      fontWeight: Weights.black, fontSize: FreePracticeLayout.deckFont),
                                  numberStyle: const TextStyle(
                                      fontFamily: Fonts.display, fontSize: FreePracticeLayout.deckNumber),
                                ),
                                const SizedBox(height: Gaps.section),
                                ..._pickerRows(s),
                                const SizedBox(height: Gaps.section),
                                _MaskRow(level: _mask, onChanged: _setMask),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: Gaps.section),
                        _CountsStrip(counts: !_setup.customized, onReset: _reset),
                        const SizedBox(height: Gaps.section),
                        SizedBox(
                          height: FreePracticeLayout.shoutHeight,
                          child: ShoutButton(
                            label: s.freeStart,
                            color: _deck.count == 0 ? Palette.desk : Palette.pink,
                            onTap: _deck.count == 0 ? null : _start,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Placed(FreePracticeLayout.tobi, child: Tobi(pose: TobiPose.fired)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _pickerRows(S s) {
    final islands = [for (final i in archipelago.islands) if (_deck.knownOf(islandCards(i)).isNotEmpty) i];
    final touched = islands.where((i) => _deck.coverageOf(islandCards(i)) != Coverage.none).length;
    final sets = offeredLookAlikes(_deck);
    final fullSets = sets.where((set) => _deck.coverageOf(set.poemIds) == Coverage.all).length;
    return [
      _PickerRow(
        label: s.islandsRow,
        value: _deck.isDefault ? s.allKnownIslands : s.islandsOf(touched, islands.length),
        onTap: () => _pick((deck) => IslandPickerScreen(deck: deck)),
      ),
      const SizedBox(height: FreePracticeLayout.rowGap),
      _PickerRow(
        label: s.cardsRow,
        value: s.cardsOf(_deck.count, _deck.known.length),
        onTap: () => _pick((deck) => CardPickerScreen(deck: deck)),
      ),
      const SizedBox(height: FreePracticeLayout.rowGap),
      _PickerRow(
        label: s.lookAlikesRow,
        value: sets.isEmpty ? s.noSetsYet : s.setsOf(fullSets, sets.length),
        onTap: sets.isEmpty ? null : () => _pick((deck) => LookAlikePickerScreen(deck: deck)),
      ),
    ];
  }
}

/// One of the sheet's picker buttons: what it picks, the current choice and
/// a chevron.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.value, required this.onTap});
  final String label, value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FreePracticeLayout.rowMinHeight),
        child: InkButton(
          onTap: onTap,
          color: onTap == null ? Palette.desk : Palette.paper,
          border: Strokes.control,
          padding: FreePracticeLayout.rowPadding,
          semanticLabel: '$label: $value',
          child: Row(children: [
            Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: FreePracticeLayout.rowLabelFont)),
            const SizedBox(width: Gaps.panel),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: Weights.bold, fontSize: FreePracticeLayout.rowValueFont),
              ),
            ),
            const SizedBox(width: Gaps.tight),
            MangaIcon(IconArt.chevron, size: FreePracticeLayout.rowChevron),
          ]),
        ),
      );
}

/// 隠し字: off or one of its levels, one tap each, with what the level hides.
class _MaskRow extends StatelessWidget {
  const _MaskRow({required this.level, required this.onChanged});
  final int level;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.maskRow, style: const TextStyle(fontWeight: Weights.black, fontSize: FreePracticeLayout.rowLabelFont)),
      const SizedBox(height: Gaps.small),
      Wrap(spacing: FreePracticeLayout.maskGap, runSpacing: FreePracticeLayout.maskGap, children: [
        for (var l = 0; l <= MaskingTuning.maxLevel; l++)
          Pressable(
            onTap: () => onChanged(l),
            semanticLabel: l == 0 ? s.maskOff : '${s.maskRow} $l',
            builder: (context, _) => Container(
              constraints: const BoxConstraints(
                  minWidth: FreePracticeLayout.maskChip, minHeight: FreePracticeLayout.maskChip),
              padding: const EdgeInsets.symmetric(horizontal: Gaps.small),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: l == level ? Palette.sun : Palette.paper,
                border: Border.all(color: Palette.ink, width: l == level ? Strokes.button : Strokes.label),
              ),
              child: Text(
                l == 0 ? s.maskOff : '$l',
                style: const TextStyle(fontFamily: Fonts.display, fontSize: FreePracticeLayout.maskChipFont, height: 1),
              ),
            ),
          ),
      ]),
      const SizedBox(height: Gaps.tight),
      Text(s.maskLevel(level),
          style: const TextStyle(fontWeight: Weights.bold, fontSize: FreePracticeLayout.maskNoteFont)),
    ]);
  }
}

/// Whether the run counts for SRS and rating: green when it does, ink with a
/// one-tap reset to the default when the setup is customised.
class _CountsStrip extends StatelessWidget {
  const _CountsStrip({required this.counts, required this.onReset});
  final bool counts;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: FreePracticeLayout.statusPadding,
      decoration: BoxDecoration(
        color: counts ? Palette.landSoft : Palette.pinkSoft,
        border: Border.all(color: Palette.ink, width: Strokes.control),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: counts
                  ? InkTag(s.countsTag, color: Palette.land, textColor: Palette.ink)
                  : InkTag(s.customTag),
            ),
            const SizedBox(height: Gaps.tight),
            Text(counts ? s.countsNote : s.customNote,
                style: const TextStyle(fontWeight: Weights.bold, fontSize: FreePracticeLayout.statusNoteFont)),
          ]),
        ),
        if (!counts) ...[
          const SizedBox(width: Gaps.panel),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: FreePracticeLayout.resetMinHeight),
            child: InkButton(
              onTap: onReset,
              border: Strokes.control,
              padding: FreePracticeLayout.resetPadding,
              semanticLabel: s.resetToDefaultLabel,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                MangaIcon(IconArt.refresh, size: FreePracticeLayout.resetIcon),
                const SizedBox(width: Gaps.tight),
                Text(s.resetToDefault,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: FreePracticeLayout.resetFont)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}
