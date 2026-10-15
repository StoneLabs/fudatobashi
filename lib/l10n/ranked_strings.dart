import 'strings.dart';

/// Strings of ranked mode (ランク戦) and the graduation exam (卒業試験).
extension RankedStrings on S {
  /// The RANKED tag: Latin capitals in every language, like the other tags.
  String get rankedTag => 'RANKED';
  String get rankedStartTitle => t('rankedStartTitle');
  String get rankedStartBody => t('rankedStartBody');
  String get rankedForfeitWarning => t('rankedForfeitWarning');
  String get rankedStart => t('rankedStart');
  String get forfeitTitle => t('forfeitTitle');
  String get forfeitBody => t('forfeitBody');
  String get forfeitYes => t('forfeitYes');
  String get forfeitNo => t('forfeitNo');
}
