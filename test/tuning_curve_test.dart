// A tuning curve: a value by x through its points.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/domain/tuning_curve.dart';

void main() {
  const plain = TuningCurve([(0, 10), (1000, 20), (3000, 0)]);
  const log = TuningCurve.log([(0, 1000), (2000, 10)]);

  test('gives each point its value exactly', () {
    expect(plain.at(0), 10);
    expect(plain.at(1000), 20);
    expect(plain.at(3000), 0);
    expect(log.at(2000), 10);
  });

  test('never overshoots on a falling, a rising or a plateau stretch', () {
    void checkWithin(TuningCurve c) {
      for (var i = 1; i < c.anchors.length; i++) {
        final (x0, v0) = c.anchors[i - 1];
        final (x1, v1) = c.anchors[i];
        final lo = math.min(v0, v1), hi = math.max(v0, v1);
        double? last;
        for (var x = x0; x <= x1; x += (x1 - x0) / 50) {
          final v = c.at(x);
          expect(v, inInclusiveRange(lo - 1e-9, hi + 1e-9), reason: 'at $x');
          if (last != null && v1 < v0) expect(v, lessThanOrEqualTo(last + 1e-9), reason: 'at $x');
          if (last != null && v1 > v0) expect(v, greaterThanOrEqualTo(last - 1e-9), reason: 'at $x');
          last = v;
        }
      }
    }

    checkWithin(const TuningCurve([(0, 100), (500, 90), (1000, 20), (2000, 10), (3000, 0)]));
    checkWithin(const TuningCurve([(0, 0), (500, 5), (1000, 80), (2000, 90), (3000, 100)]));
    checkWithin(const TuningCurve.log([(0, 3000), (1000, 500), (2000, 400), (3000, 100)]));
    const plateau = TuningCurve([(0, 0), (1000, 50), (2000, 50), (3000, 80)]);
    for (var x = 1000.0; x <= 2000; x += 50) {
      expect(plateau.at(x), closeTo(50, 1e-9), reason: 'at $x');
    }
  });

  test('two points are a straight line', () {
    const line = TuningCurve([(0, 10), (1000, 30)]);
    for (var x = 0.0; x <= 1000; x += 125) {
      expect(line.at(x), closeTo(10 + 20 * x / 1000, 1e-9));
    }
  });

  test('a log curve reads straight on a log scale between two points', () {
    expect(log.at(1000), closeTo(100, 1e-9));
    expect(log.at(500), closeTo(1000 * math.pow(0.01, 0.25), 1e-9));
  });

  test('a log curve with evenly falling points gives the midpoint of the logs', () {
    const c = TuningCurve.log([(0, 1000), (1000, 100), (2000, 10)]);
    expect(c.at(500), closeTo(math.sqrt(1000 * 100), 1e-6));
  });

  test('is held flat past its ends', () {
    expect(plain.at(-500), 10);
    expect(plain.at(9999), 0);
    expect(log.at(-1), 1000);
    expect(log.at(3600), 10);
  });
}
