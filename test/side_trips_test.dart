import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/tab_locks.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

void main() {
  const ankiren = SideTrip.ankiren;
  const tabAt = SideTripTuning.tabRemembered, ankirenAt = SideTripTuning.ankirenRemembered;

  group('unlock rule', () {
    SideTripLock? lock(int remembered, {bool allKnown = false, Set<SideTrip> latched = const {}}) =>
        SideTripUnlocks.lockOf(ankiren, allKnown: allKnown, remembered: remembered, latched: latched);
    SideTripLock? tab(int remembered, {bool allKnown = false, bool latched = false}) =>
        SideTripUnlocks.tabLock(allKnown: allKnown, remembered: remembered, latched: latched);

    test('journey: the tab opens at 25 well-remembered cards, 暗記練 at 50', () {
      expect([tabAt, ankirenAt], [25, 50]);
      expect(SideTripUnlocks.opensAt(ankiren), ankirenAt);

      final shut = tab(18)!;
      expect([shut.opensAt, shut.remembered, shut.needed], [tabAt, 18, 7]);
      expect(tab(tabAt - 1)?.needed, 1);
      expect(tab(tabAt), isNull);

      expect(lock(tabAt)?.needed, ankirenAt - tabAt, reason: 'the tab opens before the game');
      expect(lock(ankirenAt - 1)?.needed, 1);
      expect(lock(ankirenAt), isNull);
    });

    test('a latch keeps the tab or a trip open whatever the count, and all-known mode opens both', () {
      expect(tab(0, latched: true), isNull);
      expect(lock(0, latched: {ankiren}), isNull);
      expect(tab(0, allKnown: true), isNull);
      expect(lock(0, allKnown: true), isNull);
    });
  });

  group('ring', () {
    test('turns forward and back forever, one island a step, the right one coming to the front', () {
      expect([for (var t = -5; t <= 5; t++) SideTripRing.frontAt(t)], [
        SideTripIsle.lighthouse,
        SideTripIsle.ankiren,
        SideTripIsle.building,
        SideTripIsle.fuji,
        SideTripIsle.lighthouse,
        SideTripIsle.ankiren,
        SideTripIsle.building,
        SideTripIsle.fuji,
        SideTripIsle.lighthouse,
        SideTripIsle.ankiren,
        SideTripIsle.building,
      ]);
      expect(SideTripIsle.ankiren.trip, SideTrip.ankiren);
      expect([for (final isle in SideTripRing.isles) isle.comingSoon], [false, true, true, true]);
    });

    test('each step moves every island on a slot: right to front, front to left, left to back, back to right', () {
      Map<SideTripIsle, RingSlot> at(int turn) => {for (final i in SideTripRing.isles) i: SideTripRing.slotOf(i, turn)};
      expect(at(0), {
        SideTripIsle.ankiren: RingSlot.front,
        SideTripIsle.building: RingSlot.right,
        SideTripIsle.fuji: RingSlot.back,
        SideTripIsle.lighthouse: RingSlot.left,
      });
      for (var turn = -6; turn < 6; turn++) {
        for (final isle in SideTripRing.isles) {
          final next = switch (SideTripRing.slotOf(isle, turn)) {
            RingSlot.right => RingSlot.front,
            RingSlot.front => RingSlot.left,
            RingSlot.left => RingSlot.back,
            RingSlot.back => RingSlot.right,
          };
          expect(SideTripRing.slotOf(isle, turn + 1), next, reason: '$isle at $turn');
        }
      }
      expect(SideTripRing.place(SideTripIsle.building, 0.25), 0.75, reason: 'part of the way to the front');
      expect(SideTripRing.place(SideTripIsle.ankiren, 0.25), 3.75, reason: 'part of the way to the left');
      expect(SideTripRing.place(SideTripIsle.ankiren, -4.5), 0.5);
    });
  });

  group('hub', () {
    test('a fresh journey: every trip in order, locked, unranked at 入門, nothing played', () {
      final hub = SideTripsHub.of(allKnown: false, remembered: 3);
      expect(hub.entries.map((e) => e.trip), SideTrip.values);
      final e = hub[SideTrip.ankiren];
      expect([e.open, e.ranked], [false, false]);
      expect(e.lock?.needed, ankirenAt - 3);
      expect(e.band, Rating.bands.first);
      expect([e.rating, e.rankedLevel, e.maxLevel, e.games], [null, null, null, 0]);
      expect(hub.openTrips, isEmpty);
    });

    test('opens 暗記練 whole at 50, and reports the open trips for the latch', () {
      expect(SideTripsHub.of(allKnown: false, remembered: ankirenAt - 1).openTrips, isEmpty);
      expect(SideTripsHub.of(allKnown: false, remembered: ankirenAt).openTrips, {ankiren});
      expect(SideTripsHub.of(allKnown: false, remembered: 0, latched: {ankiren}).openTrips, {ankiren});
      expect(SideTripsHub.of(allKnown: true, remembered: 0).openTrips, {...SideTrip.values});
    });

    test('a standing carries through, its rating placed on the main ladder', () {
      final rating = Rating.bands[3].minRating + 1;
      final hub = SideTripsHub.of(
        allKnown: true,
        remembered: 0,
        standings: {SideTrip.ankiren: SideTripStanding(rating: rating, rankedLevel: 4, maxLevel: 9, games: 12)},
      );
      final e = hub[SideTrip.ankiren];
      expect(e.ranked, isTrue);
      expect(e.band, Rating.bands[3]);
      expect([e.rating, e.rankedLevel, e.maxLevel, e.games], [rating, 4, 9, 12]);
    });
  });

  group('Progress', () {
    poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
    fudaSets = FudaSets(poems);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final journeyOrder = [for (final g in initialGroups) ...fudaSets['initial:$g'].poemIds];

    // Unlocks [ids] (journey) and trains each until it is well remembered.
    Future<void> remember(Progress p, Iterable<int> ids) async {
      for (final id in ids) {
        p.trainer.items[ItemKey(id, false)]!.unlocked = true;
      }
      final session = PlaySession([for (var i = 0; i < StatsTuning.solidMinTimed; i++) ...ids.map(CardRef.new)]);
      var t = const Duration(seconds: 100);
      while (!session.finished) {
        session.revealed(t);
        t += const Duration(milliseconds: 700);
        session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
        t += const Duration(milliseconds: 100);
      }
      await p.recordRun(session, const PlayConfig(mode: PlayMode.training), DateTime.now());
    }

    Future<String?> stored(AppDatabase db, String key) async =>
        (await (db.select(db.keyValues)..where((k) => k.key.equals(key))).getSingleOrNull())?.value;

    test('journey: the tab latches open at 25 and 暗記練 at 50; both survive a restart and a bad day, '
        'and a reset locks them again', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.journey);
      expect(p.tabLock(LockedTab.sideTrips)?.left, tabAt);
      expect(p.sideTripsHub().openTrips, isEmpty);

      await remember(p, journeyOrder.take(tabAt));
      expect(p.tabLock(LockedTab.sideTrips), isNull);
      expect(p.sideTripsHub()[ankiren].lock?.needed, ankirenAt - tabAt);
      await remember(p, journeyOrder.skip(tabAt).take(ankirenAt - tabAt));
      expect(p.sideTripsHub().openTrips, {ankiren});

      final later = DateTime.now().add(const Duration(days: 60));
      expect(p.trainer.wellRememberedCount(p.allStats, later), 0, reason: 'every card is due weeks later');
      expect(p.sideTripsHub(later).openTrips, {ankiren});
      expect(await stored(db, 'sideTripsUnlocked'), '["ankiren"]');
      expect(await stored(db, 'sideTripsTabUnlocked'), 'true');
      final again = await Progress.open(db);
      expect(again.sideTripsHub(later).openTrips, {ankiren});
      expect(again.tabLock(LockedTab.sideTrips), isNull);

      await again.resetProgress();
      expect(again.sideTripsHub().openTrips, isEmpty, reason: 'a progress reset locks it again');
      expect(again.tabLock(LockedTab.sideTrips), isNotNull);
      await db.close();
    });

    test('a player who opened 暗記練 at 25 under the old rule finds it locked below 50, rating kept', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.journey);
      await remember(p, journeyOrder.take(30));
      await db.into(db.keyValues).insertOnConflictUpdate(
          KeyValuesCompanion.insert(key: 'sideTripsUnlocked', value: '["ankiren.ranked"]'));
      final now = DateTime.now();
      await db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
          game: ankiren,
          startedAt: now,
          endedAt: now,
          day: p.dayAt(now).number,
          ranked: true,
          score: const Value(900),
          maxScore: const Value(1200),
          completed: true,
          rating: const Value(812),
          performance: const Value(900)));
      final again = await Progress.open(db);
      expect(again.tabLock(LockedTab.sideTrips), isNull);
      final entry = again.sideTripsHub()[ankiren];
      expect(entry.lock?.needed, ankirenAt - 30);
      expect([entry.rating, entry.games], [812, 1]);
      await db.close();
    });

    test('all-known mode: the tab and every side trip open', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      expect(p.tabLock(LockedTab.sideTrips), isNull);
      expect(p.sideTripsHub().openTrips, {...SideTrip.values});
      await db.close();
    });
  });
}
