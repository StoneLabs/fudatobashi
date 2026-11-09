// 一騎打ち's board between the reads: the player's take of the called card
// and their faults (お手つき), the 送り札 both ways (which card Tobi sends, his arm carrying it, where a
// card sent to him goes, and the player placing his on their side), the
// open middle of the player's 上段, and the board laid out afresh as the
// sides change.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/gestures.dart' show PointerDownEvent, PointerMoveEvent, PointerUpEvent;
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/field_parts.dart';
import 'package:fudatobashi/domain/ikkiuchi_board.dart';
import 'package:fudatobashi/domain/ikkiuchi_field.dart';
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_read.dart';
import 'package:fudatobashi/domain/ikkiuchi_rig.dart';
import 'package:fudatobashi/domain/ikkiuchi_send.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/ikkiuchi_strike.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_layout.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_scene.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_card_faces.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_tobi_art.dart';

import 'test_ikkiuchi.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final layout = IkkiuchiLayout.ofPoems();
  final rig = IkkiuchiTobiArt.rig();
  const step = IkkiuchiBoard.stepMs;
  const phone = Size(384, 832);
  const smallLandscape = Size(640, 360);
  const tabletLandscape = Size(1376, 1032);

  // A deal of [perSide] cards a side by [seed]: Tobi's homes at [rating],
  // the player's side by the same layout.
  IkkiuchiSides dealt(int seed, {double rating = 2000, int perSide = 25, int rows = 3}) {
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
    final own = deck.sublist(0, perSide), others = deck.sublist(perSide, 2 * perSide);
    return IkkiuchiSides.start(
      layout.generate(rating: rating, own: own, others: others, rows: rows, seed: seed),
      layout.generate(rating: rating, own: others, others: own, rows: rows, seed: seed + 1).start,
    );
  }

  IkkiuchiBoardLayout layoutOf(IkkiuchiSides sides, {bool landscape = false}) => IkkiuchiBoardLayout.of(
      size: landscape ? phone.flipped : phone,
      landscape: landscape,
      tobiRows: sides.tobi,
      playerRows: sides.player,
      rig: rig);

  group("The player's take", () {
    // Two cards of the player's on a board whose field is [field]: [a] and
    // the called card [b].
    IkkiuchiBoard boardWith(CardBox a, CardBox b, {required FieldRect field}) {
      final board = IkkiuchiBoard(
        tobi: TobiFrame(const Vec(150, 20), 1, rig),
        size: const Vec(384, 832),
        cards: [(id: 1, side: IkkiuchiSide.player, box: a), (id: 2, side: IkkiuchiSide.player, box: b)],
        cardW: 38,
        fieldArea: field,
      );
      return board..callCard(2);
    }

    // The finger down at [from], drawn to [to] over [steps] steps, then
    // lifted, and the board run on for [after] steps.
    void stroke(IkkiuchiBoard board, Vec from, Vec to, {int steps = 6, int after = 600}) {
      for (var i = 0; i <= steps; i++) {
        board
          ..touch(from.lerp(to, i / steps))
          ..advance(step);
      }
      board
        ..lift()
        ..advance(step);
      for (var i = 0; i < after; i++) {
        board.advance(step);
      }
    }

    const field = FieldRect(0, 0, 384, 400);

    test('the finger touching the called card takes it', () {
      final board = boardWith(const CardBox(Vec(80, 200), 19, 27), const CardBox(Vec(200, 200), 19, 27), field: field);
      stroke(board, const Vec(200, 260), const Vec(200, 220), after: 10);
      expect(board.take?.card, 2);
      expect(board.take?.way, IkkiuchiTakeWay.touched);
    });

    test('a card knocked wholly off the field is taken', () {
      // The finger strikes card 1 down into card 2, by the field's bottom
      // edge, and never touches card 2.
      final board = boardWith(const CardBox(Vec(200, 300), 19, 27), const CardBox(Vec(200, 360), 19, 27), field: field);
      stroke(board, const Vec(200, 250), const Vec(200, 290));
      expect(board.cards.card(2).box.overlapsArea(field.x, field.y, field.right, field.bottom), isFalse,
          reason: 'wholly off the field');
      expect(board.take?.way, IkkiuchiTakeWay.leftField);
    });

    test('a card knocked but still partly on the field is not taken', () {
      // Card 2 lies across the field's bottom edge; card 1, struck from the
      // left, knocks it along the edge.
      final board = boardWith(const CardBox(Vec(120, 395), 19, 27), const CardBox(Vec(165, 395), 19, 27), field: field);
      stroke(board, const Vec(60, 395), const Vec(95, 395), steps: 4);
      final card = board.cards.card(2);
      expect(card.movedFrom(card.home, dp: 2, radians: 0.02), isTrue, reason: 'knocked');
      expect(card.box.overlapsArea(field.x, field.y, field.right, field.bottom), isTrue, reason: 'still partly on it');
      expect(board.take, isNull);
    });

    test('a new call starts the take afresh', () {
      final board = boardWith(const CardBox(Vec(80, 200), 19, 27), const CardBox(Vec(200, 200), 19, 27), field: field);
      stroke(board, const Vec(200, 260), const Vec(200, 220), after: 10);
      expect(board.take, isNotNull);
      board.callCard(1);
      expect(board.take, isNull);
    });

    test('a card box overlaps an area by its turned outline, not its corners alone', () {
      // Turned 45° over the area's corner, no corner of it inside.
      const box = CardBox(Vec(-10, -10), 20, 20, math.pi / 4);
      expect(box.overlapsArea(0, 0, 100, 100), isTrue);
      expect(const CardBox(Vec(-30, -30), 20, 20, math.pi / 4).overlapsArea(0, 0, 100, 100), isFalse);
      expect(const CardBox(Vec(50, 120), 10, 19).overlapsArea(0, 0, 100, 100), isFalse);
      expect(const CardBox(Vec(50, 110), 10, 19).overlapsArea(0, 0, 100, 100), isTrue);
    });
  });

  group("The player's faults", () {
    // Tobi's cards 1 and 2, the player's 3, 4 and 5; card 5 lies just under
    // card 2, across the band from it.
    const field = FieldRect(0, 0, 384, 400);
    const homes = {
      1: (IkkiuchiSide.opponent, Vec(80, 100)),
      2: (IkkiuchiSide.opponent, Vec(200, 140)),
      3: (IkkiuchiSide.player, Vec(80, 300)),
      4: (IkkiuchiSide.player, Vec(300, 300)),
      5: (IkkiuchiSide.player, Vec(200, 200)),
    };
    IkkiuchiBoard board() => IkkiuchiBoard(
          tobi: TobiFrame(const Vec(150, 20), 1, rig),
          size: const Vec(384, 832),
          cards: [
            for (final MapEntry(key: id, value: (side, at)) in homes.entries)
              (id: id, side: side, box: CardBox(at, 19, 27)),
          ],
          cardW: 38,
          fieldArea: field,
        );

    // The finger down on [id]'s middle and lifted, the board run on a
    // little.
    void tap(IkkiuchiBoard board, int id) {
      board
        ..touch(board.cards.card(id).box.centre)
        ..advance(step)
        ..lift()
        ..advance(step);
      for (var i = 0; i < 10; i++) {
        board.advance(step);
      }
    }

    test('a touch on the side without the read card is a fault, until the next read', () {
      final b = board()..callCard(4);
      tap(b, 1);
      expect(b.playerFaults.keys, [1]);
      expect(b.take, isNull);
      expect(b.faults, isEmpty, reason: "the player's, not Tobi's");
      b.callCard(3);
      expect(b.playerFaults, isEmpty, reason: 'a new read starts afresh');
    });

    test("a touch on the read card's own side is not a fault", () {
      final b = board()..callCard(4);
      tap(b, 3);
      tap(b, 5);
      expect(b.playerFaults, isEmpty);
      expect(b.take, isNull);
    });

    test('on a からふだ a touch on either side is a fault, and there is nothing to take', () {
      final away = poems.all.map((p) => p.id).firstWhere((id) => !homes.containsKey(id));
      final b = board()..callCard(away, onField: false);
      expect(b.called, isNull);
      tap(b, 3);
      tap(b, 1);
      expect(b.playerFaults.keys, unorderedEquals([3, 1]), reason: 'each card touched marked');
      expect(b.take, isNull);
    });

    test('a card the finger knocks into one on the side without the read card is no fault', () {
      final b = board()..callCard(4);
      // The finger strikes card 5 up into Tobi's card 2 and stops short of
      // it.
      for (var i = 0; i <= 6; i++) {
        b
          ..touch(const Vec(200, 260).lerp(const Vec(200, 235), i / 6))
          ..advance(step);
      }
      b
        ..lift()
        ..advance(step);
      for (var i = 0; i < 600; i++) {
        b.advance(step);
      }
      final knocked = b.cards.card(2);
      expect(knocked.movedFrom(knocked.home, dp: 2, radians: 0.02), isTrue, reason: 'card 5 knocked it');
      expect(b.playerFaults, isEmpty);
    });

    test('a touch on the side without the read card after the take is still a fault (競技規程細則 第二十三条 三)', () {
      final b = board()..callCard(4);
      tap(b, 4);
      expect(b.take?.card, 4);
      tap(b, 2);
      expect(b.playerFaults.keys, [2], reason: 'after their own take');

      // Tobi takes a card of his; the player then touches one of theirs.
      final sides = dealt(3);
      final tobis = layoutOf(sides).board();
      final called = sides.tobi[0].left.first;
      tobis.call(IkkiuchiRead(called: called, onField: true, move: IkkiuchiMove.whip, reachMs: 400, correctionReachMs: 400));
      for (var i = 0; i < 2000 && !tobis.cards.card(called).taken; i++) {
        tobis.advance(step);
      }
      expect(tobis.cards.card(called).taken, isTrue, reason: 'Tobi took it');
      final late = sides.player[0].left.first;
      tap(tobis, late);
      expect(tobis.playerFaults.keys, [late], reason: "after Tobi's take");
      expect(tobis.faults, isEmpty);
    });

    test('nothing read, nothing faults', () {
      final b = board();
      tap(b, 1);
      tap(b, 3);
      expect(b.playerFaults, isEmpty);
    });
  });

  group('送り札', () {
    test('Tobi sends a card whose look-alike stays with him, at his smart-send chance', () {
      final sides = dealt(3);
      final mine = sides.tobiCards;
      bool splits(int c) => mine.any((d) => layout.alike(c, d));
      expect(mine.where(splits), isNotEmpty, reason: 'the deal has a look-alike pair on his side');
      final rng = math.Random(1);
      for (var i = 0; i < 40; i++) {
        final sent = sides.tobiSends(smart: 1, alike: layout.alike, rng: rng)!;
        expect(splits(sent), isTrue);
      }
      final any = {for (var i = 0; i < 400; i++) sides.tobiSends(smart: 0, alike: layout.alike, rng: rng)!};
      expect(any.any((c) => !splits(c)), isTrue, reason: 'at 0 any of his cards');
      expect(any.difference(mine), isEmpty);
    });

    test("a card the player sends goes to its home on Tobi's side, his groups in home order", () {
      final sides = dealt(5);
      final card = sides.player.first.left.first;
      final next = sides.toTobi(card);
      expect(next.tobiCards, contains(card));
      expect(next.tobi.expand((r) => [...r.left, ...r.right]), contains(card));
      expect(next.tobi.map((r) => [r.left, r.right]).toList(),
          sides.homes.sideWith({...sides.tobiCards, card}).map((r) => [r.left, r.right]).toList());
      expect(next.player.first.left, sides.player.first.left.skip(1).toList(), reason: 'the group closes up');
      expect(next.playerCards, isNot(contains(card)));
    });

    test("Tobi's card is placed on the player's side by the placing's rules", () {
      final sides = dealt(7);
      final card = sides.tobiCards.first;
      final away = sides.without(card);
      final lower = away.player[0];
      final atEnd = away.placed(card, const ClusterEnd(FieldRow.lower, RowPart.left))!;
      expect(atEnd.player[0].left, [...lower.left, card], reason: 'at the inner end of the group');
      expect(atEnd.tobiCards, isNot(contains(card)));
      // On the outermost card of a right group: it takes that card's place
      // at the edge, and the group moves a place in.
      final r = away.player.indexWhere((row) => row.right.isNotEmpty);
      final right = away.player[r].right;
      final onCard = away.placed(card, CardSpot(right.first))!;
      expect(onCard.player[r].right, [card, ...right]);
      expect(away.placed(card, const ClusterEnd(FieldRow.upper, RowPart.right)), isNotNull, reason: 'any row');
    });

    test('a row takes at most 16 cards', () {
      final sides = dealt(9);
      final full = IkkiuchiSides(homes: sides.homes, tobi: sides.tobiCards, player: [
        IkkiuchiRow([for (var i = 0; i < 9; i++) sides.playerCards[i]], [for (var i = 9; i < 16; i++) sides.playerCards[i]]),
        IkkiuchiRow([sides.playerCards[16]], []),
        IkkiuchiRow([sides.playerCards[17]], []),
      ]);
      final card = sides.tobiCards.first;
      expect(full.placed(card, const ClusterEnd(FieldRow.lower, RowPart.left)), isNull);
      expect(full.placed(card, CardSpot(sides.playerCards[3])), isNull);
      expect(full.placed(card, const ClusterEnd(FieldRow.middle, RowPart.right)), isNotNull);
    });

    test('in 2 rows or 1 a row takes at most 8 cards, however unevenly the rows lie', () {
      final sides = dealt(9, perSide: IkkiuchiLayoutTuning.twoRowsUpTo, rows: 2);
      final p = sides.playerCards, card = sides.tobiCards.first;
      IkkiuchiSides withRows(List<IkkiuchiRow> rows) =>
          IkkiuchiSides(homes: sides.homes, tobi: sides.tobiCards, player: rows);
      const lower = FieldRow.lower, middle = FieldRow.middle;

      final uneven = withRows([IkkiuchiRow(p.sublist(0, 5), p.sublist(5, 8)), IkkiuchiRow(p.sublist(8, 10), [p[10]])]);
      expect(uneven.placed(card, const ClusterEnd(lower, RowPart.left)), isNull);
      expect(uneven.placed(card, const ClusterEnd(lower, RowPart.right)), isNull);
      expect(uneven.placed(card, CardSpot(p[2])), isNull);
      expect(uneven.placed(card, const ClusterEnd(middle, RowPart.right)), isNotNull);
      expect(uneven.placed(p[9], const ClusterEnd(lower, RowPart.left)), isNull, reason: 'nor one of the other row');
      expect(uneven.placed(p[0], CardSpot(p[6])), isNotNull, reason: 'its own cards move about in it');

      final full = withRows([IkkiuchiRow(p.sublist(0, 5), p.sublist(5, 8)), IkkiuchiRow(p.sublist(8, 11), p.sublist(11, 16))]);
      expect(full.playerBoard.freeSpots, isEmpty);
      expect(full.autoPlaced([card]).playerCards, isNot(contains(card)), reason: 'nowhere to go');

      final one = withRows([IkkiuchiRow(p.sublist(0, 3), p.sublist(3, 8))]);
      expect(one.playerBoard.freeSpots, isEmpty);
      expect(withRows([IkkiuchiRow(p.sublist(0, 3), p.sublist(3, 7))]).placed(card, const ClusterEnd(lower, RowPart.left)),
          isNotNull);
    });

    test("Tobi's arm reaches the card, carries it turned to the waiting spot, and points at it", () {
      final sides = dealt(11);
      final l = layoutOf(sides);
      final card = l.cards.firstWhere((c) => c.side == IkkiuchiSide.opponent);
      final wait = l.wait;
      final to = CardBox(Vec(wait.center.dx, wait.center.dy), wait.width / 2, wait.height / 2);
      final carry = IkkiuchiCarry(
          tobi: l.tobi, from: card.box, to: to, cardW: l.cardW, side: ArmSide.right, endFace: TobiFace.pointing);
      expect(carry.handAtTime(carry.pickAt).distanceTo(card.box.centre), lessThan(1e-6));
      expect(carry.handAtTime(carry.setAt).distanceTo(to.centre), lessThan(1e-6));
      expect(carry.cardAt(carry.pickAt - 1), isNull, reason: 'on his side until his hand takes it');
      final mid = carry.cardAt((carry.pickAt + carry.setAt) / 2)!;
      expect(mid.centre.distanceTo(carry.handAtTime((carry.pickAt + carry.setAt) / 2)), lessThan(1e-6),
          reason: 'in his hand');
      expect(turnBetween(carry.cardAt(carry.setAt)!.angle, 0).abs(), lessThan(1e-9), reason: 'facing the player');
      final pointing = l.tobi.world(rig.arm(TobiFace.pointing, ArmSide.right).hand, TobiBody.rest);
      expect(carry.handAtTime(carry.end).distanceTo(pointing), lessThan(1e-6), reason: 'his hand ends pointing');
      expect(carry.faceAt(carry.end), TobiFace.pointing);
    });

    test('in portrait the waiting card lies right of Tobi, above his side', () {
      final l = layoutOf(dealt(13));
      final wait = l.wait;
      expect(wait.height / wait.width, closeTo(IkkiuchiField.cardH, 1e-9));
      expect(wait.right, lessThanOrEqualTo(l.size.x + 1e-9));
      expect(wait.bottom, lessThan(l.field.top), reason: 'above his side');
      expect(wait.left, greaterThanOrEqualTo(l.tobi.origin.x + rig.size.x * l.tobi.k - 1e-9), reason: 'right of him');
      expect(wait.width, greaterThan(2 * l.cardW), reason: 'big');
    });

    test("in landscape the waiting card lies big just right of Tobi, in his half with its tags", () {
      const style = IkkiuchiSendStyle.wait;
      final tags = IkkiuchiSendStyle.look.stackTagRoom + IkkiuchiSendStyle.hintRoom;
      for (final size in [smallLandscape, phone.flipped, tabletLandscape]) {
        for (var seed = 0; seed < 20; seed++) {
          final sides = dealt(seed);
          final l = IkkiuchiBoardLayout.of(
              size: size, landscape: true, tobiRows: sides.tobi, playerRows: sides.player, rig: rig);
          final wait = l.wait;
          final why = '$size seed $seed';
          final tobiRight = l.tobi.origin.x + rig.size.x * l.tobi.k;
          expect(wait.height / wait.width, closeTo(IkkiuchiField.cardH, 1e-9), reason: why);
          expect(wait.width, greaterThan(style.scale * l.cardW), reason: '$why: bigger than before');
          expect(wait.width, lessThanOrEqualTo(style.landscapeScale * l.cardW + 1e-9), reason: why);
          expect(wait.left, closeTo(tobiRight + style.gap, 1e-9), reason: '$why: just right of Tobi');
          expect(wait.top, greaterThanOrEqualTo(l.field.top), reason: "$why: in Tobi's half");
          expect(wait.bottom + tags, lessThanOrEqualTo(l.band.top + 1e-9), reason: "$why: in his half with its tags");
          expect(wait.right, lessThanOrEqualTo(l.column!.left), reason: '$why: clear of the column');
        }
      }
    });
  });

  group("The player's open middle", () {
    const row = IkkiuchiPlacingTuning.middleRow;
    const margin = IkkiuchiPlacingTuning.middleMargin;
    const pitch = IkkiuchiField.pitch;

    // [sides] with the player's rows [rows].
    IkkiuchiSides withRows(IkkiuchiSides sides, List<IkkiuchiRow> rows) =>
        IkkiuchiSides(homes: sides.homes, tobi: sides.tobiCards, player: rows);

    test("Tobi's card goes into the open middle of the player's 上段, at its place among the middle cards", () {
      final sides = dealt(7);
      final [a, b, c, d, ...] = sides.tobiCards.toList()..sort();
      final upper = sides.player[row.index];
      var next = sides.placed(a, const OpenMiddle(row, 0))!;
      expect(next.player[row.index].middle, [a]);
      expect([next.player[row.index].left, next.player[row.index].right], [upper.left, upper.right],
          reason: 'the groups stay');
      expect(next.tobiCards, isNot(contains(a)));
      next = next.placed(b, const OpenMiddle(row, 1))!;
      expect(next.player[row.index].middle, [a, b], reason: 'right of the one there');
      next = next.placed(c, CardSpot(b))!;
      expect(next.player[row.index].middle, [a, c, b], reason: "on a middle card: just left of it");
      next = next.placed(d, const OpenMiddle(row, 0))!;
      expect(next.player[row.index].middle, [d, a, c, b]);
      expect(next.playerCards, containsAll([a, b, c, d]));
      for (final other in FieldRow.values.where((r) => r != row)) {
        expect(sides.placed(a, OpenMiddle(other, 0)), isNull, reason: 'only $row has an open middle');
      }
      expect(withRows(sides, sides.player.take(2).toList()).placed(a, const OpenMiddle(row, 0)), isNull,
          reason: 'not while $row is not played');
    });

    test('middle cards keep their margin clear of the groups within the row\'s room', () {
      final sides = dealt(9);
      final p = sides.playerCards;
      // 14 cards in its groups leave room for one middle card and its
      // margins, and no more.
      final full = withRows(sides, [
        IkkiuchiRow(p.sublist(14, 18), p.sublist(18, 21)),
        IkkiuchiRow(p.sublist(21, 23), p.sublist(23, 25)),
        IkkiuchiRow(p.sublist(0, 7), p.sublist(7, 14)),
      ]);
      expect(14 + 1 + 2 * margin, lessThanOrEqualTo(IkkiuchiLayoutTuning.rowSlots));
      final [a, b, ...] = sides.tobiCards.toList()..sort();
      final one = full.placed(a, const OpenMiddle(row, 0))!;
      expect(one.placed(b, const OpenMiddle(row, 0)), isNull);
      expect(one.placed(b, CardSpot(a)), isNull);
      expect(one.placed(b, const ClusterEnd(row, RowPart.left)), isNull, reason: 'the middle card keeps its room');
      expect(full.placed(b, const ClusterEnd(row, RowPart.left)), isNotNull, reason: 'without it the groups may grow');
    });

    test('a middle card moves to a group, and a group card into the middle, as the player rearranges', () {
      final sides = withRows(dealt(5), withMiddle(dealt(5).player, 2));
      final [m, n] = sides.player[row.index].middle;
      final lower = sides.player[0];
      final out = sides.placed(m, const ClusterEnd(FieldRow.lower, RowPart.left))!;
      expect(out.player[row.index].middle, [n], reason: 'the open middle closes up');
      expect(out.player[0].left, [...lower.left, m]);
      final g = lower.left.first;
      final into = sides.placed(g, const OpenMiddle(row, 1))!;
      expect(into.player[row.index].middle, [m, g, n]);
      expect(into.player[0].left, lower.left.skip(1).toList());
      expect(into.playerCards.toSet(), sides.playerCards.toSet(), reason: 'the same cards');
    });

    test("a middle card sent to Tobi goes to its home on his side, the open middle closing up", () {
      final sides = withRows(dealt(5), withMiddle(dealt(5).player, 2));
      final [m, n] = sides.player[row.index].middle;
      final next = sides.toTobi(m);
      expect(next.tobiCards, contains(m));
      expect(next.tobi.map((r) => [r.left, r.right]).toList(),
          sides.homes.sideWith({...sides.tobiCards, m}).map((r) => [r.left, r.right]).toList());
      expect(next.tobi.every((r) => r.middle.isEmpty), isTrue, reason: 'his open middles stay empty');
      expect(next.player[row.index].middle, [n]);
      expect(next.playerCards, isNot(contains(m)));
    });

    test('a row is as wide as its middle cards need, and they spread evenly, each a margin clear of the groups', () {
      expect(IkkiuchiField.rowWidth(6, 5), closeTo(IkkiuchiField.reach(6) + IkkiuchiField.reach(5) + IkkiuchiField.leastGap, 1e-9));
      for (final m in [1, 2, 3]) {
        expect(IkkiuchiField.rowWidth(6, 5, middle: m), closeTo((6 + 5 + m + 2 * margin) * pitch - IkkiuchiFieldTuning.cardGap, 1e-9));
        expect(IkkiuchiField.rowWidth(6, 5, middle: m), greaterThan(IkkiuchiField.rowWidth(6, 5, middle: m - 1)));
      }
      final ids = [for (var i = 0; i < 14; i++) i];
      final player = [
        IkkiuchiRow(ids.sublist(0, 2), ids.sublist(2, 3)),
        const IkkiuchiRow([], []),
        IkkiuchiRow(ids.sublist(3, 9), ids.sublist(9, 11), middle: ids.sublist(11, 14)),
      ];
      final tobi = [IkkiuchiRow([20, 21], [22]), IkkiuchiRow([23], []), const IkkiuchiRow([24], [25])];
      final field = IkkiuchiField(tobi: tobi, player: player);
      final least = field.leastWidth();
      expect(least, closeTo(IkkiuchiField.rowWidth(6, 2, middle: 3), 1e-9), reason: 'its widest row');
      for (final width in [least, least + 2.5]) {
        final boxes = {
          for (final c in field.layOut(width, gap: 1))
            if (c.side == IkkiuchiSide.player) c.id: c.box,
        };
        double leftOf(int id) => boxes[id]!.centre.x - 0.5;
        double rightOf(int id) => boxes[id]!.centre.x + 0.5;
        final middle = player[2].middle;
        expect(leftOf(middle.first) - rightOf(player[2].left.last), greaterThanOrEqualTo(margin * pitch - 1e-9),
            reason: '$width: clear of the left group');
        expect(leftOf(player[2].right.last) - rightOf(middle.last), greaterThanOrEqualTo(margin * pitch - 1e-9),
            reason: '$width: clear of the right group');
        final steps = [for (var i = 1; i < middle.length; i++) boxes[middle[i]]!.centre.x - boxes[middle[i - 1]]!.centre.x];
        expect(steps, everyElement(closeTo(steps.first, 1e-9)), reason: '$width: evenly');
        expect(steps.first, greaterThan(1), reason: '$width: apart');
        expect(rightOf(player[2].right.first), closeTo(width, 1e-9), reason: '$width: the groups at the edges');
        expect(boxes[middle.first]!.centre.y, boxes[player[2].left.first]!.centre.y, reason: 'in the row');
      }
      // The open middle reaches over the middle cards, the one moved left
      // out; with none, it is a card wide, or the room between the groups
      // where that is less.
      final boxes = {for (final c in field.layOut(least, gap: 1)) c.id: c.box};
      final open = field.playerMiddle(2, width: least, gap: 1)!;
      expect(open.centre.x - open.hw, closeTo(boxes[11]!.centre.x - 0.5, 1e-9));
      expect(open.centre.x + open.hw, closeTo(boxes[13]!.centre.x + 0.5, 1e-9));
      expect(open.centre.y, closeTo(boxes[11]!.centre.y, 1e-9));
      final moving = field.playerMiddle(2, leaving: 13, width: least, gap: 1)!;
      expect(moving.centre.x + moving.hw, lessThan(boxes[13]!.centre.x + 0.5));
      final empty = IkkiuchiField(tobi: tobi, player: [player[0], player[1], IkkiuchiRow(ids.sublist(3, 9), ids.sublist(9, 11))]);
      expect(empty.playerMiddle(2, width: 16, gap: 1)!.hw,
          closeTo((16 - 8 * pitch) * IkkiuchiPlacingTuning.openMiddleShare / 2, 1e-9),
          reason: 'its share of the room');
      expect(empty.playerMiddle(2, width: 8 * pitch + 2.5, gap: 1)!.hw, closeTo(0.5, 1e-9), reason: 'a card wide');
      final tight = empty.playerMiddle(2, width: IkkiuchiField.rowWidth(6, 2), gap: 1)!;
      expect(2 * tight.hw, closeTo(IkkiuchiField.leastGap, 1e-9), reason: 'the room between the groups');
      expect(tight.centre.x - tight.hw, closeTo(IkkiuchiField.reach(6), 1e-9));
    });
  });

  group('The board laid out afresh', () {
    // A scene of [sides] on the phone, run in whole frames.
    IkkiuchiBoardScene sceneOf(IkkiuchiSides sides, {bool landscape = false}) =>
        IkkiuchiBoardScene(layoutOf(sides, landscape: landscape), IkkiuchiCardFaces(showNumber: false),
            sides: sides, tobiRating: 2000, seed: 1);

    void runFor(IkkiuchiBoardScene scene, Duration time) {
      const frame = 16.0;
      for (var t = 0.0; t < time.inMilliseconds; t += frame) {
        scene.advance(frame);
      }
    }

    // Where the finger goes for the card [flow] drags to ride with its
    // middle at [to].
    Offset fingerFor(IkkiuchiSendFlow flow, Offset to) => to - flow.spots.liftedRect(Offset.zero).center;

    // Every card at rest exactly on its home in the scene's layout.
    void expectHome(IkkiuchiBoardScene scene, String why) {
      expect(scene.board.cards.gliding, isFalse, reason: why);
      final homes = {for (final c in scene.layout.cards) c.id: c.box};
      expect(scene.board.cards.cards.map((c) => c.id).toSet(), homes.keys.toSet(), reason: why);
      for (final c in scene.board.cards.cards) {
        final home = homes[c.id]!;
        expect(c.box.centre.distanceTo(home.centre), lessThan(1e-3), reason: '$why: card ${c.id}');
        expect(c.box.hw, closeTo(home.hw, 1e-9), reason: '$why: card ${c.id} at its new size');
        expect(turnBetween(c.box.angle, home.angle).abs(), lessThan(1e-6), reason: '$why: card ${c.id}');
      }
    }

    test("a send that widens a row past the fit shrinks the cards, and every card ends on its new spot", () {
      // A player's card whose home is in Tobi's widest row, so his side
      // needs more room once it is there.
      ({IkkiuchiSides sides, int card})? found;
      for (var seed = 0; found == null && seed < 40; seed++) {
        final sides = dealt(seed);
        final before = layoutOf(sides).cardW;
        for (final card in sides.playerCards) {
          if (layoutOf(sides.toTobi(card)).cardW < before - 1e-6) {
            found = (sides: sides, card: card);
            break;
          }
        }
      }
      expect(found, isNotNull);
      final (sides: sides, card: card) = found!;
      final scene = sceneOf(sides);
      final before = scene.layout.cardW;
      final box = scene.board.cards.card(card).box;
      final flow = scene.send..startSending();
      expect(flow.stage, IkkiuchiSendStage.sending);
      final from = Offset(box.centre.x, box.centre.y);
      flow
        ..dragStart(card, fromStack: false, at: from)
        ..dragTo(fingerFor(flow, flow.tobiSide.center));
      expect(flow.overTobi, isTrue);
      var settled = 0;
      scene.onSettled = () => settled++;
      flow.dragEnd();
      expect(flow.stage, IkkiuchiSendStage.placing, reason: "Tobi's arm lays it down");
      final dropped = flow.dropped!;
      expect(scene.layout.cardW, lessThan(before), reason: 'the cards shrink');
      expect(scene.board.cards.card(card).side, IkkiuchiSide.opponent);
      expect(scene.board.cards.card(card).held, isTrue, reason: 'it lies where it was let go, off the field');
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide + const Duration(milliseconds: 50));
      final carry = scene.board.carry!;
      expect(carry.from.centre.distanceTo(dropped.centre), lessThan(1e-9), reason: 'his hand takes it where it lies');
      expect(carry.to.centre.distanceTo(scene.board.cards.card(card).home.centre), lessThan(1e-9),
          reason: 'and lays it at its home');
      runFor(scene, Duration(milliseconds: ((carry.pickAt + carry.setAt) / 2).round()));
      expect(scene.board.carried?.box.centre.distanceTo(scene.board.cards.card(card).home.centre), greaterThan(1),
          reason: 'on its way in his hand');
      runFor(scene, Duration(milliseconds: carry.end.ceil()));
      expect(flow.active, isFalse);
      runFor(scene, const Duration(milliseconds: 50));
      expectHome(scene, 'after the send');
      expect(settled, 1, reason: 'the board told it is at rest');
      expect(scene.band, scene.layout.band, reason: 'the band moved along');
    });

    test('nothing faults while a card is sent or waits, or while the player arranges their cards', () {
      final cases = <String, void Function(IkkiuchiBoardScene scene)>{
        'reading': (scene) {},
        'sending': (scene) => scene.send.startSending(),
        'waiting': (scene) {
          scene.send.startReceiving();
          for (var i = 0; i < 400 && scene.send.stage != IkkiuchiSendStage.waiting; i++) {
            scene.advance(16);
          }
          expect(scene.send.stage, IkkiuchiSendStage.waiting);
        },
        'arranging': (scene) => scene.arrange.start(),
      };
      for (final MapEntry(key: why, value: start) in cases.entries) {
        final sides = dealt(5);
        final scene = sceneOf(sides);
        final read = sides.playerCards.first;
        scene.callCard(read, poems[read].kimariji);
        // The finger is down in the band as it starts, then goes onto a
        // card of Tobi's, which a touch while reading faults on.
        final band = scene.layout.band.center;
        scene.pointer(PointerDownEvent(pointer: 1, position: band));
        scene.advance(16);
        start(scene);
        final tobis = scene.board.cards.cards.firstWhere((c) => c.side == IkkiuchiSide.opponent && !c.held);
        scene.pointer(PointerMoveEvent(pointer: 1, position: Offset(tobis.box.centre.x, tobis.box.centre.y)));
        for (var i = 0; i < 5; i++) {
          scene.advance(16);
        }
        expect(scene.board.playerFaults, why == 'reading' ? isNotEmpty : isEmpty, reason: why);
      }
    });

    test('a card let go off his side glides back to its place', () {
      final sides = dealt(2);
      final scene = sceneOf(sides);
      final card = sides.player[1].right.first;
      final home = scene.board.cards.card(card).home;
      final flow = scene.send..startSending();
      flow
        ..dragStart(card, fromStack: false, at: Offset(home.centre.x, home.centre.y))
        ..dragTo(Offset(home.centre.x - 30, home.centre.y + 10));
      expect(flow.overTobi, isFalse);
      expect(scene.board.cards.card(card).held, isTrue, reason: 'off the board while dragged');
      flow.dragEnd();
      expect(flow.stage, IkkiuchiSendStage.sending, reason: 'still to send one');
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      expectHome(scene, 'back home');
      expect(scene.sides, same(sides));
    });

    test("a card let go anywhere on Tobi's side goes to him, and anywhere off it glides back", () {
      final sides = dealt(2);
      final card = sides.player[1].right.first;
      for (final landscape in [false, true]) {
        final o = landscape ? 'landscape' : 'portrait';
        // A scene where the player drags [card] to ride with its middle at
        // [at] on Tobi's side, then lets go.
        IkkiuchiBoardScene letGo(Offset Function(Rect side) at, String why) {
          final scene = sceneOf(sides, landscape: landscape);
          final flow = scene.send..startSending();
          final home = scene.board.cards.card(card).home;
          flow
            ..dragStart(card, fromStack: false, at: Offset(home.centre.x, home.centre.y))
            ..dragTo(fingerFor(flow, at(flow.tobiSide)));
          expect(flow.overTobi, flow.tobiSide.contains(at(flow.tobiSide)), reason: '$o: $why');
          flow.dragEnd();
          return scene;
        }

        const by = 2.0;
        final inside = <String, Offset Function(Rect)>{
          'top left': (r) => r.topLeft + const Offset(by, by),
          'top right': (r) => r.topRight + const Offset(-by, by),
          'bottom left': (r) => r.bottomLeft + const Offset(by, -by),
          'bottom right': (r) => r.bottomRight + const Offset(-by, -by),
          'middle': (r) => r.center,
        };
        for (final MapEntry(key: why, value: at) in inside.entries) {
          final scene = letGo(at, why);
          expect(scene.sides!.tobiCards, contains(card), reason: '$o: let go at his side\'s $why');
          expect(scene.send.stage, IkkiuchiSendStage.placing, reason: '$o: $why');
        }
        final outside = <String, Offset Function(Rect)>{
          'left of it': (r) => r.centerLeft - const Offset(by, 0),
          'right of it': (r) => r.centerRight + const Offset(by, 0),
          'above it': (r) => r.topCenter - const Offset(0, by),
          'below it': (r) => r.bottomCenter + const Offset(0, by),
        };
        for (final MapEntry(key: why, value: at) in outside.entries) {
          final scene = letGo(at, why);
          expect(scene.sides, same(sides), reason: '$o: let go $why');
          expect(scene.send.stage, IkkiuchiSendStage.sending, reason: '$o: still to send one');
          runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
          expectHome(scene, '$o: back home from $why');
        }
      }
    });

    test("Tobi's arm sets his card down as the big waiting card, and it waits there without a jump", () {
      for (final landscape in [false, true]) {
        final o = landscape ? 'landscape' : 'portrait';
        final scene = sceneOf(dealt(4), landscape: landscape);
        final flow = scene.send;
        expect(flow.startReceiving(), isTrue);
        final carry = scene.board.carry!;
        final wait = scene.wait;
        expect(wait.width, greaterThanOrEqualTo(IkkiuchiSendStyle.wait.scale * scene.layout.cardW - 1e-6), reason: '$o: big');
        final set = carry.cardAt(carry.setAt)!;
        expect(Offset(set.centre.x, set.centre.y), offsetMoreOrLessEquals(wait.center, epsilon: 1e-6), reason: o);
        expect(2 * set.hw, closeTo(wait.width, 1e-6), reason: '$o: grown to its size');
        expect(2 * set.hh, closeTo(wait.height, 1e-6), reason: '$o: grown to its size');
        final picked = carry.cardAt(carry.pickAt)!;
        expect(2 * picked.hw, closeTo(scene.layout.cardW, 1e-6), reason: '$o: a field card as he takes it');
        const frame = 16.0;
        while (flow.stage == IkkiuchiSendStage.carrying) {
          scene.advance(frame);
        }
        expect(flow.stage, IkkiuchiSendStage.waiting, reason: o);
        expect(scene.wait, rectMoreOrLessEquals(wait, epsilon: 1e-6), reason: '$o: where his hand set it');
        runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
        expect(scene.wait, scene.layout.wait, reason: '$o: glided to its place as his side closed up');
      }
    });

    test("Tobi's card is carried, waits, and is placed by a tap on a spot, the board laid out for it", () {
      for (final landscape in [false, true]) {
        final why = landscape ? 'landscape' : 'portrait';
        final sides = dealt(4);
        final scene = sceneOf(sides, landscape: landscape);
        final flow = scene.send;
        expect(flow.startReceiving(), isTrue);
        final card = flow.card!;
        expect(sides.tobiCards, contains(card));
        expect(flow.stage, IkkiuchiSendStage.carrying);
        final carry = scene.board.carry!;
        runFor(scene, Duration(milliseconds: (carry.pickAt + step * 4).ceil()));
        expect(scene.board.cards.card(card).held, isTrue, reason: '$why: in his hand');
        runFor(scene, Duration(milliseconds: (carry.end - carry.pickAt).ceil()));
        expect(flow.stage, IkkiuchiSendStage.waiting, reason: why);
        expect(scene.board.idleFace, TobiFace.pointing, reason: '$why: he points at it');
        expect(scene.sides!.tobiCards, isNot(contains(card)), reason: '$why: off his side');
        runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
        expectHome(scene, '$why: his side closed up');

        final targets = flow.targets();
        final (spot, rect) = targets.freeSpots.firstWhere((s) => s.$1 == const ClusterEnd(FieldRow.middle, RowPart.right));
        flow.tap(Offset(rect.x + rect.w / 2, rect.y + rect.h / 2));
        expect(flow.active, isFalse, reason: '$why: placing it ends the send');
        expect(scene.sides!.player[1].right.last, card, reason: '$why: at the inner end of the middle row\'s right group');
        expect(spot, const ClusterEnd(FieldRow.middle, RowPart.right));
        expect(scene.board.idleFace, TobiFace.standard, reason: why);
        runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
        expectHome(scene, '$why: placed');
        final placed = scene.board.cards.card(card);
        expect(placed.side, IkkiuchiSide.player);
        expect(placed.box.centre.distanceTo(scene.layout.cards.firstWhere((c) => c.id == card).box.centre), lessThan(1e-3));
      }
    });

    test("Tobi's card sent to a full side goes on past a row's room, never waiting with nowhere to go", () {
      for (final landscape in [false, true]) {
        final why = landscape ? 'landscape' : 'portrait';
        // A 1-row match: the player's 8 fill their row.
        final sides = dealt(4, perSide: IkkiuchiLayoutTuning.oneRowUpTo, rows: 1);
        expect(sides.playerBoard.freeSpots, isEmpty, reason: '$why: full');
        final scene = sceneOf(sides, landscape: landscape);
        final flow = scene.send;
        final sent = <int>[];
        flow.onSent = sent.add;
        expect(flow.startReceiving(), isTrue);
        final card = flow.card!;
        runFor(scene, Duration(milliseconds: scene.board.carry!.end.ceil() + 50));
        expect(flow.active, isFalse, reason: '$why: it does not wait');
        expect(sent, [card]);
        final row = scene.sides!.player.single;
        expect(row.left.last, card, reason: '$why: at the inner end of the left group');
        expect(row.length, IkkiuchiLayout.rowRoom(1) + 1, reason: '$why: past the row\'s room');
        expect(scene.sides!.tobiCards, isNot(contains(card)));
        runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
        expectHome(scene, '$why: laid out for it');
      }
    });

    test("dropped on a card, Tobi's card takes its place and the cards inward move a place in", () {
      final sides = dealt(6);
      final scene = sceneOf(sides);
      final flow = scene.send..startReceiving();
      runFor(scene, Duration(milliseconds: scene.board.carry!.end.ceil() + 100));
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      final card = flow.card!;
      final row = scene.sides!.player[0].left;
      final target = row.first;
      final box = scene.board.cards.card(target).box;
      final wait = scene.wait;
      flow.dragStart(card, fromStack: true, at: wait.center);
      expect(flow.drag?.spot, isNull);
      // The lifted card rides above the finger: the finger goes under the
      // target card's spot.
      flow.dragTo(Offset(box.centre.x, box.centre.y));
      expect(flow.drag?.spot, CardSpot(target));
      expect((flow.rectOf(CardSpot(target))!.center - Offset(box.centre.x, box.centre.y)).distance, lessThan(1e-3));
      flow.dragEnd();
      expect(scene.sides!.player[0].left, [card, ...row]);
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      expectHome(scene, 'placed on a card');
    });

    const middleRow = IkkiuchiPlacingTuning.middleRow;

    // The sides of deal [seed] with [n] of the player's cards in their open
    // middle.
    IkkiuchiSides dealtWithMiddle(int seed, int n) {
      final sides = dealt(seed);
      return IkkiuchiSides(homes: sides.homes, tobi: sides.tobiCards, player: withMiddle(sides.player, n));
    }

    // Tobi sends a card and it waits to be placed, the board at rest.
    void receive(IkkiuchiBoardScene scene) {
      expect(scene.send.startReceiving(), isTrue);
      runFor(scene, Duration(milliseconds: scene.board.carry!.end.ceil() + 100));
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      expect(scene.send.stage, IkkiuchiSendStage.waiting);
    }

    Offset centreOf(FieldRect r) => Offset(r.x + r.w / 2, r.y + r.h / 2);

    test("Tobi's card goes into the open middle by a tap, the next by a drag beside it, each where its landing shows",
        () {
      for (final landscape in [false, true]) {
        final why = landscape ? 'landscape' : 'portrait';
        final scene = sceneOf(dealt(4), landscape: landscape);
        final flow = scene.send;
        receive(scene);
        final first = flow.card!;
        final (spot, rect) = flow.targets().freeSpots.firstWhere((s) => s.$1 is OpenMiddle);
        expect(spot, const OpenMiddle(middleRow, 0), reason: why);
        final upper = scene.sides!.player[middleRow.index];
        final inner = [upper.left.last, upper.right.last].map((id) => scene.board.cards.card(id).box).toList();
        expect(rect.x, greaterThanOrEqualTo(inner[0].centre.x + inner[0].hw - 1e-3), reason: '$why: right of the left group');
        expect(rect.right, lessThanOrEqualTo(inner[1].centre.x - inner[1].hw + 1e-3), reason: '$why: left of the right group');
        expect(rect.y + rect.h / 2, closeTo(inner[0].centre.y, 1e-3), reason: '$why: in the row');
        expect(flow.placeOf(spot), (row: middleRow, part: RowPart.middle));
        final shown = flow.rectOf(spot)!;
        flow.tap(centreOf(rect));
        expect(flow.active, isFalse, reason: '$why: placed');
        expect(scene.sides!.player[middleRow.index].middle, [first], reason: why);
        runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
        expectHome(scene, '$why: placed in the middle');
        final firstBox = scene.board.cards.card(first).box;
        expect((shown.center - Offset(firstBox.centre.x, firstBox.centre.y)).distance, lessThan(1e-3),
            reason: '$why: where its landing showed');

        receive(scene);
        final second = flow.card!;
        final middle = scene.board.cards.card(first).box;
        final (_, open) = flow.targets().freeSpots.firstWhere((s) => s.$1 is OpenMiddle);
        final right = middle.centre.x + middle.hw;
        expect(open.right, greaterThan(right + 1), reason: '$why: the open middle reaches past the middle card');
        flow
          ..dragStart(second, fromStack: true, at: scene.wait.center)
          ..dragTo(Offset((right + open.right) / 2, middle.centre.y));
        expect(flow.drag?.spot, const OpenMiddle(middleRow, 1), reason: '$why: right of the middle card');
        final landing = flow.rectOf(flow.drag!.spot!)!;
        final cardW = scene.layout.cardW;
        flow.dragEnd();
        expect(scene.sides!.player[middleRow.index].middle, [first, second], reason: why);
        runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
        expectHome(scene, '$why: the second in the middle');
        expect(scene.layout.cardW, closeTo(cardW, 1e-9), reason: '$why: the field had room');
        final secondBox = scene.board.cards.card(second).box;
        expect((landing.center - Offset(secondBox.centre.x, secondBox.centre.y)).distance, lessThan(1e-3),
            reason: '$why: where its landing showed');
      }
    });

    test('並べ替え moves a middle card to a group end, and a group card into the middle beside another', () {
      final scene = sceneOf(dealtWithMiddle(6, 2));
      final flow = scene.arrange..start();
      final [m, n] = scene.sides!.player[middleRow.index].middle;
      final box = scene.board.cards.card(m).box;
      flow.dragStart(m, fromStack: false, at: Offset(box.centre.x, box.centre.y));
      final (end, endRect) = flow.targets().freeSpots.firstWhere((s) => s.$1 is ClusterEnd && (s.$1 as ClusterEnd).row != middleRow);
      flow.dragTo(centreOf(endRect));
      expect(flow.drag?.spot, end);
      flow.dragEnd();
      final to = end as ClusterEnd;
      expect(scene.sides!.player[middleRow.index].middle, [n], reason: 'the open middle closes up');
      final group = scene.sides!.player[to.row.index];
      expect(to.part == RowPart.left ? group.left.last : group.right.last, m, reason: 'at the inner end');
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      expectHome(scene, 'a middle card moved out');

      final g = scene.sides!.player[1].left.last;
      final from = scene.board.cards.card(g).box;
      final left = scene.board.cards.card(n).box;
      flow.dragStart(g, fromStack: false, at: Offset(from.centre.x, from.centre.y));
      final (_, open) = flow.targets().freeSpots.firstWhere((s) => s.$1 is OpenMiddle);
      final edge = left.centre.x + left.hw;
      expect(open.right, greaterThan(edge + 1));
      flow.dragTo(Offset((edge + open.right) / 2, left.centre.y));
      expect(flow.drag?.spot, const OpenMiddle(middleRow, 1));
      final landing = flow.spots.rectOf(flow.drag!.spot!, moving: g)!;
      final cardW = scene.layout.cardW;
      flow.dragEnd();
      expect(scene.sides!.player[middleRow.index].middle, [n, g]);
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      expectHome(scene, 'a group card moved into the middle');
      expect(scene.layout.cardW, closeTo(cardW, 1e-9), reason: 'the field had room');
      final placed = scene.board.cards.card(g).box;
      expect((landing.center - Offset(placed.centre.x, placed.centre.y)).distance, lessThan(1e-3),
          reason: 'where its landing showed');
      flow.finish();
      expect(flow.active, isFalse);
    });

    test('a card put in a tight open middle widens its row, the cards shrinking, until the row is full', () {
      // The player's 上段 is their widest row, the field as narrow as it,
      // its groups as near as they may be.
      final sides = dealt(10);
      final p = sides.playerCards;
      final scene = sceneOf(IkkiuchiSides(homes: sides.homes, tobi: sides.tobiCards, player: [
        IkkiuchiRow(p.sublist(14, 20), p.sublist(20, 22)),
        IkkiuchiRow(p.sublist(22, 24), p.sublist(24, 25)),
        IkkiuchiRow(p.sublist(0, 7), p.sublist(7, 14)),
      ]));
      final before = scene.layout.cardW;
      expect(scene.layout.field.width, closeTo(IkkiuchiField.rowWidth(7, 7) * before, 1e-6), reason: 'as narrow as the 上段');
      receive(scene);
      final card = scene.send.card!;
      final (spot, open) = scene.send.targets().freeSpots.firstWhere((s) => s.$1 is OpenMiddle);
      expect(open.w, closeTo(IkkiuchiField.leastGap * before, 1e-6), reason: 'the room between the groups');
      scene.send.tap(centreOf(open));
      expect(scene.sides!.player[middleRow.index].middle, [card]);
      expect(scene.layout.cardW, lessThan(before), reason: 'the cards shrink');
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide ~/ 2);
      expect(scene.board.cards.gliding, isTrue, reason: 'on their way');
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      expectHome(scene, 'the row widened');

      // 14 cards in its groups and one in the middle fill the row's room.
      receive(scene);
      final next = scene.send.card!;
      expect(scene.send.targets().freeSpots.where((s) => s.$1 is OpenMiddle), isEmpty, reason: 'the row is full');
      expect(scene.sides!.placed(next, CardSpot(card)), isNull);
      expect(spot, const OpenMiddle(middleRow, 0));
    });

    test('a middle card is taken by the finger, and once knocked glides home', () {
      final scene = sceneOf(dealtWithMiddle(3, 1));
      final m = scene.sides!.player[middleRow.index].middle.single;
      scene.callCard(m, '');
      final home = scene.board.cards.card(m).box;
      final at = Offset(home.centre.x, home.centre.y);
      scene.pointer(PointerDownEvent(pointer: 1, position: at));
      runFor(scene, const Duration(milliseconds: 32));
      expect(scene.board.take?.card, m);
      expect(scene.board.take?.way, IkkiuchiTakeWay.touched);
      for (var i = 1; i <= 4; i++) {
        scene.pointer(PointerMoveEvent(pointer: 1, position: at + Offset(i * home.hw, 0)));
        runFor(scene, const Duration(milliseconds: 16));
      }
      scene.pointer(PointerUpEvent(pointer: 1, position: at + Offset(4 * home.hw, 0)));
      runFor(scene, const Duration(milliseconds: 200));
      expect(scene.board.cards.card(m).movedFrom(home, dp: 2, radians: 0.02), isTrue, reason: 'knocked');
      runFor(scene, IkkiuchiPlayTuning.tidyWait + IkkiuchiPlayTuning.tidyGlide * 2);
      expectHome(scene, 'glided home');
    });

    test("a middle card the player sends goes to Tobi, the open middle closing up", () {
      final scene = sceneOf(dealtWithMiddle(2, 2));
      final [m, n] = scene.sides!.player[middleRow.index].middle;
      final box = scene.board.cards.card(m).box;
      final flow = scene.send..startSending();
      final from = Offset(box.centre.x, box.centre.y);
      flow
        ..dragStart(m, fromStack: false, at: from)
        ..dragTo(fingerFor(flow, flow.tobiSide.center));
      expect(flow.overTobi, isTrue);
      flow.dragEnd();
      expect(scene.sides!.tobiCards, contains(m));
      expect(scene.sides!.player[middleRow.index].middle, [n]);
      expect(scene.board.cards.card(m).side, IkkiuchiSide.opponent);
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide * 2);
      expectHome(scene, 'sent from the middle');
    });
  });
}
