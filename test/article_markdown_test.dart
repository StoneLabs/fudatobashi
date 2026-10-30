// The Markdown the articles add to prose, from inline samples: Tobi's lines
// and their poses, pictures with captions and their versions by language and
// kana setting, kana marks, HTML comments, and a guide's numbered chapters,
// small headings and steps.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'test_vector_art.dart';

Future<void> _show(WidgetTester tester, String source,
    {ProseStyle style = ProseStyle.explanation, MarkdownOptions options = const MarkdownOptions()}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: MarkdownProse(source, blocks: ProseBlocks(style: style, options: options))),
    ),
  ));
  expect(tester.takeException(), isNull);
}

/// Disposes what was shown, so Tobi's idle motion leaves no timer behind.
Future<void> _clear(WidgetTester tester) => tester.pumpWidget(const SizedBox());

String _text(WidgetTester tester) =>
    [for (final e in find.byType(RichText).evaluate()) (e.widget as RichText).text.toPlainText()].join('\n');

void main() {
  loadTestVectorArt();

  group('Tobi lines', () {
    testWidgets('a line with a pose is Tobi in that pose, saying the words after the braces', (tester) async {
      await _show(tester, '>{.tobi pose=waving} Hello there!');
      final line = tester.widget<TobiLine>(find.byType(TobiLine));
      expect(line.pose, TobiPose.waving);
      expect(line.line, 'Hello there!');
      await _clear(tester);
    });

    testWidgets('a space after > works too, and no pose is the standard one', (tester) async {
      await _show(tester, '> {.tobi} Hi');
      final line = tester.widget<TobiLine>(find.byType(TobiLine));
      expect(line.pose, TobiPose.standard);
      expect(line.line, 'Hi');
      await _clear(tester);
    });

    testWidgets('poses go by their art file names; an unknown one is standard', (tester) async {
      await _show(tester, '>{.tobi pose=try-hard} One\n\n>{.tobi pose=dancing} Two');
      expect([for (final l in tester.widgetList<TobiLine>(find.byType(TobiLine))) l.pose], [TobiPose.tryHard, TobiPose.standard]);
      await _clear(tester);
    });

    testWidgets('a line goes on over the lines of its quote, kana marks as the reader reads them', (tester) async {
      await _show(tester, '>{.tobi} Say\n> {むすめ}!', options: const MarkdownOptions(romaji: true));
      expect(tester.widget<TobiLine>(find.byType(TobiLine)).line, 'Say musume!');
      await _clear(tester);
    });

    testWidgets('a quote without the braces stays a quote', (tester) async {
      await _show(tester, '> Just a quote.');
      expect(find.byType(TobiLine), findsNothing);
      expect(_text(tester), contains('Just a quote.'));
    });

    test('every pose has its art file', () {
      for (final pose in TobiPose.values) {
        expect(File('assets/graphics/tobi/${pose.fileName}.svg').existsSync(), isTrue, reason: pose.fileName);
        expect(TobiPose.named(pose.fileName), pose);
      }
      expect(TobiPose.named('tryHard'), isNull, reason: 'named as the file is');
    });
  });

  group('pictures', () {
    testWidgets('a picture on a line of its own, its caption under it', (tester) async {
      await _show(tester, 'Text.\n\n![The red sound decides.](assets/artworks/articles/rows.webp)\n\nMore.');
      final picture = tester.widget<ArticlePicture>(find.byType(ArticlePicture));
      expect(picture.src, 'assets/artworks/articles/rows.webp');
      expect(picture.caption, 'The red sound decides.');
      expect(find.text('The red sound decides.'), findsOneWidget);
    });

    testWidgets('the template names the picture for the kana setting', (tester) async {
      const source = '![](assets/artworks/articles/rows_{{ "romaji" if env.romaji_mode else "hiragana" }}.en.webp)';
      for (final romaji in [false, true]) {
        await _show(tester, source, options: MarkdownOptions(romaji: romaji));
        expect(tester.widget<ArticlePicture>(find.byType(ArticlePicture)).src,
            'assets/artworks/articles/rows_${romaji ? 'romaji' : 'hiragana'}.en.webp');
      }
    });
  });

  group('kana marks', () {
    const source = 'It starts with {あきの}.';

    testWidgets('show their kana', (tester) async {
      await _show(tester, source);
      expect(_text(tester), 'It starts with あきの.');
    });

    testWidgets('show romaji when the reader reads romaji', (tester) async {
      await _show(tester, source, options: const MarkdownOptions(romaji: true));
      expect(_text(tester), 'It starts with akino.');
    });

    testWidgets('keep their kana, on one line, before the romaji where the screen asks', (tester) async {
      await _show(tester, source, options: const MarkdownOptions(romaji: true, kanaBesideRomaji: true));
      expect(_text(tester), 'It starts with あ⁠き⁠の (akino).');
    });

    testWidgets('work in headings, lists and bold text', (tester) async {
      await _show(tester, '# {はる}\n\n- **{はるの}**', style: ProseStyle.guide, options: const MarkdownOptions(romaji: true));
      expect(_text(tester), allOf(contains('haru'), contains('haruno')));
      expect(_text(tester), isNot(contains('は')));
    });

    testWidgets('braces that start with a dot, and escaped braces, are no kana mark', (tester) async {
      await _show(tester, r'A {.red} and \{あ}', options: const MarkdownOptions(romaji: true));
      expect(_text(tester), 'A {.red} and {あ}');
    });
  });

  testWidgets('an HTML comment on lines of its own is left out', (tester) async {
    await _show(tester, 'Before.\n\n<!-- picture: a field | caption: Their side -->\n\nAfter.');
    expect(_text(tester), 'Before.\nAfter.');
  });

  group('headings', () {
    testWidgets('in a guide, # headings are chapters numbered in order, ## a small heading', (tester) async {
      await _show(tester, '# First\n\nText.\n\n## Detail\n\nMore.\n\n# 二番目 | Second', style: ProseStyle.guide);
      final chapters = tester.widgetList<ProseChapter>(find.byType(ProseChapter)).toList();
      expect([for (final c in chapters) (c.number, c.title, c.sub)], [(1, 'First', null), (2, '二番目', 'Second')]);
      expect(tester.widget<ProseSubhead>(find.byType(ProseSubhead)).text, 'Detail');
      expect(find.byType(MarkerHeading), findsNothing);
    });

    testWidgets('in an explanation, a # heading is a marker heading', (tester) async {
      await _show(tester, '# 解説 | Explanation\n\n## Section');
      expect(find.byType(MarkerHeading), findsOneWidget);
      expect(find.byType(ProseChapter), findsNothing);
    });
  });

  testWidgets('in a guide, a numbered list is steps; a bulleted one stays a list', (tester) async {
    await _show(tester, '1. Deal.\n2. Remember.\n\n- a point', style: ProseStyle.guide);
    expect([for (final s in tester.widgetList<ProseStep>(find.byType(ProseStep))) (s.number, s.line.toPlainText())],
        [(1, 'Deal.'), (2, 'Remember.')]);
    expect(_text(tester), contains('a point'));
  });
}
