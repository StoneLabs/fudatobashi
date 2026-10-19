import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;

import '../config.dart';

/// What a tagged uniform of a custom shader is for. A tag follows the uniform on its line:
/// `uniform vec3 uGold; // @colour "Gold" default=#C9A45A`.
enum ParamKind { colour, number, toggle, choice, texture, placement, random, engine }

/// The flat 1 x 1 image a custom texture slot shows when the skin has no file for it.
enum TextureFallback {
  transparent(Cfg.clearTexel),
  black(Cfg.blackTexel),
  grey(Cfg.greyTexel),
  white(Cfg.whiteTexel),
  flatNormal(Cfg.flatNormal);

  const TextureFallback(this.colour);
  final Color colour;
}

class AnnotationError {
  const AnnotationError(this.file, this.line, this.message);
  final String file;
  final int line;
  final String message;

  @override
  String toString() => '$file:$line: $message';
}

/// One low..high range.
class Span {
  const Span(this.low, this.high);
  final double low, high;
  List<double> toJson() => [low, high];
}

/// One tagged uniform of a shader.
class Param {
  const Param({
    required this.uniform,
    required this.glslType,
    required this.count,
    required this.kind,
    required this.label,
    required this.group,
    required this.keys,
    required this.file,
    required this.line,
  });

  final String uniform, glslType;

  /// The array length, or null for a single value.
  final int? count;
  final ParamKind kind;
  final String label;
  final String? group;
  final Map<String, String> keys;

  /// The file and line that declare it.
  final String file;
  final int line;

  /// The name in skin.json: the uniform without its leading `u`, `uWaterSpeed` -> `waterSpeed`.
  String get key => uniform.length > 1 ? uniform[1].toLowerCase() + uniform.substring(2) : uniform;

  /// A texture's file name without `.png`: `uFoilMask` -> `foil_mask`.
  String get slotName => key.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  String? get help => keys['help'];
  String? get unit => keys['unit'];
  int get components => switch (glslType) { 'vec2' => 2, 'vec3' => 3, 'vec4' => 4, _ => 1 };

  List<String> get labels => _list('labels');
  List<String> get options => _list('options');

  List<String> _list(String name) => keys[name]?.split('|') ?? const [];

  /// `range=a..b`, or null when missing or malformed.
  Span? get range => parseSpan(keys['range']);

  double get step => double.tryParse(keys['step'] ?? '') ?? Cfg.defaultNumberStep;

  /// What a texture's channels mean, for the texture pane.
  String? get channels => keys['channels'];

  TextureFallback get fallback => TextureFallback.values.where((f) => f.name == keys['fallback']).firstOrNull ?? TextureFallback.black;

  /// A placement's range for `x`, `y` or `rotation`, or a random value's for a component.
  Span span(String name, Span fallback) => parseSpan(keys[name]) ?? fallback;

  /// The default as skin.json holds it: a hex string, a number, a bool or a choice, or a list of them.
  Object? get defaultValue {
    final raw = keys['default'];
    Object? one(String? text) => switch (kind) {
          ParamKind.colour => isHex(text ?? '') ? text!.toUpperCase() : '#000000',
          ParamKind.number => _number(text) ?? range?.low ?? 0,
          ParamKind.toggle => text == '1' || text == 'true',
          ParamKind.choice => options.contains(text) ? text : (options.isEmpty ? '' : options.first),
          _ => null,
        };
    final n = count;
    if (n == null) return one(raw);
    final parts = (raw ?? '').split('|');
    return [for (var i = 0; i < n; i++) one(parts.isEmpty ? null : parts[i < parts.length ? i : parts.length - 1])];
  }

  static num? _number(String? text) {
    if (text == null) return null;
    return int.tryParse(text) ?? double.tryParse(text);
  }
}

bool isHex(String text) => RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(text);

Span? parseSpan(String? text) {
  final m = RegExp(r'^(-?[\d.]+)\.\.(-?[\d.]+)$').firstMatch(text ?? '');
  if (m == null) return null;
  final a = double.tryParse(m[1]!), b = double.tryParse(m[2]!);
  return a == null || b == null ? null : Span(a, b);
}

/// A shader's parameters, read from the annotations in its `.frag` and the
/// local files it includes.
class ShaderInfo {
  const ShaderInfo({
    required this.name,
    required this.title,
    required this.about,
    required this.animated,
    required this.params,
    required this.untagged,
    required this.errors,
    required this.groups,
    required this.files,
  });

  /// The file name without `.frag`.
  final String name;

  /// The `@shader` name, or [name].
  final String title, about;

  /// True when the shader carries `// @animated`: the editor then keeps `uTime` running.
  final bool animated;

