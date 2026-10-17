part of '../config.dart';

/// When the tabs a new player starts without open up (`TabLock`).
abstract final class TabLockTuning {
  static const int historyRounds = 3;

  /// All-known mode's stand-in for finishing the first island.
  static const int statsFinishedRounds = 1;
}

/// The tour's practice round (`PlayScreen.tutorial`).
abstract final class TutorialTuning {
  /// How long Tobi's last line stays up before the round closes.
  static const Duration doneLinger = Duration(milliseconds: 1800);

  /// How long after the first card leaves Tobi stops the round to explain
  /// marking a card forgotten, so the card's flick plays out first.
  static const Duration forgetPause = Duration(milliseconds: 450);
}

/// Tobi's tour balloon (`TourOverlay`): how its text types itself out.
abstract final class TourTuning {
  /// Time to reveal each visible character of a line — slow enough to read
  /// as it goes, and never skippable.
  static const Duration charInterval = Duration(milliseconds: 28);

  /// The tour's first real card: the journey's first card, む (#87). Its
  /// lines name it, so a test checks it is still the first one unlocked.
  static const int firstCard = 87;

  /// How long the first card's new card screen plays its entrance before
  /// Tobi points at its parts (past `NewCardMotion.actions`).
  static const Duration newCardSettle = Duration(milliseconds: 1400);
}
