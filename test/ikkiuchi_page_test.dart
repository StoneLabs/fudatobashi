// 一騎打ち's page (IkkiuchiPage): the class strip, ranked open from the
// start (its placement matches, then Tobi drawn for the next match on its
// burst), the custom panel and its sheet (class keys and steppers, one held
// down stepping on), guest mode, and matches started from it: held in
// landscape, played to the setup picked, in 1, 2 or 3 rows, closed once over
// and the page's strip counting it. When a match is recorded: played to its
// end, free play too, on a fresh database; ended once play has begun;
// never when ended or left before, nor free play left midway, nor a guest's;
// a ranked match left after its first read is a loss, journalled from that
// read and again after every read.
//
// With RENDER_SCREENS=1 it also renders the page in its states and the
// custom sheet, with real fonts and art, to build/screens/ikkiuchi_page/.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/domain/ikkiuchi_rating.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/free_strings.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_field_preview.dart';
import 'package:fudatobashi/ui/side_trips/burst_button.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_rules_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_sheet.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/side_trips/trip_record_panels.dart';
import 'package:fudatobashi/state/ikkiuchi_journal.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_painter.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_layers.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/side_trips/trip_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_page.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_panels.dart';
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

  @override
  Future<void> stopKimarijiVoice() async {}
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
  const s = S('en');
  final real = sounds;
  setUp(() => sounds = _Quiet());
  tearDown(() => sounds = real);
  setUpAll(() async {
    await CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
    if (!renderScreens) return;
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  Future<Progress> open(WidgetTester tester, {String lang = 'en'}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
    });
    return p;
  }

  /// Plays the next ranked matches as offered, won or lost by [results].
  Future<void> playRanked(WidgetTester tester, Progress p, List<bool> results) => tester.runAsync(() async {
        for (final won in results) {
          await p.recordIkkiuchi(IkkiuchiMatchRecord(
            setup: p.ikkiuchi.rankedSetup,
            startedAt: DateTime(2026, 11, 8),
            endedAt: DateTime(2026, 11, 8, 0, 40),
            completed: true,
            playerLeft: won ? 0 : 4,
            opponentLeft: won ? 3 : 0,
          ));
        }
      });

  Future<void> showPage(WidgetTester tester, Progress p, {Screen phone = usersPhone}) async {
    useScreen(tester, phone);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
          navigatorKey: navigator,
          debugShowCheckedModeBanner: false,
          theme: buildMangaTheme(),
          builder: (context, child) => DefaultTextStyle(style: Theme.of(context).textTheme.bodyMedium!, child: child!),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    ));
    navigator.currentState!.push(MangaRoute<void>(builder: (_) => const IkkiuchiPage()));
    await tester.pump();
    await tester.pump(Motion.route);
  }

  /// The value of the strip's or a panel's cell under [label], its texts
  /// joined (a drop cell's mark among them).
  String cell(WidgetTester tester, String label) {
    final stat = find.ancestor(of: find.text(label), matching: find.byType(StatCell)).first;
    final texts = find.descendant(of: stat, matching: find.byWidgetPredicate((w) => w is RichText));
    return [for (final t in tester.widgetList<RichText>(texts).skip(1)) t.text.toPlainText()].join();
  }

  Finder burst(String title) => find.byWidgetPredicate((w) => w is BurstButton && w.title == title);
  Finder rankedBurst() => burst(s.sideTripRanked);
  Finder stepper(String label) => find.ancestor(of: find.text(label), matching: find.byType(SheetStepper));
  Finder sign(String label, String sign) => find.descendant(of: stepper(label), matching: find.text(sign));
  Finder sheetKey(String top) =>
      find.ancestor(of: find.text(top), matching: find.byType(SheetKey));

  Future<void> tapAndWait(WidgetTester tester, Finder f, Duration wait) async {
    await tester.tap(f);
    await tester.pump();
    await tester.pump(wait);
  }

  /// Opens the custom sheet from the boxed cell of Tobi's rating.
  Future<void> openSheet(WidgetTester tester) => tapAndWait(tester, find.byType(DropCellButton), Motion.sheet);

  IkkiuchiMatchScreenState screen(WidgetTester tester) =>
      tester.state<IkkiuchiMatchScreenState>(find.byType(IkkiuchiMatchScreen));

  /// Starts a match of [setup] over the page, as its START would.
  Future<IkkiuchiMatchScreenState> start(WidgetTester tester, IkkiuchiSetup setup) async {
    unawaited(startIkkiuchiMatch(tester.element(find.byType(IkkiuchiPage)), setup));
    await tester.pump();
    await tester.pump(Motion.route);
    return screen(tester);
  }

  /// Ends the memory time and runs the match on to its first read.
  Future<void> toFirstRead(WidgetTester tester, IkkiuchiMatchFlow flow) async {
    flow.endMemoryTime();
    for (var i = 0; i < 200 && !flow.playBegun; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(flow.playBegun, isTrue);
  }

  /// Waits until [saving], the match's storing, is done.
  Future<void> saved(WidgetTester tester, Future<void>? saving) async {
    expect(saving, isNotNull, reason: 'the match is recorded');
    var done = false;
    unawaited(saving!.then((_) => done = true));
    for (var i = 0; i < 100 && !done; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(done, isTrue);
  }

  Future<void> leave(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(IkkiuchiMatchScreen))).pop();
    await tester.pump();
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
  }

  /// Runs an ended match on until [flow] shows its result.
  Future<void> toResult(WidgetTester tester, IkkiuchiMatchFlow flow) async {
    for (var i = 0; i < 100 && flow.stage != IkkiuchiStage.result; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(flow.stage, IkkiuchiStage.result);
  }

  /// Runs an ended match on, through the players' thanks and its result,
  /// until the screen has closed.
  Future<void> toClosed(WidgetTester tester) async {
    for (var i = 0; i < 200 && find.byType(IkkiuchiMatchScreen).evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
  }

  Future<List<IkkiuchiMatchRow>> rows(WidgetTester tester, Progress p) async =>
      (await tester.runAsync(() => p.db.select(p.db.ikkiuchiMatches).get()))!;

  /// The ranked match's journal as stored, once the writes under way have
  /// landed.
  Future<String?> journal(WidgetTester tester, Progress p) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    final row = await tester.runAsync(
        () => (p.db.select(p.db.keyValues)..where((k) => k.key.equals('ikkiuchiJournal'))).getSingleOrNull());
    return row?.value;
  }

  const ranked = IkkiuchiSetup(
      ranked: true, opponent: IkkiuchiOpponent.tobi, opponentRating: 1300, perSide: 3, memorise: Duration(minutes: 15));

  testWidgets('a new player: the strip unrated with dashes, ranked open on its placement, custom on the first setup',
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    expect(tester.takeException(), isNull);
    expect([cell(tester, s.sideTripClass), cell(tester, s.rating), cell(tester, s.ikkiuchiWins), cell(tester, s.ikkiuchiMargin)],
        ['???', s.sideTripUnranked, '—', '—']);
    expect(find.byType(LockedPanel), findsNothing, reason: 'ranked is open from the start');
    expect(find.text(s.ikkiuchiPlacementTitle), findsOneWidget);
    expect(find.byType(PlacementSlot), findsNWidgets(IkkiuchiRating.placementMatches));
    expect(find.text(s.ikkiuchiPlacementNext), findsOneWidget);
    expect(find.descendant(of: rankedBurst(), matching: find.text('${IkkiuchiRating.start.round()}')), findsOneWidget,
        reason: 'Tobi at the start rating for the first placement match');
    expect([cell(tester, s.ikkiuchiTobiRating), cell(tester, s.ikkiuchiPerSide), cell(tester, s.ikkiuchiMemoryTime)],
        ['${IkkiuchiFreeTuning.rating.round()}▼', s.ikkiuchiPerSideCount.replaceAll('{0}', '25'), '15:00']);
    expect(find.byType(IkkiuchiFieldPreview), findsOneWidget);
    expect(burst(s.ikkiuchiPlayCards(25)), findsOneWidget);
    expect(find.byType(SideTripGuestButton), findsOneWidget);
    expect(find.byType(SideTripRulesButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('placement shows the matches played; once placed, the class, rating, wins and margin, and no row',
      (tester) async {
    final p = await open(tester);
    await playRanked(tester, p, [true, false]);
    await showPage(tester, p);
    expect(find.byType(PlacementSlot), findsNWidgets(IkkiuchiRating.placementMatches - 2));
    expect(find.text(s.ikkiuchiWon), findsOneWidget);
    expect(find.text(s.ikkiuchiLost), findsOneWidget);
    expect(find.text('▲500'), findsOneWidget);
    expect(find.text('▼300'), findsOneWidget);
    expect(find.descendant(of: rankedBurst(), matching: find.text('${p.ikkiuchi.rankedSetup.opponentRating.round()}')),
        findsOneWidget);
    expect(cell(tester, s.ikkiuchiWins), '1/2');
    expect(cell(tester, s.ikkiuchiMargin), '−0.5');
    await tester.pumpWidget(const SizedBox());

    await playRanked(tester, p, [true, true, false, true, true, true]);
    await showPage(tester, p);
    final rating = p.ikkiuchi.rating!;
    expect(cell(tester, s.rating), startsWith('${rating.round()}'));
    expect(cell(tester, s.sideTripClass), isNot('???'));
    expect(cell(tester, s.ikkiuchiWins), '4/5');
    expect(find.byType(PlacementSlot), findsNothing);
    expect(find.text(s.ikkiuchiPlacementTitle), findsNothing);
    final tobi = p.ikkiuchi.rankedSetup.opponentRating;
    expect((tobi - rating).abs(), lessThanOrEqualTo(IkkiuchiRankedTuning.drawCutOff));
    expect(find.descendant(of: rankedBurst(), matching: find.text('${tobi.round()}')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the ranked burst plays the next ranked match against the Tobi it shows', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tapAndWait(tester, rankedBurst(), Motion.route);
    final flow = screen(tester).flow!;
    expect([flow.rating, flow.memorise, flow.tally.player],
        [IkkiuchiRating.start, IkkiuchiRankedTuning.memorise, IkkiuchiRankedTuning.perSide]);
    expect(screen(tester).widget.setup.ranked, isTrue);
    flow.end();
    await tester.pump();
    await toClosed(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the custom sheet: class keys and steppers set the setup, which the panel then plays', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await openSheet(tester);
    expect(find.byType(IkkiuchiCustomSheet), findsOneWidget);
    final b = Rating.bands.firstWhere((band) => band.id == 'B');
    final bRating = b.minRating.round();
    await tapAndWait(tester, sheetKey(s.className(b)), Duration.zero);
    expect(find.descendant(of: stepper(s.ikkiuchiAnyRating), matching: find.text('$bRating')), findsOneWidget);
    await tapAndWait(tester, sign(s.ikkiuchiAnyRating, '+'), Duration.zero);
    await tapAndWait(tester, sheetKey('12'), Duration.zero);
    await tapAndWait(tester, sign(s.ikkiuchiAnyCount, '−'), Duration.zero);
    await tapAndWait(tester, sign(s.ikkiuchiMemoryTime, '−'), Duration.zero);
    expect(find.text(s.ikkiuchiSetupLine(11, '14:00', bRating + 50)), findsOneWidget);
    await tapAndWait(tester, burst(s.ikkiuchiConfirm), Motion.sheet * 2);
    expect(find.byType(IkkiuchiCustomSheet), findsNothing);
    expect([cell(tester, s.ikkiuchiTobiRating), cell(tester, s.ikkiuchiPerSide), cell(tester, s.ikkiuchiMemoryTime)],
        ['${bRating + 50}▼', s.ikkiuchiPerSideCount.replaceAll('{0}', '11'), '14:00']);

    await tapAndWait(tester, burst(s.ikkiuchiPlayCards(11)), Motion.route);
    final flow = screen(tester).flow!;
    expect([flow.rating, flow.memorise, flow.tally.player, screen(tester).widget.setup.ranked],
        [bRating + 50.0, const Duration(minutes: 14), 11, false]);
    flow.end();
    await tester.pump();
    await toClosed(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a stepper held down steps on until it is let go, and stops at its end', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await openSheet(tester);
    final plus = sign(s.ikkiuchiAnyRating, '+');
    final gesture = await tester.startGesture(tester.getCenter(plus));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    await tester.pump(IkkiuchiSheetLayout.repeatEvery * 4);
    await gesture.up();
    await tester.pump(IkkiuchiSheetLayout.repeatEvery * 4);
    const stepped = IkkiuchiFreeTuning.rating + 5 * IkkiuchiFreeTuning.ratingStep;
    expect(find.descendant(of: stepper(s.ikkiuchiAnyRating), matching: find.text('${stepped.round()}')), findsOneWidget);

    final less = sign(s.ikkiuchiMemoryTime, '−');
    final hold = await tester.startGesture(tester.getCenter(less));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    for (var i = 0; i < 20; i++) {
      await tester.pump(IkkiuchiSheetLayout.repeatEvery);
    }
    await hold.up();
    await tester.pump();
    expect(find.descendant(of: stepper(s.ikkiuchiMemoryTime), matching: find.text('1:00')),
        findsOneWidget, reason: 'held at its end');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('guest mode plays the setup picked and records nothing', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tapAndWait(tester, find.byType(SideTripGuestButton), Motion.sheet);
    expect(find.text(s.ikkiuchiGuestLine), findsOneWidget);
    await tapAndWait(tester, sheetKey('8'), Duration.zero);
    await tapAndWait(tester, burst(s.freeStart), Motion.sheet * 2);
    await tester.pump(Motion.route);
    final state = screen(tester);
    expect([state.widget.guest, state.flow!.tally.player], [true, 8]);
    await toFirstRead(tester, state.flow!);
    state.flow!.end();
    await tester.pump();
    expect(state.saving, isNull);
    await toClosed(tester);
    expect(p.ikkiuchi.matches, isEmpty);
    expect(await rows(tester, p), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('How to play opens the rules', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tapAndWait(tester, find.byType(SideTripRulesButton), Motion.sheet);
    expect(find.byType(IkkiuchiRulesSheet), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('START plays the setup in landscape; 終了 before the first read records nothing, and it closes',
      (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    List<Object?> orientations() =>
        [for (final c in calls) if (c.method == 'SystemChrome.setPreferredOrientations') c.arguments];

    final p = await open(tester);
    await showPage(tester, p);
    await openSheet(tester);
    await tapAndWait(tester, sheetKey('20'), Duration.zero);
    for (var i = 0; i < 5; i++) {
      await tapAndWait(tester, sign(s.ikkiuchiMemoryTime, '−'), Duration.zero);
    }
    await tapAndWait(tester, burst(s.ikkiuchiConfirm), Motion.sheet * 2);
    await tapAndWait(tester, burst(s.ikkiuchiPlayCards(20)), Motion.route);

    final flow = screen(tester).flow!;
    expect(flow.stage, IkkiuchiStage.placing);
    expect(flow.memorise, const Duration(minutes: 10));
    expect(flow.rating, IkkiuchiFreeTuning.rating);
    expect(flow.scene.opening.stack, hasLength(20), reason: "the player's cards wait in the stack");
    expect(flow.scene.sides!.playerCards, isEmpty);
    expect(flow.scene.sides!.tobiCards, hasLength(20));
    expect(orientations().last, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
    expect(tester.takeException(), isNull);

    flow.end();
    await tester.pump();
    expect(flow.stage, IkkiuchiStage.gameEnd);
    expect(screen(tester).saving, isNull, reason: 'nothing played yet');
    for (var i = 0; i < 100 && flow.stage == IkkiuchiStage.gameEnd; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(flow.stage, IkkiuchiStage.done, reason: 'nothing played: no result after the thanks');
    await toClosed(tester);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
    expect(orientations().last, ['DeviceOrientation.portraitUp'], reason: 'portrait again once it closes');
    expect(p.ikkiuchi.matches, isEmpty);
    expect(await rows(tester, p), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a change of size deals the match afresh until a card is placed; then the board keeps its size',
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    final state = await start(tester, IkkiuchiSetup.firstFree);
    final first = state.flow!;
    final dpr = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(390, 832) * dpr;
    await tester.pump();
    final dealt = state.flow!;
    expect(dealt, isNot(same(first)), reason: 'nothing placed yet: dealt afresh for the new size');
    final opening = dealt.scene.opening;
    final (_, r) = opening.targets().freeSpots.first;
    opening.tap(Offset(r.x + r.w / 2, r.y + r.h / 2));
    tester.view.physicalSize = const Size(384, 832) * dpr;
    await tester.pump();
    expect(state.flow, same(dealt), reason: 'a card placed: kept, scaled to fit');
    expect(dealt.scene.sides!.playerCards, hasLength(1));
    expect(tester.takeException(), isNull);
    await leave(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi's sent card says to drag it or tap a spot, and a tap on a spot or a card places it there",
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p, phone: usersPhoneLandscape);
    final flow = (await start(tester, IkkiuchiSetup.firstFree)).flow!;
    final scene = flow.scene, send = scene.send;
    scene.opening
      ..placeRest()
      ..finishTobi();
    flow.donePlacing();
    final board = tester.renderObject<RenderBox>(find.byType(IkkiuchiBoardView));

    // A finger's tap at [at] on the board, moving a little before it lifts.
    Future<void> tapOn(Offset at) async {
      final g = await tester.startGesture(board.localToGlobal(at));
      await tester.pump(const Duration(milliseconds: 40));
      await g.moveBy(const Offset(3, 2));
      await tester.pump(const Duration(milliseconds: 40));
      await g.up();
      await tester.pump();
    }

    // Tobi sends a card, and it waits; [place] taps where it goes.
    Future<int> receive(Future<void> Function() place) async {
      for (var i = 0; i < 200 && !scene.atRest; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      flow.sendByHand(IkkiuchiSide.opponent);
      for (var i = 0; i < 200 && send.stage != IkkiuchiSendStage.waiting; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(send.stage, IkkiuchiSendStage.waiting);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.text(s.ikkiuchiSentHint), findsOneWidget, reason: 'under its tag');
      final card = send.card!;
      await place();
      expect(send.stage, IkkiuchiSendStage.none, reason: 'placed by the tap');
      expect(scene.sides!.playerCards, contains(card));
      expect(find.text(s.ikkiuchiSentHint), findsNothing);
      return card;
    }

    late final PlacingSpot spot;
    final onSpot = await receive(() async {
      final (at, r) = send.targets().freeSpots.firstWhere((s) => s.$1 is ClusterEnd);
      spot = at;
      await tapOn(Offset(r.x + r.w / 2, r.y + r.h / 2));
    });
    final place = scene.sides!.playerBoard.side.placeOf(onSpot)!;
    expect(ClusterEnd(place.row, place.part), spot, reason: 'at the spot tapped');

    late final int under;
    final onCard = await receive(() async {
      under = scene.sides!.player[1].left.first;
      final box = scene.board.cards.card(under).box;
      await tapOn(Offset(box.centre.x, box.centre.y));
    });
    final side = scene.sides!.playerBoard.side;
    expect(side.placeOf(onCard)!.index, side.placeOf(under)!.index - 1, reason: "in the tapped card's place");
    expect(tester.takeException(), isNull);
    await leave(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('終了 once play has begun records the match given up, with its reads; the strip counts it',
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tapAndWait(tester, burst(s.ikkiuchiPlayCards(25)), Motion.route);
    final state = screen(tester);
    final flow = state.flow!;
    await toFirstRead(tester, flow);
    flow.end();
    await tester.pump();
    await saved(tester, state.saving);

    final match = p.ikkiuchi.matches.single;
    final setup = match.setup;
    expect([match.ranked, match.completed, match.result, match.reads], [false, false, IkkiuchiResult.gaveUp, flow.reads]);
    expect([setup.perSide, setup.memorise, setup.opponentRating], [25, const Duration(minutes: 15), IkkiuchiFreeTuning.rating]);
    expect([match.playerLeft, match.opponentLeft], [flow.tally.player, flow.tally.opponent]);
    expect(await rows(tester, p), hasLength(1));

    expect(find.text(s.ikkiuchiThanks), findsNWidgets(4), reason: 'the thanks first, on each half');
    await toResult(tester, flow);
    expect(find.text(s.ikkiuchiThanks), findsNothing);
    expect(find.text(s.ikkiuchiTobiWins), findsNWidgets(2), reason: 'fill and outline');
    expect(find.text(s.ikkiuchiResult(IkkiuchiResult.gaveUp)), findsOneWidget, reason: 'given up, no margin');
    await tester.tapAt(tester.getCenter(find.byType(IkkiuchiMatchScreen)));
    await tester.pump();
    expect(flow.stage, IkkiuchiStage.done, reason: 'a tap lets it go');
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchScreen), findsNothing, reason: 'and the screen closes');
    expect(p.ikkiuchi.matches, hasLength(1), reason: 'recorded once');
    expect(p.ikkiuchi.counts(), (played: 1, won: 0, lost: 1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi plays a match in his form, drawn from the match's seed", (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    const setup = IkkiuchiSetup.free(opponentRating: 1300, perSide: 3, memorise: Duration(minutes: 15));
    for (final seed in [5, 6]) {
      unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
          .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: seed))));
      await tester.pump();
      await tester.pump(Motion.route);
      final flow = screen(tester).flow!;
      final form = IkkiuchiTobi.formFor(seed);
      final inForm = IkkiuchiTobi.inForm(setup.opponentRating, form);
      expect(form, isNot(0));
      expect(flow.scene.tobiForm, form, reason: 'seed $seed');
      expect(flow.scene.tobiRating, inForm, reason: 'his side laid out in his form');
      await toFirstRead(tester, flow);
      expect(flow.scene.tobiRating, inForm, reason: 'his reads too');
      expect(flow.rating, setup.opponentRating, reason: "the setup's rating is before his form");
      await leave(tester);
    }
    expect(IkkiuchiTobi.formFor(5), isNot(IkkiuchiTobi.formFor(6)));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a match of 1 or 2 rows is dealt and played on its rows, its cards keeping their size', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    for (final (rows, perSide) in [(1, IkkiuchiLayoutTuning.oneRowUpTo), (2, IkkiuchiLayoutTuning.twoRowsUpTo)]) {
      final setup = IkkiuchiSetup.free(opponentRating: 3600, perSide: perSide, memorise: const Duration(minutes: 1));
      unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
          .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 2, rows: rows))));
      await tester.pump();
      await tester.pump(Motion.route);
      final flow = screen(tester).flow!;
      final scene = flow.scene;
      expect([scene.sides!.tobi.length, scene.sides!.player.length], [rows, rows]);
      final cardW = scene.layout.cardW;
      await toFirstRead(tester, flow);
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(flow.reads, isNotEmpty, reason: '$rows rows: the reads go on');
      expect(scene.layout.cardW, cardW, reason: '$rows rows');
      expect(tester.takeException(), isNull);
      await leave(tester);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a free match played to its end is recorded on a fresh database, then the screen closes',
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    const setup = IkkiuchiSetup.free(opponentRating: 3600, perSide: 1, memorise: Duration(minutes: 1));
    unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
        .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 4))));
    await tester.pump();
    await tester.pump(Motion.route);
    final state = screen(tester);
    final flow = state.flow!, send = flow.scene.send;
    await toFirstRead(tester, flow);
    // Tobi takes every card; one he sends the player is placed on its first spot.
    for (var i = 0; i < 1200 && find.byType(IkkiuchiMatchScreen).evaluate().isNotEmpty; i++) {
      if (send.stage == IkkiuchiSendStage.waiting) send.tap(send.rectOf(send.targets().freeSpots.first.$1)!.center);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(IkkiuchiMatchScreen), findsNothing, reason: 'thanks, result, then closed');
    await saved(tester, state.saving);
    final match = p.ikkiuchi.matches.single;
    expect([match.ranked, match.completed, match.result], [false, true, IkkiuchiResult.lost]);
    final stored = (await rows(tester, p)).single;
    expect([stored.ranked, stored.completed, stored.playerLeft, stored.opponentLeft], [false, true, 1, 0]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('free play left midway records nothing', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    final state = await start(tester, IkkiuchiSetup.firstFree);
    await toFirstRead(tester, state.flow!);
    await leave(tester);
    expect(state.saving, isNull);
    expect(p.ikkiuchi.matches, isEmpty);
    expect(await rows(tester, p), isEmpty);
    expect(await journal(tester, p), isNull, reason: 'free play is never journalled');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a ranked match left in its memory time records nothing', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    final state = await start(tester, ranked);
    await tester.pump(const Duration(seconds: 2));
    await leave(tester);
    expect(state.saving, isNull);
    expect(await rows(tester, p), isEmpty);
    expect(await journal(tester, p), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a ranked match is journalled from its first read, and left then it is recorded given up, a loss',
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    final state = await start(tester, ranked);
    expect(await journal(tester, p), isNull);
    await toFirstRead(tester, state.flow!);
    expect(await journal(tester, p), isNotNull, reason: 'saved as the first card is read');
    final flow = state.flow!;
    for (var i = 0; i < 600 && flow.reads.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(flow.reads, hasLength(1));
    final kept = IkkiuchiJournal.decode((await journal(tester, p))!).match;
    expect([kept.reads.single.poemId, kept.playerLeft, kept.opponentLeft],
        [flow.reads.single.poemId, flow.tally.player, flow.tally.opponent],
        reason: 'saved again once the read is over');

    await leave(tester);
    await saved(tester, state.saving);
    final match = p.ikkiuchi.matches.single;
    expect([match.ranked, match.completed, match.result, match.setup.opponentRating, match.reads.length],
        [true, false, IkkiuchiResult.gaveUp, 1300, 1]);
    expect(p.ikkiuchi.counts(ranked: true), (played: 1, won: 0, lost: 1));
    expect(await journal(tester, p), isNull, reason: 'recording it clears the journal');
    await tester.pumpWidget(const SizedBox());
  });

  group('leaving', () {
    /// The system's back.
    Future<void> back(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(Motion.route);
    }

    Future<void> answer(WidgetTester tester, String button) async {
      await tester.tap(find.text(button));
      await tester.pump();
      await tester.pump(Motion.route);
    }

    testWidgets('a ranked match after its first read asks first: Keep playing stays, Leave is a loss',
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p);
      final state = await start(tester, ranked);
      await toFirstRead(tester, state.flow!);
      await back(tester);
      expect(find.text(s.ikkiuchiLeaveTitle), findsOneWidget);
      expect(find.text(s.ikkiuchiLeaveNote), findsOneWidget);
      await answer(tester, s.ikkiuchiKeepPlaying);
      expect(find.byType(IkkiuchiMatchScreen), findsOneWidget, reason: 'still playing');
      expect(state.saving, isNull);

      await back(tester);
      await answer(tester, s.ikkiuchiLeave);
      expect(state.flow!.stage, IkkiuchiStage.gameEnd, reason: 'given up, its end shown as 終了 shows it');
      await saved(tester, state.saving);
      expect(p.ikkiuchi.matches.single.result, IkkiuchiResult.gaveUp);
      await toResult(tester, state.flow!);
      expect(find.text(s.ikkiuchiResult(IkkiuchiResult.gaveUp)), findsOneWidget);
      await toClosed(tester);
      expect(p.ikkiuchi.matches, hasLength(1), reason: 'recorded once');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('終了 after the first read of a ranked match asks first too', (tester) async {
      final p = await open(tester);
      await showPage(tester, p);
      final state = await start(tester, ranked);
      final flow = state.flow!;
      await toFirstRead(tester, flow);
      final end = tester.widget<IkkiuchiColumnLayer>(find.byType(IkkiuchiColumnLayer)).onEnd;
      end();
      await tester.pump();
      await answer(tester, s.ikkiuchiKeepPlaying);
      expect(flow.stage, isNot(IkkiuchiStage.gameEnd));
      end();
      await tester.pump();
      await answer(tester, s.ikkiuchiLeave);
      expect(flow.stage, IkkiuchiStage.gameEnd);
      await saved(tester, state.saving);
      expect(p.ikkiuchi.matches.single.result, IkkiuchiResult.gaveUp);
      await toClosed(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('before the first read, and in free play, back leaves without asking', (tester) async {
      final p = await open(tester);
      await showPage(tester, p);
      await start(tester, ranked);
      await back(tester);
      expect(find.text(s.ikkiuchiLeaveTitle), findsNothing);
      expect(find.byType(IkkiuchiMatchScreen), findsNothing);

      final free = await start(tester, IkkiuchiSetup.firstFree);
      await toFirstRead(tester, free.flow!);
      await back(tester);
      expect(find.text(s.ikkiuchiLeaveTitle), findsNothing);
      expect(find.byType(IkkiuchiMatchScreen), findsNothing);
      expect(p.ikkiuchi.matches, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('renders', skip: !renderScreens, () {
    Future<void> capture(WidgetTester tester, String screen, String lang) async {
      await tester.runAsync(() async {
        final context = tester.element(find.byType(IkkiuchiPage, skipOffstage: false));
        await precacheImage(const AssetImage(IkkiuchiBoardStyle.tatami), context);
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump();
      await tester.pump();
      await captureScreen(tester, 'ikkiuchi_page/$screen', lang: lang);
    }

    for (final phone in [widePhone, usersPhone]) {
      for (final lang in ['ja', 'en']) {
        testWidgets('page_${phone.name}_$lang', (tester) async {
          final s = S(lang);
          final stages = <String, (List<bool>, IkkiuchiSetup?)>{
            'fresh': (const [], null),
            'placing': (const [true, false], const IkkiuchiSetup.free(opponentRating: 2559, perSide: 12, memorise: Duration(minutes: 5))),
            'rated': (const [true, true, false, true, true, false, true], const IkkiuchiSetup.free(opponentRating: 1865, perSide: 1, memorise: Duration(minutes: 1))),
          };
          for (final MapEntry(key: stage, value: (results, free)) in stages.entries) {
            final p = await open(tester, lang: lang);
            await playRanked(tester, p, results);
            if (free != null) {
              await tester.runAsync(() => p.recordIkkiuchi(IkkiuchiMatchRecord(
                    setup: free,
                    startedAt: DateTime(2026, 11, 8),
                    endedAt: DateTime(2026, 11, 8, 0, 20),
                    completed: true,
                    playerLeft: 0,
                    opponentLeft: 2,
                  )));
            }
            await showPage(tester, p, phone: phone);
            expect(tester.takeException(), isNull);
            await capture(tester, '${phone.name}_$stage', lang);
            if (stage == 'rated') {
              await openSheet(tester);
              await tapAndWait(tester, sheetKey(s.className(Rating.bands.firstWhere((b) => b.id == 'B'))), Duration.zero);
              await capture(tester, '${phone.name}_custom_sheet', lang);
            }
            await tester.pumpWidget(const SizedBox());
          }
        });
      }
    }
  });
}
