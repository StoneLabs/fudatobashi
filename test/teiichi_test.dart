// 定位置's rules away from the screen: which games a custom setup allows,
// where a card may go on the own side and what that moves, where a tap or a
// drop lands, the stack and its placing times, and the cards slowest to
// place.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_geometry.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/teiichi_placing.dart';
import 'package:fudatobashi/domain/teiichi_record.dart';

void main() {
  const upper = FieldRow.upper, middle = FieldRow.middle, lower = FieldRow.lower;
  const left = RowPart.left, right = RowPart.right;

  // A board of the usual game with [row] holding these cards.
  TeiichiBoard boardWith(FieldRow row, {List<int> l = const [], List<int> m = const [], List<int> r = const []}) =>
      TeiichiBoard(TeiichiSetup.usual, AnkirenHalf([
        for (final x in FieldRow.values)
          x == row ? AnkirenRow(left: l, middle: m, right: r) : AnkirenRow(left: const [], middle: const [], right: const []),
      ]));

  List<int> ids(int from, int n) => [for (var i = 0; i < n; i++) from + i];

  group('the side trip', () {
    test('the storehouse island is 定位置, open like 暗記練 once enough cards are seen', () {
      expect(SideTripIsle.storehouse.trip, SideTrip.teiichi);
      expect(SideTripIsle.storehouse.comingSoon, isFalse);
      const opens = SideTripTuning.teiichiSeen;
      final shut = SideTripsHub.of(allKnown: false, seen: opens - 1)[SideTrip.teiichi];
      expect(shut.lock?.needed, 1);
      expect(SideTripsHub.of(allKnown: false, seen: opens)[SideTrip.teiichi].open, isTrue);
      expect(SideTripsHub.of(allKnown: false, seen: 0, latched: {SideTrip.teiichi})[SideTrip.teiichi].open, isTrue);
      expect(SideTripsHub.of(allKnown: true, seen: 0)[SideTrip.teiichi].open, isTrue);
    });
  });

  group('custom games', () {
    test('three rows hold the usual game; two and one rows hold their share of it', () {
      expect(TeiichiSetup.mostCards(3), TeiichiTuning.cards);
      expect(TeiichiSetup.mostCards(2), TeiichiTuning.cards * 2 ~/ 3);
      expect(TeiichiSetup.mostCards(1), TeiichiTuning.cards ~/ 3);
      for (var cards = TeiichiTuning.minCards; cards <= TeiichiTuning.cards; cards++) {
        for (var rows = 1; rows <= 3; rows++) {
          expect(TeiichiSetup.allows(cards: cards, rows: rows), cards <= TeiichiSetup.mostCards(rows),
              reason: '$cards cards in $rows rows');
        }
      }
    });

    test('more cards than the rows hold take as few more rows as needed', () {
      final two = TeiichiSetup.mostCards(2), one = TeiichiSetup.mostCards(1);
      expect(TeiichiSetup.rowsFor(one, 1), 1);
      expect(TeiichiSetup.rowsFor(one + 1, 1), 2);
      expect(TeiichiSetup.rowsFor(two + 1, 1), 3);
      expect(TeiichiSetup.rowsFor(two + 1, 2), 3);
      expect(TeiichiSetup.rowsFor(one, 3), 3, reason: 'more rows than needed stay');
    });

    test('the most cards a game takes is what the known cards allow, up to the usual game', () {
      expect(TeiichiSetup.maxCards(100), TeiichiTuning.cards);
      expect(TeiichiSetup.maxCards(TeiichiTuning.minCards + 1), TeiichiTuning.minCards + 1);
      expect(TeiichiSetup.maxCards(TeiichiTuning.minCards - 1), isNull);
    });

    test('the rows played fill from the player outward, the open middle only with all three', () {
      expect(const TeiichiSetup(cards: 8, rows: 1).rowsInPlay, [lower]);
      expect(const TeiichiSetup(cards: 8, rows: 2).rowsInPlay, [lower, middle]);
      expect(TeiichiSetup.usual.rowsInPlay, [lower, middle, upper]);
      expect([for (var rows = 1; rows <= 3; rows++) TeiichiSetup(cards: 8, rows: rows).openMiddle], [false, false, true]);
      expect(TeiichiSetup.usual.custom, isFalse);
      expect(const TeiichiSetup(cards: 25, rows: 3).custom, isFalse);
      expect(const TeiichiSetup(cards: 20, rows: 3).custom, isTrue);
      expect(const TeiichiSetup(cards: 20, rows: 3).full, isFalse);
    });
  });

  group('the board', () {
    test('a card goes to the inner end of a cluster', () {
      final board = boardWith(lower, l: [1, 2], r: [3, 4]);
      expect(board.put(9, const ClusterEnd(lower, left))!.half.row(lower).left, [1, 2, 9]);
      expect(board.put(9, const ClusterEnd(lower, right))!.half.row(lower).right, [9, 3, 4]);
    });

    test('a card put on a placed card takes its spot, the cards inward of it moving one place in', () {
      final board = boardWith(lower, l: [1, 2, 3], m: [], r: [4, 5, 6]);
      expect(board.put(9, const CardSpot(2))!.half.row(lower).left, [1, 9, 2, 3]);
      // The right cluster runs from its inner end out: 4 and 5 move in.
      expect(board.put(9, const CardSpot(5))!.half.row(lower).right, [4, 5, 9, 6]);
    });

    test('the open middle takes a card among its middle cards, only in the row with it', () {
      final board = boardWith(upper, m: [1, 2]);
      expect(board.put(9, const OpenMiddle(upper, 1))!.half.row(upper).middle, [1, 9, 2]);
      expect(board.put(9, const OpenMiddle(upper, 7))!.half.row(upper).middle, [1, 2, 9]);
      expect(board.put(9, const CardSpot(2))!.half.row(upper).middle, [1, 9, 2]);
      expect(boardWith(lower).put(9, const OpenMiddle(lower, 0)), isNull);
    });

    test('a placed card moves: off its spot, its cluster closing up, and onto the new one', () {
      final board = boardWith(lower, l: [1, 2, 3], r: [4]);
      final moved = board.put(1, const ClusterEnd(lower, right))!;
      expect([moved.half.row(lower).left, moved.half.row(lower).right], [
        [2, 3],
        [1, 4],
      ]);
      expect(board.put(3, const CardSpot(1))!.half.row(lower).left, [3, 1, 2]);
      expect(board.put(2, const CardSpot(2)), same(board), reason: 'let go on its own spot');
      expect(board.without(2).half.row(lower).left, [1, 3]);
    });

    test('rows not in play take nothing', () {
      final board = TeiichiBoard(const TeiichiSetup(cards: 8, rows: 1));
      expect(board.put(9, const ClusterEnd(lower, left)), isNotNull);
      expect(board.put(9, const ClusterEnd(middle, left)), isNull);
      expect(board.put(9, const ClusterEnd(upper, right)), isNull);
      expect(board.freeSpots, [const ClusterEnd(lower, left), const ClusterEnd(lower, right)]);
    });

    test('a row holds its clusters with half a card between them, whatever the split', () {
      final most = (TeiichiTuning.rowSlots - TeiichiTuning.clusterGap).floor();
      for (var l = 0; l <= most; l++) {
        final full = boardWith(lower, l: ids(1, l), r: ids(50, most - l));
        expect(TeiichiBoard.span(full.half.row(lower)), lessThanOrEqualTo(TeiichiTuning.rowSlots));
        expect(full.takes(const ClusterEnd(lower, left)), isFalse, reason: '$l left, ${most - l} right');
        expect(full.takes(const ClusterEnd(lower, right)), isFalse);
        expect(full.takes(CardSpot(full.cards.first)), isFalse, reason: 'nor a card put on a placed one');
        expect(full.freeSpots.where((s) => s is ClusterEnd && s.row == lower), isEmpty);
      }
      // With 8 on the right, the left takes 8 at most.
      final eight = boardWith(lower, l: ids(1, 7), r: ids(50, 8));
      expect(eight.put(9, const ClusterEnd(lower, left)), isNotNull);
      expect(eight.put(9, const ClusterEnd(lower, left))!.takes(const ClusterEnd(lower, left)), isFalse);
    });

    test('middle cards keep their margin either side, and the clusters lose room to them', () {
      const margin = AnkirenFieldSize.middleMargin;
      final withTwo = boardWith(upper, l: ids(1, 6), m: [30, 31], r: ids(50, 6));
      expect(TeiichiBoard.span(withTwo.half.row(upper)), 6 + 6 + 2 + 2 * margin);
      final full = boardWith(upper, l: ids(1, 7), m: [30, 31], r: ids(50, 6));
      expect(full.takes(const ClusterEnd(upper, left)), isFalse);
      expect(full.takes(const OpenMiddle(upper, 0)), isFalse);
      expect(full.put(1, const OpenMiddle(upper, 0)), isNotNull, reason: 'a card moved in from its cluster fits');
    });

    test('no row limit of 暗記練\'s: a row takes up to what its width holds', () {
      final wide = boardWith(lower, l: ids(1, 12), r: ids(50, 3));
      expect(wide.half.row(lower).cards.length, greaterThan(AnkirenTuning.rowMax));
      expect(wide.takes(const ClusterEnd(lower, left)), isTrue);
    });
  });

  group('targets', () {
    test('a card takes its spot; past the cards the dashed spots and the open middle take theirs', () {
      final board = boardWith(upper, l: [1, 2], m: [30], r: [50]);
      final t = TeiichiTargets(board);
      final g = t.geometry;
      final cards = g.half(FieldSide.own);
      double cx(FieldRect r) => r.x + r.w / 2;
      double cy(FieldRect r) => r.y + r.h / 2;
      expect(t.spotAt(cx(cards[2]!), cy(cards[2]!)), const CardSpot(2));
      expect(t.spotAt(cx(cards[30]!), cy(cards[30]!)), const CardSpot(30));
      final next = g.slot(upper, 2)!;
      expect(t.spotAt(cx(next), cy(next)), const ClusterEnd(upper, left));
      final nextRight = g.slot(upper, TeiichiTuning.rowSlots - 2)!;
      expect(t.spotAt(cx(nextRight), cy(nextRight)), const ClusterEnd(upper, right));
      final (start, end) = g.gapOf(board.half.row(upper));
      final mid = (start + end) / 2;
      final reach = (end - start) * TeiichiTuning.openMiddleShare / 2;
      expect(t.spotAt(cx(cards[30]!) - AnkirenFieldSize.cardW, cy(next)), const OpenMiddle(upper, 0));
      expect(t.spotAt(cx(cards[30]!) + AnkirenFieldSize.cardW, cy(next)), const OpenMiddle(upper, 1));
      expect(t.spotAt(mid - reach - 1, cy(next)), isNot(isA<OpenMiddle>()),
          reason: 'only the middle share of the gap is the open middle');
      final lowerStart = g.slot(lower, 0)!;
      expect(t.spotAt(cx(lowerStart), cy(lowerStart)), const ClusterEnd(lower, left));
    });

    test('the open middle grows to cover its middle cards', () {
      final crowded = boardWith(upper, m: ids(30, 5));
      final t = TeiichiTargets(crowded);
      final (_, rect) = t.freeSpots.firstWhere((s) => s.$1 is OpenMiddle);
      for (final r in [for (final id in ids(30, 5)) t.geometry.half(FieldSide.own)[id]!]) {
        expect(rect.x <= r.x && rect.right >= r.right, isTrue, reason: '$r in $rect');
      }
    });

    test('a full row shows no spots and takes no drop; a card dragged out of it frees its room', () {
      final most = (TeiichiTuning.rowSlots - TeiichiTuning.clusterGap).floor();
      final full = boardWith(lower, l: ids(1, most - 8), r: ids(50, 8));
      final t = TeiichiTargets(full);
      expect(t.freeSpots.where((s) => s.$1 is ClusterEnd && (s.$1 as ClusterEnd).row == lower), isEmpty);
      final card = t.geometry.half(FieldSide.own)[1]!;
      expect(t.spotAt(card.x + 1, card.y + 1), isNull);
      final moving = TeiichiTargets(full, moving: 50);
      expect(moving.spotAt(card.x + 1, card.y + 1), const CardSpot(1));
    });

    test('the field is a row of 16.5 pitches at true scale, whatever is on it', () {
      final empty = TeiichiTargets(TeiichiBoard(TeiichiSetup.usual)).geometry;
      final full = TeiichiTargets(boardWith(lower, l: ids(1, 8), r: ids(50, 8))).geometry;
      const span = TeiichiTuning.rowSlots * FieldGeometry.pitch - AnkirenFieldSize.cardGap;
      expect([empty.width, empty.height], [full.width, full.height]);
      expect(empty.width, closeTo(span, 1e-9));
      final cards = full.half(FieldSide.own);
      expect(cards[1]!.x, closeTo(0, 1e-9));
      expect(cards[57]!.right, closeTo(span, 1e-9));
    });
  });

  group('the stack', () {
    test('the top card goes first, with no skipping, until none is left', () {
      final placing = TeiichiPlacing(const TeiichiSetup(cards: 3, rows: 1), [5, 6, 7]);
      expect([placing.top, placing.left], [5, 3]);
      expect(placing.placeTop(const ClusterEnd(lower, left), const Duration(seconds: 1)), isTrue);
      expect([placing.top, placing.left], [6, 2]);
      expect(placing.placeTop(const ClusterEnd(upper, left), const Duration(seconds: 2)), isFalse,
          reason: 'a row out of play');
      expect(placing.top, 6);
      placing
        ..placeTop(const ClusterEnd(lower, right), const Duration(seconds: 2))
        ..placeTop(const CardSpot(5), const Duration(seconds: 3));
      expect(placing.allPlaced, isTrue);
      expect(placing.top, isNull);
      expect(placing.board.half.row(lower).left, [7, 5]);
      expect(placing.order, [5, 6, 7]);
    });

    test('a placed card taken back goes on top, and is placed again next', () {
      final placing = TeiichiPlacing(const TeiichiSetup(cards: 3, rows: 1), [5, 6, 7])
        ..placeTop(const ClusterEnd(lower, left), const Duration(seconds: 1));
      expect(placing.takeBack(5, const Duration(seconds: 2)), isTrue);
      expect([placing.top, placing.left, placing.board.cards], [5, 3, <int>[]]);
      expect(placing.takeBack(6, const Duration(seconds: 2)), isFalse, reason: 'not placed');
    });

    test('done only once every card is placed; then nothing moves', () {
      final placing = TeiichiPlacing(const TeiichiSetup(cards: 2, rows: 1), [5, 6])
        ..placeTop(const ClusterEnd(lower, left), const Duration(seconds: 1));
      expect(placing.finish(const Duration(seconds: 2)), isFalse);
      placing.placeTop(const ClusterEnd(lower, left), const Duration(seconds: 3));
      expect(placing.move(5, const ClusterEnd(lower, right)), isTrue);
      expect(placing.finish(const Duration(seconds: 4)), isTrue);
      expect(placing.placingTime, const Duration(seconds: 4));
      expect(placing.move(6, const ClusterEnd(lower, right)), isFalse);
      expect(placing.takeBack(6, const Duration(seconds: 5)), isFalse);
    });

    test('a card\'s placing time is how long it was on top, every time it was', () {
      final placing = TeiichiPlacing(const TeiichiSetup(cards: 3, rows: 1), [5, 6, 7])
        ..placeTop(const ClusterEnd(lower, left), const Duration(milliseconds: 1500))
        ..placeTop(const ClusterEnd(lower, left), const Duration(milliseconds: 4000));
      expect(placing.placingTimeOf(7, now: const Duration(milliseconds: 4500)), const Duration(milliseconds: 500));
      placing
        ..takeBack(5, const Duration(milliseconds: 5000))
        ..placeTop(const ClusterEnd(lower, right), const Duration(milliseconds: 5200))
        ..placeTop(const ClusterEnd(lower, right), const Duration(milliseconds: 6000));
      expect(placing.placingTimes, {
        6: const Duration(milliseconds: 2500),
        5: const Duration(milliseconds: 1700),
        7: const Duration(milliseconds: 1800),
      });
      expect(placing.order, [6, 5, 7]);
    });

    test('once done, its cards are asked for as in 暗記練, on the own side only', () {
      final placing = TeiichiPlacing(const TeiichiSetup(cards: 2, rows: 1), [5, 6])
        ..placeTop(const ClusterEnd(lower, left), const Duration(seconds: 1))
        ..placeTop(const ClusterEnd(lower, right), const Duration(seconds: 2))
        ..finish(const Duration(seconds: 3));
      final game = placing.recall(math.Random(1));
      expect(game.field.own.cards, [5, 6]);
      expect(game.field.opponent.cards, isEmpty);
      expect(game.prompts.toSet(), {5, 6});
      expect(game.phase, AnkirenPhase.memorise);
      expect(game.countsStrikes, isFalse);
    });
  });

  group('cards without a spot yet', () {
    Map<int, Duration> game(Map<int, int> ms) => {for (final e in ms.entries) e.key: Duration(milliseconds: e.value)};

    test('none before enough games are saved', () {
      final games = [
        for (var i = 1; i < TeiichiTuning.spotlessAfterGames; i++) game({1: 900, 2: 800, 3: 700, 4: 600}),
      ];
      expect(slowestToPlace(games), isEmpty);
    });

    test('the slowest on average over the recent games, slowest first', () {
      final old = game({9: 99000});
      final games = [
        old,
        for (var i = 0; i < TeiichiTuning.spotlessRecentGames; i++)
          game({1: 1000 + 200 * i, 2: 3000, 3: 500, 4: 4000, 5: 100, 6: 2500, 7: 2000}),
      ];
      final slow = slowestToPlace(games);
      expect([for (final s in slow) s.poemId], [4, 2, 6, 7, 1].take(TeiichiTuning.spotlessMost));
      expect(slow.first.mean, const Duration(milliseconds: 4000));
      expect(slow.any((s) => s.poemId == 9), isFalse, reason: 'older than the recent games');
    });

    test('a card counts only the games it was placed in', () {
      final games = [
        game({1: 4000, 2: 1000, 3: 1000}),
        game({2: 1000, 3: 1000}),
        game({2: 1000, 3: 2000}),
      ];
      expect([for (final s in slowestToPlace(games)) s.poemId].first, 1);
    });

    test('too few cards placed shows none', () {
      final games = [for (var i = 0; i < TeiichiTuning.spotlessAfterGames; i++) game({1: 900, 2: 800})];
      expect(slowestToPlace(games), isEmpty);
    });
  });
}
