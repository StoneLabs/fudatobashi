import 'dart:math' as math;
import 'dart:ui';

import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';
import '../../domain/ikkiuchi_cards.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_rig.dart';

/// Where everything lies on the 一騎打ち board of [size]: the full field,
/// Tobi's side across the band at the top. Portrait folds the field to its
/// rows and stands Tobi above his side; landscape lays it out at true scale
/// with Tobi in the open middle of his half.
class IkkiuchiBoardLayout {
  IkkiuchiBoardLayout._(this.size, this.landscape, this.band, this.tobi, this.cards);

  /// [tobiRows] and [playerRows] are each side's rows as its owner sees
  /// them, 下段 first, each group from its outer edge in.
  factory IkkiuchiBoardLayout.of({
    required Size size,
    required bool landscape,
    required List<IkkiuchiRow> tobiRows,
    required List<IkkiuchiRow> playerRows,
    required TobiRig rig,
  }) {
    final field = AnkirenField(own: _half(playerRows), opponent: _half(tobiRows));
    const pad = IkkiuchiBoardStyle.pad;
    final w = size.width, h = size.height;
    final areaW = w - 2 * pad, areaH = h - 2 * pad;
    final cardW = FieldGeometry.of(field, folded: true).half(FieldSide.own).values.first.w;
    late FieldGeometry g;
    late double s, top, left;
    late Rect band;
    late TobiFrame tobi;
    if (landscape) {
      const bandH = IkkiuchiBoardStyle.bandLandscape;
      g = FieldGeometry.of(field, folded: false);
      s = math.min(areaW / g.width, (areaH - bandH) / (2 * g.height));
      final half = g.height * s;
      top = pad + (areaH - (2 * half + bandH)) / 2;
      left = pad + (areaW - g.width * s) / 2;
      band = Rect.fromLTWH(0, top + half, w, bandH);
      final k = half * IkkiuchiBoardStyle.tobiShare / rig.size.y;
      tobi = TobiFrame(Vec(w / 2 - rig.size.x * k / 2, top + IkkiuchiBoardStyle.tobiTop), k, rig);
    } else {
      const bandH = IkkiuchiBoardStyle.bandPortrait;
      g = FieldGeometry.of(field, folded: true);
      final fitH = (h - pad - IkkiuchiBoardStyle.bottomGap - bandH - IkkiuchiBoardStyle.tobiMinRoom) / (2 * g.height);
      s = [areaW / g.width, IkkiuchiBoardStyle.maxCardW / cardW, fitH].reduce(math.min);
      if (g.width * s < areaW) g = FieldGeometry.of(field, folded: true, minWidth: areaW / s);
      final height = 2 * g.height * s + bandH;
      top = h - IkkiuchiBoardStyle.bottomGap - height;
      left = pad + (areaW - g.width * s) / 2;
      band = Rect.fromLTWH(0, top + g.height * s, w, bandH);
      final th = math.min(IkkiuchiBoardStyle.tobiHeight, top - pad - IkkiuchiBoardStyle.tobiTopRoom);
      final k = th / rig.size.y;
      final feetY = top - IkkiuchiBoardStyle.tobiFeetGap;
      final probe = TobiFrame(Vec.zero, k, rig);
      tobi = TobiFrame(Vec(w / 2 - rig.size.x * k / 2, feetY - probe.feet.y), k, rig);
    }
    final halves = {
      IkkiuchiSide.tobi: Offset(left, top),
      IkkiuchiSide.player: Offset(left, top + g.height * s + band.height),
    };
    final cards = [
      for (final (side, fieldSide) in [(IkkiuchiSide.tobi, FieldSide.opponent), (IkkiuchiSide.player, FieldSide.own)])
        for (final MapEntry(key: id, value: r) in g.half(fieldSide).entries)
          (
            id: id,
            side: side,
            box: CardBox(
              Vec(halves[side]!.dx + (r.x + r.w / 2) * s, halves[side]!.dy + (r.y + r.h / 2) * s),
              r.w * s / 2,
              r.h * s / 2,
              side == IkkiuchiSide.tobi ? math.pi : 0,
            ),
          ),
    ];
    return IkkiuchiBoardLayout._(Vec(w, h), landscape, band, tobi, cards);
  }

  final Vec size;
  final bool landscape;
  final Rect band;
  final TobiFrame tobi;
  final List<({int id, IkkiuchiSide side, CardBox box})> cards;

  /// [cards] laid out as a side of [rows] rows at random: the cards split
  /// as evenly as they go between the rows, the most in 下段, and each row
  /// between its left and right groups.
  static List<IkkiuchiRow> randomSide(List<int> cards, int rows, math.Random rng) {
    final shuffled = [...cards]..shuffle(rng);
    final out = <IkkiuchiRow>[];
    var i = 0;
    for (var r = 0; r < rows; r++) {
      final n = cards.length ~/ rows + (r < cards.length % rows ? 1 : 0);
      final left = n ~/ 2 + (n.isOdd && rng.nextBool() ? 1 : 0);
      out.add(IkkiuchiRow(shuffled.sublist(i, i + left), shuffled.sublist(i + left, i + n)));
      i += n;
    }
    return out;
  }

  /// A side's rows as the shared field lays them out.
  static AnkirenHalf _half(List<IkkiuchiRow> rows) => AnkirenHalf([
        for (final r in FieldRow.values)
          r.index < rows.length
              ? AnkirenRow(left: rows[r.index].left, middle: const [], right: rows[r.index].right.reversed.toList())
              : AnkirenRow(left: const [], middle: const [], right: const []),
      ]);
}
