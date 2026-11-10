// A line that gives way: at its own size where it fits, scaled down to a
// narrower room, left out where it would be under its least scale; and
// measured, as tall as the line at its own size, however narrow the room.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/ui/manga/give_way.dart';

void main() {
  // In the test font every letter is a square as wide as the font is tall:
  // 10 letters at 10 dp make a line 100 dp wide and 10 dp tall.
  const text = 'ABCDEFGHIJ';
  const line = Text(text, style: TextStyle(fontSize: 10, height: 1));

  Future<void> show(WidgetTester tester, double width) => tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: const Align(alignment: Alignment.topLeft, child: GiveWay(minScale: 0.75, child: line)),
          ),
        ),
      ));

  Size shown(WidgetTester tester) => tester.getSize(find.byType(GiveWay));

  testWidgets('at its own size where it fits', (tester) async {
    await show(tester, 120);
    expect(shown(tester), const Size(100, 10));
  });

  testWidgets('scaled down to a narrower room', (tester) async {
    await show(tester, 80);
    expect(shown(tester), const Size(80, 8));
    expect(tester.getRect(find.text(text)).width, moreOrLessEquals(80));
  });

  testWidgets('left out under its least scale, taking no room and saying nothing', (tester) async {
    final semantics = tester.ensureSemantics();
    await show(tester, 70);
    expect(shown(tester), Size.zero);
    expect(find.bySemanticsLabel(text), findsNothing);
    semantics.dispose();
  });

  testWidgets('measured as tall as the line, however narrow the room', (tester) async {
    await show(tester, 20);
    final box = tester.renderObject<RenderBox>(find.byType(GiveWay));
    expect(box.getMaxIntrinsicHeight(20), 10);
    expect(box.getMinIntrinsicWidth(double.infinity), 0);
  });
}
