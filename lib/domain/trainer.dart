import 'dart:math' as math;

import 'package:fsrs/fsrs.dart' as fsrs;

import '../config/config.dart';
import '../data/fuda_sets.dart';
import '../data/poem.dart';
import 'card_stats.dart';
import 'day_window.dart';
import 'learning_pace.dart';

export 'learning_pace.dart';

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

/// How ready the player is for new cards: most unlocked upright cards solid,
/// and every card of the latest batch practised a few times.
class Readiness {
  const Readiness({required this.unlocked, required this.solid, required this.latestBatch, required this.underPractised});

  /// Unlocked upright cards.
  final int unlocked;

  /// Of those, the solid ones.
  final int solid;

  /// The most advanced batch with an unlocked card (poem ids).
  final List<int> latestBatch;

  /// Cards of [latestBatch] with fewer than [TrainingTuning.newCardMinTimed]
  /// timed attempts.
  final List<int> underPractised;

  int get shaky => unlocked - solid;
  double get solidFraction => unlocked == 0 ? 1 : solid / unlocked;
  bool get ready => solidFraction >= PaceTuning.readySolidFraction && underPractised.isEmpty;
}

/// Why the journey is not auto-unlocking the next batch right now.
enum UnlockHold { none, allUnlocked, notReady, aheadOfPace, dailyCap }

/// Where the journey stands against its pace curve.
class PaceStatus {
  const PaceStatus({
    required this.pace,
    required this.day,
    required this.unlocked,
    required this.total,
    required this.newToday,
    required this.readiness,
    required this.nextBatch,
  });

  final LearningPace pace;

  /// Journey day (0 = the day of the first unlock).
  final int day;
  final int unlocked, total;

  /// Upright cards unlocked today, manual pulls included.
  final int newToday;
  final Readiness readiness;
  final List<int> nextBatch;

  /// Cards expected unlocked by the end of today.
  int get target => pace.targetUnlocked(day, total);

  /// New cards the pace schedules for today in total, at least [newToday]
  /// (a catch-up day is never shown as already past its own quota).
  int get newCardsQuota => math.max(newToday, target - (unlocked - newToday));

  UnlockHold get hold {
    if (nextBatch.isEmpty) return UnlockHold.allUnlocked;
    if (unlocked >= target) return UnlockHold.aheadOfPace;
    if (newToday >= pace.profile.dailyAutoCap) return UnlockHold.dailyCap;
    if (!readiness.ready) return UnlockHold.notReady;
    return UnlockHold.none;
  }

  /// First journey day whose target exceeds the unlocked count (when the curve
  /// lets the next batch in), or null when every card is unlocked.
  int? get nextPaceDay {
    if (nextBatch.isEmpty) return null;
    var d = day;
    while (pace.targetUnlocked(d, total) <= unlocked) {
      d++;
    }
    return d;
  }
}

/// Why Home's "Learn ahead" is locked. It pulls cards in ahead of the
/// pace, so it waits until the player has nothing left to consolidate.
enum LearnAheadLock {
  /// Open: the cards are well remembered and today's new cards are done.
  none,

  /// Every card is unlocked; there is nothing to learn ahead.
  allUnlocked,

  /// Some unlocked cards are not well remembered yet (see
  /// [Trainer.learnAhead]).
  shaky,

  /// The pace still has new cards for today; 修行 brings them in.
  newCardsPending,
}

/// Whether the player may pull the next batch in early, and why not.
class LearnAhead {
  const LearnAhead({required this.lock, required this.unlocked, required this.shaky});

  final LearnAheadLock lock;

  /// Unlocked upright cards.
  final int unlocked;

  /// Of those, the ones that keep it locked: each card not
  /// [Trainer.remembered], and the slow ones beyond the share
  /// [LearnAheadTuning.minQuickPercent] lets through.
  final int shaky;

  bool get open => lock == LearnAheadLock.none;
}

/// Tunable knobs of the training system (persisted; editable on the debug page).
class TrainerConfig {
  const TrainerConfig({
    this.learningMode = LearningMode.journey,
    this.pace = PaceTuning.defaultPace,
    this.batchSize = TrainingTuning.defaultBatchSize,
    this.reverseMode = ReverseMode.afterMastery,
    this.sessionLengthOverride,
    this.easyMs = TrainingTuning.defaultEasyMs,
    this.goodRatio = TrainingTuning.defaultGoodRatio,
    this.desiredRetention = TrainingTuning.defaultDesiredRetention,
    this.masteryStabilityDays = TrainingTuning.defaultMasteryStabilityDays,
    this.goalsMs = TrainingTuning.defaultGoalsMs,
  });

