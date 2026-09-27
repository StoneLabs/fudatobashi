import 'dart:convert';
import 'dart:math' as math;

import 'package:fsrs/fsrs.dart' as fsrs;

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';
import 'card_stats.dart';

/// When the upside-down (逆さま) version of a card joins training.
enum ReverseMode { afterMastery, mixed, uprightOnly }

/// Beginner journey (learn island by island) or all 100 known from the start.
enum LearningMode { journey, allKnown }

/// Progress on one kana island (an initial-kana group).
class IslandProgress {
  const IslandProgress(this.index, this.name, this.poemIds, this.unlocked, this.solid, this.mastered);
  final int index;
  final String name;
  final List<int> poemIds;
  final int unlocked, solid, mastered;
  int get total => poemIds.length;
  bool get reached => unlocked > 0;
  bool get complete => unlocked == total && solid == total;
}

/// Why the scheduler picked a card (shown on the debug page).
enum PickReason { due, fresh, learning, weak, maintenance, repeat }

class TrainingPick {
  const TrainingPick(this.key, this.reason, this.weight);
  final ItemKey key;
  final PickReason reason;
  final double weight;
}

/// Tunable knobs of the training system (persisted; editable on the debug page).
class TrainerConfig {
  const TrainerConfig({
    this.learningMode = LearningMode.journey,
    this.batchSize = TrainingTuning.defaultBatchSize,
    this.reverseMode = ReverseMode.afterMastery,
    this.sessionLength = TrainingTuning.defaultSessionLength,
    this.easyRatio = TrainingTuning.defaultEasyRatio,
    this.goodRatio = TrainingTuning.defaultGoodRatio,
    this.desiredRetention = TrainingTuning.defaultDesiredRetention,
    this.masteryStabilityDays = TrainingTuning.defaultMasteryStabilityDays,
    this.goalsMs = TrainingTuning.defaultGoalsMs,
  });

  final LearningMode learningMode;
  final int batchSize;
  final ReverseMode reverseMode;
  final int sessionLength;

  /// Time / goal at or below which a correct answer is graded Easy.
  final double easyRatio;

  /// Time / goal at or below which a correct answer is graded Good (else Hard).
  final double goodRatio;
  final double desiredRetention;
  final double masteryStabilityDays;
  final List<int> goalsMs;

  Map<String, Object> toJson() => {
        'learningMode': learningMode.name,
        'batchSize': batchSize,
        'reverseMode': reverseMode.name,
        'sessionLength': sessionLength,
        'easyRatio': easyRatio,
        'goodRatio': goodRatio,
        'desiredRetention': desiredRetention,
        'masteryStabilityDays': masteryStabilityDays,
        'goalsMs': goalsMs,
      };

  factory TrainerConfig.fromJson(Map<String, dynamic> j) => TrainerConfig(
        learningMode: LearningMode.values.asNameMap()[j['learningMode']] ?? LearningMode.journey,
        batchSize: j['batchSize'] as int? ?? TrainingTuning.defaultBatchSize,
        reverseMode: ReverseMode.values.asNameMap()[j['reverseMode']] ?? ReverseMode.afterMastery,
        sessionLength: j['sessionLength'] as int? ?? TrainingTuning.defaultSessionLength,
        easyRatio: (j['easyRatio'] as num?)?.toDouble() ?? TrainingTuning.defaultEasyRatio,
        goodRatio: (j['goodRatio'] as num?)?.toDouble() ?? TrainingTuning.defaultGoodRatio,
        desiredRetention: (j['desiredRetention'] as num?)?.toDouble() ?? TrainingTuning.defaultDesiredRetention,
        masteryStabilityDays:
            (j['masteryStabilityDays'] as num?)?.toDouble() ?? TrainingTuning.defaultMasteryStabilityDays,
        goalsMs: (j['goalsMs'] as List?)?.cast<int>() ?? TrainingTuning.defaultGoalsMs,
      );

