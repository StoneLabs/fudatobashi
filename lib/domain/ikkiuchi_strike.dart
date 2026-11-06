import 'dart:math' as math;

import '../config/config.dart';
import 'ikkiuchi_geometry.dart';
import 'ikkiuchi_rig.dart';

/// Tobi's four arm moves (一騎打ち): the clean row sweep (払い) and the three
/// wild ones.
enum IkkiuchiMove { sweep, whip, coilLunge, smear }

/// What a strike needs to know of the board.
class IkkiuchiStrikeSetup {
  const IkkiuchiStrikeSetup({
    required this.target,
    required this.targetId,
    required this.tobi,
    required this.board,
    required this.cardW,
    required this.away,
    this.wrong = const [],
    this.targetWrong = false,
    this.reachMs,
    this.endFace = TobiFace.cheering,
    this.side,
    this.lead,
  });

  /// The card struck, and its id (which settles the arm for a card right
  /// in front of him).
  final CardBox target;
  final int targetId;
  final TobiFrame tobi;

  /// The board's size; the hand never leaves it.
  final Vec board;

  /// A card's width on the board, dp: the unit of the strike's lengths
  /// that aren't Tobi's own.
  final double cardW;

  /// Points from the side without the called card toward the called card's
  /// side: the follow-through never goes against it.
  final Vec away;

  /// The cards on the side without the called card, which the live fist
  /// keeps clear of.
  final List<CardBox> wrong;

  /// Whether the card struck is itself one he would keep clear of, as when
  /// he goes for a card on the side without the called card, or any card
  /// on a からふだ: the hit then lands where it is aimed.
  final bool targetWrong;

  /// Screen ms from the start of the reach to the hit; the move's own
  /// timing when null. Never under [IkkiuchiTuning.reachFloorMs].
  final double? reachMs;

  /// His face once the strike is over, whose pose his hand goes home to.
  final TobiFace endFace;

  /// The arm to strike with; the one on the card's side when null.
  final ArmSide? side;

  /// A strike this one cuts in on, and the time in it this one starts at:
  /// the hand sets off from where it is then.
  final ({IkkiuchiStrike strike, double at})? lead;
}

/// Tobi's arm in one move of its own: a pure function of its own time, so
/// any moment can be drawn again exactly. Its hand at each move time, how
/// the arm bends behind it and how the fist shows; screen time [t] maps to
/// move time by [tau].
abstract class IkkiuchiArmMove {
  /// The arm that moves, and the face whose pose its shoulder is drawn
  /// from.
  ArmSide get side;
  TobiFace get armFace;

  /// The fist's radius, dp.
  double get fist;

  /// Screen ms of the whole move.
  double get end;

  double tau(double t);
  Vec handAt(double tau);
  TobiBody bodyAt(double t);

  /// His face at screen time [t].
  TobiFace faceAt(double t);
  double lagAt(double tau);
  double waveAt(double tau);
  double bulgeAt(double tau);
  double coilAt(double tau);

  /// The fist's size at move time [tau], as a share of [fist].
  double fistScale(double tau);

  bool doneAt(double t) => t >= end;

  Vec handAtTime(double t) => handAt(tau(t));

  /// The hand's velocity at move time [tau], dp a second of move time:
  /// what the arm's look uses, so the move looks the same at any pace.
  Vec handVelocity(double tau) {
    const w = IkkiuchiArmTuning.speedWindow;
    return (handAt(tau) - handAt(tau - w)) * (Duration.millisecondsPerSecond / w);
  }

  /// The hand's speed at move time [tau], dp a ms of move time.
  double handSpeed(double tau) => handVelocity(tau).length / Duration.millisecondsPerSecond;

  /// The arm's curve at move time [tau] from the shoulder [s]: the hand's
  /// path seen a little late further back along the arm, plus the bulge,
  /// the travelling wave and the coil.
  List<Vec> armPoints(double tau, Vec s) {
    final lag = lagAt(tau), wave = waveAt(tau), bulge = bulgeAt(tau), coil = coilAt(tau);
    final sign = side.sign;
    final h = handAt(tau);
    final axis = (h - s).unit;
    final nrm = axis.perp;
    final coiled = coil > _coilShown;
    final n = coiled ? IkkiuchiArmTuning.coilSamples : IkkiuchiArmTuning.samples;
    final points = <Vec>[];
    for (var i = 0; i < n; i++) {
      final u = i / n;
      final hu = handAt(tau - lag * math.pow(1 - u, IkkiuchiArmTuning.lagPower));
      var p = s + (hu - s) * u;
      if (coiled) {
        final th = 2 * math.pi * IkkiuchiArmTuning.coilLoops * u;
        final depth = coil * math.sqrt(math.sin(math.pi * u));
        p = p + axis * (-depth * math.sin(th)) + nrm * (sign * depth * (1 - math.cos(th)));
      }
      final env = math.sin(math.pi * u);
      final travel = math.sin(2 * math.pi * (IkkiuchiArmTuning.waveLength * u - tau / IkkiuchiArmTuning.wavePeriod));
      points.add(p + nrm * (-bulge * env * sign + wave * env * travel));
    }
    return points..add(h);
  }

