import '../config/config.dart';
import 'ikkiuchi_cards.dart';
import 'ikkiuchi_geometry.dart';
import 'ikkiuchi_read.dart';
import 'ikkiuchi_rig.dart';
import 'ikkiuchi_strike.dart';

/// One strike of a call on the board: the strike, the board time it starts
/// at, the card it goes for, and whether that card is the one called.
class IkkiuchiRun {
  IkkiuchiRun(this.strike, this.start, this.target, {required this.takes});

  final IkkiuchiStrike strike;
  final double start;
  final int target;
  final bool takes;

  bool _hit = false;
  bool _impact = false;
  double? _lastTau;

  /// Screen ms into the strike at board time [t].
  double at(double t) => t - start;
}

/// Where a strike landed, for its burst and lettering: when, where, and
/// the way out from Tobi's reach there.
class IkkiuchiImpact {
  const IkkiuchiImpact(this.at, this.point, this.out, this.move, this.card, {required this.takes});

  final double at;
  final Vec point, out;
  final IkkiuchiMove move;
  final int card;
  final bool takes;
}

/// Tobi's body and face at a moment of a strike, and the arm he strikes with.
class IkkiuchiTobiPose {
  const IkkiuchiTobiPose(this.face, this.body, this.arm);

  final TobiFace face;
  final TobiBody body;
  final ArmSide arm;
}

/// The 一騎打ち board while Tobi strikes: the cards (`IkkiuchiCards`), his
/// strikes on each call, and the faults his fist makes. It runs in fixed
/// steps of the card sim, so the same calls at the same steps always give
/// the same board.
///
/// By the rules only his fist counts: touching a card on the side without
/// the called card is a fault, and so is touching any card on a からふだ;
/// touching a wrong card on the called card's own side is not.
class IkkiuchiBoard {
  /// [centreLine] is the y of the middle of the band, which no card crosses.
  IkkiuchiBoard({
    required this.tobi,
    required this.size,
    required Iterable<({int id, IkkiuchiSide side, CardBox box})> cards,
    double? centreLine,
  }) : cards = IkkiuchiCards(cards, board: size, centreLine: centreLine);

  final TobiFrame tobi;
  final Vec size;
  final IkkiuchiCards cards;

  /// Board ms of one step.
  static const stepMs = IkkiuchiPhysicsTuning.step * Duration.millisecondsPerSecond;

  int _steps = 0;
  double _carry = 0;

  /// Board ms since it was set out.
  double get now => _steps * stepMs;

  IkkiuchiRead? _read;
  double _readAt = 0;
  final List<IkkiuchiRun> runs = [];
  final List<({bool Function() ready, IkkiuchiRun Function() start})> _pending = [];

  /// Every burst so far, and every card faulted on with when.
  final List<IkkiuchiImpact> impacts = [];
  final Map<int, double> faults = {};

  /// The face he wears after the last call, and until when.
  TobiFace restFace = TobiFace.standard;
  double restUntil = 0;

  /// The call in play, and the board time it came.
  IkkiuchiRead? get read => _read;
  double get readAt => _readAt;

  /// Whether a call is still playing out: a strike waits or runs.
  bool get busy => _pending.isNotEmpty || (runs.isNotEmpty && !runs.last.strike.doneAt(runs.last.at(now)));

  /// The strike drawn now, if any.
  IkkiuchiRun? get active => runs.isEmpty || runs.last.strike.doneAt(runs.last.at(now)) ? null : runs.last;

  /// The cards on the field and where they lie now.
  Map<int, CardBox> get field => {
        for (final c in cards.cards)
          if (c.onBoard && !c.taken) c.id: c.box,
      };

  /// The middle of his shoulders, which his arm distances count from.
  Vec get shoulders {
    final rig = tobi.rig;
    final l = tobi.world(rig.arm(TobiFace.reaching, ArmSide.left).shoulder, TobiBody.rest);
    final r = tobi.world(rig.arm(TobiFace.reaching, ArmSide.right).shoulder, TobiBody.rest);
    return l.lerp(r, 0.5);
  }

