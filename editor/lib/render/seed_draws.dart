import 'dart:math' as math;

import '../config.dart';
import '../model/shader_info.dart';
import '../model/skin.dart';

/// Valve's uniform random stream (Numerical Recipes ran1, Park-Miller with a
/// Bays-Durham shuffle). Seeds 0 and 1 give the same stream.
class Ran1 {
  Ran1(int seed) : _idum = seed >= 0 ? -seed : seed;

  static const _ntab = 32, _ia = 16807, _im = 2147483647, _iq = 127773, _ir = 2836;
  static const _ndiv = 1 + (_im - 1) ~/ _ntab;
  static const _am = 1 / _im, _rnmx = 1 - 1.2e-7;

  int _idum;
  int _iy = 0;
  final List<int> _iv = List.filled(_ntab, 0);

  int _step() {
    final k = _idum ~/ _iq;
    _idum = _ia * (_idum - k * _iq) - _ir * k;
    if (_idum < 0) _idum += _im;
    return _idum;
  }

  int _next() {
    if (_idum <= 0 || _iy == 0) {
      _idum = -_idum < 1 ? 1 : -_idum;
      for (var j = _ntab + 7; j >= 0; j--) {
        _step();
        if (j < _ntab) _iv[j] = _idum;
      }
      _iy = _iv[0];
    }
    _step();
    final j = _iy ~/ _ndiv;
    _iy = _iv[j];
    _iv[j] = _idum;
    return _iy;
  }

  double float(double lo, double hi) => math.min(_am * _next(), _rnmx) * (hi - lo) + lo;
}

/// A texture window: where the card sits on a sheet.
class Window {
  const Window(this.x, this.y, this.rotation, this.scale);
  final double x, y, rotation, scale;

  /// Card uv (x / 374, y / 374) to sheet uv, as nine floats in the order the
  /// shader's mat3 reads them (column by column).
  List<double> get matrix {
    final a = rotation * math.pi / 180;
    final c = math.cos(a) * scale, s = math.sin(a) * scale;
    const cx = 0.5, cy = Cfg.cardHeight / Cfg.cardWidth / 2;
    final tx = x - (c * cx - s * cy), ty = y - (s * cx + c * cy);
    return [c, s, 0, -s, c, 0, tx, ty, 1];
  }
}

/// Everything a seed decides for one skin.
class SeedDraws {
  const SeedDraws(this.placements, this.wear, this.grunge, this.random);

  /// Each placement's window, by the placement's key: [patternKey], then a custom shader's own.
  final Map<String, Window> placements;

  /// The two windows on the shared wear sheet.
  final Window wear, grunge;

  /// Each random value's numbers by key: components of the first item, then the second, and so on.
  final Map<String, List<double>> random;
}

Span _span(Object? v, Span fallback) {
  if (v is List && v.length == 2 && v[0] is num && v[1] is num) return Span((v[0] as num).toDouble(), (v[1] as num).toDouble());
  return fallback;
}

/// The draws a seed makes, in the fixed order, the way CS places its own: the pattern's x, y and rotation;
/// the wear window's scale, x, y, rotation; the grunge window's; then each placement of a custom shader;
/// then each random value's components for each of its items, all in declaration order.
SeedDraws drawSeed(Map<String, dynamic> skin, ShaderInfo? info, int seed) {
  final r = Ran1(seed);
  Window place(Object? given, Span x0, Span y0, Span rot0, double scale0) {
    final map = given is Map ? given : const {};
    final x = _span(map['x'], x0), y = _span(map['y'], y0), rot = _span(map['rotation'], rot0);
    final scale = map['scale'] is num ? (map['scale'] as num).toDouble() : scale0;
    return Window(r.float(x.low, x.high), r.float(y.low, y.high), r.float(rot.low, rot.high), scale);
  }

  Window placement(Param q) => place(readPath(skin, 'placements.${q.key}'), q.span('x', const Span(0, 0)), q.span('y', const Span(0, 0)),
      q.span('rotation', const Span(0, 0)), double.tryParse(q.keys['scale'] ?? '') ?? 1.0);

  Span span(List<double> v) => Span(v[0], v[1]);
  final placements = <String, Window>{
    patternKey: place(skin[patternKey], span(Cfg.patternX), span(Cfg.patternY), span(Cfg.patternRotation), Cfg.patternScale),
  };
  Window windowOnWearSheet() {
    final s = r.float(Cfg.wearWindowScaleMin, Cfg.wearWindowScaleMax);
    final x = r.float(0, 1), y = r.float(0, 1), rot = r.float(0, 360);
    return Window(x, y, rot, s);
  }

  final wear = windowOnWearSheet();
  final grunge = windowOnWearSheet();
  for (final q in info?.placements ?? const <Param>[]) {
    placements[q.key] = placement(q);
  }
  final random = <String, List<double>>{};
  for (final q in info?.randoms ?? const <Param>[]) {
    final given = readPath(skin, 'random.${q.key}');
    final map = given is Map ? given : const {};
    final spans = [for (final c in randomComponents(q)) _span(map[c], q.span(c, const Span(0, 0)))];
    random[q.key] = [
      for (var item = 0; item < (q.count ?? 1); item++)
        for (final s in spans) r.float(s.low, s.high),
    ];
  }
  return SeedDraws(placements, wear, grunge, random);
}
