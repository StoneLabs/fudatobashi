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
}