  TrainerConfig copyWith({
    LearningMode? learningMode,
    int? batchSize,
    ReverseMode? reverseMode,
    int? sessionLength,
    double? easyRatio,
    double? goodRatio,
    double? desiredRetention,
  }) =>
      TrainerConfig(
        learningMode: learningMode ?? this.learningMode,
        batchSize: batchSize ?? this.batchSize,
        reverseMode: reverseMode ?? this.reverseMode,
        sessionLength: sessionLength ?? this.sessionLength,
        easyRatio: easyRatio ?? this.easyRatio,
        goodRatio: goodRatio ?? this.goodRatio,
        desiredRetention: desiredRetention ?? this.desiredRetention,
        masteryStabilityDays: masteryStabilityDays,
        goalsMs: goalsMs,
      );
}

/// Training state of one item.
class ItemState {
  ItemState(this.key, {this.unlocked = false, this.unlockedAt, fsrs.Card? card, this.maskLevel = 0})
      : card = card ?? fsrs.Card(cardId: key.id, due: DateTime.utc(2000));

  final ItemKey key;
  bool unlocked;
  DateTime? unlockedAt;
  fsrs.Card card;
  int maskLevel;

  /// FSRS has seen at least one review.
  bool get reviewed => card.lastReview != null;

  String get fsrsJson => jsonEncode(card.toMap());

  static fsrs.Card cardFromJson(String s) =>
      fsrs.Card.fromMap(jsonDecode(s) as Map<String, dynamic>);
}

/// The spaced-repetition trainer.
///
/// FSRS models *memory* (when a card is due again); ms statistics model *speed*
/// (what to drill now, and when the player is ready for new cards). Each
/// attempt is turned into an FSRS grade by comparing its time to the goal:
/// miss → Again, ≤ easyRatio·goal → Easy, ≤ goodRatio·goal → Good, else Hard.
class Trainer {
  Trainer({required this.config, required this.items, this.goalLevel = 0})
      : scheduler = _makeScheduler(config);

  TrainerConfig config;
  final Map<ItemKey, ItemState> items;
  int goalLevel;
  fsrs.Scheduler scheduler;

  static fsrs.Scheduler _makeScheduler(TrainerConfig c) =>
      fsrs.Scheduler(desiredRetention: c.desiredRetention);

  void updateConfig(TrainerConfig c) {
    config = c;
    scheduler = _makeScheduler(c);
  }

  static Map<ItemKey, ItemState> freshItems() => {
        for (var id = 1; id <= 100; id++)
          for (final inv in [false, true]) ItemKey(id, inv): ItemState(ItemKey(id, inv)),
      };

  double get goalMs => config.goalsMs[goalLevel.clamp(0, config.goalsMs.length - 1)].toDouble();

  Iterable<ItemState> get unlocked => items.values.where((s) => s.unlocked);

  // ------------------------------------------------------------ grading

  fsrs.Rating gradeFor(AttemptRec a) {
    if (a.miss) return fsrs.Rating.again;
    final r = a.ms / goalMs;
    if (r <= config.easyRatio) return fsrs.Rating.easy;
    if (r <= config.goodRatio) return fsrs.Rating.good;
    return fsrs.Rating.hard;
  }

  /// Feeds one attempt into FSRS. Returns the grade, or null when the attempt
  /// carries no memory evidence (a redo or a corrected card).
  fsrs.Rating? review(ItemKey key, AttemptRec a) {
    if (!a.clean && !a.miss) return null;
    final s = items[key]!;
    final g = gradeFor(a);
    s.card = scheduler.reviewCard(s.card, g, reviewDateTime: a.at.toUtc(), reviewDuration: a.us ~/ 1000).card;
    return g;
  }

  /// Probability of recall now, using fractional days (FSRS-6 forgetting curve).
  double retrievability(ItemKey key, DateTime now) {
    final c = items[key]!.card;
    if (c.lastReview == null || c.stability == null) return 0;
    final decay = -scheduler.parameters[20];
    final factor = math.pow(0.9, 1 / decay) - 1;
    final days = math.max(0, now.toUtc().difference(c.lastReview!).inSeconds / 86400);
    return math.pow(1 + factor * days / c.stability!, decay).toDouble();
  }

  bool isDue(ItemKey key, DateTime now) {
    final s = items[key]!;
    return s.reviewed && !s.card.due.isAfter(now.toUtc());
  }

