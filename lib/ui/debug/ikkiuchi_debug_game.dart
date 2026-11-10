import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../ikkiuchi/ikkiuchi_board_scene.dart';
import '../ikkiuchi/ikkiuchi_dealer.dart';
import '../ikkiuchi/ikkiuchi_match_board.dart';
import '../ikkiuchi/ikkiuchi_match_flow.dart';
import 'debug_common.dart';

/// The developer's 一騎打ち game: a whole match ([IkkiuchiMatchFlow]) on the
/// whole screen, its system bars hidden, dealt at random for the players
/// to lay out their sides and Tobi in his form drawn from the deal's seed,
/// as in a match. The match holds once the 送り札 after each read are made,
/// until 次, and the card read is marked.
///
/// The developer's tools lie over everything at the board's top left: the
/// stage, Tobi's rating, and the slider that sets it for the reads to come
/// (OFF at its top, his highest rating at its foot). The buttons: "R" turns
/// the board between landscape and portrait and a number deals anew with
/// that many cards a side, either starting the match afresh; "^" and "v"
/// make a 送り札 to Tobi and from him, 空 makes the next read a からふだ, 始
/// ends the placing and the memory time (the cards still in the stack put
/// down, Tobi's side laid out at once) and 次 lets the held match go on.
/// The system back leaves.
class IkkiuchiDebugGame extends StatefulWidget {
  const IkkiuchiDebugGame({super.key, this.seed, this.landscape = true});

  /// The deal's seed, random when null.
  final int? seed;

  /// Whether the board starts in its landscape layout.
  final bool landscape;

  @override
  State<IkkiuchiDebugGame> createState() => IkkiuchiDebugGameState();
}

class IkkiuchiDebugGameState extends State<IkkiuchiDebugGame> with SingleTickerProviderStateMixin {
  final _dealer = IkkiuchiDealer(
      rows: IkkiuchiToolsTuning.dealRows, playerSeedOffset: IkkiuchiToolsTuning.playerSeedOffset);
  late int _seed = widget.seed ?? _randomSeed();
  late bool _landscape = widget.landscape;
  int _perSide = IkkiuchiToolsTuning.dealPerSide;
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  /// The slider's place: Tobi's rating, or under his lowest for OFF.
  double _slider = IkkiuchiToolsTuning.ratingStart;
  static const _off = IkkiuchiTuning.ratingMin - IkkiuchiToolsTuning.ratingStep;
  double? get _rating => _slider < IkkiuchiTuning.ratingMin ? null : _slider;

  /// Tobi's rating the deal laid his side out at, before his form.
  late double _dealRating = _rating ?? IkkiuchiTuning.ratingMin;

  IkkiuchiMatchFlow? _flow;

  /// The match as it is played now, and its board (for tests).
  IkkiuchiMatchFlow? get flow => _flow;
  IkkiuchiBoardScene? get scene => _dealer.scene;

  /// Sets Tobi's rating (null for OFF) as the slider would.
  void setRating(double? rating) => setState(() {
        _slider = rating ?? _off;
        _flow?.rating = rating;
      });

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(IkkiuchiToolsTuning.gameBars));
    _ticker.start();
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemBarsTuning.app));
    _ticker.dispose();
    _flow?.dispose();
    _dealer.dispose();
    super.dispose();
  }

  static int _randomSeed() => math.Random().nextInt(IkkiuchiToolsTuning.seeds);

  void _deal(int perSide) => setState(() {
        _perSide = perSide;
        _seed = _randomSeed();
        _dealRating = _rating ?? IkkiuchiTuning.ratingMin;
      });

  void _turn() => setState(() => _landscape = !_landscape);

  /// The match on a board filling [room]; a board set out afresh starts
  /// one afresh.
  IkkiuchiMatchFlow _flowFor(Size room) {
    _dealer.sceneFor(context, IkkiuchiDealer.boardIn(room, landscape: _landscape),
        landscape: _landscape,
        rating: _dealRating,
        seed: _seed,
        perSide: _perSide,
        form: IkkiuchiTobi.formFor(_seed),
        opening: true,
        onNew: (scene) {
          final old = _flow;
          if (old != null) SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
          _flow = IkkiuchiMatchFlow(scene,
              words: IkkiuchiMatchWords.of(context), rating: _rating, holdBeforeShimonoku: true, markCalled: true)
            ..addListener(_changed);
        });
    return _flow!;
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _tick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    _flow?.advance(dt.inMicroseconds / Duration.microsecondsPerMillisecond);
  }

  @override
  Widget build(BuildContext context) => Material(
        color: IkkiuchiBoardStyle.ground,
        child: LayoutBuilder(builder: (context, box) {
          final flow = _flowFor(box.biggest);
          return IkkiuchiDealer.turned(
            Stack(children: [
              Positioned.fill(child: IkkiuchiMatchBoard(flow, onEnd: flow.end)),
              _tools(flow),
            ]),
            landscape: _landscape,
          );
        }),
      );

  /// The developer's tools at the board's top left, inside the screen's
  /// safe area, which the landscape board lies turned in.
  Widget _tools(IkkiuchiMatchFlow flow) {
    final safe = MediaQuery.paddingOf(context);
    const inset = IkkiuchiToolsStyle.gameInset;
    return Positioned(
      left: (_landscape ? safe.top : safe.left) + inset,
      top: (_landscape ? safe.right : safe.top) + inset,
      child: IkkiuchiDebugTools(
        stage: flow.stage,
        rating: _rating,
        slider: _slider,
        onSlider: (v) => setRating(v < IkkiuchiTuning.ratingMin ? null : v),
        karafudaNext: flow.karafudaNext,
        turn: _turn,
        deals: {for (final n in IkkiuchiToolsTuning.gameCounts) n: () => _deal(n)},
        send: () => flow.sendByHand(IkkiuchiSide.player),
        receive: () => flow.sendByHand(IkkiuchiSide.opponent),
        karafuda: flow.askKarafuda,
        start: flow.endMemoryTime,
        go: flow.go,
      ),
    );
  }
}

