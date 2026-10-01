import 'dart:ui';

import '../ui/manga/vector.dart';
import 'design.dart';

/// Vector art loaded from `assets/svg/` (see `vector_art_assets.dart`); every
/// field below is set once, at startup, before first use.

/// Stroked UI icons (24-unit box unless noted), drawn in the current colour.
abstract final class IconArt {
  static late final VectorArt home;
  static late final VectorArt history;
  static late final VectorArt stats;
  static late final VectorArt help;
  static late final VectorArt settings;
  static late final VectorArt arrow;
  static late final VectorArt chevron;
  static late final VectorArt back;
  static late final VectorArt close;
  static late final VectorArt undo;
  static late final VectorArt end;
  static late final VectorArt question;
  static late final VectorArt refresh;
  static late final VectorArt lock;
  static late final VectorArt person;

  /// A tick (picked, in free practice's pickers).
  static late final VectorArt check;

  /// Two cards fanned (free play), 34-unit box.
  static late final VectorArt cards;

  /// A speaker with sound waves (the kimariji readout button).
  static late final VectorArt speaker;
}

/// Map furniture.
abstract final class MapArt {
  static late final VectorArt boat;
  static late final VectorArt flag;
  static late final VectorArt star;
}

/// Onboarding illustrations.
abstract final class SceneArt {
  /// Where [MapArt.flag] plants on Tobi's island ([welcomeIsle]) and on the
  /// beginner islet ([beginner]) — the two scenes that reuse it.
  static const welcomeIsleFlag = Rect.fromLTWH(20, 5, 16, 22);
  static const beginnerFlag = Rect.fromLTWH(44, 28, 22, 30);

  /// The "100" badge on the expert scene, lettered live rather than drawn.
  static const expertBadge = VText('100', Offset(30, 88), size: 17, family: Fonts.display, color: Palette.ink);

  /// Tobi's island in the welcome panel, seen from the side: the map's land
  /// with a wooded hill, on a sand bank in the map's white surf, and the
  /// map's flag. Tobi stands on the flat at about (76, 30).
  static late final VectorArt welcomeIsle;

  /// A far island on the horizon, not reached yet (the map's unexplored
  /// look); its base sits on the box's bottom edge.
  static late final VectorArt farIsle;

  /// White water around a boat's hull, which sits on the box's middle.
  static late final VectorArt boatWake;

  /// The welcome panel's front surf, tiled edge to edge: a big and a small
  /// deep-sea crest curling over to the right under foam caps.
  static late final VectorArt surf;

  /// "I'm new": an island with a flag in a round sea.
  static late final VectorArt beginner;

  /// "I know all 100": a fanned deck with a 100 badge.
  static late final VectorArt expert;
}
