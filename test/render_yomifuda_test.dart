// Renders every yomifuda to PNGs for visual checks against the photos in
// research/yomifuda:
//   flutter test test/render_yomifuda_test.dart
// Output: build/cards/yomifuda/yomi_NNN.png, 312 × 450 (6 px per mm).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/yomifuda_spec.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';
import 'package:fudatobashi/ui/torifuda/yomifuda_card.dart';

import 'test_vector_art.dart';

const _width = 312.0;

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  loadTestVectorArt();
  final p = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());

  test('every reading card has four columns that parse back to their markup, the kimariji first', () {
    String markup(YomifudaToken t) => t.isStretch
        ? (t.stretch == YomifudaSpec.longStretch ? 'ー' : 'ｰ')
        : t.reading == null
            ? t.text
            : '[${t.text}|${t.reading}]';
    for (final poem in p.all) {
      expect(poem.yomifudaColumns.length, 4);
      for (final column in poem.yomifudaColumns) {
        expect(YomifudaToken.parse(column).map(markup).join(), column, reason: '#${poem.id}');
      }
      final first = YomifudaToken.parse(poem.yomifudaColumns.first).fold(0, (sum, t) => sum + t.readingLength);
      expect(first, greaterThan(poem.kimarijiReading.length), reason: '#${poem.id}: the red kimariji fits the column');
    }
  });

  testWidgets('render reading cards', (tester) async {
    await tester.runAsync(() async {
      await _loadFont('Yomifuda', 'assets/fonts/YujiSyuku-Yomifuda.ttf');
      await _loadFont('ZenKaku', 'assets/fonts/ZenKakuGothicNew-Medium.ttf');
      await CardFaces.load([YomifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
      for (final poem in p.all) {
        final size = ui.Size(_width, _width * YomifudaSpec.aspect);
        final rec = ui.PictureRecorder();
        YomifudaPainter(poem: poem).paint(ui.Canvas(rec), size);
        final img = await rec.endRecording().toImage(size.width.round(), size.height.round());
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/cards/yomifuda/yomi_${poem.id.toString().padLeft(3, '0')}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });
}
