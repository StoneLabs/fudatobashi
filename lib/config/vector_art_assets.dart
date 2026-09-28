import 'package:flutter/services.dart' show rootBundle;

import '../ui/manga/svg_art.dart';
import '../ui/manga/vector.dart';
import 'design.dart';
import 'tobi_art.dart';
import 'vector_art.dart';

/// Every `.svg` asset the art config loads, as its path under `assets/svg/`
/// without the extension.
final _assetPaths = [
  for (final n in _iconNames) 'icons/$n',
  for (final n in _mapNames) 'map/$n',
  for (final n in _sceneNames) 'scenes/$n',
  for (final n in _tobiNames) 'tobi/$n',
  'tally',
];

const _iconNames = [
  'home', 'history', 'stats', 'help', 'settings', 'arrow', 'chevron', 'back', 'close', 'undo', 'end', 'question',
  'refresh', 'lock', 'person', 'cards',
];
const _mapNames = ['boat', 'flag', 'star'];
const _sceneNames = ['welcome-isle', 'far-isle', 'boat-wake', 'surf', 'beginner', 'expert'];
const _tobiNames = [
  'body', 'standard', 'waving', 'fired', 'cheering', 'pointing', 'shocked', 'try-hard', 'relaxed', 'relaxed-behind',
];

/// Loads every piece of vector art (icons, map furniture, onboarding scenes,
/// Tobi and the streak tally) from `assets/svg/`. Call once, before the
/// first frame that draws any of it; synchronous access afterwards.
Future<void> loadVectorArt() async {
  final entries =
      await Future.wait(_assetPaths.map((p) async => MapEntry(p, await rootBundle.loadString('assets/svg/$p.svg'))));
  installVectorArt(Map.fromEntries(entries));
}

/// Loads the same art from files, for tests and tools ([readFile] is
/// typically `(p) => File(p).readAsStringSync()`), synchronously.
void loadVectorArtSync(String Function(String path) readFile) =>
    installVectorArt({for (final p in _assetPaths) p: readFile('assets/svg/$p.svg')});

/// Parses [svg] (each keyed by its path under `assets/svg/`, without the
/// extension, as in [loadVectorArt]) and installs every piece.
void installVectorArt(Map<String, String> svg) {
  VectorArt parse(String path) => SvgArt.parse(svg[path]!, debugName: 'assets/svg/$path.svg');

  IconArt.home = parse('icons/home');
  IconArt.history = parse('icons/history');
  IconArt.stats = parse('icons/stats');
  IconArt.help = parse('icons/help');
  IconArt.settings = parse('icons/settings');
  IconArt.arrow = parse('icons/arrow');
  IconArt.chevron = parse('icons/chevron');
  IconArt.back = parse('icons/back');
  IconArt.close = parse('icons/close');
  IconArt.undo = parse('icons/undo');
  IconArt.end = parse('icons/end');
  IconArt.question = parse('icons/question');
  IconArt.refresh = parse('icons/refresh');
  IconArt.lock = parse('icons/lock');
  IconArt.person = parse('icons/person');
  IconArt.cards = parse('icons/cards');

  MapArt.boat = parse('map/boat');
  MapArt.flag = parse('map/flag');
  MapArt.star = parse('map/star');

  SceneArt.farIsle = parse('scenes/far-isle');
  SceneArt.boatWake = parse('scenes/boat-wake');
  SceneArt.surf = parse('scenes/surf');
  final welcomeIsle = parse('scenes/welcome-isle');
  SceneArt.welcomeIsle = welcomeIsle +
      VectorArt(welcomeIsle.box, [VUse(MapArt.flag, SceneArt.welcomeIsleFlag)], origin: welcomeIsle.origin);
  final beginner = parse('scenes/beginner');
  SceneArt.beginner =
      beginner + VectorArt(beginner.box, [VUse(MapArt.flag, SceneArt.beginnerFlag)], origin: beginner.origin);
  final expert = parse('scenes/expert');
  SceneArt.expert = expert + VectorArt(expert.box, [SceneArt.expertBadge], origin: expert.origin);

  TobiArt.body = parse('tobi/body').shapes;
  TobiArt.standard = parse('tobi/standard').shapes;
  TobiArt.waving = parse('tobi/waving').shapes;
  TobiArt.fired = parse('tobi/fired').shapes;
  TobiArt.cheering = parse('tobi/cheering').shapes;
  TobiArt.pointing = parse('tobi/pointing').shapes;
  TobiArt.shocked = parse('tobi/shocked').shapes;
  TobiArt.tryHard = parse('tobi/try-hard').shapes;
  TobiArt.relaxed = parse('tobi/relaxed').shapes;
  TobiArt.relaxedBehind = parse('tobi/relaxed-behind').shapes;

  Tally.strokes = SvgArt.strokes(svg['tally']!, debugName: 'assets/svg/tally.svg');
}
