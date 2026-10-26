// Renders every yomifuda, and the 序歌's, to PNGs for visual checks against
// the photos in research/yomifuda:
//   flutter test test/render_yomifuda_test.dart
// Output: build/cards/yomifuda/yomi_NNN.png and yomi_joka.png, 312 × 450
// (6 px per mm).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/yomifuda_spec.dart';
import 'package:fudatobashi/data/joka.dart';
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
    for (final poem in p.all) {
      expect(poem.yomifudaColumns.length, 4);
      for (final column in poem.yomifudaColumns) {
        expect(YomifudaToken.parse(column).map(_markup).join(), column, reason: '#${poem.id}');
      }
      final first = YomifudaToken.parse(poem.yomifudaColumns.first).fold(0, (sum, t) => sum + t.readingLength);
      expect(first, greaterThan(poem.kimarijiReading.length), reason: '#${poem.id}: the red kimariji fits the column');
    }
  });

  test('the 序歌\'s reading card has four columns that parse back to their markup', () {
    final joka = Waka.fromJsonString(File(jokaAsset).readAsStringSync());
    expect(joka.yomifudaColumns.length, 4);
    for (final column in joka.yomifudaColumns) {
      expect(YomifudaToken.parse(column).map(_markup).join(), column);
    }
  });

  testWidgets('render reading cards; the 序歌 has no kimariji, so only its title is red', (tester) async {
    final joka = Waka.fromJsonString(File(jokaAsset).readAsStringSync());
    final red = YomifudaStyle.standard.kimariji;
    bool isRed(int r, int g, int b) =>
        (r - red.r * 255).abs() < 40 && (g - red.g * 255).abs() < 40 && (b - red.b * 255).abs() < 40;
    final reds = <String, int>{};
    // Each card's red pixels, the leftmost and rightmost, as x across it.
    final redSpans = <String, (int, int)>{};
    await tester.runAsync(() async {
      await _loadFont('YujiSyuku', 'assets/fonts/YujiSyuku-Regular.ttf');
      await _loadFont('TorifudaNumber', 'assets/fonts/TeXGyreSchola-Regular.otf');
      await CardFaces.load([YomifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
      for (final (name, waka) in [
        for (final poem in p.all) (poem.id.toString().padLeft(3, '0'), poem),
        ('joka', joka),
      ]) {
        final size = ui.Size(_width, _width * YomifudaSpec.aspect);
        final rec = ui.PictureRecorder();
        YomifudaPainter(poem: waka).paint(ui.Canvas(rec), size);
        final img = await rec.endRecording().toImage(size.width.round(), size.height.round());
        final rgba = (await img.toByteData())!.buffer.asUint8List();
        var count = 0;
        var (left, right) = (img.width, -1);
        for (var i = 0; i < rgba.length; i += 4) {
          if (!isRed(rgba[i], rgba[i + 1], rgba[i + 2])) continue;
          count++;
          final x = i ~/ 4 % img.width;
          (left, right) = (math.min(left, x), math.max(right, x));
        }
        reds[name] = count;
        redSpans[name] = (left, right);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/cards/yomifuda/yomi_$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
    expect(reds['001'], greaterThan(0), reason: 'a card\'s kimariji is red');
    expect(reds['joka'], greaterThan(0), reason: 'the 序歌\'s title is red');
    final (left, right) = redSpans['joka']!;
    const title = YomifudaSpec.titleX * _width, em = YomifudaSpec.em * _width;
    expect(left, greaterThan(title - em / 2), reason: 'red only in the title\'s column');
    expect(right, lessThan(title + em / 2), reason: 'red only in the title\'s column');
  });
}

String _markup(YomifudaToken t) => t.isStretch
    ? (t.stretch == YomifudaSpec.longStretch ? 'ー' : 'ｰ')
    : t.reading == null
        ? t.text
        : '[${t.text}|${t.reading}]';
