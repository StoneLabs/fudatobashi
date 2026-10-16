// The full karuta rules in Help: the Japanese asset is the PDF's text, the
// English one has exactly its structure, and the page opens from Help with
// its source, link and disclaimer, switches to the Japanese original,
// jumps to a chapter and lays out on two phones (384 dp, and 360 dp at
// font scale 1.3) in both languages. With RENDER_SCREENS=1 it writes the
// page, a screen at a time, to build/screens/karuta_rules/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/help/karuta_rules_screen.dart';
import 'package:fudatobashi/ui/manga/theme.dart';
import 'package:fudatobashi/ui/shell/header_actions.dart';
import 'package:fudatobashi/ui/torifuda/glyph_atlas.dart';

import 'test_l10n.dart';
import 'test_vector_art.dart';

final _render = Platform.environment['RENDER_SCREENS'] == '1';

KarutaRules _rules(String code) => KarutaRules.fromJsonString(File(KarutaRules.asset(code)).readAsStringSync());

/// Text as compared with the PDF's: no page footers, no white space.
String _normalised(String s) => s.replaceAll(RegExp(r'－ \d+ / \d+ －'), '').replaceAll(RegExp(r'\s'), '');

/// The whole document as the PDF prints it, marks and brackets included.
String _plain(KarutaRules r) {
  final out = StringBuffer('${r.title}${r.author}');
  void notes(List<RulesNote> notes) {
    if (notes.isEmpty) return;
    out.write('【${r.notesLabel}】');
    for (final n in notes) {
      out.write(switch (n.kind) { RulesNoteKind.point => '○', RulesNoteKind.remark => '※', RulesNoteKind.notice => '' });
      out.write('${n.text}${n.notice ?? ''}');
    }
  }

  for (final c in r.chapters) {
    out.write('${c.number}${c.title}');
    for (final a in c.articles) {
      out.write('${a.number}（${a.title}）${a.body ?? ''}');
      for (final e in a.list) {
        out.write('${e.label}${e.text}');
      }
      notes(a.notes);
      for (final e in a.items) {
        out.write('${e.label}${e.text}${e.notice ?? ''}');
        notes(e.notes);
      }
    }
  }
  out.write(r.closing.enacted);
  for (final remark in r.closing.remarks) {
    out.write('※$remark');
  }
  return _normalised(out.toString());
}

