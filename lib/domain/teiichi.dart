import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_field.dart';
import 'ankiren_geometry.dart';
import 'karafuda.dart';

/// One 定位置 level: the cards laid out in how many rows, the most time
/// they may take, and the からふだ called among them.
class TeiichiLevel {
  const TeiichiLevel({required this.cards, required this.rows, required this.limit, this.karafuda = 0});

  final int cards;
  final int rows;
  final Duration limit;
  final int karafuda;
}

/// The level table ([TeiichiTuning.levels]), numbered from
/// [TeiichiTuning.firstLevel].
abstract final class TeiichiLevels {
  static List<TeiichiLevel> get all => TeiichiTuning.levels;
  static int get first => TeiichiTuning.firstLevel;
  static int get top => first + all.length - 1;

  static TeiichiLevel of(int level) => all[level - first];
}

/// One 定位置 game: how many known cards are laid out, in how many rows, the
/// からふだ called among them and the most time placing may take: ranked's
/// one setup, a level, or in a custom game whatever was picked, with no
/// limit.
class TeiichiSetup {
  const TeiichiSetup({
    required this.cards,
    required this.rows,
    this.karafuda = 0,
    this.limit,
    this.level,
    this.ranked = false,
  }) : assert(!ranked || level == null);

  /// Ranked's setup, the usual game against the clock.
  const TeiichiSetup.ranked()
      : this(
          cards: TeiichiTuning.cards,
          rows: TeiichiTuning.rows,
          karafuda: TeiichiTuning.karafuda,
          limit: TeiichiTuning.rankedLimit,
          ranked: true,
        );

  /// A level of the table.
  TeiichiSetup.forLevel(int level)
      : this(
          cards: TeiichiLevels.of(level).cards,
          rows: TeiichiLevels.of(level).rows,
          karafuda: TeiichiLevels.of(level).karafuda,
          limit: TeiichiLevels.of(level).limit,
          level: level,
        );

  /// The custom game a new player's steppers start from:
  /// [TeiichiTuning.cards] in all three rows, with [TeiichiTuning.karafuda].
  static const usual =
      TeiichiSetup(cards: TeiichiTuning.cards, rows: TeiichiTuning.rows, karafuda: TeiichiTuning.karafuda);

  final int cards;
  final int rows;
  final int karafuda;

  /// The most placing time; null for no limit.
  final Duration? limit;

  /// The level played; null for ranked and for a custom game.
  final int? level;
  final bool ranked;

  /// Every call: the cards laid out and the からふだ, each a known card, so
  /// also the known cards the game needs.
  int get calls => cards + karafuda;

  /// Neither ranked nor a level.
  bool get custom => level == null && !ranked;

  /// Enough cards to count for the best placing time.
  bool get full => cards == TeiichiTuning.cards;

  /// The rows played, from the player outward as 暗記練 fills them: 下段
  /// alone, then 中段, then 上段.
  List<FieldRow> get rowsInPlay => FieldRow.values.take(rows).toList();

  /// 暗記練's row with the open middle is played.
  bool get openMiddle => rowsInPlay.contains(AnkirenTuning.middleRow);

  /// The most cards [rows] rows hold: their share of the usual game's.
  static int mostCards(int rows) => TeiichiTuning.cards * rows ~/ TeiichiTuning.rows;

  static bool allows({required int cards, required int rows}) => cards <= mostCards(rows);

  /// The rows a game of [cards] plays when [wanted] are asked for: those,
  /// or as few more as hold the cards.
  static int rowsFor(int cards, int wanted) {
    var rows = wanted;
    while (rows < TeiichiTuning.rows && !allows(cards: cards, rows: rows)) {
      rows++;
    }
    return rows;
  }

  /// This setup fitted to [known] cards: no more cards than they allow
  /// (see [maxCards]), the rows that hold them, and no more からふだ than
  /// [Karafuda.customMax].
  TeiichiSetup fitted(int known) {
    final fittedCards = cards.clamp(TeiichiTuning.minCards, maxCards(known) ?? TeiichiTuning.minCards);
    return TeiichiSetup(
      cards: fittedCards,
      rows: rowsFor(fittedCards, rows),
      karafuda: karafuda.clamp(0, Karafuda.customMax(fittedCards, known)),
    );
  }

  /// The largest game [known] cards allow, or null when they allow not even
  /// [TeiichiTuning.minCards].
  static int? maxCards(int known) {
    final n = math.min(known, TeiichiTuning.cards);
    return n < TeiichiTuning.minCards ? null : n;
  }

  @override
  bool operator ==(Object other) =>
      other is TeiichiSetup &&
      other.cards == cards &&
      other.rows == rows &&
      other.karafuda == karafuda &&
      other.limit == limit &&
      other.level == level &&
      other.ranked == ranked;

  @override
  int get hashCode => Object.hash(cards, rows, karafuda, limit, level, ranked);

  @override
  String toString() => 'TeiichiSetup($cards cards, $rows rows, $karafuda からふだ, limit $limit, level $level, ranked $ranked)';
}

/// Where a card goes on the own side while it is laid out (see
/// [TeiichiBoard.put]).
sealed class TeiichiSpot {
  const TeiichiSpot();
}

