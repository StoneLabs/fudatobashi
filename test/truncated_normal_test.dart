// A normal draw drawn again past its cut-off: every draw within it, its
// spread as its density has it, and the density adding up to the whole.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/domain/truncated_normal.dart';

void main() {
  const narrow = TruncatedNormal(sd: 100, cutOff: 200);
  const wide = TruncatedNormal(sd: 239, cutOff: 600);

  // The integral of [f] from [from] to [to], by the midpoint rule.
  double integral(double Function(double x) f, double from, double to, {int steps = 20000}) {
    final h = (to - from) / steps;
    var sum = 0.0;
    for (var i = 0; i < steps; i++) {
      sum += f(from + (i + 0.5) * h);
    }
    return sum * h;
  }

  for (final draw in [narrow, wide]) {
    final name = 'sd ${draw.sd.round()}, cut at ±${draw.cutOff.round()}';
    group(name, () {
      final rng = math.Random(7);
      final draws = [for (var i = 0; i < 40000; i++) draw.sample(rng)];

      test('every draw is within the cut-off', () {
        expect(draws.every((x) => x.abs() <= draw.cutOff), isTrue);
        expect(draws.any((x) => x.abs() > draw.cutOff * 0.9), isTrue, reason: 'it reaches near the cut-off');
      });

      test('its density adds up to 1 within the cut-off, and is 0 past it', () {
        expect(integral(draw.density, -draw.cutOff, draw.cutOff), closeTo(1, 1e-4));
        expect(draw.density(draw.cutOff + 1), 0);
        expect(draw.density(-draw.cutOff - 1), 0);
        expect(draw.density(0), greaterThan(draw.density(draw.sd)));
      });

      test('its draws centre on 0, spread as its density has it', () {
        final mean = draws.reduce((a, b) => a + b) / draws.length;
        final sd = math.sqrt(draws.fold(0.0, (sum, x) => sum + (x - mean) * (x - mean)) / draws.length);
        final expected = math.sqrt(integral((x) => x * x * draw.density(x), -draw.cutOff, draw.cutOff));
        expect(mean.abs(), lessThan(draw.sd * 0.02));
        expect(sd, closeTo(expected, expected * 0.02));
        expect(expected, lessThan(draw.sd), reason: 'the cut-off narrows it');
      });

      test('its shares match its density and its draws', () {
        expect(draw.share(-draw.cutOff, draw.cutOff), closeTo(1, 1e-6));
        expect(draw.share(-2 * draw.cutOff, 2 * draw.cutOff), closeTo(1, 1e-6));
        expect(draw.share(draw.cutOff, 2 * draw.cutOff), 0);
        expect(draw.share(0, draw.cutOff), closeTo(0.5, 1e-6));
        final within = draw.sd;
        expect(draw.share(-within, within), closeTo(integral(draw.density, -within, within), 1e-4));
        final drawn = draws.where((x) => x.abs() <= within).length / draws.length;
        expect(draw.share(-within, within), closeTo(drawn, 0.01));
      });
    });
  }

  test('sd 239 cut at ±600 puts 80% of draws within ±300', () {
    expect(wide.share(-300, 300), closeTo(0.8, 0.001));
  });

  test('the same seed gives the same draws', () {
    final a = math.Random(3), b = math.Random(3);
    expect([for (var i = 0; i < 20; i++) narrow.sample(a)], [for (var i = 0; i < 20; i++) narrow.sample(b)]);
  });
}
