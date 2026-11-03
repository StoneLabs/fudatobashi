import 'dart:math' as math;

import '../config/config.dart';

/// Tobi's values in a match (一騎打ち) at [rating], each read from its curve
/// in [IkkiuchiTuning]. A match reads them at his rating plus his form.
class IkkiuchiTobi {
  const IkkiuchiTobi(this.rating);

  final double rating;

  /// Median time to land on a card he knows, ms.
  double get takeMs => IkkiuchiTuning.takeMs.at(rating);

  /// The spread of [takeMs] from card to card, as the standard deviation
  /// of its log.
  double get takeSpread => IkkiuchiTuning.takeSpread.at(rating);
  double get blankChance => IkkiuchiTuning.blankChance.at(rating);

  /// Median extra time a blank costs him, ms.
  double get searchMs => IkkiuchiTuning.searchMs.at(rating);
  double get lookAlikePull => IkkiuchiTuning.lookAlikePull.at(rating);

  /// His chance to touch a card on a からふだ with no look-alike on the field.
  double get strayChance => lookAlikePull * IkkiuchiTuning.strayShare;

  /// His arm's swing at the average distance, ms.
  double get armMs => IkkiuchiTuning.armMs.at(rating);

  /// His arm's swing to a card [distance] times the average distance away.
  double armMsAt(double distance) => armMs * (1 + IkkiuchiTuning.armDistanceWeight * (distance - 1));

  /// The take's animation from the start of his reach to the hit, ms.
  double get reachMs => IkkiuchiTuning.reachMs.at(rating);
  double get smartSend => IkkiuchiTuning.smartSend.at(rating);
  double get placingSeconds => IkkiuchiTuning.placingSeconds.at(rating);

  /// The chances that, in a match, his layout keeps each group of cards
  /// with the same first sound together, and each family of 友札 side by
  /// side.
  double get soundGrouping => IkkiuchiLayoutTuning.soundGrouping.at(rating);
  double get tomofudaGrouping => IkkiuchiLayoutTuning.tomofudaGrouping.at(rating);

  /// The shares of his four arm moves, adding up to 1: the sweep's from its
  /// curve, the rest split between the wild moves.
  ({double sweep, double whip, double coilLunge, double smear}) get moves {
    final sweep = IkkiuchiTuning.sweepShare.at(rating);
    const wild = IkkiuchiTuning.wildMoves;
    return (
      sweep: sweep,
      whip: (1 - sweep) * wild.whip,
      coilLunge: (1 - sweep) * wild.coilLunge,
      smear: (1 - sweep) * wild.smear,
    );
  }

  /// The reach a hit takes when it would take [ms]: never under
  /// [IkkiuchiTuning.reachFloorMs].
  static double hitReach(double ms) => math.max(IkkiuchiTuning.reachFloorMs, ms);
}
