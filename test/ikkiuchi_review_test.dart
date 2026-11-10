// A 一騎打ち match as History's match page reviews it (IkkiuchiReview): the
// takes and times, the field at rest and as each read began, who touched
// what and when, where each 送り札 went, the takes by side and row, the same
// setup before, and the rating and placement around a ranked match with
// the experience it earned.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/field_parts.dart';
import 'package:fudatobashi/domain/ikkiuchi_field.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_rating.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_review.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/rank_ladder.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/xp_history.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const player = IkkiuchiSide.player, opponent = IkkiuchiSide.opponent;
  final at = DateTime(2026, 11, 9, 10);
  Duration ms(int n) => Duration(milliseconds: n);

  const free = IkkiuchiSetup.free(opponentRating: 1200, perSide: 3, memorise: Duration(minutes: 5));

  IkkiuchiMatchRecord match(int id, IkkiuchiSetup setup, {List<IkkiuchiReadLog> reads = const []}) =>
      IkkiuchiMatchRecord(
        id: id,
        setup: setup,
        startedAt: at.add(Duration(hours: id)),
        endedAt: at.add(Duration(hours: id, minutes: 12)),
        completed: false,
        playerLeft: 1,
        opponentLeft: 1,
        reads: reads,
      );

  // Tobi's 下段 holds あさぼらけあ (31), 2 and 3; the player's 下段 10 and
  // あさぼらけう (64), a look-alike of 31, their 上段 12 in its open middle.
  const atRest = IkkiuchiLaidField(opponent: [
    IkkiuchiRow([31, 2], [3]),
  ], player: [
    IkkiuchiRow([10], [64]),
    IkkiuchiRow([], []),
    IkkiuchiRow([], [], middle: [12]),
  ]);
  final afterTwo = atRest.without(31).without(2);
  const sentTen = IkkiuchiSent(10, FieldRow.lower, RowPart.left, 0);
  const sentThree = IkkiuchiSent(3, FieldRow.middle, RowPart.left, 0);
  final reads = [
    // The player takes 31 from Tobi's side, after touching its look-alike.
    IkkiuchiReadLog(
        poemId: 31,
        cardSide: opponent,
        taker: player,
        playerFaults: 1,
        playerTake: ms(500),
        opponentTake: ms(700),
        field: atRest,
        faults: [IkkiuchiFault(player, 64, ms(300))]),
    // A tie on Tobi's side: his card.
    IkkiuchiReadLog(
        poemId: 2,
        cardSide: opponent,
        taker: opponent,
        tied: true,
        playerTake: ms(610),
        opponentTake: ms(600),
        field: atRest.without(31)),
    // A からふだ Tobi faults on: the player sends him 10.
    IkkiuchiReadLog(
            poemId: 50, opponentFaults: 1, field: afterTwo, faults: [IkkiuchiFault(opponent, 12, ms(900))])
        .withSent(sentTen),
    // The player takes 12 from their 上段's open middle.
    IkkiuchiReadLog(
        poemId: 12,
        cardSide: player,
        taker: player,
        playerTake: ms(450),
        opponentTake: ms(800),
        field: afterTwo.withSent(sentTen)),
    // Tobi beats the player to 64 and sends them 3.
    IkkiuchiReadLog(
            poemId: 64,
            cardSide: player,
            taker: opponent,
            playerTake: ms(450),
            opponentTake: ms(400),
            field: afterTwo.withSent(sentTen).without(12))
        .withSent(sentThree),
  ];
  final played = match(7, free, reads: reads);
  final review = IkkiuchiReview(played, [played]);
  List<int> ids(List<IkkiuchiReadLog> reads) => [for (final r in reads) r.poemId];

  test('the takes and times: who took what, the cards Tobi beat the player to, the fastest takes, the medians', () {
    expect(review.matchTime, const Duration(minutes: 12));
    expect(ids(review.fieldReads), [31, 2, 12, 64], reason: 'the からふだ left out');
    expect([played.takenBy(player), played.takenBy(opponent)], [2, 2]);
    expect(ids(review.beaten), [64], reason: 'the tie is not beaten');
    expect(ids(review.fastestTakes), [12, 31]);
    expect([played.medianTake(player), played.medianTake(opponent)], [ms(475), ms(650)]);
    expect(IkkiuchiMatchRecord.medianOf(const []), isNull);
    final lengths = {31: 6, 2: 2, 12: 2, 64: 6};
    expect(review.byKimariji((id) => lengths[id]!), [
      (length: 2, read: 2, took: 1, player: ms(530), opponent: ms(700)),
      (length: 6, read: 2, took: 1, player: ms(475), opponent: ms(550)),
    ]);
  });

  test('the field at rest is the first read\'s, each card coloured by where it went in the end', () {
    expect(review.atRest.toJson(), atRest.toJson());
    expect(review.cardEnds, {
      31: IkkiuchiCardEnd.player,
      2: IkkiuchiCardEnd.tied,
      3: IkkiuchiCardEnd.left,
      10: IkkiuchiCardEnd.left,
      64: IkkiuchiCardEnd.opponent,
      12: IkkiuchiCardEnd.player,
    });
    expect(IkkiuchiReview(match(8, free), [match(8, free)]).atRest.toJson(), IkkiuchiLaidField.empty.toJson(),
        reason: 'no read, no field');
  });

  test('each read: where its card lay, its touches in order, and where its 送り札 went', () {
    expect([for (final r in reads) review.spotOf(r)], [
      const IkkiuchiSpot(opponent, FieldRow.lower, RowPart.left, 0),
      const IkkiuchiSpot(opponent, FieldRow.lower, RowPart.left, 0),
      null,
      const IkkiuchiSpot(player, FieldRow.upper, RowPart.middle, 0),
      const IkkiuchiSpot(player, FieldRow.lower, RowPart.right, 0),
    ]);
    expect(review.touchesOf(reads[0]), [
      (by: player, card: 64, at: ms(300), fault: true, lookAlike: true),
      (by: player, card: 31, at: ms(500), fault: false, lookAlike: false),
      (by: opponent, card: 31, at: ms(700), fault: false, lookAlike: false),
    ]);
    expect([for (final t in review.touchesOf(reads[1])) t.by], [opponent, player], reason: 'Tobi first by 10 ms');
    expect(review.touchesOf(reads[2]), [(by: opponent, card: 12, at: ms(900), fault: true, lookAlike: false)],
        reason: 'a からふだ: only the faults');

    expect(review.sentAfter(reads[2]), [(card: 10, to: const IkkiuchiSpot(opponent, FieldRow.lower, RowPart.left, 0))]);
    expect(review.sentAfter(reads[4]), [(card: 3, to: const IkkiuchiSpot(player, FieldRow.middle, RowPart.left, 0))]);
    expect(review.sentAfter(reads[0]), isEmpty);
    expect(review.fieldAfter(reads[2]).toJson(), reads[3].field.toJson(), reason: 'the next read\'s field');
    expect(review.fieldAfter(reads[4]).toJson(), {
      'opponent': [
        [[10], <int>[], <int>[]],
      ],
      'player': [
        [<int>[], <int>[], <int>[]],
        [[3], <int>[], <int>[]],
        [<int>[], <int>[], <int>[]],
      ],
    }, reason: '64 taken, 3 laid on the player\'s 中段');
  });

  test('the replay\'s field: a 送り札 laid where it went beside where it lay, every row kept as it empties', () {
    const spot = IkkiuchiSpot(opponent, FieldRow.lower, RowPart.left, 0);
    final laid = afterTwo.laidAt(10, spot);
    expect(laid.cardsOf(player), afterTwo.cardsOf(player), reason: 'still where it lay');
    expect(laid.opponent.first.left, [10]);
    expect(afterTwo.without(10).laidAt(10, spot).toJson(), afterTwo.withSent(sentTen).toJson());

    final empty = IkkiuchiField(tobi: afterTwo.opponent, player: afterTwo.without(12).player);
    final kept = IkkiuchiField(tobi: afterTwo.opponent, player: afterTwo.without(12).player, keepRows: true);
    expect(kept.halfHeight, greaterThan(empty.halfHeight), reason: 'the player\'s emptied 上段 keeps its place');
  });

  test('a read says how it ended, as the match\'s banner said it', () {
    expect([for (final r in reads) r.callouts], [
      [IkkiuchiCallout.youTook, IkkiuchiCallout.yourFault],
      [IkkiuchiCallout.tied, IkkiuchiCallout.tobiTook],
      [IkkiuchiCallout.karafuda, IkkiuchiCallout.tobiFault],
      [IkkiuchiCallout.youTook],
      [IkkiuchiCallout.tobiTook],
    ]);
  });

  test('the takes by side and by row: the field cards read lying there, and those the player took', () {
    expect([review.takesOn(opponent), review.takesOn(player)], [(took: 1, read: 2), (took: 1, read: 2)]);
    expect([for (final row in FieldRow.values) review.takesInRow(row)],
        [(took: 1, read: 3), (took: 0, read: 0), (took: 1, read: 1)]);
  });

  test('the same setup before: the last ranked match of its mode for a ranked one, the same cards, rows, time and '
      'Tobi for free', () {
    final ranked = IkkiuchiSetup.ranked(IkkiuchiMode.rapid, opponentRating: 1700, rows: 3);
    final all = [
      match(1, free),
      match(2, const IkkiuchiSetup.free(opponentRating: 1250, perSide: 3, memorise: Duration(minutes: 5))),
      match(3, ranked),
      match(4, free),
      match(5, const IkkiuchiSetup.free(opponentRating: 1200, perSide: 4, memorise: Duration(minutes: 5))),
      match(6, IkkiuchiSetup.ranked(IkkiuchiMode.rapid, opponentRating: 1650, rows: 3)),
      match(7, free),
      match(8, IkkiuchiSetup.ranked(IkkiuchiMode.bullet, opponentRating: 1600, rows: 1)),
      match(9, const IkkiuchiSetup.free(opponentRating: 1200, perSide: 3, rows: 2, memorise: Duration(minutes: 5))),
    ];
    final freeReview = IkkiuchiReview(all[6], all);
    expect([for (final m in freeReview.peers) m.id], [1, 4]);
    expect(freeReview.last?.id, 4);
    expect(IkkiuchiReview(all[5], all).last?.id, 3);
    expect(IkkiuchiReview(all[0], all).last, isNull, reason: 'the first with its setup');
    expect(IkkiuchiReview(all[7], all).last, isNull, reason: 'the first in its mode');
    expect(IkkiuchiReview(all[8], all).last, isNull, reason: 'the same cards in other rows');
    expect([for (final m in IkkiuchiReview(all[3], all).earlier) m.id], [1, 2, 3]);
  });

  test('the rating: before and after, the placement matches with their steps, then the rated change; XP as earned',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await Progress.open(db);
    IkkiuchiMatchRecord played(IkkiuchiSetup setup, {required bool won}) => IkkiuchiMatchRecord(
          setup: setup,
          startedAt: at,
          endedAt: at.add(const Duration(minutes: 30)),
          completed: true,
          playerLeft: won ? 0 : 2,
          opponentLeft: won ? 2 : 0,
          reads: [IkkiuchiReadLog(poemId: 1, cardSide: player, taker: won ? player : opponent)],
        );
    const rapid = IkkiuchiMode.rapid, bullet = IkkiuchiMode.bullet;
    const steps = IkkiuchiRankedTuning.placementSteps;
    for (final (i, won) in [true, false, true, true, false].indexed) {
      await p.recordIkkiuchi(played(p.ikkiuchi.of(rapid).rankedSetup(rows: 3), won: won));
      if (i == 1) await p.recordIkkiuchi(played(free, won: true));
      if (i == 2) await p.recordIkkiuchi(played(p.ikkiuchi.of(bullet).rankedSetup(rows: 1), won: true));
    }
    final all = p.ikkiuchi.matches;
    final gains = XpHistory.gainsOf(p).ikkiuchi;
    final reviews = [for (final m in all) IkkiuchiReview(m, all, xp: gains[m.id])];
    final ranked = [for (final r in reviews) if (r.match.setup.mode == rapid) r];
    final other = reviews.singleWhere((r) => r.match.setup.mode == bullet);
    expect([other.placementMatch, other.ratingBefore, other.ratingChange], [1, IkkiuchiRating.start, steps.first],
        reason: "Bullet's first placement match, whatever Rapid's stand at");

    expect([for (final r in ranked) r.placementMatch], [1, 2, 3, 4, null]);
    expect(IkkiuchiReview.placementMatches, 4);
    expect([for (final r in ranked) r.endedPlacement], [false, false, false, true, false]);
    expect(ranked.first.ratingBefore, IkkiuchiRating.start);
    expect([for (final r in ranked.take(4)) r.ratingChange], [steps[0], -steps[1], steps[2], steps[3]]);
    for (var i = 1; i < ranked.length; i++) {
      expect(ranked[i].ratingBefore, ranked[i - 1].ratingAfter,
          reason: 'the free match and the Bullet one between are left out');
    }
    final rated = ranked.last;
    expect(
        rated.ratingAfter,
        IkkiuchiRating.after(rated.match.rated,
            earlier: [for (final r in ranked.take(4)) r.match.rated], rating: rated.ratingBefore));
    expect(rated.ratingChange, lessThan(0), reason: 'a loss');

    final freeMatch = reviews[2];
    expect([freeMatch.match.ranked, freeMatch.ratingBefore, freeMatch.ratingAfter, freeMatch.ratingChange],
        [false, null, null, null]);
    expect(freeMatch.placementMatch, isNull);

    expect([for (final r in reviews) r.xp!.award.total], [for (final m in all) m.xp!.total]);
    expect(reviews.last.xp!.after, p.xp.total);
    await db.close();
  });

  test('the class a rating sits in, the next and how far toward it', () {
    for (final rating in [IkkiuchiTuning.ratingMin, 1727.0, IkkiuchiTuning.ratingMax]) {
      final c = IkkiuchiReview.classProgress(rating);
      expect([c.band, c.next], [RankLadder.bandOf(rating), RankLadder.nextBand(rating)]);
      expect(c.fraction, inInclusiveRange(0, 1));
    }
    final band = RankLadder.bandOf(1727), next = RankLadder.nextBand(1727)!;
    expect(IkkiuchiReview.classProgress(1727).fraction,
        closeTo((1727 - band.minRating) / (next.minRating - band.minRating), 1e-9));
  });
}
