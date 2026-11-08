import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../data/poem.dart';
import '../../domain/ikkiuchi_call.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_match.dart';
import '../../domain/ikkiuchi_read.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_side.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../sound/sounds.dart';
import 'ikkiuchi_board_scene.dart';
import 'ikkiuchi_reader.dart';
import 'ikkiuchi_send_flow.dart';

/// What a match reads out in the player's script: each card's kimariji and
/// call, and a からふだ's tag.
class IkkiuchiMatchWords {
  const IkkiuchiMatchWords({required this.kimariji, required this.call, required this.karafuda});

  factory IkkiuchiMatchWords.of(BuildContext context) => IkkiuchiMatchWords(
        kimariji: (id) => kimarijiFor(context, id),
        call: (id) => IkkiuchiReader.callFor(context, id),
        karafuda: S.of(context).ikkiuchiKarafuda,
      );

  final String Function(int id) kimariji;
  final IkkiuchiCall Function(int id) call;
  final String karafuda;
}

/// A match (一騎打ち) run on a board scene, through its stages
/// ([IkkiuchiStage]) by the board's time ([advance]), each step one of
/// [IkkiuchiSteps.all].
///
/// The memory time runs first ([memorise] long), then the greeting and the
/// 序歌. Each read
/// takes the next card of the read order ([IkkiuchiReadOrder]): the reader
/// reads its kimariji while its voice plays, Tobi playing the read at
/// [rating], or not at all without one. Card touches count only while a
/// card is read ([IkkiuchiStage.readLive]); the finger touches no card
/// otherwise. The read is over once the card is taken, or a からふだ's
/// pause has gone by, Tobi's arm is done and the cards are home: how it
/// ended shows ([feedback]), then the card taken leaves its side and the
/// cards close up, and the 送り札 the read leaves ([IkkiuchiReadEnd]) are
/// made, one by one. Then a moment passes, the 下の句 is read, another
/// moment passes, and the next card is read. A side left empty ends the
/// match, as does the player at any time ([end]); the kimariji voice stops
/// with it, or with the flow's disposal. Each read is logged as it ends
/// ([reads]), and the cards it leaves each side are counted ([tally]).
///
/// The player may move their cards (並べ替え) only in the stages that allow
/// it; one such stage over while they still move them holds the match
/// ([IkkiuchiStage.movingCard]) until they are done. With
/// [holdBeforeShimonoku] the match holds once the 送り札 are made
/// ([IkkiuchiStage.waitingForGo]) until let go ([go]).
///
/// Between the reads a 送り札 may be asked for by hand ([sendByHand]): it
/// is made, and the stage it broke into goes on where it was.
class IkkiuchiMatchFlow extends ChangeNotifier {
  IkkiuchiMatchFlow(
    this.scene, {
    required this.words,
    this.rating,
    this.holdBeforeShimonoku = false,
    this.markCalled = false,
    this.memorise = IkkiuchiMatchTuning.memorise,
  }) {
    final sides = scene.sides!;
    _tally = IkkiuchiTally(player: sides.playerCards.length, opponent: sides.tobiCards.length);
    final field = [...sides.tobiCards, ...sides.playerCards]..sort();
    final dealt = field.toSet();
    final away = [
      for (final p in poems.all)
        if (!dealt.contains(p.id)) p.id,
    ];
    _order = IkkiuchiReadOrder.deal(field: field, away: away, rng: scene.rng);
    final ordered = _order.toSet();
    _spare = [
      for (final id in away)
        if (!ordered.contains(id)) id,
    ];
    _enter(IkkiuchiStage.memoryTime);
  }

  final IkkiuchiBoardScene scene;
  final IkkiuchiMatchWords words;

  /// Tobi's rating for the reads to come, each taking it as it starts; null
  /// while he never reaches for a card nor faults. He makes his 送り札
  /// either way.
  double? rating;

  /// Whether the match holds once the 送り札 after a read are made.
  final bool holdBeforeShimonoku;

  /// Whether the card read is marked on the board.
  final bool markCalled;

  /// How long the memory time lasts.
  final Duration memorise;

  /// Every read so far that has ended, in order.
  List<IkkiuchiReadLog> get reads => List.unmodifiable(_reads);
  final List<IkkiuchiReadLog> _reads = [];

