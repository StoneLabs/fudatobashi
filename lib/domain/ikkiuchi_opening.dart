import 'dart:math' as math;

import '../config/config.dart';
import 'ikkiuchi_layout.dart';
import 'ikkiuchi_tobi.dart';

/// Tobi laying out his side as a match (一騎打ち) opens, while the player
/// lays out theirs: his arm takes his cards from his hand to their homes in
/// [order], one at a time, each [per] after the last, so that he is done
/// once [ms] has gone by.
class IkkiuchiTobiOpening {
  IkkiuchiTobiOpening(List<IkkiuchiRow> side, {required this.ms, required math.Random rng}) : order = orderOf(side, rng);

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

  /// The cards of [side] in the order he lays them down: at random, drawn
  /// from [rng].
  static List<int> orderOf(List<IkkiuchiRow> side, math.Random rng) => [
        for (final row in side) ...[...row.left, ...row.middle, ...row.right],
      ]..shuffle(rng);

  /// His placing time at [rating], in his form, for his [cards], ms: his
  /// time per card (`IkkiuchiTuning.placingMsPerCard`) for each, squeezed
  /// when a short [memorise] needs it so that he is done
  /// [IkkiuchiMatchTuning.tobiPlacingLead] before it is up.
  static double msFor(double rating, {required int cards, required Duration memorise}) {
    final own = IkkiuchiTobi(rating).placingMsPerCard * cards;
    final room = (memorise - IkkiuchiMatchTuning.tobiPlacingLead).inMicroseconds / Duration.microsecondsPerMillisecond;
    return math.max(0.0, math.min(own, room));
  }
}
