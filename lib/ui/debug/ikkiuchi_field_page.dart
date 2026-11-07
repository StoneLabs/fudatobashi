import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../data/poem.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../ikkiuchi/ikkiuchi_board_painter.dart';
import '../ikkiuchi/ikkiuchi_board_scene.dart';
import '../ikkiuchi/ikkiuchi_match_layers.dart';
import '../ikkiuchi/ikkiuchi_reader.dart';
import 'debug_common.dart';
import 'ikkiuchi_dealer.dart';

/// The developer's view of the 一騎打ち field as the match shows it: the
/// whole screen, its system bars hidden, with Tobi in his place, his side,
/// the band (in portrait) and the player's side, dealt at random with Tobi
/// at a random rating. The page only drives the match's board
/// ([IkkiuchiBoardScene]): it reads a card at random, the reader reading
/// its kimariji, and the player's finger pushes the cards about, taking
/// the card and faulting (お手つき) as the match would; Tobi doesn't
/// strike. Once the board comes to rest again another card is read. In
/// landscape the match's own parts lie over the board: the call in the gap
/// between the sides ([IkkiuchiCallLayer]), and the game column
/// ([IkkiuchiColumnLayer]), whose 終了 deals anew once held.
/// The board starts in landscape. The developer's buttons: "R" turns its
/// layout between landscape and portrait, a number deals anew with that
/// many cards a side, "^" has the player send Tobi a card (送り札), "v"
/// has Tobi send the player one, and [IkkiuchiToolsStyle.fieldKarafudaLabel]
/// reads a からふだ; the system back leaves.
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
    scene.callCard(id, kimarijiFor(context, id), call: IkkiuchiReader.callFor(context, id));
  }

  /// Reads a card dealt to neither side at random, a からふだ, unless a
  /// 送り札 or 並べ替え is under way.
  void _readKarafuda(IkkiuchiBoardScene scene) {
    if (scene.busy) return;
    final dealt = {for (final c in scene.board.cards.cards) c.id};
    final ids = [
      for (final p in poems.all)
        if (!dealt.contains(p.id)) p.id,
    ];
    if (ids.isEmpty) return;
    final id = ids[_rng.nextInt(ids.length)];
    scene.callKarafuda(id, kimarijiFor(context, id),
        tag: S.of(context).ikkiuchiKarafuda, call: IkkiuchiReader.callFor(context, id));
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
          final scene = _sceneFor(box.biggest);
          return IkkiuchiDealer.turned(
            Stack(children: [
              Positioned.fill(
                child: IkkiuchiBoardView(
                  scene,
                  onPointer: scene.pointer,
                  overCards: _landscape ? IkkiuchiCallLayer(scene: scene) : null,
                ),
              ),
              if (_landscape) Positioned.fill(child: IkkiuchiColumnLayer(scene: scene, onEnd: () => _deal(_perSide))),
              _tools(scene),
            ]),
            landscape: _landscape,
          );
        }),
      );

  /// The developer's buttons, in board dp so they read upright: in portrait
  /// at the screen's top left, below a cutout there and clear of the card
  /// Tobi sends, which waits right of him; in landscape, where the cards
  /// reach the board's top and foot, in the room right of Tobi's side,
  /// clear of the field, the call and the game column, and of the card
  /// Tobi sends, which waits right of the player's side.
  Widget _tools(IkkiuchiBoardScene scene) {
    final panel = IkkiuchiFieldTools(
      turn: _turn,
      deals: {for (final n in IkkiuchiToolsTuning.fieldCounts) n: () => _deal(n)},
      send: scene.send.startSending,
      receive: () => scene.send.startReceiving(),
      karafuda: () => _readKarafuda(scene),
    );
    const inset = IkkiuchiToolsStyle.fieldButtonInset;
    if (!_landscape) return Positioned(top: MediaQuery.paddingOf(context).top + inset, left: inset, child: panel);
    final layout = scene.layout;
    final room = Rect.fromLTRB(layout.field.right, layout.field.top, layout.column!.left, layout.band.top);
    return Positioned.fromRect(
      rect: room.deflate(IkkiuchiToolsStyle.fieldPanelInset),
      child: Align(
        alignment: Alignment.topCenter,
        child: FittedBox(fit: BoxFit.scaleDown, child: panel),
      ),
    );
  }
}

/// The developer's buttons in their panel: the board's turn, the 送り札
/// both ways and a からふだ read in one column, the deals in the other.
class IkkiuchiFieldTools extends StatelessWidget {
  const IkkiuchiFieldTools({
    super.key,
    required this.turn,
    required this.deals,
    required this.send,
    required this.receive,
    required this.karafuda,
  });

  final VoidCallback turn, send, receive, karafuda;
  final Map<int, VoidCallback> deals;

  static const _gap = SizedBox.square(dimension: IkkiuchiToolsStyle.fieldButtonGap);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: IkkiuchiToolsStyle.fieldPanelFill,
          borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.fieldPanelRadius),
        ),
        child: Padding(
          padding: IkkiuchiToolsStyle.fieldPanelPadding,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(IkkiuchiToolsStyle.fieldPanelTitle, style: _title),
            const SizedBox(height: IkkiuchiToolsStyle.fieldPanelTitleGap),
            Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(mainAxisSize: MainAxisSize.min, children: [
                _button('R', turn),
                _gap,
                _button('^', send),
                _gap,
                _button('v', receive),
                _gap,
                _button(IkkiuchiToolsStyle.fieldKarafudaLabel, karafuda),
              ]),
              _gap,
              Column(mainAxisSize: MainAxisSize.min, children: [
                for (final (i, MapEntry(key: n, value: deal)) in deals.entries.indexed) ...[
                  if (i > 0) _gap,
                  _button('$n', deal),
                ],
              ]),
            ]),
          ]),
        ),
      );

  static final _title = debugMono.copyWith(
    fontSize: IkkiuchiToolsStyle.fieldPanelTitleFont,
    letterSpacing: IkkiuchiToolsStyle.fieldPanelTitleTracking * IkkiuchiToolsStyle.fieldPanelTitleFont,
    color: IkkiuchiToolsStyle.fieldPanelTitleInk,
  );

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