  /// Memorised for days and fast: FSRS in review with enough stability, and solid.
  bool mastered(ItemKey key, CardStats stats) {
    final c = items[key]!.card;
    return c.state == fsrs.State.review &&
        (c.stability ?? 0) >= config.masteryStabilityDays &&
        stats.solid(goalMs);
  }

  // ------------------------------------------------------------ unlocking

  /// Cards in learning order, grouped into unlock batches. Kimariji families
  /// (cards sharing their first two kana, e.g. あさじ / あさぼらけあ / あさぼらけう)
  /// stay in the same batch so they are learned side by side.
  static List<List<int>> learningBatches(Poems p, FudaSets sets, int batchSize) {
    final batches = <List<int>>[];
    for (final g in initialGroups) {
      // Follow the mnemonic's order (む す め ふ さ ほ せ, う つ し も ゆ, …),
      // then kimariji order so families end up adjacent.
      final members = [...sets['initial:$g'].poemIds]..sort((a, b) {
          final byKana = g.indexOf(p[a].kimariji[0]).compareTo(g.indexOf(p[b].kimariji[0]));
          return byKana != 0 ? byKana : p[a].kimariji.compareTo(p[b].kimariji);
        });
      final families = <List<int>>[];
      for (final id in members) {
        final k = p[id].kimariji;
        final fam = k.length == 1 ? k : k.substring(0, 2);
        if (families.isNotEmpty) {
          final lastK = p[families.last.first].kimariji;
          if (lastK.length > 1 && lastK.substring(0, 2) == fam) {
            families.last.add(id);
            continue;
          }
        }
        families.add([id]);
      }
      var cur = <int>[];
      for (final fam in families) {
        if (cur.isNotEmpty && cur.length + fam.length > batchSize + 1) {
          batches.add(cur);
          cur = [];
        }
        cur.addAll(fam);
        if (cur.length >= batchSize) {
          batches.add(cur);
          cur = [];
        }
      }
      if (cur.isNotEmpty) batches.add(cur);
    }
    return batches;
  }

  /// The next batch of upright cards to unlock, or empty when all are unlocked.
  List<int> nextBatch(Poems p, FudaSets sets) {
    for (final b in learningBatches(p, sets, config.batchSize)) {
      final locked = [for (final id in b) if (!items[ItemKey(id, false)]!.unlocked) id];
      if (locked.isNotEmpty) return locked;
    }
    return const [];
  }

  /// Every unlocked item is solid at the current goal.
  bool readyForMore(Map<ItemKey, CardStats> stats) =>
      unlocked.every((s) => (stats[s.key] ?? CardStats.empty).solid(goalMs));

  /// Unlocks what the player has earned. Returns the newly unlocked items
  /// (celebrate these!).
  List<ItemKey> unlockEarned(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats, DateTime now) {
    final fresh = <ItemKey>[];
    void unlock(ItemKey k) {
      final s = items[k]!;
      if (s.unlocked) return;
      s
        ..unlocked = true
        ..unlockedAt = now;
      fresh.add(k);
    }

    // Reverse items follow mastery of their upright card.
    if (config.reverseMode == ReverseMode.afterMastery) {
      for (final s in unlocked.toList()) {
        if (!s.key.inverted && mastered(s.key, stats[s.key] ?? CardStats.empty)) unlock(s.key.flipped);
      }
    }
    if (config.learningMode == LearningMode.allKnown) {
      for (var id = 1; id <= 100; id++) {
        unlock(ItemKey(id, false));
        if (config.reverseMode == ReverseMode.mixed) unlock(ItemKey(id, true));
      }
      return fresh;
    }
    final nothingYet = unlocked.isEmpty;
    if (nothingYet || readyForMore(stats)) {
      for (final id in nextBatch(p, sets)) {
        unlock(ItemKey(id, false));
        if (config.reverseMode == ReverseMode.mixed) unlock(ItemKey(id, true));
      }
    }
    return fresh;
  }

