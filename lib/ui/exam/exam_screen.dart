import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/play_session.dart';
import '../../domain/ranked.dart';
import '../../l10n/exam_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../play/kimariji_chip.dart';
import '../play/pointer_clock.dart';
import '../play/sfx_overlay.dart';
import '../play/swipe_deck.dart';
import '../results/results_screen.dart';
import '../sound/sounds.dart';
import 'exam_board.dart';
import 'exam_lost_screen.dart';
import 'exam_opening.dart';
import 'exam_sheets.dart';

/// 卒業試験: all 100 cards against Tobi, who plays the top half of the
/// screen at [tobi]'s pace while the player plays the bottom half.
///
/// It opens on Tobi's よろしくお願いします and a count of three; at GO the
/// player's first card is revealed and both clocks start. Every miss, card
/// marked wrong or undone swipe adds [ExamTuning.missPenaltyMs] to the
/// player's clock. The player loses the moment that clock reaches Tobi's
/// time, or by leaving, and goes on to [ExamLostScreen]; finishing first
/// passes the exam, and [ResultsScreen] celebrates the graduation.
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.cards, required this.tobi});

  final List<CardRef> cards;
  final TobiPace tobi;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

enum _Race { opening, on, won, lost }

class _ExamScreenState extends State<ExamScreen> with SingleTickerProviderStateMixin {
  static const _config = PlayConfig(mode: PlayMode.exam);

  /// The opening's sounds, at their times since the screen opened.
  static final _cues = [
    (Sfx.cardAppears, ExamMotion.greetingFirst.delay),
    for (var k = 0; k < ExamMotion.count; k++) (Sfx.ratingTick, ExamMotion.greeting + ExamMotion.beat * k),
    (Sfx.stamp, ExamMotion.start),
  ];

  late final PlaySession _session = PlaySession(widget.cards);

  /// Tobi plays the same cards in another order.
  late final List<CardRef> _tobiCards = widget.cards.reversed.toList();
  late final Ticker _ticker = createTicker(_tick);
  final _deckKey = GlobalKey<SwipeDeckState>();
  final _sfxKey = GlobalKey<SfxOverlayState>();

  /// Time since the screen opened, and the race's time since GO, held once
  /// the race is decided.
  final _sinceOpen = ValueNotifier(Duration.zero);
  final _race = ValueNotifier(Duration.zero);
  Duration _goAt = Duration.zero;
  int _cue = 0;

  _Race _state = _Race.opening;
  DateTime _startedAt = DateTime.now();
  int _misses = 0;

  /// Penalties so far, each one's "+10 s" sent up once.
  int _pops = 0;
  Duration? _dontKnowDownTs;
  bool _left = false;
  bool _ending = false;

  /// Handed off to the next screen, which then sees to the music.
  bool _handedOff = false;

  /// Kept for [dispose], where the scope can no longer be looked up.
  late final Progress _progress;

