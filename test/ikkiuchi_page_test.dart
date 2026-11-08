// 一騎打ち's page (IkkiuchiPage): its strip, ranked chained up as coming
// soon, free play's steppers, and a match started from it: held in
// landscape, played to the setup picked, closed once over and the page's
// strip counting it. When a match is recorded: ended once play has begun;
// never when ended or left before, nor free play left midway; a ranked
// match left after its first read is a loss, journalled from that read.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
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
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/ikkiuchi_journal.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_sheet.dart';
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
  setUpAll(() => CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes()));

  Future<Progress> open(WidgetTester tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true));
    });
    return p;
  }

  Future<void> showPage(WidgetTester tester, Progress p) async {
    useScreen(tester, usersPhone);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProgressScope(
      progress: p,
      child: MaterialApp(
        navigatorKey: navigator,
        theme: buildMangaTheme(),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    ));
    navigator.currentState!.push(MangaRoute<void>(builder: (_) => const IkkiuchiPage()));
    await tester.pump();
    await tester.pump(Motion.route);
  }

  String cell(WidgetTester tester, String label) {
    final stat = find.ancestor(of: find.text(label), matching: find.byType(StatCell)).first;
    return tester.widget<Text>(find.descendant(of: stat, matching: find.byType(Text)).last).data!;
  }

  Finder stepper(String label) => find.ancestor(of: find.text(label), matching: find.byType(SheetStepper));
  Finder sign(String label, String sign) => find.descendant(of: stepper(label), matching: find.text(sign));

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

  testWidgets('the strip, ranked chained as coming soon, and free play on the first match\'s setup', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    expect(tester.takeException(), isNull);
    expect([cell(tester, s.ikkiuchiPlayed), cell(tester, s.ikkiuchiWon), cell(tester, s.ikkiuchiLost)], ['0', '0', '0']);
    expect(find.byType(LockedPanel), findsOneWidget);
    expect(find.text(s.ikkiuchiRankedSoon), findsOneWidget);
    for (final (label, value) in [
      (s.ikkiuchiCards, '${IkkiuchiFreeTuning.perSide}'),
      (s.ikkiuchiMemoryTime, '15:00'),
      (s.ikkiuchiTobiRating, '${IkkiuchiFreeTuning.rating.round()}'),
    ]) {
      expect(find.descendant(of: stepper(label), matching: find.text(value)), findsOneWidget, reason: label);
    }

    await tester.tap(sign(s.ikkiuchiCards, '−'));
    await tester.tap(sign(s.ikkiuchiTobiRating, '+'));
    await tester.tap(sign(s.ikkiuchiMemoryTime, '−'));
    await tester.pump();
    expect(find.descendant(of: stepper(s.ikkiuchiCards), matching: find.text('24')), findsOneWidget);
    expect(find.descendant(of: stepper(s.ikkiuchiTobiRating), matching: find.text('1650')), findsOneWidget);
    expect(find.descendant(of: stepper(s.ikkiuchiMemoryTime), matching: find.text('14:00')), findsOneWidget);
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
    for (var i = 0; i < 5; i++) {
      await tester.tap(sign(s.ikkiuchiMemoryTime, '−'));
      await tester.tap(sign(s.ikkiuchiCards, '−'));
      await tester.pump();
    }
    await tester.tap(find.text(s.ikkiuchiStart));
    await tester.pump();
    await tester.pump(Motion.route);

    final flow = screen(tester).flow!;
    expect(flow.stage, IkkiuchiStage.memoryTime);
    expect(flow.memorise, const Duration(minutes: 10));
    expect(flow.rating, IkkiuchiFreeTuning.rating);
    expect(flow.scene.sides!.playerCards, hasLength(20));
    expect(flow.scene.sides!.tobiCards, hasLength(20));
    expect(orientations().last, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
    expect(tester.takeException(), isNull);

    flow.end();
    await tester.pump();
    expect(flow.stage, IkkiuchiStage.gameEnd);
    expect(screen(tester).saving, isNull, reason: 'nothing played yet');
    await tester.pump(IkkiuchiScreenTuning.leaveAfter);
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
    expect(orientations().last, ['DeviceOrientation.portraitUp'], reason: 'portrait again once it closes');
    expect(p.ikkiuchi.matches, isEmpty);
    expect(await rows(tester, p), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('終了 once play has begun records the match given up, with its reads; the strip counts it',
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tester.tap(find.text(s.ikkiuchiStart));
    await tester.pump();
    await tester.pump(Motion.route);
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

    await tester.pump(IkkiuchiScreenTuning.leaveAfter);
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
    expect(p.ikkiuchi.matches, hasLength(1), reason: 'recorded once');
    expect([cell(tester, s.ikkiuchiPlayed), cell(tester, s.ikkiuchiLost)], ['1', '1']);
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
}
