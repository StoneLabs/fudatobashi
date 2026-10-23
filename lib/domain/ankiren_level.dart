import 'dart:math' as math;

import '../config/config.dart';

/// One 暗記練 difficulty level: how many cards each side of the field holds
/// and how long the player may memorise them.
class AnkirenLevel {
  const AnkirenLevel(this.perSide, this.memorise, {this.allInMiddle = false});

  final int perSide;
  final Duration memorise;

  /// A beginner's field: every card in the open middle, spread out evenly,
  /// instead of a 定位置's clusters.
  final bool allInMiddle;

  /// Cards on the whole field, which must all be known cards.
  int get cards => 2 * perSide;
}

/// The level table ([AnkirenTuning.levels], 0 = easiest) and the cap the
/// player's known cards put on it.
abstract final class AnkirenLevels {
  static List<AnkirenLevel> get all => AnkirenTuning.levels;
  static int get top => all.length - 1;

  static AnkirenLevel of(int level) => all[level];

  /// The highest level whose field fits [known] distinct known cards, or null
  /// when not even level 0 does.
  static int? maxLevelFor(int known) {
    final i = all.lastIndexWhere((l) => l.cards <= known);
    return i < 0 ? null : i;
  }
}

/// What one 暗記練 game deals: ranked's one setup, or in free play a level
/// preset or a custom card count and memorise time.
class AnkirenSetup {
  const AnkirenSetup({required this.perSide, required this.memorise, this.level, this.ranked = false})
      : assert(!ranked || level == null);

  /// Ranked's setup, a real match's field; it plays no level.
  const AnkirenSetup.ranked()
      : this(perSide: AnkirenTuning.rankedPerSide, memorise: AnkirenTuning.rankedMemorise, ranked: true);

  /// A free-play level preset.
  AnkirenSetup.forLevel(int level)
      : this(perSide: AnkirenLevels.of(level).perSide, memorise: AnkirenLevels.of(level).memorise, level: level);

  /// A free-play setup outside the level table.
  const AnkirenSetup.custom({required int perSide, required Duration memorise})
      : this(perSide: perSide, memorise: memorise);

  final int perSide;
  final Duration memorise;

  /// The free-play level preset played; null for ranked and for a custom
  /// setup.
  final int? level;
  final bool ranked;

  /// A custom setup, which is not scored.
  bool get custom => level == null && !ranked;

  int get cards => 2 * perSide;

  /// Deals a beginner's field (see [AnkirenLevel.allInMiddle]).
  bool get allInMiddle => level != null && AnkirenLevels.of(level!).allInMiddle;

  /// The largest custom per-side count [known] cards allow, or null when they
  /// allow not even [AnkirenTuning.customMinPerSide].
  static int? maxCustomPerSide(int known) {
    final n = (known ~/ 2).clamp(0, AnkirenTuning.customMaxPerSide);
    return n < AnkirenTuning.customMinPerSide ? null : n;
  }

  /// The memorise times a custom setup offers, shortest first: fine steps up
  /// to [AnkirenTuning.customFineUntil], coarse ones after.
  static List<Duration> get memoriseOptions => [
        for (var t = AnkirenTuning.customMinMemorise;
            t <= AnkirenTuning.customMaxMemorise;
            t += t < AnkirenTuning.customFineUntil ? AnkirenTuning.customFineStep : AnkirenTuning.customCoarseStep)
          t,
      ];

  @override
  bool operator ==(Object other) =>
      other is AnkirenSetup &&
      other.perSide == perSide &&
      other.memorise == memorise &&
      other.level == level &&
      other.ranked == ranked;

  @override
  int get hashCode => Object.hash(perSide, memorise, level, ranked);
}

/// Free play's levels as they open (see [AnkirenTuning.strikesOut]): level 0
/// at first, then each cleared level opens the next, with every level below
/// it. Clearing [AnkirenTuning.rankedAfterLevel] is what ranked needs from
/// free play, and clearing [AnkirenTuning.customAfterLevel] opens the custom
/// setups.
class AnkirenLadder {
  const AnkirenLadder(this.cleared);

  static const none = AnkirenLadder({});

  /// The levels cleared so far.
  final Set<int> cleared;

  /// Whether a game clears its level: played to the end with fewer than
  /// [AnkirenTuning.strikesOut] [strikes].
  static bool clears({required bool completed, required int strikes}) =>
      completed && strikes < AnkirenTuning.strikesOut;

  int get _highest => cleared.isEmpty ? -1 : cleared.reduce(math.max);

  /// The highest open level.
  int get open => math.min(AnkirenLevels.top, _highest + 1);

  bool isOpen(int level) => level <= open;
  bool isCleared(int level) => cleared.contains(level);

  /// The top level is cleared: none is left to open.
  bool get allCleared => _highest == AnkirenLevels.top;

  /// The level to clear next, the highest open one; null once
  /// [allCleared].
  int? get next => allCleared ? null : open;

  /// What ranked needs from free play is done.
  bool get rankedReady => _highest >= AnkirenTuning.rankedAfterLevel;

  bool get customOpen => _highest >= AnkirenTuning.customAfterLevel;
}
