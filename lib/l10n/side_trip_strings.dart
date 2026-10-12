import '../domain/side_trips.dart';
import 'strings.dart';

/// Strings of the Side Trips tab (寄り道): its islands, their ranks, their
/// ranked and free-play buttons, and what still keeps them shut.
extension SideTripStrings on S {
  String get sideTrips => t('sideTrips');
  String get sideTripsIntro => t('sideTripsIntro');
  String get sideTripsMore => t('sideTripsMore');

  /// The banner under [trip]'s name, and what it is.
  String tripBanner(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenBanner'),
      };
  String tripAbout(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => t('ankirenAbout'),
      };

  String get sideTripUnranked => t('sideTripUnranked');
  String sideTripGames(int n) => f(n == 1 ? 'sideTripGamesOne' : 'sideTripGamesOther', [n]);

  String get sideTripRanked => t('sideTripRanked');
  String sideTripRankedLevel(int level) => f('sideTripRankedLevel', [level]);
  String get sideTripRankedSub => t('sideTripRankedSub');
  String get sideTripFreeSub => t('sideTripFreeSub');
  String sideTripFreeUpTo(int level) => f('sideTripFreeUpTo', [level]);

  /// A locked button's line: [n] cards still to remember well.
  String sideTripLockedSub(int n) => f('sideTripLockedSub', [n]);

  /// What opens a trip, or its free play: remembering [n] more cards well.
  String sideTripLockedWhy(int n) => f(n == 1 ? 'sideTripLockedOne' : 'sideTripLockedOther', [n]);
  String sideTripFreeLockedWhy(int n) => f(n == 1 ? 'sideTripFreeLockedOne' : 'sideTripFreeLockedOther', [n]);
}