  final LearningMode learningMode;
  final LearningPace pace;
  final int batchSize;
  final ReverseMode reverseMode;

  /// The debug page's round length, or null for the mode's default.
  final int? sessionLengthOverride;

  /// Cards in a 修行 round.
  int get sessionLength =>
      sessionLengthOverride ??
      (learningMode == LearningMode.allKnown
          ? TrainingTuning.allKnownSessionLength
          : TrainingTuning.defaultSessionLength);

  /// Time, ms, at or below which a correct answer is graded Easy.
  final int easyMs;

  /// Time / goal at or below which a correct answer is graded Good (else Hard).
  final double goodRatio;
  final double desiredRetention;
  final double masteryStabilityDays;
  final List<int> goalsMs;

  Map<String, Object?> toJson() => {
        'learningMode': learningMode.name,
        'pace': pace.name,
        'batchSize': batchSize,
        'reverseMode': reverseMode.name,
        'sessionLengthOverride': sessionLengthOverride,
        'easyMs': easyMs,
        'goodRatio': goodRatio,
        'desiredRetention': desiredRetention,
        'masteryStabilityDays': masteryStabilityDays,
        'goalsMs': goalsMs,
      };

  factory TrainerConfig.fromJson(Map<String, dynamic> j) => TrainerConfig(
        learningMode: LearningMode.values.asNameMap()[j['learningMode']] ?? LearningMode.journey,
        pace: LearningPace.values.asNameMap()[j['pace']] ?? PaceTuning.defaultPace,
        batchSize: j['batchSize'] as int? ?? TrainingTuning.defaultBatchSize,
        reverseMode: ReverseMode.values.asNameMap()[j['reverseMode']] ?? ReverseMode.afterMastery,
        // The old always-written `sessionLength` is ignored, so the round
        // follows the mode's default unless set on the debug page.
        sessionLengthOverride: j['sessionLengthOverride'] as int?,
        // The old `easyRatio` (a share of the goal) is ignored.
        easyMs: j['easyMs'] as int? ?? TrainingTuning.defaultEasyMs,
        goodRatio: (j['goodRatio'] as num?)?.toDouble() ?? TrainingTuning.defaultGoodRatio,
        desiredRetention: (j['desiredRetention'] as num?)?.toDouble() ?? TrainingTuning.defaultDesiredRetention,
        masteryStabilityDays:
            (j['masteryStabilityDays'] as num?)?.toDouble() ?? TrainingTuning.defaultMasteryStabilityDays,
        goalsMs: (j['goalsMs'] as List?)?.cast<int>() ?? TrainingTuning.defaultGoalsMs,
      );

  TrainerConfig copyWith({
    LearningMode? learningMode,
    LearningPace? pace,
    int? batchSize,
    ReverseMode? reverseMode,
    int? sessionLengthOverride,
    int? easyMs,
    double? goodRatio,
    double? desiredRetention,
  }) =>
      TrainerConfig(
        learningMode: learningMode ?? this.learningMode,
        pace: pace ?? this.pace,
        batchSize: batchSize ?? this.batchSize,
        reverseMode: reverseMode ?? this.reverseMode,
        sessionLengthOverride: sessionLengthOverride ?? this.sessionLengthOverride,
        easyMs: easyMs ?? this.easyMs,
        goodRatio: goodRatio ?? this.goodRatio,
        desiredRetention: desiredRetention ?? this.desiredRetention,
        masteryStabilityDays: masteryStabilityDays,
        goalsMs: goalsMs,
      );
}

/// Training state of one item.
class ItemState {
  ItemState(this.key, {this.unlocked = false, this.unlockedAt, fsrs.Card? card})
      : card = card ?? fsrs.Card(cardId: key.id, due: DateTime.utc(2000));

  final ItemKey key;
  bool unlocked;
  DateTime? unlockedAt;
  fsrs.Card card;

  /// FSRS has seen at least one review.
  bool get reviewed => card.lastReview != null;
}

/// The spaced-repetition trainer.
///
/// FSRS models *memory* (when a card is due again); ms statistics model *speed*
/// (what to drill now, and when the player is ready for new cards). Each
/// attempt is turned into an FSRS grade by its time: miss → Again,
/// ≤ easyMs → Easy, ≤ goodRatio·goal → Good, else Hard.
class Trainer {
  Trainer({
    required this.config,
    required this.items,
    this.goalLevel = 0,
    this.dayStartHour = TodaySetTuning.defaultDayStartHour,
  }) : scheduler = schedulerFor(config);

  TrainerConfig config;
  final Map<ItemKey, ItemState> items;
  int goalLevel;
  fsrs.Scheduler scheduler;

