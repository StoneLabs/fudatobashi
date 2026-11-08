import '../config/config.dart';
import 'ikkiuchi_cards.dart';
import 'ikkiuchi_match.dart';

/// A free 一騎打ち match's setup: the cards dealt to each side, the memory
/// time before play, and Tobi's rating.
class IkkiuchiSetup {
  const IkkiuchiSetup({required this.perSide, required this.memorise, required this.rating});

  /// The setup a first match starts on.
  static const first = IkkiuchiSetup(
    perSide: IkkiuchiFreeTuning.perSide,
    memorise: IkkiuchiFreeTuning.memorise,
    rating: IkkiuchiFreeTuning.rating,
  );

  final int perSide;
  final Duration memorise;
  final double rating;

  @override
  bool operator ==(Object other) =>
      other is IkkiuchiSetup && other.perSide == perSide && other.memorise == memorise && other.rating == rating;

  @override
  int get hashCode => Object.hash(perSide, memorise, rating);
}

/// How a match ended for the player. Stored by name.
enum IkkiuchiResult {
  /// The player's side was emptied first.
  won,

  /// Tobi's side was emptied first.
  lost,

  /// The player ended the match (終了, or leaving the screen).
  gaveUp;

  /// The result of a match that ended with [playerLeft] and [tobiLeft]
  /// cards on the sides, [gaveUp] when the player ended it. A match whose
  /// reads ran out with both sides still holding cards goes to the side
  /// with fewer.
  static IkkiuchiResult of({required int playerLeft, required int tobiLeft, required bool gaveUp}) {
    if (gaveUp) return IkkiuchiResult.gaveUp;
    if (playerLeft == 0) return IkkiuchiResult.won;
    if (tobiLeft == 0) return IkkiuchiResult.lost;
    return playerLeft < tobiLeft ? IkkiuchiResult.won : IkkiuchiResult.lost;
  }
}

/// One read of a match and how it ended ([end]): the card read ([poemId],
/// a からふだ when [IkkiuchiReadEnd.cardSide] is null), and when each player
/// reached it, from its deciding sound; null for one who never did.
class IkkiuchiReadLog {
  const IkkiuchiReadLog({required this.poemId, required this.end, this.playerTake, this.tobiTake});

  final int poemId;
  final IkkiuchiReadEnd end;
  final Duration? playerTake, tobiTake;
}

/// A match once it is over, as it is stored: its setup, when it ran, how it
/// ended, the cards left on each side, and every read in order.
class IkkiuchiMatchRecord {
  const IkkiuchiMatchRecord({
    required this.setup,
    required this.startedAt,
    required this.endedAt,
    required this.result,
    required this.playerLeft,
    required this.tobiLeft,
    required this.reads,
  });

  final IkkiuchiSetup setup;
  final DateTime startedAt, endedAt;
  final IkkiuchiResult result;
  final int playerLeft, tobiLeft;
  final List<IkkiuchiReadLog> reads;

  /// The faults (お手つき) [side] made over the match, a fault on both sides
  /// of one read counting two.
  int faultsOf(IkkiuchiSide side) => reads.fold(
      0, (sum, r) => sum + (side == IkkiuchiSide.player ? r.end.playerFaults : r.end.tobiFaults).length);
}