  /// Whether the player ended the match ([end]).
  bool get endedByPlayer => _endedByPlayer;
  bool _endedByPlayer = false;

  /// Whether play has begun: a card has been read.
  bool get playBegun => _readId != null;

  /// Each side's cards left as the rules have them, a read's take and
  /// 送り札 counted from its end on.
  IkkiuchiTally get tally => _tally;
  late IkkiuchiTally _tally;

  /// The card read now, and the board time of its deciding sound.
  int? _readId;
  double _decidedAt = 0;

  IkkiuchiStage get stage => _stage;
  IkkiuchiStage _stage = IkkiuchiStage.memoryTime;

  /// Ms left of a timed stage.
  double get left => _left;
  double _left = 0;

  /// The cards still to read, next first; the cards dealt to neither side
  /// and not among them.
  late final List<int> _order;
  late final List<int> _spare;

  /// Whether the next read is a からふだ, as asked for.
  bool get karafudaNext => _karafudaNext;
  bool _karafudaNext = false;

  /// How the last read ended, from its end until the next read.
  IkkiuchiReadEnd? get feedback => _feedback;
  IkkiuchiReadEnd? _feedback;

  /// Whether the cards the read stirred were sent home.
  bool _tidied = false;

  /// The card taken, until it is off the board and its side closes up.
  int? _leaving;

  /// The 送り札 still to make, each the side that sends one.
  final List<IkkiuchiSide> _sends = [];

  /// The stage a 送り札 asked for by hand broke into, with its ms left.
  ({IkkiuchiStage stage, double left})? _resume;

  /// The stage the match goes on to once the player is done moving cards.
  IkkiuchiStage? _afterMoving;

  static final _layoutRules = IkkiuchiLayout.ofPoems();

  /// Whether the player may start moving their cards now.
  bool get canArrange => _stage.allowsMoving && scene.arrange.canStart;

  /// Ends the memory time at once.
  void endMemoryTime() {
    if (_stage == IkkiuchiStage.memoryTime) _timeUp();
  }

  /// Lets a held match go on.
  void go() {
    if (_stage == IkkiuchiStage.waitingForGo) _enter(IkkiuchiStage.waitBeforeShimonoku);
  }

  /// The next read is a からふだ; not while a card is read.
  void askKarafuda() {
    if (_stage.readLive || _stage == IkkiuchiStage.gameEnd) return;
    _karafudaNext = true;
    notifyListeners();
  }

  /// [from] sends the other a card now; only between the reads
  /// ([IkkiuchiStage.allowsHandSend]) with the board at rest.
  void sendByHand(IkkiuchiSide from) {
    if (!_stage.allowsHandSend || !scene.atRest || !_has(from)) return;
    _resume = (stage: _stage, left: _left);
    _tally = _tally.sent(from, 1);
    _sends
      ..clear()
      ..add(from);
    _nextSend();
  }

  /// The player ends the match (終了), whatever is under way: a 送り札 is
  /// called off where it stands ([IkkiuchiSendFlow.cancel]).
  void end() {
    if (_stage == IkkiuchiStage.gameEnd) return;
    _endedByPlayer = true;
    scene.arrange.finish();
    scene.send.cancel();
    _sends.clear();
    _resume = null;
    _enter(IkkiuchiStage.gameEnd);
  }

  /// Runs the board on by [ms], and the match with it; by
  /// [IkkiuchiMatchTuning.longestStep] at most, so that a long gap, as while
  /// the app was away, holds the match for the rest of it.
  void advance(double ms) {
    ms = math.min(ms, _ms(IkkiuchiMatchTuning.longestStep));
    scene.advance(ms);
    if (_length(_stage) != null) return _countDown(ms);
    switch (_stage) {
      case IkkiuchiStage.kaminoku || IkkiuchiStage.waitingForHit:
        _watchRead();
      case IkkiuchiStage.closingUp:
        _watchClosing();
      case IkkiuchiStage.sendingCard || IkkiuchiStage.tobiPlacingCard || IkkiuchiStage.receivingCard:
        _watchSend();
      case IkkiuchiStage.movingCard:
        if (!scene.arrange.active && scene.atRest) _enter(_afterMoving!);
      case _:
    }
  }

