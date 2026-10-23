// 暗記練's page (AnkirenPage) on phones 360, 384 and 412 dp wide, at font
// scale 1.0 and 1.3, in English and Japanese: with ranked still shut,
// before the first ranked game, during placement, after it, and with every
// level cleared. It fits one screen at font scale 1.0 and scrolls without
// overflowing at 1.3, ranked is chained until it opens and then starts its
// one setup, the next level to clear starts from its panel, free play's
// menu chains the levels not yet open and starts a setup of the player's
// own, guest mode opens every level, and the rules open on the first visit
// and from their button.
//
// With RENDER_SCREENS=1 it also renders the page and its sheets, with real
// fonts and art, to build/screens/ankiren_page/.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/free_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_field_preview.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_screen.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_strikes.dart';
import 'package:fudatobashi/ui/history/history_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/shell/tab_chains.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_free_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_page.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_rules_sheet.dart';
import 'package:fudatobashi/ui/side_trips/burst_button.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

/// Ranked still shut (no level cleared); open but before the first ranked
/// game; one placement game in; placed (five ranked games played); and
/// placed with every level cleared.
enum _Stage { locked, fresh, placing, placed, allCleared }

const _rankedGames = {_Stage.locked: 0, _Stage.fresh: 0, _Stage.placing: 1, _Stage.placed: 5, _Stage.allCleared: 5};

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