/// Everything but the words: ids, kinds and counts, as nested lists (which
/// `equals` compares deeply, unlike records holding lists).
List<Object?> _shape(KarutaRules r) {
  List<Object?> notes(List<RulesNote> notes) => [for (final n in notes) [n.kind, n.notice != null]];
  List<Object?> entries(List<RulesEntry> entries) =>
      [for (final e in entries) [e.id, e.notice != null, notes(e.notes)]];
  return [
    for (final c in r.chapters)
      [
        c.id,
        for (final a in c.articles) [a.id, a.body != null, entries(a.list), notes(a.notes), entries(a.items)],
      ],
    r.closing.remarks.length,
  ];
}

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
    File('build/screens/karuta_rules/$name.png')
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

  group('data', () {
    final ja = _rules(KarutaRules.original), en = _rules(KarutaRules.translation);

    test('nine chapters and the 28 articles in order', () {
      expect(ja.chapters, hasLength(9));
      final articles = [for (final c in ja.chapters) ...c.articles];
      expect([for (final a in articles) a.id], [for (var n = 1; n <= 28; n++) 'art$n']);
    });

    test('the English has the same chapters, articles, paragraphs, lists and notes as the Japanese', () {
      expect(_shape(en), _shape(ja));
    });

    test('every article has paragraphs or a body, and only a body has a list or notes of its own', () {
      for (final a in [for (final c in ja.chapters) ...c.articles]) {
        expect(a.items.isEmpty, a.body != null, reason: a.id);
        if (a.body == null) expect(a.list.isEmpty && a.notes.isEmpty, isTrue, reason: a.id);
      }
    });

    test('the Japanese text is the PDF\'s, white space aside, in the sampled pages', () {
      final whole = _plain(ja);
      final samples = File('test/fixtures/rules/kyogi_kitei_saisoku_sample.txt').readAsStringSync().split('\n====\n');
      expect(samples, hasLength(6));
      for (final sample in samples) {
        expect(whole, contains(_normalised(sample)), reason: sample.trim().split('\n').take(2).join(' '));
      }
      expect(whole, startsWith(_normalised(samples.first)));
      expect(whole, endsWith(_normalised(samples.last)));
    });
  });

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    for (final (size, fontScale) in _phones) {
      final tag = '${lang}_${size.width.round()}_$fontScale';
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
          if (_render) await GlyphAtlas.load();
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
        await _capture(tester, 'help_$tag');
        await tap(find.text(s.rulesTitle));
        expect(find.byType(KarutaRulesScreen), findsOneWidget);

        final ja = _rules(KarutaRules.original), en = _rules(KarutaRules.translation);
        final shown = s.ja ? ja : en;
        final first = shown.chapters.first.articles.first.items.first.text;
        expect(find.text(s.rulesSource), findsOneWidget);
        expect(find.text(s.rulesOpenPdf), findsOneWidget);
        expect(find.text(s.rulesDisclaimer), findsOneWidget);
        expect(find.text(first), findsOneWidget);
        expect(find.text(s.rulesShowOriginal), s.ja ? findsNothing : findsOneWidget);

        final rule = tester.getRect(find.byKey(startRuleKey));
        expect(rule.height, greaterThan(0));
        expect(tester.getTopLeft(find.text(s.rulesContents)).dy, greaterThan(rule.bottom),
            reason: 'the divider sits directly above the contents');
        expect(tester.getBottomLeft(find.text(s.rulesDisclaimer)).dy,
            lessThan(rule.top));
        await _capture(tester, 'top_$tag');

        await tap(find.text(s.rulesOpenPdf));
        expect(launches.single['url'], Links.karutaRules);
        expect(launches.single['useWebView'], isFalse, reason: 'the browser, not a view inside the app');

        final list = find.descendant(of: find.byType(KarutaRulesScreen), matching: find.byType(Scrollable)).first;
        double offset() => tester.state<ScrollableState>(list).position.pixels;

        await tester.ensureVisible(find.text(s.rulesContents));
        await tap(find.text(s.rulesContents));
        await _capture(tester, 'contents_$tag');
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
          await _capture(tester, 'rules_${tag}_${i.toString().padLeft(3, '0')}');
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
        expect(find.text(shown.closing.remarks.last), findsOneWidget);

        await tap(find.bySemanticsLabel(s.back).last);
        expect(find.byType(KarutaRulesScreen), findsNothing);
        expect(find.byType(HelpScreen), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('in English, the switch shows the Japanese original and back', (tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true, onboarded: true));
    });
    await tester.binding.setSurfaceSize(_phones.first.$1);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
      child: ProgressScope(
        progress: p,
        child: MaterialApp(theme: buildMangaTheme(), debugShowCheckedModeBanner: false, home: const KarutaRulesScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    const s = S('en');
    final ja = _rules(KarutaRules.original), en = _rules(KarutaRules.translation);
    String firstText(KarutaRules r) => r.chapters.first.articles.first.items.first.text;
    expect(find.text(firstText(en)), findsOneWidget);
    expect(find.text(firstText(ja)), findsNothing);

    await tester.tap(find.text(s.rulesShowOriginal));
    await tester.pumpAndSettle();
    expect(find.text(firstText(ja)), findsOneWidget);
    expect(find.text(firstText(en)), findsNothing);
    expect(find.text(ja.title), findsOneWidget);
    expect(find.text(s.rulesDisclaimer), findsOneWidget, reason: 'the page around the rules stays English');
    await _capture(tester, 'rules_en_original');

    await tester.tap(find.text(s.rulesShowOriginal));
    await tester.pumpAndSettle();
    expect(find.text(firstText(en)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
