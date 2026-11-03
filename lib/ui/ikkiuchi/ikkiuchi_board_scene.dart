import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_send.dart';
import 'ikkiuchi_board_layout.dart';
import 'ikkiuchi_card_faces.dart';
import 'ikkiuchi_send_flow.dart';

/// The 一騎打ち board as it is drawn: its [layout], the board running on it,
/// the call shown on the band, a card marked, and the wind switch. Every
/// change repaints the board's painter.
///
/// It takes the player's finger ([pointer]): one finger pushes the cards
/// about, and [IkkiuchiPlayTuning.tidyWait] after it lifts the cards it
/// stirred glide home. With [sides] it plays the 送り札 ([send]), and each
/// change of the sides lays the board out afresh ([relayout]), every card
/// gliding to its new place and size and the band and Tobi moving along.
/// Each time the board comes to rest after the cards went home or a 送り札
/// is over, [onSettled] is told.
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

  /// The 送り札 on this board.
  late final send = IkkiuchiSendFlow(this);

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
  /// [kimariji] on the band, and the board watching for the player's take.
  void callCard(int id, String kimariji) {
    board.callCard(id);
    _marked = id;
    show(kimariji);
  }

  /// No card is read: no mark, the band empty, no take watched.
  void clearCall() {
    board.callCard(null);
    _marked = null;
    show(null);
  }

  /// The board as it was set out, the band cleared.
  void reset() {
    board = _layout.board();
    kimariji = karafuda = note = null;
    _band();
  }

  /// Something drawn over the board changed.
  void refresh() => notifyListeners();

  void advance(double ms) {
    board.advance(ms);
    _tidy(ms);
    send.advance();
    if (_from != null && !board.cards.gliding) _from = null;
    if (_settling && !board.cards.gliding && !send.active) {
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

  /// A pointer on the board, at its position in board dp: one finger
  /// pushes the cards while no 送り札 is under way.
  void pointer(PointerEvent event) {
    final at = Vec(event.localPosition.dx, event.localPosition.dy);
    switch (event) {
      case PointerDownEvent() when _finger == null && !send.active:
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

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;

  // The sides changing.

  /// Where the band, Tobi and the waiting spot were as the board was last
  /// laid out afresh; null once the cards are home.
  ({Rect band, TobiFrame tobi, Rect wait})? _from;

  double get _shift => board.cards.glided ?? 1;

  /// The band, Tobi and the waiting spot now: on their way from where they
  /// were to the new layout's while the cards glide there.
  Rect get band => _from == null ? _layout.band : Rect.lerp(_from!.band, _layout.band, _shift)!;
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
    _from = (band: band, tobi: tobi, wait: wait);
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
    super.dispose();
  }
}
