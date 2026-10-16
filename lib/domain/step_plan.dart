import 'dart:math' as math;

import '../config/config.dart';
import 'card_stats.dart';

/// How a card's looks are spaced: a due review or a new card of today's
/// set, a card picked for a batch of 30, or a weak side in a 苦手 drill.
enum StepKind { review, newCard, batch, weak }

/// What one card still needs, Anki-style but counted in looks: [base]
/// correct looks, and after any miss [TodaySetTuning.relearnLooks] correct
/// in a row (a weak side: [base] in a row, whatever came before), and no more
/// than [maxLooks] looks when given. Once settled, later looks change nothing.
class CardSteps {
  CardSteps(this.kind, this.base, {this.maxLooks});

  /// A card of today's set: a due review or a new card.
  factory CardSteps.forSet(StepKind kind) =>
      CardSteps(kind, kind == StepKind.newCard ? TodaySetTuning.newLooks : TodaySetTuning.reviewLooks);

  final StepKind kind;
  final int base;
  final int? maxLooks;
  int looks = 0, correct = 0, streak = 0;
  bool missed = false;
  bool done = false;

  CardSteps copy() => CardSteps(kind, base, maxLooks: maxLooks)
    ..looks = looks
    ..correct = correct
    ..streak = streak
    ..missed = missed
    ..done = done;

  /// Correct answers in a row that settle the card.
  int get need => missed && kind != StepKind.weak ? TodaySetTuning.relearnLooks : base;

  /// Looks still to come if every answer is right.
  int get remaining {
    if (done) return 0;
    final left = math.max(0, math.max(base - correct, need - streak));
    final cap = maxLooks;
    return cap == null ? left : math.min(left, cap - looks);
  }

  /// Every look the card takes, those to come included.
  int get total => looks + remaining;

  /// Looks beyond [base], the cost of its misses.
  int get extra => total - base;

  /// Looks so far toward [base], and those beyond it: the first [base]
  /// looks count as the card's own, so the looks a miss adds come last.
  int get baseLooks => math.min(looks, base);
  int get extraLooks => looks - baseLooks;

  void record({required bool miss}) {
    if (done) return;
    looks++;
    if (miss) {
      missed = true;
      streak = 0;
    } else {
      correct++;
      streak++;
    }
    done = (correct >= base && streak >= need) || (maxLooks != null && looks >= maxLooks!);
  }

  /// Cards shown before the card comes back after its latest look.
  int gapAfter({required bool miss}) {
    int step(List<int> gaps, int i) => gaps[i.clamp(0, gaps.length - 1)];
    return switch (kind) {
      StepKind.weak => step(WeakTuning.gaps, miss ? 0 : streak),
      _ when miss => TodaySetTuning.relearnGaps.first,
      _ when missed => step(TodaySetTuning.relearnGaps, streak),
      StepKind.newCard => step(TodaySetTuning.newGaps, correct - 1),
      StepKind.review => step(TodaySetTuning.reviewGaps, correct - 1),
      StepKind.batch => TodaySetTuning.batchGap,
    };
  }
}

/// A card's state while a run is planned.
class _Live {
  _Live(this.steps, {this.started = false});
  final CardSteps steps;
  bool started;

  /// Swipe position from which the card may come back.
  int readyAt = 0;
}

/// The order of a training run whose cards need several looks each (today's
/// set, or a batch of 30). It replays the run's swipes so far and plans the
/// rest as if every answer were right, so as long as they are, the plan
/// never changes; a miss brings its card back after a gap, with one 友札
/// the player knows right after it.
class StepPlan {
  StepPlan({
    required this.start,
    required this.order,
    required this.fillers,
    required this.knownBefore,
    required this.twinsOf,
    this.seed = 0,
    this.fillGaps = false,
  });

