import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/demo_data.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/home/journey_state.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// [cards] swiped as [script] says, [at] the first reveal's wall-clock
  /// time (now when not given).
  PlaySession play(List<CardRef> cards, List<(int ms, Outcome o)> script, {DateTime? at}) {
    final s = PlaySession(cards);
    const start = Duration(seconds: 100);
    var t = start;
    for (final (ms, o) in script) {
      s.revealed(t);
      t += Duration(milliseconds: ms);
      s.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: o, at: at?.add(t - start));
      t += const Duration(milliseconds: 100);
    }
    return s;
  }

  test('a tracked run is stored, reviewed by FSRS and survives a reload', () async {
    final executor = NativeDatabase.memory();
    final db = AppDatabase(executor);
    final progress = await Progress.open(db);
    final planned = await progress.planTraining();
    expect(planned.unlockedBefore.map((k) => poems[k.poemId].kimariji).take(3), ['む', 'す', 'め']);

    final cards = planned.cards.take(4).toList();
    final run = play(cards, [(900, Outcome.known), (4000, Outcome.known), (700, Outcome.dontKnow), (1200, Outcome.known)]);
    final report = await progress.recordRun(run, const PlayConfig(mode: PlayMode.training), DateTime.now());

    expect(report.runId, isNotNull);
    expect(report.total, isNotNull);
    expect(report.ratingAfter, isNull, reason: 'only a ranked run moves the rating');
    final k0 = ItemKey(cards[0].poemId, cards[0].inverted);
    expect(progress.stats(k0).seen, isTrue);
    expect(progress.trainer.items[k0]!.reviewed, isTrue);
    // One `Outcome.dontKnow` in the script above — the History tab's miss count.
    expect(progress.missesIn(report.runId!), 1);

    // Reload from the same database.
    final again = await Progress.open(db);
    expect(again.runs.length, 1);
    expect(again.stats(k0).count, progress.stats(k0).count);
    expect(again.trainer.items[k0]!.card.stability, progress.trainer.items[k0]!.card.stability);
    expect(again.rating, progress.rating);
    expect(again.missesIn(report.runId!), 1);
    await db.close();
  });

  test('a run keeps its raw facts: timing, day, setup and each review\'s FSRS state', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final progress = await Progress.open(db);
    final now = DateTime.now();
    final startedAt = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
    final endedAt = startedAt.add(const Duration(minutes: 1));
    final planned = await progress.planTraining(now: startedAt);
    final cards = [for (final k in planned.unlockedBefore.take(4)) CardRef(k.poemId, inverted: k.inverted)];
    final run = play(cards, [(900, Outcome.known), (4000, Outcome.known), (700, Outcome.dontKnow), (1200, Outcome.known)],
        at: startedAt);
    final report =
        await progress.recordRun(run, const PlayConfig(mode: PlayMode.training), startedAt, now: endedAt);

    final row = (await db.select(db.runs).get()).single;
    expect([row.id, row.mode, row.startedAt, row.endedAt, row.day, row.allKnown, row.planned, row.completed],
        [report.runId, PlayMode.training, startedAt, endedAt, progress.dayAt(startedAt).number, false, 4, true]);
    expect(row.goalMs, progress.trainer.goalMs);
    expect(row.clockUs, 7180000, reason: 'first reveal → last swipe let go');
    expect(progress.cardsIn(row.id), 4);

    final attempts = await (db.select(db.attempts)..orderBy([(a) => OrderingTerm.asc(a.seq)])).get();
    expect([for (final a in attempts) a.revealAtUs], [0, 1000000, 5100000, 5900000]);
    expect([for (final a in attempts) a.commitUs! - a.responseUs], everyElement(80000));
    expect([for (final a in attempts) a.outcome], [Outcome.known, Outcome.known, Outcome.dontKnow, Outcome.known]);
    for (final a in attempts) {
      final card = progress.trainer.items[ItemKey(a.poemId, a.inverted)]!.card;
      expect(a.grade, isNotNull, reason: 'a new card\'s first look is a review');
      expect(a.fsrsRecall, isNull, reason: 'nothing to recall before the first review');
      expect([a.fsrsState, a.fsrsStep, a.fsrsStability, a.fsrsDifficulty],
          [card.state, card.step, card.stability, card.difficulty]);
    }

    // The next day, a review of a card reviewed before keeps its chance of
    // recall just before it.
    final nextDay = startedAt.add(const Duration(days: 1));
    final first = ItemKey(cards[0].poemId, cards[0].inverted);
    final second = play([cards[0]], [(800, Outcome.known)], at: nextDay);
    final recall = progress.trainer.retrievability(first, second.attempts.single.at);
    await progress.recordRun(second, const PlayConfig(mode: PlayMode.training), nextDay,
        now: nextDay.add(const Duration(seconds: 5)));
    final review = (await (db.select(db.attempts)..where((a) => a.runId.equals(progress.runs.last.id))).get()).single;
    expect(review.grade, isNotNull);
    expect(review.fsrsRecall, closeTo(recall, 1e-9));
    expect(recall, inExclusiveRange(0, 1));

    final again = await Progress.open(db);
    final before = progress.trainer.items[first]!.card, after = again.trainer.items[first]!.card;
    expect([after.state, after.step, after.stability, after.difficulty],
        [before.state, before.step, before.stability, before.difficulty]);
    expect(after.due.difference(before.due).inSeconds.abs(), lessThan(1), reason: 'stored to the second');
    await db.close();
  });

  test('free play is stored for history but never feeds FSRS or rating; training does', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final progress = await Progress.open(db);
    final planned = await progress.planTraining();
    final card = planned.cards.first;
    final key = ItemKey(card.poemId, card.inverted);

    final beforeDue = progress.trainer.items[key]!.card.due;
    expect(progress.trainer.items[key]!.reviewed, isFalse);
    expect(progress.rating, isNull);

    final freeRun = play([card], [(900, Outcome.known)]);
    final freeReport = await progress.recordRun(freeRun, const PlayConfig(mode: PlayMode.free), DateTime.now());

    // Stored (and visible to the unfiltered, all-mode views)...
    expect(freeReport.runId, isNotNull);
    expect(progress.attemptsOf(key).length, 1);
    expect(progress.displayStats(key).seen, isTrue);
    // ...but FSRS, the training-only `stats()`, and the rating are untouched.
    expect(progress.trainer.items[key]!.reviewed, isFalse);
    expect(progress.trainer.items[key]!.card.due, beforeDue);
    expect(progress.stats(key).seen, isFalse);
    expect(progress.rating, isNull);
    expect(freeReport.ratingBefore, isNull);
    expect(freeReport.ratingAfter, isNull);

    final trainingRun = play([card], [(900, Outcome.known)]);
    final trainingReport =
        await progress.recordRun(trainingRun, const PlayConfig(mode: PlayMode.training), DateTime.now());

    // The very same card, now reviewed for real by a training run.
    expect(trainingReport.runId, isNotNull);
    expect(progress.trainer.items[key]!.reviewed, isTrue);
    expect(progress.trainer.items[key]!.card.due, isNot(beforeDue));
    expect(progress.stats(key).seen, isTrue);
    expect(progress.rating, isNull, reason: 'only a ranked run moves the rating');
    expect(trainingReport.ratingAfter, isNull);

    // Both attempts still show up for history/charts; only the training one
    // counts toward the training-only stats FSRS/scheduling/rating use.
    expect(progress.attemptsOf(key).length, 2);
    expect(progress.displayStats(key).count, 2);
    expect(progress.stats(key).count, 1);
    await db.close();
  });

  test('guest runs record nothing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final progress = await Progress.open(db);
    final deck = progress.freeDeck(const PlayConfig(mode: PlayMode.guest, setIds: ['initial:む すめふさほせ']));
    expect(deck, isEmpty); // unknown set id → empty
    final cards = progress.freeDeck(const PlayConfig(mode: PlayMode.guest, setIds: ['initial:むすめふさほせ']));
    expect(cards.length, 7);
    final run = play(cards, [for (var i = 0; i < 7; i++) (800, Outcome.known)]);
    final report = await progress.recordRun(run, const PlayConfig(mode: PlayMode.guest), DateTime.now());
    expect(report.runId, isNull);
    expect(await db.select(db.attempts).get(), isEmpty);
    expect(await db.select(db.runs).get(), isEmpty);
    expect(progress.rating, isNull);
    await db.close();
  });

  test('isIslandPlayable: journey mode needs every card of the island unlocked; all-known never gates it', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final progress = await Progress.open(db);

    // A fresh journey seeds only the first few cards of island 0.
    final partial = progress.islands[0];
    expect(partial.unlocked, lessThan(partial.total));
    expect(progress.isIslandPlayable(partial), isFalse);

    for (final id in partial.poemIds) {
      progress.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    final full = progress.islands[0];
    expect(full.unlocked, full.total);
    expect(progress.isIslandPlayable(full), isTrue);

    // All-known mode never gates a run, even on a (synthetic) partly
    // uncovered island: nothing stays locked once every card is unlocked.
    await progress.setLearningMode(LearningMode.allKnown);
    final stillPartial = IslandProgress(partial.index, partial.name, partial.poemIds, 1, 0, 0);
    expect(progress.isIslandPlayable(stillPartial), isTrue);
    await db.close();
  });

  test('switching journey → all-known → journey unlocks everything for good, with nothing left to celebrate',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final progress = await Progress.open(db);

    await progress.switchToAllKnown();
    expect(progress.trainer.unlocked.where((s) => !s.key.inverted).length, 100);

    await progress.setLearningMode(LearningMode.journey);
    final journey = JourneyState.of(progress);
    expect(journey.cardsUnlocked, 100);
    expect(journey.finished, isTrue, reason: 'every island already marked, not stuck mid-consolidation');
    expect(progress.islands.every((i) => progress.islandMarked(i.index)), isTrue);
    expect([for (final c in await db.select(db.islandCompletions).get()) c.runId], everyElement(isNull),
        reason: 'marked by the switch, not completed by a run');

    // Drive one island's cards solid through real practice: since it was
    // already marked complete by the switch, this earns no fresh celebration.
    final island = progress.islands[0];
    final cards = [for (final id in island.poemIds) CardRef(id)];
    for (var round = 0; round < TrainingTuning.newCardMinTimed; round++) {
      final run = play(cards, [for (final _ in cards) (400, Outcome.known)]);
      final report = await progress.recordRun(run, const PlayConfig(mode: PlayMode.training), DateTime.now());
      expect(report.islandsCompleted, isEmpty);
      expect(report.islandsReached, isEmpty);
    }
    expect(progress.islands[0].complete, isTrue, reason: 'genuinely solid now, just never re-celebrated');
    await db.close();
  });

  test('demo data seeds two weeks of a journey through the real training path', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final progress = await Progress.open(db);
    final days = <int>{};
    var lastFraction = 0.0;
    await seedDemoData(progress, onProgress: (day, total, fraction) {
      days.add(day);
      lastFraction = fraction;
      // Home stays open while the Simulation page seeds.
      if (progress.todayStale) unawaited(progress.refreshToday());
    });
    expect(days, {for (var d = 1; d <= DemoDataTuning.days; d++) d});
    expect(lastFraction, 1);
    final today = progress.todaySet()!;
    expect(today.reviews, greaterThan(0), reason: "today's set is built from the seeded history");
    // A fifth of the days are skipped, so some past days have no finished set.
    expect(progress.weekStamps().where((s) => s.done), isNotEmpty);
    final upright = progress.trainer.unlocked.where((s) => !s.key.inverted).length;
    expect(upright, inInclusiveRange(30, 90));
    expect(progress.islands.where((i) => i.reached).length, greaterThanOrEqualTo(3));
    expect(progress.islands.where((i) => i.complete), isNotEmpty);
    final completions = await db.select(db.islandCompletions).get();
    expect(completions, isNotEmpty);
    for (final c in completions) {
      expect(progress.islandsCompletedBy(c.runId!), contains(c.island), reason: 'completed by a journey run');
    }
    expect(progress.trainer.items.values.where((s) => s.card.state == fsrs.State.review), isNotEmpty);
    final graded = await (db.select(db.attempts)..where((a) => a.grade.isNotNull())).get();
    expect(graded.every((a) => a.fsrsStability != null && a.fsrsDue != null), isTrue);
    expect(graded.where((a) => a.fsrsRecall != null), isNotEmpty);
    expect((await db.select(db.attempts).get()).every((a) => a.revealAtUs != null && a.commitUs != null), isTrue);
    expect(progress.ratedRuns, isEmpty, reason: 'training never moves the rating');
    expect(progress.practiceDays.length, inInclusiveRange(DemoDataTuning.days * 0.6, DemoDataTuning.days));
    expect(progress.dueCount(DateTime.now().add(const Duration(days: 1))), greaterThan(0));
    // Free-play runs happened too: recorded for history, but never counted for SRS.
    expect(progress.runs.where((s) => s.mode == PlayMode.free), isNotEmpty);
    final allAttempts = progress.trainer.items.keys.fold<int>(0, (n, k) => n + progress.attemptsOf(k).length);
    final trainingAttempts = progress.trainer.items.keys.fold<int>(0, (n, k) => n + progress.stats(k).count);
    expect(allAttempts, greaterThan(trainingAttempts));
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
