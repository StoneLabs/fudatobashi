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
  /// からふだ's waits out [IkkiuchiPlayTuning.karafudaPause]. It is over
  /// once Tobi's arm is done and the cards are home.
  waitingForHit,

  /// How the read ended shows in the middle of the board
  /// ([IkkiuchiMatchTuning.feedback] long).
  feedback,

  /// The card taken leaves its side, and the cards close up the gap.
  closingUp,

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

  /// Whether a card is being read: the only stages a card touch counts in,
  /// the player's finger and Tobi's fist alike.
  bool get readLive => this == kaminoku || this == waitingForHit;

  /// Whether a 送り札 may be asked for by hand now: no read, its end or
  /// another 送り札 under way.
  bool get allowsHandSend =>
      this == memoryTime ||
      this == gameStart ||
      this == yoka ||
      this == waitingForGo ||
      this == waitBeforeShimonoku ||
      this == shimonoku ||
      this == breakAfterShimonoku;

  /// Whether the player may move their cards about (並べ替え).
  bool get allowsMoving =>
      this == memoryTime || this == waitBeforeShimonoku || this == shimonoku || this == movingCard;

  /// Whether a card changes sides now (送り札).
  bool get sending => this == sendingCard || this == tobiPlacingCard || this == receivingCard;
}

/// A step from one stage to another, and what makes it.
typedef IkkiuchiStep = ({IkkiuchiStage from, IkkiuchiStage to, String why});

/// Every step a match may take between its stages; the match takes no
/// other. [IkkiuchiStage.movingCard] holds a stage that no longer lets the
/// player move cards, then goes on to it; a 送り札 by hand goes back to the
/// stage it broke into; 終了 ends the match from any stage.
abstract final class IkkiuchiSteps {
  static const List<IkkiuchiStep> all = [
    (from: IkkiuchiStage.memoryTime, to: IkkiuchiStage.gameStart, why: 'time up / 始'),
    (from: IkkiuchiStage.memoryTime, to: IkkiuchiStage.movingCard, why: 'time up while moving'),
    (from: IkkiuchiStage.movingCard, to: IkkiuchiStage.gameStart, why: 'moving done'),
    (from: IkkiuchiStage.gameStart, to: IkkiuchiStage.yoka, why: 'time up'),
    (from: IkkiuchiStage.yoka, to: IkkiuchiStage.kaminoku, why: 'time up'),
    (from: IkkiuchiStage.kaminoku, to: IkkiuchiStage.waitingForHit, why: 'kimariji heard'),
    (from: IkkiuchiStage.kaminoku, to: IkkiuchiStage.gameEnd, why: 'no card left to read'),
    (from: IkkiuchiStage.waitingForHit, to: IkkiuchiStage.feedback, why: 'taken / からふだ pause over, at rest'),
    (from: IkkiuchiStage.feedback, to: IkkiuchiStage.closingUp, why: 'time up, a card taken'),
    (from: IkkiuchiStage.feedback, to: IkkiuchiStage.sendingCard, why: 'time up, player sends'),
    (from: IkkiuchiStage.feedback, to: IkkiuchiStage.receivingCard, why: 'time up, Tobi sends'),
    (from: IkkiuchiStage.feedback, to: IkkiuchiStage.waitingForGo, why: 'time up, no send (debug hold)'),
    (from: IkkiuchiStage.feedback, to: IkkiuchiStage.waitBeforeShimonoku, why: 'time up, no send'),
    (from: IkkiuchiStage.closingUp, to: IkkiuchiStage.sendingCard, why: 'closed up, player sends'),
    (from: IkkiuchiStage.closingUp, to: IkkiuchiStage.receivingCard, why: 'closed up, Tobi sends'),
    (from: IkkiuchiStage.closingUp, to: IkkiuchiStage.waitingForGo, why: 'closed up (debug hold)'),
    (from: IkkiuchiStage.closingUp, to: IkkiuchiStage.waitBeforeShimonoku, why: 'closed up'),
    (from: IkkiuchiStage.closingUp, to: IkkiuchiStage.gameEnd, why: 'a side empty'),
    (from: IkkiuchiStage.sendingCard, to: IkkiuchiStage.tobiPlacingCard, why: 'card let go on his side'),
    (from: IkkiuchiStage.tobiPlacingCard, to: IkkiuchiStage.sendingCard, why: 'laid down, another to send'),
    (from: IkkiuchiStage.tobiPlacingCard, to: IkkiuchiStage.receivingCard, why: 'laid down, Tobi sends'),
    (from: IkkiuchiStage.tobiPlacingCard, to: IkkiuchiStage.waitingForGo, why: 'laid down (debug hold)'),
    (from: IkkiuchiStage.tobiPlacingCard, to: IkkiuchiStage.waitBeforeShimonoku, why: 'laid down'),
    (from: IkkiuchiStage.tobiPlacingCard, to: IkkiuchiStage.gameEnd, why: 'a side empty'),
    (from: IkkiuchiStage.receivingCard, to: IkkiuchiStage.receivingCard, why: 'placed, another to receive'),
    (from: IkkiuchiStage.receivingCard, to: IkkiuchiStage.sendingCard, why: 'placed, player sends'),
    (from: IkkiuchiStage.receivingCard, to: IkkiuchiStage.waitingForGo, why: 'placed (debug hold)'),
    (from: IkkiuchiStage.receivingCard, to: IkkiuchiStage.waitBeforeShimonoku, why: 'placed'),
    (from: IkkiuchiStage.receivingCard, to: IkkiuchiStage.gameEnd, why: 'a side empty'),
    (from: IkkiuchiStage.waitingForGo, to: IkkiuchiStage.waitBeforeShimonoku, why: '次 (debug)'),
    (from: IkkiuchiStage.waitBeforeShimonoku, to: IkkiuchiStage.shimonoku, why: 'time up'),
    (from: IkkiuchiStage.shimonoku, to: IkkiuchiStage.breakAfterShimonoku, why: 'time up'),
    (from: IkkiuchiStage.shimonoku, to: IkkiuchiStage.movingCard, why: 'time up while moving'),
    (from: IkkiuchiStage.movingCard, to: IkkiuchiStage.breakAfterShimonoku, why: 'moving done'),
    (from: IkkiuchiStage.breakAfterShimonoku, to: IkkiuchiStage.kaminoku, why: 'time up'),
  ];

