/// skin.json format 3 and a skin's image files.
///
/// A skin is a folder of images named after their slot (`colour.png`, `pattern.png`) and a small
/// skin.json: the item, the pattern placement, and the text colours. A skin on a custom
/// shader also names the shader and keeps that shader's numbers under `values` and `random`.
library;

import 'dart:convert';
import 'dart:ui';

import '../config.dart';
import 'shader_info.dart';

/// The skin.json format this editor reads and writes.
const int skinFormat = 3;

const tiers = ['none', 'blue', 'purple', 'pink', 'red', 'gold'];

/// Why [json] cannot be opened, or null.
String? formatProblem(Map<String, dynamic> json) {
  final f = json['format'];
  if (f == skinFormat) return null;
  if (f == 2) return 'This skin is in format 2. Convert the folder with tool/migrate_v3.py, then open it again.';
  return 'Unknown skin format ${f ?? '(none)'}; this editor reads format $skinFormat.';
}

/// [skinKey] and [skinName] are not skin.json values: the key is the folder name and the names
/// live in the project's l10n files (the path is the language, `name.en`).
enum FieldKind { integer, number, numbers, range, boolean, choice, color, palette, text, shader, skinKey, skinName }

class SkinField {
  const SkinField({
    required this.path,
    required this.kind,
    required this.label,
    this.min,
    this.max,
    this.step,
    this.choices = const [],
    this.labels = const [],
    this.unit,
    this.help,
    this.defaultValue,
    this.emptyIsNull = false,
  });

  /// Dot path into skin.json, such as `text.ink`.
  final String path;
  final FieldKind kind;
  final String label;
  final double? min, max, step;

  /// Allowed values of a choice. A custom shader gets the index.
  final List<String> choices;

  /// A name for each item of a list.
  final List<String> labels;
  final String? unit, help;
  final Object? defaultValue;

  /// A text field whose empty value is written as null.
  final bool emptyIsNull;
}

final List<SkinField> itemFields = [
  SkinField(path: 'shader', kind: FieldKind.shader, label: 'Shader', defaultValue: Cfg.standardShader, help: 'standard draws the image files. A custom shader adds an effect the files cannot hold.'),
  SkinField(path: 'id', kind: FieldKind.integer, label: 'Id', min: 1, max: 999999, defaultValue: 1),
  SkinField(path: 'key', kind: FieldKind.skinKey, label: 'Key', help: 'The skin folder name. Use Rename to change it.'),
  SkinField(path: 'name.en', kind: FieldKind.skinName, label: 'Name (English)', help: 'Saved in assets/l10n/en.json.'),
  SkinField(path: 'name.ja', kind: FieldKind.skinName, label: 'Name (Japanese)', help: 'Saved in assets/l10n/ja.json.'),
  SkinField(path: 'tier', kind: FieldKind.choice, label: 'Tier', choices: tiers, defaultValue: Cfg.newSkinTier),
  SkinField(path: 'family', kind: FieldKind.text, label: 'Family', emptyIsNull: true, help: 'Colourways of one design share a family name. Leave empty for a skin on its own.'),
  SkinField(path: 'familyOdds', kind: FieldKind.number, label: 'Family odds', min: 0, max: 100, step: 0.01, unit: '%', defaultValue: 100.0, help: 'The chance of this colourway within its family, in percent.'),
  SkinField(path: 'drops', kind: FieldKind.boolean, label: 'Can drop from boxes', defaultValue: true),
  SkinField(path: 'float', kind: FieldKind.range, label: 'Float range', min: 0, max: 1, step: 0.001, defaultValue: [0.0, 1.0], help: 'A rolled float is squeezed into this range.'),
  SkinField(path: 'badge', kind: FieldKind.numbers, label: 'Badge position', min: 0, max: Cfg.cardHeight, step: 0.01, labels: ['X', 'Y'], defaultValue: [Torifuda.defaultBadgeCenter.dx, Torifuda.defaultBadgeCenter.dy], help: 'Centre of the poem-number badge in card units, X then Y. Without it the badge sits where Vanilla\'s does.'),
];

const List<SkinField> textFields = [
  SkinField(path: 'text.ink', kind: FieldKind.color, label: 'Ink', defaultValue: Cfg.defaultInk, help: 'The kana.'),
  SkinField(path: 'text.badge', kind: FieldKind.color, label: 'Badge ring', defaultValue: Cfg.defaultBadge, help: 'The circle round the poem number.'),
  SkinField(path: 'text.numeral', kind: FieldKind.color, label: 'Numeral', defaultValue: Cfg.defaultNumeral, help: 'The poem number.'),
];

