import 'strings.dart';

/// Strings for the "Licenses & credits" screen.
extension CreditsStrings on S {
  String get credits => t('credits');

  String get privacyPolicy => t('privacyPolicy');

  /// The About row that opens the source code and issue tracker in the browser.
  String get repositoryLink => t('repositoryLink');

  String get creditsFonts => t('creditsFonts');

  String get creditsCardKana => t('creditsCardKana');
  String get creditsCardKanaBody => t('creditsCardKanaBody');

  String get creditsSounds => t('creditsSounds');
  String get creditsSoundsBody => t('creditsSoundsBody');

  String get creditsMusic => t('creditsMusic');
  String get creditsMusicBody => t('creditsMusicBody');

  String get creditsVoice => t('creditsVoice');
  String get creditsVoiceBody => t('creditsVoiceBody');

  String get creditsPoemData => t('creditsPoemData');
  String get creditsPoemDataBody => t('creditsPoemDataBody');

  /// Where the full karuta rules and the karuta guide in Help come from.
  String get creditsRulesBody => t('creditsRulesBody');
  String get creditsGuideBody => t('creditsGuideBody');

  String get creditsInspiration => t('creditsInspiration');
  String get creditsInspirationBody => t('creditsInspirationBody');

  String get creditsOpenSource => t('creditsOpenSource');
  String get creditsOpenSourceBody => t('creditsOpenSourceBody');
  String get creditsViewPackages => t('creditsViewPackages');
  String get creditsViewLicense => t('creditsViewLicense');
}
