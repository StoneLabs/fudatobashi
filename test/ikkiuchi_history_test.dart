// 一騎打ち in History: the page's History button opens History on the
// matches' tab, newest first, each row with its kind, result, score, setup
// and faults; the filter keeps the kinds picked (a ranked mode, or custom);
// a row opens the match's page, its overview and its reads.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/past_runs.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/history/history_filter.dart';
import 'package:fudatobashi/ui/history/history_screen.dart';
import 'package:fudatobashi/ui/history/ikkiuchi_match_page.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_page.dart';

import 'test_card_pages.dart' show loadAppFonts;
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(loadAppFonts);
  const s = S('en');
  const player = IkkiuchiSide.player, tobi = IkkiuchiSide.opponent;

  IkkiuchiMatchRecord match(DateTime at, int playerLeft, int opponentLeft,
          {bool completed = true, IkkiuchiMode? mode, List<IkkiuchiReadLog> reads = const []}) =>
      IkkiuchiMatchRecord(
        setup: IkkiuchiSetup(
            ranked: mode != null,
            mode: mode,
            opponent: IkkiuchiOpponent.tobi,
            opponentRating: 1200,
            perSide: 5,
            rows: 3,
            memorise: const Duration(minutes: 2)),
        startedAt: at,
        endedAt: at.add(const Duration(minutes: 7)),
        completed: completed,
        playerLeft: playerLeft,
        opponentLeft: opponentLeft,
        reads: reads,
      );

  Future<Progress> opened(WidgetTester tester, List<IkkiuchiMatchRecord> matches, {String language = 'en'}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: language, languagePicked: true, toured: true));
      for (final m in matches) {
        await p.recordIkkiuchi(m);
      }
    });
    return p;
  }

  Future<Progress> seeded(WidgetTester tester) {
    final now = DateTime.now();
    // Tobi's 下段 holds 87 and 18, the player's 5 and 6.
    const field = IkkiuchiLaidField(opponent: [IkkiuchiRow([87, 18], [])], player: [IkkiuchiRow([5], [6])]);
    final after = field.without(87);
    return opened(tester, [
      match(now.subtract(const Duration(days: 3)), 2, 0, mode: IkkiuchiMode.blitz),
      match(now.subtract(const Duration(hours: 1)), 4, 3, completed: false),
      match(now, 0, 3, reads: [
        IkkiuchiReadLog.of(87, const IkkiuchiReadEnd(taker: player, cardSide: tobi),
            playerTake: const Duration(milliseconds: 640),
            opponentTake: const Duration(milliseconds: 910),
            field: field),
        IkkiuchiReadLog.of(77, const IkkiuchiReadEnd(playerFaults: {tobi}), field: after),
        IkkiuchiReadLog.of(18, const IkkiuchiReadEnd(taker: tobi, cardSide: tobi, tied: true, tobiFaults: {player}),
            playerTake: const Duration(milliseconds: 500),
            opponentTake: const Duration(milliseconds: 500),
            field: after),
      ]),
    ]);
  }

  Future<void> showPage(WidgetTester tester, Progress p, {Screen screen = usersPhone, double fontScale = 1}) async {
    useScreen(tester, screen, fontScale: fontScale);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProgressScope(
      progress: p,
      child: RepaintBoundary(
        key: screenKey,
        child: MaterialApp(
          navigatorKey: navigator,
          theme: buildMangaTheme(),
          home: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    ));
    navigator.currentState!.push(MangaRoute<void>(builder: (_) => const IkkiuchiPage()));
    await tester.pump();
    await tester.pump(Motion.route);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(Motion.route);
  }

  testWidgets('History lists the matches newest first, and a match opens its reads', (tester) async {
    final p = await seeded(tester);
    await showPage(tester, p);
    await tap(tester, find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.history));
    expect(tester.widget<HistoryScreen>(find.byType(HistoryScreen)).list, HistoryList.ikkiuchi);

    Finder inHistory(Finder f) => find.descendant(of: find.byType(HistoryScreen), matching: f);
    final won = inHistory(find.text(s.ikkiuchiResult(IkkiuchiResult.won)));
    final gaveUp = inHistory(find.text(s.ikkiuchiResult(IkkiuchiResult.gaveUp)));
    expect(won, findsOneWidget);
    expect(gaveUp, findsOneWidget);
    expect(tester.getTopLeft(won).dy, lessThan(tester.getTopLeft(gaveUp).dy));
    expect(find.text('0–3'), findsOneWidget);
    expect(find.text('4–3'), findsOneWidget);
    expect(find.textContaining(s.ikkiuchiSetupLine(5, '2:00', 1200)), findsWidgets);
    expect(find.textContaining(s.ikkiuchiFaultsLine(1, 1)), findsOneWidget);
    expect(find.text(s.historyToday), findsWidgets);
    expect(inHistory(find.text(s.ikkiuchiModeRanked(IkkiuchiMode.blitz))), findsOneWidget);
    expect(inHistory(find.text(s.ikkiuchiCustom)), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await captureScreen(tester, 'ikkiuchi_history/list');

    await tap(tester, won);
    expect(find.byType(IkkiuchiMatchPage), findsOneWidget);
    expect(find.text('+3'), findsOneWidget, reason: 'the margin');
    expect(find.text(s.ikkiuchiResult(IkkiuchiResult.won).toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureScreen(tester, 'ikkiuchi_history/match');

    await tap(tester, find.text(s.ikkiuchiTabReads));
    await tester.pumpAndSettle();
    expect(find.text(s.ikkiuchiReadsNote(3)), findsOneWidget);
    expect(find.text(kimarijiFor(tester.element(find.byType(IkkiuchiMatchPage)), 87)), findsOneWidget);
    expect(find.text('0.64s'), findsOneWidget);
    expect(find.text('0.91s'), findsOneWidget);
    expect(find.text(s.ikkiuchiKarafuda.toUpperCase()), findsOneWidget);
    expect(find.text(s.ikkiuchiTied), findsOneWidget);
    expect(find.text(s.ikkiuchiFaultCount(1).toUpperCase()), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await captureScreen(tester, 'ikkiuchi_history/match', variant: 'reads');
  });

  testWidgets('the filter offers each ranked mode and custom, and keeps the kinds picked', (tester) async {
    final now = DateTime.now();
    final p = await opened(tester, [
      match(now.subtract(const Duration(hours: 3)), 0, 2, mode: IkkiuchiMode.bullet),
      match(now.subtract(const Duration(hours: 2)), 1, 0, mode: IkkiuchiMode.rapid),
      match(now.subtract(const Duration(hours: 1)), 0, 1),
    ]);
    await showPage(tester, p);
    await tap(tester, find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.history));
    Finder inHistory(Finder f) => find.descendant(of: find.byType(HistoryScreen), matching: f);
    expect([for (final k in IkkiuchiKind.values) k.label(s)], [
      for (final mode in IkkiuchiMode.values) s.ikkiuchiModeName(mode),
      s.ikkiuchiCustom,
    ]);

    await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.historyFilterLabel));
    await tester.pumpAndSettle();
    for (final kind in IkkiuchiKind.values) {
      expect(find.widgetWithText(FilterChipBox, kind.label(s)), findsOneWidget);
    }
    await tester.tap(find.widgetWithText(FilterChipBox, s.ikkiuchiModeName(IkkiuchiMode.rapid)));
    await tester.tap(find.widgetWithText(FilterChipBox, s.ikkiuchiCustom));
    await tester.pump();
    expect(find.text(s.filterShow(2)), findsOneWidget);
    await captureScreen(tester, 'ikkiuchi_history/filter');
    await tester.tap(find.text(s.filterShow(2)));
    await tester.pumpAndSettle();

    expect(inHistory(find.text('1–0')), findsOneWidget, reason: 'Rapid');
    expect(inHistory(find.text('0–1')), findsOneWidget, reason: 'custom');
    expect(inHistory(find.text('0–2')), findsNothing, reason: 'Bullet');
    expect(inHistory(find.text(s.ikkiuchiModeRanked(IkkiuchiMode.rapid))), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a ranked match's page names its mode, a free one's custom", (tester) async {
    final now = DateTime.now();
    final p = await opened(tester, [
      match(now.subtract(const Duration(hours: 1)), 0, 2, mode: IkkiuchiMode.blitz),
      match(now, 0, 1),
    ]);
    await showPage(tester, p);
    await tap(tester, find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.history));
    for (final (score, kind) in [('0–2', s.ikkiuchiModeRanked(IkkiuchiMode.blitz)), ('0–1', s.ikkiuchiCustom)]) {
      await tap(tester, find.text(score));
      expect(find.textContaining(' · ${kind.toUpperCase()} · '), findsOneWidget, reason: kind);
      Navigator.of(tester.element(find.byType(IkkiuchiMatchPage))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a match after midnight is dated by its practice day on its page, as History lists it', (tester) async {
    final afterMidnight = DateTime(2026, 11, 9, 0, 24);
    final p = await opened(tester, [match(afterMidnight, 3, 1)]);
    expect(p.dayStartedOn(afterMidnight), DateTime.utc(2026, 11, 8));
    await showPage(tester, p);
    await tap(tester, find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.history));
    expect(find.text(s.historyDay(DateTime.utc(2026, 11, 8))), findsOneWidget);

    await tap(tester, find.text('3–1'));
    expect(find.byType(IkkiuchiMatchPage), findsOneWidget);
    expect(find.textContaining('NOV 8'), findsOneWidget);
    expect(find.textContaining('NOV 9'), findsNothing);
  });

  testWidgets('a match row keeps its faults whole on one line, in Japanese with large text', (tester) async {
    const ja = S('ja');
    final p = await opened(tester, [match(DateTime.now(), 3, 1)], language: 'ja');
    await showPage(tester, p, screen: narrowPhone, fontScale: 1.3);
    await tap(tester, find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == ja.history));
    await captureScreen(tester, 'ikkiuchi_history/list', lang: 'ja');

    final faults = find.text(ja.ikkiuchiFaultsLine(0, 0));
    expect(faults, findsOneWidget);
    expect(tester.renderObject<RenderParagraph>(faults).size.height, lessThan(HistoryListStyle.rowLineFont * 2));
  });
}
