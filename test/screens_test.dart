// Lays out onboarding and both Home modes in English and Japanese on a
// phone-sized surface and fails on any layout error. With RENDER_SCREENS=1 it
// also writes PNGs to build/screens/ for visual checks.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/app.dart';

const _phone = Size(384, 832);

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

void main() {
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

  test('the island data matches the initial-kana groups', () {
    expect(archipelago.islands.map((i) => i.name), initialGroups);
    for (final isl in archipelago.islands) {
      expect({for (final s in isl.sites) s.poemId}, {...fudaSets['initial:${isl.name}'].poemIds});
    }
  });

  Future<Progress> open(WidgetTester tester, {LearningMode? mode, bool ja = false, int journeyCards = 0}) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: ja ? AppLanguage.ja : AppLanguage.en));
      if (mode != null) await p.setLearningMode(mode);
    });
    final ids = [for (final isl in archipelago.islands) ...fudaSets['initial:${isl.name}'].poemIds];
    for (final id in ids.take(journeyCards)) {
      p.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    return p;
  }

  Future<void> show(WidgetTester tester, Progress p, String name) async {
    await tester.binding.setSurfaceSize(_phone);
    await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await _capture(tester, name);
    await tester.pumpWidget(const SizedBox());
  }

  for (final ja in [false, true]) {
    final lang = ja ? 'ja' : 'en';

    testWidgets('onboarding ($lang)', (tester) async {
      await show(tester, await open(tester, ja: ja), 'onboarding_$lang');
    });

    testWidgets('home, journey ($lang)', (tester) async {
      await show(tester, await open(tester, mode: LearningMode.journey, ja: ja, journeyCards: 27), 'journey_$lang');
    });

    testWidgets('home, all known ($lang)', (tester) async {
      await show(tester, await open(tester, mode: LearningMode.allKnown, ja: ja), 'known_$lang');
    });
  }
}
