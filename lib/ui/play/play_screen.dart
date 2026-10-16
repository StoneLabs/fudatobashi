import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/fuda_sets.dart';
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
import '../run/ranked_sheets.dart';
import '../sound/sounds.dart';
import 'kimariji_chip.dart';
import 'play_hold.dart';
import 'pointer_clock.dart';
import 'sfx_overlay.dart';
import '../tour/tour_anchor.dart';
import '../tour/tour_overlay.dart';
import '../tour/tour_steps.dart';
import '../tour/tutorial_coach.dart';
import 'start_card.dart';
import 'swipe_deck.dart';
import 'test_card.dart';

/// The play chrome (spec phone 4): a calm paper page, the previous card's
/// kimariji as a speech chip, the n/N counter, coloured SFX around the card,
/// ひとつ前 / 終了, and a don't-remember button when that is the don't-know
/// input. Ends into [ResultsScreen] once there is at least one
/// attempt; 終了 with none goes straight back.
///
/// The run starts once its [StartCard] is swiped away, so the first card is
/// timed from its own reveal, not from the screen opening.
///
/// A [planner] replans the run at every swipe (journey's training: a miss
/// comes back in steps); without one, training brings a miss back once.
///
/// Each of [newPoems] is introduced with its pages right before its first
/// appearance. Play stops meanwhile: the card stays blank under the pages
/// and is revealed only once they are gone, and the break is left out of
/// the run's total.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    required this.cards,
    required this.config,
    this.newPoems = const {},
    this.planner,
  })  : tutorial = false,
        firstCard = false,
        onSkip = null;

  /// The tour's practice round: the [TestCard]s, with Tobi coaching each
  /// move below them (see [TutorialScript]), and stopping the round once to
  /// say when to mark a card forgotten. Nothing of it is recorded; it pops
  /// with true once every card is done. [onSkip] skips the whole tour.
  PlayScreen.tutorial({super.key, this.onSkip})
      : cards = TestCard.deck,
        config = const PlayConfig(mode: PlayMode.guest),
        newPoems = const {},
        planner = null,
        tutorial = true,
        firstCard = false;

  /// The tour's first real card ([TourTuning.firstCard]), see
  /// `playFirstCard`: Tobi points out its new card screen, coaches the
  /// swipe, then talks about honesty, and the screen pops with true. The
  /// swipe is a training round only when [record], else nothing is kept.
  /// [onSkip] skips the whole tour.
  PlayScreen.firstCard({super.key, required bool record, this.onSkip})
      : cards = const [CardRef(TourTuning.firstCard)],
        config = PlayConfig(mode: record ? PlayMode.training : PlayMode.guest),
        newPoems = const {TourTuning.firstCard},
        planner = null,
        tutorial = false,
        firstCard = true;

  final List<CardRef> cards;
  final PlayConfig config;
  final Set<int> newPoems;
  final RunPlanner? planner;
  final bool tutorial;
  final bool firstCard;
  final VoidCallback? onSkip;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with PlayHold<PlayScreen> {
  late final PlaySession _session = PlaySession(widget.cards, planner: widget.planner);
  DateTime _startedAt = DateTime.now();
  final _sfxKey = GlobalKey<SfxOverlayState>();
  final _deckKey = GlobalKey<SwipeDeckState>();
  Duration? _dontKnowDownTs;
  final Set<Attempt> _requeuedForTraining = {};
  final _rng = math.Random();

  /// The start card is gone.
  bool _started = false;
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
  PlaySession get heldSession => _session;

  /// The tutorial's plan, and the move a card just came back for.
  TutorialScript? _script;
  Outcome? _retried;

  /// Tobi's stops in the tutorial and on the first card: their spots, and
  /// which are up.
  final _tourKeys = TourKeys();
  bool _forgetTour = false;
  bool _forgetExplained = false;
  bool _introTour = false;
  bool _honesty = false;
  Timer? _introSettle;
  Timer? _forgetPause;

  /// Set just before handing off to [ResultsScreen], which then owns the
  /// music itself (silent through its celebration, if any). Every other way
  /// this screen leaves goes back to a menu, so [dispose] fades music in.
  bool _wentToResults = false;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    if (widget.tutorial) {
      _script = TutorialScript(_progress.settings.dontKnowInputFor(_progress.trainer.config.learningMode));
    }
    _session.addListener(_onSessionChanged);
    music.leaveMenu();
    unawaited(PointerClock.sync());
  }

  @override
  void dispose() {
    _introSettle?.cancel();
    _forgetPause?.cancel();
    _session.removeListener(_onSessionChanged);
    if (!_wentToResults) music.enterMenu();
    // Safety net for an unexpected pop: still record a partial run (a ranked
    // one as a forfeit), just without showing results for it.
    if (!_ending && !widget.tutorial && (_session.attempts.isNotEmpty || (_ranked && _started))) {
      unawaited(_progress.recordRun(_session, widget.config, _startedAt));
    }
    super.dispose();
  }

  void _onSessionChanged() {
    if (_started) _journal();
    if (_session.finished && !_ending) unawaited(_finish());
    _introduceIfNew();
    setState(() {});
  }

  void _onStarted() {
    playSound(context, Sfx.cardFlick);
    setState(() {
      _started = true;
      _startedAt = DateTime.now();
      _introduceIfNew();
    });
    _journal();
  }

  void _journal() => unawaited(_progress.journalRun(_session, widget.config, _startedAt));

  /// A ranked run: leaving it once started is a forfeit.
  bool get _ranked => widget.config.mode == PlayMode.ranked;

  /// Stops play for the current card's introduction on its first appearance.
  void _introduceIfNew() {
    final card = _session.current;
    if (!_started || _intro != null || card == null || !_toIntroduce.remove(card.poemId)) return;
    _session.takeBreak();
    _intro = introductionOf(card.poemId, knows: _knows);
    _introduced.add(card.poemId);
    if (widget.firstCard) {
      _introSettle = Timer(TourTuning.newCardSettle, () {
        if (mounted) setState(() => _introTour = true);
      });
    }
  }

  /// The introduction is gone: the card is revealed a frame later, so the
  /// frame that reveals it does nothing else.
  void _endIntro() {
    setState(() {
      _intro = null;
      _introTour = false;
      _resuming = true;
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _resuming = false);
    });
  }

  /// The player knows [poemId]: met in an earlier run or introduced in this one.
  bool _knows(int poemId) => _introduced.contains(poemId) || _progress.knows(poemId);

  void _onCommitted(Attempt a) {
    playSound(context, Sfx.cardFlick);
    if (_coachSendsBack(a)) return;
    if ((_script?.explainsForgettingAfter(a.index) ?? false) && !_forgetExplained) {
      _forgetExplained = true;
      _forgetPause = Timer(TutorialTuning.forgetPause, () {
        if (mounted) setState(() => _forgetTour = true);
      });
    }
    if (ProgressScope.read(context).settings.sfxEffects) {
      final dontKnow = a.outcome == Outcome.dontKnow;
      if (dontKnow || widget.tutorial || _isFastCard(a)) _sfxKey.currentState?.pop(dontKnow: dontKnow);
    }
    if (a.isMiss) _requeueMiss(a);
  }

  /// Tutorial: a card that left the wrong way comes back for another go.
  bool _coachSendsBack(Attempt a) {
    final script = _script;
    if (script == null) return false;
    final expected = script.expected(a.index);
    final wrong = expected != null && a.outcome != expected;
    setState(() => _retried = wrong ? a.outcome : null);
    if (wrong) _session.undo();
    return wrong;
  }

  /// A correct card only earns its SFX pop when it beats a speed baseline:
  /// the card's own average once it has enough history, else this run's
  /// average so far. Keeps the celebration for a snappy answer, not every one.
  bool _isFastCard(Attempt a) {
    if (!a.validTime) return false;
    final cardStats = ProgressScope.read(context).stats(ItemKey(a.card.poemId, a.card.inverted));
    final baseline = cardStats.timed.length >= PlaySfxTuning.minCardSamplesForBaseline
        ? cardStats.ewmaMs
        : _sessionAverageMs();
    return baseline != null && a.cardUs / 1000 <= baseline * PlaySfxTuning.fastRatio;
  }

  double? _sessionAverageMs() {
    final prior =
        _session.attempts.take(_session.attempts.length - 1).where((x) => !x.isMiss && !x.tainted && x.validTime);
    if (prior.isEmpty) return null;
    return prior.map((x) => x.cardUs / 1000).reduce((a, b) => a + b) / prior.length;
  }

  void _toggleWrong() {
    _session.togglePreviousWrong();
    final a = _session.lastAttempt;
    if (a != null && a.wrong) _requeueMiss(a);
  }

  /// Training without a planner: brings a missed card back soon, plus one
  /// 友札 the player knows (never a new card ahead of its introduction).
  void _requeueMiss(Attempt a) {
    if (widget.config.mode != PlayMode.training ||
        widget.planner != null ||
        widget.firstCard ||
        !_requeuedForTraining.add(a)) {
      return;
    }
    _session.requeue(a.card);
    final twins = fudaSets.tomofuda(a.card.poemId).where(_knows).toList();
    if (twins.isNotEmpty) _session.requeue(CardRef(twins[_rng.nextInt(twins.length)]));
  }

  /// Skip on a tutorial or first card stop: out of the round and the whole
  /// tour. A first card swipe already made is recorded by then.
  void _skipTour() {
    Navigator.of(context).pop();
    widget.onSkip?.call();
  }

  void _markDontKnow() {
    final ts = _dontKnowDownTs;
    if (ts != null) _deckKey.currentState?.markDontKnow(ts);
  }

  Future<void> _end() async {
    if (_ending) return;
    if (_ranked && _started && !_session.finished) {
      if (await holdFor(() => confirmForfeit(context)) && mounted) await _finish();
      return;
    }
    if (_session.attempts.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    if (_ending) return;
    _ending = true;
    if (widget.tutorial) {
      if (!_session.finished) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {});
      await Future<void>.delayed(TutorialTuning.doneLinger);
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    if (widget.firstCard) {
      if (!_session.finished) {
        Navigator.of(context).pop();
        return;
      }
      await _progress.recordRun(_session, widget.config, _startedAt);
      if (mounted) setState(() => _honesty = true);
      return;
    }
    final progress = ProgressScope.read(context);
    final report = await progress.recordRun(_session, widget.config, _startedAt);
    if (!mounted) return;
    _wentToResults = true;
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
    final chipText = last == null
        ? s.start
        : widget.tutorial
            ? TestCard.kanaOf(last.card)
            : kimarijiFor(context, last.card.poemId);
    final script = _script;
    final buttonRows = dontKnowButton ? 2 : 1;
    final buttonsBottom =
        PlayLayout.buttonRowHeight * buttonRows + PlayLayout.buttonGap * (buttonRows - 1) + Gaps.section * 2;
    final live = _started && _intro == null && !_resuming && !held && !_forgetTour;

    return PopScope(
      // Mid-round the tutorial holds you to its gestures; only before the
      // start card is swiped can back leave it.
      canPop: !(widget.tutorial || widget.firstCard || _ranked) || !_started,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _ranked) unawaited(_end());
      },
      child: Scaffold(
        backgroundColor: Palette.paper,
        body: TourAnchors(
          keys: _tourKeys,
          child: Stack(children: [
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
                    child: Column(children: [
                      Expanded(
                        child: SwipeDeck(
                          key: _deckKey,
                          session: session,
                          live: live,
                          dontKnowInput: dontKnowInput,
                          showNumber: settings.showPoemNumber,
                          haptics: settings.haptics,
                          onCommitted: _onCommitted,
                          startCard: StartCard(cue: s.swipeToStart),
                          onStarted: _onStarted,
                          cardFace: widget.tutorial ? (card, text) => TestCard(number: card.poemId, showText: text) : null,
                        ),
                      ),
                      if (script != null)
                        TutorialCoach(
                          line: script.line(
                              started: _started, index: session.index, finished: session.finished, retried: _retried),
                          kana: TestCard.kanaOf(session.current ?? last!.card),
                          onBack: _started ? null : _end,
                        )
                      else if (widget.firstCard && !session.finished)
                        TutorialCoach(
                          line: _started ? CoachLine.firstCard : CoachLine.startCard,
                          kana: kimarijiFor(context, TourTuning.firstCard),
                          onBack: _started ? null : _end,
                        ),
                    ]),
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
                            timeMs: last == null || !last.validTime ? null : last.cardUs / 1000,
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
                        TourAnchor(
                          TourSpot.dontKnow,
                          child: SizedBox(
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
                        ),
                        const SizedBox(height: PlayLayout.buttonGap),
                      ],
                      SizedBox(
                        height: PlayLayout.buttonRowHeight,
                        child: Row(children: [
                          Expanded(
                            child: TourAnchor(
                              TourSpot.undo,
                              child: ActionRowButton(
                                icon: IconArt.undo,
                                label: s.undo,
                                sub: 'UNDO',
                                onTap: session.attempts.isEmpty ? null : session.undo,
                              ),
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
                  if (settings.debugMode && settings.playOverlay && !widget.tutorial)
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
            if (_forgetTour)
              Positioned.fill(
                child: TourOverlay(
                  key: const ValueKey(TourSpot.undo),
                  steps: TourStep.forgetting(dontKnowInput),
                  keys: _tourKeys,
                  onDone: () => setState(() => _forgetTour = false),
                  onSkip: _skipTour,
                ),
              ),
            if (_introTour)
              Positioned.fill(
                child: TourOverlay(
                  key: const ValueKey(TourSpot.newCard),
                  steps: TourStep.newCard(kimarijiFor(context, TourTuning.firstCard)),
                  keys: _tourKeys,
                  onDone: () {
                    playSound(context, Sfx.cardFlick);
                    _endIntro();
                  },
                  onSkip: _skipTour,
                ),
              ),
            if (_honesty)
              Positioned.fill(
                child: TourOverlay(
                  key: const ValueKey(TourSpot.dontKnow),
                  steps: TourStep.honesty(dontKnowInput),
                  keys: _tourKeys,
                  onDone: () => Navigator.of(context).pop(true),
                  onSkip: _skipTour,
                ),
              ),
          ]),
        ),
      ),
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
