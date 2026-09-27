import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  SessionReport report({
    required List<ItemKey> unlocked,
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
        unlocked: unlocked,
        goalRaised: goalRaised,
        islandsCompleted: islandsCompleted,
      );

  test('celebrations play in order: new cards (with look-alike warnings), islands, rank-up, then goal', () async {
    final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));

    // おぐ is already known; あらざ, its confusable sibling, unlocks this run.
    final knownSibling = poems.byKimariji('おぐ').id;
    progress.trainer.items[ItemKey(knownSibling, false)]!.unlocked = true;
    final newWithTwin = poems.byKimariji('あらざ').id;
    final newPlain = poems.byKimariji('たご').id; // no confusable set at all

    final r = report(
      unlocked: [ItemKey(newWithTwin, false), ItemKey(newPlain, false)],
      islandsCompleted: [2],
      ratingBefore: 1200,
      ratingAfter: 1300,
      goalRaised: true,
    );

    final list = celebrationsFor(r, progress);

    expect(list, hasLength(6));
    expect(list[0], isA<NewCardCelebration>().having((c) => c.poemId, 'poemId', newWithTwin));
    expect(
      list[1],
      isA<ConfusableWarningCelebration>()
          .having((c) => c.poemId, 'poemId', newWithTwin)
          .having((c) => c.knownSiblings, 'knownSiblings', [knownSibling]),
    );
    expect(list[2], isA<NewCardCelebration>().having((c) => c.poemId, 'poemId', newPlain));
    expect(list[3], isA<IslandCompleteCelebration>().having((c) => c.islandIndex, 'islandIndex', 2));
    expect(
      list[4],
      isA<RankUpCelebration>()
          .having((c) => c.before.id, 'before', 'F-')
          .having((c) => c.after.id, 'after', 'F+')
          .having((c) => c.ratingBefore, 'ratingBefore', 1200)
          .having((c) => c.ratingAfter, 'ratingAfter', 1300),
    );
    expect(list[5], isA<GoalUpCelebration>());

    await progress.db.close();
  });

  test('a confusable sibling unlocked in the same run does not count as already known', () async {
    final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
    final a = poems.byKimariji('あらざ').id;
    final b = poems.byKimariji('おぐ').id;

    final r = report(unlocked: [ItemKey(a, false), ItemKey(b, false)]);
    final list = celebrationsFor(r, progress);

    // Both are new this run, so neither gets a look-alike warning.
    expect(list, hasLength(2));
    expect(list.whereType<ConfusableWarningCelebration>(), isEmpty);

    await progress.db.close();
  });

  test('no rank-up celebration when the band does not change', () async {
    final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
    final r = report(unlocked: const [], ratingBefore: 1250, ratingAfter: 1260);
    expect(celebrationsFor(r, progress), isEmpty);
    await progress.db.close();
  });
}
