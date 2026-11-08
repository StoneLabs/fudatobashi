import '../config/config.dart';
import 'ikkiuchi_match.dart';
import 'ikkiuchi_side.dart';

/// Who a 一騎打ち match is played against, across the board. Stored by
/// name.
enum IkkiuchiOpponent { tobi }

/// A match's setup: ranked or free play, the opponent and their rating,
/// the cards dealt to each side, and the memory time before play.
class IkkiuchiSetup {
  const IkkiuchiSetup({
    required this.ranked,
    required this.opponent,
    required this.opponentRating,
    required this.perSide,
    required this.memorise,
  });

  /// A free match against Tobi.
  const IkkiuchiSetup.free({required this.opponentRating, required this.perSide, required this.memorise})
      : ranked = false,
        opponent = IkkiuchiOpponent.tobi;

  /// The free setup before any free match.
  static const firstFree = IkkiuchiSetup.free(
    opponentRating: IkkiuchiFreeTuning.rating,
    perSide: IkkiuchiFreeTuning.perSide,
    memorise: IkkiuchiFreeTuning.memorise,
  );

  final bool ranked;
  final IkkiuchiOpponent opponent;
  final double opponentRating;
  final int perSide;
  final Duration memorise;
}

/// Free play's choices of each part of its setup, from the least to the
/// most by its step ([IkkiuchiFreeTuning]).
abstract final class IkkiuchiFreeChoices {
  static final List<int> perSide = [
    for (var n = IkkiuchiFreeTuning.perSideMin; n <= IkkiuchiFreeTuning.perSideMax; n += IkkiuchiFreeTuning.perSideStep) n,
  ];

  static final List<Duration> memorise = [
    for (var d = IkkiuchiFreeTuning.memoriseMin; d <= IkkiuchiFreeTuning.memoriseMax; d += IkkiuchiFreeTuning.memoriseStep)
      d,
  ];

  static final List<double> opponentRating = [
    for (var r = IkkiuchiFreeTuning.ratingMin; r <= IkkiuchiFreeTuning.ratingMax; r += IkkiuchiFreeTuning.ratingStep) r,
  ];
}

/// How a match ended for the player.
enum IkkiuchiResult {
  /// Played to its end with fewer cards left than the opponent: the
  /// player's side was emptied first.
  won,

  /// Played to its end otherwise.
  lost,

  /// The player ended it (終了) or left it before its end; a loss when
  /// ranked.
  gaveUp,
}

/// One read of a match, once it has ended: the card read ([poemId]), the
/// side it lay on and who took it, both null on a からふだ; whether both
/// took it at the same time; the sides each player faulted on (お手つき),
/// 0 to 2; and when each reached the card from its deciding sound,
/// negative for one before it, null for one who never did.
class IkkiuchiReadLog {
  const IkkiuchiReadLog({
    required this.poemId,
    this.cardSide,
    this.taker,
    this.tied = false,
    this.playerFaults = 0,
    this.opponentFaults = 0,
    this.playerTake,
    this.opponentTake,
  });

  /// [poemId]'s read, which ended in [end].
  IkkiuchiReadLog.of(this.poemId, IkkiuchiReadEnd end, {this.playerTake, this.opponentTake})
      : cardSide = end.cardSide,
        taker = end.taker,
        tied = end.tied,
        playerFaults = end.playerFaults.length,
        opponentFaults = end.tobiFaults.length;

  final int poemId;
  final IkkiuchiSide? cardSide, taker;
  final bool tied;
  final int playerFaults, opponentFaults;
  final Duration? playerTake, opponentTake;

  bool get karafuda => cardSide == null;
}

/// A match once it is over, as it is stored: its setup, when it ran,
/// whether it was played to its end, the cards left on each side, and every
/// read in order. Its [id], and the player's [rating] after a ranked match,
/// come with storing it ([stored]).
class IkkiuchiMatchRecord {
  const IkkiuchiMatchRecord({
    this.id,
    required this.setup,
    required this.startedAt,
    required this.endedAt,
    required this.completed,
    required this.playerLeft,
    required this.opponentLeft,
    this.rating,
    this.reads = const [],
  });

  /// Its row's id; null until it is stored.
  final int? id;

  final IkkiuchiSetup setup;
  final DateTime startedAt, endedAt;

  /// Played to its end, a side emptied; false when the player ended it
  /// (終了) or left it.
  final bool completed;

  final int playerLeft, opponentLeft;

  /// The player's 一騎打ち rating after this ranked match; null for free
  /// play, and until it is stored.
  final double? rating;

  final List<IkkiuchiReadLog> reads;

  bool get ranked => setup.ranked;

  IkkiuchiResult get result => !completed
      ? IkkiuchiResult.gaveUp
      : playerLeft < opponentLeft
          ? IkkiuchiResult.won
          : IkkiuchiResult.lost;

  /// The faults (お手つき) each made over the match, a fault on both sides of
  /// one read counting two.
  int get playerFaults => reads.fold(0, (n, r) => n + r.playerFaults);
  int get opponentFaults => reads.fold(0, (n, r) => n + r.opponentFaults);

  /// This match as stored, under [id], with the player's [rating] after it.
  IkkiuchiMatchRecord stored({required int id, required double? rating}) => IkkiuchiMatchRecord(
        id: id,
        setup: setup,
        startedAt: startedAt,
        endedAt: endedAt,
        completed: completed,
        playerLeft: playerLeft,
        opponentLeft: opponentLeft,
        rating: rating,
        reads: reads,
      );
}
