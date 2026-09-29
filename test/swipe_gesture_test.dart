import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/play/swipe_deck.dart';
import 'package:fudatobashi/ui/play/swipe_gesture.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';

import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());

  const commit = 60.0;
  const hold = SwipeGesture(input: DontKnowInput.hold, commitDistance: commit);
  const button = SwipeGesture(input: DontKnowInput.button, commitDistance: commit);

  group('SwipeGesture', () {
    test('short drags keep tracking in every mode', () {
      expect(hold.onMove(const Offset(0, 30), holding: false), SwipeVerdict.track);
      expect(button.onMove(const Offset(30, 0), holding: false), SwipeVerdict.track);
    });

    test('a known swipe commits the moment it crosses the commit distance', () {
      expect(hold.onMove(const Offset(70, 0), holding: false), SwipeVerdict.known);
      expect(hold.onMove(const Offset(-50, -50), holding: false), SwipeVerdict.known);
      expect(button.onMove(const Offset(0, 70), holding: false), SwipeVerdict.known);
    });

    test('straight down parks in the hold, only within the down cone', () {
      expect(hold.onMove(const Offset(0, 70), holding: false), SwipeVerdict.hold);
      expect(hold.onMove(const Offset(20, 70), holding: false), SwipeVerdict.hold); // ≈16°
      expect(hold.onMove(const Offset(45, 70), holding: false), SwipeVerdict.known); // ≈33°
    });

    test('once holding, the finger may wander wider before it turns known', () {
      expect(hold.onMove(const Offset(45, 70), holding: true), SwipeVerdict.hold); // ≈33°
      expect(hold.onMove(const Offset(70, 70), holding: true), SwipeVerdict.known); // 45°
      expect(hold.onMove(const Offset(0, 30), holding: true), SwipeVerdict.track);
    });

    test('the hold becomes don\'t know only after the dwell', () {
      const dwell = SwipeTuning.dontKnowHoldDwell;
      expect(hold.onHold(dwell - const Duration(milliseconds: 1)), SwipeVerdict.hold);
      expect(hold.onHold(dwell), SwipeVerdict.dontKnow);
      expect(SwipeGesture.holdProgress(dwell ~/ 2), closeTo(0.5, 1e-6));
      expect(SwipeGesture.holdProgress(dwell * 2), 1);
    });

    test('lifting before the dwell is a known swipe; a short slow release springs back', () {
      expect(hold.onRelease(const Offset(0, 80), Offset.zero), SwipeVerdict.known);
      expect(hold.onRelease(const Offset(0, 30), const Offset(0, 900)), SwipeVerdict.known);
      expect(hold.onRelease(const Offset(0, 30), const Offset(0, 100)), SwipeVerdict.springBack);
      expect(hold.onRelease(const Offset(0, 10), const Offset(0, 900)), SwipeVerdict.springBack);
    });
  });

  group('SwipeDeck', () {
    Future<(PlaySession, GlobalKey<SwipeDeckState>)> pumpDeck(WidgetTester tester, DontKnowInput input) async {
      final session = PlaySession([const CardRef(1), const CardRef(2), const CardRef(3)]);
      final key = GlobalKey<SwipeDeckState>();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: SwipeDeck(key: key, session: session, live: true, dontKnowInput: input, haptics: false),
        ),
      ));
      await tester.pump();
      expect(session.currentRevealed, isTrue);
      return (session, key);
    }

    Future<void> dragDown(WidgetTester tester, {required Duration holdFor}) async {
      final g = await tester.startGesture(const Offset(200, 400));
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 8));
      }
      await tester.pump(holdFor);
      await g.up();
      await tester.pump(const Duration(milliseconds: 16));
    }

    testWidgets('swipe down and hold marks don\'t know', (tester) async {
      final (session, _) = await pumpDeck(tester, DontKnowInput.hold);
      await dragDown(tester, holdFor: SwipeTuning.dontKnowHoldDwell + const Duration(milliseconds: 50));
      expect(session.attempts.single.outcome, Outcome.dontKnow);
    });

    testWidgets('a quick down flick is a known swipe', (tester) async {
      final (session, _) = await pumpDeck(tester, DontKnowInput.hold);
      await dragDown(tester, holdFor: const Duration(milliseconds: 40));
      expect(session.attempts.single.outcome, Outcome.known);
    });

    testWidgets('a sideways swipe commits as known before the finger lifts', (tester) async {
      final (session, _) = await pumpDeck(tester, DontKnowInput.hold);
      final g = await tester.startGesture(const Offset(200, 400));
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(25, 0));
        await tester.pump(const Duration(milliseconds: 8));
      }
      expect(session.attempts.single.outcome, Outcome.known);
      await g.up();
    });

    testWidgets('button mode: holding down stays known; the button marks don\'t know', (tester) async {
      final (session, key) = await pumpDeck(tester, DontKnowInput.button);
      await dragDown(tester, holdFor: SwipeTuning.dontKnowHoldDwell * 2);
      expect(session.attempts.single.outcome, Outcome.known);
      await tester.pump();
      key.currentState!.markDontKnow(session.revealTs! + const Duration(milliseconds: 700));
      expect(session.attempts.last.outcome, Outcome.dontKnow);
      expect(session.attempts.last.responseUs, 700000);
    });
  });

  group('SwipeDeck start card', () {
    Duration? startedAt;

    Future<PlaySession> pumpDeck(WidgetTester tester) async {
      startedAt = null;
      final session = PlaySession([const CardRef(1), const CardRef(2)]);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: SwipeDeck(
            session: session,
            live: true,
            haptics: false,
            startCard: const ColoredBox(color: Color(0xFF000000)),
            onStarted: () => startedAt = SchedulerBinding.instance.currentSystemFrameTimeStamp,
          ),
        ),
      ));
      await tester.pump(const Duration(seconds: 2));
      return session;
    }

    bool anyTextShown(WidgetTester tester) =>
        tester.widgetList<TorifudaCard>(find.byType(TorifudaCard)).any((c) => c.showText);

    testWidgets('the first card stays blank under it and is revealed on a frame after it leaves; it is no attempt',
        (tester) async {
      final session = await pumpDeck(tester);
      expect(session.currentRevealed, isFalse);
      expect(anyTextShown(tester), isFalse, reason: 'nothing can be read under the start card');

      // Straight down, which would be a don't-know hold for a real card.
      final g = await tester.startGesture(const Offset(200, 400));
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(0, 25));
      }
      expect(startedAt, isNotNull, reason: 'the start card goes whichever way it is swiped');
      expect(session.currentRevealed, isFalse, reason: 'the reveal waits for a frame that paints the card');
      await g.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(session.revealTs, SchedulerBinding.instance.currentSystemFrameTimeStamp);
      expect(session.revealTs!, greaterThan(startedAt!));
      expect(anyTextShown(tester), isTrue);
      expect(session.attempts, isEmpty);
      expect(session.index, 0);

      for (var n = 1; n <= 2; n++) {
        final swipe = await tester.startGesture(const Offset(200, 400));
        for (var i = 0; i < 6 && session.attempts.length < n; i++) {
          await swipe.moveBy(const Offset(25, 0));
          await tester.pump(const Duration(milliseconds: 8));
        }
        await swipe.up();
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(session.attempts.map((a) => a.card.poemId), [1, 2], reason: 'only the real cards are attempts');
      expect(session.firstRevealTs!, greaterThan(startedAt!), reason: 'the run is timed from the first real card');
    });

    testWidgets('a finger already down when it leaves is timed from its first move after the reveal', (tester) async {
      final session = await pumpDeck(tester);
      final g = await tester.startGesture(const Offset(200, 400), pointer: 8);
      final waiting = await tester.createGesture(pointer: 7);
      await waiting.down(const Offset(120, 300), timeStamp: const Duration(seconds: 1));
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(25, 0));
      }
      await g.up();
      await tester.pump(const Duration(milliseconds: 16));
      final reveal = session.revealTs!;

      const late = Duration(milliseconds: 300);
      for (var i = 0; i < 6 && session.attempts.isEmpty; i++) {
        await waiting.moveBy(const Offset(25, 0), timeStamp: reveal + late + Duration(milliseconds: i));
      }
      await waiting.up();
      expect(session.attempts.single.responseUs, late.inMicroseconds);
    });
  });

  test('journey mode has no "off": it falls back to hold', () {
    const off = AppSettings(dontKnowInput: DontKnowInput.off);
    expect(off.dontKnowInputFor(LearningMode.allKnown), DontKnowInput.off);
    expect(off.dontKnowInputFor(LearningMode.journey), DontKnowInput.hold);
    expect(AppSettings.fromJson(off.toJson()).dontKnowInput, DontKnowInput.off);
  });
}
