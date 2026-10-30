import '../config/config.dart';

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

/// A card slow to place, and its mean placing time.
typedef SlowPlacing = ({int poemId, Duration mean});

/// "Cards without a spot yet": from each game's placing times, oldest
/// first, the [TeiichiTuning.spotlessMost] cards with the slowest mean over
/// the last [TeiichiTuning.spotlessRecentGames] games they were placed in,
/// slowest first. None before [TeiichiTuning.spotlessAfterGames] games, or
/// when fewer than [TeiichiTuning.spotlessLeast] cards were placed.
List<SlowPlacing> slowestToPlace(List<Map<int, Duration>> games) {
  if (games.length < TeiichiTuning.spotlessAfterGames) return const [];
  final recent = games.skip(games.length - TeiichiTuning.spotlessRecentGames.clamp(0, games.length));
  final times = <int, List<Duration>>{};
  for (final game in recent) {
    for (final MapEntry(key: id, value: time) in game.entries) {
      (times[id] ??= []).add(time);
    }
  }
  final means = [
    for (final MapEntry(key: id, value: all) in times.entries)
      (poemId: id, mean: all.reduce((a, b) => a + b) ~/ all.length),
  ]..sort((a, b) => switch (b.mean.compareTo(a.mean)) { 0 => a.poemId.compareTo(b.poemId), final c => c });
  if (means.length < TeiichiTuning.spotlessLeast) return const [];
  return means.take(TeiichiTuning.spotlessMost).toList();
}
