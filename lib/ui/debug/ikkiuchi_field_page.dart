import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_geometry.dart';
import '../../l10n/strings.dart';
import '../ikkiuchi/ikkiuchi_board_painter.dart';
import 'debug_common.dart';
import 'ikkiuchi_dealer.dart';

/// The developer's view of the 一騎打ち field as the match shows it: the
/// whole screen, its system bars hidden, with Tobi in his place, his side,
/// the band and the player's side, dealt at random with Tobi at a random
/// rating. One card is marked as the one read, its kimariji on the band,
/// and the player's finger pushes the cards about with the board's
/// physics; there are no takes, faults or scores. A while after the finger
/// lifts, every card it stirred glides home and another card is marked.
/// "R" turns the board's layout between portrait and landscape, a number
/// deals anew with that many cards a side, and the system back leaves.
class IkkiuchiFieldPage extends StatefulWidget {
  const IkkiuchiFieldPage({super.key, this.seed, this.landscape = false});

  /// The deal's seed, random when null.
  final int? seed;

  /// Whether the board starts in its landscape layout.
  final bool landscape;

  @override
  State<IkkiuchiFieldPage> createState() => IkkiuchiFieldPageState();
}

class IkkiuchiFieldPageState extends State<IkkiuchiFieldPage> with SingleTickerProviderStateMixin {
  final _dealer = IkkiuchiDealer();
  late int _seed = widget.seed ?? _randomSeed();
  late var _rng = math.Random(_seed);
  late bool _landscape = widget.landscape;
  int _perSide = IkkiuchiToolsTuning.dealPerSide;
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  /// The pointer of the finger on the board; other fingers are let be.
  int? _finger;

  /// How long until the cards the finger stirred set off home, from when it
  /// lifted; null while it is down, or with no swipe to answer.
  Duration? _wait;

  /// Whether the cards are on their way home.
  bool _returning = false;

  /// The board as drawn now (for tests).
  IkkiuchiBoardScene? get scene => _dealer.scene;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(IkkiuchiToolsTuning.fieldBars));
    _ticker.start();
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemBarsTuning.app));
    _ticker.dispose();
    _dealer.dispose();
    super.dispose();
  }

  static int _randomSeed() => math.Random().nextInt(IkkiuchiToolsTuning.seeds);

  void _deal(int perSide) => setState(() {
        _perSide = perSide;
        _seed = _randomSeed();
        _rng = math.Random(_seed);
      });

  void _turn() => setState(() => _landscape = !_landscape);

  /// The scene for a board filling [room]; a new one starts with a card marked.
  IkkiuchiBoardScene _sceneFor(Size room) => _dealer.sceneFor(context, room,
      landscape: _landscape,
      rating: IkkiuchiDealer.drawnRating(_seed + IkkiuchiToolsTuning.tobiSeedOffset),
      seed: _seed,
      perSide: _perSide,
      onNew: (scene) {
        _finger = null;
        _wait = null;
        _returning = false;
        _markAnother(scene);
      });

  /// Marks a card on the field as the one read, not the one marked so far,
  /// and shows its kimariji on the band.
  void _markAnother(IkkiuchiBoardScene scene) {
    final ids = [
      for (final c in scene.board.cards.cards)
        if (c.id != scene.marked) c.id,
    ]..sort();
    final id = ids[_rng.nextInt(ids.length)];
    scene
      ..mark(id)
      ..show(kimarijiFor(context, id));
  }

  void _onPointer(PointerEvent event) {
    final board = scene?.board;
    if (board == null) return;
    final at = Vec(event.localPosition.dx, event.localPosition.dy);
    switch (event) {
      case PointerDownEvent() when _finger == null:
        _finger = event.pointer;
        _wait = null;
        board.touch(at);
      case PointerMoveEvent() when event.pointer == _finger:
        board.touch(at);
      case PointerUpEvent() || PointerCancelEvent() when event.pointer == _finger:
        _finger = null;
        _wait = IkkiuchiToolsTuning.fieldWait;
        board.lift();
    }
  }

  void _tick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    final scene = this.scene;
    if (scene == null) return;
    scene.advance(dt.inMicroseconds / Duration.microsecondsPerMillisecond);
    final cards = scene.board.cards;
    if (_wait case final wait?) {
      final left = wait - dt;
      _wait = left > Duration.zero ? left : null;
      if (_wait != null) return;
      _returning = true;
      cards.glideHome(
        ms: IkkiuchiToolsTuning.fieldGlide.inMicroseconds / Duration.microsecondsPerMillisecond,
        ease: IkkiuchiToolsTuning.fieldGlideCurve.transform,
      );
    } else if (_returning && !cards.gliding) {
      _returning = false;
      _markAnother(scene);
    }
  }

  @override
  Widget build(BuildContext context) => Material(
        color: IkkiuchiBoardStyle.ground,
        child: LayoutBuilder(builder: (context, box) {
          final room = box.biggest;
          final scene = _sceneFor(room);
          return Stack(children: [
            Positioned.fill(
              child: IkkiuchiDealer.turned(IkkiuchiBoardView(scene, onPointer: _onPointer), landscape: _landscape),
            ),
            _buttons(scene, room),
          ]);
        }),
      );

  /// "R" and the numbers over the board: at the screen's top right in portrait;
  /// in landscape, where the cards reach every corner, at the top end of
  /// the band, which runs down the middle of the screen. Both keep below a
  /// cutout at the screen's top.
  Widget _buttons(IkkiuchiBoardScene scene, Size room) {
    const size = IkkiuchiToolsStyle.fieldButton, inset = IkkiuchiToolsStyle.fieldButtonInset;
    final top = MediaQuery.paddingOf(context).top + inset;
    final column = Column(mainAxisSize: MainAxisSize.min, children: [
      _button('R', _turn),
      for (final n in IkkiuchiToolsTuning.fieldCounts) ...[
        const SizedBox(height: IkkiuchiToolsStyle.fieldButtonGap),
        _button('$n', () => _deal(n)),
      ],
    ]);
    if (!_landscape) return Positioned(top: top, right: inset, child: column);
    // The board lies turned a quarter turn clockwise: its y runs from the
    // screen's right edge leftward.
    final bandMiddle = room.width - scene.layout.band.center.dy;
    return Positioned(top: top, left: bandMiddle - size / 2, child: column);
  }

  static final _label = debugMono.copyWith(
    fontSize: IkkiuchiToolsStyle.fieldButtonFont,
    color: IkkiuchiToolsStyle.fieldButtonInk,
  );

  static Widget _button(String label, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: IkkiuchiToolsStyle.fieldButton,
          height: IkkiuchiToolsStyle.fieldButton,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: IkkiuchiToolsStyle.fieldButtonFill,
            border: Border.all(
              color: IkkiuchiToolsStyle.fieldButtonEdge,
              width: IkkiuchiToolsStyle.fieldButtonEdgeWidth,
            ),
            borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.fieldButtonRadius),
          ),
          child: Text(label, style: _label),
        ),
      );
}
