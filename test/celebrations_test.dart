import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);

  SessionReport report({
    List<int> islandsCompleted = const [],
    double? ratingBefore,
    double? ratingAfter,
    bool goalRaised = false,
  }) =>
      SessionReport(
        sessionId: 1,
        total: const Duration(seconds: 10),
        attempts: const [],
        previousBest: null,
        ratingBefore: ratingBefore,
        ratingAfter: ratingAfter,
        goalRaised: goalRaised,
        islandsCompleted: islandsCompleted,
      );

  test('after a run: islands, rank-up, then goal', () {
    final list = celebrationsFor(report(islandsCompleted: [2], ratingBefore: 1200, ratingAfter: 1300, goalRaised: true));

    expect(list, hasLength(3));
    expect(list[0], isA<IslandCompleteCelebration>().having((c) => c.islandIndex, 'islandIndex', 2));
    expect(
      list[1],
      isA<RankUpCelebration>()
          .having((c) => c.before.id, 'before', 'F-')
          .having((c) => c.after.id, 'after', 'F+')
          .having((c) => c.ratingBefore, 'ratingBefore', 1200)
          .having((c) => c.ratingAfter, 'ratingAfter', 1300),
    );
    expect(list[2], isA<GoalUpCelebration>());
  });

  test('a new card is introduced with a look-alike warning naming the siblings the player knows', () {
    // おぐ is known; あらざ, its confusable sibling, is new.
    final knownSibling = poems.byKimariji('おぐ').id;
    final newWithTwin = poems.byKimariji('あらざ').id;
    final pages = introductionOf(newWithTwin, knows: (id) => id == knownSibling);

    expect(pages, hasLength(2));
    expect(pages[0], isA<NewCardCelebration>().having((c) => c.poemId, 'poemId', newWithTwin));
    expect(
      pages[1],
      isA<ConfusableWarningCelebration>()
          .having((c) => c.poemId, 'poemId', newWithTwin)
          .having((c) => c.knownSiblings, 'knownSiblings', [knownSibling]),
    );
  });

  test('no look-alike warning when no sibling is known yet', () {
    final newWithTwin = poems.byKimariji('あらざ').id;
    expect(introductionOf(newWithTwin, knows: (_) => false), [isA<NewCardCelebration>()]);
    final newPlain = poems.byKimariji('たご').id; // no confusable set at all
    expect(introductionOf(newPlain, knows: (_) => true), [isA<NewCardCelebration>()]);
  });

  test('no rank-up celebration when the band does not change', () {
    expect(celebrationsFor(report(ratingBefore: 1250, ratingAfter: 1260)), isEmpty);
  });
}
