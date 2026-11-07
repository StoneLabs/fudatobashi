import 'field_parts.dart';

/// Where a card goes on a side while it is laid out (see
/// [PlacingBoard.put]).
sealed class PlacingSpot {
  const PlacingSpot();
}

/// The next place at the inner end of [row]'s left or right cluster
/// ([part]).
final class ClusterEnd extends PlacingSpot {
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
final class CardSpot extends PlacingSpot {
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
final class OpenMiddle extends PlacingSpot {
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

/// One row of a side being laid out, as its owner sees it: the left
/// cluster from the outer edge inward, the cards in the open middle left to
/// right, and the right cluster from its inner end out to the edge.
class PlacingRow {
  PlacingRow({required List<int> left, required List<int> middle, required List<int> right})
      : left = List.unmodifiable(left),
        middle = List.unmodifiable(middle),
        right = List.unmodifiable(right);

  PlacingRow.empty() : this(left: const [], middle: const [], right: const []);

  final List<int> left, middle, right;

  /// The row's cards, left to right.
  List<int> get cards => [...left, ...middle, ...right];
}

/// A side being laid out: its rows by [FieldRow.index].
class PlacingSide {
  PlacingSide(List<PlacingRow> rows)
      : assert(rows.length == FieldRow.values.length),
        rows = List.unmodifiable(rows);

  PlacingSide.empty() : this([for (final _ in FieldRow.values) PlacingRow.empty()]);

  final List<PlacingRow> rows;

  PlacingRow row(FieldRow r) => rows[r.index];
  List<int> get cards => [for (final r in rows) ...r.cards];

  /// Where [poemId] lies: its row, the part of the row and its place in
  /// that part, left to right; null when it is not on the side.
  ({FieldRow row, RowPart part, int index})? placeOf(int poemId) {
    for (final r in FieldRow.values) {
      final row = this.row(r);
      for (final (part, cards) in [(RowPart.left, row.left), (RowPart.middle, row.middle), (RowPart.right, row.right)]) {
        final i = cards.indexOf(poemId);
        if (i >= 0) return (row: r, part: part, index: i);
      }
    }
    return null;
  }

  /// The side with [row] at [at].
  PlacingSide withRow(FieldRow at, PlacingRow row) =>
      PlacingSide([for (final r in FieldRow.values) r == at ? row : this.row(r)]);
}

/// The room a row has while its side is laid out: at most [slots] card
/// pitches (card and gap) across, its clusters at least [clusterGap]
/// pitches apart, or room between them for its middle cards with
/// [middleMargin] either side.
class RowRoom {
  const RowRoom({required this.slots, required this.clusterGap, required this.middleMargin});

  final double slots, clusterGap, middleMargin;

  static const _tolerance = 1e-9;

  /// The pitches [row]'s cards take across.
  double span(PlacingRow row) =>
      row.left.length +
      row.right.length +
      (row.middle.isEmpty ? clusterGap : row.middle.length + 2 * middleMargin);

  bool fits(PlacingRow row) => span(row) <= slots + _tolerance;
}

/// What a side is laid out by: the [rows] in play, the one with an open
/// middle that takes cards ([openMiddle], none when null), and each row's
/// [room].
class PlacingRules {
  const PlacingRules({required this.rows, this.openMiddle, required this.room});

  final List<FieldRow> rows;
  final FieldRow? openMiddle;
  final RowRoom room;
}

/// A side while it is laid out: cards put on it, moved about and taken off
/// it by its [rules], no row ever wider than its room.
class PlacingBoard {
  PlacingBoard(this.rules, [PlacingSide? side]) : side = side ?? PlacingSide.empty();

  final PlacingRules rules;
  final PlacingSide side;

  /// A card that is no poem, to ask where any card would go.
  static const _anyCard = -1;

  List<int> get cards => side.cards;
  bool contains(int poemId) => side.placeOf(poemId) != null;

  /// The board with [poemId] taken off it; the cards outward of it in its
  /// cluster stay, those inward close up.
  PlacingBoard without(int poemId) {
    final place = side.placeOf(poemId);
    if (place == null) return this;
    final row = side.row(place.row);
    List<int> drop(List<int> cards) => [for (final c in cards) if (c != poemId) c];
    return _with(place.row, PlacingRow(left: drop(row.left), middle: drop(row.middle), right: drop(row.right)));
  }

