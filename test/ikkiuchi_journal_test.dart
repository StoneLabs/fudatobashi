// A ranked 一騎打ち match the app never recorded (it was closed or killed
// after its first read) is a forfeit on the next start, with the reads and
// cards left of its last save: a loss, never a second record.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/field_parts.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_rating.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/state/progress.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const mode = IkkiuchiMode.blitz;
  final ranked = IkkiuchiSetup.ranked(mode, opponentRating: 1450, rows: 3);
  final perSide = mode.perSide;
  final started = DateTime(2026, 11, 8, 12);

  IkkiuchiMatchRecord played({required bool completed}) => IkkiuchiMatchRecord(
        setup: ranked,
        startedAt: started,
        endedAt: started.add(const Duration(minutes: 40)),
        completed: completed,
        playerLeft: 0,
        opponentLeft: 6,
      );

  /// The match as journalled after [reads] reads, [left] cards on each side.
  IkkiuchiMatchRecord soFar(List<IkkiuchiReadLog> reads, ({int player, int opponent}) left) => IkkiuchiMatchRecord(
        setup: ranked,
        startedAt: started,
        endedAt: started.add(Duration(minutes: reads.length)),
        memorised: const Duration(minutes: 6, seconds: 41, milliseconds: 500),
        completed: false,
        playerLeft: left.player,
        opponentLeft: left.opponent,
        reads: reads,
      );

  const taken = IkkiuchiReadLog(
    poemId: 12,
    cardSide: IkkiuchiSide.opponent,
    taker: IkkiuchiSide.player,
    playerFaults: 1,
    playerTake: Duration(milliseconds: 640),
    opponentTake: Duration(milliseconds: -80),
    field: IkkiuchiLaidField(opponent: [IkkiuchiRow([12, 7], [])], player: [IkkiuchiRow([3], [9], middle: [4])]),
    faults: [IkkiuchiFault(IkkiuchiSide.player, 4, Duration(milliseconds: 300))],
    sends: [IkkiuchiSent(3, FieldRow.lower, RowPart.right, 0)],
  );
  const karafuda = IkkiuchiReadLog(poemId: 40, opponentFaults: 2);

  test('a ranked match killed after its first read is one forfeit on the next start, as dealt', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await Progress.open(db);
    await first.journalIkkiuchi(soFar(const [], (player: perSide, opponent: perSide)));
    expect(first.ikkiuchi.matches, isEmpty);

    final restarted = await Progress.open(db);
    final m = restarted.ikkiuchi.matches.single;
    expect([m.ranked, m.completed, m.result, m.startedAt, m.endedAt, m.playerLeft, m.opponentLeft, m.reads],
        [true, false, IkkiuchiResult.gaveUp, started, started, perSide, perSide, isEmpty]);
    expect(m.memorised, const Duration(minutes: 6, seconds: 41, milliseconds: 500), reason: 'the memory time used');
    expect([m.setup.mode, m.setup.opponent, m.setup.opponentRating, m.setup.perSide, m.setup.rows, m.setup.memorise],
        [mode, IkkiuchiOpponent.tobi, 1450, perSide, 3, mode.memorise]);
    expect(restarted.ikkiuchi.counts(ranked: true), (played: 1, won: 0, lost: 1), reason: 'a loss');
    expect([for (final mode in IkkiuchiMode.values) restarted.ikkiuchi.of(mode).rankedPlayed], [0, 1, 0],
        reason: 'in its own mode');
    expect(m.rating, IkkiuchiRating.after((opponentRating: 1450, won: false), earlier: const [], rating: null),
        reason: 'rated as a loss');

    expect((await Progress.open(db)).ikkiuchi.matches, hasLength(1), reason: 'not forfeited again on a later start');
    await db.close();
  });

  test('the forfeit keeps the reads and the cards left of the last save', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await Progress.open(db);
    await first.journalIkkiuchi(soFar(const [], (player: perSide, opponent: perSide)));
    await first.journalIkkiuchi(soFar(const [taken], (player: perSide - 1, opponent: perSide)));
    await first.journalIkkiuchi(soFar(const [taken, karafuda], (player: perSide - 1, opponent: perSide - 1)));

    final m = (await Progress.open(db)).ikkiuchi.matches.single;
    expect([m.completed, m.endedAt, m.playerLeft, m.opponentLeft],
        [false, started.add(const Duration(minutes: 2)), perSide - 1, perSide - 1]);
    expect(m.reads, hasLength(2));
    final r = m.reads.first;
    expect([r.poemId, r.cardSide, r.taker, r.tied, r.playerFaults, r.opponentFaults, r.playerTake, r.opponentTake],
        [12, IkkiuchiSide.opponent, IkkiuchiSide.player, false, 1, 0, taken.playerTake, taken.opponentTake]);
    expect([r.field.toJson(), for (final f in r.faults) f.toJson(), for (final s in r.sends) s.toJson()], [
      {
        'opponent': [
          [[12, 7], <int>[], <int>[]],
        ],
        'player': [
          [[3], [4], [9]],
        ],
      },
      ['player', 4, 300000],
      [3, 0, 'right', 0],
    ]);
    final k = m.reads.last;
    expect([k.poemId, k.karafuda, k.taker, k.opponentFaults, k.playerTake], [40, true, null, 2, null]);
    await db.close();
  });

  test('a ranked match recorded in the app, played out or given up, leaves no forfeit behind', () async {
    for (final completed in [true, false]) {
      final db = AppDatabase(NativeDatabase.memory());
      final first = await Progress.open(db);
      await first.journalIkkiuchi(soFar(const [taken], (player: perSide - 1, opponent: perSide)));
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
