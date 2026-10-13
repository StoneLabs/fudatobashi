import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/synthetic_learner.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  final day0 = DateTime(2026, 9, 1, 9);
  ItemKey up(Poem p) => ItemKey(p.id, false);

  /// Share of [n] learners of [kind] that miss a card, met once (introduced
  /// and answered), when it comes back after [gap].
  double missedAfter(Duration gap, {LearnerKind kind = LearnerKind.average, int n = 2000}) {
    var missed = 0;
    for (var i = 0; i < n; i++) {
      final learner = SyntheticLearner(math.Random(i), kind: kind);
      final poem = poems[1 + i % 100];
      learner.answer(poem, up(poem), day0, introduced: true);
      if (learner.answer(poem, up(poem), day0.add(gap)).missed) missed++;
    }
    return missed / n;
  }

  test('a card met once can be gone minutes later, more so hours later, and is mostly gone by the next day', () {
    final minutes = missedAfter(const Duration(minutes: 2));
    final hours = missedAfter(const Duration(hours: 6));
    final nextDay = missedAfter(const Duration(days: 1));
    expect(minutes, inInclusiveRange(0.15, 0.4));
    expect(hours, greaterThan(minutes + 0.1));
    expect(nextDay, greaterThan(0.6));
    expect(missedAfter(const Duration(days: 1), kind: LearnerKind.quick), lessThan(nextDay));
    expect(missedAfter(const Duration(days: 1), kind: LearnerKind.slow), greaterThan(nextDay));
  });

  test('a card never introduced is not known', () {
    final learner = SyntheticLearner(math.Random(1));
    final poem = poems[1];
    expect(learner.answer(poem, up(poem), day0).miss, MissCause.forgot);
    expect(learner.stabilityOf(poem.id), isNotNull, reason: 'the miss showed the answer');
  });

  test('memory grows only with correct recalls and drops after forgetting, whatever the calendar says', () {
    final poem = poems.byKimariji('つき');
    final twin = poems.byKimariji('はなの');
    final seen = <MissCause?>{};
    for (var i = 0; i < 200; i++) {
      final learner = SyntheticLearner(math.Random(i));
      learner.answer(twin, up(twin), day0, introduced: true);
      learner.answer(poem, up(poem), day0, introduced: true);
      var at = day0;
      for (var look = 0; look < 30; look++) {
        at = at.add(Duration(hours: 1 + (look * 7) % 40));
        final before = learner.stabilityOf(poem.id)!;
        final answer = learner.answer(poem, up(poem), at);
        final after = learner.stabilityOf(poem.id)!;
        seen.add(answer.miss);
        switch (answer.miss) {
          case null:
            expect(after, greaterThan(before));
          case MissCause.forgot || MissCause.forgotToday:
            expect(after, lessThanOrEqualTo(before));
          case MissCause.lookAlike || MissCause.slip:
            expect(after, before);
        }
      }
    }
    expect(seen, containsAll([null, ...MissCause.values]));
  });

  test('takes a card for a 友札 it has met, less often as the card settles', () {
    final poem = poems.byKimariji('つき');
    final twin = poems.byKimariji('はなの');
    final other = poems.byKimariji('む');
    // Mix-ups and remembered answers, with the 友札 met or not, in the first
    // week and after it.
    final mixUps = {for (final met in [twin, other]) met: [0, 0]};
    final remembered = {for (final met in [twin, other]) met: [0, 0]};
    for (var i = 0; i < 500; i++) {
      for (final met in [twin, other]) {
        final learner = SyntheticLearner(math.Random(i));
        learner.answer(met, up(met), day0, introduced: true);
        learner.answer(poem, up(poem), day0, introduced: true);
        for (var d = 1; d <= 20; d++) {
          final miss = learner.answer(poem, up(poem), day0.add(Duration(days: d))).miss;
          if (miss == MissCause.forgot || miss == MissCause.forgotToday) continue;
          final week = d <= 7 ? 0 : 1;
          remembered[met]![week]++;
          if (miss == MissCause.lookAlike) mixUps[met]![week]++;
        }
      }
    }
    double rate(Poem met, int week) => mixUps[met]![week] / remembered[met]![week];
    expect(mixUps[other], [0, 0], reason: 'む has no 友札 among the cards met');
    expect(rate(twin, 0), inInclusiveRange(0.05, 0.2));
    expect(rate(twin, 1), lessThan(rate(twin, 0) / 2));
  });

  /// The [nth] answer of each of [n] learners drilling one card a minute
  /// apart: (ms, slipped).
  List<(double, bool)> nthAnswers(int nth, {int n = 4000}) {
    final poem = poems.byKimariji('む');
    return [
      for (var i = 0; i < n; i++)
        () {
          final learner = SyntheticLearner(math.Random(i));
          var answer = learner.answer(poem, up(poem), day0, introduced: true);
          for (var k = 1; k <= nth; k++) {
            answer = learner.answer(poem, up(poem), day0.add(Duration(minutes: k)));
          }
          return (answer.ms, answer.miss == MissCause.slip);
        }(),
    ];
  }

  test('slips on a card it knows, more often when answering in a rush', () {
    final answers = nthAnswers(20)..sort((a, b) => a.$1.compareTo(b.$1));
    double slipRate(Iterable<(double, bool)> xs) => xs.where((a) => a.$2).length / xs.length;
    final fast = answers.take(answers.length ~/ 5);
    final rest = answers.skip(answers.length ~/ 5);
    expect(slipRate(rest), inInclusiveRange(0.005, 0.04));
    expect(slipRate(fast), greaterThan(2 * slipRate(rest)));
  });

  test('gets faster with practice, ever more slowly, and never exactly the same', () {
    double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
    final at = {for (final nth in [1, 10, 50, 200]) nth: [for (final a in nthAnswers(nth, n: 400)) a.$1]};
    expect(mean(at[1]!), greaterThan(mean(at[10]!)));
    expect(mean(at[10]!), greaterThan(mean(at[50]!)));
    expect(mean(at[50]!), greaterThan(mean(at[200]!)), reason: 'still improving after 50 looks');
    expect(mean(at[1]!) - mean(at[10]!), greaterThan(mean(at[50]!) - mean(at[200]!)));
    expect(mean(at[200]!), greaterThan(SyntheticLearnerTuning.average.floorMs));
    final xs = at[50]!;
    final sd = math.sqrt(mean([for (final x in xs) math.pow(x - mean(xs), 2).toDouble()]));
    expect(sd / mean(xs), inInclusiveRange(0.15, 0.4));
  });

  test('the same seed replays the same answers', () {
    List<(double, MissCause?)> run() {
      final learner = SyntheticLearner(math.Random(7), kind: LearnerKind.slow);
      return [
        for (var k = 0; k < 200; k++)
          () {
            final poem = poems[1 + k % 12];
            final a = learner.answer(poem, up(poem), day0.add(Duration(hours: k)), introduced: k < 12);
            return (a.ms, a.miss);
          }(),
      ];
    }

    expect(run(), run());
  });
}
