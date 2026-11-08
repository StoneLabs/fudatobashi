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

/// Plays a 一騎打ち match of [setup], ranked or free ([IkkiuchiMatchScreen]).
Future<void> startIkkiuchiMatch(BuildContext context, IkkiuchiSetup setup) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup)));

/// A 一騎打ち match ([IkkiuchiMatchFlow]) of [setup] on the whole screen,
/// held in landscape with the system bars hidden and the menu music out,
/// both sides dealt from [seed] (random when null) and the opponent playing
/// at the setup's rating. The match runs on by itself.
///
/// A match that ends once play has begun (its first card read), played to
/// its end or by 終了, is recorded, and [IkkiuchiScreenTuning.leaveAfter]
/// later the screen closes; one ended before records nothing. Leaving the
/// screen before the match ends records free play not at all, and a ranked
/// match, once play has begun, as given up: a loss. From its first read a
/// ranked match is journalled, so that one the app never gets to record is
/// a forfeit on the next start ([Progress.journalIkkiuchi]).
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
  final _dealer =
      IkkiuchiDealer(rows: IkkiuchiScreenTuning.rows, playerSeedOffset: IkkiuchiScreenTuning.playerSeedOffset);
  late final int _seed = widget.seed ?? math.Random().nextInt(IkkiuchiScreenTuning.seeds);
  late final Progress _progress;
  final _startedAt = DateTime.now();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Timer? _leave;
  bool _journalled = false;
  bool _over = false;

  IkkiuchiMatchFlow? _flow;

  /// The match as it is played now (for tests).
  IkkiuchiMatchFlow? get flow => _flow;

  /// The storing of the match, once it is recorded (for tests).
  Future<void>? get saving => _saving;
  Future<void>? _saving;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.landscape));
    unawaited(SystemChrome.setEnabledSystemUIMode(IkkiuchiScreenTuning.bars));
    music.leaveMenu();
    _ticker.start();
  }

  @override
  void dispose() {
    _leave?.cancel();
    final flow = _flow;
    if (flow != null) {
      flow.removeListener(_changed);
      if (!_over) {
        flow.end();
        if (widget.setup.ranked && flow.playBegun) _record(flow);
      }
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
        rating: setup.opponentRating,
        seed: _seed,
        perSide: setup.perSide,
        onNew: (scene) {
          final old = _flow;
          if (old != null) {
            old.removeListener(_changed);
            SchedulerBinding.instance.addPostFrameCallback((_) => old.dispose());
          }
          _flow = IkkiuchiMatchFlow(scene,
              words: IkkiuchiMatchWords.of(context), rating: setup.opponentRating, memorise: setup.memorise)
            ..addListener(_changed);
        });
    return _flow!;
  }

  /// The landscape board's size in [room], turned when [room] stands
  /// upright.
  static Size _boardSize(Size room) => room.width >= room.height ? room : room.flipped;

  void _changed() {
    final flow = _flow!;
    if (widget.setup.ranked && flow.playBegun && !_journalled) {
      _journalled = true;
      unawaited(_progress.journalIkkiuchi(widget.setup, _startedAt));
    }
    if (flow.stage == IkkiuchiStage.gameEnd && !_over) {
      _over = true;
      if (flow.playBegun) _record(flow);
      _leave = Timer(IkkiuchiScreenTuning.leaveAfter, () {
        if (mounted) Navigator.maybePop(context);
      });
    }
    if (mounted) setState(() {});
  }

  /// Stores the match as it stands: played to its end unless the player
  /// ended or left it, each side's cards as the rules count them.
  void _record(IkkiuchiMatchFlow flow) {
    final left = flow.tally;
    _saving = _progress.recordIkkiuchi(IkkiuchiMatchRecord(
      setup: widget.setup,
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      completed: !flow.endedByPlayer,
      playerLeft: left.player,
      opponentLeft: left.opponent,
      reads: flow.reads,
    ));
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