/// The placement every skin's pattern.png goes through. The seed draws x, y and rotation from these ranges.
const String patternKey = 'pattern';

const List<SkinField> patternFields = [
  SkinField(path: 'pattern.x', kind: FieldKind.range, label: 'X', min: 0, max: 1, step: 0.001, defaultValue: Cfg.patternX, help: 'The sheet point under the card centre, in sheet widths.'),
  SkinField(path: 'pattern.y', kind: FieldKind.range, label: 'Y', min: 0, max: 1, step: 0.001, defaultValue: Cfg.patternY, help: 'The sheet point under the card centre, in sheet widths.'),
  SkinField(path: 'pattern.rotation', kind: FieldKind.range, label: 'Rotation', min: -360, max: 360, step: 0.1, unit: '°', defaultValue: Cfg.patternRotation, help: 'How far the card turns on the sheet, in degrees.'),
  SkinField(path: 'pattern.scale', kind: FieldKind.number, label: 'Scale', min: 0.05, max: 8, step: 0.0001, defaultValue: Cfg.patternScale, help: 'Sheet widths across the card width. A 1024 px sheet that covers 256 card units has scale 374 / 256 = 1.4609.'),
];

/// The form field of a custom shader's colour, number, switch or choice. Its value is `values.<key>`.
SkinField fieldOf(Param q) {
  final path = 'values.${q.key}';
  final labels = q.count == null ? const <String>[] : [for (var i = 0; i < q.count!; i++) i < q.labels.length ? q.labels[i] : '${i + 1}'];
  switch (q.kind) {
    case ParamKind.colour:
      return SkinField(path: path, kind: q.count == null ? FieldKind.color : FieldKind.palette, label: q.label, labels: labels, help: q.help, defaultValue: q.defaultValue);
    case ParamKind.number:
      final r = q.range ?? const Span(0, 1);
      return SkinField(path: path, kind: q.count == null ? FieldKind.number : FieldKind.numbers, label: q.label, min: r.low, max: r.high, step: q.step, unit: q.unit, labels: labels, help: q.help, defaultValue: q.defaultValue);
    case ParamKind.toggle:
      return SkinField(path: path, kind: FieldKind.boolean, label: q.label, help: q.help, defaultValue: q.defaultValue);
    default:
      return SkinField(path: path, kind: FieldKind.choice, label: q.label, choices: q.options, help: q.help, defaultValue: q.defaultValue);
  }
}

/// Where the badge of [skin] is centred, in card units.
Offset badgeCenter(Map<String, dynamic>? skin) {
  final v = skin?['badge'];
  if (v is List && v.length == 2 && v.every((e) => e is num)) return Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
  return Torifuda.defaultBadgeCenter;
}

/// The field at [path] among the item, text and pattern fields, or null.
SkinField? fieldAt(String path) => [...itemFields, ...textFields, ...patternFields].where((f) => f.path == path).firstOrNull;

List<String> _parts(String path) => path.split('.');

Object? readPath(Map<String, dynamic> json, String path) {
  Object? node = json;
  for (final p in _parts(path)) {
    if (node is! Map) return null;
    node = node[p];
  }
  return node;
}

void writePath(Map<String, dynamic> json, String path, Object? value) {
  final parts = _parts(path);
  var node = json;
  for (final p in parts.take(parts.length - 1)) {
    final next = node[p];
    if (next is Map<String, dynamic>) {
      node = next;
    } else {
      node = node[p] = <String, dynamic>{};
    }
  }
  node[parts.last] = value;
}

Object? _copy(Object? v) => v == null ? null : jsonDecode(jsonEncode(v));

/// The shader a skin is drawn with.
String shaderOf(Map<String, dynamic> skin) => (skin['shader'] as String?) ?? Cfg.standardShader;

/// A new skin with every item field at its default, drawn with [shader] ([info] is its parameters).
Map<String, dynamic> newSkin({required int id, required String key, required String tier, required String shader, ShaderInfo? info}) {
  final json = <String, dynamic>{
    'format': skinFormat,
    'id': id,
    'key': key,
    'tier': tier,
    'family': null,
    'familyOdds': null,
    'drops': true,
    'float': [0.0, 1.0],
    'text': {for (final f in textFields) _parts(f.path).last: f.defaultValue},
  };
  if (shader != Cfg.standardShader) {
    json['shader'] = shader;
    if (info != null) fillCustomDefaults(json, info);
  }
  return json;
}

