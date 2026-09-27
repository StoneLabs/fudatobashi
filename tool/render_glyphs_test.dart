// Renders the 47 torifuda kana from a font file into assets/glyphs/ as images,
// so the app can ship pre-rendered glyphs instead of the font itself.
//
//   FONT=/path/to/font.otf flutter test tool/render_glyphs_test.dart
//
// Without FONT it uses the bundled free font. Each PNG holds one kana drawn
// with Flutter's own text engine at [emPx] per em, its em box centred in a
// square canvas of emPx × [pad], exactly like TorifudaPainter places text, so
// swapping text for images changes nothing but the source of the glyph.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const emPx = 256.0;
const pad = 1.3;
const outDir = 'assets/glyphs';

void main() {
  testWidgets('render glyph atlas', (tester) async {
    await tester.runAsync(() async {
      final fontPath = Platform.environment['FONT'] ?? 'assets/fonts/YujiSyuku-Regular.ttf';
      final loader = FontLoader('GlyphSource')
        ..addFont(Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())));
      await loader.load();

      final poems = jsonDecode(File('assets/data/poems.json').readAsStringSync()) as List;
      final chars = ({for (final p in poems) ...(p['torifuda'] as String).split('')}.toList()..sort());
      final box = (emPx * pad).round();
      Directory(outDir).createSync(recursive: true);
      for (final f in Directory(outDir).listSync()) {
        if (f.path.endsWith('.png')) f.deleteSync();
      }

      for (final ch in chars) {
        final tp = TextPainter(
          text: TextSpan(
            text: ch,
            style: const TextStyle(fontFamily: 'GlyphSource', fontSize: emPx, height: 1.0, color: Color(0xFF000000)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final rec = ui.PictureRecorder();
        tp.paint(ui.Canvas(rec), Offset(box / 2 - tp.width / 2, box / 2 - tp.height / 2));
        final img = await rec.endRecording().toImage(box, box);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$outDir/${ch.codeUnitAt(0).toRadixString(16)}.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
      File('$outDir/meta.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
        'source': fontPath.split('/').last,
        'emPx': emPx,
        'pad': pad,
        'chars': chars.join(),
      }));
      // ignore: avoid_print
      print('Rendered ${chars.length} glyphs from $fontPath into $outDir');
    });
  });
}
