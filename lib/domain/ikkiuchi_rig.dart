import '../config/config.dart';
import 'ikkiuchi_geometry.dart';

/// The faces Tobi wears in a match (一騎打ち), each one of his poses: at
/// rest, in and after a strike, and pointing at a card he holds out.
enum TobiFace { standard, reaching, cheering, shocked, pointing }

/// Tobi's arms, left and right as his art draws them.
enum ArmSide {
  left,
  right;

  /// -1 for the left arm, 1 for the right: the way it reaches out.
  double get sign => this == left ? -1 : 1;
}

/// One arm of a pose, in Tobi units: where it leaves his body, where its
/// hand is, and its fist's radius (0 for an open hand).
class TobiArm {
  const TobiArm(this.shoulder, this.hand, this.fist);

  final Vec shoulder, hand;
  final double fist;
}

/// Where Tobi's arms start and end in each face's pose, read from his art,
/// and the [size] of his box, in Tobi units.
class TobiRig {
  const TobiRig({required this.size, required this.arms});

  final Vec size;
  final Map<(TobiFace, ArmSide), TobiArm> arms;

  TobiArm arm(TobiFace face, ArmSide side) => arms[(face, side)]!;
}

/// Tobi's body in a strike: squashed or stretched about his feet by
/// [sx] and [sy], turned by [rot] radians, and shifted by [dx], [dy] dp.
class TobiBody {
  const TobiBody(this.sx, this.sy, this.rot, this.dx, this.dy);

  static const rest = TobiBody(1, 1, 0, 0, 0);

  /// [pose] leaning the way [lean] points (-1 or 1), at [k] dp a Tobi unit.
  factory TobiBody.of(IkkiuchiBodyPose pose, double lean, double k) =>
      TobiBody(pose.sx, pose.sy, lean * pose.turn, lean * pose.forward * k, pose.down * k);

  final double sx, sy, rot, dx, dy;

  TobiBody lerp(TobiBody to, double t) => TobiBody(sx + (to.sx - sx) * t, sy + (to.sy - sy) * t,
      rot + (to.rot - rot) * t, dx + (to.dx - dx) * t, dy + (to.dy - dy) * t);

  TobiBody turnedTo(double rot) => TobiBody(sx, sy, rot, dx, dy);
  TobiBody shiftedTo(double dx) => TobiBody(sx, sy, rot, dx, dy);

  /// Sprung back from this pose to rest: [g] 1 here, 0 at rest.
  TobiBody toward(double g) => rest.lerp(this, g);
}

/// Tobi on the board: his box's top left at [origin], [k] dp a Tobi unit.
class TobiFrame {
  const TobiFrame(this.origin, this.k, this.rig);

  final Vec origin;
  final double k;
  final TobiRig rig;

  /// The point between his feet his body turns about, on the board.
  Vec get feet => origin + _pivot * k;

  /// The middle of his box across the board.
  double get centreX => origin.x + rig.size.x * k / 2;

  static final _pivot = Vec(IkkiuchiArmTuning.feet.x, IkkiuchiArmTuning.feet.y);

  /// The point [q] of his art (Tobi units) on the board, his body posed
  /// by [body].
  Vec world(Vec q, TobiBody body) {
    final local = Vec((q.x - _pivot.x) * k * body.sx, (q.y - _pivot.y) * k * body.sy).rotated(body.rot);
    return feet + local + Vec(body.dx, body.dy);
  }

  /// The pivot of his art, Tobi units.
  Vec get pivot => _pivot;
}
