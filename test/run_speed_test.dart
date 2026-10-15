import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/run_review.dart';
import 'package:fudatobashi/domain/run_speed.dart';

RunSwipe _swipe(int poemId, int ms, {bool miss = false, bool inverted = false, bool undone = false}) => RunSwipe(
      poemId: poemId,
      inverted: inverted,
      us: ms * 1000,
      miss: miss || undone,
      clean: !undone,
      at: DateTime(2026, 10, 1),
      undone: undone,
    );

void main() {
  int length(int poemId) => poemId % 3 + 1;

  test('splits the cards into thirds and blocks, misses counted, averages over right cards only', () {
    final swipes = [for (var i = 1; i <= 30; i++) _swipe(i, i <= 10 ? 2000 : 1000, miss: i == 15)];
    final speed = RunSpeed(swipes, kimarijiLength: length);
    expect([for (final t in speed.thirds) (t.from, t.to, t.meanMs, t.misses)], [
      (1, 10, 2000.0, 0),
      (11, 20, 1000.0, 1),
      (21, 30, 1000.0, 0),
    ]);
    expect(speed.blocks, hasLength(3));
    expect(speed.meanMs, closeTo((10 * 2000 + 19 * 1000) / 29, 1e-9));
    expect(RunSpeed.extremes(speed.thirds)!.slowest.from, 1);
  });

  test('an undone swipe makes the card swiped after it a miss and is not a card itself', () {
    final speed = RunSpeed([_swipe(1, 900), _swipe(2, 500, undone: true), _swipe(2, 800)], kimarijiLength: length);
    expect(speed.cards.map((c) => (c.number, c.miss)), [(1, false), (2, true)]);
  });

  test('finds the fastest stretch and the longest row under the goal without a miss', () {
    final ms = [for (var i = 0; i < 30; i++) 2000];
    for (var i = 12; i < 22; i++) {
      ms[i] = 900;
    }
    final swipes = [for (final (i, t) in ms.indexed) _swipe(i + 1, t, miss: i == 18)];
    final speed = RunSpeed(swipes, goalMs: 1000, kimarijiLength: length);
    expect(speed.fastestStretch, (from: 13, to: 22, ms: 9000.0));
    expect(speed.longestUnderGoal, (from: 13, to: 18));
    expect(speed.paceOf(speed.cards[18]), CardPace.miss);
    expect(speed.paceOf(speed.cards[0]), CardPace.slow);
    expect(speed.paceOf(speed.cards[12]), CardPace.underGoal);
    expect(RunSpeed(swipes.take(RunSpeedTuning.blockCards - 1).toList(), kimarijiLength: length).fastestStretch, isNull);
  });

  test('compares the sides, the 決まり字 lengths and the usual times', () {
    final swipes = [
      _swipe(1, 1000),
      _swipe(2, 2000, inverted: true),
      _swipe(3, 3000, inverted: true, miss: true),
      _swipe(4, 1500),
    ];
    final usual = {
      ItemKey(1, false).id: 1200.0,
      ItemKey(2, true).id: 1800.0,
      ItemKey(4, false).id: 1600.0,
    };
    final speed = RunSpeed(swipes, usualMs: usual, kimarijiLength: length);
    expect(speed.upright, (cards: 2, misses: 0, meanMs: 1250.0));
    expect(speed.upsideDown, (cards: 2, misses: 1, meanMs: 2000.0));
    expect([for (final k in speed.byKimariji) (k.length, k.cards, k.misses, k.meanMs, k.usualMs)], [
      (1, 1, 1, null, null),
      (2, 2, 0, 1250.0, 1400.0),
      (3, 1, 0, 2000.0, 1800.0),
    ]);
    final against = speed.againstUsual;
    expect((against.compared, against.faster, against.usualMs, against.runMs), (3, 2, 4600.0, 4500.0));
    expect([for (final d in against.gained) d.card.swipe.poemId], [1, 4]);
    expect([for (final d in against.lost) d.card.swipe.poemId], [2]);
  });
}
