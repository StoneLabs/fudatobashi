import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_game.dart';
import '../../domain/ankiren_level.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../debug/ankiren_score_readout.dart';
import '../play/pointer_clock.dart';
import '../sound/sounds.dart';
import 'ankiren_band.dart';
import 'ankiren_card.dart';
import 'ankiren_field_view.dart';
import 'ankiren_results_screen.dart';

/// 暗記練's play screen. A field of [setup]'s size is dealt from [known]
/// and shown face up while its memorise time counts down (or until the
/// player is ready); then every card turns face down and each is asked for
/// by its kimariji, in turn, until all are found or given up ("don't know"),
/// or the game is ended. It ends into [AnkirenResultsScreen].
///
/// Timing follows the swipe deck's contract: a prompt is revealed at the
/// vsync of the first frame showing it, on the pointer-event clock
/// ([PointerClock]), and a tap counts from its pointer-down time. A tap is
/// taken when the finger lifts without having moved, so dragging a zoomed
/// field never takes a card.
///
/// The screen holds its orientation while it is up: portrait, or landscape
/// for the true-scale field. It also keeps the menu music out; both hold
/// while any game is up, so one game replacing another in place (the test
/// game's next deal) never lets go of them in between.
class AnkirenScreen extends StatefulWidget {
  const AnkirenScreen({
    super.key,
    required this.setup,
    required this.known,
    this.tracked = true,
    this.seed,
    this.overlay,
  });

  final AnkirenSetup setup;

  /// The cards the field is dealt from.
  final List<int> known;

  /// False for the developer's test game: nothing is recorded.
  final bool tracked;

  /// Seeds the deal and the order of the prompts; random when null.
  final int? seed;

  /// Drawn over the field (the developer's test game's debug layer).
  final Widget Function(AnkirenGame game, FieldPlacement placement)? overlay;

  @override
  State<AnkirenScreen> createState() => _AnkirenScreenState();
}

/// A finger on a card, until it lifts.
typedef _Press = ({int poemId, Duration at, Offset where});

class _AnkirenScreenState extends State<AnkirenScreen> {
  /// Games up right now (see the class's note on orientation and music).
  static int _live = 0;

  late final Progress _progress;

  /// Read once, so the field cannot change under the player mid-game.
  late final AnkirenSettings _options;
  late final bool _zoom;
  late final AnkirenGame _game;
  final DateTime _startedAt = DateTime.now();

  late final ValueNotifier<Duration> _left = ValueNotifier(widget.setup.memorise);
  final Stopwatch _memorising = Stopwatch()..start();
  Timer? _clock;
  Timer? _pause;

  /// The current prompt is on screen (between prompts the band shows the
  /// card just found or given up).
  bool _promptShown = false;
  ({int poemId, PromptState state})? _last;

  /// A card just given up, rumbling until it turns face up.
  int? _givingUp;

  final Map<int, CardFlash> _flashes = {};
  int _flashSerial = 0;
  final Map<int, _Press> _presses = {};

  bool _ending = false;

  /// Set when handing off to Results, which then owns the music and the
  /// orientation.
  bool _wentToResults = false;

