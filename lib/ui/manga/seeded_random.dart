/// The spec's seeded generator (mulberry32), so generated art such as focus
/// lines and shout spikes matches the mock-up for the same seed.
class SeededRandom {
  SeededRandom(int seed) : _a = (seed & _mask) == 0 ? 1 : seed & _mask;

  static const _mask = 0xFFFFFFFF;
  static const _increment = 0x6D2B79F5;
  static const _range = 4294967296.0;

  int _a;

  static int _imul(int a, int b) => ((a & _mask) * (b & _mask)) & _mask;

  /// Uniform in [0, 1).
  double next() {
    _a = (_a + _increment) & _mask;
    var t = _imul(_a ^ (_a >>> 15), 1 | _a);
    t = ((t + _imul(t ^ (t >>> 7), 61 | t)) & _mask) ^ t;
    return ((t ^ (t >>> 14)) & _mask) / _range;
  }
}
