import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/step_plan.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

const training = PlayConfig(mode: PlayMode.training);

/// Plays [run] from [at] the way the play screen does, answering right
/// except on the swipes at [missAt]; the player ends it after [stopAfter]
/// swipes when given.
Future<SessionReport> playRun(Progress p, PlannedRun run, DateTime at,
    {Set<int> missAt = const {}, int? stopAfter}) async {
  final session = PlaySession(run.cards, planner: run.planner);
  var t = const Duration(seconds: 100);
  var wall = at;
  while (!session.finished && (stopAfter == null || session.swipes.length < stopAfter)) {
    session.revealed(t);
    t += const Duration(milliseconds: 900);
    wall = wall.add(const Duration(seconds: 2));
    final miss = missAt.contains(session.swipes.length);
    session.commit(
        responseTs: t, commitTs: t, outcome: miss ? Outcome.dontKnow : Outcome.known, at: wall);
    t += const Duration(milliseconds: 100);
  }
  return p.recordRun(session, training, at, now: wall);
}

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Progress> open(AppDatabase db, {int dayStartHour = TodaySetTuning.defaultDayStartHour}) async {
    final p = await Progress.open(db);
    await p.updateTrainerConfig(const TrainerConfig());
    await p.updateSettings(p.settings.copyWith(dayStartHour: dayStartHour));
    p.trainer.fuzzing = false;
    return p;
  }

  final day0 = DateTime(2026, 9, 1, 9);
  final day1 = DateTime(2026, 9, 2, 9);

  group("today's set", () {
    test('the first day: new cards in the morning, four looks each, then the day is done', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final run = await p.planTraining(rng: math.Random(1), now: day0);
      final set = p.todaySet(day0)!;
      expect(run.ofSet, isTrue);
      expect(set.newCards, run.unlockedBefore.length);
      expect(set.reviews, 0);
      expect(run.cards, hasLength(set.newCards * TodaySetTuning.newLooks));
      final report = await playRun(p, run, day0);
      expect(report.completed, isTrue);
      expect(p.todaySet(day0)!.done, isTrue);
      final done = report.dayDone!;
      expect(done.looks, run.cards.length);
      expect((done.rounds, done.newCards, done.missesFixed, done.goalStreak), (1, set.newCards, 0, 1));
      expect(done.xp, XpTuning.dayDone);
      expect(report.xp!.award.parts.where((x) => x.source == XpSource.dayDone).single.xp, XpTuning.dayDone);
      expect((p.runs.last.day, p.runs.last.dayDone), (20260901, true));
      await db.close();
    });

    test('quit midway, restart, resume: the set goes on where it was, and is done once', () async {
      final db = AppDatabase(NativeDatabase.memory());
      var p = await open(db);
      final first = await p.planTraining(rng: math.Random(1), now: day0);
      final total = first.cards.length;
      final cut = await playRun(p, first, day0, stopAfter: 10, missAt: {2});
      expect(cut.completed, isFalse);
      expect(cut.dayDone, isNull);
      final bar = p.todaySet(day0)!.bar;
      expect(bar.done, 10);
      int left(Iterable<CardSteps> steps) => steps.fold(0, (n, s) => n + s.remaining);
      expect(10 + left(p.todaySet(day0)!.steps.values), greaterThan(total), reason: 'a miss adds looks');

      p = await Progress.open(db);
      p.trainer.fuzzing = false;
      final again = p.todaySet(day0.add(const Duration(hours: 1)))!;
      expect(again.bar.done, 10, reason: 'progress survives a restart');
      expect(again.bar.total, bar.total);
      final rest = await p.planTraining(rng: math.Random(2), now: day0.add(const Duration(hours: 1)));
      expect(rest.ofSet, isTrue);
      expect(rest.cards.where((c) => again.kinds.containsKey(ItemKey(c.poemId, c.inverted))),
          hasLength(left(again.steps.values)));
      final report = await playRun(p, rest, day0.add(const Duration(hours: 1)));
      expect(report.dayDone, isNotNull);
      expect(report.dayDone!.rounds, 2);
      expect(report.dayDone!.missesFixed, 1);

      final batch = await p.planTraining(rng: math.Random(3), now: day0.add(const Duration(hours: 2)));
      expect(batch.ofSet, isFalse, reason: 'after the day is done come batches');
      expect(batch.cards, hasLength(p.trainer.config.sessionLength));
      final more = await playRun(p, batch, day0.add(const Duration(hours: 2)), missAt: {0});
      expect(more.attempts.length, greaterThan(p.trainer.config.sessionLength), reason: 'a miss comes back in steps');
      expect(more.dayDone, isNull, reason: 'the day was already done');
      expect(p.todaySet(day0.add(const Duration(hours: 2)))!.done, isTrue);
      await db.close();
    });

    test("FSRS grades a card's first look and its misses, not the looks before its step is up", () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      final run = await p.planTraining(rng: math.Random(1), now: day0);
      final report = await playRun(p, run, day0, missAt: {6});
      final cards = {for (final a in report.attempts) ItemKey(a.card.poemId, a.card.inverted)};
      final graded = [
        for (final k in cards)
          for (final a in p.attemptsOf(k)) if (a.grade != null) a,
      ];
      expect(graded, hasLength(cards.length + 1), reason: 'one first look per card, plus the miss');

      final next = await p.planTraining(rng: math.Random(2), now: day1);
      final set = p.todaySet(day1)!;
      expect(set.reviews, cards.length, reason: "yesterday's cards are due today");
      expect(next.cards.where((c) => !cards.contains(ItemKey(c.poemId, c.inverted))).length,
          set.newCards * TodaySetTuning.newLooks);
      await db.close();
    });

    test('a learning card is graded each time its step is up until it graduates; a review once a day', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      await playRun(p, await p.planTraining(rng: math.Random(1), now: day0), day0);
      final cards = [for (final s in p.trainer.unlocked) s.key];
      expect(cards.every((k) => p.trainer.items[k]!.card.state == fsrs.State.learning), isTrue);
      List<int?> gradesAfter(ItemKey k, DateTime from) => [
            for (final a in p.attemptsOf(k)) if (!a.at.isBefore(from)) a.grade,
          ];

      final soon = day0.add(const Duration(minutes: 5));
      await playRun(p, await p.planTraining(rng: math.Random(2), now: soon), soon);
      for (final k in cards) {
        expect(gradesAfter(k, soon).whereType<int>(), isEmpty, reason: '$k: its step is not up yet');
      }

      final later = day0.add(const Duration(minutes: 30));
      await playRun(p, await p.planTraining(rng: math.Random(3), now: later), later);
      final answered = [for (final k in cards) if (gradesAfter(k, later).isNotEmpty) k];
      expect(answered, isNotEmpty, reason: 'due learning cards come first');
      for (final k in answered) {
        expect(gradesAfter(k, later).first, fsrs.Rating.good.value, reason: '$k: its step was up');
        expect(gradesAfter(k, later).skip(1).whereType<int>(), isEmpty, reason: '$k: graduated, so no more today');
        expect(p.trainer.items[k]!.card.state, fsrs.State.review);
        expect(p.trainer.isDue(k, later.add(const Duration(hours: 1))), isFalse);
      }

      final dues = [for (final k in cards) p.trainer.items[k]!.card.due]..sort();
      final reviewDay = dues.first.toLocal();
      final next = await p.planTraining(rng: math.Random(4), now: reviewDay);
      final set = p.todaySet(reviewDay)!;
      expect(set.reviews, greaterThan(0));
      final from = set.window.start;
      await playRun(p, next, reviewDay);
      for (final k in set.kinds.keys.where((k) => set.kinds[k] == StepKind.review)) {
        final looks = gradesAfter(k, from);
        expect(looks.length, greaterThanOrEqualTo(TodaySetTuning.reviewLooks));
        expect(looks.whereType<int>(), hasLength(1), reason: '$k: a review is graded once a day');
      }
      await db.close();
    });

    test("a 苦手 drill's right answer on a due review leaves the day's review to 修行", () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      await playRun(p, await p.planTraining(rng: math.Random(1), now: day0), day0);
      final later = day0.add(const Duration(minutes: 30));
      await playRun(p, await p.planTraining(rng: math.Random(3), now: later), later);
      final k = [for (final s in p.trainer.unlocked) if (s.card.state == fsrs.State.review) s.key].first;
      final due = p.trainer.items[k]!.card.due.add(const Duration(minutes: 1));
      Future<void> answer(PlayConfig config, DateTime at) async {
        final session = PlaySession([CardRef(k.poemId, inverted: k.inverted)])..revealed(Duration.zero);
        session.commit(responseTs: const Duration(milliseconds: 900), commitTs: const Duration(milliseconds: 900),
            outcome: Outcome.known, at: at);
        await p.recordRun(session, config, at, now: at);
      }

      await answer(PlayConfig(mode: PlayMode.nigate, goalMs: 1000, targets: [k.id]), due);
      expect(p.attemptsOf(k).last.grade, isNull, reason: '苦手 grades only misses');
      await answer(training, due.add(const Duration(hours: 1)));
      expect(p.attemptsOf(k).last.grade, fsrs.Rating.good.value);
      await answer(training, due.add(const Duration(hours: 2)));
      expect(p.attemptsOf(k).last.grade, isNull, reason: 'reviewed once today');
      await db.close();
    });

    test('a review needs two looks today even when the first is right', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      await playRun(p, await p.planTraining(rng: math.Random(1), now: day0), day0);
      final run = await p.planTraining(rng: math.Random(2), now: day1);
      final set = p.todaySet(day1)!;
      final review = set.kinds.entries.firstWhere((e) => e.value == StepKind.review).key;
      expect(run.cards.where((c) => ItemKey(c.poemId, c.inverted) == review), hasLength(TodaySetTuning.reviewLooks));
      await db.close();
    });

    test('the day starts at the set hour: the small hours count for the day before', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db, dayStartHour: 6);
      await playRun(p, await p.planTraining(rng: math.Random(1), now: day0), day0);
      final late = DateTime(2026, 9, 2, 5);
      expect(p.dayAt(late).number, 20260901);
      expect(p.todaySet(late)!.done, isTrue);
      final run = await p.planTraining(rng: math.Random(2), now: late);
      expect(run.ofSet, isFalse, reason: 'still the day that is done');
      expect(p.dayAt(DateTime(2026, 9, 2, 6)).number, 20260902);

      await p.updateSettings(p.settings.copyWith(dayStartHour: 8));
      final w = p.dayAt(DateTime(2026, 9, 2, 5, 30));
      expect((w.number, w.start), (20260901, DateTime(2026, 9, 1, 6)),
          reason: 'a new hour takes effect from the next day start');
      final next = p.dayAt(DateTime(2026, 9, 2, 7));
      expect((next.number, next.start, next.end), (20260902, DateTime(2026, 9, 2, 6), DateTime(2026, 9, 3, 8)),
          reason: 'never a short day');
      await db.close();
    });

    test('week stamps and the goal streak follow the done days', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      for (final d in [0, 1, 3]) {
        final at = day0.add(Duration(days: d));
        await playRun(p, await p.planTraining(rng: math.Random(d), now: at), at);
      }
      final at = day0.add(const Duration(days: 4));
      await p.planTraining(rng: math.Random(9), now: at);
      final stamps = p.weekStamps(at);
      expect(stamps, hasLength(TodaySetTuning.weekDays));
      expect([for (final s in stamps) s.done ? 'v' : (s.missed ? 'x' : '-')].join(), '--vvxv-');
      expect(stamps.last.today, isTrue);
      expect(p.goalStreak(at), 1);
      expect(p.streak, isNonNegative);
      await db.close();
    });

    test('many reviews: Home offers to pause the new cards once, and yes takes them out', () async {
      for (final pace in LearningPace.values) {
        final db = AppDatabase(NativeDatabase.memory());
        final p = await open(db);
        await p.setLearningPace(pace);
        final over = pace.profile.pauseNewOver;
        await playRun(p, await p.planTraining(rng: math.Random(1), now: day0), day0);
        // Enough cards due tomorrow to go over, and a few new ones.
        final items = p.trainer.items.values.toList();
        for (final s in items.take(over + 1)) {
          s.unlocked = true;
          if (!s.reviewed) s.card = s.card.copyWith(lastReview: day0.toUtc(), due: day0.toUtc());
        }
        for (final s in items.skip(over + 1).take(3)) {
          s.unlocked = true;
        }
        await p.planTraining(rng: math.Random(2), now: day1);
        final set = p.todaySet(day1)!;
        expect(set.reviews, greaterThan(over), reason: '$pace');
        expect(set.newCards, isPositive, reason: '$pace');
        expect(p.pauseOffered(day1), isTrue, reason: '$pace');
        await p.answerPause(pause: true, now: day1);
        expect(p.pauseOffered(day1), isFalse, reason: 'asked once');
        final paused = p.todaySet(day1)!;
        expect((paused.newCards, paused.newPaused), (0, true));
        expect(p.trainer.unlocked.where((s) => !s.reviewed), isEmpty, reason: 'locked again until another day');
        await db.close();
      }
    });

    test('at or under the threshold nothing is offered', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await open(db);
      await playRun(p, await p.planTraining(rng: math.Random(1), now: day0), day0);
      await p.planTraining(rng: math.Random(2), now: day1);
      expect(p.todaySet(day1)!.reviews, lessThanOrEqualTo(LearningPace.month.profile.pauseNewOver));
      expect(p.pauseOffered(day1), isFalse);
      await db.close();
    });
  });

  test('XP: a done day, an island and graduation', () {
    expect((XpTuning.dayDone, XpTuning.perIsland, XpTuning.graduation), (1000, 10000, 100000));
    final ledger = XpLedger();
    final award = ledger
        .add(XpRun(
          runId: 1,
          startedAt: day0,
          setup: 'training',
          completed: true,
          total: null,
          goalMs: 3000,
          counts: true,
          swipes: const [],
          islands: 1,
          graduated: true,
          dayDone: true,
        ))
        .award;
    int xpOf(XpSource s) => award.parts.singleWhere((p) => p.source == s).xp;
    expect((xpOf(XpSource.dayDone), xpOf(XpSource.island), xpOf(XpSource.graduation)), (1000, 10000, 100000));
  });
}
