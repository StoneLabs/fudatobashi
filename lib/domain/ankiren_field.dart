import 'dart:math' as math;

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';

/// The two halves of the field: the player's own (自陣, the bottom of the
/// screen) and the opponent's (敵陣, the top).
enum FieldSide { own, opponent }

/// The rows of one half, from its owner outward: 下段, 中段, 上段 (the row at
/// the centre line).
enum FieldRow { lower, middle, upper }

/// One row of one half, each list running left to right as the half's owner
/// sees it.
class AnkirenRow {
  AnkirenRow({required List<int> left, required List<int> middle, required List<int> right})
      : left = List.unmodifiable(left),
        middle = List.unmodifiable(middle),
        right = List.unmodifiable(right);

  /// The left cluster, from the outer edge inward.
  final List<int> left;

  /// Cards dealt into the open middle between the clusters (usually none).
  final List<int> middle;

  /// The right cluster, from the inner end out to the edge.
  final List<int> right;

  /// The row's cards, left to right.
  List<int> get cards => [...left, ...middle, ...right];
  bool get isEmpty => left.isEmpty && middle.isEmpty && right.isEmpty;
}

/// One side's arrangement (定位置), as its owner sees it.
class AnkirenHalf {
  AnkirenHalf(List<AnkirenRow> rows)
      : assert(rows.length == FieldRow.values.length),
        rows = List.unmodifiable(rows);

  /// Indexed by [FieldRow.index].
  final List<AnkirenRow> rows;

  AnkirenRow row(FieldRow r) => rows[r.index];
  List<int> get cards => [for (final r in rows) ...r.cards];

  /// The cards in the open middle (all in one row).
  List<int> get middleCards => [for (final r in rows) ...r.middle];

  /// The row holding the middle cards, or null when there are none.
  FieldRow? get middleRow {
    for (final r in FieldRow.values) {
      if (row(r).middle.isNotEmpty) return r;
    }
    return null;
  }
}

/// A dealt 暗記練 field: both halves' arrangements.
class AnkirenField {
  AnkirenField({required this.own, required this.opponent});

  final AnkirenHalf own;
  final AnkirenHalf opponent;

  AnkirenHalf half(FieldSide side) => side == FieldSide.own ? own : opponent;
  List<int> get cards => [...own.cards, ...opponent.cards];
  int get perSide => own.cards.length;

  FieldSide? sideOf(int poemId) => own.cards.contains(poemId)
      ? FieldSide.own
      : opponent.cards.contains(poemId)
          ? FieldSide.opponent
          : null;
}

/// Deals 暗記練 fields like a real player lays out a 定位置, every random
/// choice drawn from the given `Random`, so a seed always deals the same
/// field.
///
/// The known cards are shuffled and 2 × perSide are dealt, the first half to
/// the own side. Then each side, on its own:
/// - A side big enough for an open middle ([maxMiddle]) that holds a 友札
///   pair ([middleCandidates]) splits it, with
///   [AnkirenTuning.middleChancePerSide]: a few cards go to the open middle
///   of [AnkirenTuning.middleRow], each with a 友札 left in the clusters, no
///   two of them each other's 友札.
/// - The rest form the left and right clusters, in a shape that varies from
///   deal to deal: 下段 fills first and stays the fullest ([rowShapes]), and
///   each row splits about evenly between left and right ([leftOf]).
/// - A side's 友札 are split between the left and right clusters as far as
///   their room allows. Inside a cluster the shortest kimariji take 下段, the
///   longest 上段; within a row the order is random.
class AnkirenDealer {
  AnkirenDealer({required this.tomofuda, required this.kimarijiLength});

  /// A dealer over the app's poems and 友札 sets.
  factory AnkirenDealer.ofPoems() {
    final tomo = {for (final p in poems.all) p.id: fudaSets.tomofuda(p.id)};
    return AnkirenDealer(tomofuda: (id) => tomo[id]!, kimarijiLength: (id) => poems[id].kimariji.length);
  }

  /// A card's 友札: the cards it is easily confused with.
  final List<int> Function(int poemId) tomofuda;
  final int Function(int poemId) kimarijiLength;

