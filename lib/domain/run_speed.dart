import 'dart:math' as math;

import '../config/config.dart';
import 'card_stats.dart';
import 'run_review.dart';

/// One card of a run as the Speed tab reads it: its last swipe, its place
/// in the run (1-based), and whether it was a miss (an undone swipe before
/// it counts).
class SpeedCard {
  const SpeedCard(this.swipe, this.number, {required this.miss});
  final RunSwipe swipe;
  final int number;
  final bool miss;

  /// The swipe's time, ms.
  double get ms => math.max(0, swipe.ms);

  /// Right and cleanly timed: it counts for the averages.
  bool get timed => !miss && swipe.timed;
}

/// A stretch of a run's cards, [from] to [to] (1-based): the average time
/// of its timed cards (null when none) and its misses.
class SpeedSpan {
  SpeedSpan(this.from, List<SpeedCard> cards)
      : to = from + cards.length - 1,
        meanMs = _mean(cards),
        misses = cards.where((c) => c.miss).length;

  final int from, to;
  final double? meanMs;
  final int misses;
}

/// How a card went on the Speed tab's strip.
enum CardPace {
  miss,

  /// At or under the goal × `XpTuning.blazingRatio`.
  fast,
  underGoal,
  overGoal,

  /// Over the goal × `RunSpeedTuning.slowRatio`.
  slow,
}

/// One side of the cards (upright or upside-down): how many, how many
/// missed, and the average time of the timed ones.
typedef SpeedSide = ({int cards, int misses, double? meanMs});

/// Cards whose 決まり字 has [length] kana: how many, how many missed, their
/// average time and the average of their usual times.
typedef KimarijiSpeed = ({int length, int cards, int misses, double? meanMs, double? usualMs});

/// A card against its usual time: [diffMs] below 0 is faster than usual.
typedef UsualDiff = ({SpeedCard card, double diffMs});

/// The run's timed cards that have a usual time, against it: both totals,
/// how many went faster, and the cards that gained and lost the most.
class AgainstUsual {
  AgainstUsual(List<UsualDiff> diffs)
      : compared = diffs.length,
        usualMs = diffs.fold(0, (t, d) => t + d.card.ms - d.diffMs),
        runMs = diffs.fold(0, (t, d) => t + d.card.ms),
        faster = diffs.where((d) => d.diffMs < 0).length,
        gained = [
          for (final d in [...diffs]..sort((a, b) => a.diffMs.compareTo(b.diffMs)))
            if (d.diffMs < 0) d,
        ].take(RunReviewTuning.shownCards).toList(),
        lost = [
          for (final d in [...diffs]..sort((a, b) => b.diffMs.compareTo(a.diffMs)))
            if (d.diffMs > 0) d,
        ].take(RunReviewTuning.shownCards).toList();

  final int compared, faster;
  final double usualMs, runMs;
  final List<UsualDiff> gained, lost;
}

/// The Speed tab's maths over a run's swipes: swipe times only, without
/// the miss penalties.
class RunSpeed {
  RunSpeed(
    List<RunSwipe> swipes, {
    this.goalMs,
    this.usualMs = const {},
    required this.kimarijiLength,
  }) : cards = _cardsOf(swipes);

  final List<SpeedCard> cards;

  /// The run's goal time per card, when known.
  final double? goalMs;

  /// Each card's usual time before the run, by `ItemKey.id`.
  final Map<int, double> usualMs;

  /// The number of kana in a card's 決まり字.
  final int Function(int poemId) kimarijiLength;

  static List<SpeedCard> _cardsOf(List<RunSwipe> swipes) {
    final cards = <SpeedCard>[];
    var undone = false;
    for (final s in swipes) {
      if (s.undone) {
        undone = true;
        continue;
      }
      cards.add(SpeedCard(s, cards.length + 1, miss: s.miss || undone));
      undone = false;
    }
    return cards;
  }

  /// The average time of the timed cards.
  late final double? meanMs = _mean(cards);

  /// The first, middle and last third of the cards.
  late final List<SpeedSpan> thirds = () {
    final n = cards.length;
    final cut = [0, (n / 3).round(), (2 * n / 3).round(), n];
    return [
      for (var i = 0; i < 3; i++)
        if (cut[i + 1] > cut[i]) SpeedSpan(cut[i] + 1, cards.sublist(cut[i], cut[i + 1])),
    ];
  }();

