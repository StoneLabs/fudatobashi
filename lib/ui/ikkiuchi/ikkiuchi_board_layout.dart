import 'dart:math' as math;
import 'dart:ui';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/field_parts.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../../domain/ikkiuchi_side.dart';

/// Where everything lies on the 一騎打ち board of [size]: the full field
/// ([IkkiuchiField]), Tobi's side across the band at the top, every row
/// either side has shown, empty or not. Both sides' cards are one size, as
/// big as the board lets them grow: its widest row's groups close in
/// toward the middle as they grow, until a row is as
/// narrow as it may be ([IkkiuchiField.rowWidth]), the field and the band
/// (in landscape only a narrower gap, with the rows closer) fill the
/// height, or a card is [IkkiuchiBoardStyle.maxCardW] wide. The field spans
/// the board's width, but never more than [IkkiuchiLayoutTuning.rowSlots]
/// card widths, and then lies centred. Portrait stands Tobi above his
/// side, his room kept above the field; landscape sits him in the open
/// middle of his half, the room he needs there kept open, and its rows may
/// reach the board's top and bottom edges. Landscape keeps the game
/// [column] down the board's right edge, from its top to its bottom however
/// tall the field is: the field lies centred where it can, else as far
/// right as leaves the column clear. A card Tobi sends waits at
/// [wait], big, right of him: in portrait just above his side; in landscape
/// in the open middle of his half, over his cards where it must. No room is
/// kept for it.
///
/// While the match opens, the player's cards wait in a [stack]: in
/// landscape room is kept for it right of the field, beside the player's
/// side ([IkkiuchiOpeningStyle]), the field at its full width and the cards
/// a little smaller; in portrait it lies where Tobi's card waits.
///
/// Any change to the sides lays the board out afresh by the same rules
/// ([withSides]), its rows and its cards' size kept: the cards never grow,
/// and shrink only where the field would no longer fit.
class IkkiuchiBoardLayout {
  IkkiuchiBoardLayout._(this.size, this.landscape, this.band, this.tobi, this.cardW, this.cards, this.field, this.wait,
      this.column, this.stack, this._field, this._fieldW, this._origin);

  /// [tobiRows] and [playerRows] are each side's rows as its owner sees
  /// them, 下段 first, each group from its outer edge in and the open middle
  /// left to right. With [opening] the player's stack is laid out too. With
  /// [scale] the cards keep that width, narrower only where the field would
  /// not fit otherwise.
  factory IkkiuchiBoardLayout.of({
    required Size size,
    required bool landscape,
    required List<IkkiuchiRow> tobiRows,
    required List<IkkiuchiRow> playerRows,
    required TobiRig rig,
    bool opening = false,
    double? scale,
  }) {
    final field = IkkiuchiField(
      tobi: tobiRows,
      player: playerRows,
      rowGap: landscape ? IkkiuchiFieldTuning.landscapeRowGap : IkkiuchiFieldTuning.rowGap,
      keepRows: true,
    );
    const pad = IkkiuchiBoardStyle.pad;
    final bandH = landscape ? IkkiuchiBoardStyle.landscapeGap : IkkiuchiBoardStyle.band;
    final w = size.width, h = size.height;
    final areaW = w - 2 * pad;
    final half = field.halfHeight;
    final double cardW, top, fieldW, left;
    final TobiFrame tobi;
    if (landscape) {
      // Tobi is as tall as a share of his half, so the room he needs grows
      // with the cards. Right of the field the column.
      const share = IkkiuchiBoardStyle.tobiShare;
      final room = half * share * rig.size.x / rig.size.y + 2 * IkkiuchiBoardStyle.tobiSideRoom;
      final least = field.leastWidth(tobiRoom: room);
      final full = math.max(IkkiuchiLayoutTuning.rowSlots, least);
      // The stack's room right of the field: its top card, in card widths,
      // and the gap and the edges under it, in dp.
      const stackW = IkkiuchiOpeningStyle.stackScale;
      final stackRoom = IkkiuchiOpeningStyle.stackGap + _stackEdges;
      final right = w - IkkiuchiColumnStyle.edge - IkkiuchiColumnStyle.width - IkkiuchiColumnStyle.fieldGap;
      final widest = opening ? (right - pad - stackRoom) / (full + stackW) : (right - pad) / least;
      cardW = math.min(scale ?? [widest, (h - bandH) / (2 * half), IkkiuchiBoardStyle.maxCardW].reduce(math.min), widest);
      final fieldRight = opening ? right - stackRoom - stackW * cardW : right;
      top = (h - (2 * half * cardW + bandH)) / 2;
      fieldW = math.min((fieldRight - pad) / cardW, full);
      left = math.min((w - fieldW * cardW) / 2, fieldRight - fieldW * cardW);
      final open = field.tobiOpen(fieldW);
      final k = half * cardW * share / rig.size.y;
      final middle = left + (open.from + open.to) / 2 * cardW;
      tobi = TobiFrame(Vec(middle - rig.size.x * k / 2, top + IkkiuchiBoardStyle.tobiTop), k, rig);
    } else {
      final widest = areaW / field.leastWidth();
      final tallest = (h - pad - IkkiuchiBoardStyle.bottomGap - bandH - IkkiuchiBoardStyle.tobiMinRoom) / (2 * half);
      cardW = math.min(scale ?? [widest, tallest, IkkiuchiBoardStyle.maxCardW].reduce(math.min), widest);
      fieldW = math.min(areaW / cardW, math.max(IkkiuchiLayoutTuning.rowSlots, field.leastWidth()));
      left = pad + (areaW - fieldW * cardW) / 2;
      top = h - IkkiuchiBoardStyle.bottomGap - (2 * half * cardW + bandH);
      final k = math.min(IkkiuchiBoardStyle.tobiHeight, top - pad - IkkiuchiBoardStyle.tobiTopRoom) / rig.size.y;
      final feetY = top - IkkiuchiBoardStyle.tobiFeetGap;
      final probe = TobiFrame(Vec.zero, k, rig);
      tobi = TobiFrame(Vec(w / 2 - rig.size.x * k / 2, feetY - probe.feet.y), k, rig);
    }
    final band = Rect.fromLTWH(0, top + half * cardW, w, bandH);
    final origin = Vec(left, top);
    final cards = [
      for (final c in field.layOut(fieldW, gap: bandH / cardW))
        (id: c.id, side: c.side, box: _onBoard(c.box, origin, cardW)),
    ];
    final area = Rect.fromLTWH(left, top, fieldW * cardW, 2 * half * cardW + bandH);
    const edge = IkkiuchiColumnStyle.edge;
    final column = landscape
        ? Rect.fromLTRB(w - edge - IkkiuchiColumnStyle.width, edge, w - edge, h - edge)
        : null;
    final wait = landscape ? _waitRightOfTobi(area, band, cardW, tobi, column!) : _waitByTobi(area, tobi, cardW, w);
    final stack = !opening ? null : (landscape ? _stackBesidePlayer(area, band, cardW) : wait);
    return IkkiuchiBoardLayout._(
        Vec(w, h), landscape, band, tobi, cardW, cards, area, wait, column, stack, field, fieldW, origin);
  }

