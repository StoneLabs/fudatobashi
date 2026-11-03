import 'dart:math' as math;

import '../config/config.dart';
import 'ikkiuchi_geometry.dart';
import 'ikkiuchi_strike.dart';
import 'ikkiuchi_tobi.dart';

/// What went wrong first on a call, if anything.
enum IkkiuchiSlip {
  /// He went for a look-alike (友札 or a card whose torifuda looks alike).
  lookAlike,

  /// On a からふだ with no look-alike on the field, he touched a card anyway.
  stray,
}

/// What Tobi does on one call (一騎打ち): when his reach starts, how long it
/// takes, which move, and whether he goes for a wrong card first.
///
/// His take time (reaction plus swing, at the average arm distance) is
/// drawn per card around its curve's median, nudged by the card's
/// distance, plus a search on a blank; the hit lands then. His reach (the
/// strike's animation, from its curve) ends at the hit: a quick take
/// squeezes it, never under [IkkiuchiTuning.reachFloorMs]. His reaction is
/// what comes before it.
class IkkiuchiRead {
  const IkkiuchiRead({
    required this.called,
    required this.onField,
    required this.move,
    required this.reachMs,
    required this.correctionReachMs,
    this.reactionMs = 0,
    this.takeMs,
    this.searchMs,
    this.wrong,
    this.slip,
  });

  /// The card read, and whether it is on the field (else a からふだ).
  final int called;
  final bool onField;
  final IkkiuchiMove move;

  /// Ms from the call to the start of his reach, and from there to the hit.
  final double reactionMs;
  final double reachMs;

  /// The reach of his strike at the called card after a wrong one: his
  /// reach curve's, unsqueezed.
  final double correctionReachMs;

  /// His take time drawn for the card, and what a blank added; null when
  /// he struck at once.
  final double? takeMs;
  final double? searchMs;

  /// The card he goes for first, and why; null for a clean take.
  final int? wrong;
  final IkkiuchiSlip? slip;

  /// Whether his arm moves at all.
  bool get strikes => onField || wrong != null;

  /// Tobi at [rating] on a call of [called], with [field] the cards on the
  /// field and where they lie, [from] the middle of his shoulders, and
  /// [alike] telling look-alikes apart. With [now] he strikes at once, with
  /// no reaction; without [mistakes] every strike is clean. His move is
  /// picked among [moves] (all when null, else at least one) by his
  /// rating's shares.
  factory IkkiuchiRead.decide({
    required double rating,
    required int called,
    required Map<int, CardBox> field,
    required Vec from,
    required bool Function(int a, int b) alike,
    required math.Random rng,
    bool now = false,
    bool mistakes = true,
    Set<IkkiuchiMove>? moves,
  }) {
    final tobi = IkkiuchiTobi(rating);
    final move = _pickMove(tobi, rng.nextDouble(), moves);
    final takeZ = _normal(rng), blankU = rng.nextDouble(), searchZ = _normal(rng);
    final slipU = rng.nextDouble(), wrongU = rng.nextDouble();
    final onField = field.containsKey(called);

    int? wrong;
    IkkiuchiSlip? slip;
    if (mistakes) {
      final alikes = [
        for (final id in field.keys)
          if (alike(id, called)) id,
      ]..sort();
      if (alikes.isNotEmpty && slipU < tobi.lookAlikePull) {
        wrong = alikes[(wrongU * alikes.length).floor()];
        slip = IkkiuchiSlip.lookAlike;
      } else if (!onField && alikes.isEmpty && slipU < tobi.strayChance) {
        final all = field.keys.toList()..sort();
        wrong = all[(wrongU * all.length).floor()];
        slip = IkkiuchiSlip.stray;
      }
    }
    final reach = IkkiuchiTobi.hitReach(tobi.reachMs);
    final first = wrong ?? (onField ? called : null);
    if (now || first == null) {
      return IkkiuchiRead(
          called: called, onField: onField, move: move, reachMs: reach, correctionReachMs: reach, wrong: wrong, slip: slip);
    }

    final take = tobi.takeMs * math.exp(takeZ * tobi.takeSpread);
    final search = blankU < tobi.blankChance ? tobi.searchMs * math.exp(searchZ * IkkiuchiTuning.searchSpread) : null;
    final distances = [for (final box in field.values) box.centre.distanceTo(from)];
    final mean = distances.reduce((a, b) => a + b) / distances.length;
    final distance = field[first]!.centre.distanceTo(from) / mean;
    final hit = math.max(
      IkkiuchiTuning.reachFloorMs,
      take + tobi.armMsAt(distance) - tobi.armMs + (search ?? 0),
    );
    final squeezed = IkkiuchiTobi.hitReach(math.min(tobi.reachMs, hit));
    return IkkiuchiRead(
      called: called,
      onField: onField,
      move: move,
      reachMs: squeezed,
      correctionReachMs: reach,
      reactionMs: hit - squeezed,
      takeMs: take,
      searchMs: search,
      wrong: wrong,
      slip: slip,
    );
  }

  /// One of [moves] (all when null) by his rating's shares among them,
  /// [u] in 0..1; evenly when none of them has a share.
  static IkkiuchiMove _pickMove(IkkiuchiTobi tobi, double u, Set<IkkiuchiMove>? moves) {
    final shares = tobi.moves;
    final open = [
      for (final (move, share) in [
        (IkkiuchiMove.sweep, shares.sweep),
        (IkkiuchiMove.whip, shares.whip),
        (IkkiuchiMove.coilLunge, shares.coilLunge),
        (IkkiuchiMove.smear, shares.smear),
      ])
        if (moves == null || moves.contains(move)) (move, share),
    ];
    final total = open.fold(0.0, (sum, m) => sum + m.$2);
    var acc = 0.0;
    for (final (move, share) in open) {
      acc += total > 0 ? share / total : 1 / open.length;
      if (u < acc) return move;
    }
    return open.last.$1;
  }

  /// A standard normal draw (Box-Muller).
  static double _normal(math.Random rng) {
    final u = 1 - rng.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * rng.nextDouble());
  }
}
