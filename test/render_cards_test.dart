// Renders torifuda to PNGs for visual checks and calibration:
//   flutter test test/render_cards_test.dart
// Output: build/cards/*.png (card space 374×525, scale 2).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/card_mask.dart';
import 'package:fudatobashi/domain/masking.dart';
import 'package:fudatobashi/ui/torifuda/glyph_atlas.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_spec.dart';

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Future<void> _render(Poem poem, String name, {double scale = 1, bool inverted = false, CardMask mask = CardMask.none}) async {
  final size = ui.Size(TorifudaSpec.width * scale, TorifudaSpec.height * scale);
  final rec = ui.PictureRecorder();
  TorifudaPainter(poem: poem, inverted: inverted, mask: mask).paint(ui.Canvas(rec), size);
  final img = await rec.endRecording().toImage(size.width.round(), size.height.round());
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File('build/cards/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  final p = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());

  testWidgets('render cards', (tester) async {
    await tester.runAsync(() async {
      await _loadFont('Torifuda', 'assets/fonts/YujiSyuku-Regular.ttf');
      await _loadFont('TorifudaNumber', 'assets/fonts/TeXGyreSchola-Regular.otf');
      if (Platform.environment['GLYPHS'] != 'text') await GlyphAtlas.load();
      // Calibration size: exactly the original artwork's pixel grid.
      for (var id = 1; id <= 100; id++) {
        await _render(p[id], 'calib/fuda${id.toString().padLeft(3, '0')}');
      }
      await _render(p[87], 'inverted_087', scale: 2, inverted: true);
      final rng = math.Random(3);
      for (var level = 1; level <= Masking.maxLevel; level++) {
        for (final style in [MaskStyle.scramble, MaskStyle.blank]) {
          await _render(p[87], 'mask_087_l${level}_${style.name}',
              scale: 2, mask: Masking.maskFor(p, 87, level, rng, style: style));
        }
      }
    });
  });
}