  /// Plays [read] from now: his strike (or strikes) as it decides.
  void call(IkkiuchiRead read) {
    _read = read;
    _readAt = now;
    runs.clear();
    _pending.clear();
    if (!read.strikes) return;
    final first = read.wrong ?? read.called;
    final wrongFirst = read.wrong != null;
    final fault = wrongFirst && _isDead(cards.card(read.wrong!));
    final at = now + read.reactionMs;
    _pending.add((
      ready: () => now >= at,
      start: () => _start(
            read.move,
            first,
            at: at,
            reachMs: read.reachMs,
            takes: !wrongFirst,
            endFace: wrongFirst ? (fault ? TobiFace.shocked : TobiFace.reaching) : TobiFace.cheering,
          ),
    ));
    if (!wrongFirst || !read.onField) return;
    // He goes for the called card [IkkiuchiTuning.correction] after he
    // touched the wrong one, his hand setting off from where it is then.
    // The coil winds up at his shoulder, so a correction whips instead.
    final correction = IkkiuchiTuning.correction.inMilliseconds;
    double correctAt() => runs.last.start + runs.last.strike.hitAt + correction;
    _pending.add((
      ready: () => runs.isNotEmpty && now >= correctAt(),
      start: () {
        final lead = runs.last, at = correctAt();
        return _start(read.move == IkkiuchiMove.coilLunge ? IkkiuchiMove.whip : read.move, read.called,
            at: at,
            reachMs: read.correctionReachMs,
            takes: true,
            endFace: fault ? TobiFace.shocked : TobiFace.cheering,
            lead: (run: lead, at: at - lead.start));
      },
    ));
  }

  /// Runs the board on by [ms], in whole steps.
  void advance(double ms) {
    _carry += ms;
    while (_carry >= stepMs) {
      _carry -= stepMs;
      _step();
    }
  }

  /// His face, body and striking arm now; null between strikes.
  IkkiuchiTobiPose? get pose {
    final run = active;
    if (run == null) return null;
    final t = run.at(now);
    return IkkiuchiTobiPose(run.strike.faceAt(t), run.strike.bodyAt(t), run.strike.side);
  }

  /// His face between strikes.
  TobiFace get idleFace => now < restUntil ? restFace : TobiFace.standard;

  /// Which side is without the called card: on a からふだ, neither has it.
  IkkiuchiSide? get _deadSide {
    final read = _read;
    if (read == null || !read.onField) return null;
    return cards.card(read.called).side == IkkiuchiSide.tobi ? IkkiuchiSide.player : IkkiuchiSide.tobi;
  }

  bool _isDead(IkkiuchiCard card) {
    final dead = _deadSide;
    return dead == null || card.side == dead;
  }

  /// From the side without the called card toward the called card's side
  /// (Tobi's half is above the player's); on a からふだ, toward [target]'s.
  Vec _away(IkkiuchiCard target) {
    final dead = _deadSide;
    final toward = dead == null ? target.side : (dead == IkkiuchiSide.tobi ? IkkiuchiSide.player : IkkiuchiSide.tobi);
    return toward == IkkiuchiSide.player ? const Vec(0, 1) : const Vec(0, -1);
  }

  IkkiuchiRun _start(
    IkkiuchiMove move,
    int target, {
    required double at,
    required double reachMs,
    required bool takes,
    required TobiFace endFace,
    ({IkkiuchiRun run, double at})? lead,
  }) {
    final card = cards.card(target);
    final strike = IkkiuchiStrike(
      move,
      IkkiuchiStrikeSetup(
        target: card.box,
        targetId: target,
        tobi: tobi,
        board: size,
        away: _away(card),
        wrong: [
          for (final c in cards.cards)
            if (c != card && c.onBoard && !c.taken && _isDead(c)) c.box,
        ],
        reachMs: reachMs,
        endFace: endFace,
        side: lead?.run.strike.side,
        lead: lead == null ? null : (strike: lead.run.strike, at: lead.at),
      ),
    );
    final run = IkkiuchiRun(strike, at, target, takes: takes);
    runs.add(run);
    return run;
  }

