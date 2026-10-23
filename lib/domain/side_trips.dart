import 'dart:math' as math;

import '../config/config.dart';
import 'ankiren_level.dart';
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
/// opens once [opensAt] cards are counted, and [counted] are now. What
/// counts depends on the lock: well-remembered cards for the tab, seen
/// cards for a trip (see [SideTripUnlocks]).
class SideTripLock {
  const SideTripLock({required this.opensAt, required this.counted});

  final int opensAt;
  final int counted;

  /// Cards still to count.
  int get needed => math.max(0, opensAt - counted);
}

/// When the Side Trips tab and its trips open: in journey mode the tab once
/// enough cards are well remembered at once (`Trainer.wellRememberedCount`,
/// free practice's counter) and a trip once enough cards have been seen
/// (`Progress.knownCards`), thresholds in [SideTripTuning], and for good
/// once they have; in all-known mode right away. A trip opens with its free
/// play; its ranked games need more (see [RankedLock]).
abstract final class SideTripUnlocks {
  /// Seen cards [trip] needs in journey mode.
  static int opensAt(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => SideTripTuning.ankirenSeen,
      };

  /// What keeps the tab shut, or null once it is open: in [allKnown] mode,
  /// or once [latched], it is open whatever the [remembered] count.
  static SideTripLock? tabLock({required bool allKnown, required int remembered, required bool latched}) =>
      _lock(SideTripTuning.tabRemembered, open: allKnown || latched, counted: remembered);

  /// What keeps [trip] shut, or null once it is open: in [allKnown] mode,
  /// or once among the [latched] trips, it is open whatever the [seen]
  /// count.
  static SideTripLock? lockOf(
    SideTrip trip, {
    required bool allKnown,
    required int seen,
    required Set<SideTrip> latched,
  }) =>
      _lock(opensAt(trip), open: allKnown || latched.contains(trip), counted: seen);

  static SideTripLock? _lock(int opensAt, {required bool open, required int counted}) =>
      open || counted >= opensAt ? null : SideTripLock(opensAt: opensAt, counted: counted);
}

/// What keeps an open trip's ranked games shut: they need the all-known
/// learning mode ([allKnown] false until it is on) and free play's level
/// [AnkirenTuning.rankedAfterLevel] cleared ([cleared] false until it is).
class RankedLock {
  const RankedLock({required this.allKnown, required this.cleared});

  final bool allKnown;
  final bool cleared;

  /// The free-play level to clear.
  static int get level => AnkirenTuning.rankedAfterLevel;

  /// What ranked still needs, or null once it is open.
  static RankedLock? of({required bool allKnown, required AnkirenLadder ladder}) =>
      allKnown && ladder.rankedReady ? null : RankedLock(allKnown: allKnown, cleared: ladder.rankedReady);
}

/// One ranked game of a side trip: its [score] and what it did to the
/// rating ([ratingChange]).
class SideTripResult {
  const SideTripResult({required this.score, required this.ratingChange});

  final int score;
  final double ratingChange;
}

/// A side trip's standing so far, as plain values: its ranked [rating]
/// and the last ranked game's [ratingChange] (both null until a ranked game
/// is played), free play's [ladder], the highest level the known cards allow
/// ([maxLevel]; null while unknown or when none fits), the [games] played,
/// ranked or free, and the ranked ones' [results], oldest first.
class SideTripStanding {
  const SideTripStanding({
    this.rating,
    this.ratingChange,
    this.ladder = AnkirenLadder.none,
    this.maxLevel,
    this.games = 0,
    this.results = const [],
  });

  static const none = SideTripStanding();

  final double? rating;
  final double? ratingChange;
  final AnkirenLadder ladder;
  final int? maxLevel;
  final int games;
  final List<SideTripResult> results;
}

/// One island of the Side Trips tab: a [trip], what keeps it shut
/// ([lock]) or its ranked games ([rankedLock]), and its standing.
class SideTripEntry {
  const SideTripEntry({
    required this.trip,
    required this.lock,
    required this.rankedLock,
    required this.rating,
    required this.ratingChange,
    required this.band,
    required this.ladder,
    required this.maxLevel,
    required this.games,
    required this.results,
  });

  final SideTrip trip;

  /// Null once the trip, its free play and its page, is open.
  final SideTripLock? lock;

  /// Null once its ranked games are open too.
  final RankedLock? rankedLock;

  /// The ranked rating, and what the last ranked game did to it; null
  /// until a ranked game is played.
  final double? rating;
  final double? ratingChange;

  /// The class of [rating] on the main rank's ladder; 入門 before any.
  final RankBand band;

  /// Free play's levels cleared and open, and the highest level the known
  /// cards allow (null while unknown or when none fits).
  final AnkirenLadder ladder;
  final int? maxLevel;
  final int games;

  /// The ranked games that moved the rating, oldest first.
  final List<SideTripResult> results;

  bool get open => lock == null;
  bool get rankedOpen => open && rankedLock == null;
  bool get ranked => rating != null;

  /// The free-play level to clear next and whether the known cards fill
  /// it; null once every level is cleared.
  int? get nextLevel => ladder.next;
  bool fits(int level) => maxLevel != null && level <= maxLevel!;
}

/// The Side Trips tab: every side trip, in [SideTrip] order, with its locks
/// and standing.
class SideTripsHub {
  const SideTripsHub(this.entries);

  final List<SideTripEntry> entries;

  /// The hub for a player in [allKnown] mode or not, with [seen] cards seen
  /// so far, the [latched] trips open for good, and each trip's
  /// [standings] (none when missing).
  factory SideTripsHub.of({
    required bool allKnown,
    required int seen,
    Set<SideTrip> latched = const {},
    Map<SideTrip, SideTripStanding> standings = const {},
  }) {
    SideTripEntry entry(SideTrip trip) {
      final standing = standings[trip] ?? SideTripStanding.none;
      final rating = standing.rating;
      return SideTripEntry(
        trip: trip,
        lock: SideTripUnlocks.lockOf(trip, allKnown: allKnown, seen: seen, latched: latched),
        rankedLock: RankedLock.of(allKnown: allKnown, ladder: standing.ladder),
        rating: rating,
        ratingChange: standing.ratingChange,
        band: rating == null ? Rating.bands.first : Rating.bandOf(rating),
        ladder: standing.ladder,
        maxLevel: standing.maxLevel,
        games: standing.games,
        results: standing.results,
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
