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
import '../../domain/ikkiuchi_send.dart';
import '../../domain/ikkiuchi_side.dart';

/// Where everything lies on the 一騎打ち board of [size]: the full field
/// ([IkkiuchiField]), Tobi's side across the band at the top, every row
/// either side has shown, empty or not. Both sides' cards are one size, a
/// 3-row card never wider than [IkkiuchiBoardStyle.maxCardW], in 1 or 2
/// rows [growth] times that.
///
/// In landscape the field is laid out as a 3-row match's whatever its
/// rows, [fieldWidth] 3-row card widths across, the biggest that fits
/// between the pad and the game [column], which runs down the board's
/// right edge, and the board's full height, centred there; it keeps a
/// 3-row field's height too, the rows lying by the gap between the sides
/// and the height left over at its outer edges. Its size depends on the board alone, so it
/// never changes in the match. Tobi sits in the open middle of his half,
/// over his cards where his rows near full.
///
/// In portrait the band lies across the board's middle, Tobi's side above
/// it with him standing on it, the player's under it. The field is as wide
/// as its rows with a spot at every free place on the player's side need
/// ([IkkiuchiField.widthToPlace]), centred; its cards as big as that
/// width, the board's and the height either side of the band let them,
/// at most their widest. The game column's parts lie along the band, the
/// call in its middle ([words]). Any change to the sides lays the board
/// out afresh by the same rules ([withSides]), its rows kept, the cards
/// growing or shrinking as the rows need.
///
/// The cards to place wait at [wait], big: a card Tobi sends, and while
/// the match opens the player's [stack]. In portrait under the player's
/// side, at its left edge; in landscape right of Tobi, in the open middle of his half, over
/// his cards where it must. No room is kept for it in landscape.
class IkkiuchiBoardLayout {
  IkkiuchiBoardLayout._(this.size, this.landscape, this.band, this.tobi, this.cardW, this.cards, this.field, this.wait,
      this.column, this.stack, this._field, this._fieldW, this._origin);

  /// [tobiRows] and [playerRows] are each side's rows as its owner sees
  /// them, 下段 first, each group from its outer edge in and the open middle
  /// left to right; the [onTop] cards lie on top of their side.
  /// With [opening] the player's stack is laid out too.
  factory IkkiuchiBoardLayout.of({
    required Size size,
    required bool landscape,
    required List<IkkiuchiRow> tobiRows,
    required List<IkkiuchiRow> playerRows,
    required TobiRig rig,
    Map<int, IkkiuchiSide> onTop = const {},
    bool opening = false,
  }) {
    final field = IkkiuchiField(
      tobi: tobiRows,
      player: playerRows,
      rowGap: landscape ? IkkiuchiFieldTuning.landscapeRowGap : IkkiuchiFieldTuning.rowGap,
      onTop: onTop,
      keepRows: true,
    );
    const pad = IkkiuchiBoardStyle.pad;
    final bandH = landscape ? IkkiuchiBoardStyle.landscapeGap : IkkiuchiBoardStyle.band;
    final w = size.width, h = size.height;
    final areaW = w - 2 * pad;
    // The 3-row field's width, and in landscape its half too, in this
    // match's card widths; in portrait the rows' own half.
    final grow = growth(field.rows);
    final half = landscape ? IkkiuchiField.halfOf(IkkiuchiLayoutTuning.rows, field.rowGap) / grow : field.halfHeight;
    final width = fieldWidth / grow;
    final maxCardW = IkkiuchiBoardStyle.maxCardW * grow;
    final double cardW, top, fieldW, left;
    final TobiFrame tobi;
    if (landscape) {
      // The biggest field that fits between the pad and the column and the
      // full height, whatever the sides hold, centred there; Tobi as tall
      // as a share of his half.
      final right = w - IkkiuchiColumnStyle.edge - IkkiuchiColumnStyle.width - IkkiuchiColumnStyle.fieldGap;
      cardW = [(right - pad) / width, (h - bandH) / (2 * half), maxCardW].reduce(math.min);
      fieldW = width;
      left = pad + (right - pad - fieldW * cardW) / 2;
      top = (h - (2 * half * cardW + bandH)) / 2;
      final open = field.tobiOpen(fieldW);
      final k = half * cardW * IkkiuchiBoardStyle.tobiShare / rig.size.y;
      final middle = left + (open.from + open.to) / 2 * cardW;
      tobi = TobiFrame(Vec(middle - rig.size.x * k / 2, top + IkkiuchiBoardStyle.tobiTop), k, rig);
    } else {
      // The band across the middle; Tobi's room kept above his side, and
      // under the player's the room for the cards to place, at least a
      // field card.
      fieldW = field.widthToPlace(openMiddle: IkkiuchiSides.rules(field.rows).openMiddle);
      final above = (h - bandH) / 2 - pad - IkkiuchiBoardStyle.tobiMinRoom;
      final below = (h - bandH) / 2 - IkkiuchiBoardStyle.bottomGap - _waitTags - IkkiuchiSendStyle.wait.margin;
      cardW = [areaW / fieldW, above / half, below / (half + IkkiuchiField.cardH), maxCardW].reduce(math.min);
      left = pad + (areaW - fieldW * cardW) / 2;
      top = (h - bandH) / 2 - half * cardW;
      final k = math.min(IkkiuchiBoardStyle.tobiHeight, top - pad - IkkiuchiBoardStyle.tobiTopRoom) / rig.size.y;
      final feetY = top - IkkiuchiBoardStyle.tobiFeetGap;
      final probe = TobiFrame(Vec.zero, k, rig);
      tobi = TobiFrame(Vec(w / 2 - rig.size.x * k / 2, feetY - probe.feet.y), k, rig);
    }
    final band = Rect.fromLTWH(0, top + half * cardW, w, bandH);
    final origin = Vec(left, top + (half - field.halfHeight) * cardW);
    final cards = [
      for (final c in field.layOut(fieldW, gap: bandH / cardW))
        (id: c.id, side: c.side, box: _onBoard(c.box, origin, cardW)),
    ];
    final area = Rect.fromLTWH(left, top, fieldW * cardW, 2 * half * cardW + bandH);
    const edge = IkkiuchiColumnStyle.edge;
    final column = landscape
        ? Rect.fromLTRB(w - edge - IkkiuchiColumnStyle.width, edge, w - edge, h - edge)
        : null;
    final wait = landscape ? _waitRightOfTobi(area, band, cardW, tobi, column!) : _waitUnder(area, cardW, h);
    return IkkiuchiBoardLayout._(
        Vec(w, h), landscape, band, tobi, cardW, cards, area, wait, column, opening ? wait : null, field, fieldW, origin);
  }

