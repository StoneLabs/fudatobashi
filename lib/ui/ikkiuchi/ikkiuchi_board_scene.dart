import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_call.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_send.dart';
import 'ikkiuchi_arrange_flow.dart';
import 'ikkiuchi_board_layout.dart';
import 'ikkiuchi_card_faces.dart';
import 'ikkiuchi_reader.dart';
import 'ikkiuchi_send_flow.dart';

/// The 一騎打ち board as it is drawn: its [layout], the board running on it,
/// the call shown on the band and read out by the [reader], a card marked,
/// and the wind switch. Every change repaints the board's painter.
///
/// A read is of a card on the field ([callCard]) or of a からふだ
/// ([callKarafuda]); either way the board notes the player's faults
/// (`IkkiuchiBoard.playerFaults`) until the next read.
///
/// It takes the player's finger ([pointer]): one finger pushes the cards
/// about, and [IkkiuchiPlayTuning.tidyWait] after it lifts the cards it
/// stirred glide home. With [sides] it plays the 送り札 ([send]) and
/// 並べ替え ([arrange]), and each change of the sides lays the board out
/// afresh ([relayout]), every card gliding to its new place and size and
/// the band, Tobi and the game column moving along. Each time the board
/// comes to rest after the cards went home, or a 送り札 or 並べ替え is
/// over, [onSettled] is told.
class IkkiuchiBoardScene extends ChangeNotifier {
  IkkiuchiBoardScene(this._layout, this.faces, {this.sides, this.tobiRating = 0, int seed = 0})
      : board = _layout.board(),
        rng = math.Random(seed);

  IkkiuchiBoardLayout get layout => _layout;
  IkkiuchiBoardLayout _layout;
  final IkkiuchiCardFaces faces;
  IkkiuchiBoard board;

  /// Both sides as they stand; null on a board that only shows strikes.
  IkkiuchiSides? sides;

  /// Tobi's rating, which his choices go by, and the draws they make.
  final double tobiRating;
  final math.Random rng;

  /// The 送り札 and 並べ替え on this board, and whether either is under way.
  late final send = IkkiuchiSendFlow(this);
  late final arrange = IkkiuchiArrangeFlow(this);
  bool get busy => send.active || arrange.active;

  /// The reader, reading the card called.
  final reader = IkkiuchiReader();

  VoidCallback? onSettled;

  /// The call on the band, the tag before it on a からふだ, and a small note
  /// under it.
  String? kimariji;
  String? karafuda;
  String? note;

  /// Whether the arm leaves wind lines and smear afterimages.
  bool wind = true;

  /// The card marked by an outline, if any.
  int? get marked => _marked;
  int? _marked;

  void mark(int? id) {
    _marked = id;
    notifyListeners();
  }

  /// [id] is the card read, for the player to take: marked, its words
  /// [kimariji] on the band, the reader reading its [call], and the board
  /// watching for the player's take and faults.
  void callCard(int id, String kimariji, {IkkiuchiCall? call}) {
    board.callCard(id);
    _marked = id;
    _karafudaIn = null;
    _read(call);
    show(kimariji);
  }

  /// [id], a card not on the board, is read: a からふだ, every card on the
  /// field one to fault on. No card is marked; its words [kimariji] go on
  /// the band after the [tag], and the reader reads its [call].
  /// [IkkiuchiPlayTuning.karafudaPause] after its last sound the read is
  /// over, and [onSettled] is told once the cards the finger stirred are
  /// home.
  void callKarafuda(int id, String kimariji, {required String tag, IkkiuchiCall? call}) {
    board.callCard(id, onField: false);
    _marked = null;
    _karafudaIn = (call?.decidedAt ?? 0) + _ms(IkkiuchiPlayTuning.karafudaPause);
    _read(call);
    show(kimariji, karafuda: tag);
  }

  void _read(IkkiuchiCall? call) {
    if (call == null) {
      reader.stop();
    } else {
      reader.read(call);
    }
  }

