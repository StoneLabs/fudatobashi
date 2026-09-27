import 'dart:math' as math;

import '../config/config.dart';

/// Identifies a training item: a card in one orientation.
class ItemKey {
  const ItemKey(this.poemId, this.inverted);

  factory ItemKey.fromId(int id) => ItemKey(id >> 1, id.isOdd);

  final int poemId;
  final bool inverted;

  /// Compact id (also used as the FSRS card id).
  int get id => poemId * 2 + (inverted ? 1 : 0);

  ItemKey get flipped => ItemKey(poemId, !inverted);

  @override
  bool operator ==(Object other) => other is ItemKey && other.id == id;

  @override
  int get hashCode => id;

  @override
  String toString() => '$poemId${inverted ? 'v' : '^'}';
}

/// The facts about one stored attempt that statistics need.
class AttemptRec {
  const AttemptRec({
    required this.at,
    required this.us,
    required this.miss,
    required this.clean,
    required this.deckSize,
    this.maskLevel = 0,
    this.grade,
    this.sessionId,
  });

  final DateTime at;
  final int us;

  /// "Don't know", marked wrong, or undone.
  final bool miss;

  /// The time is a clean measurement (not a redo or a corrected card).
  final bool clean;
  final int deckSize;
  final int maskLevel;
  final int? grade;
  final int? sessionId;

  double get ms => us / 1000;

  /// Usable as a speed sample: clean and correct.
  bool get timed => clean && !miss;
}

/// Speed and accuracy statistics of one item, from its attempts in time order.
class CardStats {
  CardStats(List<AttemptRec> attempts) : all = List.unmodifiable(attempts) {
    timed = [for (final a in all) if (a.timed) a.ms];
    double? e;
    for (final ms in timed) {
      final l = math.log(ms);
      e = e == null ? l : e + StatsTuning.ewmaAlpha * (l - e);
    }
    _ewmaLog = e;
  }

  static final empty = CardStats(const []);

  final List<AttemptRec> all;

  /// Clean, correct response times in ms, oldest first.
  late final List<double> timed;
  double? _ewmaLog;

  bool get seen => all.isNotEmpty;
  int get count => all.length;
  DateTime? get lastSeen => all.isEmpty ? null : all.last.at;

  /// Exponentially weighted (geometric) mean of recent times.
  double? get ewmaMs => _ewmaLog == null ? null : math.exp(_ewmaLog!);

  double? get bestMs => timed.isEmpty ? null : timed.reduce(math.min);
  double? get lastMs => timed.isEmpty ? null : timed.last;

  List<double> _window(int n) => timed.length <= n ? timed : timed.sublist(timed.length - n);

  double? mean(int n) {
    final w = _window(n);
    return w.isEmpty ? null : w.reduce((a, b) => a + b) / w.length;
  }

  double? median(int n) => percentile(n, 50);

  /// Linear-interpolated percentile of the last [n] timed attempts.
  double? percentile(int n, double p) {
    final w = [..._window(n)]..sort();
    if (w.isEmpty) return null;
    final rank = (p / 100) * (w.length - 1);
    final lo = rank.floor();
    final hi = rank.ceil();
    return w[lo] + (w[hi] - w[lo]) * (rank - lo);
  }

  /// Share of misses among the last [n] attempts.
  double missRate([int n = StatsTuning.missWindowDefault]) {
    if (all.isEmpty) return 0;
    final w = all.length <= n ? all : all.sublist(all.length - n);
    return w.where((a) => a.miss).length / w.length;
  }

  /// Rolling mean over the last [window] timed attempts, for every attempt.
  List<double> rollingMean(int window) {
    final out = <double>[];
    var sum = 0.0;
    for (var i = 0; i < timed.length; i++) {
      sum += timed[i];
      if (i >= window) sum -= timed[i - window];
      out.add(sum / math.min(i + 1, window));
    }
    return out;
  }

  /// Expected time for this card in a run, counting misses as [unknownMs].
  double expectedMs({double unknownMs = StatsTuning.unknownMs}) {
    final e = ewmaMs;
    if (e == null) return unknownMs;
    final m = missRate();
    return (1 - m) * math.min(e, unknownMs) + m * unknownMs;
  }

  /// Fast and reliable at [goalMs]: at least [StatsTuning.solidMinTimed] timed
  /// attempts, the last [StatsTuning.solidWindow] attempts all correct, and
  /// their median time within the goal.
  bool solid(double goalMs) {
    if (timed.length < StatsTuning.solidMinTimed || all.isEmpty) return false;
    final window = StatsTuning.solidWindow;
    final last = all.length <= window ? all : all.sublist(all.length - window);
    if (last.any((a) => a.miss)) return false;
    return median(window)! <= goalMs;
  }
}
