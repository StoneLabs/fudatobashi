import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../ankiren/ankiren_strikes.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import '../shell/tab_chains.dart';
import 'ankiren_sheet.dart';
import 'burst_button.dart';

/// 暗記練's free play: its setup sheet, then the game from its burst. The
/// setup is stored as it changes, so it is there next time.
Future<void> openAnkirenFree(BuildContext context) async {
  final setup = await showMangaSheet<AnkirenSetup>(
    context,
    barrierColor: FreePracticeLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const AnkirenFreeSheet(),
  );
  if (setup != null && context.mounted) await startAnkirenFree(context, setup);
}

/// Guest mode: the same sheet with every level and the custom setups open
/// and dealt from all the cards, then a game that records nothing. The
/// guest's last setup is kept only while the app runs.
Future<void> openAnkirenGuest(BuildContext context) async {
  final setup = await showMangaSheet<AnkirenSetup>(
    context,
    barrierColor: FreePracticeLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const AnkirenFreeSheet(guest: true),
  );
  if (setup != null && context.mounted) await startAnkirenGuest(context, setup);
}

/// One set of controls for a free game: a level key fills in its cards and
/// memorise time, and touching a stepper makes the setup custom, from what
/// the steppers showed. The custom key brings back the last custom setup,
/// which is not scored. Then the start burst, which closes the sheet with
/// the setup.
///
/// The owner's levels open one at a time (see [AnkirenLadder]): a level
/// still shut, and the custom setups until they open, are chained, and say
/// what opens them when tapped; a cleared level has a check, and once every
/// level is, the sheet says so. A level the known cards cannot fill says
/// why instead. A [guest] has every level and the custom setups open, dealt
/// from all the cards, and nothing is stored.
class AnkirenFreeSheet extends StatefulWidget {
  const AnkirenFreeSheet({super.key, this.guest = false});

  final bool guest;

  @override
  State<AnkirenFreeSheet> createState() => _AnkirenFreeSheetState();
}

class _AnkirenFreeSheetState extends State<AnkirenFreeSheet> {
  /// The guest's last setup, while the app runs.
  static AnkirenSetup? _guestSetup;

  late final Progress _progress;
  late final int _known;
  late final int _maxPerSide;

  /// The owner's levels; null for a guest, who has them all.
  late final AnkirenLadder? _ladder;
  final _memorise = AnkirenSetup.memoriseOptions;

  /// The level chosen, or null for the custom setup.
  int? _level;
  late int _perSide;
  late int _memoriseIndex;

  bool _isOpen(int level) => _ladder?.isOpen(level) ?? true;
  bool get _customOpen => _ladder?.customOpen ?? true;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    final ladder = _ladder = widget.guest ? null : _progress.sideTripsHub()[SideTrip.ankiren].ladder;
    _known = widget.guest ? poems.all.length : _progress.knownCards.length;
    _maxPerSide = AnkirenSetup.maxCustomPerSide(_known) ?? AnkirenTuning.customMinPerSide;
    final saved = _progress.settings.ankiren;
    final last = widget.guest ? _guestSetup ?? AnkirenSetup.forLevel(0) : saved.freeSetup;
    final maxLevel = AnkirenLevels.maxLevelFor(_known) ?? 0;
    final level = last.level ?? (_customOpen ? null : ladder!.next ?? AnkirenLevels.top);
    _level = level == null ? null : math.min(math.min(level, ladder?.open ?? level), maxLevel);
    _perSide = (last.custom ? last.perSide : saved.customPerSide).clamp(AnkirenTuning.customMinPerSide, _maxPerSide);
    _memoriseIndex = _nearest(last.custom ? last.memorise : saved.customMemorise);
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

