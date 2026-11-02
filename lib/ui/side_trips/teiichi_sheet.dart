import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/karafuda.dart';
import '../../domain/level_ladder.dart';
import '../../domain/side_trips.dart';
import '../../domain/teiichi.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import 'ankiren_sheet.dart';
import 'burst_button.dart';

/// 定位置's level sheet, opened on [current]: the setup confirmed, or null
/// when it is closed. A custom setup confirmed is kept for next time.
Future<TeiichiSetup?> pickTeiichiLevel(BuildContext context, TeiichiSetup current) => showMangaSheet<TeiichiSetup>(
      context,
      barrierColor: FreePracticeLayout.barrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => TeiichiSheet(initial: current),
    );

/// Guest mode: the same sheet with every level and the custom game open
/// and dealt from all the cards, then a game that records nothing. The
/// guest's last setup is kept only while the app runs.
Future<void> openTeiichiGuest(BuildContext context) async {
  final setup = await showMangaSheet<TeiichiSetup>(
    context,
    barrierColor: FreePracticeLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const TeiichiSheet(guest: true),
  );
  if (setup != null && context.mounted) await startTeiichiGuest(context, setup);
}

/// The level keys, the last the custom game on the levels' scale; then a
/// level's facts, or the custom game's controls: its cards, by a quick pick
/// or a stepper, from [TeiichiTuning.minCards] up to the usual game's,
/// never more than the known cards (all of them for a [guest]); its
/// からふだ, as many as the formula gives the cards until stepped, from none
/// up to [Karafuda.customMax]; then its rows. Rows that cannot hold the
/// cards are grey, with a padlock and how few they hold; more cards than
/// the rows hold take more rows, and the sheet says so. Then what counts
/// for the best placing time. Then the burst, Confirm (Start for a [guest]),
/// which closes the sheet with the setup.
///
/// The owner's levels open one at a time (see [LevelLadder]): a level still
/// shut, and the custom game until it opens, are chained and say what opens
/// them when tapped; a cleared level has a check, and once every level is,
/// the sheet says so. A [guest] has them all open, and nothing is stored.
class TeiichiSheet extends StatefulWidget {
  const TeiichiSheet({super.key, this.initial, this.guest = false});

  /// The setup it opens on; the next level to clear when not given, and a
  /// guest's last one for a guest.
  final TeiichiSetup? initial;
  final bool guest;

  @override
  State<TeiichiSheet> createState() => _TeiichiSheetState();
}

class _TeiichiSheetState extends State<TeiichiSheet> {
  /// The guest's last setup, while the app runs.
  static TeiichiSetup? _guestSetup;

  late final Progress _progress;
  late final int _known;
  late final int _most;

  /// The owner's levels; null for a guest, who has them all.
  late final LevelLadder? _ladder;

  /// The level chosen, or null for the custom game.
  int? _level;
  late int _cards;
  late int _rows;
  late int _karafuda;

  /// The rows the cards just took, when the player chose fewer.
  int? _wentUpFrom;

