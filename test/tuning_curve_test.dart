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

  test('without set slopes reads as it always has', () {
    const falling = TuningCurve.log([
      (0, 3400), (400, 2900), (800, 2350), (1200, 1800), (1600, 1300), (2000, 880),
      (2400, 600), (2800, 400), (3200, 260), (3400, 215), (3600, 180),
    ]);
    const rising = TuningCurve([(0, 0), (800, 0.05), (1600, 0.2), (2400, 0.45), (2800, 0.6), (3600, 0.75)]);
    final before = {
      falling: [3237.463530533864, 2690.5511512526164, 1184.844060352965, 340.0931100866815, 187.1415757264835],
      rising: [0.0020739378417968754, 0.027749322509765632, 0.22491978236607144, 0.63812255859375, 0.746744759427584],
      plain: [12.212198823333333, 17.653403750000003, 18.080833333333334, 1.1459375000000036, 0.0],
      log: [729.4575102545684, 278.61211686297696, 19.952623149688822, 10.0, 10.0],
    };
    for (final MapEntry(key: curve, value: values) in before.entries) {
      for (final (i, x) in [137.0, 555.0, 1700.0, 2950.0, 3555.0].indexed) {
        expect(curve.at(x), values[i], reason: '${curve.anchors} at $x');
      }
    }
  });

  group('a set slope', () {
    const e = 1e-3;
    double slopeAt(double Function(double) f, double x) => (f(x + e) - f(x - e)) / (2 * e);
    double leftSlope(double Function(double) f, double x) => (f(x) - f(x - e)) / e;
    double rightSlope(double Function(double) f, double x) => (f(x + e) - f(x)) / e;

    const points = [(0.0, 100.0), (1000.0, 80.0), (2000.0, 30.0), (3000.0, 20.0)];
    const auto = TuningCurve(points);
    const set = TuningCurve(points, slopes: [(2000, -0.01)]);

    test('is the slope at its point, from either side', () {
      expect(slopeAt(set.at, 2000), closeTo(-0.01, 1e-6));
      expect(leftSlope(set.at, 2000), closeTo(-0.01, 1e-4));
      expect(rightSlope(set.at, 2000), closeTo(-0.01, 1e-4));
      expect(set.at(2000), 30);
    });

    test("leaves the other points' slopes as they were", () {
      for (var x = 0.0; x <= 1000; x += 50) {
        expect(set.at(x), auto.at(x), reason: 'at $x, away from the set point');
      }
      expect(rightSlope(set.at, 1000), closeTo(rightSlope(auto.at, 1000), 1e-6));
      expect(leftSlope(set.at, 3000), closeTo(leftSlope(auto.at, 3000), 1e-6));
      expect(slopeAt(set.at, 2000), isNot(closeTo(slopeAt(auto.at, 2000), 1e-3)));
    });

    test('is of ln y on a log curve', () {
      const c = TuningCurve.log([(0, 1000), (1000, 100), (2000, 10)], slopes: [(1000, -0.001)]);
      expect(slopeAt((x) => math.log(c.at(x)), 1000), closeTo(-0.001, 1e-7));
      expect(c.at(1000), closeTo(100, 1e-9));
    });

    test('works on two points', () {
      const c = TuningCurve([(0, 0), (1000, 10)], slopes: [(0, 0)]);
      expect(rightSlope(c.at, 0), closeTo(0, 1e-4));
      expect(leftSlope(c.at, 1000), closeTo(0.01, 1e-4));
      expect(c.at(-5), 0);
      expect(c.at(2000), 10);
    });

    test('at an x with no point fails an assert', () {
      expect(() => TuningCurve(const [(0, 1), (10, 2)], slopes: const [(5, 1)]).at(3), throwsA(isA<AssertionError>()));
    });
  });
}
