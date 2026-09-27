// Renders the 47 torifuda kana from a font file into assets/glyphs/ as images,
// so the app can ship pre-rendered glyphs instead of the font itself.
//
//   FONT=/path/to/font.otf flutter test tool/render_glyphs_test.dart
//
// Without FONT it uses the bundled free font. Each PNG holds one kana drawn
// with Flutter's own text engine at [AtlasTuning.emPx] per em, its outline
// grown by [AtlasTuning.inkSpreadEm], and its em box centred in a square
// canvas of emPx × [AtlasTuning.pad], which is how TorifudaPainter places it.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';

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
      final box = (AtlasTuning.emPx * AtlasTuning.pad).round();
      Directory(outDir).createSync(recursive: true);
      for (final f in Directory(outDir).listSync()) {
        if (f.path.endsWith('.png')) f.deleteSync();
      }

      for (final ch in chars) {
        final rec = ui.PictureRecorder();
        final canvas = ui.Canvas(rec);
        _paintGlyph(canvas, ch, box, Paint()..color = const Color(0xFF000000));
        _paintGlyph(
          canvas,
          ch,
          box,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * AtlasTuning.inkSpreadEm * AtlasTuning.emPx
            ..strokeJoin = StrokeJoin.round,
        );
        final img = await rec.endRecording().toImage(box, box);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$outDir/${ch.codeUnitAt(0).toRadixString(16)}.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
      File('$outDir/meta.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
        'source': fontPath.split('/').last,
        'emPx': AtlasTuning.emPx,
        'pad': AtlasTuning.pad,
        'chars': chars.join(),
      }));
      // ignore: avoid_print
      print('Rendered ${chars.length} glyphs from $fontPath into $outDir');
    });
  });
}

/// Paints [ch] with its em box centred in a [box]-pixel square.
void _paintGlyph(ui.Canvas canvas, String ch, int box, Paint paint) {
  final tp = TextPainter(
    text: TextSpan(
      text: ch,
      style: TextStyle(fontFamily: 'GlyphSource', fontSize: AtlasTuning.emPx, foreground: paint),
    ),
    // A zero-leading strut makes the line box exactly the em box
    // (ascender to descender), whatever line gap the font declares.
    strutStyle: const StrutStyle(
        fontFamily: 'GlyphSource', fontSize: AtlasTuning.emPx, leading: 0, forceStrutHeight: true),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(box / 2 - tp.width / 2, box / 2 - tp.height / 2));
  tp.dispose();
}