/// The next place at the inner end of [row]'s left or right cluster
/// ([part]).
final class ClusterEnd extends TeiichiSpot {
  const ClusterEnd(this.row, this.part) : assert(part != RowPart.middle);

  final FieldRow row;
  final RowPart part;

  @override
  bool operator ==(Object other) => other is ClusterEnd && other.row == row && other.part == part;

  @override
  int get hashCode => Object.hash(row, part);

  @override
  String toString() => 'ClusterEnd($row, $part)';
}

/// The place of the card [poemId]: the card put there takes it, and the
/// cards from there inward move a place further in. In the open middle the
/// card put there goes just left of it.
final class CardSpot extends TeiichiSpot {
  const CardSpot(this.poemId);

  final int poemId;

  @override
  bool operator ==(Object other) => other is CardSpot && other.poemId == poemId;

  @override
  int get hashCode => poemId.hashCode;

  @override
  String toString() => 'CardSpot($poemId)';
}

/// [row]'s open middle, with [index] of its middle cards left of the card
/// put there.
final class OpenMiddle extends TeiichiSpot {
  const OpenMiddle(this.row, this.index);

  final FieldRow row;
  final int index;

  @override
  bool operator ==(Object other) => other is OpenMiddle && other.row == row && other.index == index;

  @override
  int get hashCode => Object.hash(row, index);

  @override
  String toString() => 'OpenMiddle($row, $index)';
}

/// The own side while it is laid out: an [AnkirenHalf] in [setup]'s rows,
/// cards put on it, moved about and taken off it, no row ever wider than
/// [TeiichiTuning.rowSlots] pitches (see [span]).
class TeiichiBoard {
  TeiichiBoard(this.setup, [AnkirenHalf? half]) : half = half ?? AnkirenHalf.empty();

  final TeiichiSetup setup;
  final AnkirenHalf half;

  /// A card that is no poem, to ask where any card would go.
  static const _anyCard = -1;

  static const _tolerance = 1e-9;

  /// The pitches [row]'s cards take across: its clusters, and between them
  /// [TeiichiTuning.clusterGap] or its middle cards with
  /// [AnkirenFieldSize.middleMargin] either side.
  static double span(AnkirenRow row) =>
      row.left.length +
      row.right.length +
      (row.middle.isEmpty ? TeiichiTuning.clusterGap : row.middle.length + 2 * AnkirenFieldSize.middleMargin);

  static bool fits(AnkirenRow row) => span(row) <= TeiichiTuning.rowSlots + _tolerance;

  List<int> get cards => half.cards;
  bool contains(int poemId) => half.placeOf(poemId) != null;

  /// The board with [poemId] taken off it; the cards outward of it in its
  /// cluster stay, those inward close up.
  TeiichiBoard without(int poemId) {
    final place = half.placeOf(poemId);
    if (place == null) return this;
    final row = half.row(place.row);
    List<int> drop(List<int> cards) => [for (final c in cards) if (c != poemId) c];
    return _with(place.row, AnkirenRow(left: drop(row.left), middle: drop(row.middle), right: drop(row.right)));
  }

  /// The board with [poemId] put at [spot], moved there when already on
  /// it; null when it may not go there: [spot] is not in play, or its row
  /// would grow too wide.
  TeiichiBoard? put(int poemId, TeiichiSpot spot) {
    if (spot case CardSpot(poemId: final target) when target == poemId) return contains(poemId) ? this : null;
    final base = without(poemId);
    final FieldRow at;
    final AnkirenRow row;
    switch (spot) {
      case ClusterEnd(row: final r, :final part):
        if (!setup.rowsInPlay.contains(r)) return null;
        final old = base.half.row(r);
        at = r;
        row = part == RowPart.left
            ? AnkirenRow(left: [...old.left, poemId], middle: old.middle, right: old.right)
            : AnkirenRow(left: old.left, middle: old.middle, right: [poemId, ...old.right]);
      case CardSpot(poemId: final target):
        final place = base.half.placeOf(target);
        if (place == null) return null;
        final old = base.half.row(place.row);
        List<int> insert(List<int> cards, int i) => [...cards.take(i), poemId, ...cards.skip(i)];
        at = place.row;
        row = switch (place.part) {
          RowPart.left => AnkirenRow(left: insert(old.left, place.index), middle: old.middle, right: old.right),
          RowPart.middle => AnkirenRow(left: old.left, middle: insert(old.middle, place.index), right: old.right),
          RowPart.right => AnkirenRow(left: old.left, middle: old.middle, right: insert(old.right, place.index + 1)),
        };
      case OpenMiddle(row: final r, :final index):
        if (!setup.openMiddle || r != AnkirenTuning.middleRow) return null;
        final old = base.half.row(r);
        final i = index.clamp(0, old.middle.length);
        at = r;
        row = AnkirenRow(left: old.left, middle: [...old.middle.take(i), poemId, ...old.middle.skip(i)], right: old.right);
    }
    return fits(row) ? base._with(at, row) : null;
  }

