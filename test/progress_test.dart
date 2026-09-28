import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
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

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  PlaySession play(List<CardRef> cards, List<(int ms, Outcome o)> script) {
    final s = PlaySession(cards);
    var t = const Duration(seconds: 100);
    for (final (ms, o) in script) {
      s.revealed(t);
      t += Duration(milliseconds: ms);
      s.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: o);
      t += const Duration(milliseconds: 100);
    }
    return s;
  }

  test('a tracked run is stored, reviewed by FSRS and survives a reload', () async {
    final executor = NativeDatabase.memory();
    final db = AppDatabase(executor);
    final progress = await Progress.open(db);
    final planned = await progress.planTraining();
    expect(planned.unlockedBefore.map((k) => poems[k.poemId].kimariji), ['む', 'す', 'め']);

    final cards = planned.cards.take(4).toList();
    final run = play(cards, [(900, Outcome.known), (4000, Outcome.known), (700, Outcome.dontKnow), (1200, Outcome.known)]);
    final report = await progress.recordRun(run, const PlayConfig(mode: PlayMode.training), DateTime.now());

    expect(report.sessionId, isNotNull);
    expect(report.total, isNotNull);
    expect(report.ratingAfter, isNotNull);
    final k0 = ItemKey(cards[0].poemId, cards[0].inverted);
    expect(progress.stats(k0).seen, isTrue);
    expect(progress.trainer.items[k0]!.reviewed, isTrue);
    // One `Outcome.dontKnow` in the script above — the History tab's miss count.
    expect(progress.missesIn(report.sessionId!), 1);

    // Reload from the same database.
    final again = await Progress.open(db);
    expect(again.sessions.length, 1);
    expect(again.stats(k0).count, progress.stats(k0).count);
    expect(again.trainer.items[k0]!.card.stability, progress.trainer.items[k0]!.card.stability);
    expect(again.rating, progress.rating);
    expect(again.missesIn(report.sessionId!), 1);
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
    expect(freeReport.sessionId, isNotNull);
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
    expect(trainingReport.sessionId, isNotNull);
    expect(progress.trainer.items[key]!.reviewed, isTrue);
    expect(progress.trainer.items[key]!.card.due, isNot(beforeDue));
    expect(progress.stats(key).seen, isTrue);
    expect(progress.rating, isNotNull);
    expect(trainingReport.ratingAfter, isNotNull);

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
    expect(report.sessionId, isNull);
    expect(await db.select(db.attempts).get(), isEmpty);
    expect(await db.select(db.sessions).get(), isEmpty);
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

  test('demo data seeds two weeks of a journey through the real training path', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final progress = await Progress.open(db);
    final days = <int>{};
    var lastFraction = 0.0;
    await seedDemoData(progress, onProgress: (day, total, fraction) {
      days.add(day);
      lastFraction = fraction;
    });
    expect(days, {for (var d = 1; d <= DemoDataTuning.days; d++) d});
    expect(lastFraction, 1);
    final upright = progress.trainer.unlocked.where((s) => !s.key.inverted).length;
    expect(upright, inInclusiveRange(30, 90));
    expect(progress.islands.where((i) => i.reached).length, greaterThanOrEqualTo(3));
    expect(progress.islands.where((i) => i.complete), isNotEmpty);
    expect(progress.trainer.items.values.where((s) => s.card.state == fsrs.State.review), isNotEmpty);
    expect(progress.ratingPoints, isNotEmpty);
    expect(progress.practiceDays.length, DemoDataTuning.days);
    expect(progress.dueCount(DateTime.now().add(const Duration(days: 1))), greaterThan(0));
    // Free-play runs happened too: recorded for history, but never counted for SRS.
    expect(progress.sessions.where((s) => s.mode == PlayMode.free.index), isNotEmpty);
    final allAttempts = progress.trainer.items.keys.fold<int>(0, (n, k) => n + progress.attemptsOf(k).length);
    final trainingAttempts = progress.trainer.items.keys.fold<int>(0, (n, k) => n + progress.stats(k).count);
    expect(allAttempts, greaterThan(trainingAttempts));
    await db.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
