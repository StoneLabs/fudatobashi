import '../config/config.dart';
import 'field_parts.dart';
import 'ikkiuchi_cards.dart';
import 'ikkiuchi_geometry.dart';
import 'ikkiuchi_read.dart';
import 'ikkiuchi_rig.dart';
import 'ikkiuchi_side.dart';
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
/// on each call, the player's finger, and the faults (お手つき) each makes.
/// It runs in fixed steps of the card sim, so the same calls at the same
/// steps always give the same board.
///
/// One rule ([faultsOn]) says what is a fault, for his fist and the finger
/// alike, as the rules have it (競技規程細則 第二十三条): touching a card on
/// the side without the called card is a fault, and so is touching any card
/// on a からふだ; touching a wrong card on the called card's own side is
/// not. Only the fist's or the finger's own touch counts, never a card
/// knocked into another (第二十三条 二), and a touch after the take counts
/// too, while the read goes on (第二十三条 三).
///
/// The player takes the called card when their finger touches it, or when
/// it has wholly left the field ([fieldArea]): no part of it lies inside it
/// any more. Being knocked by another card, or moving while still partly
/// inside the field, is no take. Tobi takes it when his fist reaches it.
/// Whoever is first takes it ([taker]); takes within
/// [IkkiuchiPlayTuning.sameTime] of each other are at the same time, and
/// the card goes to the side it lies on (競技規程 第十一条). His fist sends
/// it flying only when he took it, and once the player took it he starts
/// no more strikes on the call.
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

  /// Every burst so far, and every card his fist faulted on since the last
  /// read began, with when.
  final List<IkkiuchiImpact> impacts = [];
  final Map<int, double> faults = {};

  /// Every card the player's finger faulted on since the last read began,
  /// with when.
  final Map<int, double> playerFaults = {};

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

  /// When Tobi's fist reached the called card on a strike that goes for
  /// it; null before.
  double? get tobiHit => _tobiHit;
  double? _tobiHit;

  /// The card read now and whether it lies on the field, else it is a
  /// からふだ; null while nothing is read.
  ({int id, bool onField})? _reading;

  /// Reads [id] for the player alone, Tobi's arm still: the takes of it
  /// and both players' faults start afresh. A からふだ ([onField] false) has
  /// nothing to take. Null reads nothing, and Tobi starts no strike still
  /// to come.
  void callCard(int? id, {bool onField = true}) {
    _reading = id == null ? null : (id: id, onField: onField);
    _pending.clear();
    _called = onField ? id : null;
    _take = null;
    _tobiHit = null;
    playerFaults.clear();
    faults.clear();
  }

  /// Who took the called card, by when the player took it ([player]) and
  /// when Tobi's fist reached it ([tobi]): the first, or the owner of
  /// [side], the side it lay on, when they were within
  /// [IkkiuchiPlayTuning.sameTime] of each other. Null while neither took
  /// it.
  static IkkiuchiSide? takerOf({double? player, double? tobi, required IkkiuchiSide side}) {
    if (tobi == null) return player == null ? null : IkkiuchiSide.player;
    if (player == null) return IkkiuchiSide.opponent;
    final gap = player - tobi;
    if (gap.abs() <= _sameTime) return side;
    return gap < 0 ? IkkiuchiSide.player : IkkiuchiSide.opponent;
  }

  static final _sameTime = IkkiuchiPlayTuning.sameTime.inMicroseconds / Duration.microsecondsPerMillisecond;

  /// Whether both took the called card within
  /// [IkkiuchiPlayTuning.sameTime] of each other.
  bool get tied {
    final player = _take?.at, tobi = _tobiHit;
    return player != null && tobi != null && (player - tobi).abs() <= _sameTime;
  }

  /// Who took the called card, once the other can no longer take it at the
  /// same time; null till then, and on a からふだ.
  IkkiuchiSide? get taker {
    final id = _called, player = _take?.at, tobi = _tobiHit;
    if (id == null) return null;
    final first = player == null ? tobi : (tobi == null ? player : (player < tobi ? player : tobi));
    if (first == null || now < first + _sameTime) return null;
    return takerOf(player: player, tobi: tobi, side: cards.card(id).side);
  }

  /// The face he holds between strikes until let go; null for none.
  TobiFace? heldFace;

  /// His arm carrying a card now or last, and the board time it started.
  IkkiuchiCarry? get carry => _carryMove;
  IkkiuchiCarry? _carryMove;
  double _carryStart = 0;
  int? _carried;

  /// Carries [card] with [move] from now, or from board time [since]: the
  /// card leaves the board as his hand takes it.
  void carryCard(IkkiuchiCarry move, int card, {double? since}) {
    _carryMove = move;
    _carryStart = since ?? now;
    _carried = card;
  }

  /// The board time the carry started at.
  double get carryStart => _carryStart;

  /// Calls off the carry: his arm carries nothing, and the card it had is
  /// the caller's to put back.
  void dropCarry() {
    _carryMove = null;
    _carried = null;
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

  /// Plays [read] from now: his strike (or strikes) as it decides, his
  /// times counting from [after] ms on. The takes of the called card start
  /// afresh.
  void call(IkkiuchiRead read, {double after = 0}) {
    _read = read;
    _readAt = now;
    callCard(read.called, onField: read.onField);
    runs.clear();
    _pending.clear();
    if (!read.strikes) return;
    final first = read.wrong ?? read.called;
    final wrongFirst = read.wrong != null;
    final fault = wrongFirst && _isDead(cards.card(read.wrong!));
    final at = now + after + read.reactionMs;
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
    final reading = _reading;
    if (reading == null || !reading.onField) return null;
    return cards.card(reading.id).side == IkkiuchiSide.opponent ? IkkiuchiSide.player : IkkiuchiSide.opponent;
  }

  bool _isDead(IkkiuchiCard card) {
    final dead = _deadSide;
    return dead == null || card.side == dead;
  }

  /// Whether a touch on [card] now is a fault, by Tobi's fist or the
  /// player's finger: a card is read, and [card] lies on the side without
  /// it, or anywhere on a からふだ, and still on the field (競技規程細則
  /// 第二十三条 一). Nothing faults while nothing is read, as during a 送り札
  /// or 並べ替え.
  bool faultsOn(IkkiuchiCard card) => _reading != null && !card.taken && !card.held && _isDead(card) && _inField(card);

  /// Whether [card] is on the board with some of it inside the field, or
  /// just on the board where there is no field.
  bool _inField(IkkiuchiCard card) {
    final area = fieldArea;
    return card.onBoard && (area == null || card.box.overlapsArea(area.x, area.y, area.right, area.bottom));
  }

  /// From the side without the called card toward the called card's side
  /// (Tobi's half is above the player's); on a からふだ, toward [target]'s.
  Vec _away(IkkiuchiCard target) {
    final dead = _deadSide;
    final toward = dead == null ? target.side : (dead == IkkiuchiSide.opponent ? IkkiuchiSide.player : IkkiuchiSide.opponent);
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
      _noteTouches();
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
      if (run.takes) _tobiHit ??= run.start + strike.hitAt;
    }
    // The hit stop outlasts [IkkiuchiPlayTuning.sameTime], so who took the
    // card is known as it would fly.
    if (!run._hit && rt1 >= strike.liveFrom) {
      run._hit = true;
      final hit = _tobiHit;
      if (run.takes && hit != null && takerOf(player: _take?.at, tobi: hit, side: target.side) == IkkiuchiSide.opponent) {
        _launch(target, strike, away);
      }
    }
    if (strike.liveAt(rt1)) {
      cards.moveFist(strike.handAtTime(rt), strike.handAtTime(rt1), radius: strike.touch, keep: away);
    } else {
      cards.moveFist(null, null, radius: 0, keep: away);
    }
    _checkTouches(run, rt1);
    cards.step();
    _noteTouches();
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
        if (faultsOn(c)) c,
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

  /// Notes a fault on each card the fist or the finger touched in the last
  /// step: his, or the player's.
  void _noteTouches() {
    for (final c in cards.fistTouched) {
      if (faultsOn(c)) _fault(c);
    }
    for (final c in cards.fingerTouched) {
      if (faultsOn(c)) playerFaults.putIfAbsent(c.id, () => now);
    }
  }

  /// The carried card leaves the board as his hand takes it; once the
  /// carry is over it is let be, as where he laid it.
  void _holdCarried() {
    final move = _carryMove, id = _carried;
    if (move == null || id == null || carryTime < move.pickAt || !carrying) return;
    final card = cards.card(id);
    if (!card.held) cards.hold(card);
  }

  /// The player takes the called card once their finger touches it, or
  /// once none of it lies inside the field; never one Tobi took. Tobi
  /// starts no more strikes then.
  void _checkTake() {
    final id = _called;
    if (id == null || _take != null) return;
    final card = cards.card(id);
    if (card.taken || card.held) return;
    if (cards.fingerTouched.contains(card)) {
      _take = IkkiuchiTake(id, now, IkkiuchiTakeWay.touched);
    } else if (fieldArea != null && !_inField(card)) {
      _take = IkkiuchiTake(id, now, IkkiuchiTakeWay.leftField);
    }
    if (_take != null) _pending.clear();
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
