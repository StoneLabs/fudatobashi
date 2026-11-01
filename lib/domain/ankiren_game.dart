import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../config/config.dart';
import 'ankiren_field.dart';
import 'ankiren_level.dart';
import 'ankiren_score.dart';
import 'karafuda.dart';
import 'level_ladder.dart';

/// Where a 暗記練 game stands: the field face up to memorise, face down while
/// its cards are asked, or over.
enum AnkirenPhase { memorise, recall, done }

/// Who plays a 暗記練 game, and so what of it is kept.
enum AnkirenPlayer {
  /// The app's own player: the game is recorded, and a free-play level's
  /// strikes count.
  owner,

  /// A guest (Guest mode): nothing of the game is recorded anywhere.
  guest,

  /// The developer's test game: nothing is recorded.
  developer;

  bool get recorded => this == owner;
}

/// What a tap on a field card, or a press of the からふだ button, did.
enum TapResult {
  /// It was the card asked for, or the からふだ button on a からふだ call.
  right,

  /// Another card that is still face down, a card on a からふだ call, or the
  /// からふだ button on a card's.
  wrong,

  /// Nothing: the prompt was not on screen when the press began, the card was already found,
  /// or the game is not in recall.
  ignored,
}

/// State machine of one 暗記練 game: every field card is asked once, and
/// each of [karafuda], in a random order that ends on a field card (see
/// [Karafuda.order]), until each is found or given up, or the game is
/// ended. A からふだ call is answered with [pressKarafuda]; a tap on a card
/// meanwhile is wrong, as one on the other side would be, and so is the
/// press on a card's call. Timestamps are on the pointer-event clock; a
/// prompt's vsync time is put on it first (see `PointerClock`).
class AnkirenGame extends ChangeNotifier {
  AnkirenGame({
    required this.field,
    required this.setup,
    required math.Random rng,
    List<int> karafuda = const [],
    this.countsStrikes = false,
    this.startingStrikes = 0,
    DateTime Function()? clock,
  })  : karafuda = List.unmodifiable(karafuda),
        prompts = List.unmodifiable(Karafuda.order(field.cards, karafuda, rng)),
        _clock = clock ?? DateTime.now;

  final AnkirenField field;
  final AnkirenSetup setup;

  /// The からふだ called: known cards not on the field.
  final List<int> karafuda;

  /// A free-play level game: its [strikes] count, and it clears its level
  /// with fewer than [AnkirenTuning.strikesOut].
  final bool countsStrikes;

  /// The strikes it begins with: 定位置's cards never placed.
  final int startingStrikes;

  /// The field's cards and the からふだ in the order they are asked.
  final List<int> prompts;
  final DateTime Function() _clock;

  AnkirenPhase phase = AnkirenPhase.memorise;

  /// One per prompt asked so far, in order; after [end], one per prompt.
  final List<AnkirenAnswer> answers = [];

  final Set<int> _found = {};
  final Set<int> _givenUp = {};
  int _wrongTaps = 0;
  Duration? _revealTs;
  final List<TapProximity> _taps = [];
  final List<int> _tapped = [];
  int? _firstTapUs;
  bool _endedEarly = false;

  /// Every card was asked and found or given up (false for a game ended
  /// early).
  bool get completed => phase == AnkirenPhase.done && !_endedEarly;

  /// [startingStrikes] and the wrong taps and cards given up so far, one
  /// strike each.
  int get strikes => answers.fold(startingStrikes + _wrongTaps, (n, a) => n + a.wrongTaps + (a.gaveUp ? 1 : 0));

  /// It cleared its level (see `LevelLadder.clears`).
  bool get cleared => countsStrikes && LevelLadder.clears(completed: completed, strikes: strikes);

  /// The card being asked for, in recall.
  int? get current => phase == AnkirenPhase.recall ? prompts[answers.length] : null;

  bool isKarafuda(int poemId) => karafuda.contains(poemId);

  /// The answers to the field's cards, and to the からふだ calls.
  Iterable<AnkirenAnswer> get cardAnswers => answers.where((a) => !a.karafuda);
  Iterable<AnkirenAnswer> get karafudaAnswers => answers.where((a) => a.karafuda);

  /// Wrong taps on the current prompt.
  int get wrongTaps => _wrongTaps;

  /// The current prompt's card is shown, after
  /// [AnkirenTuning.revealAfterWrong] wrong taps; it still has to be tapped.
  bool get revealed => _wrongTaps >= AnkirenTuning.revealAfterWrong;

  bool isFound(int poemId) => _found.contains(poemId);
  bool isGivenUp(int poemId) => _givenUp.contains(poemId);

  /// Found or given up: its card is face up for good.
  bool isDone(int poemId) => isFound(poemId) || isGivenUp(poemId);

