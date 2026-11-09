// 一騎打ち's match run (IkkiuchiMatchFlow) through the developer's debug
// game: its stages in order from the placing, the 送り札 the rules leave, the
// same-time takes, Tobi's rating slider, and the end. With RENDER_SCREENS=1
// it writes its PNGs to build/screens/ikkiuchi/.
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
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_rig.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_debug_game.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_painter.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_board.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_column.dart';
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

/// Notes the kimariji voices started and how often they were stopped.
class _Voices extends _Quiet {
  final started = <int>[];
  int stopped = 0;

  @override
  Future<void> playKimarijiVoice(int poemId) async => started.add(poemId);

  @override
  Future<void> stopKimarijiVoice() async => stopped++;
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
    const tobi = IkkiuchiSide.opponent, player = IkkiuchiSide.player;

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

    test('what a read end says: 同時 or からふだ, the take, then the faults, double on both sides', () {
      const c = IkkiuchiCallout.values;
      expect(const IkkiuchiReadEnd(taker: player, cardSide: tobi).callouts, [IkkiuchiCallout.youTook]);
      expect(const IkkiuchiReadEnd(taker: tobi, cardSide: tobi, tied: true, playerFaults: {player}).callouts,
          [IkkiuchiCallout.tied, IkkiuchiCallout.tobiTook, IkkiuchiCallout.yourFault]);
      expect(const IkkiuchiReadEnd().callouts, [IkkiuchiCallout.karafuda]);
      expect(const IkkiuchiReadEnd(playerFaults: {tobi, player}, tobiFaults: {tobi}).callouts,
          [IkkiuchiCallout.karafuda, IkkiuchiCallout.yourDoubleFault, IkkiuchiCallout.tobiFault]);
      expect(c, hasLength(8));
    });

