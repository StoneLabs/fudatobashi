import 'dart:math' as math;

import '../config/config.dart';
import 'ikkiuchi_cards.dart';

/// Where a match (一騎打ち) stands, in the order it goes through them.
enum IkkiuchiStage {
  /// 暗記時間: the players learn the field before play,
  /// [IkkiuchiMatchTuning.memoryTime] long.
  memoryTime,

  /// The players greet each other (よろしくお願いします).
  gameStart,

  /// The 序歌, read before the first card.
  yoka,

  /// A card's 上の句: its kimariji is read sound by sound.
  kaminoku,

  /// The kimariji is read, and the read waits for the card's take; a
  /// からふだ's waits out its pause.
  waitingForHit,

  /// The player sends Tobi a card of theirs.
  sendingCard,

  /// Tobi's arm lays the card the player sent him on his side.
  tobiPlacingCard,

  /// Tobi's arm brings the player a card of his, and they place it.
  receivingCard,

  /// Held once the cards are at rest after a read, until let go; only where
  /// the match is told to hold there.
  waitingForGo,

  /// A moment once the cards are at rest after a read, before the 下の句.
  waitBeforeShimonoku,

  /// The 下の句 is read.
  shimonoku,

  /// The time to move cards is over while the player still moves theirs
  /// (並べ替え): held until they are done.
  movingCard,

  /// A moment after the 下の句, before the next card's 上の句.
  breakAfterShimonoku,

  /// A side is empty, or the player ended the match: the players thank
  /// each other (ありがとうございました), and nothing more happens.
  gameEnd;

  /// Whether a card is being read.
  bool get readLive => this == kaminoku || this == waitingForHit;

  /// Whether the player may move their cards about (並べ替え).
  bool get allowsMoving =>
      this == memoryTime || this == waitBeforeShimonoku || this == shimonoku || this == movingCard;

  /// Whether a card changes sides now (送り札).
  bool get sending => this == sendingCard || this == tobiPlacingCard || this == receivingCard;
}

/// The order a match reads its cards in: every card on the field, and
/// [IkkiuchiMatchTuning.karafuda]'s share of からふだ drawn from the cards
/// dealt to neither side, shuffled together.
abstract final class IkkiuchiReadOrder {
  /// The reads of [field], with からふだ from [away], by [rng].
  static List<int> deal({required List<int> field, required List<int> away, required math.Random rng}) {
    const share = IkkiuchiMatchTuning.karafuda;
    final count = math.min(away.length, (field.length * share.karafuda / share.field).round());
    final blanks = [...away]..shuffle(rng);
    return [...field, ...blanks.take(count)]..shuffle(rng);
  }
}

/// How a read ended: who took the called card from which side, and the
/// sides each player faulted on (お手つき).
///
/// It leaves the 送り札 of 競技規程細則 第二十五条: a player may send a card
/// for taking the called card from the other's side, and one for each
/// fault of the other's: one for a fault on the called card's side, two
/// for faults on both sides on a からふだ (三). When both may send, only the
/// difference is sent (四).
class IkkiuchiReadEnd {
  const IkkiuchiReadEnd({this.taker, this.cardSide, this.tobiFaults = const {}, this.playerFaults = const {}});

  /// Who took the called card, and the side it lay on; both null on a
  /// からふだ.
  final IkkiuchiSide? taker, cardSide;

  /// The sides Tobi's fist faulted on, and the player's finger.
  final Set<IkkiuchiSide> tobiFaults, playerFaults;

  /// The cards [side] may send the other.
  int mayGive(IkkiuchiSide side) {
    final other = side == IkkiuchiSide.tobi ? IkkiuchiSide.player : IkkiuchiSide.tobi;
    final take = taker == side && cardSide == other ? 1 : 0;
    return take + (other == IkkiuchiSide.tobi ? tobiFaults : playerFaults).length;
  }

  /// Who sends the other cards, and how many; null when none change sides.
  ({IkkiuchiSide from, int count})? get sends {
    final net = mayGive(IkkiuchiSide.player) - mayGive(IkkiuchiSide.tobi);
    if (net == 0) return null;
    return (from: net > 0 ? IkkiuchiSide.player : IkkiuchiSide.tobi, count: net.abs());
  }
}
