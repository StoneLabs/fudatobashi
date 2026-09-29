import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

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
    bool counts = true,
    int islands = 0,
    bool graduated = false,
  }) =>
      XpRun(
        sessionId: nextId++,
        startedAt: at ?? DateTime(2026, 9, 1, 12),
        setup: setup,
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
}
