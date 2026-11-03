import 'dart:math' as math;

import 'package:forge2d/forge2d.dart' as box2d;

import '../config/config.dart';
import 'ikkiuchi_geometry.dart';

/// The two sides of the 一騎打ち field: Tobi's, across the band at the top,
/// and the player's.
enum IkkiuchiSide { tobi, player }

/// One card on the board, as the sim has it.
class IkkiuchiCard {
  IkkiuchiCard._(this.id, this.side, this.home, this._body);

  final int id;
  final IkkiuchiSide side;

  /// Where the card lay when the board was set out.
  final CardBox home;

  box2d.Body? _body;
  CardBox? _last;

  /// Whether Tobi took it: it flies off and fades.
  bool taken = false;

  /// How much of it shows: 1, down to 0 as a taken card fades.
  double shown = 1;

  /// Whether it is on the board: not faded or flown off.
  bool get onBoard => shown > 0;

  /// Whether it is lying still (asleep in the sim).
  bool get still => _body == null || !_body!.isAwake;

  /// Where it lies now.
  CardBox get box {
    final b = _body;
    if (b == null) return _last ?? home;
    return home.movedTo(IkkiuchiCards._dp(b.position), b.angle);
  }

  /// Its speed and spin now, dp/s and rad/s.
  Vec get velocity => _body == null ? Vec.zero : IkkiuchiCards._dp(_body!.linearVelocity);
  double get spin => _body?.angularVelocity ?? 0;

  /// Whether it has moved from [home] by more than [dp] or [radians].
  bool movedFrom(CardBox from, {required double dp, required double radians}) {
    final now = box;
    return !onBoard || now.centre.distanceTo(from.centre) > dp || (now.angle - from.angle).abs() > radians;
  }
}

/// The cards on the board as rigid bodies in a Forge2D world: no gravity,
/// the tatami's friction as damping, resting cards asleep. Tobi's fist is a
/// kinematic body that exists only while it is live; the cards it pushes
/// are held to [IkkiuchiPhysicsTuning.pushMax] and never go toward the side
/// without the called card. With a [centreLine] (the y of the middle of the
/// band), no card crosses into the other half: it stops there, under the
/// band. Fixed steps of [IkkiuchiPhysicsTuning.step], so the same steps
/// always give the same board.
class IkkiuchiCards {
  IkkiuchiCards(Iterable<({int id, IkkiuchiSide side, CardBox box})> cards, {required this.board, double? centreLine})
      : _world = box2d.World(box2d.Vector2.zero()) {
    _world.setContactListener(_listener);
    if (centreLine != null) {
      const off = IkkiuchiPhysicsTuning.offBoard;
      _world.createBody(box2d.BodyDef()).createFixture(box2d.FixtureDef(
            box2d.EdgeShape()..set(_m(Vec(-off, centreLine)), _m(Vec(board.x + off, centreLine))),
            restitution: IkkiuchiPhysicsTuning.restitution,
            filter: _filter(_lineBit, _cardBit | _flyingBit),
          ));
    }
    for (final c in cards) {
      final body = _world.createBody(box2d.BodyDef(
        type: box2d.BodyType.dynamic,
        position: _m(c.box.centre),
        angle: c.box.angle,
        linearDamping: IkkiuchiPhysicsTuning.damping,
        angularDamping: IkkiuchiPhysicsTuning.spinDamping,
        isAwake: false,
      ));
      final shape = box2d.PolygonShape()
        ..setAsBoxXY(_metres(c.box.hw) - box2d.polygonRadius, _metres(c.box.hh) - box2d.polygonRadius);
      body.createFixture(box2d.FixtureDef(
        shape,
        density: IkkiuchiPhysicsTuning.density,
        friction: IkkiuchiPhysicsTuning.friction,
        restitution: IkkiuchiPhysicsTuning.restitution,
        filter: _filter(_cardBit, _cardBit | _flyingBit | _fistBit | _lineBit),
      ));
      final card = IkkiuchiCard._(c.id, c.side, c.box, body);
      body.userData = card;
      this.cards.add(card);
    }
  }

  /// The board's size; a card well past its edge is gone.
  final Vec board;
  final List<IkkiuchiCard> cards = [];
  final box2d.World _world;
  late final _listener = _FistListener(this);
  box2d.Body? _fist;
  Vec _keep = Vec.zero;
  final Set<IkkiuchiCard> _pushed = {};

  /// Every card the fist touched in the last step.
  final Set<IkkiuchiCard> fistTouched = {};

  static const _cardBit = 0x0001, _flyingBit = 0x0002, _fistBit = 0x0004, _lineBit = 0x0008;

  static box2d.Filter _filter(int category, int mask) => box2d.Filter()
    ..categoryBits = category
    ..maskBits = mask;

