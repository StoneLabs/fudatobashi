import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/tab_locks.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

import 'test_ankiren.dart';
import 'test_teiichi.dart';

void main() {
  const ankiren = SideTrip.ankiren, teiichi = SideTrip.teiichi;
  const tabAt = SideTripTuning.tabRemembered, ankirenAt = SideTripTuning.ankirenSeen;
  const teiichiAt = SideTripTuning.teiichiSeen;

  group('unlock rule', () {
    SideTripLock? lock(int seen, {bool allKnown = false, Set<SideTrip> latched = const {}}) =>
        SideTripUnlocks.lockOf(ankiren, allKnown: allKnown, seen: seen, latched: latched);
    SideTripLock? tab(int remembered, {bool allKnown = false, bool latched = false}) =>
        SideTripUnlocks.tabLock(allKnown: allKnown, remembered: remembered, latched: latched);

    test('journey: the tab opens at 25 well-remembered cards, 暗記練 at 50 seen', () {
      expect([tabAt, ankirenAt], [25, 50]);
      expect(SideTripUnlocks.opensAt(ankiren), ankirenAt);

      final shut = tab(18)!;
      expect([shut.opensAt, shut.counted, shut.needed], [tabAt, 18, 7]);
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
      expect([for (var t = -6; t <= 6; t++) SideTripRing.frontAt(t)], [
        SideTripIsle.fort,
        SideTripIsle.ankiren,
        SideTripIsle.storehouse,
        SideTripIsle.hall,
        SideTripIsle.rocks,
        SideTripIsle.fort,
        SideTripIsle.ankiren,
        SideTripIsle.storehouse,
        SideTripIsle.hall,
        SideTripIsle.rocks,
        SideTripIsle.fort,
        SideTripIsle.ankiren,
        SideTripIsle.storehouse,
      ]);
      expect(SideTripIsle.ankiren.trip, SideTrip.ankiren);
      expect(SideTripIsle.storehouse.trip, SideTrip.teiichi);
      expect([for (final isle in SideTripRing.isles) isle.comingSoon], [false, false, true, true, true]);
    });

    test('each step moves every island on a slot: right to front, front to left, then round the back to the right',
        () {
      final n = SideTripRing.isles.length;
      Map<SideTripIsle, int> at(int turn) => {for (final i in SideTripRing.isles) i: SideTripRing.slotOf(i, turn)};
      expect(at(0), {
        SideTripIsle.ankiren: 0,
        SideTripIsle.storehouse: 1,
        SideTripIsle.hall: 2,
        SideTripIsle.rocks: 3,
        SideTripIsle.fort: 4,
      });
      for (var turn = -6; turn < 6; turn++) {
        for (final isle in SideTripRing.isles) {
          final slot = SideTripRing.slotOf(isle, turn);
          expect(SideTripRing.slotOf(isle, turn + 1), slot == 0 ? n - 1 : slot - 1, reason: '$isle at $turn');
        }
      }
      expect(SideTripRing.place(SideTripIsle.storehouse, 0.25), 0.75, reason: 'part of the way to the front');
      expect(SideTripRing.place(SideTripIsle.ankiren, 0.25), n - 0.25, reason: 'part of the way to the left');
      expect(SideTripRing.place(SideTripIsle.ankiren, -n - 0.5), 0.5, reason: 'a lap and a half step back');
    });
  });

  group('hub', () {
    test('a fresh journey: every trip in order, locked, unranked at 入門, nothing played', () {
      final hub = SideTripsHub.of(allKnown: false, seen: 3);
      expect(hub.entries.map((e) => e.trip), SideTrip.values);
      final e = hub[SideTrip.ankiren];
      expect([e.open, e.ranked], [false, false]);
      expect(e.lock?.needed, ankirenAt - 3);
      expect(e.band, Rating.bands.first);
      expect([e.rating, e.nextLevel, e.maxLevel, e.games], [null, 0, null, 0]);
      expect([e.rankedLock!.allKnown, e.rankedLock!.cleared, e.rankedOpen], [false, false, false]);
      expect(hub.openTrips, isEmpty);
    });

    test('opens 定位置 at 25 seen and 暗記練 at 50, and reports the open trips for the latch', () {
      expect(SideTripsHub.of(allKnown: false, seen: teiichiAt - 1).openTrips, isEmpty);
      expect(SideTripsHub.of(allKnown: false, seen: ankirenAt - 1).openTrips, {teiichi});
      expect(SideTripsHub.of(allKnown: false, seen: ankirenAt).openTrips, {ankiren, teiichi});
      expect(SideTripsHub.of(allKnown: false, seen: 0, latched: {ankiren}).openTrips, {ankiren});
      expect(SideTripsHub.of(allKnown: true, seen: 0).openTrips, {...SideTrip.values});
    });

    test('a standing carries through, its rating placed on the main ladder', () {
      final rating = Rating.bands[3].minRating + 1;
      final hub = SideTripsHub.of(
        allKnown: true,
        seen: 0,
        standings: {
          SideTrip.ankiren: SideTripStanding(rating: rating, ladder: const AnkirenLadder({0, 1, 2, 3, 4}), maxLevel: 9, games: 12),
        },
      );
      final e = hub[SideTrip.ankiren];
      expect(e.ranked, isTrue);
      expect(e.band, Rating.bands[3]);
      expect([e.rating, e.nextLevel, e.maxLevel, e.games, e.rankedOpen], [rating, 5, 9, 12, true]);
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

    test('History counts the main rounds and the recorded side-trip games together, ended early or not', () async {
      final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.setLearningMode(LearningMode.allKnown);
      expect(p.tabLock(LockedTab.history)?.left, 3);

      final teiichiGame = playTeiichi(const TeiichiSetup(cards: 12, rows: 2), endAfter: 3);
      await p.recordTeiichi(teiichiGame.placing, teiichiGame.game, startedAt: DateTime.now());
      expect(p.tabLock(LockedTab.history)?.left, 2);

      await p.recordAnkiren(playAnkiren(const AnkirenSetup.ranked()), startedAt: DateTime.now());
      expect(p.tabLock(LockedTab.history)?.left, 1, reason: 'ranked or free, both count');

      await p.recordAnkiren(playAnkiren(const AnkirenSetup.ranked(), endAfter: 2), startedAt: DateTime.now());
      expect(p.tabLock(LockedTab.history), isNull);
      expect(p.tabLock(LockedTab.stats)?.needs, TabUnlock.finishedRounds, reason: 'Stats keeps its own rules');
    });

    test('History: 1 main round and 2 side-trip games open it', () async {
      final p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.setLearningMode(LearningMode.allKnown);
      await remember(p, journeyOrder.take(1));
      expect(p.runs.length, 1);
      expect(p.tabLock(LockedTab.history)?.left, 2);
      await p.recordAnkiren(playAnkiren(const AnkirenSetup.ranked()), startedAt: DateTime.now());
      final played = playTeiichi(const TeiichiSetup(cards: 12, rows: 2));
      await p.recordTeiichi(played.placing, played.game, startedAt: DateTime.now());
      expect(p.tabLock(LockedTab.history), isNull);
    });

    test('guest and developer games are never recorded, so they do not count', () {
      expect(AnkirenPlayer.owner.recorded, isTrue);
      expect([AnkirenPlayer.guest.recorded, AnkirenPlayer.developer.recorded], [false, false]);
    });

    test('journey: the tab and 定位置 latch open at 25 and 暗記練 at 50; all survive a restart and a bad day, '
        'and a reset locks them again', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.journey);
      expect(p.tabLock(LockedTab.sideTrips)?.left, tabAt);
      expect(p.sideTripsHub().openTrips, isEmpty);

      await remember(p, journeyOrder.take(tabAt));
      expect(p.tabLock(LockedTab.sideTrips), isNull);
      expect(p.sideTripsHub()[ankiren].lock?.needed, ankirenAt - tabAt);
      expect(p.sideTripsHub().openTrips, {teiichi});
      await remember(p, journeyOrder.skip(tabAt).take(ankirenAt - tabAt));
      expect(p.sideTripsHub().openTrips, {ankiren, teiichi});

      final later = DateTime.now().add(const Duration(days: 60));
      expect(p.trainer.wellRememberedCount(p.allStats, later), 0, reason: 'every card is due weeks later');
      expect(p.sideTripsHub().openTrips, {ankiren, teiichi});
      expect(await stored(db, 'sideTripsUnlocked'), '["teiichi","ankiren"]');
      expect(await stored(db, 'sideTripsTabUnlocked'), 'true');
      final again = await Progress.open(db);
      expect(again.sideTripsHub().openTrips, {ankiren, teiichi});
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
