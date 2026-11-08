// 一騎打ち in History: the page's History button opens History on the
// matches' tab, newest first, each row with its result, score, setup and
// faults; a row opens the match's page, its summary and its reads.
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
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
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
          {bool completed = true, bool ranked = false, List<IkkiuchiReadLog> reads = const []}) =>
      IkkiuchiMatchRecord(
        setup: IkkiuchiSetup(
            ranked: ranked,
            opponent: IkkiuchiOpponent.tobi,
            opponentRating: 1200,
            perSide: 5,
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
    return opened(tester, [
      match(now.subtract(const Duration(days: 3)), 2, 0, ranked: true),
      match(now.subtract(const Duration(hours: 1)), 4, 3, completed: false),
      match(now, 0, 3, reads: [
        IkkiuchiReadLog.of(87, const IkkiuchiReadEnd(taker: player, cardSide: tobi),
            playerTake: const Duration(milliseconds: 640), opponentTake: const Duration(milliseconds: 910)),
        IkkiuchiReadLog.of(77, const IkkiuchiReadEnd(playerFaults: {tobi})),
        IkkiuchiReadLog.of(18, const IkkiuchiReadEnd(taker: tobi, cardSide: tobi, tied: true, tobiFaults: {player}),
            playerTake: const Duration(milliseconds: 500), opponentTake: const Duration(milliseconds: 500)),
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
    expect(tester.takeException(), isNull);
    await captureScreen(tester, 'ikkiuchi_history/list');

    await tap(tester, won);
    expect(find.byType(IkkiuchiMatchPage), findsOneWidget);
    expect(find.text(s.ikkiuchiReadsNote(3)), findsOneWidget);
    expect(find.text(kimarijiFor(tester.element(find.byType(IkkiuchiMatchPage)), 87)), findsOneWidget);
    expect(find.text('0.64s'), findsOneWidget);
    expect(find.text('0.91s'), findsOneWidget);
    expect(find.text(s.ikkiuchiKarafuda.toUpperCase()), findsOneWidget);
    expect(find.text(s.ikkiuchiTied.toUpperCase()), findsOneWidget);
    expect(find.text(s.ikkiuchiFaultCount(1).toUpperCase()), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await captureScreen(tester, 'ikkiuchi_history/match');
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
