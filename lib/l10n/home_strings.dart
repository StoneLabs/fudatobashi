import 'strings.dart';

/// Strings of the Home screens.
extension HomeStrings on S {
  /// The app's own name, kept as its Latin-script brand mark in every
  /// language rather than translated.
  String get brandSub => 'FUDATOBASHI';
  String get journeyBanner => t('journeyBanner');
  String get trainingBanner => t('trainingBanner');
  String get shoutStart => t('shoutStart');
  String get islandOf => t('islandOf');
  String get cardsOf => t('homeCardsOf');
  String islandsAhead(int n) => f(n == 1 ? 'islandsAheadOne' : 'islandsAheadOther', [n]);
  String get allIslandsReached => t('allIslandsReached');
  String get now => t('now');
  String get nextChip => t('nextChip');
  String get learnedOf => t('learnedOf');
  String get reviewsAndNew => t('reviewsAndNew');
  String get reviewsDue => t('reviewsDue');
  String get slowToBeat => t('slowToBeat');
  String get caughtUp => t('caughtUp');
  String finishIsland(String island) => f('finishIsland', [island]);
  String get letsGo => t('letsGo');
  String get keepGoing => t('homeKeepGoing');
  String get ratingLabel => t('ratingLabel');
  String get toNextBand => t('toNextBand');
  String get topBand => t('topBand');
  String get knownSpeedLabel => t('knownSpeedLabel');
  String get newCardsTodayLabel => t('newCardsTodayLabel');
  String get reviewsTodayLabel => t('reviewsTodayLabel');
  String get streakDays => t('streakDays');
  String get freePlaySub => t('freePlaySub');
  String get nigateSub => t('nigateSub');
  String get nigateNote => t('nigateNote');
  String get nigateEmpty => t('nigateEmpty');
  String get guestTitle => t('guestTitle');
  String get guestMode => t('guestMode');
  String get untrackedTag => t('untrackedTag');
  String get guestShort => t('guestShort');
  String get guestConfirmTitle => t('guestConfirmTitle');
  String get guestConfirm => t('guestConfirm');
  String get settingsLabel => t('settingsLabel');

  String get learnAhead => t('learnAhead');
  String get learnAheadLocked => t('learnAheadLocked');
  String learnAheadShaky(int n) => f(n == 1 ? 'learnAheadShakyOne' : 'learnAheadShakyOther', [n]);
  String get learnAheadPending => t('learnAheadPending');
}
