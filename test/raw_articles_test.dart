import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/debug/raw_articles_page.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final k in [...files.keys, 'assets/l10n/en_articles/notes.txt', 'assets/other/x.md']) k: <Object>[],
      })!;
    }
    final text = files[key];
    if (text == null) throw FlutterError('missing $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

void main() {
  testWidgets('raw articles: lists the manifest files and opens one as written', (tester) async {
    final bundle = _Bundle({
      'assets/l10n/en_articles/sample.md': '# Sample\n{% if env.romaji_mode %}ro{% else %}ka{% endif %}\n<!-- note -->',
      'assets/l10n/ja_articles/card_details/001.md': 'card one',
    });
    await tester.pumpWidget(MaterialApp(home: RawArticlesPage(bundle: bundle)));
    await tester.pumpAndSettle();

    expect(find.text('sample.md'), findsOneWidget);
    expect(find.text('notes.txt'), findsNothing);
    expect(find.text('x.md'), findsNothing);
    expect(find.text('001.md'), findsNothing);
    await tester.tap(find.textContaining('ja/card_details'));
    await tester.pumpAndSettle();
    expect(find.text('001.md'), findsOneWidget);

    await tester.tap(find.text('sample.md'));
    await tester.pumpAndSettle();
    expect(find.textContaining('{% if env.romaji_mode %}', findRichText: true), findsOneWidget);
    expect(find.textContaining('<!-- note -->', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Romaji'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ro<!-- note -->', findRichText: true), findsOneWidget);
  });
}
