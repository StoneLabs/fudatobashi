import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
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
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';

void main() {
  const ranked = (trip: SideTrip.ankiren, mode: SideTripMode.ranked);
  const free = (trip: SideTrip.ankiren, mode: SideTripMode.free);

  group('unlock rule', () {
    SideTripLock? lock(SideTripGate gate, int remembered, {bool allKnown = false, Set<SideTripGate> latched = const {}}) =>
        SideTripUnlocks.lockOf(gate, allKnown: allKnown, remembered: remembered, latched: latched);

    test('journey: 暗記練 opens at its count of well-remembered cards, its free play at a higher one', () {
      expect(SideTripUnlocks.opensAt(ranked), SideTripTuning.ankirenRemembered);
      expect(SideTripUnlocks.opensAt(free), SideTripTuning.ankirenFreeRemembered);
      expect(SideTripTuning.ankirenFreeRemembered, greaterThan(SideTripTuning.ankirenRemembered));

      final shut = lock(ranked, 18)!;
      expect([shut.opensAt, shut.remembered, shut.needed], [SideTripTuning.ankirenRemembered, 18, 7]);
      expect(lock(ranked, SideTripTuning.ankirenRemembered - 1)?.needed, 1);
      expect(lock(ranked, SideTripTuning.ankirenRemembered), isNull);
      expect(lock(free, SideTripTuning.ankirenRemembered)?.needed,
          SideTripTuning.ankirenFreeRemembered - SideTripTuning.ankirenRemembered);
      expect(lock(free, SideTripTuning.ankirenFreeRemembered), isNull);
    });

    test('a latched gate stays open whatever the count, and all-known mode opens every gate', () {
      expect(lock(ranked, 0, latched: {ranked}), isNull);
      expect(lock(free, 0, latched: {ranked}), isNotNull, reason: 'each gate latches on its own');
      for (final gate in SideTripUnlocks.gates) {
        expect(lock(gate, 0, allKnown: true), isNull);
      }
    });

    test('gates round-trip through their stored names; unknown names are dropped', () {
      expect(SideTripUnlocks.gates, hasLength(SideTrip.values.length * SideTripMode.values.length));
      for (final gate in SideTripUnlocks.gates) {
        expect(SideTripUnlocks.named(SideTripUnlocks.nameOf(gate)), gate);
      }
      expect(SideTripUnlocks.nameOf(free), 'ankiren.free');
      expect(SideTripUnlocks.named('karuta.ranked'), isNull);
    });
  });

  group('hub', () {
    test('a fresh journey: every trip in order, locked, unranked at 入門, nothing played', () {
      final hub = SideTripsHub.of(allKnown: false, remembered: 3);
      expect(hub.entries.map((e) => e.trip), SideTrip.values);
      final e = hub[SideTrip.ankiren];
      expect([e.open, e.freeOpen, e.ranked], [false, false, false]);
      expect(e.lock?.needed, SideTripTuning.ankirenRemembered - 3);
      expect(e.freeLock?.needed, SideTripTuning.ankirenFreeRemembered - 3);
      expect(e.band, Rating.bands.first);
      expect([e.rating, e.rankedLevel, e.maxLevel, e.games], [null, null, null, 0]);
      expect(hub.openGates, isEmpty);
    });

    test('opens ranked first, then free play, and reports the open gates for the latch', () {
      final half = SideTripsHub.of(allKnown: false, remembered: SideTripTuning.ankirenRemembered);
      expect([half[SideTrip.ankiren].open, half[SideTrip.ankiren].freeOpen], [true, false]);
      expect(half.openGates, {ranked});
      final full = SideTripsHub.of(allKnown: false, remembered: SideTripTuning.ankirenFreeRemembered);
      expect(full.openGates, {ranked, free});
      expect(SideTripsHub.of(allKnown: true, remembered: 0).openGates, {...SideTripUnlocks.gates});
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

    test('journey: 暗記練 latches open, survives a restart and a bad day, and a reset locks it again', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.journey);
      expect(p.sideTripsHub().openGates, isEmpty);

      await remember(p, journeyOrder.take(SideTripTuning.ankirenRemembered));
      expect(p.sideTripsHub().openGates, {ranked});

      final later = DateTime.now().add(const Duration(days: 60));
      expect(p.trainer.wellRememberedCount(p.allStats, later), 0, reason: 'every card is due weeks later');
      expect(p.sideTripsHub(later).openGates, {ranked});
      final stored = await (db.select(db.keyValues)..where((k) => k.key.equals('sideTripsUnlocked'))).get();
      expect(stored.single.value, '["ankiren.ranked"]');
      final again = await Progress.open(db);
      expect(again.sideTripsHub(later).openGates, {ranked});

      await again.resetProgress();
      expect(again.sideTripsHub().openGates, isEmpty, reason: 'a progress reset locks it again');
      await db.close();
    });

    test('all-known mode: every side trip open', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      expect(p.sideTripsHub().openGates, {...SideTripUnlocks.gates});
      await db.close();
    });
  });
}