  Duration get _penalty => Duration(milliseconds: _misses * ExamTuning.missPenaltyMs);

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _session.addListener(_onSessionChanged);
    music.leaveMenu();
    unawaited(PointerClock.sync());
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _session.removeListener(_onSessionChanged);
    _sinceOpen.dispose();
    _race.dispose();
    if (!_handedOff) music.enterMenu();
    // Safety net for an unexpected pop: the try is still recorded.
    if (!_ending && _session.attempts.isNotEmpty) {
      unawaited(_progress.recordRun(_session, _config, _startedAt, tobi: widget.tobi.total));
    }
    super.dispose();
  }

  void _tick(Duration elapsed) {
    _sinceOpen.value = elapsed;
    while (_cue < _cues.length && elapsed >= _cues[_cue].$2) {
      playSound(context, _cues[_cue++].$1);
    }
    switch (_state) {
      case _Race.opening:
        if (elapsed >= ExamMotion.start) _go(elapsed);
      case _Race.on:
        _race.value = elapsed - _goAt;
        _checkTime();
      case _Race.won || _Race.lost:
        break;
    }
  }

  /// GO: the first card is revealed and both clocks start.
  void _go(Duration at) {
    _goAt = at;
    _startedAt = DateTime.now();
    setState(() => _state = _Race.on);
  }

  /// The player's clock with penalties has caught up with Tobi's time.
  void _checkTime() {
    if (_state == _Race.on && _race.value + _penalty >= widget.tobi.total) unawaited(_end(won: false));
  }

  void _onSessionChanged() {
    final misses = RankedScore.missesOf(_session);
    if (misses > _misses) {
      _pops++;
      playSound(context, Sfx.ankirenWrong);
    }
    _misses = misses;
    if (_session.finished) {
      unawaited(_finishRun());
    } else {
      _checkTime();
    }
    setState(() {});
  }

  /// The player's last card is in: their time with penalties against Tobi's.
  Future<void> _finishRun() async {
    if (_state != _Race.on) return;
    final total = _session.total;
    if (total != null) _race.value = total;
    final won =
        total != null && RankedScore.of(_session, total, penaltyMs: ExamTuning.missPenaltyMs).scored < widget.tobi.total;
    await _end(won: won);
  }

  void _onCommitted(Attempt a) {
    playSound(context, Sfx.cardFlick);
    if (a.outcome == Outcome.dontKnow && _progress.settings.sfxEffects) _sfxKey.currentState?.pop(dontKnow: true);
  }

  void _markDontKnow() {
    final ts = _dontKnowDownTs;
    if (ts != null) _deckKey.currentState?.markDontKnow(ts);
  }

  Future<void> _leave() async {
    if (_ending) return;
    if (await confirmExamLeave(context) && mounted) await _end(won: false, left: true);
  }

  /// Stops play where it is, records the try, and after a moment on the
  /// board goes on to the graduation or to Tobi's win.
  Future<void> _end({required bool won, bool left = false}) async {
    if (_ending) return;
    _ending = true;
    _left = left;
    _ticker.stop();
    setState(() => _state = won ? _Race.won : _Race.lost);
    if (won) playSound(context, Sfx.best);
    final shown = Future<void>.delayed(left ? Duration.zero : (won ? ExamMotion.won : ExamMotion.lost));
    final report = await _progress.recordRun(_session, _config, _startedAt, tobi: widget.tobi.total);
    await shown;
    if (!mounted) return;
    _handedOff = true;
    final Widget next = report.passed
        ? ResultsScreen(report: report, config: _config)
        : ExamLostScreen(
            report: report,
            tobi: widget.tobi.total,
            clock: _race.value,
            misses: _misses,
            done: _session.attempts.length,
            total: _session.cards.length,
          );
    // Also closes the leave sheet, if time ran out while it was up.
    await Navigator.of(context).pushAndRemoveUntil(MangaRoute<void>(builder: (_) => next), (r) => r.isFirst);
  }

  TobiPose _tobiPose(int done) => switch (_state) {
        _Race.opening => TobiPose.fired,
        _Race.on => done >= _session.attempts.length ? TobiPose.fired : TobiPose.tryHard,
        _Race.won => TobiPose.shocked,
        _Race.lost => TobiPose.cheering,
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final settings = progress.settings;
    final dontKnowInput = settings.dontKnowInputFor(progress.trainer.config.learningMode);
    final last = _session.lastAttempt;
    final playing = _state == _Race.on;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: Palette.paper,
        body: Stack(children: [
          SafeArea(
            child: Column(children: [
              Expanded(
                flex: ExamLayout.tobiFlex,
                child: TobiSide(pace: widget.tobi, cards: _tobiCards, race: _race, pose: _tobiPose),
              ),
              Scoreboard(
                pace: widget.tobi,
                race: _race,
                done: _session.attempts.length,
                total: _session.cards.length,
                penalty: _penalty,
              ),
              Expanded(
                flex: ExamLayout.playerFlex,
                child: Column(children: [
                  Padding(
                    padding: ExamLayout.chipRow,
                    child: Row(children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: KimarijiChip(
                              text: last == null ? s.start : kimarijiFor(context, last.card.poemId),
                              timeMs: last == null || !last.validTime ? null : last.responseUs / 1000,
                              wrong: last?.isMiss ?? false,
                              onTap: last == null || !playing ? null : _session.togglePreviousWrong,
                            ),
                          ),
                        ),
                      ),
                      if (_pops > 0) PenaltyPop(key: ValueKey(_pops)),
                    ]),
                  ),
                  Expanded(
                    child: Stack(children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !playing,
                          child: SwipeDeck(
                            key: _deckKey,
                            session: _session,
                            live: playing,
                            dontKnowInput: dontKnowInput,
                            showNumber: settings.showPoemNumber,
                            haptics: settings.haptics,
                            onCommitted: _onCommitted,
                          ),
                        ),
                      ),
                      Positioned.fill(child: SfxOverlay(key: _sfxKey)),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Gaps.gutter, Gaps.section, Gaps.gutter, Gaps.section),
                child: Column(children: [
                  if (dontKnowInput == DontKnowInput.button) ...[
                    SizedBox(
                      height: PlayLayout.buttonRowHeight,
                      child: Listener(
                        onPointerDown: (e) => _dontKnowDownTs = e.timeStamp,
                        child: ActionRowButton(
                          icon: IconArt.question,
                          label: s.dontRemember,
                          sub: "DON'T REMEMBER",
                          color: Palette.pinkSoft,
                          onTap: playing ? _markDontKnow : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: PlayLayout.buttonGap),
                  ],
                  SizedBox(
                    height: PlayLayout.buttonRowHeight,
                    child: Row(children: [
                      Expanded(
                        child: ActionRowButton(
                          icon: IconArt.undo,
                          label: s.undo,
                          sub: 'UNDO',
                          onTap: playing && _session.attempts.isNotEmpty ? _session.undo : null,
                        ),
                      ),
                      const SizedBox(width: PlayLayout.buttonGap),
                      Expanded(
                        child: ActionRowButton(icon: IconArt.end, label: s.end, sub: 'END', onTap: _ending ? null : _leave),
                      ),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          if (_state == _Race.opening || _state == _Race.on) Positioned.fill(child: ExamOpening(clock: _sinceOpen)),
          if (_state == _Race.won) Positioned.fill(child: ExamShout(s.examWinShout)),
          if (_state == _Race.lost && !_left) Positioned.fill(child: ExamShout(s.examTimeUpShout)),
        ]),
      ),
    );
  }
}