  /// Whether the match may step from [from] to [to].
  static bool allows(IkkiuchiStage from, IkkiuchiStage to) =>
      to == IkkiuchiStage.gameEnd ||
      all.any((s) => s.from == from && s.to == to) ||
      (from.allowsHandSend && to.sending) ||
      (from.sending && to.allowsHandSend);
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
  const IkkiuchiReadEnd({
    this.taker,
    this.cardSide,
    this.tied = false,
    this.tobiFaults = const {},
    this.playerFaults = const {},
  });

  /// Who took the called card, and the side it lay on; both null on a
  /// からふだ.
  final IkkiuchiSide? taker, cardSide;

  /// Whether both took it at the same time, the card going to the side it
  /// lay on (陣の札).
  final bool tied;

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

  /// What the read's end says, in order: 同時 or からふだ, who took it, the
  /// player's fault, then Tobi's; a fault on both sides of a からふだ is a
  /// double one.
  List<IkkiuchiCallout> get callouts => [
        if (tied) IkkiuchiCallout.tied,
        if (cardSide == null) IkkiuchiCallout.karafuda,
        if (taker case final taker?) taker == IkkiuchiSide.player ? IkkiuchiCallout.youTook : IkkiuchiCallout.tobiTook,
        ...switch (playerFaults.length) {
          0 => const <IkkiuchiCallout>[],
          1 => const [IkkiuchiCallout.yourFault],
          _ => const [IkkiuchiCallout.yourDoubleFault],
        },
        ...switch (tobiFaults.length) {
          0 => const <IkkiuchiCallout>[],
          1 => const [IkkiuchiCallout.tobiFault],
          _ => const [IkkiuchiCallout.tobiDoubleFault],
        },
      ];
}

/// One part of what a read's end says ([IkkiuchiReadEnd.callouts]).
enum IkkiuchiCallout { tied, karafuda, youTook, tobiTook, yourFault, yourDoubleFault, tobiFault, tobiDoubleFault }
