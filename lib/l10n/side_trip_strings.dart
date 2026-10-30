import '../domain/ankiren_field.dart';
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
        SideTripIsle.storehouse => t('teiichiName'),
        SideTripIsle.hall => t('sideTripsIsleHall'),
        SideTripIsle.rocks => t('sideTripsIsleRocks'),
        SideTripIsle.fort => t('sideTripsIsleFort'),
      };

  /// The screen-reader actions that turn the ring of islands.
  String get sideTripsNextIsland => t('sideTripsNextIsland');
  String get sideTripsPreviousIsland => t('sideTripsPreviousIsland');

  /// The banner under [trip]'s name, and the tag beside its lettering on
  /// the hub.
  String tripBanner(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenBanner'),
        SideTrip.teiichi => t('teiichiBanner'),
      };
  /// [trip]'s name: 暗記練 or 定位置 in Japanese, "AnkiRen" or "Teiichi"
  /// otherwise.
  String tripName(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenName'),
        SideTrip.teiichi => t('teiichiName'),
      };
  String tripTag(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenTag'),
        SideTrip.teiichi => t('teiichiTag'),
      };

  String get sideTripUnranked => t('sideTripUnranked');
  String get sideTripRanked => t('sideTripRanked');

  /// Free play's next level to clear, its facts (a template: cards a side,
  /// then the time to memorise them), and in its place once every level is
  /// cleared.
  String get sideTripNextLevel => t('sideTripNextLevel');
  String get sideTripNextFacts => t('sideTripNextFacts');
  String get sideTripAllClear => t('sideTripAllClear');

  /// A locked trip's cards seen so far, out of what opens it (a template).
  String get sideTripSeen => t('sideTripSeen');
  String get sideTripSeenCount => t('sideTripSeenCount');

  /// A locked trip in brief: [n] cards still to see.
  String sideTripLockedSub(int n) => f('sideTripLockedSub', [n]);

  /// The locked ranked bar's line: [n] cards still to see (a
  /// template, its number set in display type).
  String sideTripLandIn(int n) => t(n == 1 ? 'sideTripLandInOne' : 'sideTripLandInOther');

  /// What opens a trip: seeing [n] more cards.
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
  String ankirenRuleStrikes(int strikes) => f('ankirenRuleStrikes', [strikes]);
  String ankirenRuleRanked(int perSide, String memorise, int level) =>
      f('ankirenRuleRanked', [perSide, memorise, level]);
  String get ankirenScoring => t('ankirenScoring');
  String ankirenScoreFind(int firstTry, int speed) => f('ankirenScoreFind', [firstTry, speed]);

  /// Taps that miss score by where they land (the tier table): a card's
  /// first tap plus its second, which counts [percent]%; later ones not at
  /// all.
  String ankirenScoreNear(int percent) => f('ankirenScoreNear', [percent]);

  /// The tier table: its heads, a first tap on the card ([points] plus its
  /// speed bonus), and where a tap lands, nearest first.
  String get ankirenTierPlace => t('ankirenTierPlace');
  String get ankirenTierFirst => t('ankirenTierFirst');
  String get ankirenTierSecond => t('ankirenTierSecond');
  String ankirenTierSpeed(String points) => f('ankirenTierSpeed', [points]);
  String ankirenTier(TapProximity place) => switch (place) {
        TapProximity.card => t('ankirenTierCard'),
        TapProximity.neighbour => t('ankirenTierNeighbour'),
        TapProximity.row => t('ankirenTierRow'),
        TapProximity.quadrant => t('ankirenTierQuadrant'),
        TapProximity.side => t('ankirenTierSide'),
        TapProximity.otherSide => t('ankirenTierOtherSide'),
      };
  String ankirenScoreEarly(String factor) => f('ankirenScoreEarly', [factor]);
  String get ankirenScoreLevel => t('ankirenScoreLevel');

  /// The marks on the scoring rows: points, and level.
  String get ankirenMarkPoints => t('ankirenMarkPoints');
}
