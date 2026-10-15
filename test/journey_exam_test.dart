// Journey Home's graduation exam strip (hidden until open, open, cooling
// down) and Tobi pointing it out as it opens, the banner that replaces it
// once the exam is passed and the question behind it, and the rank ladder
// before there is a rank: what each shows and does, and that each fits 360
// and 384 dp phones at text scale 1.0 and 1.3 in English and Japanese.
//
// With RENDER_SCREENS=1 it also renders them to build/screens/ (journey_*,
// rank_*).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart' show ItemKey;
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/exam_strings.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/ranked_strings.dart';
import 'package:fudatobashi/l10n/stats_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/home/exam_strip.dart';
import 'package:fudatobashi/ui/home/switch_banner.dart';
import 'package:fudatobashi/ui/manga/phrases.dart';
import 'package:fudatobashi/ui/rank/rank_screen.dart';
import 'package:fudatobashi/ui/tour/tour_overlay.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

/// A phone: its size in dp and its pixels per dp, with a 28 dp status bar
/// and a 48 dp navigation bar.
typedef _Phone = ({String name, Size size, double dpr});

const _narrow = (name: '360', size: Size(360, 780), dpr: 3.0);
const _users = (name: '384', size: Size(384, 832), dpr: 2.8125);
const _statusBar = 28.0, _navBar = 48.0;

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

