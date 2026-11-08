import 'dart:math' as math;

/// A normal draw around 0 with standard deviation [sd], drawn again
/// whenever it lands more than [cutOff] away, so every draw is within
/// ±[cutOff] (a truncated normal).
class TruncatedNormal {
  const TruncatedNormal({required this.sd, required this.cutOff});

  final double sd;
  final double cutOff;

  /// One draw from [rng].
  double sample(math.Random rng) {
    while (true) {
      final x = sd * _standard(rng);
      if (x.abs() <= cutOff) return x;
    }
  }

  /// How thickly the draws fall at [x]: the normal's density, raised so
  /// that it adds up to 1 within ±[cutOff], and 0 past it.
  double density(double x) {
    if (x.abs() > cutOff) return 0;
    final z = x / sd;
    return math.exp(-z * z / 2) / (sd * math.sqrt(2 * math.pi) * _kept);
  }

  /// The share of draws from [from] to [to].
  double share(double from, double to) {
    final lo = from.clamp(-cutOff, cutOff), hi = to.clamp(-cutOff, cutOff);
    if (hi <= lo) return 0;
    return (_erf(hi / (sd * math.sqrt2)) - _erf(lo / (sd * math.sqrt2))) / (2 * _kept);
  }

  /// The share of a plain normal's draws that land within ±[cutOff].
  double get _kept => _erf(cutOff / (sd * math.sqrt2));

  /// A standard normal draw (Box-Muller).
  static double _standard(math.Random rng) {
    final u = 1 - rng.nextDouble();
    return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * rng.nextDouble());
  }

  /// The error function, to within 1.5e-7 (Abramowitz and Stegun 7.1.26).
  static double _erf(double x) {
    final t = 1 / (1 + 0.3275911 * x.abs());
    final poly = t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429))));
    final y = 1 - poly * math.exp(-x * x);
    return x < 0 ? -y : y;
  }
}