  /// No card is read: no mark, the band empty, the reader still, no take
  /// or fault watched.
  void clearCall() {
    board.callCard(null);
    _marked = null;
    _karafudaIn = null;
    reader.stop();
    show(null);
  }

  /// The board as it was set out, the band cleared and the reader still.
  void reset() {
    board = _layout.board();
    kimariji = karafuda = note = null;
    _karafudaIn = null;
    reader.stop();
    _band();
  }

  /// Each side's cards left: one Tobi sends counts as the player's from the
  /// moment he picks it up. Null on a board that only shows strikes.
  ({int tobi, int player})? get cardsLeft {
    final sides = this.sides;
    if (sides == null) return null;
    final carried = send.stage == IkkiuchiSendStage.carrying ? 1 : 0;
    final waiting = send.stage == IkkiuchiSendStage.waiting ? 1 : 0;
    return (tobi: sides.tobiCards.length - carried, player: sides.playerCards.length + carried + waiting);
  }

  /// Something drawn over the board changed.
  void refresh() => notifyListeners();

  void advance(double ms) {
    board.advance(ms);
    reader.advance(ms);
    _tidy(ms);
    _endKarafuda(ms);
    send.advance();
    if (_from != null && !board.cards.gliding) _from = null;
    if (_settling && !board.cards.gliding && !busy) {
      _settling = false;
      onSettled?.call();
    }
    notifyListeners();
  }

  // The player's finger.

  /// The pointer of the finger on the board; other fingers are let be.
  int? _finger;

  /// Ms until the cards the finger stirred set off home; null while it is
  /// down, or with nothing to tidy.
  double? _tidyIn;

  /// Whether [onSettled] is told once the cards glide no more.
  bool _settling = false;

  /// Ms until a からふだ's read is over; null with none read.
  double? _karafudaIn;

  /// [onSettled] is told once the cards glide no more and nothing is under
  /// way.
  void settle() => _settling = true;

  /// A pointer on the board, at its position in board dp: one finger
  /// pushes the cards while no 送り札 or 並べ替え is under way.
  void pointer(PointerEvent event) {
    final at = Vec(event.localPosition.dx, event.localPosition.dy);
    switch (event) {
      case PointerDownEvent() when _finger == null && !busy:
        _finger = event.pointer;
        _tidyIn = null;
        board.touch(at);
      case PointerMoveEvent() when event.pointer == _finger:
        board.touch(at);
      case PointerUpEvent() || PointerCancelEvent() when event.pointer == _finger:
        _finger = null;
        _tidyIn = IkkiuchiPlayTuning.tidyWait.inMicroseconds / Duration.microsecondsPerMillisecond;
        board.lift();
    }
  }

  void _tidy(double ms) {
    final wait = _tidyIn;
    if (wait == null) return;
    final left = wait - ms;
    _tidyIn = left > 0 ? left : null;
    if (_tidyIn != null) return;
    _settling = true;
    board.cards.glideHome(ms: _ms(IkkiuchiPlayTuning.tidyGlide), ease: IkkiuchiPlayTuning.tidyCurve.transform);
  }

  /// Once a からふだ's read is over the board settles; while the finger is
  /// down, or the cards it stirred wait to go home, they settle it instead.
  void _endKarafuda(double ms) {
    final left = _karafudaIn;
    if (left == null) return;
    _karafudaIn = left > ms ? left - ms : null;
    if (_karafudaIn == null && _finger == null && _tidyIn == null) _settling = true;
  }

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;

  // The sides changing.

  /// Where the band, the field, the game column, Tobi and the waiting spot
  /// were as the board was last laid out afresh; null once the cards are
  /// home.
  ({Rect band, Rect field, Rect? column, TobiFrame tobi, Rect wait})? _from;

  double get _shift => board.cards.glided ?? 1;