/// The debug game's tools: the stage and Tobi's rating, his rating slider
/// at the very left, and the buttons beside it.
class IkkiuchiDebugTools extends StatelessWidget {
  const IkkiuchiDebugTools({
    super.key,
    required this.stage,
    required this.rating,
    required this.slider,
    required this.onSlider,
    required this.karafudaNext,
    required this.turn,
    required this.deals,
    required this.send,
    required this.receive,
    required this.karafuda,
    required this.start,
    required this.go,
  });

  final IkkiuchiStage stage;
  final double? rating;
  final double slider;
  final ValueChanged<double> onSlider;
  final bool karafudaNext;
  final VoidCallback turn, send, receive, karafuda, start, go;
  final Map<int, VoidCallback> deals;

  static String stageName(IkkiuchiStage stage) => switch (stage) {
        IkkiuchiStage.placing => IkkiuchiToolsStyle.placing,
        IkkiuchiStage.memoryTime => IkkiuchiToolsStyle.memoryTime,
        IkkiuchiStage.gameStart => IkkiuchiToolsStyle.gameStart,
        IkkiuchiStage.yoka => IkkiuchiToolsStyle.yoka,
        IkkiuchiStage.kaminoku => IkkiuchiToolsStyle.kaminoku,
        IkkiuchiStage.waitingForHit => IkkiuchiToolsStyle.waitingForHit,
        IkkiuchiStage.feedback => IkkiuchiToolsStyle.feedback,
        IkkiuchiStage.closingUp => IkkiuchiToolsStyle.closingUp,
        IkkiuchiStage.sendingCard => IkkiuchiToolsStyle.sendingCard,
        IkkiuchiStage.tobiPlacingCard => IkkiuchiToolsStyle.tobiPlacingCard,
        IkkiuchiStage.receivingCard => IkkiuchiToolsStyle.receivingCard,
        IkkiuchiStage.finalSend => IkkiuchiToolsStyle.finalSend,
        IkkiuchiStage.waitingForGo => IkkiuchiToolsStyle.waitingForGo,
        IkkiuchiStage.waitBeforeShimonoku => IkkiuchiToolsStyle.waitBeforeShimonoku,
        IkkiuchiStage.shimonoku => IkkiuchiToolsStyle.shimonoku,
        IkkiuchiStage.movingCard => IkkiuchiToolsStyle.movingCard,
        IkkiuchiStage.breakAfterShimonoku => IkkiuchiToolsStyle.breakAfterShimonoku,
        IkkiuchiStage.gameEnd => IkkiuchiToolsStyle.gameEnd,
        IkkiuchiStage.result => IkkiuchiToolsStyle.result,
        IkkiuchiStage.done => IkkiuchiToolsStyle.done,
      };

  static String ratingName(double? rating) =>
      IkkiuchiToolsStyle.ratingLabel + (rating == null ? IkkiuchiToolsStyle.ratingOff : '${rating.round()}');

