// Help's "All other guides" row opens the list of guides, and each row of the
// list opens its guide with the title and options of the guide list
// (`Guides.all`). With RENDER_SCREENS=1 it renders the list.
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
import 'package:fudatobashi/l10n/all_guides_strings.dart';
import 'package:fudatobashi/l10n/articles.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/help/all_guides_screen.dart';
import 'package:fudatobashi/ui/help/guide_catalog.dart';
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

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    testWidgets('Help opens the list of all guides and each row opens its guide ($lang)', (tester) async {
      late Progress p;
      await tester.runAsync(() async {
        p = await Progress.open(AppDatabase(NativeDatabase.memory()));
        p.tabsAlwaysOpen = true;
        await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true, onboarded: true));
        await p.setLearningMode(LearningMode.allKnown);
        for (final guide in Guides.all) {
          await Articles.load(lang, guide.article);
        }
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
      await tap(find.text(s.allGuidesTitle));
      expect(find.byType(AllGuidesScreen), findsOneWidget);
      await captureScreen(tester, 'all_guides/list', lang: lang);

      expect(Guides.all.length, 3);
      for (final guide in Guides.all) {
        await tap(find.text(guide.title(s)));
        final screen = tester.widget<GuideScreen>(find.byType(GuideScreen));
        expect((screen.article, screen.title, screen.sub, screen.kanaBesideRomaji),
            (guide.article, guide.title(s), guide.subOf(s), guide.kanaBesideRomaji));
        await tap(find.bySemanticsLabel(s.back).last);
        expect(find.byType(GuideScreen), findsNothing);
        expect(find.byType(AllGuidesScreen), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
