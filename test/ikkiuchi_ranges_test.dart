// 一騎打ち's developer view of Tobi's curves: the range each value spans at a
// rating, from his form a match and his own draws a card.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_values.dart';

void main() {
  const sd = IkkiuchiTuning.formSd, cutOff = IkkiuchiTuning.formCutOff;
  const min = IkkiuchiTuning.ratingMin, max = IkkiuchiTuning.ratingMax;

  group('a value drawn per card', () {
    final drawn = IkkiuchiValue('drawn', IkkiuchiUnit.ms, (_) => 1000, drawSpread: (_) => 0.5);

    test('spans median × e^±σ at 1σ and e^±2σ at 2σ', () {
      final (lo, hi) = drawn.cardRange(1600, 1)!;
      expect(lo, closeTo(1000 * math.exp(-0.5), 1e-9));
      expect(hi, closeTo(1000 * math.exp(0.5), 1e-9));
      final (lo2, hi2) = drawn.cardRange(1600, 2)!;
      expect(lo2, closeTo(1000 * math.exp(-1), 1e-9));
      expect(hi2, closeTo(1000 * math.exp(1), 1e-9));
    });

    test('reads its range with the unit once', () {
      expect(drawn.cardRangeText(1600, 1), '0.61–1.65 s');
      expect(IkkiuchiUnit.ms.range(200, 900), '200–900 ms');
      expect(IkkiuchiUnit.ms.range(1130, 10200), '1.13–10.2 s');
      expect(IkkiuchiUnit.percent.range(0.004, 0.012), '0.4–1.2%');
      expect(IkkiuchiUnit.percent.range(0.26, 0.32), '26–32%');
    });

    test("is Tobi's take time, spread by his take spread", () {
      final take = ikkiuchiValueGroups.expand((g) => g.rows).firstWhere((v) => v.name == 'take time');
      const tobi = IkkiuchiTobi(1600);
      final (lo, hi) = take.cardRange(1600, 1)!;
      expect(lo, closeTo(tobi.takeMs * math.exp(-tobi.takeSpread), 1e-9));
      expect(hi, closeTo(tobi.takeMs * math.exp(tobi.takeSpread), 1e-9));
    });
  });

  group('a value read from his curves', () {
    final rising = IkkiuchiValue('rising', IkkiuchiUnit.plain, (t) => t.rating);
    final falling = IkkiuchiValue('falling', IkkiuchiUnit.plain, (t) => max - t.rating);

    test('spans the ratings his form reaches, 1 sd and 2 sd each way, never past its cut-off', () {
      final reach2 = math.min(2 * sd, cutOff);
      expect(ikkiuchiFormReach(1), math.min(sd, cutOff));
      expect(ikkiuchiFormReach(2), reach2);
      expect(ikkiuchiFormReach(cutOff / sd + 1), cutOff);
      expect(rising.matchRange(1600, 1), (1600 - sd, 1600 + sd));
      expect(rising.matchRange(1600, 2), (1600 - reach2, 1600 + reach2));
      expect(falling.matchRange(1600, 1), (max - 1600 - sd, max - 1600 + sd));
    });

    test('stops at the ends of the rating range', () {
      final reach2 = ikkiuchiFormReach(2);
      expect(rising.matchRange(min, 1), (min, min + sd));
      expect(rising.matchRange(min + sd / 2, 2), (min, min + sd / 2 + reach2));
      expect(rising.matchRange(max, 2), (max - reach2, max));
      expect(falling.matchRange(max, 1), (0, sd));
    });

    test('has no per-card range unless he draws it per card', () {
      expect(rising.cardRange(1600, 1), isNull);
      expect(rising.cardRangeText(1600, 1), ikkiuchiNoRange);
    });

    test('reads as one value where his form doesn\'t move it', () {
      final flat = IkkiuchiValue('flat', IkkiuchiUnit.percent, (_) => 0);
      expect(flat.matchRangeText(1600, 2), '0%');
    });
  });

  test('a fixed value has no range at all', () {
    const fixed = IkkiuchiValue.fixed('fixed', IkkiuchiUnit.ms, 350);
    expect(fixed.at(min), 350);
    expect(fixed.at(max), 350);
    for (final s in IkkiuchiToolsTuning.sigmas) {
      expect(fixed.matchRange(1600, s), isNull);
      expect(fixed.cardRange(1600, s), isNull);
      expect(fixed.matchRangeText(1600, s), ikkiuchiNoRange);
      expect(fixed.cardRangeText(1600, s), ikkiuchiNoRange);
    }
    expect(ikkiuchiNoRange, '—');
  });
}