  void _step() {
    final t = now;
    while (_pending.isNotEmpty && _pending.first.ready()) {
      _pending.removeAt(0).start();
    }
    final run = active;
    if (run == null) {
      cards.moveFist(null, null, radius: 0, keep: Vec.zero);
      cards.step();
      _steps++;
      return;
    }
    final strike = run.strike;
    final rt = run.at(t), rt1 = rt + stepMs;
    final target = cards.card(run.target);
    final away = _away(target);
    if (!run._impact && rt1 >= strike.hitAt) {
      run._impact = true;
      impacts.add(IkkiuchiImpact(run.start + strike.hitAt, strike.contact, strike.outward, strike.move, run.target,
          takes: run.takes));
    }
    if (!run._hit && rt1 >= strike.liveFrom) {
      run._hit = true;
      if (run.takes) _launch(target, strike, away);
    }
    if (strike.liveAt(rt1)) {
      cards.moveFist(strike.handAtTime(rt), strike.handAtTime(rt1), radius: strike.touch, keep: away);
    } else {
      cards.moveFist(null, null, radius: 0, keep: away);
    }
    _checkTouches(run, rt1);
    cards.step();
    for (final c in cards.fistTouched) {
      if (_isDead(c)) _fault(c);
    }
    _steps++;
    if (strike.doneAt(run.at(now)) && _pending.isEmpty) {
      restFace = strike.setup.endFace == TobiFace.reaching ? TobiFace.standard : strike.setup.endFace;
      restUntil = now + IkkiuchiArmTuning.restFaceHold;
    }
  }

  /// The live fist's path since the last step, every
  /// [IkkiuchiArmTuning.touchStep] of move time, so a touch between two
  /// steps counts too.
  void _checkTouches(IkkiuchiRun run, double rt1) {
    final strike = run.strike;
    final tau = strike.tau(rt1);
    final from = run._lastTau ?? tau;
    run._lastTau = tau;
    // The card struck at comes first, so a slap on it is the fault noted.
    final dead = [
      for (final c in cards.cards)
        if (c.onBoard && !c.taken && _isDead(c)) c,
    ]..sort((a, b) => (b.id == run.target ? 1 : 0) - (a.id == run.target ? 1 : 0));
    if (dead.isEmpty) return;
    for (var u = from + IkkiuchiArmTuning.touchStep; u <= tau; u += IkkiuchiArmTuning.touchStep) {
      if (!strike.liveAtTau(u, afterHit: u > strike.contactTau)) continue;
      final hand = strike.handAt(u);
      for (final c in dead) {
        if (c.box.gapTo(hand) < strike.touch) _fault(c);
      }
    }
  }

  void _fault(IkkiuchiCard card) => faults.putIfAbsent(card.id, () => now);

  /// The taken card leaves at the fist's speed: along the row off a
  /// sweep, else the way the fist went, bent forward and never toward the
  /// side without the called card.
  void _launch(IkkiuchiCard card, IkkiuchiStrike strike, Vec away) {
    final v = strike.realVelocity(strike.contactTau);
    final speed = (v.length * IkkiuchiPhysicsTuning.hitBoost)
        .clamp(IkkiuchiPhysicsTuning.hitMin, IkkiuchiPhysicsTuning.hitMax)
        .toDouble();
    if (strike.clean) {
      final spin = (card.id.isOdd ? 1 : -1) * IkkiuchiPhysicsTuning.sweepSpin;
      cards.launch(card, strike.rowWay * speed, spin);
      return;
    }
    final dir = notAgainst(v.unit + strike.forward * IkkiuchiPhysicsTuning.hitForward, away).dir;
    final velocity = dir * speed;
    final box = card.box;
    final r = strike.contact - box.centre;
    final inertia = ((2 * box.hw) * (2 * box.hw) + (2 * box.hh) * (2 * box.hh)) / 12;
    final turn = strike.forward.cross(dir);
    final spin = r.cross(velocity) / inertia * IkkiuchiPhysicsTuning.hitSpin +
        IkkiuchiPhysicsTuning.hitSpinKick * (turn == 0 ? 1 : turn.sign);
    cards.launch(card, velocity, spin);
  }
}
