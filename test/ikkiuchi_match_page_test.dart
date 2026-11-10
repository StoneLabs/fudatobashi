// 一騎打ち's match page in History, tab by tab, on the matches of
// test/fixtures/ikkiuchi_matches.json: a ranked win, a placement match, a
// free loss and a ranked match given up, with the matches before them;
// and the field replayed read by read. With RENDER_SCREENS=1 it renders
// each tab in both languages on the user's phone and stretched to show the
// whole tab, as ikkiuchi_match/<tab>_<match>.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_mode.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/domain/ikkiuchi_review.dart';
import 'package:fudatobashi/domain/ikkiuchi_side.dart';
import 'package:fudatobashi/domain/ikkiuchi_xp.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/history/ikkiuchi_match_page.dart';
import 'package:fudatobashi/ui/history/review_field.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'test_card_pages.dart' show loadAppFonts, loadCardArt;
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

/// The user's phone stretched to show a tab's whole contents, and further
/// for every read of a ranked match.
const _tallPhone = Screen('384', Size(384, 1500), 2.8125);
const _tallerPhone = Screen('384', Size(384, 2240), 2.8125);

/// The fixture's matches in the order recorded, each with its name. The
/// ones it gives with their reads are as stored; the earlier ones, given as
/// sums, get reads made up to give them: every field read reached by both
/// at their medians, the player's takes first, a からふだ for each fault.
List<(String, IkkiuchiMatchRecord)> _fixture() {
  final json = jsonDecode(File('test/fixtures/ikkiuchi_matches.json').readAsStringSync()) as Map<String, dynamic>;
  Duration? us(Object? n) => n == null ? null : Duration(microseconds: n as int);
  IkkiuchiSide? side(Object? name) => name == null ? null : IkkiuchiSide.values.byName(name as String);
  IkkiuchiReadLog read(Map<String, dynamic> r) => IkkiuchiReadLog(
        poemId: r['poem'] as int,
        cardSide: side(r['side']),
        taker: side(r['taker']),
        tied: r['tied'] as bool? ?? false,
        playerFaults: r['playerFaults'] as int? ?? 0,
        opponentFaults: r['opponentFaults'] as int? ?? 0,
        playerTake: us(r['playerTake']),
        opponentTake: us(r['opponentTake']),
        field: IkkiuchiLaidField.fromJson(r['field'] as Map<String, dynamic>),
        faults: [for (final f in r['faults'] as List? ?? const []) IkkiuchiFault.fromJson(f as List)],
        sends: [for (final s in r['sends'] as List? ?? const []) IkkiuchiSent.fromJson(s as List)],
      );
  List<IkkiuchiReadLog> madeUp(Map<String, dynamic> m) {
    IkkiuchiReadLog take(int i, IkkiuchiSide taker) => IkkiuchiReadLog(
        poemId: i + 1,
        cardSide: taker,
        taker: taker,
        playerTake: us(m['playerMedian']),
        opponentTake: us(m['opponentMedian']));
    final player = m['playerTakes'] as int, opponent = m['opponentTakes'] as int;
    final faults = (m['playerFaults'] as int, m['opponentFaults'] as int);
    return [
      for (var i = 0; i < player; i++) take(i, IkkiuchiSide.player),
      for (var i = player; i < player + opponent; i++) take(i, IkkiuchiSide.opponent),
      for (var i = player + opponent; i < (m['reads'] as int); i++)
        IkkiuchiReadLog(
          poemId: i % 100 + 1,
          playerFaults: i - player - opponent < faults.$1 ? 1 : 0,
          opponentFaults: (m['reads'] as int) - i <= faults.$2 ? 1 : 0,
        ),
    ];
  }

  return [
    for (final (i, m) in (json['matches'] as List).cast<Map<String, dynamic>>().indexed)
      (
        m['name'] as String,
        IkkiuchiMatchRecord(
          id: i + 1,
          setup: IkkiuchiSetup(
            ranked: m['ranked'] as bool,
            mode: m['ranked'] as bool ? IkkiuchiMode.rapid : null,
            opponent: IkkiuchiOpponent.tobi,
            opponentRating: (m['opponentRating'] as num).toDouble(),
            perSide: m['perSide'] as int,
            rows: IkkiuchiLayoutTuning.rows,
            memorise: Duration(seconds: m['memoriseSeconds'] as int),
          ),
          startedAt: DateTime.parse(m['startedAt'] as String),
          endedAt: m['endedAt'] == null
              ? DateTime.parse(m['startedAt'] as String).add(Duration(minutes: m['minutes'] as int))
              : DateTime.parse(m['endedAt'] as String),
          memorised: Duration(seconds: m['memorisedSeconds'] as int),
          completed: m['completed'] as bool,
          playerLeft: m['playerLeft'] as int,
          opponentLeft: m['opponentLeft'] as int,
          rating: (m['rating'] as num?)?.toDouble(),
          reads: m['reads'] is List ? [for (final r in m['reads'] as List) read(r as Map<String, dynamic>)] : madeUp(m),
        ),
      ),
  ];
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(loadAppFonts);

  final fixture = _fixture();
  final all = [for (final (_, m) in fixture) m];
  final xpAfter = {
    for (final m in (jsonDecode(File('test/fixtures/ikkiuchi_matches.json').readAsStringSync())['matches'] as List))
      if (m['xpAfter'] case final int after) m['name'] as String: after,
  };

  /// The page's review of the fixture's match [name], with the experience
  /// it earned on top of the total the fixture gives after it.
  IkkiuchiReview review(String name) {
    final match = fixture.firstWhere((m) => m.$1 == name).$2;
    final award = IkkiuchiXp.of(match, placed: false);
    return IkkiuchiReview(match, all, xp: XpGain(before: xpAfter[name]! - award.total, award: award));
  }

  /// A player in [language], with the card art loaded first: cards keep
  /// what they first drew.
  Future<Progress> open(WidgetTester tester, String language) async {
    await loadCardArt(tester);
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: language, languagePicked: true, toured: true));
    });
    return p;
  }

  Future<void> show(WidgetTester tester, Progress p, IkkiuchiReview review, {Screen screen = usersPhone}) async {
    useScreen(tester, screen);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
          key: UniqueKey(),
          debugShowCheckedModeBanner: false,
          theme: buildMangaTheme(),
          home: IkkiuchiMatchPage(review: review),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> close(WidgetTester tester, Progress p) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => p.db.close());
  }

  group('every tab shows', () {
    const s = S('en');
    final cases = {
      'rankedWin': (s.ikkiuchiResult(IkkiuchiResult.won), s.ikkiuchiNewRating),
      'placement': (s.ikkiuchiResult(IkkiuchiResult.won), s.ikkiuchiPlacing(2, IkkiuchiReview.placementMatches)),
      'freeLoss': (s.ikkiuchiResult(IkkiuchiResult.lost), s.ikkiuchiNoRank),
      'gaveUp': (s.ikkiuchiResult(IkkiuchiResult.gaveUp), s.ikkiuchiNewRating),
    };
    for (final MapEntry(key: name, value: (result, rating)) in cases.entries) {
      testWidgets('for $name', (tester) async {
        final p = await open(tester, 'en');
        final r = review(name);
        await show(tester, p, r);
        expect(find.text(result.toUpperCase()), findsOneWidget, reason: 'the stamp');
        expect(find.text('${r.match.playerLeft}–${r.match.opponentLeft}'), findsOneWidget);
        await tab(tester, s.ikkiuchiTabField);
        expect(find.textContaining(s.ikkiuchiFieldTitle, findRichText: true), findsOneWidget);
        expect(find.byType(FieldWordCard), findsNWidgets(r.atRest.cardsOf(IkkiuchiSide.player).length +
            r.atRest.cardsOf(IkkiuchiSide.opponent).length));
        await tab(tester, s.ikkiuchiTabSpeed);
        expect(find.textContaining(s.ikkiuchiTakesTitle, findRichText: true), findsOneWidget);
        await tab(tester, s.ikkiuchiTabRating);
        expect(find.text(rating), findsOneWidget);
        final memory = r.xp!.award.parts.where((x) => x.source == XpSource.memory).firstOrNull;
        expect(memory?.count, r.match.completed ? r.match.memorised.inSeconds : null,
            reason: 'its memory time used, paid in a match played to its end');
        if (memory != null) {
          expect(find.text('${s.xpSource(XpSource.memory)} ${s.xpCount(memory)}'), findsOneWidget,
              reason: 'a line of its own');
        }
        await tab(tester, s.ikkiuchiTabReads);
        expect(find.text(s.ikkiuchiReadsNote(r.match.reads.length)), findsOneWidget);
        await close(tester, p);
      });
    }
  });

  testWidgets('a match ended before its first read says so on the tabs that show reads', (tester) async {
    const s = S('en');
    final p = await open(tester, 'en');
    final first = all.last;
    final none = IkkiuchiMatchRecord(
      id: first.id! + 1,
      setup: IkkiuchiSetup.firstFree,
      startedAt: first.endedAt,
      endedAt: first.endedAt.add(const Duration(minutes: 3)),
      completed: false,
      playerLeft: IkkiuchiSetup.firstFree.perSide,
      opponentLeft: IkkiuchiSetup.firstFree.perSide,
    );
    await show(tester, p, IkkiuchiReview(none, [...all, none], xp: const XpGain(before: 0, award: XpAward([]))));
    await tab(tester, s.ikkiuchiTabField);
    expect(find.text(s.ikkiuchiNoReads), findsOneWidget);
    await tab(tester, s.ikkiuchiTabSpeed);
    await tab(tester, s.ikkiuchiTabRating);
    expect(find.text(s.ikkiuchiNoRank), findsOneWidget);
    await tab(tester, s.ikkiuchiTabReads);
    expect(find.text(s.ikkiuchiNoReads), findsOneWidget);
    await close(tester, p);
  });

  testWidgets('the replay steps read by read, a 送り札 laid where it went', (tester) async {
    const s = S('en');
    final p = await open(tester, 'en');
    final r = review('rankedWin');
    await show(tester, p, r, screen: _tallPhone);
    await tab(tester, s.ikkiuchiTabField);
    await tester.tap(find.text(s.ikkiuchiStartReview.toUpperCase()));
    await tester.pumpAndSettle();
    final reads = r.match.reads;
    final at = reads.indexWhere((read) => read.sends.isNotEmpty && read.cardSide == IkkiuchiSide.opponent);
    for (var i = 0; i < at; i++) {
      await tester.tap(find.bySemanticsLabel(s.ikkiuchiStepNext));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text(s.ikkiuchiStepRead(at + 1, reads.length).toUpperCase()), findsOneWidget);
    final sent = reads[at].sends.single.card;
    final band = tester.getRect(find.byType(FieldBand));
    List<Rect> sentCards() => [
          for (final e in find.byWidgetPredicate((w) => w is FieldWord && w.poemId == sent).evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ];
    expect(sentCards().map((c) => c.center.dy > band.center.dy), unorderedEquals([true, false]),
        reason: 'the card on the player\'s side, and where it went on Tobi\'s');

    await tester.tap(find.bySemanticsLabel(s.ikkiuchiStepNext));
    await tester.pumpAndSettle();
    expect(find.text(s.ikkiuchiStepRead(at + 2, reads.length).toUpperCase()), findsOneWidget);
    expect(sentCards().map((c) => c.center.dy < band.center.dy), [true], reason: 'on Tobi\'s side now');

    await tester.tap(find.bySemanticsLabel(s.ikkiuchiStepBack));
    await tester.pumpAndSettle();
    expect(find.text(s.ikkiuchiStepRead(at + 1, reads.length).toUpperCase()), findsOneWidget);
    expect(sentCards(), hasLength(2));

    await tester.tap(find.text(s.ikkiuchiShowAll));
    await tester.pumpAndSettle();
    expect(find.text(s.ikkiuchiStartReview.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester, p);
  });

  for (final lang in ['ja', 'en']) {
    group('renders ($lang)', () {
      final s = S(lang);
      const tabs = (overview: 0, field: 1, speed: 2, rating: 3, reads: 4);
      String label(int i) => [s.ikkiuchiTabOverview, s.ikkiuchiTabField, s.ikkiuchiTabSpeed, s.ikkiuchiTabRating,
          s.ikkiuchiTabReads][i];
      Future<void> render(WidgetTester tester, String match, Screen screen, List<(int, String)> frames) async {
        final p = await open(tester, lang);
        await show(tester, p, review(match), screen: screen);
        for (final (i, name) in frames) {
          await tab(tester, label(i));
          await captureScreen(tester, 'ikkiuchi_match/$name', lang: lang);
        }
        await close(tester, p);
      }

      testWidgets('the ranked win', (tester) async {
        await render(tester, 'rankedWin', usersPhone, [
          (tabs.overview, 'overview_ranked_win'),
          (tabs.field, 'field_ranked_win'),
          (tabs.speed, 'speed_ranked_win'),
          (tabs.rating, 'rate_xp_ranked_win'),
        ]);
      });

      testWidgets('the ranked win, whole tabs', (tester) async {
        await render(tester, 'rankedWin', _tallPhone, [
          (tabs.overview, 'overview_ranked_win_tall'),
          (tabs.field, 'field_ranked_win_tall'),
          (tabs.speed, 'speed_ranked_win_tall'),
          (tabs.rating, 'rate_xp_ranked_win_tall'),
        ]);
      });

      testWidgets('the ranked win, every read', (tester) async {
        await render(tester, 'rankedWin', _tallerPhone, [(tabs.reads, 'reads_ranked_win_full')]);
      });

      testWidgets('the free loss', (tester) async {
        await render(tester, 'freeLoss', usersPhone, [
          (tabs.overview, 'overview_free_loss'),
          (tabs.field, 'field_free_loss'),
          (tabs.rating, 'rate_xp_free_loss'),
          (tabs.reads, 'reads_free_loss'),
        ]);
      });

      testWidgets('the free loss, whole tabs', (tester) async {
        await render(tester, 'freeLoss', _tallPhone, [
          (tabs.overview, 'overview_free_loss_tall'),
          (tabs.speed, 'speed_free_loss_tall'),
          (tabs.reads, 'reads_free_loss_tall'),
        ]);
      });

      testWidgets('the match given up', (tester) async {
        await render(tester, 'gaveUp', usersPhone, [(tabs.overview, 'overview_gave_up')]);
        await render(tester, 'gaveUp', _tallPhone, [(tabs.overview, 'overview_gave_up_tall')]);
      });

      testWidgets('the placement match', (tester) async {
        await render(tester, 'placement', usersPhone, [(tabs.rating, 'rate_xp_placement')]);
      });

      for (final (read, screen, name) in [
        (16, usersPhone, 'review_16'),
        (36, usersPhone, 'review_36'),
        (23, usersPhone, 'review_23'),
        (8, usersPhone, 'review_8'),
        (36, _tallPhone, 'review_36_tall'),
      ]) {
        testWidgets('the ranked win\'s read $read, ${screen.size.height.round()} dp tall', (tester) async {
          final p = await open(tester, lang);
          await show(tester, p, review('rankedWin'), screen: screen);
          await tab(tester, label(tabs.field));
          await tester.tap(find.text(s.ikkiuchiStartReview.toUpperCase()));
          await tester.pumpAndSettle();
          for (var i = 1; i < read; i++) {
            await tester.tap(find.bySemanticsLabel(s.ikkiuchiStepNext));
            await tester.pump();
          }
          await tester.pumpAndSettle();
          if (screen == usersPhone) {
            await tester.ensureVisible(find.byType(FieldGround));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await captureScreen(tester, 'ikkiuchi_match/$name', lang: lang);
          await close(tester, p);
        });
      }
    }, skip: !renderScreens);
  }
}
