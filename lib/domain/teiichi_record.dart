import 'dart:math' as math;

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
/// time, the cards found with the first tap, the wrong taps, and whether it
/// was played to the end.
typedef TeiichiGameFacts = ({int cards, Duration placing, int firstTaps, int wrongTaps, bool completed});

/// How the owner has been doing lately: the [games] averaged, up to
/// [TeiichiTuning.formGames], their wrong taps and their placing time.
typedef TeiichiForm = ({int games, double wrongTaps, Duration placing});

/// 定位置's record on the hub and its page: the best placing time and the
/// recent form, both of the games that count ([counts]); the last game; and
/// how many were played.
class TeiichiRecord {
  const TeiichiRecord({this.best, this.form, this.last, this.games = 0});

  /// The record of [games], oldest first.
  factory TeiichiRecord.of(List<TeiichiGameFacts> games) {
    final counted = games.where(counts).toList();
    final recent = counted.skip(math.max(0, counted.length - TeiichiTuning.formGames)).toList();
    final n = recent.length;
    return TeiichiRecord(
      best: counted.isEmpty ? null : counted.map((g) => g.placing).reduce((a, b) => a < b ? a : b),
      form: n == 0
          ? null
          : (
              games: n,
              wrongTaps: recent.fold(0, (sum, g) => sum + g.wrongTaps) / n,
              placing: recent.fold(Duration.zero, (sum, g) => sum + g.placing) ~/ n,
            ),
      last: games.lastOrNull,
      games: games.length,
    );
  }

  static const none = TeiichiRecord();

  /// A game of the usual count of cards, played to the end: only such
  /// games set the best placing time and the form.
  static bool counts(TeiichiGameFacts game) => game.completed && game.cards == TeiichiTuning.cards;

  final Duration? best;

  /// Null before the first game that counts.
  final TeiichiForm? form;
  final TeiichiGameFacts? last;
  final int games;
}
