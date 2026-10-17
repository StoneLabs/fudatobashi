part of '../config.dart';

/// The graduation exam (卒業試験): the journey's last island, all 100 cards
/// against Tobi (see `TobiPace`).
abstract final class ExamTuning {
  /// Tobi's time for the 100 cards, his mistakes' penalties included, drawn
  /// evenly from this range each try.
  static const int tobiMinMs = 240000;
  static const int tobiMaxMs = 330000;

  /// Each of Tobi's cards is at his usual pace, quick, or slow. A usual one
  /// may start a burst of quick cards (this chance, this many of them) or
  /// be a slow one instead (this chance).
  static const double tobiBurstChance = 0.08;
  static const int tobiBurstMin = 2;
  static const int tobiBurstMax = 4;
  static const double tobiSlowChance = 0.12;

  /// His cards share out his time by these weights, a usual card's being
  /// 1 give or take [tobiJitter], so they still add up to his time. With
  /// the chances above, a quick card takes about a third of his usual pace
  /// and a slow one about 2.6 times it.
  static const double tobiQuickWeight = 0.3;
  static const double tobiSlowWeight = 2.6;
  static const double tobiJitter = 0.25;

  /// Chance that a card of his is a mistake, which adds [missPenaltyMs] to
  /// his time, up to [tobiMaxMisses] mistakes a try.
  static const double tobiMissChance = 0.02;
  static const int tobiMaxMisses = 4;

  /// A slow card of his shows him thinking once it has been up this long.
  static const Duration tobiThinkAfter = Duration(milliseconds: 1400);

  /// Added to the player's time for each miss or card marked wrong.
  static const int missPenaltyMs = RankedTuning.missPenaltyMs;

  /// One try per this long, counted from the start of the last try.
  static const Duration cooldown = Duration(hours: 1);
}

/// Developer mode's exam tools (Settings › developer).
abstract final class ExamDevTuning {
  /// Tobi's clock for the 100 cards with the fast-Tobi switch on, before
  /// his mistakes' penalties, so a win can be tried out.
  static const int fastTobiMs = 60000;

  /// Each card's time in the free-play run that opens the exam.
  static const int openCardMs = 1200;
}
