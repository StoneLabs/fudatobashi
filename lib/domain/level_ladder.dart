import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_level.dart';
import 'teiichi.dart';

/// What sets one side trip's ladder of levels apart: where it starts and
/// ends, and which cleared levels open ranked and the custom setups.
enum LadderRules {
  ankiren,
  teiichi;

  int get first => switch (this) {
        ankiren => 0,
        teiichi => TeiichiLevels.first,
      };

  int get top => switch (this) {
        ankiren => AnkirenLevels.top,
        teiichi => TeiichiLevels.top,
      };

  int get rankedAfter => switch (this) {
        ankiren => AnkirenTuning.rankedAfterLevel,
        teiichi => TeiichiTuning.rankedAfterLevel,
      };

  int get customAfter => switch (this) {
        ankiren => AnkirenTuning.customAfterLevel,
        teiichi => TeiichiTuning.customAfterLevel,
      };
}

/// A side trip's levels as they open (see [AnkirenTuning.strikesOut]): the
/// first at first, then each cleared level opens the next, with every level
/// below it. Clearing [LadderRules.rankedAfter] is what ranked needs from
/// the levels, and clearing [LadderRules.customAfter] opens the custom
/// setups.
class LevelLadder {
  const LevelLadder(this.cleared, [this.rules = LadderRules.ankiren]);

  static const none = LevelLadder({});

  /// The levels cleared so far.
  final Set<int> cleared;
  final LadderRules rules;

  /// Whether a game clears its level: played to the end with fewer than
  /// [AnkirenTuning.strikesOut] [strikes].
  static bool clears({required bool completed, required int strikes}) =>
      completed && strikes < AnkirenTuning.strikesOut;

  int get _highest => cleared.isEmpty ? rules.first - 1 : cleared.reduce(math.max);

  /// The highest open level.
  int get open => math.min(rules.top, _highest + 1);

  bool isOpen(int level) => level <= open;
  bool isCleared(int level) => cleared.contains(level);

  /// The top level is cleared: none is left to open.
  bool get allCleared => _highest == rules.top;

  /// The level to clear next, the highest open one; null once
  /// [allCleared].
  int? get next => allCleared ? null : open;

  /// What ranked needs from the levels is done.
  bool get rankedReady => _highest >= rules.rankedAfter;

  bool get customOpen => _highest >= rules.customAfter;
}
