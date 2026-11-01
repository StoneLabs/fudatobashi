// Renders the little marks beside the lines of 暗記練's and 定位置's rules
// (遊び方) to PNGs in build/rule_marks/, each the whole mark: its box, fill,
// ink border and icon, at 4 pixels per dp of AnkirenRulesLayout.markBox.
//
//   ./scripts/rule_marks.sh      renders them and converts them to lossless
//                                WebP in assets/graphics/sidetrips/rules/
//
// Run on its own, `flutter test tool/rule_marks/render_marks_test.dart` only
// writes the PNGs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/vector_art.dart';
import 'package:fudatobashi/ui/ankiren/ankiren_strikes.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import '../../test/test_vector_art.dart';

const _out = 'build/rule_marks';
const _pixelRatio = 4.0;

/// A mark: its file, its fill and what is drawn in the box.
typedef _Mark = ({String name, Color color, Widget icon});

Widget _icon(VectorArt art, Color color) =>
    MangaIcon(art, size: AnkirenRulesLayout.markIcon, color: color, strokeWidth: AnkirenRulesLayout.markIconStroke);

List<_Mark> _marks() => [
      (name: 'wrong', color: Palette.pinkSoft, icon: _icon(IconArt.close, Palette.ink)),
      (name: 'dont-know', color: Palette.desk, icon: _icon(IconArt.question, Palette.ink)),
      (name: 'leave', color: Palette.ink, icon: _icon(IconArt.end, Palette.paper)),
      (
        name: 'strikes',
        color: Palette.pinkSoft,
        icon: const AnkirenStrikes(strikes: 1, count: 1, cardHeight: AnkirenRulesLayout.markStrike),
      ),
      (name: 'karafuda', color: Palette.paper, icon: _icon(IconArt.karafuda, Palette.ink)),
      (name: 'cards', color: Palette.paper, icon: _icon(IconArt.cards, Palette.ink)),
      (name: 'tap', color: Palette.sun, icon: _icon(IconArt.cards, Palette.ink)),
      (name: 'early', color: Palette.sun, icon: _icon(IconArt.history, Palette.ink)),
      (name: 'clock', color: Palette.shallow, icon: _icon(IconArt.history, Palette.ink)),
      (name: 'to-end', color: Palette.land, icon: _icon(IconArt.end, Palette.ink)),
      (name: 'width', color: Palette.paper, icon: const _WidthIcon()),
    ];

void main() {
  loadTestVectorArt();

  for (final mark in _marks()) {
    testWidgets(mark.name, (tester) async {
      tester.view
        ..devicePixelRatio = _pixelRatio
        ..physicalSize = const Size.square(AnkirenRulesLayout.markBox * _pixelRatio * 2);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const ValueKey('mark'),
            child: Container(
              width: AnkirenRulesLayout.markBox,
              height: AnkirenRulesLayout.markBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mark.color,
                border: Border.all(color: Palette.ink, width: AnkirenRulesLayout.markBorder),
              ),
              child: mark.icon,
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('mark')));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_out/mark-${mark.name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }
}

/// A row's width: two upright bars with a double-headed arrow between them,
/// inked like the other marks' icons.
class _WidthIcon extends StatelessWidget {
  const _WidthIcon();

  @override
  Widget build(BuildContext context) => CustomPaint(size: AnkirenRulesLayout.markWidthIcon, painter: _WidthPainter());
}

class _WidthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = AnkirenRulesLayout.markIconStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final half = AnkirenRulesLayout.markIconStroke / 2;
    final left = half, right = size.width - half, mid = size.height / 2;
    const head = AnkirenRulesLayout.markWidthHead;
    canvas.drawLine(Offset(left, 0), Offset(left, size.height), pen);
    canvas.drawLine(Offset(right, 0), Offset(right, size.height), pen);
    final from = left + 2.8 * half, to = right - 2.8 * half;
    canvas.drawLine(Offset(from, mid), Offset(to, mid), pen..strokeCap = StrokeCap.butt);
    canvas.drawPath(
        Path()
          ..moveTo(from + head, mid - head)
          ..lineTo(from - half, mid)
          ..lineTo(from + head, mid + head)
          ..close()
          ..moveTo(to - head, mid - head)
          ..lineTo(to + half, mid)
          ..lineTo(to - head, mid + head)
          ..close(),
        pen..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_WidthPainter old) => false;
}
