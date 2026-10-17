import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/card_explanations.dart';
import 'package:fudatobashi/ui/manga/markdown_prose.dart';
import 'package:fudatobashi/ui/manga/ruby_text.dart';
import 'package:markdown/markdown.dart' as md;

/// Every element tag in [nodes], nested ones too, with a fence's language.
Set<String> _tags(List<md.Node> nodes) => {
      for (final n in nodes)
        if (n is md.Element) ...{
          n.tag,
          ?n.attributes['class'],
          ..._tags(n.children ?? const []),
        },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every card has an explanation in English and Japanese', () {
    for (final code in ['en', 'ja']) {
      for (var id = 1; id <= 100; id++) {
        expect(File(CardExplanations.asset(code, id)).existsSync(), isTrue, reason: '$code #$id');
      }
    }
  });

  for (final code in ['en', 'ja']) {
    test('card 1\'s explanation uses every kind of block an expert needs ($code)', () async {
      final nodes = MarkdownProse.parse(await CardExplanations.load(code, 1));
      final tags = _tags(nodes);
      for (final tag in ['h1', 'h2', 'h3', 'p', 'strong', 'em', 'ul', 'ol', 'li', 'blockquote', 'pre', 'img']) {
        expect(tags, contains(tag), reason: tag);
      }
      expect(tags, contains('language-${MarkdownProse.verseFence}'));
      expect(nodes.whereType<md.Element>().where((e) => e.tag == 'h2').length, greaterThan(1));
      final img = [for (final n in nodes) if (n is md.Element && n.tag == 'p') ...?n.children]
          .whereType<md.Element>()
          .firstWhere((e) => e.tag == 'img');
      expect(File(img.attributes['src']!).existsSync(), isTrue, reason: 'the picture is a bundled asset');
    });

    test('a card without an explanation yet says it is coming ($code)', () async {
      final nodes = MarkdownProse.parse(await CardExplanations.load(code, 20));
      final heading = nodes.whereType<md.Element>().where((e) => e.tag == 'h2').single;
      expect(heading.textContent, code == 'en' ? 'Coming soon' : '準備中');
    });
  }

  testWidgets('a # heading is a marker heading; text after " | " is its sub', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MarkdownProse('# 解説 | Explanation\n\ntext'))));
    expect(find.textContaining('解説', findRichText: true), findsOneWidget);
    expect(find.textContaining('Explanation', findRichText: true), findsOneWidget, reason: 'the sub after " | "');
  });

  testWidgets('card 1\'s explanation lays out as prose, its verse with furigana', (tester) async {
    final source = File(CardExplanations.asset('en', 1)).readAsStringSync();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MarkdownProse(source)))));
    expect(tester.takeException(), isNull);
    expect(find.text('What the poem says'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget, reason: 'the # heading is a marker heading');
    expect(find.byType(RubyText), findsNWidgets(3), reason: 'one per verse line');
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('3.'), findsOneWidget);
  });
}
