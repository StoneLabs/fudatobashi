import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/play_session.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/deck_selection.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/settings.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  /// Every card in the journey's learning order.
  final journeyOrder = [for (final g in initialGroups) ...fudaSets['initial:$g'].poemIds];

  /// Plays [cards] once each, correct in 700 ms, recorded under [config].
  Future<SessionReport> play(Progress p, List<CardRef> cards, PlayConfig config) {
    final session = PlaySession(cards);
    var t = const Duration(seconds: 100);
    while (!session.finished) {
      session.revealed(t);
      t += const Duration(milliseconds: 700);
      session.commit(responseTs: t, commitTs: t + const Duration(milliseconds: 80), outcome: Outcome.known);
      t += const Duration(milliseconds: 100);
    }
    return p.recordRun(session, config, DateTime.now());
  }

  /// Unlocks [ids] (journey) and trains each until it is well remembered.
  Future<void> remember(Progress p, List<int> ids) async {
    for (final id in ids) {
      p.trainer.items[ItemKey(id, false)]!.unlocked = true;
    }
    final cards = [
      for (var i = 0; i < StatsTuning.solidMinTimed; i++) ...ids.map(CardRef.new),
    ];
    await play(p, cards, const PlayConfig(mode: PlayMode.training));
  }

  Future<Progress> openIn(AppDatabase db, LearningMode mode) async {
    final p = await Progress.open(db);
    await p.setLearningMode(mode);
    return p;
  }

  group('free practice lock', () {
    test('journey: locked until enough cards are well remembered at once, then open for good', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await openIn(db, LearningMode.journey);
      expect(p.freePractice().open, isFalse);
      expect(p.freePractice().needed, FreePracticeTuning.unlockRemembered);

      final ids = journeyOrder.take(FreePracticeTuning.unlockRemembered).toList();
      await remember(p, ids.take(ids.length - 1).toList());
      expect(p.freePractice().open, isFalse);
      expect(p.freePractice().needed, 1);

      await remember(p, [ids.last]);
      expect(p.freePractice().open, isTrue);

      // Weeks later every card is due, so none is well remembered; the latch
      // keeps it open, and it is stored, so a restart keeps it too.
      final later = DateTime.now().add(const Duration(days: 60));
      expect(p.trainer.wellRememberedCount(p.allStats, later), 0);
      expect(p.freePractice(later).open, isTrue);
      final stored = await (db.select(db.keyValues)..where((k) => k.key.equals('freePracticeUnlocked'))).get();
      expect(stored.single.value, 'true');
      final again = await Progress.open(db);
      expect(again.freePractice(later).open, isTrue);

      await again.resetProgress();
      expect(again.freePractice().open, isFalse, reason: 'a progress reset locks it again');
      await db.close();
    });

    test('all-known mode: always open', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await openIn(db, LearningMode.allKnown);
      expect(p.freePractice().open, isTrue);
      expect(p.freePractice().needed, 0);
      await db.close();
    });
  });

  group('deck selection', () {
    final island0 = fudaSets['initial:${initialGroups[0]}'].poemIds;
    final island1 = fudaSets['initial:${initialGroups[1]}'].poemIds;
    // One card of island 1 is not known yet.
    final known = {...island0, ...island1.skip(1)};
    final unknown = island1.first;

    test('starts with every known card, which is the default deck', () {
      final deck = DeckSelection(known: known);
      expect(deck.selected, known);
      expect(deck.isDefault, isTrue);
      expect(deck.customIds, isNull);
      expect(deck.coverageOf(island1), Coverage.all, reason: 'unknown cards do not count against an island');
    });

    test('islands, 友札 sets and single cards edit one set of cards, so they always agree', () {
      final deck = DeckSelection(known: known);
      deck.toggleGroup(island0);
      expect(deck.coverageOf(island0), Coverage.none);
      expect(island0.any(deck.contains), isFalse, reason: 'the card picker sees the island gone');
      expect(deck.customIds, [...island1.skip(1)]..sort());

      // A 友札 set with a card on island 0 and one elsewhere.
      final set = fudaSets
          .ofKind(FudaSetKind.confusable)
          .firstWhere((s) => s.poemIds.any(island0.contains) && s.poemIds.any((id) => !island0.contains(id)));
      final knownDeck = DeckSelection(known: {...known, ...set.poemIds});
      knownDeck.toggleGroup(island0);
      expect(knownDeck.coverageOf(set.poemIds), Coverage.some);
      knownDeck.toggleGroup(set.poemIds);
      expect(knownDeck.coverageOf(set.poemIds), Coverage.all);
      expect(knownDeck.coverageOf(island0), Coverage.some, reason: 'the set brought one island-0 card back');

      final one = island0.first;
      deck.toggleCard(one);
      expect(deck.coverageOf(island0), Coverage.some);
      for (final id in island0.skip(1)) {
        deck.toggleCard(id);
      }
      expect(deck.coverageOf(island0), Coverage.all);
      expect(deck.isDefault, isTrue, reason: 'every known card again is the default deck');
      expect(deck.customIds, isNull);
    });

    test('unknown cards can never be picked', () {
      final deck = DeckSelection(known: known, picked: [unknown, island0.first]);
      expect(deck.selected, {island0.first}, reason: 'a stored card no longer known is dropped');
      deck.toggleCard(unknown);
      expect(deck.contains(unknown), isFalse);
      deck.clear();
      deck.toggleGroup(island1);
      expect(deck.selected, {...island1.skip(1)});
      deck.selectAll();
      expect(deck.selected, known);
    });
  });

  group('what counts for SRS', () {
    test('free practice counts only at its default: every known card, no 隠し字', () {
      expect(const FreePracticeSetup().config.countsForSrs, isTrue);
      expect(const FreePracticeSetup().customized, isFalse);
      expect(const FreePracticeSetup(maskLevel: 2).config.countsForSrs, isFalse);
      expect(const FreePracticeSetup(cardIds: [1, 2]).config.countsForSrs, isFalse);
      expect(const PlayConfig(mode: PlayMode.training).countsForSrs, isTrue);
      expect(const PlayConfig(mode: PlayMode.free).countsForSrs, isFalse, reason: 'all 100, not the known deck');
      expect(const PlayConfig(mode: PlayMode.free, setIds: ['initial:むすめふさほせ']).countsForSrs, isFalse);
      expect(const PlayConfig(mode: PlayMode.nigate).countsForSrs, isFalse);
      expect(const PlayConfig(mode: PlayMode.guest, setIds: [PlayConfig.knownDeckId]).countsForSrs, isFalse);
    });

    test('a hand-picked deck of every known card is the default again', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await openIn(db, LearningMode.allKnown);
      final all = [for (var id = 1; id <= 100; id++) id];
      expect(p.freePracticeRun(FreePracticeSetup(cardIds: all)).countsForSrs, isTrue);
      expect(p.freePracticeRun(FreePracticeSetup(cardIds: all.skip(1).toList())).countsForSrs, isFalse);
      expect(p.freePracticeRun(FreePracticeSetup(cardIds: all, maskLevel: 1)).countsForSrs, isFalse);
      await db.close();
    });

    test('an uncustomised free run feeds FSRS and the rating; a customised one only History', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await openIn(db, LearningMode.allKnown);
      final counted = const FreePracticeSetup().config;
      final deck = p.freeDeck(counted);
      expect(deck.length, 100);
      final a = deck[0], b = deck[1], c = deck[2];
      ItemKey key(CardRef r) => ItemKey(r.poemId, r.inverted);

      final report = await play(p, [a], counted);
      expect(report.sessionId, isNotNull);
      expect(p.trainer.items[key(a)]!.reviewed, isTrue);
      expect(p.stats(key(a)).seen, isTrue);
      expect(p.rating, isNotNull);
      expect(report.ratingAfter, isNot(report.ratingBefore));

      final rating = p.rating;
      final picked = FreePracticeSetup(cardIds: [b.poemId]).config;
      await play(p, [b], picked);
      final masked = const FreePracticeSetup(maskLevel: 3).config;
      await play(p, [c], masked);
      for (final r in [b, c]) {
        expect(p.trainer.items[key(r)]!.reviewed, isFalse);
        expect(p.stats(key(r)).seen, isFalse);
        expect(p.displayStats(key(r)).seen, isTrue, reason: 'still in History and the card charts');
      }
      expect(p.rating, rating);

      // The same split after a restart, from what the sessions stored.
      final again = await Progress.open(db);
      expect(again.stats(key(a)).seen, isTrue);
      expect(again.stats(key(b)).seen, isFalse);
      expect(again.stats(key(c)).seen, isFalse);
      expect(again.configOf(again.sessions[1]).cardIds, [b.poemId]);
      await db.close();
    });

    test('journey: the default deck is the cards met so far, each way up only once its reverse is unlocked', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await openIn(db, LearningMode.journey);
      final ids = journeyOrder.take(8).toList();
      await remember(p, ids.take(6).toList());
      p.trainer.items[ItemKey(ids[6], false)]!.unlocked = true; // unlocked, not met yet
      expect(p.knownCards, {...ids.take(6)});
      const run = FreePracticeSetup();
      expect({for (final r in p.freeDeck(run.config)) r.poemId}, {...ids.take(6)});

      final rng = math.Random(1);
      List<bool> turns() => [for (var i = 0; i < 20; i++) ...p.freeDeck(run.config, rng: rng).map((r) => r.inverted)];
      for (final id in ids) {
        p.trainer.items[ItemKey(id, true)]!.unlocked = false;
      }
      expect(turns().any((inverted) => inverted), isFalse, reason: 'no reverse item is unlocked');
      for (final id in ids) {
        p.trainer.items[ItemKey(id, true)]!.unlocked = true;
      }
      expect(turns().toSet(), {true, false}, reason: 'both ways up once the reverse items are unlocked');
      final guest = p.freeDeck(const PlayConfig(mode: PlayMode.guest));
      expect(guest.length, 100, reason: 'a guest always gets all 100');
      await db.close();
    });
  });

  test('the old free-play setting (sets, orientation) migrates to the counted default', () {
    final old = AppSettings.fromJson({
      'freePlay': {'mode': 'free', 'setIds': ['initial:うつしもゆ'], 'orientation': 'upright', 'maskLevel': 3},
    });
    expect(old.freePractice, const FreePracticeSetup());
    expect(old.freePractice.customized, isFalse);

    const custom = FreePracticeSetup(cardIds: [3, 5, 8], maskLevel: 2);
    final back = AppSettings.fromJson(const AppSettings(freePractice: custom).toJson());
    expect(back.freePractice, custom);
  });

  test('a 修行 round is 50 cards in all-known mode, 30 in journey, unless the debug page overrides it', () {
    expect(const TrainerConfig(learningMode: LearningMode.allKnown).sessionLength, TrainingTuning.allKnownSessionLength);
    expect(const TrainerConfig().sessionLength, TrainingTuning.defaultSessionLength);
    expect(const TrainerConfig(learningMode: LearningMode.allKnown, sessionLengthOverride: 20).sessionLength, 20);
    final stored = TrainerConfig.fromJson({'learningMode': 'allKnown', 'sessionLength': 30});
    expect(stored.sessionLength, TrainingTuning.allKnownSessionLength, reason: 'the old always-stored 30 is ignored');
    expect(TrainerConfig.fromJson(stored.copyWith(sessionLengthOverride: 40).toJson()).sessionLength, 40);
  });
}
