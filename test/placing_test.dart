// The placing rules any side is laid out by: where a card may go and what
// that moves, and where a tap or a drop lands.
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/domain/field_parts.dart';
import 'package:fudatobashi/domain/placing.dart';

void main() {
  const lower = FieldRow.lower, middle = FieldRow.middle, upper = FieldRow.upper;
  const left = RowPart.left, right = RowPart.right;
  const room = RowRoom(slots: 10, clusterGap: 0.5, middleMargin: 0.5);
  const allRows = PlacingRules(rows: FieldRow.values, openMiddle: upper, room: room);
  const noMiddle = PlacingRules(rows: [lower, middle], room: room);

  // A side with [row] holding these cards.
  PlacingSide sideWith(FieldRow row, {List<int> l = const [], List<int> m = const [], List<int> r = const []}) =>
      PlacingSide.empty().withRow(row, PlacingRow(left: l, middle: m, right: r));

  group('the board', () {
    test('a cluster end takes a card at its inner end', () {
      final board = PlacingBoard(allRows, sideWith(lower, l: [1, 2], r: [3, 4]));
      expect(board.put(9, const ClusterEnd(lower, left))!.side.row(lower).left, [1, 2, 9]);
      expect(board.put(9, const ClusterEnd(lower, right))!.side.row(lower).right, [9, 3, 4]);
    });

    test("a card put on a card takes its place, the cards inward of it moving a place in", () {
      final board = PlacingBoard(allRows, sideWith(middle, l: [1, 2, 3], r: [4, 5, 6]));
      expect(board.put(9, const CardSpot(2))!.side.row(middle).left, [1, 9, 2, 3]);
      expect(board.put(9, const CardSpot(5))!.side.row(middle).right, [4, 5, 9, 6]);
    });

    test('a card moved closes the gap it leaves; let go on its own place, nothing changes', () {
      final board = PlacingBoard(allRows, sideWith(lower, l: [1, 2, 3], r: [4]));
      final moved = board.put(1, const ClusterEnd(middle, right))!;
      expect(moved.side.row(lower).left, [2, 3]);
      expect(moved.side.row(middle).right, [1]);
      expect(board.put(2, const CardSpot(2)), same(board));
      expect(board.without(7), same(board), reason: 'not on the board');
    });

    test('only the rows in play take cards, and an open middle only where the rules have one', () {
      final board = PlacingBoard(noMiddle);
      expect(board.takes(const ClusterEnd(upper, left)), isFalse);
      expect(board.takes(const OpenMiddle(upper, 0)), isFalse);
      expect(board.takes(const OpenMiddle(lower, 0)), isFalse);
      expect(board.freeSpots, [
        const ClusterEnd(lower, left),
        const ClusterEnd(lower, right),
        const ClusterEnd(middle, left),
        const ClusterEnd(middle, right),
      ]);
      final open = PlacingBoard(allRows, sideWith(upper, m: [1, 2]));
      expect(open.put(9, const OpenMiddle(upper, 1))!.side.row(upper).middle, [1, 9, 2]);
    });

    test("a row takes cards while its room holds them and its clusters' gap", () {
      // 10 pitches with half a pitch between the clusters: 9 cards.
      final nine = PlacingBoard(noMiddle, sideWith(lower, l: [1, 2, 3, 4, 5], r: [6, 7, 8, 9]));
      expect(room.span(nine.side.row(lower)), 9.5);
      expect(nine.takes(const ClusterEnd(lower, left)), isFalse);
      expect(nine.takes(const CardSpot(3)), isFalse, reason: 'nor on a card');
      expect(nine.takes(const CardSpot(3), card: 6), isTrue, reason: 'a card of the row moves within it');
      final eight = nine.without(9);
      expect(eight.takes(const ClusterEnd(lower, right)), isTrue);
    });
  });

  group('targets', () {
    // A side laid out a unit a pitch: cards 0.9 wide, rows 1.5 apart from
    // 下段 at the bottom; the left cluster from x = 0, the right one ending
    // at x = 10.
    const w = 0.9, h = 1.2;
    double top(FieldRow row) => (2 - row.index) * 1.5;

    Map<int, FieldRect> cardsOf(PlacingSide side) => {
          for (final row in FieldRow.values) ...{
            for (final (i, id) in side.row(row).left.indexed) id: FieldRect(i.toDouble(), top(row), w, h),
            for (final (i, id) in side.row(row).right.reversed.indexed) id: FieldRect(9.0 - i, top(row), w, h),
          },
        };

    FieldRect end(PlacingSide side, FieldRow row, RowPart part) {
      final r = side.row(row);
      return FieldRect(part == left ? r.left.length.toDouble() : 9.0 - r.right.length, top(row), w, h);
    }

    test('a card takes its place first; past the cards a cluster end takes its own', () {
      final board = PlacingBoard(noMiddle, sideWith(lower, l: [1, 2], r: [3]));
      final t = PlacingTargets(board, cards: cardsOf(board.side), clusterEnd: (row, part) => end(board.side, row, part));
      expect(t.spotAt(1.5, top(lower) + 0.5), const CardSpot(2));
      expect(t.spotAt(2.5, top(lower) + 0.5), const ClusterEnd(lower, left));
      expect(t.spotAt(8.5, top(lower) + 0.5), const ClusterEnd(lower, right));
      expect(t.spotAt(5, top(lower) + 0.5), isNull, reason: 'the gap between');
      expect(t.spotAt(0.5, top(middle) + 0.5), const ClusterEnd(middle, left));
      expect(t.spotAt(0.5, top(upper) + 0.5), isNull, reason: 'a row out of play');
    });

    test('a cluster end the geometry has no room for is not offered and takes nothing', () {
      final board = PlacingBoard(noMiddle, sideWith(lower, l: [1, 2], r: [3]));
      final t = PlacingTargets(
        board,
        cards: cardsOf(board.side),
        clusterEnd: (row, part) => row == lower && part == right ? null : end(board.side, row, part),
      );
      expect(t.freeSpots.map((s) => s.$1), isNot(contains(const ClusterEnd(lower, right))));
      expect(t.freeSpots.map((s) => s.$1), contains(const ClusterEnd(lower, left)));
      expect(t.spotAt(8.5, top(lower) + 0.5), isNull);
    });

    test('a card dragged out of a full row frees its room', () {
      final board = PlacingBoard(noMiddle, sideWith(lower, l: [1, 2, 3, 4, 5], r: [6, 7, 8, 9]));
      FieldRect? ends(FieldRow row, RowPart part) => end(board.side, row, part);
      final cards = cardsOf(board.side);
      expect(PlacingTargets(board, cards: cards, clusterEnd: ends).spotAt(0.5, top(lower) + 0.5), isNull);
      final moving = PlacingTargets(board.without(9), moving: 9, cards: cards..remove(9), clusterEnd: ends);
      expect(moving.spotAt(0.5, top(lower) + 0.5), const CardSpot(1));
    });

    test('an open middle takes the place among its middle cards under the touch', () {
      final board = PlacingBoard(allRows, sideWith(upper, m: [30, 31]));
      final cards = {30: FieldRect(3, top(upper), w, h), 31: FieldRect(6, top(upper), w, h)};
      final t = PlacingTargets(
        board,
        cards: cards,
        clusterEnd: (row, part) => FieldRect(part == left ? 0 : 9, top(row), w, h),
        openMiddle: (row) => FieldRect(1, top(row), 8, h),
      );
      expect(t.spotAt(2.5, top(upper) + 0.5), const OpenMiddle(upper, 0));
      expect(t.spotAt(5, top(upper) + 0.5), const OpenMiddle(upper, 1));
      expect(t.spotAt(8, top(upper) + 0.5), const OpenMiddle(upper, 2));
      expect(t.spotAt(3.5, top(upper) + 0.5), const CardSpot(30));
    });
  });
}