class _QuietSounds extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final real = sounds;
  setUp(() => sounds = _QuietSounds());
  tearDown(() => sounds = real);

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

  // An all-known player in [lang] at [stage], who has seen the rules
  // unless [rulesSeen] is false, with the levels up to [cleared] cleared
  // when given instead of the stage's.
  Future<Progress> open(WidgetTester tester, _Stage stage, String lang, {bool rulesSeen = true, int? cleared}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.setLearningMode(LearningMode.allKnown);
      await p.updateSettings(p.settings.copyWith(
        language: lang,
        languagePicked: true,
        toured: true,
        ankiren: p.settings.ankiren.copyWith(rulesSeen: rulesSeen),
      ));
      final top = cleared ??
          switch (stage) {
            _Stage.locked => -1,
            _Stage.allCleared => AnkirenLevels.top,
            _ => AnkirenTuning.rankedAfterLevel,
          };
      for (var level = 0; level <= top; level++) {
        await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(level), strikes: true), startedAt: DateTime.now());
      }
      for (var i = 0; i < _rankedGames[stage]!; i++) {
        await p.recordAnkiren(playAnkiren(const AnkirenSetup.ranked(), ms: 500 + 120 * i, seed: i),
            startedAt: DateTime.now());
      }
    });
    return p;
  }

  // Shows [p]'s 暗記練 page on [phone] at [fontScale], pushed over an empty
  // screen.
  Future<void> showPage(WidgetTester tester, Progress p, Screen phone, {double fontScale = 1}) async {
    useScreen(tester, phone, fontScale: fontScale);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
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
    navigator.currentState!.push(MangaRoute<void>(builder: (_) => const AnkirenPage()));
    await tester.pump();
    await tester.pump(Motion.route);
    await tester.pump(Motion.sheet);
    await tester.pump();
  }

  Finder onPage(Finder f) => find.descendant(of: find.byType(AnkirenPage), matching: f);
  Finder numbered(String template, int value) =>
      find.byWidgetPredicate((w) => w is NumberedText && w.template == template && w.values.single == value);
  Finder close(S s) => find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.close);
  Finder historyButton(S s) =>
      onPage(find.byWidgetPredicate((w) => w is InkIconButton && w.semanticLabel == s.history));
  Finder levelButton(S s) => onPage(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenAllLevels));
  Finder burst(String title) => find.byWidgetPredicate((w) => w is BurstButton && w.title == title);

  // [f] shows whole, inside the gutters, between the system bars.
  void expectShown(WidgetTester tester, Finder f, Screen phone) {
    final r = tester.getRect(f);
    expect(r.left, greaterThanOrEqualTo(Gaps.gutter - 0.5), reason: '$f');
    expect(r.right, lessThanOrEqualTo(phone.size.width - Gaps.gutter + 0.5), reason: '$f');
    expect(r.top, greaterThanOrEqualTo(phone.bars.top), reason: '$f');
    expect(r.bottom, lessThanOrEqualTo(phone.size.height - phone.bars.bottom + 0.5), reason: '$f');
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder f, Duration wait) async {
    await tester.tap(f);
    await tester.pump();
    await tester.pump(wait);
  }

  Future<void> closeSheet(WidgetTester tester, S s) async {
    await tester.tap(close(s));
    await tester.pump();
    await tester.pump(Motion.sheet * 2);
  }

  group('fits', () {
    for (final phone in [narrowPhone, usersPhone, widePhone]) {
      for (final fontScale in [1.0, 1.3]) {
        for (final lang in ['en', 'ja']) {
          for (final stage in _Stage.values) {
            testWidgets('${stage.name}, ${phone.name} dp, font scale $fontScale ($lang)', (tester) async {
              final s = S(lang);
              final p = await open(tester, stage, lang);
              await showPage(tester, p, phone, fontScale: fontScale);
              expect(tester.takeException(), isNull);
              expect(find.byType(AnkirenRulesSheet), findsNothing, reason: 'the rules were seen');

              // At font scale 1 the page is one screen: both bursts, the pair and the
              // next level's tag show without scrolling. Larger type may scroll to them.
              final allCleared = stage == _Stage.allCleared;
              // The tag, not its unseen copy that keeps the panel's content clear of it.
              final tag = onPage(find.textContaining(allCleared ? s.ankirenAllClearedTitle : s.ankirenNextToClear)).last;
              final scroll = tester.state<ScrollableState>(onPage(find.byType(Scrollable)));
              if (fontScale == 1) expect(scroll.position.maxScrollExtent, 0, reason: 'nothing to scroll to');
              for (final f in [
                onPage(find.byType(RankedBurst)),
                onPage(find.byType(BurstButton)).last,
                onPage(find.byType(SideTripGuestButton)),
                onPage(find.byType(SideTripRulesButton)),
                tag,
                levelButton(s),
              ]) {
                await tester.ensureVisible(f);
                await tester.pump();
                expectShown(tester, f, phone);
              }
              expect(tester.getSize(levelButton(s)).height, greaterThanOrEqualTo(AnkirenPageLayout.levelButtonHeight),
                  reason: 'the level button is a full touch target');
              scroll.position.jumpTo(0);
              await tester.pump();
              final ground = onPage(find.byWidgetPredicate((w) => w is GradationBox && w.spec == Tones.homeSea));
              expect(tester.getSize(ground), phone.size, reason: 'Home\'s dots, in blue, behind the whole page');
              expect(Tones.homeSea.radiusAt(0), 0, reason: 'no dots at the top');
              expect(Tones.homeSea.radiusAt(1), greaterThan(0), reason: 'dots at the bottom');
              final placed = stage == _Stage.placed || allCleared;
              final games = onPage(find.textContaining(placed ? s.ankirenLast5 : s.ankirenPlacementTitle));
              expect(find.ancestor(of: games, matching: find.byType(MangaPanel)), findsWidgets,
                  reason: 'the games sit on a panel, not on the dots');
              if (fontScale == 1) {
                expect(onPage(find.descendant(of: find.byType(AnkirenFieldPreview), matching: find.byType(Stack))),
                    findsOneWidget,
                    reason: 'the field preview shows');
              }

              final entry = p.sideTripsHub()[SideTrip.ankiren];
              final chains = find.ancestor(of: onPage(find.byType(RankedBurst)), matching: find.byType(Stack));
              final chained = find.descendant(of: chains.first, matching: find.byType(TabChains));
              expect(chained, stage == _Stage.locked ? findsOneWidget : findsNothing,
                  reason: 'ranked is chained until it opens');
              expect(entry.rankedOpen, stage != _Stage.locked);
              final next = entry.nextLevel;
              expect(onPage(burst(s.ankirenPlayLevel(next ?? AnkirenLevels.top))), findsOneWidget);
              switch (stage) {
                case _Stage.locked:
                  expect(onPage(find.textContaining(s.ankirenPlacementTitle)), findsOneWidget);
                  expect(next, 0);
                case _Stage.fresh:
                  expect(onPage(find.text(s.sideTripUnranked)), findsOneWidget);
                  expect(onPage(find.textContaining(s.ankirenPlacementTitle)), findsOneWidget);
                  expect(next, AnkirenTuning.rankedAfterLevel + 1);
                case _Stage.placing:
                  expect(onPage(find.textContaining(s.ankirenPlacementTitle)), findsOneWidget);
                  expect(onPage(find.text('${entry.results.single.score}')), findsOneWidget);
                case _Stage.placed || _Stage.allCleared:
                  expect(onPage(find.textContaining(s.ankirenLast5)), findsOneWidget);
                  for (final r in entry.results.reversed.take(AnkirenPageLayout.lastGames)) {
                    expect(onPage(find.text('${r.score}')), findsWidgets);
                  }
                  // The strip's change and one a game.
                  expect(onPage(find.byType(RatingChangeTag)), findsNWidgets(1 + AnkirenPageLayout.lastGames));
                  expect(next, allCleared ? isNull : AnkirenTuning.rankedAfterLevel + 1);
              }
              await tester.pumpWidget(const SizedBox());
            });
          }
        }
      }
    }

    for (final lang in ['en', 'ja']) {
      for (final phone in [narrowPhone, widePhone]) {
        testWidgets('the sheets fit at font scale 1.3, ${phone.name} dp ($lang)', (tester) async {
          final s = S(lang);
          final p = await open(tester, _Stage.placed, lang);
          await showPage(tester, p, phone, fontScale: 1.3);
          for (final opener in [onPage(find.byType(SideTripGuestButton)), levelButton(s)]) {
            await tapAndSettle(tester, opener, Motion.sheet);
            expect(find.byType(AnkirenFreeSheet), findsOneWidget);
            expect(tester.takeException(), isNull);
            await closeSheet(tester, s);
            expect(find.byType(AnkirenFreeSheet), findsNothing);
          }
          await tapAndSettle(tester, onPage(find.byType(SideTripRulesButton)), Motion.sheet);
          expect(find.byType(AnkirenRulesSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });

  group('acts', () {
    for (final lang in ['en', 'ja']) {
      testWidgets('the rules explain every tier and both taps, with the tuning\'s numbers ($lang)', (tester) async {
        final s = S(lang);
        final p = await open(tester, _Stage.placed, lang);
        await showPage(tester, p, usersPhone);
        await tapAndSettle(tester, onPage(find.byType(SideTripRulesButton)), Motion.sheet);
        final rules = find.byType(AnkirenRulesSheet);
        String shown(Text t) => Phrases.spoken(t.textSpan?.toPlainText() ?? t.data ?? '').replaceAll('⁠', '');
        List<String> texts(Finder of) =>
            [for (final t in tester.widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))) shown(t)];
        final lines = texts(rules);
        bool listed(String line) => lines.any((l) => l.contains(Phrases.spoken(line)));
        expect(listed(s.ankirenScoreFind(AnkirenTuning.cardPoints, AnkirenTuning.speedMax)), isTrue);
        expect(listed(s.ankirenScoreNear((AnkirenTuning.tapWeights[1] * 100).round())), isTrue);
        expect(lines.where((l) => l.contains('20%')), hasLength(1), reason: 'the second tap counts a fifth');
        expect(listed(s.ankirenScoreLevel), isTrue, reason: 'custom games are not scored');

        final cells = texts(find.descendant(of: rules, matching: find.byType(Table)));
        String line(String cell) => cell.split('\n').first;
        expect([for (final c in cells.take(3)) line(c)],
            [for (final head in [s.ankirenTierPlace, s.ankirenTierFirst, s.ankirenTierSecond]) Phrases.spoken(head)]);
        final rows = [for (var i = 3; i + 2 < cells.length; i += 3) cells.sublist(i, i + 3)];
        expect([for (final r in rows) line(r.first)],
            [for (final place in TapProximity.values) Phrases.spoken(s.ankirenTier(place))]);
        expect([for (final r in rows) r.skip(1).toList()], [
          [Phrases.spoken(s.ankirenTierSpeed('100')), '20'],
          ['40', '8'],
          ['30', '6'],
          ['15', '3'],
          ['10', '2'],
          ['0', '0'],
        ]);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('ranked starts its one setup once open, and does nothing while chained', (tester) async {
      final locked = await open(tester, _Stage.locked, 'en');
      await showPage(tester, locked, usersPhone);
      await tapAndSettle(tester, onPage(find.byType(RankedBurst)), Motion.route);
      expect(find.byType(AnkirenScreen), findsNothing, reason: 'ranked is shut');
      await tester.pump(AnkirenPageLayout.lockBalloonLife);
      await tester.pumpWidget(const SizedBox());

      final p = await open(tester, _Stage.placed, 'en');
      await showPage(tester, p, usersPhone);
      await tapAndSettle(tester, onPage(find.byType(RankedBurst)), Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, const AnkirenSetup.ranked());
      expect(game.player, AnkirenPlayer.owner);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the next level\'s burst starts the next level to clear', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.fresh, 'en');
      const next = AnkirenTuning.rankedAfterLevel + 1;
      expect(p.sideTripsHub()[SideTrip.ankiren].nextLevel, next);
      await showPage(tester, p, usersPhone);
      expect(onPage(numbered(s.ankirenLevelValue, next)), findsOneWidget, reason: 'the level is a fact');
      await tapAndSettle(tester, onPage(burst(s.ankirenPlayLevel(next))), Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, AnkirenSetup.forLevel(next));
      expect(game.player, AnkirenPlayer.owner);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('free play: a level key fills the steppers, a stepper makes it custom, and it starts', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.placed, 'en', cleared: AnkirenTuning.customAfterLevel);
      await showPage(tester, p, usersPhone);
      await tapAndSettle(tester, levelButton(s), Motion.sheet);
      final sheet = find.byType(AnkirenFreeSheet);
      expect(sheet, findsOneWidget);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      expect(inSheet(find.byType(ClearedCheck)), findsNWidgets(AnkirenTuning.customAfterLevel + 1));
      expect(inSheet(find.byType(TabChains)), findsNWidgets(AnkirenLevels.top - AnkirenTuning.customAfterLevel - 1),
          reason: 'the levels past the next one are shut; custom is open');

      const level = 7;
      final preset = AnkirenLevels.of(level);
      await tester.runAsync(() async {
        await tester.tap(inSheet(find.text('$level')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(p.settings.ankiren.freeSetup, AnkirenSetup.forLevel(level));
      expect(inSheet(numbered(s.ankirenPerSideCount, preset.perSide)), findsOneWidget, reason: 'the stepper shows it');

      await tester.runAsync(() async {
        await tester.tap(inSheet(find.text('+')).first);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      final custom = AnkirenSetup.custom(perSide: preset.perSide + 1, memorise: preset.memorise);
      expect(p.settings.ankiren.freeSetup, custom, reason: 'a stepper turns the level into a custom setup');

      await tester.tap(inSheet(find.text(s.freeStart)));
      await tester.pump();
      await tester.pump(Motion.sheet);
      await tester.pump(Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, custom);
      expect(game.setup.ranked, isFalse);
      expect(game.player, AnkirenPlayer.owner);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('free play chains the levels not yet opened, and custom until its level', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.locked, 'en');
      await showPage(tester, p, usersPhone);
      await tapAndSettle(tester, levelButton(s), Motion.sheet);
      final sheet = find.byType(AnkirenFreeSheet);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      expect(inSheet(find.byType(ClearedCheck)), findsNothing);
      expect(inSheet(find.byType(TabChains)), findsNWidgets(AnkirenLevels.top + 1),
          reason: 'only Lv 0 is open; custom is shut');
      final before = p.settings.ankiren.freeSetup;
      await tester.tap(inSheet(find.text('+')).first, warnIfMissed: false);
      await tester.pump();
      expect(p.settings.ankiren.freeSetup, before, reason: 'the steppers are shut with custom');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('guest mode opens every level and custom, and its game records nothing', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.locked, 'en');
      final before = p.settings.ankiren.freeSetup;
      await showPage(tester, p, usersPhone);
      await tapAndSettle(tester, onPage(find.byType(SideTripGuestButton)), Motion.sheet);
      final sheet = find.byType(AnkirenFreeSheet);
      expect(tester.widget<AnkirenFreeSheet>(sheet).guest, isTrue);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
      expect(inSheet(find.byType(TabChains)), findsNothing, reason: 'every level is open');
      expect(inSheet(find.byType(ClearedCheck)), findsNothing);

      final top = AnkirenLevels.top;
      await tester.tap(inSheet(find.text('$top')));
      await tester.pump();
      await tester.tap(inSheet(find.text(s.freeStart)));
      await tester.pump();
      await tester.pump(Motion.sheet);
      await tester.pump(Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, AnkirenSetup.forLevel(top));
      expect(game.player, AnkirenPlayer.guest);
      expect(game.known, hasLength(poems.all.length), reason: 'dealt from all the cards');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(p.settings.ankiren.freeSetup, before, reason: 'a guest stores nothing');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the rules open on the first visit only, and from their button; × closes them', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.fresh, 'en', rulesSeen: false);
      await showPage(tester, p, usersPhone);
      expect(find.byType(AnkirenRulesSheet), findsOneWidget, reason: 'the first visit opens with the rules');
      for (final picture in [AnkirenRulesLayout.memorise, AnkirenRulesLayout.flip, AnkirenRulesLayout.take]) {
        expect(find.byWidgetPredicate((w) => w is Image && w.image == AssetImage(picture)), findsOneWidget);
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(p.settings.ankiren.rulesSeen, isTrue);
      await closeSheet(tester, s);
      expect(find.byType(AnkirenRulesSheet), findsNothing);
      await tester.pumpWidget(const SizedBox());

      await showPage(tester, p, usersPhone);
      expect(find.byType(AnkirenRulesSheet), findsNothing, reason: 'only the first visit');
      await tapAndSettle(tester, onPage(find.byType(SideTripRulesButton)), Motion.sheet);
      expect(find.byType(AnkirenRulesSheet), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('History opens on 暗記練\'s games', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.placed, 'en');
      await showPage(tester, p, usersPhone);
      await tapAndSettle(tester, historyButton(s), Motion.route);
      final history = tester.widget<HistoryScreen>(find.byType(HistoryScreen));
      expect(history.trip, SideTrip.ankiren);
      expect(find.textContaining(s.sideTripRanked), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('renders', skip: !renderScreens, () {
    Future<void> precacheArt(WidgetTester tester) async {
      await tester.runAsync(() async {
        final context = tester.element(find.byType(AnkirenPage, skipOffstage: false));
        await precacheImage(const AssetImage(AnkirenPlayLayout.tatami), context);
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump();
      await tester.pump();
    }

    Future<void> capture(WidgetTester tester, String screen, String lang) async {
      await precacheArt(tester);
      await captureScreen(tester, 'ankiren_page/$screen', lang: lang);
    }

    for (final phone in [narrowPhone, usersPhone, widePhone]) {
      for (final lang in ['en', 'ja']) {
        for (final fontScale in [1.0, 1.3]) {
          testWidgets('page_${phone.name}_${lang}_$fontScale', (tester) async {
            final s = S(lang);
            for (final stage in _Stage.values) {
              final p = await open(tester, stage, lang);
              await showPage(tester, p, phone, fontScale: fontScale);
              await capture(tester, stage.name, lang);
              if (stage case _Stage.fresh || _Stage.allCleared) {
                await tapAndSettle(tester, levelButton(s), Motion.sheet);
                await capture(tester, 'free_${stage.name}', lang);
                await closeSheet(tester, s);
              }
              if (stage == _Stage.placed) {
                await tapAndSettle(tester, onPage(find.byType(SideTripGuestButton)), Motion.sheet);
                await capture(tester, 'guest', lang);
                await closeSheet(tester, s);
                await tapAndSettle(tester, onPage(find.byType(SideTripRulesButton)), Motion.sheet);
                await capture(tester, 'rules', lang);
                await tester.ensureVisible(find.byType(Table));
                await tester.pump();
                await capture(tester, 'scoring', lang);
                await closeSheet(tester, s);
                await tapAndSettle(tester, historyButton(s), Motion.route);
                await capture(tester, 'history', lang);
              }
              await tester.pumpWidget(const SizedBox());
            }
          });
        }
      }
    }
  });
}
