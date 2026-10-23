// SRS Debug's Rating tab: the class table lists every class of the rating
// with the rating it starts at and its time per card, worked out from the
// class lines. With RENDER_SCREENS=1 it renders the table to
// build/screens/debug_rating_classes.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/debug/debug_page.dart';

import 'test_screens.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(loadRenderMonoFont);

  testWidgets('debug: the Rating tab shows each class\'s rating and time per card', (tester) async {
    late Progress p;
    await tester.runAsync(() async => p = await Progress.open(AppDatabase(NativeDatabase.memory())));
    useScreen(tester, usersPhone);
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(progress: p, child: const MaterialApp(home: DebugPage())),
    ));
    await tester.ensureVisible(find.text('Rating'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rating'));
    await tester.pumpAndSettle();
    final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).last;
    final title = find.text('Classes by time per card');
    await tester.scrollUntilVisible(title, 200, scrollable: list);
    await tester.runAsync(() => Scrollable.ensureVisible(tester.element(title)));
    await tester.pumpAndSettle();
    expect(title, findsOneWidget);

    String perCard(double? seconds) => (seconds! / RankedTuning.cards).toStringAsFixed(2);
    const bands = Rating.bands;
    final table = find.ancestor(of: title, matching: find.byType(Column)).first;
    String row(RankBand band) => tester
        .widget<Text>(find.descendant(of: table, matching: find.textContaining(RegExp('^${RegExp.escape(band.labelEn)} '))))
        .data!;
    expect(row(bands.first), endsWith('> ${perCard(bands[1].maxSeconds)} s'), reason: 'slower than the first line');
    for (var i = 1; i + 1 < bands.length; i++) {
      final band = bands[i];
      expect(row(band), contains('${band.minRating.round()}'), reason: band.labelEn);
      expect(row(band), endsWith('${perCard(band.maxSeconds)}–${perCard(bands[i + 1].maxSeconds)} s'),
          reason: band.labelEn);
    }
    expect(row(bands.last), endsWith('≤ ${perCard(bands.last.maxSeconds)} s'), reason: 'the top class has no end');

    await captureScreen(tester, 'debug_rating_classes');
    await tester.pumpWidget(const SizedBox());
  });
}
