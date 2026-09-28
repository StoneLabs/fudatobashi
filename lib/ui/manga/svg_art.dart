import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart' show Matrix4;
import 'package:xml/xml.dart';

import '../../config/design.dart';
import 'vector.dart';

/// Loads [VectorArt] from real `.svg` files (`assets/svg/`), so the app's
/// hand-drawn art can be redrawn in Inkscape, Illustrator or Figma instead of
/// living as path strings in Dart.
///
/// Conventions an editor must keep, and that this loader assumes:
///  * The root `<svg>`'s `viewBox="minX minY width height"` gives the art's
///    box (`width`×`height`) and origin (`minX`, `minY`); any `width`/
///    `height` attributes on the root are ignored.
///  * `<g>`, `<path>`, `<rect>`, `<circle>`, `<ellipse>`, `<line>`,
///    `<polyline>` and `<polygon>` are supported, nested arbitrarily under
///    `<g>`. Anything else — filters, gradients, text, masks, `<use>`, a
///    `<style>` sheet — fails to load, naming the file and the element;
///    there is no silent fallback.
///  * `<metadata>`, `<title>`, `<desc>`, `<defs>` and Inkscape/Sodipodi's own
///    elements (`sodipodi:namedview` and its children) are ignored outright,
///    along with any attribute this loader doesn't otherwise read, so an
///    editor's bookkeeping never breaks a load.
///  * Presentation attributes (`fill`, `stroke`, `stroke-width`,
///    `stroke-linecap`, `stroke-linejoin`, `stroke-dasharray`, `opacity`) and
///    an equivalent `style="..."` both work; `style` wins where they
///    overlap. Left unset on both, an attribute inherits from the nearest
///    ancestor `<g>` that sets it, exactly like [VStyle.over] — and if no
///    ancestor sets it either, from the style the call site paints with
///    ([VectorPainter.paint]'s `base`). That is not the CSS/SVG initial
///    value (an unset `stroke` is not "none"): the app supplies its own base
///    style at paint time, the same way it always has.
///  * `fill`/`stroke` is a literal `#rgb`/`#rrggbb`, `none` ([noInk], turns
///    the paint off) or `currentColor` ([currentInk], the colour the call
///    site paints in). A literal colour must name one of [SvgPalette.tokens];
///    in debug mode, an unrecognised one asserts, naming the file and the
///    element, so the art and the palette can't quietly diverge.
///  * A screentone fill is `fill="url(#tone-<name>)"` for a `<name>` in
///    [SvgTones.tokens]. The matching `<pattern id="tone-<name>">` in
///    `<defs>` is a real dot screen, generated so editors preview it, and is
///    not itself read back — the app always draws the tone itself, anchored
///    to the coordinate frame it's drawn in; nest a toned shape inside a
///    translated or rotated `<g>` and its dots shift with that frame, so
///    toned art keeps its tone-filled shapes unwrapped.
///  * `transform`, on any `<g>` or shape, composes `translate`, `scale`,
///    `rotate` and `matrix` — in the order listed, as SVG does — into one
///    affine map, applied about the local origin. A lone `rotate(a cx cy)`
///    draws through the same call the app always rotated art with.
///  * `d` (path data) takes any numeric format and both absolute and
///    relative commands, including arcs.
///  * An element tagged [VTag.eye] (so Tobi can blink) is an `<eye...>`-id
///    `<g>` or shape; the id is otherwise just documentation.
abstract final class SvgArt {
  /// Parses one art piece. [debugName] (e.g. `icons/lock.svg`) names the
  /// asset in any error.
  static VectorArt parse(String source, {required String debugName}) {
    final root = XmlDocument.parse(source).rootElement;
    if (root.name.local != 'svg') {
      throw SvgArtException('expected an <svg> root', debugName);
    }
    final box = _numbers(_require(root, 'viewBox', debugName));
    if (box.length != 4) {
      throw SvgArtException('viewBox needs 4 numbers, got "${root.getAttribute('viewBox')}"', debugName);
    }
    final shapes = [for (final child in root.childElements) _parseNode(child, debugName)].whereType<VShape>();
    return VectorArt(Size(box[2], box[3]), shapes.toList(), origin: Offset(box[0], box[1]));
  }

