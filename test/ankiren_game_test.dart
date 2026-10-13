import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_rating.dart';
import 'package:fudatobashi/domain/ankiren_score.dart';
import 'package:fudatobashi/domain/rating.dart';

void main() {
  final dealer = AnkirenDealer(tomofuda: (_) => const [], kimarijiLength: (id) => 1 + id % 4);
  final known = [for (var id = 1; id <= 30; id++) id];

  const card = TapProximity.card, neighbour = TapProximity.neighbour, row = TapProximity.row;
  const quadrant = TapProximity.quadrant, side = TapProximity.side, otherSide = TapProximity.otherSide;
  int ms(int t) => t * 1000;
  AnkirenAnswer answer({int wrongTaps = 0, int? us, List<TapProximity> taps = const [], int? firstUs}) => AnkirenAnswer(
        poemId: 1,
        side: FieldSide.own,
        wrongTaps: wrongTaps,
        responseUs: us,
        at: DateTime(2026),
        taps: taps,
        firstTapUs: firstUs,
      );

  /// A card found with its first tap [t] ms after its prompt.
  AnkirenAnswer found(int t) => answer(us: ms(t), taps: const [card], firstUs: ms(t));

  /// A card's points for [taps], the first [firstMs] after its prompt.
  int points(List<TapProximity> taps, {int firstMs = 300}) => AnkirenScore.pointsOf(taps, ms(firstMs));
  const misses = [neighbour, row, quadrant, side, otherSide];

  group('score', () {
    test('first try: base points plus a speed bonus from slow to fast', () {
      const full = AnkirenTuning.cardPoints + AnkirenTuning.speedMax;
      expect(AnkirenScore.points(found(50)), full);
      expect(AnkirenScore.points(found(AnkirenTuning.speedFull.inMilliseconds)), full);
      expect(AnkirenScore.points(found(AnkirenTuning.speedNone.inMilliseconds)), AnkirenTuning.cardPoints);
      expect(AnkirenScore.points(found(20000)), AnkirenTuning.cardPoints);
    });

    test('a perfect game: the total follows the card count, the time left and the level', () {
      int total(int level, {int responseMs = 1000, Duration left = Duration.zero}) =>
          AnkirenScore.firstTryTotal(level, responseMs: responseMs.toDouble(), timeLeft: left);
      final top = AnkirenLevels.top;
      final topTime = AnkirenLevels.of(top).memorise;
      expect(total(top, responseMs: 100), AnkirenScore.maxFor(AnkirenLevels.of(top).cards));
      expect(total(top, left: topTime), (total(top) * (1 + AnkirenTuning.earlyBonus)).round());
      expect(total(top, left: const Duration(days: 1)), total(top, left: topTime));
      expect(total(top - 1, left: const Duration(minutes: 4)), lessThan(total(top)), reason: 'early < next level');
    });

    test('a level ended early never beats a harder one played in full within that time', () {
      int total(int level, Duration used) =>
          AnkirenScore.firstTryTotal(level, responseMs: 1000, timeLeft: AnkirenLevels.of(level).memorise - used);

      for (var l = 0; l < AnkirenLevels.top; l++) {
        for (var m = l + 1; m <= AnkirenLevels.top; m++) {
          final full = total(m, AnkirenLevels.of(m).memorise);
          for (var s = AnkirenLevels.of(m).memorise.inSeconds; s <= AnkirenLevels.of(l).memorise.inSeconds; s += 10) {
            expect(total(l, Duration(seconds: s)), lessThan(full), reason: 'level $l ended at ${s}s vs level $m full');
          }
        }
      }
    });

    test('the speed bonus is a smooth sigmoid through the fitted points, 0.1 s to 5 s', () {
      final at = {for (final t in [100, 300, 600, 1000, 3000, 5000]) t: AnkirenScore.speedBonus(ms(t))};
      expect(at, {100: 100, 300: 88, 600: 72, 1000: 56, 3000: 16, 5000: 0});
      // Within reach of the targets it was fitted to.
      for (final MapEntry(key: t, value: v) in AnkirenTuning.speedTargets.entries) {
        expect(at[t]! - v, inInclusiveRange(-6, 6), reason: '$t ms');
      }
      // Falling all the way, never in a jump: the share over every ms.
      var last = 1.0;
      for (var t = 1; t <= 6000; t++) {
        final share = AnkirenScore.speedShare(t.toDouble());
        expect(share, lessThanOrEqualTo(last));
        expect(last - share, lessThan(0.002), reason: 'at $t ms');
        last = share;
      }
      expect(AnkirenScore.speedShare(4900), inExclusiveRange(0, 0.02));
    });

    test('a time that is no measurement keeps the points but earns no speed bonus', () {
      expect(AnkirenScore.points(found(0)), AnkirenTuning.cardPoints);
      expect(AnkirenScore.points(answer(us: -5000, taps: const [card], firstUs: -5000)), AnkirenTuning.cardPoints);
      expect(found(0).validTime, isFalse);
      expect(answer(us: 1).validTime, isTrue);
    });

    test('the tiers fall from the card itself to nothing on the other side; the second tap counts a fifth', () {
      const share = AnkirenTuning.tapShare;
      expect(share.keys, TapProximity.values, reason: 'every place has its share');
      expect(share.values, [1, 0.6, 0.4, 0.25, 0.15, 0], reason: "the user's tiers");
      for (var i = 1; i < TapProximity.values.length; i++) {
        expect(share[TapProximity.values[i]], lessThan(share[TapProximity.values[i - 1]]!));
      }
      expect(AnkirenTuning.tapWeights, [1, 0.2], reason: 'two taps count, the second a fifth');
      expect(AnkirenTuning.tapWeights.length, lessThanOrEqualTo(AnkirenTuning.revealAfterWrong),
          reason: 'no tap on a card already shown counts');
    });

    test('the first tap: the card earns its points and speed; a miss its tier, with no speed', () {
      expect([for (final p in TapProximity.values) points([p], firstMs: 100)], [200, 60, 40, 25, 15, 0]);
      expect([for (final p in TapProximity.values) points([p], firstMs: 4000)],
          [100 + AnkirenScore.speedBonus(ms(4000)), 60, 40, 25, 15, 0]);
      expect([for (final p in TapProximity.values) AnkirenScore.speedWeight([p])], [1, 0, 0, 0, 0, 0]);
    });

    test('the second tap: a fifth of its tier, with no speed, right card or not', () {
      for (final first in misses) {
        for (final second in TapProximity.values) {
          final expected = (100 * AnkirenTuning.tapShare[first]! + 20 * AnkirenTuning.tapShare[second]!).round();
          expect(points([first, second]), expected, reason: '${first.name} then ${second.name}');
          expect(points([first, second], firstMs: 100), expected, reason: 'no speed bonus for a miss');
        }
      }
      expect(points([neighbour, card]), 60 + 20);
      expect(points([neighbour, neighbour]), 60 + 12);
      expect(points([row, card]), 40 + 20);
      expect(points([quadrant, side]), 25 + 3);
      expect(points([side, side]), 15 + 3);
      expect(points([otherSide, card]), 20);
      expect(points([otherSide, otherSide]), 0);
    });

    test('taps after the second add nothing', () {
      expect(AnkirenScore.share([neighbour, row, card]), AnkirenScore.share([neighbour, row]));
      expect(AnkirenScore.pointsOf([side, otherSide, card, card], ms(300)), points([side, otherSide]));
    });

    test('the most a card earns is a first tap on it at full speed; a miss first never reaches a find', () {
      const best = AnkirenTuning.cardPoints + AnkirenTuning.speedMax;
      final slowest = points([card], firstMs: 60000);
      expect(slowest, AnkirenTuning.cardPoints);
      for (final first in TapProximity.values) {
        expect(points([first], firstMs: 1), lessThanOrEqualTo(best));
        if (first == card) continue;
        for (final second in TapProximity.values) {
          expect(points([first, second], firstMs: 1), lessThan(slowest), reason: '${first.name} then ${second.name}');
          final weighted = AnkirenTuning.tapWeights[0] * AnkirenTuning.tapShare[first]! +
              AnkirenTuning.tapWeights[1] * AnkirenTuning.tapShare[second]!;
          expect(weighted, lessThan(AnkirenTuning.tapWeights[0] * AnkirenTuning.tapShare[card]!));
          if (second != card) expect(points([first, card]), greaterThan(points([first, second])));
          expect(points([first, second]), greaterThanOrEqualTo(points([first])),
              reason: 'giving up after a tap never beats going on');
        }
      }
      expect(points([neighbour, card]), 80, reason: 'the best a miss first can do');
    });

    test('shown, given up or never found: the taps made still count', () {
      final shown = answer(wrongTaps: 2, us: ms(900), taps: const [neighbour, row], firstUs: ms(200));
      expect(shown.revealed, isTrue);
      expect(AnkirenScore.points(shown), 60 + 8);
      final givenUpAfterOne = answer(wrongTaps: 1, taps: const [quadrant], firstUs: ms(200));
      expect((givenUpAfterOne.found, AnkirenScore.points(givenUpAfterOne)), (false, 25));
      final givenUpAfterTwo = answer(wrongTaps: 2, taps: const [side, neighbour], firstUs: ms(200));
      expect(AnkirenScore.points(givenUpAfterTwo), 15 + 12);
      expect(AnkirenScore.points(answer()), 0, reason: 'given up or never found with no tap');
      expect(answer().found, isFalse);
    });

    test('a game: total, max and fraction', () {
      final answers = [
        found(100),
        found(3000),
        found(0),
        answer(wrongTaps: 1, us: ms(1000), taps: const [quadrant, card], firstUs: ms(400)),
        answer(wrongTaps: 2, us: ms(1000), taps: const [neighbour, side], firstUs: ms(500)),
        answer(),
      ];
      final s = AnkirenScore(answers, prompts: 6);
      expect(s.total, 200 + 116 + 100 + 45 + 63);
      expect(s.max, 6 * 200);
      expect(s.fraction, closeTo(524 / 1200, 1e-12));
      expect(AnkirenScore([], prompts: 0).fraction, 0);
    });
  });

  group('score: being ready early and the level', () {
    test('recall points make the fraction; time left and the level scale the score', () {
      final answers = [found(100), found(1000)];
      final plain = AnkirenScore(answers, prompts: 2);
      expect((plain.recall, plain.maxRecall, plain.total, plain.max, plain.early), (356, 400, 356, 400, 0));
      final quick = AnkirenScore(answers, prompts: 2, timeLeft: 0.5, factor: 0.85);
      expect(quick.fraction, plain.fraction, reason: 'the rating reads recall only');
      expect(quick.total, (356 * (1 + AnkirenTuning.earlyBonus * 0.5) * 0.85).round());
      expect(quick.max, (400 * 0.85).round());
      expect(quick.early, quick.total - (356 * 0.85).round());
      expect(AnkirenScore([], prompts: 2, timeLeft: 1).total, 0, reason: 'nothing found, nothing to multiply');
    });

    test('each level below the top counts less', () {
      expect(AnkirenScore.factorFor(AnkirenLevels.top), 1);
      for (var l = 1; l <= AnkirenLevels.top; l++) {
        expect(AnkirenScore.factorFor(l - 1), closeTo(AnkirenScore.factorFor(l) * AnkirenTuning.levelFactor, 1e-12));
      }
    });

    test("being ready early at a level never beats the next level's shorter time played in full", () {
      // The same recall at each: level a ended at level b's memorise time
      // against level b played to its end.
      for (var a = 0; a < AnkirenLevels.top; a++) {
        for (var b = a + 1; b <= AnkirenLevels.top; b++) {
          final (la, lb) = (AnkirenLevels.of(a), AnkirenLevels.of(b));
          if (lb.memorise >= la.memorise) continue;
          final timeLeft = 1 - lb.memorise.inSeconds / la.memorise.inSeconds;
          final early = la.cards * AnkirenScore.factorFor(a) * (1 + AnkirenTuning.earlyBonus * timeLeft);
          final full = lb.cards * AnkirenScore.factorFor(b);
          expect(early, lessThanOrEqualTo(full), reason: 'level $a ended at level $b\'s time');
        }
      }
    });
  });

  group('rating', () {
    const ratings = AnkirenRatingModel.levelRatings;

    test('one difficulty per level; play starts at level 0, in 入門', () {
      expect(ratings.length, AnkirenLevels.all.length);
      for (var l = 1; l < ratings.length; l++) {
        expect(ratings[l] - ratings[l - 1], 250);
      }
      expect(AnkirenRating.start, ratings.first);
      expect(Rating.bandOf(AnkirenRating.start).label, '入門');
      expect(AnkirenRating.levelFor(AnkirenRating.start, maxLevel: 10), 0);
    });

    test('the level is the highest one the rating has reached, capped by the known cards', () {
      expect(AnkirenRating.levelFor(649, maxLevel: 10), 0);
      expect(AnkirenRating.levelFor(650, maxLevel: 10), 1);
      expect(AnkirenRating.levelFor(2899, maxLevel: 10), 9);
      expect(AnkirenRating.levelFor(2900, maxLevel: 10), 10);
      expect(AnkirenRating.levelFor(5000, maxLevel: 10), 10);
      expect(AnkirenRating.levelFor(2000, maxLevel: 4), 4);
      expect(AnkirenRating.levelFor(100, maxLevel: 4), 0);
      var last = 0;
      for (var r = 0.0; r < 3500; r += 1) {
        final l = AnkirenRating.levelFor(r, maxLevel: 10);
        expect(l - last, inInclusiveRange(0, 1), reason: 'one step at a time, at $r');
        last = l;
      }
    });

    test('placement: a perfect player climbs to level 9 in three games', () {
      var r = AnkirenRating.start;
      for (var game = 0; game < AnkirenRatingModel.placementGames; game++) {
        final level = AnkirenRating.levelFor(r, maxLevel: 10);
        final p = AnkirenRating.performance(level, 1, placement: AnkirenRating.isPlacement(game));
        final next = AnkirenRating.update(r, p, game);
        expect(next, greaterThan(r));
        r = next;
      }
      expect(AnkirenRating.levelFor(r, maxLevel: 10), 9);
      expect(AnkirenRating.isPlacement(AnkirenRatingModel.placementGames), isFalse);
    });

    test('a game at par holds the level, during placement and after', () {
      for (var level = 0; level <= 10; level++) {
        for (final games in [0, 10]) {
          final placement = AnkirenRating.isPlacement(games);
          final p = AnkirenRating.performance(level, AnkirenRatingModel.par, placement: placement);
          expect(AnkirenRating.update(ratings[level], p, games), ratings[level]);
          var r = ratings[level] + 200;
          for (var i = 0; i < 20; i++) {
            r = AnkirenRating.update(r, p, games);
            expect(AnkirenRating.levelFor(r, maxLevel: 10), level);
          }
        }
      }
    });

    test('par is the score of the game its tuning describes', () {
      // 70 cards in 100 found with the first tap in 1.5 s, 10 with the
      // second after a first tap in their row, and 20 tapped twice
      // elsewhere on their side.
      final answers = [
        for (var i = 0; i < 70; i++) found(1500),
        for (var i = 0; i < 10; i++) answer(wrongTaps: 1, us: ms(3000), taps: const [row, card], firstUs: ms(1500)),
        for (var i = 0; i < 20; i++) answer(wrongTaps: 2, taps: const [side, side], firstUs: ms(2000)),
      ];
      expect(AnkirenScore(answers, prompts: 100).fraction, closeTo(AnkirenRatingModel.par, 0.005));
    });

    test('near misses rate above giving up, and below finding the card', () {
      double performance(List<AnkirenAnswer> misses) => AnkirenRating.performance(
          5, AnkirenScore([for (var i = 0; i < 8; i++) found(1500), ...misses], prompts: 10).fraction,
          placement: false);
      final givenUp = performance([answer(), answer()]);
      final near = performance([
        answer(wrongTaps: 1, taps: const [neighbour], firstUs: ms(900)),
        answer(wrongTaps: 2, taps: const [quadrant, side], firstUs: ms(900)),
      ]);
      final secondTap = performance([
        for (var i = 0; i < 2; i++) answer(wrongTaps: 1, us: ms(2000), taps: const [neighbour, card], firstUs: ms(900)),
      ]);
      final firstTap = performance([found(1500), found(1500)]);
      expect(givenUp, lessThan(near));
      expect(near, lessThan(secondTap));
      expect(secondTap, lessThan(firstTap));
      expect(near - givenUp, lessThan(AnkirenRatingModel.levelRatings[1] - AnkirenRatingModel.levelRatings[0]),
          reason: 'two near misses in ten cards move a game less than a level');
    });

    test('the rating never drops below the start', () {
      var r = ratings[3];
      for (var game = 0; game < 30; game++) {
        final level = AnkirenRating.levelFor(r, maxLevel: 10);
        final p = AnkirenRating.performance(level, 0, placement: AnkirenRating.isPlacement(game));
        r = AnkirenRating.update(r, p, game);
        expect(r, greaterThanOrEqualTo(AnkirenRating.start));
      }
      expect(r, AnkirenRating.start);
    });

    test('established games move the rating less, and it stays continuous', () {
      final p = AnkirenRating.performance(5, 0.9, placement: false);
      final placed = AnkirenRating.update(ratings[5], p, 0) - ratings[5];
      final established = AnkirenRating.update(ratings[5], p, 10) - ratings[5];
      expect(established, greaterThan(0));
      expect(established, lessThan(placed));
      expect(AnkirenRating.performance(5, 0.9, placement: true) - ratings[5],
          closeTo(AnkirenRatingModel.placementStretch * (p - ratings[5]), 1e-9));
      for (var f = 0.0; f < 1; f += 0.01) {
        final step = AnkirenRating.performance(5, f + 0.001, placement: false) -
            AnkirenRating.performance(5, f, placement: false);
        expect(step, inExclusiveRange(0, 2));
      }
    });
  });

  group('game', () {
    /// A game scored like the top level, at [perSide] cards a side.
    AnkirenGame newGame({int seed = 1, int perSide = 4, bool custom = false}) {
      final f = dealer.deal(known, perSide, math.Random(seed));
      const memorise = Duration(seconds: 20);
      return AnkirenGame(
        field: f,
        setup: custom
            ? AnkirenSetup.custom(perSide: perSide, memorise: memorise)
            : AnkirenSetup(perSide: perSide, memorise: memorise, level: AnkirenLevels.top),
        rng: math.Random(seed),
        clock: () => DateTime(2026, 10, 12),
      );
    }

    Duration t(int ms) => Duration(milliseconds: ms);
    int other(AnkirenGame g) => g.field.cards.firstWhere((c) => c != g.current && !g.isFound(c));

    test('ready early: the share of the memorise time left counts; out of time, none', () {
      final g = newGame()..startRecall(memorised: const Duration(seconds: 5));
      expect((g.memorised, g.timeLeft, g.score!.timeLeft), (const Duration(seconds: 5), 0.75, 0.75));
      final h = newGame()..startRecall();
      expect((h.memorised, h.timeLeft), (h.setup.memorise, 0.0));
      expect((newGame()..startRecall(memorised: const Duration(minutes: 5))).timeLeft, 0);
    });

    test('every field card is asked once, in a seeded random order', () {
      final g = newGame(perSide: 12);
      expect(g.prompts.toSet(), g.field.cards.toSet());
      expect(g.prompts.length, g.field.cards.length);
      expect(g.prompts, newGame(perSide: 12).prompts);
      expect(g.prompts, isNot(g.field.cards), reason: 'shuffled');
      expect(newGame(seed: 2, perSide: 12).prompts, isNot(g.prompts));
    });

    test('memorise, then recall: taps count only once a prompt is on screen', () {
      final g = newGame();
      expect((g.phase, g.current), (AnkirenPhase.memorise, null));
      expect(g.tap(g.prompts.first, t(10)), TapResult.ignored);
      g.startRecall();
      expect((g.phase, g.current), (AnkirenPhase.recall, g.prompts.first));
      expect(g.tap(g.current!, t(20)), TapResult.ignored, reason: 'the prompt is not on screen yet');
      g.promptRevealed(t(100));
      g.promptRevealed(t(400));
      expect(g.tap(999, t(500)), TapResult.ignored, reason: 'not a field card');
      expect(g.tap(g.current!, t(3000)), TapResult.right);
      final a = g.answers.single;
      expect(a.responseUs, 2900 * 1000, reason: 'from the first reveal');
      expect((a.side, a.at), (g.field.sideOf(g.prompts.first), DateTime(2026, 10, 12)));
      expect(AnkirenScore.points(a), 100 + 17);
      expect(g.current, g.prompts[1]);
      expect(g.tap(g.prompts[1], t(1700)), TapResult.ignored, reason: 'the next prompt is not on screen yet');
    });

    test('a press that began before the prompt was on screen answers nothing', () {
      final g = newGame()..startRecall();
      g.promptRevealed(t(100));
      expect(g.tap(other(g), t(99)), TapResult.ignored, reason: 'not a wrong tap');
      expect(g.tap(g.current!, t(50)), TapResult.ignored, reason: 'not a find');
      expect(g.wrongTaps, 0);
      expect(g.answers, isEmpty);
      expect(g.tap(g.current!, t(100)), TapResult.right, reason: 'a press after the reveal counts');
    });

    test('a wrong tap does not move on; the second one reveals the card, which must still be tapped', () {
      final g = newGame()..startRecall();
      g.promptRevealed(t(0));
      final asked = g.current!;
      expect(g.tap(other(g), t(300)), TapResult.wrong);
      expect((g.current, g.wrongTaps, g.revealed), (asked, 1, false));
      expect(g.tap(other(g), t(600)), TapResult.wrong);
      expect((g.current, g.wrongTaps, g.revealed), (asked, 2, true));
      expect(g.tap(asked, t(900)), TapResult.right);
      final a = g.answers.single;
      expect((a.poemId, a.wrongTaps, a.responseUs, a.revealed), (asked, 2, 900 * 1000, true));
      expect(a.taps, hasLength(AnkirenTuning.tapWeights.length),
          reason: 'the third tap, on the card shown, is not kept');
      expect(AnkirenScore.points(a), AnkirenScore.pointsOf(a.taps, 300 * 1000));
      expect(a.taps, isNot(contains(TapProximity.card)));
      expect((g.wrongTaps, g.revealed), (0, false));
    });

    test('a found card ignores taps; a tap at or before the reveal is no time', () {
      final g = newGame()..startRecall();
      g.promptRevealed(t(0));
      final first = g.current!;
      g.tap(first, t(700));
      g.promptRevealed(t(1000));
      expect(g.tap(first, t(1100)), TapResult.ignored);
      expect(g.wrongTaps, 0);
      expect(g.tap(g.current!, t(1000)), TapResult.right);
      expect(g.answers.last.responseUs, 0);
      expect(g.answers.last.validTime, isFalse);
      expect(AnkirenScore.points(g.answers.last), AnkirenTuning.cardPoints);
    });

    test('each answer keeps where its taps landed, measured from the card asked, and the first one\'s time', () {
      final g = newGame(perSide: 12)..startRecall();
      g.promptRevealed(t(0));
      final asked = g.current!;
      final wrong = other(g);
      g.tap(wrong, t(300));
      final second = g.field.cards.lastWhere((c) => c != asked && c != wrong);
      g.tap(second, t(600));
      g.tap(asked, t(900));
      g.promptRevealed(t(1000));
      g.tap(g.current!, t(1700));
      g.promptRevealed(t(2000));
      g.giveUp();
      g.promptRevealed(t(3000));
      final missedAsked = g.current!;
      final missedTap = other(g);
      g.tap(missedTap, t(3400));
      g.giveUp();
      final [shown, first, untouched, missed, ...] = g.answers;
      expect(shown.taps, [g.field.proximity(asked, wrong), g.field.proximity(asked, second)]);
      expect(shown.firstTapUs, 300 * 1000);
      expect([first.taps, first.firstTapUs, first.responseUs], [[TapProximity.card], 700 * 1000, 700 * 1000]);
      expect([untouched.taps, untouched.firstTapUs], [isEmpty, null]);
      expect([missed.taps, missed.firstTapUs], [[g.field.proximity(missedAsked, missedTap)], 400 * 1000]);
      expect([for (final a in [shown, untouched, missed]) AnkirenScore.points(a)], [
        AnkirenScore.pointsOf(shown.taps, null),
        0,
        (100 * AnkirenTuning.tapShare[missed.taps.single]!).round(),
      ]);
    });

    test('found with the second tap, after a first tap next to the card: 60 + a fifth of 100', () {
      for (var seed = 1;; seed++) {
        final g = newGame(seed: seed, perSide: 12)..startRecall();
        g.promptRevealed(t(0));
        final asked = g.current!;
        final next = g.field.cards.where((c) => g.field.proximity(asked, c) == TapProximity.neighbour).firstOrNull;
        if (next == null) continue;
        expect(g.tap(next, t(100)), TapResult.wrong);
        expect(g.tap(asked, t(400)), TapResult.right);
        final a = g.answers.single;
        expect([a.wrongTaps, a.taps, a.firstTapUs], [1, [neighbour, card], 100 * 1000]);
        expect(AnkirenScore.points(a), 80, reason: 'neither tap earns a speed bonus');
        return;
      }
    });

    test('a card found on the third tap or later scores its first two taps, not nothing', () {
      for (var seed = 1;; seed++) {
        final g = newGame(seed: seed, perSide: 12)..startRecall();
        g.promptRevealed(t(0));
        final asked = g.current!;
        final f = g.field;
        final near = f.cards.where((c) => f.proximity(asked, c) == neighbour).firstOrNull;
        final far = f.cards.where((c) => f.proximity(asked, c) == otherSide).firstOrNull;
        if (near == null || far == null) continue;
        g.tap(near, t(300));
        g.tap(far, t(600));
        expect(g.revealed, isTrue, reason: 'the card shakes');
        g.tap(far, t(800));
        expect(g.tap(asked, t(1200)), TapResult.right);
        final a = g.answers.single;
        expect([a.wrongTaps, a.found, a.taps], [3, true, [neighbour, otherSide]]);
        expect(AnkirenScore.points(a), 60, reason: 'the shown card and the tap before it add nothing');
        return;
      }
    });

    test('the same wrong card tapped twice counts as both taps, and shows the card', () {
      final g = newGame(perSide: 12)..startRecall();
      g.promptRevealed(t(0));
      final asked = g.current!;
      final wrong = other(g);
      final place = g.field.proximity(asked, wrong);
      expect(g.tap(wrong, t(300)), TapResult.wrong);
      expect(g.tap(wrong, t(500)), TapResult.wrong);
      expect((g.wrongTaps, g.revealed), (2, true));
      g.tap(asked, t(900));
      final a = g.answers.single;
      expect(a.taps, [place, place]);
      expect(AnkirenScore.points(a), (120 * AnkirenTuning.tapShare[place]!).round());
    });

    test('every tier counts on either tap, for cluster cards, middle cards and a beginner field', () {
      AnkirenRow r(List<int> left, [List<int> middle = const [], List<int> right = const []]) =>
          AnkirenRow(left: left, middle: middle, right: right);
      // Own side, from 下段: 1 2 3 | 4 5, then 6 7 | 8, then 9 [10 11] 12 13
      // with 10 and 11 in the open middle of 上段. Opponent: 21 22 | 23.
      final clustered = AnkirenField(
        own: AnkirenHalf([r([1, 2, 3], [], [4, 5]), r([6, 7], [], [8]), r([9], [10, 11], [12, 13])]),
        opponent: AnkirenHalf([r([21, 22], [], [23]), r([]), r([])]),
      );
      final beginner = AnkirenField(
        own: AnkirenHalf([r([]), r([]), r([], [31, 32, 33, 34])]),
        opponent: AnkirenHalf([r([]), r([]), r([], [41, 42, 43])]),
      );
      // [asked]'s answer in a game on [field] where it is asked first and
      // [taps] are made, the first 300 ms after the prompt; given up unless
      // they find it.
      AnkirenAnswer play(AnkirenField field, int asked, List<int> taps) {
        final setup = AnkirenSetup(perSide: field.perSide, memorise: const Duration(minutes: 1), level: 0);
        var seed = 0;
        AnkirenGame g;
        do {
          g = AnkirenGame(field: field, setup: setup, rng: math.Random(seed++));
        } while (g.prompts.first != asked);
        g
          ..startRecall()
          ..promptRevealed(t(0));
        for (final (i, c) in taps.indexed) {
          g.tap(c, t(300 + 400 * i));
        }
        if (g.answers.isEmpty) g.giveUp();
        return g.answers.single;
      }

      final cases = [
        (clustered, 2, [2], [card], 188),
        (clustered, 2, [1, 2], [neighbour, card], 60 + 20),
        (clustered, 1, [3, 7], [row, quadrant], 40 + 5),
        (clustered, 2, [6, 4], [quadrant, side], 25 + 3),
        (clustered, 2, [21, 22], [otherSide, otherSide], 0),
        (clustered, 2, [10, 2], [side, card], 15 + 20),
        (clustered, 10, [11, 12], [row, row], 40 + 8),
        (clustered, 10, [4, 10], [side, card], 15 + 20),
        (clustered, 10, [23, 9], [otherSide, row], 8),
        (clustered, 12, [11, 13], [side, neighbour], 15 + 12),
        (clustered, 22, [21, 23, 22], [neighbour, side], 60 + 3),
        (beginner, 32, [31, 34], [neighbour, row], 60 + 8),
        (beginner, 32, [41, 32], [otherSide, card], 20),
        (beginner, 41, [43], [row], 40),
      ];
      for (final (field, asked, taps, places, points) in cases) {
        final a = play(field, asked, taps);
        expect([a.taps, AnkirenScore.points(a)], [places, points], reason: 'asked $asked, tapped $taps');
      }
    });

    test('a custom setup is not scored; its finds and times still are counted', () {
      final g = newGame(custom: true)..startRecall();
      g.promptRevealed(t(0));
      g.tap(g.current!, t(600));
      g.promptRevealed(t(1000));
      g.tap(other(g), t(1300));
      g.tap(g.current!, t(1500));
      g.promptRevealed(t(2000));
      g.tap(g.current!, t(3000));
      g.end();
      expect(g.score, isNull);
      expect((g.firstTries, g.averageFirstTryMs), (2, (600 + 1000) / 2));
      expect(newGame().averageFirstTryMs, isNull);
    });

    test('finding every card completes the game; then every tap is ignored', () {
      final g = newGame();
      var notified = 0;
      g.addListener(() => notified++);
      g.startRecall();
      var now = 0;
      while (g.phase == AnkirenPhase.recall) {
        g.promptRevealed(t(now += 1000));
        expect(g.tap(g.current!, t(now += 500)), TapResult.right);
      }
      expect((g.phase, g.completed, g.current), (AnkirenPhase.done, true, null));
      expect(g.answers.map((a) => a.poemId), g.prompts);
      expect(g.score!.recall, g.prompts.length * (100 + 77));
      expect(g.score!.fraction, closeTo(177 / 200, 1e-12));
      expect(g.tap(g.prompts.first, t(now + 100)), TapResult.ignored);
      expect(notified, 1 + g.prompts.length);
    });

    test('"don\'t know" gives the card up, keeping its taps, and asks the next; the game still completes', () {
      final g = newGame()..startRecall();
      expect(g.giveUp(), isNull, reason: 'the prompt is not on screen yet');
      g.promptRevealed(t(0));
      final first = g.current!;
      g.tap(other(g), t(300));
      expect(g.giveUp(), first);
      expect((g.isGivenUp(first), g.isFound(first), g.isDone(first)), (true, false, true));
      final a = g.answers.single;
      expect((a.poemId, a.found, a.responseUs, a.wrongTaps), (first, false, null, 1));
      expect(AnkirenScore.points(a), (100 * AnkirenTuning.tapShare[a.taps.single]!).round(),
          reason: 'its tap still counts');
      expect((g.current, g.wrongTaps, g.revealTs), (g.prompts[1], 0, null));
      expect(g.giveUp(), isNull, reason: 'the next prompt is not on screen yet');
      g.promptRevealed(t(1000));
      expect(g.tap(first, t(1200)), TapResult.ignored, reason: 'a card given up is out of play');
      var now = 1000;
      while (g.phase == AnkirenPhase.recall) {
        g.promptRevealed(t(now += 1000));
        g.giveUp();
      }
      expect((g.phase, g.completed, g.score!.recall), (AnkirenPhase.done, true, AnkirenScore.points(a)));
      expect(g.answers.map((a) => a.poemId), g.prompts);
    });

    test('ending early: the card asked keeps its taps, the rest were never reached and earn nothing', () {
      final g = newGame()..startRecall();
      g.promptRevealed(t(0));
      g.tap(g.current!, t(800));
      g.promptRevealed(t(2000));
      g.tap(other(g), t(2500));
      g.end();
      expect((g.phase, g.completed, g.current), (AnkirenPhase.done, false, null));
      expect(g.answers.length, g.prompts.length);
      expect(g.answers.map((a) => a.poemId), g.prompts);
      expect(g.answers.skip(1).every((a) => !a.found && a.responseUs == null), isTrue);
      expect(g.answers[1].wrongTaps, 1, reason: 'the prompt on screen keeps its wrong tap');
      expect(g.answers.skip(2).every((a) => a.taps.isEmpty), isTrue, reason: 'cards never reached');
      expect(g.score!.recall, 100 + 63 + AnkirenScore.points(g.answers[1]));
      expect([for (final a in g.answers.skip(2)) AnkirenScore.points(a)], everyElement(0));
      expect(g.tap(g.prompts.last, t(3000)), TapResult.ignored);
    });

    test('ending during memorise leaves every prompt unanswered', () {
      final g = newGame()..end();
      expect(g.answers.length, g.prompts.length);
      expect(g.answers.any((a) => a.found), isFalse);
      expect(g.score!.total, 0);
      g.startRecall();
      expect(g.phase, AnkirenPhase.done);
    });
  });
}
