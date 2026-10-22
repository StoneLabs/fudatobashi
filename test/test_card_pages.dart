// Shared by the card browser and About page tests: the app's fonts, card
// art and data, a fresh player in either language and a phone to show a
// page on.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/config/yomifuda_spec.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';
import 'package:fudatobashi/ui/torifuda/glyph_atlas.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

/// The data every page reads, loaded from the files on disk.
void loadCardPageData() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

/// The app's own fonts, so pages lay out as on a phone (the test font's
/// square glyphs are wider than any real one).
Future<void> loadAppFonts() async {
  await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
  await _loadFont('ZenKaku', [
    'ZenKakuGothicNew-Regular.ttf',
    'ZenKakuGothicNew-Medium.ttf',
    'ZenKakuGothicNew-Bold.ttf',
    'ZenKakuGothicNew-Black.ttf',
  ]);
  await _loadFont('YujiSyuku', ['YujiSyuku-Regular.ttf']);
  await _loadFont('TorifudaNumber', ['TeXGyreSchola-Regular.otf']);
}

/// The torifuda's kana and the yomifuda's blank face, as the app loads
/// them at startup.
Future<void> loadCardArt(WidgetTester tester) => tester.runAsync(() async {
      await GlyphAtlas.load();
      await CardFaces.load([YomifudaStyle.standard.background, TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
    });

/// A player past onboarding, with the UI in [lang].
Future<Progress> openPlayer(WidgetTester tester, String lang) async {
  late Progress p;
  await tester.runAsync(() async {
    p = await Progress.open(AppDatabase(NativeDatabase.memory()));
    p.tabsAlwaysOpen = true;
    await p.updateSettings(
        p.settings.copyWith(language: lang, languagePicked: true, toured: true, onboarded: true));
  });
  return p;
}

/// Shows [page] for [p] at [screen]'s size and [textScale].
Future<void> showPage(WidgetTester tester, Progress p, Widget page,
    {Screen screen = usersPhone, double textScale = 1}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.binding.setSurfaceSize(screen.size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(RepaintBoundary(
    key: screenKey,
    child: ProgressScope(
      progress: p,
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildMangaTheme(), builder: withUiFont, home: page),
    ),
  ));
  await settle(tester);
}

/// Lets taps, routes and card moves finish, a frame at a time so each
/// move starts when it would on a phone.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
  expect(tester.takeException(), isNull);
}

/// Taps [finder] and lets what it opens settle.
Future<void> tapOn(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}
