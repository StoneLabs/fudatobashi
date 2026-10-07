import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/manga/manga.dart' show OutlinedText;
import 'package:fudatobashi/ui/play/play_screen.dart';
import 'package:fudatobashi/ui/play/pointer_clock.dart';
import 'package:fudatobashi/ui/play/swipe_deck.dart';
import 'package:fudatobashi/ui/play/time_format.dart';
import 'package:fudatobashi/ui/results/results_screen.dart';

import 'test_l10n.dart';
import 'test_play.dart';
import 'test_vector_art.dart';

/// The timing contract across the engine's clocks: touches and frames are
/// stamped from different clocks on iOS, macOS and Linux, and a response
/// at or before its reveal is no measurement.
void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Duration ms(int v) => Duration(milliseconds: v);

  /// An iPhone's sleep since boot: touch times run this far behind frame times.
  const sleep = Duration(hours: 35, minutes: 7, seconds: 12, microseconds: 483012);
  const channel = MethodChannel('fudatobashi/clock');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'sleepOffsetUs' ? sleep.inMicroseconds : null;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

  group('PointerClock', () {
    testWidgets('iOS and macOS: a frame time moves back by the sleep the runner reports', (tester) async {
      await PointerClock.sync();
      expect(calls.single.method, 'sleepOffsetUs');
      expect(PointerClock.offset, sleep);
      expect(PointerClock.fromFrame(sleep + ms(2500)), ms(2500));
    }, variant: const TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.macOS}));

    testWidgets('Linux: a frame time wraps like GTK\'s 32-bit millisecond event times', (tester) async {
      const wrap = Duration(milliseconds: 1 << 32);
      expect(PointerClock.fromFrame(ms(2500)), ms(2500));
      expect(PointerClock.fromFrame(wrap + ms(2500)), ms(2500));
      expect(PointerClock.fromFrame(wrap * 3 + ms(2500)), ms(2500));
      await PointerClock.sync();
      expect(calls, isEmpty, reason: 'nothing to ask the runner');
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('Android and Windows: one clock, nothing to convert or ask', (tester) async {
      await PointerClock.sync();
      expect(calls, isEmpty);
      expect(PointerClock.fromFrame(sleep), sleep);
      expect(PointerClock.offset, Duration.zero);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.windows}));
  });

  group('SwipeDeck on iOS', () {
    final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

    Future<PlaySession> pumpDeck(WidgetTester tester, {Widget? startCard}) async {
      await PointerClock.sync();
      final session = PlaySession([const CardRef(1), const CardRef(2)]);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: SwipeDeck(session: session, live: true, haptics: false, startCard: startCard),
        ),
      ));
      await tester.pump(const Duration(seconds: 2));
      return session;
    }

    testWidgets('the reveal is put on the touch clock, so a swipe is timed exactly', (tester) async {
      final session = await pumpDeck(tester);
      expect(session.revealTs, SchedulerBinding.instance.currentSystemFrameTimeStamp - sleep);

      await _swipeAt(tester, session, session.revealTs! + ms(612));
      expect(session.attempts.single.responseUs, ms(612).inMicroseconds);
      expect(session.attempts.single.validTime, isTrue);
    }, variant: ios);

    testWidgets('a finger already down when the start card leaves is timed from its first move after the reveal',
        (tester) async {
      final session = await pumpDeck(tester, startCard: const ColoredBox(color: Color(0xFF000000)));
      final g = await tester.startGesture(const Offset(200, 400), pointer: 8);
      final waiting = await tester.createGesture(pointer: 7);
      await waiting.down(const Offset(120, 300), timeStamp: SchedulerBinding.instance.currentSystemFrameTimeStamp - sleep);
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(25, 0));
      }
      await g.up();
      await tester.pump(ms(16));
      final reveal = session.revealTs!;
      expect(reveal, SchedulerBinding.instance.currentSystemFrameTimeStamp - sleep);

      const late = Duration(milliseconds: 300);
      for (var i = 0; i < 6 && session.attempts.isEmpty; i++) {
        await waiting.moveBy(const Offset(25, 0), timeStamp: reveal + late + ms(i));
      }
      await waiting.up();
      expect(session.attempts.single.responseUs, late.inMicroseconds);
    }, variant: ios);
  });

  testWidgets('iOS: a run is timed on one clock end to end, card by card, in total and as a best', (tester) async {
    final p = await _openProgress(tester);
    const config = PlayConfig(mode: PlayMode.free);
    final session = await _openPlay(tester, p, config);
    final firstReveal = session.revealTs!;
    expect(firstReveal + sleep, lessThanOrEqualTo(SchedulerBinding.instance.currentSystemFrameTimeStamp),
        reason: 'the reveal frame, moved onto the touch clock');

    final times = [ms(612), ms(845), ms(1033), ms(707)];
    late Duration end;
    for (final t in times) {
      end = await _swipeAt(tester, session, session.revealTs! + t);
    }
    expect(session.attempts.map((a) => a.responseUs), [for (final t in times) t.inMicroseconds]);

    final report = await _results(tester);
    expect(report.total, end - firstReveal);
    expect(p.sessions.single.totalUs, (end - firstReveal).inMicroseconds);
    expect(p.bestFor(config), end - firstReveal);
    expect(report.personalBest, isTrue);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a touch at or before its reveal is no measurement: not timed, graded, rewarded or totalled',
      (tester) async {
    final p = await _openProgress(tester);
    const config = PlayConfig(mode: PlayMode.training);
    final session = await _openPlay(tester, p, config);

    await _swipeAt(tester, session, session.revealTs! + ms(3500));
    await _swipeAt(tester, session, session.revealTs!);
    await _swipeAt(tester, session, session.revealTs! - ms(3));
    // Stamped far behind the frames, as on iOS before the clocks were joined.
    await _swipeAt(tester, session, Duration.zero);
    expect(session.attempts.map((a) => a.responseUs <= 0), [false, true, true, true]);
    expect(session.attempts.map((a) => a.validTime), [true, false, false, false]);

    final report = await _results(tester);
    expect(report.completed, isTrue);
    expect(report.total, isNull, reason: 'the last swipe is stamped before the first reveal');
    expect(report.personalBest, isFalse);
    expect(p.sessions.single.totalUs, isNull);
    expect(p.sessions.single.completed, isTrue);
    expect(p.bestFor(config), isNull);

    final recs = [for (final a in session.attempts) p.attemptsOf(ItemKey(a.card.poemId, a.card.inverted)).single];
    expect(recs.map((r) => r.grade != null), [true, false, false, false], reason: 'FSRS grades only the timed answer');
    expect([for (final a in session.attempts) p.stats(ItemKey(a.card.poemId, false)).timed.length], [1, 0, 0, 0]);
    final xp = {for (final part in report.xp!.award.parts) part.source};
    expect(xp, contains(XpSource.clear));
    expect(xp, isNot(contains(XpSource.speed)));
    expect(xp, isNot(contains(XpSource.best)));

    expect(find.text('TOTAL TIME'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is OutlinedText && w.text == missingTime), findsOneWidget,
        reason: 'no total, shown as a dash');
    expect(find.text('3.500 s'), findsOneWidget, reason: 'the average is over the timed answer only');
    expect(find.text('3.500s'), findsOneWidget, reason: 'the only slow card with a time');
    expect(find.byWidgetPredicate((w) => w is Text && RegExp(r'^-\d').hasMatch(w.data ?? '')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<Progress> _openProgress(WidgetTester tester) async {
  late Progress p;
  await tester.runAsync(() async {
    p = await Progress.open(AppDatabase(NativeDatabase.memory()));
  });
  return p;
}

/// A play screen with four ordinary cards, its start card swiped away.
Future<PlaySession> _openPlay(WidgetTester tester, Progress p, PlayConfig config) async {
  await tester.binding.setSurfaceSize(const Size(384, 832));
  await tester.pumpWidget(ProgressScope(
    progress: p,
    child: MaterialApp(home: PlayScreen(cards: [for (var id = 1; id <= 4; id++) CardRef(id)], config: config)),
  ));
  await tester.pump();
  await tester.pump();
  await swipeStartCard(tester);
  final session = tester.widget<SwipeDeck>(find.byType(SwipeDeck)).session;
  expect(session.currentRevealed, isTrue);
  return session;
}

/// A known swipe on the current card, touching down at [touch] (a
/// pointer-clock time) and moving 8 ms per step until it commits. Returns
/// the committing move's time.
Future<Duration> _swipeAt(WidgetTester tester, PlaySession session, Duration touch) async {
  final before = session.index;
  final g = await tester.createGesture();
  await g.down(const Offset(192, 360), timeStamp: touch);
  var t = touch;
  while (session.index == before) {
    t += const Duration(milliseconds: 8);
    await g.moveBy(const Offset(25, 0), timeStamp: t);
    await tester.pump(const Duration(milliseconds: 8));
  }
  await g.up(timeStamp: t);
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
  return t;
}

/// Waits for the run to be recorded and the Results screen to open.
Future<SessionReport> _results(WidgetTester tester) async {
  for (var i = 0; i < 20 && find.byType(ResultsScreen).evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byType(ResultsScreen), findsOneWidget);
  return tester.widget<ResultsScreen>(find.byType(ResultsScreen)).report;
}
