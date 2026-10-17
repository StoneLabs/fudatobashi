part of '../config.dart';

/// The full-screen warnings before what can't be undone (`HoldWarningScreen`:
/// Settings' journey → all-known switch, Reset all data): confirming takes a
/// deliberate hold instead of a tap.
abstract final class HoldWarningTuning {
  static const Duration holdDuration = Duration(seconds: 15);
}

/// `HoldToConfirmButton`'s haptics: buzzes that come faster and harder as
/// the hold nears the end, like arming something. The gap between buzzes
/// shrinks from [buzzFirst] to [buzzLast]; past each of [strengthSteps]
/// (shares of the hold) a buzz steps up from a click to a light, a medium
/// and a heavy impact.
abstract final class HoldConfirmTuning {
  static const Duration buzzFirst = Duration(milliseconds: 1000);
  static const Duration buzzLast = Duration(milliseconds: 90);
  static const List<double> strengthSteps = [0.35, 0.65, 0.88];
}

/// Defaults of `AppSettings`.
abstract final class DefaultSettings {
  static const String language = 'system';
  static const bool languagePicked = false;
  static const DontKnowInput dontKnowInput = DontKnowInput.hold;
  static const bool showPoemNumber = true;
  static const bool haptics = true;
  static const bool sfxEffects = true;
  static const bool music = true;
  static const double musicVolume = 0.5;
  static const double cardScale = SwipeTuning.cardScaleMax;
  static const bool swipeSound = true;
  static const bool effectSounds = true;
  static const bool showRunningTimer = false;
  static const FreePracticeSetup freePractice = FreePracticeSetup();
  static const MaskStyle maskStyle = MaskStyle.scramble;
  static const bool debugMode = false;
  static const bool onboarded = false;
  static const bool toured = false;
  static const bool playOverlay = false;
  static const bool showPerformanceOverlay = false;
  static const bool fastTobi = false;
  static const KimarijiScript kimarijiScript = KimarijiScript.auto;
  static const bool accessibilityMode = false;

  /// 暗記練 (Settings › 寄り道 › 暗記練), and its free play's last setup.
  static const AnkirenSettings ankiren = AnkirenSettings();
  static const AnkirenLayout ankirenLayout = AnkirenLayout.portrait;
  static const AnkirenPrompt ankirenPrompt = AnkirenPrompt.textAndVoice;
  static const int ankirenFreeLevel = 0;
  static const int ankirenCustomPerSide = 8;
  static const Duration ankirenCustomMemorise = Duration(minutes: 1);
  static const bool ankirenRulesSeen = false;
}