  /// The `d` of every top-level `<path>`, in document order, ignoring style:
  /// for art whose per-piece styling is decided at paint time (the streak's
  /// 正 strokes, see `Tally`).
  static List<String> strokes(String source, {required String debugName}) =>
      [for (final shape in parse(source, debugName: debugName).shapes) (shape as VPath).d];
}

/// Thrown when an `.svg` asset doesn't fit [SvgArt]'s conventions.
class SvgArtException implements Exception {
  SvgArtException(this.message, this.debugName);
  final String message;
  final String debugName;

  @override
  String toString() => 'SvgArtException: $message (in $debugName)';
}

/// The colours hand-drawn art may use, named for the literal hex [SvgArt]
/// reads back and asserts against. Named after their [Palette] (or
/// [MapStyle]) field.
abstract final class SvgPalette {
  static const tokens = {
    'ink': Palette.ink,
    'paper': Palette.paper,
    'pink': Palette.pink,
    'sun': Palette.sun,
    'cardFrame': Palette.cardFrame,
    'cardPaper': Palette.cardPaper,
    'treeDeep': MapStyle.tree,
    'treeHighlight': MapStyle.treeHighlight,
  };

  static final _byColor = {for (final e in tokens.entries) e.value: e.key};

  static String? nameOf(Color c) => _byColor[c];
}

/// The screentones hand-drawn art may fill with, named for [Tones]' field.
abstract final class SvgTones {
  static const tokens = {
    'ink': Tones.ink,
    'inkLight': Tones.inkLight,
    'inkMid': Tones.inkMid,
    'inkDark': Tones.inkDark,
    'inkReverse': Tones.inkReverse,
    'pink': Tones.pink,
    'sea': Tones.sea,
    'seaDeep': Tones.seaDeep,
    'land': Tones.land,
    'sun': Tones.sun,
    'violet': Tones.violet,
    'seaFaint': Tones.seaFaint,
    'stamp': Tones.stamp,
    'mapSea': Tones.mapSea,
    'mapLand': Tones.mapLand,
    'mapShoal': Tones.mapShoal,
    'mapInk': Tones.mapInk,
  };

  static final _byTone = {for (final e in tokens.entries) e.value: e.key};

  static String? nameOf(ToneSpec t) => _byTone[t];
}

const _ignoredElements = {'metadata', 'title', 'desc', 'defs', 'namedview', 'guide', 'grid'};

VShape? _parseNode(XmlElement el, String file) {
  final name = el.name.local;
  if (_ignoredElements.contains(name)) return null;

  final style = _parseStyle(el, file);
  final t = _parseGroupTransform(el.getAttribute('transform'), file);
  final id = el.getAttribute('id');
  final tag = id != null && id.startsWith('eye') ? VTag.eye : null;

  if (name == 'g') {
    final children = [for (final c in el.childElements) _parseNode(c, file)].whereType<VShape>().toList();
    return VGroup(children, style: style, rotate: t.rotate, pivot: t.pivot, transform: t.matrix, tag: tag);
  }

  final VShape leaf = switch (name) {
    'path' => VPath(_require(el, 'd', file), style, tag),
    'rect' => _rect(el, style, tag, file),
    'circle' => VEllipse.circle(Offset(_num(el, 'cx', file), _num(el, 'cy', file)), _num(el, 'r', file), style, tag),
    'ellipse' => VEllipse(Offset(_num(el, 'cx', file), _num(el, 'cy', file)), _num(el, 'rx', file),
        _num(el, 'ry', file), style, tag),
    'line' => VPath(
        'M ${_num(el, 'x1', file)} ${_num(el, 'y1', file)} L ${_num(el, 'x2', file)} ${_num(el, 'y2', file)}',
        style,
        tag),
    'polyline' => VPath(_polyPath(el, file, closed: false), style, tag),
    'polygon' => VPath(_polyPath(el, file, closed: true), style, tag),
    _ => throw SvgArtException('unsupported element <$name>${id == null ? '' : ' id="$id"'}', file),
  };
  if (t.rotate == 0 && t.matrix == null) return leaf;
  return VGroup([leaf], rotate: t.rotate, pivot: t.pivot, transform: t.matrix);
}

