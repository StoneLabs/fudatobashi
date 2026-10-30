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

  bool contains(double px, double py) => px >= x && px < right && py >= y && py < bottom;

  /// The smallest rectangle around this one and [o].
  FieldRect union(FieldRect o) {
    final left = math.min(x, o.x), top = math.min(y, o.y);
    return FieldRect(left, top, math.max(right, o.right) - left, math.max(bottom, o.bottom) - top);
  }

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
/// card slots (or as many as asked), all three rows. Folded keeps only the
/// rows some half uses and is as wide as its widest row with that row's
/// open middle closed to [AnkirenFieldSize.foldedHole] pitches, or to room
/// for its middle cards (or as wide as asked, opening the middles up).
/// Either way the left cluster starts at the half's left edge, the right one
/// ends at its right edge, and middle cards are spread evenly over their
/// row's open gap.
class FieldGeometry {
  FieldGeometry._(this.width, this.height, this.slots, this._x0, this._rows);

  final double width;
  final double height;

  /// How many card pitches (card and gap) a row spans.
  final double slots;
  final double _x0;
  final List<FieldRow> _rows;
  late final List<Map<int, FieldRect>> _halves;

  /// The cards of one half, by poem id.
  Map<int, FieldRect> half(FieldSide side) => _halves[side.index];

  static const double pitch = AnkirenFieldSize.cardW + AnkirenFieldSize.cardGap;
  static const double _rowPitch = AnkirenFieldSize.cardH + AnkirenFieldSize.rowGap;

  /// [minWidth] (folded only, cm) widens the open middles so the clusters
  /// reach out that far; [trueSlots] (true scale only) is how many card
  /// pitches a row spans, the territory's own when not given.
  factory FieldGeometry.of(AnkirenField field, {required bool folded, double minWidth = 0, double? trueSlots}) {
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
        (minWidth + AnkirenFieldSize.cardGap) / pitch,
      ].reduce(math.max);
      x0 = 0;
      width = slots * pitch - AnkirenFieldSize.cardGap;
    } else {
      slots = trueSlots ?? AnkirenFieldSize.slots.toDouble();
      final span = slots * pitch - AnkirenFieldSize.cardGap;
      width = math.max(AnkirenFieldSize.territoryW, span);
      x0 = (width - span) / 2;
    }

    final geometry = FieldGeometry._(width, height, slots, x0, rowsShown);
    Map<int, FieldRect> layOut(FieldSide side) {
      final rects = <int, FieldRect>{};
      void put(int poemId, FieldRect r) => rects[poemId] = side == FieldSide.opponent ? r.turned(width, height) : r;

      for (final row in rowsShown) {
        final cards = field.half(side).row(row);
        if (cards.isEmpty) continue;
        final rightStart = slots - cards.right.length;
        for (final (j, id) in cards.left.indexed) {
          put(id, geometry.slot(row, j.toDouble())!);
        }
        for (final (j, id) in cards.right.indexed) {
          put(id, geometry.slot(row, rightStart + j)!);
        }
        final (gapStart, gapEnd) = geometry.gapOf(cards);
        final step = (gapEnd - gapStart) / (cards.middle.length + 1);
        final top = geometry.rowTop(row)!;
        for (final (i, id) in cards.middle.indexed) {
          put(id, FieldRect(gapStart + (i + 1) * step - AnkirenFieldSize.cardW / 2, top, AnkirenFieldSize.cardW,
              AnkirenFieldSize.cardH));
        }
      }
      return Map.unmodifiable(rects);
    }

    return geometry.._halves = [for (final side in FieldSide.values) layOut(side)];
  }

  /// How far down [row] lies in a half as its owner sees it, or null when
  /// the row is not shown.
  double? rowTop(FieldRow row) {
    final i = _rows.indexOf(row);
    return i < 0 ? null : (_rows.length - 1 - i) * _rowPitch;
  }

  /// The card place [slot] pitches in from the left edge of a half as its
  /// owner sees it, in [row]; null when the row is not shown.
  FieldRect? slot(FieldRow row, double slot) {
    final top = rowTop(row);
    return top == null ? null : FieldRect(_x0 + slot * pitch, top, AnkirenFieldSize.cardW, AnkirenFieldSize.cardH);
  }

  /// Where the open gap between [row]'s clusters starts and ends, across a
  /// half as its owner sees it.
  (double, double) gapOf(AnkirenRow row) =>
      (_x0 + row.left.length * pitch, _x0 + (slots - row.right.length) * pitch - AnkirenFieldSize.cardGap);
}
