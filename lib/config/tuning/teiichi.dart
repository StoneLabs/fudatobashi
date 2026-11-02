part of '../config.dart';

/// 定位置 (the layout side trip): its levels and games (`TeiichiSetup`), how
/// a ranked game scores (`TeiichiScore`), the room a row has while placing
/// (`TeiichiBoard`), and what its page shows of the games played
/// (`SideTrips.teiichiRecord`).
abstract final class TeiichiTuning {
  /// The levels, [firstLevel] first; a limit is placing time only. They
  /// open one at a time (see `LevelLadder`).
  static const List<TeiichiLevel> levels = [
    TeiichiLevel(cards: 4, rows: 1, limit: Duration(minutes: 15)),
    TeiichiLevel(cards: 8, rows: 2, limit: Duration(minutes: 15)),
    TeiichiLevel(cards: 12, rows: 2, limit: Duration(minutes: 10)),
    TeiichiLevel(cards: 16, rows: 3, limit: Duration(minutes: 5), karafuda: 7),
    TeiichiLevel(cards: 20, rows: 3, limit: Duration(minutes: 3), karafuda: 8),
    TeiichiLevel(cards: 25, rows: 3, limit: Duration(minutes: 3), karafuda: 10),
    TeiichiLevel(cards: 25, rows: 3, limit: Duration(minutes: 2, seconds: 30), karafuda: 10),
    TeiichiLevel(cards: 25, rows: 3, limit: Duration(minutes: 2), karafuda: 10),
    TeiichiLevel(cards: 25, rows: 3, limit: Duration(minutes: 1, seconds: 30), karafuda: 10),
  ];
  static const int firstLevel = 0;

  /// Clearing [rankedAfterLevel] opens ranked (in all-known mode), and
  /// [customAfterLevel] the custom setups, whatever is cleared after it.
  static const int rankedAfterLevel = 3;
  static const int customAfterLevel = 5;

  /// Ranked games all lay out the usual game, dealt from all 100 cards, in
  /// at most [rankedLimit]; then the cards flip.
  static const Duration rankedLimit = Duration(minutes: 15);

  /// A ranked game's right first taps earn their normal points
  /// (`AnkirenScore.pointsOf`) times 1 + [bonusPerHalving] for each time
  /// the placing time halves [halvingClock], in fractions of a halving too.
  static const double bonusPerHalving = 0.15;
  static const Duration halvingClock = Duration(minutes: 15);

  /// The usual game: a real match's side of [cards] known cards in all
  /// three rows. Only games of [cards] with every card placed count for the
  /// best placing time.
  static const int cards = 25;
  static const int rows = 3;

  /// からふだ (see [AnkirenTuning.karafudaPer]): a game calls [karafudaPer]
  /// for every [karafudaPerCards] cards laid out, rounded up (`Karafuda`),
  /// so the usual game [karafuda].
  static const int karafudaPer = 10;
  static const int karafudaPerCards = 25;
  static const int karafuda = (cards * karafudaPer + karafudaPerCards - 1) ~/ karafudaPerCards;

  /// The page's form averages the last [formGames] games that count.
  static const int formGames = 5;

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

/// 定位置's rating (`TripRating.teiichi`), by 暗記練's rule
/// ([AnkirenRatingModel]) and on its scale, but a rating of its own.
abstract final class TeiichiRatingModel {
  /// A ranked game's performance is its final score over [pointsPerRating]
  /// (see `TripRating.teiichi.performance`): a game of [anchorScore] points
  /// performs at [anchorRating].
  static const int anchorScore = 7300;
  static const int anchorRating = 2800;
  static const double pointsPerRating = anchorScore / anchorRating;
}

/// The developer's 定位置 tools (`TeiichiToolsPage`): the placing times of
/// its bonus table, its ranked calculator's placing slider, the tap times
/// its class table tries, and its rating graph's range and dots.
abstract final class TeiichiToolsTuning {
  /// The bonus table's placing times, fastest first, each priced on one
  /// right first tap [bonusTap] after its prompt.
  static const List<Duration> bonusTimes = [
    Duration(seconds: 30),
    Duration(seconds: 45),
    Duration(minutes: 1),
    Duration(minutes: 1, seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 7, seconds: 30),
    Duration(minutes: 10),
    Duration(minutes: 15),
  ];
  static const Duration bonusTap = Duration(seconds: 1);

  /// The ranked calculator's placing slider: where it starts, and its step.
  static const Duration placingStart = Duration(minutes: 3);
  static const Duration placingStep = Duration(seconds: 5);

  /// The class table: every call right with the first tap at each of
  /// [classTapTimes], the slowest placing time that reaches each class, to
  /// [classPlacingStep].
  static const List<Duration> classTapTimes = [
    Duration(milliseconds: 100),
    Duration(milliseconds: 600),
    Duration(seconds: 1),
    Duration(seconds: 2),
  ];
  static const Duration classPlacingStep = Duration(seconds: 1);

  /// The rating-by-score graph: its top score and the gap between its score
  /// ticks, and its dots, each a ranked game placed in [placing] with every
  /// call right with the first tap [tap] after its prompt.
  static const int ratingXMax = 9000;
  static const int ratingXTick = 3000;
  static const List<({Duration placing, Duration tap})> ratingDots = [
    (placing: Duration(minutes: 1, seconds: 30), tap: Duration(milliseconds: 100)),
    (placing: Duration(minutes: 3), tap: Duration(seconds: 1)),
  ];
}

/// 定位置's play screen (`TeiichiScreen`): its clock and the pace of its
/// placing.
abstract final class TeiichiPlayTuning {
  /// The placing clock's step: it shows whole seconds.
  static const Duration clockTick = Duration(seconds: 1);

  /// A countdown turns urgent with this much time left.
  static const Duration lowTime = Duration(seconds: 30);

  /// The tip to turn the phone waits this long on a portrait screen, so
  /// that the screen has come in and a turn asked for has landed.
  static const Duration tipDelay = Duration(seconds: 1);
}
