// How a 一騎打ち match is stored: its row with the setup, result, cards left
// and faults, its reads in order, and both coming back on load.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_cards.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/state/ikkiuchi_records.dart';
import 'package:fudatobashi/state/progress.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const tobi = IkkiuchiSide.tobi, player = IkkiuchiSide.player;
  const setup = IkkiuchiSetup(perSide: 10, memorise: Duration(minutes: 3), rating: 2000);

  final record = IkkiuchiMatchRecord(
    setup: setup,
    startedAt: DateTime(2026, 11, 8, 10),
    endedAt: DateTime(2026, 11, 8, 10, 20),
    result: IkkiuchiResult.lost,
    playerLeft: 3,
    tobiLeft: 0,
    reads: const [
      IkkiuchiReadLog(
          poemId: 12,
          end: IkkiuchiReadEnd(taker: player, cardSide: tobi),
          playerTake: Duration(milliseconds: 640),
          tobiTake: Duration(milliseconds: 900)),
      IkkiuchiReadLog(poemId: 77, end: IkkiuchiReadEnd(playerFaults: {tobi, player})),
      IkkiuchiReadLog(
          poemId: 5,
          end: IkkiuchiReadEnd(taker: tobi, cardSide: player, tied: true, tobiFaults: {tobi}),
          playerTake: Duration(milliseconds: 410),
          tobiTake: Duration(milliseconds: 400)),
    ],
  );

  test('a match keeps its setup, result, cards left, faults and reads, and they come back on load', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    expect(p.ikkiuchi.matches, isEmpty);
    final row = await p.recordIkkiuchi(record);

    expect(p.ikkiuchi.matches, [row]);
    expect(
        [row.startedAt, row.endedAt, row.perSide, row.memoriseMs, row.tobiRating, row.result],
        [record.startedAt, record.endedAt, 10, 180000, 2000.0, IkkiuchiResult.lost]);
    expect([row.playerLeft, row.tobiLeft, row.playerFaults, row.tobiFaults], [3, 0, 2, 1]);
    expect(IkkiuchiRecords.setupOf(row), setup);

    final again = await Progress.open(db);
    expect(again.ikkiuchi.matches, [row]);
    final reads = await again.ikkiuchiReadsOf(row.id);
    expect([
      for (final r in reads)
        (r.seq, r.poemId, r.karafuda, r.taker, r.tied, r.playerFaults, r.tobiFaults, r.playerUs, r.tobiUs)
    ], [
      (0, 12, false, player, false, 0, 0, 640000, 900000),
      (1, 77, true, null, false, 2, 0, null, null),
      (2, 5, false, tobi, true, 0, 1, 410000, 400000),
    ]);
    await db.close();
  });

  test('a reset forgets every match and its reads', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    final row = await p.recordIkkiuchi(record);
    await p.resetProgress();
    expect(p.ikkiuchi.matches, isEmpty);
    expect(await p.ikkiuchiReadsOf(row.id), isEmpty);
    expect(await db.select(db.ikkiuchiMatches).get(), isEmpty);
    await db.close();
  });

  test('the result: an emptied side, else the side with fewer, and a match ended by the player is given up', () {
    expect(IkkiuchiResult.of(playerLeft: 0, tobiLeft: 4, gaveUp: false), IkkiuchiResult.won);
    expect(IkkiuchiResult.of(playerLeft: 2, tobiLeft: 0, gaveUp: false), IkkiuchiResult.lost);
    expect(IkkiuchiResult.of(playerLeft: 1, tobiLeft: 3, gaveUp: false), IkkiuchiResult.won);
    expect(IkkiuchiResult.of(playerLeft: 1, tobiLeft: 3, gaveUp: true), IkkiuchiResult.gaveUp);
  });
}
