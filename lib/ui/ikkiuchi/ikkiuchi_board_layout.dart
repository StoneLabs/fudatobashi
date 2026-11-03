import 'dart:math' as math;
import 'dart:ui';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/field_parts.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_cards.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_rig.dart';

/// Where everything lies on the 一騎打ち board of [size]: the full field
/// ([IkkiuchiField]), Tobi's side across the band at the top. Both sides'
/// cards are one size, as big as the board lets them grow: its widest row's
/// groups close in toward the middle as they grow, until a row's groups
/// come [IkkiuchiField.leastGap] apart, the field and the band fill the
/// height, or a card is [IkkiuchiBoardStyle.maxCardW] wide. The field spans
/// the board's width, but never more than [IkkiuchiLayoutTuning.rowSlots]
/// card widths, and then lies centred. Portrait stands Tobi above his
/// side, his room kept above the field; landscape sits him in the open
/// middle of his half, the room he needs there kept open, and its rows may
/// reach the board's top and bottom edges. A card Tobi sends waits at
/// [wait]: in portrait right of him, just above his side; in landscape in
/// the margin beside the player's side.
///
/// Any change to the sides lays the board out afresh by the same rules
/// ([withSides]), its cards growing or shrinking to fit.
class IkkiuchiBoardLayout {
  IkkiuchiBoardLayout._(this.size, this.landscape, this.band, this.tobi, this.cardW, this.cards, this.field, this.wait,
      this._field, this._fieldW, this._origin);

  /// [tobiRows] and [playerRows] are each side's rows as its owner sees
  /// them, 下段 first, each group from its outer edge in.
  factory IkkiuchiBoardLayout.of({
    required Size size,
    required bool landscape,
    required List<IkkiuchiRow> tobiRows,
    required List<IkkiuchiRow> playerRows,
    required TobiRig rig,
  }) {
    final field = IkkiuchiField(tobi: tobiRows, player: playerRows);
    const pad = IkkiuchiBoardStyle.pad, bandH = IkkiuchiBoardStyle.band;
    final w = size.width, h = size.height;
    final areaW = w - 2 * pad;
    final half = field.halfHeight;
    final double cardW, top, fieldW;
    final TobiFrame tobi;
    if (landscape) {
      // Tobi is as tall as a share of his half, so the room he needs grows
      // with the cards.
      const share = IkkiuchiBoardStyle.tobiShare;
      final room = half * share * rig.size.x / rig.size.y + 2 * IkkiuchiBoardStyle.tobiSideRoom;
      cardW = [
        areaW / field.leastWidth(tobiRoom: room),
        (h - bandH) / (2 * half),
        IkkiuchiBoardStyle.maxCardW,
      ].reduce(math.min);
      top = (h - (2 * half * cardW + bandH)) / 2;
      fieldW = math.min(areaW / cardW, math.max(IkkiuchiLayoutTuning.rowSlots, field.leastWidth(tobiRoom: room)));
      final open = field.tobiOpen(fieldW);
      final k = half * cardW * share / rig.size.y;
      final middle = pad + (areaW - fieldW * cardW) / 2 + (open.from + open.to) / 2 * cardW;
      tobi = TobiFrame(Vec(middle - rig.size.x * k / 2, top + IkkiuchiBoardStyle.tobiTop), k, rig);
    } else {
      cardW = [
        areaW / field.leastWidth(),
        (h - pad - IkkiuchiBoardStyle.bottomGap - bandH - IkkiuchiBoardStyle.tobiMinRoom) / (2 * half),
        IkkiuchiBoardStyle.maxCardW,
      ].reduce(math.min);
      fieldW = math.min(areaW / cardW, math.max(IkkiuchiLayoutTuning.rowSlots, field.leastWidth()));
      top = h - IkkiuchiBoardStyle.bottomGap - (2 * half * cardW + bandH);
      final k = math.min(IkkiuchiBoardStyle.tobiHeight, top - pad - IkkiuchiBoardStyle.tobiTopRoom) / rig.size.y;
      final feetY = top - IkkiuchiBoardStyle.tobiFeetGap;
      final probe = TobiFrame(Vec.zero, k, rig);
      tobi = TobiFrame(Vec(w / 2 - rig.size.x * k / 2, feetY - probe.feet.y), k, rig);
    }
    final band = Rect.fromLTWH(0, top + half * cardW, w, bandH);
    final left = pad + (areaW - fieldW * cardW) / 2;
    final origin = Vec(left, top);
    final cards = [
      for (final c in field.layOut(fieldW, gap: bandH / cardW))
        (id: c.id, side: c.side, box: _onBoard(c.box, origin, cardW)),
    ];
    final area = Rect.fromLTWH(left, top, fieldW * cardW, 2 * half * cardW + bandH);
    final wait = landscape ? _waitBeside(area, band, cardW, w) : _waitByTobi(area, tobi, cardW, w);
    return IkkiuchiBoardLayout._(Vec(w, h), landscape, band, tobi, cardW, cards, area, wait, field, fieldW, origin);
  }

