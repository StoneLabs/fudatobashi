// Renders the pre-rendered art (PrerenderedArt: the map's boat and the
// onboarding scenes) from its vector source into assets/art/:
//
//   flutter test tool/render_art_test.dart
//
// Each PNG is its vector's box at ArtRender.scale pixels per unit. Re-run it
// after changing any of that art.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/vector_art.dart';
import 'package:fudatobashi/ui/manga/vector.dart';

import '../test/test_vector_art.dart';

const outDir = 'assets/art';

void main() {
  loadTestVectorArt();

  testWidgets('render art', (tester) async {
    await tester.runAsync(() async {
      // The expert scene letters its 100 badge in the display font.
      final display = FontLoader(Fonts.display)
        ..addFont(Future.value(ByteData.sublistView(File('assets/fonts/DelaGothicOne-Regular.ttf').readAsBytesSync())));
      await display.load();

      Directory(outDir).createSync(recursive: true);
      for (final a in PrerenderedArt.all) {
        final size = a.art.box * ArtRender.scale;
        final rec = ui.PictureRecorder();
        VectorPainter.paint(ui.Canvas(rec), a.art, Offset.zero & size);
        final img = await rec.endRecording().toImage(size.width.ceil(), size.height.ceil());
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File(a.asset).writeAsBytesSync(png!.buffer.asUint8List());
      }
      // ignore: avoid_print
      print('Rendered ${PrerenderedArt.all.length} images into $outDir');
    });
  });
}
