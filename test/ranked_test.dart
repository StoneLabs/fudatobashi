import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/ranked.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/demo_data.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// [cards] played at [ms] each, [misses] of them as "don't know", the
  /// first [stopAfter] only when given.
  PlaySession play(List<CardRef> cards, int ms, {int misses = 0, int? stopAfter}) {
    final s = PlaySession(cards);
    var t = const Duration(seconds: 100);
    for (var i = 0; i < (stopAfter ?? cards.length); i++) {
      s.revealed(t);
      t += Duration(milliseconds: ms);
      s.commit(responseTs: t, commitTs: t, outcome: i < misses ? Outcome.dontKnow : Outcome.known);
    }
    return s;
  }

  final all = [for (final p in poems.all) CardRef(p.id)];

  group('scoring', () {
    test('each miss adds the penalty to the clock', () {
      final run = play(all, 1500, misses: 3);
      final score = RankedScore.of(run, run.total!);
      expect(score.misses, 3);
      expect(score.scored, run.total! + const Duration(milliseconds: 3 * RankedTuning.missPenaltyMs));
    });

    test('a run left early is never scored better than missing every card left at the same pace', () {
      for (final ms in [800, 3000, 9000]) {
        final left = play(all, ms, stopAfter: 40);
        final forfeit = RankedScore.of(left, left.elapsed).scored;
        final finishedBadly = play(all, ms, stopAfter: 100);
        final missedRest = finishedBadly.total! + const Duration(milliseconds: 60 * RankedTuning.missPenaltyMs);
        expect(forfeit, greaterThanOrEqualTo(missedRest), reason: '$ms ms a card');
      }
    });

    test("Tobi's cards and mistakes add up to his time, inside its range", () {
      for (var seed = 0; seed < 20; seed++) {
        final tobi = TobiPace.draw(math.Random(seed));
        expect(tobi.total.inMilliseconds, inInclusiveRange(ExamTuning.tobiMinMs, ExamTuning.tobiMaxMs));
        expect(tobi.cardEnds, hasLength(RankedTuning.cards));
        expect(tobi.misses.length, lessThanOrEqualTo(ExamTuning.tobiMaxMisses));
        expect(tobi.total, tobi.finish + const Duration(milliseconds: ExamTuning.missPenaltyMs) * tobi.misses.length);
        for (var i = 1; i < tobi.cardEnds.length; i++) {
          expect(tobi.cardEnds[i], greaterThan(tobi.cardEnds[i - 1]));
        }
        expect(tobi.doneAt(Duration.zero), 0);
        expect(tobi.doneAt(tobi.finish), RankedTuning.cards);
        expect(tobi.timeAt(tobi.finish), tobi.total);
        expect(tobi.timeAt(tobi.finish + const Duration(minutes: 1)), tobi.total, reason: 'his clock stops as he finishes');
      }
    });

    test("Tobi's rhythm: bursts of quick cards, the odd slow one, and now and then a mistake", () {
      var quick = 0, slow = 0, misses = 0;
      const tries = 200;
      for (var seed = 0; seed < tries; seed++) {
        final tobi = TobiPace.draw(math.Random(seed));
        final pace = tobi.finish.inMicroseconds / RankedTuning.cards;
        for (var i = 0; i < RankedTuning.cards; i++) {
          final took = (tobi.cardEnds[i] - tobi.startOf(i)).inMicroseconds;
          switch (tobi.beatOf(i)) {
            case TobiBeat.quick:
              quick++;
              expect(took, lessThan(pace * 0.5), reason: 'a quick card is plainly quick');
            case TobiBeat.slow:
              slow++;
              expect(took, greaterThan(pace * 2), reason: 'a slow card is plainly slow');
            case TobiBeat.usual:
              expect(took, inInclusiveRange(pace * 0.55, pace * 1.5));
          }
        }
        misses += tobi.misses.length;
      }
      const cards = tries * RankedTuning.cards;
      expect(quick / cards, inInclusiveRange(0.12, 0.3));
      expect(slow / cards, inInclusiveRange(0.06, 0.16));
      expect(misses / tries, inInclusiveRange(1.0, 3.0));
    });
  });

  group('ranked runs', () {
    test('the first places the rating at its performance; later ones move it toward theirs', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      expect(p.placed, isFalse);
      const ranked = PlayConfig(mode: PlayMode.ranked);

      final first = await p.recordRun(play(all, 1500, misses: 2), ranked, DateTime.now());
      expect(first.placement, isTrue);
      final scored = first.score!.scored;
      expect(scored, first.total! + const Duration(milliseconds: 2 * RankedTuning.missPenaltyMs));
      expect(p.rating, closeTo(Rating.performance(scored.inMilliseconds.toDouble()), 1e-6));
      expect(first.xp!.award.parts.map((x) => x.source), containsAll([XpSource.ranked, XpSource.placement]));

      final placed = p.rating!;
      final second = await p.recordRun(play(all, 1000), ranked, DateTime.now());
      expect(second.placement, isFalse);
      final perf = Rating.performance(second.score!.scored.inMilliseconds.toDouble());
      expect(p.rating, closeTo(placed + RatingModel.provisionalK * (perf - placed), 1e-6));
      expect(second.xp!.award.parts.map((x) => x.source), isNot(contains(XpSource.placement)));

      final free = await p.recordRun(play(all.take(10).toList(), 500), const PlayConfig(mode: PlayMode.nigate), DateTime.now());
      expect(free.ratingAfter, free.ratingBefore, reason: '苦手 never moves the rating');

      final again = await Progress.open(db);
      expect(again.rating, p.rating, reason: 'the rating is the latest ranked run\'s');
      final rated = [
        for (final r in again.pastRuns.reversed)
          if (again.ratingOf(r) case final rating?) (placement: r.placement, rating: rating),
      ];
      expect([for (final r in rated) r.placement], [true, false]);
      expect(rated[0].rating.before, isNull);
      expect(rated[1].rating.before, closeTo(placed, 1e-9));
      expect(rated[1].rating.performance, closeTo(perf, 1e-9));
      expect(rated[1].rating.after, closeTo(p.rating!, 1e-9));
      await db.close();
    });

    test('a forfeit on the first ranked run places the rating at 0, with no scored time', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      final report = await p.recordRun(play(all, 900, stopAfter: 60), const PlayConfig(mode: PlayMode.ranked), DateTime.now());
      expect(report.forfeit, isTrue);
      expect(report.placement, isTrue);
      expect(p.rating, RankedTuning.forfeitPerformance);
      final row = p.runs.single;
      expect(row.performance, RankedTuning.forfeitPerformance);
      expect(row.scoredMs, isNull);
      expect(row.clockUs, isNotNull, reason: 'the time played still counts as practice');
      final past = p.pastRuns.single;
      expect(past.placement, isTrue);
      expect(past.time, isNull);
      expect(p.ratingOf(past), (before: null, after: 0.0, performance: 0.0));
      await db.close();
    });

    test('a later forfeit plays like 0 and moves the rating by K, as any ranked run', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      const ranked = PlayConfig(mode: PlayMode.ranked);
      Future<void> forfeit(double k) async {
        final before = p.rating!;
        final report = await p.recordRun(play(all, 900, stopAfter: 30), ranked, DateTime.now());
        expect(report.forfeit, isTrue);
        expect(p.rating, closeTo(before + k * (RankedTuning.forfeitPerformance - before), 1e-9));
        expect(p.runs.last.performance, RankedTuning.forfeitPerformance);
      }

      await p.recordRun(play(all, 900), ranked, DateTime.now());
      await forfeit(RatingModel.provisionalK);
      while (p.ratedRuns.length < RatingModel.provisionalSessions) {
        await p.recordRun(play(all, 900), ranked, DateTime.now());
      }
      await forfeit(RatingModel.establishedK);
      expect(p.ratedRuns, hasLength(RatingModel.provisionalSessions + 1), reason: 'forfeits count as runs');

      final again = await Progress.open(db);
      expect(again.rating, p.rating, reason: 'the same rating after a reload');
      final history = again.rankedHistory;
      var replayed = history.first.$2.after;
      for (final (i, (_, r)) in history.indexed.skip(1)) {
        replayed = Rating.update(replayed, r.performance, i);
      }
      expect(replayed, closeTo(again.rating!, 1e-9), reason: 'replaying the performances gives the same rating');
      await db.close();
    });

    test('the ranked demo seeds an all-known player whose ranked runs make a rating history', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await seedRankedDemoData(p, days: 6);
      expect(p.trainer.config.learningMode, LearningMode.allKnown);
      final ranked = [for (final r in p.runs) if (r.mode == PlayMode.ranked) r];
      expect(ranked, hasLength(6 ~/ DemoDataTuning.rankedEvery));
      expect(ranked.every((r) => r.rating != null && r.performance != null && r.scoredMs != null && r.allKnown), isTrue);
      expect(p.rating, ranked.last.rating);
      expect(p.pastRuns.where((r) => r.placement).single.id, ranked.first.id);
      expect({for (final r in p.runs) r.day}.length, 6, reason: 'training every day');
      await db.close();
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('a ranked run the app never recorded counts as a forfeit on the next start, with its swipes', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      const config = PlayConfig(mode: PlayMode.ranked);
      final run = PlaySession(all);
      await p.journalRun(run, config, DateTime.now());
      var t = const Duration(seconds: 100);
      for (var i = 0; i < 5; i++) {
        run.revealed(t);
        t += const Duration(milliseconds: 1200);
        run.commit(responseTs: t, commitTs: t, outcome: i == 0 ? Outcome.dontKnow : Outcome.known);
        await p.journalRun(run, config, DateTime.now());
      }
      run.undo();
      await p.journalRun(run, config, DateTime.now());

      final again = await Progress.open(db);
      final row = again.runs.single;
      expect([row.mode, row.completed, row.planned], [PlayMode.ranked, false, RankedTuning.cards]);
      expect(row.performance, RankedTuning.forfeitPerformance);
      expect(row.scoredMs, isNull, reason: 'a forfeit has no scored time');
      expect(again.rating, RankedTuning.forfeitPerformance, reason: 'it placed the rating');
      expect(again.cardsIn(row.id), 4, reason: 'the swipes made before the app closed are kept');
      expect(again.missesIn(row.id), 2, reason: 'the miss, and the swipe undone');
      expect(again.pastRuns.single.cards, 4, reason: 'History says where it stopped');
      expect(again.attemptsOf(ItemKey(all.first.poemId, false)).single.miss, isTrue);
      final third = await Progress.open(db);
      expect(third.runs, hasLength(1), reason: 'counted once');
      await db.close();
    });

    test('a ranked run closed before its first swipe is still a forfeit at card 0', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      await p.journalRun(PlaySession(all), const PlayConfig(mode: PlayMode.ranked), DateTime.now());
      final again = await Progress.open(db);
      expect(again.runs.single.completed, isFalse);
      expect(again.cardsIn(again.runs.single.id), 0);
      expect(again.rating, RankedTuning.forfeitPerformance);
      await db.close();
    });

    test('a training run or an exam try the app never recorded is recorded with its swipes', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.journey);
      final cards = [for (final s in p.trainer.unlocked.take(6)) CardRef(s.key.poemId)];
      final training = play(cards, 900, misses: 1, stopAfter: 3);
      await p.journalRun(training, const PlayConfig(mode: PlayMode.training), DateTime.now());
      var again = await Progress.open(db);
      expect(again.runs.single.mode, PlayMode.training);
      expect(again.runs.single.completed, isFalse);
      expect(again.cardsIn(again.runs.single.id), 3);
      expect(again.runs.single.clockUs, training.elapsed.inMicroseconds);

      final tobi = TobiPace.draw(math.Random(1));
      final exam = play(all, 1500, stopAfter: 7);
      await again.journalRun(exam, const PlayConfig(mode: PlayMode.exam), DateTime.now(), tobi: tobi.total, tobiLine: tobi.line);
      again = await Progress.open(db);
      final row = again.runs.last;
      expect([row.mode, row.completed, row.tobiMs], [PlayMode.exam, false, tobi.total.inMilliseconds]);
      expect(again.cardsIn(row.id), 7);
      expect(again.graduated, isFalse);
      expect((await Progress.open(db)).runs, hasLength(2), reason: 'each counted once');
      await db.close();
    });

    test('a run recorded as it ends leaves nothing for the next start', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      const config = PlayConfig(mode: PlayMode.ranked);
      final run = play(all, 1000);
      unawaited(p.journalRun(run, config, DateTime.now()));
      await p.recordRun(run, config, DateTime.now());
      unawaited(p.journalRun(run, config, DateTime.now()));
      expect((await Progress.open(db)).runs, hasLength(1));
      await db.close();
    });
  });

  group('level-ups', () {
    /// The kinds of [report]'s pages after the run, in order.
    List<Type> pagesOf(SessionReport report) => [for (final c in celebrationsFor(report)) c.runtimeType];

    /// [report]'s XP page, then its level-up page when it gained a level.
    void expectLevelPages(SessionReport report, String run) {
      final pages = pagesOf(report);
      expect(pages, contains(XpCelebration), reason: run);
      if (report.xp!.levelsGained > 0) {
        expect(pages.indexOf(LevelUpCelebration), pages.indexOf(XpCelebration) + 1, reason: '$run: level-up right after XP');
      } else {
        expect(pages, isNot(contains(LevelUpCelebration)), reason: run);
      }
    }

    test('every level gained shows its page: exam tries, the placement run and ranked runs, as after a reload', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.journey);
      await p.recordRun(play(all, 900), PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: [for (final c in all) c.poemId]),
          DateTime.now());
      var levels = 0;
      final exam = <SessionReport>[
        await p.recordRun(play(all, 3000, misses: 5), const PlayConfig(mode: PlayMode.exam), DateTime.now(),
            tobi: const Duration(minutes: 4)),
        await p.recordRun(play(all, 2000), const PlayConfig(mode: PlayMode.exam), DateTime.now(),
            tobi: const Duration(minutes: 5)),
      ];
      expect(exam.map((r) => r.passed), [false, true]);
      // A lost try's page shows its XP pages alone (`ExamLostScreen`).
      expect([for (final c in xpCelebrations(exam.first.xp)) c.runtimeType],
          exam.first.xp!.levelsGained > 0 ? [XpCelebration, LevelUpCelebration] : [XpCelebration]);
      expectLevelPages(exam.last, 'the exam passed');
      expect(pagesOf(exam.last).first, GraduationCelebration);
      for (final r in exam) {
        levels += r.xp!.levelsGained;
      }

      await p.switchToAllKnown();
      const ranked = PlayConfig(mode: PlayMode.ranked);
      final placement = await p.recordRun(play(all, 1800, misses: 3), ranked, DateTime.now());
      expect(placement.placement, isTrue);
      expectLevelPages(placement, 'placement');
      expect(pagesOf(placement).last, PlacementCelebration, reason: 'the class it placed into comes last');
      levels += placement.xp!.levelsGained;
      for (var i = 0; i < 6; i++) {
        final run = await p.recordRun(play(all, 1500), ranked, DateTime.now());
        expectLevelPages(run, 'ranked run ${i + 1}');
        levels += run.xp!.levelsGained;
      }
      expect(levels, greaterThan(0), reason: 'some run gained a level');

      // The level after a reload is the level the pages showed.
      final again = await Progress.open(db);
      expect(again.xp.total, p.xp.total, reason: 'no level gained silently on the next start');
      await db.close();
    });
  });

  group('the graduation exam', () {
    test('opens once every card is swiped, then allows one try an hour', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.journey);
      expect(p.exam().open, isFalse);
      expect(p.exam().cardsLeft, 100);
      await p.recordRun(play(all.take(99).toList(), 900), PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: [for (final c in all.take(99)) c.poemId]), DateTime.now());
      expect(p.exam().cardsLeft, 1);
      await p.recordRun(play([all.last], 900), PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: [all.last.poemId]), DateTime.now());
      expect(p.exam().open, isTrue);
      expect(p.exam().canStart, isTrue);

      final at = DateTime.now();
      await p.noteExamStarted(at);
      expect(p.exam(at.add(const Duration(minutes: 20))).cooldown, const Duration(minutes: 40));
      expect(p.exam(at.add(ExamTuning.cooldown)).canStart, isTrue);
      final again = await Progress.open(db);
      expect(again.exam(at).canStart, isFalse, reason: 'the try is remembered');

      expect(p.switchBannerShown, isFalse);
      final won = await p.recordRun(play(all, 900), const PlayConfig(mode: PlayMode.exam), at, tobi: const Duration(minutes: 4));
      expect(won.graduated, isTrue);
      expect(p.rating, isNull, reason: 'the exam is not a ranked run');
      expect(p.exam().passed, isTrue);
      expect(p.switchBannerShown, isTrue);
      expect(p.switchBannerCollapsed, isFalse);
      p.collapseSwitchBanner();
      expect(p.switchBannerShown, isTrue, reason: 'folding keeps the banner');
      expect(p.switchBannerCollapsed, isTrue);
      p.expandSwitchBanner();
      expect(p.switchBannerCollapsed, isFalse);

      // The flag an earlier build stored when its ✕ hid the banner for good.
      await db.into(db.keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: 'switchBannerClosed', value: 'true'));
      expect((await Progress.open(db)).switchBannerShown, isTrue, reason: 'the old flag is not read');
      await db.close();
    });
  });
}
