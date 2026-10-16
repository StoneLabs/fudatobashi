import '../config/config.dart';
import 'card_stats.dart';
import 'play_session.dart';

/// 苦手: the weak sides among the played ones, worst first, and the line an
/// answer must beat to count as fast (see [WeakTuning]).
class WeakCards {
  WeakCards._(this.sides, this.quick, this.usualMs, this.verdicts);

  factory WeakCards.of(Map<ItemKey, CardStats> stats) {
    final played = {
      for (final e in stats.entries)
        if (e.value.seen) e.key: e.value,
    };
    final times = [for (final st in played.values) ?st.ewmaMs]..sort();
    final usual = times.isEmpty ? StatsTuning.unknownMs : times[times.length ~/ 2];
    final line = usual * WeakTuning.lineRatio;
    final expected = {for (final e in played.entries) e.key: e.value.expectedMs()};
    final verdicts = {
      for (final k in played.keys)
        k: WeakVerdict(
          expectedMs: expected[k]!,
          recentMisses: [for (final a in played[k]!.all.reversed.take(WeakTuning.recentMissLooks)) a.miss],
          slow: expected[k]! > line,
        ),
    };
    bool weak(ItemKey k) => verdicts[k]!.weak;
    int worstFirst(ItemKey a, ItemKey b) {
      final by = expected[b]!.compareTo(expected[a]!);
      return by != 0 ? by : a.id.compareTo(b.id);
    }

    return WeakCards._(
      [for (final k in played.keys) if (weak(k)) k]..sort(worstFirst),
      [for (final k in played.keys) if (!weak(k) && expected[k]! <= usual) k]..sort((a, b) => a.id.compareTo(b.id)),
      usual,
      verdicts,
    );
  }

  /// Why each played side is weak or not.
  final Map<ItemKey, WeakVerdict> verdicts;

  /// Weak sides, worst first.
  final List<ItemKey> sides;

  /// Played sides at or under the usual time: the quick cards a drill mixes in.
  final List<ItemKey> quick;

  /// The player's usual card time: the median of every played side's.
  final double usualMs;

  double get lineMs => usualMs * WeakTuning.lineRatio;

  /// Cards with a weak side.
  int get cards => {for (final k in sides) k.poemId}.length;

  /// An answer under [lineMs]: correct, cleanly timed and fast.
  static bool fast({required bool miss, required bool clean, required int us, required double lineMs}) =>
      !miss && clean && Attempt.isValidTime(us) && us <= lineMs * 1000;

  /// A side's answers in a drill, in order, end with [WeakTuning.clearLooks]
  /// fast ones in a row: it is cleared.
  static bool cleared(List<bool> fastLooks) =>
      fastLooks.length >= WeakTuning.clearLooks &&
      fastLooks.skip(fastLooks.length - WeakTuning.clearLooks).every((f) => f);

  /// The sides a drill worked on, in order of their first look: its
  /// [targets] that were shown, and every side shown more than once (a
  /// quick card missed comes back too).
  static List<WeakSide> drill(Iterable<Attempt> attempts, Set<ItemKey> targets, double lineMs) {
    final sides = <ItemKey, WeakSide>{};
    for (final a in attempts) {
      final key = ItemKey(a.card.poemId, a.card.inverted);
      (sides[key] ??= WeakSide(key)).looks.add((
        miss: a.isMiss,
        ms: a.cardUs / 1000,
        fast: fast(miss: a.isMiss, clean: !a.tainted, us: a.cardUs, lineMs: lineMs),
      ));
    }
    return [for (final s in sides.values) if (targets.contains(s.key) || s.looks.length > 1) s];
  }
}

/// How a played side was judged: its expected time and latest answers
/// (newest first) against the line.
class WeakVerdict {
  const WeakVerdict({required this.expectedMs, required this.recentMisses, required this.slow});
  final double expectedMs;
  final List<bool> recentMisses;
  final bool slow;

  bool get missed => recentMisses.any((m) => m);
  bool get weak => missed || slow;
}

/// The cards picked for a 苦手 drill, before they are ordered.
class WeakPick {
  const WeakPick({required this.targets, required this.lookAlikes, required this.anchors, required this.fillers});
  final List<ItemKey> targets;

  /// Each target's look-alike, and whether it is a 友札 (else its other side).
  final Map<ItemKey, ({ItemKey key, bool friend})> lookAlikes;
  final List<ItemKey> anchors;
  final List<ItemKey> fillers;
}

/// One side's looks in a 苦手 drill.
class WeakSide {
  WeakSide(this.key);
  final ItemKey key;
  final List<({bool miss, double ms, bool fast})> looks = [];

  bool get cleared => WeakCards.cleared([for (final l in looks) l.fast]);

  /// Its fastest correct look, ms.
  double? get bestMs {
    final times = [for (final l in looks) if (!l.miss) l.ms];
    return times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b);
  }
}
