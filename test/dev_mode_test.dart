// Settings' hidden developer mode: ten taps on Version unlock it, and the
// page scrolls down to the Developer section it adds at its foot.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:fudatobashi/ui/shell/header_actions.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('ten taps on Version show the Developer section on the page, without leaving it', (tester) async {
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true));
      await p.setLearningMode(LearningMode.journey);
    });
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FudatobashiApp(progress: p));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(SettingsButton));
    await tester.pump();
    await tester.pump(Motion.route * 2);
    const s = S('en');
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    scroll.jumpTo(scroll.maxScrollExtent);
    await tester.pump();

    for (var i = 0; i < DevModeTuning.tapsRequired; i++) {
      await tester.tap(find.text(s.version));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(p.settings.debugMode, isTrue);
    for (var i = 0; i < 10; i++) {
      await tester.pump(DevModeTuning.revealScroll ~/ 5);
    }
    final page = tester.getRect(find.byType(Scrollable).first);
    final header = tester.getRect(find.text(s.sectionDeveloper.toUpperCase()));
    expect(page.contains(header.center), isTrue, reason: 'scrolled into sight: $header in $page');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });
}