  /// The 3-row field across, in 3-row card widths: a full row of a 3-row
  /// match ([IkkiuchiField.fullRow]).
  static final double fieldWidth = IkkiuchiField.fullRow(IkkiuchiLayoutTuning.rows);

  /// How many times a 3-row card's width the cards of a match of [rows]
  /// rows are: as many times as a full row of a 3-row match is a full row
  /// of theirs ([IkkiuchiLayoutTuning.rowSlots]), so their full row fills
  /// the 3-row field too.
  static double growth(int rows) =>
      IkkiuchiLayoutTuning.rowSlots[IkkiuchiLayoutTuning.rows]! / IkkiuchiLayoutTuning.rowSlots[rows]!;

  /// A box of the field in card widths from [origin], on the board.
  static CardBox _onBoard(CardBox b, Vec origin, double cardW) =>
      CardBox(origin + b.centre * cardW, b.hw * cardW, b.hh * cardW, b.angle);

  /// The room under the waiting card for its tag and the hint under it.
  static final _waitTags = IkkiuchiSendStyle.look.stackTagRoom + IkkiuchiSendStyle.hintRoom;

  /// Under the player's side, [IkkiuchiSendStyle.wait]'s `margin` under
  /// it, at its left edge, so that the opening's hint has room right of
  /// it: as tall as the room down to the board's foot takes it with its
  /// tags under it, at most `maxHeight` and at least a field card.
  static Rect _waitUnder(Rect field, double cardW, double h) {
    const style = IkkiuchiSendStyle.wait;
    final top = field.bottom + style.margin;
    final room = h - IkkiuchiBoardStyle.bottomGap - _waitTags - top;
    final height = math.max(math.min(style.maxHeight, room), cardW * IkkiuchiField.cardH);
    final width = height / IkkiuchiField.cardH;
    return Rect.fromLTWH(field.left, top, width, height);
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
  /// landscape only; in portrait its parts lie along the [band].
  final Rect? column;

  /// Where the call, or what to do in its place, lies: in landscape across
  /// the field in the gap; in portrait in the band's middle, between the
  /// game column's parts at its ends.
  Rect get words => wordsAt(band, field);

  /// [words] with the band at [band] and the field at [field].
  Rect wordsAt(Rect band, Rect field) => landscape
      ? Rect.fromLTRB(field.left, band.top, field.right, band.bottom)
      : Rect.fromCenter(center: band.center, width: band.width - 2 * _bandEnd, height: IkkiuchiBoardStyle.words);

  /// How the call looks there: on a see-through strip in landscape's gap,
  /// in ink on the band's paper in portrait.
  IkkiuchiCallLook get callLook => landscape ? IkkiuchiCallStyle.inGap : IkkiuchiCallStyle.onBand;

  /// The room the game column's parts take at each end of the band, and
  /// the gap from them.
  static const _bandEnd = IkkiuchiColumnStyle.edge + 2 * (IkkiuchiColumnStyle.width + IkkiuchiColumnStyle.bandGap);

  /// Where the player's stack lies while the match opens; null once laid
  /// out for play.
  final Rect? stack;

  final IkkiuchiField _field;
  final double _fieldW;
  final Vec _origin;

  /// The board laid out afresh with these sides, the [onTop] cards on top,
  /// by the same rules on the same board, for the opening while [opening]
  /// says so, else as it was.
  IkkiuchiBoardLayout withSides(
          {required List<IkkiuchiRow> tobiRows,
          required List<IkkiuchiRow> playerRows,
          Map<int, IkkiuchiSide> onTop = const {},
          bool? opening}) =>
      IkkiuchiBoardLayout.of(
        size: Size(size.x, size.y),
        landscape: landscape,
        tobiRows: tobiRows,
        playerRows: playerRows,
        rig: tobi.rig,
        onTop: onTop,
        opening: opening ?? stack != null,
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
