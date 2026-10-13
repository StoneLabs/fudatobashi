// Settings' "Day starts at" row (journey mode only) and the hour sheet it
// opens: it shows the hour in use, a picked hour is stored and takes effect
// from the next day start, and closing the sheet keeps the hour. The
// Learning section and the sheet fit phones 360, 384 and 412 dp wide at
// font scale 1.0 and 1.3, in English and Japanese.
//
// With RENDER_SCREENS=1 it also renders the Learning section and the sheet
// at 2 px per dp to .scratchpad/daily_set/renders/.
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
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/settings_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/settings/settings_rows.dart';
import 'package:fudatobashi/ui/shell/header_actions.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

/// A phone: its size in dp and its pixels per dp (all 1080 × 2340 px),
/// with a 28 dp status bar and a 48 dp navigation bar.
typedef _Phone = ({String name, Size size, double dpr});

const _narrow = (name: '360', size: Size(360, 780), dpr: 3.0);
const _users = (name: '384', size: Size(384, 832), dpr: 2.8125);
const _wide = (name: '412', size: Size(1080 / 2.625, 2340 / 2.625), dpr: 2.625);
const _statusBar = 28.0, _navBar = 48.0;

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
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  // A player in [lang] who has taken the tour, in [mode], with today's
  // set built.
  Future<Progress> player(WidgetTester tester, {String lang = 'en', LearningMode mode = LearningMode.journey}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
      await p.setLearningMode(mode);
    });
    return p;
  }

  // Opens Settings from Home on [phone] at [fontScale], with the Learning
  // section scrolled to the top.
  Future<void> showSettings(WidgetTester tester, Progress p, _Phone phone, {double fontScale = 1}) async {
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
    final s = S(p.settings.language);
    await tester.ensureVisible(find.text(s.sectionLearning.toUpperCase()));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    scroll.jumpTo(scroll.pixels + tester.getRect(find.text(s.sectionLearning.toUpperCase())).top -
        tester.getRect(find.byType(Scrollable).first).top);
    await tester.pump();
  }

  // Lets the database work started by a tap finish, then the frames after.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump(Motion.sheet * 2);
  }

  Finder dayStartRow(S s) => find.ancestor(of: find.text(s.dayStart), matching: find.byType(SettingsTapRow));

  Finder sheetPanel(S s) => find.ancestor(of: find.text(s.dayStartChange), matching: find.byType(MangaPanel));

  Finder hourCell(S s, int hour) =>
      find.ancestor(of: find.descendant(of: sheetPanel(s), matching: find.text(s.hourOfDay(hour))), matching: find.byType(InkButton));

  Future<void> openSheet(WidgetTester tester, S s) async {
    await tester.tap(find.text(s.dayStart));
    await tester.pump();
    await tester.pump(Motion.sheet * 2);
  }

  void expectInside(WidgetTester tester, Finder f, Rect box, String why) {
    for (final e in f.evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(r.left >= box.left - 0.5 && r.right <= box.right + 0.5 && r.top >= box.top - 0.5 && r.bottom <= box.bottom + 0.5,
          isTrue, reason: '$why: $r in $box');
    }
  }

  // The row's texts sit inside its group, inside the screen.
  void expectRowFits(WidgetTester tester, S s, _Phone phone, String why) {
    expect(tester.takeException(), isNull, reason: why);
    final group = tester.getRect(find.ancestor(of: dayStartRow(s), matching: find.byType(SettingsGroup)));
    expect(group.left, greaterThanOrEqualTo(0), reason: why);
    expect(group.right, lessThanOrEqualTo(phone.size.width), reason: why);
    expectInside(tester, find.descendant(of: dayStartRow(s), matching: find.byType(RichText)), group, why);
  }

  // The sheet shows whole between the system bars, every hour inside it.
  void expectSheetFits(WidgetTester tester, S s, _Phone phone, String why) {
    expect(tester.takeException(), isNull, reason: why);
    final sheet = tester.getRect(sheetPanel(s));
    expect(sheet.top, greaterThanOrEqualTo(_statusBar), reason: why);
    expect(sheet.bottom, lessThanOrEqualTo(phone.size.height - _navBar + 0.5), reason: why);
    expect(sheet.left, greaterThanOrEqualTo(0), reason: why);
    expect(sheet.right, lessThanOrEqualTo(phone.size.width), reason: why);
    for (var h = TodaySetTuning.firstDayStartHour; h <= TodaySetTuning.lastDayStartHour; h++) {
      final cell = tester.getRect(hourCell(s, h));
      expectInside(tester, hourCell(s, h), sheet.deflate(Strokes.panel), '$why ${s.hourOfDay(h)}');
      expectInside(tester, find.descendant(of: hourCell(s, h), matching: find.byType(RichText)), cell, '$why ${s.hourOfDay(h)}');
    }
    expectInside(tester, find.descendant(of: sheetPanel(s), matching: find.byType(RichText)), sheet, why);
  }

  testWidgets('journey mode shows the row with the hour in use; all-known mode has none', (tester) async {
    const s = S('en');
    final journey = await player(tester);
    await showSettings(tester, journey, _users);
    expect(dayStartRow(s), findsOneWidget);
    expect(find.descendant(of: dayStartRow(s), matching: find.text(s.dayStartNote)), findsOneWidget);
    expect(find.descendant(of: dayStartRow(s), matching: find.text(s.hourOfDay(TodaySetTuning.defaultDayStartHour))),
        findsOneWidget);
    final pace = tester.getRect(find.text(s.pace));
    expect(tester.getRect(dayStartRow(s)).top, greaterThan(pace.bottom), reason: 'under Pace');
    expect(tester.getRect(dayStartRow(s)).bottom, lessThan(tester.getRect(find.text(s.dontKnowInput)).top));
    await tester.pumpWidget(const SizedBox());

    final known = await player(tester, mode: LearningMode.allKnown);
    await showSettings(tester, known, _users);
    expect(find.text(s.learningMode), findsOneWidget);
    expect(find.text(s.dayStart), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the sheet picks an hour and stores it, from the next day start', (tester) async {
    const s = S('en');
    final p = await player(tester);
    final now = DateTime.now();
    final today = p.dayAt(now);
    await showSettings(tester, p, _users);
    await openSheet(tester, s);
    expect(find.text(s.other.dayStart), findsOneWidget, reason: 'the other language under the title');
    final picked = TodaySetTuning.defaultDayStartHour;
    for (var h = TodaySetTuning.firstDayStartHour; h <= TodaySetTuning.lastDayStartHour; h++) {
      expect(tester.widget<InkButton>(hourCell(s, h)).color, h == picked ? Palette.sun : Palette.paper);
      expect(find.ancestor(of: hourCell(s, h), matching: find.byType(Transform)).evaluate().isNotEmpty, h == picked,
          reason: 'only the hour in use is tilted');
    }

    const hour = 6;
    await tester.runAsync(() => tester.tap(hourCell(s, hour)));
    await settle(tester);
    expect(sheetPanel(s), findsNothing);
    expect(p.settings.dayStartHour, hour);
    expect(p.trainer.dayStartHour, hour);
    expect(find.descendant(of: dayStartRow(s), matching: find.text(s.hourOfDay(hour))), findsOneWidget);

    final still = p.dayAt(now);
    expect((still.number, still.start, still.end), (today.number, today.start, today.end),
        reason: 'today keeps its window');
    final next = p.dayAt(today.end);
    expect(next.start, today.end, reason: 'the next day starts where today ends');
    expect(next.end.hour, hour);
    final after = p.dayAt(next.end);
    expect((after.start.hour, after.end.hour), (hour, hour));
  });

  testWidgets('closing the sheet keeps the hour', (tester) async {
    const s = S('en');
    final p = await player(tester);
    await showSettings(tester, p, _users);
    await openSheet(tester, s);
    await tester.tapAt(const Offset(200, 60));
    await settle(tester);
    expect(sheetPanel(s), findsNothing);
    expect(p.settings.dayStartHour, TodaySetTuning.defaultDayStartHour);
  });

  group('fits', () {
    for (final lang in ['en', 'ja']) {
      testWidgets('the row and the sheet ($lang) on every phone and font scale', (tester) async {
        final p = await player(tester, lang: lang);
        final s = S(lang);
        for (final phone in [_narrow, _users, _wide]) {
          for (final fontScale in [1.0, 1.3]) {
            final why = '${phone.name} $lang $fontScale';
            await showSettings(tester, p, phone, fontScale: fontScale);
            expectRowFits(tester, s, phone, why);
            await openSheet(tester, s);
            expectSheetFits(tester, s, phone, why);
            await tester.pumpWidget(const SizedBox());
          }
        }
      });
    }
  });

  group('renders', skip: Platform.environment['RENDER_SCREENS'] != '1', () {
    Future<void> capture(WidgetTester tester, String name) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('.scratchpad/daily_set/renders/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    for (final lang in ['en', 'ja']) {
      for (final (phone, fontScale) in [(_users, 1.0), (_narrow, 1.3)]) {
        testWidgets('day_start_${phone.name}_${lang}_$fontScale', (tester) async {
          final p = await player(tester, lang: lang);
          final s = S(lang);
          await showSettings(tester, p, phone, fontScale: fontScale);
          await capture(tester, 'day_start_row_${phone.name}_${lang}_$fontScale');
          await openSheet(tester, s);
          await capture(tester, 'day_start_sheet_${phone.name}_${lang}_$fontScale');
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
