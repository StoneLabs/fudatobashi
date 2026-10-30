import 'dart:convert';

import 'ankiren_field.dart';
import 'ankiren_review.dart';
import 'teiichi.dart';
import 'teiichi_record.dart';

/// A card of a recorded 定位置 game as it was placed: how long it was on top
/// of the stack, every time it was.
typedef TeiichiPlaced = ({int poemId, Duration time});

/// A recorded 定位置 game as History reviews it: its setup, the placing
/// time, the layout as placed, the cards in the order they were placed,
/// and the cards asked for after, recorded as a 暗記練 game's ([recall]).
class TeiichiGameRecord {
  /// A game from its stored run: [meta] is its details' JSON (see
  /// [TeiichiMeta]).
  factory TeiichiGameRecord({required AnkirenGameRecord recall, required String meta, required List<TeiichiPlaced> placed}) {
    final details = jsonDecode(meta) as Map<String, dynamic>;
    return TeiichiGameRecord._(
      recall,
      TeiichiSetup(cards: details[TeiichiMeta.cardsKey] as int, rows: details[TeiichiMeta.rowsKey] as int),
      Duration(milliseconds: details[TeiichiMeta.placingKey] as int),
      AnkirenHalf.fromJson(details[TeiichiMeta.layoutKey] as List),
      List.unmodifiable(placed),
    );
  }

  TeiichiGameRecord._(this.recall, this.setup, this.placing, this.layout, this.placed);

  final AnkirenGameRecord recall;
  final TeiichiSetup setup;

  /// From the deal to done.
  final Duration placing;

  /// The own side as placed.
  final AnkirenHalf layout;

  /// The cards in the order they were placed.
  final List<TeiichiPlaced> placed;

  int get id => recall.id;
  DateTime get startedAt => recall.startedAt;
  bool get completed => recall.completed;
  bool get custom => setup.custom;

  /// The layout as the field it was played on.
  AnkirenField get field => AnkirenField(own: layout, opponent: AnkirenHalf.empty());

  int get wrongTaps => recall.cards.fold(0, (n, c) => n + c.wrongTaps);

  /// The cards that took a wrong tap.
  int get wrongCards => recall.cards.where((c) => c.wrongTaps > 0).length;

  /// It sets the best placing time and the form (see [TeiichiRecord.counts]).
  bool get counts => completed && setup.full;

  /// The cards placed, the slowest to place first.
  List<TeiichiPlaced> get slowest => [...placed]..sort((a, b) => b.time.compareTo(a.time));

  /// Played with the same setup as [other].
  bool sameSetup(TeiichiGameRecord other) => other.setup == setup;
}

/// One 定位置 [game] against the games recorded before it ([all] holds every
/// recorded game, this one among them).
class TeiichiReview {
  TeiichiReview(this.game, List<TeiichiGameRecord> all) : _earlier = [for (final g in all) if (g.id < game.id) g];

  final TeiichiGameRecord game;
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
