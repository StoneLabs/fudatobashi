import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/run_review.dart';

RunSwipe _swipe(int ms, {bool miss = false, bool undone = false}) => RunSwipe(
      poemId: 1,
      inverted: false,
      us: ms * 1000,
      miss: miss,
      clean: !undone,
      at: DateTime(2026),
      undone: undone,
    );

/// History's time graph: where the line goes and where its bottom sits.
void main() {
  test('The timeline shares the clock out by swipe time and adds a penalty at each miss', () {
    final t = RunTimeline.of([_swipe(1000), _swipe(3000, miss: true)], clockMs: 8000, penaltyMs: 10000);
    expect(t.ms, [0, 2000, 18000]);
    expect(t.missCards, [2]);
    expect(t.evenAt(1), 9000);
  });

  test('An undone swipe adds its time and miss to the card swiped again after it', () {
    final t = RunTimeline.of([_swipe(1000, miss: true, undone: true), _swipe(1000)], clockMs: 2000, penaltyMs: 10000);
    expect(t.ms, [0, 12000]);
    expect(t.missCards, [1]);
  });

  test('The bottom is the slowest earlier run, but never past twice this run', () {
    const run = RunTimeline([0, 50000, 100000]);
    expect(run.bottomWith(const []), 100000, reason: 'no reference: the run ends in the corner');
    expect(run.bottomWith(const [RunTimeline([0, 60000]), RunTimeline([0, 150000])]), 150000);
    expect(run.bottomWith(const [RunTimeline([0, 900000])]), 100000 * RunReviewTuning.graphReach);
    expect(run.bottomWith(const [RunTimeline([0, 40000])]), 100000, reason: 'never above this run');
  });

  test('Practise these: the misses, then the slowest, each once', () {
    final cards = RunCards([
      RunSwipe(poemId: 5, inverted: false, us: 900000, miss: true, clean: true, at: DateTime(2026)),
      RunSwipe(poemId: 6, inverted: false, us: 3000000, miss: false, clean: true, at: DateTime(2026)),
      RunSwipe(poemId: 5, inverted: true, us: 2000000, miss: false, clean: true, at: DateTime(2026)),
      RunSwipe(poemId: 7, inverted: false, us: 500000, miss: false, clean: true, at: DateTime(2026)),
    ]);
    expect(cards.practise, [5, 6, 7]);
    expect(cards.fastest.first.poemId, 7);
  });
}