  /// Every tagged uniform in file order, engine inputs included.
  final List<Param> params;

  /// Uniforms with no tag: nothing sets them.
  final List<Param> untagged;
  final List<AnnotationError> errors;

  /// Form sections in order: the shader's own, then those of its includes, with the shared include last.
  final List<String> groups;

  /// The shader file and the includes it reads, as paths.
  final List<String> files;

  Iterable<Param> get formParams =>
      params.where((q) => q.kind == ParamKind.colour || q.kind == ParamKind.number || q.kind == ParamKind.toggle || q.kind == ParamKind.choice);
  List<Param> get placements => [for (final q in params) if (q.kind == ParamKind.placement) q];
  List<Param> get randoms => [for (final q in params) if (q.kind == ParamKind.random) q];
  List<Param> get textures => [for (final q in params) if (q.kind == ParamKind.texture) q];

  List<Param> inGroup(String group) => [for (final q in formParams) if ((q.group ?? Cfg.defaultGroup) == group) q];

  Param? byKey(String key) => params.where((q) => q.key == key && q.kind != ParamKind.engine).firstOrNull;
}

final _uniformLine = RegExp(r'^\s*uniform\s+(?:(?:highp|mediump|lowp)\s+)?(\w+)\s+(\w+)\s*(?:\[\s*(\w+)\s*\])?\s*;(.*)$');
final _tagComment = RegExp(r'^\s*//\s*@(\w+)\s*(.*)$');
final _groupLine = RegExp(r'^\s*//\s*@group\s+(.+?)\s*$');
final _shaderLine = RegExp(r'^\s*//\s*@shader\s+"([^"]+)"\s*(.*)$');
final _animatedLine = RegExp(r'^\s*//\s*@animated\b');
final _includeLine = RegExp(r'^\s*#include\s+"([^"]+)"');
final _pair = RegExp(r'(\w+)=("[^"]*"|\S+)');
final _label = RegExp(r'^"([^"]*)"\s*');

const _glslTypes = {
  ParamKind.colour: {'vec3'},
  ParamKind.number: {'float'},
  ParamKind.toggle: {'float'},
  ParamKind.choice: {'float'},
  ParamKind.texture: {'sampler2D'},
  ParamKind.placement: {'mat3'},
  ParamKind.random: {'float', 'vec2', 'vec3', 'vec4'},
};

class _Reader {
  _Reader(this.root);

  final Directory root;
  final params = <Param>[], untagged = <Param>[], errors = <AnnotationError>[];
  final groupsByFile = <String, List<String>>{};
  final files = <String>[];
  String title = '', about = '';
  bool animated = false;

