import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/masking.dart';

void main() {
  final p = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());

  test('every mask at every level keeps the card unique', () {
    final rng = math.Random(42);
    final revealed = <int, int>{};
    for (final poem in p.all) {
      for (var level = 1; level <= Masking.maxLevel; level++) {
        for (var seed = 0; seed < 5; seed++) {
          final m = Masking.maskFor(p, poem.id, level, rng);
          expect(Masking.minVisibleDistance(p, poem.id, m.hidden), greaterThanOrEqualTo(Masking.minDistance),
              reason: '#${poem.id} level $level');
          expect(m.hidden.every((i) => i >= 0 && i < poem.torifuda.length), isTrue);
        }
      }
      // Fixed levels: how often the guarantee forces a kana back into view.
      final l4 = Masking.maskFor(p, poem.id, 4, rng);
      if (l4.hidden.length < 5) revealed[poem.id] = 5 - l4.hidden.length;
    }
    // ignore: avoid_print
    print('cards needing reveals at level 4 (whole first column): $revealed');
  });

  test('first-kana mask hides exactly the first kana', () {
    final m = Masking.maskFor(p, 87, 1, math.Random(1));
    expect(m.hidden, {0});
  });
}
