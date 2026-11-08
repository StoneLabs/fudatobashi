import 'dart:math' as math;

import '../config/config.dart';
import 'ikkiuchi_layout.dart';
import 'ikkiuchi_tobi.dart';

/// Tobi laying out his side as a match (一騎打ち) opens, while the player
/// lays out theirs: his arm takes his cards from his hand to their homes in
/// [order], one at a time, each [per] after the last, so that he is done
/// once [ms] has gone by.
class IkkiuchiTobiOpening {
  IkkiuchiTobiOpening(List<IkkiuchiRow> side, {required this.ms}) : order = orderOf(side);

  /// His cards in the order he lays them down.
  final List<int> order;

  /// His whole placing time, ms.
  final double ms;

  /// Each card's share of [ms], from the start of its carry to the next's.
  double get per => order.isEmpty ? ms : ms / order.length;

  /// When the carry of the [i]th card of [order] starts, ms from the start.
  double startOf(int i) => i * per;

  /// How long his arm carries each card to its home, and goes back: as
  /// when he sends one, but no more than their shares of [per]
  /// ([IkkiuchiCarryTuning.layShare]).
  double get carryMs => math.min(IkkiuchiCarryTuning.carry, per * IkkiuchiCarryTuning.layShare.carry);
  double get backMs => math.min(IkkiuchiCarryTuning.back, per * IkkiuchiCarryTuning.layShare.back);

  /// The cards of [side] (his rows as he sees them, 下段 first) in the
  /// order he lays them down: row by row from his 下段, by turns from the
  /// outer edges of his left and right groups inward.
  static List<int> orderOf(List<IkkiuchiRow> side) => [
        for (final row in side)
          for (var i = 0; i < math.max(row.left.length, row.right.length); i++) ...[
            if (i < row.left.length) row.left[i],
            if (i < row.right.length) row.right[i],
          ],
      ];

  /// His placing time at [rating], in his form, ms: his placing time
  /// (`IkkiuchiTuning.placingSeconds`), squeezed when a short [memorise]
  /// needs it so that he is done [IkkiuchiMatchTuning.tobiPlacingLead]
  /// before it is up.
  static double msFor(double rating, Duration memorise) {
    final own = IkkiuchiTobi(rating).placingSeconds * Duration.millisecondsPerSecond;
    final room = (memorise - IkkiuchiMatchTuning.tobiPlacingLead).inMicroseconds / Duration.microsecondsPerMillisecond;
    return math.max(0.0, math.min(own, room));
  }
}