  /// A box of the field in card widths from [origin], on the board.
  static CardBox _onBoard(CardBox b, Vec origin, double cardW) =>
      CardBox(origin + b.centre * cardW, b.hw * cardW, b.hh * cardW, b.angle);

  /// A waiting card [height] tall, centred across [from]..[to] with its
  /// foot at [foot].
  static Rect _waitIn(double from, double to, double foot, double height) {
    final width = height / IkkiuchiField.cardH;
    return Rect.fromLTWH((from + to - width) / 2, foot - height, width, height);
  }

  /// Right of Tobi, its tag's foot just over his side.
  static Rect _waitByTobi(Rect field, TobiFrame tobi, double cardW, double w) {
    const style = IkkiuchiSendStyle.wait;
    final from = tobi.origin.x + tobi.rig.size.x * tobi.k, to = w - IkkiuchiBoardStyle.pad;
    final height = [
      style.maxHeight,
      tobi.rig.size.y * tobi.k * style.tobiShare,
      (to - from - 2 * style.margin) * IkkiuchiField.cardH,
    ].reduce(math.min);
    final foot = field.top - IkkiuchiSendStyle.look.stackTagRoom - style.margin;
    return _waitIn(from, to, foot, math.max(height, cardW * IkkiuchiField.cardH));
  }

  /// In the margin right of the player's side, as tall as that side at
  /// most, its tag under it; never smaller than the field's cards.
  static Rect _waitBeside(Rect field, Rect band, double cardW, double w) {
    const style = IkkiuchiSendStyle.wait;
    final from = field.right, to = w;
    final room = field.bottom - band.bottom - IkkiuchiSendStyle.look.stackTagRoom;
    final height = math.max(
      cardW * IkkiuchiField.cardH,
      [style.maxHeight, room - 2 * style.margin, (to - from - 2 * style.margin) * IkkiuchiField.cardH].reduce(math.min),
    );
    final left = math.min((from + to - height / IkkiuchiField.cardH) / 2, w - height / IkkiuchiField.cardH);
    final top = band.bottom + (room - height) / 2;
    return Rect.fromLTWH(left, top, height / IkkiuchiField.cardH, height);
  }

  final Vec size;
  final bool landscape;
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

  final IkkiuchiField _field;
  final double _fieldW;
  final Vec _origin;

  /// The board laid out afresh with these sides, by the same rules on the
  /// same board.
  IkkiuchiBoardLayout withSides({required List<IkkiuchiRow> tobiRows, required List<IkkiuchiRow> playerRows}) =>
      IkkiuchiBoardLayout.of(
        size: Size(size.x, size.y),
        landscape: landscape,
        tobiRows: tobiRows,
        playerRows: playerRows,
        rig: tobi.rig,
      );

  /// Where a card added at the inner end of the player's [row]'s left or
  /// right group ([part]) would lie; null where it has no room
  /// ([IkkiuchiField.playerEnd]).
  FieldRect? playerEnd(FieldRow row, RowPart part) {
    final box = _field.playerEnd(row.index,
        left: part == RowPart.left, width: _fieldW, gap: IkkiuchiBoardStyle.band / cardW);
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