  /// Blocks of [RunSpeedTuning.blockCards] cards, the last maybe shorter.
  late final List<SpeedSpan> blocks = [
    for (var i = 0; i < cards.length; i += RunSpeedTuning.blockCards)
      SpeedSpan(i + 1, cards.sublist(i, math.min(cards.length, i + RunSpeedTuning.blockCards))),
  ];

  /// The slowest and fastest of [spans] by average time, null when fewer
  /// than two have one.
  static ({SpeedSpan slowest, SpeedSpan fastest})? extremes(List<SpeedSpan> spans) {
    final timed = [for (final s in spans) if (s.meanMs != null) s];
    if (timed.length < 2) return null;
    timed.sort((a, b) => a.meanMs!.compareTo(b.meanMs!));
    return (slowest: timed.last, fastest: timed.first);
  }

  /// The [RunSpeedTuning.blockCards] cards in a row with the least swipe
  /// time, null when the run is shorter.
  late final ({int from, int to, double ms})? fastestStretch = () {
    const k = RunSpeedTuning.blockCards;
    if (cards.length < k) return null;
    var sum = cards.take(k).fold<double>(0, (t, c) => t + c.ms);
    var best = (from: 1, to: k, ms: sum);
    for (var i = k; i < cards.length; i++) {
      sum += cards[i].ms - cards[i - k].ms;
      if (sum < best.ms) best = (from: i - k + 2, to: i + 1, ms: sum);
    }
    return best;
  }();

  /// The longest row of right cards at or under the goal, null when none
  /// or the goal is unknown.
  late final ({int from, int to})? longestUnderGoal = () {
    final goal = goalMs;
    if (goal == null) return null;
    ({int from, int to})? best;
    var run = 0;
    for (final (i, c) in cards.indexed) {
      run = !c.miss && c.ms <= goal ? run + 1 : 0;
      if (run > 0 && (best == null || run > best.to - best.from + 1)) best = (from: i - run + 2, to: i + 1);
    }
    return best;
  }();

  /// How [card] went against the goal; without a goal, right cards count
  /// as under it.
  CardPace paceOf(SpeedCard card) {
    final goal = goalMs;
    if (card.miss) return CardPace.miss;
    if (goal == null) return CardPace.underGoal;
    if (card.ms <= goal * XpTuning.blazingRatio) return CardPace.fast;
    if (card.ms <= goal) return CardPace.underGoal;
    return card.ms > goal * RunSpeedTuning.slowRatio ? CardPace.slow : CardPace.overGoal;
  }

  late final SpeedSide upright = _side(false);
  late final SpeedSide upsideDown = _side(true);

  SpeedSide _side(bool inverted) {
    final side = [for (final c in cards) if (c.swipe.inverted == inverted) c];
    return (cards: side.length, misses: side.where((c) => c.miss).length, meanMs: _mean(side));
  }

  /// [card]'s usual time on its side before the run, if it had one.
  double? usualOf(SpeedCard card) => usualMs[ItemKey(card.swipe.poemId, card.swipe.inverted).id];

  /// The cards by their 決まり字's length, shortest first.
  late final List<KimarijiSpeed> byKimariji = () {
    final groups = <int, List<SpeedCard>>{};
    for (final c in cards) {
      (groups[kimarijiLength(c.swipe.poemId)] ??= []).add(c);
    }
    final usual = [for (final c in cards) if (usualOf(c) case final u?) (c, u)];
    return [
      for (final length in groups.keys.toList()..sort())
        (
          length: length,
          cards: groups[length]!.length,
          misses: groups[length]!.where((c) => c.miss).length,
          meanMs: _mean(groups[length]!),
          usualMs: _average([for (final (c, u) in usual) if (kimarijiLength(c.swipe.poemId) == length) u]),
        ),
    ];
  }();

  /// The timed cards against their usual times.
  late final AgainstUsual againstUsual = AgainstUsual([
    for (final c in cards)
      if (c.timed)
        if (usualOf(c) case final u?) (card: c, diffMs: c.ms - u),
  ]);
}

double? _mean(List<SpeedCard> cards) => _average([for (final c in cards) if (c.timed) c.ms]);

double? _average(List<double> values) => values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
