// Settings › Card size: the setting is saved and loaded, its page shows a
// test card that resizes live under the slider, and the swipe cards are
// smaller by the same share (and still swipe) down to the minimum. The page
// fits 384 × 832 dp and 360 dp wide at font scale 1.3.
//
// With RENDER_SCREENS=1 it also renders the page to .scratchpad/card_size/.
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
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/settings_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/play/card_size.dart';
import 'package:fudatobashi/ui/play/swipe_deck.dart';
import 'package:fudatobashi/ui/play/test_card.dart';
import 'package:fudatobashi/ui/shell/header_actions.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';
import 'package:fudatobashi/ui/settings/card_size_screen.dart';
import 'package:fudatobashi/ui/settings/settings_rows.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

typedef _Phone = ({String name, Size size, double dpr});

const _users = (name: '384', size: Size(384, 832), dpr: 2.8125);
const _narrow = (name: '360', size: Size(360, 780), dpr: 3.0);
const _statusBar = 28.0, _navBar = 48.0;

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> loadFont(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
    }
    await loader.load();
  }

  setUpAll(() async {
    await loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
  });

  Future<Progress> player(WidgetTester tester, {String lang = 'en', double? scale}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true, cardScale: scale));
      await p.setLearningMode(LearningMode.journey);
    });
    return p;
  }

  group('the setting', () {
    test('is saved and loaded, and kept within its range', () {
      expect(const AppSettings().cardScale, DefaultSettings.cardScale);
      expect(DefaultSettings.cardScale, 1);
      expect(AppSettings.fromJson(const AppSettings(cardScale: 0.7).toJson()).cardScale, 0.7);
      expect(AppSettings.fromJson({}).cardScale, DefaultSettings.cardScale);
      expect(AppSettings.fromJson({'cardScale': 0.1}).cardScale, SwipeTuning.cardScaleMin);
      expect(AppSettings.fromJson({'cardScale': 3}).cardScale, SwipeTuning.cardScaleMax);
      expect(const AppSettings().copyWith(cardScale: 0.5).cardScale, 0.5);
    });

    testWidgets('survives a restart of the app', (tester) async {
      late Progress p;
      late AppDatabase db;
      await tester.runAsync(() async {
        db = AppDatabase(NativeDatabase.memory());
        p = await Progress.open(db);
        await p.updateSettings(p.settings.copyWith(cardScale: 0.45));
        p = await Progress.open(db);
      });
      expect(p.settings.cardScale, 0.45);
    });
  });

  Future<void> openPage(WidgetTester tester, Progress p, _Phone phone, {double fontScale = 1}) async {
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
    await tester.tap(find.byType(SettingsButton));
    await tester.pump();
    await tester.pump(Motion.route * 2);
    final row = find.ancestor(of: find.text(S(p.settings.language).cardSize), matching: find.byType(SettingsTapRow));
    await tester.ensureVisible(row);
    await tester.pump();
    await tester.tap(row);
    await tester.pump();
    await tester.pump(Motion.route * 2);
  }

  double cardWidth(WidgetTester tester) => tester.getSize(find.byType(TestCard)).width;

  Future<void> drag(WidgetTester tester, double dx) async {
    await tester.drag(find.byType(Slider), Offset(dx, 0));
    await tester.pump();
  }

  for (final (phone, fontScale) in [(_users, 1.0), (_narrow, 1.3)]) {
    for (final lang in ['en', 'ja']) {
      testWidgets('the page shows the card, resizing live under the slider (${phone.name}, $lang, $fontScale)',
          (tester) async {
        final s = S(lang);
        final p = await player(tester, lang: lang);
        await openPage(tester, p, phone, fontScale: fontScale);
        expect(find.byType(CardSizeScreen), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        final full = cardWidth(tester);
        expect(tester.getSize(find.byType(TestCard)).height, closeTo(full * playCardSize(const Size(100, 100), 1).height / playCardSize(const Size(100, 100), 1).width, 0.5));

        await drag(tester, -60);
        final smaller = cardWidth(tester);
        expect(smaller, lessThan(full));
        final scale = p.settings.cardScale;
        expect(scale, inInclusiveRange(SwipeTuning.cardScaleMin, 1));
        expect(smaller, closeTo(full * scale, 0.5));
        expect(find.text('${(scale * 100).round()}%'), findsWidgets);

        await drag(tester, -2000);
        expect(p.settings.cardScale, SwipeTuning.cardScaleMin);
        expect(find.text('25%'), findsWidgets);
        expect(cardWidth(tester), closeTo(full * SwipeTuning.cardScaleMin, 0.5));

        final screen = Offset.zero & phone.size;
        expect(tester.takeException(), isNull);
        for (final f in [find.byType(TestCard), find.byType(Slider), find.text(s.cardSizeNote)]) {
          final r = tester.getRect(f);
          expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(.1, .1)), isTrue,
              reason: '$f $r');
          expect(r.bottom, lessThanOrEqualTo(phone.size.height - _navBar + 0.5), reason: '$f');
        }
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pump(Motion.route * 2);
        expect(find.descendant(of: find.byType(SettingsTapRow), matching: find.text('25%')), findsOneWidget,
            reason: 'the Settings row shows it');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  group('the swipe cards', () {
    Future<PlaySession> pumpDeck(WidgetTester tester, double scale) async {
      final p = await player(tester, scale: scale);
      final session = PlaySession([const CardRef(1), const CardRef(2)]);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ProgressScope(
          progress: p,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: SwipeDeck(session: session, live: true, haptics: false),
          ),
        ),
      ));
      await tester.pump();
      return session;
    }

    double width(WidgetTester tester) => tester.getSize(find.byType(TorifudaCard).first).width;

    testWidgets('are smaller by the chosen share', (tester) async {
      await pumpDeck(tester, 1);
      final full = width(tester);
      await tester.pumpWidget(const SizedBox());
      for (final scale in [0.7, SwipeTuning.cardScaleMin]) {
        await pumpDeck(tester, scale);
        expect(width(tester), closeTo(full * scale, 0.5), reason: '$scale');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('still swipe at the smallest size, from the middle of the screen', (tester) async {
      final session = await pumpDeck(tester, SwipeTuning.cardScaleMin);
      final g = await tester.startGesture(const Offset(200, 400));
      for (var i = 0; i < 6 && session.attempts.isEmpty; i++) {
        await g.moveBy(const Offset(25, 0));
        await tester.pump(const Duration(milliseconds: 8));
      }
      await g.up();
      await tester.pump(const Duration(milliseconds: 16));
      expect(session.attempts.single.outcome, Outcome.known);
    });
  });

  group('renders', skip: Platform.environment['RENDER_SCREENS'] != '1', () {
    for (final (scale, lang) in [(1.0, 'en'), (0.6, 'ja'), (0.25, 'en')]) {
      testWidgets('card_size_${(scale * 100).round()}_$lang', (tester) async {
        final p = await player(tester, lang: lang, scale: scale);
        await openPage(tester, p, _users);
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('.scratchpad/card_size/card_size_${(scale * 100).round()}_$lang.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        });
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
