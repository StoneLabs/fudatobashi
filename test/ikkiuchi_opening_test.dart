// 一騎打ち's opening (IkkiuchiOpeningFlow, run by IkkiuchiMatchFlow): the
// player places their cards from a stack while Tobi lays out his side with
// his arm and the memory time runs; 完了 once every card is placed; the rest
// placed by the game when the time runs out; 覚えた any time after 完了, Tobi
// laying down the rest of his side at once; Tobi squeezed into a short
// memory time; the memory time used, from the placing to the first read;
// and 並べ替え after 完了 until play begins. The board of a match of 1, 2
// or 3 rows keeps its rows and its cards' size to the end.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/gestures.dart' show PointerDownEvent, PointerUpEvent;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ikkiuchi_call.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_opening.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_send.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_layout.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_scene.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_card_faces.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_player_spots.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_tobi_art.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_vector_art.dart';

class _Quiet extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}

  @override
  Future<void> stopKimarijiVoice() async {}
}

void main() {
  loadTestVectorArt();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final layout = IkkiuchiLayout.ofPoems();
  final rig = IkkiuchiTobiArt.rig();
  const phone = Size(832, 384);
  final real = sounds;
  setUp(() => sounds = _Quiet());
  tearDown(() => sounds = real);

  // A match's opening dealt by [seed], [perSide] cards a side in [rows]
  // rows and Tobi at [rating], on the phone in landscape or held upright,
  // as the match screen deals it.
  IkkiuchiBoardScene dealt(int seed, {double rating = 2000, int perSide = 25, int rows = 3, bool landscape = true}) {
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
    final own = deck.sublist(0, perSide), others = deck.sublist(perSide, 2 * perSide);
    final homes = layout.generate(rating: rating, own: own, others: others, rows: rows, seed: seed);
    final sides = IkkiuchiSides.start(homes, [for (var r = 0; r < rows; r++) const IkkiuchiRow([], [])]);
    final board = IkkiuchiBoardLayout.of(
        size: landscape ? phone : phone.flipped,
        landscape: landscape,
        tobiRows: sides.tobi,
        playerRows: sides.player,
        rig: rig,
        opening: true);
    return IkkiuchiBoardScene(board, IkkiuchiCardFaces(showNumber: false),
        sides: sides, stack: others, tobiRating: rating, seed: seed);
  }

  const words = IkkiuchiMatchWords(call: _call);

  IkkiuchiMatchFlow match(int seed,
          {double rating = 2000, int perSide = 25, int rows = 3, Duration? memorise, bool landscape = true}) =>
      IkkiuchiMatchFlow(dealt(seed, rating: rating, perSide: perSide, rows: rows, landscape: landscape),
          words: words, rating: rating, memorise: memorise ?? IkkiuchiMatchTuning.memorise);

  const frame = 16.0;
  void run(IkkiuchiMatchFlow flow, double ms) {
    for (var t = 0.0; t < ms; t += frame) {
      flow.advance(frame);
    }
  }

  void runUntil(IkkiuchiMatchFlow flow, bool Function() done, {double most = 200000}) {
    for (var t = 0.0; t < most && !done(); t += frame) {
      flow.advance(frame);
    }
    expect(done(), isTrue);
  }

  // Taps the first free spot for each card still in the stack, or for
  // [count] of them.
  void placeByTaps(IkkiuchiBoardScene scene, {int? count}) {
    final opening = scene.opening;
    for (var i = 0; opening.top != null && (count == null || i < count); i++) {
      final (_, r) = opening.targets().freeSpots.first;
      opening.tap(Offset(r.x + r.w / 2, r.y + r.h / 2));
    }
  }

  // Tobi's cards on the board now.
  Set<int> tobiDown(IkkiuchiBoardScene scene) => {
        for (final id in scene.sides!.tobiCards)
          if (scene.board.cards.card(id) case final c when c.onBoard && !c.held) id,
      };

  group('Tobi laying out his side', () {
    test('he lays every card of his once, in a random order from the match\'s seed', () {
      final side = [
        const IkkiuchiRow([1, 2, 3], [4]),
        const IkkiuchiRow([], [5, 6], middle: [8]),
        const IkkiuchiRow([7], []),
      ];
      List<int> order(int seed) => IkkiuchiTobiOpening.orderOf(side, math.Random(seed));
      expect(order(1).toSet(), {1, 2, 3, 4, 5, 6, 7, 8});
      expect(order(1), hasLength(8));
      expect(order(1), order(1), reason: 'the same seed, the same order');
      expect({for (var seed = 0; seed < 5; seed++) order(seed).join(',')}.length, greaterThan(1), reason: 'not fixed');
    });

    test('his placing time is his time per card at his rating for each card, squeezed to end before a short memory time',
        () {
      const lead = IkkiuchiMatchTuning.tobiPlacingLead, full = Duration(minutes: 15);
      for (final rating in [0.0, 1600.0, 3600.0]) {
        final perCard = IkkiuchiTobi(rating).placingMsPerCard;
        for (final cards in [1, 8, 25]) {
          expect(IkkiuchiTobiOpening.msFor(rating, cards: cards, memorise: full), closeTo(perCard * cards, 1e-6),
              reason: 'rating $rating, $cards cards: a full memory time leaves it as it is');
        }
      }
      const minute = Duration(minutes: 1);
      expect(IkkiuchiTobi(0).placingMsPerCard * 25, greaterThan(minute.inMilliseconds), reason: 'slower than a minute');
      expect(IkkiuchiTobiOpening.msFor(0, cards: 25, memorise: minute), (minute - lead).inMilliseconds);
    });

    test('with fewer cards he is done sooner, each card laid down as quickly', () {
      final flow = match(12, rating: 1600, perSide: 8);
      final perCard = IkkiuchiTobi(1600).placingMsPerCard;
      runUntil(flow, () => flow.scene.opening.tobiDone);
      expect(flow.scene.board.now, closeTo(8 * perCard, 2 * frame), reason: 'his 8 cards, each in his time per card');
    });

    test('each card has its share of his time, his arm no longer on it than a carry and in its shares', () {
      final side = [const IkkiuchiRow([1, 2], [3, 4])];
      final slow = IkkiuchiTobiOpening(side, ms: 40000, rng: math.Random(0));
      expect(slow.per, 10000);
      expect([slow.startOf(0), slow.startOf(3)], [0, 30000]);
      expect([slow.carryMs, slow.backMs], [IkkiuchiCarryTuning.carry, IkkiuchiCarryTuning.back]);
      final quick = IkkiuchiTobiOpening(side, ms: 3200, rng: math.Random(0));
      expect(quick.carryMs + quick.backMs, lessThan(quick.per), reason: 'done with a card before the next');
      expect(quick.carryMs, closeTo(800 * IkkiuchiCarryTuning.layShare.carry, 1e-9));
    });
  });

  group('The opening of a match', () {
    test('it opens placing: the stack full, the side empty, his cards off the board, the memory time running', () {
      final flow = match(1);
      final scene = flow.scene, opening = scene.opening;
      expect(flow.stage, IkkiuchiStage.placing);
      expect(flow.left, IkkiuchiMatchTuning.memorise.inMilliseconds);
      expect(opening.stack, hasLength(25));
      expect(opening.placing, isTrue);
      expect(scene.sides!.playerCards, isEmpty);
      expect(scene.stack, isNotNull, reason: 'room kept for the stack');
      expect(tobiDown(scene), isEmpty, reason: 'his cards wait off the board');
      expect([flow.tally.player, flow.tally.opponent], [25, 25]);
      expect(scene.cardsLeft, (tobi: 25, player: 25), reason: 'the cards in the stack count');
      expect(flow.canArrange, isFalse);
      run(flow, 2000);
      expect(flow.left, closeTo(IkkiuchiMatchTuning.memorise.inMilliseconds - 2000, frame));
    });

    test('Tobi lays his cards down one by one at their homes, and is done after his placing time', () {
      final flow = match(2, rating: 2600);
      final scene = flow.scene, opening = scene.opening;
      final ms = IkkiuchiTobiOpening.msFor(2600, cards: 25, memorise: IkkiuchiMatchTuning.memorise);
      run(flow, ms / 2);
      final half = tobiDown(scene).length;
      expect(half, inInclusiveRange(11, 13), reason: 'about half his cards down');
      expect(opening.tobiDone, isFalse);
      for (final id in tobiDown(scene)) {
        final c = scene.board.cards.card(id);
        expect(c.box.centre.distanceTo(c.home.centre), lessThan(1e-3), reason: 'card $id at its home');
      }
      run(flow, ms / 2 + 200);
      expect(opening.tobiDone, isTrue);
      expect(tobiDown(scene), scene.sides!.tobiCards);
      expect(scene.board.carrying, isFalse);
    });

    test('placing every card and 完了: the memory time runs on, the board laid out for play', () {
      final flow = match(3);
      final scene = flow.scene, opening = scene.opening;
      run(flow, 1000);
      placeByTaps(scene, count: 24);
      flow.donePlacing();
      expect(flow.stage, IkkiuchiStage.placing, reason: '完了 waits for the last card');
      placeByTaps(scene);
      expect(opening.allPlaced, isTrue);
      expect(scene.sides!.playerCards, hasLength(25));
      final left = flow.left;
      flow.donePlacing();
      expect(flow.stage, IkkiuchiStage.memoryTime);
      expect(flow.left, left, reason: 'the memory time goes on from where it was');
      expect(opening.placing, isFalse);
      expect(scene.stack, isNull, reason: 'laid out for play');
      expect(flow.canArrange, isTrue);
      run(flow, 1000);
      expect(scene.board.cards.gliding, isFalse);
      for (final c in scene.board.cards.cards.where((c) => c.onBoard && !c.held)) {
        expect(c.box.centre.distanceTo(c.home.centre), lessThan(1e-3), reason: 'card ${c.id} at its home');
      }
    });

    test('a placed card moves by a drag, or goes back onto the stack', () {
      final flow = match(4);
      final scene = flow.scene, opening = scene.opening;
      placeByTaps(scene, count: 3);
      run(flow, 600);
      final card = scene.sides!.playerCards.first;
      final box = scene.board.cards.card(card).box;
      final at = Offset(box.centre.x, box.centre.y);
      expect(opening.cardAt(at), (card: card, fromStack: false));
      opening
        ..dragStart(card, fromStack: false, at: at)
        ..dragTo(scene.stack!.center);
      expect(opening.drag!.onStack, isTrue);
      opening.dragEnd();
      expect(opening.top, card, reason: 'back on top of the stack');
      expect(opening.stack, hasLength(23));
      expect(scene.sides!.playerCards, isNot(contains(card)));
      run(flow, 600);

      final placed = scene.sides!.playerCards.first;
      final from = scene.board.cards.card(placed).box;
      final (spot, r) = opening.targets().freeSpots.lastWhere((s) => s.$1 is ClusterEnd);
      opening
        ..dragStart(placed, fromStack: false, at: Offset(from.centre.x, from.centre.y))
        ..dragTo(Offset(r.x + r.w / 2, r.y + r.h / 2));
      expect(opening.drag!.spot, spot, reason: 'the spot under the finger');
      opening.dragEnd();
      expect(scene.sides!.playerCards, contains(placed));
      expect(opening.stack, hasLength(23), reason: 'a move takes nothing from the stack');
      final place = scene.sides!.playerBoard.side.placeOf(placed)!;
      expect(spot, ClusterEnd(place.row, place.part));
    });

    test('the time running out with cards in the stack: the game places them by the rules, and play begins', () {
      const memorise = Duration(minutes: 1);
      final flow = match(5, memorise: memorise);
      final scene = flow.scene, opening = scene.opening;
      placeByTaps(scene, count: 4);
      run(flow, memorise.inMilliseconds - 500.0);
      expect(flow.stage, IkkiuchiStage.placing);
      expect(opening.tobiDone, isTrue, reason: 'squeezed to be done first');
      run(flow, 600);
      expect(flow.stage, IkkiuchiStage.gameStart);
      expect(opening.stack, isEmpty);
      expect(opening.placing, isFalse);
      final sides = scene.sides!;
      expect(sides.playerCards, hasLength(25));
      final rules = IkkiuchiSides.rules(sides.player.length);
      for (final row in sides.playerBoard.side.rows) {
        expect(rules.room.fits(row), isTrue);
      }
      final counts = [for (final r in sides.player) r.length];
      expect(counts.reduce(math.max) - counts.reduce(math.min), lessThanOrEqualTo(1), reason: 'spread over the rows: $counts');
      expect(scene.stack, isNull);
      expect(flow.tally.player, 25);
    });

    test('覚えた once the player is done ends the memory time, Tobi laying down the rest of his side at once', () {
      final flow = match(6, rating: 0);
      final scene = flow.scene;
      placeByTaps(scene);
      flow.startEarly();
      expect(flow.stage, IkkiuchiStage.placing, reason: 'not before 完了');
      flow.donePlacing();
      run(flow, IkkiuchiTobi(0).placingMsPerCard + 300);
      expect(scene.opening.tobiDone, isFalse);
      expect(scene.opening.inHand, isNotNull, reason: 'a card in his hand');
      expect(tobiDown(scene), isNot(scene.sides!.tobiCards), reason: 'Tobi still lays out his side');
      flow.startEarly();
      expect(flow.stage, IkkiuchiStage.gameStart);
      expect(scene.opening.tobiDone, isTrue);
      expect(scene.board.carrying, isFalse, reason: 'his arm still');
      expect(tobiDown(scene), scene.sides!.tobiCards, reason: 'every card of his down');
      for (final id in tobiDown(scene)) {
        final c = scene.board.cards.card(id);
        expect(c.box.centre.distanceTo(c.home.centre), lessThan(1e-3), reason: 'card $id at its home');
      }
    });

    test('the memory time used runs from the start of the placing to the first read, cut short by 覚えた', () {
      const memorise = Duration(minutes: 1), early = Duration(seconds: 20);
      final toFirstRead = IkkiuchiMatchTuning.greeting + IkkiuchiMatchTuning.yoka;
      Duration used({required bool ready}) {
        final flow = match(13, memorise: memorise);
        placeByTaps(flow.scene);
        flow.donePlacing();
        if (ready) {
          run(flow, early.inMilliseconds.toDouble());
          flow.startEarly();
        }
        runUntil(flow, () => flow.playBegun);
        final at = flow.memorised;
        run(flow, 3000);
        expect(flow.memorised, at, reason: 'it stops at the first read');
        flow.dispose();
        return at;
      }

      expect(used(ready: false).inMilliseconds, closeTo((memorise + toFirstRead).inMilliseconds, 2 * frame),
          reason: 'all of it, then the greeting and the 序歌');
      expect(used(ready: true).inMilliseconds, closeTo((early + toFirstRead).inMilliseconds, 2 * frame),
          reason: 'cut short by 覚えた');
    });

    test('a short memory time squeezes Tobi: he is done just before it is up, and the reading starts on time', () {
      const memorise = Duration(minutes: 1);
      final flow = match(7, rating: 0, memorise: memorise);
      final scene = flow.scene;
      placeByTaps(scene);
      flow.donePlacing();
      final squeezed = (memorise - IkkiuchiMatchTuning.tobiPlacingLead).inMilliseconds.toDouble();
      run(flow, squeezed - 1000);
      expect(scene.opening.tobiDone, isFalse);
      run(flow, 1200);
      expect(scene.opening.tobiDone, isTrue, reason: 'done ${IkkiuchiMatchTuning.tobiPlacingLead} before it is up');
      expect(flow.stage, IkkiuchiStage.memoryTime);
      run(flow, memorise.inMilliseconds - squeezed);
      expect(flow.stage, IkkiuchiStage.gameStart, reason: 'the memory time is up on time');
    });

    test('after 完了 the player may rearrange until play begins; a move left open holds the match', () {
      final flow = match(8);
      final scene = flow.scene, arrange = scene.arrange;
      placeByTaps(scene);
      flow.donePlacing();
      run(flow, 600);
      expect(flow.canArrange, isTrue);
      arrange.start();
      final card = scene.sides!.playerCards.first;
      final box = scene.board.cards.card(card).box;
      final (_, r) = arrange.targets().freeSpots.last;
      arrange.dragStart(card, fromStack: false, at: Offset(box.centre.x, box.centre.y));
      arrange.dragTo(Offset(r.x + r.w / 2, r.y + r.h / 2));
      expect(arrange.drag!.spot, isNotNull);
      arrange.dragEnd();
      run(flow, 600);
      flow.endMemoryTime();
      expect(flow.stage, IkkiuchiStage.movingCard, reason: 'held while the cards are still moved');
      arrange.finish();
      run(flow, 600);
      expect(flow.stage, IkkiuchiStage.gameStart);
      expect(flow.canArrange, isFalse);
    });

    test('a card placed while his arm carries one: the carry goes on, the card to its home', () {
      final flow = match(9);
      final scene = flow.scene;
      run(flow, 100);
      expect(scene.opening.inHand, isNotNull);
      final carried = scene.opening.inHand!;
      final before = scene.board;
      placeByTaps(scene, count: 1);
      expect(scene.board, isNot(same(before)), reason: 'laid out afresh');
      expect(scene.board.cards.card(carried).held, isTrue, reason: 'still in his hand');
      run(flow, 100);
      expect(scene.board.carry, isNotNull, reason: 'the carry goes on, on the new board');
      runUntil(flow, () => scene.opening.inHand != carried);
      final c = scene.board.cards.card(carried);
      expect(c.held, isFalse);
      expect(c.box.centre.distanceTo(c.home.centre), lessThan(1e-3));
    });

    test('終了 while placing ends the match with both sides laid out', () {
      final flow = match(10);
      final scene = flow.scene;
      placeByTaps(scene, count: 5);
      run(flow, 3000);
      flow.end();
      expect(flow.stage, IkkiuchiStage.gameEnd);
      expect(scene.opening.stack, isEmpty);
      expect(scene.opening.tobiDone, isTrue);
      expect(scene.sides!.playerCards, hasLength(25));
      expect(tobiDown(scene), scene.sides!.tobiCards);
    });
  });

  group('The board through a match', () {
    test("a match of 1, 2 or 3 rows keeps its rows and its cards' size from the deal to its last cards", () {
      for (final (rows, perSide) in [
        (1, IkkiuchiLayoutTuning.oneRowUpTo),
        (2, IkkiuchiLayoutTuning.twoRowsUpTo),
        (3, 25),
      ]) {
        final flow = match(11, perSide: perSide, rows: rows);
        final scene = flow.scene;
        final start = scene.layout;
        placeByTaps(scene);
        flow.donePlacing();
        scene.opening.finishTobi();

        // Where each row of each side lies down the board, by its cards.
        Map<(IkkiuchiSide, int), double> rowsAt() {
          final sides = scene.sides!;
          return {
            for (final c in scene.layout.cards)
              (
                c.side,
                (c.side == IkkiuchiSide.player ? sides.player : sides.tobi)
                    .indexWhere((r) => [...r.left, ...r.middle, ...r.right].contains(c.id)),
              ): c.box.centre.y,
          };
        }

        final placed = rowsAt();
        void expectKept(String why) {
          final layout = scene.layout;
          expect(layout.cardW, start.cardW, reason: '$rows rows, $why: the cards keep their size');
          expect([layout.field.top, layout.field.height], [start.field.top, start.field.height],
              reason: '$rows rows, $why: the field keeps its rows');
          expect(layout.tobi.k, start.tobi.k, reason: '$rows rows, $why: Tobi keeps his size');
          for (final MapEntry(key: row, value: y) in rowsAt().entries) {
            expect(y, closeTo(placed[row]!, 1e-9), reason: '$rows rows, $why: row $row in its place');
          }
        }

        expectKept('laid out for play');
        var sides = scene.sides!;
        while (sides.tobiCards.length > 1 || sides.playerCards.length > 1) {
          final card = sides.playerCards.length >= sides.tobiCards.length ? sides.playerCards.last : sides.tobiCards.last;
          scene.relayout(sides.without(card));
          sides = scene.sides!;
          expectKept('${sides.tobiCards.length} and ${sides.playerCards.length} cards left');
        }
        flow.dispose();
      }
    });
  });
  // No two of the scene's cards overlap, and each lies on the board, in its
  // own half clear of the band, and clear of the game column.
  void expectApart(IkkiuchiBoardScene scene, String why) {
    final layout = scene.layout;
    final board = Rect.fromLTWH(0, 0, layout.size.x, layout.size.y);
    final cards = [
      for (final c in layout.cards) (side: c.side, at: IkkiuchiPlayerSpots.boundsOf(c.box).deflate(1e-6)),
    ];
    for (final (i, card) in cards.indexed) {
      final at = card.at;
      expect(board.intersect(at), at, reason: '$why: on the board');
      expect(card.side == IkkiuchiSide.opponent ? at.bottom <= layout.band.top : at.top >= layout.band.bottom, isTrue,
          reason: '$why: in its half');
      if (layout.column case final column?) expect(at.right, lessThanOrEqualTo(column.left), reason: why);
      for (final other in cards.skip(i + 1)) {
        expect(at.overlaps(other.at), isFalse, reason: '$why: no cards overlap');
      }
    }
  }

  // Plays [flow] to its end, the player faulting on every read: touching a
  // card of the side the card read is not on, and on a からふだ any card. The
  // first [karafuda] reads are からふだ that Tobi lets go by, the player
  // touching both sides on each. They send Tobi a card when the rules ask,
  // and place each card he sends at the first free spot the field shows,
  // checking that it shows a spot in every row the rules give one and that
  // no cards overlap. Gives the most
  // cards they held, the most a row of theirs held before the match was
  // decided, and how many of his cards went on without waiting for them.
  ({int held, int row, int unplaced}) faultEveryRead(IkkiuchiMatchFlow flow, {int karafuda = 0}) {
    final scene = flow.scene, send = scene.send, rating = flow.rating;
    var held = 0, row = 0, unplaced = 0;
    int? read;
    final touches = <int>[];
    void touch(int id) {
      final c = scene.board.cards.card(id).box.centre, at = Offset(c.x, c.y);
      scene.pointer(PointerDownEvent(pointer: 1, position: at));
      scene.pointer(PointerUpEvent(pointer: 1, position: at));
    }

    for (var t = 0.0; t < const Duration(hours: 1).inMilliseconds && !flow.stage.over; t += frame) {
      final first = flow.reads.length < karafuda;
      flow.rating = first ? null : rating;
      if (first) flow.askKarafuda();
      final carrying = send.stage == IkkiuchiSendStage.carrying;
      flow.advance(frame);
      if (carrying && send.stage == IkkiuchiSendStage.none) unplaced++;
      final sides = scene.sides!, call = scene.reader.call;
      if (touches.isNotEmpty) touch(touches.removeAt(0));
      if (flow.stage == IkkiuchiStage.kaminoku && call != null && call.card != read) {
        read = call.card;
        final (tobi, mine) = (sides.tobiCards.first, sides.playerCards.first);
        touches.addAll(first ? [tobi, mine] : [sides.tobiCards.contains(call.card) ? mine : tobi]);
      }
      if (send.stage == IkkiuchiSendStage.sending && send.drag == null) {
        final card = sides.playerCards.first, c = scene.board.cards.card(card).box.centre;
        send.dragStart(card, fromStack: false, at: Offset(c.x, c.y));
        send.dragTo(send.tobiSide.center);
        send.dragEnd();
      }
      if (send.stage == IkkiuchiSendStage.waiting) {
        final why = '${sides.playerCards.length} held';
        expectApart(scene, why);
        final free = send.targets().freeSpots;
        expect(free, isNotEmpty, reason: '$why: a spot on the field for each card he sends');
        expect({for (final (spot, _) in free) send.placeOf(spot)!.row},
            {for (final spot in scene.sides!.playerBoard.freeSpots) send.placeOf(spot)!.row},
            reason: '$why: a spot in every row the rules give one');
        final (_, r) = free.first;
        final spot = Rect.fromLTWH(r.x, r.y, r.w, r.h);
        for (final c in scene.layout.cards) {
          expect(spot.deflate(1e-6).overlaps(IkkiuchiPlayerSpots.boundsOf(c.box)), isFalse, reason: '$why: the spot is free');
        }
        send.tap(spot.center);
        expect(send.stage, IkkiuchiSendStage.none, reason: '$why: placed there');
        expectApart(scene, '$why, placed');
      }
      held = math.max(held, scene.sides!.playerCards.length);
      if (!flow.tally.decided) row = math.max(row, scene.sides!.player.map((r) => r.length).reduce(math.max));
    }
    expect(flow.stage.over, isTrue,
        reason: 'the match never hangs: held in ${flow.stage}, ${send.stage}, '
            '${scene.sides!.tobiCards.length} and ${scene.sides!.playerCards.length} cards');
    return (held: held, row: row, unplaced: unplaced);
  }

  group('The field zooms out', () {
    for (final landscape in [true, false]) {
      final where = landscape ? 'landscape' : 'portrait';
      for (final (name, perSide, rows) in [
        ('Bullet', IkkiuchiMode.bullet.perSide, 2),
        ('Bullet', IkkiuchiMode.bullet.perSide, 3),
        ('Blitz', IkkiuchiMode.blitz.perSide, 2),
        ('Blitz', IkkiuchiMode.blitz.perSide, 3),
        ('Rapid', IkkiuchiMode.rapid.perSide, IkkiuchiMode.rapid.defaultRows),
        ('custom', IkkiuchiLayoutTuning.oneRowUpTo, 1),
        ('custom', IkkiuchiLayoutTuning.twoRowsUpTo, 2),
        ('custom', 25, 3),
      ]) {
        test('$name, $perSide a side in $rows rows, $where, the player faulting on every read: every card Tobi '
            'sends gets a spot on the field, no row past its most, and Tobi wins', () {
          final flow = match(5, perSide: perSide, rows: rows, landscape: landscape), scene = flow.scene;
          placeByTaps(scene);
          flow
            ..donePlacing()
            ..startEarly();
          final start = scene.layout.cardW;
          final most = faultEveryRead(flow);
          expect(most.unplaced, 0, reason: 'each waits for the player to place it');
          expect(most.row, lessThanOrEqualTo(IkkiuchiLayout.rowCap));
          expect(flow.result, IkkiuchiResult.lost, reason: 'Tobi wins');
          expect(scene.layout.cardW, lessThanOrEqualTo(start + 1e-9), reason: 'never bigger than at the start');
          flow.dispose();
        });
      }

      test('25 a side in 3 rows, $where, the first 12 reads からふだ the player faults on both sides of: the one '
          'card past every row at its most goes past a row\'s room, and Tobi wins', () {
        const perSide = 25;
        final flow = match(5, perSide: perSide, rows: 3, landscape: landscape), scene = flow.scene;
        placeByTaps(scene);
        flow
          ..donePlacing()
          ..startEarly();
        final most = faultEveryRead(flow, karafuda: 12);
        expect(most.held, greaterThanOrEqualTo(2 * perSide - 1));
        expect(most.unplaced, 1);
        expect(most.row, IkkiuchiLayout.rowCap + 1);
        expect(flow.result, IkkiuchiResult.lost, reason: 'Tobi wins');
        flow.dispose();
      });
    }
  });
}

IkkiuchiCall _call(int id) => IkkiuchiCall(id, const ['か']);