  /// [allInMiddle] lays each side out for beginners: every card in the open
  /// middle of [AnkirenTuning.middleRow], in random order.
  AnkirenField deal(List<int> known, int perSide, math.Random rng, {bool allInMiddle = false}) {
    final deck = {...known}.toList()..shuffle(rng);
    assert(perSide >= 1 && deck.length >= 2 * perSide, 'not enough known cards for $perSide per side');
    final ownCards = deck.sublist(0, perSide);
    final opponentCards = deck.sublist(perSide, 2 * perSide);
    AnkirenHalf arrange(List<int> cards) => allInMiddle ? _spread(cards) : _arrange(cards, rng);
    return AnkirenField(own: arrange(ownCards), opponent: arrange(opponentCards));
  }

  /// The most cards a side of [perSide] may put in the open middle: none
  /// below [AnkirenTuning.middleMinPerSide], else up to
  /// [AnkirenTuning.middleMax] as long as [AnkirenTuning.middleMinClustered]
  /// stay in its clusters.
  static int maxMiddle(int perSide) {
    if (perSide < AnkirenTuning.middleMinPerSide) return 0;
    final room = math.min(AnkirenTuning.middleMax, perSide - AnkirenTuning.middleMinClustered);
    return room < AnkirenTuning.middleMin ? 0 : room;
  }

  static bool mayHaveMiddle(int perSide) => maxMiddle(perSide) > 0;

  /// The typical shape (cards per row, by [FieldRow.index]) for [clustered]
  /// cluster cards (see [AnkirenTuning.singleRowUpTo]), when
  /// [AnkirenTuning.middleRow] also holds [middleCards] (see
  /// [AnkirenTuning.rowMax]); a deal varies it ([rowShapes]).
  static List<int> rowCounts(int clustered, {int middleCards = 0}) {
    if (clustered <= AnkirenTuning.singleRowUpTo) return [clustered, 0, 0];
    if (clustered <= AnkirenTuning.twoRowsUpTo) return [(clustered + 1) ~/ 2, clustered ~/ 2, 0];
    var lower = (clustered + 2) ~/ 3;
    final rest = clustered - lower;
    var middle = math.min(lower, (rest * AnkirenTuning.middleRowPercent + 99) ~/ 100);
    final upper = math.min(rest - middle, AnkirenTuning.rowMax - middleCards);
    for (var spill = rest - middle - upper; spill > 0; spill--) {
      lower > middle ? middle++ : lower++;
    }
    return [lower, middle, upper];
  }

  /// The cards of a side that may go to its open middle: those with a 友札
  /// among its other cards.
  List<int> middleCandidates(List<int> side) => [
        for (final c in side)
          if (tomofuda(c).any((t) => t != c && side.contains(t))) c,
      ];

  /// Every shape (cards per row, by [FieldRow.index]) a side may give its
  /// [clustered] cluster cards when [AnkirenTuning.middleRow] also holds
  /// [middleCards]: the rows [rowCounts] uses, each within
  /// [AnkirenTuning.rowJitter] of it, 下段 the fullest, and no row over
  /// [AnkirenTuning.rowMax] with its middle cards.
  static List<List<int>> rowShapes(int clustered, {int middleCards = 0}) {
    final base = rowCounts(clustered, middleCards: middleCards);
    const j = AnkirenTuning.rowJitter;
    bool fits(List<int> shape) => FieldRow.values.every((r) {
          final n = shape[r.index];
          final room = AnkirenTuning.rowMax - (r == AnkirenTuning.middleRow ? middleCards : 0);
          return n >= 0 && n <= room && (n > 0) == (base[r.index] > 0) && n <= shape[FieldRow.lower.index];
        });
    return [
      for (var lower = base[0] - j; lower <= base[0] + j; lower++)
        for (var middle = base[1] - j; middle <= base[1] + j; middle++)
          if ((clustered - lower - middle - base[2]).abs() <= j && fits([lower, middle, clustered - lower - middle]))
            [lower, middle, clustered - lower - middle],
    ];
  }

  /// How many of a row's [n] cluster cards go to its left cluster: half, the
  /// odd card either way, and with [AnkirenTuning.splitLean] one card more to
  /// one side.
  static int leftOf(int n, math.Random rng) {
    var left = n ~/ 2 + (n.isOdd && rng.nextBool() ? 1 : 0);
    if (rng.nextDouble() < AnkirenTuning.splitLean) left += rng.nextBool() ? 1 : -1;
    return left.clamp(0, n);
  }

  static AnkirenHalf _spread(List<int> cards) => AnkirenHalf([
        for (final r in FieldRow.values)
          AnkirenRow(left: const [], middle: r == AnkirenTuning.middleRow ? cards : const [], right: const []),
      ]);

