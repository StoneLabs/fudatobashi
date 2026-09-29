import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';

import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);

  SessionReport report({
    List<int> islandsCompleted = const [],
    double? ratingBefore,
    double? ratingAfter,
    bool goalRaised = false,
    bool graduated = false,
    XpGain? xp,
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
        graduated: graduated,
        xp: xp,
      );
  XpGain gain(int before, int xp) => XpGain(before: before, award: XpAward([XpPart(XpSource.correct, 1, xp)]));

  test('after a run: islands, goal, then the rating rising into a rank-up', () {
    final list = celebrationsFor(report(islandsCompleted: [2], ratingBefore: 1200, ratingAfter: 1300, goalRaised: true));

    expect(list, hasLength(4));
    expect(list[0], isA<IslandCompleteCelebration>().having((c) => c.islandIndex, 'islandIndex', 2));
    expect(list[1], isA<GoalUpCelebration>());
    expect(
      list[2],
      isA<RatingCelebration>()
          .having((c) => c.before, 'before', 1200)
          .having((c) => c.after, 'after', 1300)
          .having((c) => c.ranksUp, 'ranksUp', isTrue),
    );
    expect(
      list[3],
      isA<RankUpCelebration>()
          .having((c) => c.before.id, 'before', 'F-')
          .having((c) => c.after.id, 'after', 'F+')
          .having((c) => c.ratingBefore, 'ratingBefore', 1200)
          .having((c) => c.ratingAfter, 'ratingAfter', 1300),
    );
  });

  test('the full order: islands, goal, graduation, XP, level-up, rating, rank-up', () {
    final levelUp = gain(XpCurve.reach(2) - 5, 10);
    final list = celebrationsFor(report(
      islandsCompleted: [1, 2],
      goalRaised: true,
      graduated: true,
      xp: levelUp,
      ratingBefore: 1600,
      ratingAfter: 1660,
    ));
    expect(list.map((c) => c.runtimeType), [
      IslandCompleteCelebration,
      IslandCompleteCelebration,
      GoalUpCelebration,
      GraduationCelebration,
      XpCelebration,
      LevelUpCelebration,
      RatingCelebration,
      RankUpCelebration,
    ]);
  });

  test('the rating page only when the shown rating rose', () {
    List<Type> pages(double? before, double after) =>
        celebrationsFor(report(ratingBefore: before, ratingAfter: after)).map((c) => c.runtimeType).toList();

    expect(pages(1250, 1276), [RatingCelebration]);
    expect((celebrationsFor(report(ratingBefore: 1250, ratingAfter: 1276)).single as RatingCelebration).ranksUp, isFalse);
    expect(pages(1250, 1240), isEmpty, reason: 'a drop is never celebrated');
    expect(pages(1250, 1250), isEmpty, reason: 'no change');
    expect(pages(1250.2, 1250.4), isEmpty, reason: 'both show as 1250');
    expect(pages(1250.4, 1250.6), [RatingCelebration], reason: '1250 → 1251 shows as +1');
    expect(pages(null, 1300), [RankUpCelebration], reason: 'a first rating has nothing to rise from');
    expect(pages(null, 700), isEmpty);
    expect(celebrationsFor(report(ratingBefore: 1300)), isEmpty, reason: 'an unrated run');
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

  test('graduation, then the XP and the level it reached', () {
    final levelUp = gain(XpCurve.reach(2) - 5, 10);
    final list = celebrationsFor(report(islandsCompleted: [2], goalRaised: true, graduated: true, xp: levelUp));
    expect(list.map((c) => c.runtimeType), [
      IslandCompleteCelebration,
      GoalUpCelebration,
      GraduationCelebration,
      XpCelebration,
      LevelUpCelebration,
    ]);
    expect((list[4] as LevelUpCelebration).gain, levelUp);
  });

  test('every run that earned XP gets its page, a level-up only when one was reached', () {
    expect(celebrationsFor(report(xp: gain(0, 40))).map((c) => c.runtimeType), [XpCelebration]);
    expect(celebrationsFor(report(xp: gain(0, 0))), isEmpty, reason: 'nothing earned, nothing to show');
    expect(celebrationsFor(report()), isEmpty, reason: 'a guest run earns no XP');
  });

  test('no rank-up celebration when the band does not change', () {
    expect(celebrationsFor(report(ratingBefore: 1250, ratingAfter: 1260)).whereType<RankUpCelebration>(), isEmpty);
  });
}
