// Restore from a backup: the header title is shown whole, shrunk to fit
// beside the back button, on 384 dp and on 360 dp at font scale 1.3, in
// both languages.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/l10n/data_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/data_store.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/settings/data_actions.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

class _Dialogs implements FileDialogs {
  @override
  Future<bool> save(String fileName, Uint8List bytes) async => false;

  @override
  Future<File?> pick() async => null;
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    for (final (family, files) in [
      ('Dela', ['DelaGothicOne-Regular.ttf']),
      ('Reggae', ['ReggaeOne-Regular.ttf']),
      ('ZenKaku', ['ZenKakuGothicNew-Regular.ttf', 'ZenKakuGothicNew-Bold.ttf', 'ZenKakuGothicNew-Black.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
      }
      await loader.load();
    }
  });

  for (final (width, fontScale) in [(384.0, 1.0), (384.0, 1.3), (360.0, 1.3)]) {
    for (final lang in ['en', 'ja']) {
      testWidgets('the title fits beside the back button ($width, $lang, $fontScale)', (tester) async {
        late Progress p;
        await tester.runAsync(() async {
          p = await Progress.open(AppDatabase(NativeDatabase.memory()));
          await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
        });
        final root = Directory.systemTemp.createTempSync('restore_page_');
        addTearDown(() => root.deleteSync(recursive: true));
        final store = DataStore(
          DataPaths(
              database: File('${root.path}/fudatobashi.sqlite'),
              support: Directory('${root.path}/support'),
              temp: Directory('${root.path}/temp')),
          dialogs: _Dialogs(),
        );
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = Size(width, 800);
        tester.platformDispatcher.textScaleFactorTestValue = fontScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(ProgressScope(
          progress: p,
          child: MaterialApp(
            theme: buildMangaTheme(),
            debugShowCheckedModeBanner: false,
            home: RestorePage(store: store, confirm: true),
          ),
        ));
        await tester.pump();

        final s = S(lang);
        final title = find.byType(ScreenTitle);
        expect(find.textContaining(s.restoreBackup, findRichText: true), findsOneWidget);
        expect(tester.takeException(), isNull);
        final paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: title, matching: find.byType(RichText)));
        expect(paragraph.didExceedMaxLines, isFalse, reason: 'the title is not ellipsized');
        expect(find.ancestor(of: title, matching: find.byType(FittedBox)), findsOneWidget);
        final back = tester.getRect(find.bySemanticsLabel(s.back));
        expect(tester.getRect(title).right, lessThanOrEqualTo(back.left + 0.5));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