  /// How far the edges of the cards under the stack's top one reach past it.
  static final _stackEdges = IkkiuchiSendStyle.look.stackDepth * IkkiuchiSendStyle.look.stackStep;

  /// [IkkiuchiOpeningStyle.stackGap] right of the field, as wide as its
  /// room, centred on the player's half with its tag under it.
  static Rect _stackBesidePlayer(Rect field, Rect band, double cardW) {
    final tag = IkkiuchiSendStyle.look.stackTagRoom;
    final width = IkkiuchiOpeningStyle.stackScale * cardW, height = width * IkkiuchiField.cardH;
    final half = Rect.fromLTRB(field.left, band.bottom, field.right, field.bottom);
    final top = half.top + (half.height - height - tag) / 2;
    return Rect.fromLTWH(field.right + IkkiuchiOpeningStyle.stackGap, top, width, height);
  }

  /// A box of the field in card widths from [origin], on the board.
  static CardBox _onBoard(CardBox b, Vec origin, double cardW) =>
      CardBox(origin + b.centre * cardW, b.hw * cardW, b.hh * cardW, b.angle);

  /// The room under the waiting card for its tag and the hint under it.
  static final _waitTags = IkkiuchiSendStyle.look.stackTagRoom + IkkiuchiSendStyle.hintRoom;

  /// A waiting card [height] tall, centred across [from]..[to] with its
  /// foot at [foot].
  static Rect _waitIn(double from, double to, double foot, double height) {
    final width = height / IkkiuchiField.cardH;
    return Rect.fromLTWH((from + to - width) / 2, foot - height, width, height);
  }

  /// Right of Tobi, its tags' foot just over his side; where the field's
  /// cards are big, [IkkiuchiSendStyle.wait]'s `scale` of them wide, as far
  /// as the room above the side takes it.
  static Rect _waitByTobi(Rect field, TobiFrame tobi, double cardW, double w) {
    const style = IkkiuchiSendStyle.wait;
    final from = tobi.origin.x + tobi.rig.size.x * tobi.k, to = w - IkkiuchiBoardStyle.pad;
    final foot = field.top - _waitTags - style.margin;
    final height = [
      math.max(math.min(style.maxHeight, tobi.rig.size.y * tobi.k * style.tobiShare), style.scale * cardW * IkkiuchiField.cardH),
      (to - from - 2 * style.margin) * IkkiuchiField.cardH,
      foot - IkkiuchiBoardStyle.pad,
    ].reduce(math.min);
    return _waitIn(from, to, foot, math.max(height, cardW * IkkiuchiField.cardH));
  }