  /// The board with [poemId] put at [spot], moved there when already on
  /// it; null when it may not go there: [spot] is not in play, or its row
  /// would grow too wide.
  PlacingBoard? put(int poemId, PlacingSpot spot) {
    if (spot case CardSpot(poemId: final target) when target == poemId) return contains(poemId) ? this : null;
    final base = without(poemId);
    final FieldRow at;
    final PlacingRow row;
    switch (spot) {
      case ClusterEnd(row: final r, :final part):
        if (!rules.rows.contains(r)) return null;
        final old = base.side.row(r);
        at = r;
        row = part == RowPart.left
            ? PlacingRow(left: [...old.left, poemId], middle: old.middle, right: old.right)
            : PlacingRow(left: old.left, middle: old.middle, right: [poemId, ...old.right]);
      case CardSpot(poemId: final target):
        final place = base.side.placeOf(target);
        if (place == null) return null;
        final old = base.side.row(place.row);
        List<int> insert(List<int> cards, int i) => [...cards.take(i), poemId, ...cards.skip(i)];
        at = place.row;
        row = switch (place.part) {
          RowPart.left => PlacingRow(left: insert(old.left, place.index), middle: old.middle, right: old.right),
          RowPart.middle => PlacingRow(left: old.left, middle: insert(old.middle, place.index), right: old.right),
          RowPart.right => PlacingRow(left: old.left, middle: old.middle, right: insert(old.right, place.index + 1)),
        };
      case OpenMiddle(row: final r, :final index):
        if (r != rules.openMiddle || !rules.rows.contains(r)) return null;
        final old = base.side.row(r);
        final i = index.clamp(0, old.middle.length);
        at = r;
        row = PlacingRow(left: old.left, middle: [...old.middle.take(i), poemId, ...old.middle.skip(i)], right: old.right);
    }
    return rules.room.fits(row) ? base._with(at, row) : null;
  }

  /// [spot] would take a card not on the board, or [card] moved there.
  bool takes(PlacingSpot spot, {int? card}) => put(card ?? _anyCard, spot) != null;

  /// The places off the cards that a card not on the board may go: each
  /// row in play's cluster ends, and its open middle, that it fits in.
  List<PlacingSpot> get freeSpots => [
        for (final row in rules.rows) ...[
          for (final part in const [RowPart.left, RowPart.right])
            if (takes(ClusterEnd(row, part))) ClusterEnd(row, part),
          if (takes(OpenMiddle(row, 0))) OpenMiddle(row, 0),
        ],
      ];

  PlacingBoard _with(FieldRow at, PlacingRow row) => PlacingBoard(rules, side.withRow(at, row));
}

/// Where a tap or a drop lands on a side being laid out: [base], with
/// [moving], the placed card being dragged, left out of it. [cards] is
/// where each of its cards lies, [clusterEnd] where the next place at a
/// cluster's inner end lies (null where there is no room for it), and
/// [openMiddle] where a row's open middle takes taps and drops (null where
/// the row does not show).
///
/// A card takes the spot it covers; past the cards, the free spots take
/// their own, the first listed first, and an open middle the place among
/// its middle cards under the touch. Spots the card does not fit take
/// nothing.
class PlacingTargets {
  PlacingTargets(
    this.base, {
    this.moving,
    required this.cards,
    required this.clusterEnd,
    FieldRect? Function(FieldRow row)? openMiddle,
  }) : openMiddle = openMiddle ?? _noMiddle;

  final PlacingBoard base;
  final int? moving;
  final Map<int, FieldRect> cards;
  final FieldRect? Function(FieldRow row, RowPart part) clusterEnd;
  final FieldRect? Function(FieldRow row) openMiddle;

  static FieldRect _noMiddle(FieldRow row) => throw StateError('$row has no open middle');

  bool _takes(PlacingSpot spot) => base.takes(spot, card: moving);

  /// The free spots past the cards, each where it lies: the cluster ends
  /// and open middles the card fits in.
  List<(PlacingSpot, FieldRect)> get freeSpots => [
        for (final spot in base.freeSpots)
          if (_rectOf(spot) case final rect?) (spot, rect),
      ];

  FieldRect? _rectOf(PlacingSpot spot) => switch (spot) {
        ClusterEnd(:final row, :final part) => clusterEnd(row, part),
        OpenMiddle(:final row) => openMiddle(row),
        CardSpot() => throw StateError('a free spot is never a card'),
      };

  /// What a card let go at ([x], [y]) would take, or null.
  PlacingSpot? spotAt(double x, double y) {
    for (final MapEntry(key: id, value: rect) in cards.entries) {
      if (rect.contains(x, y)) return _takes(CardSpot(id)) ? CardSpot(id) : null;
    }
    for (final (spot, rect) in freeSpots) {
      if (!rect.contains(x, y)) continue;
      if (spot is! OpenMiddle) return spot;
      final middle = base.side.row(spot.row).middle;
      final index = middle.where((id) => cards[id]!.x + cards[id]!.w / 2 < x).length;
      return OpenMiddle(spot.row, index);
    }
    return null;
  }
}
