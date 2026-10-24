import 'strings.dart';

/// Strings of History's run review that its heroes and tiles add to the
/// tabs' own.
extension ReviewStrings on S {
  /// A practice run's hero: the cards swiped, how many were right.
  String reviewCardsWord(int n) => t(countKey('reviewCardsWord', n));
  String get reviewSwipedRun => t('reviewSwipedRun');
  String get reviewSwipedDrill => t('reviewSwipedDrill');
  String reviewRightOf(int right, int of) => f('reviewRightOf', [right, of]);

  /// A timed run's hero bar and tiles.
  String reviewThisRunTime(Object time) => f('reviewThisRunTime', [time]);
  String reviewVsLast(Object time, Object last) => f('reviewVsLast', [time, last]);
  String reviewYouTobi(Object you, Object tobi) => f('reviewYouTobi', [you, tobi]);
  String reviewTobiYou(Object tobi, Object you) => f('reviewTobiYou', [tobi, you]);
  String reviewClock(Object time) => f('reviewClock', [time]);
  String reviewAvgOver(int cards) => f(countKey('reviewAvgOver', cards), [cards]);

  /// The Speed tab: the strip's cards never played, the usual's tile.
  String get reviewNotPlayed => t('reviewNotPlayed');
  String get reviewBeforeRun => t('reviewBeforeRun');

  /// The Rating tab's tiles.
  String get reviewBefore => t('reviewBefore');
  String reviewFromScored(Object time) => f('reviewFromScored', [time]);
  String get reviewForfeitZero => t('reviewForfeitZero');
  String get reviewPartWay => t('reviewPartWay');
  String get reviewPlacedHere => t('reviewPlacedHere');

  /// Under the Cards tab's Practice these.
  String get reviewPractiseNote => t('reviewPractiseNote');

  /// The experience panel.
  String get reviewXpSources => t('reviewXpSources');

  /// A 暗記練 game's hero, tiles and score sum.
  String reviewPointsMade(Object card, Object early) => f('reviewPointsMade', [card, early]);
  String reviewCardPoints(Object card) => f('reviewCardPoints', [card]);
  String reviewUpFrom(Object best) => f('reviewUpFrom', [best]);
  String get reviewRightCardFirst => t('reviewRightCardFirst');
  String get reviewEveryCard => t('reviewEveryCard');
  String get reviewFirstTapFinds => t('reviewFirstTapFinds');
  String get reviewWrongTaps => t('reviewWrongTaps');
  String reviewUnderClears(int strikes) => f('reviewUnderClears', [strikes]);
  String reviewMemorisedOf(Object used, Object allowed) => f('reviewMemorisedOf', [used, allowed]);
  String get reviewSumTitle => t('reviewSumTitle');
}
