// A ranked 一騎打ち match the app never recorded (it was closed or killed
// after its first read) is a forfeit on the next start: a loss, never a
// second record.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_rating.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/state/progress.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const ranked = IkkiuchiSetup.ranked(opponentRating: 1450);
  const perSide = IkkiuchiRankedTuning.perSide;
  final started = DateTime(2026, 11, 8, 12);

  IkkiuchiMatchRecord played({required bool completed}) => IkkiuchiMatchRecord(
        setup: ranked,
        startedAt: started,
        endedAt: started.add(const Duration(minutes: 40)),
        completed: completed,
        playerLeft: 0,
        opponentLeft: 6,
      );

  test('a ranked match killed after its first read is one forfeit on the next start, as dealt', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await Progress.open(db);
    await first.journalIkkiuchi(ranked, started);
    expect(first.ikkiuchi.matches, isEmpty);

    final restarted = await Progress.open(db);
    final m = restarted.ikkiuchi.matches.single;
    expect([m.ranked, m.completed, m.result, m.startedAt, m.endedAt, m.playerLeft, m.opponentLeft, m.reads],
        [true, false, IkkiuchiResult.gaveUp, started, started, perSide, perSide, isEmpty]);
    expect([m.setup.opponent, m.setup.opponentRating, m.setup.perSide, m.setup.memorise],
        [IkkiuchiOpponent.tobi, 1450, perSide, IkkiuchiRankedTuning.memorise]);
    expect(restarted.ikkiuchi.counts(ranked: true), (played: 1, won: 0, lost: 1), reason: 'a loss');
    expect(m.rating, IkkiuchiRating.after((opponentRating: 1450, won: false), earlier: const [], rating: null),
        reason: 'rated as a loss');

    expect((await Progress.open(db)).ikkiuchi.matches, hasLength(1), reason: 'not forfeited again on a later start');
    await db.close();
  });

  test('a ranked match recorded in the app, played out or given up, leaves no forfeit behind', () async {
    for (final completed in [true, false]) {
      final db = AppDatabase(NativeDatabase.memory());
      final first = await Progress.open(db);
      await first.journalIkkiuchi(ranked, started);
      await first.recordIkkiuchi(played(completed: completed));
      final matches = (await Progress.open(db)).ikkiuchi.matches;
      expect([for (final m in matches) (m.completed, m.playerLeft)], [(completed, 0)], reason: 'completed: $completed');
      await db.close();
    }
  });

  test('a journal that cannot be read is dropped, recording nothing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await Progress.open(db);
    await db.into(db.keyValues).insert(KeyValuesCompanion.insert(key: 'ikkiuchiJournal', value: '{"ranked":'));
    expect((await Progress.open(db)).ikkiuchi.matches, isEmpty);
    expect(await db.select(db.keyValues).get(), isNot(contains(predicate<KeyValue>((k) => k.key == 'ikkiuchiJournal'))));
    await db.close();
  });
}
