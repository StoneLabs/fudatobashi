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
import '../../domain/ankiren_geometry.dart';
import '../../domain/ankiren_level.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../play/pointer_clock.dart';
import '../sound/sounds.dart';
import 'ankiren_band.dart';
import 'ankiren_card.dart';
import 'ankiren_field_view.dart';
import 'ankiren_results_screen.dart';

/// 暗記練's play screen. A field of [setup]'s size is dealt from [known]
/// and shown face up while its memorise time counts down (or until the
/// player is ready); then every card turns face down and each is asked for
/// by its kimariji, in turn, until all are found or the game is ended. It
/// ends into [AnkirenResultsScreen].
///
/// Timing follows the swipe deck's contract: a prompt is revealed at the
/// vsync of the first frame showing it, on the pointer-event clock
/// ([PointerClock]), and a tap counts from its pointer-down time. A tap is
/// taken when the finger lifts without having moved, so dragging a zoomed
/// field never takes a card.
///
/// The screen holds its orientation while it is up: portrait, or landscape
/// for the true-scale field.
class AnkirenScreen extends StatefulWidget {
  const AnkirenScreen({super.key, required this.setup, required this.known, this.tracked = true, this.seed});

  final AnkirenSetup setup;

  /// The cards the field is dealt from.
  final List<int> known;

  /// False for the developer's test game: nothing is recorded.
  final bool tracked;

  /// Seeds the deal and the order of the prompts; random when null.
  final int? seed;

  @override
  State<AnkirenScreen> createState() => _AnkirenScreenState();
}

/// A finger on a card, until it lifts.
typedef _Press = ({int poemId, Duration at, Offset where});

class _AnkirenScreenState extends State<AnkirenScreen> {
  late final Progress _progress;

  /// Read once, so the field cannot change under the player mid-game.
  late final AnkirenSettings _options;
  late final AnkirenGame _game;
  late final FieldGeometry _geometry;
  final DateTime _startedAt = DateTime.now();

  late final ValueNotifier<Duration> _left = ValueNotifier(widget.setup.memorise);
  Timer? _clock;
  Timer? _pause;

  /// The current prompt is on screen (between prompts the band shows the
  /// card just found).
  bool _promptShown = false;
  int? _lastFound;

  final Map<int, CardFlash> _flashes = {};
  int _flashSerial = 0;
  final Map<int, _Press> _presses = {};

  bool _ending = false;

  /// Set when handing off to Results, which then owns the music.
  bool _wentToResults = false;

  bool get _landscape => _options.layout == AnkirenLayout.landscape;

  @override
  void initState() {
    super.initState();
    _progress = ProgressScope.read(context);
    _options = _progress.settings.ankiren;
    final rng = math.Random(widget.seed);
    final field = AnkirenDealer.ofPoems().deal(widget.known, widget.setup.perSide, rng);
    _game = AnkirenGame(field: field, setup: widget.setup, rng: rng);
    _geometry = FieldGeometry.of(field, folded: !_landscape);
    unawaited(SystemChrome.setPreferredOrientations(_landscape
        ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
        : const [DeviceOrientation.portraitUp]));
    music.leaveMenu();
    unawaited(PointerClock.sync());
    _clock = Timer.periodic(AnkirenPlayTuning.clockTick, (_) {
      _left.value -= AnkirenPlayTuning.clockTick;
      if (_left.value <= Duration.zero) _startRecall();
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pause?.cancel();
    _left.dispose();
    _releaseOrientation();
    if (!_wentToResults) music.enterMenu();
    // Safety net for an unexpected pop (e.g. the system back gesture) once
    // recall has begun: the game still counts, just without Results.
    if (!_ending && widget.tracked && _game.phase == AnkirenPhase.recall) {
      _game.end();
      unawaited(_progress.recordAnkiren(_game, startedAt: _startedAt, meta: _meta));
    }
    super.dispose();
  }

  static void _releaseOrientation() => unawaited(SystemChrome.setPreferredOrientations(const []));

  Map<String, Object?> get _meta => {'layout': _options.layout.name, 'zoom': _options.zoom && !_landscape};

  bool get _still => MediaQuery.disableAnimationsOf(context);

  /// The memorise time is up, or the player is ready: the field turns face
  /// down and the first prompt follows.
  void _startRecall() {
    _clock?.cancel();
    if (!mounted || _game.phase != AnkirenPhase.memorise) return;
    setState(_game.startRecall);
    playSound(context, Sfx.cardAppears);
    _pause = Timer((_still ? Duration.zero : AnkirenMotion.flip) + AnkirenPlayTuning.promptPause, _showPrompt);
  }

  void _showPrompt() {
    if (!mounted || _game.phase != AnkirenPhase.recall) return;
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
        playSound(context, Sfx.ankirenRight);
        if (haptics) unawaited(HapticFeedback.lightImpact());
        setState(() {
          _flashes[poemId] = CardFlash(CardFeedback.right, ++_flashSerial);
          _promptShown = false;
          _lastFound = poemId;
        });
        _pause = _game.phase == AnkirenPhase.done
            ? Timer(AnkirenPlayTuning.finishPause, _finish)
            : Timer(AnkirenPlayTuning.promptPause, _showPrompt);
    }
  }

  /// End: before recall nothing has been played, so it just leaves; after,
  /// the cards not found yet count as missed.
  void _end() {
    if (_ending) return;
    if (_game.phase == AnkirenPhase.memorise) {
      Navigator.of(context).pop();
      return;
    }
    _game.end();
    unawaited(_finish());
  }

  Future<void> _finish() async {
    if (_ending || !mounted) return;
    _ending = true;
    _pause?.cancel();
    final report =
        widget.tracked ? await _progress.recordAnkiren(_game, startedAt: _startedAt, meta: _meta) : null;
    if (!mounted) return;
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
    final shown = asked ?? _lastFound;
    final voice = _options.prompt == AnkirenPrompt.textAndVoice;
    final showNumber = _progress.settings.showPoemNumber;

    Widget card(int poemId, FieldSide side) => Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _onDown(poemId, e),
          onPointerUp: _onUp,
          onPointerCancel: (e) => _presses.remove(e.pointer),
          child: AnkirenCard(
            key: ValueKey(poemId),
            poemId: poemId,
            faceUp: memorising || _game.isFound(poemId),
            inverted: side == FieldSide.opponent && !_options.opponentUpright,
            showNumber: showNumber,
            flash: _flashes[poemId],
            revealed: asked == poemId && _game.revealed,
          ),
        );

    final band = AnkirenBand(
      landscape: _landscape,
      leading: BandButton(icon: IconArt.end, label: s.end, onTap: _ending ? null : _end),
      center: memorising
          ? MemoriseClock(left: _left, landscape: _landscape)
          : PromptText(
              text: shown == null ? null : kimarijiFor(context, shown),
              found: asked == null && shown != null,
              done: _game.answers.length,
              total: _game.prompts.length,
              landscape: _landscape,
            ),
      trailing: memorising
          ? BandButton(icon: IconArt.arrow, label: s.ankirenReady, color: Palette.sun, onTap: _startRecall)
          : voice && asked != null
              ? FittedBox(child: KimarijiSpeakerButton(poemId: asked))
              : null,
    );

    return Scaffold(
      backgroundColor: AnkirenPlayLayout.background,
      body: SafeArea(
        child: AnkirenFieldView(
          geometry: _geometry,
          landscape: _landscape,
          zoom: _options.zoom,
          card: card,
          band: band,
        ),
      ),
    );
  }
}
