import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/config.dart';
import 'ankiren_field.dart';
import 'ankiren_level.dart';
import 'ankiren_score.dart';

/// Where a 暗記練 game stands: the field face up to memorise, face down while
/// its cards are asked, or over.
enum AnkirenPhase { memorise, recall, done }

/// What a tap on a field card did.
enum TapResult {
  /// It was the card asked for.
  right,

  /// Another card that is still face down.
  wrong,

  /// Nothing: the prompt was not on screen when the press began, the card was already found,
  /// or the game is not in recall.
  ignored,
}

/// State machine of one 暗記練 game: every field card is asked once, in a
/// random order, until each is found or given up, or the game is ended.
/// Timestamps are on the pointer-event clock; a prompt's vsync time is put
/// on it first (see `PointerClock`).
class AnkirenGame extends ChangeNotifier {
  AnkirenGame({
    required this.field,
    required this.setup,
    required math.Random rng,
    DateTime Function()? clock,
  })  : prompts = List.unmodifiable(field.cards..shuffle(rng)),
        _clock = clock ?? DateTime.now;

  final AnkirenField field;
  final AnkirenSetup setup;

  /// The field's cards in the order they are asked.
  final List<int> prompts;
  final DateTime Function() _clock;

  AnkirenPhase phase = AnkirenPhase.memorise;

  /// One per prompt asked so far, in order; after [end], one per prompt.
  final List<AnkirenAnswer> answers = [];

  final Set<int> _found = {};
  final Set<int> _givenUp = {};
  int _wrongTaps = 0;
  Duration? _revealTs;
  bool _endedEarly = false;

  /// Every card was asked and found or given up (false for a game ended
  /// early).
  bool get completed => phase == AnkirenPhase.done && !_endedEarly;

  /// The card being asked for, in recall.
  int? get current => phase == AnkirenPhase.recall ? prompts[answers.length] : null;

  /// Wrong taps on the current prompt.
  int get wrongTaps => _wrongTaps;

  /// The current prompt's card is shown, after
  /// [AnkirenTuning.revealAfterWrong] wrong taps; it still has to be tapped.
  bool get revealed => _wrongTaps >= AnkirenTuning.revealAfterWrong;

  bool isFound(int poemId) => _found.contains(poemId);
  bool isGivenUp(int poemId) => _givenUp.contains(poemId);

  /// Found or given up: its card is face up for good.
  bool isDone(int poemId) => isFound(poemId) || isGivenUp(poemId);

  AnkirenScore get score => AnkirenScore(
        answers,
        prompts: prompts.length,
        timeLeft: timeLeft,
        factor: AnkirenScore.factorFor(setup),
      );

  /// How long the field was memorised: all of its time unless the player was
  /// ready sooner.
  Duration get memorised => _memorised ?? setup.memorise;
  Duration? _memorised;

  /// The share of the memorise time left unused.
  double get timeLeft => (1 - memorised.inMicroseconds / setup.memorise.inMicroseconds).clamp(0.0, 1.0);

  /// Turns the cards face down and asks the first one; [memorised] when the
  /// player is ready before the time is up.
  void startRecall({Duration? memorised}) {
    if (phase != AnkirenPhase.memorise) return;
    _memorised = memorised;
    phase = AnkirenPhase.recall;
    notifyListeners();
  }

  /// Called with the vsync timestamp of the first frame showing the current
  /// prompt, on the pointer-event clock.
  void promptRevealed(Duration frameTs) {
    if (phase != AnkirenPhase.recall || _revealTs != null) return;
    _revealTs = frameTs;
  }

  Duration? get revealTs => _revealTs;

  /// A tap on [poemId]'s card, its pointer-down time on the pointer-event
  /// clock. A press that began before the prompt was on screen is ignored.
  TapResult tap(int poemId, Duration pointerDownTs) {
    final asked = current;
    final revealTs = _revealTs;
    if (asked == null || revealTs == null || pointerDownTs < revealTs || isDone(poemId) || field.sideOf(poemId) == null) {
      return TapResult.ignored;
    }
    if (poemId != asked) {
      _wrongTaps++;
      notifyListeners();
      return TapResult.wrong;
    }
    _answer(asked, (pointerDownTs - revealTs).inMicroseconds);
    _found.add(asked);
    _moveOn();
    return TapResult.right;
  }

  /// The player doesn't know the current card ("don't know"): it is given up,
  /// earning nothing, and the next one is asked. Returns the card given up,
  /// or null when no prompt is on screen.
  int? giveUp() {
    final asked = current;
    if (asked == null || _revealTs == null) return null;
    _answer(asked, null);
    _givenUp.add(asked);
    _moveOn();
    return asked;
  }

  void _moveOn() {
    if (answers.length == prompts.length) phase = AnkirenPhase.done;
    notifyListeners();
  }

  /// Ends the game early: the prompts not found yet count as never found.
  void end() {
    if (phase == AnkirenPhase.done) return;
    _endedEarly = true;
    while (answers.length < prompts.length) {
      _answer(prompts[answers.length], null);
    }
    phase = AnkirenPhase.done;
    notifyListeners();
  }

  void _answer(int poemId, int? responseUs) {
    answers.add(AnkirenAnswer(
      poemId: poemId,
      side: field.sideOf(poemId)!,
      wrongTaps: _wrongTaps,
      responseUs: responseUs,
      at: _clock(),
    ));
    _wrongTaps = 0;
    _revealTs = null;
  }
}