/// A lone `rotate(a[, cx, cy])` — the one transform a plain rotation about a
/// point needs — is kept as [VGroup.rotate]/[VGroup.pivot], which draws
/// through the same [Canvas.rotate] call this app has always used; anything
/// else (any other function, or more than one) becomes a general
/// [VGroup.transform] matrix.
({double rotate, Offset pivot, Matrix4? matrix}) _parseGroupTransform(String? raw, String file) {
  if (raw == null) return (rotate: 0, pivot: Offset.zero, matrix: null);
  final calls = _transformCall.allMatches(raw).toList();
  if (calls.length == 1 && calls.single.group(0) == raw.trim() && calls.single.group(1) == 'rotate') {
    final a = _numbers(calls.single.group(2)!);
    if (a.length == 1) return (rotate: a[0], pivot: Offset.zero, matrix: null);
    if (a.length == 3) return (rotate: a[0], pivot: Offset(a[1], a[2]), matrix: null);
  }
  return (rotate: 0, pivot: Offset.zero, matrix: _parseTransform(raw, file));
}

VRect _rect(XmlElement el, VStyle style, VTag? tag, String file) {
  final rectRadius = _rectRadius(el, file);
  return VRect(
    Rect.fromLTWH(_num(el, 'x', file, 0), _num(el, 'y', file, 0), _num(el, 'width', file), _num(el, 'height', file)),
    radius: rectRadius,
    style: style,
    tag: tag,
  );
}

double _rectRadius(XmlElement el, String file) {
  final rx = el.getAttribute('rx');
  final ry = el.getAttribute('ry');
  if (rx == null && ry == null) return 0;
  final rxv = double.parse((rx ?? ry)!);
  final ryv = double.parse((ry ?? rx)!);
  if ((rxv - ryv).abs() > 1e-6) {
    throw SvgArtException('elliptical <rect> corners (rx≠ry) are not supported', file);
  }
  return rxv;
}

String _polyPath(XmlElement el, String file, {required bool closed}) {
  final points = _numbers(_require(el, 'points', file));
  if (points.length < 4 || points.length.isOdd) {
    throw SvgArtException('a <poly${closed ? 'gon' : 'line'}> needs pairs of points', file);
  }
  final d = StringBuffer('M ${points[0]} ${points[1]}');
  for (var i = 2; i < points.length; i += 2) {
    d.write(' L ${points[i]} ${points[i + 1]}');
  }
  if (closed) d.write(' Z');
  return d.toString();
}

VStyle _parseStyle(XmlElement el, String file) {
  final css = <String, String>{};
  final styleAttr = el.getAttribute('style');
  if (styleAttr != null) {
    for (final decl in styleAttr.split(';')) {
      final i = decl.indexOf(':');
      if (i > 0) css[decl.substring(0, i).trim()] = decl.substring(i + 1).trim();
    }
  }
  String? attr(String name) => css[name] ?? el.getAttribute(name);
  final label = el.getAttribute('id') ?? '<${el.name.local}>';

  Color? fill;
  ToneSpec? tone;
  final fillRaw = attr('fill')?.trim();
  if (fillRaw != null && fillRaw.startsWith('url(')) {
    final id = _urlFragment(fillRaw, file);
    final toneName = id.startsWith('tone-') ? id.substring(5) : id;
    tone = SvgTones.tokens[toneName];
    if (tone == null) throw SvgArtException('unknown screentone "#$id" on $label', file);
  } else if (fillRaw != null) {
    fill = _color(fillRaw, file: file, label: label, prop: 'fill');
  }
  final strokeRaw = attr('stroke')?.trim();
  final dashRaw = attr('stroke-dasharray')?.trim();

  return VStyle(
    fill: fill,
    tone: tone,
    stroke: strokeRaw == null ? null : _color(strokeRaw, file: file, label: label, prop: 'stroke'),
    width: _numAttr(attr('stroke-width'), file),
    cap: switch (attr('stroke-linecap')) { null => null, final v => StrokeCap.values.byName(v.trim()) },
    join: switch (attr('stroke-linejoin')) { null => null, final v => StrokeJoin.values.byName(v.trim()) },
    dash: (dashRaw == null || dashRaw == 'none') ? null : _numbers(dashRaw),
    opacity: _numAttr(attr('opacity'), file),
  );
}

