// 一騎打ち's ranked rating: placed by the first matches against Tobi at the
// estimate so far, each moving it by its step, then moved Elo-style by
// each match against Tobi drawn near the player's rating; a match given up
// is a loss. Every ranked match keeps the rating after it, and the ratings
// replay from the stored matches.
import 'dart:math' as math;

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

  /// Plays the next ranked match as offered, [won] or not.
  Future<IkkiuchiMatchRecord> play(Progress p, {required bool won, bool completed = true}) async =>
      (await p.recordIkkiuchi(ranked(p.ikkiuchi.rankedSetup, won: won, completed: completed))).match;

  test('the expected score: a half when even, more against a weaker opponent, the two sides adding to one', () {
    expect(IkkiuchiRating.expected(1500, 1500), 0.5);
    expect(IkkiuchiRating.expected(1700, 1500), greaterThan(0.5));
    expect(IkkiuchiRating.expected(1700, 1500) + IkkiuchiRating.expected(1500, 1700), closeTo(1, 1e-12));
  });

  test('a ranked match is always the same: Tobi, its cards a side and its memory time', () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    final setup = p.ikkiuchi.rankedSetup;
    expect([setup.ranked, setup.opponent, setup.perSide, setup.memorise],
        [true, IkkiuchiOpponent.tobi, IkkiuchiRankedTuning.perSide, IkkiuchiRankedTuning.memorise]);
    await p.db.close();
  });

  test('placement: Tobi at exactly the estimate, each result moving it by its step; the last is the rating',
      () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    expect([p.ikkiuchi.rating, p.ikkiuchi.rankedPlayed, p.ikkiuchi.placing], [null, 0, isTrue]);
    final results = [true, false, true, false];
    expect(results, hasLength(placing));
    var estimate = IkkiuchiRating.start;
    for (final (i, won) in results.indexed) {
      expect(p.ikkiuchi.rankedSetup.opponentRating, estimate, reason: 'placement match ${i + 1}');
      expect(p.ikkiuchi.rating, isNull, reason: 'unrated while placing');
      await play(p, won: won);
      estimate += (won ? 1 : -1) * steps[i];
    }
    expect(estimate, 1600 + 500 - 300 + 200 - 100);
    expect(p.ikkiuchi.matches.last.rating, estimate);
    expect([p.ikkiuchi.placing, p.ikkiuchi.rankedPlayed], [false, placing]);
    expect(p.ikkiuchi.rating, estimate);
    expect(p.ikkiuchi.ratingChange, isNull, reason: 'no change to show from unrated');
    await p.db.close();
  });

  test('after placement: Tobi drawn near the rating, the same until played; K by the matches rated', () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    for (var i = 0; i < placing; i++) {
      await play(p, won: true);
    }
    final placed = p.ikkiuchi.rating!;
    final tobi = p.ikkiuchi.rankedSetup.opponentRating;
    expect(p.ikkiuchi.rankedSetup.opponentRating, tobi, reason: 'the same until the match is played');
    expect((tobi - placed).abs(), lessThanOrEqualTo(IkkiuchiRankedTuning.drawCutOff));
    await play(p, won: true);
    expect(p.ikkiuchi.matches.last.setup.opponentRating, tobi, reason: 'played against the Tobi shown');
    final gain = k * (1 - IkkiuchiRating.expected(placed, tobi));
    expect(p.ikkiuchi.rating, closeTo(placed + gain, 1e-9));
    expect(p.ikkiuchi.ratingChange, closeTo(gain, 1e-9));

    final next = p.ikkiuchi.rankedSetup.opponentRating;
    await play(p, won: false);
    expect(p.ikkiuchi.ratingChange, closeTo(-k * IkkiuchiRating.expected(placed + gain, next), 1e-9));

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
      expect(IkkiuchiRating.opponentFor(played: played, rating: top), inInclusiveRange(top - 600, top));
      expect(IkkiuchiRating.opponentFor(played: played, rating: bottom), inInclusiveRange(bottom, bottom + 600));
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
    expect(reopened.ikkiuchi.rating, p.ikkiuchi.rating);
    await db.close();
  });
}
