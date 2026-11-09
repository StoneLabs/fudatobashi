// How a 一騎打ち match is stored: its row with the setup, how far it was
// played and the cards left, its reads in order with the field each was
// played on, its faults and its 送り札, and both coming back on load as the
// same records; what is worked out from them (the result, the faults, the
// counts, the free setup to restore); and the day it was played on.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/day_window.dart';
import 'package:fudatobashi/domain/field_parts.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/stats_history.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const opponent = IkkiuchiSide.opponent, player = IkkiuchiSide.player;

  IkkiuchiSetup setup({bool ranked = false, int perSide = 10, double rating = 2000}) => IkkiuchiSetup(
      ranked: ranked,
      opponent: IkkiuchiOpponent.tobi,
      opponentRating: rating,
      perSide: perSide,
      memorise: const Duration(minutes: 3));

  IkkiuchiMatchRecord match(DateTime at,
          {IkkiuchiSetup? played, bool completed = true, int playerLeft = 3, int opponentLeft = 0,
          List<IkkiuchiReadLog> reads = const []}) =>
      IkkiuchiMatchRecord(
        setup: played ?? setup(),
        startedAt: at,
        endedAt: at.add(const Duration(minutes: 20)),
        completed: completed,
        playerLeft: playerLeft,
        opponentLeft: opponentLeft,
        reads: reads,
      );

  // Tobi's 下段 holds 12 and 5, the player's 上段 34 and 56 with 8 in its
  // open middle.
  const field = IkkiuchiLaidField(opponent: [
    IkkiuchiRow([12], [5]),
  ], player: [
    IkkiuchiRow([], []),
    IkkiuchiRow([], []),
    IkkiuchiRow([34], [56], middle: [8]),
  ]);
  final reads = [
    IkkiuchiReadLog.of(12, const IkkiuchiReadEnd(taker: player, cardSide: opponent),
            field: field,
            playerTake: const Duration(milliseconds: 640),
            opponentTake: const Duration(milliseconds: 900))
        .withSent(const IkkiuchiSent(34, FieldRow.lower, RowPart.left, 1)),
    IkkiuchiReadLog.of(77, const IkkiuchiReadEnd(playerFaults: {opponent, player}),
            field: field.without(12).withSent(const IkkiuchiSent(34, FieldRow.lower, RowPart.left, 1)),
            faults: const [
              IkkiuchiFault(player, 8, Duration(milliseconds: 410)),
              IkkiuchiFault(player, 5, Duration(milliseconds: 1250)),
            ])
        .withSent(const IkkiuchiSent(5, FieldRow.upper, RowPart.middle, 0))
        .withSent(const IkkiuchiSent(34, FieldRow.upper, RowPart.right, 1)),
    IkkiuchiReadLog.of(5, const IkkiuchiReadEnd(taker: opponent, cardSide: opponent, tied: true, tobiFaults: {player}),
        faults: const [IkkiuchiFault(opponent, 56, Duration(milliseconds: -30))],
        playerTake: const Duration(milliseconds: -20),
        opponentTake: const Duration(milliseconds: -10)),
  ];
  final played = match(DateTime(2026, 11, 8, 10), played: setup(ranked: true), reads: reads);

  /// Everything a record holds but what storing it adds (its id and
  /// rating), to compare two.
  List<Object?> fields(IkkiuchiMatchRecord m) => [
        m.setup.ranked,
        m.setup.opponent,
        m.setup.opponentRating,
        m.setup.perSide,
        m.setup.memorise,
        m.startedAt,
        m.endedAt,
        m.completed,
        m.playerLeft,
        m.opponentLeft,
        for (final r in m.reads) ...[
          (r.poemId, r.cardSide, r.taker, r.tied, r.playerFaults, r.opponentFaults, r.playerTake, r.opponentTake),
          r.field.toJson(),
          [for (final f in r.faults) f.toJson()],
          [for (final s in r.sends) s.toJson()],
        ],
      ];

  test('a match keeps its setup, times, end, cards left and reads, and comes back the same on load', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    expect(p.ikkiuchi.matches, isEmpty);
    final stored = await p.recordIkkiuchi(played);

    expect([stored.id, stored.rating], [isNotNull, isNotNull], reason: 'a ranked match is rated');
    expect(fields(stored), fields(played), reason: 'as recorded');
    List<Object?> all(Progress p) => [
          for (final m in p.ikkiuchi.matches) [m.id, m.rating, ...fields(m)],
        ];
    expect(all(p), [
      [stored.id, stored.rating, ...fields(stored)],
    ]);
    expect([for (final r in stored.reads) (r.karafuda, r.playerFaults, r.opponentFaults)],
        [(false, 0, 0), (true, 2, 0), (false, 0, 1)]);

    expect(all(await Progress.open(db)), all(p));
    await db.close();
  });

  test('each read comes back with the field it was played on, who faulted where, and where each 送り札 went',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    await (await Progress.open(db)).recordIkkiuchi(played);
    final [first, second, third] = (await Progress.open(db)).ikkiuchi.matches.single.reads;

    expect([first.field.opponent.single.left, first.field.opponent.single.right], [
      [12],
      [5],
    ]);
    expect([for (final r in first.field.player) [r.left, r.middle, r.right]], [
      [<int>[], <int>[], <int>[]],
      [<int>[], <int>[], <int>[]],
      [[34], [8], [56]],
    ]);
    expect(first.field.spotOf(8), const IkkiuchiSpot(player, FieldRow.upper, RowPart.middle, 0));
    expect(first.faults, isEmpty);
    expect([for (final s in first.sends) (s.card, s.row, s.part, s.index)], [(34, FieldRow.lower, RowPart.left, 1)]);

    expect(second.field.spotOf(34), const IkkiuchiSpot(opponent, FieldRow.lower, RowPart.left, 0),
        reason: 'sent to Tobi after the first read, laid at the end his left group had');
    expect([for (final f in second.faults) (f.by, f.card, f.at)], [
      (player, 8, const Duration(milliseconds: 410)),
      (player, 5, const Duration(milliseconds: 1250)),
    ]);
    expect([for (final s in second.sends) (s.card, s.row, s.part, s.index)], [
      (5, FieldRow.upper, RowPart.middle, 0),
      (34, FieldRow.upper, RowPart.right, 1),
    ]);

    expect(third.field.toJson(), IkkiuchiLaidField.empty.toJson(), reason: 'none given');
    expect([for (final f in third.faults) (f.by, f.card, f.at.inMicroseconds)], [(opponent, 56, -30000)]);
    expect(third.sends, isEmpty);
    await db.close();
  });

  test('a 送り札 moves its card off its side and lays it where it went on the other', () {
    final sent = field.withSent(const IkkiuchiSent(56, FieldRow.middle, RowPart.right, 0));
    expect(sent.spotOf(56), const IkkiuchiSpot(opponent, FieldRow.middle, RowPart.right, 0));
    expect(sent.cardsOf(player), [34, 8]);
    expect(sent.opponent, hasLength(2), reason: 'a row added for it');
    final back = sent.withSent(const IkkiuchiSent(56, FieldRow.upper, RowPart.middle, 0));
    expect(back.spotOf(56), const IkkiuchiSpot(player, FieldRow.upper, RowPart.middle, 0));
    expect(back.player[2].middle, [56, 8], reason: 'laid left of 8');
    expect(field.withSent(const IkkiuchiSent(99, FieldRow.lower, RowPart.left, 0)).toJson(), field.toJson(),
        reason: 'a card on neither side');
    expect(field.without(12).cardsOf(opponent), [5]);
  });

  test('the reads of each match come back with their own match, in order', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    await p.recordIkkiuchi(match(DateTime(2026, 11, 8, 9), reads: reads.reversed.toList()));
    await p.recordIkkiuchi(match(DateTime(2026, 11, 8, 10), reads: reads.take(1).toList()));
    await p.recordIkkiuchi(match(DateTime(2026, 11, 8, 11)));
    final again = await Progress.open(db);
    expect([for (final m in again.ikkiuchi.matches) [for (final r in m.reads) r.poemId]], [
      [5, 77, 12],
      [12],
      <int>[],
    ]);
    await db.close();
  });

  test('the result: given up unless played to its end; then won only with fewer cards left', () {
    IkkiuchiResult result(bool completed, int playerLeft, int opponentLeft) =>
        match(DateTime(2026), completed: completed, playerLeft: playerLeft, opponentLeft: opponentLeft).result;
    expect(result(true, 0, 4), IkkiuchiResult.won);
    expect(result(true, 2, 0), IkkiuchiResult.lost);
    expect(result(true, 3, 3), IkkiuchiResult.lost, reason: 'a tie is no win');
    expect(result(false, 0, 4), IkkiuchiResult.gaveUp);
    expect(result(false, 10, 10), IkkiuchiResult.gaveUp);
  });

  test('the faults over a match add up its reads\', a fault on both sides counting two', () {
    expect([played.playerFaults, played.opponentFaults], [2, 1]);
    expect([match(DateTime(2026)).playerFaults, match(DateTime(2026)).opponentFaults], [0, 0]);
  });

  test('the counts: played, won and lost, a match given up counting as lost, of a kind when asked', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    final at = DateTime(2026, 11, 8, 10);
    await p.recordIkkiuchi(match(at, playerLeft: 0, opponentLeft: 2));
    await p.recordIkkiuchi(match(at, playerLeft: 4, opponentLeft: 0));
    await p.recordIkkiuchi(match(at, completed: false));
    await p.recordIkkiuchi(match(at, played: setup(ranked: true), playerLeft: 0, opponentLeft: 1));
    expect(p.ikkiuchi.counts(), (played: 4, won: 2, lost: 2));
    expect(p.ikkiuchi.counts(ranked: false), (played: 3, won: 1, lost: 2));
    expect(p.ikkiuchi.counts(ranked: true), (played: 1, won: 1, lost: 0));
    await db.close();
  });

  test('free play starts as the last free match was set up, a ranked one after it aside', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    final first = p.ikkiuchi.freeSetup;
    expect([first.ranked, first.perSide, first.memorise, first.opponentRating],
        [false, IkkiuchiSetup.firstFree.perSide, IkkiuchiSetup.firstFree.memorise, IkkiuchiSetup.firstFree.opponentRating]);
    await p.recordIkkiuchi(match(DateTime(2026, 11, 8, 10), played: setup(perSide: 7, rating: 850)));
    await p.recordIkkiuchi(match(DateTime(2026, 11, 8, 11), played: setup(ranked: true, perSide: 25, rating: 1500)));
    final free = (await Progress.open(db)).ikkiuchi.freeSetup;
    expect([free.ranked, free.perSide, free.opponentRating], [false, 7, 850]);
    await db.close();
  });

  test('a reset forgets every match and its reads', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    await p.recordIkkiuchi(played);
    await p.resetProgress();
    expect(p.ikkiuchi.matches, isEmpty);
    expect(await db.select(db.ikkiuchiMatches).get(), isEmpty);
    expect(await db.select(db.ikkiuchiReads).get(), isEmpty);
    await db.close();
  });

  test('a match is stored on the practice day it started on, and that day counts as played', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    await p.recordIkkiuchi(match(yesterday));
    await p.recordIkkiuchi(match(now));

    final days = [for (final r in await db.select(db.ikkiuchiMatches).get()) r.day];
    expect(days, [p.dayAt(yesterday).number, p.dayAt(now).number]);
    expect(await db.select(db.days).get(), hasLength(2), reason: 'each day stored');

    final reopened = await Progress.open(db);
    final today = reopened.dayAt(now).date;
    expect(reopened.dayActivity.keys, containsAll([today, reopened.dayAt(yesterday).date]));
    expect(reopened.activeStreak(now), 2, reason: 'a day with a match is a day played');
    expect(reopened.practiceLog[today]?.active, isTrue, reason: 'the calendar marks it');
    expect(reopened.practiceLog[today]?.games, 1);
    expect(DayWindow.dateOf(days.last), today);
    await db.close();
  });
}
