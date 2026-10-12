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
      expect(AnkirenScore.points(answer(us: ms(300))), full);
      expect(AnkirenScore.points(answer(us: ms(AnkirenTuning.fastMs))), full);
      final halfway = (AnkirenTuning.fastMs + AnkirenTuning.slowMs) ~/ 2;
      expect(AnkirenScore.points(answer(us: ms(halfway))), AnkirenTuning.firstTry + AnkirenTuning.speedMax ~/ 2);
      expect(AnkirenScore.points(answer(us: ms(AnkirenTuning.slowMs))), AnkirenTuning.firstTry);
      expect(AnkirenScore.points(answer(us: ms(20000))), AnkirenTuning.firstTry);
    });

    test('a time that is no measurement keeps the points but earns no speed bonus', () {
      expect(AnkirenScore.points(answer(us: 0)), AnkirenTuning.firstTry);
      expect(AnkirenScore.points(answer(us: -5000)), AnkirenTuning.firstTry);
      expect(answer(us: 0).validTime, isFalse);
      expect(answer(us: 1).validTime, isTrue);
    });

    test('second try earns less and no bonus; revealed or never found earns nothing', () {
      expect(AnkirenScore.points(answer(wrongTaps: 1, us: ms(500))), AnkirenTuning.secondTry);
      expect(AnkirenScore.points(answer(wrongTaps: 2, us: ms(500))), 0);
      expect(answer(wrongTaps: 2, us: ms(500)).revealed, isTrue);
      expect(AnkirenScore.points(answer(wrongTaps: 5, us: ms(500))), 0);
      expect(AnkirenScore.points(answer()), 0);
      expect(answer().found, isFalse);
    });

    test('a game: total, max, fraction and the first-try summary', () {
      final answers = [
        answer(us: ms(800)),
        answer(us: ms(2900)),
        answer(us: 0),
        answer(wrongTaps: 1, us: ms(1000)),
        answer(wrongTaps: 2, us: ms(1000)),
        answer(),
      ];
      final s = AnkirenScore(answers, prompts: 6);
      expect(s.total, 150 + 125 + 100 + 40);
      expect(s.max, 6 * 150);
      expect(s.fraction, closeTo(415 / 900, 1e-12));
      expect(s.firstTries, 3);
      expect(s.averageFirstTryMs, closeTo((800 + 2900) / 2, 1e-9), reason: 'valid times only');
      expect(AnkirenScore([], prompts: 6).averageFirstTryMs, isNull);
      expect(AnkirenScore([], prompts: 0).fraction, 0);
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
      expect(AnkirenRating.performance(5, 0.9, placement: true) - ratings[5], closeTo(3 * (p - ratings[5]), 1e-9));
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
      expect(AnkirenScore.points(a), 100 + 25);
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
      expect(g.score.total, g.prompts.length * (100 + 50));
      expect(g.score.fraction, 1);
      expect(g.tap(g.prompts.first, t(now + 100)), TapResult.ignored);
      expect(notified, 1 + g.prompts.length);
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
      expect(g.score.total, 100 + 50);
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
