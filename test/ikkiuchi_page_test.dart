// 一騎打ち's page (IkkiuchiPage): the mode tabs over the box of the tab
// opened last (Rapid at first; a tap is remembered, playing is not), the
// box's standing (placement's slots and line, then the class, rating and
// the curve of the mode's last ranked matches; while placing, the note,
// then the estimates; a tap on the curve opens the rank page's box at
// rest, closed by its button or a tap outside), its field, cards and
// memory time, and its burst, which plays the mode's next ranked match
// against the Tobi it shows, in the rows Settings › 寄り道 › 一騎打ち picks
// for it; free play's rows, the bots' page (no bots yet) and the custom
// page, and matches started from it: held in
// landscape, played to the setup picked, in 1, 2 or 3 rows, closed once
// over. When a match is recorded: played to its end, free play too, on a
// fresh database; ended once play has begun; never when ended or left
// before, nor free play left midway, nor a guest's; a ranked match left
// after its first read is a loss, journalled from that read and again
// after every read. A read that decides the match with a 送り札 due sends
// it on its own, nobody placing it, to the middle of the other's 上段,
// turned; it is stored as any 送り札, and History's 盤面 shows it there.
//
// With RENDER_SCREENS=1 it also renders the page in its states (as mock
// D's frames), the curve's popup, the bots' page, the custom page, the
// settings, and that last 送り札 in flight, landed and on History's 盤面,
// with real fonts and art, to build/screens/ikkiuchi_page/.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
import 'package:fudatobashi/domain/rank_ladder.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_field_picture.dart';
import 'package:fudatobashi/ui/side_trips/burst_button.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_rules_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_bots_page.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_mode_box.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_rating_curve.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/state/ikkiuchi_journal.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/domain/field_parts.dart';
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_review.dart';
import 'package:fudatobashi/domain/ikkiuchi_send.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_painter.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_column.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_result.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_screen.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_results_screen.dart';
import 'package:fudatobashi/ui/history/ikkiuchi_field_tab.dart';
import 'package:fudatobashi/ui/history/ikkiuchi_match_page.dart';
import 'package:fudatobashi/ui/history/review_field.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_rank_overlay.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_rank_plot.dart';
import 'package:fudatobashi/ui/results/celebration_chrome.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/xp_overlay.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/placing/placing_widgets.dart';
import 'package:fudatobashi/ui/settings/settings_rows.dart';
import 'package:fudatobashi/ui/settings/side_trip_settings_screen.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_curve_popup.dart';
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
  // Tall enough for the curve in the test font, whose glyphs take more room
  // than the app's.
  const curvePhone = Screen('384 tall', Size(384, 960), 2.8125);
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
  Future<void> tapAndWait(WidgetTester tester, Finder f, Duration wait) async {
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await tester.pump();
    await tester.pump(wait);
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
  /// until the screen has closed, letting its storing land.
  Future<void> toClosed(WidgetTester tester) async {
    for (var i = 0; i < 200 && find.byType(IkkiuchiMatchScreen).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
  }

  /// Back to 一騎打ち from a match's results.
  Future<void> backFromResults(WidgetTester tester) async {
    expect(find.byType(IkkiuchiResultsScreen), findsOneWidget);
    await tester.tap(find.text(s.ikkiuchiBackToPage.toUpperCase()));
    await tester.pump();
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiResultsScreen), findsNothing);
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

  /// A tap on [button] of the dialog asking.
  Future<void> answer(WidgetTester tester, String button) async {
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(button)));
    await tester.pump();
    await tester.pump(Motion.route);
  }

  /// The column's end button, read [label].
  Finder endButton(String label) =>
      find.descendant(of: find.byType(HoldToConfirmButton), matching: find.text(label));

  /// The end button held as long as it takes.
  Future<void> hold(WidgetTester tester) async {
    final press = await tester.startGesture(tester.getCenter(find.byType(HoldToConfirmButton)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(IkkiuchiMatchTuning.endHold);
    await tester.pump(const Duration(milliseconds: 100));
    await press.up();
    await tester.pump();
    await tester.pump(Motion.route);
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
    await showPage(tester, p, phone: curvePhone);
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
    final preview = tester.widget<IkkiuchiFieldPicture>(find.byType(IkkiuchiFieldPicture));
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
    await showPage(tester, p, phone: curvePhone);
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

  /// The curve's tap target.
  Finder curveTap() => find.byWidgetPredicate(
      (w) => w is Pressable && w.semanticLabel == s.ikkiuchiCurveOpen && w.key != IkkiuchiRankedBox.standingKey);

  /// The standing's tap target: the badge with the rating or the placement slots.
  Finder standingTap() => find.byKey(IkkiuchiRankedBox.standingKey);

  testWidgets("the curve's room: the note before placement, the estimates while placing, then the curve",
      (tester) async {
    final p = await open(tester);
    await showPage(tester, p, phone: curvePhone);
    expect(find.byType(IkkiuchiCurveNote), findsOneWidget);
    expect(find.byType(IkkiuchiPlacementCurve), findsNothing);
    expect(curveTap(), findsNothing, reason: 'nothing to open before the first placement match');
    expect(standingTap(), findsNothing, reason: 'nor from the standing');
    await tester.pumpWidget(const SizedBox());

    for (var played = 1; played < IkkiuchiRating.placementMatches; played++) {
      await playRanked(tester, p, [played.isOdd]);
      await showPage(tester, p, phone: curvePhone);
      final records = p.ikkiuchi.of(rapid);
      expect(tester.widget<IkkiuchiPlacementCurve>(find.byType(IkkiuchiPlacementCurve)).path,
          [IkkiuchiRating.start, for (final m in records.matches) m.rating!],
          reason: 'from the start through the estimate after each of the $played played');
      expect(find.byType(IkkiuchiCurveNote), findsNothing);
      expect(find.byType(IkkiuchiRatingCurve), findsNothing);
      expect(curveTap(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }

    await playRanked(tester, p, [true, false]);
    await showPage(tester, p, phone: curvePhone);
    expect(find.byType(IkkiuchiPlacementCurve), findsNothing);
    expect(tester.widget<IkkiuchiRatingCurve>(find.byType(IkkiuchiRatingCurve)).ratings, p.ikkiuchi.of(rapid).curve);
    expect(curveTap(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("a tap on the curve opens the mode's box from its rank page at rest; close or a tap outside shuts it",
      (tester) async {
    final p = await open(tester);
    await playRanked(tester, p, [true, false, true, true, true, false], mode: IkkiuchiMode.bullet);
    await playRanked(tester, p, [true, false]);
    Finder inPopup(Finder f) => find.descendant(of: find.byType(IkkiuchiCurvePopup), matching: f);
    Future<void> sheetMoved() async {
      for (var i = 0; i < 3; i++) {
        await tester.pump(Motion.sheet);
      }
    }

    Future<void> tapCurve() async {
      await tester.tap(curveTap());
      await sheetMoved();
    }

    for (final mode in [IkkiuchiMode.bullet, rapid]) {
      await tester.runAsync(
          () => p.updateSettings(p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.copyWith(tab: mode))));
      await showPage(tester, p, phone: curvePhone);
      final change = p.ikkiuchi.of(mode).lastChange!;
      await tapCurve();
      expect(tester.takeException(), isNull);
      final shown = tester.widget<IkkiuchiCurvePopup>(find.byType(IkkiuchiCurvePopup)).change;
      expect([shown.mode, shown.before, shown.after, shown.placing], [mode, change.before, change.after, mode == rapid]);
      expect(inPopup(find.byType(IkkiuchiRankBoxAtRest)), findsOneWidget);
      expect(inPopup(find.text('${change.after.round()}')), findsWidgets, reason: 'the rating at once, not counting');
      expect(tester.widget<IkkiuchiRankPlot>(inPopup(find.byType(IkkiuchiRankPlot))).timeline.placing, mode == rapid,
          reason: 'the placement chart while placing, else the curve');
      expect(inPopup(find.byType(StageClock)), findsNothing, reason: 'nothing moves');
      expect(inPopup(find.byType(CelebrationCta)), findsNothing, reason: "no button of the rank page's");

      await tester.tap(inPopup(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.close)));
      await sheetMoved();
      expect(find.byType(IkkiuchiCurvePopup), findsNothing, reason: 'closed by its button');

      await tapCurve();
      expect(find.byType(IkkiuchiCurvePopup), findsOneWidget);
      await tester.tapAt(Offset(curvePhone.size.width / 2, curvePhone.bars.top + Gaps.gutter));
      await sheetMoved();
      expect(find.byType(IkkiuchiCurvePopup), findsNothing, reason: 'closed by a tap outside it');
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a curve given way on a short phone is opened from the badge and the rating or the slots',
      (tester) async {
    final p = await open(tester);
    await playRanked(tester, p, [true, false, true, true, true, false], mode: IkkiuchiMode.bullet);
    await playRanked(tester, p, [true, false]);
    for (final mode in [IkkiuchiMode.bullet, rapid]) {
      await tester.runAsync(
          () => p.updateSettings(p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.copyWith(tab: mode))));
      await showPage(tester, p, phone: shortNarrowPhone, fontScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.byWidgetPredicate((w) => w is IkkiuchiPlacementCurve || w is IkkiuchiCurveNote), findsNothing);
      expect(curveTap(), findsNothing);
      expect(standingTap(), findsOneWidget);
      final records = p.ikkiuchi.of(mode);
      final targets = [
        find.byType(IkkiuchiClassBadge),
        if (records.placing) find.text(s.ikkiuchiPlacementTitle) else find.text('${records.rating!.round()}'),
      ];
      for (final target in targets) {
        await tester.tap(find.descendant(of: standingTap(), matching: target));
        for (var i = 0; i < 3; i++) {
          await tester.pump(Motion.sheet);
        }
        expect(tester.takeException(), isNull);
        final shown = tester.widget<IkkiuchiCurvePopup>(find.byType(IkkiuchiCurvePopup)).change;
        expect([shown.mode, shown.placing], [mode, mode == rapid]);
        await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.close));
        for (var i = 0; i < 3; i++) {
          await tester.pump(Motion.sheet);
        }
        expect(find.byType(IkkiuchiCurvePopup), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
    }
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
    final preview = tester.widget<IkkiuchiFieldPicture>(find.byType(IkkiuchiFieldPicture));
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
    expect(tester.widget<IkkiuchiFieldPicture>(find.byType(IkkiuchiFieldPicture)).rows, 2,
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

  testWidgets('the custom row and Guest open the custom page, Guest in guest mode', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tapAndWait(tester, find.text(s.ikkiuchiCustom), Motion.route);
    expect(tester.widget<IkkiuchiCustomPage>(find.byType(IkkiuchiCustomPage)).guest, isFalse);
    Navigator.of(tester.element(find.byType(IkkiuchiCustomPage))).pop();
    await tester.pump();
    await tester.pump(Motion.route);
    await tapAndWait(tester, find.byType(SideTripGuestButton), Motion.route);
    expect(tester.widget<IkkiuchiCustomPage>(find.byType(IkkiuchiCustomPage)).guest, isTrue);
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
    final flow = (await start(
            tester,
            const IkkiuchiSetup.free(
                opponentRating: IkkiuchiFreeTuning.rating,
                perSide: 20,
                rows: IkkiuchiFreeTuning.rows,
                memorise: Duration(minutes: 10)))).flow!;
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
    expect(find.byType(IkkiuchiResultsScreen), findsNothing, reason: 'and no results: it just closes');
    expect(find.byType(IkkiuchiPage), findsOneWidget);
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
    // stands far right.
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
    expect(hint.right, lessThanOrEqualTo(column.left - IkkiuchiSendStyle.wait.gap + 1e-6), reason: 'clear of the column');
    expect(hint.top, greaterThan(wait.bottom), reason: 'under the card');
    expect(tester.takeException(), isNull);
    await leave(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('終了 once play has begun records the match given up, with its reads, counted once', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    final state = await start(tester, IkkiuchiSetup.firstFree);
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
    expect(find.byType(IkkiuchiResultsScreen), findsOneWidget, reason: 'its results in its place');
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

  testWidgets(
      'a match played to its end is recorded; its result, then its results upright with its XP over them, '
      'then Review game opens its field and back returns to them', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    Object? last(String method) => calls.lastWhere((c) => c.method == method).arguments;

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
    for (var i = 0; i < 1200 && flow.stage != IkkiuchiStage.result; i++) {
      if (send.stage == IkkiuchiSendStage.waiting) send.tap(send.rectOf(send.targets().freeSpots.first.$1)!.center);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(IkkiuchiMatchResult), findsOneWidget, reason: 'its result first');
    await saved(tester, state.saving);
    final match = p.ikkiuchi.matches.single;
    expect([match.ranked, match.completed, match.result], [false, true, IkkiuchiResult.lost]);
    final stored = (await rows(tester, p)).single;
    expect([stored.ranked, stored.completed, stored.playerLeft, stored.opponentLeft], [false, true, 1, 0]);
    expect(last('SystemChrome.setPreferredOrientations'),
        ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);

    await tester.tapAt(tester.getCenter(find.byType(IkkiuchiMatchScreen)));
    await tester.pump();
    await tester.pump();
    expect(find.byType(IkkiuchiResultsScreen), findsOneWidget, reason: 'a tap closes the result: the results follow');
    expect(find.byType(CelebrationSequence), findsNothing, reason: 'the results show first');
    expect(find.byType(IkkiuchiMatchScreen, skipOffstage: false), findsOneWidget, reason: 'still going');
    expect(last('SystemChrome.setPreferredOrientations'), ['DeviceOrientation.portraitUp'],
        reason: 'upright before the results show');
    expect(last('SystemChrome.setEnabledSystemUIMode'), '${SystemBarsTuning.app}', reason: 'the system bars back');
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchScreen, skipOffstage: false), findsNothing);
    await tester.pump(ResultsLayout.overlayStagger);
    expect(find.byType(XpOverlay), findsOneWidget, reason: 'then the XP it earned over them');
    for (var i = 0; i < 5 && find.byType(CelebrationSequence).evaluate().isNotEmpty; i++) {
      await tester.tapAt(const Offset(200, 300));
      await tester.pump();
      await tester.pump(ResultsLayout.overlayFade);
      await tester.pump();
    }
    expect(find.byType(CelebrationSequence), findsNothing, reason: 'tapped through');

    await tester.tap(find.text(s.ikkiuchiReviewMatch));
    await tester.pump();
    await tester.pump(Motion.route);
    final page = tester.widget<IkkiuchiMatchPage>(find.byType(IkkiuchiMatchPage));
    expect(page.review.match.id, match.id, reason: 'the match just played');
    expect(find.byType(IkkiuchiFieldTab), findsOneWidget, reason: 'open on its field');
    await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.back));
    await tester.pump();
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchPage), findsNothing);
    await backFromResults(tester);
    expect(find.byType(IkkiuchiPage), findsOneWidget, reason: 'back on the page');
    expect(tester.takeException(), isNull);
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
        expect([for (final mode in IkkiuchiMode.values) p.settings.ikkiuchi.rowsOf(mode)], [2, 2, 3]);
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

  group('the turn', () {
    /// Starts a match of [setup] over the page on [phone] with the auto turn
    /// [turn], noting the orientations it asks for.
    Future<(IkkiuchiMatchScreenState, List<Object?>)> playOn(WidgetTester tester, Screen phone,
        {required bool turn,
        double fontScale = 1,
        IkkiuchiSetup setup =
            const IkkiuchiSetup.free(opponentRating: 1600, perSide: 5, rows: 3, memorise: Duration(minutes: 15))}) async {
      final orientations = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') orientations.add(call.arguments);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final p = await open(tester);
      await tester.runAsync(
          () => p.updateSettings(p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.copyWith(autoTurn: turn))));
      await showPage(tester, p, phone: phone, fontScale: fontScale);
      unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
          .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 3))));
      await tester.pump();
      await tester.pump(Motion.route);
      return (screen(tester), orientations);
    }

    /// [f] inside the game column.
    Finder inColumn(Finder f) => find.descendant(of: find.byType(IkkiuchiMatchColumn), matching: f);

    /// Whether [inner] lies inside [outer].
    bool within(Rect inner, Rect outer) =>
        inner.left >= outer.left && inner.top >= outer.top && inner.right <= outer.right && inner.bottom <= outer.bottom;

    testWidgets('Settings › Side trips › Ikkiuchi: Auto turn screen is on until switched off, and is kept',
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p, page: const IkkiuchiSettingsScreen());
      final row = find.text(s.ikkiuchiAutoTurn, findRichText: true);
      expect(row, findsOneWidget);
      expect(find.text(s.ikkiuchiAutoTurnNote), findsOneWidget);
      expect(p.settings.ikkiuchi.autoTurn, isTrue);
      await tester.tap(row);
      await tester.pump();
      expect(p.settings.ikkiuchi.autoTurn, isFalse);
      expect(p.settings.ikkiuchi.wind, isTrue, reason: 'the other switch is left as it was');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with the auto turn on the match asks for landscape, and lies turned on an upright screen',
        (tester) async {
      final (state, orientations) = await playOn(tester, usersPhone, turn: true);
      expect(orientations, [
        ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']
      ]);
      expect(state.flow!.scene.layout.landscape, isTrue);
      expect(find.byType(RotatedBox), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with it off the match lets the phone turn and lays out upright; it restores the app on leaving',
        (tester) async {
      final (state, orientations) = await playOn(tester, usersPhone, turn: false);
      expect(orientations, [
        ['DeviceOrientation.portraitUp', 'DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']
      ], reason: 'never the landscape lock');
      final layout = state.flow!.scene.layout;
      expect(layout.landscape, isFalse);
      expect((layout.size.x, layout.size.y), (usersPhone.size.width, usersPhone.size.height));
      expect(tester.takeException(), isNull);
      await leave(tester);
      expect(orientations.last, ['DeviceOrientation.portraitUp']);
      await tester.pumpWidget(const SizedBox());
    });

    // On the user's phone at its text size, and on a small one at the
    // largest.
    for (final (phone, scale) in [(usersPhone, 1.1), (const Screen('360x640', Size(360, 640), 3), 1.3)]) {
      testWidgets('held upright the game column lies along the band: 終了 and the score at its left end, the button '
          'at its right, the call between them, clear of each other and of the cards (${phone.name}, text $scale)',
          (tester) async {
        final (state, _) = await playOn(tester, phone, turn: false, fontScale: scale);
        final scene = state.flow!.scene, band = scene.band, words = scene.words;
        expect(tester.getRect(find.byType(IkkiuchiMatchColumn)), band);
        final end = tester.getRect(find.byType(HoldToConfirmButton));
        final tobi = tester.getRect(inColumn(find.text(s.ikkiuchiTobi)));
        final you = tester.getRect(inColumn(find.text(s.ikkiuchiYou)));
        final done = tester.getRect(find.ancestor(of: inColumn(find.text(s.done)), matching: find.byType(InkButton)));
        expect(inColumn(find.text('5')), findsNWidgets(2), reason: 'each side has 5 cards');
        for (final part in [end, tobi, you, done]) {
          expect(within(part, band), isTrue, reason: '$part lies in the band');
          expect(part.overlaps(words), isFalse, reason: '$part is clear of the call');
        }
        expect(end.right, lessThan(tobi.left));
        expect(tobi.right, lessThan(words.left));
        expect(done.left, greaterThan(words.right));
        expect(tobi.bottom, lessThan(band.center.dy), reason: "Tobi's count on his half");
        expect(you.top, greaterThan(band.center.dy));
        for (final card in scene.layout.cards) {
          final box = card.box;
          expect(card.side == IkkiuchiSide.player ? box.centre.y - box.hh >= band.bottom : box.centre.y + box.hh <= band.top,
              isTrue,
              reason: 'card ${card.id} is clear of the band');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets("held upright the band's buttons work: 完了 once every card is placed, then 覚えた left of 並べ替え, "
        '並べ替え ended by 完了', (tester) async {
      final (state, _) = await playOn(tester, usersPhone, turn: false);
      final flow = state.flow!, scene = flow.scene;
      Finder button(String label) => inColumn(find.text(label));
      await tester.tap(button(s.done), warnIfMissed: false);
      await tester.pump();
      expect(flow.stage, IkkiuchiStage.placing, reason: 'faded until every card is placed');
      scene.opening.placeRest();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(button(s.done));
      await tester.pump();
      expect(flow.stage, IkkiuchiStage.memoryTime);
      await tester.pump(IkkiuchiPlayTuning.relayoutGlide * 2);
      expect(tester.getRect(button(s.ikkiuchiReady)).right, lessThan(tester.getRect(button(s.ikkiuchiArrange)).left),
          reason: 'the last button rightmost');
      await tester.tap(button(s.ikkiuchiArrange));
      await tester.pump();
      expect(scene.arrange.active, isTrue);
      expect(find.text(s.ikkiuchiArranging), findsOneWidget, reason: 'the band says what goes on');
      expect(button(s.ikkiuchiReady), findsNothing);
      await tester.tap(button(s.done));
      await tester.pump();
      expect(scene.arrange.active, isFalse);
      await tester.pump(IkkiuchiPlayTuning.relayoutGlide * 2);
      await tester.tap(button(s.ikkiuchiReady));
      await tester.pump();
      expect(flow.stage, IkkiuchiStage.gameStart);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('held upright 投了 is on the band: two taps say to hold it; held it asks, Keep playing plays on and '
        'Surrender loses', (tester) async {
      final (state, _) = await playOn(tester, usersPhone, turn: false, setup: ranked);
      final flow = state.flow!;
      await toFirstRead(tester, flow);
      expect(endButton(s.ikkiuchiSurrender), findsOneWidget);
      expect(within(tester.getRect(find.byType(HoldToConfirmButton)), flow.scene.band), isTrue);
      for (var i = 0; i < HoldConfirmTuning.hintTaps; i++) {
        await tester.tap(find.byType(HoldToConfirmButton));
        await tester.pump(const Duration(milliseconds: 200));
      }
      final seconds = (IkkiuchiMatchTuning.endHold.inMilliseconds / Duration.millisecondsPerSecond).round();
      expect(find.text(s.ikkiuchiSurrenderHint(seconds)), findsOneWidget);
      await tester.pump(HoldConfirmTuning.hintLife);
      await hold(tester);
      expect(find.text(s.ikkiuchiSurrenderTitle), findsOneWidget);
      await answer(tester, s.ikkiuchiKeepPlaying);
      expect(flow.stage.over, isFalse, reason: 'plays on');
      await hold(tester);
      await answer(tester, s.ikkiuchiSurrender);
      expect(flow.stage, IkkiuchiStage.gameEnd);
      await saved(tester, state.saving);
      await toClosed(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('with it off a phone held sideways gets the landscape layout, unturned', (tester) async {
      final (state, _) = await playOn(tester, usersPhoneLandscape, turn: false);
      expect(state.flow!.scene.layout.landscape, isTrue);
      expect(find.byType(RotatedBox), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('the wind', () {
    testWidgets('Settings › Side trips › Ikkiuchi: Wind effects is on until switched off, and is kept', (tester) async {
      final p = await open(tester);
      await showPage(tester, p, page: const IkkiuchiSettingsScreen());
      final row = find.text(s.ikkiuchiWind, findRichText: true);
      expect(row, findsOneWidget);
      expect(find.text(s.ikkiuchiWindNote), findsOneWidget);
      expect(p.settings.ikkiuchi.wind, isTrue);
      await tester.tap(row);
      await tester.pump();
      expect(p.settings.ikkiuchi.wind, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    for (final wind in [true, false]) {
      testWidgets('the match board has wind ${wind ? 'on' : 'off'} as the setting says', (tester) async {
        final p = await open(tester);
        await tester.runAsync(
            () => p.updateSettings(p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.copyWith(wind: wind))));
        await showPage(tester, p, phone: usersPhoneLandscape);
        const setup = IkkiuchiSetup.free(opponentRating: 1600, perSide: 5, rows: 3, memorise: Duration(minutes: 15));
        unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
            .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 3))));
        await tester.pump();
        await tester.pump(Motion.route);
        expect(screen(tester).flow!.scene.wind, wind);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('the last 送り札', () {
    const ja = S('ja');

    /// Runs the match on by [time], frame by frame.
    Future<void> play(WidgetTester tester, Duration time) async {
      const frame = Duration(milliseconds: 16);
      for (var t = Duration.zero; t < time; t += frame) {
        await tester.pump(frame);
      }
    }

    /// Runs the match on, frame by frame, until [done].
    Future<void> playUntil(WidgetTester tester, bool Function() done, {String? reason}) async {
      for (var i = 0; i < 3000 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(done(), isTrue, reason: reason);
    }

    /// The match as it shows now, rendered as [name], its tatami drawn.
    Future<void> capture(WidgetTester tester, String name, String lang) async {
      if (!renderScreens) return;
      await tester.runAsync(() async {
        final context = tester.element(find.byType(IkkiuchiMatchScreen));
        await precacheImage(const AssetImage(IkkiuchiBoardStyle.tatami), context);
      });
      await tester.pump();
      await tester.pump();
      await captureScreen(tester, 'ikkiuchi_page/$name', lang: lang);
    }

    const setup = IkkiuchiSetup.free(opponentRating: 1600, perSide: 5, rows: 3, memorise: Duration(minutes: 15));

    /// A match of [playing], free of [setup] by default, dealt from [seed] on the user's phone turned,
    /// both sides laid out, in its memory time, Tobi reaching for no card.
    Future<IkkiuchiMatchFlow> laidOut(WidgetTester tester, Progress p, int seed, {IkkiuchiSetup? playing}) async {
      await showPage(tester, p, phone: usersPhoneLandscape);
      unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
          .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: playing ?? setup, seed: seed))));
      await tester.pump();
      await tester.pump(Motion.route);
      final flow = screen(tester).flow!;
      flow.scene.opening
        ..placeRest()
        ..finishTobi();
      flow.donePlacing();
      flow.rating = null;
      await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);
      expect(flow.stage, IkkiuchiStage.memoryTime);
      return flow;
    }

    /// [from] sends the other cards by hand until it has one left, each put
    /// down as the 送り札 has it: the player's dragged over Tobi's side, his
    /// tapped onto a free spot of theirs.
    Future<void> downToOne(WidgetTester tester, IkkiuchiMatchFlow flow, IkkiuchiSide from) async {
      final scene = flow.scene, send = scene.send;
      int left() => from == IkkiuchiSide.player ? scene.sides!.playerCards.length : scene.sides!.tobiCards.length;
      while (left() > 1) {
        flow.sendByHand(from);
        if (from == IkkiuchiSide.player) {
          final card = scene.sides!.playerCards.first;
          final at = scene.board.cards.card(card).box.centre;
          send.dragStart(card, fromStack: false, at: Offset(at.x, at.y));
          send.dragTo(Offset(at.x, scene.band.top - scene.layout.cardW));
          send.dragEnd();
        } else {
          await playUntil(tester, () => send.stage == IkkiuchiSendStage.waiting);
          send.tap(send.rectOf(send.targets().freeSpots.first.$1)!.center);
        }
        await playUntil(tester, () => flow.stage == IkkiuchiStage.memoryTime);
      }
    }

    /// On to the next read's deciding sound, and a moment past it.
    Future<void> toRead(WidgetTester tester, IkkiuchiMatchFlow flow) async {
      await playUntil(tester, () => flow.stage == IkkiuchiStage.kaminoku);
      await play(tester, Duration(milliseconds: flow.scene.reader.call!.decidedAt.round() + 200));
    }

    /// The player's finger down on [card] and up.
    void touch(IkkiuchiMatchFlow flow, int card) {
      final at = flow.scene.board.cards.card(card).box.centre;
      flow.scene
        ..pointer(PointerDownEvent(pointer: 7, position: Offset(at.x, at.y)))
        ..pointer(PointerUpEvent(pointer: 7, position: Offset(at.x, at.y)));
    }

    /// Every stage [flow] goes through from now on.
    List<IkkiuchiStage> stagesOf(IkkiuchiMatchFlow flow) {
      final seen = [flow.stage];
      flow.addListener(() {
        if (seen.last != flow.stage) seen.add(flow.stage);
      });
      return seen;
    }

    /// [card] lies in the middle of the room the [others] in its row leave
    /// it between [left] and [right]: clear of them, as far from each side.
    void expectMidRow(Rect card, Iterable<Rect> others, {required double left, required double right}) {
      final row = [
        for (final o in others)
          if ((o.center.dy - card.center.dy).abs() < 1) o,
      ];
      final from = [left, for (final o in row) if (o.center.dx < card.center.dx) o.right].reduce(math.max);
      final to = [right, for (final o in row) if (o.center.dx > card.center.dx) o.left].reduce(math.min);
      final (l, r) = (card.left - from, to - card.right);
      expect(l, greaterThan(0), reason: "clear of the row's cards");
      expect(r, greaterThan(0));
      expect((l - r).abs(), lessThan(0.2 * card.width), reason: 'in the middle of the room between them');
    }

    /// The card that went across on its own lies at its place: in the middle
    /// of [to]'s 上段, its edge on the gap between the sides, centred between
    /// the row's other cards, and turned 180° from [to]'s own cards.
    void expectLanded(IkkiuchiMatchFlow flow, int card, IkkiuchiSide to) {
      final scene = flow.scene, sides = scene.sides!;
      final top = to == IkkiuchiSide.player ? sides.player.last : sides.tobi.last;
      expect(top.middle, [card], reason: 'in the middle of the 上段');
      expect(sides.turned, {card});
      final box = scene.board.cards.card(card).box, band = scene.layout.band;
      if (to == IkkiuchiSide.player) {
        expect(box.centre.y - box.hh, closeTo(band.bottom, 0.5), reason: 'the row by the centre line');
      } else {
        expect(box.centre.y + box.hh, closeTo(band.top, 0.5), reason: 'the row by the centre line');
      }
      Rect rect(CardBox b) => Rect.fromCenter(center: Offset(b.centre.x, b.centre.y), width: 2 * b.hw, height: 2 * b.hh);
      expectMidRow(rect(box), [for (final c in scene.board.cards.cards) if (c.id != card) rect(c.box)],
          left: scene.field.left, right: scene.field.right);
      final own = to == IkkiuchiSide.player ? 0.0 : math.pi;
      expect(math.cos(box.angle - own), closeTo(-1, 1e-6), reason: 'turned from their own, as slid over');
    }

    /// History's 盤面 of the match, opened as History opens it and stepped
    /// to its last read: [card] on the side it left, and dashed where it
    /// went, in the middle of [to]'s row by the band; rendered as [name].
    Future<void> expectReplayed(WidgetTester tester, Progress p, int card, IkkiuchiSide to, String name) async {
      useScreen(tester, const Screen('384 tall', Size(384, 1300), 2.8125));
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final match = p.ikkiuchi.matches.single;
      await tester.pumpWidget(RepaintBoundary(
        key: screenKey,
        child: ProgressScope(
          progress: p,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildMangaTheme(),
            home: IkkiuchiMatchPage.of(p, match, initialTab: IkkiuchiMatchPage.fieldTab),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ja.ikkiuchiStartReview.toUpperCase()));
      await tester.pumpAndSettle();
      final reads = match.reads.length;
      for (var i = 1; i < reads; i++) {
        await tester.tap(find.bySemanticsLabel(ja.ikkiuchiStepNext));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text(ja.ikkiuchiStepRead(reads, reads).toUpperCase()), findsOneWidget, reason: 'the last read');
      List<Rect> rects(Finder f) => [for (final e in f.evaluate()) tester.getRect(find.byWidget(e.widget))];
      final words = rects(find.byWidgetPredicate((w) => w is FieldWord && w.poemId == card));
      final lying = rects(find.byWidgetPredicate((w) => w is FieldWordCard && w.poemId == card));
      expect([lying.length, words.length], [1, 2], reason: 'where it lay, and dashed where it went');
      final at = words.firstWhere((r) => !lying.single.contains(r.center));
      final band = tester.getRect(find.byType(FieldBand));
      final cards = rects(find.byType(FieldWordCard));
      final cardH = cards.first.height;
      if (to == IkkiuchiSide.opponent) {
        expect(at.center.dy, inExclusiveRange(band.top - cardH, band.top), reason: "Tobi's row by the band");
      } else {
        expect(at.center.dy, inExclusiveRange(band.bottom, band.bottom + cardH), reason: "the player's row by the band");
      }
      const pad = IkkiuchiHistoryStyle.fieldPadding;
      expectMidRow(at, cards, left: band.left + pad, right: band.right - pad);
      await captureScreen(tester, 'ikkiuchi_page/$name', lang: 'ja');
    }

    /// The match recorded, its last read with [card] sent after it to the
    /// middle of [to]'s 上段, as any 送り札 is stored.
    Future<void> expectStored(WidgetTester tester, Progress p, int card, IkkiuchiSide to) async {
      await saved(tester, screen(tester).saving);
      final match = p.ikkiuchi.matches.single;
      final last = match.reads.last;
      final spot = IkkiuchiSpot(to, FieldRow.values[setup.rows - 1], RowPart.middle, 0);
      expect([for (final s in last.sends) (s.card, s.row, s.part, s.index)], [(card, spot.row, spot.part, spot.index)]);
      expect(IkkiuchiReview(match, p.ikkiuchi.matches).sentAfter(last), [(card: card, to: spot)]);
    }

    testWidgets("a take that empties the player's side: their last card goes to Tobi's 上段 on its own",
        (tester) async {
      final p = await open(tester, lang: 'ja');
      // The deal whose first read of a card is one of Tobi's, the player's
      // last card left on their side.
      final flow = await laidOut(tester, p, 3);
      final scene = flow.scene;
      await downToOne(tester, flow, IkkiuchiSide.player);
      final last = scene.sides!.playerCards.single;
      expect([flow.tally.player, flow.tally.opponent], [1, 9]);
      flow.endMemoryTime();
      await toRead(tester, flow);
      for (var i = 0; i < 10 && scene.board.called == null; i++) {
        await playUntil(tester, () => flow.stage == IkkiuchiStage.breakAfterShimonoku, reason: 'a からふだ goes by');
        await toRead(tester, flow);
      }
      final read = scene.board.called!;
      expect(scene.board.cards.card(read).side, IkkiuchiSide.opponent, reason: "seed 3 reads one of Tobi's first");
      final seen = stagesOf(flow);
      touch(flow, read);
      await playUntil(tester, () => flow.stage == IkkiuchiStage.finalSend);
      expect(flow.tally.decided, isTrue);
      expect(flow.reads.last.sends.single.card, last, reason: 'noted on the read as it goes');
      await play(tester, IkkiuchiMatchTuning.finalSendGlide * 0.5);
      expect([scene.send.active, scene.board.carrying], [false, false], reason: "nobody places it, Tobi's arm still");
      expect(flow.stage, IkkiuchiStage.finalSend);
      await capture(tester, 'final_send_to_tobi_1_flying', 'ja');
      await play(tester, IkkiuchiMatchTuning.finalSendGlide * 0.5 + const Duration(milliseconds: 100));
      expect(flow.stage, IkkiuchiStage.finalSend, reason: 'it lies there a moment');
      expectLanded(flow, last, IkkiuchiSide.opponent);
      await capture(tester, 'final_send_to_tobi_2_landed', 'ja');
      await playUntil(tester, () => flow.stage != IkkiuchiStage.finalSend);
      expect(flow.stage, IkkiuchiStage.gameEnd);
      expect(seen, [
        IkkiuchiStage.waitingForHit,
        IkkiuchiStage.feedback,
        IkkiuchiStage.closingUp,
        IkkiuchiStage.finalSend,
        IkkiuchiStage.gameEnd,
      ]);
      await playUntil(tester, () => flow.stage == IkkiuchiStage.result);
      expect(flow.result, IkkiuchiResult.won);
      await expectStored(tester, p, last, IkkiuchiSide.opponent);
      await expectReplayed(tester, p, last, IkkiuchiSide.opponent, 'final_send_to_tobi_3_history');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a fault that empties Tobi's side: his last card goes to the player's 上段 on its own",
        (tester) async {
      final p = await open(tester, lang: 'ja');
      final flow = await laidOut(tester, p, 3);
      final scene = flow.scene;
      await downToOne(tester, flow, IkkiuchiSide.opponent);
      final last = scene.sides!.tobiCards.single;
      expect([flow.tally.player, flow.tally.opponent], [9, 1]);
      flow
        ..askKarafuda()
        ..endMemoryTime();
      await toRead(tester, flow);
      expect(scene.board.called, isNull, reason: 'a からふだ');
      final seen = stagesOf(flow);
      touch(flow, scene.sides!.playerCards.first);
      await playUntil(tester, () => flow.stage == IkkiuchiStage.finalSend);
      await play(tester, IkkiuchiMatchTuning.finalSendGlide * 0.5);
      expect([scene.send.active, scene.board.carrying], [false, false], reason: "nobody places it, Tobi's arm still");
      await capture(tester, 'final_send_to_player_1_flying', 'ja');
      await play(tester, IkkiuchiMatchTuning.finalSendGlide * 0.5 + const Duration(milliseconds: 100));
      expect(flow.stage, IkkiuchiStage.finalSend, reason: 'it lies there a moment');
      expectLanded(flow, last, IkkiuchiSide.player);
      await capture(tester, 'final_send_to_player_2_landed', 'ja');
      await playUntil(tester, () => flow.stage != IkkiuchiStage.finalSend);
      expect(flow.stage, IkkiuchiStage.gameEnd);
      expect(seen, [
        IkkiuchiStage.waitingForHit,
        IkkiuchiStage.feedback,
        IkkiuchiStage.finalSend,
        IkkiuchiStage.gameEnd,
      ]);
      await playUntil(tester, () => flow.stage == IkkiuchiStage.result);
      expect(flow.result, IkkiuchiResult.lost);
      await expectStored(tester, p, last, IkkiuchiSide.player);
      await expectReplayed(tester, p, last, IkkiuchiSide.player, 'final_send_to_player_3_history');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    /// A match decided by the player's take of Tobi's card, their own last
    /// card then sent across (seed 3), run on to [stage]; [playing] is its
    /// setup.
    Future<IkkiuchiMatchFlow> decidedAt(WidgetTester tester, Progress p, IkkiuchiStage stage,
        {IkkiuchiSetup? playing}) async {
      final flow = await laidOut(tester, p, 3, playing: playing);
      final scene = flow.scene;
      await downToOne(tester, flow, IkkiuchiSide.player);
      flow.endMemoryTime();
      await toRead(tester, flow);
      for (var i = 0; i < 10 && scene.board.called == null; i++) {
        await playUntil(tester, () => flow.stage == IkkiuchiStage.breakAfterShimonoku, reason: 'a からふだ goes by');
        await toRead(tester, flow);
      }
      touch(flow, scene.board.called!);
      await playUntil(tester, () => flow.stage == stage);
      expect(flow.tally.decided, isTrue);
      return flow;
    }

    /// The end button held as long as it takes, then the system's back.
    Future<void> holdAndBack(WidgetTester tester) async {
      final press = await tester.startGesture(tester.getCenter(find.byType(HoldToConfirmButton)));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(IkkiuchiMatchTuning.endHold);
      await press.up();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
    }

    for (final inRanked in [false, true]) {
      for (final stage in [IkkiuchiStage.closingUp, IkkiuchiStage.finalSend]) {
        testWidgets('holding 終了/投了 and back in ${stage.name} of the deciding read (${inRanked ? 'ranked' : 'free'}) ends nothing',
            (tester) async {
          final p = await open(tester, lang: 'ja');
          final match = inRanked
              ? const IkkiuchiSetup(
                  ranked: true,
                  mode: IkkiuchiMode.rapid,
                  opponent: IkkiuchiOpponent.tobi,
                  opponentRating: 1600,
                  perSide: 5,
                  rows: 3,
                  memorise: Duration(minutes: 15))
              : null;
          final flow = await decidedAt(tester, p, stage, playing: match);
          // Surrender names the button once a ranked match is under way and
          // can still be given up; decided, it is 終了 again.
          expect(find.descendant(of: find.byType(HoldToConfirmButton), matching: find.text(ja.end)), findsOneWidget);
          await holdAndBack(tester);
          expect(find.byType(AlertDialog), findsNothing, reason: 'nothing to confirm');
          expect(find.byType(IkkiuchiMatchScreen), findsOneWidget, reason: 'back leaves nothing');
          expect(flow.endedByPlayer, isFalse);
          await playUntil(tester, () => flow.stage == IkkiuchiStage.result);
          expect(flow.result, IkkiuchiResult.won);
          await saved(tester, screen(tester).saving);
          final recorded = p.ikkiuchi.matches.single;
          expect([recorded.completed, recorded.result], [true, IkkiuchiResult.won]);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });

  group('leaving', () {
    /// The system's back.
    Future<void> back(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(Motion.route);
    }

    testWidgets('a ranked match after its first read asks first: Keep playing stays, Surrender is a loss',
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p);
      final state = await start(tester, ranked);
      await toFirstRead(tester, state.flow!);
      await back(tester);
      expect(find.text(s.ikkiuchiSurrenderTitle), findsOneWidget);
      expect(find.text(s.ikkiuchiSurrenderNote), findsOneWidget);
      await answer(tester, s.ikkiuchiKeepPlaying);
      expect(find.byType(IkkiuchiMatchScreen), findsOneWidget, reason: 'still playing');
      expect(state.saving, isNull);

      await back(tester);
      await answer(tester, s.ikkiuchiSurrender);
      expect(state.flow!.stage, IkkiuchiStage.gameEnd, reason: 'given up, its end shown as 終了 shows it');
      await saved(tester, state.saving);
      expect(p.ikkiuchi.matches.single.result, IkkiuchiResult.gaveUp);
      await toResult(tester, state.flow!);
      expect(find.text(s.ikkiuchiResult(IkkiuchiResult.gaveUp)), findsOneWidget);
      await toClosed(tester);
      expect(find.byType(IkkiuchiResultsScreen), findsOneWidget, reason: 'its results follow, a loss');
      expect(p.ikkiuchi.matches, hasLength(1), reason: 'recorded once');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('終了 is 投了 once leaving a ranked match counts: held, it asks; Keep playing plays on, Surrender loses',
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p);
      final state = await start(tester, ranked);
      final flow = state.flow!;
      expect(endButton(s.end), findsOneWidget, reason: 'before the first read leaving is no loss');
      expect(endButton(s.ikkiuchiSurrender), findsNothing);
      await toFirstRead(tester, flow);
      expect(endButton(s.end), findsNothing);
      expect(endButton(s.ikkiuchiSurrender), findsOneWidget);

      await hold(tester);
      expect(find.text(s.ikkiuchiSurrenderTitle), findsOneWidget, reason: 'the hold, then the question');
      expect(find.text(s.ikkiuchiSurrenderNote), findsOneWidget);
      await answer(tester, s.ikkiuchiKeepPlaying);
      expect(find.byType(AlertDialog), findsNothing);
      expect(flow.stage, isNot(IkkiuchiStage.gameEnd), reason: 'plays on');
      expect(state.saving, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(flow.stage.over, isFalse);

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(HoldToConfirmButton));
        await tester.pump(const Duration(milliseconds: 200));
      }
      final seconds = (IkkiuchiMatchTuning.endHold.inMilliseconds / Duration.millisecondsPerSecond).round();
      expect(find.text(s.ikkiuchiSurrenderHint(seconds)), findsOneWidget, reason: 'two taps say to hold it');
      expect(find.byType(AlertDialog), findsNothing, reason: 'a tap ends nothing');
      await tester.pump(HoldConfirmTuning.hintLife);

      await hold(tester);
      await answer(tester, s.ikkiuchiSurrender);
      expect(flow.stage, IkkiuchiStage.gameEnd);
      await saved(tester, state.saving);
      expect(p.ikkiuchi.matches.single.result, IkkiuchiResult.gaveUp, reason: 'a loss');
      await toClosed(tester);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('before the first read, and in free play, back leaves without asking and 終了 stays',
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p);
      await start(tester, ranked);
      await back(tester);
      expect(find.text(s.ikkiuchiSurrenderTitle), findsNothing);
      expect(find.byType(IkkiuchiMatchScreen), findsNothing);

      final free = await start(tester, IkkiuchiSetup.firstFree);
      await toFirstRead(tester, free.flow!);
      expect(endButton(s.end), findsOneWidget, reason: 'leaving free play is no loss');
      await back(tester);
      expect(find.text(s.ikkiuchiSurrenderTitle), findsNothing);
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
      expect(shutRows(tester), [true, false, false]);
      expect(brief(tester), [8, 3], reason: 'rows that still fit stay');

      await tapAndWait(tester, key('${IkkiuchiLayoutTuning.oneRowUpTo}'), Duration.zero);
      expect(shutRows(tester), [false, false, false]);
      expect(find.text(s.ikkiuchiRowsAny(IkkiuchiLayoutTuning.oneRowUpTo)), findsOneWidget);
      expect(brief(tester), [4, 3], reason: 'rows that still fit stay');

      await tapAndWait(tester, key(s.ikkiuchiRowsKey(1)), Duration.zero);
      expect(brief(tester), [4, 1]);
      await tapAndWait(tester, plus(1), Duration.zero);
      expect(brief(tester), [5, 2], reason: 'the fewest rows 5 fit');
      await tapAndWait(tester, minus(1), Duration.zero);
      expect(brief(tester), [4, 2]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("the burst starts a free match of the setup, in its rows; then it is the free setup",
        (tester) async {
      final p = await open(tester);
      await showPage(tester, p, page: page(rating: 1600, perSide: 25, rows: 3, minutes: 15));
      final b = RankLadder.bands.firstWhere((band) => band.id == 'B');
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
      await backFromResults(tester);
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
      await tapAndWait(tester, key('4'), Duration.zero);
      await tapAndWait(tester, key(s.ikkiuchiRowsKey(1)), Duration.zero);
      await tester.ensureVisible(burst(s.ikkiuchiPlayCards(4)));
      await tapAndWait(tester, burst(s.ikkiuchiPlayCards(4)), Motion.route);
      final state = screen(tester);
      expect([state.widget.guest, state.widget.setup.perSide, state.widget.setup.rows], [true, 4, 1]);
      await toFirstRead(tester, state.flow!);
      state.flow!.end();
      await tester.pump();
      expect(state.saving, isNull);
      await toClosed(tester);
      expect(find.byType(IkkiuchiResultsScreen), findsOneWidget, reason: "a guest's match has its results too");
      expect(find.text(s.ikkiuchiReviewMatch), findsNothing, reason: 'nothing saved to review');
      await tester.pump(ResultsLayout.overlayStagger * 2);
      expect(find.byType(CelebrationSequence), findsNothing, reason: 'nothing earned');
      await backFromResults(tester);
      expect(p.ikkiuchi.matches, isEmpty);
      expect(await rows(tester, p), isEmpty);

      unawaited(openIkkiuchiCustom(tester.element(find.byType(IkkiuchiCustomPage)), guest: true));
      await tester.pump();
      await tester.pump(Motion.route);
      final opened = tester.widget<IkkiuchiCustomPage>(find.byType(IkkiuchiCustomPage).last);
      expect([opened.guest, opened.initial.perSide, opened.initial.rows], [true, 4, 1],
          reason: "the guest's last setup");
      await tester.pumpWidget(const SizedBox());
    });

    // The mock's three states, one in English, and guest mode in both, on
    // the user's phone.
    group('renders', skip: !renderScreens, () {
      final states = {
        'two': page(),
        'three': page(perSide: 20, rows: 3, minutes: 10),
        'one': page(rating: 2084, perSide: 4, rows: 1, minutes: 3),
        'eight': page(rating: 2084, perSide: 8, rows: 2, minutes: 3),
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
    // A match with the auto turn off, on the user's phone held upright and
    // held sideways: its opening, its memory time and a read.
    for (final (name, phone) in [('portrait', usersPhone), ('landscape', usersPhoneLandscape)]) {
      testWidgets('match_turn_off_$name', (tester) async {
        final p = await open(tester, lang: 'ja');
        await tester.runAsync(
            () => p.updateSettings(p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.copyWith(autoTurn: false))));
        await showPage(tester, p, phone: phone);
        const setup = IkkiuchiSetup.free(opponentRating: 1600, perSide: 20, rows: 3, memorise: Duration(minutes: 15));
        unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
            .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 3))));
        await tester.pump();
        await tester.pump(Motion.route);
        final flow = screen(tester).flow!, scene = flow.scene;
        expect(scene.layout.landscape, name == 'landscape');
        await play(tester, const Duration(seconds: 6));
        await capture(tester, 'match_turn_off_${name}_1_start', 'ja');

        scene.opening
          ..placeRest()
          ..finishTobi();
        flow.donePlacing();
        await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);
        await capture(tester, 'match_turn_off_${name}_2_memory', 'ja');

        await toFirstRead(tester, flow);
        await play(tester, const Duration(milliseconds: 3000));
        await capture(tester, 'match_turn_off_${name}_3_read', 'ja');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    // Every stage of a match of 25 a side on the user's phone at text size
    // 1, 1.1 and 1.3, in landscape and, with the auto turn off, held
    // upright, to match_stages/: placing, every card placed, the memory
    // time, 並べ替え, the greeting, a read, how it ended, a 送り札 each way,
    // the 下の句 and the result; then a ranked match's 投了: its hint, held
    // and the question after.
    for (final (orient, phone) in [('landscape', usersPhoneLandscape), ('portrait', usersPhone)]) {
      for (final (lang, scale) in [('ja', 1.0), ('ja', 1.1), ('en', 1.1), ('ja', 1.3)]) {
        Future<IkkiuchiMatchFlow> startOn(WidgetTester tester, IkkiuchiSetup setup) async {
          final p = await open(tester, lang: lang);
          await tester.runAsync(() => p.updateSettings(
              p.settings.copyWith(ikkiuchi: p.settings.ikkiuchi.copyWith(autoTurn: orient == 'landscape'))));
          await showPage(tester, p, phone: phone, fontScale: scale);
          unawaited(Navigator.of(tester.element(find.byType(IkkiuchiPage)))
              .push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, seed: 3))));
          await tester.pump();
          await tester.pump(Motion.route);
          final flow = screen(tester).flow!;
          expect(flow.scene.layout.landscape, orient == 'landscape');
          return flow;
        }

        Future<void> playUntil(WidgetTester tester, bool Function() done) async {
          for (var i = 0; i < 1000 && !done(); i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(done(), isTrue);
        }

        Future<void> shot(WidgetTester tester, String stage) async {
          expect(tester.takeException(), isNull, reason: stage);
          await capture(tester, 'match_stages/${orient}_$stage', lang);
        }

        testWidgets('match_stages_${orient}_${lang}_$scale', (tester) async {
          const setup = IkkiuchiSetup.free(opponentRating: 1600, perSide: 25, rows: 3, memorise: Duration(minutes: 15));
          final flow = await startOn(tester, setup), scene = flow.scene, send = scene.send;
          flow.rating = null;
          await play(tester, const Duration(seconds: 6));
          await shot(tester, '01_placing');

          scene.opening.placeRest();
          await play(tester, IkkiuchiColumnStyle.blinkPeriod * 2);
          await shot(tester, '02_placed');

          flow.donePlacing();
          await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);
          await shot(tester, '03_memory');

          flow.startArranging();
          await play(tester, const Duration(milliseconds: 600));
          await shot(tester, '04_arranging');
          scene.arrange.finish();
          await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);

          flow.endMemoryTime();
          await play(tester, const Duration(milliseconds: 600));
          await shot(tester, '05_greeting');

          await playUntil(tester, () => flow.stage == IkkiuchiStage.kaminoku && scene.board.called != null);
          await play(tester, Duration(milliseconds: scene.reader.call!.decidedAt ~/ 2));
          await shot(tester, '06_read');

          await play(tester, Duration(milliseconds: scene.reader.call!.decidedAt.round()));
          final read = scene.board.cards.card(scene.board.called!).box.centre;
          scene.pointer(PointerDownEvent(pointer: 7, position: Offset(read.x, read.y)));
          await tester.pump(const Duration(milliseconds: 50));
          scene.pointer(PointerUpEvent(pointer: 7, position: Offset(read.x, read.y)));
          await playUntil(tester, () => flow.stage == IkkiuchiStage.feedback);
          await play(tester, IkkiuchiMatchTuning.feedbackIn + const Duration(milliseconds: 200));
          await shot(tester, '07_feedback');

          // The player sends Tobi a card: the one the rules ask for, else
          // one by hand.
          await playUntil(tester, () =>
              flow.stage == IkkiuchiStage.sendingCard || (flow.stage.allowsHandSend && scene.atRest));
          if (flow.stage != IkkiuchiStage.sendingCard) flow.sendByHand(IkkiuchiSide.player);
          await play(tester, const Duration(milliseconds: 600));
          await shot(tester, '08_sending');
          final mine = scene.board.cards.card(scene.sides!.playerCards.first).box.centre;
          final from = Offset(mine.x, mine.y);
          send.dragStart(scene.sides!.playerCards.first, fromStack: false, at: from);
          for (var i = 1; i <= 6; i++) {
            send.dragTo(Offset.lerp(from, send.tobiSide.center, i / 6)!);
            await tester.pump(const Duration(milliseconds: 16));
          }
          await shot(tester, '09_sending_drag');
          send.dragEnd();

          // Tobi sends the player one by hand.
          await playUntil(tester, () => flow.stage.allowsHandSend && scene.atRest);
          flow.sendByHand(IkkiuchiSide.opponent);
          await playUntil(tester, () => send.stage == IkkiuchiSendStage.waiting);
          await play(tester, const Duration(milliseconds: 600));
          await shot(tester, '10_waiting');
          final card = send.card!;
          final spot = send.rectOf(send.targets().freeSpots.first.$1)!;
          send.dragStart(card, fromStack: true, at: scene.wait.center);
          for (var i = 1; i <= 6; i++) {
            send.dragTo(Offset.lerp(scene.wait.center, spot.center, i / 6)!);
            await tester.pump(const Duration(milliseconds: 16));
          }
          await shot(tester, '11_placing');
          send.dragEnd();

          await playUntil(tester, () => flow.stage == IkkiuchiStage.shimonoku && flow.share > 0.4);
          await shot(tester, '12_shimonoku');

          flow.end();
          await toResult(tester, flow);
          await play(tester, const Duration(milliseconds: 1500));
          await shot(tester, '13_result');
          await leave(tester);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('match_surrender_${orient}_${lang}_$scale', (tester) async {
          const setup = IkkiuchiSetup(
              ranked: true,
              mode: IkkiuchiMode.rapid,
              opponent: IkkiuchiOpponent.tobi,
              opponentRating: 1300,
              perSide: 25,
              rows: 3,
              memorise: Duration(minutes: 15));
          final flow = await startOn(tester, setup);
          flow.rating = null;
          flow.scene.opening
            ..placeRest()
            ..finishTobi();
          flow.donePlacing();
          await play(tester, IkkiuchiPlayTuning.relayoutGlide * 2);
          await toFirstRead(tester, flow);
          await play(tester, const Duration(milliseconds: 1500));
          await shot(tester, '14_surrender');

          final end = find.byType(HoldToConfirmButton);
          for (var i = 0; i < HoldConfirmTuning.hintTaps; i++) {
            await tester.tap(end);
            await tester.pump(const Duration(milliseconds: 200));
          }
          await play(tester, const Duration(milliseconds: 400));
          await shot(tester, '15_surrender_hint');
          await play(tester, HoldConfirmTuning.hintLife);

          final press = await tester.startGesture(tester.getCenter(end));
          await play(tester, IkkiuchiMatchTuning.endHold ~/ 2);
          await shot(tester, '16_surrender_hold');
          await play(tester, IkkiuchiMatchTuning.endHold);
          await press.up();
          await tester.pump();
          await tester.pump(Motion.route);
          expect(find.text(S(lang).ikkiuchiSurrenderTitle), findsOneWidget);
          await shot(tester, '17_surrender_asked');
          await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(S(lang).ikkiuchiKeepPlaying)));
          await tester.pump();
          await tester.pump(Motion.route);
          expect(flow.stage.over, isFalse);
          await leave(tester);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

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

    // The curve's popup on the user's phone, in Japanese at text sizes 1
    // and 1.1 and in English at 1.1, to curve_popup/: the page with Rapid
    // in placement after two matches, and the popup of Bullet (rated) and
    // of Rapid.
    for (final (lang, scale) in [('ja', 1.0), ('ja', 1.1), ('en', 1.1)]) {
      testWidgets('curve_popup_${lang}_$scale', (tester) async {
        final p = await rated(
            tester, lang, {IkkiuchiMode.bullet: bulletRatings, IkkiuchiMode.blitz: blitzRatings, rapid: rapidPlacing});
        for (final mode in [rapid, IkkiuchiMode.bullet]) {
          await openTab(tester, p, mode);
          await showPage(tester, p, fontScale: scale);
          if (mode == rapid) await capture(tester, 'curve_popup/page_rapid_placing', lang);
          await tester.tap(find.byWidgetPredicate((w) => w is IkkiuchiPlacementCurve || w is IkkiuchiRatingCurve));
          await tester.pump();
          await tester.pump(Motion.sheet);
          expect(tester.takeException(), isNull);
          await capture(tester, 'curve_popup/popup_${mode.name}', lang);
          await tester.pumpWidget(const SizedBox());
        }
      });
    }

    // Each player on phones 360 to 412 dp wide and 640 to 915 dp tall, with
    // the user's phone's bars, at text sizes 1, 1.1 and 1.3: nothing
    // overflows; the curve, or its note, takes the height left over, at
    // least its least height, or gives way; the page fills the screen,
    // and scrolls only without the curve; where the curve shows, the burst
    // stays put from tab to tab. From the user's phone's height up the
    // page fits at every text size, with the curve up to 1.1, and from
    // 900 dp with the curve at 1.3 too.
    // Renders, to heights/: every tab on the user's phone at each text
    // size; at its width, Bullet and Rapid at each height; and both on the
    // shortest phones and the tallest.
    const regular = {IkkiuchiMode.bullet: bulletRatings, IkkiuchiMode.blitz: blitzRatings, rapid: rapidPlacing};
    final players = <String, (String, Map<IkkiuchiMode, List<double>>, List<IkkiuchiMode>)>{
      'regular_ja': ('ja', regular, IkkiuchiMode.values),
      'regular_en': ('en', regular, IkkiuchiMode.values),
      'few': ('ja', {...regular, rapid: rapidPlaced}, [rapid]),
      'new': ('ja', {}, [IkkiuchiMode.bullet]),
    };
    const widths = [360.0, 384.0, 412.0];
    const heights = [640.0, 700.0, 760.0, 780.0, 800.0, 832.0, 900.0, 915.0];
    const textScales = [1.0, 1.1, 1.3];
    bool rendered(Size size, double scale, IkkiuchiMode mode) =>
        (size.width == usersPhone.size.width && size.height == usersPhone.size.height) ||
        (mode != IkkiuchiMode.blitz &&
            (size.width == usersPhone.size.width && scale == 1 ||
                size == const Size(360, 640) ||
                size == const Size(360, 800) ||
                size == const Size(412, 915)));
    for (final MapEntry(key: player, value: (lang, ratings, tabs)) in players.entries) {
      testWidgets('heights_$player', (tester) async {
        final p = await rated(tester, lang, ratings);
        for (final size in [for (final w in widths) for (final h in heights) Size(w, h)]) {
          final phone = Screen('${size.width.round()}x${size.height.round()}', size, usersPhone.dpr);
          for (final scale in textScales) {
            final where = '${phone.name} at text size $scale';
            final bursts = <int>{};
            for (final mode in tabs) {
              await openTab(tester, p, mode);
              await showPage(tester, p, phone: phone, fontScale: scale);
              expect(tester.takeException(), isNull, reason: '$where, ${mode.name}');
              final curve = find.byWidgetPredicate(
                  (w) => w is IkkiuchiRatingCurve || w is IkkiuchiPlacementCurve || w is IkkiuchiCurveNote);
              final shown = curve.evaluate().isNotEmpty;
              if (shown) {
                expect(tester.getSize(curve).height, greaterThanOrEqualTo(IkkiuchiPageLayout.curveMinHeight),
                    reason: '$where, ${mode.name}');
                expect(fits(tester), isTrue, reason: '$where, ${mode.name}: only a page without the curve scrolls');
                bursts.add((tester.getRect(find.byType(BurstButton)).top * 100).round());
              }
              if (fits(tester)) {
                expect(tester.getRect(find.byType(SideTripRulesButton)).bottom,
                    moreOrLessEquals(size.height - phone.bars.bottom - IkkiuchiPageLayout.bottomGap),
                    reason: '$where, ${mode.name}: the page fills the screen');
              }
              if (size.height >= usersPhone.size.height) {
                expect(fits(tester), isTrue, reason: '$where, ${mode.name}: fits');
              }
              if (size.height >= 900 || size.height >= usersPhone.size.height && scale <= 1.1) {
                expect(shown, isTrue, reason: '$where, ${mode.name}: the curve shows');
              }
              if (rendered(size, scale, mode)) {
                final state = switch (player) {
                  'few' => 'rapid_few',
                  'new' => 'new',
                  _ => mode == rapid ? 'rapid_placing' : mode.name,
                };
                await capture(tester, 'heights/${phone.name}_$state', lang);
              }
              await tester.pumpWidget(const SizedBox());
            }
            expect(bursts.length, lessThanOrEqualTo(1), reason: '$where: the burst stays put from tab to tab');
          }
        }
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
    }
  });
}
