// The practice round's stop before ス (when to mark a card forgotten, and
// Undo), and the tour's first real card, む: Tobi on its real new card
// screen (with the reader reading it), the real swipe, then Tobi on being
// honest. The swipe is real progress once, never twice; Skip leaves from
// inside both rounds.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/tour_strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/home_screen.dart';
import 'package:fudatobashi/ui/play/play_screen.dart';
import 'package:fudatobashi/ui/play/swipe_deck.dart';
import 'package:fudatobashi/ui/results/new_card_overlay.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/tour/tour_anchor.dart';
import 'package:fudatobashi/ui/tour/tour_overlay.dart';
import 'package:fudatobashi/ui/tour/tour_steps.dart';
import 'package:fudatobashi/ui/tour/tutorial_coach.dart';

import 'test_l10n.dart';
import 'test_play.dart';
import 'test_vector_art.dart';

const _phone = Size(384, 832);
const _scrim = Offset(5, 420);
const s = S('en');

class _Reader extends Sounds {
  final read = <int>[];

  @override
  Future<void> playKimarijiVoice(int poemId) async => read.add(poemId);
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('the tour card is the journey\'s first card, and a fresh 修行 opens with it, new', () async {
    const config = TrainerConfig();
    expect(Trainer.learningBatches(poems, fudaSets, config.batchSize).first.first, TourTuning.firstCard);
    expect(poems[TourTuning.firstCard].kimariji, 'む');
    final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    await p.setLearningMode(LearningMode.journey);
    final planned = await p.planTraining();
    expect(planned.cards.first.poemId, TourTuning.firstCard);
    expect(planned.newPoems, contains(TourTuning.firstCard));
    await p.db.close();
  });

  late _Reader reader;

