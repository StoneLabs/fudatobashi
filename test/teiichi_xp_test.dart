// 定位置 earns experience by 暗記練's rules: level and ranked games only, the
// cards never placed earn nothing.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/teiichi_placing.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/side_trips.dart';
import 'package:fudatobashi/state/xp_history.dart';

import 'test_teiichi.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Progress> open(AppDatabase db) async {
    final p = await Progress.open(db);
    await p.setLearningMode(LearningMode.allKnown);
    return p;
  }

  Future<SideTripReport> record(Progress p, ({TeiichiPlacing placing, AnkirenGame game}) played) =>
      p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());

  /// What 暗記練's rules give the last game recorded, scored on a ledger of
  /// its own.
  XpGain byAnkirenRules(Progress p) =>
      XpLedger().addAnkiren(XpHistory.ankirenRunOf(p.sideTrips, p.sideTrips.runs.last));

  test('a level game earns what the same game earns in 暗記練, and it comes back on load', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    final report = await record(p, playTeiichi(TeiichiSetup.forLevel(1), strikes: true, wrongAt: {1}));
    final xp = report.xp!;
    expect(xp.award.total, greaterThan(0));
    expect(xp.award.parts.map((x) => x.source), contains(XpSource.clear));
    expect(xp.award.total, byAnkirenRules(p).award.total);
    expect(p.xp.total, xp.award.total);

    final again = await open(db);
    expect(again.xp.total, xp.award.total, reason: 'the ledger is rebuilt from the stored games');
    expect(XpHistory.gainsOf(again).teiichi[again.sideTrips.runs.last.id]!.award.total, xp.award.total);
    await db.close();
  });

  test('a game ended early earns only what its cards earned, and no clear', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    final report = await record(p, playTeiichi(TeiichiSetup.forLevel(1), strikes: true, endAfter: 3));
    expect(report.xp!.award.total, greaterThan(0));
    expect(report.xp!.award.parts.map((x) => x.source), isNot(contains(XpSource.clear)));
    await db.close();
  });

  test('cards never placed are never called, so they earn nothing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    final all = await record(p, playTeiichi(TeiichiSetup.forLevel(1), strikes: true));
    final some = await record(p, playTeiichi(TeiichiSetup.forLevel(1), strikes: true, placeCards: 4));
    final perCard = all.xp!.award.parts.firstWhere((x) => x.source == XpSource.firstTap);
    final fewer = some.xp!.award.parts.firstWhere((x) => x.source == XpSource.firstTap);
    expect(perCard.count, 8);
    expect(fewer.count, 4);
    await db.close();
  });

  test('a custom game earns nothing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    final report = await record(p, playTeiichi(const TeiichiSetup(cards: 8, rows: 2)));
    expect(report.xp!.award.total, 0);
    expect(p.xp.total, 0);
    await db.close();
  });

  test('a ranked game earns the clear and ranked bonuses; a forfeit nothing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    final done = await record(p, playTeiichi(const TeiichiSetup.ranked()));
    final sources = done.xp!.award.parts.map((x) => x.source);
    expect(sources, containsAll([XpSource.clear, XpSource.ranked]));
    final forfeit = await record(p, playTeiichi(const TeiichiSetup.ranked(), endAfter: 5));
    expect(forfeit.xp!.award.total, 0);
    await db.close();
  });
}
