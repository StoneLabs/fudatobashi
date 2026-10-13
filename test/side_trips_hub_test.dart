// The Side Trips hub (寄り道) on phones 360 and 412 dp wide, at font scale
// 1.0 and 1.3, in English and Japanese, with 暗記練 locked, open and
// ranked: everything shows above the tab bar, nothing overflows, and the
// buttons do what they say. 暗記練's opening shows once.
//
// With RENDER_SCREENS=1 it also renders the hub at 1080 × 2340 px, with
// real fonts and art, to .scratchpad/side_trips/.
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
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/ankiren_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/tour_strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_screen.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_free_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_rules_sheet.dart';
import 'package:fudatobashi/ui/side_trips/dojo_scene.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/side_trips/side_trips_screen.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_vector_art.dart';

/// A phone: its size in dp and its pixels per dp (both 1080 × 2340 px),
/// with a 28 dp status bar and a 48 dp navigation bar.
typedef _Phone = ({String name, Size size, double dpr});

const _narrow = (name: '360', size: Size(360, 780), dpr: 3.0);
const _wide = (name: '412', size: Size(1080 / 2.625, 2340 / 2.625), dpr: 2.625);
const _users = (name: '384', size: Size(384, 832), dpr: 2.8125);
const _statusBar = 28.0, _navBar = 48.0;

enum _Hub { locked, open, ranked }

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

