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
    AnkirenAnswer answer({int wrongTaps = 0, int? us}) =>
        AnkirenAnswer(poemId: 1, side: FieldSide.own, wrongTaps: wrongTaps, responseUs: us, at: DateTime(2026));
    int ms(int t) => t * 1000;

    test('first try: base points plus a speed bonus from slow to fast', () {
      const full = AnkirenTuning.firstTry + AnkirenTuning.speedMax;
      expect(AnkirenScore.points(answer(us: ms(50))), full);
      expect(AnkirenScore.points(answer(us: ms(AnkirenTuning.speedFull.inMilliseconds))), full);
      expect(AnkirenScore.points(answer(us: ms(AnkirenTuning.speedNone.inMilliseconds))), AnkirenTuning.firstTry);
      expect(AnkirenScore.points(answer(us: ms(20000))), AnkirenTuning.firstTry);
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

    test('second try earns a quarter of the best and no bonus; revealed or never found earns nothing', () {
      expect(AnkirenTuning.secondTry * 4, AnkirenTuning.firstTry + AnkirenTuning.speedMax);
      expect(AnkirenScore.points(answer(wrongTaps: 1, us: ms(500))), AnkirenTuning.secondTry);
      expect(AnkirenScore.points(answer(wrongTaps: 2, us: ms(500))), 0);
      expect(answer(wrongTaps: 2, us: ms(500)).revealed, isTrue);
      expect(AnkirenScore.points(answer(wrongTaps: 5, us: ms(500))), 0);
      expect(AnkirenScore.points(answer()), 0);
      expect(answer().found, isFalse);
    });

    test('a game: total, max, fraction and the first-try summary', () {
      final answers = [
        answer(us: ms(100)),
        answer(us: ms(3000)),
        answer(us: 0),
        answer(wrongTaps: 1, us: ms(1000)),
        answer(wrongTaps: 2, us: ms(1000)),
        answer(),
      ];
      final s = AnkirenScore(answers, prompts: 6);
      expect(s.total, 200 + 116 + 100 + 50);
      expect(s.max, 6 * 200);
      expect(s.fraction, closeTo(466 / 1200, 1e-12));
      expect(s.firstTries, 3);
      expect(s.averageFirstTryMs, closeTo((100 + 3000) / 2, 1e-9), reason: 'valid times only');
      expect(AnkirenScore([], prompts: 6).averageFirstTryMs, isNull);
      expect(AnkirenScore([], prompts: 0).fraction, 0);
    });
  });

  group('score: being ready early and the level', () {
    AnkirenAnswer found(int ms) =>
        AnkirenAnswer(poemId: 1, side: FieldSide.own, wrongTaps: 0, responseUs: ms * 1000, at: DateTime(2026));

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

    test('each level below the top counts less; a custom setup like the hardest level it matches', () {
      expect(AnkirenScore.factorFor(AnkirenSetup.forLevel(AnkirenLevels.top)), 1);
      for (var l = 1; l <= AnkirenLevels.top; l++) {
        expect(AnkirenScore.factorFor(AnkirenSetup.forLevel(l - 1)),
            closeTo(AnkirenScore.factorFor(AnkirenSetup.forLevel(l)) * AnkirenTuning.levelFactor, 1e-12));
      }
      double custom(int perSide, int seconds) =>
          AnkirenScore.factorFor(AnkirenSetup.custom(perSide: perSide, memorise: Duration(seconds: seconds)));
      expect(custom(25, 900), AnkirenScore.factorFor(AnkirenSetup.forLevel(8)));
      expect(custom(25, 300), 1);
      expect(custom(2, 900), AnkirenScore.factorFor(AnkirenSetup.forLevel(0)));
    });

    test("being ready early at a level never beats the next level's shorter time played in full", () {
      // The same recall at each: level a ended at level b's memorise time
      // against level b played to its end.
      for (var a = 0; a < AnkirenLevels.top; a++) {
        for (var b = a + 1; b <= AnkirenLevels.top; b++) {
          final (la, lb) = (AnkirenLevels.of(a), AnkirenLevels.of(b));
          if (lb.memorise >= la.memorise) continue;
          final timeLeft = 1 - lb.memorise.inSeconds / la.memorise.inSeconds;
          final early = la.cards * AnkirenScore.factorFor(AnkirenSetup.forLevel(a)) * (1 + AnkirenTuning.earlyBonus * timeLeft);
          final full = lb.cards * AnkirenScore.factorFor(AnkirenSetup.forLevel(b));
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
    AnkirenGame newGame({int seed = 1, int perSide = 4}) {
      final f = dealer.deal(known, perSide, math.Random(seed));
      return AnkirenGame(
        field: f,
        setup: AnkirenSetup.custom(perSide: perSide, memorise: const Duration(seconds: 20)),
        rng: math.Random(seed),
        clock: () => DateTime(2026, 10, 12),
      );
    }

    Duration t(int ms) => Duration(milliseconds: ms);
    int other(AnkirenGame g) => g.field.cards.firstWhere((c) => c != g.current && !g.isFound(c));

    test('ready early: the share of the memorise time left counts; out of time, none', () {
      final g = newGame()..startRecall(memorised: const Duration(seconds: 5));
      expect((g.memorised, g.timeLeft, g.score.timeLeft), (const Duration(seconds: 5), 0.75, 0.75));
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
      expect(g.score.recall, g.prompts.length * (100 + 77));
      expect(g.score.fraction, closeTo(177 / 200, 1e-12));
      expect(g.tap(g.prompts.first, t(now + 100)), TapResult.ignored);
      expect(notified, 1 + g.prompts.length);
    });

    test('"don\'t know" gives the card up for nothing and asks the next; the game still completes', () {
      final g = newGame()..startRecall();
      expect(g.forget(), isNull, reason: 'the prompt is not on screen yet');
      g.promptRevealed(t(0));
      final first = g.current!;
      g.tap(other(g), t(300));
      expect(g.forget(), first);
      expect((g.isForgotten(first), g.isFound(first), g.isDone(first)), (true, false, true));
      final a = g.answers.single;
      expect((a.poemId, a.found, a.responseUs, a.wrongTaps), (first, false, null, 1));
      expect(AnkirenScore.points(a), 0);
      expect((g.current, g.wrongTaps, g.revealTs), (g.prompts[1], 0, null));
      expect(g.forget(), isNull, reason: 'the next prompt is not on screen yet');
      g.promptRevealed(t(1000));
      expect(g.tap(first, t(1200)), TapResult.ignored, reason: 'a card given up is out of play');
      var now = 1000;
      while (g.phase == AnkirenPhase.recall) {
        g.promptRevealed(t(now += 1000));
        g.forget();
      }
      expect((g.phase, g.completed, g.score.total), (AnkirenPhase.done, true, 0));
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
      expect(g.score.recall, 100 + 63);
      expect(g.tap(g.prompts.last, t(3000)), TapResult.ignored);
    });

    test('ending during memorise leaves every prompt unanswered', () {
      final g = newGame()..end();
      expect(g.answers.length, g.prompts.length);
      expect(g.answers.any((a) => a.found), isFalse);
      expect(g.score.total, 0);
      g.startRecall();
      expect(g.phase, AnkirenPhase.done);
    });
  });
}
