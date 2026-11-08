import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../domain/ankiren_level.dart';
import '../../domain/karafuda.dart';
import '../../domain/level_ladder.dart';
import '../../domain/side_trips.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import 'trip_sheet.dart';
import 'burst_button.dart';

/// 暗記練's level sheet, opened on [current]: the setup confirmed, or null
/// when it is closed. The setup is stored as it changes, which keeps the
/// custom one for next time.
Future<AnkirenSetup?> pickAnkirenFree(BuildContext context, AnkirenSetup current) => showMangaSheet<AnkirenSetup>(
      context,
      barrierColor: FreePracticeLayout.barrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => AnkirenFreeSheet(initial: current),
    );

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
/// which is not scored. Then the burst, Confirm (Start for a [guest]),
/// which closes the sheet with the setup.
///
/// The owner's levels open one at a time (see [LevelLadder]): a level
/// still shut, and the custom setups until they open, are chained, and say
/// what opens them when tapped; a cleared level has a check, and once every
/// level is, the sheet says so. A level the known cards cannot fill says
/// why instead. A [guest] has every level and the custom setups open, dealt
/// from all the cards, and nothing is stored.
class AnkirenFreeSheet extends StatefulWidget {
  const AnkirenFreeSheet({super.key, this.initial, this.guest = false});

  /// The setup it opens on; the last one stored when not given, and a
  /// guest's last one for a guest.
  final AnkirenSetup? initial;
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
  late final LevelLadder? _ladder;
  final _memorise = AnkirenSetup.memoriseOptions;

  /// The level chosen, or null for the custom setup.
  int? _level;
  late int _perSide;
  late int _memoriseIndex;
  late int _karafuda;

  /// The most からふだ a custom field of [perSide] may call (see
  /// [Karafuda.customMax]).
  int _maxKarafuda(int perSide) => Karafuda.customMax(2 * perSide, _known);

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
    final last = widget.guest ? _guestSetup ?? AnkirenSetup.forLevel(0) : widget.initial ?? saved.freeSetup;
    final maxLevel = AnkirenLevels.maxLevelFor(_known) ?? 0;
    final level = last.level ?? (_customOpen ? null : ladder!.next ?? AnkirenLevels.top);
    _level = level == null ? null : math.min(math.min(level, ladder?.open ?? level), maxLevel);
    _perSide = (last.custom ? last.perSide : saved.customPerSide).clamp(AnkirenTuning.customMinPerSide, _maxPerSide);
    _memoriseIndex = _nearest(last.custom ? last.memorise : saved.customMemorise);
    final karafuda = last.custom ? last.karafuda : saved.customKarafuda ?? AnkirenSetup.customKarafuda(_perSide);
    _karafuda = karafuda.clamp(0, _maxKarafuda(_perSide));
  }

  int _nearest(Duration d) {
    var best = 0;
    for (final (i, t) in _memorise.indexed) {
      if ((t - d).abs() < (_memorise[best] - d).abs()) best = i;
    }
    return best;
  }

  AnkirenSetup get _setup => _level == null
      ? AnkirenSetup.custom(perSide: _perSide, memorise: _memorise[_memoriseIndex], karafuda: _karafuda)
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
        _karafuda = setup.karafuda.clamp(0, _maxKarafuda(_perSide));
        step();
      });

  /// A new card count takes the からふだ the formula gives it.
  void _stepPerSide(int by) => _stepCustom(() {
        _perSide += by;
        _karafuda = AnkirenSetup.customKarafuda(_perSide).clamp(0, _maxKarafuda(_perSide));
      });

  Future<void> _confirm() async {
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
    return TripSheet(
      title: widget.guest ? s.ankirenGuestMode : s.ankirenSelectLevel,
      sub: widget.guest ? s.sub?.ankirenGuestMode : s.sub?.ankirenSelectLevel,
      line: widget.guest ? s.ankirenGuestLine : null,
      body: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SheetLabel(s.ankirenLevelRow, s.sub?.ankirenLevelRow),
          const SizedBox(height: AnkirenSheetLayout.labelGap),
          _levelKeys(s),
        ]),
        if (ladder != null)
          SheetUnlockNote(
            allCleared: ladder.allCleared,
            line: s.ankirenUnlockLine(AnkirenTuning.strikesOut),
          ),
        // The steppers' labels go without the English, which would wrap them.
        SheetStepper(
          label: SheetLabel(s.ankirenPerSide, null),
          value: NumberedText(
            s.ankirenPerSideCount,
            [setup.perSide],
            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.stepperUnitFont),
            numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont),
          ),
          onLess: steps && setup.perSide > AnkirenTuning.customMinPerSide ? () => _stepPerSide(-1) : null,
          onMore: steps && setup.perSide < _maxPerSide ? () => _stepPerSide(1) : null,
        ),
        SheetStepper(
          label: SheetLabel(s.karafudaStepper, null),
          value: setup.karafuda == 0
              ? Text(s.karafudaOff,
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.stepperUnitFont))
              : Text('${setup.karafuda}',
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont)),
          onLess: steps && setup.karafuda > 0 ? () => _stepCustom(() => _karafuda--) : null,
          onMore: steps && setup.karafuda < _maxKarafuda(setup.perSide) ? () => _stepCustom(() => _karafuda++) : null,
        ),
        SheetStepper(
          label: SheetLabel(s.ankirenMemoriseTime, null),
          value: Text(formatMinutes(setup.memorise),
              style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont)),
          onLess: steps && memorise > 0 ? () => _stepCustom(() => _memoriseIndex--) : null,
          onMore: steps && memorise < _memorise.length - 1 ? () => _stepCustom(() => _memoriseIndex++) : null,
        ),
      ],
      footer: BurstButton(
        title: widget.guest ? s.freeStart : s.ankirenConfirm,
        sub: (widget.guest ? s.sub?.freeStart : s.sub?.ankirenConfirm)?.toUpperCase(),
        onTap: setup.calls <= _known ? _confirm : null,
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
          builder: (context) => SheetKey(
            semanticLabel: s.ankirenLevelTag(l),
            chosen: _level == l,
            fits: AnkirenLevels.needs(l) <= _known,
            locked: !_isOpen(l),
            cleared: _ladder?.isCleared(l) ?? false,
            onTap: !_isOpen(l)
                ? () => balloon(context, s.ankirenLevelLocked(l - 1, l))
                : AnkirenLevels.needs(l) <= _known
                    ? () => _change(() => _level = l)
                    : () => balloon(context, s.ankirenLevelNeeds(l, AnkirenLevels.needs(l), _known)),
            top: Text('$l', style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.keyFont)),
            bottom: Text(s.ankirenKeyCards(level.perSide),
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keySubFont, color: Palette.mute)),
          ),
        ),
      Builder(
        builder: (context) => SheetKey(
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
    return SheetKeyGrid(keys);
  }
}
