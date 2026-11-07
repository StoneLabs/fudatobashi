// Shared by the tests that lay out 一騎打ち's sides.
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';

/// The player's [rows] with [n] of their cards moved into the open middle
/// of [IkkiuchiPlacingTuning.middleRow]: from the inner ends of its groups,
/// by turns from the left, then from 下段's once they are empty.
List<IkkiuchiRow> withMiddle(List<IkkiuchiRow> rows, int n) {
  final at = IkkiuchiPlacingTuning.middleRow.index;
  final groups = [
    for (final r in rows) [[...r.left], [...r.right]],
  ];
  final middle = <int>[];
  for (var i = 0; i < n; i++) {
    final from = [for (final r in [at, 0]) ...groups[r]].where((g) => g.isNotEmpty).toList();
    final group = from.length > 1 && i.isOdd ? from[1] : from.first;
    middle.add(group.removeLast());
  }
  return [
    for (final (r, [left, right]) in groups.indexed) IkkiuchiRow(left, right, middle: r == at ? middle : const []),
  ];
}
