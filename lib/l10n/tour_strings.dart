import 'strings.dart';

/// Strings of the first-run tour, its practice round and the locked tabs.
extension TourStrings on S {
  String get coachStartCard => t('coachStartCard');
  String coachKnowIt(String kana) => f('coachKnowIt', [kana]);
  String get coachDontKnowHold => t('coachDontKnowHold');
  String get coachDontKnowButton => t('coachDontKnowButton');
  String get coachDontKnowOff => t('coachDontKnowOff');
  String get coachFast => t('coachFast');
  String get coachDone => t('coachDone');
  String get coachRetryKnow => t('coachRetryKnow');
  String get coachRetryHold => t('coachRetryHold');
  String get coachRetryButton => t('coachRetryButton');
}
