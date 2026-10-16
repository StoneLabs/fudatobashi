// The Side Trips hub (寄り道) on phones 360 and 412 dp wide, at font scale
// 1.0 and 1.3, in English and Japanese, with 暗記練 locked, open and
// ranked: everything shows above the tab bar, nothing overflows, and the
// buttons do what they say. 暗記練's opening shows once.
//
// With RENDER_SCREENS=1 it also renders the hub at 1080 × 2340 px, with
// real fonts and art, to .scratchpad/side_trips/.
import 'dart:io';
import 'dart:math' as math;
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
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/side_trip_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/tour_strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_screen.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/home_screen.dart';
import 'package:fudatobashi/ui/home/home_widgets.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_page.dart';
import 'package:fudatobashi/ui/side_trips/dojo_scene.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_entry.dart';
import 'package:fudatobashi/ui/side_trips/side_trips_screen.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';

import 'test_ankiren.dart';
import 'test_l10n.dart';
import 'test_tabs.dart';
import 'test_vector_art.dart';

/// A phone: its size in dp and its pixels per dp (both 1080 × 2340 px),
/// with a 28 dp status bar and a 48 dp navigation bar.
typedef _Phone = ({String name, Size size, double dpr});

const _narrow = (name: '360', size: Size(360, 780), dpr: 3.0);
const _wide = (name: '412', size: Size(1080 / 2.625, 2340 / 2.625), dpr: 2.625);
const _users = (name: '384', size: Size(384, 832), dpr: 2.8125);
const _statusBar = 28.0, _navBar = 48.0;

/// The least left between the rank stamp, hanging out over the panel's
/// corner, and the screen's right edge.
const _stampMargin = 4.0;

