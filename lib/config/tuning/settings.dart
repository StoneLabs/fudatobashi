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
/// and a heavy impact. Its hint, when it has one, pops after [hintTaps]
/// taps in a row, each within [hintWindow] of the last, and stays
/// [hintLife].
abstract final class HoldConfirmTuning {
  static const Duration buzzFirst = Duration(milliseconds: 1000);
  static const Duration buzzLast = Duration(milliseconds: 90);
  static const List<double> strengthSteps = [0.35, 0.65, 0.88];
  static const int hintTaps = 2;
  static const Duration hintWindow = Duration(milliseconds: 1500);
  static const Duration hintLife = Duration(milliseconds: 2400);
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
  static const bool cardPanelSwiped = false;
  static const bool timerNotificationsAsked = false;
  static const bool reminders = false;
  static const bool remindersOffered = false;
  static const SoundLadderMode soundLadder = SoundLadderMode.sounds;

  /// 暗記練 (Settings › 寄り道 › 暗記練), and its free play's last setup.
  static const AnkirenSettings ankiren = AnkirenSettings();
  static const AnkirenLayout ankirenLayout = AnkirenLayout.portrait;
  static const AnkirenPrompt ankirenPrompt = AnkirenPrompt.textAndVoice;
  static const int ankirenFreeLevel = 0;
  static const int ankirenCustomPerSide = 8;
  static const Duration ankirenCustomMemorise = Duration(minutes: 1);
  static const bool ankirenRulesSeen = false;

  /// 定位置 (Settings › 寄り道 › 定位置), and its custom game's last setup:
  /// the usual game's cards and rows.
  static const TeiichiSettings teiichi = TeiichiSettings();
  static const bool teiichiRulesSeen = false;
  static const int teiichiCustomCards = TeiichiTuning.cards;
  static const int teiichiCustomRows = TeiichiTuning.rows;
  static const bool teiichiAutoTurn = true;
  static const bool teiichiTurnTipOff = false;

  /// 一騎打ち (Settings › 寄り道 › 一騎打ち): each mode's ranked matches in its
  /// own rows until the player picks others, the page on Rapid's tab until
  /// they open another, and a match turning the screen sideways with
  /// Tobi's arm leaving wind lines.
  static const IkkiuchiSettings ikkiuchi = IkkiuchiSettings();
  static const IkkiuchiMode ikkiuchiTab = IkkiuchiMode.rapid;
  static const bool ikkiuchiAutoTurn = true;
  static const bool ikkiuchiWind = true;
}

/// The orientations the app allows: portrait only. 暗記練's landscape layout
/// (`AnkirenLayout.landscape`) and 定位置 turn the screen for their games
/// alone, to [landscape] (or, 定位置 and 一騎打ち without their auto turn, to
/// [any]), and return to these after.
abstract final class OrientationTuning {
  static const List<DeviceOrientation> app = [DeviceOrientation.portraitUp];
  static const List<DeviceOrientation> landscape = [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];
  static const List<DeviceOrientation> any = [DeviceOrientation.portraitUp, ...landscape];
}

/// How the app shows the system bars: drawn over, edge to edge. A page that
/// hides them returns to this as it closes.
abstract final class SystemBarsTuning {
  static const SystemUiMode app = SystemUiMode.edgeToEdge;
}
