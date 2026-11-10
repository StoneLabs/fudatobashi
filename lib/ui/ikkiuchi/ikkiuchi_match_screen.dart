import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_tobi.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';
import 'ikkiuchi_dealer.dart';
import 'ikkiuchi_match_board.dart';
import 'ikkiuchi_match_flow.dart';
import 'ikkiuchi_results_screen.dart';

/// Plays a 一騎打ち match of [setup], ranked or free, or a [guest]'s that
/// records nothing ([IkkiuchiMatchScreen]).
Future<void> startIkkiuchiMatch(BuildContext context, IkkiuchiSetup setup, {bool guest = false}) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => IkkiuchiMatchScreen(setup: setup, guest: guest)));

/// A 一騎打ち match ([IkkiuchiMatchFlow]) of [setup] on the whole screen,
/// held in landscape with the system bars hidden and the menu music out,
/// dealt from [seed] (random when null) for the players to lay out their
/// sides, the opponent playing at the setup's rating in his form drawn
/// from it (`IkkiuchiTobi.formFor`). The match runs on by itself.
///
/// A match that ends once play has begun (its first card read), played to
/// its end or by 終了, is recorded; one ended before records nothing, and a
/// [guest]'s never records anything. Once its end has been shown (the
/// players' thanks, then its result) the screen closes: a match whose
/// play had begun hands over to its results ([IkkiuchiResultsScreen]),
/// upright with the system bars back, and one ended before just closes.
/// Leaving the screen before the match ends records free play not at all,
/// and a ranked match, once play has begun, as given up: a loss. From its
/// first read, and again after every read and every 送り札, a ranked match
/// is journalled as it stands, so that one the app never gets to record is
/// a forfeit on the next start with its reads and cards left
/// ([Progress.journalIkkiuchi]).
///
/// Once leaving a ranked match counts, 終了 is named 投了, and ending it so
/// or by the system's back asks first ([confirmLeaving]) and gives it up,
/// its end shown as any match's; before its first read, and in free play,
/// 終了 stays and the back leaves at once.
///
/// Until the screen stands in landscape the board lies turned in it; a
/// change of its size deals the same match afresh until the player places
/// a card, and after that the board keeps its size, scaled to fit.
class IkkiuchiMatchScreen extends StatefulWidget {
  const IkkiuchiMatchScreen({super.key, required this.setup, this.seed, this.guest = false});

  /// The match's setup: each side is laid out in its rows, as its cards
  /// allow them (`IkkiuchiLayout.rowsAllowed`); the board keeps them, and
  /// its cards' size, to the match's end.
  final IkkiuchiSetup setup;
  final int? seed;
  final bool guest;

  @override
  State<IkkiuchiMatchScreen> createState() => IkkiuchiMatchScreenState();
}

class IkkiuchiMatchScreenState extends State<IkkiuchiMatchScreen> with SingleTickerProviderStateMixin {
  late final _dealer = IkkiuchiDealer(rows: widget.setup.rows, playerSeedOffset: IkkiuchiScreenTuning.playerSeedOffset);
  late final int _seed = widget.seed ?? math.Random().nextInt(IkkiuchiScreenTuning.seeds);
  late final double _form = IkkiuchiTobi.formFor(_seed);
  late final Progress _progress;
  final _startedAt = DateTime.now();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  /// The match's log as last journalled (`IkkiuchiMatchFlow.logChanges`);
  /// null before the first save.
  int? _journalled;
  bool _over = false;

  /// The match as it ended, for one whose play had begun; null until it
  /// ends, and for one ended before.
  IkkiuchiMatchRecord? _ended;

  /// Whether the screen is closing ([_close]), and whether it handed over
  /// to the results, which then hold the music.
  bool _closing = false, _toResults = false;

  IkkiuchiMatchFlow? _flow;

  /// The match as it is played now (for tests).
  IkkiuchiMatchFlow? get flow => _flow;