  void read(File file, int depth) {
    final name = p.basename(file.path);
    if (files.contains(file.path) || depth > Cfg.includeDepthMax) return;
    files.add(file.path);
    final List<String> lines;
    try {
      lines = file.readAsLinesSync();
    } catch (_) {
      return;
    }
    String? group;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i], n = i + 1;
      Match? m;
      if ((m = _includeLine.firstMatch(line)) != null) {
        final target = File(p.join(file.parent.path, m![1]!));
        if (target.existsSync()) {
          read(target, depth + 1);
        } else {
          errors.add(AnnotationError(name, n, 'The include ${m[1]} is not in the shaders folder'));
        }
      } else if (_animatedLine.hasMatch(line)) {
        animated = true;
      } else if ((m = _shaderLine.firstMatch(line)) != null) {
        title = m![1]!;
        about = m[2]!.trim();
      } else if ((m = _groupLine.firstMatch(line)) != null) {
        group = m![1]!;
      } else if ((m = _uniformLine.firstMatch(line)) != null) {
        _uniform(name, n, m!, group);
      } else if (RegExp(r'^\s*uniform\b').hasMatch(line)) {
        errors.add(AnnotationError(name, n, 'Declare one uniform per line: uniform <type> <name>;'));
      }
    }
  }

  void _uniform(String file, int line, Match m, String? group) {
    final type = m[1]!, uniform = m[2]!;
    int? count;
    if (m[3] != null) {
      count = int.tryParse(m[3]!);
      if (count == null || count < 1) {
        errors.add(AnnotationError(file, line, 'The array length of $uniform must be a plain number'));
        return;
      }
    }
    final tag = _tagComment.firstMatch(m[4] ?? '');
    Param make(ParamKind kind, String label, Map<String, String> keys) => Param(
          uniform: uniform, glslType: type, count: count, kind: kind, label: label, group: group, keys: keys, file: file, line: line);
    if (tag == null) {
      untagged.add(make(ParamKind.engine, uniform, const {}));
      return;
    }
    final kindName = tag[1] == 'switch' ? 'toggle' : tag[1]!;
    final kind = ParamKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) {
      errors.add(AnnotationError(file, line, 'Unknown tag @${tag[1]} on $uniform'));
      return;
    }
    var rest = tag[2]!;
    var label = uniform.length > 1 ? uniform.substring(1) : uniform;
    final lm = _label.firstMatch(rest);
    if (lm != null) {
      label = lm[1]!;
      rest = rest.substring(lm.end);
    }
    final keys = <String, String>{
      for (final pair in _pair.allMatches(rest)) pair[1]!: pair[2]!.startsWith('"') ? pair[2]!.substring(1, pair[2]!.length - 1) : pair[2]!,
    };
    final allowed = _glslTypes[kind];
    if (allowed != null && !allowed.contains(type)) {
      errors.add(AnnotationError(file, line, '@${tag[1]} needs ${allowed.join(' or ')}, but $uniform is $type'));
      return;
    }
    if (count != null && (kind == ParamKind.toggle || kind == ParamKind.choice || kind == ParamKind.placement || kind == ParamKind.texture)) {
      errors.add(AnnotationError(file, line, '@${tag[1]} cannot be an array ($uniform)'));
      return;
    }
    if (kind != ParamKind.engine && !RegExp(r'^u[A-Z]').hasMatch(uniform)) {
      errors.add(AnnotationError(file, line, 'Name $uniform as u followed by a capital, such as uPaperEdge'));
      return;
    }
    _check(kind, uniform, keys, file, line);
    if (group != null) {
      final list = groupsByFile.putIfAbsent(file, () => []);
      if (!list.contains(group) && (kind == ParamKind.colour || kind == ParamKind.number || kind == ParamKind.toggle || kind == ParamKind.choice)) {
        list.add(group);
      }
    }
    params.add(make(kind, label, keys));
  }

  void _check(ParamKind kind, String uniform, Map<String, String> keys, String file, int line) {
    void bad(String message) => errors.add(AnnotationError(file, line, message));
    switch (kind) {
      case ParamKind.number:
        if (parseSpan(keys['range']) == null) bad('$uniform needs range=low..high');
      case ParamKind.choice:
        if ((keys['options'] ?? '').isEmpty) bad('$uniform needs options=a|b|c');
      case ParamKind.colour:
        for (final c in (keys['default'] ?? '').split('|')) {
          if (c.isNotEmpty && !isHex(c)) bad('$uniform: "$c" is not a colour such as #EAEAEA');
        }
      case ParamKind.texture:
        final fallback = keys['fallback'];
        if (fallback != null && !TextureFallback.values.any((f) => f.name == fallback)) {
          bad('$uniform: fallback must be one of ${TextureFallback.values.map((f) => f.name).join(', ')}');
        }
      case ParamKind.placement:
        for (final k in ['x', 'y', 'rotation']) {
          if (keys.containsKey(k) && parseSpan(keys[k]) == null) bad('$uniform: $k needs low..high');
        }
      case ParamKind.random:
        for (final k in ['x', 'y', 'z', 'w']) {
          if (keys.containsKey(k) && parseSpan(keys[k]) == null) bad('$uniform: $k needs low..high');
        }
      case ParamKind.toggle || ParamKind.engine:
        break;
    }
  }
}

/// Reads [frag] and the files it includes. Never throws: problems go in [ShaderInfo.errors].
ShaderInfo parseShader(File frag) {
  final reader = _Reader(frag.parent)..read(frag, 0);
  final name = p.basenameWithoutExtension(frag.path), own = p.basename(frag.path);
  final byFile = reader.groupsByFile;
  final groups = <String>[
    ...?byFile[own],
    for (final e in byFile.entries)
      if (e.key != own && e.key != Cfg.sharedInclude) ...e.value,
    ...?byFile[Cfg.sharedInclude],
  ].fold<List<String>>([], (list, g) => list.contains(g) ? list : [...list, g]);
  final params = reader.params;
  final hasUngrouped = params.any((q) => q.group == null && q.kind != ParamKind.engine &&
      (q.kind == ParamKind.colour || q.kind == ParamKind.number || q.kind == ParamKind.toggle || q.kind == ParamKind.choice));
  return ShaderInfo(
    name: name,
    title: reader.title.isEmpty ? name : reader.title,
    about: reader.about,
    animated: reader.animated,
    params: params,
    untagged: reader.untagged,
    errors: reader.errors,
    groups: [...groups, if (hasUngrouped) Cfg.defaultGroup],
    files: reader.files,
  );
}
