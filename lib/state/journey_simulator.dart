import 'dart:math' as math;

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';
import '../domain/card_stats.dart';
import '../domain/play_session.dart';
import '../domain/synthetic_learner.dart';
import 'play_config.dart';
import 'progress.dart';

/// Called after each simulated card with the cards done and the round's
/// current length (training requeues misses, so it can grow).
typedef CardProgress = void Function(int done, int total);

/// Receives each simulated swipe: the card, when it was answered and the
/// learner's answer.
typedef SimulatedAnswer = void Function(ItemKey key, DateTime at, LearnerAnswer answer);

/// Plays simulated rounds through the real path: [Progress.planTraining] →
/// a [PlaySession] answered by a [SyntheticLearner] → [Progress.recordRun].
/// Drives the pacing tests and the dev-mode demo data.
class JourneySimulator {
  JourneySimulator(
    this.progress, {
    required int seed,
    LearnerKind learner = LearnerKind.average,
    this.onReport,
    this.onAnswer,
  }) : rng = math.Random(seed),
       learner = SyntheticLearner(math.Random(seed + 1), kind: learner);

  final Progress progress;
  final math.Random rng;
  final SyntheticLearner learner;

  /// Receives every recorded run's report.
  final void Function(SessionReport report)? onReport;
  final SimulatedAnswer? onAnswer;

  /// Plays [rounds] training rounds spread over the local day [date], then
  /// [freeRounds] free-play runs of [freeCards] cards. A round of today's set
  /// stops after a round's length of swipes (the player sits down that
  /// often), unless the player plays [wholeSets]; once the day is done,
  /// rounds are batches. [onRound] reports each round's card progress, with
  /// the round's 0-based index.
  Future<void> day(
    DateTime date, {
    required int rounds,
    int freeRounds = 0,
    int freeCards = 0,
    bool wholeSets = false,
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
        await trainingRound(start,
            onCard: onCard, setSwipes: wholeSets ? null : progress.trainer.config.sessionLength);
      } else {
        await freeRound(start, freeCards, onCard: onCard);
      }
    }
  }

  /// Plays today's set on the local day [date] until it is done, then stops.
  /// Each sitting plays what is left of the set whole; the next one starts
  /// [SimulationTuning.sittingGap] after the last ended.
  Future<void> finishSet(DateTime date) async {
    var start = DateTime(date.year, date.month, date.day, SyntheticLearnerTuning.firstRoundHour,
        rng.nextInt(SyntheticLearnerTuning.roundStartJitterMinutes));
    for (var i = 0; i < SimulationTuning.maxSittingsPerDay; i++) {
      final end = await trainingRound(start);
      if (progress.todaySet(end)?.done ?? true) return;
      start = end.add(SimulationTuning.sittingGap);
    }
  }

  /// One training round from [start] ([learnAhead]: after "Learn ahead"),
  /// ended after [setSwipes] swipes if it plays today's set. Returns when it
  /// ended.
  Future<DateTime> trainingRound(DateTime start, {bool learnAhead = false, CardProgress? onCard, int? setSwipes}) async {
    final plan = learnAhead
        ? await progress.learnAheadCards(rng: rng, now: start)
        : await progress.planTraining(rng: rng, now: start);
    if (plan.cards.isEmpty) return start;
    return _play(plan.cards, const PlayConfig(mode: PlayMode.training), start,
        newPoems: plan.newPoems, planner: plan.planner, maxSwipes: plan.ofSet ? setSwipes : null, onCard: onCard);
  }

  /// A customised free-play round (all 100 cards, cut to [cards]): stored,
  /// but it never counts for SRS.
  Future<DateTime> freeRound(DateTime start, int cards, {CardProgress? onCard}) async {
    const config = PlayConfig(mode: PlayMode.free);
    final deck = progress.freeDeck(config, rng: rng).take(cards).toList();
    if (deck.isEmpty) return start;
    return _play(deck, config, start, onCard: onCard);
  }

  /// Plays [cards] from [start], introducing each of [newPoems] before its
  /// first swipe and, in training without a [planner], bringing a missed
  /// card back with one 友札 the player knows, as the play screen does. The
  /// player ends the run early after [maxSwipes] swipes.
  Future<DateTime> _play(
    List<CardRef> cards,
    PlayConfig config,
    DateTime start, {
    Set<int> newPoems = const {},
    RunPlanner? planner,
    int? maxSwipes,
    CardProgress? onCard,
  }) async {
    final session = PlaySession(cards, planner: planner);
    final toIntroduce = {...newPoems};
    var engine = Duration.zero;
    var wall = start;
    while (!session.finished && (maxSwipes == null || session.swipes.length < maxSwipes)) {
      final card = session.current!;
      final key = ItemKey(card.poemId, card.inverted);
      session.revealed(engine);
      final answer = learner.answer(poems[card.poemId], key, wall, introduced: toIntroduce.remove(card.poemId));
      onAnswer?.call(key, wall, answer);
      final responseTs = engine + Duration(microseconds: (answer.ms * 1000).round());
      wall = wall.add(Duration(milliseconds: answer.ms.round())).add(SyntheticLearnerTuning.cardGap);
      session.commit(
        responseTs: responseTs,
        commitTs: responseTs + SyntheticLearnerTuning.responseToCommit,
        outcome: answer.missed ? Outcome.dontKnow : Outcome.known,
        at: wall,
      );
      if (answer.missed && config.mode == PlayMode.training && planner == null) {
        session.requeue(card);
        bool knows(int id) => (newPoems.contains(id) && !toIntroduce.contains(id)) || progress.knows(id);
        final twins = fudaSets.tomofuda(card.poemId).where(knows).toList();
        if (twins.isNotEmpty) session.requeue(CardRef(twins[rng.nextInt(twins.length)]));
      }
      engine = responseTs + SyntheticLearnerTuning.responseToCommit + SyntheticLearnerTuning.commitToNextReveal;
      onCard?.call(session.index, session.cards.length);
    }
    final report = await progress.recordRun(session, config, start, now: wall);
    onReport?.call(report);
    return wall;
  }
}