  bool get _landscape => _options.layout == AnkirenLayout.landscape;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _options = _progress.settings.ankiren;
    _zoom = _progress.settings.accessibilityMode && !_landscape;
    final rng = math.Random(widget.seed);
    final field =
        AnkirenDealer.ofPoems().deal(widget.known, widget.setup.perSide, rng, allInMiddle: widget.setup.allInMiddle);
    _game = AnkirenGame(field: field, setup: widget.setup, rng: rng);
    unawaited(SystemChrome.setPreferredOrientations(_landscape
        ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : const [DeviceOrientation.portraitUp]));
    _live++;
    music.leaveMenu();
    unawaited(PointerClock.sync());
    // Counted by the ticks due, not the ones run: a stalled or suspended app
    // skips ticks, never time.
    _clock = Timer.periodic(AnkirenPlayTuning.clockTick, (timer) {
      final left = widget.setup.memorise - AnkirenPlayTuning.clockTick * timer.tick;
      _left.value = left > Duration.zero ? left : Duration.zero;
      if (left <= Duration.zero) _startRecall();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pause?.cancel();
    _left.dispose();
    // Results let go of the orientation and own the music once handed
    // over to.
    if (--_live == 0 && !_wentToResults) {
      _releaseOrientation();
      music.enterMenu();
    }
    _leave();
    super.dispose();
  }

  /// A ranked game is on and recall has begun: leaving it is a forfeit.
  bool get _forfeitable => widget.tracked && widget.setup.ranked && _game.phase == AnkirenPhase.recall;

  /// The screen is going without End or Results: nothing more happens on
  /// it. A game already played to its end is recorded without Results, a
  /// ranked one still in recall is forfeited, and anything else (free play
  /// midway, memorising) records nothing.
  void _leave() {
    if (_ending) return;
    _ending = true;
    _clock?.cancel();
    _pause?.cancel();
    if (widget.tracked && (_game.phase == AnkirenPhase.done || _forfeitable)) {
      _game.end();
      unawaited(_progress.recordAnkiren(_game, startedAt: _startedAt, meta: _meta));
    }
  }

  static void _releaseOrientation() => unawaited(SystemChrome.setPreferredOrientations(const []));

  Map<String, Object?> get _meta => {'layout': _options.layout.name, 'zoom': _zoom};

  bool get _still => MediaQuery.disableAnimationsOf(context);

  /// The memorise time is up, or the player is [ready] sooner: the field
  /// turns face down and the first prompt follows.
  void _startRecall({bool ready = false}) {
    _clock?.cancel();
    if (!mounted || _game.phase != AnkirenPhase.memorise) return;
    setState(() => _game.startRecall(memorised: ready ? _memorising.elapsed : null));
    playSound(context, Sfx.ankirenFlip);
    _pause = Timer((_still ? Duration.zero : AnkirenMotion.flip) + AnkirenPlayTuning.promptPause, _showPrompt);
  }

  void _showPrompt() {
    if (!mounted || _game.phase != AnkirenPhase.recall) return;
    if (_game.answers.isEmpty) playSound(context, Sfx.ankirenRecall);
    setState(() => _promptShown = true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final asked = _game.current;
      if (!mounted || !_promptShown || asked == null || _game.revealTs != null) return;
      _game.promptRevealed(PointerClock.fromFrame(SchedulerBinding.instance.currentSystemFrameTimeStamp));
      if (_options.prompt == AnkirenPrompt.textAndVoice) unawaited(sounds.playKimarijiVoice(asked));
    });
  }

  void _onDown(int poemId, PointerDownEvent e) =>
      _presses[e.pointer] = (poemId: poemId, at: e.timeStamp, where: e.position);

  void _onUp(PointerUpEvent e) {
    final press = _presses.remove(e.pointer);
    if (press == null || (e.position - press.where).distance > kTouchSlop) return;
    _take(press.poemId, press.at);
  }

  void _take(int poemId, Duration downAt) {
    final haptics = _progress.settings.haptics;
    switch (_game.tap(poemId, downAt)) {
      case TapResult.ignored:
        return;
      case TapResult.wrong:
        playSound(context, Sfx.ankirenWrong);
        if (haptics) unawaited(HapticFeedback.heavyImpact());
        setState(() => _flashes[poemId] = CardFlash(CardFeedback.wrong, ++_flashSerial));
      case TapResult.right:
        playSound(context, Sfx.ankirenTake);
        if (haptics) unawaited(HapticFeedback.lightImpact());
        setState(() {
          _flashes[poemId] = CardFlash(CardFeedback.right, ++_flashSerial);
          _promptShown = false;
          _last = (poemId: poemId, state: PromptState.found);
        });
        _next();
    }
  }

  /// "Don't know": the card asked for is shown as after the wrong taps, then
  /// turns face up, and the next one is asked.
  void _giveUp() {
    final poemId = _game.giveUp();
    if (poemId == null) return;
    setState(() {
      _promptShown = false;
      _last = (poemId: poemId, state: PromptState.givenUp);
      _givingUp = poemId;
    });
    _pause = Timer(AnkirenPlayTuning.givenUpReveal, () {
      if (!mounted) return;
      setState(() => _givingUp = null);
      _next();
    });
  }

  /// After a card is taken or given up: the next prompt, or Results.
  void _next() => _pause = _game.phase == AnkirenPhase.done
      ? Timer(AnkirenPlayTuning.finishPause, _finish)
      : Timer(AnkirenPlayTuning.promptPause, _showPrompt);

  /// End, or the back gesture: before recall nothing has been played, so it
  /// just leaves; after, the cards not found yet count as missed, and a
  /// ranked game asks first, as it is a forfeit.
  Future<void> _end() async {
    if (_ending) return;
    if (_game.phase == AnkirenPhase.memorise) {
      Navigator.of(context).pop();
      return;
    }
    if (_forfeitable && !await _confirmLeave()) return;
    if (_ending || !mounted) return;
    _game.end();
    unawaited(_finish());
  }