  /// The local hour at which a new day begins.
  int dayStartHour;

  bool _fuzzing = true;

  /// Whether the scheduler randomly spreads its review intervals. Off, a
  /// simulation replays exactly.
  set fuzzing(bool on) {
    _fuzzing = on;
    scheduler = schedulerFor(config, fuzzing: on);
  }

  static fsrs.Scheduler schedulerFor(TrainerConfig c, {bool fuzzing = true}) =>
      fsrs.Scheduler(desiredRetention: c.desiredRetention, enableFuzzing: fuzzing);

  void updateConfig(TrainerConfig c) {
    config = c;
    scheduler = schedulerFor(c, fuzzing: _fuzzing);
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
    if (a.ms <= config.easyMs) return fsrs.Rating.easy;
    if (a.ms / goalMs <= config.goodRatio) return fsrs.Rating.good;
    return fsrs.Rating.hard;
  }

  /// Feeds one attempt into FSRS and returns its grade, or null when the attempt
  /// carries no long-term memory evidence: a redo, a corrected card, or a
  /// correct answer on a card that is not due yet. Players keep drilling after
  /// their dues are done; those extra swipes train speed (see [CardStats]) but
  /// would otherwise inflate FSRS stability with short-term recall. A correct
  /// answer without a valid time can't be graded either. A miss always counts,
  /// since failing a card is evidence of forgetting.
  ///
  /// A card in FSRS's learning or relearning steps is due once its step is
  /// up, so every answer from then on is graded until it graduates, the same
  /// day if the player keeps at it. Journey mode grades reviews by the day:
  /// given [dayEnd], a review is due when it falls before the day ends, and
  /// only while the day has not graded the card yet ([firstToday]), so the
  /// looks today's set asks for after it are never extra reviews.
  fsrs.Rating? review(ItemKey key, AttemptRec a, {DateTime? dayEnd, bool firstToday = true}) {
    if (!a.miss && !a.timed) return null;
    final s = items[key]!;
    if (!a.miss && !_gradable(s, a.at.toUtc(), dayEnd: dayEnd, firstToday: firstToday)) return null;
    final g = gradeFor(a);
    s.card = scheduler.reviewCard(s.card, g, reviewDateTime: a.at.toUtc(), reviewDuration: a.us ~/ 1000).card;
    return g;
  }

  /// Whether a correct answer at [at] is a review of [s] (see [review]).
  static bool _gradable(ItemState s, DateTime at, {DateTime? dayEnd, required bool firstToday}) {
    if (!s.reviewed) return true;
    final c = s.card;
    if (dayEnd == null || c.state != fsrs.State.review) return !c.due.isAfter(at);
    return firstToday && c.due.isBefore(dayEnd.toUtc());
  }

  /// Probability of recall now, using fractional days (FSRS-6 forgetting curve).
  double retrievability(ItemKey key, DateTime now) => recallOf(items[key]!.card, scheduler, now);

