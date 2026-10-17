part of '../config.dart';

/// The card panel on a card's About page (`CardPanel`): drag the front card
/// sideways and fling it to bring the other card forward.
abstract final class CardPanelTuning {
  /// While dragged, the card follows the finger 1:1 and turns this many
  /// degrees per dp.
  static const double dragTurn = 0.06;

  /// Let go further than this and the card is thrown to [throwTo] dp,
  /// turned [throwTurn] degrees; the cards swap [swapDelay] after.
  static const double throwDistance = 46;
  static const double throwTo = 260;
  static const double throwTurn = 16;
  static const Duration swapDelay = Duration(milliseconds: 170);

  /// Every move of a card: the throw, the snap back, the swap.
  static const Duration move = Duration(milliseconds: 340);
  static const Curve moveCurve = Cubic(0.2, 0.7, 0.3, 1);
}

/// The sound ladder on a card's About page (`SoundLadderView`).
abstract final class SoundLadderTuning {
  /// A step with more new cards than [foldAfter] shows [foldTo] of them and
  /// a "+N more" chip.
  static const int foldAfter = 7;
  static const int foldTo = 6;
}
