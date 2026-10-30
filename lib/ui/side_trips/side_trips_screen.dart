import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/side_trips.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import 'ankiren_page.dart';
import 'teiichi_page.dart';
import '../manga/manga.dart';
import 'dojo_scene.dart';
import 'side_trip_entry.dart';

/// The Side Trips tab (寄り道): the dojo scene ([DojoScene]) with its ring of
/// islands ([SideTripRing]) over the entry of the island in front, carried
/// on the near swell: a trip's ([SideTripEntryView]), or one saying the
/// island is still being built ([SideTripSoonEntry]). Everything a trip's
/// entry shows comes from the hub ([SideTripsHub]).
///
/// A swipe anywhere turns the ring a step, the swell and the entry riding
/// under the finger and the sea's paper layers behind them sliding slower,
/// the further back the slower; under reduced motion the islands and
/// entries crossfade. Screen readers get the island's name and actions to
/// turn the ring. The tab always comes back with 暗記練 in front.
///
/// The first time the tab shows a trip open after showing it locked, its
/// torii opens with a snap; once, like the tab chains, and only with the
/// trip in front.
class SideTripsScreen extends StatefulWidget {
  const SideTripsScreen({super.key, this.underBar = 0});

  /// How far the sea runs on below the screen, under the tab bar.
  final double underBar;

  @override
  State<SideTripsScreen> createState() => _SideTripsScreenState();
}

class _SideTripsScreenState extends State<SideTripsScreen> with TickerProviderStateMixin {
  /// Trips whose opening is being shown.
  final Set<SideTrip> _opening = {};
  bool _syncScheduled = false;

  /// How far the ring has turned, a whole step at rest; and Tobi's boat's
  /// drift, in steps.
  late final _turn = AnimationController.unbounded(vsync: this)..addListener(_onTurn);
  late final _boat = AnimationController.unbounded(vsync: this);

  /// Under reduced motion, the crossfade from the ring at [_fadeFrom].
  late final _fade = AnimationController(
      vsync: this, duration: DojoRingMotion.crossfade, value: 1, animationBehavior: AnimationBehavior.preserve);
  int _fadeFrom = 0;

  /// The step the ring settles on, and the last it rested on.
  int _step = 0;
  int _rest = 0;

  /// The swipe under way: the step it set off from, the boat's drift then
  /// (both followed while [_swiping]), and under reduced motion how far
  /// the finger has gone.
  int _from = 0;
  double _boatFrom = 0;
  bool _swiping = false;
  double _swiped = 0;