  AnkirenHalf _arrange(List<int> cards, math.Random rng) {
    final middle = _middleCards(cards, rng);
    final clustered = [for (final c in cards) if (!middle.contains(c)) c];

    final shapes = rowShapes(clustered.length, middleCards: middle.length);
    final counts = shapes[rng.nextInt(shapes.length)];
    final leftRows = [for (final n in counts) leftOf(n, rng)];
    final rightRows = [for (final r in FieldRow.values) counts[r.index] - leftRows[r.index]];
    final (left, right) = _splitClusters(clustered, leftRows.fold(0, (a, b) => a + b), rng);
    final leftByRow = _fillRows(left, leftRows, rng);
    final rightByRow = _fillRows(right, rightRows, rng);

    return AnkirenHalf([
      for (final r in FieldRow.values)
        AnkirenRow(
          left: leftByRow[r.index],
          middle: r == AnkirenTuning.middleRow ? middle : const [],
          right: rightByRow[r.index],
        ),
    ]);
  }

  List<int> _middleCards(List<int> cards, math.Random rng) {
    final most = maxMiddle(cards.length);
    final candidates = middleCandidates(cards);
    if (most == 0 || candidates.isEmpty || rng.nextDouble() >= AnkirenTuning.middleChancePerSide) return const [];
    final k = AnkirenTuning.middleMin + rng.nextInt(most - AnkirenTuning.middleMin + 1);
    final chosen = <int>[];
    for (final c in candidates..shuffle(rng)) {
      if (chosen.length == k) break;
      if (!chosen.any((m) => tomofuda(m).contains(c) || tomofuda(c).contains(m))) chosen.add(c);
    }
    return chosen;
  }

  /// Splits a side's cluster cards into the left cluster ([leftRoom] cards)
  /// and the right one: each 友札 family alternates between them while there
  /// is room, the other cards fill what is left.
  (List<int>, List<int>) _splitClusters(List<int> cards, int leftRoom, math.Random rng) {
    final rightRoom = cards.length - leftRoom;
    final left = <int>[], right = <int>[];
    bool goesLeft(int inLeft, int inRight) {
      final roomLeft = leftRoom - left.length, roomRight = rightRoom - right.length;
      if (roomLeft == 0 || roomRight == 0) return roomLeft > 0;
      if (inLeft != inRight) return inLeft < inRight;
      if (roomLeft != roomRight) return roomLeft > roomRight;
      return rng.nextBool();
    }

    for (final family in _families(cards, rng)..sort((a, b) => b.length - a.length)) {
      var inLeft = 0, inRight = 0;
      for (final c in family) {
        if (goesLeft(inLeft, inRight)) {
          left.add(c);
          inLeft++;
        } else {
          right.add(c);
          inRight++;
        }
      }
    }
    return (left, right);
  }

  /// [cards] grouped into 友札 families (each card with every card it is
  /// linked to by 友札, directly or not), in random order.
  List<List<int>> _families(List<int> cards, math.Random rng) {
    final shuffled = [...cards]..shuffle(rng);
    final families = <List<int>>[];
    final placed = <int>{};
    for (final c in shuffled) {
      if (!placed.add(c)) continue;
      final family = [c];
      for (var i = 0; i < family.length; i++) {
        for (final t in tomofuda(family[i])) {
          if (shuffled.contains(t) && placed.add(t)) family.add(t);
        }
      }
      families.add(family);
    }
    return families;
  }

  /// Deals one cluster's cards into its rows ([perRow], by [FieldRow.index]):
  /// the shortest kimariji to 下段 first, then 中段, then 上段, equal lengths
  /// in random order; the order within a row is random too.
  List<List<int>> _fillRows(List<int> cluster, List<int> perRow, math.Random rng) {
    final shuffled = [...cluster]..shuffle(rng);
    final order = [for (var i = 0; i < shuffled.length; i++) i]..sort((a, b) {
        final byLength = kimarijiLength(shuffled[a]).compareTo(kimarijiLength(shuffled[b]));
        return byLength != 0 ? byLength : a.compareTo(b);
      });
    final rows = <List<int>>[];
    var next = 0;
    for (final n in perRow) {
      rows.add([for (final i in order.sublist(next, next + n)) shuffled[i]]..shuffle(rng));
      next += n;
    }
    return rows;
  }
}
