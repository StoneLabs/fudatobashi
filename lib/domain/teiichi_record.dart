/// The keys of a recorded 定位置 game's details (its run's meta). The placing
/// order and times are kept card by card in their own table.
abstract final class TeiichiMeta {
  static const cardsKey = 'cards';
  static const rowsKey = 'rows';
  static const customKey = 'custom';

  /// From the deal to done.
  static const placingKey = 'placingMs';

  /// The final layout (`AnkirenHalf.toJson`).
  static const layoutKey = 'layout';
}

/// A recorded 定位置 game as its page shows it: its card count, the placing
/// time and the cards found with the first tap.
typedef TeiichiGameFacts = ({int cards, Duration placing, int firstTaps});

/// 定位置's record on the hub and its page: the best placing time of a usual
/// game's count of cards played to the end, and the last game.
class TeiichiRecord {
  const TeiichiRecord({this.best, this.last, this.games = 0});

  static const none = TeiichiRecord();

  final Duration? best;
  final TeiichiGameFacts? last;
  final int games;
}
