// How a 定位置 game is stored: its run with the setup, placing time and
// layout, its answers as 暗記練 keeps them, its placings in order; and what
// the stored games add up to on the hub and the page.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/teiichi_record.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/progress.dart';

import 'test_teiichi.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const teiichi = SideTrip.teiichi;

  Future<Progress> open(AppDatabase db) async {
    final p = await Progress.open(db);
    await p.setLearningMode(LearningMode.allKnown);
    return p;
  }

  test('a game keeps its setup, placing, layout, answers and placings, and they come back on load', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    const setup = TeiichiSetup(cards: 12, rows: 2);
    final played = playTeiichi(setup, placeMs: 1500, wrongAt: {2});
    await p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());

    final run = await db.select(db.sideTripRuns).getSingle();
    expect([run.game, run.ranked, run.level, run.score, run.rating, run.completed], [teiichi, false, null, null, null, true]);
    final meta = jsonDecode(run.meta) as Map<String, dynamic>;
    expect(meta[TeiichiMeta.cardsKey], 12);
    expect(meta[TeiichiMeta.rowsKey], 2);
    expect(meta[TeiichiMeta.customKey], isTrue);
    expect(meta[TeiichiMeta.placingKey], 12 * 1500);
    expect(AnkirenHalf.fromJson(meta[TeiichiMeta.layoutKey] as List).cards, played.placing.board.cards);

    final answers = await (db.select(db.sideTripAnswers)..orderBy([(a) => OrderingTerm.asc(a.seq)])).get();
    expect([for (final a in answers) a.poemId], played.game.prompts);
    expect([for (final a in answers) a.wrongTaps], [for (final a in played.game.answers) a.wrongTaps]);
    expect([for (final a in answers) a.responseUs], [for (final a in played.game.answers) a.responseUs]);
    expect(answers[2].firstTap, isNotNull);

    final placings = await (db.select(db.teiichiPlacings)..orderBy([(x) => OrderingTerm.asc(x.seq)])).get();
    expect([for (final x in placings) x.poemId], played.placing.order);
    expect([for (final x in placings) x.placingUs], everyElement(1500000));

    final again = await open(db);
    final record = again.sideTripsHub()[teiichi].placing;
    expect(record.games, 1);
    expect(record.last, (cards: 12, placing: const Duration(seconds: 18), firstTaps: 11));
    expect(record.best, isNull, reason: 'only games of the usual count of cards set a best');
    await db.close();
  });

  test('the best placing time is the fastest usual-sized game played to the end', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    Future<void> record(TeiichiSetup setup, int placeMs, {int? endAfter}) async {
      final played = playTeiichi(setup, placeMs: placeMs, endAfter: endAfter);
      await p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());
    }

    await record(TeiichiSetup.usual, 2000);
    await record(TeiichiSetup.usual, 1000, endAfter: 3);
    await record(const TeiichiSetup(cards: 24, rows: 3), 500);
    await record(TeiichiSetup.usual, 1500);
    final entry = p.sideTripsHub()[teiichi];
    expect(entry.placing.best, const Duration(milliseconds: TeiichiTuning.cards * 1500));
    expect(entry.placing.games, 4);
    expect(entry.games, 4);
    expect(entry.placing.last?.placing, const Duration(milliseconds: TeiichiTuning.cards * 1500));
    expect(p.sideTripsHub()[SideTrip.ankiren].games, 0, reason: '定位置 games are no 暗記練 games');
    await db.close();
  });

  test('a progress reset deletes the placings with the games', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await open(db);
    final played = playTeiichi(TeiichiSetup.usual);
    await p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());
    await p.resetProgress();
    expect(await db.select(db.teiichiPlacings).get(), isEmpty);
    expect(p.sideTripsHub()[teiichi].placing.games, 0);
    await db.close();
  });
}