  /// A timed stage runs [ms] on; listeners hear of each second gone.
  void _countDown(double ms) {
    final second = (_left / Duration.millisecondsPerSecond).ceil();
    _left -= ms;
    if (_left <= 0) {
      _timeUp();
    } else if ((_left / Duration.millisecondsPerSecond).ceil() != second) {
      notifyListeners();
    }
  }

  /// How long [stage] lasts; null for one that is not timed.
  Duration? _length(IkkiuchiStage stage) => switch (stage) {
        IkkiuchiStage.memoryTime => memorise,
        IkkiuchiStage.gameStart => IkkiuchiMatchTuning.greeting,
        IkkiuchiStage.yoka => IkkiuchiMatchTuning.yoka,
        IkkiuchiStage.feedback => IkkiuchiMatchTuning.feedback,
        IkkiuchiStage.waitBeforeShimonoku => IkkiuchiMatchTuning.waitBeforeShimonoku,
        IkkiuchiStage.shimonoku => IkkiuchiMatchTuning.shimonoku,
        IkkiuchiStage.breakAfterShimonoku => IkkiuchiMatchTuning.breakAfterShimonoku,
        _ => null,
      };

  /// A timed stage is over: the next one starts, or, while the player
  /// still moves cards in a stage that no longer lets them, the match holds.
  void _timeUp() {
    final IkkiuchiStage next;
    switch (_stage) {
      case IkkiuchiStage.memoryTime:
        next = IkkiuchiStage.gameStart;
      case IkkiuchiStage.gameStart:
        next = IkkiuchiStage.yoka;
      case IkkiuchiStage.yoka || IkkiuchiStage.breakAfterShimonoku:
        next = IkkiuchiStage.kaminoku;
      case IkkiuchiStage.waitBeforeShimonoku:
        next = IkkiuchiStage.shimonoku;
      case IkkiuchiStage.shimonoku:
        next = IkkiuchiStage.breakAfterShimonoku;
      case IkkiuchiStage.feedback:
        return _leaving == null ? _nextSend() : _enter(IkkiuchiStage.closingUp);
      case _:
        throw StateError('$_stage is not timed');
    }
    if (scene.arrange.active && !next.allowsMoving) {
      _afterMoving = next;
      _enter(IkkiuchiStage.movingCard);
    } else {
      _enter(next);
    }
  }

  static double _ms(Duration d) => d.inMicroseconds / Duration.microsecondsPerMillisecond;