  // A coil thinner than this (dp) is drawn as a plain arm.
  static const _coilShown = 0.5;
}

/// One strike of Tobi's arm at a card.
///
/// Each move has its own timing ("move time"); a strike plays it faster or
/// slower so the hit comes [hitAt] screen ms after the reach starts, holds
/// still for the hit stop, then plays the rest at a pace held within
/// [IkkiuchiArmTuning.afterPace]. The fist touches cards only while it is
/// live, from the end of the hit stop to the end of the follow-through
/// (the same piece of path at every speed); before that it is in the air,
/// and on the way home it is lifted.
class IkkiuchiStrike extends IkkiuchiArmMove {
  IkkiuchiStrike(this.move, this.setup) {
    final tobi = setup.tobi;
    final card = setup.target;
    final k = tobi.k, u = setup.cardW;
    final off = card.centre.x - tobi.centreX;
    final sideDeadZone = IkkiuchiArmTuning.sideDeadZone * u;
    side = setup.side ??
        (off < -sideDeadZone
            ? ArmSide.left
            : off > sideDeadZone
                ? ArmSide.right
                : (setup.targetId.isOdd ? ArmSide.left : ArmSide.right));
    final sgn = side.sign;
    final rig = tobi.rig;
    final shoulder = tobi.world(rig.arm(TobiFace.reaching, side).shoulder, TobiBody.rest);
    final lead = setup.lead;
    final h0 = lead == null
        ? tobi.world(rig.arm(TobiFace.reaching, side).hand, TobiBody.rest)
        : lead.strike.handAtTime(lead.at);
    final hEnd = tobi.world(rig.arm(setup.endFace, side).hand, TobiBody.rest);
    final t = card.centre;
    final reach = t - shoulder;
    final f = reach.unit;
    var n = f.perp;
    if (n.x * sgn < 0) n = -n;
    final e = card.reachAlong(n);
    final rowX = off.abs() > sideDeadZone ? off.sign : sgn;
    final reachMs = setup.reachMs == null ? null : math.max(IkkiuchiTuning.reachFloorMs, setup.reachMs!);
    _geo = _Geo(
      shoulder: shoulder,
      h0: h0,
      hEnd: hEnd,
      target: t,
      edge: t + n * e,
      n: n,
      f: f,
      d: reach.length,
      k: k,
      u: u,
      lean: off.abs() > IkkiuchiArmTuning.leanDeadZone * u ? off.sign : sgn,
      side: sgn,
      board: setup.board,
      row: Vec(rowX, 0),
      rowHalf: card.hw,
      rowExitX: rowX > 0 ? setup.board.x - IkkiuchiArmTuning.rowExitInset * u : IkkiuchiArmTuning.rowExitInset * u,
      reachMs: reachMs,
      away: setup.away,
      touch: IkkiuchiArmTuning.fist * u * IkkiuchiArmTuning.touch,
      wrong: setup.wrong,
      targetWrong: setup.targetWrong,
      body0: lead == null ? TobiBody.rest : lead.strike.bodyAt(lead.at),
    );
    _plan = switch (move) {
      IkkiuchiMove.whip => _whip(_geo),
      IkkiuchiMove.coilLunge => _coilLunge(_geo),
      IkkiuchiMove.smear => _smear(_geo),
      IkkiuchiMove.sweep => _sweep(_geo),
    };
    hitStop = switch (move) {
      IkkiuchiMove.whip => IkkiuchiWhipTuning.hitStop,
      IkkiuchiMove.coilLunge => IkkiuchiCoilTuning.hitStop,
      IkkiuchiMove.smear => IkkiuchiSmearTuning.hitStop,
      IkkiuchiMove.sweep => IkkiuchiSweepTuning.hitStop,
    };
    _pre = reachMs == null ? 1 : reachMs / _plan.tc;
    _post = reachMs == null
        ? 1
        : _pre.clamp(IkkiuchiArmTuning.afterPace.min, IkkiuchiArmTuning.afterPace.max).toDouble();
    hitAt = _plan.tc * _pre;
    end = hitAt + hitStop + (_plan.end - _plan.tc) * _post;
    fist = IkkiuchiArmTuning.fist * u;
    _fistStart = lead == null ? rig.arm(TobiFace.reaching, side).fist * k / fist : 1;
    _fistEnd = rig.arm(setup.endFace, side).fist * k / fist;
  }

  final IkkiuchiMove move;
  final IkkiuchiStrikeSetup setup;

  /// The arm he strikes with.
  @override
  late final ArmSide side;

  @override
  TobiFace get armFace => TobiFace.reaching;

  /// Screen ms from the start of the reach to the hit, the hit stop, and
  /// the whole strike.
  late final double hitAt;
  late final double hitStop;
  @override
  late final double end;

  late final _Geo _geo;
  late final _Plan _plan;
  late final double _pre, _post, _fistStart, _fistEnd;