  /// The islands whose swell breaks leftward: it rolled in that way.
  final Set<SideTripIsle> _leftward = {};

  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.valuesOf(context).enabled;
    if (shown && !_shown) _home();
    _shown = shown;
  }

  @override
  void dispose() {
    _turn.dispose();
    _boat.dispose();
    _fade.dispose();
    super.dispose();
  }

  bool get _still => MediaQuery.disableAnimationsOf(context);

  double get _stepWidth => context.size!.width * SideTripRingTuning.dragPerStep;

  /// The ring at rest with 暗記練 in front.
  void _home() {
    _turn.stop();
    _boat.stop();
    _fade.value = 1;
    _swiping = false;
    _step = _rest = _from = 0;
    _turn.value = 0;
    _boat.value = 0;
    _leftward.clear();
  }

  /// While a swipe turns the ring, the boat drifts with it and the island
  /// rolling in breaks the way it travels.
  void _onTurn() {
    if (!_swiping) return;
    final turn = _turn.value;
    _boat.value = _boatFrom + turn - _from;
    if (turn == _from) return;
    final forward = turn > _from;
    final coming = SideTripRing.frontAt(forward ? _from + 1 : _from - 1);
    if (_leftward.contains(coming) != forward) {
      setState(() => forward ? _leftward.add(coming) : _leftward.remove(coming));
    }
  }

  void _setOff() {
    _turn.stop();
    _boat.stop();
    _from = _turn.value.round();
    _boatFrom = _boat.value - (_turn.value - _from);
    _swiping = true;
  }

  void _onDragStart(DragStartDetails _) {
    _swiped = 0;
    if (!_still) _setOff();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final dx = d.primaryDelta ?? 0;
    if (_still) {
      _swiped += dx;
      return;
    }
    _turn.value = (_turn.value - dx / _stepWidth).clamp(_from - 1.0, _from + 1.0);
  }

  /// A fling turns on to the next step its way; a slower release settles
  /// on the nearest. A finger going left turns the ring forward.
  void _onDragEnd(DragEndDetails d) {
    final speed = d.primaryVelocity ?? 0;
    final fling = speed.abs() >= SideTripRingTuning.flingSpeed;
    if (_still) {
      final push = fling ? speed : _swiped;
      if (fling || _swiped.abs() >= SideTripRingTuning.stillSwipe) _crossfadeTo(_step - push.sign.toInt());
      return;
    }
    final turn = _turn.value;
    final target = !fling ? turn.round() : (speed < 0 ? turn.floor() + 1 : turn.ceil() - 1);
    _settle(target.clamp(_from - 1, _from + 1), -speed / _stepWidth);
  }

  void _onDragCancel() {
    if (_swiping) _settle(_turn.value.round(), 0);
  }

  /// Turns the ring [by] a step forward (1) or back (-1).
  void _stepBy(int by) {
    if (_still) return _crossfadeTo(_step + by);
    _setOff();
    _settle(_from + by, 0);
  }

  void _settle(int step, double velocity) {
    _step = step;
    _turn
        .animateWith(SpringSimulation(DojoRingMotion.settle, _turn.value, step.toDouble(), velocity))
        .whenComplete(_settled);
  }

  /// The ring has clicked into place: the boat springs back.
  void _settled() {
    _swiping = false;
    _turn.value = _step.toDouble();
    if (!_still) _boat.animateWith(SpringSimulation(DojoRingMotion.boatReturn, _boat.value, 0, 0));
    _rested();
  }

  void _crossfadeTo(int step) {
    _fadeFrom = _step;
    _step = step;
    _turn.value = step.toDouble();
    _fade.forward(from: 0);
    _rested();
  }

  void _rested() {
    if (_step != _rest && ProgressScope.read(context).settings.haptics) HapticFeedback.selectionClick();
    setState(() => _rest = _step);
  }

  /// While the tab is on screen with [trip] in front: remembers it shown
  /// locked, or starts showing its opening when it was and has opened
  /// since.
  void _syncLatch(Progress progress, SideTripsHub hub, SideTrip trip) {
    if (!TickerMode.valuesOf(context).enabled) return;
    final seen = progress.sideTripsSeenLocked;
    final locked = [if (!hub[trip].open) trip];
    final opened = [if (seen.contains(trip) && hub[trip].open) trip];
    if (_syncScheduled || (seen.containsAll(locked) && opened.isEmpty)) return;
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      progress.noteSideTripsSeenLocked(locked);
      if (opened.isEmpty) return;
      progress.noteSideTripsOpened(opened);
      setState(() => _opening.addAll(opened));
    });
  }

  /// [entry]'s torii: padlocked until its opening has been shown.
  GateState _gate(Progress progress, SideTripEntry entry) {
    if (!entry.open || progress.sideTripsSeenLocked.contains(entry.trip)) return GateState.locked;
    return _opening.contains(entry.trip) ? GateState.opening : GateState.open;
  }

  Widget _entry(SideTripsHub hub, SideTripIsle isle) => switch (isle.trip) {
        null => const SideTripSoonEntry(),
        SideTrip.ankiren => SideTripEntryView(hub[SideTrip.ankiren], onOpen: () => openAnkirenPage(context)),
        SideTrip.teiichi => SideTripEntryView(hub[SideTrip.teiichi], onOpen: () => openTeiichiPage(context)),
      };

  /// [isle]'s entry and swell show as far as the crossfade has come to it.
  Animation<double> _shownOf(SideTripIsle isle) {
    if (_fade.isCompleted) return kAlwaysCompleteAnimation;
    if (isle == SideTripRing.frontAt(_step)) return _fade;
    return ReverseAnimation(_fade);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, bounds) => OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: bounds.maxHeight + widget.underBar,
          maxHeight: bounds.maxHeight + widget.underBar,
          child: _hub(context),
        ),
      );

  Widget _hub(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final hub = progress.sideTripsHub();
    final front = SideTripRing.frontAt(_rest);
    final trip = front.trip;
    if (trip != null && !_swiping && _fade.isCompleted) _syncLatch(progress, hub, trip);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: ClipRect(
        child: LayoutBuilder(builder: (context, box) {
          final k = box.maxWidth / DojoSceneLayout.width;
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: _HubFrame(
                minScene: DojoSceneLayout.minHeight * k,
                side: math.max(Gaps.gutter, (box.maxWidth - SideTripsLayout.maxWidth) / 2),
                bottomGap: SideTripsLayout.bottomGap + widget.underBar,
                crest: DojoSceneLayout.crest * k + DojoSceneLayout.crestGap,
                turn: _turn,
                fade: _fade,
                fadeFrom: _fadeFrom,
                scene: Semantics(
                  container: true,
                  liveRegion: true,
                  label: s.isleName(front),
                  customSemanticsActions: {
                    CustomSemanticsAction(label: s.sideTripsNextIsland): () => _stepBy(1),
                    CustomSemanticsAction(label: s.sideTripsPreviousIsland): () => _stepBy(-1),
                  },
                  child: DojoScene(
                    turn: _turn,
                    fade: _fade,
                    fadeFrom: _fadeFrom,
                    gates: {for (final e in hub.entries) e.trip: _gate(progress, e)},
                    onOpened: (trip) => setState(() => _opening.remove(trip)),
                  ),
                ),
                boat: DojoBoat(drift: _boat),
                backWaves: RepaintBoundary(child: _BackWaves(turn: _turn)),
                waves: [
                  for (final isle in SideTripRing.isles)
                    FadeTransition(opacity: _shownOf(isle), child: _Swell(leftward: _leftward.contains(isle))),
                ],
                entries: [
                  for (final isle in SideTripRing.isles)
                    FadeTransition(opacity: _shownOf(isle), child: _entry(hub, isle)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The near swell that carries an island's entry, filling its box: the
/// picture, then its plain halftone repeated below it; mirrored to break
/// [leftward].
class _Swell extends StatelessWidget {
  const _Swell({required this.leftward});

  final bool leftward;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final k = box.maxWidth / DojoSceneLayout.width;
        const piece = DojoSceneLayout.seaNear;
        const fill = DojoSceneLayout.fill;
        final size = piece.rect.size * k;
        final tiles = math.max(0, ((box.maxHeight - size.height) / (fill.height * k)).ceil());
        final picture = ScenePicture(piece.asset, size: size);
        return Transform.flip(
          flipX: leftward,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              maxHeight: double.infinity,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                picture,
                for (var i = 0; i < tiles; i++)
                  ClipRect(
                    child: SizedBox(
                      width: size.width,
                      height: fill.height * k,
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: Transform.translate(offset: -fill.topLeft * k, child: picture),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        );
      });
}

/// The sea's paper layers behind the near swell
/// ([DojoSceneLayout.backWaves]), back to front, filling the swell's box:
/// each slides its own share of the way as the ring turns [turn] steps of
/// the box's width, round and round, and gently bobs; under reduced motion
/// they stay put.
class _BackWaves extends StatelessWidget {
  const _BackWaves({required this.turn});

  final Animation<double> turn;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth;
        final k = width / DojoSceneLayout.width;
        final still = MediaQuery.disableAnimationsOf(context);
        return IdleLoop(
          step: DojoSceneLayout.waveStep,
          builder: (context, elapsed, _) => AnimatedBuilder(
            animation: turn,
            builder: (context, _) => Stack(clipBehavior: Clip.none, children: [
              for (final layer in DojoSceneLayout.backWaves)
                ..._tiles(layer, k, width, still ? 0 : turn.value, elapsed),
            ]),
          ),
        );
      });

  /// [layer] across the box, two copies side by side, slid along by
  /// [turned] steps and bobbed as far as [elapsed] is into its period.
  List<Widget> _tiles(WaveLayer layer, double k, double width, double turned, Duration elapsed) {
    final size = layer.piece.rect.size * k;
    final left = -(layer.speed * turned * width) % width;
    final phase = (elapsed.inMicroseconds % layer.period.inMicroseconds) / layer.period.inMicroseconds;
    final top = layer.piece.rect.top * k + layer.bob * k * math.sin(2 * math.pi * phase);
    return [
      for (final x in [left - width, left])
        Positioned(left: x, top: top, child: ScenePicture(layer.piece.asset, size: size)),
    ];
  }
}

/// The hub's layout: each island's entry at the bottom inside [side]
/// gutters and [bottomGap], its swell cresting [crest] above it, and the
/// [scene] filling everything above the tallest entry, at least [minScene]
/// tall. When they need more height than the hub is given, it grows (and
/// the tab scrolls). The [backWaves] share the showing swell's box, behind
/// it; the [boat] shares the scene's box, between the two.
///
/// Only the entry of the island in front shows, unless the ring is
/// between two steps of [turn]: then the two entries ride their swells
/// across, side by side, at a height part of the way between theirs; or
/// while [fade] runs, the entry at [fadeFrom] shows where it rests too.
class _HubFrame extends MultiChildRenderObjectWidget {
  _HubFrame({
    required this.minScene,
    required this.side,
    required this.bottomGap,
    required this.crest,
    required this.turn,
    required this.fade,
    required this.fadeFrom,
    required Widget scene,
    required Widget boat,
    required Widget backWaves,
    required List<Widget> waves,
    required List<Widget> entries,
  }) : super(children: [
          scene,
          backWaves,
          boat,
          for (var i = 0; i < entries.length; i++) ...[waves[i], entries[i]],
        ]);

  final double minScene, side, bottomGap, crest;
  final Animation<double> turn, fade;
  final int fadeFrom;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHubFrame(
      minScene: minScene, side: side, bottomGap: bottomGap, crest: crest, turn: turn, fade: fade, fadeFrom: fadeFrom);

  @override
  void updateRenderObject(BuildContext context, _RenderHubFrame renderObject) => renderObject
    ..minScene = minScene
    ..side = side
    ..bottomGap = bottomGap
    ..crest = crest
    ..turn = turn
    ..fade = fade
    ..fadeFrom = fadeFrom;
}

class _HubFrameParentData extends ContainerBoxParentData<RenderBox> {}

/// An island's swell and entry as they show now: across by [dx], the
/// entry's top at [top].
typedef _Unit = ({int isle, double dx, double top});

class _RenderHubFrame extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HubFrameParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HubFrameParentData> {
  _RenderHubFrame({
    required this._minScene,
    required this._side,
    required this._bottomGap,
    required this._crest,
    required Animation<double> turn,
    required this._fade,
    required this._fadeFrom,
  }) : _turnAnimation = turn;

  double _minScene;
  set minScene(double v) {
    if (v == _minScene) return;
    _minScene = v;
    markNeedsLayout();
  }

  double _side;
  set side(double v) {
    if (v == _side) return;
    _side = v;
    markNeedsLayout();
  }

  double _bottomGap;
  set bottomGap(double v) {
    if (v == _bottomGap) return;
    _bottomGap = v;
    markNeedsLayout();
  }

  double _crest;
  set crest(double v) {
    if (v == _crest) return;
    _crest = v;
    markNeedsLayout();
  }

  Animation<double> _turnAnimation;
  set turn(Animation<double> v) {
    if (v == _turnAnimation) return;
    if (attached) _turnAnimation.removeListener(_moved);
    _turnAnimation = v;
    if (attached) _turnAnimation.addListener(_moved);
    _moved();
  }

  Animation<double> _fade;
  set fade(Animation<double> v) {
    if (v == _fade) return;
    if (attached) _fade.removeListener(_moved);
    _fade = v;
    if (attached) _fade.addListener(_moved);
    _moved();
  }

  int _fadeFrom;
  set fadeFrom(int v) {
    if (v == _fadeFrom) return;
    _fadeFrom = v;
    _moved();
  }

  /// The island whose entry takes taps and screen readers: the one in
  /// front, or nearest it.
  int _front = 0;

  void _moved() {
    markNeedsPaint();
    final front = SideTripRing.frontAt(_turnAnimation.value.round()).index;
    if (front == _front) return;
    _front = front;
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _turnAnimation.addListener(_moved);
    _fade.addListener(_moved);
  }

  @override
  void detach() {
    _turnAnimation.removeListener(_moved);
    _fade.removeListener(_moved);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HubFrameParentData) child.parentData = _HubFrameParentData();
  }

  RenderBox get _scene => firstChild!;
  RenderBox get _backWaves => childAfter(_scene)!;
  RenderBox get _boat => childAfter(_backWaves)!;

  /// The swells and entries, in [SideTripRing.isles] order.
  final List<RenderBox> _waves = [], _entries = [];

  @override
  void performLayout() {
    _waves.clear();
    _entries.clear();
    for (var child = childAfter(_boat); child != null; child = childAfter(childAfter(child)!)) {
      _waves.add(child);
      _entries.add(childAfter(child)!);
    }
    final width = constraints.maxWidth;
    final entryWidth = BoxConstraints.tightFor(width: math.max(0, width - 2 * _side));
    var tallest = 0.0;
    for (final entry in _entries) {
      entry.layout(entryWidth, parentUsesSize: true);
      tallest = math.max(tallest, entry.size.height);
    }
    final deck = tallest + _bottomGap;
    final height = math.max(constraints.minHeight, _minScene + deck);
    _scene.layout(BoxConstraints.tight(Size(width, height - deck)));
    _boat.layout(BoxConstraints.tight(Size(width, height - deck)));
    for (final wave in [..._waves, _backWaves]) {
      wave.layout(BoxConstraints.tight(Size(width, deck + _crest)));
    }
    size = constraints.constrain(Size(width, height));
  }

  /// Where island [i]'s entry rests: its top.
  double _restTop(int i) => size.height - _bottomGap - _entries[i].size.height;

  /// The swells and entries showing now.
  List<_Unit> get _units {
    final turn = _turnAnimation.value;
    final step = turn.round();
    if (_fade.value < 1) {
      return [
        for (final at in [_fadeFrom, step])
          (isle: SideTripRing.frontAt(at).index, dx: 0.0, top: _restTop(SideTripRing.frontAt(at).index)),
      ];
    }
    final from = turn.floor();
    final f = turn - from;
    final out = SideTripRing.frontAt(from).index;
    if (f == 0) return [(isle: out, dx: 0.0, top: _restTop(out))];
    final coming = SideTripRing.frontAt(from + 1).index;
    final top = _restTop(out) + (_restTop(coming) - _restTop(out)) * f;
    final width = size.width;
    return [(isle: out, dx: -f * width, top: top), (isle: coming, dx: (1 - f) * width, top: top)];
  }

  /// Where the back waves' top is now: the showing swells', or under
  /// reduced motion part of the way from the one fading out to the one
  /// fading in.
  double _backTop(List<_Unit> units) =>
      _fade.value < 1 ? units.first.top + (units.last.top - units.first.top) * _fade.value : units.first.top;

  /// Where [child] paints now; off to the right when it does not show.
  Offset _offsetOf(RenderBox child, List<_Unit> units) {
    if (child == _scene || child == _boat) return Offset.zero;
    if (child == _backWaves) return Offset(0, _backTop(units) - _crest);
    final isWave = _waves.contains(child);
    final i = isWave ? _waves.indexOf(child) : _entries.indexOf(child);
    final unit = units.where((u) => u.isle == i).firstOrNull ?? (isle: i, dx: size.width, top: _restTop(i));
    return isWave ? Offset(unit.dx, unit.top - _crest) : Offset(_side + unit.dx, unit.top);
  }

  RenderBox get _frontEntry => _entries[_front];

  @override
  void paint(PaintingContext context, Offset offset) {
    final units = _units;
    context.paintChild(_scene, offset);
    context.paintChild(_backWaves, offset + _offsetOf(_backWaves, units));
    context.paintChild(_boat, offset);
    for (final unit in units) {
      context.paintChild(_waves[unit.isle], offset + _offsetOf(_waves[unit.isle], units));
      context.paintChild(_entries[unit.isle], offset + _offsetOf(_entries[unit.isle], units));
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final at = _offsetOf(child, _units);
    transform.translateByDouble(at.dx, at.dy, 0, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final entry = _frontEntry;
    final hit = result.addWithPaintOffset(
      offset: _offsetOf(entry, _units),
      position: position,
      hitTest: (result, p) => entry.hitTest(result, position: p),
    );
    return hit || _scene.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitor(_scene);
    if (_entries.isNotEmpty) visitor(_frontEntry);
  }
}
