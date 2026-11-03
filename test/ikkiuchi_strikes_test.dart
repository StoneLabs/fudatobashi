// 一騎打ち's Tobi striking: the strike's path, the card sim, the board that
// ties them together, his mistakes, and a headless count of the faults he
// makes when he means to take cleanly.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ikkiuchi_board.dart';
import 'package:fudatobashi/domain/ikkiuchi_cards.dart';
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_read.dart';
import 'package:fudatobashi/domain/ikkiuchi_rig.dart';
import 'package:fudatobashi/domain/ikkiuchi_strike.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_layout.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_tobi_art.dart';

import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  final layout = IkkiuchiLayout.ofPoems();
  final rig = IkkiuchiTobiArt.rig();
  const ratings = [0.0, 1600.0, 2800.0, 3600.0];
  const step = IkkiuchiBoard.stepMs;

  // A full field dealt by [seed]: Tobi's side by his layout at [rating],
  // the player's at random, on a phone's screen.
  IkkiuchiBoard boardFor(int seed, double rating, {bool landscape = false}) {
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
    final own = deck.sublist(0, 25), others = deck.sublist(25, 50);
    final l = IkkiuchiBoardLayout.of(
      size: landscape ? const Size(832, 384) : const Size(384, 832),
      landscape: landscape,
      tobiRows: layout.generate(rating: rating, own: own, others: others, rows: 3, seed: seed).start,
      playerRows: IkkiuchiBoardLayout.randomSide(others, 3, math.Random(seed)),
      rig: rig,
    );
    return l.board();
  }

  // A clean strike at [card] with [move], its reach [reachMs].
  IkkiuchiRead strikeAt(IkkiuchiBoard board, int card, IkkiuchiMove move, double reachMs) =>
      IkkiuchiRead(called: card, onField: true, move: move, reachMs: reachMs, correctionReachMs: reachMs);

  // A setup for a strike at [card] on [board], as the board makes one.
  IkkiuchiStrikeSetup setupFor(IkkiuchiBoard board, int card, {double? reachMs}) {
    final target = board.cards.card(card);
    final dead = target.side == IkkiuchiSide.tobi ? IkkiuchiSide.player : IkkiuchiSide.tobi;
    return IkkiuchiStrikeSetup(
      target: target.box,
      targetId: card,
      tobi: board.tobi,
      board: board.size,
      cardW: board.cards.cardW,
      away: dead == IkkiuchiSide.tobi ? const Vec(0, 1) : const Vec(0, -1),
      wrong: [
        for (final c in board.cards.cards)
          if (c.side == dead) c.box,
      ],
      reachMs: reachMs,
    );
  }

  int sideCard(IkkiuchiBoard board, IkkiuchiSide side, int pick) {
    final ids = [
      for (final c in board.cards.cards)
        if (c.side == side) c.id,
    ]..sort();
    return ids[pick % ids.length];
  }

  // Runs [board] until its call has played out and its cards lie still,
  // or with [settle] only that many ms past the call.
  void playOut(IkkiuchiBoard board, {void Function()? each, double? settle}) {
    double? doneAt;
    for (var i = 0; i < 4000; i++) {
      if (!board.busy) doneAt ??= board.now;
      if (settle == null ? !board.busy && board.cards.settled : doneAt != null && board.now - doneAt >= settle) {
        break;
      }
      board.advance(step);
      each?.call();
    }
  }

  group("Tobi's strike path", () {
    final board = boardFor(1, 2000);
    final card = sideCard(board, IkkiuchiSide.player, 7);

    test('is a pure function of its time', () {
      for (final move in IkkiuchiMove.values) {
        final a = IkkiuchiStrike(move, setupFor(board, card, reachMs: 400));
        final b = IkkiuchiStrike(move, setupFor(board, card, reachMs: 400));
        final times = [for (var t = 0.0; t <= a.end; t += 37) t];
        final forth = [for (final t in times) a.handAtTime(t)];
        final back = [for (final t in times.reversed) a.handAtTime(t)].reversed.toList();
        expect(back, forth, reason: '${move.name}: the same hand whatever came before');
        expect([for (final t in times) b.handAtTime(t)], forth, reason: '${move.name}: the same for a strike alike');
        final s = board.tobi.feet;
        expect(a.armPoints(a.tau(a.hitAt), s), b.armPoints(b.tau(b.hitAt), s));
        expect(a.armPoints(0, s).first, s, reason: 'the arm starts at the shoulder');
        expect(a.armPoints(a.tau(a.hitAt), s).last, a.handAtTime(a.hitAt), reason: 'and ends at the hand');
      }
    });

    test("hits at his reach curve's time, never under its floor", () {
      for (final rating in ratings) {
        for (final move in IkkiuchiMove.values) {
          final reach = IkkiuchiTobi(rating).reachMs;
          final strike = IkkiuchiStrike(move, setupFor(board, card, reachMs: reach));
          expect(strike.hitAt, closeTo(math.max(IkkiuchiTuning.reachFloorMs, reach), 1e-9), reason: '$rating ${move.name}');
          expect(strike.handAtTime(strike.hitAt).distanceTo(strike.contact), lessThan(strike.touch * 2),
              reason: '$rating ${move.name}: the hand is at the card at the hit');
        }
      }
      for (final move in IkkiuchiMove.values) {
        final quick = IkkiuchiStrike(move, setupFor(board, card, reachMs: 40));
        expect(quick.hitAt, IkkiuchiTuning.reachFloorMs, reason: '${move.name}: no hit under the floor');
      }
    });

    test('the fist is live only from the end of the hit stop to the end of the follow-through', () {
      for (final reach in [130.0, 400.0, 1000.0]) {
        for (final move in IkkiuchiMove.values) {
          final s = IkkiuchiStrike(move, setupFor(board, card, reachMs: reach));
          final why = '${move.name} at $reach ms';
          expect(s.tau(s.liveUntil), closeTo(s.backAt, 1e-6), reason: '$why: it ends where the move turns for home');
          for (var t = 0.0; t <= s.end; t += 1) {
            expect(s.liveAt(t), t >= s.liveFrom && t <= s.liveUntil, reason: '$why at $t ms');
          }
          expect(s.liveAt(s.hitAt + s.hitStop / 2), isFalse, reason: '$why: not in the hit stop');
        }
      }
    });

    test('the live fist keeps its clearance from the side without the called card', () {
      for (final rating in ratings) {
        for (var seed = 0; seed < 6; seed++) {
          for (final landscape in [false, true]) {
            final b = boardFor(seed, rating, landscape: landscape);
            for (final side in IkkiuchiSide.values) {
              final c = sideCard(b, side, seed * 5 + 3);
              for (final move in IkkiuchiMove.values) {
                final setup = setupFor(b, c, reachMs: IkkiuchiTobi(rating).reachMs);
                final s = IkkiuchiStrike(move, setup);
                for (var t = s.liveFrom; t <= s.liveUntil; t += 0.5) {
                  final gap = gapToCards(setup.wrong, s.handAtTime(t)) - s.touch;
                  expect(gap, greaterThanOrEqualTo(IkkiuchiArmTuning.clearance * b.cards.cardW - 0.01),
                      reason: '$rating seed $seed ${side.name} ${move.name} at $t');
                }
              }
            }
          }
        }
      }
    });
  });

  group('The card sim', () {
    test('a launched card leaves the field, and resting cards sleep', () {
      final cards = IkkiuchiCards([
        (id: 1, side: IkkiuchiSide.player, box: const CardBox(Vec(200, 600), 19, 27)),
        (id: 2, side: IkkiuchiSide.player, box: const CardBox(Vec(240, 600), 19, 27)),
      ], board: const Vec(384, 832), cardW: 38);
      expect(cards.settled, isTrue, reason: 'laid out still');
      cards.launch(cards.card(1), const Vec(-3000, 400), 4);
      for (var i = 0; i < 600; i++) {
        cards.step();
      }
      expect(cards.card(1).onBoard, isFalse, reason: 'the taken card is gone');
      expect(cards.card(2).still, isTrue);
      expect(cards.card(2).movedFrom(cards.card(2).home, dp: 0.01, radians: 0.001), isFalse);
    });

    test('no card crosses the middle of the band', () {
      final cards = IkkiuchiCards([
        (id: 1, side: IkkiuchiSide.player, box: const CardBox(Vec(200, 600), 19, 27)),
        (id: 2, side: IkkiuchiSide.tobi, box: const CardBox(Vec(200, 300), 19, 27, math.pi)),
      ], board: const Vec(384, 832), cardW: 38, centreLine: 450);
      cards.launch(cards.card(1), const Vec(0, -3000), 0);
      for (var i = 0; i < 600; i++) {
        cards.step();
      }
      expect(cards.card(2).movedFrom(cards.card(2).home, dp: 0.01, radians: 0.001), isFalse);
    });

    test('a taken card that stops on the field fades from it', () {
      final cards = IkkiuchiCards([
        (id: 1, side: IkkiuchiSide.player, box: const CardBox(Vec(200, 600), 19, 27)),
      ], board: const Vec(384, 832), cardW: 38);
      cards.launch(cards.card(1), const Vec(150, 0), 0);
      for (var i = 0; i < 240; i++) {
        cards.step();
      }
      expect(cards.card(1).onBoard, isFalse);
    });

    test('is the same for the same calls at the same steps', () {
      List<CardBox> run() {
        final board = boardFor(4, 1600);
        board.call(strikeAt(board, sideCard(board, IkkiuchiSide.player, 11), IkkiuchiMove.smear, 300));
        playOut(board);
        return [for (final c in board.cards.cards) c.box];
      }

      final a = run(), b = run();
      for (var i = 0; i < a.length; i++) {
        expect((a[i].centre, a[i].angle), (b[i].centre, b[i].angle));
      }
    });

    test('after a strike every card on the board lies still', () {
      final board = boardFor(2, 2800);
      board.call(strikeAt(board, sideCard(board, IkkiuchiSide.tobi, 3), IkkiuchiMove.whip, 300));
      playOut(board);
      expect(board.busy, isFalse);
      expect(board.cards.settled, isTrue);
      expect(board.cards.cards.where((c) => c.onBoard && !c.taken), hasLength(49));
    });
  });

  group("Tobi's mistakes", () {
    // Two look-alikes dealt to the two sides, by their kimariji.
    ({IkkiuchiBoard board, int called, int alike}) pair(IkkiuchiSide calledSide) {
      for (var seed = 0;; seed++) {
        final board = boardFor(seed, 1600);
        for (final a in board.cards.cards.where((c) => c.side == calledSide)) {
          for (final b in board.cards.cards.where((c) => c.side != calledSide)) {
            if (layout.alike(a.id, b.id)) return (board: board, called: a.id, alike: b.id);
          }
        }
      }
    }

    test("a look-alike on the side without the called card is a fault; he then takes the called card", () {
      final (:board, :called, :alike) = pair(IkkiuchiSide.player);
      board.call(IkkiuchiRead(
        called: called,
        onField: true,
        move: IkkiuchiMove.whip,
        reachMs: 400,
        correctionReachMs: 300,
        wrong: alike,
        slip: IkkiuchiSlip.lookAlike,
      ));
      playOut(board);
      expect(board.faults.keys.first, alike);
      expect(board.cards.card(called).taken, isTrue);
      expect(board.cards.card(alike).taken, isFalse);
      expect(board.runs, hasLength(2));
      final first = board.runs.first, second = board.runs.last;
      expect(second.start - first.start - first.strike.hitAt, IkkiuchiTuning.correction.inMilliseconds,
          reason: 'he corrects after the correction time');
      expect(second.strike.side, first.strike.side, reason: 'with the same arm');
      expect(second.strike.handAt(0).distanceTo(first.strike.handAtTime(second.start - first.start)),
          lessThan(1e-6),
          reason: 'his hand sets off from where it was');
    });

    test("a wrong card on the called card's own side is not a fault", () {
      final board = boardFor(5, 1600);
      final called = sideCard(board, IkkiuchiSide.player, 3), wrong = sideCard(board, IkkiuchiSide.player, 12);
      board.call(IkkiuchiRead(
          called: called, onField: true, move: IkkiuchiMove.whip, reachMs: 400, correctionReachMs: 300, wrong: wrong));
      playOut(board);
      expect(board.faults, isEmpty);
      expect(board.cards.card(called).taken, isTrue);
    });

    test('a touch on a からふだ is a fault, and takes nothing', () {
      final board = boardFor(6, 0);
      final away = poems.all.map((p) => p.id).firstWhere((id) => !board.field.containsKey(id));
      final touched = sideCard(board, IkkiuchiSide.tobi, 8);
      board.call(IkkiuchiRead(
          called: away, onField: false, move: IkkiuchiMove.smear, reachMs: 500, correctionReachMs: 500, wrong: touched));
      playOut(board);
      expect(board.faults.keys.first, touched);
      expect(board.cards.cards.where((c) => c.taken), isEmpty);
      expect(board.restFace, TobiFace.shocked);
    });

    test('without mistakes he never goes for a wrong card, and on a からふだ he stays still', () {
      final board = boardFor(7, 0);
      final rng = math.Random(1);
      final away = poems.all.map((p) => p.id).firstWhere((id) => !board.field.containsKey(id));
      for (var i = 0; i < 300; i++) {
        final called = i.isEven ? board.field.keys.elementAt(i % 50) : away;
        final read = IkkiuchiRead.decide(
            rating: 0, called: called, field: board.field, from: board.shoulders, alike: layout.alike, rng: rng, mistakes: false);
        expect(read.wrong, isNull);
        expect(read.strikes, called != away);
      }
    });

    test('reads take his drawn take time: the hit lands then, his reach squeezed, never under the floor', () {
      final board = boardFor(8, 3600);
      final rng = math.Random(2);
      for (final rating in ratings) {
        for (var i = 0; i < 200; i++) {
          final read = IkkiuchiRead.decide(
              rating: rating,
              called: board.field.keys.elementAt(i % 50),
              field: board.field,
              from: board.shoulders,
              alike: layout.alike,
              rng: rng,
              mistakes: false);
          expect(read.reachMs, greaterThanOrEqualTo(IkkiuchiTuning.reachFloorMs));
          expect(read.reachMs, lessThanOrEqualTo(math.max(IkkiuchiTuning.reachFloorMs, IkkiuchiTobi(rating).reachMs) + 1e-9));
          expect(read.reactionMs, greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('His moves', () {
    final board = boardFor(9, 2000);
    IkkiuchiMove draw(double rating, math.Random rng, Set<IkkiuchiMove>? moves) => IkkiuchiRead.decide(
            rating: rating,
            called: board.field.keys.first,
            field: board.field,
            from: board.shoulders,
            alike: layout.alike,
            rng: rng,
            mistakes: false,
            moves: moves)
        .move;

    test('are picked among the moves on, by his shares among them', () {
      const n = 4000;
      final rng = math.Random(3);
      const on = {IkkiuchiMove.sweep, IkkiuchiMove.whip};
      final drawn = [for (var i = 0; i < n; i++) draw(3600, rng, on)];
      expect(drawn.toSet(), on);
      final shares = IkkiuchiTobi(3600).moves;
      final sweep = shares.sweep / (shares.sweep + shares.whip);
      expect(drawn.where((m) => m == IkkiuchiMove.sweep).length / n, closeTo(sweep, 0.03));
    });

    test('a move on alone is always his, even with no share at his rating', () {
      expect(IkkiuchiTobi(0).moves.sweep, 0);
      final rng = math.Random(4);
      for (var i = 0; i < 50; i++) {
        expect(draw(0, rng, {IkkiuchiMove.sweep}), IkkiuchiMove.sweep);
      }
    });
  });

  // The headless check of the mock's faults: many seeded clean strikes at
  // each rating, with every move, in both layouts, half of them at the
  // player's cards. None may touch a card on the side without the called
  // card, the fist is never on the board on the way home, and Tobi's own
  // cards never move while he returns from the player's side.
  test('clean strikes make no accidental faults and push nothing on the way home', () {
    const strikesPerCase = 4;
    var strikes = 0, accidental = 0, homePushes = 0, tobiMoved = 0, overCap = 0;
    final rows = <String>[];
    for (final landscape in [false, true]) {
      for (final rating in ratings) {
        for (final move in IkkiuchiMove.values) {
          var caseFaults = 0;
          for (var i = 0; i < strikesPerCase; i++) {
            final seed = 100 * i + move.index;
            final board = boardFor(seed, rating, landscape: landscape);
            final rng = math.Random(seed);
            final side = i.isEven ? IkkiuchiSide.player : IkkiuchiSide.tobi;
            final called = sideCard(board, side, rng.nextInt(25));
            final decided = IkkiuchiRead.decide(
                rating: rating,
                called: called,
                field: board.field,
                from: board.shoulders,
                alike: layout.alike,
                rng: rng,
                mistakes: false,
                moves: {move});
            board.call(strikeAt(board, called, move, decided.reachMs));
            Map<IkkiuchiCard, CardBox>? home;
            playOut(board, settle: 150, each: () {
              final run = board.runs.lastOrNull;
              if (run == null) return;
              final t = run.at(board.now);
              if (t > run.strike.liveUntil + step && board.cards.fistOn) homePushes++;
              for (final c in board.cards.fistTouched) {
                if (!c.taken && c.velocity.length > board.cards.pushCap * 1.001) overCap++;
              }
              if (side == IkkiuchiSide.player && home == null && t > run.strike.liveUntil) {
                home = {
                  for (final c in board.cards.cards)
                    if (c.side == IkkiuchiSide.tobi && c.onBoard) c: c.box,
                };
              }
            });
            strikes++;
            if (board.faults.isNotEmpty) caseFaults++;
            for (final MapEntry(key: c, value: box) in (home ?? {}).entries) {
              if (c.movedFrom(box, dp: 0.5, radians: 0.01)) tobiMoved++;
            }
          }
          accidental += caseFaults;
          rows.add('${landscape ? 'landscape' : 'portrait '} ${rating.round().toString().padLeft(4)} '
              '${move.name.padRight(9)} faults $caseFaults/$strikesPerCase');
        }
      }
    }
    // ignore: avoid_print
    print('$strikes clean strikes: $accidental accidental faults, $homePushes steps with the fist on the way home, '
        '$tobiMoved of his cards moved while he returned, $overCap pushes over the cap\n${rows.join('\n')}');
    expect(accidental, 0);
    expect(homePushes, 0);
    expect(tobiMoved, 0);
    expect(overCap, 0);
  });
}