  /// The fist's radius, dp, and how near a card its centre touches it.
  @override
  late final double fist;
  double get touch => _geo.touch;

  /// Where the hand meets the card: the edge it comes at (moved toward the
  /// called card's side where the hit must land clear), or for the row
  /// sweep, its side along the row.
  Vec get contact => _plan.contact ?? _geo.edge;

  /// From his shoulder toward the card, and square to it outward.
  Vec get forward => _geo.f;
  Vec get outward => _geo.n;

  /// Along the row, the way the row sweep runs.
  Vec get rowWay => _geo.row;

  /// Whether the move sends the card off cleanly along its row.
  bool get clean => _plan.clean;

  /// The move time where the hand leaves for the card, the hit, and where
  /// the follow-through ends and the lifted hand turns for home.
  double get goAt => _plan.goAt;
  double get contactTau => _plan.tc;
  double get backAt => _plan.backAt;

  /// Screen ms the fist is live from and until.
  double get liveFrom => hitAt + hitStop;
  double get liveUntil => liveFrom + (_plan.backAt - _plan.tc) * _post;

  /// The move time at screen time [t]: paced, and frozen for the hit stop.
  @override
  double tau(double t) {
    if (t < hitAt) return t / _pre;
    if (t < hitAt + hitStop) return _plan.tc;
    return _plan.tc + (t - hitAt - hitStop) / _post;
  }

  /// Whether the fist touches what it meets at screen time [t].
  bool liveAt(double t) => liveAtTau(tau(t), afterHit: t >= liveFrom);

  /// [liveAt] at move time [tau], [afterHit] once the hit stop is over.
  bool liveAtTau(double tau, {required bool afterHit}) => afterHit && tau <= _plan.backAt;

  /// The hand at move time [tau]; before the strike, where the strike it
  /// cut in on had it.
  @override
  Vec handAt(double tau) {
    final lead = setup.lead;
    if (tau < 0 && lead != null) return lead.strike.handAtTime(lead.at + tau * _pre);
    return _plan.hand(tau);
  }

  @override
  TobiBody bodyAt(double t) => _plan.body(tau(t));

  @override
  double lagAt(double tau) => _plan.lag(tau);
  @override
  double waveAt(double tau) => _plan.wave(tau);
  @override
  double bulgeAt(double tau) => _plan.bulge(tau);
  @override
  double coilAt(double tau) => _plan.coil(tau);

  /// How strong the smear afterimages are, 0 to 1.
  double smearAt(double tau) => _plan.smear(tau);

  /// The hand's velocity at move time [tau] on the screen, dp/s: what the
  /// hit and the pushes use.
  Vec realVelocity(double tau) => handVelocity(tau) * (1 / (tau < _plan.tc ? _pre : _post));

  @override
  TobiFace faceAt(double t) =>
      t < liveFrom + IkkiuchiArmTuning.faceAfterHit ? TobiFace.reaching : setup.endFace;

  /// The fist's size at move time [tau], as a share of [fist]: it grows
  /// out of his pose's fist at the very start and turns into the end
  /// pose's hand at the very end.
  @override
  double fistScale(double tau) {
    const settle = IkkiuchiArmTuning.fistSettle;
    final grown = _fistStart + (1 - _fistStart) * (tau / settle).clamp(0.0, 1.0);
    final p = ((tau - (_plan.end - settle)) / settle).clamp(0.0, 1.0);
    return grown + (_fistEnd - grown) * p;
  }
}

/// A strike's geometry: [shoulder] and the resting hand [h0] (or where a
/// strike cut in on had it), [hEnd] the end pose's hand, the card's centre
/// [target], the [edge] the hand meets, [n] outward square to the reach,
/// [f] toward the card, [d] the reach, [k] dp a Tobi unit, [u] dp a card
/// width, [lean] the way his body leans, [side] his arm's sign, the [row] way and its half card
/// [rowHalf] and exit, and [body0] his body at the start.
class _Geo {
  _Geo({
    required this.shoulder,
    required this.h0,
    required this.hEnd,
    required this.target,
    required this.edge,
    required this.n,
    required this.f,
    required this.d,
    required this.k,
    required this.u,
    required this.lean,
    required this.side,
    required this.board,
    required this.row,
    required this.rowHalf,
    required this.rowExitX,
    required this.reachMs,
    required this.away,
    required this.touch,
    required this.wrong,
    required this.targetWrong,
    required this.body0,
  });

  final Vec shoulder, h0, hEnd, target, edge, n, f, board, row, away;
  final double d, k, u, lean, side, rowHalf, rowExitX, touch;
  final double? reachMs;
  final List<CardBox> wrong;
  final bool targetWrong;
  final TobiBody body0;

  TobiBody pose(IkkiuchiBodyPose p, [double? way]) => TobiBody.of(p, way ?? lean, k);

