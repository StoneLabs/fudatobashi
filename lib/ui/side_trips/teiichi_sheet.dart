import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/teiichi.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';
import 'ankiren_sheet.dart';
import 'burst_button.dart';

/// 定位置's custom game sheet, opened on [current]: the setup started, or
/// null when it is closed.
Future<TeiichiSetup?> pickTeiichiCustom(BuildContext context, TeiichiSetup current) => showMangaSheet<TeiichiSetup>(
      context,
      barrierColor: FreePracticeLayout.barrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => TeiichiSheet(initial: current),
    );

/// Guest mode: the same sheet over all the cards, then a game that records
/// nothing. The guest's last setup is kept only while the app runs.
Future<void> openTeiichiGuest(BuildContext context) async {
  final setup = await showMangaSheet<TeiichiSetup>(
    context,
    barrierColor: FreePracticeLayout.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const TeiichiSheet(guest: true),
  );
  if (setup != null && context.mounted) await startTeiichiGuest(context, setup);
}

/// A custom 定位置 game: its cards, by a quick pick or a stepper, from
/// [TeiichiTuning.minCards] up to the usual game's, never more than the
/// known cards (all of them for a [guest]); then its rows. Rows that cannot
/// hold the cards are grey, with a padlock and how few they hold; more
/// cards than the rows hold take more rows, and the sheet says so. Then
/// what counts for the best placing time, and the burst that starts it.
class TeiichiSheet extends StatefulWidget {
  const TeiichiSheet({super.key, this.initial, this.guest = false});

  /// The setup it opens on; the usual game when not given, and a guest's
  /// last one for a guest.
  final TeiichiSetup? initial;
  final bool guest;

  @override
  State<TeiichiSheet> createState() => _TeiichiSheetState();
}

class _TeiichiSheetState extends State<TeiichiSheet> {
  /// The guest's last setup, while the app runs.
  static TeiichiSetup? _guestSetup;

  late final int _known;
  late final int _most;
  late int _cards;
  late int _rows;

  /// The rows the cards just took, when the player chose fewer.
  int? _wentUpFrom;

  @override
  void initState() {
    super.initState();
    _known = widget.guest ? poems.all.length : ProgressScope.read(context).knownCards.length;
    _most = TeiichiSetup.maxCards(_known) ?? TeiichiTuning.minCards;
    final last = widget.guest ? _guestSetup ?? TeiichiSetup.usual : widget.initial ?? TeiichiSetup.usual;
    _cards = last.cards.clamp(TeiichiTuning.minCards, _most);
    _rows = TeiichiSetup.rowsFor(_cards, last.rows);
  }

  TeiichiSetup get _setup => TeiichiSetup(cards: _cards, rows: _rows);

  void _setCards(int cards) => setState(() {
        final wanted = _rows;
        _cards = cards;
        _rows = TeiichiSetup.rowsFor(cards, wanted);
        _wentUpFrom = _rows == wanted ? null : wanted;
      });

  void _start() {
    if (widget.guest) _guestSetup = _setup;
    Navigator.pop(context, _setup);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final wentUpFrom = _wentUpFrom;
    const label = TextStyle(fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.lineFont, color: Palette.mute);
    const note = TextStyle(fontWeight: Weights.bold, fontSize: TeiichiSheetLayout.noteFont);
    return AnkirenSheet(
      title: widget.guest ? s.ankirenGuestMode : s.teiichiCustomTitle,
      sub: widget.guest ? s.sub?.ankirenGuestMode : s.sub?.teiichiCustomTitle,
      line: widget.guest ? s.teiichiGuestLine : null,
      body: [
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
                top: Text('$n',
                    style: const TextStyle(fontFamily: Fonts.display, fontSize: TeiichiSheetLayout.cardKeyFont)),
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
      ],
      footer: BurstButton(title: s.freeStart, sub: s.sub?.freeStart.toUpperCase(), onTap: _start),
    );
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
