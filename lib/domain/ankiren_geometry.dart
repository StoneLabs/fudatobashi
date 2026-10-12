import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_field.dart';

/// A rectangle on the field, in centimetres.
class FieldRect {
  const FieldRect(this.x, this.y, this.w, this.h);

  final double x, y, w, h;

  double get right => x + w;
  double get bottom => y + h;

  bool overlaps(FieldRect o) => x < o.right && o.x < right && y < o.bottom && o.y < bottom;

  /// This rectangle turned 180° within a [width] × [height] area.
  FieldRect turned(double width, double height) => FieldRect(width - right, height - bottom, w, h);

  @override
  String toString() => 'FieldRect($x, $y, $w × $h)';
}

/// Where every card of a field lies, in real centimetres
/// ([AnkirenFieldSize]). Each half has its own coordinates, origin at the top
/// left as the screen shows it: the own half as its owner sees it (上段 at the
/// top, by the centre line), the opponent's turned 180° (its 下段 at the top,
/// its owner's left on the screen's right). Both halves are the same size.
///
/// True scale lays a half out over the real territory's [AnkirenFieldSize.slots]
/// card slots, all three rows. Folded keeps only the rows some half uses
/// and is as wide as its widest row with that row's open middle closed to
/// [AnkirenFieldSize.foldedHole] pitches, or to room for its middle cards
/// (or as wide as asked, opening the middles up). Either way the left
/// cluster starts at the half's left edge, the right one ends at its right
/// edge, and middle cards are spread evenly over their row's open gap.
class FieldGeometry {
  FieldGeometry._(this.width, this.height, this._halves);

  final double width;
  final double height;
  final List<Map<int, FieldRect>> _halves;

  /// The cards of one half, by poem id.
  Map<int, FieldRect> half(FieldSide side) => _halves[side.index];

  static const double _pitch = AnkirenFieldSize.cardW + AnkirenFieldSize.cardGap;
  static const double _rowPitch = AnkirenFieldSize.cardH + AnkirenFieldSize.rowGap;

  /// [minWidth] (folded only, cm) widens the open middles so the clusters
  /// reach out that far.
  factory FieldGeometry.of(AnkirenField field, {required bool folded, double minWidth = 0}) {
    final halves = [field.own, field.opponent];
    final rowsShown = [
      for (final r in FieldRow.values)
        if (!folded || halves.any((h) => !h.row(r).isEmpty)) r,
    ];
    final height = rowsShown.length * AnkirenFieldSize.cardH + (rowsShown.length - 1) * AnkirenFieldSize.rowGap;

    final double slots, x0, width;
    if (folded) {
      double rowSlots(AnkirenRow r) =>
          r.left.length +
          r.right.length +
          (r.middle.isEmpty
              ? AnkirenFieldSize.foldedHole
              : math.max(AnkirenFieldSize.foldedHole, r.middle.length + 2 * AnkirenFieldSize.middleMargin));
      slots = [
        for (final h in halves) ...h.rows.map(rowSlots),
        (minWidth + AnkirenFieldSize.cardGap) / _pitch,
      ].reduce(math.max);
      x0 = 0;
      width = slots * _pitch - AnkirenFieldSize.cardGap;
    } else {
      slots = AnkirenFieldSize.slots.toDouble();
      width = AnkirenFieldSize.territoryW;
      x0 = (width - slots * _pitch + AnkirenFieldSize.cardGap) / 2;
    }

    Map<int, FieldRect> layOut(AnkirenHalf half, {required bool turned}) {
      final rects = <int, FieldRect>{};
      void put(int poemId, double x, double y) {
        final r = FieldRect(x, y, AnkirenFieldSize.cardW, AnkirenFieldSize.cardH);
        rects[poemId] = turned ? r.turned(width, height) : r;
      }

      for (final row in FieldRow.values) {
        final cards = half.row(row);
        if (cards.isEmpty) continue;
        final y = (rowsShown.length - 1 - rowsShown.indexOf(row)) * _rowPitch;
        final rightStart = slots - cards.right.length;
        for (final (j, id) in cards.left.indexed) {
          put(id, x0 + j * _pitch, y);
        }
        for (final (j, id) in cards.right.indexed) {
          put(id, x0 + (rightStart + j) * _pitch, y);
        }
        final gapStart = x0 + cards.left.length * _pitch;
        final gap = x0 + rightStart * _pitch - AnkirenFieldSize.cardGap - gapStart;
        final step = gap / (cards.middle.length + 1);
        for (final (i, id) in cards.middle.indexed) {
          put(id, gapStart + (i + 1) * step - AnkirenFieldSize.cardW / 2, y);
        }
      }
      return Map.unmodifiable(rects);
    }

    return FieldGeometry._(width, height, [
      layOut(field.own, turned: false),
      layOut(field.opponent, turned: true),
    ]);
  }
}
