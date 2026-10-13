import '../domain/side_trips.dart';
import 'strings.dart';

/// Strings of the Side Trips tab (寄り道): its dojo scene, its islands, their
/// ranks, their ranked and free-play buttons, what still keeps them shut,
/// and 暗記練's rules.
extension SideTripStrings on S {
  String get sideTrips => t('sideTrips');

  /// The tab's title lettering, Japanese in every language, and the banner
  /// under it.
  String get sideTripsLettering => t('sideTripsLettering');
  String get sideTripsBanner => t('sideTripsBanner');

  /// The scene's "coming soon" tags.
  String get sideTripsMist => t('sideTripsMist');
  String get sideTripsBuilding => t('sideTripsBuilding');
  String get sideTripsSoon => t('sideTripsSoon');

  /// The banner under [trip]'s name, what it is, and the tag beside its
  /// lettering on the hub.
  String tripBanner(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenBanner'),
      };
  String tripAbout(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenAbout'),
      };
  String tripTag(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenTag'),
      };

  String get sideTripUnranked => t('sideTripUnranked');
  String get sideTripRanked => t('sideTripRanked');
  String sideTripRankedLevel(int level) => f('sideTripRankedLevel', [level]);
  String get sideTripFreeSub => t('sideTripFreeSub');
  String sideTripFreeUpTo(int level) => f('sideTripFreeUpTo', [level]);

  /// The next ranked game, and its facts (a template: cards a side, then
  /// the time to memorise them).
  String get sideTripNextGame => t('sideTripNextGame');
  String get sideTripNextFacts => t('sideTripNextFacts');

  /// A locked trip's cards remembered well so far, out of what opens it (a
  /// template).
  String get sideTripRemembered => t('sideTripRemembered');
  String get sideTripRememberedCount => t('sideTripRememberedCount');

  /// A locked button's line: [n] cards still to remember well.
  String sideTripLockedSub(int n) => f('sideTripLockedSub', [n]);

  /// The locked ranked bar's line: [n] cards still to remember well (a
  /// template, its number set in display type).
  String sideTripLandIn(int n) => t(n == 1 ? 'sideTripLandInOne' : 'sideTripLandInOther');

  /// What opens a trip, or its free play: remembering [n] more cards well.
  String sideTripLockedWhy(int n) => f(n == 1 ? 'sideTripLockedOne' : 'sideTripLockedOther', [n]);
  String sideTripFreeLockedWhy(int n) => f(n == 1 ? 'sideTripFreeLockedOne' : 'sideTripFreeLockedOther', [n]);

  /// 暗記練's rules: its three steps, a line on each, and its scoring.
  String get howToPlay => t('howToPlay');
  String get ankirenStepMemorise => t('ankirenStepMemorise');
  String get ankirenStepFlip => t('ankirenStepFlip');
  String get ankirenStepTake => t('ankirenStepTake');
  String get ankirenStepMemoriseNote => t('ankirenStepMemoriseNote');
  String get ankirenStepFlipNote => t('ankirenStepFlipNote');
  String get ankirenStepTakeNote => t('ankirenStepTakeNote');
  String get ankirenRulesScore => t('ankirenRulesScore');
  String get sideTripRulesDone => t('sideTripRulesDone');
}
