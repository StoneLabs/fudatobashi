// 一騎打ち's ranked rating: placed by the first matches against Tobi at the
// start rating, then moved Elo-style by each match against Tobi at the
// player's own rating; a match given up is a loss. Every ranked match
// keeps the rating after it, and the ratings replay from the stored
// matches.
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
  const placing = IkkiuchiRankedTuning.placementMatches;
  const spread = IkkiuchiRankedTuning.performanceSpread;
  const k = IkkiuchiRankedTuning.k;
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
  Future<IkkiuchiMatchRecord> play(Progress p, {required bool won, bool completed = true}) =>
      p.recordIkkiuchi(ranked(p.ikkiuchi.rankedSetup, won: won, completed: completed));

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

  test('placement: Tobi at the start rating, the player unrated, then rated at the mean of the performances',
      () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    expect([p.ikkiuchi.rating, p.ikkiuchi.rankedPlayed, p.ikkiuchi.placing], [null, 0, isTrue]);
    final results = [true, false, true];
    expect(results, hasLength(placing));
    for (final (i, won) in results.indexed) {
      expect(p.ikkiuchi.rankedSetup.opponentRating, IkkiuchiRating.start, reason: 'placement match ${i + 1}');
      expect(p.ikkiuchi.rating, isNull, reason: 'unrated while placing');
      await play(p, won: won);
    }
    const placed = IkkiuchiRating.start + spread / placing;
    expect(p.ikkiuchi.matches.last.rating, closeTo(placed, 1e-9));
    expect([p.ikkiuchi.placing, p.ikkiuchi.rankedPlayed], [false, placing]);
    expect(p.ikkiuchi.rating, closeTo(placed, 1e-9));
    expect(p.ikkiuchi.ratingChange, isNull, reason: 'no change to show from unrated');
    await p.db.close();
  });

  test('after placement: Tobi at the player\'s rating, a win up and a loss down by half of K', () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    for (var i = 0; i < placing; i++) {
      await play(p, won: true);
    }
    final placed = p.ikkiuchi.rating!;
    expect(p.ikkiuchi.rankedSetup.opponentRating, placed);
    await play(p, won: true);
    expect(p.ikkiuchi.rating, closeTo(placed + k / 2, 1e-9));
    expect(p.ikkiuchi.ratingChange, closeTo(k / 2, 1e-9));
    expect(p.ikkiuchi.rankedSetup.opponentRating, closeTo(placed + k / 2, 1e-9));
    await play(p, won: false);
    expect(p.ikkiuchi.rating, closeTo(placed, 1e-9));
    expect(p.ikkiuchi.ratingChange, closeTo(-k / 2, 1e-9));
    await p.db.close();
  });

  test('a ranked match given up is a loss, whatever the cards left say', () async {
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await play(p, won: true, completed: false);
    expect(p.ikkiuchi.matches.single.rating, IkkiuchiRating.start - spread);
    await p.db.close();
  });

  test('Tobi plays within the ratings he has, and a match against him there rates by the ratings apart', () {
    const top = IkkiuchiTuning.ratingMax;
    expect(IkkiuchiRating.opponentFor(played: placing, rating: top + 300), top);
    expect(IkkiuchiRating.opponentFor(played: placing, rating: IkkiuchiTuning.ratingMin - 50), IkkiuchiTuning.ratingMin);
    expect(IkkiuchiRating.opponentFor(played: placing - 1, rating: 2000), IkkiuchiRating.start, reason: 'still placing');
    final earlier = [for (var i = 0; i < placing; i++) (opponentRating: IkkiuchiRating.start, won: true)];
    final after = IkkiuchiRating.after((opponentRating: top, won: true), earlier: earlier, rating: top + 300);
    expect(after - (top + 300), closeTo(k * (1 - IkkiuchiRating.expected(top + 300, top)), 1e-9));
    expect(after - (top + 300), lessThan(k / 2), reason: 'a win over a weaker Tobi earns less');
  });

  test('free play never touches the rating, and the ratings come back on load as stored', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    for (final won in [true, true, false, true, false]) {
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