  /// All cards unlocked and solid: the goal can tighten.
  bool readyForNextGoal(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats) =>
      goalLevel < config.goalsMs.length - 1 && nextBatch(p, sets).isEmpty && readyForMore(stats);

  // ------------------------------------------------------------ islands

  /// Index of the kana island (initial-kana group) a card belongs to.
  static int islandOf(Poem poem) => initialGroups.indexWhere((g) => g.contains(poem.kimariji[0]));

  List<IslandProgress> islands(FudaSets sets, Map<ItemKey, CardStats> stats) => [
        for (final (i, g) in initialGroups.indexed)
          () {
            final ids = sets['initial:$g'].poemIds;
            var u = 0, so = 0, m = 0;
            for (final id in ids) {
              final k = ItemKey(id, false);
              if (!items[k]!.unlocked) continue;
              u++;
              final st = stats[k] ?? CardStats.empty;
              if (st.solid(goalMs)) so++;
              if (mastered(k, st)) m++;
            }
            return IslandProgress(i, g, ids, u, so, m);
          }(),
      ];

  // ------------------------------------------------------------ sessions

  /// Plans a training session: due reviews first, then a weighted mix of
  /// fresh, slow and shaky cards, with a little maintenance of the rest.
  List<TrainingPick> planSession(Map<ItemKey, CardStats> stats, DateTime now, math.Random rng) {
    final pool = unlocked.toList();
    if (pool.isEmpty) return const [];
    final n = config.sessionLength;
    final picks = <TrainingPick>[];

    final due = [for (final s in pool) if (isDue(s.key, now)) s]
      ..sort((a, b) => a.card.due.compareTo(b.card.due));
    for (final s in due.take((n * TrainingTuning.dueShare).round())) {
      picks.add(TrainingPick(s.key, PickReason.due, 1));
    }

    (PickReason, double) weigh(ItemState s) {
      final st = stats[s.key] ?? CardStats.empty;
      if (st.timed.isEmpty) return (PickReason.fresh, TrainingTuning.freshWeight);
      final slow = (st.ewmaMs! / goalMs).clamp(TrainingTuning.slownessClampMin, TrainingTuning.slownessClampMax);
      final miss = st.missRate();
      final hours = now.difference(st.lastSeen!).inMinutes / 60;
      final recency = 1 + math.min(hours / 24, TrainingTuning.recencyCapDays);
      final w = slow * slow * (1 + TrainingTuning.missWeightFactor * miss) * recency;
      if (!st.solid(goalMs)) {
        return (miss > 0 ? PickReason.weak : PickReason.learning, w * TrainingTuning.unsolidWeightMultiplier);
      }
      return (PickReason.maintenance, w * TrainingTuning.maintenanceWeightMultiplier);
    }

    final weighted = [for (final s in pool) (s, weigh(s))];
    while (picks.length < n) {
      final recent =
          picks.reversed.take(math.min(TrainingTuning.recentRepeatWindow, pool.length - 1)).map((p) => p.key).toSet();
      final options = [for (final w in weighted) if (!recent.contains(w.$1.key)) w];
      if (options.isEmpty) break;
      final total = options.fold<double>(0, (a, w) => a + w.$2.$2);
      var r = rng.nextDouble() * total;
      var chosen = options.last;
      for (final w in options) {
        r -= w.$2.$2;
        if (r <= 0) {
          chosen = w;
          break;
        }
      }
      picks.add(TrainingPick(chosen.$1.key, chosen.$2.$1, chosen.$2.$2));
    }
    // Keep due cards from clumping at the start.
    picks.shuffle(rng);
    _spreadRepeats(picks);
    return picks;
  }

  /// Nudges identical neighbours apart where possible.
  static void _spreadRepeats(List<TrainingPick> picks) {
    for (var i = 1; i < picks.length; i++) {
      if (picks[i].key != picks[i - 1].key) continue;
      for (var j = i + 1; j < picks.length; j++) {
        if (picks[j].key != picks[i - 1].key && (j + 1 >= picks.length || picks[j + 1].key != picks[i].key)) {
          final t = picks[i];
          picks[i] = picks[j];
          picks[j] = t;
          break;
        }
      }
    }
  }
}
