import 'dart:math' as math;

import 'package:fsrs/fsrs.dart' as fsrs;

import '../config/config.dart';
import '../data/islands.dart';
import '../domain/card_stats.dart';
import '../domain/day_window.dart';
import 'play_config.dart';
import 'progress.dart';

/// How well a card is remembered, from not started to mastered.
enum MemoryStage {
  notStarted,
  fresh,
  learning,
  gettingThere,
  solid,
  mastered;

  bool get known => index >= solid.index;
}

/// One practice day as the calendar shows it.
class PracticeDay {
  PracticeDay(this.date);

  final DateTime date;
  int swipes = 0;
  int runs = 0;
  int games = 0;
  Duration clock = Duration.zero;
  bool setDone = false;

  bool get active => runs > 0 || games > 0;
}

/// Swipes, misses and typical time of one side of the cards.
class SideSummary {
  const SideSummary({required this.known, required this.swipes, required this.misses, required this.medianMs});
  final int known, swipes, misses;
  final double? medianMs;

  double? get missRate => swipes == 0 ? null : misses / swipes;
}

/// One card side's row in the SRS card table.
class CardTableRow {
  const CardTableRow({
    required this.key,
    required this.order,
    this.stability,
    this.difficulty,
    this.recall,
    this.due,
    required this.lapses,
    this.medianMs,
  });

  final ItemKey key;

  /// Its place in learning order.
  final int order;
  final double? stability, difficulty, recall;
  final DateTime? due;
  final int lapses;
  final double? medianMs;
}

/// The SRS page's, the rank page's and the calendar's reading of [Progress].
extension StatsHistory on Progress {
  /// [key]'s memory stage now.
  MemoryStage stageOf(ItemKey key) {
    final item = trainer.items[key]!;
    if (!item.unlocked) return MemoryStage.notStarted;
    final st = stats(key);
    if (st.count < SrsTuning.newBelowSwipes) return MemoryStage.fresh;
    if (trainer.mastered(key, st)) return MemoryStage.mastered;
    if (st.solid(trainer.goalMs)) return MemoryStage.solid;
    if (!item.reviewed || item.card.state != fsrs.State.review) return MemoryStage.learning;
    return MemoryStage.gettingThere;
  }

  /// Cards of one side known now.
  int knownCount({bool inverted = false}) => [
        for (final id in learningOrder)
          if (stageOf(ItemKey(id, inverted)).known) id,
      ].length;

  /// The poem ids island by island, in learning order.
  List<int> get learningOrder => [
        for (final isl in archipelago.islands)
          for (final site in isl.sites) site.poemId,
      ];

  /// The average chance of recall now over every reviewed card side, null
  /// before the first review.
  double? recallNow([DateTime? now]) {
    final at = now ?? DateTime.now();
    final recalls = [
      for (final s in trainer.items.values)
        if (s.unlocked && s.reviewed) trainer.retrievability(s.key, at),
    ];
    return recalls.isEmpty ? null : recalls.reduce((a, b) => a + b) / recalls.length;
  }

  /// Every day with play, by date.
  Map<DateTime, PracticeDay> get practiceLog {
    final days = <DateTime, PracticeDay>{};
    PracticeDay at(int day) => days.putIfAbsent(DayWindow.dateOf(day), () => PracticeDay(DayWindow.dateOf(day)));
    for (final r in runs) {
      final d = at(r.day)
        ..runs += 1
        ..swipes += cardsIn(r.id);
      if (Progress.clockOf(r) case final clock?) d.clock += clock;
    }
    for (final trip in sideTrips.runs) {
      at(trip.day).games += 1;
    }
    for (final d in days.values) {
      d.setDone = setDoneOn(d.date);
    }
    return days;
  }

  /// The longest run of days in a row with play.
  int get bestStreak {
    final dates = practiceLog.keys.toList()..sort();
    var best = 0, run = 0;
    DateTime? last;
    for (final d in dates) {
      run = last != null && d.difference(last).inDays == 1 ? run + 1 : 1;
      best = math.max(best, run);
      last = d;
    }
    return best;
  }

  /// The [count] days up to and including today, oldest first.
  List<DateTime> lastDays(int count, [DateTime? now]) {
    final today = dayAt(now).date;
    return [for (var i = count - 1; i >= 0; i--) DateTime.utc(today.year, today.month, today.day - i)];
  }

  /// The days from the first day with play up to today, oldest first.
  List<DateTime> playedDays([DateTime? now]) {
    final first = practiceLog.keys.fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    if (first == null) return const [];
    final today = dayAt(now).date;
    return lastDays(today.difference(first).inDays + 1, now);
  }

