import 'dart:math' as math;

import '../config/config.dart';
import 'ikkiuchi_geometry.dart';
import 'ikkiuchi_layout.dart';
import 'ikkiuchi_side.dart';

/// The full 一騎打ち field folded to its rows, in card widths: Tobi's side at
/// the top, turned to face him, the player's below, a gap between them.
/// Each row's groups lie at the field's edges, its open middle between
/// them; the field is never so narrow that a row's groups come nearer than
/// [leastGap]. Cards in a row's open middle spread evenly over the room
/// between the places at its groups' inner ends, the field never so narrow
/// that they come nearer the groups than [IkkiuchiPlacingTuning.middleMargin]
/// pitches. Only the rows some side uses are shown, or with [keepRows]
/// every row either side has, so that a field emptying keeps its rows in
/// place.
class IkkiuchiField {
  IkkiuchiField(
      {required this.tobi, required this.player, this.rowGap = IkkiuchiFieldTuning.rowGap, bool keepRows = false})
      : _shown = [
          for (var r = 0; r < math.max(tobi.length, player.length); r++)
            if (keepRows || [tobi, player].any((side) => r < side.length && side[r].length > 0)) r,
        ];

  /// Each side's rows as its owner sees them, 下段 first, each group from
  /// its outer edge in and the open middle left to right.
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

  /// The narrowest a row of [left] and [right] cards in its groups and
  /// [middle] in its open middle may be: its groups [leastGap] apart, or
  /// room between the places at their inner ends for its middle cards with
  /// [IkkiuchiPlacingTuning.middleMargin] pitches either side.
  static double rowWidth(int left, int right, {int middle = 0}) => middle == 0
      ? reach(left) + reach(right) + (left > 0 && right > 0 ? leastGap : 0)
      : (left + right + middle + 2 * IkkiuchiPlacingTuning.middleMargin) * pitch - IkkiuchiFieldTuning.cardGap;

  /// The room [row]'s middle cards spread over on a field [width] wide:
  /// from the place at its left group's inner end to the far edge of the
  /// place at its right group's.
  static ({double from, double to}) _open(IkkiuchiRow row, double width) =>
      (from: row.left.length * pitch, to: width - row.right.length * pitch);

  /// The left edge of the [index]th of [count] cards spread evenly over
  /// [open].
  static double _spread(({double from, double to}) open, int index, int count) =>
      open.from + (open.to - open.from) * (index + 1) / (count + 1) - 0.5;

  /// A half's height.
  double get halfHeight => _shown.length * cardH + (_shown.length - 1) * rowGap;

  /// Tobi's rows as the screen shows them, his 下段 at the top: the cards at
  /// the screen's left (his right group) and at its right.
  Iterable<({int left, int right})> get _tobiRows => [
        for (final r in _shown)
          r < tobi.length ? (left: tobi[r].right.length, right: tobi[r].left.length) : (left: 0, right: 0),
      ];

  /// The player's [row] (0 is 下段), empty where they have none.
  IkkiuchiRow _playerRow(int row) => row < player.length ? player[row] : const IkkiuchiRow([], []);

  /// How far Tobi's widest group reaches in from the screen's left, and
  /// from its right.
  ({double left, double right}) get _tobiReach => (
        left: _tobiRows.map((r) => reach(r.left)).reduce(math.max),
        right: _tobiRows.map((r) => reach(r.right)).reduce(math.max),
      );

  /// The narrowest the field may be: each row at least its [rowWidth], and
  /// with [tobiRoom] the open middle of Tobi's side at least that wide
  /// between the widest of his groups on each side.
  double leastWidth({double tobiRoom = 0}) => [
        for (final r in _tobiRows) rowWidth(r.left, r.right),
        for (final r in _shown.map(_playerRow)) rowWidth(r.left.length, r.right.length, middle: r.middle.length),
        if (tobiRoom > 0) _tobiReach.left + _tobiReach.right + tobiRoom,
      ].reduce(math.max);

  /// Where the open middle of Tobi's side is, across a field [width] wide:
  /// from the end of his widest group on the screen's left to the start of
  /// his widest on its right.
  ({double from, double to}) tobiOpen(double width) => (from: _tobiReach.left, to: width - _tobiReach.right);

  /// Where a card added at the inner end of the player's [row] (0 is 下段)
  /// would lie, in its [left] or right group, on a field [width] wide, the
  /// halves [gap] apart; null when the row is not shown or the card does
  /// not fit: the row with it would be narrower than its [rowWidth] allows.
  /// Where the two groups' places would overlap, only the left one is
  /// offered.
  CardBox? playerEnd(int row, {required bool left, required double width, required double gap}) {
    final i = _shown.indexOf(row);
    if (i < 0) return null;
    final r = _playerRow(row);
    bool fits(int l, int rt) => rowWidth(l, rt, middle: r.middle.length) <= width + _tolerance;
    final (l, rt) = (r.left.length, r.right.length);
    if (!fits(left ? l + 1 : l, left ? rt : rt + 1)) return null;
    final leftX = l * pitch, rightX = width - 1 - rt * pitch;
    if (!left && fits(l + 1, rt) && leftX + 1 > rightX) return null;
    return CardBox(Vec((left ? leftX : rightX) + 0.5, _playerTop(i, gap) + cardH / 2), 0.5, cardH / 2);
  }

