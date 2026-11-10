// 一騎打ち's experience: every card the player took, the memory time used by
// the minute, a win by the cards a side, a clear, a ranked match and the
// match that ends placement; a match given up keeps only its cards. It is settled as the match is recorded,
// stored with it, and added to the player's experience.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_rating.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/ikkiuchi_xp.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/xp_history.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const player = IkkiuchiSide.player, opponent = IkkiuchiSide.opponent;
  final at = DateTime(2026, 11, 9, 10);

  /// [took] reads the player took (the first a tie on their side), [lost]
  /// the opponent took, and a からふだ.
  List<IkkiuchiReadLog> reads(int took, int lost) => [
        for (var i = 0; i < took; i++)
          IkkiuchiReadLog(poemId: 1 + i, cardSide: i.isEven ? player : opponent, taker: player, tied: i == 0),
        for (var i = 0; i < lost; i++) IkkiuchiReadLog(poemId: 60 + i, cardSide: player, taker: opponent),
        const IkkiuchiReadLog(poemId: 99),
      ];

  /// The memory time a match used, unless given: 12½ minutes.
  const memorised = Duration(minutes: 12, seconds: 30);
  final memoryXp = (IkkiuchiXpTuning.memoryPerMinute * 12.5).round();

  IkkiuchiMatchRecord match(IkkiuchiSetup setup,
          {required int took,
          required int lost,
          required bool won,
          bool completed = true,
          Duration memory = memorised}) =>
      IkkiuchiMatchRecord(
        setup: setup,
        startedAt: at,
        endedAt: at.add(const Duration(minutes: 30)),
        memorised: memory,
        completed: completed,
        playerLeft: won ? 0 : 3,
        opponentLeft: won ? 3 : 0,
        reads: reads(took, lost),
      );

  final ranked = IkkiuchiSetup.ranked(IkkiuchiMode.rapid, opponentRating: 1745, rows: 3);
  const free = IkkiuchiSetup.free(opponentRating: 1200, perSide: 12, memorise: Duration(minutes: 5));
  List<(XpSource, int, int)> lines(XpAward award) => [for (final p in award.parts) (p.source, p.count, p.xp)];

  test('a ranked win: every card taken, a tie among them, the memory time, the win by the cards a side, the clear '
      'and ranked', () {
    final award = IkkiuchiXp.of(match(ranked, took: 24, lost: 21, won: true), placed: false);
    expect(lines(award), [
      (XpSource.taken, 24, 24 * IkkiuchiXpTuning.perCard),
      (XpSource.memory, memorised.inSeconds, memoryXp),
      (XpSource.won, 1, IkkiuchiXpTuning.winPerCard * IkkiuchiMode.rapid.perSide),
      (XpSource.clear, 1, IkkiuchiXpTuning.clear),
      (XpSource.ranked, 1, IkkiuchiXpTuning.ranked),
    ]);
    expect(
        award.total,
        24 * IkkiuchiXpTuning.perCard +
            memoryXp +
            IkkiuchiXpTuning.winPerCard * 25 +
            IkkiuchiXpTuning.clear +
            IkkiuchiXpTuning.ranked);
    expect(
        [IkkiuchiXpTuning.perCard, IkkiuchiXpTuning.memoryPerMinute, IkkiuchiXpTuning.winPerCard, IkkiuchiXpTuning.ranked],
        [900, 3000, 200, 500]);
  });

  test('a loss played to its end: its cards, the memory time, the clear and ranked, no win', () {
    expect(lines(IkkiuchiXp.of(match(ranked, took: 20, lost: 25, won: false), placed: false)), [
      (XpSource.taken, 20, 20 * IkkiuchiXpTuning.perCard),
      (XpSource.memory, memorised.inSeconds, memoryXp),
      (XpSource.clear, 1, IkkiuchiXpTuning.clear),
      (XpSource.ranked, 1, IkkiuchiXpTuning.ranked),
    ]);
  });

  test('a free win: the win by its own cards a side, nothing for ranked', () {
    expect(lines(IkkiuchiXp.of(match(free, took: 10, lost: 2, won: true), placed: false)), [
      (XpSource.taken, 10, 10 * IkkiuchiXpTuning.perCard),
      (XpSource.memory, memorised.inSeconds, memoryXp),
      (XpSource.won, 1, IkkiuchiXpTuning.winPerCard * 12),
      (XpSource.clear, 1, IkkiuchiXpTuning.clear),
    ]);
  });

  test('the memory time used earns the same for every minute, however short or long', () {
    int memory(Duration used) => IkkiuchiXp.of(match(free, took: 10, lost: 2, won: true, memory: used), placed: false)
        .parts
        .singleWhere((p) => p.source == XpSource.memory)
        .xp;
    expect(memory(const Duration(minutes: 1)), IkkiuchiXpTuning.memoryPerMinute);
    expect(memory(const Duration(seconds: 90)), IkkiuchiXpTuning.memoryPerMinute * 3 ~/ 2, reason: 'cut short by 覚えた');
    expect(memory(const Duration(minutes: 15, seconds: 7)), (IkkiuchiXpTuning.memoryPerMinute * (15 + 7 / 60)).round());
    expect(IkkiuchiXp.of(match(free, took: 10, lost: 2, won: true, memory: Duration.zero), placed: false).parts
        .map((p) => p.source), isNot(contains(XpSource.memory)), reason: 'none used, no line');
  });

  test('a match given up keeps only its cards, even the one that would end placement', () {
    final givenUp = match(ranked, took: 8, lost: 4, won: true, completed: false);
    expect(givenUp.result, IkkiuchiResult.gaveUp);
    expect(lines(IkkiuchiXp.of(givenUp, placed: true)), [(XpSource.taken, 8, 8 * IkkiuchiXpTuning.perCard)],
        reason: 'not its memory time either');
    expect(IkkiuchiXp.of(match(ranked, took: 0, lost: 4, won: false, completed: false), placed: false).parts, isEmpty,
        reason: 'no card, nothing');
  });

  test("only the ranked match that ends a mode's placement earns its bonus, once a mode; recorded, each keeps its XP",
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    Future<bool> placedBy(IkkiuchiMode mode, int i) async {
      final report = await p.recordIkkiuchi(
          match(p.ikkiuchi.of(mode).rankedSetup(rows: mode.defaultRows), took: 22, lost: 23, won: i.isEven));
      return report.match.xp!.parts.any((x) => x.source == XpSource.placement);
    }

    final placed = <bool>[];
    for (var i = 0; i < IkkiuchiRating.placementMatches + 2; i++) {
      placed.add(await placedBy(IkkiuchiMode.rapid, i));
    }
    expect(placed, [
      for (var i = 0; i < IkkiuchiRating.placementMatches + 2; i++) i == IkkiuchiRating.placementMatches - 1,
    ]);
    final blitz = [for (var i = 0; i < IkkiuchiRating.placementMatches; i++) await placedBy(IkkiuchiMode.blitz, i)];
    expect(blitz.last, isTrue, reason: "Blitz's own placement ends with its own bonus");
    final fourth = (await Progress.open(db)).ikkiuchi.matches[IkkiuchiRating.placementMatches - 1];
    expect(lines(fourth.xp!).last, (XpSource.placement, 1, IkkiuchiXpTuning.placement), reason: 'as stored');
    await db.close();
  });

  test('recording a match adds its XP to the player\'s, which the ledger rebuilds the same on load', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    final first = await p.recordIkkiuchi(match(free, took: 10, lost: 2, won: true));
    expect([first.xp.before, first.xp.award.total, p.xp.total],
        [0, first.match.xp!.total, first.match.xp!.total]);
    final second = await p.recordIkkiuchi(match(ranked, took: 3, lost: 6, won: false, completed: false));
    expect([second.xp.before, second.xp.after, p.xp.total],
        [first.xp.after, first.xp.after + 3 * IkkiuchiXpTuning.perCard, second.xp.after]);

    final again = await Progress.open(db);
    expect(again.xp.total, p.xp.total, reason: 'the stored awards, added up again');
    final gains = XpHistory.gainsOf(again).ikkiuchi;
    expect([for (final m in again.ikkiuchi.matches) lines(gains[m.id]!.award)],
        [lines(first.match.xp!), lines(second.match.xp!)]);
    expect([for (final m in again.ikkiuchi.matches) lines(m.xp!)], [lines(first.match.xp!), lines(second.match.xp!)],
        reason: 'each match keeps its award');
    await db.close();
  });

  test('an award comes back from its JSON line by line', () {
    const award = XpAward([XpPart(XpSource.taken, 24, 4800), XpPart(XpSource.won, 1, 1000)]);
    expect(lines(XpAward.fromJson(award.toJson())), lines(award));
    expect(award.toJson(), [
      ['taken', 24, 4800],
      ['won', 1, 1000],
    ]);
  });
}
