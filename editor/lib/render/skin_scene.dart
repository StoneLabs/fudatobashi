import 'dart:ui' as ui;

import '../config.dart';
import '../model/shader_info.dart';
import '../model/skin.dart';
import 'light.dart';
import 'seed_draws.dart';

/// Everything the shader needs to draw one card. It holds its images; nothing disposes an image a
/// scene may still paint, so a scene stays drawable for as long as it lives.
class SkinScene {
  const SkinScene({
    required this.program,
    required this.custom,
    required this.skin,
    required this.images,
    this.kana,
    this.badge,
    this.wearSheet,
    required this.seed,
    required this.wear,
    required this.light,
    this.tilt = ui.Offset.zero,
    this.time = 0,
  });

  final ui.FragmentProgram program;

  /// The parameters of a custom shader; null for the standard card.
  final ShaderInfo? custom;
  final Map<String, dynamic> skin;

  /// Images by slot name. A slot that is absent gets its flat default.
  final Map<String, ui.Image> images;

  /// The kana layer and the badge layer of the poem, and the shared wear sheet.
  final ui.Image? kana, badge, wearSheet;

  /// 0 to 999.
  final int seed;

  /// The wear the shader draws, 0 new to 1 worn out.
  final double wear;
  final Light light;

  /// Preview tilt, -1 to 1 on each axis.
  final ui.Offset tilt;

  /// Seconds, for animated shaders.
  final double time;

  SkinScene copyWith({ui.Offset? tilt, double? time}) => SkinScene(
        program: program,
        custom: custom,
        skin: skin,
        images: images,
        kana: kana,
        badge: badge,
        wearSheet: wearSheet,
        seed: seed,
        wear: wear,
        light: light,
        tilt: tilt ?? this.tilt,
        time: time ?? this.time,
      );

  /// What the seed decides for this skin.
  SeedDraws get draws => drawSeed(skin, custom, seed);
}

/// The skin's float range, low to high.
(double, double) floatRange(Map<String, dynamic> skin) {
  final r = skin['float'];
  if (r is List && r.length == 2 && r[0] is num && r[1] is num) return ((r[0] as num).toDouble(), (r[1] as num).toDouble());
  return (0, 1);
}

/// 1 x 1 images in one colour, made once each.
abstract final class FlatImages {
  static final Map<ui.Color, ui.Image> _cache = {};

  static ui.Image of(ui.Color color) => _cache.putIfAbsent(color, () {
        final rec = ui.PictureRecorder();
        ui.Canvas(rec).drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint()
          ..color = color
          ..blendMode = ui.BlendMode.src);
        return rec.endRecording().toImageSync(1, 1);
      });
}

(double, double, double)? parseHex(Object? v) {
  if (v is! String || !isHex(v)) return null;
  int part(int i) => int.parse(v.substring(1 + i * 2, 3 + i * 2), radix: 16);
  return (part(0) / 255, part(1) / 255, part(2) / 255);
}

final Expando<Set<String>> _absentNames = Expando('absent uniforms');
final Expando<int> _samplerCounts = Expando('sampler counts');

/// Binds uniforms and samplers by name. A name the shader does not declare is skipped (and
/// remembered per program), so a hand-edited shader still draws.
class ShaderBinder {
  ShaderBinder(this.shader, ui.FragmentProgram program) : _absent = _absentNames[program] ??= <String>{} {
    _fillSamplers(program);
  }

  final ui.FragmentShader shader;
  final Set<String> _absent;

  /// Puts a 1 x 1 image in every sampler. Outside debug builds Flutter does not check that each
  /// sampler has an image, and drawing with an empty one crashes the app, so none is ever left empty,
  /// whatever the names or images.
  void _fillSamplers(ui.FragmentProgram program) {
    final fallback = FlatImages.of(Cfg.blackTexel);
    final known = _samplerCounts[program];
    var count = 0;
    while (count < (known ?? Cfg.samplerLimit)) {
      try {
        shader.setImageSampler(count, fallback);
      } catch (_) {
        break;
      }
      count++;
    }
    _samplerCounts[program] ??= count;
  }

  void _set(String name, void Function() bind) {
    if (_absent.contains(name)) return;
    try {
      bind();
    } on ArgumentError {
      _absent.add(name);
    } catch (_) {
      // This value could not be set; a sampler keeps the image _fillSamplers gave it.
    }
  }

  void float(String n, double v) => _set(n, () => shader.getUniformFloat(n).set(v));
  void vec2(String n, double x, double y) => _set(n, () => shader.getUniformVec2(n).set(x, y));
  void vec3(String n, double x, double y, double z) => _set(n, () => shader.getUniformVec3(n).set(x, y, z));
  void vec4(String n, double x, double y, double z, double w) => _set(n, () => shader.getUniformVec4(n).set(x, y, z, w));
  void mat3(String n, List<double> m) => _set(n, () => shader.getUniformMat3(n).set(m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8]));
  void colour(String n, (double, double, double) c) => vec3(n, c.$1, c.$2, c.$3);

  void floatArray(String n, List<double> values) => _set(n, () {
        final a = shader.getUniformFloatArray(n);
        for (var i = 0; i < a.length; i++) {
          a[i].set(values[i < values.length ? i : values.length - 1]);
        }
      });

  void vec3Array(String n, List<(double, double, double)> colors) => _set(n, () {
        final a = shader.getUniformVec3Array(n);
        for (var i = 0; i < a.length; i++) {
          final c = colors[i < colors.length ? i : colors.length - 1];
          a[i].set(c.$1, c.$2, c.$3);
        }
      });

  /// [values] holds [width] numbers per item, items in order.
  void vecArray(String n, int width, List<double> values) => _set(n, () {
        double at(int i) => i < values.length ? values[i] : 0;
        switch (width) {
          case 2:
            final a = shader.getUniformVec2Array(n);
            for (var i = 0; i < a.length; i++) {
              a[i].set(at(i * 2), at(i * 2 + 1));
            }
          case 3:
            final a = shader.getUniformVec3Array(n);
            for (var i = 0; i < a.length; i++) {
              a[i].set(at(i * 3), at(i * 3 + 1), at(i * 3 + 2));
            }
          default:
            final a = shader.getUniformVec4Array(n);
            for (var i = 0; i < a.length; i++) {
              a[i].set(at(i * 4), at(i * 4 + 1), at(i * 4 + 2), at(i * 4 + 3));
            }
        }
      });

  void sampler(String n, ui.Image image, [ui.FilterQuality quality = Cfg.textureFilter]) => _set(n, () {
        shader.setImageSampler(shader.getImageSampler(n).shaderIndex, image, filterQuality: quality);
      });
}

