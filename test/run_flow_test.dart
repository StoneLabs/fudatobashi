import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/play/play_screen.dart';
import 'package:fudatobashi/ui/play/swipe_deck.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/new_card_overlay.dart';

/// New cards in a run: where they may first appear, their introduction
/// pages, and the timing contract around them.
void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Duration ms(int v) => Duration(milliseconds: v);

  group('the planner holds new cards back', () {
    TrainingPick pick(int id) => TrainingPick(ItemKey(id, false), PickReason.due, 1);
    bool isNew(int id) => id >= 50;

    test('the first five swipes are cards the player has met', () {
      final picks = [pick(1), pick(50), pick(2), pick(51), pick(3), pick(4), pick(5), pick(6)];
      expect(Trainer.holdBackNew(picks, isNew), TrainingTuning.newCardHoldBack);
      expect(picks.map((p) => p.key.poemId), [1, 2, 3, 4, 5, 50, 51, 6]);
    });

    test('with fewer met cards than that, every met card goes first', () {
      final picks = [pick(50), pick(1), pick(51), pick(2)];
      expect(Trainer.holdBackNew(picks, isNew), 2);
      expect(picks.map((p) => p.key.poemId), [1, 2, 50, 51]);
    });

    test('a planned journey round opens with met cards and names its new ones', () async {
      final progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await progress.setLearningMode(LearningMode.journey);
      final first = await progress.planTraining();
      final firstBatch = {for (final s in progress.trainer.unlocked) s.key.poemId};
      expect(first.newPoems, firstBatch, reason: 'the very first round is all new cards');

      // Meet the first batch, then pull in the next one.
      final met = PlaySession([for (final id in firstBatch) CardRef(id)]);
      var t = ms(0);
      for (var i = 0; i < firstBatch.length; i++) {
        met.revealed(t);
        t += ms(900);
        met.commit(responseTs: t, commitTs: t, outcome: Outcome.known);
      }
      final report = await progress.recordRun(met, const PlayConfig(mode: PlayMode.training), DateTime.now());
      expect(report.newCards, firstBatch.toList(), reason: 'the round lists the cards it met first');

      final nextBatch = {for (final k in (await progress.learnNextCards()).unlockedBefore) k.poemId};
      expect(nextBatch, isNotEmpty);
      for (var seed = 0; seed < 20; seed++) {
        final next = await progress.planTraining(rng: math.Random(seed));
        final planned = {for (final c in next.cards) c.poemId};
        expect(next.newPoems, nextBatch.intersection(planned));
        final opening = next.cards.take(TrainingTuning.newCardHoldBack).map((c) => c.poemId);
        expect(opening.where(next.newPoems.contains), isEmpty, reason: 'seed $seed: ${next.cards.map((c) => c.poemId)}');
      }
      await progress.db.close();
    });
  });

  test('a break before a card is left out of the total, not added to that card', () {
    final s = PlaySession([const CardRef(1), const CardRef(2)]);
    s.revealed(ms(0));
    s.commit(responseTs: ms(500), commitTs: ms(520), outcome: Outcome.known);
    s.takeBreak();
    s.revealed(ms(10520));
    s.commit(responseTs: ms(11000), commitTs: ms(11020), outcome: Outcome.known);
    expect(s.attempts.last.responseUs, 480000);
    expect(s.total, ms(1020));
  });

  testWidgets('a new card is introduced before its first appearance and revealed fresh after the page', (tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(leadIn: false));
    });
    const newCard = 100;
    final cards = [for (final id in [1, 2, 3, 4, 5]) CardRef(id), CardRef(newCard), const CardRef(7), const CardRef(8)];
    await tester.binding.setSurfaceSize(const Size(384, 832));
    await tester.pumpWidget(ProgressScope(
      progress: p,
      child: MaterialApp(
        home: PlayScreen(cards: cards, config: const PlayConfig(mode: PlayMode.free), newPoems: {newCard}),
      ),
    ));
    await tester.pump();
    await tester.pump();
    final session = tester.widget<SwipeDeck>(find.byType(SwipeDeck)).session;

    Future<void> swipe() async {
      expect(session.currentRevealed, isTrue);
      final before = session.index;
      final g = await tester.startGesture(const Offset(192, 360));
      while (session.index == before) {
        await g.moveBy(const Offset(25, 0));
        await tester.pump(ms(8));
      }
      await g.up();
      await tester.pump(ms(16));
      await tester.pump(ms(16));
    }

    for (var i = 0; i < 5; i++) {
      expect(find.byType(NewCardOverlay), findsNothing, reason: 'swipe ${i + 1}');
      await swipe();
    }

    expect(session.index, 5);
    expect(find.byType(NewCardOverlay), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(session.currentRevealed, isFalse, reason: 'the card stays blank under its page');

    await tester.tap(find.text('BRING IT ON!'));
    var closedAt = Duration.zero;
    for (var frame = 0; find.byType(CelebrationSequence).evaluate().isNotEmpty; frame++) {
      expect(frame, lessThan(100));
      expect(session.currentRevealed, isFalse, reason: 'not revealed while the page is still up');
      await tester.pump(ms(16));
      closedAt = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    }
    expect(session.currentRevealed, isFalse, reason: 'the frame that removes the page reveals nothing');
    await tester.pump(ms(16));
    expect(session.currentRevealed, isTrue);
    expect(session.revealTs!, greaterThan(closedAt));

    await tester.pump(ms(400));
    await swipe();
    expect(session.attempts.last.card.poemId, newCard);
    expect(session.attempts.last.responseUs, lessThan(ms(600).inMicroseconds),
        reason: 'the page time is not part of the card time');
    expect(find.byType(NewCardOverlay), findsNothing, reason: 'introduced once');
    await tester.pumpWidget(const SizedBox());
  });
}
