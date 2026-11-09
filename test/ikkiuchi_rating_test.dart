// 一騎打ち's ranked rating, one for each mode: placed by the first matches
// against Tobi at the estimate so far, each moving it by its step, then
// moved Elo-style by each match against Tobi drawn near the player's
// rating; a match given up is a loss. Every ranked match keeps the rating
// after it, and the ratings replay from the stored matches. Each mode is
// placed and rated on its own matches, with its own draws.
import 'dart:math' as math;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_rating.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/state/ikkiuchi_records.dart';
import 'package:fudatobashi/state/progress.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final placing = IkkiuchiRating.placementMatches;
  const steps = IkkiuchiRankedTuning.placementSteps;
  const k = IkkiuchiRankedTuning.provisionalK;
  final at = DateTime(2026, 11, 8, 10);

  /// A ranked match of [setup], won, lost, or given up when not [completed].
  IkkiuchiMatchRecord ranked(IkkiuchiSetup setup, {required bool won, bool completed = true}) => IkkiuchiMatchRecord(
        setup: setup,
        startedAt: at,
        endedAt: at.add(const Duration(minutes: 40)),
        completed: completed,
        playerLeft: won ? 0 : 4,
        opponentLeft: won ? 3 : 0,
      );

  /// Plays the next ranked match of [mode] as offered, [won] or not.
  Future<IkkiuchiMatchRecord> play(Progress p,
          {required bool won, bool completed = true, IkkiuchiMode mode = IkkiuchiMode.rapid}) async =>
      (await p.recordIkkiuchi(
              ranked(p.ikkiuchi.of(mode).rankedSetup(rows: mode.defaultRows), won: won, completed: completed)))
          .match;

  test('the expected score: a half when even, more against a weaker opponent, the two sides adding to one', () {
    expect(IkkiuchiRating.expected(1500, 1500), 0.5);
    expect(IkkiuchiRating.expected(1700, 1500), greaterThan(0.5));
    expect(IkkiuchiRating.expected(1700, 1500) + IkkiuchiRating.expected(1500, 1700), closeTo(1, 1e-12));
  });

  test("a mode's ranked match is always the same: Tobi, its cards a side and memory time, in the rows given",
      () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    for (final mode in IkkiuchiMode.values) {
      for (final rows in mode.rowChoices) {
        final setup = p.ikkiuchi.of(mode).rankedSetup(rows: rows);
        expect([setup.ranked, setup.mode, setup.opponent, setup.perSide, setup.memorise, setup.rows],
            [true, mode, IkkiuchiOpponent.tobi, mode.perSide, mode.memorise, rows]);
      }
    }
    await p.db.close();
  });

  test("every mode's rows fit its cards, up to the most rows a side has, its own rows among them", () {
    for (final mode in IkkiuchiMode.values) {
      expect(mode.rowChoices.last, IkkiuchiLayoutTuning.rows, reason: mode.name);
      expect(mode.rowChoices, contains(mode.defaultRows), reason: mode.name);
      for (final rows in mode.rowChoices) {
        expect(IkkiuchiLayout.rowsAllowed(mode.perSide, rows), isTrue, reason: '${mode.name}, $rows rows');
      }
    }
  });

  test('placement: Tobi at exactly the estimate, each result moving it by its step; the last is the rating',
      () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    IkkiuchiModeRecords rapid() => p.ikkiuchi.of(IkkiuchiMode.rapid);
    expect([rapid().rating, rapid().band, rapid().rankedPlayed, rapid().placing, rapid().curve],
        [null, null, 0, isTrue, isEmpty]);
    final results = [true, false, true, false];
    expect(results, hasLength(placing));
    var estimate = IkkiuchiRating.start;
    for (final (i, won) in results.indexed) {
      expect(rapid().rankedSetup(rows: 3).opponentRating, estimate, reason: 'placement match ${i + 1}');
      expect([rapid().rating, rapid().band, rapid().curve], [null, null, isEmpty], reason: 'unrated while placing');
      await play(p, won: won);
      estimate += (won ? 1 : -1) * steps[i];
    }
    expect(estimate, 1600 + 500 - 300 + 200 - 100);
    expect(p.ikkiuchi.matches.last.rating, estimate);
    expect([rapid().placing, rapid().rankedPlayed], [false, placing]);
    expect(rapid().rating, estimate);
    expect(rapid().band, Rating.bandOf(estimate));
    expect(rapid().ratingChange, isNull, reason: 'no change to show from unrated');
    expect(rapid().curve, [estimate], reason: 'the curve starts at the first rating');
    await p.db.close();
  });

  test('after placement: Tobi drawn near the rating, the same until played; K by the matches rated', () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    for (var i = 0; i < placing; i++) {
      await play(p, won: true);
    }
    IkkiuchiModeRecords rapid() => p.ikkiuchi.of(IkkiuchiMode.rapid);
    final placed = rapid().rating!;
    final tobi = rapid().rankedSetup(rows: 3).opponentRating;
    expect(rapid().rankedSetup(rows: 3).opponentRating, tobi, reason: 'the same until the match is played');
    expect((tobi - placed).abs(), lessThanOrEqualTo(IkkiuchiRankedTuning.drawCutOff));
    await play(p, won: true);
    expect(p.ikkiuchi.matches.last.setup.opponentRating, tobi, reason: 'played against the Tobi shown');
    final gain = k * (1 - IkkiuchiRating.expected(placed, tobi));
    expect(rapid().rating, closeTo(placed + gain, 1e-9));
    expect(rapid().ratingChange, closeTo(gain, 1e-9));

    final next = rapid().rankedSetup(rows: 3).opponentRating;
    await play(p, won: false);
    expect(rapid().ratingChange, closeTo(-k * IkkiuchiRating.expected(placed + gain, next), 1e-9));

    expect(IkkiuchiRating.kAfter(IkkiuchiRankedTuning.provisionalMatches - 1), k);
    expect(IkkiuchiRating.kAfter(IkkiuchiRankedTuning.provisionalMatches), IkkiuchiRankedTuning.establishedK);
    await p.db.close();
  });

  test('beating a stronger Tobi gains more, losing to a weaker one costs more', () {
    final earlier = [for (var i = 0; i < placing; i++) (opponentRating: IkkiuchiRating.start, won: true)];
    double change(double tobi, {required bool won}) =>
        IkkiuchiRating.after((opponentRating: tobi, won: won), earlier: earlier, rating: 2000) - 2000;
    expect(change(2300, won: true), greaterThan(change(2000, won: true)));
    expect(change(1700, won: false), lessThan(change(2000, won: false)));
  });

  test('the draw: within the cut-off, 80% of matches within ±300, whole points', () {
    final draws = [for (var seed = 0; seed < 4000; seed++) IkkiuchiRating.draw(math.Random(seed))];
    expect(draws.every((d) => d.abs() <= IkkiuchiRankedTuning.drawCutOff), isTrue);
    expect(draws.every((d) => d == d.roundToDouble()), isTrue);
    expect(draws.where((d) => d.abs() <= 300).length / draws.length, closeTo(0.8, 0.03));
    expect(draws.where((d) => d > 0).length / draws.length, closeTo(0.5, 0.03));
  });

  test('a ranked match given up is a loss, whatever the cards left say', () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await play(p, won: true, completed: false);
    expect(p.ikkiuchi.matches.single.rating, IkkiuchiRating.start - steps.first);
    await p.db.close();
  });

  test('Tobi and the rating stay within the ratings Tobi plays at', () {
    const top = IkkiuchiTuning.ratingMax, bottom = IkkiuchiTuning.ratingMin;
    for (var played = placing; played < placing + 50; played++) {
      for (final mode in IkkiuchiMode.values) {
        expect(IkkiuchiRating.opponentFor(mode, played: played, rating: top), inInclusiveRange(top - 600, top));
        expect(
            IkkiuchiRating.opponentFor(mode, played: played, rating: bottom), inInclusiveRange(bottom, bottom + 600));
      }
    }
    final earlier = [for (var i = 0; i < placing; i++) (opponentRating: IkkiuchiRating.start, won: true)];
    expect(IkkiuchiRating.after((opponentRating: top, won: true), earlier: earlier, rating: top), top);
    expect(IkkiuchiRating.after((opponentRating: bottom, won: false), earlier: earlier, rating: bottom), bottom);
  });

  test('free play never touches the rating, and the ratings come back on load as stored', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    for (final won in [true, true, false, true, false, true]) {
      await play(p, won: won);
      await p.recordIkkiuchi(ranked(IkkiuchiSetup.firstFree, won: true));
    }
    final ratings = [for (final m in p.ikkiuchi.matches) m.rating];
    expect([for (final (i, r) in ratings.indexed) if (i.isOdd) r], everyElement(isNull));
    expect([for (final (i, r) in ratings.indexed) if (i.isEven) r], everyElement(isNotNull));
    final reopened = await Progress.open(db);
    expect([for (final m in reopened.ikkiuchi.matches) m.rating], ratings);
    expect(reopened.ikkiuchi.of(IkkiuchiMode.rapid).rating, p.ikkiuchi.of(IkkiuchiMode.rapid).rating);
    await db.close();
  });

  test('each mode is placed and rated on its own matches, and stored with its mode and rows', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    for (final won in [true, true, true, true, false]) {
      await play(p, won: won, mode: IkkiuchiMode.bullet);
    }
    await play(p, won: false, mode: IkkiuchiMode.blitz);
    final bullet = p.ikkiuchi.of(IkkiuchiMode.bullet), blitz = p.ikkiuchi.of(IkkiuchiMode.blitz);
    final rapid = p.ikkiuchi.of(IkkiuchiMode.rapid);
    expect([bullet.rankedPlayed, blitz.rankedPlayed, rapid.rankedPlayed], [5, 1, 0]);
    expect([bullet.placing, blitz.placing, rapid.placing], [false, true, true]);
    expect(blitz.matches.single.rating, IkkiuchiRating.start - steps.first, reason: "Blitz's first placement match");
    expect(blitz.rankedSetup(rows: 2).opponentRating, IkkiuchiRating.start - steps.first,
        reason: "Blitz's estimate, not Bullet's rating");
    expect(rapid.rankedSetup(rows: 3).opponentRating, IkkiuchiRating.start);
    expect(bullet.lastRanked(2), [bullet.matches[4], bullet.matches[3]]);

    final reopened = (await Progress.open(db)).ikkiuchi;
    expect([for (final m in reopened.matches) (m.setup.mode, m.setup.rows)], [
      for (var i = 0; i < 5; i++) (IkkiuchiMode.bullet, IkkiuchiMode.bullet.defaultRows),
      (IkkiuchiMode.blitz, IkkiuchiMode.blitz.defaultRows),
    ]);
    expect(reopened.of(IkkiuchiMode.bullet).rating, bullet.rating);
    await db.close();
  });

  test("each mode draws Tobi's ratings from its own seeds", () {
    List<double> draws(IkkiuchiMode mode) => [
          for (var played = placing; played < placing + 20; played++)
            IkkiuchiRating.opponentFor(mode, played: played, rating: 2000),
        ];
    final all = [for (final mode in IkkiuchiMode.values) draws(mode)];
    for (final (i, a) in all.indexed) {
      for (final b in all.skip(i + 1)) {
        expect(a, isNot(b));
      }
    }
    expect(draws(IkkiuchiMode.blitz), draws(IkkiuchiMode.blitz), reason: 'the same until played');
  });

  test("the curve: the rating after each of a mode's last ranked matches, from the first rating", () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    const more = 25;
    for (var i = 0; i < placing + more; i++) {
      await play(p, won: i.isEven, mode: IkkiuchiMode.blitz);
    }
    final blitz = p.ikkiuchi.of(IkkiuchiMode.blitz);
    expect(blitz.curve, hasLength(IkkiuchiModeTuning.curveMatches));
    expect(blitz.curve, [
      for (final m in blitz.matches.skip(blitz.rankedPlayed - IkkiuchiModeTuning.curveMatches)) m.rating,
    ]);
    expect(blitz.curve.last, blitz.rating);
    await p.db.close();
  });
}
