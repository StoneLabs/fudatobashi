import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/fuda_sets.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/play_session.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../debug/play_overlay.dart';
import '../manga/manga.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';
import '../results/results_screen.dart';
import 'kimariji_chip.dart';
import 'sfx_overlay.dart';
import 'swipe_deck.dart';

/// The play chrome (spec phone 4): a calm paper page, the previous card's
/// kimariji as a speech chip, the n/N counter, coloured SFX around the card,
/// ひとつ前 / 終了, and a don't-remember button when that is the don't-know
/// input. Ends into [ResultsScreen] once there is at least one
/// attempt; 終了 with none goes straight back.
///
/// Each of [newPoems] is introduced with its pages right before its first
/// appearance. Play stops meanwhile: the card stays blank under the pages
/// and is revealed only once they are gone, and the break is left out of
/// the run's total.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.cards, required this.config, this.newPoems = const {}});

  final List<CardRef> cards;
  final PlayConfig config;
  final Set<int> newPoems;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final PlaySession _session = PlaySession(widget.cards);
  final DateTime _startedAt = DateTime.now();
  final _sfxKey = GlobalKey<SfxOverlayState>();
  final _deckKey = GlobalKey<SwipeDeckState>();
  Duration? _dontKnowDownTs;
  final Set<Attempt> _requeuedForTraining = {};
  final _rng = math.Random();
  bool _live = false;
  bool _ending = false;

  /// New cards not introduced yet, and those introduced this run.
  late final Set<int> _toIntroduce = {...widget.newPoems};
  final Set<int> _introduced = {};

  /// The current card's introduction while it is on screen, and the frame
  /// after it is gone (see [_endIntro]).
  List<Celebration>? _intro;
  bool _resuming = false;

  /// Kept for [dispose], where the scope can no longer be looked up.
  late final Progress _progress;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _session.addListener(_onSessionChanged);
    _introduceIfNew();
    if (_progress.settings.leadIn) {
      Future.delayed(SwipeTuning.leadIn, () {
        if (mounted) setState(() => _live = true);
      });
    } else {
      _live = true;
    }
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    // Safety net for an unexpected pop (e.g. the system back gesture): still
    // record a partial run, just without showing results for it.
    if (!_ending && _session.attempts.isNotEmpty) {
      unawaited(_progress.recordRun(_session, widget.config, _startedAt));
    }
    super.dispose();
  }

  void _onSessionChanged() {
    if (_session.finished && !_ending) unawaited(_finish());
    _introduceIfNew();
    setState(() {});
  }

  /// Stops play for the current card's introduction on its first appearance.
  void _introduceIfNew() {
    final card = _session.current;
    if (_intro != null || card == null || !_toIntroduce.remove(card.poemId)) return;
    _session.takeBreak();
    _intro = introductionOf(card.poemId, knows: _knows);
    _introduced.add(card.poemId);
  }

  /// The introduction is gone: the card is revealed a frame later, so the
  /// frame that reveals it does nothing else.
  void _endIntro() {
    setState(() {
      _intro = null;
      _resuming = true;
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _resuming = false);
    });
  }

  /// The player knows [poemId]: met in an earlier run or introduced in this one.
  bool _knows(int poemId) => _introduced.contains(poemId) || _progress.knows(poemId);

  void _onCommitted(Attempt a) {
    if (ProgressScope.read(context).settings.sfxEffects) {
      final dontKnow = a.outcome == Outcome.dontKnow;
      if (dontKnow || _isFastCard(a)) _sfxKey.currentState?.pop(dontKnow: dontKnow);
    }
    if (a.isMiss) _requeueMiss(a);
  }

  /// A correct card only earns its SFX pop when it beats a speed baseline:
  /// the card's own average once it has enough history, else this run's
  /// average so far. Keeps the celebration for a snappy answer, not every one.
  bool _isFastCard(Attempt a) {
    final cardStats = ProgressScope.read(context).stats(ItemKey(a.card.poemId, a.card.inverted));
    final baseline = cardStats.timed.length >= PlaySfxTuning.minCardSamplesForBaseline
        ? cardStats.ewmaMs
        : _sessionAverageMs();
    return baseline != null && a.responseUs / 1000 <= baseline * PlaySfxTuning.fastRatio;
  }

  double? _sessionAverageMs() {
    final prior = _session.attempts.take(_session.attempts.length - 1).where((x) => !x.isMiss && !x.tainted);
    if (prior.isEmpty) return null;
    return prior.map((x) => x.responseUs / 1000).reduce((a, b) => a + b) / prior.length;
  }

  void _toggleWrong() {
    _session.togglePreviousWrong();
    final a = _session.lastAttempt;
    if (a != null && a.wrong) _requeueMiss(a);
  }

  /// Training only: brings a missed card back soon, plus one 友札 the player
  /// knows (never a new card ahead of its introduction).
  void _requeueMiss(Attempt a) {
    if (widget.config.mode != PlayMode.training || !_requeuedForTraining.add(a)) return;
    _session.requeue(a.card);
    final twins = fudaSets.tomofuda(a.card.poemId).where(_knows).toList();
    if (twins.isNotEmpty) _session.requeue(CardRef(twins[_rng.nextInt(twins.length)]));
  }

  void _markDontKnow() {
    final ts = _dontKnowDownTs;
    if (ts != null) _deckKey.currentState?.markDontKnow(ts);
  }

  Future<void> _end() async {
    if (_ending) return;
    if (_session.attempts.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_ending) return;
    _ending = true;
    final report = await ProgressScope.read(context).recordRun(_session, widget.config, _startedAt);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MangaRoute<void>(
      builder: (_) => ResultsScreen(report: report, config: widget.config),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final settings = progress.settings;
    final dontKnowInput = settings.dontKnowInputFor(progress.trainer.config.learningMode);
    final dontKnowButton = dontKnowInput == DontKnowInput.button;
    final session = _session;
    final last = session.lastAttempt;
    final chipText = last == null ? s.start : poems[last.card.poemId].kimariji;
    final buttonRows = dontKnowButton ? 2 : 1;
    final buttonsBottom =
        PlayLayout.buttonRowHeight * buttonRows + PlayLayout.buttonGap * (buttonRows - 1) + Gaps.section * 2;
    final live = _live && _intro == null && !_resuming;

    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(children: [
        SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: PlayLayout.toneBandHeight,
                child: const IgnorePointer(
                  child: StaticArt([ToneLayer(Tones.seaFaint, fadeAngle: 180, fadeStops: [0, 1])]),
                ),
              ),
              Positioned.fill(
                bottom: buttonsBottom,
                child: SwipeDeck(
                  key: _deckKey,
                  session: session,
                  live: live,
                  dontKnowInput: dontKnowInput,
                  showNumber: settings.showPoemNumber,
                  haptics: settings.haptics,
                  onCommitted: _onCommitted,
                ),
              ),
              Positioned.fill(bottom: buttonsBottom, child: SfxOverlay(key: _sfxKey)),
              Positioned(
                left: Gaps.gutter,
                right: Gaps.gutter,
                top: Gaps.section,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Shrinks rather than running into the counter at large
                  // font scales.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: KimarijiChip(
                        text: chipText,
                        timeMs: last == null ? null : last.responseUs / 1000,
                        wrong: last?.isMiss ?? false,
                        onTap: last == null ? null : _toggleWrong,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gaps.panel),
                  _Counter(n: math.min(session.index + 1, session.cards.length), total: session.cards.length),
                ]),
              ),
              Positioned(
                left: Gaps.gutter,
                right: Gaps.gutter,
                bottom: Gaps.section,
                child: Column(children: [
                  if (dontKnowButton) ...[
                    SizedBox(
                      height: PlayLayout.buttonRowHeight,
                      child: Listener(
                        onPointerDown: (e) => _dontKnowDownTs = e.timeStamp,
                        child: ActionRowButton(
                          icon: IconArt.question,
                          label: s.dontRemember,
                          sub: "DON'T REMEMBER",
                          color: Palette.pinkSoft,
                          onTap: live && !_ending ? _markDontKnow : null,
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
                          onTap: session.attempts.isEmpty ? null : session.undo,
                        ),
                      ),
                      const SizedBox(width: PlayLayout.buttonGap),
                      Expanded(
                        child: ActionRowButton(icon: IconArt.end, label: s.end, sub: 'END', onTap: _ending ? null : _end),
                      ),
                    ]),
                  ),
                ]),
              ),
              if (settings.debugMode && settings.playOverlay)
                Positioned(bottom: buttonsBottom + Gaps.section, left: Gaps.section, child: PlayDebugOverlay(session: session)),
            ],
          ),
        ),
        if (_intro != null)
          Positioned.fill(
            child: CelebrationSequence(
              key: ObjectKey(_intro),
              pages: _intro!,
              onDone: _endIntro,
            ),
          ),
      ]),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.n, required this.total});
  final int n, total;

  @override
  Widget build(BuildContext context) => Container(
        height: PlayLayout.counterHeight,
        padding: PlayLayout.counterPadding,
        decoration: const BoxDecoration(color: Palette.paper, border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.control))),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          OutlinedText(
            '$n',
            style: const TextStyle(fontFamily: Fonts.display, fontSize: PlayLayout.counterNumberFont, color: Palette.pink, height: 1),
            outline: Palette.ink,
            outlineWidth: PlayLayout.counterOutline,
          ),
          const SizedBox(width: PlayLayout.counterGap),
          Text('/ $total', style: const TextStyle(fontFamily: Fonts.display, fontSize: PlayLayout.counterSlashFont, height: 1)),
        ]),
      );
}
