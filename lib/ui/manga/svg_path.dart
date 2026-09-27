import 'dart:ui';

/// Parses SVG path data (all commands, absolute and relative) into a [Path].
/// Parsed paths are cached by their source string.
abstract final class SvgPath {
  static final _cache = <String, Path>{};
  static final _token = RegExp(r'[A-Za-z]|[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?');
  static final _command = RegExp(r'^[A-Za-z]$');

  static Path parse(String d) => _cache[d] ??= _parse(d);

  static Path _parse(String d) {
    final tokens = [for (final m in _token.allMatches(d)) m.group(0)!];
    final path = Path();
    var i = 0;
    var cmd = '';
    var cur = Offset.zero;
    var start = Offset.zero;
    Offset? lastCubic;
    Offset? lastQuad;

    bool isCommand(String t) => _command.hasMatch(t);
    double num() => double.parse(tokens[i++]);
    Offset point(bool rel) {
      final p = Offset(num(), num());
      return rel ? cur + p : p;
    }

    while (i < tokens.length) {
      if (isCommand(tokens[i])) {
        cmd = tokens[i++];
      } else if (cmd == 'M') {
        cmd = 'L';
      } else if (cmd == 'm') {
        cmd = 'l';
      }
      final rel = cmd == cmd.toLowerCase();
      Offset? cubic;
      Offset? quad;
      switch (cmd.toUpperCase()) {
        case 'M':
          cur = start = point(rel);
          path.moveTo(cur.dx, cur.dy);
        case 'L':
          cur = point(rel);
          path.lineTo(cur.dx, cur.dy);
        case 'H':
          final x = num();
          cur = Offset(rel ? cur.dx + x : x, cur.dy);
          path.lineTo(cur.dx, cur.dy);
        case 'V':
          final y = num();
          cur = Offset(cur.dx, rel ? cur.dy + y : y);
          path.lineTo(cur.dx, cur.dy);
        case 'C':
          final c1 = point(rel);
          cubic = point(rel);
          cur = point(rel);
          path.cubicTo(c1.dx, c1.dy, cubic.dx, cubic.dy, cur.dx, cur.dy);
        case 'S':
          final c1 = lastCubic == null ? cur : cur * 2 - lastCubic;
          cubic = point(rel);
          cur = point(rel);
          path.cubicTo(c1.dx, c1.dy, cubic.dx, cubic.dy, cur.dx, cur.dy);
        case 'Q':
          quad = point(rel);
          cur = point(rel);
          path.quadraticBezierTo(quad.dx, quad.dy, cur.dx, cur.dy);
        case 'T':
          quad = lastQuad == null ? cur : cur * 2 - lastQuad;
          cur = point(rel);
          path.quadraticBezierTo(quad.dx, quad.dy, cur.dx, cur.dy);
        case 'A':
          final rx = num(), ry = num(), rotation = num();
          final largeArc = num() != 0, sweep = num() != 0;
          cur = point(rel);
          path.arcToPoint(cur,
              radius: Radius.elliptical(rx, ry), rotation: rotation, largeArc: largeArc, clockwise: sweep);
        case 'Z':
          path.close();
          cur = start;
          if (i < tokens.length && !isCommand(tokens[i])) throw FormatException('Number after Z', d);
        default:
          throw FormatException('Unsupported SVG path command $cmd', d);
      }
      lastCubic = cubic;
      lastQuad = quad;
    }
    return path;
  }
}
