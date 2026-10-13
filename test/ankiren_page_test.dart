// 暗記練's page (AnkirenPage) on phones 360, 384 and 412 dp wide, at font
// scale 1.0 and 1.3, in English and Japanese: before the first ranked
// game, during placement and after it. It fits one screen without
// overflowing, ranked starts with no level to pick, free play starts a run
// of the player's own setup, and the rules open on the first visit and
// from their button.
//
// With RENDER_SCREENS=1 it also renders the page and its sheets at
// 1080 × 2340 px, with real fonts and art, to .scratchpad/ankiren_page/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_rating.dart';
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
import 'package:fudatobashi/ui/history/history_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_free_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_page.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_rules_sheet.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_vector_art.dart';

/// A phone: its size in dp and its pixels per dp (all 1080 × 2340 px),
/// with a 28 dp status bar and a 48 dp navigation bar.
typedef _Phone = ({String name, Size size, double dpr});

const _narrow = (name: '360', size: Size(360, 780), dpr: 3.0);
const _users = (name: '384', size: Size(384, 832), dpr: 2.8125);
const _wide = (name: '412', size: Size(1080 / 2.625, 2340 / 2.625), dpr: 2.625);
const _statusBar = 28.0, _navBar = 48.0;

/// Before the first ranked game, one placement game in, and placed (five
/// ranked games played).
enum _Stage { fresh, placing, placed }

