import '../config/config.dart';
import 'karafuda.dart';

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

  /// The からふだ [level] calls: none below [AnkirenTuning.karafudaFromLevel].
  static int karafudaOf(int level) =>
      level < AnkirenTuning.karafudaFromLevel ? 0 : Karafuda.forAnkiren(of(level).cards);

  /// The known cards [level] needs: its field's and its からふだ.
  static int needs(int level) => of(level).cards + karafudaOf(level);

  /// The highest level [known] distinct known cards are enough for (see
  /// [needs]), or null when not even level 0's.
  static int? maxLevelFor(int known) {
    final i = [for (var l = 0; l <= top; l++) needs(l)].lastIndexWhere((n) => n <= known);
    return i < 0 ? null : i;
  }
}

/// What one 暗記練 game deals: ranked's one setup, or in free play a level
/// preset or a custom card count, memorise time and からふだ.
class AnkirenSetup {
  const AnkirenSetup({required this.perSide, required this.memorise, this.level, this.ranked = false, this._karafuda})
      : assert(!ranked || level == null);

  /// Ranked's setup, a real match's field; it plays no level.
  const AnkirenSetup.ranked()
      : this(perSide: AnkirenTuning.rankedPerSide, memorise: AnkirenTuning.rankedMemorise, ranked: true);

  /// A free-play level preset.
  AnkirenSetup.forLevel(int level)
      : this(perSide: AnkirenLevels.of(level).perSide, memorise: AnkirenLevels.of(level).memorise, level: level);

  /// A free-play setup outside the level table.
  const AnkirenSetup.custom({required int perSide, required Duration memorise, int karafuda = 0})
      : this(perSide: perSide, memorise: memorise, karafuda: karafuda);

  final int perSide;
  final Duration memorise;
  final int? _karafuda;

  /// The からふだ it calls: a custom setup's own, a level's
  /// ([AnkirenLevels.karafudaOf]), ranked's as a field its size.
  int get karafuda =>
      _karafuda ?? (ranked ? Karafuda.forAnkiren(cards) : level == null ? 0 : AnkirenLevels.karafudaOf(level!));

  /// Every call: the field's cards and the からふだ, each a known card, so
  /// also the known cards the game needs.
  int get calls => cards + karafuda;

  /// The free-play level preset played; null for ranked and for a custom
  /// setup.
  final int? level;
  final bool ranked;

  /// A custom setup, which is not scored.
  bool get custom => level == null && !ranked;

  int get cards => 2 * perSide;

  /// Deals a beginner's field (see [AnkirenLevel.allInMiddle]).
  bool get allInMiddle => level != null && AnkirenLevels.of(level!).allInMiddle;

  /// The からふだ a custom setup of [perSide] calls unless the player picks
  /// another count: as many as the formula gives a field its size.
  static int customKarafuda(int perSide) => Karafuda.forAnkiren(2 * perSide);

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
      other.ranked == ranked &&
      other.karafuda == karafuda;

  @override
  int get hashCode => Object.hash(perSide, memorise, level, ranked, karafuda);
}
