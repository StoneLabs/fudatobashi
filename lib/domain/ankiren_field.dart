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
/// - With [AnkirenTuning.middleChancePerSide], it puts a few cards in the
///   open middle of one row ([AnkirenTuning.middleRows]), at most half its
///   cards. The first is a card with a 友札 anywhere on the field when there is
///   one; no two middle cards of a side are each other's 友札.
/// - The rest form the left and right clusters. 下段 fills first, 上段 is the
///   sparsest (see [rowCounts]), and each row splits left / right (see
///   [leftCount]).
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

  AnkirenField deal(List<int> known, int perSide, math.Random rng) {
    final deck = {...known}.toList()..shuffle(rng);
    assert(perSide >= 1 && deck.length >= 2 * perSide, 'not enough known cards for $perSide per side');
    final ownCards = deck.sublist(0, perSide);
    final opponentCards = deck.sublist(perSide, 2 * perSide);
    final field = {...ownCards, ...opponentCards};
    return AnkirenField(
      own: _arrange(ownCards, field, rng),
      opponent: _arrange(opponentCards, field, rng),
    );
  }

  /// Cards per row for [clustered] cluster cards, indexed by [FieldRow.index].
  static List<int> rowCounts(int clustered) {
    final lower = (clustered + 2) ~/ 3;
    final rest = clustered - lower;
    final middle = math.min(lower, (rest * AnkirenTuning.middleRowPercent + 99) ~/ 100);
    return [lower, middle, rest - middle];
  }

  /// How many of a row's [n] cluster cards go to its left cluster: the extra
  /// card of an odd row goes left, except in 中段 where it goes right.
  static int leftCount(FieldRow row, int n) => row == FieldRow.middle ? n ~/ 2 : (n + 1) ~/ 2;

  AnkirenHalf _arrange(List<int> cards, Set<int> field, math.Random rng) {
    final middle = _middleCards(cards, field, rng);
    final middleRow = AnkirenTuning.middleRows[rng.nextInt(AnkirenTuning.middleRows.length)];
    final clustered = [for (final c in cards) if (!middle.contains(c)) c];

    final counts = rowCounts(clustered.length);
    final leftRows = [for (final r in FieldRow.values) leftCount(r, counts[r.index])];
    final rightRows = [for (final r in FieldRow.values) counts[r.index] - leftRows[r.index]];
    final (left, right) = _splitClusters(clustered, leftRows.fold(0, (a, b) => a + b), rng);
    final leftByRow = _fillRows(left, leftRows, rng);
    final rightByRow = _fillRows(right, rightRows, rng);

    return AnkirenHalf([
      for (final r in FieldRow.values)
        AnkirenRow(
          left: leftByRow[r.index],
          middle: r == middleRow ? middle : const [],
          right: rightByRow[r.index],
        ),
    ]);
  }

  List<int> _middleCards(List<int> cards, Set<int> field, math.Random rng) {
    if (rng.nextDouble() >= AnkirenTuning.middleChancePerSide) return const [];
    final range = AnkirenTuning.middleMax - AnkirenTuning.middleMin + 1;
    final k = math.min(AnkirenTuning.middleMin + rng.nextInt(range), cards.length ~/ 2);
    if (k == 0) return const [];

    final paired = [for (final c in cards) if (tomofuda(c).any(field.contains)) c];
    final first = paired.isEmpty ? cards[rng.nextInt(cards.length)] : paired[rng.nextInt(paired.length)];
    final chosen = [first];
    for (final c in [...cards]..shuffle(rng)) {
      if (chosen.length == k) break;
      if (c != first && !chosen.any((m) => tomofuda(m).contains(c))) chosen.add(c);
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