/// Where the exam stands on journey Home.
enum _Stage { locked, open, cooldown, passed }

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

  /// [cards] each played in 900 ms, all known.
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

  /// A toured journey player 27 cards in, at [stage]: 37 cards never swiped
  /// while locked; a try 17:50 ago while cooling down; passed with Tobi at
  /// 5:00. Tobi has pointed the open exam out already unless [intro].
  Future<Progress> open(WidgetTester tester, _Stage stage,
      {String lang = 'en', LearningMode? mode, bool intro = false}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      p.tabsAlwaysOpen = true;
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.journey);
      final swiped = stage == _Stage.locked ? all.take(63).toList() : all;
      await p.recordRun(play(swiped), PlayConfig(mode: PlayMode.free, setIds: const [], cardIds: [for (final c in swiped) c.poemId]),
          DateTime.now());
      if (stage == _Stage.cooldown) await p.noteExamStarted(DateTime.now().subtract(const Duration(minutes: 17, seconds: 50)));
      if (stage == _Stage.passed) {
        await p.recordRun(play(all), const PlayConfig(mode: PlayMode.exam), DateTime.now(), tobi: const Duration(minutes: 5));
      }
      if (mode != null) await p.setLearningMode(mode);
      if (!intro) await p.noteExamIntroShown();
    });
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    for (final id in ids.take(27)) {
      p.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    return p;
  }

  // [p]'s Home on [phone]. All-known Home has its own layout tests, so
  // [checkHome] false leaves it to them.
  Future<void> onPhone(WidgetTester tester, Progress p, _Phone phone, {double fontScale = 1, bool checkHome = true}) async {
    final bars = FakeViewPadding(top: _statusBar * phone.dpr, bottom: _navBar * phone.dpr);
    tester.view
      ..devicePixelRatio = phone.dpr
      ..physicalSize = phone.size * phone.dpr
      ..padding = bars
      ..viewPadding = bars;
    tester.platformDispatcher.textScaleFactorTestValue = fontScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(phone.size);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    final error = tester.takeException();
    if (checkHome) expect(error, isNull);
  }

  // [text] as shown with its phrase marks (`Phrases`), which only change
  // where its lines may break.
  Finder phrase(String text) => find.byWidgetPredicate((w) =>
      w is RichText && w.text.toPlainText().replaceAll(RegExp('[\u200b\u2060]'), '') == Phrases.spoken(text));

  // The strip and the banner sit inside the map panel, clear of its edges.
  void expectInsideMap(WidgetTester tester, Finder footer) {
    final map = tester.getRect(find.ancestor(of: footer, matching: find.byType(ClipPath)).first);
    final box = tester.getRect(footer);
    expect(box.left, greaterThanOrEqualTo(map.left - 0.5));
    expect(box.right, lessThanOrEqualTo(map.right + 0.5));
    expect(box.bottom, lessThanOrEqualTo(map.bottom + 0.5));
  }

  group('exam strip', () {
    testWidgets('hidden until every card is swiped once, with no word from Tobi', (tester) async {
      final p = await open(tester, _Stage.locked, intro: true);
      expect(p.exam().cardsLeft, 37);
      expect(p.examIntroDue, isFalse);
      await onPhone(tester, p, _users);
      expect(find.byType(ExamStrip), findsNothing);
      expect(find.byType(TourOverlay), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('as it opens, Tobi points it out once; a tap away closes him', (tester) async {
      final p = await open(tester, _Stage.open, intro: true);
      expect(p.examIntroDue, isTrue);
      await onPhone(tester, p, _users);
      const s = S('en');
      expect(find.byType(ExamStrip), findsOneWidget);
      expect(find.byType(TourOverlay), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(phrase(s.examIntro), findsOneWidget);
      await tester.tapAt(const Offset(60, 300));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TourOverlay), findsNothing);
      expect(p.examIntroDue, isFalse, reason: 'shown once');
      expect(find.text(s.examStart), findsNothing, reason: 'a tap away only closes it');

      await tester.runAsync(p.replayExamIntro);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TourOverlay), findsOneWidget, reason: "developer mode's replay");
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a tap on the strip under Tobi's word opens the exam's question", (tester) async {
      final p = await open(tester, _Stage.open, intro: true);
      await onPhone(tester, p, _users);
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(ExamStrip), warnIfMissed: false);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TourOverlay), findsNothing);
      expect(p.examIntroDue, isFalse);
      expect(find.text(S('en').examStart), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('open: OPEN, with the miss penalty', (tester) async {
      final p = await open(tester, _Stage.open);
      expect(p.exam().canStart, isTrue);
      await onPhone(tester, p, _users);
      const s = S('en');
      expect(find.text(s.examOpenPill), findsOneWidget);
      expect(find.text(s.examPenalty(10)), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('cooling down: the countdown ticks every second', (tester) async {
      final p = await open(tester, _Stage.cooldown);
      await onPhone(tester, p, _users);
      const s = S('en');
      expect(find.text(s.examTryAgainIn), findsOneWidget);
      String shown() => tester.widgetList<Text>(find.descendant(of: find.byType(ExamStrip), matching: find.byType(Text)))
          .map((t) => t.data ?? '')
          .firstWhere((t) => RegExp(r'^\d+:\d\d$').hasMatch(t));
      expect(shown(), startsWith('42:'));
      final before = shown();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100)));
      await tester.pump(const Duration(seconds: 1));
      expect(shown(), isNot(before));
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['en', 'ja']) {
      for (final phone in [_narrow, _users]) {
        for (final fontScale in [1.0, 1.3]) {
          final tag = '${lang}_${phone.name}_$fontScale';
          testWidgets('every stage fits ($tag)', (tester) async {
            for (final stage in [_Stage.open, _Stage.cooldown]) {
              final p = await open(tester, stage, lang: lang);
              await onPhone(tester, p, phone, fontScale: fontScale);
              expectInsideMap(tester, find.byType(ExamStrip));
              await _capture(tester, 'journey_exam_${stage.name}_$tag');
              await tester.pumpWidget(const SizedBox());
            }
            final p = await open(tester, _Stage.open, lang: lang, intro: true);
            await onPhone(tester, p, phone, fontScale: fontScale);
            await tester.pump(const Duration(seconds: 5));
            expect(tester.takeException(), isNull);
            await _capture(tester, 'journey_exam_intro_$tag');
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  });

  group('after passing', () {
    testWidgets('the banner replaces the strip; its question closes on the backdrop, or switches', (tester) async {
      final p = await open(tester, _Stage.passed);
      expect(p.switchBannerShown, isTrue);
      await onPhone(tester, p, _users);
      const s = S('en');
      expect(find.byType(ExamStrip), findsNothing);
      expect(find.byType(SwitchBanner), findsOneWidget);

      await tester.tap(find.byType(SwitchBanner));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(phrase(s.switchTitle), findsOneWidget);
      expect(phrase(s.switchBody), findsOneWidget);
      await tester.tapAt(const Offset(40, 120));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(phrase(s.switchTitle), findsNothing);
      expect(p.trainer.config.learningMode, LearningMode.journey);
      expect(find.byType(SwitchBanner), findsOneWidget, reason: 'closing it keeps the banner');

      await tester.tap(find.byType(SwitchBanner));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        await tester.tap(find.text(s.switchNow));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(p.trainer.config.learningMode, LearningMode.allKnown);
      expect(find.byType(SwitchBanner), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the ✕ puts the banner away, and nothing takes its place', (tester) async {
      final p = await open(tester, _Stage.passed);
      await onPhone(tester, p, _users);
      await tester.runAsync(() async {
        await tester.tap(find.bySemanticsLabel(const S('en').close));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(p.switchBannerShown, isFalse);
      expect(find.byType(SwitchBanner), findsNothing);
      expect(find.byType(ExamStrip), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['en', 'ja']) {
      for (final phone in [_narrow, _users]) {
        for (final fontScale in [1.0, 1.3]) {
          final tag = '${lang}_${phone.name}_$fontScale';
          testWidgets('the banner and its question fit ($tag)', (tester) async {
            final p = await open(tester, _Stage.passed, lang: lang);
            await onPhone(tester, p, phone, fontScale: fontScale);
            expectInsideMap(tester, find.byType(SwitchBanner));
            await _capture(tester, 'journey_banner_$tag');
            await tester.tap(find.byType(SwitchBanner));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
            expect(tester.takeException(), isNull);
            expect(phrase(S(lang).switchLater), findsOneWidget);
            await _capture(tester, 'journey_switch_$tag');
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  });

  group('rank ladder before there is a rank', () {
    Future<void> openLadder(WidgetTester tester, Progress p, String lang) async {
      final s = S(lang);
      await tester.tap(find.text(s.stats));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(s.rank));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.byType(RankScreen), findsOneWidget);
    }

    for (final lang in ['en', 'ja']) {
      for (final phone in [_narrow, _users]) {
        for (final fontScale in [1.0, 1.3]) {
          final tag = '${lang}_${phone.name}_$fontScale';
          testWidgets('journey: locked until the exam, then offers the switch ($tag)', (tester) async {
            final s = S(lang);
            final p = await open(tester, _Stage.open, lang: lang);
            await onPhone(tester, p, phone, fontScale: fontScale);
            await openLadder(tester, p, lang);
            expect(phrase(s.rankLockedTitle), findsOneWidget);
            expect(find.text(s.youTag), findsNothing);
            await _capture(tester, 'rank_locked_$tag');
            await tester.pumpWidget(const SizedBox());

            final passed = await open(tester, _Stage.passed, lang: lang);
            await onPhone(tester, passed, phone, fontScale: fontScale);
            await openLadder(tester, passed, lang);
            expect(phrase(s.rankLockedSwitchButton), findsOneWidget);
            await _capture(tester, 'rank_locked_graduated_$tag');
            await tester.pumpWidget(const SizedBox());
          });

          testWidgets('all-known before the first ranked run: no YOU rung ($tag)', (tester) async {
            final s = S(lang);
            final p = await open(tester, _Stage.passed, lang: lang, mode: LearningMode.allKnown);
            expect(p.placed, isFalse);
            await onPhone(tester, p, phone, fontScale: fontScale, checkHome: false);
            await openLadder(tester, p, lang);
            expect(find.text(s.rankedUnplacedLine), findsOneWidget);
            expect(find.text(s.youTag), findsNothing);
            expect(find.text(s.ratingLabel), findsNothing);
            await _capture(tester, 'rank_unplaced_$tag');
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  });
}