/// Writes the default of every number, colour, placement and random value of a custom shader that
/// the skin has no entry for.
void fillCustomDefaults(Map<String, dynamic> json, ShaderInfo info) {
  Map<String, dynamic> section(String name) => json[name] is Map<String, dynamic> ? json[name] as Map<String, dynamic> : json[name] = <String, dynamic>{};
  if (info.formParams.isNotEmpty) {
    final values = section('values');
    for (final q in info.formParams) {
      values.putIfAbsent(q.key, () => _copy(q.defaultValue));
    }
  }
  if (info.placements.isNotEmpty) {
    final placements = section('placements');
    for (final q in info.placements) {
      placements.putIfAbsent(q.key, () => placementDefault(q));
    }
  }
  if (info.randoms.isNotEmpty) {
    final random = section('random');
    for (final q in info.randoms) {
      random.putIfAbsent(q.key, () => randomDefault(q));
    }
  }
}

Map<String, dynamic> placementDefault(Param q) => {
      'x': q.span('x', const Span(0, 0)).toJson(),
      'y': q.span('y', const Span(0, 0)).toJson(),
      'rotation': q.span('rotation', const Span(0, 0)).toJson(),
      'scale': double.tryParse(q.keys['scale'] ?? '') ?? 1.0,
    };

/// The component names of a random value: `x`, `y`, `z`, `w`.
List<String> randomComponents(Param q) => const ['x', 'y', 'z', 'w'].sublist(0, q.components);

Map<String, dynamic> randomDefault(Param q) => {
      for (final c in randomComponents(q)) c: q.span(c, const Span(0, 0)).toJson(),
    };

/// One image of a skin: `<name>.png` in its folder, bound to the sampler `u<Name>`.
class Slot {
  const Slot(this.name, this.label, this.help, {this.placed = false, this.sharedFile, this.flat = Cfg.blackTexel, this.flatNote = 'black'});

  /// The file name without `.png`, in snake case.
  final String name;
  final String label, help;

  /// Whether the slot is read through the pattern placement.
  final bool placed;

  /// A file in the skins folder used when the skin has none.
  final String? sharedFile;

  /// The one colour the shader gets when there is no file at all, and what it means.
  final Color flat;
  final String flatNote;

  String get fileName => '$name.png';

  /// The sampler: `pattern_material` -> `uPatternMaterial`.
  String get uniform => 'u${name.split('_').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join()}';

  /// What the shader gets without the skin's own file.
  String get defaultNote => sharedFile != null ? 'the shared $sharedFile' : flatNote;
}

/// The files of the standard card, in the order the texture list shows them.
const List<Slot> standardSlots = [
  Slot('colour', 'Colour', 'RGBA. The whole card front exactly as it shows: trim, lines, paper, art. 1496 x 2100, 4 pixels per card unit. Clear parts show the pattern.', sharedFile: Cfg.sharedColourFile, flat: Cfg.clearTexel, flatNote: 'clear'),
  Slot('normal', 'Normal', 'A tangent-space normal map, OpenGL style (flat is 128, 128, 255): embossing, rivets, paper grain, lacquer flakes.', flat: Cfg.flatNormal, flatNote: 'flat'),
  Slot('material', 'Material', 'R: metal. G: gloss. Gold leaf is metal with the gold in colour.png; lacquer is gloss without metal.', flat: Cfg.paperMaterial, flatNote: 'paper: no metal, low gloss'),
  Slot('pattern', 'Pattern', 'RGBA. A seamless sheet that the seed moves and turns. It shows wherever colour.png is clear. 1024 x 1024 for 256 card units.', placed: true, flat: Cfg.clearTexel, flatNote: 'none'),
  Slot('pattern_material', 'Pattern material', 'R: metal. G: gloss, for the pattern.', placed: true, flat: Cfg.paperMaterial, flatNote: 'paper: no metal, low gloss'),
  Slot('pattern_normal', 'Pattern normal', 'A normal map for the pattern, OpenGL style.', placed: true, flat: Cfg.flatNormal, flatNote: 'flat'),
  Slot('wear', 'Wear', 'Grey. White wears first, black never wears. It decides where and in what order the card wears; the float is the threshold. _shared/wear.png (edges and corners first) is a ready-made one.', flat: Cfg.blackTexel, flatNote: 'No file: the card never wears.'),
  Slot('under', 'Under', 'RGBA. What shows where the paint has worn off.', flat: Cfg.cardStock, flatNote: 'card stock'),
];

/// The extra images a custom shader declares with @texture.
List<Slot> customSlots(ShaderInfo? info) => [
      for (final q in info?.textures ?? const <Param>[])
        Slot(q.slotName, q.label, q.channels ?? 'An image the ${info!.name} shader reads.', flat: q.fallback.colour, flatNote: q.fallback.name),
    ];

/// Every image slot of a skin drawn with [info] (null for standard).
List<Slot> slotsFor(ShaderInfo? info) => [...standardSlots, ...customSlots(info)];