  /// How the からふだ calls went so far.
  KarafudaTally get karafudaTally => KarafudaTally.of([
        for (final a in answers) (karafuda: a.karafuda, found: a.found, wrongTaps: a.wrongTaps, tapped: a.tapped),
      ]);

  /// Null unless ranked: only ranked games have points.
  AnkirenScore? get score => setup.ranked ? AnkirenScore(answers, prompts: prompts.length, timeLeft: timeLeft) : null;

  /// Field cards found with the first tap.
  int get firstTries => cardAnswers.where((a) => a.firstTry).length;

  /// Mean response time of the field cards' first-tap finds with a valid
  /// time, ms; null when there are none.
  double? get averageFirstTryMs {
    final timed = [for (final a in cardAnswers) if (a.firstTry && a.validTime) a.responseUs! / 1000];
    return timed.isEmpty ? null : timed.reduce((a, b) => a + b) / timed.length;
  }

  /// How long the field was memorised: all of its time unless the player was
  /// ready sooner.
  Duration get memorised => _memorised ?? setup.memorise;
  Duration? _memorised;

  /// The share of the memorise time left unused.
  double get timeLeft => (1 - memorised.inMicroseconds / setup.memorise.inMicroseconds).clamp(0.0, 1.0);

  /// Turns the cards face down and asks the first one, if any is to ask;
  /// [memorised] when the player is ready before the time is up.
  void startRecall({Duration? memorised}) {
    if (phase != AnkirenPhase.memorise) return;
    _memorised = memorised;
    phase = prompts.isEmpty ? AnkirenPhase.done : AnkirenPhase.recall;
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
  /// Where it lands is kept while taps still count
  /// ([AnkirenTuning.tapWeights]), a card tapped twice counting twice.
  TapResult tap(int poemId, Duration pointerDownTs) {
    final asked = current;
    if (asked == null || isDone(poemId) || field.sideOf(poemId) == null) return TapResult.ignored;
    final place = isKarafuda(asked) ? TapProximity.otherSide : field.proximity(asked, poemId);
    return _take(poemId, place, pointerDownTs, right: poemId == asked);
  }

  /// A press of the からふだ button at its pointer-down time: right on a
  /// からふだ call, which it answers as a tap on its card would; else a wrong
  /// tap, as one on the other side. Ignored when a [tap] would be.
  TapResult pressKarafuda(Duration pointerDownTs) {
    final asked = current;
    if (asked == null) return TapResult.ignored;
    final right = isKarafuda(asked);
    return _take(Karafuda.button, right ? TapProximity.card : TapProximity.otherSide, pointerDownTs, right: right);
  }

  /// A tap on [target] ([Karafuda.button] for the button), landing at
  /// [place]; [right] when it answers the call.
  TapResult _take(int target, TapProximity place, Duration pointerDownTs, {required bool right}) {
    final asked = current!;
    final revealTs = _revealTs;
    if (revealTs == null || pointerDownTs < revealTs) return TapResult.ignored;
    _firstTapUs ??= (pointerDownTs - revealTs).inMicroseconds;
    if (_taps.length < AnkirenTuning.tapWeights.length) {
      _taps.add(place);
      _tapped.add(target);
    }
    if (!right) {
      _wrongTaps++;
      notifyListeners();
      return TapResult.wrong;
    }
    _answer(asked, (pointerDownTs - revealTs).inMicroseconds);
    _found.add(asked);
    _moveOn();
    return TapResult.right;
  }

  /// The player doesn't know the current card ("don't know"): it is given
  /// up, keeping what its taps so far earned, and the next one is asked.
  /// Returns the card given up, or null when no prompt is on screen.
  int? giveUp() {
    final asked = current;
    if (asked == null || _revealTs == null) return null;
    _answer(asked, null, gaveUp: true);
    _givenUp.add(asked);
    _moveOn();
    return asked;
  }

  void _moveOn() {
    if (answers.length == prompts.length) phase = AnkirenPhase.done;
    notifyListeners();
  }

  /// Ends the game early: the prompts not found yet count as never found,
  /// the one asked keeping its taps so far.
  void end() {
    if (phase == AnkirenPhase.done) return;
    _endedEarly = true;
    while (answers.length < prompts.length) {
      _answer(prompts[answers.length], null);
    }
    phase = AnkirenPhase.done;
    notifyListeners();
  }

  void _answer(int poemId, int? responseUs, {bool gaveUp = false}) {
    answers.add(AnkirenAnswer(
      poemId: poemId,
      side: field.sideOf(poemId),
      wrongTaps: _wrongTaps,
      responseUs: responseUs,
      at: _clock(),
      gaveUp: gaveUp,
      taps: List.unmodifiable(_taps),
      tapped: List.unmodifiable(_tapped),
      firstTapUs: _firstTapUs,
    ));
    _wrongTaps = 0;
    _revealTs = null;
    _taps.clear();
    _tapped.clear();
    _firstTapUs = null;
  }
}
