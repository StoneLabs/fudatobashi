import '../domain/xp.dart';
import 'strings.dart';

/// Strings of the results screen and its celebration overlays.
extension ResultsStrings on S {
  String get keepGoing => t('resultsKeepGoing');
  String get keepGoingSub => t('keepGoingSub');
  String get homeSub => t('homeSub');
  String get endedEarly => t('endedEarly');
  String timeSaved(String seconds) => f('timeSaved', [seconds]);
  String get firstRecordedRun => t('firstRecordedRun');
  String get guestNotRecorded => t('guestNotRecorded');

  String get newCardsHeading => t('newCardsHeading');
  String get newCardsLabel => t('newCardsLabel');
  String get newCardsNote => t('newCardsNote');

  String get toughestHeading => t('toughestHeading');
  String get toughestNote => t('toughestNote');

  String get avgPerCardLabel => t('avgPerCardLabel');
  String knownOf(int known, int total) => f('knownOf', [known, total]);
  String get knownSpeedNote => t('knownSpeedNote');

  String get newCardShout => t('newCardShout');
  String get newCardBand => t('newCardBand');

  /// Where a card is decided; `{0}` marks where the deciding kana goes.
  String deciderTip(int position, String? twin) {
    final nth = ja ? '$position音目' : '${_ordinal(position)} sound';
    if (twin == null) return t('deciderTipNoTwin').replaceAll('{nth}', nth);
    return t('deciderTipTwin').replaceAll('{nth}', nth).replaceAll('{twin}', twin);
  }

  static String _ordinal(int n) => switch (n % 100) {
        11 || 12 || 13 => '${n}th',
        _ => switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' },
      };

  String get learnAboutCard => t('learnAboutCard');
  String get bringItOn => t('bringItOn');

  String get lookAlikeBand => t('lookAlikeBand');
  String get mixUpWarning => t('mixUpWarning');
  String get gotIt => t('gotIt');

  String get islandCompleteBand => t('islandCompleteBand');
  String get cardsLearnedOf => t('cardsLearnedOf');
  String get nextIslandBand => t('nextIslandBand');
  String nextIslandNote(int cards, String first, String second) => f('nextIslandNote', [cards, first, second]);
  String get islandProgress => t('islandProgress');
  String get allIslandsDone => t('allIslandsDone');
  String get setSail => t('setSail');

  String get rankUpBand => t('rankUpBand');
  String get beforeBandLabel => t('beforeBandLabel');
  String get nowBandLabel => t('nowBandLabel');
  String get newBadge => t('newBadge');
  String get onward => t('onward');
  String get nextClassBand => t('nextClassBand');
  String get nextClassTarget => t('nextClassTarget');
  String get nextClassPace => t('nextClassPace');
  String get topClassReached => t('topClassReached');
  String get topClassChase => t('topClassChase');

  String get xpBand => t('xpBand');
  String get xpUnit => t('xpUnit');
  String levelShort(int level) => f('levelShort', [level]);
  String xpToNext(int xp, int level) => f('xpToNext', [xp, level]);
  String get levelUpFlash => t('levelUpFlash');
  String get xpCta => t('xpCta');

  String xpSource(XpSource source) => switch (source) {
        XpSource.correct => t('xpSourceCorrect'),
        XpSource.missed => t('xpSourceMissed'),
        XpSource.speed => t('xpSourceSpeed'),
        XpSource.reviews => t('xpSourceReviews'),
        XpSource.newCards => t('xpSourceNewCards'),
        XpSource.clear => t('xpSourceClear'),
        XpSource.daily => t('xpSourceDaily'),
        XpSource.best => t('xpSourceBest'),
        XpSource.island => t('xpSourceIsland'),
        XpSource.graduation => t('xpSourceGraduation'),
      };

  /// The count beside an XP line, or null where it says nothing.
  String? xpCount(XpPart part) => switch (part.source) {
        XpSource.clear || XpSource.best || XpSource.graduation => null,
        XpSource.daily => part.count > 1 ? dayStreak(part.count) : null,
        _ => f('xpCountTimes', [part.count]),
      };

  String get levelUpBand => t('levelUpBand');
  String levelsGained(int n) => f('levelsGained', [n]);
  String get nextLevelBand => t('nextLevelBand');

  String get ratingBand => t('ratingBand');

  /// `{0}` marks the points, `{band}` the class they lead to.
  String ratingToNext(String band) => t('ratingToNext').replaceAll('{band}', band);
  String get ratingCta => t('ratingCta');

  String get graduationBand => t('graduationBand');
  String get graduationKai => t('graduationKai');
  String get graduationKaiNote => t('graduationKaiNote');
  String get graduationSwitch => t('graduationSwitch');
  String get graduationCta => t('graduationCta');

  String get goalUpBand => t('goalUpBand');
  String goalUpNote(int ms) => f('goalUpNote', [ms]);
  String get nicePace => t('nicePace');
}
