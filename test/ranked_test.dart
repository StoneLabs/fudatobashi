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
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/ranked.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

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

    test('a forfeit is never better than missing every card left at the same pace', () {
      for (final ms in [800, 3000, 9000]) {
        final left = play(all, ms, stopAfter: 40);
        final forfeit = RankedScore.of(left, left.elapsed).scored;
        final finishedBadly = play(all, ms, stopAfter: 100);
        final missedRest = finishedBadly.total! + const Duration(milliseconds: 60 * RankedTuning.missPenaltyMs);
        expect(forfeit, greaterThanOrEqualTo(missedRest), reason: '$ms ms a card');
      }
    });

    test("Tobi's cards add up to his time, inside its range", () {
      for (var seed = 0; seed < 20; seed++) {
        final tobi = TobiPace.draw(math.Random(seed));
        expect(tobi.total.inMilliseconds, inInclusiveRange(ExamTuning.tobiMinMs, ExamTuning.tobiMaxMs));
        expect(tobi.cardEnds, hasLength(RankedTuning.cards));
        expect(tobi.cardEnds.last, tobi.total);
        for (var i = 1; i < tobi.cardEnds.length; i++) {
          expect(tobi.cardEnds[i], greaterThan(tobi.cardEnds[i - 1]));
        }
        expect(tobi.doneAt(Duration.zero), 0);
        expect(tobi.doneAt(tobi.total), RankedTuning.cards);
      }
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
      await db.close();
    });

    test('a ranked run the app never recorded counts as a forfeit on the next start', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      await p.noteRankedStarted(DateTime.now());
      final again = await Progress.open(db);
      expect(again.sessions.single.completed, isFalse);
      expect(again.sessions.single.mode, PlayMode.ranked.name);
      expect(again.rating, closeTo(Rating.performance(RankedScore.blank().scored.inMilliseconds.toDouble()), 1e-6));
      final third = await Progress.open(db);
      expect(third.sessions, hasLength(1), reason: 'counted once');
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
      await p.closeSwitchBanner();
      expect((await Progress.open(db)).switchBannerShown, isFalse);
      await db.close();
    });
  });
}
