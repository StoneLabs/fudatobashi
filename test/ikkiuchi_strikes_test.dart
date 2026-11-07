// 一騎打ち's Tobi striking: the strike's path, the card sim, the board that
// ties them together, his mistakes, and a headless count of the faults he
// makes when he means to take cleanly.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/ikkiuchi_board.dart';
import 'package:fudatobashi/domain/ikkiuchi_cards.dart';
import 'package:fudatobashi/domain/ikkiuchi_field.dart';
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

  // Boards as they stand in portrait, turned for landscape: a phone's whole
  // screen, a short phone's small board, and a tablet's, where the cards
  // grow to their widest.
  const phone = Size(384, 832), small = Size(300, 460), large = Size(1032, 1376);
  const sizes = {'phone': phone, 'small': small, 'large': large};

  // A full field dealt by [seed]: Tobi's side by his layout at [rating],
  // the player's by it too, on a board of [size].
  IkkiuchiBoardLayout layoutFor(int seed, double rating, {bool landscape = false, Size size = phone}) {
    final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
    final own = deck.sublist(0, 25), others = deck.sublist(25, 50);
    return IkkiuchiBoardLayout.of(
      size: landscape ? size.flipped : size,
      landscape: landscape,
      tobiRows: layout.generate(rating: rating, own: own, others: others, rows: 3, seed: seed).start,
      playerRows: layout.generate(rating: rating, own: others, others: own, rows: 3, seed: seed + 1).start,
      rig: rig,
    );
  }

  IkkiuchiBoard boardFor(int seed, double rating, {bool landscape = false, Size size = phone}) =>
      layoutFor(seed, rating, landscape: landscape, size: size).board();

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
      for (final MapEntry(key: name, value: size) in sizes.entries) {
        for (final rating in ratings) {
          for (var seed = 0; seed < 6; seed++) {
            for (final landscape in [false, true]) {
              final b = boardFor(seed, rating, landscape: landscape, size: size);
              for (final side in IkkiuchiSide.values) {
                final c = sideCard(b, side, seed * 5 + 3);
                for (final move in IkkiuchiMove.values) {
                  final setup = setupFor(b, c, reachMs: IkkiuchiTobi(rating).reachMs);
                  final s = IkkiuchiStrike(move, setup);
                  for (var t = s.liveFrom; t <= s.liveUntil; t += 0.5) {
                    final gap = gapToCards(setup.wrong, s.handAtTime(t)) - s.touch;
                    expect(gap, greaterThanOrEqualTo(IkkiuchiArmTuning.clearance * b.cards.cardW - 0.01),
                        reason: '$name ${landscape ? 'landscape' : 'portrait'} $rating seed $seed ${side.name} '
                            '${move.name} at $t');
                  }
                }
              }
            }
          }
        }
      }
    });
  });

  group("The board's layout", () {
    const eps = 1e-6;
    const pad = IkkiuchiBoardStyle.pad;

    // Each row's cards, left to right, by side and height.
    Iterable<List<CardBox>> rowsOf(IkkiuchiBoardLayout l) {
      final rows = <(IkkiuchiSide, double), List<CardBox>>{};
      for (final c in l.cards) {
        (rows[(c.side, (c.box.centre.y * 1000).roundToDouble())] ??= []).add(c.box);
      }
      return rows.values.map((r) => r..sort((a, b) => a.centre.x.compareTo(b.centre.x)));
    }

    test('both sides have one card size, grown until the board stops it', () {
      for (final MapEntry(key: name, value: size) in sizes.entries) {
        for (final landscape in [false, true]) {
          for (var seed = 0; seed < 40; seed++) {
            final l = layoutFor(seed, 1000 + 50.0 * seed, landscape: landscape, size: size);
            final why = '$name ${landscape ? 'landscape' : 'portrait'} seed $seed';
            final u = l.cardW;
            expect(l.cards.map((c) => 2 * c.box.hw), everyElement(closeTo(u, eps)), reason: '$why: one size');
            expect(u, lessThanOrEqualTo(IkkiuchiBoardStyle.maxCardW + eps));
            final lefts = l.cards.map((c) => c.box.centre.x - c.box.hw);
            final rights = l.cards.map((c) => c.box.centre.x + c.box.hw);
            final fieldW = rights.reduce(math.max) - lefts.reduce(math.min);
            expect(fieldW, lessThanOrEqualTo(IkkiuchiLayoutTuning.rowSlots * u + eps), reason: '$why: at most 16.5 cards wide');
            final centred = (lefts.reduce(math.min) + rights.reduce(math.max) - l.size.x).abs() < eps;
            final bool capped;
            if (landscape) {
              // The game column at the right edge, and left of it room for
              // a sent card, a card wide and its margins.
              final column = l.column!;
              final room = column.left - 2 * IkkiuchiSendStyle.wait.margin - u;
              expect(column.right, closeTo(l.size.x - IkkiuchiColumnStyle.edge, eps), reason: why);
              expect(rights.reduce(math.max), lessThanOrEqualTo(room + eps), reason: "$why: room for a sent card");
              expect(centred || (rights.reduce(math.max) - room).abs() < eps, isTrue,
                  reason: '$why: centred, or as far right as leaves that room');
              expect(l.wait.left, greaterThanOrEqualTo(rights.reduce(math.max) - eps), reason: '$why: right of the field');
              expect(l.wait.right, lessThanOrEqualTo(column.left + eps), reason: '$why: left of the column');
              capped = fieldW < room - pad - eps;
            } else {
              expect(l.column, isNull);
              expect(centred, isTrue, reason: '$why: centred');
              capped = fieldW < l.size.x - 2 * pad - eps;
            }
            if (!capped) expect(lefts.reduce(math.min), closeTo(pad, eps), reason: '$why: the field spans the board');
            var leastMiddle = double.infinity;
            for (final row in rowsOf(l)) {
              final gaps = [
                for (var i = 1; i < row.length; i++)
                  row[i].centre.x - row[i].hw - (row[i - 1].centre.x + row[i - 1].hw),
              ];
              expect(gaps, everyElement(greaterThanOrEqualTo(IkkiuchiFieldTuning.cardGap * u - eps)), reason: why);
              final middles = gaps.where((g) => g > IkkiuchiFieldTuning.cardGap * u + eps).toList();
              expect(middles.length, lessThanOrEqualTo(1), reason: '$why: one open middle a row');
              for (final g in middles) {
                expect(g, greaterThanOrEqualTo(IkkiuchiField.leastGap * u - eps), reason: '$why: groups apart');
                leastMiddle = math.min(leastMiddle, g);
              }
            }
            for (final c in l.cards) {
              final b = c.box;
              if (c.side == IkkiuchiSide.tobi) {
                expect(b.centre.y + b.hh, lessThanOrEqualTo(l.band.top + eps), reason: '$why: his cards above the band');
              } else {
                expect(b.centre.y - b.hh, greaterThanOrEqualTo(l.band.bottom - eps), reason: "$why: the player's below");
              }
            }
            final tops = l.cards.map((c) => c.box.centre.y - c.box.hh);
            final bottoms = l.cards.map((c) => c.box.centre.y + c.box.hh);
            final tobi = l.tobi;
            final tobiBox = Rect.fromLTWH(tobi.origin.x, tobi.origin.y, rig.size.x * tobi.k, rig.size.y * tobi.k);
            final bool tall;
            var tobiTight = false;
            if (landscape) {
              tall = (bottoms.reduce(math.max) - tops.reduce(math.min) - l.size.y).abs() < eps;
              expect(tops.reduce(math.min), greaterThanOrEqualTo(-eps), reason: '$why: on the board');
              expect(bottoms.reduce(math.max), lessThanOrEqualTo(l.size.y + eps), reason: '$why: on the board');
              for (final c in l.cards.where((c) => c.side == IkkiuchiSide.tobi)) {
                final b = c.box;
                final rect = Rect.fromCenter(center: Offset(b.centre.x, b.centre.y), width: 2 * b.hw, height: 2 * b.hh);
                expect(rect.overlaps(tobiBox), isFalse, reason: '$why: Tobi sits clear of his cards');
                final side = math.min((rect.left - tobiBox.right).abs(), (tobiBox.left - rect.right).abs());
                if ((side - IkkiuchiBoardStyle.tobiSideRoom * u).abs() < 1e-3) tobiTight = true;
              }
            } else {
              tall = (tops.reduce(math.min) - pad - IkkiuchiBoardStyle.tobiMinRoom).abs() < eps;
              expect(tobi.feet.y, lessThan(tops.reduce(math.min)), reason: '$why: Tobi stands above his side');
            }
            final wide = (leastMiddle - IkkiuchiField.leastGap * u).abs() < 1e-3;
            final widest = (u - IkkiuchiBoardStyle.maxCardW).abs() < eps;
            expect(tall || wide || tobiTight || widest, isTrue,
                reason: '$why: the cards grow until the field fills the height, a row closes, '
                    'Tobi has just his room, or they are as wide as they may be ($u)');
          }
        }
      }
    });

    test('the field is never wider than 16.5 cards, and spans the board when width limits the cards', () {
      for (final MapEntry(key: name, value: size) in sizes.entries) {
        for (final landscape in [false, true]) {
          var spans = false;
          for (var seed = 0; seed < 60; seed++) {
            final l = layoutFor(seed, 800 + 40.0 * seed, landscape: landscape, size: size);
            final lefts = l.cards.map((c) => c.box.centre.x - c.box.hw);
            final rights = l.cards.map((c) => c.box.centre.x + c.box.hw);
            final fieldW = rights.reduce(math.max) - lefts.reduce(math.min);
            expect(fieldW, lessThanOrEqualTo(IkkiuchiLayoutTuning.rowSlots * l.cardW + eps), reason: '$name $landscape $seed');
            if ((fieldW - (l.size.x - 2 * pad)).abs() < eps) spans = true;
          }
          if (name == 'phone' && !landscape) expect(spans, isTrue, reason: 'width-limited portrait boards are spanned');
        }
      }
    });

    test('landscape rows reach the top and bottom edges when the height limits the cards', () {
      final l = layoutFor(3, 2000, landscape: true);
      final tops = l.cards.map((c) => c.box.centre.y - c.box.hh);
      final bottoms = l.cards.map((c) => c.box.centre.y + c.box.hh);
      expect(tops.reduce(math.min), closeTo(0, eps));
      expect(bottoms.reduce(math.max), closeTo(l.size.y, eps));
      final tobi = l.tobi;
      expect(tobi.origin.y, greaterThanOrEqualTo(0), reason: 'Tobi on the board');
    });

    test('a small board has small cards and a large one its widest', () {
      for (final landscape in [false, true]) {
        final widths = {
          for (final MapEntry(:key, :value) in sizes.entries) key: layoutFor(3, 2000, landscape: landscape, size: value).cardW,
        };
        expect(widths['small']!, lessThan(widths['phone']!));
        expect(widths['large'], IkkiuchiBoardStyle.maxCardW);
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

    test('a card knocked across the band slides on into the other side and knocks a card there', () {
      final cards = IkkiuchiCards([
        (id: 1, side: IkkiuchiSide.player, box: const CardBox(Vec(200, 600), 19, 27)),
        (id: 2, side: IkkiuchiSide.tobi, box: const CardBox(Vec(200, 300), 19, 27, math.pi)),
      ], board: const Vec(384, 832), cardW: 38);
      for (var i = 0; i < 6; i++) {
        cards
          ..moveFinger(Vec(200, 660 - 20.0 * i), Vec(200, 640 - 20.0 * i))
          ..step();
      }
      cards.moveFinger(null, null);
      for (var i = 0; i < 600; i++) {
        cards.step();
      }
      expect(cards.card(1).box.centre.y, lessThan(450), reason: 'past the middle of the band');
      expect(cards.card(2).movedFrom(cards.card(2).home, dp: 1, radians: 0.01), isTrue);
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

    test("the finger strikes a card it passes in one step, and the board takes it off once it lifts", () {
      // The stroke goes from wholly left of the card to wholly right of it
      // in one step, so only a sweep along its way meets the card.
      const cardW = 38.0, y = 600.0;
      final cards = IkkiuchiCards([
        (id: 1, side: IkkiuchiSide.player, box: const CardBox(Vec(200, y), cardW / 2, 27)),
      ], board: const Vec(384, 832), cardW: cardW);
      final r = IkkiuchiPhysicsTuning.finger * cardW;
      cards.moveFinger(Vec(200 - cardW / 2 - r - 8, y), Vec(200 + cardW / 2 + r + 8, y));
      cards.step();
      expect(cards.fingerOn, isTrue);
      cards.moveFinger(null, null);
      for (var i = 0; i < 10; i++) {
        cards.step();
      }
      expect(cards.fingerOn, isFalse);
      expect(cards.card(1).box.centre.x, greaterThan(200 + cardW / 2), reason: 'knocked on, not passed through');

      final board = boardFor(1, 2000);
      final card = board.cards.cards.firstWhere((c) => c.side == IkkiuchiSide.player);
      final at = card.home.centre + Vec(0, -card.home.hh - r - 2);
      board.touch(at);
      expect(board.cards.fingerOn, isFalse, reason: 'on the board from the next advance');
      board.advance(step);
      expect(board.cards.fingerOn, isTrue);
      board.touch(at + Vec(0, 2 * card.home.hh));
      board.lift();
      board.advance(step * 4);
      expect(board.cards.fingerOn, isFalse, reason: 'off once it reached where it lifted');
      expect(card.movedFrom(card.home, dp: 1, radians: 0.01), isTrue, reason: 'it pushed the card it went through');
    });

    test('the cards stirred glide home the shortest way round and lie still there, one gone off the board too', () {
      const cardW = 38.0;
      final cards = IkkiuchiCards([
        (id: 1, side: IkkiuchiSide.player, box: const CardBox(Vec(200, 600), 19, 27)),
        (id: 2, side: IkkiuchiSide.player, box: const CardBox(Vec(100, 600), 19, 27)),
        (id: 3, side: IkkiuchiSide.player, box: const CardBox(Vec(300, 700), 19, 27, math.pi)),
      ], board: const Vec(384, 832), cardW: cardW);
      final gone = cards.card(1), knocked = cards.card(2), still = cards.card(3);
      // A fast stroke through card 1 sends it off the board's right edge.
      cards.moveFinger(const Vec(150, 600), const Vec(180, 600));
      for (var x = 180.0; x < 280; x += 30) {
        cards.step();
        cards.moveFinger(Vec(x, 600), Vec(x + 30, 600));
      }
      cards.moveFinger(const Vec(60, 640), const Vec(60, 640));
      cards.step();
      cards.moveFinger(const Vec(60, 640), const Vec(110, 560));
      cards.step();
      cards.moveFinger(null, null);
      for (var i = 0; i < 2000 && gone.onBoard; i++) {
        cards.step();
      }
      expect(gone.onBoard, isFalse, reason: 'knocked off the board');
      for (var i = 0; i < 240; i++) {
        cards.step();
      }
      expect(knocked.movedFrom(knocked.home, dp: 1, radians: 0.01), isTrue);
      final from = knocked.box;

      const ms = 100.0;
      cards.glideHome(ms: ms, ease: (t) => t);
      expect(cards.gliding, isTrue);
      expect(gone.onBoard, isTrue, reason: 'it comes back');
      for (var i = 0; i < ms / step / 2; i++) {
        cards.step();
      }
      final half = knocked.box;
      expect(half.centre.distanceTo(from.centre.lerp(knocked.home.centre, 0.5)), lessThan(1e-6), reason: 'halfway');
      expect(half.angle, closeTo(from.angle + turnBetween(from.angle, knocked.home.angle) / 2, 1e-9));
      for (var i = 0; i < ms / step / 2 + 1; i++) {
        cards.step();
      }
      expect(cards.gliding, isFalse);
      // Set down anew, a card lies at rest at home, though the sim wakes it
      // for a while. It keeps positions in single floats, as when the board
      // was set out.
      for (var i = 0; i < 60; i++) {
        cards.step();
      }
      for (final c in [gone, knocked, still]) {
        expect(c.box.centre.distanceTo(c.home.centre), lessThan(1e-3), reason: 'card ${c.id} home');
        expect(turnBetween(c.box.angle, c.home.angle).abs(), lessThan(1e-6), reason: 'card ${c.id} turned home');
        expect((c.velocity.length, c.spin), (0, 0), reason: 'card ${c.id} at rest');
        expect(c.onBoard, isTrue);
      }
      cards.moveFinger(const Vec(160, 600), const Vec(170, 600));
      for (var i = 0; i < 6; i++) {
        cards.step();
        cards.moveFinger(Vec(170 + 10.0 * i, 600), Vec(180 + 10.0 * i, 600));
      }
      expect(gone.movedFrom(gone.home, dp: 1, radians: 0.01), isTrue, reason: 'home, it is in the sim again');
    });

    test('a turn the shortest way round', () {
      expect(turnBetween(0, math.pi / 2), closeTo(math.pi / 2, 1e-12));
      expect(turnBetween(0, -math.pi / 2), closeTo(-math.pi / 2, 1e-12));
      expect(turnBetween(5 * math.pi + 0.1, math.pi), closeTo(-0.1, 1e-9));
      expect(turnBetween(-7 * math.pi / 2, 0), closeTo(-math.pi / 2, 1e-9));
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

    // The whole board scaled by [f]: Tobi, the cards and the board alike.
    IkkiuchiBoard scaled(IkkiuchiBoardLayout l, double f) => IkkiuchiBoard(
          tobi: TobiFrame(l.tobi.origin * f, l.tobi.k * f, rig),
          size: l.size * f,
          cards: [
            for (final c in l.cards)
              (id: c.id, side: c.side, box: CardBox(c.box.centre * f, c.box.hw * f, c.box.hh * f, c.box.angle)),
          ],
          cardW: l.cardW * f,
        );

    test('a strike plays alike at any card size: on the board scaled, it and its knocks scale too', () {
      for (final move in IkkiuchiMove.values) {
        final l = layoutFor(10 + move.index, 2000);
        final called = sideCard(l.board(), move.index.isEven ? IkkiuchiSide.player : IkkiuchiSide.tobi, 6);
        final one = scaled(l, 1);
        one.call(strikeAt(one, called, move, 300));
        playOut(one);
        for (final f in [0.5, 2.0]) {
          final why = '${move.name} at ${f}x';
          final board = scaled(l, f);
          board.call(strikeAt(board, called, move, 300));
          playOut(board);
          final a = one.runs.last.strike, b = board.runs.last.strike;
          for (var t = 0.0; t <= a.end; t += 10) {
            expect(b.handAtTime(t).distanceTo(a.handAtTime(t) * f), lessThan(1e-6 * f), reason: '$why: the hand at $t');
          }
          expect(board.faults.keys, one.faults.keys, reason: why);
          for (final c in one.cards.cards) {
            final d = board.cards.card(c.id);
            expect((d.taken, d.onBoard), (c.taken, c.onBoard), reason: '$why: card ${c.id}');
            if (!c.onBoard) continue;
            expect(d.box.centre.distanceTo(c.box.centre * f), lessThan(1e-3 * l.cardW * f), reason: '$why: card ${c.id}');
            expect(d.box.angle, closeTo(c.box.angle, 1e-3), reason: '$why: card ${c.id}');
          }
        }
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
      expect(board.faults, contains(touched));
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
  // each rating, with every move, in both layouts on small, phone and large
  // boards, half of them at the player's cards. None may touch a card on the side without the called
  // card, and the fist is never on the board on the way home. Cards knocked
  // across the band may move cards on the other side; those knocks are
  // never the fist's touches.
  test('clean strikes make no accidental faults and push nothing on the way home', () {
    const strikesPerCase = 4;
    var strikes = 0, accidental = 0, homePushes = 0, overCap = 0;
    final rows = <String>[];
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      for (final landscape in [false, true]) {
        for (final rating in ratings) {
          for (final move in IkkiuchiMove.values) {
            var caseFaults = 0;
            for (var i = 0; i < strikesPerCase; i++) {
              final seed = 100 * i + move.index;
              final board = boardFor(seed, rating, landscape: landscape, size: size);
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
              playOut(board, settle: 150, each: () {
                final run = board.runs.lastOrNull;
                if (run == null) return;
                final t = run.at(board.now);
                if (t > run.strike.liveUntil + step && board.cards.fistOn) homePushes++;
                for (final c in board.cards.fistTouched) {
                  if (!c.taken && c.velocity.length > board.cards.pushCap * 1.001) overCap++;
                }
              });
              strikes++;
              if (board.faults.isNotEmpty) caseFaults++;
            }
            accidental += caseFaults;
            rows.add('${name.padRight(5)} ${landscape ? 'landscape' : 'portrait '} ${rating.round().toString().padLeft(4)} '
                '${move.name.padRight(9)} faults $caseFaults/$strikesPerCase');
          }
        }
      }
    }
    // ignore: avoid_print
    print('$strikes clean strikes: $accidental accidental faults, $homePushes steps with the fist on the way home, '
        '$overCap pushes over the cap\n${rows.join('\n')}');
    expect(accidental, 0);
    expect(homePushes, 0);
    expect(overCap, 0);
  });
}
