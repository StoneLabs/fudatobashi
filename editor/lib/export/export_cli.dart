import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;

import '../config.dart';
import '../io/shader_library.dart';
import '../model/skin.dart';
import '../model/skin_loader.dart';
import '../render/kana_texture.dart';
import '../render/light.dart';
import '../render/skin_scene.dart';

const _usage = '''
Usage: fudatobashi_skin_editor --export <skinsDir> <outDir> [options]

Renders each skin with its preview poem to <outDir>/<key>.png and exits.
  --skins a,b        only these skin folders
  --scale N          pixels per card unit (default ${Cfg.exportScale})
  --seed N           seed (default ${Cfg.exportSeed})
  --float F          0 to 1, squeezed into the skin's float range (default 0, the low end)
  --tilt x,y         tilt, -1 to 1 on each axis (default 0,0)
  --time T           seconds, for animated shaders (default 0)
  --crop x,y,w,h     only this part of the card, in card units
''';

class _Options {
  late Directory skins, out;
  List<String>? only;
  double scale = Cfg.exportScale;
  int seed = Cfg.exportSeed;
  double float01 = 0, time = 0;
  ui.Offset tilt = ui.Offset.zero;
  ui.Rect? crop;
}

List<double> _numbers(String text, int count, String flag) {
  final parts = text.split(',').map(double.tryParse).toList();
  if (parts.length != count || parts.contains(null)) throw FormatException('$flag needs $count numbers separated by commas');
  return parts.cast<double>();
}

_Options _parse(List<String> args) {
  final o = _Options();
  final positional = <String>[];
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    String value() {
      if (i + 1 >= args.length) throw FormatException('$a needs a value');
      return args[++i];
    }

    switch (a) {
      case '--skins':
        o.only = value().split(',');
      case '--scale':
        o.scale = double.parse(value());
      case '--seed':
        o.seed = int.parse(value());
      case '--float':
        o.float01 = double.parse(value());
      case '--time':
        o.time = double.parse(value());
      case '--tilt':
        final t = _numbers(value(), 2, a);
        o.tilt = ui.Offset(t[0], t[1]);
      case '--crop':
        final c = _numbers(value(), 4, a);
        o.crop = ui.Rect.fromLTWH(c[0], c[1], c[2], c[3]);
      default:
        if (a.startsWith('--')) throw FormatException('Unknown option $a');
        positional.add(a);
    }
  }
  if (positional.length != 2) throw const FormatException('Give the skins folder and the output folder');
  o.skins = Directory(positional[0]);
  o.out = Directory(positional[1]);
  if (!o.skins.existsSync()) throw FormatException('${o.skins.path} does not exist');
  return o;
}

/// Renders skins to PNG files without opening any interface. Returns the exit code.
Future<int> runExport(List<String> args) async {
  final _Options o;
  try {
    o = _parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n$_usage');
    return 2;
  }
  o.out.createSync(recursive: true);
  ShaderLibrary.clearLive();
  final library = ShaderLibrary(bundled: await ui.FragmentProgram.fromAsset(Cfg.shaderAsset));
  await library.watch(o.skins);
  var failures = 0;
  final root = Directory(p.normalize(o.skins.absolute.path));
  final wearSheet = await loadEngineImage(root, Cfg.wearSheetFile);
  for (final skin in await scanSkins(root)) {
    final folder = p.basename(skin.dir.path);
    if (o.only != null && !o.only!.contains(folder)) continue;
    final problem = formatProblem(skin.json);
    if (problem != null) {
      stderr.writeln('$folder: $problem');
      failures++;
      continue;
    }
    final shader = shaderOf(skin.json);
    await library.ensure(shader);
    final result = library.result(shader);
    if (result != null && !result.ok) {
      stderr.writeln('$folder: ${result.summary}');
      failures++;
      continue;
    }
    final poem = Cfg.defaultPoem;
    final custom = shader == Cfg.standardShader ? null : library.info(shader);
    final (lo, hi) = floatRange(skin.json);
    final scene = SkinScene(
      program: library.program(shader),
      custom: custom,
      badge: await buildBadgeTexture(poem, badgeCenter(skin.json)),
      wearSheet: wearSheet,
      skin: skin.json,
      images: await loadSkinImages(root, skin.dir, slotsFor(custom)),
      kana: await buildKanaTexture(poem),
      seed: o.seed,
      wear: lo + o.float01.clamp(0.0, 1.0) * (hi - lo),
      light: lightPresets.first.light,
      tilt: o.tilt,
      time: o.time,
    );
    final view = o.crop ?? const ui.Rect.fromLTWH(0, 0, Cfg.cardWidth, Cfg.cardHeight);
    final image = renderScene(scene, view, (view.width * o.scale).round(), (view.height * o.scale).round());
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(p.join(o.out.path, '$folder.png'));
    await file.writeAsBytes(png!.buffer.asUint8List());
    stdout.writeln('${file.path} ${image.width}x${image.height}');
    image.dispose();
  }
  library.dispose();
  return failures == 0 ? 0 : 1;
}

/// Exits the app once the export is done. Kept apart so [runExport] stays testable.
Future<void> exportAndExit(List<String> args) async {
  final code = await runExport(args);
  exit(code);
}
