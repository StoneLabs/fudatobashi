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
  String get nextChip => t('nextChip');
  String get learnedOf => t('learnedOf');
  String get caughtUp => t('caughtUp');
  String get letsGo => t('letsGo');
  String get ratingLabel => t('ratingLabel');
  String get toNextBand => t('toNextBand');
  String get topBand => t('topBand');
  String get knownSpeedLabel => t('knownSpeedLabel');
  String get streakDays => t('streakDays');
  String get freePlaySub => t('freePlaySub');
  String get nigateSub => t('nigateSub');
  String get nigateEmpty => t('nigateEmpty');
  String get nigateNone => t('nigateNone');
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
  String learnAheadDailyLimit(int n) => f('learnAheadDailyLimit', [n]);

  String get todayLabel => t('todayLabel');
  String get todayCardsInRun => t('todayCardsInRun');
  String todayReviews(int cards, int looks) => f(countKey('todayReviews', cards), [cards, looks]);
  String get todayNoReviews => t('todayNoReviews');
  String todayNew(int cards, int looks) => f('todayNew', [cards, looks]);
  String get todayNoNew => t('todayNoNew');
  String get todayNewPaused => t('todayNewPaused');
  String get todayMisses => t('todayMisses');
  String get todayDone => t('todayDone');

  /// The 本日完了 hanko of a done day: a decorative Japanese stamp in every
  /// language.
  String get dayDoneStamp => '本日完了';

  /// A week stamp's weekday, for [DateTime.weekday] (1 is Monday).
  String weekdayLetter(int weekday) => t('weekdayLetters').split(' ')[weekday - 1];

  String get heroTodaySet => t('heroTodaySet');
  String get heroKeepItUp => t('heroKeepItUp');
  String get heroKeepGoing => t('heroKeepGoing');
  String get todayLeft => t('todayLeft');
  String get todayDoneExtra => t('todayDoneExtra');

  String pauseTitle(int reviews) => f('pauseTitle', [reviews]);
  String get pauseBody => t('pauseBody');
  String get pauseNote => t('pauseNote');
  String get pauseYes => t('pauseYes');
  String get pauseNo => t('pauseNo');
  String get noticeOk => t('noticeOk');
}
