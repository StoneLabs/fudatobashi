import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';
import 'ikkiuchi_dealer.dart';
import 'ikkiuchi_match_board.dart';
import 'ikkiuchi_match_flow.dart';

/// Plays a free 一騎打ち match of [setup] ([IkkiuchiMatchScreen]).
Future<void> startIkkiuchiMatch(BuildContext context, IkkiuchiSetup setup) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup)));

/// A free 一騎打ち match ([IkkiuchiMatchFlow]) on the whole screen, held in
/// landscape with the system bars hidden and the menu music out, both
/// sides dealt from [seed] (random when null) and Tobi playing at the
/// setup's rating. The match runs on by itself; once it is over it is
/// recorded, and [IkkiuchiFreeTuning.leaveAfter] later the screen closes.
/// Leaving before then ends the match as given up, and records it so.
///
/// Until the screen stands in landscape the board lies turned in it; a
/// change of its size deals the same match afresh while the memory time
/// runs, and after that the board keeps its size, scaled to fit.
class IkkiuchiMatchScreen extends StatefulWidget {
  const IkkiuchiMatchScreen({super.key, required this.setup, this.seed});

  final IkkiuchiSetup setup;
  final int? seed;

  @override
  State<IkkiuchiMatchScreen> createState() => IkkiuchiMatchScreenState();
}

class IkkiuchiMatchScreenState extends State<IkkiuchiMatchScreen> with SingleTickerProviderStateMixin {
  final _dealer = IkkiuchiDealer(rows: IkkiuchiFreeTuning.rows, playerSeedOffset: IkkiuchiFreeTuning.playerSeedOffset);
  late final int _seed = widget.seed ?? math.Random().nextInt(IkkiuchiFreeTuning.seeds);
  late final Progress _progress;
  final _startedAt = DateTime.now();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Timer? _leave;
  bool _recorded = false;

  IkkiuchiMatchFlow? _flow;

  /// The match as it is played now (for tests).
  IkkiuchiMatchFlow? get flow => _flow;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.landscape));
    unawaited(SystemChrome.setEnabledSystemUIMode(IkkiuchiFreeTuning.bars));
    music.leaveMenu();
    _ticker.start();
  }

  @override
  void dispose() {
    _leave?.cancel();
    final flow = _flow;
    if (flow != null) {
      flow.removeListener(_changed);
      flow.end();
      _record(flow);
      flow.dispose();
    }
    unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.app));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemBarsTuning.app));
    music.enterMenu();
    _ticker.dispose();
    _dealer.dispose();
    super.dispose();
  }

  /// The match on a board filling [room], dealt afresh while its memory
  /// time runs when [room] changes.
  IkkiuchiMatchFlow _flowFor(Size room) {
    final flow = _flow;
    if (flow != null && flow.stage != IkkiuchiStage.memoryTime) return flow;
    final setup = widget.setup;
    _dealer.sceneFor(context, _boardSize(room),
        landscape: true,
        rating: setup.rating,
        seed: _seed,
        perSide: setup.perSide,
        onNew: (scene) {
          final old = _flow;
          if (old != null) {
            old.removeListener(_changed);
            SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
          }
          _flow = IkkiuchiMatchFlow(scene,
              words: IkkiuchiMatchWords.of(context), rating: setup.rating, memorise: setup.memorise)
            ..addListener(_changed);
        });
    return _flow!;
  }

  /// The landscape board's size in [room], turned when [room] stands
  /// upright.
  static Size _boardSize(Size room) => room.width >= room.height ? room : room.flipped;

  void _changed() {
    final flow = _flow!;
    if (flow.stage == IkkiuchiStage.gameEnd && !_recorded) {
      _record(flow);
      _leave = Timer(IkkiuchiFreeTuning.leaveAfter, () {
        if (mounted) Navigator.maybePop(context);
      });
    }
    if (mounted) setState(() {});
  }

  /// Stores the match, once.
  void _record(IkkiuchiMatchFlow flow) {
    if (_recorded) return;
    _recorded = true;
    final sides = flow.scene.sides!;
    final playerLeft = sides.playerCards.length, tobiLeft = sides.tobiCards.length;
    unawaited(_progress.recordIkkiuchi(IkkiuchiMatchRecord(
      setup: widget.setup,
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      result: IkkiuchiResult.of(playerLeft: playerLeft, tobiLeft: tobiLeft, gaveUp: flow.endedByPlayer),
      playerLeft: playerLeft,
      tobiLeft: tobiLeft,
      reads: flow.reads,
    )));
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
          final room = box.biggest;
          final flow = _flowFor(room);
          final size = flow.scene.layout.size;
          final board = SizedBox(width: size.x, height: size.y, child: IkkiuchiMatchBoard(flow));
          return FittedBox(child: room.width >= room.height ? board : RotatedBox(quarterTurns: 1, child: board));
        }),
      );
}