  Future<bool> _confirmLeave() async {
    final s = S.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(s.ankirenLeaveTitle),
        content: Text(s.ankirenLeaveNote),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.ankirenLeave)),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _finish() async {
    if (_ending || !mounted) return;
    _ending = true;
    _pause?.cancel();
    final report =
        widget.tracked ? await _progress.recordAnkiren(_game, startedAt: _startedAt, meta: _meta) : null;
    // Left meanwhile: its route is on its way out, and replacing "the
    // current route" would replace the one under it.
    if (!mounted || ModalRoute.isCurrentOf(context) == false) return;
    _wentToResults = true;
    _releaseOrientation();
    unawaited(Navigator.of(context).pushReplacement(MangaRoute<void>(
      builder: (_) => AnkirenResultsScreen(game: _game, report: report, tracked: widget.tracked),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final memorising = _game.phase == AnkirenPhase.memorise;
    final asked = _promptShown ? _game.current : null;
    final last = _last;
    final voice = _options.prompt == AnkirenPrompt.textAndVoice;
    final settings = _progress.settings;
    final showNumber = settings.showPoemNumber;

    Widget card(int poemId, FieldSide side) => Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _onDown(poemId, e),
          onPointerUp: _onUp,
          onPointerCancel: (e) => _presses.remove(e.pointer),
          child: AnkirenCard(
            key: ValueKey(poemId),
            poemId: poemId,
            faceUp: memorising || (_game.isDone(poemId) && _givingUp != poemId),
            inverted: side == FieldSide.opponent,
            showNumber: showNumber,
            flash: _flashes[poemId],
            revealed: (asked == poemId && _game.revealed) || _givingUp == poemId,
          ),
        );

    final shown = asked ?? last?.poemId;
    final band = AnkirenBand(
      landscape: _landscape,
      leading: BandButton(icon: IconArt.end, label: s.end, onTap: _ending ? null : () => unawaited(_end())),
      center: memorising
          ? MemoriseClock(left: _left, landscape: _landscape)
          : Row(mainAxisSize: MainAxisSize.min, children: [
              PromptText(
                text: shown == null ? null : kimarijiFor(context, shown),
                state: asked != null || last == null ? PromptState.asked : last.state,
                done: _game.answers.length,
                total: _game.prompts.length,
                landscape: _landscape,
              ),
              if (voice && asked != null) KimarijiSpeakerButton(poemId: asked),
            ]),
      trailing: memorising
          ? BandButton(icon: IconArt.arrow, label: s.ankirenReady, color: Palette.sun, onTap: () => _startRecall(ready: true))
          : BandButton(icon: IconArt.question, label: s.ankirenDontKnow, onTap: asked == null ? null : _giveUp),
    );

    final overlay = widget.overlay;
    final Widget field = AnkirenFieldView(
      field: _game.field,
      landscape: _landscape,
      zoom: _zoom,
      card: card,
      band: band,
      overlay: overlay == null ? null : (placement) => overlay(_game, placement),
    );
    final screen = Scaffold(
      backgroundColor: AnkirenPlayLayout.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AnkirenPlayLayout.tatami),
            repeat: ImageRepeat.repeat,
            scale: AnkirenPlayLayout.tatamiScale,
          ),
        ),
        child: SafeArea(
          child: settings.debugMode && settings.playOverlay ? _withReadout(field) : field,
        ),
      ),
    );
    return PopScope(
      canPop: !_forfeitable,
      onPopInvokedWithResult: (didPop, _) => didPop ? _leave() : unawaited(_end()),
      child: screen,
    );
  }

  /// [field] with dev mode's scoring readout in room of its own, above it
  /// in portrait and beside it in landscape, so it never hides a card.
  Widget _withReadout(Widget field) {
    final readout = Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.section, Gaps.small, Gaps.section, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: AnkirenScoreReadout(game: _game, split: !_landscape),
        ),
      ),
    );
    return _landscape
        ? Row(children: [
            SizedBox(width: AnkirenPlayLayout.readoutColumn, child: readout),
            Expanded(child: field),
          ])
        : Column(children: [
            SizedBox(height: AnkirenPlayLayout.readoutStrip, child: readout),
            Expanded(child: field),
          ]);
  }
}
