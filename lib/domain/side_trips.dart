import 'dart:math' as math;

import '../config/config.dart';
import 'rating.dart';

/// The side trips (寄り道): games beside the journey that train other
/// skills, each an island of the Side Trips tab. [label] is its name, in
/// karuta's own Japanese whatever the UI language.
enum SideTrip {
  /// 暗記練: memorise a field of known cards, then take each by its kimariji.
  ankiren('暗記練');

  const SideTrip(this.label);

  final String label;
}

/// The islands of the Side Trips tab, in the order of their ring: each side
/// trip's, then those still being built.
enum SideTripIsle {
  ankiren(SideTrip.ankiren),
  building(null),
  fuji(null),
  lighthouse(null);

  const SideTripIsle(this.trip);

  /// The side trip played there; null while it is still being built.
  final SideTrip? trip;

  bool get comingSoon => trip == null;
}

/// The four places of the ring of islands, in the order an island passes
/// them as the ring turns back: it comes to the [front] from the [right],
/// which it reached from the [back], which it reached from the [left].
enum RingSlot { front, right, back, left }

/// The ring of islands on the Side Trips tab. It turns like a revolver's
/// cylinder, a step at a time and round forever either way: each step
/// forward brings the island on the right to the front, sends the front
/// one to the left, the left one to the back and the back one to the
/// right. At turn 0 the first island is in front.
abstract final class SideTripRing {
  static const isles = SideTripIsle.values;

  /// The island in front after [turn] steps (back ones count negative).
  static SideTripIsle frontAt(int turn) => isles[turn % isles.length];

  /// Where [isle] stands after [turn] steps.
  static RingSlot slotOf(SideTripIsle isle, int turn) => RingSlot.values[place(isle, turn.toDouble()).round()];

  /// How far round the ring [isle] is after [turn] steps, a fraction of
  /// the way between two slots while the ring turns: from 0 (the front) up
  /// to the [RingSlot] count, which is the front again.
  static double place(SideTripIsle isle, double turn) => (isle.index - turn) % isles.length;
}

/// What keeps the Side Trips tab or a side trip shut in journey mode: it
/// opens once [opensAt] cards are well remembered at once, and
/// [remembered] are now.
class SideTripLock {
  const SideTripLock({required this.opensAt, required this.remembered});

  final int opensAt;
  final int remembered;

  /// Cards still to remember well.
  int get needed => math.max(0, opensAt - remembered);
}

/// When the Side Trips tab and its trips open: in journey mode once enough
/// cards are well remembered at once (`Trainer.wellRememberedCount`, free
/// practice's counter, thresholds in [SideTripTuning]), and for good once
/// they have; in all-known mode right away. A trip opens whole, its ranked
/// games and free play together.
abstract final class SideTripUnlocks {
  /// Well-remembered cards [trip] needs in journey mode.
  static int opensAt(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => SideTripTuning.ankirenRemembered,
      };

  /// What keeps the tab shut, or null once it is open: in [allKnown] mode,
  /// or once [latched], it is open whatever the [remembered] count.
  static SideTripLock? tabLock({required bool allKnown, required int remembered, required bool latched}) =>
      _lock(SideTripTuning.tabRemembered, open: allKnown || latched, remembered: remembered);

  /// What keeps [trip] shut, or null once it is open: in [allKnown] mode,
  /// or once among the [latched] trips, it is open whatever the
  /// [remembered] count.
  static SideTripLock? lockOf(
    SideTrip trip, {
    required bool allKnown,
    required int remembered,
    required Set<SideTrip> latched,
  }) =>
      _lock(opensAt(trip), open: allKnown || latched.contains(trip), remembered: remembered);

  static SideTripLock? _lock(int opensAt, {required bool open, required int remembered}) =>
      open || remembered >= opensAt ? null : SideTripLock(opensAt: opensAt, remembered: remembered);
}

/// A side trip's standing so far, as plain values: its ranked [rating]
/// and the last ranked game's [ratingChange] (both null until a ranked game
/// is played), the [rankedLevel] ranked plays at now and the highest level
/// the known cards allow ([maxLevel]; either null while unknown), and the
/// [games] played, ranked or free.
class SideTripStanding {
  const SideTripStanding({this.rating, this.ratingChange, this.rankedLevel, this.maxLevel, this.games = 0});

  static const none = SideTripStanding();

  final double? rating;
  final double? ratingChange;
  final int? rankedLevel;
  final int? maxLevel;
  final int games;
}

/// One island of the Side Trips tab: a [trip], what keeps it shut
/// ([lock]), and its standing.
class SideTripEntry {
  const SideTripEntry({
    required this.trip,
    required this.lock,
    required this.rating,
    required this.ratingChange,
    required this.band,
    required this.rankedLevel,
    required this.maxLevel,
    required this.games,
  });

  final SideTrip trip;

  /// Null once the trip, its ranked games and free play, is open.
  final SideTripLock? lock;

  /// The ranked rating, and what the last ranked game did to it; null
  /// until a ranked game is played.
  final double? rating;
  final double? ratingChange;

  /// The class of [rating] on the main rank's ladder; 入門 before any.
  final RankBand band;

  /// The level a ranked game plays at now, and the highest one the known
  /// cards allow; null while unknown.
  final int? rankedLevel;
  final int? maxLevel;
  final int games;

  bool get open => lock == null;
  bool get ranked => rating != null;
}

/// The Side Trips tab: every side trip, in [SideTrip] order, with its locks
/// and standing.
class SideTripsHub {
  const SideTripsHub(this.entries);

  final List<SideTripEntry> entries;

  /// The hub for a player in [allKnown] mode or not, with [remembered]
  /// cards well remembered now, the [latched] trips open for good, and
  /// each trip's [standings] (none when missing).
  factory SideTripsHub.of({
    required bool allKnown,
    required int remembered,
    Set<SideTrip> latched = const {},
    Map<SideTrip, SideTripStanding> standings = const {},
  }) {
    SideTripEntry entry(SideTrip trip) {
      final standing = standings[trip] ?? SideTripStanding.none;
      final rating = standing.rating;
      return SideTripEntry(
        trip: trip,
        lock: SideTripUnlocks.lockOf(trip, allKnown: allKnown, remembered: remembered, latched: latched),
        rating: rating,
        ratingChange: standing.ratingChange,
        band: rating == null ? Rating.bands.first : Rating.bandOf(rating),
        rankedLevel: standing.rankedLevel,
        maxLevel: standing.maxLevel,
        games: standing.games,
      );
    }

    return SideTripsHub([for (final trip in SideTrip.values) entry(trip)]);
  }

  SideTripEntry operator [](SideTrip trip) => entries.firstWhere((e) => e.trip == trip);

  /// The trips open now, for the unlock latch.
  Set<SideTrip> get openTrips => {
        for (final e in entries)
          if (e.open) e.trip,
      };
}