Color _color(String v, {required String file, required String label, required String prop}) {
  if (v == 'none') return noInk;
  if (v == 'currentColor') return currentInk;
  final c = _hex(v, file);
  assert(SvgPalette.nameOf(c) != null,
      'unrecognised $prop colour "$v" on $label (in $file) — add it to SvgPalette.tokens or use a palette colour');
  return c;
}

Color _hex(String v, String file) {
  if (!v.startsWith('#')) throw SvgArtException('expected a hex colour or currentColor/none, got "$v"', file);
  var digits = v.substring(1);
  if (digits.length == 3) digits = [for (final d in digits.split('')) '$d$d'].join();
  if (digits.length != 6) throw SvgArtException('expected #rgb or #rrggbb, got "$v"', file);
  return Color(0xFF000000 | int.parse(digits, radix: 16));
}

String _urlFragment(String v, String file) {
  final m = RegExp(r'^url\(\s*#([^)\s]+)\s*\)$').firstMatch(v);
  if (m == null) throw SvgArtException('expected url(#id), got "$v"', file);
  return m.group(1)!;
}

double? _numAttr(String? v, String file) => v == null ? null : double.parse(v.trim());

double _num(XmlElement el, String name, String file, [double? fallback]) {
  final v = el.getAttribute(name);
  if (v == null) {
    if (fallback != null) return fallback;
    throw SvgArtException('missing required attribute "$name" on <${el.name.local}>', file);
  }
  return double.parse(v.trim());
}

String _require(XmlElement el, String name, String file) {
  final v = el.getAttribute(name);
  if (v == null) throw SvgArtException('missing required attribute "$name" on <${el.name.local}>', file);
  return v;
}

final _numberToken = RegExp(r'[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?');

List<double> _numbers(String s) => [for (final m in _numberToken.allMatches(s)) double.parse(m.group(0)!)];

final _transformCall = RegExp(r'(\w+)\s*\(([^)]*)\)');

Matrix4 _parseTransform(String s, String file) {
  var m = Matrix4.identity();
  for (final call in _transformCall.allMatches(s)) {
    m = m * _oneTransform(call.group(1)!, _numbers(call.group(2)!), file);
  }
  return m;
}

Matrix4 _oneTransform(String name, List<double> a, String file) {
  switch (name) {
    case 'translate':
      return Matrix4.identity()..translateByDouble(a[0], a.length > 1 ? a[1] : 0, 0, 1);
    case 'scale':
      final sy = a.length > 1 ? a[1] : a[0];
      return Matrix4.identity()..scaleByDouble(a[0], sy, 1, 1);
    case 'rotate':
      final m = Matrix4.identity();
      final about = a.length >= 3;
      if (about) m.translateByDouble(a[1], a[2], 0, 1);
      m.rotateZ(a[0] * math.pi / 180);
      if (about) m.translateByDouble(-a[1], -a[2], 0, 1);
      return m;
    case 'matrix':
      return Matrix4(a[0], a[1], 0, 0, a[2], a[3], 0, 0, 0, 0, 1, 0, a[4], a[5], 0, 1);
    default:
      throw SvgArtException('unsupported transform function "$name(...)"', file);
  }
}
