// 一騎打ち's opening (IkkiuchiOpeningFlow, run by IkkiuchiMatchFlow): the
// player places their cards from a stack while Tobi lays out his side with
// his arm and the memory time runs; 完了 once every card is placed; the rest
// placed by the game when the time runs out; 覚えた once both are done; Tobi
// squeezed into a short memory time; and 並べ替え after 完了 until play
// begins.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ikkiuchi_call.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_opening.dart';
import 'package:fudatobashi/domain/ikkiuchi_send.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_layout.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_scene.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_card_faces.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_flow.dart';
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

  // A match's opening dealt by [seed], [perSide] cards a side and Tobi at
  // [rating], on the phone in landscape, as the match screen deals it.
  IkkiuchiBoardScene dealt(int seed, {double rating = 2000, int perSide = 25}) {
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
    final own = deck.sublist(0, perSide), others = deck.sublist(perSide, 2 * perSide);
    final homes = layout.generate(rating: rating, own: own, others: others, rows: 3, seed: seed);
    final sides = IkkiuchiSides.start(homes, [for (var r = 0; r < 3; r++) const IkkiuchiRow([], [])]);
    final board = IkkiuchiBoardLayout.of(
        size: phone, landscape: true, tobiRows: sides.tobi, playerRows: sides.player, rig: rig, opening: true);
    return IkkiuchiBoardScene(board, IkkiuchiCardFaces(showNumber: false),
        sides: sides, stack: others, tobiRating: rating, seed: seed);
  }

  const words = IkkiuchiMatchWords(kimariji: _kimariji, call: _call, karafuda: 'からふだ');

  IkkiuchiMatchFlow match(int seed, {double rating = 2000, int perSide = 25, Duration? memorise}) =>
      IkkiuchiMatchFlow(dealt(seed, rating: rating, perSide: perSide),
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

    test('his placing time is his curve at his rating, squeezed to end before a short memory time', () {
      const lead = IkkiuchiMatchTuning.tobiPlacingLead;
      for (final rating in [0.0, 1600.0, 3600.0]) {
        final own = IkkiuchiTobi(rating).placingSeconds * 1000;
        expect(IkkiuchiTobiOpening.msFor(rating, const Duration(minutes: 15)), closeTo(own, 1e-6),
            reason: 'rating $rating: a full memory time leaves it as it is');
      }
      const minute = Duration(minutes: 1);
      expect(IkkiuchiTobi(0).placingSeconds * 1000, greaterThan(minute.inMilliseconds), reason: 'slower than a minute');
      expect(IkkiuchiTobiOpening.msFor(0, minute), (minute - lead).inMilliseconds);
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
      expect(flow.canStartEarly, isFalse);
      run(flow, 2000);
      expect(flow.left, closeTo(IkkiuchiMatchTuning.memorise.inMilliseconds - 2000, frame));
    });

    test('Tobi lays his cards down one by one at their homes, and is done after his placing time', () {
      final flow = match(2, rating: 2600);
      final scene = flow.scene, opening = scene.opening;
      final ms = IkkiuchiTobiOpening.msFor(2600, IkkiuchiMatchTuning.memorise);
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

    test('覚えた only once the player is done and Tobi has laid out his side; it ends the memory time', () {
      final flow = match(6, rating: 3000);
      final scene = flow.scene;
      placeByTaps(scene);
      expect(flow.canStartEarly, isFalse, reason: 'not before 完了');
      flow.startEarly();
      expect(flow.stage, IkkiuchiStage.placing);
      flow.donePlacing();
      expect(scene.opening.tobiDone, isFalse);
      expect(flow.canStartEarly, isFalse, reason: 'Tobi still lays out his side');
      flow.startEarly();
      expect(flow.stage, IkkiuchiStage.memoryTime);
      runUntil(flow, () => scene.opening.tobiDone);
      expect(flow.canStartEarly, isTrue);
      flow.startEarly();
      expect(flow.stage, IkkiuchiStage.gameStart);
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
}

String _kimariji(int id) => '$id';

IkkiuchiCall _call(int id) => IkkiuchiCall(id, const ['か']);
