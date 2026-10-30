// The karuta guide in Help: it opens from Help's row as the karuta article,
// with kana beside their romaji, and closes back to Help; and the kimariji
// it explains are the poems' own. The guide itself lays out in
// guides_test.dart.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/articles.dart';
import 'package:fudatobashi/l10n/guide_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/help/guide_screen.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/shell/header_actions.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('kimarijiAmong all 100 poems is each poem\'s own kimariji', () {
    for (final p in poems.all) {
      expect(poems.kimarijiAmong(p, poems.all), p.kimariji, reason: '${p.id}');
    }
  });

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    testWidgets('Help opens the karuta guide and closes back to it ($lang)', (tester) async {
      late Progress p;
      await tester.runAsync(() async {
        p = await Progress.open(AppDatabase(NativeDatabase.memory()));
        p.tabsAlwaysOpen = true;
        await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true, onboarded: true));
        await p.setLearningMode(LearningMode.allKnown);
        await Articles.load(lang, Articles.karutaGuide);
      });
      await tester.binding.setSurfaceSize(usersPhone.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(RepaintBoundary(key: screenKey, child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));

      Future<void> tap(Finder f) async {
        await tester.tap(f);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
      }

      await tap(find.byType(HelpButton));
      expect(find.byType(HelpScreen), findsOneWidget);
      await captureScreen(tester, 'karuta_guide/help', lang: lang);
      await tap(find.text(s.guideTitle));
      final guide = tester.widget<GuideScreen>(find.byType(GuideScreen));
      expect((guide.article, guide.kanaBesideRomaji), (Articles.karutaGuide, true));
      await captureScreen(tester, 'karuta_guide/guide', lang: lang);

      await tap(find.bySemanticsLabel(s.back).last);
      expect(find.byType(GuideScreen), findsNothing);
      expect(find.byType(HelpScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
