import 'dart:convert';

import 'ankiren_field.dart';
import 'ankiren_review.dart';
import 'level_ladder.dart';
import 'teiichi.dart';
import 'teiichi_record.dart';
import 'teiichi_score.dart';
import 'xp.dart';

/// A card dealt to a recorded 定位置 game: how long it was on top of the
/// stack, every time it was.
typedef TeiichiPlaced = ({int poemId, Duration time});

/// A recorded 定位置 game as History reviews it: its setup, the placing
/// time, the layout as placed, the cards in the order they were placed and
/// those never placed, and the cards asked for after, recorded as a 暗記練
/// game's ([recall]).
class TeiichiGameRecord {
  /// A game from its stored run: [meta] is its details' JSON (see
  /// [TeiichiMeta]), and [dealt] every card dealt, in the order they were
  /// placed, then those never placed, which are not on its layout.
  factory TeiichiGameRecord({
    required AnkirenGameRecord recall,
    required String meta,
    required List<TeiichiPlaced> dealt,
  }) {
    final details = jsonDecode(meta) as Map<String, dynamic>;
    final layout = AnkirenHalf.fromJson(details[TeiichiMeta.layoutKey] as List);
    final laid = layout.cards.toSet();
    return TeiichiGameRecord._(
      recall,
      TeiichiSetup(
        cards: details[TeiichiMeta.cardsKey] as int,
        rows: details[TeiichiMeta.rowsKey] as int,
        karafuda: recall.karafuda.length,
        level: recall.level,
        ranked: recall.ranked,
      ),
      Duration(milliseconds: details[TeiichiMeta.placingKey] as int),
      layout,
      List.unmodifiable([for (final c in dealt) if (laid.contains(c.poemId)) c]),
      List.unmodifiable([for (final c in dealt) if (!laid.contains(c.poemId)) c.poemId]),
    );
  }

  TeiichiGameRecord._(this.recall, this.setup, this.placing, this.layout, this.placed, this.unplaced);

  final AnkirenGameRecord recall;
  final TeiichiSetup setup;

  /// A custom game.
  bool get custom => setup.custom;

  /// From the deal to the flip.
  final Duration placing;

  /// The own side as placed.
  final AnkirenHalf layout;

  /// The cards in the order they were placed.
  final List<TeiichiPlaced> placed;

  /// The cards still in the stack when the others flipped: never called,
  /// and counted as misses with 0 points.
  final List<int> unplaced;

  int get id => recall.id;
  DateTime get startedAt => recall.startedAt;
  bool get completed => recall.completed;

  /// The layout as the field it was played on.
  AnkirenField get field => AnkirenField(own: layout, opponent: AnkirenHalf.empty());

  bool get ranked => recall.ranked;
  int? get level => recall.level;

  /// A ranked game left before its end.
  bool get forfeit => ranked && !completed;

  /// Every wrong tap, the からふだ calls' among them.
  int get wrongTaps => recall.calls.fold(0, (n, c) => n + c.wrongTaps);

  /// Its wrong taps, calls given up and cards never placed, one strike
  /// each.
  int get strikes => recall.strikes + unplaced.length;

  /// It cleared its level.
  bool get cleared => level != null && LevelLadder.clears(completed: completed, strikes: strikes);

  /// Every card dealt, placed or not.
  int get dealt => recall.cards.length + unplaced.length;

  /// What the placing time multiplied the first-tap points by, and added
  /// to them as a whole percentage.
  double get scoreFactor => TeiichiScore.factorOf(placing);
  int get bonusPercent => TeiichiScore.bonusPercent(placing);

  /// The field cards that took a wrong tap.
  int get wrongCards => recall.cards.where((c) => c.wrongTaps > 0).length;

  /// It sets the best placing time and the form (see [TeiichiRecord.counts]).
  bool get counts => completed && setup.full && unplaced.isEmpty;

  /// The cards placed, the slowest to place first.
  List<TeiichiPlaced> get slowest => [...placed]..sort((a, b) => b.time.compareTo(a.time));

  /// Played with the same setup as [other].
  bool sameSetup(TeiichiGameRecord other) => other.setup == setup;
}

/// One 定位置 [game] against the games recorded before it ([all] holds every
/// recorded game, this one among them), with the [xp] it earned; null where
/// no experience is wanted (a list row).
class TeiichiReview {
  TeiichiReview(this.game, List<TeiichiGameRecord> all, {this.xp})
      : _earlier = [for (final g in all) if (g.id < game.id) g];

  final TeiichiGameRecord game;
  final XpGain? xp;
  final List<TeiichiGameRecord> _earlier;

  /// The earlier games with the same setup, oldest first.
  late final List<TeiichiGameRecord> peers = [for (final g in _earlier) if (game.sameSetup(g)) g];

  TeiichiGameRecord? get last => peers.lastOrNull;

  /// The best placing time of the earlier games that count; null before
  /// the first.
  Duration? get bestBefore {
    Duration? best;
    for (final g in _earlier) {
      if (g.counts && (best == null || g.placing < best)) best = g.placing;
    }
    return best;
  }

  /// A game that counts and beat [bestBefore], or the first that counts.
  bool get isBest {
    final best = bestBefore;
    return game.counts && (best == null || game.placing < best);
  }

  /// The cards asked for as a 暗記練 game's, against the earlier games'.
  AnkirenReview get recall => AnkirenReview(game.recall, [for (final g in _earlier) g.recall, game.recall]);
}
