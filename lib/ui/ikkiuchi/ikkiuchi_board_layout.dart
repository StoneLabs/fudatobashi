import 'dart:math' as math;
import 'dart:ui';

import '../../config/design.dart';
import '../../domain/ikkiuchi_board.dart';
import '../../domain/ikkiuchi_cards.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_rig.dart';

/// Where everything lies on the 一騎打ち board of [size]: the full field
/// ([IkkiuchiField]), Tobi's side across the band at the top. Both sides'
/// cards are one size, as big as the board lets them grow: the field spans
/// the board's width, its widest row's groups closing in toward the middle
/// as they grow, until a row's groups come [IkkiuchiField.leastGap] apart,
/// the field and the band fill the height, or a card is
/// [IkkiuchiBoardStyle.maxCardW] wide. Portrait stands Tobi above his
/// side, his room kept above the field; landscape sits him in the open
/// middle of his half, the room he needs there kept open.
class IkkiuchiBoardLayout {
  IkkiuchiBoardLayout._(this.size, this.landscape, this.band, this.tobi, this.cardW, this.cards);

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
    final areaW = w - 2 * pad, areaH = h - 2 * pad;
    final half = field.halfHeight;
    final double cardW, top;
    final TobiFrame tobi;
    if (landscape) {
      // Tobi is as tall as a share of his half, so the room he needs grows
      // with the cards.
      const share = IkkiuchiBoardStyle.tobiShare;
      final room = half * share * rig.size.x / rig.size.y + 2 * IkkiuchiBoardStyle.tobiSideRoom;
      cardW = [
        areaW / field.leastWidth(tobiRoom: room),
        (areaH - bandH) / (2 * half),
        IkkiuchiBoardStyle.maxCardW,
      ].reduce(math.min);
      top = pad + (areaH - (2 * half * cardW + bandH)) / 2;
      final open = field.tobiOpen(areaW / cardW);
      final k = half * cardW * share / rig.size.y;
      final middle = pad + (open.from + open.to) / 2 * cardW;
      tobi = TobiFrame(Vec(middle - rig.size.x * k / 2, top + IkkiuchiBoardStyle.tobiTop), k, rig);
    } else {
      cardW = [
        areaW / field.leastWidth(),
        (h - pad - IkkiuchiBoardStyle.bottomGap - bandH - IkkiuchiBoardStyle.tobiMinRoom) / (2 * half),
        IkkiuchiBoardStyle.maxCardW,
      ].reduce(math.min);
      top = h - IkkiuchiBoardStyle.bottomGap - (2 * half * cardW + bandH);
      final k = math.min(IkkiuchiBoardStyle.tobiHeight, top - pad - IkkiuchiBoardStyle.tobiTopRoom) / rig.size.y;
      final feetY = top - IkkiuchiBoardStyle.tobiFeetGap;
      final probe = TobiFrame(Vec.zero, k, rig);
      tobi = TobiFrame(Vec(w / 2 - rig.size.x * k / 2, feetY - probe.feet.y), k, rig);
    }
    final band = Rect.fromLTWH(0, top + half * cardW, w, bandH);
    final cards = [
      for (final c in field.layOut(areaW / cardW, gap: bandH / cardW))
        (
          id: c.id,
          side: c.side,
          box: CardBox(Vec(pad, top) + c.box.centre * cardW, c.box.hw * cardW, c.box.hh * cardW, c.box.angle),
        ),
    ];
    return IkkiuchiBoardLayout._(Vec(w, h), landscape, band, tobi, cardW, cards);
  }

  final Vec size;
  final bool landscape;
  final Rect band;
  final TobiFrame tobi;

  /// Every card's width, dp.
  final double cardW;
  final List<({int id, IkkiuchiSide side, CardBox box})> cards;

  /// The board set out on this layout, no card crossing the middle of the band.
  IkkiuchiBoard board() => IkkiuchiBoard(tobi: tobi, size: size, cards: cards, cardW: cardW, centreLine: band.center.dy);
}
