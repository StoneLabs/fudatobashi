import '../config/config.dart';
import 'field_parts.dart';
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

/// How the player took the called card: their finger touched it, or it
/// left the field.
enum IkkiuchiTakeWay { touched, leftField }

/// The player's take of [card] at board time [at].
class IkkiuchiTake {
  const IkkiuchiTake(this.card, this.at, this.way);

  final int card;
  final double at;
  final IkkiuchiTakeWay way;
}

/// Tobi's body and face at a moment of a strike or a carry, and the arm
/// that moves.
class IkkiuchiTobiPose {
  const IkkiuchiTobiPose(this.face, this.body, this.arm);

  final TobiFace face;
  final TobiBody body;
  final ArmSide arm;
}

/// The 一騎打ち board in play: the cards (`IkkiuchiCards`), Tobi's strikes
/// on each call and the faults his fist makes, and the player's finger. It
/// runs in fixed steps of the card sim, so the same calls at the same steps
/// always give the same board.
///
/// By the rules only his fist counts: touching a card on the side without
/// the called card is a fault, and so is touching any card on a からふだ;
/// touching a wrong card on the called card's own side is not.
///
/// The player takes the called card when their finger touches it, or when
/// it has wholly left the field ([fieldArea]): no part of it lies inside it
/// any more. Being knocked by another card, or moving while still partly
/// inside the field, is no take.
///
/// Between the reads his arm may carry a card ([carryCard]), as when he
/// sends one to the player.
class IkkiuchiBoard {
  /// [cardW] is a card's width, dp; the board's time starts at [startStep]
  /// steps, as a board set out afresh goes on from the last one's.
  IkkiuchiBoard({
    required this.tobi,
    required this.size,
    required Iterable<({int id, IkkiuchiSide side, CardBox box})> cards,
    required double cardW,
    this.fieldArea,
    int startStep = 0,
  })  : cards = IkkiuchiCards(cards, board: size, cardW: cardW),
        _steps = startStep;

  final TobiFrame tobi;
  final Vec size;
  final IkkiuchiCards cards;

  /// The field: both sides' territories, from the far edge of Tobi's back
  /// row to the far edge of the player's, dp.
  final FieldRect? fieldArea;

  /// Board ms of one step.
  static const stepMs = IkkiuchiPhysicsTuning.step * Duration.millisecondsPerSecond;

  int _steps;
  double _carry = 0;

