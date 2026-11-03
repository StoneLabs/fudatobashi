import 'dart:ui';

import '../../config/tobi_art.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../domain/ikkiuchi_rig.dart';
import '../manga/svg_path.dart';
import '../manga/tobi.dart';
import '../manga/vector.dart';

/// Tobi's art in a match (一騎打ち): his pose for each face, drawn with
/// or without one arm, and where his arms start and end in each.
abstract final class IkkiuchiTobiArt {
  static TobiPose poseOf(TobiFace face) => switch (face) {
        TobiFace.standard => TobiPose.standard,
        TobiFace.reaching => TobiPose.tryHard,
        TobiFace.cheering => TobiPose.cheering,
        TobiFace.shocked => TobiPose.shocked,
        TobiFace.pointing => TobiPose.pointing,
      };

  static List<VShape> _shapes(TobiFace face) => switch (face) {
        TobiFace.standard => TobiArt.standard,
        TobiFace.reaching => TobiArt.tryHard,
        TobiFace.cheering => TobiArt.cheering,
        TobiFace.shocked => TobiArt.shocked,
        TobiFace.pointing => TobiArt.pointing,
      };

  static VTag _tag(ArmSide side) => side == ArmSide.left ? VTag.armLeft : VTag.armRight;

  static final _art = <(TobiFace, ArmSide?), VectorArt>{};

  /// Tobi in [face]'s pose, without the arm on [without] when given.
  static VectorArt art(TobiFace face, {ArmSide? without}) => _art[(face, without)] ??= without == null
      ? Tobi.artOf(poseOf(face))
      : TobiArt.compose([
          for (final s in _shapes(face))
            if (s.tag != _tag(without)) s,
        ]);

  /// Where his arms start and end in each face's pose, read from the art.
  static TobiRig rig() => TobiRig(
        size: Vec(TobiArt.box.width, TobiArt.box.height),
        arms: {
          for (final face in TobiFace.values)
            for (final side in ArmSide.values) (face, side): _arm(face, side),
        },
      );

  /// An arm: its line starts at the shoulder; its hand is the fist's
  /// centre, or the line's end for an open hand.
  static TobiArm _arm(TobiFace face, ArmSide side) {
    final group = _shapes(face).whereType<VGroup>().firstWhere((g) => g.tag == _tag(side));
    final line = SvgPath.parse(group.children.whereType<VPath>().first.d).computeMetrics().toList();
    final start = line.first.getTangentForOffset(0)!.position;
    final end = line.last.getTangentForOffset(line.last.length)!.position;
    final fist = group.children.whereType<VEllipse>().firstOrNull;
    return TobiArm(_vec(start), fist == null ? _vec(end) : _vec(fist.center), fist?.rx ?? 0);
  }

  static Vec _vec(Offset o) => Vec(o.dx, o.dy);
}
