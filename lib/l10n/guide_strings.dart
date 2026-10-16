import '../config/design.dart';
import 'strings.dart';

/// Strings of the karuta guide in Help ("How karuta works"). The kana a
/// line names come in as `{0}`, `{1}` … from the poems themselves.
extension GuideStrings on S {
  String get guideTitle => t('guideTitle');
  String get guideRowNote => t('guideRowNote');
  String get guideIntro => t('guideIntro');

  String get guidePoemsTitle => t('guidePoemsTitle');
  String get guidePoems1 => t('guidePoems1');
  String get guidePoems2 => t('guidePoems2');
  String get guidePoems3 => t('guidePoems3');
  String get guideFirstHalf => t('guideFirstHalf');
  String get guideSecondHalf => t('guideSecondHalf');

  String get guideCardsTitle => t('guideCardsTitle');
  String get guideCards1 => t('guideCards1');
  String get guideCards2 => t('guideCards2');
  String get guideYomifuda => t('guideYomifuda');
  String get guideYomifudaNote => t('guideYomifudaNote');
  String get guideTorifuda => t('guideTorifuda');
  String get guideTorifudaNote => t('guideTorifudaNote');
  String get guideCardsTobi => t('guideCardsTobi');

  String get guideMatchTitle => t('guideMatchTitle');

  /// A match from dealing the cards to the win, one line a step.
  List<String> get guideSteps => [for (var i = 1; i <= KarutaGuideExamples.steps; i++) t('guideStep$i')];
  String get guideTheirSide => t('guideTheirSide');
  String get guideYourSide => t('guideYourSide');
  String get guideFieldRead => t('guideFieldRead');
  String get guideMatchTobi => t('guideMatchTobi');

  String get guideFaultTitle => t('guideFaultTitle');
  String get guideFault1 => t('guideFault1');
  String get guideFault2 => t('guideFault2');
  String get guideFault3 => t('guideFault3');
  String get guideFaultTobi => t('guideFaultTobi');

  String get guideKimarijiTitle => t('guideKimarijiTitle');
  String get guideKimariji1 => t('guideKimariji1');
  String get guideOneTitle => t('guideOneTitle');
  String guideOne(String mnemonic) => f('guideOne', [mnemonic]);
  String get guideLongTitle => t('guideLongTitle');
  String guideLong(String first, String second, String shared) => f('guideLong', [first, second, shared]);
  String get guideLongCaption => t('guideLongCaption');
  String get guideChangeTitle => t('guideChangeTitle');
  String guideChange(String read, String left, String shared) => f('guideChange', [read, left, shared]);
  String get guideReadStamp => t('guideReadStamp');
  String get guideChangeCaption => t('guideChangeCaption');
  String guideSix(List<String> starts) => f('guideSix', starts);
  String get guideKimarijiTobi => t('guideKimarijiTobi');

  String get guideAppTitle => t('guideAppTitle');
  String get guideApp1 => t('guideApp1');
  String get guideApp2 => t('guideApp2');
  String get guideAppTobi => t('guideAppTobi');
}