  bool _isOpen(int level) => _ladder?.isOpen(level) ?? true;
  bool get _customOpen => _ladder?.customOpen ?? true;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    final ladder = _ladder = widget.guest ? null : _progress.sideTripsHub()[SideTrip.teiichi].ladder;
    _known = widget.guest ? poems.all.length : _progress.knownCards.length;
    _most = TeiichiSetup.maxCards(_known) ?? TeiichiTuning.minCards;
    final next = ladder?.next ?? TeiichiLevels.top;
    final last = widget.guest
        ? _guestSetup ?? TeiichiSetup.forLevel(TeiichiLevels.first)
        : widget.initial ?? TeiichiSetup.forLevel(next);
    _level = last.level ?? (_customOpen ? null : next);
    final settings = _progress.settings;
    final saved = TeiichiSetup(
      cards: settings.teiichiCards,
      rows: settings.teiichiRows,
      karafuda: settings.teiichiKarafuda ?? Karafuda.forTeiichi(settings.teiichiCards),
    );
    final custom = (last.custom ? last : (widget.guest ? TeiichiSetup.usual : saved)).fitted(_known);
    _cards = custom.cards;
    _rows = custom.rows;
    _karafuda = custom.karafuda;
  }

  TeiichiSetup get _setup => _level == null
      ? TeiichiSetup(cards: _cards, rows: _rows, karafuda: _karafuda)
      : TeiichiSetup.forLevel(_level!);

  /// The most からふだ [cards] may call (see [Karafuda.customMax]).
  int _maxKarafuda(int cards) => Karafuda.customMax(cards, _known);

  /// A new card count takes the からふだ the formula gives it.
  void _setCards(int cards) => setState(() {
        final wanted = _rows;
        _cards = cards;
        _rows = TeiichiSetup.rowsFor(cards, wanted);
        _wentUpFrom = _rows == wanted ? null : wanted;
        _karafuda = Karafuda.forTeiichi(cards).clamp(0, _maxKarafuda(cards));
      });

  void _confirm() {
    final setup = _setup;
    if (widget.guest) {
      _guestSetup = setup;
    } else if (setup.custom) {
      unawaited(_progress.updateSettings(_progress.settings
          .copyWith(teiichiCards: setup.cards, teiichiRows: setup.rows, teiichiKarafuda: setup.karafuda)));
    }
    Navigator.pop(context, setup);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final setup = _setup;
    final ladder = _ladder;
    final level = _level;
    return AnkirenSheet(
      title: widget.guest ? s.ankirenGuestMode : s.ankirenSelectLevel,
      sub: widget.guest ? s.sub?.ankirenGuestMode : s.sub?.ankirenSelectLevel,
      line: widget.guest ? s.teiichiGuestLine : null,
      body: [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SheetLabel(s.ankirenLevelRow, s.sub?.ankirenLevelRow),
          const SizedBox(height: AnkirenSheetLayout.labelGap),
          _levelKeys(s),
        ]),
        if (ladder != null)
          SheetUnlockNote(allCleared: ladder.allCleared, line: s.teiichiUnlockLine(AnkirenTuning.strikesOut)),
        if (level != null) _LevelFacts(setup) else ..._customControls(s),
      ],
      footer: BurstButton(
        title: widget.guest ? s.freeStart : s.ankirenConfirm,
        sub: (widget.guest ? s.sub?.freeStart : s.sub?.ankirenConfirm)?.toUpperCase(),
        onTap: setup.calls <= _known ? _confirm : null,
      ),
    );
  }

  /// Every level and then the custom game, [TeiichiSheetLayout.keysPerRow]
  /// a row: one still shut chained, saying what opens it; a cleared one
  /// checked.
  Widget _levelKeys(S s) {
    void balloon(BuildContext context, String message) => BalloonPop.show(context, message,
        size: AnkirenSheetLayout.lockBalloon, life: AnkirenSheetLayout.lockBalloonLife);
    const number = TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.keyFont);
    const sub = TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keySubFont, color: Palette.mute);
    return SheetKeyGrid([
      for (var l = TeiichiLevels.first; l <= TeiichiLevels.top; l++)
        Builder(
          builder: (context) => SheetKey(
            semanticLabel: s.ankirenLevelTag(l),
            chosen: _level == l,
            fits: true,
            locked: !_isOpen(l),
            cleared: _ladder?.isCleared(l) ?? false,
            onTap: _isOpen(l)
                ? () => setState(() => _level = l)
                : () => balloon(context, s.ankirenLevelLocked(l - 1, l)),
            top: Text('$l', style: number),
            bottom: Text(s.teiichiKeyCards(TeiichiLevels.of(l).cards), style: sub),
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
              ? () => setState(() => _level = null)
              : () => balloon(context, s.ankirenCustomLocked(TeiichiTuning.customAfterLevel)),
          top: Text(s.ankirenCustom,
              style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keyCustomFont)),
          bottom: s.sub == null
              ? null
              : Text(s.sub!.ankirenCustom.toUpperCase(),
                  style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.keyCustomSubFont)),
        ),
      ),
    ], perRow: TeiichiSheetLayout.keysPerRow);
  }

  List<Widget> _customControls(S s) {
    final wentUpFrom = _wentUpFrom;
    const label = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.lineFont, color: Palette.mute);
    const note = TextStyle(fontWeight: Weights.bold, fontSize: TeiichiSheetLayout.noteFont);
    return [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: SheetLabel(s.ankirenCards, s.sub?.ankirenCards)),
          if (!widget.guest) NumberedText(s.teiichiFromKnown, [_known], style: label),
        ]),
        const SizedBox(height: AnkirenSheetLayout.labelGap),
        _keys([
          for (final n in TeiichiTuning.cardKeys)
            SheetKey(
              semanticLabel: s.cardsCount(n),
              chosen: _cards == n,
              fits: n <= _most,
              locked: false,
              cleared: false,
              onTap: n <= _most ? () => _setCards(n) : () {},
              top: Text('$n', style: const TextStyle(fontFamily: Fonts.display, fontSize: TeiichiSheetLayout.cardKeyFont)),
            ),
        ]),
      ]),
      SheetStepper(
        label: SheetLabel(s.teiichiAnyNumber, null),
        value: Text('$_cards',
            style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont)),
        onLess: _cards > TeiichiTuning.minCards ? () => _setCards(_cards - 1) : null,
        onMore: _cards < _most ? () => _setCards(_cards + 1) : null,
      ),
      SheetStepper(
        label: SheetLabel(s.karafudaStepper, null),
        value: _karafuda == 0
            ? Text(s.karafudaOff,
                style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenSheetLayout.stepperUnitFont))
            : Text('$_karafuda',
                style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenSheetLayout.stepperValueFont)),
        onLess: _karafuda > 0 ? () => setState(() => _karafuda--) : null,
        onMore: _karafuda < _maxKarafuda(_cards) ? () => setState(() => _karafuda++) : null,
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SheetLabel(s.teiichiRows, s.sub?.teiichiRows),
        const SizedBox(height: AnkirenSheetLayout.labelGap),
        _keys([for (var rows = TeiichiTuning.rows; rows >= 1; rows--) _rowsKey(s, rows)]),
      ]),
      if (wentUpFrom != null)
        Text.rich(TextSpan(children: [
          Phrases.span(s.teiichiRowsWentUp(_rows),
              style: const TextStyle(backgroundColor: TeiichiSheetLayout.wentUpMark, color: Palette.ink)),
          const TextSpan(text: ' '),
          Phrases.span(s.teiichiRowsHold(wentUpFrom, TeiichiSetup.mostCards(wentUpFrom))),
        ]), style: note),
      Text.rich(Phrases.span(s.teiichiBestNote(TeiichiTuning.cards)), style: note),
    ];
  }

  /// [keys] side by side, as wide as each other.
  static Widget _keys(List<Widget> keys) => Row(children: [
        for (final (i, key) in keys.indexed) ...[
          if (i > 0) const SizedBox(width: AnkirenSheetLayout.keyGap),
          Expanded(child: key),
        ],
      ]);

  /// The key for [rows] rows: how many cards they hold, or, too few for the
  /// cards chosen, grey with a padlock; a tap on it then says why.
  Widget _rowsKey(S s, int rows) {
    final most = TeiichiSetup.mostCards(rows);
    final allowed = TeiichiSetup.allows(cards: _cards, rows: rows);
    final ink = allowed ? Palette.ink : Palette.mute;
    final sub = TextStyle(fontWeight: Weights.black, fontSize: TeiichiSheetLayout.rowKeySubFont, color: ink);
    return SizedBox(
      height: TeiichiSheetLayout.rowKeyHeight,
      child: Builder(
        builder: (context) => SheetKey(
          semanticLabel: s.teiichiRowsKey(rows),
          chosen: _rows == rows,
          fits: allowed,
          locked: false,
          cleared: false,
          onTap: allowed
              ? () => setState(() {
                    _rows = rows;
                    _wentUpFrom = null;
                  })
              : () => BalloonPop.show(context, s.teiichiRowsHold(rows, most),
                  size: AnkirenSheetLayout.lockBalloon, life: AnkirenSheetLayout.lockBalloonLife),
          top: NumberedText(
            s.teiichiRowsKey(rows),
            [rows],
            style: TextStyle(fontFamily: Fonts.display, fontSize: TeiichiSheetLayout.rowKeyFont, color: ink),
          ),
          bottom: rows == TeiichiTuning.rows
              ? Text(s.teiichiRowsUpTo(most), style: sub)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!allowed) ...[
                    MangaIcon(IconArt.lock, size: TeiichiSheetLayout.rowKeyLock, color: ink),
                    const SizedBox(width: TeiichiSheetLayout.rowKeyLockGap),
                  ],
                  Text(s.teiichiRowsAtMost(most), style: sub),
                ]),
        ),
      ),
    );
  }
}

/// A level's setup in a line: its cards, rows and most time, and its
/// からふだ when it calls any.
class _LevelFacts extends StatelessWidget {
  const _LevelFacts(this.setup);

  final TeiichiSetup setup;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Text(
      [
        s.cardsCount(setup.cards),
        s.teiichiRowsKey(setup.rows),
        s.teiichiToPlace(formatMinutes(setup.limit!)),
        if (setup.karafuda > 0) s.karafudaCount(setup.karafuda),
      ].join(' · '),
      style: const TextStyle(fontWeight: Weights.black, fontSize: TeiichiSheetLayout.noteFont),
    );
  }
}
