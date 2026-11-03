import 'dart:math' as math;

/// The rows of one half, from its owner outward: 下段, 中段, 上段 (the row at
/// the centre line).
enum FieldRow { lower, middle, upper }

/// The parts of one row, left to right as the half's owner sees it: the
/// left cluster, the open middle and the right cluster. A half's clusters
/// are its quadrants.
enum RowPart { left, middle, right }

/// A rectangle on the field, in the units of whatever lays the field out.
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
