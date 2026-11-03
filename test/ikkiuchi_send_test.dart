// 一騎打ち's board between the reads: the player's take of the called card,
// the 送り札 both ways (which card Tobi sends, his arm carrying it, where a
// card sent to him goes, and the player placing his on their side), and
// the board laid out afresh as the sides change.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/field_parts.dart';
import 'package:fudatobashi/domain/ikkiuchi_board.dart';
import 'package:fudatobashi/domain/ikkiuchi_cards.dart';
import 'package:fudatobashi/domain/ikkiuchi_field.dart';
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_rig.dart';
import 'package:fudatobashi/domain/ikkiuchi_send.dart';
import 'package:fudatobashi/domain/ikkiuchi_strike.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_layout.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_scene.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_card_faces.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_tobi_art.dart';

import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final layout = IkkiuchiLayout.ofPoems();
  final rig = IkkiuchiTobiArt.rig();
  const step = IkkiuchiBoard.stepMs;
  const phone = Size(384, 832);

  // A deal of [perSide] cards a side by [seed]: Tobi's homes at [rating],
  // the player's side by the same layout.
  IkkiuchiSides dealt(int seed, {double rating = 2000, int perSide = 25}) {
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
    final own = deck.sublist(0, perSide), others = deck.sublist(perSide, 2 * perSide);
    return IkkiuchiSides.start(
      layout.generate(rating: rating, own: own, others: others, rows: 3, seed: seed),
      layout.generate(rating: rating, own: others, others: own, rows: 3, seed: seed + 1).start,
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

    test("Tobi's arm reaches the card, carries it turned to the waiting spot, and points at it", () {
      final sides = dealt(11);
      final l = layoutOf(sides);
      final card = l.cards.firstWhere((c) => c.side == IkkiuchiSide.tobi);
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

    test('the waiting spot lies clear of the field, right of Tobi in portrait and beside the side in landscape', () {
      for (final landscape in [false, true]) {
        final l = layoutOf(dealt(13), landscape: landscape);
        final wait = l.wait;
        expect(wait.height / wait.width, closeTo(IkkiuchiField.cardH, 1e-9));
        expect(wait.right, lessThanOrEqualTo(l.size.x + 1e-9));
        if (landscape) {
          expect(wait.left, greaterThanOrEqualTo(l.field.right - 1e-9), reason: 'in the margin');
          expect(wait.top, greaterThanOrEqualTo(l.band.bottom), reason: "beside the player's side");
        } else {
          expect(wait.bottom, lessThan(l.field.top), reason: 'above his side');
          expect(wait.left, greaterThanOrEqualTo(l.tobi.origin.x + rig.size.x * l.tobi.k - 1e-9), reason: 'right of him');
        }
      }
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
        ..dragTo(Offset(from.dx, scene.layout.field.top + scene.layout.cardW));
      expect(flow.overTobi, isTrue);
      var settled = 0;
      scene.onSettled = () => settled++;
      flow.dragEnd();
      expect(flow.active, isFalse);
      expect(scene.layout.cardW, lessThan(before), reason: 'the cards shrink');
      expect(scene.board.cards.card(card).side, IkkiuchiSide.tobi);
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide ~/ 2);
      expect(scene.board.cards.gliding, isTrue);
      final halfway = scene.board.cards.card(card).box;
      expect(halfway.centre.distanceTo(scene.board.cards.card(card).home.centre), greaterThan(1),
          reason: 'on its way, not jumped');
      runFor(scene, IkkiuchiPlayTuning.relayoutGlide);
      expectHome(scene, 'after the send');
      expect(settled, 1, reason: 'the board told it is at rest');
      expect(scene.band, scene.layout.band, reason: 'the band moved along');
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
  });
}
