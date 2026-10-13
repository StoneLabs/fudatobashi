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

  /// The scene's "coming soon" tag.
  String get sideTripsBuilding => t('sideTripsBuilding');
  String get sideTripsSoon => t('sideTripsSoon');

  /// An island still being built: its lettering (Japanese in every
  /// language) and banner, and its panel's title and line.
  String get sideTripsSoonLettering => t('sideTripsSoonLettering');
  String get sideTripsSoonBanner => t('sideTripsSoonBanner');
  String get sideTripsSoonTitle => t('sideTripsSoonTitle');
  String get sideTripsSoonLine => t('sideTripsSoonLine');

  /// [isle]'s name, for screen readers.
  String isleName(SideTripIsle isle) => switch (isle) {
        SideTripIsle.ankiren => t('ankirenName'),
        SideTripIsle.building => t('sideTripsIsleBuilding'),
        SideTripIsle.fuji => t('sideTripsIsleFuji'),
        SideTripIsle.lighthouse => t('sideTripsIsleLighthouse'),
      };

  /// The screen-reader actions that turn the ring of islands.
  String get sideTripsNextIsland => t('sideTripsNextIsland');
  String get sideTripsPreviousIsland => t('sideTripsPreviousIsland');

  /// The banner under [trip]'s name, and the tag beside its lettering on
  /// the hub.
  String tripBanner(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenBanner'),
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

  /// A locked trip in brief: [n] cards still to remember well.
  String sideTripLockedSub(int n) => f('sideTripLockedSub', [n]);

  /// The locked ranked bar's line: [n] cards still to remember well (a
  /// template, its number set in display type).
  String sideTripLandIn(int n) => t(n == 1 ? 'sideTripLandInOne' : 'sideTripLandInOther');

  /// What opens a trip: remembering [n] more cards well.
  String sideTripLockedWhy(int n) => f(n == 1 ? 'sideTripLockedOne' : 'sideTripLockedOther', [n]);

  /// A trip's class on the main rank's ladder.
  String get sideTripClass => t('sideTripClass');

  /// 暗記練's rules: its three steps with a line on each, what a miss or
  /// leaving does, and how a game scores. The templates take their numbers
  /// from the tuning.
  String get howToPlay => t('howToPlay');
  String get ankirenStepMemorise => t('ankirenStepMemorise');
  String get ankirenStepFlip => t('ankirenStepFlip');
  String get ankirenStepTake => t('ankirenStepTake');
  String get ankirenStepMemoriseLine => t('ankirenStepMemoriseLine');
  String get ankirenStepFlipLine => t('ankirenStepFlipLine');
  String get ankirenStepTakeLine => t('ankirenStepTakeLine');
  String get ankirenRuleWrong => t('ankirenRuleWrong');
  String ankirenRuleReveal(int taps) => f('ankirenRuleReveal', [taps]);
  String get ankirenRuleDontKnow => t('ankirenRuleDontKnow');
  String get ankirenRuleLeave => t('ankirenRuleLeave');
  String get ankirenScoring => t('ankirenScoring');
  String ankirenScoreFind(int firstTry, int speed, int secondTry) =>
      f('ankirenScoreFind', [firstTry, speed, secondTry]);
  String ankirenScoreEarly(String factor) => f('ankirenScoreEarly', [factor]);
  String get ankirenScoreLevel => t('ankirenScoreLevel');

  /// The marks on the scoring rows: points, and level.
  String get ankirenMarkPoints => t('ankirenMarkPoints');
  String get ankirenMarkLevel => t('ankirenMarkLevel');
}