    test('the tally: the card taken leaves its side, then the 送り札 go, as many as the sender has', () {
      const even = IkkiuchiTally(player: 3, opponent: 3);
      List<int> counts(IkkiuchiTally t) => [t.player, t.opponent];
      expect(counts(even.after(const IkkiuchiReadEnd(taker: player, cardSide: player))), [2, 3]);
      expect(counts(even.after(const IkkiuchiReadEnd(taker: player, cardSide: tobi))), [2, 3],
          reason: 'took from his side, and sent him one');
      expect(counts(even.after(const IkkiuchiReadEnd(taker: tobi, cardSide: player, tied: true))), [3, 2]);
      expect(counts(even.after(const IkkiuchiReadEnd(playerFaults: {tobi, player}))), [5, 1], reason: 'a からふだ');
      expect(
          counts(const IkkiuchiTally(player: 1, opponent: 1)
              .after(const IkkiuchiReadEnd(taker: player, cardSide: player, playerFaults: {tobi}))),
          [1, 0],
          reason: 'their last card taken, then his last sent for the fault');
      expect(
          counts(const IkkiuchiTally(player: 1, opponent: 4)
              .after(const IkkiuchiReadEnd(taker: player, cardSide: tobi, tobiFaults: {player}))),
          [0, 4],
          reason: 'two to send, one to send with');
      expect(counts(even.sent(player, 1)), [2, 4]);
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
    late _Voices voices;
    setUp(() => sounds = voices = _Voices());
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

    Future<void> runUntil(WidgetTester tester, bool Function() done, {double most = 20000, String? reason}) async {
      for (var t = 0.0; t < most && !done(); t += frame.inMilliseconds) {
        await tester.pump(frame);
      }
      expect(done(), isTrue, reason: reason);
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

    // Both sides laid out and 完了, into the memory time: the cards still in
    // the stack put down by the game, and Tobi's side laid down at once.
    Future<void> laidOut(WidgetTester tester) async {
      final f = flow(tester);
      f.scene.opening
        ..placeRest()
        ..finishTobi();
      f.donePlacing();
      expect(f.stage, IkkiuchiStage.memoryTime);
      await run(tester, IkkiuchiPlayTuning.relayoutGlide.inMilliseconds + 100.0);
    }

    testWidgets('placing, 始, Game Start, Yoka, then the reads in order, the 下の句 7 s', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 3));
      expect(stage(tester), IkkiuchiStage.placing);
      expect(find.text(IkkiuchiToolsStyle.placing), findsOneWidget);
      expect(find.text('のこり 15:00'), findsOneWidget, reason: 'the memory time runs from the placing on');
      await run(tester, 2000);
      expect(find.text('のこり 14:58'), findsOneWidget);
      expect(flow(tester).canArrange, isFalse, reason: 'cards are placed from the stack, not arranged');
      await capture(tester, 'game_placing');
      await tester.tap(tool(IkkiuchiToolsStyle.goLabel));
      await tester.pump(frame);
      expect(stage(tester), IkkiuchiStage.placing, reason: '次 only lets a held match go');
      await tester.tap(tool(IkkiuchiToolsStyle.startLabel));
      await tester.pump(frame);
      expect(stage(tester), IkkiuchiStage.gameStart, reason: '始 ends the placing and the memory time');
      final opening = flow(tester).scene.opening;
      expect(opening.stack, isEmpty, reason: 'the cards left in the stack are put down');
      expect(opening.tobiDone, isTrue, reason: "Tobi's side laid down at once");
      expect(flow(tester).scene.sides!.playerCards, hasLength(IkkiuchiToolsTuning.dealPerSide));
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

    testWidgets('the column: 完了 once every card is placed, then 覚えた over 並べ替え once Tobi is done', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 5));
      final f = flow(tester), opening = f.scene.opening;
      Finder button(String label) => find.descendant(of: find.byType(IkkiuchiMatchColumn), matching: find.text(label));
      expect(button('完了'), findsOneWidget);
      expect(button('並べ替え'), findsNothing, reason: 'nothing to arrange while placing');
      await tester.tap(button('完了'), warnIfMissed: false);
      await tester.pump(frame);
      expect(f.stage, IkkiuchiStage.placing, reason: 'faded until every card is placed');
      // The stack's top card by a tap on a spot, the rest by the game.
      final (_, r) = opening.targets().freeSpots.first;
      await tester.tapAt(onScreen(tester, Vec(r.x + r.w / 2, r.y + r.h / 2)));
      await tester.pump(frame);
      expect(opening.stack, hasLength(IkkiuchiToolsTuning.dealPerSide - 1),
          reason: 'a tap on a spot places the top card');
      opening.placeRest();
      await run(tester, 600);
      await capture(tester, 'game_all_placed');
      await tester.tap(button('完了'));
      await tester.pump(frame);
      expect(f.stage, IkkiuchiStage.memoryTime);
      expect(button('覚えた'), findsOneWidget);
      expect(button('並べ替え'), findsOneWidget);
      await tester.tap(button('覚えた'), warnIfMissed: false);
      await tester.pump(frame);
      expect(f.stage, IkkiuchiStage.memoryTime, reason: 'Tobi still lays out his side');
      await run(tester, 600);
      await capture(tester, 'game_memorise_tobi_placing');
      opening.finishTobi();
      await tester.pump(frame);
      await tester.tap(button('覚えた'));
      await tester.pump(frame);
      expect(f.stage, IkkiuchiStage.gameStart);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tobi plays the deal in his form, drawn from its seed as in a match', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 3));
      final s = flow(tester).scene;
      final form = IkkiuchiTobi.formFor(3);
      final inForm = IkkiuchiTobi.inForm(IkkiuchiToolsTuning.ratingStart, form);
      expect(form, isNot(0));
      expect(s.tobiForm, form);
      expect(s.tobiRating, inForm, reason: 'his side laid out in his form');
      await tester.tap(tool(IkkiuchiToolsStyle.startLabel));
      await tester.pump(frame);
      await run(tester, IkkiuchiMatchTuning.greeting.inMilliseconds + 50.0);
      await run(tester, IkkiuchiMatchTuning.yoka.inMilliseconds + 50.0);
      expect(stage(tester), IkkiuchiStage.kaminoku);
      expect(s.tobiRating, inForm, reason: 'his reads too');
      expect(flow(tester).rating, IkkiuchiToolsTuning.ratingStart, reason: "the slider's rating is before his form");
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a take on their own side holds at 次, then 1s wait, 下の句 7 s, 1s break, the next 上の句',
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

    testWidgets('each read is logged as it ends: the card, who took it, and when from its deciding sound',
        (tester) async {
      final p = await open(tester);
      await seedReading(tester, p, IkkiuchiSide.player);
      final f = flow(tester), s = f.scene;
      final read = s.board.called!;
      final dealt = s.sides!.playerCards.length;
      expect(f.reads, isEmpty);
      expect(f.playBegun, isTrue, reason: 'a card is read');
      expect([f.tally.player, f.tally.opponent], [dealt, s.sides!.tobiCards.length]);
      await run(tester, s.reader.call!.decidedAt + 300);
      await touch(tester, s.board.cards.card(read).box.centre);
      await runUntil(tester, () => stage(tester) == IkkiuchiStage.feedback);
      final log = f.reads.single;
      expect([log.poemId, log.taker, log.cardSide, log.tied, log.playerFaults, log.opponentFaults, log.opponentTake],
          [read, IkkiuchiSide.player, IkkiuchiSide.player, false, 0, 0, null]);
      expect(log.playerTake!.inMilliseconds, inInclusiveRange(300, 450), reason: 'touched 300 ms after it, give or take a few frames');
      expect(s.sides!.playerCards, contains(read), reason: 'still on the board while its end shows');
      expect(f.tally.player, dealt - 1, reason: 'counted gone from the read\'s end');
      expect(f.endedByPlayer, isFalse);
      f.end();
      expect(f.endedByPlayer, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('each read keeps the field it was played on, its faults with who and when, and where each 送り札 went',
        (tester) async {
      final p = await open(tester);
      await seedReading(tester, p, IkkiuchiSide.opponent);
      final f = flow(tester), s = f.scene;
      final firstField = s.sides!.field.toJson();
      final read = s.board.called!;
      await run(tester, s.reader.call!.decidedAt + 100);
      await touch(tester, s.board.cards.card(read).box.centre);
      await runUntil(tester, () => f.stage == IkkiuchiStage.sendingCard);
      final mine = s.sides!.player[0].left.last;
      final from = s.board.cards.card(mine).box.centre;
      final over = Vec(from.x, s.layout.band.top + s.layout.cardW / 2);
      final drag = await tester.startGesture(onScreen(tester, from));
      await tester.pump(frame);
      for (var i = 1; i <= 6; i++) {
        await drag.moveTo(onScreen(tester, from.lerp(over, i / 6)));
        await tester.pump(frame);
      }
      await drag.up();
      await runUntil(tester, () => f.stage == IkkiuchiStage.waitingForGo);

      final first = f.reads.single;
      expect(first.field.toJson(), firstField, reason: 'the field as the read began');
      expect(first.field.spotOf(read)?.side, IkkiuchiSide.opponent);
      expect(first.faults, isEmpty);
      final sentTo = s.sides!.field.spotOf(mine)!;
      expect(sentTo.side, IkkiuchiSide.opponent, reason: 'sent to Tobi');
      expect([for (final x in first.sends) (x.card, x.row, x.part, x.index)],
          [(mine, sentTo.row, sentTo.part, sentTo.index)]);

      await tester.tap(tool(IkkiuchiToolsStyle.karafudaLabel));
      await tester.pump(frame);
      f.go();
      await runUntil(tester, () => f.stage == IkkiuchiStage.kaminoku);
      final secondField = s.sides!.field;
      expect(secondField.spotOf(read), isNull, reason: 'the card taken is gone');
      expect(secondField.spotOf(mine), sentTo, reason: 'the 送り札 lies where it went');
      await run(tester, s.reader.call!.decidedAt + 200);
      final tools = Rect.fromPoints(
          tester.getTopLeft(find.byType(IkkiuchiDebugTools)), tester.getBottomRight(find.byType(IkkiuchiDebugTools)));
      final touched = s.sides!.playerCards
          .firstWhere((id) => !tools.inflate(8).contains(onScreen(tester, s.board.cards.card(id).box.centre)));
      await touch(tester, s.board.cards.card(touched).box.centre);
      await runUntil(tester, () => s.send.stage == IkkiuchiSendStage.waiting, reason: 'their fault: Tobi sends one');
      final his = s.send.card!;
      await run(tester, 600);
      final (_, rect) = s.send.targets().freeSpots.first;
      await tester.tapAt(onScreen(tester, Vec(rect.x + rect.w / 2, rect.y + rect.h / 2)));
      await runUntil(tester, () => f.stage == IkkiuchiStage.waitingForGo);

      expect(f.reads, hasLength(2));
      final second = f.reads.last;
      expect(second.karafuda, isTrue);
      expect(second.field.toJson(), secondField.toJson());
      expect([for (final x in second.faults) (x.by, x.card)], [(IkkiuchiSide.player, touched)]);
      expect(second.faults.single.at.inMilliseconds, inInclusiveRange(200, 350),
          reason: 'touched 200 ms after the deciding sound, give or take a few frames');
      final placed = s.sides!.field.spotOf(his)!;
      expect(placed.side, IkkiuchiSide.player, reason: 'Tobi sent it to the player');
      expect([for (final x in second.sends) (x.card, x.row, x.part, x.index)],
          [(his, placed.row, placed.part, placed.index)]);
      expect(f.reads.first.sends, hasLength(1), reason: 'a 送り札 goes with the read it followed');
      expect(f.logChanges, 4, reason: 'two reads ended, a 送り札 after each');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a long gap between frames, as after the app was away, runs the match on by one step at most',
        (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 3));
      final f = flow(tester);
      final left = f.left;
      f.advance(const Duration(minutes: 5).inMilliseconds.toDouble());
      expect(left - f.left, IkkiuchiMatchTuning.longestStep.inMilliseconds);
      expect(f.stage, IkkiuchiStage.placing);
      expect(f.playBegun, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a read ends in Feedback: its words slide in on the strip, then the flow goes on', (tester) async {
      final p = await open(tester);
      for (final landscape in [true, false]) {
        final o = landscape ? 'landscape' : 'portrait';
        for (var seed = 0;; seed++) {
          await toFirstRead(tester, p, seed, landscape: landscape);
          final b = flow(tester).scene.board;
          if (b.called != null && b.cards.card(b.called!).side == IkkiuchiSide.player) break;
        }
        final f = flow(tester), s = f.scene;
        await run(tester, s.reader.call!.decidedAt + 50);
        await touch(tester, s.board.cards.card(s.board.called!).box.centre);
        await runUntil(tester, () => f.stage == IkkiuchiStage.feedback);
        expect(f.feedback!.callouts, [IkkiuchiCallout.youTook], reason: o);
        await run(tester, IkkiuchiMatchTuning.feedbackIn.inMilliseconds / 2);
        expect(find.text('あなたの取り'), findsOneWidget, reason: o);
        await capture(tester, 'game_feedback_${o}_sliding');
        await run(tester, IkkiuchiMatchTuning.feedbackIn.inMilliseconds.toDouble());
        await capture(tester, 'game_feedback_$o');
        expect(f.canArrange, isFalse);
        await runUntil(tester, () => f.stage != IkkiuchiStage.feedback);
        expect(f.stage, IkkiuchiStage.closingUp, reason: '$o: the card taken leaves');
        await runUntil(tester, () => f.stage == IkkiuchiStage.waitingForGo);
        expect(find.text('あなたの取り'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the finger touches no card outside 上の句 and Waiting for card hit', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 3));
      await laidOut(tester);
      final f = flow(tester), s = f.scene;
      final id = s.sides!.playerCards.first;
      final card = s.board.cards.card(id);
      final before = card.box.centre;
      final g = await tester.startGesture(onScreen(tester, before + const Vec(-30, 0)));
      for (var i = 1; i <= 8; i++) {
        await g.moveTo(onScreen(tester, before + Vec(-30 + i * 8.0, 0)));
        await tester.pump(frame);
      }
      await g.up();
      await run(tester, 200);
      expect(card.box.centre.distanceTo(before), lessThan(1e-6), reason: 'memory time: nothing moves');
      expect(s.fingerOn, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a からふだ waits 5 s; a touch late in it is still a fault', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 6));
      game(tester).setRating(null);
      await tester.tap(tool(IkkiuchiToolsStyle.karafudaLabel));
      await tester.tap(tool(IkkiuchiToolsStyle.startLabel));
      await runUntil(tester, () => stage(tester) == IkkiuchiStage.kaminoku);
      final f = flow(tester), s = f.scene;
      await run(tester, s.reader.call!.decidedAt + IkkiuchiPlayTuning.karafudaPause.inMilliseconds - 600.0);
      expect(f.stage, IkkiuchiStage.waitingForHit);
      await touch(tester, s.board.cards.card(s.sides!.playerCards.first).box.centre);
      expect(s.board.playerFaults, isNotEmpty);
      await runUntil(tester, () => f.stage == IkkiuchiStage.feedback);
      expect(f.feedback!.callouts, [IkkiuchiCallout.karafuda, IkkiuchiCallout.yourFault]);
      await runUntil(tester, () => f.stage == IkkiuchiStage.receivingCard, reason: 'their fault: Tobi sends one');
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
      await seedReading(tester, p, IkkiuchiSide.opponent);
      final f = flow(tester), s = f.scene;
      final read = s.board.called!;
      await touch(tester, s.board.cards.card(read).box.centre);
      await runUntil(tester, () => f.stage == IkkiuchiStage.closingUp);
      await run(tester, 150);
      await capture(tester, 'game_closing_up');
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
      await run(tester, 500);
      final laid = s.board.cards.card(card);
      expect(laid.held, isFalse, reason: 'still on the board once his arm is back, no gap');
      expect(s.board.field.keys, contains(card));
      expect(laid.box.centre.distanceTo(laid.home.centre), lessThan(1e-3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('v: Receiving Card, his card waiting just right of him, placed by a tap; then back to the hold',
        (tester) async {
      final p = await open(tester);
      for (final landscape in [true, false]) {
        final o = landscape ? 'landscape' : 'portrait';
        await show(tester, p, IkkiuchiDebugGame(seed: 8, landscape: landscape));
        await laidOut(tester);
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
        expect(f.left, lessThan(IkkiuchiMatchTuning.memorise.inMilliseconds), reason: '$o: the memory time goes on');
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the kimariji voice stops when the match ends', (tester) async {
      final p = await open(tester);
      await toFirstRead(tester, p, 3);
      final f = flow(tester);
      expect(voices.started, hasLength(1), reason: 'the read started its voice');
      expect(voices.stopped, 0);
      f.end();
      expect(f.stage, IkkiuchiStage.gameEnd);
      expect(voices.stopped, 1);
      f.end();
      expect(voices.stopped, 1, reason: 'ending an ended match does nothing');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the kimariji voice stops when the match ends by itself', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 4));
      await tester.tap(tool('5'));
      await tester.pump(frame);
      await tester.pump(frame);
      await laidOut(tester);
      final f = flow(tester), s = f.scene;
      final before = voices.stopped;
      for (var i = 0; i < 5; i++) {
        f.sendByHand(IkkiuchiSide.opponent);
        await runUntil(tester, () => s.send.stage == IkkiuchiSendStage.waiting);
        final (spot, _) = s.send.targets().freeSpots.first;
        s.send.tap(s.send.rectOf(spot)!.center);
        await runUntil(tester, () => !f.stage.sending);
      }
      expect(f.stage, IkkiuchiStage.gameEnd);
      expect(voices.stopped, before + 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the kimariji voice stops when a new deal or turn replaces the match, and when the page goes',
        (tester) async {
      final p = await open(tester);
      await toFirstRead(tester, p, 3);
      expect(voices.started, hasLength(1));
      expect(voices.stopped, 0);
      for (final button in ['5', IkkiuchiToolsStyle.turnLabel]) {
        final before = voices.stopped;
        await tester.tap(tool(button));
        await tester.pump(frame);
        await tester.pump(frame);
        expect(voices.stopped, before + 1, reason: '$button: the old match is torn down');
        expect(stage(tester), IkkiuchiStage.placing, reason: '$button: a new match');
      }
      final before = voices.stopped;
      await tester.pumpWidget(const SizedBox());
      expect(voices.stopped, before + 1, reason: 'the page is gone');
    });

    // The board once 終了 came during a 送り札: nothing under way, no arm carrying, and every card of both sides
    // lying at its home on its side, none lost and none doubled; the score as it stood.
    Future<void> expectWhole(WidgetTester tester, IkkiuchiMatchFlow f, {required String why}) async {
      final s = f.scene;
      final score = s.cardsLeft;
      final sent = s.send.stage == IkkiuchiSendStage.waiting ? 1 : 0;
      final total = s.sides!.tobiCards.length + s.sides!.playerCards.length + sent;
      f.end();
      expect(f.stage, IkkiuchiStage.gameEnd, reason: why);
      expect(s.send.active, isFalse, reason: why);
      await run(tester, IkkiuchiPlayTuning.relayoutGlide.inMilliseconds + 300.0);
      expect(f.stage, IkkiuchiStage.gameEnd, reason: why);
      expect(s.atRest, isTrue, reason: why);
      expect(s.board.carry, isNull, reason: why);
      expect(s.board.heldFace, isNull, reason: why);
      expect(s.send.drag, isNull, reason: why);
      expect(s.cardsLeft, score, reason: '$why: the score does not jump');
      final sides = s.sides!;
      final tobi = sides.tobiCards, player = sides.playerCards.toSet();
      expect(tobi.length + player.length, total, reason: '$why: no card lost');
      expect(tobi.intersection(player), isEmpty, reason: why);
      final lying = {
        for (final c in s.board.cards.cards)
          if (c.onBoard && !c.held) c.id,
      };
      expect(lying, {...tobi, ...player}, reason: '$why: every card on the board, none held up');
      for (final c in s.board.cards.cards) {
        expect(c.side, tobi.contains(c.id) ? IkkiuchiSide.opponent : IkkiuchiSide.player, reason: '$why: card ${c.id}');
        expect(c.box.centre.distanceTo(c.home.centre), lessThan(1e-3), reason: '$why: card ${c.id} at its home');
      }
      expect(tester.takeException(), isNull, reason: why);
    }

    testWidgets('終了 in Sending Card ends the match, a lifted card back home', (tester) async {
      final p = await open(tester);
      for (final (lift, over) in [(false, false), (true, false), (true, true)]) {
        final why = 'lifted $lift, over his side $over';
        await show(tester, p, const IkkiuchiDebugGame(seed: 8));
        await laidOut(tester);
        final f = flow(tester), s = f.scene;
        f.sendByHand(IkkiuchiSide.player);
        expect(f.stage, IkkiuchiStage.sendingCard, reason: why);
        final card = s.sides!.playerCards.first;
        final at = s.board.cards.card(card).box.centre;
        if (lift) {
          s.send.dragStart(card, fromStack: false, at: Offset(at.x, at.y));
          s.send.dragTo(over ? s.send.tobiSide.center : Offset(at.x, at.y + 10));
          expect(s.send.overTobi, over, reason: why);
          expect(s.board.cards.card(card).held, isTrue, reason: why);
        }
        final sent = s.sides!.playerCards.toSet();
        await expectWhole(tester, f, why: why);
        expect(s.sides!.playerCards.toSet(), sent, reason: '$why: nothing was sent');
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('終了 in Tobi Placing Card ends the match, the card laid on his side, his arm still', (tester) async {
      final p = await open(tester);
      for (final carryFirst in [false, true]) {
        final why = carryFirst ? 'his arm has the card' : 'the card lies where it was let go';
        await show(tester, p, const IkkiuchiDebugGame(seed: 8));
        await laidOut(tester);
        final f = flow(tester), s = f.scene;
        f.sendByHand(IkkiuchiSide.player);
        final card = s.sides!.playerCards.first;
        final at = s.board.cards.card(card).box.centre;
        s.send
          ..dragStart(card, fromStack: false, at: Offset(at.x, at.y))
          ..dragTo(s.send.tobiSide.center + const Offset(0, 40))
          ..dragEnd();
        await tester.pump(frame);
        expect(f.stage, IkkiuchiStage.tobiPlacingCard, reason: why);
        if (carryFirst) {
          await runUntil(tester, () => s.board.carried != null, reason: why);
          await run(tester, 100);
          expect(s.board.carrying, isTrue, reason: why);
          expect(s.board.carried, isNotNull, reason: why);
        } else {
          expect(s.board.carry, isNull, reason: why);
        }
        await expectWhole(tester, f, why: why);
        expect(s.sides!.tobiCards, contains(card), reason: why);
        expect(s.sides!.playerCards, isNot(contains(card)), reason: why);
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('終了 in Receiving Card ends the match, his card placed on their side', (tester) async {
      final p = await open(tester);
      for (final stage in ['carrying', 'in his hand', 'waiting']) {
        final why = 'his card: $stage';
        await show(tester, p, const IkkiuchiDebugGame(seed: 8));
        await laidOut(tester);
        final f = flow(tester), s = f.scene;
        final tobiBefore = s.sides!.tobiCards.toSet();
        f.sendByHand(IkkiuchiSide.opponent);
        expect(f.stage, IkkiuchiStage.receivingCard, reason: why);
        switch (stage) {
          case 'carrying':
            expect(s.send.stage, IkkiuchiSendStage.carrying, reason: why);
            expect(s.board.carried, isNull, reason: why);
          case 'in his hand':
            await runUntil(tester, () => s.board.carried != null, reason: why);
            await run(tester, 100);
            expect(s.send.stage, IkkiuchiSendStage.carrying, reason: why);
          case _:
            await runUntil(tester, () => s.send.stage == IkkiuchiSendStage.waiting, reason: why);
            await run(tester, 100);
        }
        final card = s.send.card!;
        await expectWhole(tester, f, why: why);
        expect(tobiBefore, contains(card), reason: why);
        expect(s.sides!.playerCards, contains(card), reason: '$why: it counts as theirs, as the score had it');
        expect(s.sides!.tobiCards, isNot(contains(card)), reason: why);
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("the slider: OFF at the top never strikes; his highest rating at the foot", (tester) async {
      final p = await open(tester);
      await seedReading(tester, p, IkkiuchiSide.opponent);
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

    testWidgets('Tobi\'s side left empty: ありがとうございました, then Tobi wins by the cards left, until a tap',
        (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 4));
      await tester.tap(tool('5'));
      await tester.pump(frame);
      await tester.pump(frame);
      await laidOut(tester);
      final f = flow(tester), s = f.scene;
      expect(s.sides!.tobiCards, hasLength(5));
      for (var i = 0; i < 5; i++) {
        f.sendByHand(IkkiuchiSide.opponent);
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
      await runUntil(tester, () => f.stage == IkkiuchiStage.result);
      expect(find.text('ありがとうございました'), findsNothing);
      expect(f.result, IkkiuchiResult.lost);
      expect(find.text('トビの勝ち！'), findsNWidgets(2), reason: 'fill and outline');
      expect(find.text('10枚差で負け'), findsOneWidget, reason: 'by the cards the player has left');
      expect(s.board.idleFace, TobiFace.cheering);
      await run(tester, 800);
      await capture(tester, 'game_result_lost');
      f.sendByHand(IkkiuchiSide.player);
      f.askKarafuda();
      f.end();
      expect(f.stage, IkkiuchiStage.result, reason: 'nothing more happens');
      await tester.tapAt(onScreen(tester, Vec(s.layout.size.x / 2, s.layout.size.y / 2)));
      await tester.pump(frame);
      expect(f.stage, IkkiuchiStage.done, reason: 'a tap lets it go');
      expect(find.text('トビの勝ち！'), findsNothing);
      await run(tester, 2000);
      expect(f.stage, IkkiuchiStage.done, reason: 'it stays');
      expect(find.byType(IkkiuchiDebugGame), findsOneWidget, reason: 'no exit of its own');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the player\'s side left empty: the player beat Tobi, who is shocked; the result goes in time',
        (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiDebugGame(seed: 4));
      await tester.tap(tool('5'));
      await tester.pump(frame);
      await tester.pump(frame);
      await laidOut(tester);
      final f = flow(tester), s = f.scene;
      for (var i = 0; i < 5; i++) {
        f.sendByHand(IkkiuchiSide.player);
        await tester.pump(frame);
        final from = s.board.cards.card(s.sides!.playerCards.first).box.centre;
        final over = Vec(from.x, s.layout.band.top - s.layout.cardW);
        final drag = await tester.startGesture(onScreen(tester, from));
        await tester.pump(frame);
        for (var k = 1; k <= 6; k++) {
          await drag.moveTo(onScreen(tester, from.lerp(over, k / 6)));
          await tester.pump(frame);
        }
        await drag.up();
        await tester.pump(frame);
        await runUntil(tester, () => !f.stage.sending);
      }
      expect(s.sides!.playerCards, isEmpty);
      await runUntil(tester, () => f.stage == IkkiuchiStage.result);
      expect(f.result, IkkiuchiResult.won);
      expect(find.text('トビに勝った！'), findsNWidgets(2));
      expect(find.text('10枚差で勝ち'), findsOneWidget, reason: "by the cards Tobi has left");
      expect(s.board.idleFace, TobiFace.shocked);
      await run(tester, 800);
      await capture(tester, 'game_result_won');
      await runUntil(tester, () => f.stage == IkkiuchiStage.done,
          most: IkkiuchiMatchTuning.result.inMilliseconds + 500.0, reason: 'its time up');
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