/// Cards remembered well on the locked hub: 13 short of 暗記練.
const _lockedCards = 37;

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
  // [hub]: locked (37 cards remembered: the tab is open, 暗記練 is not), open
  // (52, unranked) or ranked (60, and two ranked games played).
  // (All-known Home itself overflows a 360 dp phone at font scale 1.3 in
  // Japanese, so these stay on the journey.)
  Future<Progress> open(WidgetTester tester, _Hub hub, String lang) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true, ankiren: const AnkirenSettings(rulesSeen: true)));
      switch (hub) {
        case _Hub.locked:
          await p.setLearningMode(LearningMode.journey);
          await remember(p, journeyOrder.take(_lockedCards));
        case _Hub.open:
          await p.setLearningMode(LearningMode.journey);
          await remember(p, journeyOrder.take(52));
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
    await tester.tap(tabButton(S(p.settings.language).sideTrips));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder inHub(Finder f) => find.descendant(of: find.byType(SideTripsScreen), matching: f);

  // How far the ring has turned, and the island in front.
  double turnOf(WidgetTester tester) => tester.widget<DojoScene>(find.byType(DojoScene)).turn.value;
  SideTripIsle frontOf(WidgetTester tester) => SideTripRing.frontAt(turnOf(tester).round());

  // The lowest the front swell's crest line runs: its picture's top, the
  // one on screen and highest, plus how deep its crest goes.
  double crestBottom(WidgetTester tester, _Phone phone) {
    final tops = [
      for (final e in inHub(find.byWidgetPredicate(
              (w) => w is ScenePicture && w.asset == DojoSceneLayout.seaNear.asset)).evaluate())
        if (tester.getRect(find.byWidget(e.widget).first).left.abs() < 0.5) tester.getRect(find.byWidget(e.widget).first).top,
    ];
    return tops.reduce(math.min) + DojoSceneLayout.crest * phone.size.width / DojoSceneLayout.width;
  }

  // Swipes the ring a step: a finger going left turns it forward.
  Future<void> swipe(WidgetTester tester, {bool forward = true}) async {
    await tester.fling(inHub(find.byType(DojoScene)), Offset(forward ? -200 : 200, 0), 1200);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  }

  Finder pictures(String asset) =>
      inHub(find.byWidgetPredicate((w) => w is ScenePicture && w.asset == asset));

  // [f] shows whole, inside the gutters and above the tab bar.
  void expectShown(WidgetTester tester, Finder f, _Phone phone) {
    final r = tester.getRect(f);
    final bar = tester.getRect(find.byType(MangaTabBar));
    expect(r.left, greaterThanOrEqualTo(Gaps.gutter - 0.5), reason: '$f');
    expect(r.right, lessThanOrEqualTo(phone.size.width - Gaps.gutter + 0.5), reason: '$f');
    expect(r.top, greaterThanOrEqualTo(_statusBar), reason: '$f');
    expect(r.bottom, lessThanOrEqualTo(bar.top), reason: '$f');
  }

  // The box that holds [f], tilted, on screen: its corners' bounds.
  Rect paintedRect(WidgetTester tester, Finder f) {
    final box = tester.renderObject<RenderBox>(find.descendant(of: f, matching: find.byType(DecoratedBox)).first);
    final corners = [
      for (final c in [Offset.zero, Offset(box.size.width, 0), Offset(0, box.size.height), box.size.bottomRight(Offset.zero)])
        box.localToGlobal(c),
    ];
    return Rect.fromLTRB(
      corners.map((c) => c.dx).reduce(math.min),
      corners.map((c) => c.dy).reduce(math.min),
      corners.map((c) => c.dx).reduce(math.max),
      corners.map((c) => c.dy).reduce(math.max),
    );
  }

  test('every picture in assets/images/sidetrips is art the hub, its rules or the rating and rank pages use', () {
    final used = {
      for (final piece in [
        DojoSceneLayout.sky,
        DojoSceneLayout.sunRays,
        DojoSceneLayout.sunFace,
        DojoSceneLayout.sunBlink,
        for (final cloud in DojoSceneLayout.clouds) cloud.piece,
        DojoSceneLayout.sea,
        DojoSceneLayout.toriiLocked,
        DojoSceneLayout.toriiOpen,
        DojoSceneLayout.boat,
        DojoSceneLayout.seaNear,
        for (final layer in DojoSceneLayout.backWaves) layer.piece,
        DojoRingLayout.nobori,
      ])
        piece.asset,
      for (final art in [DojoRingLayout.ankiren, DojoRingLayout.building, DojoRingLayout.fuji, DojoRingLayout.lighthouse])
        ...[art.colour, art.haze],
      AnkirenRulesLayout.memorise,
      AnkirenRulesLayout.flip,
      AnkirenRulesLayout.take,
      AnkirenRatingLayout.pole,
      ...AnkirenRatingLayout.cloth,
      AnkirenRankLayout.splash,
      AnkirenRankLayout.crack,
    };
    final files = Directory('assets/images/sidetrips').listSync(recursive: true).whereType<File>();
    expect({for (final f in files) f.path}, used);
  });

  group('fits', () {
    for (final phone in [_narrow, _users, _wide]) {
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
              expect(tester.getRect(inHub(find.byType(SideTripHead))).top,
                  greaterThanOrEqualTo(crestBottom(tester, phone)), reason: 'the entry sits under the crest');
              final lettering = inHub(find.byWidgetPredicate(
                  (w) => w is Text && w.data?.replaceAll('\n', ' ') == s.sideTripsLettering)).first;
              expect(tester.getRect(lettering).top, greaterThanOrEqualTo(_statusBar),
                  reason: 'the title clears the status bar');
              expect(tester.getRect(lettering).right,
                  lessThanOrEqualTo(DojoSceneLayout.sunFace.rect.left * phone.size.width / DojoSceneLayout.width),
                  reason: 'the title stays clear of the sun');
              expect(tester.getRect(inHub(find.byType(SingleChildScrollView))).bottom, phone.size.height,
                  reason: 'the sea runs on under the tab bar');
              if (hub == _Hub.locked) {
                expect(inHub(find.text(s.howToPlay)), findsNothing, reason: 'no rules while locked');
                expectShown(tester, inHub(find.textContaining(s.sideTripRemembered)), phone);
                expectShown(tester, inHub(find.byType(CardPips)).first, phone);
                expectShown(tester, inHub(find.textContaining(s.sideTripRanked)), phone);
                expect(inHub(find.byType(PageBurst)), findsNothing);
              } else {
                expectShown(tester, inHub(find.byType(PageBurst)), phone);
                expectShown(tester, inHub(find.text(s.ankirenPageTitle)), phone);
                expect(inHub(find.byType(RankedBurst)), findsNothing, reason: 'ranked starts from the page');
                expect(inHub(find.byType(SideTripRulesButton)), findsNothing);
                expect(inHub(find.byType(SideTripFreeButton)), findsNothing);
                expect(inHub(find.byType(HomeRowButton)), findsNothing, reason: 'the burst is the only button');
              }

              switch (hub) {
                case _Hub.locked:
                  expect(inHub(find.text(s.freePlay)), findsNothing, reason: 'one lock at a time');
                  final rows = tester.widgetList<CardPips>(inHub(find.byType(CardPips)));
                  expect([for (final r in rows) r.pips.length], [25, 25], reason: '50 pips in two rows');
                  expect([for (final r in rows) ...r.pips].where((p) => p == PipState.learned),
                      hasLength(_lockedCards));
                case _Hub.open:
                  expect(inHub(find.text(s.sideTripUnranked)), findsOneWidget);
                case _Hub.ranked:
                  expect(inHub(find.text('${entry.rating!.round()}')), findsOneWidget);
              }

              final stamp = inHub(find.byType(Sticker));
              expect(find.descendant(of: inHub(find.byType(SideTripHead)), matching: find.byType(Image)), findsNothing,
                  reason: 'no flag picture');
              if (hub != _Hub.ranked) {
                expect(stamp, findsNothing, reason: 'no class while locked or unranked');
              } else {
                expect(stamp, findsOneWidget);
                expect(find.descendant(of: stamp, matching: find.textContaining(s.classStem(entry.band), findRichText: true)),
                    findsOneWidget, reason: 'the stamp says ${s.className(entry.band)}');
                final painted = paintedRect(tester, stamp);
                expect(painted.left, greaterThan(0), reason: '$painted');
                expect(painted.right, lessThanOrEqualTo(phone.size.width - _stampMargin), reason: '$painted');
                expect(painted.top, greaterThanOrEqualTo(_statusBar), reason: '$painted');
                final rows = find.descendant(
                    of: inHub(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenOpenPage)),
                    matching: find.byType(RichText));
                expect(rows, findsWidgets);
                for (final text in rows.evaluate()) {
                  final rect = tester.getRect(find.byWidget(text.widget));
                  expect(painted.overlaps(rect), isFalse, reason: 'the stamp $painted covers text at $rect');
                }
              }
              await tester.pumpWidget(const SizedBox());
            });
          }
        }
      }
    }
  });

  group('actions', () {
    testWidgets('the burst opens AnkiRen\'s page, where ranked starts', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      final level = p.sideTripsHub()[SideTrip.ankiren].rankedLevel!;
      await tester.tap(inHub(find.byType(PageBurst)));
      await tester.pump();
      await tester.pump(Motion.route * 2);
      expect(find.byType(AnkirenPage), findsOneWidget);
      await tester.tap(find.byType(RankedBurst));
      await tester.pump();
      await tester.pump(Motion.route);
      final game = tester.widget<AnkirenScreen>(find.byType(AnkirenScreen));
      expect(game.setup, AnkirenSetup.forLevel(level, ranked: true));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the stats row opens AnkiRen\'s page too', (tester) async {
      const s = S('en');
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      await tester.tap(inHub(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == s.ankirenOpenPage)));
      await tester.pump();
      await tester.pump(Motion.route);
      expect(find.byType(AnkirenPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('locked: the bar says what opens it', (tester) async {
      const s = S('en');
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

  group('ring', () {
    testWidgets('a swipe left brings the island on the right to the front, round and round; a swipe right goes back',
        (tester) async {
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      expect(frontOf(tester), SideTripIsle.ankiren);
      final order = <SideTripIsle>[];
      for (var i = 0; i < 4; i++) {
        await swipe(tester);
        order.add(frontOf(tester));
      }
      expect(order, [SideTripIsle.building, SideTripIsle.fuji, SideTripIsle.lighthouse, SideTripIsle.ankiren]);
      expect(turnOf(tester), 4);

      order.clear();
      for (var i = 0; i < 5; i++) {
        await swipe(tester, forward: false);
        order.add(frontOf(tester));
      }
      expect(order, [
        SideTripIsle.lighthouse,
        SideTripIsle.fuji,
        SideTripIsle.building,
        SideTripIsle.ankiren,
        SideTripIsle.lighthouse,
      ]);
      expect(turnOf(tester), -1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('one swipe turns one step, however hard; a short slow one settles back, a long slow one turns',
        (tester) async {
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      await tester.fling(inHub(find.byType(DojoScene)), const Offset(-370, 0), 6000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(turnOf(tester), 1);

      await tester.timedDrag(inHub(find.byType(DojoScene)), const Offset(-90, 0), const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(turnOf(tester), 1, reason: 'not far enough');

      await tester.timedDrag(inHub(find.byType(DojoScene)), const Offset(260, 0), const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(turnOf(tester), 0, reason: 'past halfway');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the turn follows the finger: the entries ride across on their swells', (tester) async {
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      final width = _users.size.width;
      final gesture = await tester.startGesture(tester.getCenter(inHub(find.byType(DojoScene))));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(Offset(-width / 4, 0));
      await tester.pump();
      final turn = turnOf(tester);
      expect(turn, closeTo(0.25 + 20 / width, 0.02));
      final body = tester.getRect(inHub(find.byType(SideTripBody)));
      expect(body.left, closeTo(Gaps.gutter - turn * width, 0.5), reason: '暗記練 washes out to the left');
      expect(tester.getRect(inHub(find.byType(SideTripSoonEntry)).first).left,
          closeTo(Gaps.gutter + (1 - turn) * width, 0.5), reason: 'the next rolls in from the right');
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(turnOf(tester), 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('between the front and the left an island shows twice, out past the left edge on the near arm '
        'as its blue twin comes in on the far arm, both under the finger, either way', (tester) async {
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      final width = _users.size.width;
      const ankiren = DojoRingLayout.ankiren;
      Rect? rectOf(String asset) => pictures(asset).evaluate().isEmpty ? null : tester.getRect(pictures(asset));
      final front = rectOf(ankiren.colour)!;
      final left = rectOf(DojoRingLayout.lighthouse.haze)!;
      expect(rectOf(ankiren.haze), isNull, reason: 'at rest each island shows once');
      expect(rectOf(DojoRingLayout.lighthouse.colour), isNull);

      // Drags to [turns] steps from [from], and the island's colour and blue
      // pictures then.
      Future<List<(Rect, Rect)>> drag(int from, List<double> turns) async {
        final gesture = await tester.startGesture(tester.getCenter(inHub(find.byType(DojoScene))));
        final way = turns.first > from ? -1.0 : 1.0;
        await gesture.moveBy(Offset(way * 20, 0));
        final seen = <(Rect, Rect)>[];
        for (final turn in turns) {
          await gesture.moveBy(Offset(-(turn - turnOf(tester)) * width, 0));
          await tester.pump();
          expect(turnOf(tester), closeTo(turn, 0.01));
          seen.add((rectOf(ankiren.colour)!, rectOf(ankiren.haze)!));
        }
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        return seen;
      }

      final out = await drag(0, [0.3, 0.7]);
      for (final (near, far) in out) {
        expect(near.left, lessThan(front.left), reason: 'leaving to the left');
        expect(near.width, greaterThan(front.width), reason: 'growing a little as it passes');
        expect(far.left, lessThan(0), reason: 'coming in from beyond the left edge');
        expect(far.width, lessThan(left.width * 1.01));
      }
      expect(out[1].$1.right, lessThan(out[0].$1.right), reason: 'the colour island follows the finger out');
      expect(out[1].$2.left, greaterThan(out[0].$2.left), reason: 'its twin follows the finger in');
      expect(out[1].$1.left, lessThan(-front.width / 2), reason: 'well past the left edge');
      expect(turnOf(tester), 1);
      expect(rectOf(ankiren.colour), isNull);
      expect(rectOf(ankiren.haze), left, reason: 'it rests in the left slot');

      final back = await drag(1, [0.7, 0.3]);
      expect(back[1].$1.left, greaterThan(back[0].$1.left), reason: 'the colour island comes back in');
      expect(back[1].$2.left, lessThan(back[0].$2.left), reason: 'its twin leaves');
      expect(back[0].$1.left, closeTo(out[1].$1.left, 0.5), reason: 'the same track both ways');
      expect(turnOf(tester), 0);
      expect(rectOf(ankiren.colour), front);
      expect(rectOf(ankiren.haze), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    for (final still in [false, true]) {
      testWidgets(
          still
              ? 'under reduced motion the paper waves stay put'
              : 'the paper waves slide slower the further back they are, and bob gently', (tester) async {
        if (still) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        }
        final p = await open(tester, _Hub.ranked, 'en');
        await openHub(tester, p, _users);
        final width = _users.size.width;
        const layers = DojoSceneLayout.backWaves;
        expect([for (final layer in layers) layer.speed], orderedEquals([...layers.map((l) => l.speed)]..sort()),
            reason: 'back to front, each faster than the one behind');
        expect(layers.last.speed, lessThan(1), reason: 'slower than the near swell');
        List<Rect> tiles(WaveLayer layer) => [
              for (var i = 0; i < pictures(layer.piece.asset).evaluate().length; i++)
                tester.getRect(pictures(layer.piece.asset).at(i)),
            ];
        for (final layer in layers) {
          expect([for (final r in tiles(layer)) r.left], [closeTo(-width, 0.5), closeTo(0, 0.5)],
              reason: 'two copies side by side, one filling the screen');
        }

        final tops = [for (final layer in layers) tiles(layer).first.top];
        await tester.pump(layers.first.period * 0.25);
        for (final (i, layer) in layers.indexed) {
          final bob = tiles(layer).first.top - tops[i];
          expect(bob.abs(), lessThanOrEqualTo(2 * layer.bob * width / DojoSceneLayout.width + 0.01), reason: 'gently');
          if (still) expect(bob, 0, reason: 'no bob under reduced motion');
        }
        if (!still) expect(tiles(layers.first).first.top, isNot(closeTo(tops.first, 0.05)), reason: 'it bobs');

        final gesture = await tester.startGesture(tester.getCenter(inHub(find.byType(DojoScene))));
        await gesture.moveBy(const Offset(-20, 0));
        await gesture.moveBy(Offset(-0.4 * width, 0));
        await tester.pump();
        final turn = turnOf(tester);
        final swells = [
          for (var i = 0; i < pictures(DojoSceneLayout.seaNear.asset).evaluate().length; i++)
            tester.getRect(pictures(DojoSceneLayout.seaNear.asset).at(i)).left,
        ];
        for (final layer in layers) {
          final slid = still ? 0.0 : -layer.speed * turn * width;
          for (final r in tiles(layer)) {
            final copies = (r.left - slid) / width;
            expect(copies - copies.round(), closeTo(0, 0.5 / width),
                reason: '${layer.piece.asset} slides ${layer.speed} of the way, its copies a screen apart');
          }
        }
        if (!still) expect(swells, contains(closeTo(-turn * width, 0.5)), reason: 'the near swell rides the finger');
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a swipe that starts on the burst turns the ring and starts no game', (tester) async {
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      await tester.fling(inHub(find.byType(PageBurst)), const Offset(-200, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(frontOf(tester), SideTripIsle.building);
      expect(find.byType(AnkirenScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('each step: its entry in front, labels on the front and right islands, its torii', (tester) async {
      const s = S('en');
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      int tags() => inHub(find.text(s.sideTripsBuilding)).evaluate().length;

      expect(inHub(find.byType(SideTripBody)).hitTestable(), findsOneWidget);
      expect(inHub(find.byType(SideTripSoonEntry)).hitTestable(), findsNothing);
      expect(tags(), 1, reason: 'the building site on the right');
      expect(pictures(DojoRingLayout.nobori.asset), findsOneWidget, reason: "暗記練's banner is its label");
      expect(pictures(DojoSceneLayout.toriiOpen.asset), findsOneWidget);

      for (final (front, labels, banner) in [
        (SideTripIsle.building, 2, false),
        (SideTripIsle.fuji, 2, false),
        (SideTripIsle.lighthouse, 1, true),
      ]) {
        await swipe(tester);
        expect(frontOf(tester), front);
        expect(inHub(find.byType(SideTripSoonEntry)).hitTestable(), findsOneWidget, reason: '$front');
        expect(inHub(find.byType(SideTripBody)).hitTestable(), findsNothing, reason: '$front');
        expect(inHub(find.text(s.sideTripsSoonLine)).hitTestable(), findsOneWidget, reason: 'one entry shows');
        expect(tags(), labels, reason: '$front');
        expect(pictures(DojoRingLayout.nobori.asset), banner ? findsOneWidget : findsNothing, reason: '$front');
        expect(pictures(DojoSceneLayout.toriiOpen.asset), findsNothing, reason: 'padlocked for $front');
        expect(pictures(DojoSceneLayout.toriiLocked.asset), findsOneWidget, reason: '$front');
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the boat drifts with the turn, then springs back', (tester) async {
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      double drift() => tester.widget<DojoBoat>(find.byType(DojoBoat)).drift.value;
      final gesture = await tester.startGesture(tester.getCenter(inHub(find.byType(DojoScene))));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-220, 0));
      await tester.pump();
      expect(drift(), closeTo(turnOf(tester), 1e-9), reason: 'drifts with the turn: left, as the swipe');
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(turnOf(tester), 1);
      expect(drift(), isNot(closeTo(0, 0.01)), reason: 'still on its way back');
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      expect(drift(), closeTo(0, 1e-3));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the tab comes back with 暗記練 in front', (tester) async {
      const s = S('en');
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      await swipe(tester);
      await swipe(tester);
      expect(frontOf(tester), SideTripIsle.fuji);
      await tester.tap(tabButton(s.home));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(tabButton(s.sideTrips));
      await tester.pump();
      expect(turnOf(tester), 0);
      expect(inHub(find.byType(SideTripBody)).hitTestable(), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('screen readers hear the island and can turn the ring', (tester) async {
      const s = S('en');
      final semantics = tester.ensureSemantics();
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      void act(SideTripIsle shown, String action) => tester.semantics.performAction(
            find.semantics.byLabel(s.isleName(shown)),
            SemanticsAction.customAction,
            args: CustomSemanticsAction.getIdentifier(CustomSemanticsAction(label: action)),
          );

      expect(find.semantics.byLabel(s.isleName(SideTripIsle.ankiren)), findsOne);
      act(SideTripIsle.ankiren, s.sideTripsNextIsland);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(frontOf(tester), SideTripIsle.building);
      expect(find.semantics.byLabel(s.isleName(SideTripIsle.building)), findsOne);
      act(SideTripIsle.building, s.sideTripsPreviousIsland);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      act(SideTripIsle.ankiren, s.sideTripsPreviousIsland);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(frontOf(tester), SideTripIsle.lighthouse);
      expect(find.semantics.byLabel(s.isleName(SideTripIsle.lighthouse)), findsOne);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('under reduced motion a swipe crossfades to the next island; nothing drifts', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await open(tester, _Hub.ranked, 'en');
      await openHub(tester, p, _users);
      double drift() => tester.widget<DojoBoat>(find.byType(DojoBoat)).drift.value;
      final body = tester.getRect(inHub(find.byType(SideTripBody)));

      final gesture = await tester.startGesture(tester.getCenter(inHub(find.byType(DojoScene))));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(turnOf(tester), 0, reason: 'nothing follows the finger');
      expect(tester.getRect(inHub(find.byType(SideTripBody))), body);
      await gesture.up();
      await tester.pump();
      expect(turnOf(tester), 1);
      await tester.pump(DojoRingMotion.crossfade ~/ 2);
      expect(tester.getRect(inHub(find.byType(SideTripBody))), body, reason: 'fading where it rests');
      expect(drift(), 0);
      await tester.pump(DojoRingMotion.crossfade);
      expect(frontOf(tester), SideTripIsle.building);
      expect(inHub(find.byType(SideTripSoonEntry)).hitTestable(), findsOneWidget);
      expect(drift(), 0, reason: 'the boat stays still');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    for (final still in [false, true]) {
      testWidgets(still ? 'under reduced motion the clouds stay put' : 'the clouds drift slowly and come round',
          (tester) async {
        if (still) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        }
        final p = await open(tester, _Hub.ranked, 'en');
        await openHub(tester, p, _users);
        final clouds = [for (final cloud in DojoSceneLayout.clouds) pictures(cloud.piece.asset)];
        List<double> lefts() => [for (final c in clouds) tester.getRect(c).left];
        final start = lefts();
        await tester.pump(const Duration(seconds: 1));
        final second = lefts();
        await tester.pump(DojoSceneLayout.cloudLoop * 0.3);
        final later = lefts();
        await tester.pump(DojoSceneLayout.cloudLoop - DojoSceneLayout.cloudLoop * 0.3 - const Duration(seconds: 1));
        final round = lefts();
        for (var i = 0; i < clouds.length; i++) {
          if (still) {
            expect([second[i], later[i]], everyElement(start[i]));
          } else {
            expect(second[i] - start[i], inInclusiveRange(0, 4), reason: 'slowly');
            expect(later[i], isNot(closeTo(start[i], 1)));
            expect(round[i], closeTo(start[i], 0.5), reason: 'round again after a loop');
          }
        }
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets(still ? 'under reduced motion the sun keeps still, eyes open' : 'the sun bobs, turns its rays and blinks',
          (tester) async {
        if (still) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        }
        final p = await open(tester, _Hub.ranked, 'en');
        await openHub(tester, p, _users);
        final order = [for (final e in inHub(find.byType(ScenePicture)).evaluate()) (e.widget as ScenePicture).asset];
        expect(order.indexOf(DojoSceneLayout.sky.asset), lessThan(order.indexOf(DojoSceneLayout.sunRays.asset)));
        expect(order.indexOf(DojoSceneLayout.sunRays.asset), lessThan(order.indexOf(DojoSceneLayout.sunFace.asset)));
        for (final cloud in DojoSceneLayout.clouds) {
          expect(order.indexOf(DojoSceneLayout.sunBlink.asset), lessThan(order.indexOf(cloud.piece.asset)),
              reason: 'the clouds pass in front of the sun');
        }
        // the open-eyed face, found even while the blink frame hides it
        final face = find.descendant(
            of: find.byType(SideTripsScreen),
            matching: find.byWidgetPredicate((w) => w is ScenePicture && w.asset == DojoSceneLayout.sunFace.asset,
                skipOffstage: false),
            skipOffstage: false);
        final rays = pictures(DojoSceneLayout.sunRays.asset);
        final start = (face: tester.getCenter(face), rays: tester.getTopLeft(rays));
        final heights = <double>{};
        final corners = <Offset>{};
        var blinked = false;
        for (var t = Duration.zero; t < DojoSceneLayout.sunPeriod; t += DojoSceneLayout.sunStep) {
          await tester.pump(DojoSceneLayout.sunStep);
          heights.add(tester.getCenter(face).dy);
          corners.add(tester.getTopLeft(rays));
          blinked |= tester.widget<IndexedStack>(find.ancestor(of: face, matching: find.byType(IndexedStack)).first).index == 1;
        }
        if (still) {
          expect(heights, {start.face.dy});
          expect(corners, {start.rays});
          expect(blinked, isFalse);
        } else {
          final k = _users.size.width / DojoSceneLayout.width;
          final bob = heights.reduce(math.max) - heights.reduce(math.min);
          expect(bob, inInclusiveRange(1, 2 * DojoSceneLayout.sunLift * k + 0.5), reason: 'a little');
          expect(corners.length, greaterThan(1), reason: 'the rays turn');
          expect(blinked, isTrue);
        }
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('every coming-soon entry fits under its crest', (tester) async {
      for (final (phone, lang, fontScale) in [(_narrow, 'ja', 1.3), (_users, 'en', 1.3), (_wide, 'en', 1.0)]) {
        final p = await open(tester, _Hub.ranked, lang);
        await openHub(tester, p, phone, fontScale: fontScale);
        await swipe(tester);
        expect(tester.takeException(), isNull);
        final entry = inHub(find.byType(SideTripSoonEntry)).hitTestable();
        expectShown(tester, entry, phone);
        expect(tester.getRect(entry).top, greaterThanOrEqualTo(crestBottom(tester, phone)));
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('unlock moment', () {
    GateState gate(WidgetTester tester) => tester.widget<DojoScene>(find.byType(DojoScene)).gate;

    testWidgets('暗記練 seen locked opens once, with the chains\' snap and a toast; then it stays open', (tester) async {
      const s = S('en');
      final p = await open(tester, _Hub.locked, 'en');
      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards).take(11)));
      await openHub(tester, p, _users);
      expect(gate(tester), GateState.locked);
      expect(p.sideTripsSeenLocked, {SideTrip.ankiren});

      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards + 11).take(2)));
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

    testWidgets('暗記練 opening while another island is in front waits until it comes back', (tester) async {
      final p = await open(tester, _Hub.locked, 'en');
      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards).take(11)));
      await openHub(tester, p, _users);
      await swipe(tester);
      expect(frontOf(tester), SideTripIsle.building);
      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards + 11).take(2)));
      await tester.pump();
      await tester.pump(DojoUnlockMotion.unlock);
      expect(heard.played, isEmpty);
      expect(p.sideTripsSeenLocked, {SideTrip.ankiren}, reason: 'not shown yet');

      await swipe(tester, forward: false);
      expect(frontOf(tester), SideTripIsle.ankiren);
      expect(gate(tester), GateState.opening);
      await tester.pump();
      await tester.pump(DojoUnlockMotion.unlock);
      expect(heard.played, contains(Sfx.ratingBreak));
      await tester.pump(DojoUnlockMotion.unlock);
      await tester.pump();
      expect(gate(tester), GateState.open);
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
      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards).take(11)));
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await openHub(tester, p, _users);
      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards + 11).take(2)));
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
      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards).take(11)));
      await openHub(tester, p, _users);
      await tester.runAsync(() => remember(p, journeyOrder.skip(_lockedCards + 11).take(2)));
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

    testWidgets('ring', (tester) async {
      final p = await open(tester, _Hub.ranked, 'ja');
      await openHub(tester, p, _users);
      await precacheArt(tester);
      final centre = tester.getCenter(inHub(find.byType(DojoScene)));
      for (final (name, by) in [('back_half', 0.5), ('fwd_30', -0.3), ('fwd_60', -0.6)]) {
        final gesture = await tester.startGesture(centre);
        await gesture.moveBy(Offset(by.sign * 20, 0));
        await gesture.moveBy(Offset(by * _users.size.width - by.sign * 20, 0));
        await tester.pump();
        await precacheArt(tester);
        await capture(tester, _users, 'ring_$name');
        await gesture.moveBy(Offset(-by * _users.size.width, 0));
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));
      }
      for (var step = 1; step <= 3; step++) {
        await swipe(tester);
        await tester.pump(const Duration(seconds: 3));
        await precacheArt(tester);
        await capture(tester, _users, 'ring_step$step');
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