  /// The band, the field, the game column, Tobi and the waiting spot now:
  /// on their way from where they were to the new layout's while the cards
  /// glide there.
  Rect get band => _from == null ? _layout.band : Rect.lerp(_from!.band, _layout.band, _shift)!;
  Rect get field => _from == null ? _layout.field : Rect.lerp(_from!.field, _layout.field, _shift)!;
  Rect? get column => _from == null ? _layout.column : Rect.lerp(_from!.column, _layout.column, _shift);
  Rect get wait => _from == null ? _layout.wait : Rect.lerp(_from!.wait, _layout.wait, _shift)!;
  TobiFrame get tobi {
    final from = _from?.tobi, to = _layout.tobi;
    if (from == null) return to;
    final t = _shift;
    return TobiFrame(from.origin.lerp(to.origin, t), from.k + (to.k - from.k) * t, to.rig);
  }

  /// The sides are now [next]: the board is laid out for them afresh and
  /// set out anew, every card gliding from where it lies now, or from
  /// [from] for one off the board, to its new home and size. Unless a
  /// 送り札 goes on, [onSettled] is told once they are all home.
  void relayout(IkkiuchiSides next, {Map<int, CardBox> from = const {}}) {
    final lying = {
      for (final c in board.cards.cards)
        if (c.onBoard && !c.held) c.id: c.box,
      ...from,
    };
    final old = board;
    _from = (band: band, field: field, column: column, tobi: tobi, wait: wait);
    sides = next;
    _layout = _layout.withSides(tobiRows: next.tobi, playerRows: next.player);
    board = _layout.board(startStep: old.steps)
      ..heldFace = old.heldFace
      ..restFace = old.restFace
      ..restUntil = old.restUntil;
    board.cards.glideFrom(
      {
        for (final c in _layout.cards) c.id: ?lying[c.id],
      },
      ms: _ms(IkkiuchiPlayTuning.relayoutGlide),
      ease: IkkiuchiPlayTuning.relayoutCurve.transform,
    );
    _settling = true;
    _band();
  }

  // The band.

  /// A new call on the band, its note cleared.
  void show(String? kimariji, {String? karafuda}) {
    this.kimariji = kimariji;
    this.karafuda = karafuda;
    note = null;
    _band();
  }

  void annotate(String note) {
    this.note = note;
    _band();
  }

  /// The band's text, recorded once each time it changes, for the band at
  /// the layout's place.
  ui.Picture? get bandText => _bandText ??= _recordBand();
  ui.Picture? _bandText;

  void _band() {
    _bandText?.dispose();
    _bandText = null;
    notifyListeners();
  }

  ui.Picture? _recordBand() {
    final text = kimariji;
    if (text == null) return null;
    final band = _layout.band;
    final dim = karafuda != null;
    final call = TextPainter(
      text: TextSpan(children: [
        if (karafuda case final tag?)
          TextSpan(
            text: tag + IkkiuchiBoardStyle.karafudaGap,
            style: const TextStyle(fontSize: IkkiuchiBoardStyle.karafudaTag),
          ),
        TextSpan(
          text: text,
          style: const TextStyle(fontSize: IkkiuchiBoardStyle.kimariji),
        ),
      ], style: TextStyle(
        fontFamily: Fonts.display,
        height: 1,
        color: dim ? IkkiuchiBoardStyle.karafudaColor : IkkiuchiBoardStyle.kimarijiColor,
      )),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: band.width);
    final small = note == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: note,
              style: const TextStyle(
                fontFamily: Fonts.ui,
                fontSize: IkkiuchiBoardStyle.noteFont,
                height: 1,
                color: IkkiuchiBoardStyle.noteColor,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: IkkiuchiBoardStyle.noteEllipsis,
          )..layout(maxWidth: band.width - 2 * IkkiuchiBoardStyle.pad));
    final height = call.height + (small == null ? 0 : IkkiuchiBoardStyle.noteGap + small.height);
    final top = band.center.dy - height / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    call.paint(canvas, Offset(band.center.dx - call.width / 2, top));
    small?.paint(canvas, Offset(band.center.dx - small.width / 2, top + call.height + IkkiuchiBoardStyle.noteGap));
    call.dispose();
    small?.dispose();
    return recorder.endRecording();
  }

  @override
  void dispose() {
    _bandText?.dispose();
    reader.dispose();
    super.dispose();
  }
}