  /// [p] moved inside the board, [margin] card widths in from its edges.
  Vec onBoard(Vec p, [double margin = IkkiuchiArmTuning.screenMargin]) => Vec(
      p.x.clamp(margin * u, board.x - margin * u), p.y.clamp(margin * u, board.y - margin * u));

  /// How far from [p] along [dir] the board's edge is.
  double roomAlong(Vec p, Vec dir) {
    var t = double.infinity;
    if (dir.x > _tiny) t = math.min(t, (board.x - p.x) / dir.x);
    if (dir.x < -_tiny) t = math.min(t, -p.x / dir.x);
    if (dir.y > _tiny) t = math.min(t, (board.y - p.y) / dir.y);
    if (dir.y < -_tiny) t = math.min(t, -p.y / dir.y);
    return t;
  }

  static const _tiny = 1e-6;

  /// The hand on its way home: [g] 1 at [from], 0 at [home], negative past
  /// it, its overshoot held to [IkkiuchiArmTuning.overshootCap].
  Vec returnHand(Vec from, Vec home, double g) {
    final span = from - home;
    final dist = span.length;
    final gg = g < 0 && dist > 0 ? g * math.min(1, IkkiuchiArmTuning.overshootCap * u / dist) : g;
    return home + span * gg;
  }

  /// The follow-through from [from] (the hit) along [dir] for [length] dp
  /// over [dur] ms, eased by [curve] and bent [bend] dp toward the called
  /// card's side by its end. [tc], the move's own ms to the hit, scales the
  /// length with the take's speed unless [scaled] is false. Any part of
  /// [dir] toward the side without the called card is dropped, and it
  /// brakes where its touch would come near a card there.
  _Follow follow({
    required Vec from,
    required Vec dir,
    required double length,
    required double dur,
    required double tc,
    double bend = 0,
    double Function(double p) curve = _Ease.outCubic,
    bool scaled = true,
  }) {
    final ms = reachMs;
    final scale = scaled && ms != null
        ? math.sqrt(tc / ms).clamp(IkkiuchiArmTuning.followScale.min, IkkiuchiArmTuning.followScale.max)
        : 1.0;
    final kept = notAgainst(dir, away);
    final run = length * scale * math.max(kept.share, IkkiuchiArmTuning.followKeep);
    final end = from + kept.dir * run + away * bend;
    final bendFrom = from + kept.dir * (run * IkkiuchiArmTuning.followBendAt);
    Vec path(double s) => bezier(from, bendFrom, end, s);
    final stop = _clearRun(path);
    return _Follow(
      dur * math.sqrt(stop).clamp(IkkiuchiArmTuning.brakeMin, 1.0),
      (p) => path(stop * curve(p)),
      path(stop),
    );
  }

  /// Whether the fist's touch at [p] keeps [IkkiuchiArmTuning.clearance]
  /// from every card in [wrong].
  bool clearAt(Vec p) => gapToCards(wrong, p) - touch >= IkkiuchiArmTuning.clearance * u;

