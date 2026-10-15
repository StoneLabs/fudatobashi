import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/free_strings.dart';
import 'package:fudatobashi/l10n/history_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/stats_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/profile/profile_screen.dart';
import 'package:fudatobashi/ui/rank/rank_badges.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_vector_art.dart';

const _phone = Size(384, 832);

/// A narrower phone as tall as the user's, where a large font scale leaves
/// History's header the least room.
const _narrowPhone = Size(360, 832);

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['RENDER_SCREENS'] != '1') return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screens/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// History with side-trip games beside the runs, and My Profile's side-trip
/// ranks, on the user's phone at a large font scale.
void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  final day = DateTime(2026, 10, 1, 9);

  // An all-known player with every tab open.
  Future<Progress> open(WidgetTester tester, {required bool ja}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: ja ? 'ja' : 'en', languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.allKnown);
    });
    return p;
  }

  PlaySession swipes(List<int> ids) {
    final session = PlaySession([for (final id in ids) CardRef(id)]);
    var t = const Duration(seconds: 100);
    while (!session.finished) {
      session.revealed(t);
      t += const Duration(milliseconds: 700);
      session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
      t += const Duration(milliseconds: 100);
    }
    return session;
  }

  // The user's phone: 384 × 832 at 2.8125 px per dp, with a 28 dp status bar
  // and a 48 dp navigation bar.
  void onPhone(WidgetTester tester, {required double fontScale, Size size = _phone}) {
    const dpr = 2.8125;
    const bars = FakeViewPadding(top: 28 * dpr, bottom: 48 * dpr);
    tester.view
      ..devicePixelRatio = dpr
      ..physicalSize = size * dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    for (final (phone, fontScale) in [(_phone, 1.0), (_phone, 1.3), (_narrowPhone, 1.3)]) {
      final setup = '$lang, ${phone.width.round()} dp, font scale $fontScale';

      testWidgets('History lists runs and 暗記練 games newest first, sums them up, and its filter narrows both ($setup)',
          (tester) async {
        final s = S(ja ? 'ja' : 'en');
        final p = await open(tester, ja: ja);
        final ranked = playAnkiren(AnkirenSetup.forLevel(0, ranked: true), wrongAt: {1});
        final custom =
            playAnkiren(const AnkirenSetup.custom(perSide: 3, memorise: Duration(seconds: 30)), endAfter: 4);
        // The 暗記練 games come the next day.
        await tester.runAsync(() async {
          await p.recordRun(swipes([1, 2, 3]), const PlayConfig(mode: PlayMode.training), day);
          await p.recordRun(swipes([4, 5]), const FreePracticeSetup().config, day.add(const Duration(hours: 1)));
          await p.recordAnkiren(ranked, startedAt: day.add(const Duration(hours: 26)));
          await p.recordAnkiren(custom, startedAt: day.add(const Duration(hours: 27)));
        });
        onPhone(tester, fontScale: fontScale, size: phone);
        await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(s.history)));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);

        Finder tags() => find.descendant(of: find.byType(ListView), matching: find.byType(InkTag));
        // The filter sits above the list, whose tags may read the same.
        Finder chip(String label) => find.text(label).first;
        Future<void> filter(String label) async {
          await tester.tap(chip(label));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }

        // The record strip's stats on show, each label with the number under it.
        Map<String, String?> record() => {
              for (final label in [s.historyRunsLabel, s.historyCardsLabel, s.historyDaysLabel, s.historyBestLabel])
                if (find.text(label).evaluate().isNotEmpty)
                  label: tester
                      .widget<Text>(find
                          .descendant(
                            of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
                            matching: find.byType(Text),
                          )
                          .last)
                      .data,
            };

        final rankedTag = '暗記練 · ${s.sideTripRankedLevel(0)}';
        final customTag = '暗記練 · ${s.freePlay} · ${s.deckCustom}';
        expect([for (final e in tester.widgetList<InkTag>(tags())) e.text],
            [customTag, rankedTag, '${s.freePlay} · ${s.deckAllKnown}', s.training]);
        String line(int cards, int misses) =>
            s.historyLineTemplate.replaceAll('{0}', '$cards').replaceAll('{1}', '$misses');
        String score(int points) => s.historyScoreTemplate.replaceAll('{0}', '$points');
        expect(find.text(line(AnkirenLevels.of(0).cards, 1)), findsOneWidget,
            reason: 'one card found after a wrong tap');
        expect(find.text(line(6, 2)), findsOneWidget, reason: 'ended with two cards never found');
        expect(find.text(score(ranked.score!.total)), findsOneWidget);
        expect(find.byWidgetPredicate((w) => w is NumberedText && w.template == s.historyScoreTemplate),
            findsOneWidget, reason: 'a custom game has no score');
        expect(record(), {
          s.historyRunsLabel: '4',
          s.historyCardsLabel: '${3 + 2 + AnkirenLevels.of(0).cards + 6}',
          s.historyDaysLabel: '2'
        });

        for (final label in [s.allTab, s.training, s.freePlay, s.weakCards, SideTrip.ankiren.label]) {
          final rect = tester.getRect(chip(label));
          expect(rect.left, greaterThanOrEqualTo(Gaps.gutter));
          expect(rect.right, lessThanOrEqualTo(phone.width - Gaps.gutter), reason: 'the filter wraps into rows');
        }

        final shot = '${lang}_${phone.width.round()}_$fontScale';
        await _capture(tester, 'history_filter_$shot');
        await filter(SideTrip.ankiren.label);
        await _capture(tester, 'history_ankiren_$shot');
        expect([for (final e in tester.widgetList<InkTag>(tags())) e.text], [customTag, rankedTag]);
        expect(record(), {
          s.historyRunsLabel: '2',
          s.historyCardsLabel: '${AnkirenLevels.of(0).cards + 6}',
          s.historyBestLabel: '${ranked.score!.total}',
        });
        await filter(s.training);
        expect([for (final e in tester.widgetList<InkTag>(tags())) e.text], [s.training]);
        expect(record(), {s.historyRunsLabel: '1', s.historyCardsLabel: '3', s.historyDaysLabel: '1'});
        await filter(s.weakCards);
        expect(tags(), findsNothing);
        expect(find.text(s.noRunsYet), findsOneWidget);
        expect(record(), {s.historyRunsLabel: '0', s.historyCardsLabel: '0', s.historyDaysLabel: '0'});
        await filter(s.allTab);
        expect(tags(), findsNWidgets(4));
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('My Profile shows 暗記練\'s rank under the main one, unranked at 入門 before its first game ($lang)',
        (tester) async {
      final s = S(ja ? 'ja' : 'en');
      final p = await open(tester, ja: ja);
      p.rating = Rating.bands[2].minRating;
      onPhone(tester, fontScale: 1.3);
      Future<void> showProfile() async {
        await tester.pumpWidget(RepaintBoundary(
          key: const ValueKey('screen'),
          child: ProgressScope(progress: p, child: const MaterialApp(home: ProfileScreen())),
        ));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      }

      await showProfile();
      expect(find.text(SideTrip.ankiren.label), findsOneWidget);
      expect(find.text(s.sideTripUnranked), findsOneWidget);
      expect(tester.widget<ClassBadge>(find.byType(ClassBadge)).band, Rating.bands.first);

      await tester.runAsync(() => p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(0, ranked: true)), startedAt: day));
      final rating = p.sideTrips.ratingOf(SideTrip.ankiren)!;
      await showProfile();
      final row = find.ancestor(of: find.byType(ClassBadge), matching: find.byType(Row)).first;
      expect(find.descendant(of: row, matching: find.text('${rating.round()}')), findsOneWidget);
      expect(find.text(s.sideTripUnranked), findsNothing);
      expect(tester.widget<ClassBadge>(find.byType(ClassBadge)).band, Rating.bandOf(rating));
      final badge = tester.getSize(find.byType(ClassBadge));
      final sticker = tester.getSize(find.byType(RankSticker));
      expect(badge.height, lessThan(sticker.height), reason: 'smaller than the main rank');
      await _capture(tester, 'profile_side_trips_$lang');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
