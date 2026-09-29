import 'strings.dart';

/// Strings of the My Profile page.
extension ProfileStrings on S {
  String get myProfile => t('myProfile');

  /// "{0} / {1} well remembered", the numbers set in display type by
  /// `NumberedText` (paired with `HomeStrings.learnedOf`).
  String get wellRememberedOf => t('wellRememberedOf');

  String firstSwipeOn(String at) => f('firstSwipeOn', [at]);
}
