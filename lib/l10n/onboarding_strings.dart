import 'strings.dart';

/// Strings of the first-launch screen. Japanese marks where lines may break
/// inside a sentence with `​` (see `Phrases`).
extension OnboardingStrings on S {
  /// Big lettering, Japanese in both languages.
  String get welcomeTitle => t('welcomeTitle');
  String get welcomeBanner => t('welcomeBanner');
  String get tobiHello => t('tobiHello');

  /// Tobi's question, broken into balloon lines.
  String get howWell => t('howWell');
  String get howWellOneLine => howWell.replaceAll('\n', ja ? '' : ' ');
  String get beginnerTag => t('beginnerTag');
  String get beginnerTitle => t('beginnerTitle');
  String get beginnerSub => t('beginnerSub');
  String firstStop(String island, int n) => f('firstStop', [island, n]);
  String get expertTag => t('expertTag');
  String get expertTitle => t('expertTitle');
  String get expertSub => t('expertSub');
  String get expertNote => t('expertNote');
  String get changeLaterBefore => t('changeLaterBefore');
  String get changeLaterWhere => t('changeLaterWhere');
  String get changeLaterAfter => t('changeLaterAfter');

  String get paceBanner => t('paceBanner');
  String get howFast => t('howFast');
  String get relaxedTag => t('relaxedTag');
  String get relaxedCall => t('relaxedCall');
  String get relaxedTitle => t('relaxedTitle');
  String get relaxedSub => t('relaxedSub');
  String get relaxedNote => t('relaxedNote');
  String get sprintTag => t('sprintTag');
  String get sprintCall => t('sprintCall');
  String get sprintTitle => t('sprintTitle');
  String get sprintSub => t('sprintSub');
  String get sprintNote => t('sprintNote');
  String get paceLaterWhere => t('paceLaterWhere');
}
