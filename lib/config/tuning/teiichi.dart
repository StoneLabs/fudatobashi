part of '../config.dart';

/// 定位置 (the layout side trip): its games (`TeiichiSetup`), the room a row
/// has while placing (`TeiichiBoard`), and what its page shows of the games
/// played (`SideTrips.teiichiRecord`).
abstract final class TeiichiTuning {
  /// The usual game: a real match's side of [cards] known cards in all
  /// three rows. Only games of [cards] count for the best placing time.
  static const int cards = 25;
  static const int rows = 3;

  /// A custom game's fewest cards, as 暗記練's custom setups' fewest a side.
  static const int minCards = AnkirenTuning.customMinPerSide;

  /// The custom game's quick picks of the card count.
  static const List<int> cardKeys = [8, 12, 16, 20, 25];

  /// A row is [rowSlots] card pitches (card and gap) across, a real
  /// side's width. Its clusters keep at least [clusterGap] pitches between
  /// them, or room for its middle cards with
  /// [AnkirenFieldSize.middleMargin] either side.
  static const double rowSlots = 16.5;
  static const double clusterGap = 0.5;

  /// The open middle takes taps and drops over this share of the gap
  /// between a row's clusters, in its middle, and over any middle cards.
  static const double openMiddleShare = 1 / 3;
}

/// 定位置's play screen (`TeiichiScreen`): its clock and the pace of its
/// placing.
abstract final class TeiichiPlayTuning {
  /// The placing clock's step: it shows whole seconds.
  static const Duration clockTick = Duration(seconds: 1);
}