  /// Today's set: [start] holds each card not settled yet. Cards looked at
  /// earlier today come back first; the rest open with
  /// [TrainingTuning.newCardHoldBack] reviews (when there are that many),
  /// and [newCards] (in learning order) are spread evenly among the other
  /// reviews.
  factory StepPlan.forSet({
    required Map<ItemKey, CardSteps> start,
    required List<ItemKey> reviews,
    required List<ItemKey> newCards,
    required List<ItemKey> fillers,
    required Set<int> knownBefore,
    required Iterable<int> Function(int poemId) twinsOf,
    int seed = 0,
  }) {
    final unstarted = start.keys.where((k) => start[k]!.looks == 0).toSet();
    final opening = reviews.where(unstarted.contains).take(TrainingTuning.newCardHoldBack).toList();
    final rest = [for (final k in reviews) if (unstarted.contains(k) && !opening.contains(k)) k];
    final fresh = newCards.where(unstarted.contains).toList();
    final slots = rest.length + fresh.length;
    final mixed = <ItemKey>[];
    var r = 0, n = 0;
    for (var s = 0; s < slots; s++) {
      final newHere = n < fresh.length && s == ((n + 0.5) * slots / fresh.length).floor();
      mixed.add(newHere || r >= rest.length ? fresh[n++] : rest[r++]);
    }
    return StepPlan(
      start: start,
      order: [...opening, ...mixed],
      fillers: fillers,
      knownBefore: knownBefore,
      twinsOf: twinsOf,
      seed: seed,
    );
  }

