part of '../config.dart';

/// The match timer (`MatchTimerScreen`, Help › Tools).
abstract final class MatchTimerTuning {
  static const Duration defaultTime = Duration(minutes: 15);

  /// The ring changes colour, and the warning sounds, when this much is left.
  static const Duration warnAt = Duration(minutes: 2);

  static const Duration tick = Duration(milliseconds: 200);
  static const int maxMinutes = 99;
  static const int maxSeconds = 59;

  static const Sfx warnSound = Sfx.lookAlike;
  static const Sfx endSound = Sfx.graduation;

  /// A sound whose moment passed longer ago than this (the app was asleep
  /// in the background, as iOS does) is skipped rather than played late.
  static const Duration lateSoundGrace = Duration(seconds: 2);

  /// How long Android's background service outlasts the end, so the end
  /// sound gets to play before the phone may sleep.
  static const Duration backgroundLinger = Duration(seconds: 5);
}
