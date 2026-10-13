import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_xp.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

import 'test_ankiren.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const goalMs = 1000.0;
  var nextId = 1;
  XpSwipe hit(int poemId, int ms, {bool graded = false, bool clean = true}) =>
      XpSwipe(poemId: poemId, correct: true, clean: clean, us: ms * 1000, graded: graded);
  XpSwipe miss(int poemId, {bool clean = true}) =>
      XpSwipe(poemId: poemId, correct: false, clean: clean, us: 900000, graded: true);
  XpRun run(
    List<XpSwipe> swipes, {
    DateTime? at,
    String setup = 'training',
    Duration? total = const Duration(seconds: 30),
    bool? completed,
    bool counts = true,
    int islands = 0,
    bool graduated = false,
  }) =>
      XpRun(
        sessionId: nextId++,
        startedAt: at ?? DateTime(2026, 9, 1, 12),
        setup: setup,
        completed: completed ?? total != null,
        total: total,
        goalMs: goalMs,
        counts: counts,
        swipes: swipes,
        islands: islands,
        graduated: graduated,
      );
  Map<XpSource, (int, int)> parts(XpGain g) => {for (final p in g.award.parts) p.source: (p.count, p.xp)};

  group('the level curve', () {
    test('a level takes the base times its square root: a little more each time, ever more gently', () {
      expect(XpCurve.reach(1), 0);
      expect(XpCurve.reach(2), XpTuning.levelBase.round());
      expect(XpCurve.span(4), (2 * XpTuning.levelBase).round());
      expect(XpCurve.span(100), (10 * XpTuning.levelBase).round());
      for (var level = 1; level < 200; level++) {
        expect(XpCurve.reach(level + 1) - XpCurve.reach(level), XpCurve.span(level));
        expect(XpCurve.span(level + 1), greaterThan(XpCurve.span(level)));
      }
      for (var level = 2; level < 200; level++) {
        expect(XpCurve.span(level + 1) - XpCurve.span(level),
            lessThanOrEqualTo(XpCurve.span(level) - XpCurve.span(level - 1) + 1),
            reason: 'never growing faster (±1 for rounding)');
      }
    });

    test('a total sits in the level it has reached, with the XP left to the next', () {
      expect(XpCurve.of(0).level, 1);
      expect(XpCurve.of(XpCurve.reach(2) - 1).level, 1);
      final two = XpCurve.of(XpCurve.reach(2));
      expect((two.level, two.into, two.span), (2, 0, XpCurve.span(2)));
      final mid = XpCurve.of(XpCurve.reach(7) + 120);
      expect((mid.level, mid.into, mid.toNext), (7, 120, XpCurve.span(7) - 120));
    });

    test('a gain names every level it crosses', () {
      final gain = XpGain(
        before: XpCurve.reach(3) - 10,
        award: XpAward([XpPart(XpSource.correct, 1, XpCurve.span(3) + XpCurve.span(4) + 20)]),
      );
      expect(gain.levelBefore.level, 2);
      expect(gain.levelAfter.level, 5);
      expect(gain.levelsGained, 3);
      expect(XpGain(before: 0, award: const XpAward([])).levelsGained, 0);
    });
  });

  group('earning', () {
    test('correct swipes, misses, speed against the goal, reviews and new cards', () {
      final ledger = XpLedger()..add(run([hit(1, 900), hit(2, 900)]));
      final gain = ledger.add(run([
        hit(1, 700, graded: true), // blazing, a review
        hit(2, 1000), // at the goal
        hit(3, 1400, graded: true), // slow, new
        hit(4, 600, clean: false), // a redo: no speed bonus, still new
        miss(5), // new
        miss(6, clean: false), // undone: earns nothing, but met
      ], at: DateTime(2026, 9, 1, 18)));
      expect(parts(gain), {
        XpSource.correct: (4, 4 * XpTuning.perCorrect),
        XpSource.missed: (1, XpTuning.perMiss),
        XpSource.speed: (2, XpTuning.speedBlazing + XpTuning.speedAtGoal),
        XpSource.reviews: (1, XpTuning.perReview),
        XpSource.newCards: (4, 4 * XpTuning.perNewCard),
        XpSource.clear: (1, XpTuning.clear),
      });
      expect(gain.after, ledger.total);
    });

    test('free play meets no new cards and a run ended early earns no clear', () {
      final gain = XpLedger().add(run([hit(1, 1200)], counts: false, total: null));
      expect(parts(gain).keys, [XpSource.correct, XpSource.daily]);
    });

    test('the first run of a day earns the daily bonus, growing with the streak up to its cap', () {
      final ledger = XpLedger();
      int daily(DateTime at) => parts(ledger.add(run([hit(1, 1200)], at: at)))[XpSource.daily]?.$2 ?? 0;
      expect(daily(DateTime(2026, 9, 1, 9)), XpTuning.daily);
      expect(daily(DateTime(2026, 9, 1, 20)), 0, reason: 'once a day');
      expect(daily(DateTime(2026, 9, 2, 7)), XpTuning.daily + XpTuning.perStreakDay);
      expect(daily(DateTime(2026, 9, 3, 7)), XpTuning.daily + 2 * XpTuning.perStreakDay);
      expect(daily(DateTime(2026, 9, 5, 7)), XpTuning.daily, reason: 'a day off restarts the streak');
      for (var d = 6; d < 6 + XpTuning.streakCapDays + 3; d++) {
        daily(DateTime(2026, 9, d, 7));
      }
      expect(daily(DateTime(2026, 9, 6 + XpTuning.streakCapDays + 3, 7)),
          XpTuning.daily + XpTuning.streakCapDays * XpTuning.perStreakDay);
    });

    test('a personal best beats an earlier time on the same setup', () {
      final ledger = XpLedger();
      bool best(Duration? total, {String setup = 'a'}) =>
          parts(ledger.add(run([hit(1, 1200)], setup: setup, total: total))).containsKey(XpSource.best);
      expect(best(const Duration(seconds: 30)), isFalse, reason: 'the first run sets the record');
      expect(best(const Duration(seconds: 31)), isFalse);
      expect(best(null), isFalse, reason: 'a run ended early has no time');
      expect(best(const Duration(seconds: 29)), isTrue);
      expect(best(const Duration(seconds: 10), setup: 'b'), isFalse, reason: 'another setup races itself');
    });

    test('islands and graduation are one-off bonuses, and graduation is latched', () {
      final ledger = XpLedger();
      expect(ledger.graduated, isFalse);
      final gain = ledger.add(run([hit(1, 1200)], islands: 2, graduated: true));
      expect(parts(gain)[XpSource.island], (2, 2 * XpTuning.perIsland));
      expect(parts(gain)[XpSource.graduation], (1, XpTuning.graduation));
      expect(ledger.graduated, isTrue);
    });

    test('the ledger adds runs up in the order they were played', () {
      final early = run([hit(1, 1200)], at: DateTime(2026, 9, 1));
      final late = run([hit(1, 1200)], at: DateTime(2026, 9, 2));
      final ledger = XpLedger.of([late, early]);
      final inOrder = XpLedger()
        ..add(early)
        ..add(late);
      expect(ledger.total, inOrder.total);
    });
  });

  group('recorded runs', () {
    PlaySession play(List<CardRef> cards, int ms) {
      final s = PlaySession(cards);
      var t = const Duration(seconds: 100);
      for (var i = 0; i < cards.length; i++) {
        s.revealed(t);
        t += Duration(milliseconds: ms);
        s.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
        t += const Duration(milliseconds: 100);
      }
      return s;
    }

    test('a tracked run reports its XP, and the history adds up to the same after a reload', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final progress = await Progress.open(db);
      final planned = await progress.planTraining();
      final first = await progress.recordRun(play(planned.cards, 900), const PlayConfig(mode: PlayMode.training), DateTime.now());
      expect(first.xp!.before, 0);
      expect(first.xp!.award.parts.map((p) => p.source), contains(XpSource.newCards));

      final free = await progress.recordRun(
          play(progress.freeDeck(const PlayConfig(mode: PlayMode.free)).take(3).toList(), 900),
          const PlayConfig(mode: PlayMode.free),
          DateTime.now());
      expect(free.xp!.before, first.xp!.after);
      expect(progress.xp.total, free.xp!.after);

      final guest = await progress.recordRun(play([const CardRef(1)], 900), const PlayConfig(mode: PlayMode.guest), DateTime.now());
      expect(guest.xp, isNull, reason: 'a guest earns nothing');

      final again = await Progress.open(db);
      expect(again.xp.total, progress.xp.total);
      await db.close();
    });

    test('the 100th card learned graduates the journey once, even after a reload', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final progress = await Progress.open(db);
      await progress.setLearningMode(LearningMode.journey);
      for (final p in poems.all) {
        progress.trainer.items[ItemKey(p.id, false)]!.unlocked = true;
      }
      final all = [for (final p in poems.all) CardRef(p.id)];
      final half = await progress.recordRun(
          play(all.take(99).toList(), 900), const PlayConfig(mode: PlayMode.training), DateTime.now());
      expect(half.graduated, isFalse);

      final last = await progress.recordRun(play([all.last], 900), const PlayConfig(mode: PlayMode.training), DateTime.now());
      expect(last.graduated, isTrue);
      expect(last.xp!.award.parts.map((p) => p.source), contains(XpSource.graduation));

      final after = await progress.recordRun(play([all.first], 900), const PlayConfig(mode: PlayMode.training), DateTime.now());
      expect(after.graduated, isFalse, reason: 'latched');

      final again = await Progress.open(db);
      expect(again.xp.graduated, isTrue);
      expect(again.xp.total, progress.xp.total, reason: 'the graduation bonus is part of the history');
      await db.close();
    });
  });

  group('暗記練 games', () {
    var nextRun = 1;
    AnkirenXpAnswer first(int ms) => (wrongTaps: 0, responseUs: ms * 1000);
    const second = (wrongTaps: 1, responseUs: 2000000);
    const shown = (wrongTaps: AnkirenTuning.revealAfterWrong, responseUs: 3000000);
    const givenUp = (wrongTaps: 0, responseUs: null);
    AnkirenXpRun game(
      List<AnkirenXpAnswer> answers, {
      bool ranked = false,
      bool completed = true,
      int level = 2,
      String setup = 'level 2',
      int score = 500,
      DateTime? at,
    }) =>
        AnkirenXpRun(
          runId: nextRun++,
          startedAt: at ?? DateTime(2026, 10, 13, 12),
          ranked: ranked,
          completed: completed,
          level: level,
          setup: setup,
          score: score,
          answers: answers,
        );

    test('a first tap earns more at higher levels, and its speed bonus falls with the time', () {
      expect(AnkirenXp.cardXp(0), AnkirenXpTuning.firstTap);
      expect(AnkirenXp.cardXp(AnkirenLevels.top) - AnkirenXp.cardXp(AnkirenLevels.top - 1), AnkirenXpTuning.firstTapPerLevel);
      expect(AnkirenXp.speedXp(100000), AnkirenXpTuning.speedMax);
      expect(AnkirenXp.speedXp(1500000), inExclusiveRange(0, AnkirenXpTuning.speedMax));
      expect(AnkirenXp.speedXp(5000000), 0);
      expect(AnkirenXp.speedXp(0), 0, reason: 'no measurement');
    });

    test('a ranked game played to the end: finds, misses, speed, the clear and the ranked bonus', () {
      final gain = XpLedger().addAnkiren(game(
        [first(100), first(100), (wrongTaps: 0, responseUs: 0), second, shown, givenUp],
        ranked: true,
      ));
      final card = AnkirenXp.cardXp(2);
      expect(parts(gain), {
        XpSource.firstTap: (3, 3 * card),
        XpSource.secondTap: (1, (card * AnkirenXpTuning.secondTapShare).round()),
        XpSource.missed: (2, 2 * AnkirenXpTuning.perMiss),
        XpSource.speed: (2, 2 * AnkirenXpTuning.speedMax),
        XpSource.clear: (1, AnkirenXpTuning.clear),
        XpSource.ranked: (1, AnkirenXpTuning.ranked),
      });
      expect(gain.award.parts.map((p) => p.source).toList(),
          [XpSource.firstTap, XpSource.secondTap, XpSource.missed, XpSource.speed, XpSource.clear, XpSource.ranked],
          reason: 'listed in the order the XP page shows them');
    });

    test('free play earns the same finds without the ranked bonus; ended early, only its finds', () {
      final ledger = XpLedger();
      final free = ledger.addAnkiren(game([first(100), givenUp]));
      expect(parts(free).keys, [XpSource.firstTap, XpSource.missed, XpSource.speed, XpSource.clear]);
      final ended = ledger.addAnkiren(game([first(100), givenUp, givenUp], completed: false));
      expect(parts(ended).keys, [XpSource.firstTap, XpSource.speed]);
    });

    test('a forfeit earns nothing, but counts toward placement', () {
      final ledger = XpLedger();
      ledger.addAnkiren(game([first(500)], ranked: true));
      expect(ledger.addAnkiren(game([first(500), givenUp], ranked: true, completed: false)).award.total, 0);
      final third = ledger.addAnkiren(game([first(500)], ranked: true));
      expect(parts(third)[XpSource.placement], (1, AnkirenXpTuning.placement), reason: 'the third ranked game places');
      expect(parts(ledger.addAnkiren(game([first(500)], ranked: true))).containsKey(XpSource.placement), isFalse);

      final forfeited = XpLedger();
      for (var i = 1; i < AnkirenRatingModel.placementGames; i++) {
        forfeited.addAnkiren(game([first(500)], ranked: true));
      }
      expect(forfeited.addAnkiren(game([first(500)], ranked: true, completed: false)).award.total, 0,
          reason: 'not even the placement bonus');
    });

    test('a personal best beats every earlier score of the same setup, in a game played to the end', () {
      final ledger = XpLedger();
      bool best(int score, {String setup = 'level 2', bool completed = true}) =>
          parts(ledger.addAnkiren(game([first(500)], score: score, setup: setup, completed: completed)))
              .containsKey(XpSource.best);
      expect(best(400), isFalse, reason: 'the first game sets the record');
      expect(best(380), isFalse);
      expect(best(900, completed: false), isFalse, reason: 'a game ended early races nobody');
      expect(best(420), isTrue);
      expect(best(410), isFalse, reason: 'the ended game did not raise the record');
      expect(best(100, setup: 'custom 3 × 60000 ms'), isFalse, reason: 'another setup races itself');
    });

    test('the ledger adds runs and 暗記練 games up in the order played; the daily bonus stays with runs', () {
      final morning = game([first(100)], at: DateTime(2026, 9, 1, 8));
      final noon = run([hit(1, 1200)], at: DateTime(2026, 9, 1, 12));
      final ledger = XpLedger.of([noon], [morning]);
      final inOrder = XpLedger();
      final a = inOrder.addAnkiren(morning);
      final b = inOrder.add(noon);
      expect(ledger.total, inOrder.total);
      expect(b.before, a.after);
      expect(parts(a).containsKey(XpSource.daily), isFalse);
      expect(parts(b)[XpSource.daily], (1, XpTuning.daily), reason: 'the first run of the day, after a game');
    });

    test('recorded games report their XP by kind, and the history adds up to the same after a reload', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final progress = await Progress.open(db);
      await progress.setLearningMode(LearningMode.allKnown);
      final at = DateTime(2026, 10, 13, 9);
      Future<XpGain> record(AnkirenSetup setup, {int? endAfter, Set<int> wrongAt = const {}}) async =>
          (await progress.recordAnkiren(playAnkiren(setup, ms: 600, endAfter: endAfter, wrongAt: wrongAt), startedAt: at))
              .xp!;

      final ranked = await record(AnkirenSetup.forLevel(1, ranked: true), wrongAt: {0});
      final cards = AnkirenLevels.of(1).cards;
      expect(parts(ranked)[XpSource.firstTap], (cards - 1, (cards - 1) * AnkirenXp.cardXp(1)));
      expect(parts(ranked)[XpSource.secondTap]?.$1, 1);
      expect(parts(ranked).keys, containsAll([XpSource.speed, XpSource.clear, XpSource.ranked]));
      expect(ranked.before, 0);

      final free = await record(AnkirenSetup.forLevel(1));
      expect(free.before, ranked.after);
      expect(parts(free).keys, isNot(contains(XpSource.ranked)));

      final custom = await record(const AnkirenSetup.custom(perSide: 4, memorise: Duration(minutes: 1)));
      expect(parts(custom)[XpSource.firstTap]!.$2, 8 * AnkirenXp.cardXp(1), reason: 'scored as the level it matches');

      final ended = await record(AnkirenSetup.forLevel(1), endAfter: 2);
      expect(parts(ended).keys, [XpSource.firstTap, XpSource.speed]);

      final forfeit = await record(AnkirenSetup.forLevel(1, ranked: true), endAfter: 2);
      expect(forfeit.award.parts, isEmpty);
      expect(progress.xp.total, forfeit.after);

      final again = await Progress.open(db);
      expect(again.xp.total, progress.xp.total);
      await db.close();
    });
  });
}
