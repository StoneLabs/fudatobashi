import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../l10n/strings.dart';
import '../ikkiuchi/ikkiuchi_board_painter.dart';
import '../ikkiuchi/ikkiuchi_board_scene.dart';
import 'debug_common.dart';
import 'ikkiuchi_dealer.dart';

/// The developer's view of the 一騎打ち field as the match shows it: the
/// whole screen, its system bars hidden, with Tobi in his place, his side,
/// the band (in portrait) and the player's side, dealt at random with Tobi at a random
/// rating. The page only drives the match's board ([IkkiuchiBoardScene]):
/// it reads a card at random, its kimariji on the band, and the player's
/// finger pushes the cards about, taking the card as the match would;
/// Tobi doesn't strike. Once the board comes to rest again another card
/// is read. The board starts in landscape; "R" turns its layout between
/// landscape and portrait, a
/// number deals anew with that many cards a side, "^" has the player send
/// Tobi a card (送り札) and "v" has Tobi send the player one; the system
/// back leaves.
class IkkiuchiFieldPage extends StatefulWidget {
  const IkkiuchiFieldPage({super.key, this.seed, this.landscape = true});

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

  /// The scene for a board filling [room]; a new one starts with a card
  /// read, and reads another each time it comes to rest.
  IkkiuchiBoardScene _sceneFor(Size room) => _dealer.sceneFor(context, room,
      landscape: _landscape,
      rating: IkkiuchiDealer.drawnRating(_seed + IkkiuchiToolsTuning.tobiSeedOffset),
      seed: _seed,
      perSide: _perSide,
      onNew: (scene) {
        scene.onSettled = () => _readAnother(scene);
        _readAnother(scene);
      });

  /// Reads a card on the field at random, not the one read so far.
  void _readAnother(IkkiuchiBoardScene scene) {
    final ids = [
      for (final id in scene.board.field.keys)
        if (id != scene.board.called) id,
    ]..sort();
    if (ids.isEmpty) return;
    final id = ids[_rng.nextInt(ids.length)];
    scene.callCard(id, kimarijiFor(context, id));
  }

  void _tick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    scene?.advance(dt.inMicroseconds / Duration.microsecondsPerMillisecond);
  }

  @override
  Widget build(BuildContext context) => Material(
        color: IkkiuchiBoardStyle.ground,
        child: LayoutBuilder(builder: (context, box) {
          final room = box.biggest;
          final scene = _sceneFor(room);
          return Stack(children: [
            Positioned.fill(
              child: IkkiuchiDealer.turned(IkkiuchiBoardView(scene, onPointer: scene.pointer), landscape: _landscape),
            ),
            _buttons(scene, room),
          ]);
        }),
      );

  /// The buttons over the board, "R", the numbers, "^" and "v": at the
  /// screen's top left in portrait, clear of the card Tobi sends, which
  /// waits right of him; in landscape, where the cards reach every corner,
  /// at the top end of the gap between the sides, which runs down the middle
  /// of the screen, the buttons as wide as it is. Both keep below a cutout
  /// at the screen's top.
  Widget _buttons(IkkiuchiBoardScene scene, Size room) {
    const inset = IkkiuchiToolsStyle.fieldButtonInset;
    final size = _landscape ? math.min(IkkiuchiToolsStyle.fieldButton, scene.layout.band.height) : IkkiuchiToolsStyle.fieldButton;
    final top = MediaQuery.paddingOf(context).top + inset;
    final column = Column(mainAxisSize: MainAxisSize.min, children: [
      _button('R', _turn, size),
      for (final n in IkkiuchiToolsTuning.fieldCounts) ...[
        const SizedBox(height: IkkiuchiToolsStyle.fieldButtonGap),
        _button('$n', () => _deal(n), size),
      ],
      const SizedBox(height: IkkiuchiToolsStyle.fieldButtonGap),
      _button('^', scene.send.startSending, size),
      const SizedBox(height: IkkiuchiToolsStyle.fieldButtonGap),
      _button('v', () => scene.send.startReceiving(), size),
    ]);
    if (!_landscape) return Positioned(top: top, left: inset, child: column);
    // The board lies turned a quarter turn clockwise: its y runs from the
    // screen's right edge leftward.
    final gapMiddle = room.width - scene.layout.band.center.dy;
    return Positioned(top: top, left: gapMiddle - size / 2, child: column);
  }

  static final _label = debugMono.copyWith(
    fontSize: IkkiuchiToolsStyle.fieldButtonFont,
    color: IkkiuchiToolsStyle.fieldButtonInk,
  );

  static Widget _button(String label, VoidCallback onTap, double size) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
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
