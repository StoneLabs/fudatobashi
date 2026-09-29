import 'strings.dart';

/// Strings of the settings screen.
extension SettingsStrings on S {
  String get sectionLearning => t('sectionLearning');
  String get sectionPlay => t('sectionPlay');
  String get sectionSound => t('sectionSound');
  String get sectionDeveloper => t('sectionDeveloper');

  String get languageNote => t('languageNote');
  String get learningMode => t('learningMode');
  String get learningModeNote => t('learningModeNote');
  String get learningJourney => t('learningJourney');
  String get learningAllKnown => t('learningAllKnown');
  String get pace => t('pace');
  String get paceMonth => t('paceMonth');
  String get paceSprint => t('paceSprint');
  String get paceNote => t('paceNote');
  String get cardEffects => t('cardEffects');
  String get cardEffectsNote => t('cardEffectsNote');
  String get vibration => t('vibration');
  String get vibrationNote => t('vibrationNote');
  String get sounds => t('sounds');
  String get soundsNote => t('soundsNote');
  String get soundSilentNote => t('soundSilentNote');
  String get dontKnowInput => t('dontKnowInput');
  String get dontKnowInputNote => t('dontKnowInputNote');
  String get dontKnowHold => t('dontKnowHold');
  String get dontKnowHoldSub => t('dontKnowHoldSub');
  String get dontKnowButton => t('dontKnowButton');
  String get dontKnowButtonSub => t('dontKnowButtonSub');
  String get dontKnowOff => t('dontKnowOff');
  String get dontKnowOffSub => t('dontKnowOffSub');

  String get warning => t('warning');
  String get allKnownWarningShout => t('allKnownWarningShout');
  String get allKnownWarningTitle => t('allKnownWarningTitle');
  String get allKnownWarningBody => t('allKnownWarningBody');
  String allKnownWarningHold(int seconds) => f('allKnownWarningHold', [seconds]);
  String get allKnownWarningHolding => t('allKnownWarningHolding');

  String get about => t('about');
  String get version => t('version');
  String get creditsNote => t('creditsNote');
  String tapsRemaining(int n) => f(n == 1 ? 'tapsRemainingOne' : 'tapsRemainingOther', [n]);
  String get devModeUnlocked => t('devModeUnlocked');
  String get developerMode => t('developerMode');
}