  Future<Progress> open(WidgetTester tester, {DontKnowInput input = DontKnowInput.hold}) async {
    reader = _Reader();
    sounds = reader;
    addTearDown(() => sounds = Sounds());
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(
          p.settings.copyWith(language: 'en', languagePicked: true, toured: false, dontKnowInput: input));
      await p.setLearningMode(LearningMode.journey);
    });
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = _phone * 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FudatobashiApp(progress: p));
    await tester.pump(const Duration(milliseconds: 500));
    return p;
  }

  // Lets the database catch up until [done].
  Future<void> settleDb(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 60 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(done(), isTrue);
  }

  Future<void> typeOut(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(seconds: 6));
  }

  Future<void> tapOn(WidgetTester tester) async {
    await typeOut(tester);
    await tester.tapAt(_scrim);
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder line(String text) => find.text(text, findRichText: true);

  Finder anchorOn(Finder screen, TourSpot spot) =>
      find.descendant(of: screen, matching: find.byWidgetPredicate((w) => w is TourAnchor && w.spot == spot));

  Future<void> drag(WidgetTester tester, Offset by, {Duration hold = Duration.zero}) async {
    final g = await tester.startGesture(const Offset(192, 320));
    for (var i = 0; i < 4; i++) {
      await g.moveBy(by);
      await tester.pump(const Duration(milliseconds: 8));
    }
    await tester.pump(hold);
    await g.up();
    await tester.pump(const Duration(milliseconds: 400));
  }

  // The practice round's stop before ス: when to mark a card forgotten,
  // then Undo pointed at, in order.
  Future<void> throughForgetting(WidgetTester tester, DontKnowInput input) async {
    await tester.pump(TutorialTuning.forgetPause);
    for (final (i, step) in TourStep.forgetting(input).indexed) {
      await tester.pump(const Duration(milliseconds: 650));
      expect(line(step.line(s)), findsOneWidget, reason: 'forgetting stop $i');
      if (step.spot case final spot?) expect(anchorOn(find.byType(PlayScreen), spot), findsOneWidget);
      await tapOn(tester);
    }
    expect(find.byType(TourOverlay).evaluate().where((e) => e.findAncestorWidgetOfExactType<PlayScreen>() != null),
        isEmpty);
    await tester.pump(const Duration(milliseconds: 400));
  }

  // From the tour's start to its first card stop, the practice round won.
  Future<void> toFirstCardStop(WidgetTester tester, {DontKnowInput input = DontKnowInput.hold}) async {
    for (final step in TourStep.of(LearningMode.journey, tabsLocked: false)) {
      if (step.firstCard) break;
      await tapOn(tester);
      if (step.practice) {
        await tester.pump(const Duration(seconds: 1));
        await drag(tester, const Offset(40, 0));
        await drag(tester, const Offset(40, 0));
        await throughForgetting(tester, input);
        if (input == DontKnowInput.button) {
          await tester.tap(find.text(s.dontRemember));
          await tester.pump(const Duration(milliseconds: 400));
        } else {
          await drag(tester, const Offset(0, 25), hold: SwipeTuning.dontKnowHoldDwell + const Duration(milliseconds: 50));
        }
        await drag(tester, const Offset(40, 0));
        await tester.pump(TutorialTuning.doneLinger);
        await tester.pump(const Duration(milliseconds: 600));
      }
    }
    expect(line(s.tourFirstCard), findsOneWidget);
  }

  // Opens the first card and swipes its start card away, up to the new
  // card screen with Tobi on it.
  Future<void> toNewCardScreen(WidgetTester tester) async {
    await tapOn(tester);
    await settleDb(tester, () => find.byType(PlayScreen).evaluate().isNotEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(s.coachStartCard, findRichText: true), findsOneWidget);
    await swipeStartCard(tester);
    expect(find.byType(NewCardOverlay), findsOneWidget);
    await tester.pump(TourTuning.newCardSettle);
    await tester.pump(const Duration(milliseconds: 50));
  }

  // Through Tobi's stops on the new card screen, checking each.
  Future<void> throughNewCardStops(WidgetTester tester) async {
    final steps = TourStep.newCard('mu');
    for (final (i, step) in steps.indexed) {
      await tester.pump(const Duration(milliseconds: 650));
      expect(line(step.line(s)), findsOneWidget, reason: 'stop $i');
      expect(anchorOn(find.byType(NewCardOverlay), step.spot!), findsOneWidget, reason: 'stop $i is on the real screen');
      if (step.voice != null) expect(reader.read, [TourTuning.firstCard], reason: 'the reader reads む');
      await tapOn(tester);
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(NewCardOverlay), findsNothing, reason: 'the new card screen has closed');
    expect(find.byType(TutorialCoach), findsOneWidget);
    expect(line(s.coachFirstCard('mu')), findsOneWidget);
  }

  Future<void> swipeTheCard(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    final session = tester.widget<SwipeDeck>(find.byType(SwipeDeck)).session;
    expect(session.current?.poemId, TourTuning.firstCard);
    await drag(tester, const Offset(40, 0));
    await settleDb(tester, () => line(s.tourHonest).evaluate().isNotEmpty);
  }

  Future<void> throughHonesty(WidgetTester tester, DontKnowInput input) async {
    final steps = TourStep.honesty(input);
    for (final (i, step) in steps.indexed) {
      await tester.pump(const Duration(milliseconds: 650));
      expect(line(step.line(s)), findsOneWidget, reason: 'honesty stop $i');
      if (step.spot case final spot?) expect(anchorOn(find.byType(PlayScreen), spot), findsOneWidget);
      await tapOn(tester);
    }
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(PlayScreen), findsNothing);
  }

  Future<void> finish(WidgetTester tester, Progress p) async {
    expect(line(s.tourFinale), findsOneWidget);
    await tapOn(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TourOverlay), findsNothing);
    expect(p.settings.toured, isTrue);
  }

  testWidgets('the tour walks the first real card, and its swipe is the card\'s first look', (tester) async {
    final p = await open(tester);
    await toFirstCardStop(tester);
    expect(p.knows(TourTuning.firstCard), isFalse);
    await toNewCardScreen(tester);
    await throughNewCardStops(tester);
    await swipeTheCard(tester);

    expect(p.runs, hasLength(1), reason: 'recorded as soon as it is swiped');
    expect(p.runs.single.mode, PlayMode.training);
    expect(p.cardsIn(p.runs.single.id), 1);
    expect(p.knows(TourTuning.firstCard), isTrue);
    expect(p.stats(const ItemKey(TourTuning.firstCard, false)).seen, isTrue);

    await throughHonesty(tester, DontKnowInput.hold);
    await finish(tester, p);
    expect(p.runs, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a replay of the tour shows the first card again but records nothing', (tester) async {
    final p = await open(tester, input: DontKnowInput.button);
    await toFirstCardStop(tester, input: DontKnowInput.button);
    await toNewCardScreen(tester);
    await throughNewCardStops(tester);
    await swipeTheCard(tester);
    await throughHonesty(tester, DontKnowInput.button);
    await finish(tester, p);
    final looks = p.stats(const ItemKey(TourTuning.firstCard, false)).all.length;

    replayTour(tester.element(find.byType(HomeScreen)));
    await settleDb(tester, () => find.byType(TourOverlay).evaluate().isNotEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    reader.read.clear();
    await toFirstCardStop(tester, input: DontKnowInput.button);
    await toNewCardScreen(tester);
    await throughNewCardStops(tester);
    await swipeTheCard(tester);
    await throughHonesty(tester, DontKnowInput.button);
    await finish(tester, p);
    expect(p.runs, hasLength(1), reason: 'the replay is not recorded');
    expect(p.stats(const ItemKey(TourTuning.firstCard, false)).all.length, looks);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Skip on the new card screen ends the tour and records nothing', (tester) async {
    final p = await open(tester);
    await toFirstCardStop(tester);
    await toNewCardScreen(tester);
    await tester.pump(const Duration(milliseconds: 650));
    await tapOn(tester);
    expect(line(s.tourReader), findsOneWidget);
    await tester.tap(find.text(s.tourSkip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(PlayScreen), findsNothing);
    expect(find.byType(TourOverlay), findsNothing);
    expect(p.settings.toured, isTrue);
    expect(p.runs, isEmpty);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Skip at the practice round\'s stop before ス ends the tour', (tester) async {
    final p = await open(tester);
    for (final step in TourStep.of(LearningMode.journey, tabsLocked: false)) {
      await tapOn(tester);
      if (step.practice) break;
    }
    await tester.pump(const Duration(seconds: 1));
    await drag(tester, const Offset(40, 0));
    await drag(tester, const Offset(40, 0));
    await tester.pump(TutorialTuning.forgetPause);
    await typeOut(tester);
    expect(line(s.tourWhyForgetHold), findsOneWidget);
    await tester.tap(find.text(s.tourSkip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(PlayScreen), findsNothing);
    expect(find.byType(TourOverlay), findsNothing);
    expect(p.settings.toured, isTrue);
    expect(p.runs, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Skip after the swipe keeps the swipe and ends the tour', (tester) async {
    final p = await open(tester);
    await toFirstCardStop(tester);
    await toNewCardScreen(tester);
    await throughNewCardStops(tester);
    await swipeTheCard(tester);
    await typeOut(tester);
    await tester.tap(find.text(s.tourSkip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(PlayScreen), findsNothing);
    expect(find.byType(TourOverlay), findsNothing);
    expect(p.settings.toured, isTrue);
    expect(p.runs, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
}
