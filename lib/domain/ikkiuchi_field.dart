import 'dart:math' as math;

import '../config/config.dart';
import 'ikkiuchi_cards.dart';
import 'ikkiuchi_geometry.dart';
import 'ikkiuchi_layout.dart';

/// The full 一騎打ち field folded to its rows, in card widths: Tobi's side at
/// the top, turned to face him, the player's below, a gap between them.
/// Each row's groups lie at the field's edges, its open middle between
/// them; the field is never so narrow that a row's groups come nearer than
/// [leastGap]. Only the rows some side uses are shown.
class IkkiuchiField {
  IkkiuchiField({required this.tobi, required this.player, this.rowGap = IkkiuchiFieldTuning.rowGap})
      : _shown = [
          for (var r = 0; r < math.max(tobi.length, player.length); r++)
            if ([tobi, player].any((side) => r < side.length && side[r].length > 0)) r,
        ];

  /// Each side's rows as its owner sees them, 下段 first, each group from
  /// its outer edge in.
  final List<IkkiuchiRow> tobi, player;

  /// The gap between a side's rows, in card widths.
  final double rowGap;

  /// The rows shown, by index into a side's rows.
  final List<int> _shown;

  /// A card and the gap after it, across.
  static const double pitch = 1 + IkkiuchiFieldTuning.cardGap;

  /// A card's height.
  static const double cardH = IkkiuchiFieldTuning.cardAspect;

  /// The least open middle between a row's groups:
  /// [IkkiuchiLayoutTuning.groupGap] pitches.
  static const double leastGap = IkkiuchiLayoutTuning.groupGap * pitch + IkkiuchiFieldTuning.cardGap;

  /// How far a group of [n] cards reaches in from its edge.
  static double reach(int n) => n == 0 ? 0 : n * pitch - IkkiuchiFieldTuning.cardGap;

  /// A half's height.
  double get halfHeight => _shown.length * cardH + (_shown.length - 1) * rowGap;

  /// Tobi's rows as the screen shows them, his 下段 at the top: the cards at
  /// the screen's left (his right group) and at its right.
  Iterable<({int left, int right})> get _tobiRows => [
        for (final r in _shown)
          r < tobi.length ? (left: tobi[r].right.length, right: tobi[r].left.length) : (left: 0, right: 0),
      ];

  Iterable<({int left, int right})> get _playerRows => [
        for (final r in _shown)
          r < player.length ? (left: player[r].left.length, right: player[r].right.length) : (left: 0, right: 0),
      ];

  /// How far Tobi's widest group reaches in from the screen's left, and
  /// from its right.
  ({double left, double right}) get _tobiReach => (
        left: _tobiRows.map((r) => reach(r.left)).reduce(math.max),
        right: _tobiRows.map((r) => reach(r.right)).reduce(math.max),
      );

  /// The narrowest the field may be: each row's groups [leastGap] apart at
  /// least, and with [tobiRoom] the open middle of Tobi's side at least that
  /// wide between the widest of his groups on each side.
  double leastWidth({double tobiRoom = 0}) {
    double row(({int left, int right}) r) =>
        reach(r.left) + reach(r.right) + (r.left > 0 && r.right > 0 ? leastGap : 0);
    return [
      for (final r in [..._tobiRows, ..._playerRows]) row(r),
      if (tobiRoom > 0) _tobiReach.left + _tobiReach.right + tobiRoom,
    ].reduce(math.max);
  }

  /// Where the open middle of Tobi's side is, across a field [width] wide:
  /// from the end of his widest group on the screen's left to the start of
  /// his widest on its right.
  ({double from, double to}) tobiOpen(double width) => (from: _tobiReach.left, to: width - _tobiReach.right);

  /// Where a card added at the inner end of the player's [row] (0 is 下段)
  /// would lie, in its [left] or right group, on a field [width] wide, the
  /// halves [gap] apart; null when the row is not shown or the card does
  /// not fit: the row with it would be wider than the field or its groups
  /// nearer than [leastGap]. Where the two groups' places would overlap,
  /// only the left one is offered.
  CardBox? playerEnd(int row, {required bool left, required double width, required double gap}) {
    final i = _shown.indexOf(row);
    if (i < 0) return null;
    final r = row < player.length ? player[row] : const IkkiuchiRow([], []);
    bool fits(int l, int rt) => reach(l) + reach(rt) + (l > 0 && rt > 0 ? leastGap : 0) <= width + _tolerance;
    final (l, rt) = (r.left.length, r.right.length);
    if (!fits(left ? l + 1 : l, left ? rt : rt + 1)) return null;
    final leftX = l * pitch, rightX = width - 1 - rt * pitch;
    if (!left && fits(l + 1, rt) && leftX + 1 > rightX) return null;
    final rowPitch = cardH + rowGap;
    final y = halfHeight + gap + (_shown.length - 1 - i) * rowPitch;
    return CardBox(Vec((left ? leftX : rightX) + 0.5, y + cardH / 2), 0.5, cardH / 2);
  }

  static const _tolerance = 1e-9;

  /// Every card on a field [width] wide, from its top left, the halves
  /// [gap] apart; Tobi's cards turned to face him.
  List<({int id, IkkiuchiSide side, CardBox box})> layOut(double width, {required double gap}) {
    final rowPitch = cardH + rowGap;
    final playerTop = halfHeight + gap;
    final n = _shown.length;
    ({int id, IkkiuchiSide side, CardBox box}) card(int id, IkkiuchiSide side, double x, double y) => (
          id: id,
          side: side,
          box: CardBox(Vec(x + 0.5, y + cardH / 2), 0.5, cardH / 2, side == IkkiuchiSide.tobi ? math.pi : 0),
        );
    return [
      for (final (i, r) in _shown.indexed) ...[
        if (r < tobi.length) ...[
          for (final (j, id) in tobi[r].left.indexed) card(id, IkkiuchiSide.tobi, width - 1 - j * pitch, i * rowPitch),
          for (final (j, id) in tobi[r].right.indexed) card(id, IkkiuchiSide.tobi, j * pitch, i * rowPitch),
        ],
        if (r < player.length) ...[
          for (final (j, id) in player[r].left.indexed)
            card(id, IkkiuchiSide.player, j * pitch, playerTop + (n - 1 - i) * rowPitch),
          for (final (j, id) in player[r].right.indexed)
            card(id, IkkiuchiSide.player, width - 1 - j * pitch, playerTop + (n - 1 - i) * rowPitch),
        ],
      ],
    ];
  }
}
