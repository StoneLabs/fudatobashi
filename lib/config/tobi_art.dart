import 'dart:ui';

import '../ui/manga/vector.dart';
import 'design.dart';

/// Tobi the mascot, a torifuda with a hachimaki: a shared body plus one part
/// per pose, loaded from `assets/svg/tobi/` (see `vector_art_assets.dart`),
/// 84 × 100 units; arms and effects may reach outside the box.
abstract final class TobiArt {
  static const box = Size(84, 100);

  /// Drawn under every pose, in [compose]'s own pen style.
  static late final List<VShape> body;

  /// Hands on hips, friendly face.
  static late final List<VShape> standard;

  /// One arm waving, the other on the hip (onboarding).
  static late final List<VShape> waving;

  /// Fist raised, frowning with resolve (the Training hero).
  static late final List<VShape> fired;

  /// Both arms up, eyes closed with joy.
  static late final List<VShape> cheering;

  /// Arm out to the side, pointing at something.
  static late final List<VShape> pointing;

  /// Wide eyes and a sweat drop.
  static late final List<VShape> shocked;

  /// Both fists pumped, eyes squeezed shut, teeth gritted, sweating (the
  /// sprint pace).
  static late final List<VShape> tryHard;

  /// Hands behind the head ([relaxedBehind]), eyes closed in contentment,
  /// humming (the relaxed pace).
  static late final List<VShape> relaxed;
  static late final List<VShape> relaxedBehind;

  static const _pen = VStyle(stroke: Palette.ink, width: 3, cap: StrokeCap.round, join: StrokeJoin.round);

  /// Tobi in [pose]; [behind] goes under the body (limbs tucked behind it).
  static VectorArt compose(List<VShape> pose, {List<VShape> behind = const []}) => VectorArt(box, [
        VGroup([...behind, ...body, ...pose], style: _pen),
      ]);
}