  static const _gap = SizedBox.square(dimension: IkkiuchiToolsStyle.gameButtonGap);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chip(stageName(stage)),
          const SizedBox(height: IkkiuchiToolsStyle.readoutGap),
          _chip(ratingName(rating)),
          const SizedBox(height: IkkiuchiToolsStyle.readoutGap),
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _slider(),
            _gap,
            _panel(),
          ]),
        ],
      );

  static final _readout = debugMono.copyWith(fontSize: IkkiuchiToolsStyle.readoutFont, color: IkkiuchiToolsStyle.readoutInk);

  static Widget _chip(String text) => DecoratedBox(
        decoration: BoxDecoration(
          color: IkkiuchiToolsStyle.readoutFill,
          borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.gamePanelRadius),
        ),
        child: Padding(padding: IkkiuchiToolsStyle.readoutPadding, child: Text(text, style: _readout)),
      );

  /// The slider standing on end: a quarter turn puts its low end on top.
  Widget _slider() => DecoratedBox(
        decoration: BoxDecoration(
          color: IkkiuchiToolsStyle.readoutFill,
          borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.gamePanelRadius),
        ),
        child: SizedBox(
          width: IkkiuchiToolsStyle.sliderWidth,
          height: IkkiuchiToolsStyle.sliderLength,
          child: RotatedBox(
            quarterTurns: 1,
            child: SliderTheme(
              data: const SliderThemeData(
                trackHeight: IkkiuchiToolsStyle.gameSliderTrack,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: IkkiuchiToolsStyle.gameSliderThumb),
                overlayShape: RoundSliderOverlayShape(overlayRadius: IkkiuchiToolsStyle.gameSliderOverlay),
                activeTrackColor: IkkiuchiToolsStyle.gameSliderActive,
                inactiveTrackColor: IkkiuchiToolsStyle.gameSliderInactive,
                thumbColor: IkkiuchiToolsStyle.gameSliderThumbFill,
                showValueIndicator: ShowValueIndicator.never,
              ),
              child: Slider(
                value: slider,
                min: IkkiuchiDebugGameState._off,
                max: IkkiuchiTuning.ratingMax,
                divisions: ((IkkiuchiTuning.ratingMax - IkkiuchiDebugGameState._off) / IkkiuchiToolsTuning.ratingStep).round(),
                onChanged: onSlider,
              ),
            ),
          ),
        ),
      );

  Widget _panel() => DecoratedBox(
        decoration: BoxDecoration(
          color: IkkiuchiToolsStyle.gamePanelFill,
          borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.gamePanelRadius),
        ),
        child: Padding(
          padding: IkkiuchiToolsStyle.gamePanelPadding,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(IkkiuchiToolsStyle.gamePanelTitle, style: _title),
            const SizedBox(height: IkkiuchiToolsStyle.gamePanelTitleGap),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _button(IkkiuchiToolsStyle.turnLabel, turn),
              _gap,
              _button(IkkiuchiToolsStyle.sendLabel, send),
              _gap,
              _button(IkkiuchiToolsStyle.receiveLabel, receive),
              _gap,
              _button(IkkiuchiToolsStyle.karafudaLabel, karafuda, on: karafudaNext),
              _gap,
              _button(IkkiuchiToolsStyle.startLabel, start),
              _gap,
              _button(IkkiuchiToolsStyle.goLabel, go),
            ]),
            _gap,
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (final (i, MapEntry(key: n, value: deal)) in deals.entries.indexed) ...[
                if (i > 0) _gap,
                _button('$n', deal),
              ],
            ]),
          ]),
        ),
      );

  static final _title = debugMono.copyWith(
    fontSize: IkkiuchiToolsStyle.gamePanelTitleFont,
    letterSpacing: IkkiuchiToolsStyle.gamePanelTitleTracking * IkkiuchiToolsStyle.gamePanelTitleFont,
    color: IkkiuchiToolsStyle.gamePanelTitleInk,
  );

  static final _label = debugMono.copyWith(
    fontSize: IkkiuchiToolsStyle.gameButtonFont,
    color: IkkiuchiToolsStyle.gameButtonInk,
  );

  static Widget _button(String label, VoidCallback onTap, {bool on = false}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: IkkiuchiToolsStyle.gameButton,
          height: IkkiuchiToolsStyle.gameButton,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? IkkiuchiToolsStyle.gameButtonOnFill : IkkiuchiToolsStyle.gameButtonFill,
            border: Border.all(color: IkkiuchiToolsStyle.gameButtonEdge, width: IkkiuchiToolsStyle.gameButtonEdgeWidth),
            borderRadius: BorderRadius.circular(IkkiuchiToolsStyle.gameButtonRadius),
          ),
          child: Text(label, style: _label),
        ),
      );
}