  /// [setup]'s usual shape, for a preview: its cards shared out over the
  /// rows in play, the rows nearest the player first, half left and half
  /// right. Its cards are numbered from 0, not poems.
  static TeiichiBoard typical(TeiichiSetup setup) {
    var next = 0;
    List<int> take(int n) => [for (var i = 0; i < n; i++) next++];
    final rows = setup.rowsInPlay;
    AnkirenRow row(FieldRow at) {
      final i = rows.indexOf(at);
      if (i < 0) return AnkirenRow(left: const [], middle: const [], right: const []);
      final cards = setup.cards ~/ rows.length + (i < setup.cards % rows.length ? 1 : 0);
      return AnkirenRow(left: take((cards + 1) ~/ 2), middle: const [], right: take(cards ~/ 2));
    }

    return TeiichiBoard(setup, AnkirenHalf([for (final r in FieldRow.values) row(r)]));
  }

  /// [spot] would take a card not on the board, or [card] moved there.
  bool takes(TeiichiSpot spot, {int? card}) => put(card ?? _anyCard, spot) != null;

  /// The places off the cards that a card not on the board may go: each
  /// row in play's cluster ends, and its open middle, that it fits in.
  List<TeiichiSpot> get freeSpots => [
        for (final row in setup.rowsInPlay) ...[
          for (final part in const [RowPart.left, RowPart.right])
            if (takes(ClusterEnd(row, part))) ClusterEnd(row, part),
          if (takes(OpenMiddle(row, 0))) OpenMiddle(row, 0),
        ],
      ];

  TeiichiBoard _with(FieldRow at, AnkirenRow row) =>
      TeiichiBoard(setup, AnkirenHalf([for (final r in FieldRow.values) r == at ? row : half.row(r)]));
}

/// Where a tap or a drop lands on the own side while it is laid out, on
/// its true-scale geometry ([FieldGeometry], a row [TeiichiTuning.rowSlots]
/// pitches across) with [board]'s cards; [moving] is the placed card being
/// dragged, left out of the board.
///
/// A card takes the spot it covers; past the cards, a dashed spot at a
/// cluster's inner end takes its own; the open middle takes the rest of
/// its share of the gap between the clusters, grown over any middle cards
/// ([TeiichiTuning.openMiddleShare]). Spots the card does not fit take
/// nothing.
class TeiichiTargets {
  factory TeiichiTargets(TeiichiBoard board, {int? moving}) {
    final base = moving == null ? board : board.without(moving);
    final geometry = geometryOf(base.half);
    return TeiichiTargets._(base, moving, geometry, geometry.half(FieldSide.own));
  }

  TeiichiTargets._(this.base, this.moving, this.geometry, this._cards);

  /// The board the spots are on, [moving] left out.
  final TeiichiBoard base;
  final int? moving;
  final FieldGeometry geometry;
  final Map<int, FieldRect> _cards;

  /// The own side's true-scale geometry with [half] laid out on it.
  static FieldGeometry geometryOf(AnkirenHalf half) => FieldGeometry.of(
        AnkirenField(own: half, opponent: AnkirenHalf.empty()),
        folded: false,
        trueSlots: TeiichiTuning.rowSlots,
      );

  bool _takes(TeiichiSpot spot) => base.takes(spot, card: moving);

  /// The dashed spots past the cards, each where it lies: the cluster ends
  /// and open middles the card fits in.
  List<(TeiichiSpot, FieldRect)> get freeSpots => [
        for (final spot in base.freeSpots)
          switch (spot) {
            ClusterEnd(:final row, :final part) => (spot, _clusterEnd(row, part)),
            OpenMiddle(:final row) => (spot, _openMiddle(row)),
            CardSpot() => throw StateError('a free spot is never a card'),
          },
      ];

  /// What a card let go at ([x], [y]) on the own half would take, or null.
  TeiichiSpot? spotAt(double x, double y) {
    for (final MapEntry(key: id, value: rect) in _cards.entries) {
      if (rect.contains(x, y)) return _takes(CardSpot(id)) ? CardSpot(id) : null;
    }
    for (final (spot, rect) in freeSpots) {
      if (!rect.contains(x, y)) continue;
      if (spot is! OpenMiddle) return spot;
      final middle = base.half.row(spot.row).middle;
      final index = middle.where((id) => _cards[id]!.x + _cards[id]!.w / 2 < x).length;
      return OpenMiddle(spot.row, index);
    }
    return null;
  }

  FieldRect _clusterEnd(FieldRow row, RowPart part) {
    final cards = base.half.row(row);
    final slot = part == RowPart.left ? cards.left.length : geometry.slots - cards.right.length - 1;
    return geometry.slot(row, slot.toDouble())!;
  }

  FieldRect _openMiddle(FieldRow row) {
    final cards = base.half.row(row);
    final (start, end) = geometry.gapOf(cards);
    final reach = (end - start) * TeiichiTuning.openMiddleShare / 2;
    final centre = (start + end) / 2;
    final top = geometry.rowTop(row)!;
    var rect = FieldRect(centre - reach, top, 2 * reach, AnkirenFieldSize.cardH);
    for (final id in cards.middle) {
      rect = rect.union(_cards[id]!);
    }
    return rect;
  }
}