const _rankedGames = {_Stage.fresh: 0, _Stage.placing: 1, _Stage.placed: 5};

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
  // unless [rulesSeen] is false.
  Future<Progress> open(WidgetTester tester, _Stage stage, String lang, {bool rulesSeen = true}) async {
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
      for (var i = 0; i < _rankedGames[stage]!; i++) {
        final level = p.sideTripsHub()[SideTrip.ankiren].rankedLevel!;
        await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(level, ranked: true), ms: 500 + 120 * i, seed: i),
            startedAt: DateTime.now());
      }
    });
    return p;
  }

  // Shows [p]'s 暗記練 page on [phone] at [fontScale], pushed over an empty
  // screen.
  Future<void> showPage(WidgetTester tester, Progress p, _Phone phone, {double fontScale = 1}) async {
    final bars = FakeViewPadding(top: _statusBar * phone.dpr, bottom: _navBar * phone.dpr);
    tester.view
      ..devicePixelRatio = phone.dpr
      ..physicalSize = phone.size * phone.dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

  // [f] shows whole, inside the gutters, between the system bars.
  void expectShown(WidgetTester tester, Finder f, _Phone phone) {
    final r = tester.getRect(f);
    expect(r.left, greaterThanOrEqualTo(Gaps.gutter - 0.5), reason: '$f');
    expect(r.right, lessThanOrEqualTo(phone.size.width - Gaps.gutter + 0.5), reason: '$f');
    expect(r.top, greaterThanOrEqualTo(_statusBar), reason: '$f');
    expect(r.bottom, lessThanOrEqualTo(phone.size.height - _navBar + 0.5), reason: '$f');
  }

  group('fits', () {
    for (final phone in [_narrow, _users, _wide]) {
      for (final fontScale in [1.0, 1.3]) {
        for (final lang in ['en', 'ja']) {
          for (final stage in _Stage.values) {
            testWidgets('${stage.name}, ${phone.name} dp, font scale $fontScale ($lang)', (tester) async {
              final s = S(lang);
              final p = await open(tester, stage, lang);
              await showPage(tester, p, phone, fontScale: fontScale);
              expect(tester.takeException(), isNull);
              expect(find.byType(AnkirenRulesSheet), findsNothing, reason: 'the rules were seen');

              // One screen: the burst and the pair show without scrolling.
              expectShown(tester, onPage(find.byType(RankedBurst)), phone);
              expectShown(tester, onPage(find.byType(SideTripFreeButton)), phone);
              expectShown(tester, onPage(find.byType(SideTripRulesButton)), phone);
              expectShown(tester, onPage(find.textContaining(s.ankirenNextRanked)), phone);
              final scroll = tester.state<ScrollableState>(onPage(find.byType(Scrollable)));
              expect(scroll.position.maxScrollExtent, 0, reason: 'nothing to scroll to');
              final ground = onPage(find.byWidgetPredicate((w) => w is GradationBox && w.spec == Tones.homeSea));
              expect(tester.getSize(ground), phone.size, reason: 'Home\'s dots, in blue, behind the whole page');
              expect(Tones.homeSea.radiusAt(0), 0, reason: 'no dots at the top');
              expect(Tones.homeSea.radiusAt(1), greaterThan(0), reason: 'dots at the bottom');
              final games = onPage(find.textContaining(stage == _Stage.placed ? s.ankirenLast5 : s.ankirenPlacementTitle));
              expect(find.ancestor(of: games, matching: find.byType(MangaPanel)), findsWidgets,
                  reason: 'the games sit on a panel, not on the dots');
              if (fontScale == 1) {
                expect(onPage(find.descendant(of: find.byType(AnkirenFieldPreview), matching: find.byType(Stack))),
                    findsOneWidget,
                    reason: 'the field preview shows');
              }

              final entry = p.sideTripsHub()[SideTrip.ankiren];
              switch (stage) {
                case _Stage.fresh:
                  expect(onPage(find.text(s.sideTripUnranked)), findsOneWidget);
                  expect(onPage(find.textContaining(s.ankirenPlacementTitle)), findsOneWidget);
                  expect(entry.rankedLevel, 0);
                case _Stage.placing:
                  expect(onPage(find.textContaining(s.ankirenPlacementTitle)), findsOneWidget);
                  expect(onPage(find.text('${entry.results.single.score}')), findsOneWidget);
                case _Stage.placed:
                  expect(onPage(find.textContaining(s.ankirenLast5)), findsOneWidget);
                  for (final r in entry.results.reversed.take(AnkirenPageLayout.lastGames)) {
                    expect(onPage(find.text('${r.score}')), findsWidgets);
                  }
                  // The strip's change and one a game.
                  expect(onPage(find.byType(RatingChangeTag)), findsNWidgets(1 + AnkirenPageLayout.lastGames));
              }
              await tester.pumpWidget(const SizedBox());
            });
          }
        }
      }
    }

    for (final lang in ['en', 'ja']) {
      for (final phone in [_narrow, _wide]) {
        testWidgets('the sheets fit at font scale 1.3, ${phone.name} dp ($lang)', (tester) async {
          final s = S(lang);
          final p = await open(tester, _Stage.placed, lang);
          await showPage(tester, p, phone, fontScale: 1.3);
          await tester.tap(onPage(find.byType(SideTripFreeButton)));
          await tester.pump();
          await tester.pump(Motion.sheet);
          expect(find.byType(AnkirenFreeSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(close(s));
          await tester.pump();
          await tester.pump(Motion.sheet * 2);
          expect(find.byType(AnkirenFreeSheet), findsNothing);
          await tester.tap(onPage(find.byType(SideTripRulesButton)));
          await tester.pump();
          await tester.pump(Motion.sheet);
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
        await showPage(tester, p, _users);
        await tester.tap(onPage(find.byType(SideTripRulesButton)));
        await tester.pump();
        await tester.pump(Motion.sheet);
        final rules = find.byType(AnkirenRulesSheet);
        String shown(Text t) => Phrases.spoken(t.textSpan?.toPlainText() ?? t.data ?? '').replaceAll('\u2060', '');
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
          ['60', '12'],
          ['40', '8'],
          ['25', '5'],
          ['15', '3'],
          ['0', '0'],
        ]);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('ranked starts at the level the rating sets, with no level to pick', (tester) async {
      final p = await open(tester, _Stage.placed, 'en');
      final entry = p.sideTripsHub()[SideTrip.ankiren];
      final level = AnkirenRating.levelFor(entry.rating!, maxLevel: AnkirenLevels.top);
      expect(entry.rankedLevel, level);
      await showPage(tester, p, _users);
      expect(onPage(numbered(const S('en').ankirenLevelValue, level)), findsOneWidget, reason: 'the level is a fact');
      await tester.tap(onPage(find.byType(RankedBurst)));
      await tester.pump();
      await tester.pump(Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, AnkirenSetup.forLevel(level, ranked: true));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('free play: a level key fills the steppers, a stepper makes it custom, and it starts', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.placed, 'en');
      await showPage(tester, p, _users);
      await tester.tap(onPage(find.text(s.freePlay)));
      await tester.pump();
      await tester.pump(Motion.sheet);
      final sheet = find.byType(AnkirenFreeSheet);
      expect(sheet, findsOneWidget);
      Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);

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
      expect(inSheet(find.textContaining(RegExp('Scored as|採点'))), findsNothing,
          reason: 'a custom setup is not scored');

      await tester.tap(inSheet(find.text(s.freeStart)));
      await tester.pump();
      await tester.pump(Motion.sheet);
      await tester.pump(Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, custom);
      expect(game.setup.ranked, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the rules open on the first visit only, and from their button; × closes them', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.fresh, 'en', rulesSeen: false);
      await showPage(tester, p, _users);
      expect(find.byType(AnkirenRulesSheet), findsOneWidget, reason: 'the first visit opens with the rules');
      for (final picture in [AnkirenRulesLayout.memorise, AnkirenRulesLayout.flip, AnkirenRulesLayout.take]) {
        expect(find.byWidgetPredicate((w) => w is Image && w.image == AssetImage(picture)), findsOneWidget);
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(p.settings.ankiren.rulesSeen, isTrue);
      await tester.tap(close(s));
      await tester.pump();
      await tester.pump(Motion.sheet * 2);
      expect(find.byType(AnkirenRulesSheet), findsNothing);
      await tester.pumpWidget(const SizedBox());

      await showPage(tester, p, _users);
      expect(find.byType(AnkirenRulesSheet), findsNothing, reason: 'only the first visit');
      await tester.tap(onPage(find.byType(SideTripRulesButton)));
      await tester.pump();
      await tester.pump(Motion.sheet);
      expect(find.byType(AnkirenRulesSheet), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('History opens on 暗記練\'s games', (tester) async {
      const s = S('en');
      final p = await open(tester, _Stage.placed, 'en');
      await showPage(tester, p, _users);
      await tester.tap(onPage(find.textContaining(s.history)));
      await tester.pump();
      await tester.pump(Motion.route);
      final history = tester.widget<HistoryScreen>(find.byType(HistoryScreen));
      expect(history.trip, SideTrip.ankiren);
      expect(find.textContaining(s.sideTripRankedLevel(p.sideTripsHub()[SideTrip.ankiren].results.last.level)),
          findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('renders', skip: Platform.environment['RENDER_SCREENS'] != '1', () {
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

    Future<void> capture(WidgetTester tester, _Phone phone, String name) async {
      await precacheArt(tester);
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: phone.dpr);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('.scratchpad/ankiren_page/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    for (final phone in [_narrow, _users, _wide]) {
      for (final lang in ['en', 'ja']) {
        for (final fontScale in [1.0, 1.3]) {
          testWidgets('page_${phone.name}_${lang}_$fontScale', (tester) async {
            for (final stage in _Stage.values) {
              final p = await open(tester, stage, lang);
              await showPage(tester, p, phone, fontScale: fontScale);
              await capture(tester, phone, '${stage.name}_${phone.name}_${lang}_$fontScale');
              if (stage == _Stage.placed) {
                await tester.tap(onPage(find.byType(SideTripFreeButton)));
                await tester.pump();
                await tester.pump(Motion.sheet);
                await capture(tester, phone, 'free_${phone.name}_${lang}_$fontScale');
                await tester.tap(close(S(lang)));
                await tester.pump();
                await tester.pump(Motion.sheet * 2);
                await tester.tap(onPage(find.byType(SideTripRulesButton)));
                await tester.pump();
                await tester.pump(Motion.sheet);
                await capture(tester, phone, 'rules_${phone.name}_${lang}_$fontScale');
                await tester.ensureVisible(find.byType(Table));
                await tester.pump();
                await capture(tester, phone, 'scoring_${phone.name}_${lang}_$fontScale');
                await tester.tap(close(S(lang)));
                await tester.pump();
                await tester.pump(Motion.sheet * 2);
                await tester.tap(onPage(find.textContaining(S(lang).history)));
                await tester.pump();
                await tester.pump(Motion.route);
                await capture(tester, phone, 'history_${phone.name}_${lang}_$fontScale');
              }
              await tester.pumpWidget(const SizedBox());
            }
          });
        }
      }
    }
  });
}
