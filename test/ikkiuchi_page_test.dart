// 一騎打ち's page (IkkiuchiPage): the mode tabs over the box of the tab
// opened last (Rapid at first; a tap is remembered, playing is not), the
// box's standing (placement's slots and line, then the class, rating and
// the curve of the mode's last ranked matches), its field, cards and
// memory time, and its burst, which plays the mode's next ranked match
// against the Tobi it shows, in the rows Settings › 寄り道 › 一騎打ち picks
// for it; free play's rows, the bots' page (no bots yet) and the custom
// sheet (class keys and steppers, one held down stepping on), which starts
// the match it sets up; guest mode; and matches started from it: held in
// landscape, played to the setup picked, in 1, 2 or 3 rows, closed once
// over. When a match is recorded: played to its end, free play too, on a
// fresh database; ended once play has begun; never when ended or left
// before, nor free play left midway, nor a guest's; a ranked match left
// after its first read is a loss, journalled from that read and again
// after every read.
//
// With RENDER_SCREENS=1 it also renders the page in its states (as mock
// D's frames), the bots' page, the custom sheet and the settings, with real
// fonts and art, to build/screens/ikkiuchi_page/.
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
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
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
import 'package:fudatobashi/ui/side_trips/ikkiuchi_bots_page.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_mode_box.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_rating_curve.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/state/ikkiuchi_journal.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_send.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_painter.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_column.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_layers.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/placing/placing_widgets.dart';
import 'package:fudatobashi/ui/settings/settings_rows.dart';
import 'package:fudatobashi/ui/settings/side_trip_settings_screen.dart';
import 'package:fudatobashi/ui/side_trips/trip_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_custom_page.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_page.dart';
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
  const rapid = IkkiuchiMode.rapid;
  final real = sounds;
  setUp(() => sounds = _Quiet());
  tearDown(() => sounds = real);
  setUpAll(() async {
    await CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
    if (!renderScreens) return;
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('Torifuda', ['YujiSyuku-Regular.ttf']);
    await _loadFont('TorifudaNumber', ['TeXGyreSchola-Regular.otf']);
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

  /// Plays the next ranked matches of [mode] as offered, won or lost by
  /// [results].
  Future<void> playRanked(WidgetTester tester, Progress p, List<bool> results,
          {IkkiuchiMode mode = IkkiuchiMode.rapid}) =>
      tester.runAsync(() async {
        for (final won in results) {
          await p.recordIkkiuchi(IkkiuchiMatchRecord(
            setup: p.ikkiuchi.of(mode).rankedSetup(rows: mode.defaultRows),
            startedAt: DateTime(2026, 11, 8),
            endedAt: DateTime(2026, 11, 8, 0, 40),
            completed: true,
            playerLeft: won ? 0 : 4,
            opponentLeft: won ? 3 : 0,
          ));
        }
      });

  Future<void> showPage(WidgetTester tester, Progress p,
      {Screen phone = usersPhone, Widget page = const IkkiuchiPage(), double fontScale = 1}) async {
    useScreen(tester, phone, fontScale: fontScale);
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
    navigator.currentState!.push(MangaRoute<void>(builder: (_) => page));
    await tester.pump();
    await tester.pump(Motion.route);
  }

  /// The mode box shown.
  IkkiuchiRankedBox box(WidgetTester tester) => tester.widget<IkkiuchiRankedBox>(find.byType(IkkiuchiRankedBox));

  /// [f] inside the mode box.
  Finder inBox(Finder f) => find.descendant(of: find.byType(IkkiuchiRankedBox), matching: f);

  /// A mode's tab.
  Finder tab(IkkiuchiMode mode) => find.text(s.ikkiuchiModeName(mode));

  /// Whether the page fits the screen without scrolling.
  bool fits(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position.maxScrollExtent == 0;

  Finder burst(String title) => find.byWidgetPredicate((w) => w is BurstButton && w.title == title);
  Finder rankedBurst() => burst(s.sideTripRanked);
  Finder stepper(String label) => find.ancestor(of: find.text(label), matching: find.byType(SheetStepper));
  Finder sign(String label, String sign) => find.descendant(of: stepper(label), matching: find.text(sign));
  Finder sheetKey(String top) =>
      find.ancestor(of: find.text(top), matching: find.byType(SheetKey));

  Future<void> tapAndWait(WidgetTester tester, Finder f, Duration wait) async {
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await tester.pump();
    await tester.pump(wait);
  }

  /// Opens the custom sheet from free play's custom row.
  Future<void> openSheet(WidgetTester tester) => tapAndWait(tester, find.text(s.ikkiuchiCustom), Motion.sheet);

  /// Confirms the custom sheet, which starts its match.
  Future<void> confirm(WidgetTester tester) async {
    await tapAndWait(tester, burst(s.ikkiuchiConfirm), Motion.sheet * 2);
    await tester.pump(Motion.route);
  }

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
      ranked: true,
      mode: IkkiuchiMode.rapid,
      opponent: IkkiuchiOpponent.tobi,
      opponentRating: 1300,
      perSide: 3,
      rows: 3,
      memorise: Duration(minutes: 15));

  testWidgets("a new player: Rapid's tab, its placement still to play and the curve's room saying when it comes",
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    expect(tester.takeException(), isNull);
    expect(box(tester).records.mode, rapid, reason: 'Rapid first');
    expect(tester.widget<IkkiuchiModeTabs>(find.byType(IkkiuchiModeTabs)).chosen, rapid);
    for (final mode in IkkiuchiMode.values) {
      expect(tab(mode), findsOneWidget);
    }
    expect(inBox(find.text(s.ikkiuchiPlacementTitle)), findsOneWidget);
    for (var i = 1; i <= IkkiuchiRating.placementMatches; i++) {
      expect(inBox(find.text('$i')), findsOneWidget, reason: 'placement match $i still to play');
    }
    expect(inBox(find.text(s.ikkiuchiPlacingLine(rapid, first: true).replaceAll('{0}', '4'))), findsOneWidget);
    expect(find.byType(IkkiuchiCurveNote), findsOneWidget);
    expect(find.byType(IkkiuchiRatingCurve), findsNothing);
    final preview = tester.widget<IkkiuchiFieldPreview>(find.byType(IkkiuchiFieldPreview));
    expect([preview.perSide, preview.rows], [rapid.perSide, rapid.defaultRows]);
    expect(inBox(find.text(s.ikkiuchiBoxPerSide.replaceAll('{0}', '25'))), findsOneWidget);
    expect(inBox(find.text('15:00')), findsOneWidget);
    expect(find.descendant(of: rankedBurst(), matching: find.text('${IkkiuchiRating.start.round()}')), findsOneWidget,
        reason: 'Tobi at the start rating for the first placement match');
    expect(find.text(s.ikkiuchiFreePlay), findsWidgets);
    expect(find.text(s.ikkiuchiBots), findsOneWidget);
    expect(find.text(s.ikkiuchiCustom), findsOneWidget);
    expect(find.byType(SideTripGuestButton), findsOneWidget);
    expect(find.byType(SideTripRulesButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('placement shows the matches played; once placed, the class, rating, its change and the curve',
      (tester) async {
    final p = await open(tester);
    await playRanked(tester, p, [true, false]);
    await showPage(tester, p);
    expect(inBox(find.text(s.ikkiuchiSlotWon)), findsOneWidget);
    expect(inBox(find.text(s.ikkiuchiSlotLost)), findsOneWidget);
    expect([for (final n in ['1', '2', '3', '4']) inBox(find.text(n)).evaluate().length], [0, 0, 1, 1]);
    expect(inBox(find.text(s.ikkiuchiPlacingLine(rapid, first: false).replaceAll('{0}', '2'))), findsOneWidget);
    expect(
        find.descendant(
            of: rankedBurst(), matching: find.text('${p.ikkiuchi.of(rapid).rankedSetup(rows: 3).opponentRating.round()}')),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await playRanked(tester, p, [true, true, false, true, true, true]);
    await showPage(tester, p);
    final records = p.ikkiuchi.of(rapid);
    final rating = records.rating!;
    expect(inBox(find.text(s.rating)), findsOneWidget);
    expect(inBox(find.text('${rating.round()}')), findsOneWidget);
    expect(inBox(find.byType(RatingChangeTag)), findsOneWidget);
    expect(tester.widget<RatingChangeTag>(inBox(find.byType(RatingChangeTag))).change, records.ratingChange!.round());
    expect(inBox(find.text(s.ikkiuchiPlacementTitle)), findsNothing);
    expect(find.byType(IkkiuchiCurveNote), findsNothing);
    expect(tester.widget<IkkiuchiRatingCurve>(find.byType(IkkiuchiRatingCurve)).ratings, records.curve);
    expect(records.curve, hasLength(5), reason: 'from the match that ended placement');
    final tobi = records.rankedSetup(rows: 3).opponentRating;
    expect((tobi - rating).abs(), lessThanOrEqualTo(IkkiuchiRankedTuning.drawCutOff));
    expect(find.descendant(of: rankedBurst(), matching: find.text('${tobi.round()}')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the ranked burst plays the next ranked match against the Tobi it shows', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tapAndWait(tester, rankedBurst(), Motion.route);
    final flow = screen(tester).flow!;
    expect([flow.rating, flow.memorise, flow.tally.player], [IkkiuchiRating.start, rapid.memorise, rapid.perSide]);
    final setup = screen(tester).widget.setup;
    expect([setup.ranked, setup.mode, setup.rows], [true, rapid, 3]);
    flow.end();
    await tester.pump();
    await toClosed(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("a tab tapped shows its mode's box and is remembered; the page opens on it again", (tester) async {
    const blitz = IkkiuchiMode.blitz;
    final p = await open(tester);
    await showPage(tester, p);
    await tester.tap(tab(blitz));
    await tester.pump();
    expect(p.settings.ikkiuchi.tab, blitz);
    expect(box(tester).records.mode, blitz);
    expect(tester.widget<IkkiuchiModeTabs>(find.byType(IkkiuchiModeTabs)).chosen, blitz);
    expect(inBox(find.text(s.ikkiuchiPlacingLine(blitz, first: true).replaceAll('{0}', '4'))), findsOneWidget);
    final preview = tester.widget<IkkiuchiFieldPreview>(find.byType(IkkiuchiFieldPreview));
    expect([preview.perSide, preview.rows], [blitz.perSide, blitz.defaultRows]);
    expect(inBox(find.text(s.ikkiuchiBoxPerSide.replaceAll('{0}', '13'))), findsOneWidget);
    expect(inBox(find.text('8:00')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await showPage(tester, p);
    expect(box(tester).records.mode, blitz, reason: 'the tab opened last');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("ranked plays the mode of the tab opened last, in the rows picked for it, with that mode's standing",
      (tester) async {
    const bullet = IkkiuchiMode.bullet;
    final p = await open(tester);
    await playRanked(tester, p, [true, false], mode: rapid);
    await tester.runAsync(
        () => p.updateSettings(p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.withRows(bullet, 2))));
    await showPage(tester, p);
    expect(inBox(find.text(s.ikkiuchiSlotWon)), findsOneWidget, reason: "Rapid's placement");
    await tester.tap(tab(bullet));
    await tester.pump();
    expect(inBox(find.text(s.ikkiuchiSlotWon)), findsNothing, reason: "Rapid's placement matches are not Bullet's");
    expect(tester.widget<IkkiuchiFieldPreview>(find.byType(IkkiuchiFieldPreview)).rows, 2,
        reason: 'the field in the rows picked');

    await tapAndWait(tester, rankedBurst(), Motion.route);
    final flow = screen(tester).flow!;
    expect([flow.memorise, flow.tally.player], [bullet.memorise, bullet.perSide]);
    final setup = screen(tester).widget.setup;
    expect([setup.ranked, setup.mode, setup.rows], [true, bullet, 2]);
    expect(flow.scene.sides!.player, hasLength(2), reason: 'laid out in the rows picked');
    flow.end();
    await tester.pump();
    await toClosed(tester);
    expect(p.settings.ikkiuchi.tab, bullet, reason: 'playing leaves the tab as it was');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("the bots row opens the bots' page, which lists no bots yet", (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tapAndWait(tester, find.text(s.ikkiuchiBots), Motion.route);
    expect(find.byType(IkkiuchiBotsPage), findsOneWidget);
    expect(find.text(s.ikkiuchiBotsIntro), findsOneWidget);
    expect(tester.takeException(), isNull);
    final back = find.descendant(
        of: find.byType(IkkiuchiBotsPage),
        matching: find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.back));
    await tapAndWait(tester, back, Motion.route);
    expect(find.byType(IkkiuchiBotsPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the custom sheet: class keys and steppers set the setup, which it then plays', (tester) async {
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
    await confirm(tester);
    expect(find.byType(IkkiuchiCustomSheet), findsNothing);
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
    await confirm(tester);

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

  testWidgets("Tobi's sent card waiting by the game column keeps its hint clear of it", (tester) async {
    final p = await open(tester);
    await showPage(tester, p, phone: usersPhoneLandscape);
    final setup = IkkiuchiSetup.free(
        opponentRating: 1600, perSide: IkkiuchiLayoutTuning.oneRowUpTo, rows: 1, memorise: const Duration(minutes: 15));
    unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
        .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 3))));
    await tester.pump();
    await tester.pump(Motion.route);
    final flow = screen(tester).flow!, scene = flow.scene, send = scene.send;
    scene.opening
      ..placeRest()
      ..finishTobi();
    flow.donePlacing();
    // Tobi's cards all in his right group, at the screen's left, so that he
    // stands far right and his card waits against the column.
    final sides = scene.sides!, homes = sides.homes;
    final dealt = [...sides.tobiCards, ...sides.playerCards];
    final right = [
      for (final id in dealt)
        if (homes.homeOf(id).group == IkkiuchiGroup.right) id,
    ].take(IkkiuchiLayout.rowRoom(1) - 1).toList();
    final rest = [for (final id in dealt) if (!right.contains(id)) id].take(4).toList();
    scene.relayout(IkkiuchiSides(homes: homes, tobi: right, player: [IkkiuchiRow(rest.take(2).toList(), rest.skip(2).toList())]));
    for (var i = 0; i < 200 && !scene.atRest; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    flow.sendByHand(IkkiuchiSide.opponent);
    for (var i = 0; i < 200 && send.stage != IkkiuchiSendStage.waiting; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 600));
    final column = scene.column!, wait = scene.wait;
    final board = tester.renderObject<RenderBox>(find.byType(IkkiuchiBoardView));
    final tag = find.ancestor(of: find.text(s.ikkiuchiSentHint), matching: find.byType(PlacingTag));
    final hint = Rect.fromPoints(board.globalToLocal(tester.getTopLeft(tag)), board.globalToLocal(tester.getBottomRight(tag)));
    expect(wait.center.dx + hint.width / 2, greaterThan(column.left), reason: 'centred, it would reach over the column');
    expect(hint.right, closeTo(column.left - IkkiuchiSendStyle.wait.gap, 1e-6), reason: 'clear of the column');
    expect(hint.top, greaterThan(wait.bottom), reason: 'under the card');
    expect(tester.takeException(), isNull);
    await leave(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('終了 once play has begun records the match given up, with its reads, counted once', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await openSheet(tester);
    await confirm(tester);
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
      final setup =
          IkkiuchiSetup.free(opponentRating: 3600, perSide: perSide, rows: rows, memorise: const Duration(minutes: 1));
      unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
          .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 2))));
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

  testWidgets('the game column lies the same in a match of 1, 2 or 3 rows, anchored to the screen\'s edges',
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p, phone: usersPhoneLandscape);
    Rect rectOf(Finder f) => tester.getRect(find.descendant(of: find.byType(IkkiuchiMatchColumn), matching: f));
    final screenSize = usersPhoneLandscape.size;
    const edge = IkkiuchiColumnStyle.edge;
    final column = Rect.fromLTRB(screenSize.width - edge - IkkiuchiColumnStyle.width, edge, screenSize.width - edge,
        screenSize.height - edge);
    for (final (rows, perSide) in [(1, IkkiuchiLayoutTuning.oneRowUpTo), (2, IkkiuchiLayoutTuning.twoRowsUpTo), (3, 25)]) {
      final setup =
          IkkiuchiSetup.free(opponentRating: 1600, perSide: perSide, rows: rows, memorise: const Duration(minutes: 5));
      unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
          .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 2))));
      await tester.pump();
      await tester.pump(Motion.route);
      final flow = screen(tester).flow!;
      flow.scene.opening.placeRest();
      flow.donePlacing();
      await tester.pump(IkkiuchiPlayTuning.relayoutGlide * 2);
      expect(tester.getRect(find.byType(IkkiuchiMatchColumn)), column, reason: '$rows rows');
      final end = rectOf(find.byType(HoldToConfirmButton));
      final buttons = [
        for (final label in [s.ikkiuchiReady, s.ikkiuchiArrange])
          tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(InkButton))),
      ];
      final tobi = rectOf(find.text(s.ikkiuchiTobi)), you = rectOf(find.text(s.ikkiuchiYou));
      expect(end.top, column.top, reason: '$rows rows: 終了 at the top');
      expect(buttons.last.bottom, column.bottom, reason: '$rows rows: the buttons at the foot');
      expect([end.bottom < tobi.top, you.bottom < buttons.first.top], [true, true],
          reason: '$rows rows: the score clear of 終了 and the buttons');
      expect((tobi.bottom + you.top) / 2, closeTo(column.center.dy, IkkiuchiColumnStyle.count),
          reason: '$rows rows: the score in the middle');
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

  group('settings', () {
    for (final lang in ['en', 'ja']) {
      testWidgets('Settings › Side trips › Ikkiuchi: the rows of Bullet and Blitz, not Rapid; a pick is kept ($lang)',
          (tester) async {
        final s = S(lang);
        final p = await open(tester, lang: lang);
        await showPage(tester, p, page: const IkkiuchiSettingsScreen());
        Finder option(IkkiuchiMode mode, int rows) => find.descendant(
            of: find.ancestor(of: find.text(s.ikkiuchiRowsTitle(mode)), matching: find.byType(SettingsChoices)),
            matching: find.widgetWithText(InkButton, s.ikkiuchiRowsKey(rows)));
        expect(find.text(s.ikkiuchiRowsTitle(IkkiuchiMode.rapid)), findsNothing);
        for (final mode in [IkkiuchiMode.bullet, IkkiuchiMode.blitz]) {
          expect(find.text(s.ikkiuchiRowsNote(mode)), findsOneWidget);
          for (final rows in [1, 2, 3]) {
            expect(option(mode, rows), mode.rowChoices.contains(rows) ? findsOneWidget : findsNothing,
                reason: '${mode.name}, $rows rows');
          }
        }
        expect([for (final mode in IkkiuchiMode.values) p.settings.ikkiuchi.rowsOf(mode)], [1, 2, 3]);
        expect(tester.takeException(), isNull);
        await captureScreen(tester, 'ikkiuchi_page/settings', lang: lang);

        await tester.tap(option(IkkiuchiMode.bullet, 3));
        await tester.pump();
        expect([for (final mode in IkkiuchiMode.values) p.settings.ikkiuchi.rowsOf(mode)], [3, 2, 3]);
        expect(p.settings.ikkiuchi.tab, IkkiuchiMode.rapid, reason: 'the tab is left as it was');
        await tester.pumpWidget(const SizedBox());
      });
    }
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

  group('custom page', () {
    IkkiuchiCustomPage page(
            {double rating = 2559, int perSide = 13, int rows = 2, int minutes = 6, bool guest = false}) =>
        IkkiuchiCustomPage(
            guest: guest,
            initial: IkkiuchiSetup.free(
                opponentRating: rating, perSide: perSide, rows: rows, memorise: Duration(minutes: minutes)));

    Finder key(String top) => find.ancestor(of: find.text(top), matching: find.byType(Pressable)).first;
    bool shut(WidgetTester tester, int rows) => tester.widget<Pressable>(key(s.ikkiuchiRowsKey(rows))).onTap == null;
    List<bool> shutRows(WidgetTester tester) => [for (final r in [1, 2, 3]) shut(tester, r)];
    Finder numbered(String template) => find.byWidgetPredicate((w) => w is NumberedText && w.template == template);

    /// The summary's cards a side and rows.
    List<Object> brief(WidgetTester tester) => tester
        .widget<NumberedText>(find.byWidgetPredicate((w) =>
            w is NumberedText && [1, 2, 3].any((r) => w.template == s.ikkiuchiCustomCards(r))))
        .values;
    Finder plus(int at) => find.text('+').at(at);
    Finder minus(int at) => find.text('−').at(at);

    testWidgets('the rows the cards fit, the others shut with why; a change of cards moves them to the fewest',
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p, page: page());
      expect(tester.takeException(), isNull);
      expect(shutRows(tester), [true, false, false]);
      expect(numbered(s.ikkiuchiRowsFromTwo(IkkiuchiLayoutTuning.oneRowUpTo)), findsOneWidget);
      expect(brief(tester), [13, 2]);
      expect(find.text(s.ikkiuchiRowsUpTo(IkkiuchiLayoutTuning.oneRowUpTo)), findsOneWidget);
      expect(find.text(s.ikkiuchiRowsUpTo(IkkiuchiLayoutTuning.twoRowsUpTo)), findsOneWidget);
      expect(find.text(s.ikkiuchiRowsUpTo(IkkiuchiFreeTuning.perSideMax)), findsOneWidget);

      await tapAndWait(tester, key(s.ikkiuchiRowsKey(1)), Duration.zero);
      expect(brief(tester), [13, 2], reason: 'a shut key does nothing');

      await tapAndWait(tester, key('20'), Duration.zero);
      expect(shutRows(tester), [true, true, false]);
      expect(
          numbered(s.ikkiuchiRowsOnlyThree(IkkiuchiLayoutTuning.twoRowsUpTo, IkkiuchiLayoutTuning.oneRowUpTo)),
          findsOneWidget);
      expect(brief(tester), [20, 3], reason: '2 rows no longer fit');

      await tapAndWait(tester, key('8'), Duration.zero);
      expect(shutRows(tester), [false, false, false]);
      expect(find.text(s.ikkiuchiRowsAny(IkkiuchiLayoutTuning.oneRowUpTo)), findsOneWidget);
      expect(brief(tester), [8, 3], reason: 'rows that still fit stay');

      await tapAndWait(tester, key(s.ikkiuchiRowsKey(1)), Duration.zero);
      expect(brief(tester), [8, 1]);
      await tapAndWait(tester, plus(1), Duration.zero);
      expect(brief(tester), [9, 2], reason: 'the fewest rows 9 fit');
      await tapAndWait(tester, minus(1), Duration.zero);
      expect(brief(tester), [8, 2]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("the burst starts a free match of the setup, in its rows; then it is the free setup",
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p, page: page(rating: 1600, perSide: 25, rows: 3, minutes: 15));
      final b = Rating.bands.firstWhere((band) => band.id == 'B');
      final bRating = b.minRating.round();
      await tapAndWait(tester, key(s.className(b)), Duration.zero);
      await tapAndWait(tester, plus(0), Duration.zero);
      await tapAndWait(tester, key('12'), Duration.zero);
      await tapAndWait(tester, minus(1), Duration.zero);
      await tapAndWait(tester, key(s.ikkiuchiRowsKey(2)), Duration.zero);
      await tapAndWait(tester, minus(2), Duration.zero);
      expect(brief(tester), [11, 2]);
      expect(find.byWidgetPredicate((w) => w is NumberedText && w.template == s.ikkiuchiCustomTimes),
          findsOneWidget);
      expect(
          tester.widget<NumberedText>(numbered(s.ikkiuchiCustomTimes)).values, ['14:00', bRating + 50]);

      await tester.ensureVisible(burst(s.ikkiuchiPlayCards(11)));
      await tapAndWait(tester, burst(s.ikkiuchiPlayCards(11)), Motion.route);
      final state = screen(tester);
      final setup = state.widget.setup;
      expect([setup.ranked, setup.mode, setup.opponentRating, setup.perSide, setup.rows, setup.memorise, state.widget.guest],
          [false, null, bRating + 50.0, 11, 2, const Duration(minutes: 14), false]);
      expect(state.flow!.scene.sides!.player, hasLength(2), reason: 'laid out in the rows picked');
      await toFirstRead(tester, state.flow!);
      state.flow!.end();
      await tester.pump();
      await saved(tester, state.saving);
      await toClosed(tester);
      expect(find.byType(IkkiuchiCustomPage), findsOneWidget, reason: 'back on the page');

      final free = p.ikkiuchi.freeSetup;
      expect([free.opponentRating, free.perSide, free.rows, free.memorise],
          [bRating + 50.0, 11, 2, const Duration(minutes: 14)], reason: 'kept with its rows');
      unawaited(openIkkiuchiCustom(tester.element(find.byType(IkkiuchiCustomPage))));
      await tester.pump();
      await tester.pump(Motion.route);
      final opened = tester.widget<IkkiuchiCustomPage>(find.byType(IkkiuchiCustomPage).last).initial;
      expect([opened.perSide, opened.rows], [11, 2], reason: 'the page opens on the last free setup');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a stepper held down steps on until it is let go, and stops at its end', (tester) async {
      final p = await open(tester);
      await showPage(tester, p, page: page(rating: 1600, minutes: 6));
      final gesture = await tester.startGesture(tester.getCenter(plus(0)));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
      await tester.pump(IkkiuchiCustomLayout.repeatEvery * 4);
      await gesture.up();
      await tester.pump(IkkiuchiCustomLayout.repeatEvery * 4);
      expect(find.text('${(1600 + 5 * IkkiuchiFreeTuning.ratingStep).round()}'), findsOneWidget);

      final hold = await tester.startGesture(tester.getCenter(minus(2)));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
      for (var i = 0; i < 10; i++) {
        await tester.pump(IkkiuchiCustomLayout.repeatEvery);
      }
      await hold.up();
      await tester.pump();
      expect(find.text('1:00'), findsOneWidget, reason: 'held at its end');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('in guest mode it says so, and its burst plays a match that records nothing', (tester) async {
      final p = await open(tester);
      await showPage(tester, p, page: page(guest: true));
      expect(find.byWidgetPredicate((w) => w is ScreenTitle && w.title == s.ikkiuchiGuestMode), findsOneWidget);
      expect(find.text(s.ikkiuchiGuestLine, findRichText: true), findsOneWidget);
      await tapAndWait(tester, key('8'), Duration.zero);
      await tapAndWait(tester, key(s.ikkiuchiRowsKey(1)), Duration.zero);
      await tester.ensureVisible(burst(s.ikkiuchiPlayCards(8)));
      await tapAndWait(tester, burst(s.ikkiuchiPlayCards(8)), Motion.route);
      final state = screen(tester);
      expect([state.widget.guest, state.widget.setup.perSide, state.widget.setup.rows], [true, 8, 1]);
      await toFirstRead(tester, state.flow!);
      state.flow!.end();
      await tester.pump();
      expect(state.saving, isNull);
      await toClosed(tester);
      expect(p.ikkiuchi.matches, isEmpty);
      expect(await rows(tester, p), isEmpty);

      unawaited(openIkkiuchiCustom(tester.element(find.byType(IkkiuchiCustomPage)), guest: true));
      await tester.pump();
      await tester.pump(Motion.route);
      final opened = tester.widget<IkkiuchiCustomPage>(find.byType(IkkiuchiCustomPage).last);
      expect([opened.guest, opened.initial.perSide, opened.initial.rows], [true, 8, 1],
          reason: "the guest's last setup");
      await tester.pumpWidget(const SizedBox());
    });

    // The mock's three states, one in English, and guest mode in both, on
    // the user's phone.
    group('renders', skip: !renderScreens, () {
      final states = {
        'two': page(),
        'three': page(perSide: 20, rows: 3, minutes: 10),
        'one': page(rating: 2084, perSide: 8, rows: 1, minutes: 3),
        'guest': page(guest: true),
      };
      for (final (lang, names) in [('ja', states.keys), ('en', ['two', 'guest'])]) {
        for (final name in names) {
          testWidgets('custom_${name}_$lang', (tester) async {
            final p = await open(tester, lang: lang);
            await showPage(tester, p, page: states[name]!);
            await tester.runAsync(() => precacheImage(
                const AssetImage(IkkiuchiBoardStyle.tatami), tester.element(find.byType(IkkiuchiCustomPage))));
            await tester.pump();
            await tester.pump();
            expect(tester.takeException(), isNull);
            final panel = tester.getRect(find.byType(MangaPanel).first);
            expect(panel.bottom, lessThanOrEqualTo(usersPhone.size.height - usersPhone.bars.bottom),
                reason: 'the page fits the screen');
            await captureScreen(tester, 'ikkiuchi_custom/$name', lang: lang);
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
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

    // Runs the match on by [time], frame by frame.
    Future<void> play(WidgetTester tester, Duration time) async {
      const frame = Duration(milliseconds: 50);
      for (var t = Duration.zero; t < time; t += frame) {
        await tester.pump(frame);
      }
    }

    // A match of 1, 2 or 3 rows on the user's phone: as it opens, Tobi
    // laying out his side; every card placed, 完了 blinking; and a read with
    // few cards left, the cards taken off the sides by hand.
    for (final rows in [1, 2, 3]) {
      testWidgets('match_${rows}row', (tester) async {
        final perSide = switch (rows) {
          1 => IkkiuchiLayoutTuning.oneRowUpTo,
          2 => IkkiuchiLayoutTuning.twoRowsUpTo,
          _ => IkkiuchiMode.rapid.perSide,
        };
        final p = await open(tester, lang: 'ja');
        await showPage(tester, p, phone: usersPhoneLandscape);
        final setup = IkkiuchiSetup.free(
            opponentRating: 1600, perSide: perSide, rows: rows, memorise: const Duration(minutes: 15));
        unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
            .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 3))));
        await tester.pump();
        await tester.pump(Motion.route);
        final flow = screen(tester).flow!, scene = flow.scene;
        await play(tester, const Duration(seconds: 6));
        await capture(tester, 'match_${rows}row_1_start', 'ja');

        scene.opening.placeRest();
        await play(tester, IkkiuchiColumnStyle.blinkPeriod * 2);
        await capture(tester, 'match_${rows}row_2_placed', 'ja');

        flow.donePlacing();
        scene.opening.finishTobi();
        var sides = scene.sides!;
        while (sides.tobiCards.length > 3 || sides.playerCards.length > 2) {
          final card = sides.playerCards.length > 2 ? sides.playerCards.first : sides.tobiCards.first;
          scene.relayout(sides.without(card));
          sides = scene.sides!;
        }
        await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);
        await toFirstRead(tester, flow);
        await play(tester, const Duration(milliseconds: 1500));
        await capture(tester, 'match_${rows}row_3_few_left', 'ja');
        expect(tester.takeException(), isNull);
        await leave(tester);
        await tester.pumpWidget(const SizedBox());
      });
    }

    // The bigger cards of a match of 1 or 2 rows in its moments: Tobi's
    // 送り札 waiting, then dragged over a spot on the player's side; his
    // fist at the hit of a strike; and the result.
    for (final rows in [1, 2]) {
      testWidgets('match_${rows}row_moments', (tester) async {
        final perSide = rows == 1 ? IkkiuchiLayoutTuning.oneRowUpTo : IkkiuchiLayoutTuning.twoRowsUpTo;
        final p = await open(tester, lang: 'ja');
        await showPage(tester, p, phone: usersPhoneLandscape);
        final setup = IkkiuchiSetup.free(
            opponentRating: 1600, perSide: perSide, rows: rows, memorise: const Duration(minutes: 15));
        unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
            .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 3))));
        await tester.pump();
        await tester.pump(Motion.route);
        final flow = screen(tester).flow!, scene = flow.scene;
        scene.opening
          ..placeRest()
          ..finishTobi();
        flow.donePlacing();
        // Room on the player's side for the card Tobi sends.
        final sides = scene.sides!;
        scene.relayout(sides.without(sides.playerCards.first).without(sides.playerCards.last));
        await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);

        flow.sendByHand(IkkiuchiSide.opponent);
        final send = scene.send;
        for (var i = 0; i < 200 && send.stage != IkkiuchiSendStage.waiting; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await play(tester, const Duration(milliseconds: 600));
        await capture(tester, 'match_${rows}row_4_waiting', 'ja');

        final card = send.card!;
        final spot = send.rectOf(send.targets().freeSpots.first.$1)!;
        send.dragStart(card, fromStack: true, at: scene.wait.center);
        for (var i = 1; i <= 6; i++) {
          send.dragTo(Offset.lerp(scene.wait.center, spot.center, i / 6)!);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await capture(tester, 'match_${rows}row_5_placing', 'ja');
        send.dragEnd();
        await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);

        await toFirstRead(tester, flow);
        bool atHit() {
          final run = scene.board.active;
          return run != null && run.at(scene.board.now) >= run.strike.hitAt;
        }

        for (var i = 0; i < 2000 && !atHit(); i++) {
          await tester.pump(const Duration(milliseconds: 4));
        }
        expect(atHit(), isTrue);
        await capture(tester, 'match_${rows}row_6_strike', 'ja');

        await play(tester, const Duration(seconds: 2));
        flow.end();
        await toResult(tester, flow);
        await play(tester, const Duration(milliseconds: 1500));
        await capture(tester, 'match_${rows}row_7_result', 'ja');
        expect(tester.takeException(), isNull);
        await leave(tester);
        await tester.pumpWidget(const SizedBox());
      });
    }

    /// A player whose ranked matches in each mode of [ratings] ended at
    /// those ratings, oldest first, each won when it rose: the first three
    /// place them, the fourth gives the first rating, where the curve
    /// starts.
    Future<Progress> rated(WidgetTester tester, String lang, Map<IkkiuchiMode, List<double>> ratings) async {
      final db = AppDatabase(NativeDatabase.memory());
      late Progress p;
      await tester.runAsync(() async {
        p = await Progress.open(db);
        for (final MapEntry(key: mode, value: after) in ratings.entries) {
          for (final (i, r) in after.indexed) {
            final won = i == 0 || r > after[i - 1];
            final at = DateTime(2026, 10, 1).add(Duration(hours: 6 * i));
            final report = await p.recordIkkiuchi(IkkiuchiMatchRecord(
              setup: p.ikkiuchi.of(mode).rankedSetup(rows: mode.defaultRows),
              startedAt: at,
              endedAt: at.add(const Duration(minutes: 20)),
              completed: true,
              playerLeft: won ? 0 : 3,
              opponentLeft: won ? 3 : 0,
            ));
            await (db.update(db.ikkiuchiMatches)..where((m) => m.id.equals(report.match.id!)))
                .write(IkkiuchiMatchesCompanion(rating: Value(r)));
          }
        }
        p = await Progress.open(db);
        await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
      });
      return p;
    }

    Future<void> openTab(WidgetTester tester, Progress p, IkkiuchiMode mode) => tester.runAsync(
        () => p.updateSettings(p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.copyWith(tab: mode))));

    // The players of mock D's frames: a regular player placed in Bullet
    // and Blitz, Rapid still placing (won one, lost one); a few days on,
    // Rapid placed with three rated matches; a new player.
    const bulletRatings = <double>[
      2100, 2400, 2300, 2478, 2491, 2483, 2502, 2517, 2509, 2526, 2540, 2533, 2551, 2566, 2558, 2571, 2563, 2580, //
      2592, 2587, 2581, 2596, 2610,
    ];
    const blitzRatings = <double>[
      2100, 2400, 2300, 2391, 2404, 2398, 2415, 2429, 2441, 2436, 2452, 2466, 2459, 2474, 2488, 2481, 2497, 2509, //
      2502, 2494, 2498, 2489, 2480,
    ];
    const rapidPlacing = <double>[2100, 1800];
    const rapidPlaced = <double>[2100, 1800, 1700, 1820, 1852, 1874];
    final frames = <String, (String, Map<IkkiuchiMode, List<double>>, IkkiuchiMode)>{
      'bullet': ('ja', {IkkiuchiMode.bullet: bulletRatings, IkkiuchiMode.blitz: blitzRatings, rapid: rapidPlacing}, IkkiuchiMode.bullet),
      'blitz': ('ja', {IkkiuchiMode.bullet: bulletRatings, IkkiuchiMode.blitz: blitzRatings, rapid: rapidPlacing}, IkkiuchiMode.blitz),
      'rapid_placing': ('ja', {IkkiuchiMode.bullet: bulletRatings, IkkiuchiMode.blitz: blitzRatings, rapid: rapidPlacing}, rapid),
      'rapid_few': ('ja', {IkkiuchiMode.bullet: bulletRatings, IkkiuchiMode.blitz: blitzRatings, rapid: rapidPlaced}, rapid),
      'new': ('ja', {}, IkkiuchiMode.bullet),
      'blitz_en': ('en', {IkkiuchiMode.bullet: bulletRatings, IkkiuchiMode.blitz: blitzRatings, rapid: rapidPlacing}, IkkiuchiMode.blitz),
    };
    for (final phone in [usersPhone, widePhone]) {
      for (final MapEntry(key: frame, value: (lang, ratings, mode)) in frames.entries) {
        testWidgets('page_${phone.name}_$frame', (tester) async {
          final p = await rated(tester, lang, ratings);
          await openTab(tester, p, mode);
          await showPage(tester, p, phone: phone);
          expect(tester.takeException(), isNull);
          expect(fits(tester), isTrue, reason: 'on one screen');
          await capture(tester, '${phone.name}_${frame.replaceAll('_en', '')}', lang);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    // Bigger text: the page scrolls, nothing overflows.
    for (final frame in ['bullet', 'rapid_placing', 'blitz_en']) {
      testWidgets('page_384_${frame}_t13', (tester) async {
        final (lang, ratings, mode) = frames[frame]!;
        final p = await rated(tester, lang, ratings);
        await openTab(tester, p, mode);
        await showPage(tester, p, fontScale: 1.3);
        expect(tester.takeException(), isNull);
        await capture(tester, '384_${frame.replaceAll('_en', '')}', lang);
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final lang in ['ja', 'en']) {
      testWidgets('bots_$lang', (tester) async {
        final p = await open(tester, lang: lang);
        await showPage(tester, p, page: const IkkiuchiBotsPage());
        expect(tester.takeException(), isNull);
        await captureScreen(tester, 'ikkiuchi_page/384_bots', lang: lang);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('custom_sheet_$lang', (tester) async {
        final s = S(lang);
        final p = await open(tester, lang: lang);
        await showPage(tester, p);
        await tapAndWait(tester, find.textContaining(s.ikkiuchiCustom).first, Motion.sheet);
        await tapAndWait(tester, sheetKey(s.className(Rating.bands.firstWhere((b) => b.id == 'B'))), Duration.zero);
        await capture(tester, '384_custom_sheet', lang);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
