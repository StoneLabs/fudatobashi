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

  group('score', () {
    AnkirenAnswer answer({int wrongTaps = 0, int? us, TapProximity? first, int? firstUs}) => AnkirenAnswer(
          poemId: 1,
          side: FieldSide.own,
          wrongTaps: wrongTaps,
          responseUs: us,
          at: DateTime(2026),
          firstTap: first ?? (wrongTaps == 0 && us != null ? TapProximity.card : null),
          firstTapUs: firstUs ?? (wrongTaps == 0 ? us : null),
        );
    int ms(int t) => t * 1000;

    test('first try: base points plus a speed bonus from slow to fast', () {
      const full = AnkirenTuning.firstTry + AnkirenTuning.speedMax;
      expect(AnkirenScore.points(answer(us: ms(50))), full);
      expect(AnkirenScore.points(answer(us: ms(AnkirenTuning.speedFull.inMilliseconds))), full);
      expect(AnkirenScore.points(answer(us: ms(AnkirenTuning.speedNone.inMilliseconds))), AnkirenTuning.firstTry);
      expect(AnkirenScore.points(answer(us: ms(20000))), AnkirenTuning.firstTry);
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
      expect(AnkirenScore.points(answer(us: 0)), AnkirenTuning.firstTry);
      expect(AnkirenScore.points(answer(us: -5000)), AnkirenTuning.firstTry);
      expect(answer(us: 0).validTime, isFalse);
      expect(answer(us: 1).validTime, isTrue);
    });

    test('the first tap\'s credit falls from the card itself to nothing on the other side', () {
      const credit = AnkirenTuning.firstTapCredit;
      expect(credit.keys, TapProximity.values, reason: 'every place has its share');
      expect(credit[TapProximity.card], 1);
      expect(credit[TapProximity.otherSide], 0);
      for (var i = 1; i < TapProximity.values.length; i++) {
        expect(credit[TapProximity.values[i]], lessThan(credit[TapProximity.values[i - 1]]!));
      }
    });

    test('found with the second tap: the first tap\'s share and a little more, speed bonus and all', () {
      final bonus = AnkirenScore.speedBonus(ms(300));
      for (final place in TapProximity.values.skip(1)) {
        final a = answer(wrongTaps: 1, us: ms(4000), first: place, firstUs: ms(300));
        expect(a.credit, AnkirenTuning.firstTapCredit[place]! + AnkirenTuning.secondTapShare);
        expect(AnkirenScore.points(a), ((AnkirenTuning.firstTry + bonus) * a.credit).round(), reason: place.name);
      }
      expect(AnkirenScore.points(answer(wrongTaps: 1, us: ms(4000), first: TapProximity.neighbour, firstUs: ms(300))),
          (188 * 0.7).round());
      expect(AnkirenScore.points(answer(wrongTaps: 1, us: ms(4000), first: TapProximity.otherSide, firstUs: ms(300))),
          (188 * 0.1).round());
    });

    test('the second tap: finding the card always beats missing it, never a find with the first tap', () {
      for (final place in TapProximity.values.skip(1)) {
        final found = AnkirenScore.credit(found: true, wrongTaps: 1, firstTap: place);
        expect(found, greaterThan(AnkirenScore.credit(found: true, wrongTaps: 2, firstTap: place)), reason: place.name);
        expect(found, greaterThan(AnkirenScore.credit(found: false, wrongTaps: 1, firstTap: place)),
            reason: place.name);
        expect(found, lessThan(AnkirenScore.credit(found: true, wrongTaps: 0, firstTap: TapProximity.card)));
      }
    });

    test('the speed bonus is timed at the first tap, not the find, and scaled by its share', () {
      int near(int firstMs, int foundMs) => AnkirenScore.points(
          answer(wrongTaps: 1, us: ms(foundMs), first: TapProximity.row, firstUs: ms(firstMs)));
      expect(near(300, 900), near(300, 9000), reason: 'the find\'s time does not count');
      expect(near(100, 5000), ((AnkirenTuning.firstTry + AnkirenTuning.speedMax) * 0.5).round());
      expect(near(5000, 5100), (AnkirenTuning.firstTry * 0.5).round());
      expect(near(0, 900), (AnkirenTuning.firstTry * 0.5).round(), reason: 'no measurement, no bonus');
    });

    test('shown, given up or never found earns nothing, however near the first tap', () {
      final shown = answer(wrongTaps: 2, us: ms(500), first: TapProximity.neighbour, firstUs: ms(200));
      expect(shown.revealed, isTrue);
      expect(AnkirenScore.points(shown), 0);
      final late = answer(wrongTaps: 5, us: ms(500), first: TapProximity.neighbour, firstUs: ms(200));
      expect(AnkirenScore.points(late), 0);
      final givenUp = answer(wrongTaps: 1, first: TapProximity.neighbour, firstUs: ms(200));
      expect((givenUp.found, givenUp.credit, AnkirenScore.points(givenUp)), (false, 0, 0));
      expect(AnkirenScore.points(answer()), 0);
      expect(answer().found, isFalse);
    });

    test('a game: total, max and fraction', () {
      final answers = [
        answer(us: ms(100)),
        answer(us: ms(3000)),
        answer(us: 0),
        answer(wrongTaps: 1, us: ms(1000), first: TapProximity.quadrant, firstUs: ms(1000)),
        answer(wrongTaps: 2, us: ms(1000), first: TapProximity.neighbour, firstUs: ms(500)),
        answer(),
      ];
      final s = AnkirenScore(answers, prompts: 6);
      expect(s.total, 200 + 116 + 100 + 55);
      expect(s.max, 6 * 200);
      expect(s.fraction, closeTo(471 / 1200, 1e-12));
      expect(AnkirenScore([], prompts: 0).fraction, 0);
    });
  });

  group('score: being ready early and the level', () {
    AnkirenAnswer found(int ms) => AnkirenAnswer(
        poemId: 1,
        side: FieldSide.own,
        wrongTaps: 0,
        responseUs: ms * 1000,
        at: DateTime(2026),
        firstTap: TapProximity.card,
        firstTapUs: ms * 1000);

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
      expect(AnkirenScore.points(a), 0);
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
      expect(AnkirenScore.points(g.answers.last), AnkirenTuning.firstTry);
    });

    test('the first tap is kept with each answer: where it landed and when', () {
      final g = newGame(perSide: 12)..startRecall();
      g.promptRevealed(t(0));
      final asked = g.current!;
      final wrong = other(g);
      g.tap(wrong, t(300));
      g.tap(other(g), t(600));
      g.tap(asked, t(900));
      g.promptRevealed(t(1000));
      g.tap(g.current!, t(1700));
      g.promptRevealed(t(2000));
      g.giveUp();
      g.promptRevealed(t(3000));
      g.tap(other(g), t(3400));
      g.giveUp();
      final [shown, first, untouched, missed, ...] = g.answers;
      expect((shown.firstTap, shown.firstTapUs), (g.field.proximity(asked, wrong), 300 * 1000));
      expect((first.firstTap, first.firstTapUs, first.responseUs), (TapProximity.card, 700 * 1000, 700 * 1000));
      expect((untouched.firstTap, untouched.firstTapUs), (null, null));
      expect(missed.firstTap, isNotNull);
      expect(missed.firstTapUs, 400 * 1000);
      expect([for (final a in [shown, untouched, missed]) AnkirenScore.points(a)], [0, 0, 0]);
    });

    test('found with the second tap, after a first tap next to the card', () {
      for (var seed = 1;; seed++) {
        final g = newGame(seed: seed, perSide: 12)..startRecall();
        g.promptRevealed(t(0));
        final asked = g.current!;
        final next = g.field.cards.where((c) => g.field.proximity(asked, c) == TapProximity.neighbour).firstOrNull;
        if (next == null) continue;
        expect(g.tap(next, t(300)), TapResult.wrong);
        expect(g.tap(asked, t(4000)), TapResult.right);
        final a = g.answers.single;
        expect((a.wrongTaps, a.firstTap, a.firstTapUs), (1, TapProximity.neighbour, 300 * 1000));
        expect(AnkirenScore.points(a), ((100 + 88) * 0.7).round());
        return;
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

    test('"don\'t know" gives the card up for nothing and asks the next; the game still completes', () {
      final g = newGame()..startRecall();
      expect(g.giveUp(), isNull, reason: 'the prompt is not on screen yet');
      g.promptRevealed(t(0));
      final first = g.current!;
      g.tap(other(g), t(300));
      expect(g.giveUp(), first);
      expect((g.isGivenUp(first), g.isFound(first), g.isDone(first)), (true, false, true));
      final a = g.answers.single;
      expect((a.poemId, a.found, a.responseUs, a.wrongTaps), (first, false, null, 1));
      expect(AnkirenScore.points(a), 0);
      expect((g.current, g.wrongTaps, g.revealTs), (g.prompts[1], 0, null));
      expect(g.giveUp(), isNull, reason: 'the next prompt is not on screen yet');
      g.promptRevealed(t(1000));
      expect(g.tap(first, t(1200)), TapResult.ignored, reason: 'a card given up is out of play');
      var now = 1000;
      while (g.phase == AnkirenPhase.recall) {
        g.promptRevealed(t(now += 1000));
        g.giveUp();
      }
      expect((g.phase, g.completed, g.score!.total), (AnkirenPhase.done, true, 0));
      expect(g.answers.map((a) => a.poemId), g.prompts);
    });

    test('ending early records the rest as never found and counts them as nothing', () {
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
      expect(g.score!.recall, 100 + 63);
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
