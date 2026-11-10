// 一騎打ち's results after a match (IkkiuchiResultsScreen): how it ended,
// the tiles of a ranked match (its rating, or while placing the estimate)
// and of a free one (its XP); Review game, only for a match that was saved,
// opens that match's History page on its field, and back from it returns
// to the results; a guest's match has no Review game, Back to 一騎打ち
// takes the whole row, and nothing is celebrated. With RENDER_SCREENS=1
// it renders a ranked win, a ranked loss, a placement loss, a free match
// given up and a guest's match, in both languages at text scale 1 and 1.1,
// as ikkiuchi_results/<match>.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_review.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/summary_strings.dart';
import 'package:fudatobashi/state/ikkiuchi_records.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/history/ikkiuchi_field_tab.dart';
import 'package:fudatobashi/ui/history/ikkiuchi_match_page.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_results_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/run_summary.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_card_pages.dart' show loadAppFonts, loadCardArt;
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

class _Quiet extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}
}

/// A read of [poemId] on [field]: who took it, from their own side (no
/// one on a からふだ), each one's time to it in ms, and the faults each made
/// on it.
IkkiuchiReadLog _read(int poemId, IkkiuchiSide? taker,
        {int? you, int? tobi, int faults = 0, int tobiFaults = 0, IkkiuchiLaidField field = IkkiuchiLaidField.empty}) =>
    IkkiuchiReadLog(
      poemId: poemId,
      cardSide: taker,
      taker: taker,
      playerTake: you == null ? null : Duration(milliseconds: you),
      opponentTake: tobi == null ? null : Duration(milliseconds: tobi),
      playerFaults: faults,
      opponentFaults: tobiFaults,
      field: field,
    );

/// [cards] laid out in three rows of up to ten, each split between its
/// left and right groups; the rows stay as their cards are taken.
List<IkkiuchiRow> _rows(List<int> cards) {
  List<int> part(int from, int to) => cards.sublist(from.clamp(0, cards.length), to.clamp(0, cards.length));
  return [for (var i = 0; i < 30; i += 10) IkkiuchiRow(part(i, i + 5), part(i + 5, i + 10))];
}

/// [you] takes by the player and [tobi] by Tobi, in turn while both have
/// some, the loser of each read reaching most cards a little later; the
/// player's [faults] and Tobi's on the first reads; then a からふだ.
List<IkkiuchiReadLog> _reads({required int you, required int tobi, int faults = 0, int tobiFaults = 0}) {
  final reads = <IkkiuchiReadLog>[];
  var (mine, his) = (you, tobi);
  for (var i = 0; mine + his > 0; i++) {
    final poem = i * 37 % 100 + 1;
    final playerTakes = his == 0 || (mine > 0 && i.isEven);
    final fast = 420 + i * 137 % 640, slow = fast + 90 + i * 53 % 300;
    final reached = i % 3 != 0;
    reads.add(_read(
      poem,
      playerTakes ? IkkiuchiSide.player : IkkiuchiSide.opponent,
      you: playerTakes ? fast : (reached ? slow : null),
      tobi: playerTakes ? (reached ? slow : null) : fast,
      faults: i < faults ? 1 : 0,
      tobiFaults: i < tobiFaults ? 1 : 0,
    ));
    playerTakes ? mine-- : his--;
  }
  reads.add(_read(99, null));
  // Each read on the field as it lay: every card not yet taken.
  List<int> left(IkkiuchiSide side, Set<int> taken) => [
        for (final c in reads)
          if (c.cardSide == side && !taken.contains(c.poemId)) c.poemId,
      ];
  final taken = <int>{};
  final laid = <IkkiuchiReadLog>[];
  for (final r in reads) {
    laid.add(_read(r.poemId, r.taker,
        you: r.playerTake?.inMilliseconds,
        tobi: r.opponentTake?.inMilliseconds,
        faults: r.playerFaults,
        tobiFaults: r.opponentFaults,
        field: IkkiuchiLaidField(
            player: _rows(left(IkkiuchiSide.player, taken)), opponent: _rows(left(IkkiuchiSide.opponent, taken)))));
    taken.add(r.poemId);
  }
  return laid;
}

