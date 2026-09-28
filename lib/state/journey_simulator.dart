import 'dart:math' as math;

import '../config/config.dart';
import '../data/poem.dart';
import '../domain/card_stats.dart';
import '../domain/play_session.dart';
import '../domain/synthetic_learner.dart';
import 'play_config.dart';
import 'progress.dart';

/// Called after each simulated card with the cards done and the round's
/// current length (training requeues misses, so it can grow).
typedef CardProgress = void Function(int done, int total);

/// Plays simulated rounds through the real path: [Progress.planTraining] →
/// a [PlaySession] answered by a [SyntheticLearner] → [Progress.recordRun].
/// Drives the pacing tests and the dev-mode demo data.
class JourneySimulator {
  JourneySimulator(this.progress, {required int seed, LearnerKind learner = LearnerKind.average, this.onReport})
    : rng = math.Random(seed),
      learner = SyntheticLearner(math.Random(seed + 1), kind: learner);

  final Progress progress;
  final math.Random rng;
  final SyntheticLearner learner;

  /// Receives every recorded run's report.
  final void Function(SessionReport report)? onReport;

  /// Plays [rounds] training rounds spread over the local day [date], then
  /// [freeRounds] free-play runs of [freeCards] cards. [onRound] reports each
  /// round's card progress, with the round's 0-based index.
  Future<void> day(
    DateTime date, {
    required int rounds,
    int freeRounds = 0,
    int freeCards = 0,
    void Function(int round, int done, int total)? onRound,
  }) async {
    final count = rounds + freeRounds;
    final span =
        (SyntheticLearnerTuning.lastRoundHour - SyntheticLearnerTuning.firstRoundHour) * Duration.minutesPerHour;
    for (var i = 0; i < count; i++) {
      final offset = count == 1 ? 0 : span * i ~/ (count - 1);
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        SyntheticLearnerTuning.firstRoundHour,
        offset + rng.nextInt(SyntheticLearnerTuning.roundStartJitterMinutes),
      );
      void onCard(int done, int total) => onRound?.call(i, done, total);
      if (i < rounds) {
        await trainingRound(start, onCard: onCard);
      } else {
        await freeRound(start, freeCards, onCard: onCard);
      }
    }
  }

  /// One training round from [start] ([learnAhead]: after "Learn ahead").
  /// Returns when it ended.
  Future<DateTime> trainingRound(DateTime start, {bool learnAhead = false, CardProgress? onCard}) async {
    final plan = learnAhead
        ? await progress.learnAheadCards(rng: rng, now: start)
        : await progress.planTraining(rng: rng, now: start);
    if (plan.cards.isEmpty) return start;
    return _play(plan.cards, const PlayConfig(mode: PlayMode.training), start, onCard: onCard);
  }

  Future<DateTime> freeRound(DateTime start, int cards, {CardProgress? onCard}) async {
    const config = PlayConfig(mode: PlayMode.free);
    final deck = progress.freeDeck(config, rng: rng).take(cards).toList();
    if (deck.isEmpty) return start;
    return _play(deck, config, start, onCard: onCard);
  }

  Future<DateTime> _play(List<CardRef> cards, PlayConfig config, DateTime start, {CardProgress? onCard}) async {
    final session = PlaySession(cards);
    var engine = Duration.zero;
    var wall = start;
    while (!session.finished) {
      final card = session.current!;
      session.revealed(engine);
      final answer = learner.answer(poems[card.poemId], ItemKey(card.poemId, card.inverted), wall);
      final responseTs = engine + Duration(microseconds: (answer.ms * 1000).round());
      wall = wall.add(Duration(milliseconds: answer.ms.round())).add(SyntheticLearnerTuning.cardGap);
      session.commit(
        responseTs: responseTs,
        commitTs: responseTs + SyntheticLearnerTuning.responseToCommit,
        outcome: answer.miss ? Outcome.dontKnow : Outcome.known,
        at: wall,
      );
      if (answer.miss && config.mode == PlayMode.training) session.requeue(card);
      engine = responseTs + SyntheticLearnerTuning.responseToCommit + SyntheticLearnerTuning.commitToNextReveal;
      onCard?.call(session.index, session.cards.length);
    }
    final report = await progress.recordRun(session, config, start, now: wall);
    onReport?.call(report);
    return wall;
  }
}
