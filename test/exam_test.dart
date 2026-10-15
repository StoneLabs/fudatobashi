// The graduation exam's run against Tobi: a win graduates, a loss and a try
// left early go to Tobi's page with the next try counting down. With
// RENDER_SCREENS=1 it also writes the exam's screens to build/screens/.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/ranked.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/exam_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/exam/exam_dev.dart';
import 'package:fudatobashi/ui/exam/exam_lost_screen.dart';
import 'package:fudatobashi/ui/exam/exam_opening.dart';
import 'package:fudatobashi/ui/exam/exam_screen.dart';
import 'package:fudatobashi/ui/exam/exam_sheets.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/play/swipe_deck.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/graduation_overlay.dart';
import 'package:fudatobashi/ui/results/results_screen.dart';
import 'package:fudatobashi/ui/run/run_launcher.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['RENDER_SCREENS'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screens/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('Joka', ['YujiSyuku-Joka.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  /// A journey player with every card swiped once, so the exam is open.
  Future<Progress> open(WidgetTester tester, {bool ja = false}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: ja ? 'ja' : 'en', languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.journey);
      await openExamForDev(p);
    });
    expect(p.exam().canStart, isTrue);
    return p;
  }

  /// A Home stand-in that opens the exam as Home does.
  Future<void> pumpHome(WidgetTester tester, Progress p) async {
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMangaTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(child: GestureDetector(onTap: () => startExam(context), child: const Text('HOME'))),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> pushExam(WidgetTester tester, List<CardRef> cards, TobiPace tobi) async {
    tester.state<NavigatorState>(find.byType(Navigator)).push(MangaRoute<void>(builder: (_) => ExamScreen(cards: cards, tobi: tobi)));
    await tester.pump();
    await tester.pump();
  }

  /// Pumps [d] in frames of [step].
  Future<void> pumpFor(WidgetTester tester, Duration d, {Duration step = const Duration(milliseconds: 50)}) async {
    for (var t = Duration.zero; t < d; t += step) {
      await tester.pump(step);
    }
  }

  /// Through the greeting and the count, to the first card revealed.
  Future<PlaySession> toGo(WidgetTester tester) async {
    await pumpFor(tester, ExamMotion.start + const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 16));
    final session = tester.widget<SwipeDeck>(find.byType(SwipeDeck)).session;
    expect(session.currentRevealed, isTrue, reason: 'GO reveals the first card');
    return session;
  }

  Future<void> swipe(WidgetTester tester, PlaySession session) async {
    final before = session.index;
    final g = await tester.startGesture(tester.getCenter(find.byType(SwipeDeck)));
    while (session.index == before) {
      await g.moveBy(const Offset(25, 0));
      await tester.pump(const Duration(milliseconds: 8));
    }
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// Lets the database catch up while the screens move on, until [target]
  /// shows.
  Future<void> until(WidgetTester tester, Finder target) async {
    for (var i = 0; i < 80 && target.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(target, findsOneWidget);
  }

  TobiPace even(Duration total, int cards) =>
      TobiPace(total, [for (var i = 1; i <= cards; i++) total * (i / cards)]);

  final five = [for (final id in [3, 14, 15, 92, 65]) CardRef(id)];

  testWidgets('beating Tobi passes the exam: misses add time, and Results shows the graduation', (tester) async {
    final p = await open(tester);
    await tester.binding.setSurfaceSize(const Size(384, 832));
    await pumpHome(tester, p);
    await pushExam(tester, five, even(const Duration(minutes: 1), five.length));
    expect(find.byType(ExamOpening), findsOneWidget);
    final session = await toGo(tester);

    await swipe(tester, session);
    await swipe(tester, session);
    await tester.tap(find.text('UNDO'));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text(S('en').examPenaltyPop(ExamTuning.missPenaltyMs ~/ 1000)), findsWidgets, reason: 'an undo costs 10 s');
    while (!session.finished) {
      await swipe(tester, session);
    }
    expect(find.byType(ExamShout), findsOneWidget);
    await pumpFor(tester, const Duration(milliseconds: 400));
    await _capture(tester, 'exam_won_en');
    await until(tester, find.byType(ResultsScreen));
    final report = p.sessions.last;
    expect(report.mode, PlayMode.exam.name);
    expect(report.completed, isTrue);
    expect(p.graduated, isTrue);
    expect(p.exam().passed, isTrue);
    await until(tester, find.byType(GraduationOverlay));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("once the player's time with penalties reaches Tobi's, Tobi wins and the next try counts down", (tester) async {
    final p = await open(tester);
    await tester.runAsync(() => p.noteExamStarted(DateTime.now()));
    await tester.binding.setSurfaceSize(const Size(384, 832));
    await pumpHome(tester, p);
    await pushExam(tester, five, even(const Duration(seconds: 12), five.length));
    final session = await toGo(tester);
    await swipe(tester, session);
    await swipe(tester, session);
    await tester.tap(find.text('UNDO'));
    await pumpFor(tester, const Duration(milliseconds: 300));
    expect(find.byType(ExamShout), findsNothing);
    await pumpFor(tester, const Duration(seconds: 2));
    expect(find.byType(ExamShout), findsOneWidget, reason: '10 s of penalty plus 2 s reach his 12 s');
    expect(tester.widget<SwipeDeck>(find.byType(SwipeDeck)).live, isFalse, reason: 'play stops right there');

    await until(tester, find.byType(ExamLostScreen));
    final s = S('en');
    expect(find.text(s.examLostTitle), findsWidgets);
    expect(find.text(s.examNextTry.toUpperCase()), findsOneWidget);
    expect(find.textContaining(RegExp(r'^5\d:\d\d$')), findsOneWidget, reason: 'the hour counting down');
    expect(p.sessions.last.mode, PlayMode.exam.name);
    expect(p.sessions.last.completed, isFalse);
    expect(p.graduated, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving mid-try asks first, then Tobi wins and the try is used', (tester) async {
    final p = await open(tester);
    await tester.binding.setSurfaceSize(const Size(384, 832));
    await pumpHome(tester, p);
    await tester.tap(find.text('HOME'));
    await pumpFor(tester, const Duration(milliseconds: 600));
    final s = S('en');
    await tester.tap(find.text(s.examStart));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byType(ExamScreen), findsOneWidget);
    expect(p.exam().canStart, isFalse, reason: 'the try is used as it starts');
    final session = await toGo(tester);
    await swipe(tester, session);

    await tester.tap(find.text('END'));
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tester.tap(find.text(s.examLeaveNo));
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.byType(ExamLostScreen), findsNothing, reason: 'kept playing');
    await swipe(tester, session);

    await tester.tap(find.text('END'));
    await pumpFor(tester, const Duration(milliseconds: 600));
    await tester.tap(find.text(s.examLeaveYes));
    await until(tester, find.byType(ExamLostScreen));
    expect(find.textContaining(s.examCardsLine(2, RankedTuning.cards)), findsOneWidget, reason: 'how far the try got');
    expect(p.sessions.last.mode, PlayMode.exam.name);
    expect(p.sessions.last.completed, isFalse);
    expect(p.exam().cooldown, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  group('renders', () {
    for (final ja in [false, true]) {
      for (final width in [360.0, 384.0]) {
        for (final scale in [1.0, 1.3]) {
          final tag = '${ja ? 'ja' : 'en'}_${width.round()}_$scale';
          testWidgets('the exam fits ($tag)', (tester) async {
            const dpr = 2.8125;
            const bars = FakeViewPadding(top: 28 * dpr, bottom: 48 * dpr);
            final size = Size(width, width == 360 ? 740 : 832);
            tester.view
              ..devicePixelRatio = dpr
              ..physicalSize = size * dpr
              ..padding = bars
              ..viewPadding = bars;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.reset);
            addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

            final p = await open(tester, ja: ja);
            await tester.runAsync(() => p.noteExamStarted(DateTime.now()));
            await pumpHome(tester, p);
            final home = tester.element(find.text('HOME'));
            confirmExamStart(home);
            await pumpFor(tester, const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull);
            await _capture(tester, 'exam_start_$tag');
            Navigator.of(home).pop();
            await pumpFor(tester, const Duration(milliseconds: 600));

            final tobi = TobiPace.draw(math.Random(7));
            await pushExam(tester, p.rankedDeck(rng: math.Random(7)), tobi);
            await pumpFor(tester, ExamMotion.greeting - const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
            await _capture(tester, 'exam_greeting_$tag');
            await pumpFor(tester, const Duration(milliseconds: 900));
            await _capture(tester, 'exam_countdown_$tag');

            final session = await toGo(tester);
            await _capture(tester, 'exam_go_$tag');
            for (var i = 0; i < 6; i++) {
              await pumpFor(tester, const Duration(seconds: 2), step: const Duration(milliseconds: 250));
              await swipe(tester, session);
            }
            await tester.tap(find.text(S(ja ? 'ja' : 'en').undo));
            await pumpFor(tester, const Duration(milliseconds: 200));
            expect(tester.takeException(), isNull);
            await _capture(tester, 'exam_play_$tag');

            for (var t = Duration.zero; t < tobi.total && find.byType(ExamShout).evaluate().isEmpty; t += const Duration(seconds: 1)) {
              await tester.pump(const Duration(seconds: 1));
            }
            await pumpFor(tester, const Duration(milliseconds: 400));
            expect(find.byType(ExamShout), findsOneWidget);
            await _capture(tester, 'exam_timeup_$tag');
            await until(tester, find.byType(ExamLostScreen));
            for (var i = 0; i < 40 && find.byType(CelebrationSequence).evaluate().isEmpty; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            for (var i = 0; i < 40 && find.byType(CelebrationSequence).evaluate().isNotEmpty; i++) {
              await tester.tapAt(tester.getCenter(find.byType(CelebrationSequence)));
              await tester.pump(const Duration(milliseconds: 400));
            }
            await pumpFor(tester, const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull);
            await _capture(tester, 'exam_lost_$tag');
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  });
}
