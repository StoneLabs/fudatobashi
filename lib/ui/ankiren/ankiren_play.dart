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
import '../../domain/karafuda.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/karafuda_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../../state/settings.dart';
import '../play/pointer_clock.dart';
import '../sound/sounds.dart';
import 'ankiren_band.dart';
import 'ankiren_card.dart';
import 'ankiren_strikes.dart';

/// A finger on a card, until it lifts.
typedef _Press = ({int poemId, Duration at, Offset where});

/// What a play screen shares with 暗記練's ([game]'s field turned face down
/// and each card asked for in turn): the screen held in its orientation and
/// the menu music kept out while it is up ([holdStage]), and the recall
/// itself: the field turning over ([turnFaceDown]), the prompts, the taps
/// on the cards ([recallCard]), "don't know" ([dontKnowButton]), the
/// からふだ button ([karafudaButton]) and the band's prompt
/// ([recallPrompt]). Once every call is answered or given up it calls
/// [recallOver].
///
/// Timing follows the swipe deck's contract: a prompt is revealed at the
/// vsync of the first frame showing it, on the pointer-event clock
/// ([PointerClock]), and a tap counts from its pointer-down time. A tap is
/// taken when the finger lifts without having moved, so dragging a zoomed
/// field never takes a card.
///
/// The orientation and the music hold while any such screen is up, so one
/// game replacing another in place never lets go of them in between.
mixin AnkirenPlay<W extends StatefulWidget> on State<W> {
  /// Screens up right now (see the note on orientation and music).
  static int _live = 0;

  AnkirenGame get game;

  /// The play options, read once, so they cannot change under the player
  /// mid-game.
  late final AnkirenSettings ankirenOptions = ProgressScope.read(context).settings.ankiren;

  /// Set when handing off to Results, which then owns the music and the
  /// orientation.
  bool wentToResults = false;

  /// The current prompt is on screen (between prompts the band shows the
  /// card just found or given up).
  bool _promptShown = false;
  ({int poemId, PromptState state})? _last;

  /// A card just given up, rumbling until it turns face up; a からふだ
  /// given up rumbles the からふだ button.
  int? _givingUp;

  final Map<int, CardFlash> _flashes = {};
  int _flashSerial = 0;
  final Map<int, _Press> _presses = {};
  Timer? _pause;

  /// Every card is found or given up; the screen moves on to Results.
  void recallOver();

  bool get stillMotion => MediaQuery.disableAnimationsOf(context);

  /// The card asked for, once its prompt is on screen.
  int? get asked => _promptShown ? game.current : null;

  /// Holds the screen in [orientations] and keeps the menu music out until
  /// [releaseStage].
  void holdStage(List<DeviceOrientation> orientations) {
    unawaited(SystemChrome.setPreferredOrientations(orientations));
    _live++;
    music.leaveMenu();
    unawaited(PointerClock.sync());
  }

  /// Lets go of the orientation and the music, unless another such screen
  /// or Results holds them.
  void releaseStage() {
    stopRecall();
    if (--_live == 0 && !wentToResults) {
      releaseOrientation();
      music.enterMenu();
    }
  }

  static void releaseOrientation() => unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.app));

  /// Each slot of a landscape band, widened for the strikes beside End or
  /// the からふだ button beside "don't know", whichever is wider, so the
  /// centre stays centred.
  static double landscapeSlot({required bool strikes, required bool karafuda}) {
    final box = AnkirenArt.strikeBack.box;
    const out = AnkirenTuning.strikesOut;
    final strikesWidth = AnkirenPlayLayout.bandGap +
        out * AnkirenPlayLayout.strikeCardLandscape * box.width / box.height +
        (out - 1) * AnkirenPlayLayout.strikeGap;
    const karafudaWidth = AnkirenPlayLayout.bandGap + AnkirenPlayLayout.sideSlot;
    return AnkirenPlayLayout.sideSlot + math.max(strikes ? strikesWidth : 0, karafuda ? karafudaWidth : 0);
  }

  /// [end] with the strikes: under them in portrait, beside them in
  /// [landscape].
  Widget withStrikes(Widget end, {required bool landscape}) {
    final strikes = AnkirenStrikes(
      strikes: game.strikes,
      cardHeight: landscape ? AnkirenPlayLayout.strikeCardLandscape : AnkirenPlayLayout.strikeCardPortrait,
    );
    return landscape
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            end,
            const SizedBox(width: AnkirenPlayLayout.bandGap),
            strikes,
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            strikes,
            const SizedBox(height: AnkirenPlayLayout.strikeRowGap),
            SizedBox(height: AnkirenPlayLayout.strikeButton, child: end),
          ]);
  }

  /// Nothing more of the recall happens.
  void stopRecall() => _pause?.cancel();

  /// The field turns face down, [memorised] as [AnkirenGame.startRecall]
  /// takes it, and the first prompt follows.
  void turnFaceDown({Duration? memorised}) {
    if (!mounted || game.phase != AnkirenPhase.memorise) return;
    setState(() => game.startRecall(memorised: memorised));
    playSound(context, Sfx.ankirenFlip);
    _pause = Timer((stillMotion ? Duration.zero : AnkirenMotion.flip) + AnkirenPlayTuning.promptPause, _showPrompt);
  }

  void _showPrompt() {
    if (!mounted || game.phase != AnkirenPhase.recall) return;
    if (game.answers.isEmpty) playSound(context, Sfx.ankirenRecall);
    setState(() => _promptShown = true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final asked = game.current;
      if (!mounted || !_promptShown || asked == null || game.revealTs != null) return;
      game.promptRevealed(PointerClock.fromFrame(SchedulerBinding.instance.currentSystemFrameTimeStamp));
      if (ankirenOptions.prompt == AnkirenPrompt.textAndVoice) unawaited(sounds.playKimarijiVoice(asked));
    });
  }

  void _onDown(int poemId, PointerDownEvent e) =>
      _presses[e.pointer] = (poemId: poemId, at: e.timeStamp, where: e.position);

  void _onUp(PointerUpEvent e) {
    final press = _presses.remove(e.pointer);
    if (press == null || (e.position - press.where).distance > kTouchSlop) return;
    _take(press.poemId, press.at);
  }

  /// A tap on [poemId]'s card, or on the からふだ button ([Karafuda.button]).
  void _take(int poemId, Duration downAt) {
    final haptics = ProgressScope.read(context).settings.haptics;
    final asked = game.current;
    final result = poemId == Karafuda.button ? game.pressKarafuda(downAt) : game.tap(poemId, downAt);
    switch (result) {
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
          _last = (poemId: asked!, state: PromptState.found);
        });
        _next();
    }
  }

  /// "Don't know": the card asked for is shown as after the wrong taps, then
  /// turns face up, and the next one is asked. Where strikes count, it is
  /// one, and sounds like a wrong tap.
  void _giveUp() {
    final poemId = game.giveUp();
    if (poemId == null) return;
    if (game.countsStrikes) playSound(context, Sfx.ankirenWrong);
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
  void _next() => _pause = game.phase == AnkirenPhase.done
      ? Timer(AnkirenPlayTuning.finishPause, recallOver)
      : Timer(AnkirenPlayTuning.promptPause, _showPrompt);

  /// [poemId]'s field card on [side], taking taps once its prompt is up:
  /// face up while [faceUp], and for good once found or given up.
  Widget recallCard(int poemId, FieldSide side, {bool faceUp = false, bool showNumber = false}) => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _onDown(poemId, e),
        onPointerUp: _onUp,
        onPointerCancel: (e) => _presses.remove(e.pointer),
        child: AnkirenCard(
          key: ValueKey(poemId),
          poemId: poemId,
          faceUp: faceUp || (game.isDone(poemId) && _givingUp != poemId),
          inverted: side == FieldSide.opponent,
          showNumber: showNumber,
          flash: _flashes[poemId],
          revealed: (asked == poemId && game.revealed) || _givingUp == poemId,
        ),
      );

  /// The band's middle once the field is face down: the card asked for, or
  /// the last one found or given up while the next waits, with the speaker
  /// while a prompt is up, if voices are on.
  Widget recallPrompt({required bool landscape}) {
    final asked = this.asked;
    final last = _last;
    final shown = asked ?? last?.poemId;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      PromptText(
        text: shown == null ? null : kimarijiFor(context, shown),
        state: asked != null || last == null ? PromptState.asked : last.state,
        done: game.answers.length,
        total: game.prompts.length,
        landscape: landscape,
      ),
      if (ankirenOptions.prompt == AnkirenPrompt.textAndVoice && asked != null) KimarijiSpeakerButton(poemId: asked),
    ]);
  }

  /// "Don't know", while a prompt is up; faded until the first one is.
  Widget dontKnowButton() => BandButton(
        icon: IconArt.question,
        label: S.of(context).ankirenDontKnow,
        dimmed: asked == null && game.answers.isEmpty,
        onTap: asked == null ? null : _giveUp,
      );

  /// The からふだ button, for a game with any: it takes presses as a card
  /// takes taps, timed from the finger going down, and shows what they did
  /// as a card does (see [TapFeedback]), rumbling once shown after the wrong
  /// taps on a からふだ call, or given up. Faded until the first prompt is up.
  Widget karafudaButton() {
    final asked = this.asked, givingUp = _givingUp;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _onDown(Karafuda.button, e),
      onPointerUp: _onUp,
      onPointerCancel: (e) => _presses.remove(e.pointer),
      child: TapFeedback(
        flash: _flashes[Karafuda.button],
        revealed: (asked != null && game.isKarafuda(asked) && game.revealed) ||
            (givingUp != null && game.isKarafuda(givingUp)),
        child: BandButton(
          icon: IconArt.karafuda,
          label: S.of(context).karafuda,
          dimmed: asked == null && game.answers.isEmpty,
          // The press itself is taken by the listener, from its pointer
          // down; this gives the button its pressed look.
          onTap: asked == null ? null : () {},
        ),
      ),
    );
  }
}

/// A play screen's ground: the tatami, inside the safe area.
class AnkirenTatami extends StatelessWidget {
  const AnkirenTatami({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AnkirenPlayLayout.background,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AnkirenPlayLayout.tatami),
              repeat: ImageRepeat.repeat,
              scale: AnkirenPlayLayout.tatamiScale,
            ),
          ),
          child: SafeArea(child: child),
        ),
      );
}
