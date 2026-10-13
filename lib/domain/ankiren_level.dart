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

/// What one 暗記練 game deals: a level preset, or (free play only) a custom
/// card count and memorise time.
class AnkirenSetup {
  const AnkirenSetup({required this.perSide, required this.memorise, this.level, this.ranked = false})
      : assert(!ranked || level != null);

  /// A level preset; ranked games always play one.
  AnkirenSetup.forLevel(int level, {bool ranked = false})
      : this(
          perSide: AnkirenLevels.of(level).perSide,
          memorise: AnkirenLevels.of(level).memorise,
          level: level,
          ranked: ranked,
        );

  /// A free-play setup outside the level table.
  const AnkirenSetup.custom({required int perSide, required Duration memorise})
      : this(perSide: perSide, memorise: memorise);

  final int perSide;
  final Duration memorise;

  /// The level preset played, or null for a custom setup.
  final int? level;
  final bool ranked;

  int get cards => 2 * perSide;

  /// The level this setup scores as: its own, or for a custom setup the
  /// hardest level it is at least as hard as (as many cards a side or more,
  /// as long to memorise or less), or level 0.
  int get scoredLevel =>
      level ??
      math.max(0, AnkirenLevels.all.lastIndexWhere((l) => perSide >= l.perSide && memorise <= l.memorise));

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