  /// The storing of the match, once it is recorded (for tests).
  Future<void>? get saving => _saving;
  Future<IkkiuchiReport>? _saving;

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
    final flow = _flow;
    if (flow != null) {
      flow.removeListener(_changed);
      if (!_over) {
        final decided = flow.tally.decided;
        flow.end();
        if (widget.setup.ranked && flow.playBegun && !widget.guest) _record(_matchSoFar(flow, completed: decided));
      }
      flow.dispose();
    }
    _restoreScreen();
    if (!_toResults) music.enterMenu();
    _ticker.dispose();
    _dealer.dispose();
    super.dispose();
  }

  /// The match on a board filling [room], dealt afresh when [room] changes
  /// before the player places a card.
  IkkiuchiMatchFlow _flowFor(Size room) {
    final flow = _flow;
    if (flow != null && !(flow.stage == IkkiuchiStage.placing && flow.scene.opening.untouched)) return flow;
    final setup = widget.setup;
    _dealer.sceneFor(context, _boardSize(room),
        landscape: true,
        rating: setup.opponentRating,
        seed: _seed,
        perSide: setup.perSide,
        form: _form,
        opening: true,
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
    if (widget.setup.ranked && !widget.guest && flow.playBegun && !_over && _journalled != flow.logChanges) {
      _journalled = flow.logChanges;
      unawaited(_progress.journalIkkiuchi(_matchSoFar(flow, completed: false)));
    }
    if (flow.stage == IkkiuchiStage.gameEnd && !_over) {
      _over = true;
      if (flow.playBegun) {
        final match = _ended = _matchSoFar(flow, completed: !flow.endedByPlayer);
        if (!widget.guest) _record(match);
      }
    }
    if (flow.stage == IkkiuchiStage.done && !_closing) unawaited(_close());
    if (mounted) setState(() {});
  }

  /// The match's end has been shown: a match whose play had begun hands
  /// over to its results once it is stored, the screen upright again with
  /// the system bars back; one ended before just closes, back to the page.
  Future<void> _close() async {
    _closing = true;
    final ended = _ended;
    if (ended == null) {
      if (mounted) unawaited(Navigator.maybePop(context));
      return;
    }
    final report = await _saving;
    // Left meanwhile: its route is on its way out, and replacing "the
    // current route" would replace the one under it.
    if (!mounted || ModalRoute.isCurrentOf(context) == false) return;
    _toResults = true;
    _restoreScreen();
    unawaited(Navigator.of(context).pushReplacement(
        MangaRoute<void>(builder: (_) => IkkiuchiResultsScreen(match: report?.match ?? ended, report: report))));
  }

  /// The app's own orientation and system bars, for the screen after.
  static void _restoreScreen() {
    unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.app));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemBarsTuning.app));
  }

  /// Stores [match], over: played to its end unless the player ended or
  /// left it, each side's cards as the rules count them.
  void _record(IkkiuchiMatchRecord match) => _saving = _progress.recordIkkiuchi(match);

  /// The match as it stands, [completed] or not.
  IkkiuchiMatchRecord _matchSoFar(IkkiuchiMatchFlow flow, {required bool completed}) {
    final left = flow.tally;
    return IkkiuchiMatchRecord(
      setup: widget.setup,
      startedAt: _startedAt,
      endedAt: DateTime.now(),
      memorised: flow.memorised,
      completed: completed,
      playerLeft: left.player,
      opponentLeft: left.opponent,
      reads: flow.reads,
    );
  }

  void _tick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    _flow?.advance(dt.inMicroseconds / Duration.microsecondsPerMillisecond);
  }

  /// Whether leaving now gives up a ranked match that counts: from its
  /// first read until it is decided.
  bool get _leavingCounts {
    final flow = _flow;
    return widget.setup.ranked && !widget.guest && !_over && flow != null && flow.playBegun && flow.canEnd;
  }

  /// Whether the match is decided and its end still to come: it can't be
  /// left until then.
  bool get _awaitingEnd {
    final flow = _flow;
    return flow != null && !_over && !flow.canEnd;
  }

  Future<bool> _confirmSurrender() {
    final s = S.of(context);
    return confirmLeaving(context,
        title: s.ikkiuchiSurrenderTitle,
        note: s.ikkiuchiSurrenderNote,
        stay: s.ikkiuchiKeepPlaying,
        leave: s.ikkiuchiSurrender);
  }

  /// 終了 (投了), or the system's back while leaving counts: ends the
  /// match, once the player says so when it counts. Once the match is
  /// decided it does nothing, the match played to its end.
  Future<void> _end() async {
    if (_flow?.canEnd != true) return;
    if (_leavingCounts && !await _confirmSurrender()) return;
    if (mounted) _flow?.end();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_leavingCounts && !_awaitingEnd,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_end());
        },
        child: Material(
          color: IkkiuchiBoardStyle.ground,
          child: LayoutBuilder(builder: (context, box) {
            final room = box.biggest;
            final flow = _flowFor(room);
            final size = flow.scene.layout.size;
            final board = SizedBox(width: size.x, height: size.y, child: IkkiuchiMatchBoard(flow, onEnd: _end, surrender: _leavingCounts));
            return FittedBox(child: room.width >= room.height ? board : RotatedBox(quarterTurns: 1, child: board));
          }),
        ),
      );
}
