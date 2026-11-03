import 'dart:math' as math;

import 'package:forge2d/forge2d.dart' as box2d;

import '../config/config.dart';
import 'ikkiuchi_geometry.dart';

/// The two sides of the 一騎打ち field: Tobi's, across the band at the top,
/// and the player's.
enum IkkiuchiSide { tobi, player }

/// One card on the board, as the sim has it.
class IkkiuchiCard {
  IkkiuchiCard._(this.id, this.side, this.home, this._sim);

  final int id;
  final IkkiuchiSide side;

  /// Where the card lay when the board was set out.
  final CardBox home;

  box2d.Body? _body;
  CardBox? _last;
  final IkkiuchiCards _sim;

  /// Whether the sim has woken it since it last lay at home.
  bool _stirred = false;

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
    return home.movedTo(_sim._dp(b.position), b.angle);
  }

  /// Its speed and spin now, dp/s and rad/s.
  Vec get velocity => _body == null ? Vec.zero : _sim._dp(_body!.linearVelocity);
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
/// without the called card. The player's finger is another, while it is
/// down. A knocked card slides freely across the band into the other side.
/// Fixed steps of [IkkiuchiPhysicsTuning.step], so the same steps always
/// give the same board.
///
/// The world is measured in cards: a card [cardW] dp wide is
/// [IkkiuchiPhysicsTuning.cardMetres] across in it, so the cards move alike
/// at any size.
class IkkiuchiCards {
  IkkiuchiCards(Iterable<({int id, IkkiuchiSide side, CardBox box})> cards,
      {required this.board, required this.cardW})
      : _world = box2d.World(box2d.Vector2.zero()) {
    _world.setContactListener(_listener);
    for (final c in cards) {
      final card = IkkiuchiCard._(c.id, c.side, c.box, this);
      card._body = _bodyAtHome(card);
      this.cards.add(card);
    }
  }

  /// [card]'s body, lying asleep at its home.
  box2d.Body _bodyAtHome(IkkiuchiCard card) {
    final home = card.home;
    final body = _world.createBody(box2d.BodyDef(
      type: box2d.BodyType.dynamic,
      position: _m(home.centre),
      angle: home.angle,
      linearDamping: IkkiuchiPhysicsTuning.damping,
      angularDamping: IkkiuchiPhysicsTuning.spinDamping,
      isAwake: false,
    ));
    final shape = box2d.PolygonShape()
      ..setAsBoxXY(_metres(home.hw) - box2d.polygonRadius, _metres(home.hh) - box2d.polygonRadius);
    body.createFixture(box2d.FixtureDef(
      shape,
      density: IkkiuchiPhysicsTuning.density,
      friction: IkkiuchiPhysicsTuning.friction,
      restitution: IkkiuchiPhysicsTuning.restitution,
      filter: _filter(_cardBit, _cardBit | _flyingBit | _fistBit | _fingerBit),
    ));
    body.userData = card;
    return body;
  }

  /// The board's size; a card well past its edge is gone.
  final Vec board;

  /// A card's width on the board, dp.
  final double cardW;
  final List<IkkiuchiCard> cards = [];
  final box2d.World _world;
  late final _listener = _FistListener(this);
  box2d.Body? _fist, _finger;
  Vec _keep = Vec.zero;
  final Set<IkkiuchiCard> _pushed = {};

  /// Every card the fist touched in the last step.
  final Set<IkkiuchiCard> fistTouched = {};

  static const _cardBit = 0x0001, _flyingBit = 0x0002, _fistBit = 0x0004, _fingerBit = 0x0008;

  static box2d.Filter _filter(int category, int mask) => box2d.Filter()
    ..categoryBits = category
    ..maskBits = mask;

