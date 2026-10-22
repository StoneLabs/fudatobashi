// The full karuta rules in Help: the page opens from Help with its source,
// link and disclaimer, switches to the Japanese original,
// jumps to a chapter and lays out on two phones (384 dp, and 360 dp at
// font scale 1.3) in both languages. With RENDER_SCREENS=1 it writes the
// page, a screen at a time, to build/screens/karuta_rules/.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/links.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/karuta_rules.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/rules_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/help/karuta_rules_screen.dart';
import 'package:fudatobashi/ui/shell/header_actions.dart';
import 'package:fudatobashi/ui/torifuda/glyph_atlas.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

KarutaRules _rules(String code) => KarutaRules.parse(File(KarutaRules.asset(code)).readAsStringSync());

final _firstParagraph = RegExp(r'^\*\*.+?\*\* (.+)$', multiLine: true);

/// The text of the first numbered paragraph.
String _firstText(KarutaRules r) => _firstParagraph.firstMatch(r.body)![1]!.trim();

/// The last ※ remark of the closing.
String _lastRemark(KarutaRules r) => r.body.trim().split('\n').last.substring(1).trim();

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

const _phones = [(usersPhone, 1.0), (narrowPhone, 1.3)];

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
    await _loadFont('Torifuda', ['YujiSyuku-Regular.ttf']);
  });

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    for (final (phone, fontScale) in _phones) {
      final size = phone.size;
      final tag = '${lang}_${phone.name}_$fontScale';
      testWidgets('Help opens the rules, which scroll through without overflow ($tag)', (tester) async {
        final launches = <Map<Object?, Object?>>[];
        const channel = MethodChannel('plugins.flutter.io/url_launcher');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launch') launches.add(call.arguments as Map<Object?, Object?>);
          return true;
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
        late Progress p;
        await tester.runAsync(() async {
          if (renderScreens) await GlyphAtlas.load();
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
        expect(find.text(s.rulesRowNote), findsOneWidget);
        await captureScreen(tester, 'karuta_rules/help', lang: lang);
        await tap(find.text(s.rulesTitle));
        expect(find.byType(KarutaRulesScreen), findsOneWidget);

        final ja = _rules(KarutaRules.original), en = _rules(KarutaRules.translation);
        final shown = s.ja ? ja : en;
        final first = _firstText(shown);
        expect(find.text(s.rulesSource), findsOneWidget);
        expect(find.text(s.rulesOpenPdf), findsOneWidget);
        expect(find.text(s.rulesDisclaimer), findsOneWidget);
        expect(find.text(first), findsOneWidget);

        final rule = tester.getRect(find.byKey(startRuleKey));
        expect(rule.height, greaterThan(0));
        expect(tester.getTopLeft(find.text(s.rulesContents)).dy, greaterThan(rule.bottom),
            reason: 'the divider sits directly above the contents');
        expect(tester.getBottomLeft(find.text(s.rulesDisclaimer)).dy,
            lessThan(rule.top));
        await captureScreen(tester, 'karuta_rules/top', lang: lang);

        await tap(find.text(s.rulesOpenPdf));
        expect(launches.single['url'], Links.karutaRules);
        expect(launches.single['useWebView'], isFalse, reason: 'the browser, not a view inside the app');

        final list = find.descendant(of: find.byType(KarutaRulesScreen), matching: find.byType(Scrollable)).first;
        double offset() => tester.state<ScrollableState>(list).position.pixels;

        await tester.ensureVisible(find.text(s.rulesContents));
        await tap(find.text(s.rulesContents));
        await captureScreen(tester, 'karuta_rules/contents', lang: lang);
        final last = shown.chapters.last;
        final row = find.text('${last.number}  ${last.title}');
        await tester.ensureVisible(row);
        await tester.pump();
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(offset(), greaterThan(size.height), reason: 'jumped down to the last chapter');
        expect(tester.getTopLeft(find.text(last.title).last).dy, inInclusiveRange(0, size.height / 2));
        tester.state<ScrollableState>(list).position.jumpTo(0);
        await tester.pump();
        await tap(find.text(s.rulesContents));

        var reachedEnd = false;
        for (var i = 0; i < 200; i++) {
          await captureScreen(tester, 'karuta_rules/rules', lang: lang, variant: 'step${i.toString().padLeft(3, '0')}');
          final before = offset();
          await tester.drag(list, Offset(0, -size.height * 0.7));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          if (offset() == before) {
            reachedEnd = true;
            break;
          }
        }
        expect(reachedEnd, isTrue);
        expect(find.text(s.rulesDisclaimerShort), findsOneWidget);
        expect(find.text(_lastRemark(shown)), findsOneWidget);

        await tap(find.bySemanticsLabel(s.back).last);
        expect(find.byType(KarutaRulesScreen), findsNothing);
        expect(find.byType(HelpScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
