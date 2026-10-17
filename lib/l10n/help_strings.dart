import 'strings.dart';

/// Strings of the Help page itself; its guides bring their own
/// (`GuideStrings`, `RulesStrings`, `TourStrings`).
extension HelpStrings on S {
  String get helpGuides => t('helpGuides');
  String get helpTools => t('helpTools');
  String get helpToolsSoon => t('helpToolsSoon');
}
