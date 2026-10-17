// The karuta guide in Help: it opens from Help's row, lays out on two
// phones (384 dp, and 360 dp at font scale 1.3) in both languages, its text
// uses no dashes or colons, and the kimariji it shows are the poems'.
// With RENDER_SCREENS=1 it writes the guide, a screen at a time, to
// build/screens/karuta_guide/.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/config/yomifuda_spec.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/l10n/guide_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/help/karuta_guide_screen.dart';
import 'package:fudatobashi/ui/shell/header_actions.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';
import 'package:fudatobashi/ui/torifuda/glyph_atlas.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

final _render = Platform.environment['RENDER_SCREENS'] == '1';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!_render) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('screen')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/screens/karuta_guide/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

const _phones = [(Size(384, 832), 1.0), (Size(360, 780), 1.3)];

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // The app's own fonts, so Home and the guide lay out as on a phone (the
  // test font's square glyphs are wider than any real one).
  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
    await _loadFont('Torifuda', ['YujiSyuku-Regular.ttf']);
    await _loadFont('YujiSyuku', ['YujiSyuku-Regular.ttf']);
  });

  group('text', () {
    for (final code in ['en', 'ja']) {
      test('no dashes or colons in the guide ($code)', () {
        final strings = jsonDecode(File('assets/l10n/$code.json').readAsStringSync()) as Map<String, dynamic>;
        final guide = {for (final e in strings.entries) if (e.key.startsWith('guide')) e.key: e.value as String};
        expect(guide.length, greaterThan(40));
        for (final MapEntry(:key, :value) in guide.entries) {
          expect(value, isNot(matches(RegExp('[—–:：]'))), reason: key);
        }
      });
    }

    test('every step of a match has its line', () {
      for (final code in ['en', 'ja']) {
        final steps = S(code).guideSteps;
        expect(steps, hasLength(KarutaGuideExamples.steps));
        expect(steps.every((l) => !l.startsWith('guideStep')), isTrue, reason: code);
      }
    });
  });

  group('kimariji', () {
    test('kimarijiAmong all 100 poems is each poem\'s own kimariji', () {
      for (final p in poems.all) {
        expect(poems.kimarijiAmong(p, poems.all), p.kimariji, reason: '${p.id}');
      }
    });

    test('はるすぎて and はるのよの need three sounds, then はる once はるすぎて is read', () {
      final first = poems[KarutaGuideExamples.readFirst], second = poems[KarutaGuideExamples.shortened];
      expect(first.kamiKana, startsWith('はるすぎて'));
      expect(second.kamiKana, startsWith('はるのよの'));
      expect(first.kimariji, 'はるす');
      expect(second.kimariji, 'はるの');
      final left = poems.all.where((p) => p.id != first.id);
      expect(poems.kimarijiAmong(second, left), 'はる');
    });

    test('the seven one-sound cards are むすめふさほせ', () {
      final one = {for (final p in poems.all) if (p.kimariji.length == 1) p.kimariji};
      expect(KarutaGuideExamples.oneSound, 'むすめふさほせ');
      expect(KarutaGuideExamples.oneSound.split('').toSet(), one);
    });

    test('the six-sound cards are the two each of あさぼらけ, わたのはら and きみがため', () {
      final six = [for (final p in poems.all) if (p.kimariji.length == 6) p.kimariji];
      expect(six, hasLength(KarutaGuideExamples.sixSound.length * 2));
      for (final start in KarutaGuideExamples.sixSound) {
        expect(six.where((k) => k.startsWith(start)), hasLength(2), reason: start);
      }
    });
  });

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    for (final (size, fontScale) in _phones) {
      final tag = '${lang}_${size.width.round()}_$fontScale';
      testWidgets('Help opens the guide, which scrolls through without overflow ($tag)', (tester) async {
        late Progress p;
        await tester.runAsync(() async {
          if (_render) await GlyphAtlas.load();
          await CardFaces.load([YomifudaStyle.standard.background, TorifudaStyle.standard.background],
              read: (a) => File(a).readAsBytes());
          p = await Progress.open(AppDatabase(NativeDatabase.memory()));
          p.tabsAlwaysOpen = true;
          await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true, onboarded: true));
          await p.setLearningMode(LearningMode.allKnown);
        });
        tester.platformDispatcher.textScaleFactorTestValue = fontScale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
        await tester.pump(const Duration(milliseconds: 500));

        Future<void> tap(Finder f) async {
          await tester.tap(f);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        }

        await tap(find.byType(HelpButton));
        expect(find.byType(HelpScreen), findsOneWidget);
        expect(find.text(s.comingSoon), findsNothing, reason: 'the guide took its place');
        await _capture(tester, 'help_$tag');
        await tap(find.text(s.guideTitle));
        expect(find.byType(KarutaGuideScreen), findsOneWidget);

        final list = find.descendant(of: find.byType(KarutaGuideScreen), matching: find.byType(Scrollable)).first;
        var reachedEnd = false;
        for (var i = 0; i < 40; i++) {
          await _capture(tester, 'guide_${tag}_${i.toString().padLeft(2, '0')}');
          final before = tester.state<ScrollableState>(list).position.pixels;
          await tester.drag(list, Offset(0, -size.height * 0.6));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          if (tester.state<ScrollableState>(list).position.pixels == before) {
            reachedEnd = true;
            break;
          }
        }
        expect(reachedEnd, isTrue);
        expect(find.text(s.guideAppTobi), findsOneWidget, reason: 'the guide ends with Tobi\'s last line');

        await tap(find.bySemanticsLabel(s.back).last);
        expect(find.byType(KarutaGuideScreen), findsNothing);
        expect(find.byType(HelpScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