  Future<void> _save() async {
    if (widget.guest) {
      _guestSetup = _setup;
      return;
    }
    await _progress.updateSettings(
        _progress.settings.copyWith(ankiren: _progress.settings.ankiren.withFreeSetup(_setup)));
  }

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
    final setup = _setup;
    await _save();
    if (mounted) Navigator.pop(context, setup);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final setup = _setup;
    final memorise = _nearest(setup.memorise);
    final steps = _customOpen;
    final ladder = _ladder;
    return AnkirenSheet(
      title: widget.guest ? s.ankirenGuestMode : s.freePlay,
      sub: widget.guest ? s.sub?.ankirenGuestMode : s.sub?.freePlay,
      line: widget.guest ? s.ankirenGuestLine : null,
      body: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SheetLabel(s.ankirenLevelRow, s.sub?.ankirenLevelRow),
          const SizedBox(height: AnkirenSheetLayout.labelGap),
          _levelKeys(s),
        ]),
        if (ladder != null) _UnlockNote(allCleared: ladder.allCleared),
        _Stepper(
          label: _SheetLabel(s.ankirenPerSide, s.sub?.ankirenPerSide),
          value: NumberedText(
            s.ankirenPerSideCount,
            [setup.perSide],
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.stepperUnitFont),
            numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont),
          ),
          onLess: steps && setup.perSide > AnkirenTuning.customMinPerSide ? () => _stepCustom(() => _perSide--) : null,
          onMore: steps && setup.perSide < _maxPerSide ? () => _stepCustom(() => _perSide++) : null,
        ),
        _Stepper(
          label: _SheetLabel(s.ankirenMemoriseTime, s.sub?.ankirenMemoriseTime),
          value: Text(formatMinutes(setup.memorise),
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont)),
          onLess: steps && memorise > 0 ? () => _stepCustom(() => _memoriseIndex--) : null,
          onMore: steps && memorise < _memorise.length - 1 ? () => _stepCustom(() => _memoriseIndex++) : null,
        ),
      ],
      footer: BurstButton(
        title: s.freeStart,
        sub: s.sub?.freeStart.toUpperCase(),
        onTap: setup.cards <= _known ? _start : null,
      ),
    );
  }

  /// Levels 0–10 and the custom setup, [AnkirenSheetLayout.keysPerRow] a
  /// row: one still shut chained, saying what opens it; one the known cards
  /// cannot fill saying why; a cleared one checked.
  Widget _levelKeys(S s) {
    void balloon(BuildContext context, String message) => BalloonPop.show(context, message,
        size: AnkirenSheetLayout.lockBalloon, life: AnkirenSheetLayout.lockBalloonLife);
    final keys = <Widget>[
      for (final (l, level) in AnkirenLevels.all.indexed)
        Builder(
          builder: (context) => _Key(
            semanticLabel: s.ankirenLevelTag(l),
            chosen: _level == l,
            fits: level.cards <= _known,
            locked: !_isOpen(l),
            cleared: _ladder?.isCleared(l) ?? false,
            onTap: !_isOpen(l)
                ? () => balloon(context, s.ankirenLevelLocked(l - 1, l))
                : level.cards <= _known
                    ? () => _change(() => _level = l)
                    : () => balloon(context, s.ankirenLevelNeeds(l, level.cards, _known)),
            top: Text('$l', style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.keyFont)),
            bottom: Text(s.ankirenKeyCards(level.perSide),
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keySubFont, color: Palette.mute)),
          ),
        ),
      Builder(
        builder: (context) => _Key(
          semanticLabel: s.ankirenCustom,
          chosen: _level == null,
          fits: true,
          locked: !_customOpen,
          cleared: false,
          onTap: _customOpen
              ? () => _change(() => _level = null)
              : () => balloon(context, s.ankirenCustomLocked(AnkirenTuning.customAfterLevel)),
          top: Text(s.ankirenCustom,
              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keyCustomFont)),
          bottom: s.sub == null
              ? null
              : Text(s.sub!.ankirenCustom.toUpperCase(),
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keyCustomSubFont)),
        ),
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

/// How the levels open, by a struck card; or, once every level is
/// cleared, the all-clear stamp and a cheer.
class _UnlockNote extends StatelessWidget {
  const _UnlockNote({required this.allCleared});

  final bool allCleared;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.noteFont);
    return Row(children: [
      if (allCleared)
        Sticker(
          tilt: AnkirenSheetLayout.stampTilt,
          child: Text(s.ankirenAllClearStamp,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stampFont, height: 1)),
        )
      else
        const AnkirenStrikes(strikes: 1, count: 1, cardHeight: AnkirenSheetLayout.noteCard),
      const SizedBox(width: AnkirenSheetLayout.noteGap),
      Expanded(
        child: Text.rich(
            Phrases.span(allCleared ? s.ankirenAllCleared : s.ankirenUnlockLine(AnkirenTuning.strikesOut)),
            style: style),
      ),
    ]);
  }
}

/// A section's label, with the other language's [sub] in small tracked
/// capitals, each breaking only between words.
class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text, this.sub);

  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          Phrases.span(text),
          if (sub != null) ...[
            const TextSpan(text: ' '),
            Phrases.span(
              sub!.toUpperCase(),
              style: const TextStyle(
                fontSize: AnkirenSheetLayout.labelSubFont,
                letterSpacing: AnkirenSheetLayout.labelSubTracking * AnkirenSheetLayout.labelSubFont,
              ),
            ),
          ],
        ]),
        style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.labelFont),
      );
}

/// One key of the level keys: Settings' choice colours (sun when [chosen],
/// desk grey when the known cards do not [fits] it or it is [locked]),
/// [top] over [bottom]; chained when [locked], checked when [cleared].
class _Key extends StatelessWidget {
  const _Key({
    required this.semanticLabel,
    required this.chosen,
    required this.fits,
    required this.locked,
    required this.cleared,
    required this.onTap,
    required this.top,
    this.bottom,
  });

  final String semanticLabel;
  final bool chosen, fits, locked, cleared;
  final VoidCallback onTap;
  final Widget top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: chosen,
        child: SizedBox(
          height: AnkirenSheetLayout.keyHeight,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: InkButton(
                onTap: onTap,
                color: chosen
                    ? Palette.sun
                    : fits && !locked
                        ? Palette.paper
                        : Palette.desk,
                border: chosen ? AnkirenSheetLayout.keyChosenBorder : AnkirenSheetLayout.keyBorder,
                padding: AnkirenSheetLayout.keyPadding,
                semanticLabel: semanticLabel,
                child: Opacity(
                  opacity: locked ? AnkirenSheetLayout.lockedOpacity : 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      DefaultTextStyle.merge(style: const TextStyle(height: 1), child: top),
                      if (bottom != null) ...[
                        const SizedBox(height: AnkirenSheetLayout.keyLabelGap),
                        DefaultTextStyle.merge(style: const TextStyle(height: 1), child: bottom!),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
            if (locked) const Positioned.fill(child: ClipRect(child: TabChains(scale: AnkirenSheetLayout.chainScale))),
            if (cleared)
              const Positioned(
                right: -AnkirenSheetLayout.checkOut,
                top: -AnkirenSheetLayout.checkOut,
                child: ClearedCheck(size: AnkirenSheetLayout.check),
              ),
          ]),
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