  /// A batch: each card needs as many looks as it was picked, in the order
  /// of its first pick, [TodaySetTuning.batchGap] cards apart.
  factory StepPlan.forBatch({
    required List<ItemKey> picks,
    required Set<int> knownBefore,
    required Iterable<int> Function(int poemId) twinsOf,
    int seed = 0,
  }) {
    final counts = <ItemKey, int>{};
    for (final k in picks) {
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return StepPlan(
      start: {for (final e in counts.entries) e.key: CardSteps(StepKind.batch, e.value)},
      order: counts.keys.toList(),
      fillers: const [],
      knownBefore: knownBefore,
      twinsOf: twinsOf,
      seed: seed,
    );
  }

  /// 苦手: each of [targets] needs [WeakTuning.clearLooks] fast answers in a
  /// row, at most [WeakTuning.maxLooks] looks (the caller counts a slow
  /// answer as a miss). The drill opens with a quick card from [anchors],
  /// puts each target's look-alike from [lookAlikes] right after it, and
  /// another quick card after every [WeakTuning.anchorEvery] targets; each
  /// of those needs one look. [fillers] are shown rather than a weak side
  /// coming back before its gap.
  factory StepPlan.forWeak({
    required List<ItemKey> targets,
    required Map<ItemKey, ItemKey> lookAlikes,
    required List<ItemKey> anchors,
    required List<ItemKey> fillers,
    required Set<int> knownBefore,
    required Iterable<int> Function(int poemId) twinsOf,
    int seed = 0,
  }) {
    final order = <ItemKey>[];
    final quick = anchors.iterator;
    void add(ItemKey? k) {
      if (k != null && !order.contains(k) && !targets.contains(k)) order.add(k);
    }

    void anchor() => add(quick.moveNext() ? quick.current : null);
    anchor();
    for (final (i, t) in targets.indexed) {
      order.add(t);
      add(lookAlikes[t]);
      if ((i + 1) % WeakTuning.anchorEvery == 0) anchor();
    }
    return StepPlan(
      start: {
        for (final k in order)
          k: targets.contains(k)
              ? CardSteps(StepKind.weak, WeakTuning.clearLooks, maxLooks: WeakTuning.maxLooks)
              : CardSteps(StepKind.batch, 1),
      },
      order: order,
      fillers: fillers,
      knownBefore: knownBefore,
      twinsOf: twinsOf,
      seed: seed,
      fillGaps: true,
    );
  }

  /// Each card's state as the run starts.
  final Map<ItemKey, CardSteps> start;

  /// The first looks of the cards not started yet.
  final List<ItemKey> order;

  /// Cards with nothing left to do, shown in between when only the card just
  /// shown is left.
  final List<ItemKey> fillers;

  /// Cards the player knew before the run (a 友札 is always one they know).
  final Set<int> knownBefore;
  final Iterable<int> Function(int poemId) twinsOf;
  final int seed;

  /// A filler waits in between rather than a card coming back early, and
  /// each filler is shown once.
  final bool fillGaps;

  /// The cards of the run, in order, before its first swipe.
  List<ItemKey> get cards => upcoming(const []);

  /// The rest of the run after [swipes] (card and whether it was a miss, in
  /// order), with [next] already on screen when given.
  List<ItemKey> upcoming(List<(ItemKey, bool)> swipes, {ItemKey? next}) {
    final live = {for (final e in start.entries) e.key: _Live(e.value.copy(), started: e.value.looks > 0)};
    final met = <int>{};
    int? lastNew;
    var pos = 0;

    void look(ItemKey key, {required bool miss}) {
      final card = live[key] ??= _Live(CardSteps(StepKind.batch, 0));
      if (!card.started && card.steps.kind == StepKind.newCard) lastNew = pos;
      card.started = true;
      card.steps.record(miss: miss);
      card.readyAt = pos + 1 + card.steps.gapAfter(miss: miss);
      met.add(key.poemId);
      if (miss) _addTwin(live, key, card.readyAt + 1, met, pos);
      pos++;
    }

    for (final (key, miss) in swipes) {
      look(key, miss: miss);
    }
    final out = <ItemKey>[];
    ItemKey? last = swipes.isEmpty ? null : swipes.last.$1;
    if (next != null) {
      look(next, miss: false);
      last = next;
    }
    var cursor = 0;
    while (true) {
      while (cursor < order.length && live[order[cursor]]!.started) {
        cursor++;
      }
      final pick = _pick(live, pos, last, lastNew, cursor);
      if (pick == null) break;
      final (key, filler) = pick;
      if (filler) {
        pos++;
      } else {
        look(key, miss: false);
      }
      out.add(key);
      last = key;
    }
    return out;
  }

  /// After a miss on [key], one 友札 the player knows gets a look of its own
  /// right after the missed card comes back.
  void _addTwin(Map<ItemKey, _Live> live, ItemKey key, int readyAt, Set<int> met, int pos) {
    final twins = [for (final id in twinsOf(key.poemId)) if (knownBefore.contains(id) || met.contains(id)) id];
    if (twins.isEmpty) return;
    final twin = ItemKey(twins[(seed + pos) % twins.length], false);
    if (twin == key || (live[twin]?.steps.remaining ?? 0) > 0) return;
    live[twin] = _Live(CardSteps(StepKind.batch, 1), started: true)..readyAt = readyAt;
  }

  /// The card for position [pos], and whether it only fills in; null when
  /// the run is over. [order] is started up to [cursor].
  (ItemKey, bool)? _pick(Map<ItemKey, _Live> live, int pos, ItemKey? last, int? lastNew, int cursor) {
    ItemKey? earliest({required bool ready}) {
      ItemKey? best;
      for (final e in live.entries) {
        final c = e.value;
        if (!c.started || c.steps.remaining == 0 || e.key == last || (ready && c.readyAt > pos)) continue;
        if (best == null || c.readyAt < live[best]!.readyAt) best = e.key;
      }
      return best;
    }

    final due = earliest(ready: true);
    if (due != null) return (due, false);
    if (cursor < order.length) {
      final first = order[cursor];
      final spaced = lastNew == null || pos - lastNew >= TodaySetTuning.newSpacing;
      if (live[first]!.steps.kind != StepKind.newCard || spaced) return (first, false);
      for (var i = cursor + 1; i < order.length; i++) {
        final c = live[order[i]]!;
        if (!c.started && c.steps.kind != StepKind.newCard) return (order[i], false);
      }
      return (first, false);
    }
    final others = [
      for (final k in fillers)
        if (k != last && !(fillGaps && (live[k]?.started ?? false))) k,
    ];
    final early = earliest(ready: false);
    if (early != null && (!fillGaps || others.isEmpty)) return (early, false);
    if (early == null && (last == null || (live[last]?.steps.remaining ?? 0) == 0)) return null;
    if (others.isNotEmpty) return (others[(seed + pos) % others.length], true);
    return (last!, false);
  }
}