  /// Where the open middle of the player's [row] takes taps and drops on a
  /// field [width] wide, the halves [gap] apart: its
  /// [IkkiuchiPlacingTuning.openMiddleShare] of the room its middle cards
  /// spread over, in the middle of it, at least a card wide where the room
  /// between its groups' cards is, and over its middle cards as they lie,
  /// but [leaving], a card of the player's being moved. Null when the row
  /// is not shown.
  CardBox? playerMiddle(int row, {int? leaving, required double width, required double gap}) {
    final i = _shown.indexOf(row);
    if (i < 0) return null;
    final r = _playerRow(row);
    final open = _open(r, width);
    final (lo, hi) = (reach(r.left.length), width - reach(r.right.length));
    final half = math.min(math.max((open.to - open.from) * IkkiuchiPlacingTuning.openMiddleShare, 1), hi - lo) / 2;
    var (from, to) = ((lo + hi) / 2 - half, (lo + hi) / 2 + half);
    for (final (j, id) in r.middle.indexed) {
      if (id == leaving) continue;
      final x = _spread(open, j, r.middle.length);
      (from, to) = (math.min(from, x), math.max(to, x + 1));
    }
    return CardBox(Vec((from + to) / 2, _playerTop(i, gap) + cardH / 2), (to - from) / 2, cardH / 2);
  }

  /// Where a card put in the open middle of the player's [row], with
  /// [index] of its middle cards left of it, would lie on a field [width]
  /// wide, the halves [gap] apart: the row's cards as they would be,
  /// [leaving] gone from it and the middle cards spread anew. Null when the
  /// row is not shown.
  CardBox? playerMiddleAt(int row, int index, {int? leaving, required double width, required double gap}) {
    final i = _shown.indexOf(row);
    if (i < 0) return null;
    final rest = _without(_playerRow(row), leaving);
    final count = rest.middle.length + 1;
    final x = _spread(_open(rest, width), index.clamp(0, count - 1), count);
    return CardBox(Vec(x + 0.5, _playerTop(i, gap) + cardH / 2), 0.5, cardH / 2);
  }

  /// [row] with [card] taken out of it.
  static IkkiuchiRow _without(IkkiuchiRow row, int? card) {
    if (card == null) return row;
    List<int> drop(List<int> cards) => [
          for (final c in cards)
            if (c != card) c,
        ];
    return IkkiuchiRow(drop(row.left), drop(row.right), middle: drop(row.middle));
  }

  /// The top of the player's [i]th row shown, the halves [gap] apart.
  double _playerTop(int i, double gap) => halfHeight + gap + (_shown.length - 1 - i) * (cardH + rowGap);

  static const _tolerance = 1e-9;

  /// Every card on a field [width] wide, from its top left, the halves
  /// [gap] apart; Tobi's cards turned to face him.
  List<({int id, IkkiuchiSide side, CardBox box})> layOut(double width, {required double gap}) {
    final rowPitch = cardH + rowGap;
    ({int id, IkkiuchiSide side, CardBox box}) card(int id, IkkiuchiSide side, double x, double y) => (
          id: id,
          side: side,
          box: CardBox(Vec(x + 0.5, y + cardH / 2), 0.5, cardH / 2, side == IkkiuchiSide.opponent ? math.pi : 0),
        );
    return [
      for (final (i, r) in _shown.indexed) ...[
        if (r < tobi.length) ...[
          for (final (j, id) in tobi[r].left.indexed) card(id, IkkiuchiSide.opponent, width - 1 - j * pitch, i * rowPitch),
          for (final (j, id) in tobi[r].right.indexed) card(id, IkkiuchiSide.opponent, j * pitch, i * rowPitch),
        ],
        if (r < player.length) ...[
          for (final (j, id) in player[r].left.indexed) card(id, IkkiuchiSide.player, j * pitch, _playerTop(i, gap)),
          for (final (j, id) in player[r].middle.indexed)
            card(id, IkkiuchiSide.player, _spread(_open(player[r], width), j, player[r].middle.length),
                _playerTop(i, gap)),
          for (final (j, id) in player[r].right.indexed)
            card(id, IkkiuchiSide.player, width - 1 - j * pitch, _playerTop(i, gap)),
        ],
      ],
    ];
  }
}
