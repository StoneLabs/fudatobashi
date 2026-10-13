import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_level.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import 'ankiren_sheet.dart';
import 'burst_button.dart';

/// 暗記練's free play: its setup sheet, then the game from its burst. The
/// setup is stored as it changes, so it is there next time.
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

/// One set of controls for a free game: a level key fills in its cards and
/// memorise time (a level the known cards cannot fill says why instead),
/// and touching a stepper makes the setup custom, from what the steppers
/// showed. The custom key brings back the last custom setup. Under them,
/// the level the setup scores as; then the start burst.
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

  /// The level chosen, or null for the custom setup.
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

  /// Makes the setup custom from what it is now, then [step]s it.
  void _stepCustom(VoidCallback step) => _change(() {
        final setup = _setup;
        _level = null;
        _perSide = setup.perSide.clamp(AnkirenTuning.customMinPerSide, _maxPerSide);
        _memoriseIndex = _nearest(setup.memorise);
        step();
      });

  Future<void> _start() async {
    await _save();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final setup = _setup;
    final memorise = _nearest(setup.memorise);
    return AnkirenSheet(
      title: s.freePlay,
      sub: s.other.freePlay,
      line: s.ankirenFreeNote,
      body: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SheetLabel(s.ankirenLevelRow, s.other.ankirenLevelRow),
          const SizedBox(height: AnkirenSheetLayout.labelGap),
          _levelKeys(s),
        ]),
        _Stepper(
          label: _SheetLabel(s.ankirenPerSide, s.other.ankirenPerSide),
          value: NumberedText(
            s.ankirenPerSideCount,
            [setup.perSide],
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.stepperUnitFont),
            numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont),
          ),
          onLess: setup.perSide > AnkirenTuning.customMinPerSide ? () => _stepCustom(() => _perSide--) : null,
          onMore: setup.perSide < _maxPerSide ? () => _stepCustom(() => _perSide++) : null,
        ),
        _Stepper(
          label: _SheetLabel(s.ankirenMemoriseTime, s.other.ankirenMemoriseTime),
          value: Text(formatMinutes(setup.memorise),
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont)),
          onLess: memorise > 0 ? () => _stepCustom(() => _memoriseIndex--) : null,
          onMore: memorise < _memorise.length - 1 ? () => _stepCustom(() => _memoriseIndex++) : null,
        ),
        _ScoredAs(setup.scoredLevel),
      ],
      footer: BurstButton(
        title: s.freeStart,
        sub: s.other.freeStart.toUpperCase(),
        onTap: setup.cards <= _known ? _start : null,
      ),
    );
  }

  /// Levels 0–10 and the custom setup, [AnkirenSheetLayout.keysPerRow] a
  /// row; a level the known cards cannot fill pops up why instead.
  Widget _levelKeys(S s) {
    final keys = <Widget>[
      for (final (l, level) in AnkirenLevels.all.indexed)
        Builder(
          builder: (context) => _Key(
            semanticLabel: s.ankirenLevelTag(l),
            chosen: _level == l,
            fits: level.cards <= _known,
            onTap: level.cards <= _known
                ? () => _change(() => _level = l)
                : () => BalloonPop.show(context, s.ankirenLevelNeeds(l, level.cards, _known),
                    size: AnkirenSheetLayout.lockBalloon, life: AnkirenSheetLayout.lockBalloonLife),
            top: Text('$l', style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.keyFont)),
            bottom: Text(s.ankirenKeyCards(level.perSide),
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keySubFont, color: Palette.mute)),
          ),
        ),
      _Key(
        semanticLabel: s.ankirenCustom,
        chosen: _level == null,
        fits: true,
        onTap: () => _change(() => _level = null),
        top: Text(s.ankirenCustom,
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keyCustomFont)),
        bottom: Text(s.other.ankirenCustom.toUpperCase(),
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keyCustomSubFont)),
      ),
    ];
    const perRow = AnkirenSheetLayout.keysPerRow;
    return Column(children: [
      for (var row = 0; row < keys.length; row += perRow) ...[
        if (row > 0) const SizedBox(height: AnkirenSheetLayout.keyGap),
        Row(children: [
          for (var i = row; i < row + perRow; i++) ...[
            if (i > row) const SizedBox(width: AnkirenSheetLayout.keyGap),
            Expanded(child: i < keys.length ? keys[i] : const SizedBox.shrink()),
          ],
        ]),
      ],
    ]);
  }
}

