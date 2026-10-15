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

  // Journey Home's exam strip and Tobi's word when it opens, the banner
  // after passing, and its question.
  String get examStripSub => t('examStripSub');
  String get examVsTobi => t('examVsTobi');
  String examPenalty(int seconds) => f('examPenalty', [seconds]);
  String get examOpenPill => t('examOpenPill');
  String get examTryAgainIn => t('examTryAgainIn');
  String examCooldownWhy(String wait) => f('examCooldownWhy', [wait]);
  String get examIntro => t('examIntro');
  String get examIntroHint => t('examIntroHint');
  String get switchBanner => t('switchBanner');
  String get switchTag => t('switchTag');
  String get switchTitle => t('switchTitle');
  String get switchBody => t('switchBody');
  String get switchNow => t('switchNow');
  String get switchLater => t('switchLater');

  // The rank ladder before there is a rank.
  String get rankLockedTitle => t('rankLockedTitle');
  String get rankLockedBody => t('rankLockedBody');
  String get rankLockedSwitchTitle => t('rankLockedSwitchTitle');
  String get rankLockedSwitchBody => t('rankLockedSwitchBody');
  String get rankLockedSwitchButton => t('rankLockedSwitchButton');

  // All-known Home's ランク戦, ranked Results and the placement page.
  String get rankedChipAll => t('rankedChipAll');
  String get rankedChipMixed => t('rankedChipMixed');
  String get rankedChipNoMask => t('rankedChipNoMask');
  String get rankedChipCounts => t('rankedChipCounts');

  /// "Rating {0} · {1} to {band}": the rating and the points to [band].
  String rankedRatingLine(String band) => t('rankedRatingLine').replaceAll('{band}', band);
  String get rankedRatingTop => t('rankedRatingTop');
  String get rankedUnplacedLine => t('rankedUnplacedLine');
  String get shoutRanked => t('shoutRanked');
  String get notForRank => t('notForRank');
  String get streakKeep => t('streakKeep');
  String get rankUnplaced => t('rankUnplaced');
  String get rankLockedKnown => t('rankLockedKnown');
  String get rankedScoredTime => t('rankedScoredTime');
  String get rankedClockTime => t('rankedClockTime');

  /// "Misses: {0} × {1} s".
  String get rankedMisses => t('rankedMisses');

  /// "Cards left: {0} × {1} s".
  String get rankedCardsLeft => t('rankedCardsLeft');
  String rankedForfeitNote(int left) => f(left == 1 ? 'rankedForfeitNoteOne' : 'rankedForfeitNoteOther', [left]);
  String get rankedAgain => t('rankedAgain');
  String get rankedAgainSub => t('rankedAgainSub');
  String get ratingFirst => t('ratingFirst');
  String get placementBand => t('placementBand');
}