  /// The match steps to [stage], for the time it lasts, or [left] of it.
  void _enter(IkkiuchiStage stage, {double? left}) {
    assert(IkkiuchiSteps.allows(_stage, stage) || stage == _stage, 'no step from $_stage to $stage');
    _stage = stage;
    _left = left ?? _ms(_length(stage) ?? Duration.zero);
    scene.fingerOn = stage.readLive;
    if (stage == IkkiuchiStage.kaminoku) _read();
    if (stage == IkkiuchiStage.gameEnd) {
      scene.clearCall();
      unawaited(sounds.stopKimarijiVoice());
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(sounds.stopKimarijiVoice());
    super.dispose();
  }

  // The reads.

  /// Reads the next card, or a からふだ when asked for one.
  void _read() {
    final id = _nextCard();
    if (id == null) return _enter(IkkiuchiStage.gameEnd);
    final sides = scene.sides!;
    final onField = sides.tobiCards.contains(id) || sides.playerCards.contains(id);
    final board = scene.board;
    final rating = this.rating;
    scene.tobiRating = rating ?? IkkiuchiTuning.ratingMin;
    final tobi = rating == null
        ? null
        : IkkiuchiRead.decide(
            rating: rating,
            called: id,
            field: board.field,
            from: board.shoulders,
            alike: _layoutRules.alike,
            rng: scene.rng,
          );
    final call = words.call(id);
    _readId = id;
    _decidedAt = board.now + call.decidedAt;
    if (onField) {
      scene.callCard(id, words.kimariji(id), call: call, tobi: tobi);
    } else {
      scene.callKarafuda(id, words.kimariji(id), tag: words.karafuda, call: call, tobi: tobi);
    }
    if (!markCalled) scene.mark(null);
    unawaited(sounds.playKimarijiVoice(id));
    _tidied = false;
    _leaving = null;
    _feedback = null;
  }

  int? _nextCard() {
    if (_karafudaNext) {
      _karafudaNext = false;
      final sides = scene.sides!;
      final at = _order.indexWhere((id) => !sides.tobiCards.contains(id) && !sides.playerCards.contains(id));
      if (at >= 0) return _order.removeAt(at);
      if (_spare.isNotEmpty) return _spare.removeAt(scene.rng.nextInt(_spare.length));
    }
    return _order.isEmpty ? null : _order.removeAt(0);
  }

  /// The read in play: once its kimariji is heard it waits for the take;
  /// once over and Tobi's arm is done the cards go home, and once they are
  /// at rest the read ends.
  void _watchRead() {
    final reader = scene.reader, call = reader.call;
    if (_stage == IkkiuchiStage.kaminoku && call != null && reader.heard >= call.sounds.length) {
      _enter(IkkiuchiStage.waitingForHit);
    }
    if (!scene.readOver || scene.board.busy) return;
    if (!_tidied) {
      _tidied = true;
      scene.tidyUp();
      return;
    }
    if (scene.atRest) _endRead();
  }

  /// The read ends: no more touches count, the card the player took fades
  /// where it lies, its 送り札 are noted, and how it ended shows.
  void _endRead() {
    final board = scene.board;
    final id = board.called;
    final taker = board.taker;
    Set<IkkiuchiSide> sidesOf(Iterable<int> cards) => {for (final c in cards) board.cards.card(c).side};
    final end = IkkiuchiReadEnd(
      taker: taker,
      cardSide: id == null ? null : board.cards.card(id).side,
      tied: board.tied,
      tobiFaults: sidesOf(board.faults.keys),
      playerFaults: sidesOf(board.playerFaults.keys),
    );
    _sends.clear();
    if (end.sends case (:final from, :final count)) _sends.addAll(List.filled(count, from));
    _tally = _tally.after(end);
    if (id != null && taker != null) {
      if (taker == IkkiuchiSide.player) board.cards.fadeOut(board.cards.card(id));
      _leaving = id;
    }
    final take = board.take?.at, hit = board.tobiHit;
    Duration? from(double? at) => at == null ? null : Duration(microseconds: ((at - _decidedAt) * Duration.microsecondsPerMillisecond).round());
    _reads.add(IkkiuchiReadLog(poemId: _readId!, end: end, playerTake: from(take), tobiTake: from(hit)));
    scene.clearCall();
    _feedback = end;
    _enter(IkkiuchiStage.feedback);
  }

  /// Once the card taken is off the board its side closes up; once the
  /// cards are home the 送り札 are made.
  void _watchClosing() {
    if (_leaving case final id?) {
      if (scene.board.cards.card(id).onBoard) return;
      _leaving = null;
      scene.relayout(scene.sides!.without(id));
      return;
    }
    if (scene.atRest) _nextSend();
  }

  // The 送り札.

  bool _has(IkkiuchiSide side) =>
      side == IkkiuchiSide.player ? scene.sides!.playerCards.isNotEmpty : scene.sides!.tobiCards.isNotEmpty;

  /// Makes the next 送り札 still to make, by a side with a card left.
  void _nextSend() {
    while (_sends.isNotEmpty) {
      final from = _sends.removeAt(0);
      if (!_has(from)) continue;
      if (from == IkkiuchiSide.player) {
        scene.send.startSending();
        _enter(IkkiuchiStage.sendingCard);
      } else {
        scene.send.startReceiving();
        _enter(IkkiuchiStage.receivingCard);
      }
      return;
    }
    _sendsDone();
  }

  void _watchSend() {
    final send = scene.send;
    if (_stage == IkkiuchiStage.sendingCard && send.stage == IkkiuchiSendStage.placing) {
      _enter(IkkiuchiStage.tobiPlacingCard);
    }
    if (!send.active && scene.atRest) _nextSend();
  }

  /// Every 送り札 is made and the cards are at rest: the match ends on an
  /// empty side, goes back to the stage a 送り札 by hand broke into, or
  /// heads for the 下の句.
  void _sendsDone() {
    final sides = scene.sides!;
    if (sides.tobiCards.isEmpty || sides.playerCards.isEmpty) return _enter(IkkiuchiStage.gameEnd);
    if (_resume case (:final stage, :final left)) {
      _resume = null;
      return _enter(stage, left: left);
    }
    _enter(holdBeforeShimonoku ? IkkiuchiStage.waitingForGo : IkkiuchiStage.waitBeforeShimonoku);
  }
}
