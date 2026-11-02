// A ranked 定位置 game the app never recorded (it was killed) is a forfeit on
// the next start, as in the main game, and never a second record.
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/teiichi_placing.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/progress.dart';

import 'test_teiichi.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const setup = TeiichiSetup.ranked();
  final deck = [for (var id = 1; id <= setup.cards; id++) id];
  final dealt = DateTime(2026, 11, 2, 12);

  Future<Progress> open(AppDatabase db) async {
    final p = await Progress.open(db);
    await p.setLearningMode(LearningMode.allKnown);
    return p;
  }

  List<SideTripRun> games(Progress p) => p.sideTrips.runsOf(SideTrip.teiichi).toList();

  test('a ranked game killed after the deal is one forfeit at 0 on the next start, counting for the rating', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await open(db);
    await first.journalTeiichi(deck, dealt);
    expect(games(first), isEmpty);

    final restarted = await open(db);
    final run = games(restarted).single;
    expect((run.ranked, run.score, run.performance, run.completed, run.startedAt), (true, 0, 0, false, dealt));
    expect(restarted.sideTrips.teiichiRecordOf(run).forfeit, isTrue);
    expect(restarted.sideTripsHub()[SideTrip.teiichi].rating, 0);
    expect(restarted.sideTrips.rankedGames(SideTrip.teiichi), 1);

    expect(games(await open(db)), hasLength(1), reason: 'not forfeited again on a later start');
    await db.close();
  });

  test('a ranked game played to the end leaves no forfeit behind', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await open(db);
    await first.journalTeiichi(deck, dealt);
    final played = playTeiichi(setup);
    await first.recordTeiichi(played.placing, played.game, startedAt: dealt);

    final run = games(await open(db)).single;
    expect(run.completed, isTrue);
    expect(run.score, greaterThan(0));
    await db.close();
  });

  test('a ranked game forfeited in the app is one forfeit, not two', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await open(db);
    await first.journalTeiichi(deck, dealt);
    final placing = TeiichiPlacing(setup, deck)..stop(const Duration(seconds: 5));
    await first.recordTeiichi(placing, placing.recall(Random(1))..end(), startedAt: dealt);
    expect(games(first), hasLength(1));

    final runs = games(await open(db));
    expect(runs, hasLength(1));
    expect(runs.single.completed, isFalse);
    await db.close();
  });

  test('a level game, which is never journalled, gives no forfeit on a restart', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final first = await open(db);
    final played = playTeiichi(TeiichiSetup.forLevel(0), strikes: true);
    await first.recordTeiichi(played.placing, played.game, startedAt: dealt);
    expect(games(await open(db)), hasLength(1));
    await db.close();
  });
}