  /// Upright cards known at the end of each of [days].
  List<int> knownOn(List<DateTime> days) {
    final dayOfRun = {for (final r in runs) r.id: r.day};
    final goalOn = <int, double>{};
    for (final r in runs) {
      if (r.mode != PlayMode.nigate) goalOn[r.day] = r.goalMs.toDouble();
    }
    final numbers = [for (final d in days) DayWindow.numberOf(d)];
    var goal = trainer.goalMs;
    final goals = <double>[];
    for (final n in numbers) {
      goal = goalOn[n] ?? goal;
      goals.add(goal);
    }
    final known = List.filled(days.length, 0);
    for (final id in learningOrder) {
      final attempts = [
        for (final a in attemptsOf(ItemKey(id, false)))
          if (a.countsForSrs) (a, dayOfRun[a.runId] ?? DayWindow.numberOf(a.at)),
      ];
      var taken = 0;
      bool? solid;
      for (final (i, n) in numbers.indexed) {
        var grew = false;
        while (taken < attempts.length && attempts[taken].$2 <= n) {
          taken++;
          grew = true;
        }
        if (grew || solid == null || (i > 0 && goals[i] != goals[i - 1])) {
          solid = CardStats([for (final (a, _) in attempts.take(taken)) a]).solid(goals[i]);
        }
        if (solid) known[i]++;
      }
    }
    return known;
  }

  /// Upright cards unlocked by the end of each of [days].
  List<int> unlockedOn(List<DateTime> days) {
    final unlocks = [
      for (final id in learningOrder)
        if (trainer.items[ItemKey(id, false)]!.unlockedAt case final at?) DayWindow.at(at, settings.dayStartHour).date,
    ];
    return [for (final d in days) unlocks.where((u) => !u.isAfter(d)).length];
  }

  /// The median time of each of [days]' right swipes, over every card and
  /// over the cards known now; null for a day without one.
  ({List<double?> all, List<double?> known}) speedOn(List<DateTime> days) {
    final dayOfRun = {for (final r in runs) r.id: r.day};
    final index = {for (final (i, d) in days.indexed) DayWindow.numberOf(d): i};
    final all = [for (final _ in days) <double>[]];
    final known = [for (final _ in days) <double>[]];
    for (final key in trainer.items.keys) {
      final isKnown = stageOf(key).known;
      for (final a in attemptsOf(key)) {
        if (!a.timed) continue;
        final i = index[dayOfRun[a.runId] ?? DayWindow.numberOf(a.at)];
        if (i == null) continue;
        all[i].add(a.ms);
        if (isKnown) known[i].add(a.ms);
      }
    }
    return (all: [for (final v in all) _median(v)], known: [for (final v in known) _median(v)]);
  }

  /// Every swipe on one side of the cards.
  SideSummary sideSummary({required bool inverted}) {
    var swipes = 0, misses = 0;
    final times = <double>[];
    for (final key in trainer.items.keys.where((k) => k.inverted == inverted)) {
      for (final a in attemptsOf(key)) {
        if (a.undone) continue;
        swipes++;
        if (a.miss) misses++;
        if (a.timed) times.add(a.ms);
      }
    }
    return SideSummary(known: knownCount(inverted: inverted), swipes: swipes, misses: misses, medianMs: _median(times));
  }

  /// Every unlocked card side, in learning order, upright before
  /// upside-down.
  List<CardTableRow> cardTable([DateTime? now]) {
    final at = now ?? DateTime.now();
    final order = learningOrder;
    return [
      for (final inverted in [false, true])
        for (final (i, id) in order.indexed)
          if (trainer.items[ItemKey(id, inverted)] case final item? when item.unlocked)
            CardTableRow(
              key: item.key,
              order: i,
              stability: item.reviewed ? item.card.stability : null,
              difficulty: item.reviewed ? item.card.difficulty : null,
              recall: item.reviewed ? trainer.retrievability(item.key, at) : null,
              due: item.reviewed ? item.card.due : null,
              lapses: _lapses(item.key),
              medianMs: displayStats(item.key).median(SrsTuning.typicalWindow),
            ),
    ];
  }

  /// Again grades after a card's first review.
  int _lapses(ItemKey key) {
    final graded = [for (final a in attemptsOf(key)) if (a.grade != null) a.grade!];
    return graded.skip(1).where((g) => g == fsrs.Rating.again.value).length;
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
