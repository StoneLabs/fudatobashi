import 'dart:math' as math;

import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/ikkiuchi_layout.dart';

/// How many groups of cards a game deals Tobi more than one card of, for
/// the developer's graphs: worked out exactly over every deal of
/// [IkkiuchiToolsTuning.gamePerSide] cards to him from all the poems.
class IkkiuchiGroupsDealt {
  IkkiuchiGroupsDealt(List<int> sizes) : _chances = _spread(sizes, IkkiuchiToolsTuning.gamePerSide);

  /// The first-sound groups ([IkkiuchiLayout.groupOf]).
  factory IkkiuchiGroupsDealt.sounds() {
    final layout = IkkiuchiLayout.ofPoems();
    final count = <String, int>{};
    for (final poem in poems.all) {
      count.update(layout.groupOf(poem.id), (n) => n + 1, ifAbsent: () => 1);
    }
    return IkkiuchiGroupsDealt(count.values.toList());
  }

  /// The 友札 families, every other card a group of one.
  factory IkkiuchiGroupsDealt.families() {
    final families = IkkiuchiLayout.ofPoems().families([for (final poem in poems.all) poem.id]);
    final inFamilies = families.fold(0, (n, f) => n + f.length);
    return IkkiuchiGroupsDealt([
      for (final f in families) f.length,
      for (var i = inFamilies; i < poems.all.length; i++) 1,
    ]);
  }

  /// The chance of k such groups at index k.
  final List<double> _chances;

  /// The share of games in which he keeps at least one such group
  /// together, keeping each with [chance].
  double anyKept(double chance) {
    var none = 0.0;
    for (final (k, p) in _chances.indexed) {
      none += p * math.pow(1 - chance, k);
    }
    return 1 - none;
  }

  // Counts the deals of [perSide] cards from groups of [sizes], group by
  // group, by how many cards are dealt so far and how many groups got
  // more than one.
  static List<double> _spread(List<int> sizes, int perSide) {
    List<List<double>> none() => [for (var n = 0; n <= perSide; n++) List.filled(sizes.length + 1, 0.0)];
    var ways = none()..[0][0] = 1;
    for (final size in sizes) {
      final next = none();
      for (var n = 0; n <= perSide; n++) {
        for (var k = 0; k < sizes.length; k++) {
          if (ways[n][k] == 0) continue;
          for (var x = 0; x <= math.min(size, perSide - n); x++) {
            next[n + x][x > 1 ? k + 1 : k] += ways[n][k] * _choose(size, x);
          }
        }
      }
      ways = next;
    }
    final all = ways[perSide].reduce((a, b) => a + b);
    return [for (final w in ways[perSide]) w / all];
  }

  static double _choose(int n, int k) {
    var c = 1.0;
    for (var i = 0; i < k; i++) {
      c = c * (n - i) / (i + 1);
    }
    return c;
  }
}

/// The first-sound groups and the 友札 families, worked out on first use.
final ikkiuchiSoundsDealt = IkkiuchiGroupsDealt.sounds();
final ikkiuchiFamiliesDealt = IkkiuchiGroupsDealt.families();
