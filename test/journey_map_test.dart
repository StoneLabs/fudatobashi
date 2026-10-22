// The islands map on journey Home: it scrolls in its box, shows the boat
// (and the current island, if there is room) clear of the labels over its top
// and of the strip or banner under it wherever the boat is, and a drag pans
// it up and down and leaves it where it was put.
//
// With RENDER_SCREENS=1 it also renders Home to build/screens/journey_map/.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart' show ItemKey;
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/exam_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/exam_strip.dart';
import 'package:fudatobashi/ui/home/journey_pan.dart';
import 'package:fudatobashi/ui/home/journey_state.dart';
import 'package:fudatobashi/ui/home/switch_banner.dart';
import 'package:fudatobashi/ui/home/today_box.dart';
import 'package:fudatobashi/ui/islands/island_map.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

/// What sits under the map in its panel.
enum _Footer { none, exam, banner }

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

  final all = [for (final p in poems.all) CardRef(p.id)];

  PlaySession play(List<CardRef> cards) {
    final s = PlaySession(cards);
    var t = const Duration(seconds: 100);
    for (var i = 0; i < cards.length; i++) {
      s.revealed(t);
      t += const Duration(milliseconds: 900);
      s.commit(responseTs: t, commitTs: t, outcome: Outcome.known);
    }
    return s;
  }

  // A journey player with the boat sailing into island [index]: every
  // earlier island unlocked and the first card of this one, or all ten and
  // finished for the last; every card swiped once so the exam is open (the
  // strip), or passed too (the banner), as [footer] says. The first island
  // and some of the second are unlocked from the start, so [index] is at
  // least 1.
  Future<Progress> player(WidgetTester tester, int index, _Footer footer, {String lang = 'en'}) async {
    final last = index == archipelago.islands.length - 1;
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.journey);
      if (footer != _Footer.none) {
        await p.recordRun(play(all), PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: [for (final c in all) c.poemId]),
            DateTime.now());
      }
      if (footer == _Footer.banner) {
        await p.recordRun(play(all), const PlayConfig(mode: PlayMode.exam), DateTime.now(), tobi: const Duration(minutes: 5));
      }
      await p.noteExamIntroShown();
      if (last) {
        await p.switchToAllKnown();
        await p.setLearningMode(LearningMode.journey);
      }
    });
    if (!last) {
      for (final isl in archipelago.islands.take(index + 1)) {
        final ids = fudaSets['initial:${isl.name}'].poemIds;
        for (final id in isl.index < index ? ids : ids.take(1)) {
          p.trainer.items[ItemKey(id, false)]!.unlocked = true;
        }
      }
    }
    return p;
  }

  Future<void> onPhone(WidgetTester tester, Progress p, Screen phone, {double fontScale = 1}) async {
    useScreen(tester, phone, fontScale: fontScale);
    await tester.binding.setSurfaceSize(phone.size);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  }

  // Lets a fling or a move to the boat run out. The sea's tide never stops,
  // so the frames are pumped rather than settled.
  Future<void> glide(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
  }

  // A point in the map's box, clear of the labels and of what is under it.
  Offset inMap(WidgetTester tester) {
    final frame = tester.getRect(find.byType(SingleChildScrollView));
    return Offset(frame.right - 40, frame.top + 100);
  }

  group('the pan', () {
    // Every island, boxes from the least that keeps the boat clear up to a
    // tall one, with and without something under the map.
    test('puts the boat clear of the labels and the box bottom, wherever it is', () {
      for (final labels in [HomeLayout.mapCountTop + 40, HomeLayout.mapCountTop + 54]) {
        for (final overhang in [0.0, ExamStripStyle.mapOverhang]) {
          for (final height in [170.0, 200.0, 240.0, 300.0, 420.0]) {
            for (final width in [320.0, 360.0, 412.0]) {
              final pan = JourneyPan(box: Size(width, height), map: archipelago.size, labels: labels, overhang: overhang);
              final why = '$width × $height, labels $labels, overhang $overhang';
              expect(pan.height, greaterThanOrEqualTo(pan.frame), reason: why);
              for (final isl in archipelago.islands) {
                final boat = IslandMap.boatPosition(archipelago.islands, isl.index);
                final offset = pan.offsetFor(JourneyPan.focuses(isl, boat));
                expect(offset, inInclusiveRange(0, pan.maxOffset), reason: why);
                final sprite = IslandMap.boatRect(boat);
                final top = labels + sprite.top * pan.scale - offset, bottom = labels + sprite.bottom * pan.scale - offset;
                expect(top, greaterThanOrEqualTo(labels - 0.01), reason: '${isl.name}: $why');
                expect(bottom, lessThanOrEqualTo(height - JourneyView.bottomGap + 0.01), reason: '${isl.name}: $why');
                final left = (sprite.left - pan.viewport.left) * pan.scale;
                expect(left, greaterThanOrEqualTo(0), reason: '${isl.name}: $why');
                expect(left + sprite.width * pan.scale, lessThanOrEqualTo(width), reason: '${isl.name}: $why');
              }
            }
          }
        }
      }
    });

    test('keeps the current island in view as well when the box has room for both', () {
      final pan = JourneyPan(box: const Size(358, 240), map: archipelago.size, labels: 84, overhang: 0);
      for (final isl in archipelago.islands) {
        final boat = IslandMap.boatPosition(archipelago.islands, isl.index);
        final offset = pan.offsetFor(JourneyPan.focuses(isl, boat));
        final top = 84 + isl.bounds.top * pan.scale - offset, bottom = 84 + isl.bounds.bottom * pan.scale - offset;
        expect(top, greaterThanOrEqualTo(84 - 0.01), reason: isl.name);
        expect(bottom, lessThanOrEqualTo(240 - JourneyView.bottomGap + 0.01), reason: isl.name);
      }
    });
  });

  group('on Home', () {
    // The boat's box on screen, from the map's own place and viewport.
    Rect boatOnScreen(WidgetTester tester, Progress p) {
      final map = tester.widget<IslandMap>(find.byType(IslandMap));
      final at = tester.getRect(find.byType(IslandMap));
      final scale = at.width / map.viewport!.width;
      final boat = IslandMap.boatRect(map.boat!);
      return Rect.fromLTWH(at.left + (boat.left - map.viewport!.left) * scale, at.top + (boat.top - map.viewport!.top) * scale,
          boat.width * scale, boat.height * scale);
    }

    // The map's visible part: down to what is under it, and the label stack
    // laid over its top.
    ({Rect box, double labelsBottom}) visible(WidgetTester tester, _Footer footer) {
      final frame = tester.getRect(find.byType(SingleChildScrollView));
      final below = switch (footer) {
        _Footer.none => null,
        _Footer.exam => find.byType(ExamStrip),
        _Footer.banner => find.byType(SwitchBanner),
      };
      final bottom = below == null ? frame.bottom : tester.getRect(below).top;
      final count = find.byWidgetPredicate((w) => w is Positioned && w.top == HomeLayout.mapCountTop);
      return (box: Rect.fromLTRB(frame.left, frame.top, frame.right, bottom), labelsBottom: tester.getRect(count).bottom);
    }

    // The boat is clear of the labels and of what is under the map, when the
    // box has room for that at all: its clear part is as tall as the boat.
    void expectBoatClear(WidgetTester tester, Progress p, _Footer footer, String why, {bool roomy = false}) {
      final boat = boatOnScreen(tester, p);
      final seen = visible(tester, footer);
      final room = seen.box.bottom - JourneyView.bottomGap - seen.labelsBottom;
      if (roomy) expect(room, greaterThanOrEqualTo(boat.height), reason: '$why: room for the boat');
      if (room < boat.height) return;
      expect(boat.top, greaterThanOrEqualTo(seen.labelsBottom - 0.5), reason: '$why: under the labels $boat');
      expect(boat.bottom, lessThanOrEqualTo(seen.box.bottom + 0.5), reason: '$why: above the strip $boat');
      expect(boat.left, greaterThanOrEqualTo(seen.box.left - 0.5), reason: why);
      expect(boat.right, lessThanOrEqualTo(seen.box.right + 0.5), reason: why);
    }

    testWidgets('the boat is in view at the last island with the exam strip showing', (tester) async {
      final p = await player(tester, archipelago.islands.length - 1, _Footer.exam);
      expect(JourneyState.of(p).current, archipelago.islands.length - 1);
      await onPhone(tester, p, usersPhone);
      expect(find.byType(ExamStrip), findsOneWidget);
      expectBoatClear(tester, p, _Footer.exam, 'last island, strip', roomy: true);
    });

    for (final phone in [usersPhone, narrowPhone]) {
      for (final fontScale in [1.0, 1.3]) {
        for (final lang in ['en', 'ja']) {
          testWidgets('the boat is in view at the second, a middle and the last island (${phone.name}, $fontScale, $lang)',
              (tester) async {
            for (final (index, footer) in [
              (1, _Footer.none),
              (4, _Footer.none),
              (8, _Footer.exam),
              (10, _Footer.exam),
              (10, _Footer.banner),
              (10, _Footer.none),
            ]) {
              final p = await player(tester, index, footer, lang: lang);
              await onPhone(tester, p, phone, fontScale: fontScale);
              expect(JourneyState.of(p).current, index);
              expectBoatClear(tester, p, footer, '${phone.name} $fontScale $lang island $index $footer', roomy: phone == usersPhone);
              await tester.pumpWidget(const SizedBox());
            }
          });
        }
      }
    }

    testWidgets('the labels stay inside the sea kept clear for them, without much to spare', (tester) async {
      for (final fontScale in [1.0, 1.3, 2.0]) {
        final p = await player(tester, 5, _Footer.none);
        await onPhone(tester, p, usersPhone, fontScale: fontScale);
        final top = tester.getRect(find.byType(SingleChildScrollView)).top;
        final kept = JourneyPan.labelsBottom(TextScaler.linear(fontScale));
        final used = visible(tester, _Footer.none).labelsBottom - top;
        expect(used, lessThanOrEqualTo(kept), reason: 'scale $fontScale');
        expect(kept - used, lessThan(10), reason: 'scale $fontScale');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a vertical drag pans the map, stops at both ends, and leaves it where it is put', (tester) async {
      final p = await player(tester, 5, _Footer.none);
      await onPhone(tester, p, usersPhone);
      final frame = tester.getRect(find.byType(SingleChildScrollView));
      final today = tester.getRect(find.byType(TodayBox));
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable)).position;
      final start = scroll.pixels;
      expect(start, inExclusiveRange(0, scroll.maxScrollExtent), reason: 'the boat is mid-route: room both ways');
      expect(tester.getRect(find.byType(IslandMap)).top, moreOrLessEquals(frame.top - start, epsilon: 0.5));

      await tester.dragFrom(inMap(tester), const Offset(0, -30));
      await tester.pump(const Duration(seconds: 1));
      expect(scroll.pixels, moreOrLessEquals(start + 30, epsilon: 0.5), reason: 'the map follows the finger');
      expect(tester.getRect(find.byType(TodayBox)), today, reason: 'Home itself does not move');

      await tester.flingFrom(inMap(tester), const Offset(0, 500), 2000);
      await glide(tester);
      expect(scroll.pixels, 0, reason: 'the top end');
      expect(tester.getRect(find.byType(IslandMap)).top, moreOrLessEquals(frame.top, epsilon: 0.5));

      await tester.flingFrom(inMap(tester), const Offset(0, -900), 3000);
      await glide(tester);
      expect(scroll.pixels, scroll.maxScrollExtent, reason: 'the bottom end');
      final end = tester.getRect(find.byType(IslandMap));
      expect(end.bottom, moreOrLessEquals(frame.bottom, epsilon: 0.5));
      expect(tester.getRect(find.byType(TodayBox)), today);

      await tester.pump(const Duration(seconds: 30));
      expect(tester.getRect(find.byType(IslandMap)), end, reason: 'it stays where it was left');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a drag on the strip does not pan the map, and a tap still opens the exam', (tester) async {
      final p = await player(tester, archipelago.islands.length - 1, _Footer.exam);
      await onPhone(tester, p, usersPhone);
      final before = tester.getRect(find.byType(IslandMap));
      await tester.drag(find.byType(ExamStrip), const Offset(0, -40), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getRect(find.byType(IslandMap)), before);
      await tester.tap(find.byType(ExamStrip));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(const S('en').examStart), findsOneWidget);
    });

    testWidgets('the view goes to the new boat when it moves, and not for other changes', (tester) async {
      final p = await player(tester, 3, _Footer.none);
      await onPhone(tester, p, usersPhone);
      await tester.dragFrom(inMap(tester), const Offset(0, 30));
      await tester.pump(const Duration(seconds: 1));
      final dragged = tester.getRect(find.byType(IslandMap)).top;
      p.trainer.items[ItemKey(fudaSets['initial:${archipelago.islands[3].name}'].poemIds.first, false)]!.unlocked = true;
      await tester.runAsync(() => p.updateSettings(p.settings));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getRect(find.byType(IslandMap)).top, moreOrLessEquals(dragged, epsilon: 0.5), reason: 'same boat');

      final next = fudaSets['initial:${archipelago.islands[3].name}'].poemIds;
      for (final id in next) {
        p.trainer.items[ItemKey(id, false)]!.unlocked = true;
      }
      for (final id in fudaSets['initial:${archipelago.islands[4].name}'].poemIds.take(1)) {
        p.trainer.items[ItemKey(id, false)]!.unlocked = true;
      }
      await tester.runAsync(() => p.updateSettings(p.settings));
      await glide(tester);
      expect(JourneyState.of(p).current, 4);
      expectBoatClear(tester, p, _Footer.none, 'after sailing on');
    });
  });

  group('renders', skip: !renderScreens, () {
    for (final lang in ['en', 'ja']) {
      for (final (phone, fontScale) in [(usersPhone, 1.0), (narrowPhone, 1.3)]) {
        testWidgets('home_${phone.name}_${lang}_$fontScale', (tester) async {
          for (final (index, footer) in [
            (1, _Footer.none),
            (4, _Footer.none),
            (10, _Footer.exam),
            (10, _Footer.banner),
            (10, _Footer.none),
          ]) {
            final p = await player(tester, index, footer, lang: lang);
            await onPhone(tester, p, phone, fontScale: fontScale);
            await captureScreen(tester, 'journey_map/home_${index}_${footer.name}', lang: lang);
            if (index == 10 && footer == _Footer.exam) {
              await tester.dragFrom(inMap(tester), const Offset(0, 90));
              await tester.pump(const Duration(seconds: 1));
              await captureScreen(tester, 'journey_map/home_${index}_${footer.name}_dragged', lang: lang);
            }
            await tester.pumpWidget(const SizedBox());
          }
        });
      }
    }
  });
}
