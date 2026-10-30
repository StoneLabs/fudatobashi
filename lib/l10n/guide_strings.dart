import 'strings.dart';

/// Strings of the karuta guide in Help ("How karuta works"), whose text is
/// an article (`Articles.karutaGuide`): its row and title.
extension GuideStrings on S {
  String get guideTitle => t('guideTitle');
  String get guideRowNote => t('guideRowNote');
}
