// 一騎打ち's match run (IkkiuchiMatchFlow) through the developer's debug
// game: its stages in order, the 送り札 the rules leave, the same-time
// takes, Tobi's rating slider, and the end. With RENDER_SCREENS=1 it writes
// its PNGs to build/screens/ikkiuchi/.
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_board.dart';
import 'package:fudatobashi/domain/ikkiuchi_cards.dart';
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_debug_game.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_painter.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_board.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/manga/theme.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

class _Quiet extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('The rules', () {
    const tobi = IkkiuchiSide.tobi, player = IkkiuchiSide.player;

    test('a take from the other side: the taker sends one; from their own side: none', () {
      expect(const IkkiuchiReadEnd(taker: player, cardSide: tobi).sends, (from: player, count: 1));
      expect(const IkkiuchiReadEnd(taker: tobi, cardSide: player).sends, (from: tobi, count: 1));
      expect(const IkkiuchiReadEnd(taker: player, cardSide: player).sends, isNull);
    });

    test('a fault: the one who faulted gets a card from the other; on a からふだ, two for both sides', () {
      expect(const IkkiuchiReadEnd(taker: player, cardSide: player, tobiFaults: {player}).sends, (from: player, count: 1));
      expect(const IkkiuchiReadEnd(playerFaults: {tobi}).sends, (from: tobi, count: 1));
      expect(const IkkiuchiReadEnd(playerFaults: {tobi, player}).sends, (from: tobi, count: 2));
      expect(const IkkiuchiReadEnd(playerFaults: {tobi}, tobiFaults: {player}).sends, isNull, reason: 'both fault: even');
    });

    test('a take and a fault on one read (第二十五条): two, or only the difference', () {
      expect(const IkkiuchiReadEnd(taker: player, cardSide: tobi, tobiFaults: {player}).sends, (from: player, count: 2),
          reason: 'took from his side and he faulted');
      expect(const IkkiuchiReadEnd(taker: player, cardSide: tobi, playerFaults: {player}).sends, isNull,
          reason: 'took from his side but faulted on their own');
      expect(const IkkiuchiReadEnd(taker: tobi, cardSide: tobi, playerFaults: {player}).sends, (from: tobi, count: 1));
    });

    test('takes within the same-time window go to the side the card lies on; else to the first', () {
      final w = IkkiuchiPlayTuning.sameTime.inMicroseconds / 1000;
      expect(w, closeTo(16.66, 1e-9));
      expect(IkkiuchiBoard.takerOf(player: 100, tobi: 100 + w, side: tobi), tobi);
      expect(IkkiuchiBoard.takerOf(player: 100 + w, tobi: 100, side: player), player);
      expect(IkkiuchiBoard.takerOf(player: 100, tobi: 100 + w + 0.1, side: tobi), player);
      expect(IkkiuchiBoard.takerOf(player: 100 + w + 0.1, tobi: 100, side: player), tobi);
      expect(IkkiuchiBoard.takerOf(player: 5, side: tobi), player);
      expect(IkkiuchiBoard.takerOf(tobi: 5, side: player), tobi);
      expect(IkkiuchiBoard.takerOf(side: player), isNull);
    });

    test('the read order is the field and 10 からふだ for every 25 field cards', () {
      final field = List.generate(50, (i) => i + 1), away = List.generate(50, (i) => i + 51);
      final order = IkkiuchiReadOrder.deal(field: field, away: away, rng: math.Random(1));
      expect(order.where((id) => id <= 50).toSet(), field.toSet());
      expect(order.where((id) => id > 50), hasLength(20));
      expect(order.take(10).toList(), isNot(List.generate(10, (i) => i + 1)), reason: 'shuffled');
      expect(IkkiuchiReadOrder.deal(field: field.take(10).toList(), away: away, rng: math.Random(1)), hasLength(14));
    });
  });

  group('The debug game', () {
    final real = sounds;
    setUp(() => sounds = _Quiet());
    tearDown(() => sounds = real);

    setUpAll(() async {
      await loadRenderMonoFont();
      await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
      await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
      if (renderScreens) {
        await _loadFont('Torifuda', ['YujiSyuku-Regular.ttf']);
        await _loadFont('TorifudaNumber', ['TeXGyreSchola-Regular.otf']);
      }
      await CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
      await _loadFont('ZenKaku', [
        'ZenKakuGothicNew-Regular.ttf',
        'ZenKakuGothicNew-Medium.ttf',
        'ZenKakuGothicNew-Bold.ttf',
        'ZenKakuGothicNew-Black.ttf',
      ]);
    });

    const frame = Duration(milliseconds: 16);

    Future<Progress> open(WidgetTester tester) async {
      late Progress p;
      await tester.runAsync(() async {
        p = await Progress.open(AppDatabase(NativeDatabase.memory()));
        await p.updateSettings(p.settings.copyWith(
            language: 'ja',
            languagePicked: true,
            toured: true,
            debugMode: true,
            kimarijiScript: KimarijiScript.hiragana));
      });
      return p;
    }

    Future<void> show(WidgetTester tester, Progress p, Widget page) async {
      useScreen(tester, usersPhone);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(RepaintBoundary(
        key: screenKey,
        child: ProgressScope(
          progress: p,
          child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildMangaTheme(), home: page),
        ),
      ));
      await tester.pump();
      await tester.pump(frame);
    }

    Future<void> capture(WidgetTester tester, String name) async {
      if (!renderScreens) return;
      await tester.runAsync(() async {
        final context = tester.element(find.byType(IkkiuchiBoardView));
        await precacheImage(const AssetImage(IkkiuchiBoardStyle.tatami), context);
      });
      await tester.pump();
      await tester.pump();
      await captureScreen(tester, 'ikkiuchi/$name');
    }

    IkkiuchiDebugGameState game(WidgetTester tester) => tester.state(find.byType(IkkiuchiDebugGame));
    IkkiuchiMatchFlow flow(WidgetTester tester) => game(tester).flow!;
    IkkiuchiStage stage(WidgetTester tester) => flow(tester).stage;
    Finder tool(String label) => find.descendant(of: find.byType(IkkiuchiDebugTools), matching: find.text(label));

    Future<void> run(WidgetTester tester, double ms) async {
      for (var t = 0.0; t < ms; t += frame.inMilliseconds) {
        await tester.pump(frame);
      }
    }

    Future<void> runUntil(WidgetTester tester, bool Function() done, {double most = 20000}) async {
      for (var t = 0.0; t < most && !done(); t += frame.inMilliseconds) {
        await tester.pump(frame);
      }
      expect(done(), isTrue);
    }

    Offset onScreen(WidgetTester tester, Vec at) =>
        tester.renderObject<RenderBox>(find.byType(IkkiuchiBoardView)).localToGlobal(Offset(at.x, at.y));

    // The debug game of [seed] on to its first read, Tobi off.
    Future<void> toFirstRead(WidgetTester tester, Progress p, int seed, {bool landscape = true}) async {
      await show(tester, p, IkkiuchiDebugGame(seed: seed, landscape: landscape));
      game(tester).setRating(null);
      await tester.tap(tool(IkkiuchiToolsStyle.startLabel));
      await tester.pump(frame);
      expect(stage(tester), IkkiuchiStage.gameStart);
      await run(tester, IkkiuchiMatchTuning.greeting.inMilliseconds + 50.0);
      expect(stage(tester), IkkiuchiStage.yoka);
      await run(tester, IkkiuchiMatchTuning.yoka.inMilliseconds + 50.0);
      expect(stage(tester), IkkiuchiStage.kaminoku);
    }

    // A seed whose first read is a card on [side], clear of the tools.
    Future<int> seedReading(WidgetTester tester, Progress p, IkkiuchiSide side) async {
      for (var seed = 0;; seed++) {
        await toFirstRead(tester, p, seed);
        final board = flow(tester).scene.board;
        final called = board.called;
        if (called == null || board.cards.card(called).side != side) continue;
        final tools = Rect.fromPoints(
            tester.getTopLeft(find.byType(IkkiuchiDebugTools)), tester.getBottomRight(find.byType(IkkiuchiDebugTools)));
        if (!tools.inflate(8).contains(onScreen(tester, board.cards.card(called).box.centre))) return seed;
      }
    }

    Future<void> touch(WidgetTester tester, Vec at) async {
      final g = await tester.startGesture(onScreen(tester, at));
      await tester.pump(frame);
      await g.up();
      await tester.pump(frame);
    }

    testWidgets('memory time, 始, Game Start, Yoka, then the reads in order, the 下の句 7 s', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 3));
      expect(stage(tester), IkkiuchiStage.memoryTime);
      expect(find.text(IkkiuchiToolsStyle.memoryTime), findsOneWidget);
      expect(find.text('のこり 15:00'), findsOneWidget, reason: 'the time left in the gap');
      await run(tester, 2000);
      expect(find.text('のこり 14:58'), findsOneWidget);
      expect(flow(tester).canArrange, isTrue, reason: 'cards may move while memorising');
      await capture(tester, 'game_memory_time');
      await tester.tap(tool(IkkiuchiToolsStyle.goLabel));
      await tester.pump(frame);
      expect(stage(tester), IkkiuchiStage.memoryTime, reason: '▶ only lets a held match go');
      await tester.tap(tool(IkkiuchiToolsStyle.startLabel));
      await tester.pump(frame);
      expect(stage(tester), IkkiuchiStage.gameStart, reason: '始 ends the memory time');
      await run(tester, 600);
      expect(find.byType(IkkiuchiGreeting), findsOneWidget);
      expect(find.text('よろしくお願いします'), findsNWidgets(4), reason: 'on each half, fill and outline');
      await capture(tester, 'game_greeting');
      await run(tester, IkkiuchiMatchTuning.greeting.inMilliseconds.toDouble());
      expect(stage(tester), IkkiuchiStage.yoka);
      await run(tester, IkkiuchiMatchTuning.yoka.inMilliseconds + 50.0);
      expect(stage(tester), IkkiuchiStage.kaminoku);
      expect(flow(tester).canArrange, isFalse);
      final s = flow(tester).scene;
      final call = s.reader.call!;
      await run(tester, call.decidedAt / 2);
      expect(find.text(IkkiuchiDebugTools.stageName(stage(tester))), findsOneWidget);
      expect(find.text('Tobi rating: 1600'), findsOneWidget);
      await capture(tester, 'game_kaminoku');
      await run(tester, call.decidedAt);
      expect(stage(tester), s.board.called == null && s.readOver ? isNot(IkkiuchiStage.kaminoku) : IkkiuchiStage.waitingForHit);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a take on their own side holds at ▶, then 1s wait, 下の句 7 s, 1s break, the next 上の句',
        (tester) async {
      final p = await open(tester);
      await seedReading(tester, p, IkkiuchiSide.player);
      final s = flow(tester).scene;
      final read = s.board.called!;
      await run(tester, s.reader.call!.decidedAt + 50);
      expect(stage(tester), IkkiuchiStage.waitingForHit);
      expect(flow(tester).canArrange, isFalse);
      await touch(tester, s.board.cards.card(read).box.centre);
      expect(s.board.take?.card, read);
      await runUntil(tester, () => stage(tester) == IkkiuchiStage.waitingForGo);
      expect(s.sides!.playerCards, isNot(contains(read)), reason: 'the card taken left their side');
      expect(flow(tester).canArrange, isFalse);
      await tester.tap(tool(IkkiuchiToolsStyle.goLabel));
      await tester.pump(frame);
      expect(stage(tester), IkkiuchiStage.waitBeforeShimonoku);
      expect(flow(tester).canArrange, isTrue);
      await run(tester, 1000 + 50);
      expect(stage(tester), IkkiuchiStage.shimonoku);
      expect(flow(tester).canArrange, isTrue);
      await run(tester, 7000 - 100);
      expect(stage(tester), IkkiuchiStage.shimonoku, reason: 'the 下の句 lasts 7 s');
      await run(tester, 150);
      expect(stage(tester), IkkiuchiStage.breakAfterShimonoku);
      expect(flow(tester).canArrange, isFalse);
      await run(tester, 1000 + 50);
      expect(stage(tester), IkkiuchiStage.kaminoku);
      expect(s.board.called, isNot(read));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('並べ替え still open as the 下の句 ends holds in Moving Card until 完了', (tester) async {
      final p = await open(tester);
      await seedReading(tester, p, IkkiuchiSide.player);
      final f = flow(tester), s = f.scene;
      await touch(tester, s.board.cards.card(s.board.called!).box.centre);
      await runUntil(tester, () => f.stage == IkkiuchiStage.waitingForGo);
      f.go();
      await run(tester, 200);
      await tester.tap(find.text('並べ替え'));
      await tester.pump(frame);
      expect(s.arrange.active, isTrue);
      await run(tester, 1000 + 7000 + 100);
      expect(f.stage, IkkiuchiStage.movingCard);
      expect(find.text(IkkiuchiToolsStyle.movingCard), findsOneWidget);
      await run(tester, 2000);
      expect(f.stage, IkkiuchiStage.movingCard, reason: 'held until done');
      await tester.tap(find.text('完了'));
      await run(tester, 600);
      expect(f.stage, IkkiuchiStage.breakAfterShimonoku);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a take from Tobi's side: Sending Card, then Tobi Placing Card by his arm", (tester) async {
      final p = await open(tester);
      await seedReading(tester, p, IkkiuchiSide.tobi);
      final f = flow(tester), s = f.scene;
      final read = s.board.called!;
      await touch(tester, s.board.cards.card(read).box.centre);
      await runUntil(tester, () => f.stage == IkkiuchiStage.sendingCard);
      expect(s.sides!.tobiCards, isNot(contains(read)));
      expect(find.text(IkkiuchiToolsStyle.sendingCard), findsOneWidget);
      final card = s.sides!.player[0].left.last;
      final from = s.board.cards.card(card).box.centre;
      final over = Vec(from.x, s.layout.band.top + s.layout.cardW / 2);
      final drag = await tester.startGesture(onScreen(tester, from));
      await tester.pump(frame);
      for (var i = 1; i <= 6; i++) {
        await drag.moveTo(onScreen(tester, from.lerp(over, i / 6)));
        await tester.pump(frame);
      }
      await capture(tester, 'game_sending');
      await drag.up();
      await tester.pump(frame);
      expect(f.stage, IkkiuchiStage.tobiPlacingCard);
      await run(tester, IkkiuchiPlayTuning.relayoutGlide.inMilliseconds + 500.0);
      await capture(tester, 'game_tobi_placing');
      await runUntil(tester, () => f.stage == IkkiuchiStage.waitingForGo);
      expect(s.sides!.tobiCards, contains(card));
      expect(s.board.cards.card(card).box.centre.distanceTo(s.board.cards.card(card).home.centre), lessThan(1e-3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('v: Receiving Card, his card waiting just right of him, placed by a tap; then back to the hold',
        (tester) async {
      final p = await open(tester);
      for (final landscape in [true, false]) {
        final o = landscape ? 'landscape' : 'portrait';
        await show(tester, p, IkkiuchiDebugGame(seed: 8, landscape: landscape));
        final f = flow(tester), s = f.scene;
        await tester.tap(tool(IkkiuchiToolsStyle.receiveLabel));
        await tester.pump(frame);
        expect(f.stage, IkkiuchiStage.receivingCard, reason: o);
        await runUntil(tester, () => s.send.stage == IkkiuchiSendStage.waiting);
        await run(tester, 600);
        final wait = s.wait, tobi = s.layout.tobi;
        final tobiRight = tobi.origin.x + tobi.rig.size.x * tobi.k;
        expect(wait.left, greaterThanOrEqualTo(tobiRight - 1e-6), reason: '$o: right of Tobi');
        expect(wait.width, greaterThan(IkkiuchiSendStyle.wait.scale * s.layout.cardW - 1e-6), reason: '$o: big');
        if (landscape) expect(wait.bottom, lessThan(s.layout.band.top), reason: "in Tobi's half");
        await capture(tester, 'game_receiving_$o');
        final (_, rect) = s.send.targets().freeSpots.first;
        await tester.tapAt(onScreen(tester, Vec(rect.x + rect.w / 2, rect.y + rect.h / 2)));
        await runUntil(tester, () => f.stage == IkkiuchiStage.memoryTime);
        expect(f.left, lessThan(IkkiuchiMatchTuning.memoryTime.inMilliseconds), reason: '$o: the memory time goes on');
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("the slider: OFF at the top never strikes; his highest rating at the foot", (tester) async {
      final p = await open(tester);
      await seedReading(tester, p, IkkiuchiSide.tobi);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, slider.min, reason: 'OFF is the low end, set on top by the quarter turn');
      expect(slider.max, IkkiuchiTuning.ratingMax);
      expect(find.text('Tobi rating: OFF'), findsOneWidget);
      final f = flow(tester), s = f.scene;
      await run(tester, 8000);
      expect(s.board.runs, isEmpty, reason: 'off: no strike');
      expect(s.board.faults, isEmpty);
      expect(f.stage, IkkiuchiStage.waitingForHit, reason: 'the card waits for the player');
      // Dragged to its foot: his highest rating, from the next read.
      final box = tester.renderObject<RenderBox>(find.byType(Slider));
      final g = await tester.startGesture(box.localToGlobal(box.size.center(Offset.zero)));
      await g.moveTo(box.localToGlobal(Offset(box.size.width + 40, box.size.height / 2)));
      await g.up();
      await tester.pump(frame);
      expect(find.text('Tobi rating: ${IkkiuchiTuning.ratingMax.round()}'), findsOneWidget);
      expect(f.rating, IkkiuchiTuning.ratingMax);
      expect(s.board.runs, isEmpty, reason: 'not on the read in play');
      await touch(tester, s.board.cards.card(s.board.called!).box.centre);
      await runUntil(tester, () => f.stage == IkkiuchiStage.sendingCard);
      final card = s.sides!.player[0].left.last;
      s.send
        ..dragStart(card, fromStack: false, at: Offset(s.board.cards.card(card).box.centre.x, s.board.cards.card(card).box.centre.y))
        ..dragTo(s.send.tobiSide.center + const Offset(0, 40))
        ..dragEnd();
      await runUntil(tester, () => f.stage == IkkiuchiStage.waitingForGo);
      f.go();
      await runUntil(tester, () => f.stage == IkkiuchiStage.kaminoku);
      await runUntil(tester, () => s.board.runs.isNotEmpty, most: 8000);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a side left empty ends the match: ありがとうございました, and nothing more', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 4));
      await tester.tap(tool('5'));
      await tester.pump(frame);
      await tester.pump(frame);
      final f = flow(tester), s = f.scene;
      expect(s.sides!.tobiCards, hasLength(5));
      for (var i = 0; i < 5; i++) {
        f.sendByHand(IkkiuchiSide.tobi);
        await runUntil(tester, () => s.send.stage == IkkiuchiSendStage.waiting);
        final (spot, _) = s.send.targets().freeSpots.first;
        final r = s.send.rectOf(spot)!;
        s.send.tap(r.center);
        await runUntil(tester, () => !f.stage.sending);
      }
      expect(s.sides!.tobiCards, isEmpty);
      expect(f.stage, IkkiuchiStage.gameEnd);
      await run(tester, 800);
      expect(find.text('ありがとうございました'), findsNWidgets(4));
      await capture(tester, 'game_end');
      await run(tester, 5000);
      expect(f.stage, IkkiuchiStage.gameEnd, reason: 'it stays');
      f.sendByHand(IkkiuchiSide.player);
      f.askKarafuda();
      expect(f.stage, IkkiuchiStage.gameEnd);
      expect(find.byType(IkkiuchiDebugGame), findsOneWidget, reason: 'no exit of its own');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('空 makes the next read a からふだ, which ends after its pause', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 6));
      game(tester).setRating(null);
      await tester.tap(tool(IkkiuchiToolsStyle.karafudaLabel));
      await tester.tap(tool(IkkiuchiToolsStyle.startLabel));
      await runUntil(tester, () => stage(tester) == IkkiuchiStage.kaminoku);
      final s = flow(tester).scene;
      expect(s.board.called, isNull, reason: 'a からふだ');
      expect(s.karafuda, 'からふだ');
      await runUntil(tester, () => stage(tester) == IkkiuchiStage.waitingForGo);
      expect(s.reader.call, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
