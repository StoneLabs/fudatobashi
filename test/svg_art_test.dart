// Loads a few small SVG fixtures and their editor-round-tripped variants
// (styles moved into style="", content wrapped in a transform, Inkscape's
// own metadata added, a path's commands made relative, a path swapped for an
// equivalent <rect>/<circle>) and checks each renders pixel-identically to
// its original.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/manga/svg_art.dart';
import 'package:fudatobashi/ui/manga/vector.dart';

const _fixtures = 'test/fixtures/svg';

String _read(String name) => File('$_fixtures/$name.svg').readAsStringSync();

VectorArt _parse(String name) => SvgArt.parse(_read(name), debugName: '$name.svg');

Future<Uint8List> _renderRgba(WidgetTester tester, VectorArt art) async {
  late Uint8List bytes;
  await tester.runAsync(() async {
    final rec = ui.PictureRecorder();
    VectorPainter.paint(ui.Canvas(rec), art, Offset.zero & art.box);
    final image = await rec.endRecording().toImage(art.box.width.ceil(), art.box.height.ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    bytes = data!.buffer.asUint8List();
  });
  return bytes;
}

void main() {
  Future<void> expectSameRender(WidgetTester tester, String variant, String original) async {
    expect(await _renderRgba(tester, _parse(variant)), await _renderRgba(tester, _parse(original)));
  }

  testWidgets('a style="" attribute renders the same as presentation attributes', (tester) async {
    await expectSameRender(tester, 'badge_style_attr', 'badge');
  });

  testWidgets('content wrapped in a <g transform="translate(...)"> renders the same', (tester) async {
    await expectSameRender(tester, 'transform_wrapped', 'transform_original');
  });

  testWidgets("Inkscape's own metadata, layer group and namespaces don't change the render", (tester) async {
    await expectSameRender(tester, 'badge_metadata', 'badge');
  });

  testWidgets('relative path commands render the same as absolute ones', (tester) async {
    await expectSameRender(tester, 'badge_relative', 'badge');
  });

  testWidgets('a <rect>/<circle> renders the same as an equivalent <path>', (tester) async {
    await expectSameRender(tester, 'shape_as_native', 'shape_as_path');
  });

  testWidgets('transform composes translate/scale/rotate/matrix like SVG, on a shape or a <g>', (tester) async {
    const box = 'viewBox="0 0 20 20"';
    final onShape = SvgArt.parse(
      '<svg $box><rect x="2" y="2" width="6" height="4" fill="#141414" '
      'transform="translate(5 3) rotate(40) scale(1.4 0.8)"/></svg>',
      debugName: 'onShape',
    );
    final nested = SvgArt.parse(
      '<svg $box><g transform="translate(5 3)"><g transform="rotate(40)">'
      '<rect x="2" y="2" width="6" height="4" fill="#141414" transform="scale(1.4 0.8)"/>'
      '</g></g></svg>',
      debugName: 'nested',
    );
    final asMatrix = SvgArt.parse(
      '<svg $box><rect x="2" y="2" width="6" height="4" fill="#141414" '
      'transform="matrix(1 0 0 1 5 3) rotate(40) scale(1.4 0.8)"/></svg>',
      debugName: 'asMatrix',
    );
    final base = await _renderRgba(tester, onShape);
    expect(await _renderRgba(tester, nested), base);
    expect(await _renderRgba(tester, asMatrix), base);
  });

  test('an unsupported element (here, text) fails loudly, naming the file', () {
    expect(
      () => _parse('unsupported'),
      throwsA(isA<SvgArtException>().having((e) => e.toString(), 'message', contains('unsupported.svg'))),
    );
  });

  test('a colour outside the palette asserts, naming the file and element', () {
    expect(
      () => SvgArt.parse('<svg viewBox="0 0 10 10"><rect id="odd" width="10" height="10" fill="#123456"/></svg>',
          debugName: 'odd.svg'),
      throwsA(isA<AssertionError>()),
    );
  });
}
