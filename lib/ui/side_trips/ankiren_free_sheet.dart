import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';

/// 暗記練's free play: its setup sheet, then the game from its big button.
/// The setup is stored as it changes, so it is there next time.
Future<void> openAnkirenFree(BuildContext context) async {
  final start = await showMangaSheet<bool>(
    context,
    barrierColor: FreePracticeLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const AnkirenFreeSheet(),
  );
  if (start == true && context.mounted) {
    await startAnkirenFree(context, ProgressScope.read(context).settings.ankiren.freeSetup);
  }
}

/// A level preset (those the known cards cannot fill say why instead), or a
/// custom count of cards per side and memorise time; and the start button.
class AnkirenFreeSheet extends StatefulWidget {
  const AnkirenFreeSheet({super.key});

  @override
  State<AnkirenFreeSheet> createState() => _AnkirenFreeSheetState();
}

class _AnkirenFreeSheetState extends State<AnkirenFreeSheet> {
  late final Progress _progress;
  late final int _known;
  late final int _maxPerSide;
  final _memorise = AnkirenSetup.memoriseOptions;

  /// The preset chosen, or null for the custom setup.
  int? _level;
  late int _perSide;
  late int _memoriseIndex;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _known = _progress.knownCards.length;
    _maxPerSide = AnkirenSetup.maxCustomPerSide(_known) ?? AnkirenTuning.customMinPerSide;
    final saved = _progress.settings.ankiren;
    final maxLevel = AnkirenLevels.maxLevelFor(_known);
    final level = saved.freeLevel;
    _level = level == null || maxLevel == null ? null : math.min(level, maxLevel);
    _perSide = saved.customPerSide.clamp(AnkirenTuning.customMinPerSide, _maxPerSide);
    _memoriseIndex = _nearest(saved.customMemorise);
  }

  int _nearest(Duration d) {
    var best = 0;
    for (final (i, t) in _memorise.indexed) {
      if ((t - d).abs() < (_memorise[best] - d).abs()) best = i;
    }
    return best;
  }

  AnkirenSetup get _setup => _level == null
      ? AnkirenSetup.custom(perSide: _perSide, memorise: _memorise[_memoriseIndex])
      : AnkirenSetup.forLevel(_level!);

  Future<void> _save() =>
      _progress.updateSettings(_progress.settings.copyWith(ankiren: _progress.settings.ankiren.withFreeSetup(_setup)));

  void _change(VoidCallback change) {
    setState(change);
    _save();
  }

  Future<void> _start() async {
    await _save();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final setup = _setup;
    final fits = setup.cards <= _known;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(clipBehavior: Clip.none, children: [
              MangaPanel(
                shape: const PanelShape(topLeft: Offset(0, FreePracticeLayout.sheetCut)),
                padding: FreePracticeLayout.sheetPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [InkTag(s.freeSheetTag)]),
                          const SizedBox(height: Gaps.small),
                          Text(SideTrip.ankiren.label,
                              style: const TextStyle(
                                  fontFamily: Fonts.display,
                                  fontSize: FreePracticeLayout.title,
                                  height: TypeScale.displayLineHeight)),
                          const SizedBox(height: FreePracticeLayout.titleGap),
                          Text(s.ankirenSetupLine(setup.perSide, formatMinutes(setup.memorise)),
                              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.lineFont)),
                          const SizedBox(height: Gaps.section),
                          _heading(s.ankirenLevelRow),
                          const SizedBox(height: Gaps.small),
                          _levelChips(s),
                          if (_level == null) ...[
                            const SizedBox(height: Gaps.section),
                            _heading(s.ankirenPerSide),
                            const SizedBox(height: Gaps.tight),
                            _Stepper(
                              value: '$_perSide',
                              onLess: _perSide > AnkirenTuning.customMinPerSide ? () => _change(() => _perSide--) : null,
                              onMore: _perSide < _maxPerSide ? () => _change(() => _perSide++) : null,
                            ),
                            const SizedBox(height: Gaps.small),
                            _heading(s.ankirenMemoriseTime),
                            const SizedBox(height: Gaps.tight),
                            _Stepper(
                              value: formatMinutes(_memorise[_memoriseIndex]),
                              onLess: _memoriseIndex > 0 ? () => _change(() => _memoriseIndex--) : null,
                              onMore:
                                  _memoriseIndex < _memorise.length - 1 ? () => _change(() => _memoriseIndex++) : null,
                            ),
                          ],
                          const SizedBox(height: Gaps.section),
                          DashedBox(
                            padding: FreePracticeLayout.statusPadding,
                            child: Text.rich(Phrases.span(s.ankirenFreeNote),
                                style: const TextStyle(
                                    fontWeight: Weights.bold, fontSize: FreePracticeLayout.statusNoteFont)),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: Gaps.section),
                    SizedBox(
                      height: FreePracticeLayout.shoutHeight,
                      child: ShoutButton(
                        label: s.freeStart,
                        color: fits ? Palette.pink : Palette.desk,
                        onTap: fits ? _start : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Placed(FreePracticeLayout.tobi, child: Tobi(pose: TobiPose.fired)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) =>
      Text(text, style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.sectionFont));

  /// Levels 0–10 and Custom, one tap each; a level the known cards cannot
  /// fill pops up why instead.
  Widget _levelChips(S s) => Wrap(
        spacing: AnkirenSheetLayout.chipGap,
        runSpacing: AnkirenSheetLayout.chipGap,
        children: [
          for (final (l, level) in AnkirenLevels.all.indexed)
            Builder(
              builder: (context) => _Chip(
                label: '$l',
                semanticLabel: s.ankirenLevelTag(l),
                selected: _level == l,
                enabled: level.cards <= _known,
                onTap: level.cards <= _known
                    ? () => _change(() => _level = l)
                    : () => BalloonPop.show(context, s.ankirenLevelNeeds(l, level.cards, _known),
                        size: AnkirenSheetLayout.lockBalloon, life: AnkirenSheetLayout.lockBalloonLife),
              ),
            ),
          _Chip(
            label: s.ankirenCustom,
            selected: _level == null,
            enabled: true,
            onTap: () => _change(() => _level = null),
          ),
        ],
      );
}

/// One choice of the level row: sun-lit when chosen, greyed when the known
/// cards cannot fill it.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.enabled, required this.onTap, this.semanticLabel});

  final String label;
  final String? semanticLabel;
  final bool selected, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: semanticLabel ?? label,
        builder: (context, _) => Container(
          constraints: const BoxConstraints(
              minWidth: AnkirenSheetLayout.levelChip, minHeight: AnkirenSheetLayout.levelChip),
          padding: const EdgeInsets.symmetric(horizontal: Gaps.small),
          decoration: BoxDecoration(
            color: selected
                ? Palette.sun
                : enabled
                    ? Palette.paper
                    : Palette.desk,
            border: Border.all(color: Palette.ink, width: selected ? Strokes.button : Strokes.label),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Fonts.display,
                fontSize: AnkirenSheetLayout.levelChipFont,
                height: 1,
                color: enabled ? Palette.ink : Palette.mute,
              ),
            ),
          ),
        ),
      );
}

/// − value +: steps a custom setting through its allowed values; an end
/// reached disables its button.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onLess, required this.onMore});

  final String value;
  final VoidCallback? onLess, onMore;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget button(String sign, String label, VoidCallback? onTap) => SizedBox.square(
          dimension: AnkirenSheetLayout.stepperButton,
          child: InkButton(
            onTap: onTap,
            color: onTap == null ? Palette.desk : Palette.paper,
            border: Strokes.control,
            semanticLabel: label,
            child: Text(sign,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperFont, height: 1)),
          ),
        );
    return Row(children: [
      button('−', s.ankirenLess, onLess),
      SizedBox(
        width: AnkirenSheetLayout.stepperValueWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperFont, height: 1)),
        ),
      ),
      button('+', s.ankirenMore, onMore),
    ]);
  }
}
