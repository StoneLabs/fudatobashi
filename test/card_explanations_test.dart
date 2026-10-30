import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/manga/article_picture.dart';
import 'package:fudatobashi/ui/manga/markdown_blocks.dart';
import 'package:fudatobashi/ui/manga/markdown_prose.dart';
import 'package:fudatobashi/ui/manga/ruby_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a # heading is a marker heading; text after " | " is its sub', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: MarkdownProse('# 解説 | Explanation\n\ntext'))));
    expect(find.textContaining('解説', findRichText: true), findsOneWidget);
    expect(find.textContaining('Explanation', findRichText: true), findsOneWidget, reason: 'the sub after " | "');
  });

  testWidgets('every block an expert needs lays out as prose, a verse with furigana', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MarkdownProse(_sample)))));
    expect(tester.takeException(), isNull);
    expect(find.text('Section'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget, reason: 'the # heading is a marker heading');
    expect(find.byType(RubyText), findsNWidgets(2), reason: 'one per verse line');
    expect(find.byType(ArticlePicture), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
  });
}

const _sample = '''# Explanation

## Section

Text with **strong** and *emphasis*.

```${MarkdownBlocks.verseFence}
[秋|あき]の[田|た]の
わが[衣手|ころもで]は
```

### Sub-section

- one
- two

> A quote.

1. first
2. second

![A picture](assets/glyphs/308f.png)
''';
