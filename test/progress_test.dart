import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/state/play_config.dart';
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

    // Reload from the same database.
    final again = await Progress.open(db);
    expect(again.sessions.length, 1);
    expect(again.stats(k0).count, progress.stats(k0).count);
    expect(again.trainer.items[k0]!.card.stability, progress.trainer.items[k0]!.card.stability);
    expect(again.rating, progress.rating);
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
}
