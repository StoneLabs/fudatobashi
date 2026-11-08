import 'dart:math' as math;

import '../config/config.dart';
import 'level_ladder.dart';
import 'rating.dart';
import 'teiichi_record.dart';
import 'trip_rating.dart';

/// The side trips (寄り道): games beside the journey that train other
/// skills, each an island of the Side Trips tab. [label] is its name, in
/// karuta's own Japanese whatever the UI language.
enum SideTrip {
  /// 暗記練: memorise a field of known cards, then take each by its kimariji.
  ankiren('暗記練', LadderRules.ankiren, TripRating.ankiren),

  /// 定位置: lay known cards out on the own side, then take each by its
  /// kimariji, as in 暗記練.
  teiichi('定位置', LadderRules.teiichi, TripRating.teiichi);

  const SideTrip(this.label, this.ladder, this.rating);

  final String label;

  /// How its levels open.
  final LadderRules ladder;

  /// How its ranked games rate.
  final TripRating rating;

  /// Its levels with none cleared.
  LevelLadder get noLevels => LevelLadder(const {}, ladder);
}

/// The islands of the Side Trips tab, in the order of their ring: each side
/// trip's, then those still being built.
enum SideTripIsle {
  ankiren(SideTrip.ankiren),
  storehouse(SideTrip.teiichi),
  hall(null),
  rocks(null);

  const SideTripIsle(this.trip);

  /// The side trip played there; null for the hall, where 一騎打ち is
  /// played outside the side trips' levels and ratings, and for an island
  /// still being built.
  final SideTrip? trip;

  bool get comingSoon => trip == null && this != hall;
}

/// The ring of islands on the Side Trips tab, one slot for each island. It
/// turns like a revolver's cylinder, a step at a time and round forever
/// either way: each step forward brings the island on the right to the
/// front, sends the front one to the left and every other one a slot on
/// round the back, from the left towards the right. At turn 0 the first of
/// [isles] is in front.
///
/// The slots count from the front (0) the way an island goes as the ring
/// turns back: the right (1), round the back from right to left, and the
/// left last.
class SideTripRing {
  const SideTripRing(this.isles);

  /// The ring for islands [open] or not: from 一騎打ち's hall ([home]) on
  /// round in [SideTripIsle] order, the open islands first and the shut
  /// ones behind them, so the island in front at turn 0 is open whenever
  /// one is.
  factory SideTripRing.of(bool Function(SideTripIsle isle) open) {
    const all = SideTripIsle.values;
    final round = [for (var i = 0; i < all.length; i++) all[(home.index + i) % all.length]];
    return SideTripRing([...round.where(open), ...round.where((isle) => !open(isle))]);
  }

  /// The island the ring starts on when every island is open.
  static const home = SideTripIsle.hall;

  final List<SideTripIsle> isles;

  /// The island in front after [turn] steps (back ones count negative).
  SideTripIsle frontAt(int turn) => isles[turn % isles.length];

  /// The slot [isle] stands in after [turn] steps.
  int slotOf(SideTripIsle isle, int turn) => place(isle, turn.toDouble()).round();

  /// How far round the ring [isle] is after [turn] steps, a fraction of
  /// the way between two slots while the ring turns: from 0 (the front) up
  /// to the island count, which is the front again.
  double place(SideTripIsle isle, double turn) => (isles.indexOf(isle) - turn) % isles.length;
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
/// play; its ranked games need more (see [RankedLock]). 一騎打ち's hall opens
/// once every card is known ([hallLock]).
abstract final class SideTripUnlocks {
  /// Seen cards [trip] needs in journey mode.
  static int opensAt(SideTrip trip) => switch (trip) {
        SideTrip.ankiren => SideTripTuning.ankirenSeen,
        SideTrip.teiichi => SideTripTuning.teiichiSeen,
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

  /// What keeps 一騎打ち's hall shut, or null once it is open: it needs
  /// [IkkiuchiUnlockTuning.known] cards [known], every one, which
  /// [allKnown] mode knows.
  static SideTripLock? hallLock({required bool allKnown, required int known}) =>
      _lock(IkkiuchiUnlockTuning.known, open: allKnown, counted: known);

  static SideTripLock? _lock(int opensAt, {required bool open, required int counted}) =>
      open || counted >= opensAt ? null : SideTripLock(opensAt: opensAt, counted: counted);
}

/// What keeps an open trip's ranked games shut: they need the all-known
/// learning mode ([allKnown] false until it is on) and the trip's [level]
/// cleared ([cleared] false until it is).
class RankedLock {
  const RankedLock({required this.allKnown, required this.cleared, required this.level});

  final bool allKnown;
  final bool cleared;

  /// The level to clear ([LadderRules.rankedAfter]).
  final int level;

  /// What ranked still needs, or null once it is open.
  static RankedLock? of({required bool allKnown, required LevelLadder ladder}) => allKnown && ladder.rankedReady
      ? null
      : RankedLock(allKnown: allKnown, cleared: ladder.rankedReady, level: ladder.rules.rankedAfter);
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
/// ranked or free, the ranked ones' [results], oldest first, and 定位置's
/// [placing] record.
class SideTripStanding {
  const SideTripStanding({
    this.rating,
    this.ratingChange,
    this.ladder = LevelLadder.none,
    this.maxLevel,
    this.games = 0,
    this.results = const [],
    this.placing = TeiichiRecord.none,
  });

  final double? rating;
  final double? ratingChange;
  final LevelLadder ladder;
  final int? maxLevel;
  final int games;
  final List<SideTripResult> results;
  final TeiichiRecord placing;
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
    this.placing = TeiichiRecord.none,
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
  final LevelLadder ladder;
  final int? maxLevel;
  final int games;

  /// The ranked games that moved the rating, oldest first.
  final List<SideTripResult> results;

  /// 定位置's best placing time and last game.
  final TeiichiRecord placing;

  bool get open => lock == null;
  bool get rankedOpen => open && rankedLock == null;
  bool get ranked => rating != null;

  /// The free-play level to clear next and whether the known cards fill
  /// it; null once every level is cleared.
  int? get nextLevel => ladder.next;
  bool fits(int level) => maxLevel != null && level <= maxLevel!;
}

/// The Side Trips tab: every side trip, in [SideTrip] order, with its locks
/// and standing, and what keeps 一騎打ち's hall shut ([hallLock]).
class SideTripsHub {
  const SideTripsHub(this.entries, {this.hallLock});

  final List<SideTripEntry> entries;

  /// Null once 一騎打ち's hall is open.
  final SideTripLock? hallLock;

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
      final standing = standings[trip] ?? SideTripStanding(ladder: trip.noLevels);
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
        placing: standing.placing,
      );
    }

    return SideTripsHub(
      [for (final trip in SideTrip.values) entry(trip)],
      hallLock: SideTripUnlocks.hallLock(allKnown: allKnown, known: seen),
    );
  }

  SideTripEntry operator [](SideTrip trip) => entries.firstWhere((e) => e.trip == trip);

  /// Whether [isle] is open: its trip, or 一騎打ち's hall; never an island
  /// still being built.
  bool isOpen(SideTripIsle isle) => switch (isle.trip) {
        final trip? => this[trip].open,
        null => isle == SideTripIsle.hall && hallLock == null,
      };

  /// The ring of islands, the open ones first ([SideTripRing.of]).
  SideTripRing get ring => SideTripRing.of(isOpen);

  /// The trips open now, for the unlock latch.
  Set<SideTrip> get openTrips => {
        for (final e in entries)
          if (e.open) e.trip,
      };
}