  /// [card]'s probability of recall at [now] under [scheduler]; 0 before its
  /// first review.
  static double recallOf(fsrs.Card card, fsrs.Scheduler scheduler, DateTime now) {
    if (card.lastReview == null || card.stability == null) return 0;
    final decay = -scheduler.parameters[20];
    final factor = math.pow(0.9, 1 / decay) - 1;
    final days = math.max(0, now.toUtc().difference(card.lastReview!).inSeconds / 86400);
    return math.pow(1 + factor * days / card.stability!, decay).toDouble();
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
  bool allSolid(Map<ItemKey, CardStats> stats) =>
      unlocked.every((s) => (stats[s.key] ?? CardStats.empty).solid(goalMs));

  Iterable<ItemState> get _uprightUnlocked => unlocked.where((s) => !s.key.inverted);

  Readiness readiness(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats) {
    final up = _uprightUnlocked.toList();
    final solid = up.where((s) => (stats[s.key] ?? CardStats.empty).solid(goalMs)).length;
    final latest = learningBatches(p, sets, config.batchSize).lastWhere(
      (b) => b.any((id) => items[ItemKey(id, false)]!.unlocked),
      orElse: () => const [],
    );
    return Readiness(
      unlocked: up.length,
      solid: solid,
      latestBatch: latest,
      underPractised: [
        for (final id in latest)
          if (items[ItemKey(id, false)]!.unlocked &&
              (stats[ItemKey(id, false)] ?? CardStats.empty).timed.length < TrainingTuning.newCardMinTimed)
            id,
      ],
    );
  }

  /// When the journey began: the earliest upright unlock.
  DateTime? get journeyStart {
    DateTime? first;
    for (final s in _uprightUnlocked) {
      final at = s.unlockedAt;
      if (at != null && (first == null || at.isBefore(first))) first = at;
    }
    return first;
  }

  /// Days from the journey's start to [now] (0 on its first day).
  int journeyDay(DateTime now) {
    final start = journeyStart;
    return start == null ? 0 : math.max(0, daysBetween(start, now, dayStartHour: dayStartHour));
  }

  /// Days (local time, each starting at [dayStartHour]) from [a] to [b]: 0
  /// on the same day, negative when [b] is earlier.
  static int daysBetween(DateTime a, DateTime b, {int dayStartHour = 0}) =>
      DayWindow.at(b, dayStartHour).date.difference(DayWindow.at(a, dayStartHour).date).inDays;

  PaceStatus paceStatus(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats, DateTime now) {
    final up = _uprightUnlocked.toList();
    return PaceStatus(
      pace: config.pace,
      day: journeyDay(now),
      unlocked: up.length,
      total: items.length ~/ 2,
      newToday: up
          .where((s) => s.unlockedAt != null && daysBetween(s.unlockedAt!, now, dayStartHour: dayStartHour) == 0)
          .length,
      readiness: readiness(p, sets, stats),
      nextBatch: nextBatch(p, sets),
    );
  }

  /// Remembered: practised, its latest answer correct, at most the odd slip
  /// lately, and no FSRS review or learning step due. More forgiving than
  /// [CardStats.solid], which one slip resets, so a whole deck can be
  /// remembered at once.
  bool remembered(ItemKey key, CardStats stats, DateTime now) =>
      stats.timed.length >= StatsTuning.solidMinTimed &&
      !stats.all.last.miss &&
      !isDue(key, now) &&
      stats.missRate(LearnAheadTuning.recentWindow) <= LearnAheadTuning.maxRecentMissRate;

  /// Quick: its latest [LearnAheadTuning.speedWindow] timed answers take
  /// [LearnAheadTuning.quickMs] or less on average.
  static bool quick(CardStats stats) =>
      (stats.mean(LearnAheadTuning.speedWindow) ?? double.infinity) <= LearnAheadTuning.quickMs;

  /// Well remembered: [remembered] and [quick].
  bool wellRemembered(ItemKey key, CardStats stats, DateTime now) => remembered(key, stats, now) && quick(stats);

  /// Unlocked upright cards well remembered right now.
  int wellRememberedCount(Map<ItemKey, CardStats> stats, DateTime now) =>
      _uprightUnlocked.where((s) => wellRemembered(s.key, stats[s.key] ?? CardStats.empty, now)).length;

  /// Home's "Learn ahead": open once every unlocked card is [remembered] and
  /// at least [LearnAheadTuning.minQuickPercent] of them are also [quick],
  /// and today has no new cards of its own left.
  /// [newPending]: today's set still has new cards to settle; without a
  /// set, the pace still has new cards for today.
  LearnAhead learnAhead(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats, DateTime now, {bool? newPending}) {
    final up = _uprightUnlocked.toList();
    var forgotten = 0, slow = 0;
    for (final s in up) {
      final st = stats[s.key] ?? CardStats.empty;
      if (!remembered(s.key, st, now)) {
        forgotten++;
      } else if (!quick(st)) {
        slow++;
      }
    }
    final slowAllowed = up.length * (100 - LearnAheadTuning.minQuickPercent) ~/ 100;
    final shaky = forgotten + math.max<int>(0, slow - slowAllowed);
    final pace = paceStatus(p, sets, stats, now);
    return LearnAhead(
      lock: pace.hold == UnlockHold.allUnlocked
          ? LearnAheadLock.allUnlocked
          : shaky > 0
              ? LearnAheadLock.shaky
              : newPending ?? pace.hold == UnlockHold.none
                  ? LearnAheadLock.newCardsPending
                  : LearnAheadLock.none,
      unlocked: up.length,
      shaky: shaky,
    );
  }

  List<ItemKey> _unlock(Iterable<ItemKey> keys, DateTime now) {
    final fresh = [for (final k in keys) if (!items[k]!.unlocked) k];
    for (final k in fresh) {
      items[k]!
        ..unlocked = true
        ..unlockedAt = now;
    }
    return fresh;
  }

  List<ItemKey> _batchKeys(List<int> ids) => [
        for (final id in ids) ...[
          ItemKey(id, false),
          if (config.reverseMode == ReverseMode.mixed) ItemKey(id, true),
        ],
      ];

  /// Unlocks the next batch now, whatever the pace and readiness say (the
  /// player's "Learn ahead"). Returns the newly unlocked items.
  List<ItemKey> unlockNextBatch(Poems p, FudaSets sets, DateTime now) =>
      _unlock(_batchKeys(nextBatch(p, sets)), now);

  /// Unlocks what the player has earned. Returns the newly unlocked items
  /// (celebrate these!). Without [batches] the journey's new cards wait for
  /// the morning ([unlockForToday]); reverse items still follow mastery.
  List<ItemKey> unlockEarned(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats, DateTime now,
      {bool batches = true}) {
    final fresh = <ItemKey>[];
    // Reverse items follow mastery of their upright card.
    if (config.reverseMode == ReverseMode.afterMastery) {
      fresh.addAll(_unlock([
        for (final s in _uprightUnlocked.toList())
          if (mastered(s.key, stats[s.key] ?? CardStats.empty)) s.key.flipped,
      ], now));
    }
    if (config.learningMode == LearningMode.allKnown) {
      return fresh..addAll(_unlock(_batchKeys([for (var id = 1; id <= items.length ~/ 2; id++) id]), now));
    }
    if (batches && (unlocked.isEmpty || paceStatus(p, sets, stats, now).hold == UnlockHold.none)) {
      fresh.addAll(unlockNextBatch(p, sets, now));
    }
    return fresh;
  }

  /// The journey's new cards for today, all at once in the morning: whole
  /// batches until the pace's target for today or its daily cap is reached.
  List<ItemKey> unlockForToday(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats, DateTime now) {
    final batches = <List<ItemKey>>[];
    while (true) {
      final pace = paceStatus(p, sets, stats, now);
      final hold = pace.hold;
      if (hold != UnlockHold.none && hold != UnlockHold.notReady && pace.unlocked > 0) break;
      final batch = unlockNextBatch(p, sets, now);
      if (batch.isEmpty) break;
      batches.add(batch);
    }
    return [for (final b in batches) ...b];
  }

  /// All cards unlocked and solid: the goal can tighten.
  bool readyForNextGoal(Poems p, FudaSets sets, Map<ItemKey, CardStats> stats) =>
      goalLevel < config.goalsMs.length - 1 && nextBatch(p, sets).isEmpty && allSolid(stats);

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

  /// Never trained in either orientation: the card is new to the player.
  static bool isNewPoem(Map<ItemKey, CardStats> stats, int poemId) =>
      !(stats[ItemKey(poemId, false)]?.seen ?? false) && !(stats[ItemKey(poemId, true)]?.seen ?? false);

  /// Plans a training session: due reviews first, then a weighted mix of
  /// fresh, slow and shaky cards, with a little maintenance of the rest.
  /// New cards stay out of the first [TrainingTuning.newCardHoldBack] swipes
  /// while there are other cards to open with.
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

    // New cards get enough slots to reach their practice threshold this round.
    final newCap = picks.length + (n * TrainingTuning.newCardMaxShare).round();
    for (final s in pool) {
      final st = stats[s.key] ?? CardStats.empty;
      final reason = st.seen ? PickReason.learning : PickReason.fresh;
      for (var i = st.timed.length; i < TrainingTuning.newCardMinTimed && picks.length < math.min(n, newCap); i++) {
        picks.add(TrainingPick(s.key, reason, TrainingTuning.freshWeight));
      }
    }

    (PickReason, double) weigh(ItemState s) {
      final st = stats[s.key] ?? CardStats.empty;
      if (st.timed.length < TrainingTuning.newCardMinTimed) {
        return (st.seen ? PickReason.learning : PickReason.fresh, TrainingTuning.freshWeight);
      }
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
    final opening = holdBackNew(picks, (poemId) => isNewPoem(stats, poemId));
    _spreadRepeats(picks, from: math.max(1, opening));
    return picks;
  }

  /// Moves the first [TrainingTuning.newCardHoldBack] picks of known cards
  /// to the front, keeping the order otherwise, so the run opens with cards
  /// the player has met. Returns how many picks open the run that way.
  static int holdBackNew(List<TrainingPick> picks, bool Function(int poemId) isNew) {
    final opening = <TrainingPick>[], rest = <TrainingPick>[];
    for (final p in picks) {
      (opening.length < TrainingTuning.newCardHoldBack && !isNew(p.key.poemId) ? opening : rest).add(p);
    }
    picks
      ..setAll(0, opening)
      ..setAll(opening.length, rest);
    return opening.length;
  }

  /// Nudges identical neighbours apart where possible, leaving the picks
  /// before [from] in place.
  static void _spreadRepeats(List<TrainingPick> picks, {int from = 1}) {
    for (var i = from; i < picks.length; i++) {
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