/// A section's label, with the other language's [sub] in small tracked
/// capitals, each breaking only between words.
class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text, this.sub);

  final String text, sub;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          Phrases.span(text),
          const TextSpan(text: ' '),
          Phrases.span(
            sub.toUpperCase(),
            style: const TextStyle(
              fontSize: AnkirenSheetLayout.labelSubFont,
              letterSpacing: AnkirenSheetLayout.labelSubTracking * AnkirenSheetLayout.labelSubFont,
            ),
          ),
        ]),
        style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.labelFont),
      );
}

/// One key of the level keys: Settings' choice colours (sun when [chosen],
/// desk grey when the known cards do not [fits] it), [top] over [bottom].
class _Key extends StatelessWidget {
  const _Key({
    required this.semanticLabel,
    required this.chosen,
    required this.fits,
    required this.onTap,
    required this.top,
    required this.bottom,
  });

  final String semanticLabel;
  final bool chosen, fits;
  final VoidCallback onTap;
  final Widget top, bottom;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: chosen,
        child: SizedBox(
          height: AnkirenSheetLayout.keyHeight,
          child: InkButton(
            onTap: onTap,
            color: chosen
                ? Palette.sun
                : fits
                    ? Palette.paper
                    : Palette.desk,
            border: chosen ? AnkirenSheetLayout.keyChosenBorder : AnkirenSheetLayout.keyBorder,
            padding: AnkirenSheetLayout.keyPadding,
            semanticLabel: semanticLabel,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DefaultTextStyle.merge(style: const TextStyle(height: 1), child: top),
                const SizedBox(height: AnkirenSheetLayout.keyLabelGap),
                DefaultTextStyle.merge(style: const TextStyle(height: 1), child: bottom),
              ]),
            ),
          ),
        ),
      );
}

/// A stepper: its [label] at the left, which gives way first, then − value
/// +; an end reached disables its button.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onLess, required this.onMore});

  final Widget label, value;
  final VoidCallback? onLess, onMore;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget button(String sign, String name, VoidCallback? onTap) => SizedBox.square(
          dimension: AnkirenSheetLayout.stepperButton,
          child: InkButton(
            onTap: onTap,
            color: onTap == null ? Palette.desk : Palette.paper,
            border: Strokes.control,
            semanticLabel: name,
            child: Text(sign,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperSignFont, height: 1)),
          ),
        );
    return Row(children: [
      Expanded(child: label),
      const SizedBox(width: AnkirenSheetLayout.stepperGap),
      button('−', s.ankirenLess, onLess),
      SizedBox(
        width: AnkirenSheetLayout.stepperValueWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AnkirenSheetLayout.stepperGap),
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: value)),
        ),
      ),
      button('+', s.ankirenMore, onMore),
    ]);
  }
}

/// The level a setup scores as, on a sun tag, and the same in the other
/// language, over a rule.
class _ScoredAs extends StatelessWidget {
  const _ScoredAs(this.level);

  final int level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Palette.ink, width: AnkirenSheetLayout.scoredRule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AnkirenSheetLayout.scoredTop),
        child: Wrap(
          spacing: AnkirenSheetLayout.scoredGap,
          runSpacing: AnkirenSheetLayout.scoredGap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.sun,
                border: Border.all(color: Palette.ink, width: AnkirenSheetLayout.scoredTagBorder),
              ),
              child: Padding(
                padding: AnkirenSheetLayout.scoredTagPadding,
                child: NumberedText(
                  s.ankirenScoredAs,
                  [level],
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.scoredFont),
                  numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.scoredNumber),
                ),
              ),
            ),
            NumberedText(
              s.other.ankirenScoredAs.toUpperCase(),
              [level],
              style: const TextStyle(fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.scoredFont, color: Palette.mute),
              numberStyle:
                  const TextStyle(fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.scoredFont, color: Palette.mute),
            ),
          ],
        ),
      ),
    );
  }
}