  /// Where a hit meant for [p] lands, so the live fist sets off clear of
  /// the side without the called card: [p] itself when [clearAt] or when
  /// he means to strike a wrong card ([targetWrong]), else [p] moved toward
  /// the called card's side just far enough. That happens where the sides
  /// lie close and he comes at the card's edge facing the other side.
  Vec clearHit(Vec p) {
    if (targetWrong || clearAt(p)) return p;
    // Out from [p] by the touch and its clearance until clear, then halved
    // back in.
    final out = touch + IkkiuchiArmTuning.clearance * u;
    var lo = 0.0, hi = out;
    while (!clearAt(p + away * hi)) {
      lo = hi;
      hi += out;
    }
    for (var j = 0; j < IkkiuchiArmTuning.brakeRefine; j++) {
      final mid = (lo + hi) / 2;
      if (clearAt(p + away * mid)) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return p + away * hi;
  }

  /// How far along [path] (0 to 1) the fist goes before its touch comes
  /// within [IkkiuchiArmTuning.clearance] of a card in [wrong].
  double _clearRun(Vec Function(double s) path) {
    if (wrong.isEmpty) return 1;
    bool clear(double s) => clearAt(path(s));
    if (!clear(0)) return 0;
    const n = IkkiuchiArmTuning.brakeSamples;
    for (var i = 1; i <= n; i++) {
      if (clear(i / n)) continue;
      var lo = (i - 1) / n, hi = i / n;
      for (var j = 0; j < IkkiuchiArmTuning.brakeRefine; j++) {
        final mid = (lo + hi) / 2;
        if (clear(mid)) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      return lo;
    }
    return 1;
  }
}

/// A follow-through: its [dur], the hand at each share of it, and its [end].
class _Follow {
  _Follow(this.dur, this.at, this.end);

  final double dur;
  final Vec Function(double p) at;
  final Vec end;
}

/// A move's plan, in move time: where the hand leaves for the card
/// ([goAt]), the hit ([tc]), where the follow-through ends ([backAt]) and
/// the [end]; and the hand, lag, wave, bulge, coil, smear and body over it.
class _Plan {
  _Plan({
    required this.goAt,
    required this.tc,
    required this.backAt,
    required this.end,
    required this.hand,
    required this.lag,
    required this.body,
    this.wave = _none,
    this.bulge = _none,
    this.coil = _none,
    this.smear = _none,
    this.clean = false,
    this.contact,
  });

  final double goAt, tc, backAt, end;
  final Vec Function(double tau) hand;
  final double Function(double tau) lag, wave, bulge, coil, smear;
  final TobiBody Function(double tau) body;
  final bool clean;

  /// Where the hand meets the card, when not at the edge it comes at.
  final Vec? contact;

  static double _none(double tau) => 0;
}

/// One piece of a timeline: [dur] ms long, [f] given its progress 0..1
/// and its own ms.
class _Piece<T> {
  const _Piece(this.dur, this.f);

  final double dur;
  final T Function(double p, double ms) f;
}

/// Pieces one after another: [before] up to their start, [after] past their end.
T Function(double t) _timeline<T>(List<_Piece<T>> pieces, T before, T after) => (t) {
      if (t <= 0) return before;
      var t0 = 0.0;
      for (final pc in pieces) {
        if (t < t0 + pc.dur) return pc.f((t - t0) / pc.dur, t - t0);
        t0 += pc.dur;
      }
      return after;
    };

/// A constant over a piece.
_Piece<double> _flat(double dur, double v) => _Piece(dur, (_, _) => v);

abstract final class _Ease {
  static double inOutSine(double p) => 0.5 - 0.5 * math.cos(math.pi * p);
  static double outCubic(double p) => 1 - _pow(1 - p, 3);
  static double inOutCubic(double p) => p < 0.5 ? 4 * p * p * p : 1 - _pow(-2 * p + 2, 3) / 2;
  static double inOutQuart(double p) => p < 0.5 ? 8 * _pow(p, 4) : 1 - _pow(-2 * p + 2, 4) / 2;
  static double outQuart(double p) => 1 - _pow(1 - p, 4);

  /// Eases out past 1 and back, by [s].
  static double backOut(double p, double s) => 1 + (s + 1) * _pow(p - 1, 3) + s * _pow(p - 1, 2);

  /// A spring dying out from 1.
  static double spring(double p, IkkiuchiSpring s) => math.exp(-s.decay * p) * math.cos(s.waves * math.pi * p);

  static double clamp01(double p) => p.clamp(0.0, 1.0);
}

double _pow(double p, double e) => math.pow(p, e).toDouble();

typedef _W = IkkiuchiWhipTuning;
typedef _B = IkkiuchiCoilTuning;
typedef _C = IkkiuchiSmearTuning;
typedef _D = IkkiuchiSweepTuning;

/// The wide whip.
_Plan _whip(_Geo c) {
  final k = c.k;
  const tw = _W.windUp, to = _W.out, tr = _W.back;
  const tc = tw + to;
  final hw = c.h0 + c.f * (-_W.windBack * k) + c.n * (_W.windOut * k);
  final hit = c.clearHit(c.edge);
  final q = c.onBoard(hw.lerp(hit, _W.bowAt) + c.n * math.max(_W.bow * c.d, _W.bowMin * c.u));
  final fol = c.follow(
    from: hit,
    dir: (hit - q).unit,
    length: (_W.followShare * c.d).clamp(_W.followMin * c.u, _W.followMax * c.u),
    dur: _W.follow,
    tc: tc,
  );
  final back = tc + fol.dur;
  final wound = c.pose(_W.wound), struck = c.pose(_W.struck);
  final turned = struck.turnedTo(c.lean * _W.followTurn);
  return _Plan(
    goAt: tw,
    tc: tc,
    backAt: back,
    end: back + tr,
    contact: hit,
    hand: _timeline([
      _Piece(tw, (p, _) => c.h0.lerp(hw, _Ease.inOutSine(p))),
      _Piece(to, (p, _) => bezier(hw, q, hit, _pow(p, _W.outPower))),
      _Piece(fol.dur, (p, _) => fol.at(p)),
      _Piece(tr, (p, _) => c.returnHand(fol.end, c.hEnd, _Ease.spring(p, _W.home))),
    ], c.h0, c.hEnd),
    lag: _timeline([
      _flat(tw, _W.lagWind),
      _flat(to, _W.lagOut),
      _flat(fol.dur, _W.lagFollow),
      _flat(tr, _W.lagHome),
    ], _W.lagRest, _W.lagRest),
    wave: _timeline([
      _flat(tw, _W.waveWind * k),
      _flat(to, _W.waveOut * k),
      _flat(fol.dur, _W.waveFollow * k),
      _Piece(tr, (p, _) => _W.waveHome * k * (1 - p)),
    ], 0, 0),
    bulge: _timeline([
      _Piece(tw, (p, _) => _W.bulgeWind * k * _Ease.inOutSine(p)),
      _Piece(to, (p, _) => _W.bulgeWind * k + _W.bulgeOut * k * math.sin(math.pi * p)),
      _Piece(fol.dur, (p, _) => _W.bulgeWind * k * (1 - p)),
    ], 0, 0),
    body: _timeline([
      _Piece(tw, (p, _) => c.body0.lerp(wound, _Ease.inOutSine(p))),
      _Piece(to, (p, _) => wound.lerp(struck, _Ease.outCubic(_Ease.clamp01(p * _W.strikeQuick)))),
      _Piece(fol.dur, (p, _) => struck.lerp(turned, _Ease.outCubic(p))),
      _Piece(tr, (p, _) => turned.toward(_Ease.spring(p, _W.home))),
    ], c.body0, TobiBody.rest),
  );
}

/// The coil and lunge.
_Plan _coilLunge(_Geo c) {
  final k = c.k;
  const tco = _B.coil, th = _B.hold, tl = _B.lunge, ts = _B.sweep, tr = _B.back;
  final centre = c.shoulder + c.n * (_B.coilOut * k) + c.f * (_B.coilForward * k);
  final r0 = c.h0.distanceTo(centre), r1 = _B.coilRadius * k;
  final a0 = math.atan2(c.h0.y - centre.y, c.h0.x - centre.x);
  final spin = -c.side * 2 * math.pi * _B.turns;
  Vec coilAt(double p) {
    final q = _Ease.inOutSine(p);
    final ang = a0 + spin * q, r = r0 + (r1 - r0) * q;
    return centre + Vec(math.cos(ang), math.sin(ang)) * r;
  }

  final hc = coilAt(1);
  final u = c.u;
  final land0 = c.target + c.n * (c.edge.distanceTo(c.target) + _B.landOut * u) + c.f * (-_B.landBack * u);
  final past0 = c.target + c.n * (-(c.edge.distanceTo(c.target) + _B.sweepOut * u)) + c.f * (_B.sweepOn * u);
  // The sweep across the card: up to the hit, then its follow-through. It
  // moves with the hit where the hit must land clear.
  final qc = math.min(1.0, _B.hitInto * u / land0.distanceTo(past0));
  final pc = 1 - math.pow(1 - qc, 1 / 3).toDouble();
  final tc = tco + th + tl + pc * ts;
  final aim = land0.lerp(past0, qc);
  final hit = c.clearHit(aim);
  final shift = hit - aim;
  final land = land0 + shift, past = past0 + shift;
  final fol = c.follow(from: hit, dir: past - land, length: hit.distanceTo(past), dur: (1 - pc) * ts, tc: tc);
  final back = tc + fol.dur;
  final sweep = back - (tco + th + tl);
  final squashed = c.pose(_B.squashed), stretched = c.pose(_B.stretched);
  final twisted = stretched.turnedTo(c.lean * _B.sweepTurn);
  return _Plan(
    goAt: tco + th,
    tc: tc,
    backAt: back,
    end: back + tr,
    contact: c.edge + shift,
    hand: _timeline([
      _Piece(tco, (p, _) => coilAt(p)),
      _Piece(th, (_, ms) => hc + c.n * (math.sin(ms * _B.shakeRate) * _B.shake * k)),
      _Piece(tl, (p, _) => hc.lerp(land, _Ease.inOutQuart(p))),
      _Piece(pc * ts, (p, _) => land.lerp(past, _Ease.outCubic(p * pc))),
      _Piece(fol.dur, (p, _) => fol.at(p)),
      _Piece(tr, (p, _) => fol.end.lerp(c.hEnd, _Ease.backOut(p, _B.homeOvershoot))),
    ], c.h0, c.hEnd),
    lag: _timeline([
      _flat(tco, _B.lagCoil),
      _flat(th, _B.lagCoil),
      _Piece(tl, (p, _) => _B.lagCoil * (1 - p) + _B.lagLunge * p),
      _flat(sweep, _B.lagSweep),
      _flat(tr, _B.lagHome),
    ], _B.lagRest, _B.lagRest),
    wave: _timeline([
      _flat(tco + th + tl, 0),
      _flat(sweep, _B.waveSweep * k),
      _Piece(tr, (p, _) => _B.waveHome * k * math.sin(math.pi * p)),
    ], 0, 0),
    coil: _timeline([
      _Piece(tco, (p, _) => _B.coilLoop * k * _Ease.outCubic(p)),
      _flat(th, _B.coilLoop * k),
      _Piece(tl, (p, _) => _B.coilLoop * k * (1 - _Ease.clamp01(p * _B.unwindQuick))),
    ], 0, 0),
    body: _timeline([
      _Piece(tco, (p, _) => c.body0.lerp(squashed, _Ease.outCubic(p))),
      _Piece(th, (_, ms) => squashed.shiftedTo(math.sin(ms * _B.bodyShakeRate) * _B.bodyShake)),
      _Piece(tl, (p, _) => squashed.lerp(stretched, _Ease.outQuart(p))),
      _Piece(sweep, (p, _) => stretched.lerp(twisted, _Ease.outCubic(p))),
      _Piece(tr, (p, _) => twisted.toward(_Ease.spring(p, _B.bodyHome))),
    ], c.body0, TobiBody.rest),
  );
}

/// The smear swing.
_Plan _smear(_Geo c) {
  final k = c.k;
  const ta = _C.draw, tar = _C.arc, tr = _C.back;
  const tc = ta + tar;
  final mid = c.shoulder.lerp(c.edge, 0.5);
  final a = c.edge.distanceTo(mid);
  final b = math.max(_C.bowMin * c.u, math.min(_C.bow * c.d, c.roomAlong(mid, c.n) - _C.edgeRoom * c.u));
  const th0 = math.pi + _C.overhead, th1 = 0.0;
  Vec ellipse(double th) => mid + c.f * (a * math.cos(th)) + c.n * (b * math.sin(th));
  final drawn = ellipse(th0);
  Vec arcAt(double q) => c.onBoard(ellipse(th0 + (th1 - th0) * q), IkkiuchiArmTuning.arcMargin);
  // The swing carries on across the card and curls in toward the called
  // card's side as it brakes.
  final fol = c.follow(from: arcAt(1), dir: -c.n, length: _C.followShare * b, bend: _C.curl * a, dur: _C.follow, tc: tc);
  final back = tc + fol.dur;
  final drawnBack = c.pose(_C.drawn), swung = c.pose(_C.swung);
  return _Plan(
    goAt: ta,
    tc: tc,
    backAt: back,
    end: back + tr,
    hand: _timeline([
      _Piece(ta, (p, _) => c.h0.lerp(drawn, _Ease.inOutSine(p))),
      _Piece(tar, (p, _) => arcAt(_pow(p, _C.arcPower))),
      _Piece(fol.dur, (p, _) => fol.at(p)),
      _Piece(tr, (p, _) => c.returnHand(fol.end, c.hEnd, _Ease.spring(p, _C.home))),
    ], c.h0, c.hEnd),
    lag: _timeline([
      _flat(ta, _C.lagDraw),
      _flat(tar, _C.lagArc),
      _flat(fol.dur, _C.lagFollow),
      _flat(tr, _C.lagHome),
    ], _C.lagRest, _C.lagRest),
    wave: _timeline([
      _flat(ta, 0),
      _flat(tar, _C.waveArc * k),
      _flat(fol.dur, _C.waveFollow * k),
      _Piece(tr, (p, _) => _C.waveHome * k * (1 - p)),
    ], 0, 0),
    smear: _timeline([
      _flat(ta, 0),
      _Piece(tar, (p, _) => _Ease.clamp01((p - _C.smearFrom) * _C.smearRise)),
      _Piece(fol.dur, (p, _) => 1 - p),
    ], 0, 0),
    body: _timeline([
      _Piece(ta, (p, _) => c.body0.lerp(drawnBack, _Ease.inOutSine(p))),
      _Piece(tar, (p, _) => drawnBack.lerp(swung, _Ease.inOutCubic(p))),
      _Piece(fol.dur, (_, _) => swung),
      _Piece(tr, (p, _) => swung.toward(_Ease.spring(p, _C.bodyHome))),
    ], c.body0, TobiBody.rest),
  );
}

/// The row sweep.
_Plan _sweep(_Geo c) {
  final k = c.k;
  const ta = _D.lift, tap = _D.approach, tr = _D.back;
  final row = c.row;
  final inner = Vec(c.target.x - row.x * (c.rowHalf + _D.inside * c.u), c.target.y);
  final lifted = c.h0 + c.f * (-_D.liftBack * k) + Vec(0, -_D.liftUp * k);
  final q = c.onBoard(Vec(inner.x - row.x * math.min(_D.bow * c.d, _D.bowMax * c.u), inner.y - _D.rise * c.u));
  const tc = ta + tap + _D.hitInto;
  // The sweep runs along the row to the board's edge, at any speed.
  final fol = c.follow(
    from: inner,
    dir: row,
    length: (c.rowExitX - inner.x).abs(),
    dur: _D.sweep,
    tc: tc,
    scaled: false,
    curve: (p) => 1 - _pow(1 - p, _D.sweepPower),
  );
  final back = ta + tap + fol.dur;
  final low = c.pose(_D.low), leaning = c.pose(_D.leaning, row.x);
  return _Plan(
    goAt: ta,
    tc: tc,
    backAt: back,
    end: back + tr,
    clean: true,
    contact: inner,
    hand: _timeline([
      _Piece(ta, (p, _) => c.h0.lerp(lifted, _Ease.inOutSine(p))),
      _Piece(tap, (p, _) => bezier(lifted, q, inner, _pow(p, _D.approachPower))),
      _Piece(fol.dur, (p, _) => fol.at(p)),
      _Piece(tr, (p, _) => fol.end.lerp(c.hEnd, _Ease.backOut(p, _D.homeOvershoot))),
    ], c.h0, c.hEnd),
    lag: _timeline([
      _flat(ta, _D.lagLift),
      _flat(tap, _D.lagApproach),
      _flat(fol.dur, _D.lagSweep),
      _flat(tr, _D.lagHome),
    ], _D.lagRest, _D.lagRest),
    bulge: _timeline([
      _flat(ta, 0),
      _Piece(tap, (p, _) => _D.bulge * k * math.sin(math.pi * p)),
    ], 0, 0),
    body: _timeline([
      _Piece(ta, (p, _) => c.body0.lerp(low, _Ease.inOutSine(p))),
      _Piece(tap, (p, _) => low.lerp(leaning, _Ease.outCubic(p))),
      _Piece(fol.dur, (_, _) => leaning),
      _Piece(tr, (p, _) => leaning.toward(_Ease.spring(p, _D.bodyHome))),
    ], c.body0, TobiBody.rest),
  );
}

/// Tobi's arm carrying a card ([IkkiuchiCarryTuning]): a calm reach to the
/// card lying at [from], then on with it in his hand to [to], turning it to
/// lie as [to] does, and home to [endFace]'s pose. No fist touches on the
/// way: the arm is in the air.
class IkkiuchiCarry extends IkkiuchiArmMove {
  IkkiuchiCarry({
    required this.tobi,
    required this.from,
    required this.to,
    required this.cardW,
    required this.side,
    this.endFace = TobiFace.standard,
  }) {
    final rig = tobi.rig, k = tobi.k;
    final h0 = tobi.world(rig.arm(armFace, side).hand, TobiBody.rest);
    final hEnd = tobi.world(rig.arm(endFace, side).hand, TobiBody.rest);
    final pick = from.centre, set = to.centre;
    const fetch = IkkiuchiCarryTuning.fetch, carry = IkkiuchiCarryTuning.carry;
    _hand = _timeline([
      _Piece(fetch, (p, _) => bezier(h0, _bowed(h0, pick), pick, _Ease.inOutCubic(p))),
      _Piece(carry, (p, _) => bezier(pick, _bowed(pick, set), set, _Ease.inOutCubic(p))),
      _Piece(IkkiuchiCarryTuning.back, (p, _) => set.lerp(hEnd, _Ease.inOutCubic(p))),
    ], h0, hEnd);
    fist = IkkiuchiArmTuning.fist * cardW;
    _fistStart = rig.arm(armFace, side).fist * k / fist;
    _fistEnd = rig.arm(endFace, side).fist * k / fist;
  }

  final TobiFrame tobi;

  /// The card where it lies before he takes it, and where he sets it.
  final CardBox from, to;
  final double cardW;
  @override
  final ArmSide side;
  final TobiFace endFace;

  @override
  TobiFace get armFace => TobiFace.standard;

  @override
  late final double fist;
  late final double _fistStart, _fistEnd;
  late final Vec Function(double tau) _hand;

  /// When his hand takes the card off the field, and sets it down.
  double get pickAt => IkkiuchiCarryTuning.fetch;
  double get setAt => pickAt + IkkiuchiCarryTuning.carry;

  @override
  double get end => setAt + IkkiuchiCarryTuning.back;

  /// The way from [a] to [b], bowed out to his arm's side.
  Vec _bowed(Vec a, Vec b) {
    final span = b - a;
    var n = span.unit.perp;
    if (n.x * side.sign < 0) n = -n;
    return a.lerp(b, 0.5) + n * math.min(span.length * IkkiuchiCarryTuning.bow, IkkiuchiCarryTuning.bowMax * cardW);
  }

  /// The card at screen time [t] while it is in his hand, under it, turned
  /// and grown as it goes; [to] once set; null before he takes it.
  CardBox? cardAt(double t) {
    if (t < pickAt) return null;
    if (t >= setAt) return to;
    final p = _Ease.inOutCubic((t - pickAt) / IkkiuchiCarryTuning.carry);
    final turned = from.lerp(to, p);
    return CardBox(handAt(t), turned.hw, turned.hh, turned.angle);
  }

  @override
  double tau(double t) => t;
  @override
  Vec handAt(double tau) => _hand(tau);
  @override
  TobiBody bodyAt(double t) => TobiBody.rest;
  @override
  TobiFace faceAt(double t) => t < end ? armFace : endFace;
  @override
  double lagAt(double tau) => IkkiuchiCarryTuning.lag;
  @override
  double waveAt(double tau) => IkkiuchiCarryTuning.wave * tobi.k * math.sin(math.pi * _Ease.clamp01(tau / end));
  @override
  double bulgeAt(double tau) => 0;
  @override
  double coilAt(double tau) => 0;

  /// The fist grows out of his pose's hand as he reaches, and turns into
  /// [endFace]'s at the very end.
  @override
  double fistScale(double tau) {
    const settle = IkkiuchiArmTuning.fistSettle;
    final grown = _fistStart + (1 - _fistStart) * (tau / settle).clamp(0.0, 1.0);
    final p = ((tau - (end - settle)) / settle).clamp(0.0, 1.0);
    return grown + (_fistEnd - grown) * p;
  }
}
