// Helpers for tests on the Side Trips tab.
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/ui/side_trips/dojo_scene.dart';

/// The island in front of the Side Trips tab's ring.
SideTripIsle frontIsle(WidgetTester tester) {
  final scene = tester.widget<DojoScene>(find.byType(DojoScene));
  return scene.ring.frontAt(scene.turn.value.round());
}

/// Swipes the ring on, a step at a time, until [isle] is in front,
/// wherever the ring's order puts it.
Future<void> turnRingTo(WidgetTester tester, SideTripIsle isle) async {
  for (var i = 0; i < SideTripIsle.values.length && frontIsle(tester) != isle; i++) {
    await tester.fling(find.byType(DojoScene), const Offset(-200, 0), 1200);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  }
  expect(frontIsle(tester), isle);
}