  /// Just right of Tobi, [IkkiuchiSendStyle.wait]'s `gap` clear of him, in
  /// the open middle of his half and over his cards where it must: at most
  /// `landscapeScale` field cards wide, as tall as his half takes it with
  /// its tags under it, and centred on the half; never past the [column].
  static Rect _waitRightOfTobi(Rect field, Rect band, double cardW, TobiFrame tobi, Rect column) {
    const style = IkkiuchiSendStyle.wait;
    final tag = _waitTags;
    const aspect = IkkiuchiField.cardH;
    final half = Rect.fromLTRB(field.left, field.top, field.right, band.top);
    final width = math.max(cardW, math.min(style.landscapeScale * cardW, (half.height - tag - 2 * style.gap) / aspect));
    final height = width * aspect;
    final left = math.min(tobi.origin.x + tobi.rig.size.x * tobi.k + style.gap, column.left - style.gap - width);
    return Rect.fromLTWH(left, half.top + (half.height - height - tag) / 2, width, height);
  }

  final Vec size;
  final bool landscape;
  /// The strip between the sides: the band in portrait, only the gap in
  /// landscape, where nothing is drawn in it.
  final Rect band;
  final TobiFrame tobi;

  /// Every card's width, dp.
  final double cardW;
  final List<({int id, IkkiuchiSide side, CardBox box})> cards;

  /// Both territories, from the far edge of Tobi's back row to the far
  /// edge of the player's, as wide as the field.
  final Rect field;

  /// Where a card Tobi sends waits for the player to place it.
  final Rect wait;

  /// The game column down the board's right edge, top to bottom, in
  /// landscape only.
  final Rect? column;

  /// Where the player's stack lies while the match opens; null once laid
  /// out for play.
  final Rect? stack;

  final IkkiuchiField _field;
  final double _fieldW;
  final Vec _origin;

  /// The board laid out afresh with these sides, by the same rules on the
  /// same board, its cards' size kept, for the opening while [opening] says
  /// so, else as it was.
  IkkiuchiBoardLayout withSides(
          {required List<IkkiuchiRow> tobiRows, required List<IkkiuchiRow> playerRows, bool? opening}) =>
      IkkiuchiBoardLayout.of(
        size: Size(size.x, size.y),
        landscape: landscape,
        tobiRows: tobiRows,
        playerRows: playerRows,
        rig: tobi.rig,
        opening: opening ?? stack != null,
        scale: cardW,
      );

  /// Where a card added at the inner end of the player's [row]'s left or
  /// right group ([part]) would lie; null where it has no room
  /// ([IkkiuchiField.playerEnd]).
  FieldRect? playerEnd(FieldRow row, RowPart part) =>
      _rect(_field.playerEnd(row.index, left: part == RowPart.left, width: _fieldW, gap: _gap));

  /// Where the open middle of the player's [row] takes taps and drops,
  /// [leaving] counted as gone from the row; null where the row is not
  /// shown ([IkkiuchiField.playerMiddle]).
  FieldRect? playerMiddle(FieldRow row, {int? leaving}) =>
      _rect(_field.playerMiddle(row.index, leaving: leaving, width: _fieldW, gap: _gap));

  /// Where a card put in the open middle of the player's [row], with
  /// [index] of its middle cards left of it, would lie, [leaving] gone from
  /// the row ([IkkiuchiField.playerMiddleAt]).
  FieldRect? playerMiddleAt(FieldRow row, int index, {int? leaving}) =>
      _rect(_field.playerMiddleAt(row.index, index, leaving: leaving, width: _fieldW, gap: _gap));

  /// The open middle of Tobi's side on the board, between his widest groups
  /// on either side, over his half.
  Rect get tobiOpen {
    final open = _field.tobiOpen(_fieldW);
    return Rect.fromLTRB(_origin.x + open.from * cardW, field.top, _origin.x + open.to * cardW, band.top);
  }

  /// The gap between the halves, in card widths.
  double get _gap => band.height / cardW;

  /// [box] of the field, upright on the board.
  FieldRect? _rect(CardBox? box) {
    if (box == null) return null;
    final b = _onBoard(box, _origin, cardW);
    return FieldRect(b.centre.x - b.hw, b.centre.y - b.hh, 2 * b.hw, 2 * b.hh);
  }

  /// The board set out on this layout, its time from [startStep].
  IkkiuchiBoard board({int startStep = 0}) => IkkiuchiBoard(
        tobi: tobi,
        size: size,
        cards: cards,
        cardW: cardW,
        fieldArea: FieldRect(field.left, field.top, field.width, field.height),
        startStep: startStep,
      );
}
