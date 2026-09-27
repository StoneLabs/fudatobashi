import 'dart:math' as math;

import '../data/poem.dart';
import 'card_mask.dart';

/// 隠し字: hides torifuda kana so players stop leaning on the first characters.
///
/// Uniqueness guarantee: the kana that stay visible must still tell the card
/// apart from every other card of the 100 in at least [minDistance] positions
/// (positions compared cell by cell; a missing kana counts as different).
/// Random masks are resampled; fixed masks reveal the fewest kana needed.
abstract final class Masking {
  static const minDistance = 2;
  static const maxLevel = 7;

  static const levelDescriptions = {
    0: 'Off',
    1: 'First kana',
    2: 'First two kana',
    3: 'First three kana',
    4: 'Whole first column',
    5: 'First column + 1 random',
    6: 'First column + 3 random',
    7: 'Half the kana, anywhere',
  };

  static CardMask maskFor(Poems p, int poemId, int level, math.Random rng, {MaskStyle style = MaskStyle.scramble}) {
    if (level <= 0) return CardMask.none;
    final len = p[poemId].torifuda.length;
    final seed = rng.nextInt(1 << 20);
    final random = level >= 5;
    Set<int> hidden = _candidate(len, level, rng);
    if (random) {
      for (var i = 0; i < 40 && minVisibleDistance(p, poemId, hidden) < minDistance; i++) {
        hidden = _candidate(len, level, rng);
      }
    }
    hidden = _repair(p, poemId, hidden);
    return CardMask(hidden: hidden, style: style, seed: seed);
  }

  static Set<int> _candidate(int len, int level, math.Random rng) {
    switch (level) {
      case 1:
        return {0};
      case 2:
        return {0, 1};
      case 3:
        return {0, 1, 2};
      case 4:
        return {0, 1, 2, 3, 4};
      case 5:
      case 6:
        final extra = level == 5 ? 1 : 3;
        final rest = List<int>.generate(len - 5, (i) => i + 5)..shuffle(rng);
        return {0, 1, 2, 3, 4, ...rest.take(extra)};
      default:
        final all = List<int>.generate(len - 1, (i) => i + 1)..shuffle(rng);
        return {0, ...all.take(len ~/ 2 - 1)};
    }
  }

  /// Reveals hidden kana (latest positions first) until the card is unique.
  static Set<int> _repair(Poems p, int poemId, Set<int> hidden) {
    final h = {...hidden};
    while (h.isNotEmpty && minVisibleDistance(p, poemId, h) < minDistance) {
      int? best;
      var bestD = -1;
      for (final i in (h.toList()..sort((a, b) => b.compareTo(a)))) {
        final d = minVisibleDistance(p, poemId, h.difference({i}));
        if (d > bestD) {
          bestD = d;
          best = i;
        }
      }
      h.remove(best);
    }
    return h;
  }

  /// Smallest number of visible positions in which this card differs from any
  /// other card.
  static int minVisibleDistance(Poems p, int poemId, Set<int> hidden) {
    final t = p[poemId].torifuda;
    var min = 1 << 30;
    for (final o in p.all) {
      if (o.id == poemId) continue;
      var d = 0;
      for (var i = 0; i < t.length; i++) {
        if (hidden.contains(i)) continue;
        if (i >= o.torifuda.length || o.torifuda[i] != t[i]) d++;
      }
      // A longer card has kana where this one has none: visibly different.
      if (o.torifuda.length > t.length) d++;
      if (d < min) min = d;
    }
    return min;
  }
}
