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

    test('a perfect game: the total follows the card count and the time left', () {
      const ranked = AnkirenSetup.ranked();
      int total({int responseMs = 1000, Duration left = Duration.zero}) =>
          AnkirenScore.firstTryTotal(ranked, responseMs: responseMs.toDouble(), timeLeft: left);
      expect(total(responseMs: 100), AnkirenScore.maxFor(ranked.cards));
      expect(total(left: ranked.memorise), (total() * (1 + AnkirenTuning.earlyBonus)).round());
      expect(total(left: const Duration(days: 1)), total(left: ranked.memorise));
    });

    test('the speed bonus is a smooth sigmoid through the fitted points, 0.1 s to 5 s', () {
      final at = {for (final t in [100, 300, 600, 1000, 3000, 5000]) t: AnkirenScore.speedBonus(ms(t))};
      expect(at, {100: 50, 300: 44, 600: 36, 1000: 28, 3000: 8, 5000: 0});
      // Within reach of the targets it was fitted to.
      for (final MapEntry(key: t, value: v) in AnkirenTuning.speedTargets.entries) {
        expect(AnkirenScore.speedShare(t.toDouble()) - v, inInclusiveRange(-0.06, 0.06), reason: '$t ms');
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
      expect(share.values, [1, 0.4, 0.3, 0.15, 0.1, 0], reason: "the user's tiers");
      for (var i = 1; i < TapProximity.values.length; i++) {
        expect(share[TapProximity.values[i]], lessThan(share[TapProximity.values[i - 1]]!));
      }
      expect(AnkirenTuning.tapWeights, [1, 0.2], reason: 'two taps count, the second a fifth');
      expect(AnkirenTuning.tapWeights.length, lessThanOrEqualTo(AnkirenTuning.revealAfterWrong),
          reason: 'no tap on a card already shown counts');
    });

    test('the first tap: the card earns its points and speed; a miss its tier, with no speed', () {
      expect([for (final p in TapProximity.values) points([p], firstMs: 100)], [150, 40, 30, 15, 10, 0]);
      expect([for (final p in TapProximity.values) points([p], firstMs: 4000)],
          [100 + AnkirenScore.speedBonus(ms(4000)), 40, 30, 15, 10, 0]);
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
      expect(points([neighbour, card]), 40 + 20);
      expect(points([neighbour, neighbour]), 40 + 8);
      expect(points([row, card]), 30 + 20);
      expect(points([quadrant, side]), 15 + 2);
      expect(points([side, side]), 10 + 2);
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
      expect(points([neighbour, card]), 60, reason: 'the best a miss first can do');
    });

    test('shown, given up or never found: the taps made still count', () {
      final shown = answer(wrongTaps: 2, us: ms(900), taps: const [neighbour, row], firstUs: ms(200));
      expect(shown.revealed, isTrue);
      expect(AnkirenScore.points(shown), 40 + 6);
      final givenUpAfterOne = answer(wrongTaps: 1, taps: const [quadrant], firstUs: ms(200));
      expect((givenUpAfterOne.found, AnkirenScore.points(givenUpAfterOne)), (false, 15));
      final givenUpAfterTwo = answer(wrongTaps: 2, taps: const [side, neighbour], firstUs: ms(200));
      expect(AnkirenScore.points(givenUpAfterTwo), 10 + 8);
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
      expect(s.total, 150 + 108 + 100 + 35 + 42);
      expect(s.max, 6 * 150);
      expect(s.fraction, closeTo(435 / 900, 1e-12));
      expect(AnkirenScore([], prompts: 0).fraction, 0);
    });
  });

  group('score: being ready early', () {
    test('recall points make the fraction; time left scales the score', () {
      final answers = [found(100), found(1000)];
      final plain = AnkirenScore(answers, prompts: 2);
      expect((plain.recall, plain.maxRecall, plain.total, plain.max, plain.early), (278, 300, 278, 300, 0));
      final quick = AnkirenScore(answers, prompts: 2, timeLeft: 0.5);
      expect(quick.fraction, plain.fraction, reason: 'the fraction reads recall only');
      expect(quick.total, (278 * (1 + AnkirenTuning.earlyBonus * 0.5)).round());
      expect(quick.max, 300);
      expect(quick.early, quick.total - 278);
      expect(AnkirenScore([], prompts: 2, timeLeft: 1).total, 0, reason: 'nothing found, nothing to multiply');
    });

    test('only cards found with the first tap are multiplied', () {
      final near = answer(wrongTaps: 1, us: ms(900), taps: const [row, card], firstUs: ms(300));
      final answers = [found(100), near];
      final score = AnkirenScore(answers, prompts: 2, timeLeft: 1);
      final nearPoints = AnkirenScore.points(near);
      expect((score.recall, score.firstRight), (150 + nearPoints, 150));
      expect(score.total, (150 * (1 + AnkirenTuning.earlyBonus)).round() + nearPoints);
      expect(score.early, score.total - score.recall);
      expect(AnkirenScore.totalOf(score.recall, score.firstRight, 0), score.recall);
    });
  });

  group('rating', () {
    const ranked = AnkirenSetup.ranked();
    double band(String id) => Rating.bands.firstWhere((b) => b.id == id).minRating;

    test('ranked is one fixed setup, a real match, with no level', () {
      expect(ranked.perSide, AnkirenTuning.rankedPerSide);
      expect(ranked.memorise, AnkirenTuning.rankedMemorise);
      expect(ranked.level, isNull);
      expect(ranked.custom, isFalse);
    });

    test('the anchors: 50 first taps at 0.5 s reach A, 25 at 2.5 s and 25 row-then-right reach F-', () {
      final a = AnkirenScore.firstTryTotal(ranked, responseMs: 500);
      expect(AnkirenRating.performance(a), closeTo(band('A'), 1));
      final half = AnkirenScore([
        for (var i = 0; i < ranked.perSide; i++) found(2500),
        for (var i = 0; i < ranked.perSide; i++)
          answer(wrongTaps: 1, us: ms(3000), taps: const [row, card], firstUs: ms(500)),
      ], prompts: ranked.cards);
      expect(half.total,
          ranked.perSide * (AnkirenTuning.cardPoints + AnkirenScore.speedBonus(ms(2500))) + ranked.perSide * 50);
      expect(AnkirenRating.performance(half.total), closeTo(band('F-'), 1));
      expect(AnkirenRating.scoreFor(AnkirenRating.performance(a)), closeTo(a, 1e-6));
    });

    test('the curve is a line down to the lower anchor, then straight to zero, and never negative', () {
      final low = AnkirenRating.lowScore;
      expect(AnkirenRating.performance(0), 0);
      expect(AnkirenRating.performance(low.round()), closeTo(band('F-'), 1));
      expect(AnkirenRating.performance(low.round() ~/ 2), closeTo(band('F-') / 2, 1));
      expect(AnkirenRating.performance(low.round() + 1000) - AnkirenRating.performance(low.round()),
          closeTo(1000 * AnkirenRating.slope, 1e-6));
      for (var score = 0; score < 12000; score += 97) {
        expect(AnkirenRating.performance(score), greaterThanOrEqualTo(0));
        expect(AnkirenRating.scoreFor(AnkirenRating.performance(score)), closeTo(score, 1e-6));
      }
    });

    test('play starts in 入門, and a zero-point game rates 0 without any floor', () {
      expect(Rating.bandOf(AnkirenRating.start).label, '入門');
      final p = AnkirenRating.performance(0);
      expect(AnkirenRating.update(AnkirenRating.start, p, const []), 0);
      expect(AnkirenRating.update(1000, 0, const [1, 2, 3]), closeTo(1000 * (1 - AnkirenRatingModel.establishedK), 1e-9));
    });

    test('placement: the rating is the mean of the placement games, then each game moves it K of the way', () {
      final ps = [1500.0, 2100.0, 1800.0, 2400.0];
      var r = AnkirenRating.start;
      for (var game = 0; game < ps.length; game++) {
        expect(AnkirenRating.isPlacement(game), game < AnkirenRatingModel.placementGames);
        final next = AnkirenRating.update(r, ps[game], ps.take(game).toList());
        if (game < AnkirenRatingModel.placementGames) {
          final placed = ps.take(game + 1);
          expect(next, closeTo(placed.reduce((a, b) => a + b) / placed.length, 1e-9));
        } else {
          expect(next, closeTo(r + AnkirenRatingModel.establishedK * (ps[game] - r), 1e-9));
        }
        r = next;
      }
    });

    test('placement means the games as played', () {
      const low = 100.0, high = 1300.0;
      final first = AnkirenRating.update(AnkirenRating.start, low, const []);
      expect(first, low);
      expect(AnkirenRating.update(first, high, const [low]), (low + high) / 2);
    });

    test('near misses rate above giving up, and below finding the card', () {
      double performance(List<AnkirenAnswer> misses) => AnkirenRating.performance(
          AnkirenScore([for (var i = 0; i < 8; i++) found(1500), ...misses], prompts: 10).total);
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
    });

    test('being ready early raises the performance', () {
      final full = AnkirenScore.firstTryTotal(ranked, responseMs: 1000);
      final early = AnkirenScore.firstTryTotal(ranked, responseMs: 1000, timeLeft: const Duration(minutes: 5));
      expect(AnkirenRating.performance(early), greaterThan(AnkirenRating.performance(full)));
    });
  });

  group('ladder', () {
    test('level 0 opens first; clearing a level opens the next, and every level below it', () {
      expect((AnkirenLadder.none.open, AnkirenLadder.none.next), (0, 0));
      expect(AnkirenLadder.none.isOpen(1), isFalse);
      const cleared = AnkirenLadder({0, 1, 2});
      expect((cleared.open, cleared.next, cleared.isCleared(2), cleared.isCleared(3)), (3, 3, true, false));
      const gap = AnkirenLadder({5});
      expect((gap.open, gap.isOpen(2), gap.isCleared(2)), (6, true, false), reason: 'a level cleared out of order');
    });

    test('ranked needs Lv 4 cleared, custom setups Lv 8, and the top level clears them all', () {
      AnkirenLadder upTo(int level) => AnkirenLadder({for (var l = 0; l <= level; l++) l});
      expect(upTo(AnkirenTuning.rankedAfterLevel - 1).rankedReady, isFalse);
      expect(upTo(AnkirenTuning.rankedAfterLevel).rankedReady, isTrue);
      expect(upTo(AnkirenTuning.customAfterLevel - 1).customOpen, isFalse);
      expect(upTo(AnkirenTuning.customAfterLevel).customOpen, isTrue);
      final all = upTo(AnkirenLevels.top);
      expect((all.allCleared, all.next, all.open), (true, null, AnkirenLevels.top));
      expect(upTo(AnkirenLevels.top - 1).next, AnkirenLevels.top);
    });

    test('a game clears its level when played to the end with fewer strikes than end it', () {
      expect(AnkirenLadder.clears(completed: true, strikes: AnkirenTuning.strikesOut - 1), isTrue);
      expect(AnkirenLadder.clears(completed: true, strikes: AnkirenTuning.strikesOut), isFalse);
      expect(AnkirenLadder.clears(completed: false, strikes: 0), isFalse);
    });
  });

  group('game', () {
    /// A ranked-style (scored) game at [perSide] cards a side, or a custom one.
    AnkirenGame newGame({int seed = 1, int perSide = 4, bool custom = false, bool strikes = false}) {
      final f = dealer.deal(known, perSide, math.Random(seed));
      const memorise = Duration(seconds: 20);
      return AnkirenGame(
        field: f,
        setup: custom
            ? AnkirenSetup.custom(perSide: perSide, memorise: memorise)
            : AnkirenSetup(perSide: perSide, memorise: memorise, ranked: true),
        rng: math.Random(seed),
        countsStrikes: strikes,
        clock: () => DateTime(2026, 10, 12),
      );
    }

    Duration t(int ms) => Duration(milliseconds: ms);
    int other(AnkirenGame g) => g.field.cards.firstWhere((c) => c != g.current && !g.isDone(c));

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
      expect(AnkirenScore.points(a), 100 + 8);
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
        expect(AnkirenScore.points(a), 60, reason: 'neither tap earns a speed bonus');
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
        expect(AnkirenScore.points(a), 40, reason: 'the shown card and the tap before it add nothing');
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
        (clustered, 2, [2], [card], 144),
        (clustered, 2, [1, 2], [neighbour, card], 40 + 20),
        (clustered, 1, [3, 7], [row, quadrant], 30 + 3),
        (clustered, 2, [6, 4], [quadrant, side], 15 + 2),
        (clustered, 2, [21, 22], [otherSide, otherSide], 0),
        (clustered, 2, [10, 2], [side, card], 10 + 20),
        (clustered, 10, [11, 12], [row, row], 30 + 6),
        (clustered, 10, [4, 10], [side, card], 10 + 20),
        (clustered, 10, [23, 9], [otherSide, row], 6),
        (clustered, 12, [11, 13], [side, neighbour], 10 + 8),
        (clustered, 22, [21, 23, 22], [neighbour, side], 40 + 2),
        (beginner, 32, [31, 34], [neighbour, row], 40 + 6),
        (beginner, 32, [41, 32], [otherSide, card], 20),
        (beginner, 41, [43], [row], 30),
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
      expect(g.score!.recall, g.prompts.length * (100 + 38));
      expect(g.score!.fraction, closeTo(138 / 150, 1e-12));
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
      expect(g.score!.recall, 100 + 32 + AnkirenScore.points(g.answers[1]));
      expect([for (final a in g.answers.skip(2)) AnkirenScore.points(a)], everyElement(0));
      expect(g.tap(g.prompts.last, t(3000)), TapResult.ignored);
    });

    test('strikes: every wrong tap and every "don\'t know" is one, and a third does not end the game', () {
      final g = newGame(strikes: true)..startRecall();
      g.promptRevealed(t(0));
      g.tap(other(g), t(300));
      g.tap(other(g), t(600));
      expect((g.strikes, g.phase), (2, AnkirenPhase.recall), reason: 'two wrong taps on one card are two strikes');
      g.tap(g.current!, t(900));
      g.promptRevealed(t(2000));
      expect(g.giveUp(), isNotNull);
      expect(AnkirenTuning.strikesOut, 3);
      expect((g.strikes, g.phase, g.completed, g.cleared), (3, AnkirenPhase.recall, false, false));
      g.promptRevealed(t(3000));
      expect(g.tap(other(g), t(3200)), TapResult.wrong, reason: 'play goes on, and counts the strike');
      expect(g.strikes, 4);
    });

    test('a level game played to the end with fewer strikes clears it; without strikes counted none does', () {
      void play(AnkirenGame g, {required int wrong}) {
        g.startRecall();
        var now = 0;
        for (var i = 0; g.phase == AnkirenPhase.recall; i++) {
          g.promptRevealed(t(now += 1000));
          if (i < wrong) g.tap(other(g), t(now += 200));
          g.tap(g.current!, t(now += 300));
        }
      }

      final cleared = newGame(strikes: true);
      play(cleared, wrong: AnkirenTuning.strikesOut - 1);
      expect((cleared.completed, cleared.strikes, cleared.cleared), (true, AnkirenTuning.strikesOut - 1, true));
      final failed = newGame(strikes: true);
      play(failed, wrong: AnkirenTuning.strikesOut);
      expect((failed.completed, failed.strikes, failed.cleared), (true, AnkirenTuning.strikesOut, false));
      final free = newGame();
      play(free, wrong: 5);
      expect((free.completed, free.strikes, free.cleared), (true, 5, false));
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
