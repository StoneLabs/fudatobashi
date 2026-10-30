import 'strings.dart';

/// Strings of the karuta guide in Help ("How karuta works"), whose text is
/// an article (`Articles.karutaGuide`): its row and title, and the stamp on
/// a card that has been read in First sounds' pictures.
extension GuideStrings on S {
  String get guideTitle => t('guideTitle');
  String get guideRowNote => t('guideRowNote');
  String get guideReadStamp => t('guideReadStamp');
}