class _HeardSounds extends Sounds {
  final played = <Sfx>[];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);

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
  final journeyOrder = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];

  late _HeardSounds heard;
  final real = sounds;
  setUp(() => sounds = heard = _HeardSounds());
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

  // Unlocks [ids] (journey) and trains each until it is well remembered.
  Future<void> remember(Progress p, Iterable<int> ids) async {
    for (final id in ids) {
      p.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    final session = PlaySession([for (var i = 0; i < StatsTuning.solidMinTimed; i++) ...ids.map(CardRef.new)]);
    var t = const Duration(seconds: 100);
    while (!session.finished) {
      session.revealed(t);
      t += const Duration(milliseconds: 700);
      session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
      t += const Duration(milliseconds: 100);
    }
    await p.recordRun(session, const PlayConfig(mode: PlayMode.training), DateTime.now());
  }

  // A player on the journey who has taken the tour, in [lang], with the hub
  // [hub]: locked (12 cards remembered), open (27: ranked open, free play
  // still locked, unranked) or ranked (60, and two ranked games played).
  // (All-known Home itself overflows a 360 dp phone at font scale 1.3 in
  // Japanese, so these stay on the journey.)
  Future<Progress> open(WidgetTester tester, _Hub hub, String lang) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
      switch (hub) {
        case _Hub.locked:
          await p.setLearningMode(LearningMode.journey);
          await remember(p, journeyOrder.take(12));
        case _Hub.open:
          await p.setLearningMode(LearningMode.journey);
          await remember(p, journeyOrder.take(27));
        case _Hub.ranked:
          await p.setLearningMode(LearningMode.journey);
          await remember(p, journeyOrder.take(60));
          for (final ms in [900, 600]) {
            final level = p.sideTripsHub()[SideTrip.ankiren].rankedLevel!;
            await p.recordAnkiren(playAnkiren(AnkirenSetup.forLevel(level, ranked: true), ms: ms),
                startedAt: DateTime.now());
          }
      }
    });
    return p;
  }

  // Shows [p]'s app on [phone] at [fontScale], on the Side Trips tab.
  Future<void> openHub(WidgetTester tester, Progress p, _Phone phone, {double fontScale = 1}) async {
    final bars = FakeViewPadding(top: _statusBar * phone.dpr, bottom: _navBar * phone.dpr);
    tester.view
      ..devicePixelRatio = phone.dpr
      ..physicalSize = phone.size * phone.dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.descendant(of: find.byType(MangaTabBar), matching: find.text(S(p.settings.language).sideTrips)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder inHub(Finder f) => find.descendant(of: find.byType(SideTripsScreen), matching: f);

  // [f] shows whole, inside the gutters and above the tab bar.
  void expectShown(WidgetTester tester, Finder f, _Phone phone) {
    final r = tester.getRect(f);
    final bar = tester.getRect(find.byType(MangaTabBar));
    expect(r.left, greaterThanOrEqualTo(Gaps.gutter - 0.5), reason: '$f');
    expect(r.right, lessThanOrEqualTo(phone.size.width - Gaps.gutter + 0.5), reason: '$f');
    expect(r.top, greaterThanOrEqualTo(_statusBar), reason: '$f');
    expect(r.bottom, lessThanOrEqualTo(bar.top), reason: '$f');
  }

  test('every picture in assets/images/sidetrips is art the hub or its rules use', () {
    final used = {
      for (final piece in [
        DojoSceneLayout.sky,
        ...DojoSceneLayout.farLeft,
        DojoSceneLayout.fuji,
        DojoSceneLayout.sea,
        DojoSceneLayout.construction,
        DojoSceneLayout.isle,
        DojoSceneLayout.nobori,
        DojoSceneLayout.toriiLocked,
        DojoSceneLayout.toriiOpen,
        DojoSceneLayout.boat,
        DojoSceneLayout.seaNear,
      ])
        piece.asset,
      SideTripsLayout.flag,
      AnkirenRulesLayout.memorise,
      AnkirenRulesLayout.flip,
      AnkirenRulesLayout.take,
    };
    expect({for (final f in Directory('assets/images/sidetrips').listSync()) f.path}, used);
  });

  group('fits', () {
    for (final phone in [_narrow, _wide]) {
      for (final fontScale in [1.0, 1.3]) {
        for (final lang in ['en', 'ja']) {
          for (final hub in _Hub.values) {
            testWidgets('${hub.name}, ${phone.name} dp, font scale $fontScale ($lang)', (tester) async {
              final s = S(lang);
              final p = await open(tester, hub, lang);
              await openHub(tester, p, phone, fontScale: fontScale);
              expect(tester.takeException(), isNull);
              final entry = p.sideTripsHub()[SideTrip.ankiren];
              expect(entry.open, hub != _Hub.locked);

              final scroll = tester.state<ScrollableState>(inHub(find.byType(Scrollable)));
              expect(scroll.position.maxScrollExtent, 0, reason: 'the hub fits without scrolling');
              expectShown(tester, inHub(find.byType(SideTripBody)), phone);
              expectShown(tester, inHub(find.byType(SideTripHead)), phone);
              expect(tester.getRect(inHub(find.text(s.sideTripsLettering)).first).top,
                  greaterThanOrEqualTo(_statusBar), reason: 'the title clears the status bar');
              for (final label in [s.howToPlay, if (hub != _Hub.locked) s.freePlay]) {
                expectShown(tester, inHub(find.text(label)), phone);
              }

              switch (hub) {
                case _Hub.locked:
                  expect(inHub(find.byType(RankedBurst)), findsNothing);
                  expect(inHub(find.text(s.freePlay)), findsNothing, reason: 'one lock at a time');
                  expect(inHub(find.byType(CardPips)), findsOneWidget);
                case _Hub.open:
                  expectShown(tester, inHub(find.byType(RankedBurst)), phone);
                  expect(inHub(find.text(s.sideTripUnranked)), findsOneWidget);
                  expect(inHub(find.text(s.sideTripLockedSub(SideTripTuning.ankirenFreeRemembered - 27))),
                      findsOneWidget, reason: 'free play is still locked');
                case _Hub.ranked:
                  expectShown(tester, inHub(find.byType(RankedBurst)), phone);
                  expect(inHub(find.text('${entry.rating!.round()}')), findsOneWidget);
                  expect(inHub(find.text(s.sideTripFreeUpTo(entry.maxLevel!))), findsOneWidget);
              }
              await tester.pumpWidget(const SizedBox());
            });
          }
        }
      }
    }
  });

  group('actions', () {
    testWidgets('the burst starts a ranked game', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      final level = p.sideTripsHub()[SideTrip.ankiren].rankedLevel!;
      await tester.tap(inHub(find.byType(RankedBurst)));
      await tester.pump();
      await tester.pump(Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, AnkirenSetup.forLevel(level, ranked: true));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('free play opens its setup; the rules open their sheet and close', (tester) async {
      const s = S('en');
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      await tester.tap(inHub(find.text(s.freePlay)));
      await tester.pump();
      await tester.pump(Motion.sheet);
      expect(find.byType(AnkirenFreeSheet), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(Motion.sheet * 2);
      expect(find.byType(AnkirenFreeSheet), findsNothing);

      await tester.tap(inHub(find.text(s.howToPlay)));
      await tester.pump();
      await tester.pump(Motion.sheet);
      expect(find.byType(AnkirenRulesSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(s.sideTripRulesDone));
      await tester.pump();
      await tester.pump(Motion.sheet * 2);
      expect(find.byType(AnkirenRulesSheet), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['en', 'ja']) {
      testWidgets('the rules fit at font scale 1.3 on a narrow phone ($lang)', (tester) async {
        final s = S(lang);
        final p = await open(tester, _Hub.locked, lang);
        await openHub(tester, p, _narrow, fontScale: 1.3);
        await tester.tap(inHub(find.text(s.howToPlay)));
        await tester.pump();
        await tester.pump(Motion.sheet);
        expect(find.byType(AnkirenRulesSheet), findsOneWidget, reason: 'the rules are open while 暗記練 is locked');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('locked: the bar and free play say what opens them', (tester) async {
      const s = S('en');
      final p = await open(tester, _Hub.open, 'en');
      await openHub(tester, p, _users);
      await tester.tap(inHub(find.text(s.freePlay)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.descendant(of: find.byType(SpeechBalloon), matching: find.text(s.sideTripFreeLockedWhy(23))),
          findsOneWidget);
      await tester.pump(SideTripsLayout.lockBalloonLife);
      await tester.pumpWidget(const SizedBox());

      final locked = await open(tester, _Hub.locked, 'en');
      await openHub(tester, locked, _users);
      await tester.tap(inHub(find.textContaining(s.sideTripRanked)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.descendant(of: find.byType(SpeechBalloon), matching: find.text(s.sideTripLockedWhy(13))),
          findsOneWidget);
      await tester.pump(SideTripsLayout.lockBalloonLife);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('unlock moment', () {
    GateState gate(WidgetTester tester) => tester.widget<DojoScene>(find.byType(DojoScene)).gate;

    testWidgets('暗記練 seen locked opens once, with the chains\' snap and a toast; then it stays open', (tester) async {
      const s = S('en');
      final p = await open(tester, _Hub.locked, 'en');
      await tester.runAsync(() => remember(p, journeyOrder.skip(12).take(11)));
      await openHub(tester, p, _users);
      expect(gate(tester), GateState.locked);
      expect(p.sideTripsSeenLocked, {SideTrip.ankiren});

      await tester.runAsync(() => remember(p, journeyOrder.skip(23).take(2)));
      await tester.pump();
      expect(p.sideTripsHub()[SideTrip.ankiren].open, isTrue);
      await tester.pump();
      expect(gate(tester), GateState.opening);
      expect(p.sideTripsSeenLocked, isEmpty, reason: 'shown once');
      expect(heard.played, isEmpty, reason: 'the padlock rattles first');
      await tester.pump();
      await tester.pump(DojoUnlockMotion.unlock * DojoUnlockMotion.snapAt + const Duration(milliseconds: 20));
      expect(heard.played, contains(Sfx.ratingBreak));
      expect(find.text(s.tabUnlocked(s.ankirenName)), findsOneWidget);
      await tester.pump(DojoUnlockMotion.unlock);
      await tester.pump();
      expect(gate(tester), GateState.open);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());

      heard.played.clear();
      await openHub(tester, p, _users);
      expect(gate(tester), GateState.open);
      await tester.pump(DojoUnlockMotion.unlock);
      expect(heard.played, isNot(contains(Sfx.ratingBreak)), reason: 'latched');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a trip never seen locked just shows open', (tester) async {
      final p = await open(tester, _Hub.open, 'en');
      await openHub(tester, p, _users);
      expect(gate(tester), GateState.open);
      expect(p.sideTripsSeenLocked, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('under reduced motion it opens at once', (tester) async {
      final p = await open(tester, _Hub.locked, 'en');
      await tester.runAsync(() => remember(p, journeyOrder.skip(12).take(11)));
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await openHub(tester, p, _users);
      await tester.runAsync(() => remember(p, journeyOrder.skip(23).take(2)));
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }
      expect(gate(tester), GateState.open);
      expect(tester.takeException(), isNull);
      expect(heard.played, contains(Sfx.ratingBreak));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('renders', skip: Platform.environment['RENDER_SCREENS'] != '1', () {
    Future<void> precacheArt(WidgetTester tester) async {
      await tester.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
      });
      await tester.pump();
      await tester.pump();
    }

    Future<void> capture(WidgetTester tester, _Phone phone, String name) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: phone.dpr);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('.scratchpad/side_trips/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    testWidgets('unlock', (tester) async {
      final p = await open(tester, _Hub.locked, 'ja');
      await tester.runAsync(() => remember(p, journeyOrder.skip(12).take(11)));
      await openHub(tester, p, _users);
      await tester.runAsync(() => remember(p, journeyOrder.skip(23).take(2)));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await precacheArt(tester);
      var at = Duration.zero;
      for (final t in [0.3, 0.55, 0.7, 1.0]) {
        final next = DojoUnlockMotion.unlock * t;
        await tester.pump(next - at);
        at = next;
        await precacheArt(tester);
        await capture(tester, _users, 'unlock_$t');
      }
      await tester.pumpWidget(const SizedBox());
    });

    for (final (phone, lang, fontScale) in [(_users, 'ja', 1.0), (_narrow, 'en', 1.3)]) {
      testWidgets('rules_${phone.name}_${lang}_$fontScale', (tester) async {
        final p = await open(tester, _Hub.locked, lang);
        await openHub(tester, p, phone, fontScale: fontScale);
        await tester.tap(inHub(find.text(S(lang).howToPlay)));
        await tester.pump();
        await tester.pump(Motion.sheet);
        await precacheArt(tester);
        await capture(tester, phone, 'rules_${phone.name}_${lang}_$fontScale');
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final phone in [_users, _narrow, _wide]) {
      for (final fontScale in [1.0, 1.3]) {
        for (final lang in ['en', 'ja']) {
          for (final hub in _Hub.values) {
            final name = '${hub.name}_${phone.name}_${lang}_$fontScale';
            testWidgets(name, (tester) async {
              final p = await open(tester, hub, lang);
              await openHub(tester, p, phone, fontScale: fontScale);
              await precacheArt(tester);
              await capture(tester, phone, name);
              await tester.pumpWidget(const SizedBox());
            });
          }
        }
      }
    }
  });
}