  /// Board ms since it was set out, and its whole steps.
  double get now => _steps * stepMs;
  int get steps => _steps;

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
          if (c.onBoard && !c.taken && !c.held) c.id: c.box,
      };

  /// The card the player is to take now, and their take of it once made.
  int? get called => _called;
  int? _called;
  IkkiuchiTake? get take => _take;
  IkkiuchiTake? _take;

  /// Calls [id] for the player alone, Tobi's arm still: the player's take
  /// of it starts afresh. Null calls nothing.
  void callCard(int? id) {
    _called = id;
    _take = null;
  }

  /// The face he holds between strikes until let go; null for none.
  TobiFace? heldFace;

  /// His arm carrying a card now or last, and the board time it started.
  IkkiuchiCarry? get carry => _carryMove;
  IkkiuchiCarry? _carryMove;
  double _carryStart = 0;
  int? _carried;

  /// Carries [card] with [move] from now: the card leaves the board as his
  /// hand takes it.
  void carryCard(IkkiuchiCarry move, int card) {
    _carryMove = move;
    _carryStart = now;
    _carried = card;
  }

  /// Ms into the carry now.
  double get carryTime => now - _carryStart;

  /// Whether his arm is carrying a card now.
  bool get carrying => _carryMove != null && !_carryMove!.doneAt(carryTime);

  /// The card in his hand now and where it lies, or where he set it once
  /// the carry is over; null before his hand takes it.
  ({int id, CardBox box})? get carried {
    final move = _carryMove, id = _carried;
    if (move == null || id == null) return null;
    final box = move.cardAt(carryTime);
    return box == null ? null : (id: id, box: box);
  }

  /// The middle of his shoulders, which his arm distances count from.
  Vec get shoulders {
    final rig = tobi.rig;
    final l = tobi.world(rig.arm(TobiFace.reaching, ArmSide.left).shoulder, TobiBody.rest);
    final r = tobi.world(rig.arm(TobiFace.reaching, ArmSide.right).shoulder, TobiBody.rest);
    return l.lerp(r, 0.5);
  }

  /// Plays [read] from now: his strike (or strikes) as it decides. The
  /// player's take of the called card starts afresh.
  void call(IkkiuchiRead read) {
    _read = read;
    _readAt = now;
    callCard(read.onField ? read.called : null);
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

  /// Where the player's finger is (dp) while it is down, and where its
  /// pusher is in the sim; whether it has lifted.
  Vec? _fingerTo, _fingerAt;
  bool _lifted = false;

  /// The player's finger is down at [at] (dp). From the next [advance] it
  /// pushes the cards there; each new place it is moved to is reached over
  /// the steps of the next advance, evenly, so it strikes them at the
  /// finger's own speed.
  void touch(Vec at) {
    if (_lifted) _takeFingerOff();
    _fingerTo = at;
  }

  /// The finger lifts: it leaves the board once at the last place it touched.
  void lift() => _lifted = _fingerTo != null;

  void _takeFingerOff() {
    cards.moveFinger(null, null);
    _fingerTo = _fingerAt = null;
    _lifted = false;
  }

  /// Runs the board on by [ms], in whole steps.
  void advance(double ms) {
    _carry += ms;
    var steps = 0;
    for (var left = _carry; left >= stepMs; left -= stepMs) {
      steps++;
    }
    final to = _fingerTo, from = _fingerAt ?? to;
    for (var i = 1; i <= steps; i++) {
      _carry -= stepMs;
      if (from != null && to != null) cards.moveFinger(from.lerp(to, (i - 1) / steps), from.lerp(to, i / steps));
      _step();
    }
    if (steps == 0 || to == null) return;
    _fingerAt = to;
    if (_lifted) _takeFingerOff();
  }

  /// His face, body and moving arm now; null between moves.
  IkkiuchiTobiPose? get pose {
    if (carrying) {
      final move = _carryMove!, t = carryTime;
      return IkkiuchiTobiPose(move.faceAt(t), move.bodyAt(t), move.side);
    }
    final run = active;
    if (run == null) return null;
    final t = run.at(now);
    return IkkiuchiTobiPose(run.strike.faceAt(t), run.strike.bodyAt(t), run.strike.side);
  }

  /// His face between strikes.
  TobiFace get idleFace => heldFace ?? (now < restUntil ? restFace : TobiFace.standard);

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
        cardW: cards.cardW,
        away: _away(card),
        wrong: [
          for (final c in cards.cards)
            if (c != card && c.onBoard && !c.taken && _isDead(c)) c.box,
        ],
        targetWrong: _isDead(card),
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
    _holdCarried();
    final run = active;
    if (run == null) {
      cards.moveFist(null, null, radius: 0, keep: Vec.zero);
      cards.step();
      _checkTake();
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
    _checkTake();
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

  /// The carried card leaves the board as his hand takes it.
  void _holdCarried() {
    final move = _carryMove, id = _carried;
    if (move == null || id == null || carryTime < move.pickAt) return;
    final card = cards.card(id);
    if (!card.held) cards.hold(card);
  }

  /// The player takes the called card once their finger touches it, or
  /// once none of it lies inside the field; never one Tobi took.
  void _checkTake() {
    final id = _called, area = fieldArea;
    if (id == null || _take != null) return;
    final card = cards.card(id);
    if (card.taken || card.held) return;
    if (cards.fingerTouched.contains(card)) {
      _take = IkkiuchiTake(id, now, IkkiuchiTakeWay.touched);
    } else if (area != null && (!card.onBoard || !card.box.overlapsArea(area.x, area.y, area.right, area.bottom))) {
      _take = IkkiuchiTake(id, now, IkkiuchiTakeWay.leftField);
    }
  }

  /// The taken card leaves at the fist's speed: along the row off a
  /// sweep, else the way the fist went, bent forward and never toward the
  /// side without the called card.
  void _launch(IkkiuchiCard card, IkkiuchiStrike strike, Vec away) {
    final v = strike.realVelocity(strike.contactTau);
    final u = cards.cardW;
    final speed = (v.length * IkkiuchiPhysicsTuning.hitBoost)
        .clamp(IkkiuchiPhysicsTuning.hitMin * u, IkkiuchiPhysicsTuning.hitMax * u)
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