IkkiuchiMatchRecord _match(IkkiuchiSetup setup,
        {required int playerLeft, required int opponentLeft, bool completed = true, List<IkkiuchiReadLog> reads = const []}) =>
    IkkiuchiMatchRecord(
      setup: setup,
      startedAt: DateTime(2026, 11, 9, 20),
      endedAt: DateTime(2026, 11, 9, 20, 24),
      completed: completed,
      playerLeft: playerLeft,
      opponentLeft: opponentLeft,
      reads: reads,
    );

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final real = sounds;
  setUp(() => sounds = _Quiet());
  tearDown(() => sounds = real);
  setUpAll(loadAppFonts);
  const blitz = IkkiuchiMode.blitz;

  Future<Progress> open(WidgetTester tester, String lang) async {
    await loadCardArt(tester);
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
    });
    return p;
  }

  Future<IkkiuchiReport> record(WidgetTester tester, Progress p, IkkiuchiMatchRecord match) async =>
      (await tester.runAsync(() => p.recordIkkiuchi(match)))!;

  /// Blitz's next ranked match, won or lost by [won], with [reads].
  IkkiuchiMatchRecord ranked(Progress p, {required bool won, List<IkkiuchiReadLog> reads = const []}) =>
      _match(p.ikkiuchi.of(blitz).rankedSetup(rows: blitz.defaultRows),
          playerLeft: won ? 0 : 4, opponentLeft: won ? 3 : 0, reads: reads);

  /// Plays Blitz's next ranked matches, won or lost by [results].
  Future<void> playRanked(WidgetTester tester, Progress p, List<bool> results) async {
    for (final won in results) {
      await record(tester, p, ranked(p, won: won));
    }
  }

  /// [results] over a page it goes back to, on the user's phone at
  /// [fontScale], before any celebration.
  Future<void> show(WidgetTester tester, Progress p, IkkiuchiResultsScreen results, {double fontScale = 1}) async {
    useScreen(tester, usersPhone, fontScale: fontScale);
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
    unawaited(navigator.currentState!.push(MangaRoute<void>(builder: (_) => results)));
    await tester.pump();
    await tester.pump(Motion.route);
    expect(tester.takeException(), isNull);
  }

  Finder review(S s) => find.text(s.ikkiuchiReviewMatch);

  testWidgets("Review game opens the match's page on its field, not the latest match's; back returns to the results",
      (tester) async {
    const s = S('en');
    final p = await open(tester, 'en');
    final played = await record(tester, p,
        _match(IkkiuchiSetup.firstFree, playerLeft: 0, opponentLeft: 2, reads: _reads(you: 25, tobi: 23)));
    await record(tester, p, _match(IkkiuchiSetup.firstFree, playerLeft: 3, opponentLeft: 0));
    await show(tester, p, IkkiuchiResultsScreen(match: played.match, report: played));
    expect(find.text(s.untrackedTag), findsNothing);
    await tester.pump(ResultsLayout.overlayStagger);
    expect(find.byType(CelebrationSequence), findsOneWidget, reason: 'its XP over the results first');
    for (var i = 0; i < 5 && find.byType(CelebrationSequence).evaluate().isNotEmpty; i++) {
      await tester.tapAt(const Offset(200, 300));
      await tester.pump();
      await tester.pump(ResultsLayout.overlayFade);
      await tester.pump();
    }
    expect(find.byType(CelebrationSequence), findsNothing);

    await tester.tap(review(s));
    await tester.pump();
    await tester.pump(Motion.route);
    final page = tester.widget<IkkiuchiMatchPage>(find.byType(IkkiuchiMatchPage));
    expect(page.review.match.id, played.match.id);
    expect(page.initialTab, IkkiuchiMatchPage.fieldTab);
    expect(find.byType(IkkiuchiFieldTab), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.back));
    await tester.pump();
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchPage), findsNothing);
    expect(find.byType(IkkiuchiResultsScreen), findsOneWidget, reason: 'back on the results');

    await tester.tap(find.text(s.ikkiuchiBackToPage.toUpperCase()));
    await tester.pump();
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiResultsScreen), findsNothing, reason: 'back to the page under it');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("a guest's match: no Review game, Back to Ikkiuchi across the row, nothing celebrated", (tester) async {
    const s = S('en');
    final p = await open(tester, 'en');
    final played = _match(IkkiuchiSetup.firstFree, playerLeft: 0, opponentLeft: 2, reads: _reads(you: 25, tobi: 23));
    await show(tester, p, IkkiuchiResultsScreen(match: played));
    expect(review(s), findsNothing);
    expect(find.text(s.untrackedTag), findsOneWidget);
    expect(find.textContaining(s.ikkiuchiGuestMode.toUpperCase()), findsOneWidget, reason: 'in the header line');
    expect(find.text(s.summaryNotSaved), findsOneWidget, reason: 'no XP');
    final row = tester.getSize(find.byType(SummaryShout)).width;
    expect(row, usersPhone.size.width - 2 * Gaps.gutter, reason: 'the whole row');
    await tester.pump(ResultsLayout.overlayStagger * 2);
    expect(find.byType(CelebrationSequence), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a match the player took and reached no card in says so', (tester) async {
    const s = S('en');
    final p = await open(tester, 'en');
    final played = await record(tester, p,
        _match(IkkiuchiSetup.firstFree, playerLeft: 25, opponentLeft: 24, completed: false, reads: [_read(5, IkkiuchiSide.opponent, tobi: 700)]));
    await show(tester, p, IkkiuchiResultsScreen(match: played.match, report: played));
    expect(find.text(s.ikkiuchiNoTakes, findRichText: true), findsOneWidget);
    expect(review(s), findsOneWidget, reason: 'saved, so it can be reviewed');
    await tester.pumpWidget(const SizedBox());
  });

  /// Each match the results are shown for: how it is played, after the
  /// matches before it, and what its results say in English.
  final matches = <String, (Future<(IkkiuchiMatchRecord, IkkiuchiReport?)> Function(WidgetTester, Progress), List<String>)>{
    'ranked_win': (
      (tester, p) async {
        await playRanked(tester, p, [true, false, true, true]);
        final report = await record(tester, p, ranked(p, won: true, reads: _reads(you: 14, tobi: 10, faults: 1, tobiFaults: 2)));
        return (report.match, report);
      },
      [const S('en').ikkiuchiResultLine(IkkiuchiResult.won, 3), const S('en').ikkiuchiRatingLabel.toUpperCase()],
    ),
    'ranked_loss': (
      (tester, p) async {
        await playRanked(tester, p, [true, true, false, true, true]);
        final report = await record(tester, p, ranked(p, won: false, reads: _reads(you: 9, tobi: 13, faults: 3, tobiFaults: 1)));
        return (report.match, report);
      },
      [const S('en').ikkiuchiResultLine(IkkiuchiResult.lost, 4), const S('en').ikkiuchiRatingLabel.toUpperCase()],
    ),
    'placement_loss': (
      (tester, p) async {
        await playRanked(tester, p, [true]);
        final report = await record(tester, p, ranked(p, won: false, reads: _reads(you: 10, tobi: 13, faults: 2)));
        return (report.match, report);
      },
      [const S('en').ikkiuchiPlacing(2, IkkiuchiReview.placementMatches)],
    ),
    'free_gave_up': (
      (tester, p) async {
        final report = await record(
            tester,
            p,
            _match(IkkiuchiSetup.firstFree,
                playerLeft: 19, opponentLeft: 17, completed: false, reads: _reads(you: 6, tobi: 8, faults: 2, tobiFaults: 1)));
        return (report.match, report);
      },
      [const S('en').ikkiuchiResultLine(IkkiuchiResult.gaveUp, 2), const S('en').ikkiuchiLeftCount(36)],
    ),
    'guest': (
      (tester, p) async => (
            _match(const IkkiuchiSetup.free(opponentRating: 1500, perSide: 4, rows: 1, memorise: Duration(minutes: 2)),
                playerLeft: 0, opponentLeft: 2, reads: _reads(you: 5, tobi: 2, tobiFaults: 1)),
            null,
          ),
      [const S('en').ikkiuchiResultLine(IkkiuchiResult.won, 2), const S('en').summaryNotSaved],
    ),
  };

  for (final lang in ['en', 'ja']) {
    for (final scale in [1.0, 1.1]) {
      for (final MapEntry(key: name, value: (play, says)) in matches.entries) {
        testWidgets('${name}_$lang at text scale $scale', skip: !renderScreens && (lang != 'en' || scale != 1),
            (tester) async {
          final p = await open(tester, lang);
          final (match, report) = await play(tester, p);
          await show(tester, p, IkkiuchiResultsScreen(match: match, report: report), fontScale: scale);
          if (lang == 'en') {
            for (final text in says) {
              expect(find.text(text, findRichText: true), findsWidgets, reason: text);
            }
          }
          expect(review(S(lang)), report == null ? findsNothing : findsOneWidget);
          await captureScreen(tester, 'ikkiuchi_results/$name', lang: lang);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