/// Builds a shader for [scene] and binds every input. [view] is the window in card units, [size] the pixel size painted.
ui.FragmentShader bindScene(SkinScene scene, ui.Rect view, ui.Size size) {
  final shader = scene.program.fragmentShader();
  final b = ShaderBinder(shader, scene.program);

  b.vec2('uSize', size.width, size.height);
  b.vec4('uView', view.left, view.top, view.width, view.height);
  b.float('uFloat', scene.wear.clamp(0.0, 1.0));
  b.vec2('uTilt', scene.tilt.dx, scene.tilt.dy);
  b.float('uMaxTilt', Cfg.maxTilt);
  b.float('uTime', scene.time);

  final l = scene.light;
  final (lx, ly, lz) = l.direction;
  b.vec3('uLightDir', lx, ly, lz);
  b.vec3('uLightColor', l.color.r, l.color.g, l.color.b);
  b.float('uLightIntensity', l.intensity);
  b.float('uAmbient', l.ambient);

  final draws = scene.draws;
  b.mat3('uWearWin', draws.wear.matrix);
  b.mat3('uGrungeWin', draws.grunge.matrix);
  b.mat3('uPatternWin', draws.placements[patternKey]!.matrix);
  for (final f in textFields) {
    final name = f.path.split('.').last;
    b.colour('u${name[0].toUpperCase()}${name.substring(1)}', parseHex(readPath(scene.skin, f.path)) ?? parseHex(f.defaultValue)!);
  }
  b.sampler('uText', scene.kana ?? FlatImages.of(Cfg.blackTexel));
  b.sampler('uBadgeText', scene.badge ?? FlatImages.of(Cfg.blackTexel));
  b.sampler('uWearSheet', scene.wearSheet ?? FlatImages.of(Cfg.blackTexel));
  for (final slot in slotsFor(scene.custom)) {
    b.sampler(slot.uniform, scene.images[slot.name] ?? FlatImages.of(slot.flat));
  }

  final info = scene.custom;
  if (info != null) {
    for (final q in info.params) {
      switch (q.kind) {
        case ParamKind.colour || ParamKind.number || ParamKind.toggle || ParamKind.choice:
          _bindValue(b, q, readPath(scene.skin, 'values.${q.key}') ?? q.defaultValue);
        case ParamKind.placement:
          final w = draws.placements[q.key];
          if (w != null) b.mat3(q.uniform, w.matrix);
        case ParamKind.random:
          final v = draws.random[q.key];
          if (v == null) break;
          if (q.count == null && q.components == 1) {
            b.float(q.uniform, v.first);
          } else if (q.components == 1) {
            b.floatArray(q.uniform, v);
          } else if (q.count == null) {
            switch (q.components) {
              case 2:
                b.vec2(q.uniform, v[0], v[1]);
              case 3:
                b.vec3(q.uniform, v[0], v[1], v[2]);
              default:
                b.vec4(q.uniform, v[0], v[1], v[2], v[3]);
            }
          } else {
            b.vecArray(q.uniform, q.components, v);
          }
        case ParamKind.texture || ParamKind.engine:
          break;
      }
    }
  }
  return shader;
}

/// Draws [view] of the card (card units) into a new [width] x [height] image.
ui.Image renderScene(SkinScene scene, ui.Rect view, int width, int height) {
  final size = ui.Size(width.toDouble(), height.toDouble());
  final shader = bindScene(scene, view, size);
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(ui.Offset.zero & size, ui.Paint()..shader = shader);
  final picture = rec.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  shader.dispose();
  return image;
}

void _bindValue(ShaderBinder b, Param q, Object? value) {
  final fallback = q.defaultValue;
  double number(Object? v, Object? d) => (v is num ? v : (d as num)).toDouble();
  switch (q.kind) {
    case ParamKind.number:
      if (q.count == null) {
        b.float(q.uniform, number(value, fallback));
      } else {
        final list = value is List ? value : const [];
        final defaults = fallback as List;
        b.floatArray(q.uniform, [for (var i = 0; i < q.count!; i++) number(i < list.length ? list[i] : null, defaults[i])]);
      }
    case ParamKind.toggle:
      b.float(q.uniform, value == true ? 1 : 0);
    case ParamKind.choice:
      final i = q.options.indexOf('$value');
      b.float(q.uniform, i < 0 ? 0 : i.toDouble());
    case ParamKind.colour:
      if (q.count == null) {
        b.colour(q.uniform, parseHex(value) ?? parseHex(fallback)!);
      } else {
        final list = value is List ? value : const [];
        final defaults = fallback as List;
        b.vec3Array(q.uniform, [for (var i = 0; i < q.count!; i++) parseHex(i < list.length ? list[i] : null) ?? parseHex(defaults[i])!]);
      }
    default:
      break;
  }
}
