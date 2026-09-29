// Shared by the tests that play through PlayScreen, whose deck always opens
// with the start card on top.
import 'package:flutter_test/flutter_test.dart';

/// Flicks the start card away and pumps until the first card is revealed.
Future<void> swipeStartCard(WidgetTester tester, {Offset from = const Offset(192, 360)}) async {
  final g = await tester.startGesture(from);
  for (var i = 0; i < 4; i++) {
    await g.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 8));
  }
  await g.up();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}
