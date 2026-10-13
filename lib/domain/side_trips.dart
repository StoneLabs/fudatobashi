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

/// The two ways into a side trip: its ranked games, which move its own
/// rating, and free play at any setup.
enum SideTripMode { ranked, free }

/// One mode of one side trip: what opens, and what the unlock latch keeps
/// open.
typedef SideTripGate = ({SideTrip trip, SideTripMode mode});

/// What keeps a side trip's mode shut in journey mode: it opens once
/// [opensAt] cards are well remembered at once, and [remembered] are now.
class SideTripLock {
  const SideTripLock({required this.opensAt, required this.remembered});

  final int opensAt;
  final int remembered;

  /// Cards still to remember well.
  int get needed => math.max(0, opensAt - remembered);
}

/// When side trips open: in journey mode once enough cards are well
/// remembered at once (`Trainer.wellRememberedCount`, free practice's
/// counter, thresholds in [SideTripTuning]), and for good once they have;
/// in all-known mode right away. A trip's own lock covers its ranked games.
abstract final class SideTripUnlocks {
  static final List<SideTripGate> gates = [
    for (final trip in SideTrip.values)
      for (final mode in SideTripMode.values) (trip: trip, mode: mode),
  ];

  /// Well-remembered cards [gate] needs in journey mode.
  static int opensAt(SideTripGate gate) => switch (gate) {
        (trip: SideTrip.ankiren, mode: SideTripMode.ranked) => SideTripTuning.ankirenRemembered,
        (trip: SideTrip.ankiren, mode: SideTripMode.free) => SideTripTuning.ankirenFreeRemembered,
      };

  /// What keeps [gate] shut, or null once it is open: [allKnown] mode and
  /// the [latched] gates are open whatever the [remembered] count.
  static SideTripLock? lockOf(
    SideTripGate gate, {
    required bool allKnown,
    required int remembered,
    required Set<SideTripGate> latched,
  }) {
    if (allKnown || latched.contains(gate)) return null;
    final need = opensAt(gate);
    return remembered >= need ? null : SideTripLock(opensAt: need, remembered: remembered);
  }

  /// [gate] as the latch stores it, e.g. `ankiren.free`.
  static String nameOf(SideTripGate gate) => '${gate.trip.name}.${gate.mode.name}';

  /// The gate stored as [name], or null for one that no longer exists.
  static SideTripGate? named(String name) => gates.where((g) => nameOf(g) == name).firstOrNull;
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

/// One island of the Side Trips tab: a [trip], what keeps it ([lock]) or
/// its free play ([freeLock]) shut, and its standing.
class SideTripEntry {
  const SideTripEntry({
    required this.trip,
    required this.lock,
    required this.freeLock,
    required this.rating,
    required this.ratingChange,
    required this.band,
    required this.rankedLevel,
    required this.maxLevel,
    required this.games,
  });

  final SideTrip trip;

  /// Null once the trip and its ranked games are open.
  final SideTripLock? lock;

  /// Null once its free play is open.
  final SideTripLock? freeLock;

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
  bool get freeOpen => freeLock == null;
  bool get ranked => rating != null;
}

/// The Side Trips tab: every side trip, in [SideTrip] order, with its locks
/// and standing.
class SideTripsHub {
  const SideTripsHub(this.entries);

  final List<SideTripEntry> entries;

  /// The hub for a player in [allKnown] mode or not, with [remembered]
  /// cards well remembered now, the [latched] gates open for good, and
  /// each trip's [standings] (none when missing).
  factory SideTripsHub.of({
    required bool allKnown,
    required int remembered,
    Set<SideTripGate> latched = const {},
    Map<SideTrip, SideTripStanding> standings = const {},
  }) {
    SideTripLock? lock(SideTrip trip, SideTripMode mode) =>
        SideTripUnlocks.lockOf((trip: trip, mode: mode), allKnown: allKnown, remembered: remembered, latched: latched);
    SideTripEntry entry(SideTrip trip) {
      final standing = standings[trip] ?? SideTripStanding.none;
      final rating = standing.rating;
      return SideTripEntry(
        trip: trip,
        lock: lock(trip, SideTripMode.ranked),
        freeLock: lock(trip, SideTripMode.free),
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

  /// The gates open now, for the unlock latch.
  Set<SideTripGate> get openGates => {
        for (final e in entries) ...[
          if (e.open) (trip: e.trip, mode: SideTripMode.ranked),
          if (e.freeOpen) (trip: e.trip, mode: SideTripMode.free),
        ],
      };
}