  static double _metres(double dp) => dp / IkkiuchiPhysicsTuning.dpPerMetre;
  static box2d.Vector2 _m(Vec p) => box2d.Vector2(_metres(p.x), _metres(p.y));
  static Vec _dp(box2d.Vector2 v) =>
      Vec(v.x * IkkiuchiPhysicsTuning.dpPerMetre, v.y * IkkiuchiPhysicsTuning.dpPerMetre);

  IkkiuchiCard card(int id) => cards.firstWhere((c) => c.id == id);

  /// Whether every card on the board lies still.
  bool get settled => cards.every((c) => c.still || !c.onBoard);

  /// Sends [card] off as taken at [velocity] (dp/s) and [spin] (rad/s): it
  /// flies freely, knocking the cards it meets, and the fist passes it by.
  void launch(IkkiuchiCard card, Vec velocity, double spin) {
    final body = card._body;
    if (body == null) return;
    card.taken = true;
    body
      ..isBullet = true
      ..linearDamping = IkkiuchiPhysicsTuning.launchDamping
      ..linearVelocity = _m(velocity)
      ..angularVelocity = spin.clamp(-IkkiuchiPhysicsTuning.maxSpin, IkkiuchiPhysicsTuning.maxSpin);
    body.fixtures.first.filterData = _filter(_flyingBit, _cardBit | _flyingBit | _lineBit);
  }

  /// The fist over the next step: from [from] to [to] (dp), a circle of
  /// [radius]; the cards it pushes never go against [keep]. Null takes it
  /// off the board.
  void moveFist(Vec? from, Vec? to, {required double radius, required Vec keep}) {
    if (from == null || to == null) {
      final fist = _fist;
      if (fist != null) _world.destroyBody(fist);
      _fist = null;
      return;
    }
    _keep = keep;
    var fist = _fist;
    if (fist == null) {
      fist = _fist = _world.createBody(box2d.BodyDef(type: box2d.BodyType.kinematic, position: _m(from)));
      fist.createFixture(box2d.FixtureDef(
        box2d.CircleShape(radius: _metres(radius)),
        restitution: IkkiuchiPhysicsTuning.fistRestitution,
        filter: _filter(_fistBit, _cardBit),
      ));
    }
    fist.linearVelocity = (_m(to)..sub(fist.position))..scale(1 / IkkiuchiPhysicsTuning.step);
  }

  bool get fistOn => _fist != null;

  /// One step of the sim.
  void step() {
    _pushed.clear();
    _world.stepDt(IkkiuchiPhysicsTuning.step);
    fistTouched
      ..clear()
      ..addAll(_pushed);
    const cap = IkkiuchiPhysicsTuning.pushMax * (1 + IkkiuchiPhysicsTuning.fistRestitution);
    for (final card in _pushed) {
      final body = card._body;
      if (body == null || card.taken) continue;
      var v = _dp(body.linearVelocity);
      final against = v.dot(_keep);
      if (against < 0) v = v - _keep * against;
      if (v.length > cap) v = v * (cap / v.length);
      body.linearVelocity = _m(v);
    }
    for (final card in cards) {
      final body = card._body;
      if (body == null || !body.isAwake) continue;
      final w = body.angularVelocity;
      if (w.abs() > IkkiuchiPhysicsTuning.maxSpin) body.angularVelocity = w.sign * IkkiuchiPhysicsTuning.maxSpin;
      final at = card.box.centre;
      const off = IkkiuchiPhysicsTuning.offBoard;
      final gone = at.x < -off || at.y < -off || at.x > board.x + off || at.y > board.y + off;
      final landed = card.taken && _dp(body.linearVelocity).length < IkkiuchiPhysicsTuning.landSpeed;
      if (gone || landed) _remove(card, shown: gone ? 0 : card.shown);
    }
    for (final card in cards) {
      if (card._body != null || !card.taken || card.shown <= 0) continue;
      const fade = IkkiuchiPhysicsTuning.step * Duration.millisecondsPerSecond / IkkiuchiPhysicsTuning.fadeMs;
      card.shown = math.max(0, card.shown - fade);
    }
  }

  void _remove(IkkiuchiCard card, {required double shown}) {
    card._last = card.box;
    _world.destroyBody(card._body!);
    card._body = null;
    card.shown = shown;
  }
}

/// Notes every card Tobi's fist touches.
class _FistListener extends box2d.ContactListener {
  _FistListener(this.cards);

  final IkkiuchiCards cards;

  @override
  void beginContact(box2d.Contact contact) => _note(contact);

  @override
  void preSolve(box2d.Contact contact, box2d.Manifold oldManifold) => _note(contact);

  void _note(box2d.Contact contact) {
    final fist = cards._fist;
    if (fist == null) return;
    final a = contact.bodyA, b = contact.bodyB;
    final other = a == fist ? b : (b == fist ? a : null);
    if (other?.userData case final IkkiuchiCard card) cards._pushed.add(card);
  }
}