  late final double _dpPerMetre = cardW / IkkiuchiPhysicsTuning.cardMetres;
  double _metres(double dp) => dp / _dpPerMetre;
  box2d.Vector2 _m(Vec p) => box2d.Vector2(_metres(p.x), _metres(p.y));
  Vec _dp(box2d.Vector2 v) => Vec(v.x * _dpPerMetre, v.y * _dpPerMetre);

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
    body.fixtures.first.filterData = _filter(_flyingBit, _cardBit | _flyingBit);
  }

  /// The fist over the next step: from [from] to [to] (dp), a circle of
  /// [radius]; the cards it pushes never go against [keep]. Null takes it
  /// off the board.
  void moveFist(Vec? from, Vec? to, {required double radius, required Vec keep}) {
    _keep = keep;
    _fist = _push(_fist, from, to,
        radius: radius, category: _fistBit, restitution: IkkiuchiPhysicsTuning.fistRestitution);
  }

  bool get fistOn => _fist != null;

  /// The player's finger over the next step: from [from] to [to] (dp), a
  /// circle of [IkkiuchiPhysicsTuning.finger]. Null takes it off the board.
  void moveFinger(Vec? from, Vec? to) =>
      _finger = _push(_finger, from, to, radius: IkkiuchiPhysicsTuning.finger * cardW, category: _fingerBit);

  bool get fingerOn => _finger != null;

  /// [pusher] over the next step: a kinematic circle of [radius] from [from]
  /// to [to] (dp), set down at [from] if it is not on the board yet. It
  /// moves at the speed of that way, so it strikes the cards as hard as it
  /// moves, and the sim sweeps it along the whole way (continuous
  /// collision), so a fast stroke never passes through a card. Null [from]
  /// or [to] takes it off the board.
  box2d.Body? _push(box2d.Body? pusher, Vec? from, Vec? to,
      {required double radius, required int category, double? restitution}) {
    if (from == null || to == null) {
      if (pusher != null) _world.destroyBody(pusher);
      return null;
    }
    final body = pusher ?? _world.createBody(box2d.BodyDef(type: box2d.BodyType.kinematic, position: _m(from)));
    if (pusher == null) {
      final fixture = box2d.FixtureDef(box2d.CircleShape(radius: _metres(radius)), filter: _filter(category, _cardBit));
      if (restitution != null) fixture.restitution = restitution;
      body.createFixture(fixture);
    }
    body.linearVelocity = (_m(to)..sub(body.position))..scale(1 / IkkiuchiPhysicsTuning.step);
    return body;
  }

  /// The fastest a card the fist pushes may go, dp/s.
  double get pushCap => IkkiuchiPhysicsTuning.pushMax * cardW * (1 + IkkiuchiPhysicsTuning.fistRestitution);

  /// One step of the sim.
  void step() {
    _pushed.clear();
    _world.stepDt(IkkiuchiPhysicsTuning.step);
    fistTouched
      ..clear()
      ..addAll(_pushed);
    final cap = pushCap;
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
      card._stirred = true;
      final w = body.angularVelocity;
      if (w.abs() > IkkiuchiPhysicsTuning.maxSpin) body.angularVelocity = w.sign * IkkiuchiPhysicsTuning.maxSpin;
      final at = card.box.centre;
      final off = IkkiuchiPhysicsTuning.offBoard * cardW;
      final gone = at.x < -off || at.y < -off || at.x > board.x + off || at.y > board.y + off;
      final landed = card.taken && _dp(body.linearVelocity).length < IkkiuchiPhysicsTuning.landSpeed * cardW;
      if (gone || landed) _remove(card, shown: gone ? 0 : card.shown);
    }
    for (final card in cards) {
      if (card._body != null || !card.taken || card.shown <= 0) continue;
      const fade = IkkiuchiPhysicsTuning.step * Duration.millisecondsPerSecond / IkkiuchiPhysicsTuning.fadeMs;
      card.shown = math.max(0, card.shown - fade);
    }
    if (_gliding.isNotEmpty) _glide();
  }

  /// The cards gliding home, each from where it lay as it set off, and the
  /// glide's length, its time so far (ms) and its ease.
  final Map<IkkiuchiCard, CardBox> _gliding = {};
  double _glideMs = 0, _glideAt = 0;
  double Function(double t) _ease = _linear;

  static double _linear(double t) => t;

  /// Sends every card the sim has stirred since it lay at home back there,
  /// gliding over [ms] eased by [ease] (from 0 to 1 as its time goes from 0
  /// to 1), the shortest way round. On the way it is out of the sim; once
  /// home it lies there still. A card gone off the board glides back from
  /// where it left; a taken card stays taken.
  void glideHome({required double ms, required double Function(double t) ease}) {
    for (final card in cards) {
      if (card.taken || !card._stirred) continue;
      if (card._body != null) _remove(card, shown: 1);
      card.shown = 1;
      _gliding[card] = card.box;
    }
    _glideMs = ms;
    _glideAt = 0;
    _ease = ease;
  }

  /// Whether cards are gliding home.
  bool get gliding => _gliding.isNotEmpty;

  void _glide() {
    _glideAt += IkkiuchiPhysicsTuning.step * Duration.millisecondsPerSecond;
    final t = math.min(1.0, _glideAt / _glideMs);
    final e = _ease(t);
    for (final MapEntry(key: card, value: from) in _gliding.entries) {
      final home = card.home;
      card._last = home.movedTo(from.centre.lerp(home.centre, e), from.angle + turnBetween(from.angle, home.angle) * e);
    }
    if (t < 1) return;
    for (final card in _gliding.keys) {
      card
        .._body = _bodyAtHome(card)
        .._last = null
        .._stirred = false;
    }
    _gliding.clear();
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
