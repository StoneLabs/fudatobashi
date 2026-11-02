import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ankiren_field.dart';
import 'package:fudatobashi/domain/ankiren_game.dart';
import 'package:fudatobashi/domain/ankiren_level.dart';
import 'package:fudatobashi/domain/ankiren_review.dart';
import 'package:fudatobashi/domain/ankiren_score.dart';
import 'package:fudatobashi/domain/ankiren_tomofuda.dart';
import 'package:fudatobashi/domain/ankiren_xp.dart';
import 'package:fudatobashi/domain/karafuda.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/teiichi.dart';
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/domain/trainer.dart';

void main() {
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('counts', () {
    test('暗記練: 15 per 50 field cards, rounded up, from level 4', () {
      expect([for (var l = 0; l <= AnkirenLevels.top; l++) AnkirenLevels.karafudaOf(l)],
          [0, 0, 0, 0, 6, 8, 11, 13, 15, 15, 15]);
      expect([for (var l = 0; l <= AnkirenLevels.top; l++) AnkirenSetup.forLevel(l).karafuda],
          [0, 0, 0, 0, 6, 8, 11, 13, 15, 15, 15]);
      expect(const AnkirenSetup.ranked().karafuda, 15);
      expect(const AnkirenSetup.ranked().calls, 65);
      expect(AnkirenSetup.customKarafuda(3), 2);
      expect(const AnkirenSetup.custom(perSide: 5, memorise: Duration(minutes: 1), karafuda: 0).karafuda, 0);
    });

    test('a level needs known cards for its field and its からふだ', () {
      expect([for (var l = 0; l <= AnkirenLevels.top; l++) AnkirenLevels.needs(l)],
          [6, 8, 10, 14, 26, 34, 47, 55, 65, 65, 65]);
      expect(AnkirenLevels.maxLevelFor(25), 3);
      expect(AnkirenLevels.maxLevelFor(26), 4);
      expect(AnkirenLevels.maxLevelFor(64), 7);
      expect(AnkirenLevels.maxLevelFor(65), AnkirenLevels.top);
    });

    test('定位置: 10 per 25 cards, rounded up; the usual game needs 35 known', () {
      expect([for (final n in [8, 12, 16, 20, 25]) Karafuda.forTeiichi(n)], [4, 5, 7, 8, 10]);
      expect(TeiichiTuning.karafuda, Karafuda.forTeiichi(TeiichiTuning.cards));
      expect(TeiichiSetup.usual.calls, 35);
      expect(SideTripTuning.teiichiSeen, 35);
    });

    test('a custom game calls no more than its cards, nor than the known cards left over', () {
      expect(Karafuda.customMax(10, 100), 10);
      expect(Karafuda.customMax(10, 14), 4);
      expect(Karafuda.customMax(10, 8), 0);
      expect(const TeiichiSetup(cards: 20, rows: 3, karafuda: 8).fitted(25),
          const TeiichiSetup(cards: 20, rows: 3, karafuda: 5));
    });
  });

  group('picking', () {
    // Cards 1–40 known; 1–10 on the board; 11–20 are 友札 of board cards.
    final picker = KarafudaPicker((id) => id <= 10 ? [id + 10] : id <= 20 ? [id - 10] : const []);
    final board = [for (var id = 1; id <= 10; id++) id];
    final known = [for (var id = 1; id <= 40; id++) id];

    test('pools: known cards off the board, split by 友札', () {
      final pools = picker.pools(board, known);
      expect(pools.similar, [for (var id = 11; id <= 20; id++) id]);
      expect(pools.rest, [for (var id = 21; id <= 40; id++) id]);
      expect(pools.friendsOf[13], [3]);
    });

    test('each pick comes from the 友札 with the bias, statistically', () {
      final rng = math.Random(7);
      const games = 4000;
      var similar = 0;
      for (var i = 0; i < games; i++) {
        if (picker.pick(board, known, 1, rng).single <= 20) similar++;
      }
      expect(similar / games, closeTo(AnkirenTuning.karafudaTomofudaShare, 0.03));
    });

    test('the odds match the draws, and a pool run dry falls back to the other', () {
      final pools = picker.pools(board, known);
      for (final count in [1, 6, 15, 30]) {
        final odds = KarafudaPicker.odds(pools, count);
        final rng = math.Random(count);
        const games = 3000;
        final seen = <int, int>{};
        for (var i = 0; i < games; i++) {
          for (final id in KarafudaPicker.draw(pools, count, rng)) {
            seen[id] = (seen[id] ?? 0) + 1;
          }
        }
        double share(List<int> ids) => ids.fold(0, (n, id) => n + (seen[id] ?? 0)) / games / ids.length;
        expect(share(pools.similar), closeTo(odds.similar, 0.03), reason: '$count from the 友札');
        expect(share(pools.rest), closeTo(odds.rest, 0.03), reason: '$count from the rest');
      }
      final all = KarafudaPicker.odds(pools, 30);
      expect([all.similar, all.rest], [closeTo(1, 1e-9), closeTo(1, 1e-9)], reason: 'every card drawn');
    });

    test('only known cards, never the board, and fewer only when too few are left', () {
      final rng = math.Random(3);
      for (var i = 0; i < 200; i++) {
        final picks = picker.pick(board, known, 15, rng);
        expect(picks.length, 15);
        expect(picks.toSet().length, 15);
        expect(picks.every((id) => id > 10 && id <= 40), isTrue);
      }
      expect(picker.pick(board, [...board, 31, 32], 6, rng)..sort(), [31, 32]);
      expect(picker.pick(board, board, 6, rng), isEmpty);
      final noFriends = picker.pick(board, [...board, for (var id = 21; id <= 40; id++) id], 6, rng);
      expect(noFriends.length, 6, reason: 'no 友札 known: all from the rest');
    });

    test('the real 友札 come from the app’s 友札', () {
      final tomofuda = AnkirenTomofuda(poems);
      final pools = KarafudaPicker.ofPoems.pools(const [1, 2, 3], [for (final p in poems.all) p.id]);
      for (final id in pools.similar) {
        expect(pools.friendsOf[id]!.every((b) => tomofuda.of(id).contains(b)), isTrue);
      }
      for (final id in pools.rest) {
        expect(tomofuda.of(id).any((b) => b <= 3), isFalse);
      }
    });
  });

  group('order', () {
    test('mixed in at random, never last', () {
      final board = [for (var id = 1; id <= 20; id++) id];
      final karafuda = [for (var id = 50; id < 56; id++) id];
      final positions = <int>{};
      for (var seed = 0; seed < 300; seed++) {
        final order = Karafuda.order(board, karafuda, math.Random(seed));
        expect(order.toSet(), {...board, ...karafuda});
        expect(board.contains(order.last), isTrue);
        for (final (i, id) in order.indexed) {
          if (id >= 50) positions.add(i);
        }
      }
      expect(positions, containsAll([0, 10, 24]), reason: 'anywhere but last');
    });

    test('without からふだ, the board is shuffled as before', () {
      final board = [for (var id = 1; id <= 20; id++) id];
      expect(Karafuda.order(board, const [], math.Random(5)), [...board]..shuffle(math.Random(5)));
    });
  });

  group('the game', () {
    final dealer = AnkirenDealer(tomofuda: (_) => const [], kimarijiLength: (id) => 1 + id % 4);
    AnkirenGame game({bool strikes = false, AnkirenSetup? setup}) {
      final rng = math.Random(1);
      final field = dealer.deal([for (var id = 1; id <= 20; id++) id], 3, rng);
      return AnkirenGame(
        field: field,
        setup: setup ?? AnkirenSetup.forLevel(1),
        rng: rng,
        karafuda: const [90, 91],
        countsStrikes: strikes,
      )..startRecall();
    }

    const t = Duration(seconds: 10);
    const at = Duration(milliseconds: 300);

    /// Moves on to the first からふだ call, finding each card first.
    void toKarafuda(AnkirenGame g) {
      while (!g.isKarafuda(g.current!)) {
        g.promptRevealed(t);
        g.tap(g.current!, t + at);
      }
      g.promptRevealed(t);
    }

    test('the button answers a からふだ call as a first tap would', () {
      final g = game();
      toKarafuda(g);
      final asked = g.current!;
      expect(g.pressKarafuda(t + at), TapResult.right);
      final a = g.answers.last;
      expect([a.poemId, a.karafuda, a.side, a.firstTry, a.taps, a.tapped], [asked, true, null, true, [TapProximity.card], [Karafuda.button]]);
      expect(AnkirenScore.points(a), AnkirenScore.pointsOf(const [TapProximity.card], at.inMicroseconds));
    });

    test('a card on a からふだ call is wrong, as one on the other side; two show the button', () {
      final g = game(strikes: true);
      toKarafuda(g);
      final card = g.field.cards.firstWhere((c) => !g.isDone(c));
      expect(g.tap(card, t + at), TapResult.wrong);
      expect(g.revealed, isFalse);
      expect(g.tap(card, t + at * 2), TapResult.wrong);
      expect([g.revealed, g.strikes], [true, 2]);
      expect(g.pressKarafuda(t + at * 3), TapResult.right);
      final a = g.answers.last;
      expect([a.taps, a.tapped, a.wrongTaps], [[TapProximity.otherSide, TapProximity.otherSide], [card, card], 2]);
      expect(AnkirenScore.points(a), 0, reason: 'the worst first tap, and a second that earns nothing');
    });

    test('the button on a card is wrong, as a tap on the other side', () {
      final g = game(strikes: true);
      g.promptRevealed(t);
      while (g.isKarafuda(g.current!)) {
        g.pressKarafuda(t + at);
        g.promptRevealed(t);
      }
      final asked = g.current!;
      expect(g.pressKarafuda(t + at), TapResult.wrong);
      expect(g.strikes, 1);
      expect(g.tap(asked, t + at * 2), TapResult.right);
      expect([g.answers.last.taps, g.answers.last.tapped], [[TapProximity.otherSide, TapProximity.card], [Karafuda.button, asked]]);
      expect(g.karafudaTally.wrongPresses, 1);
    });

    test('"don\'t know" on a からふだ is a strike; three strikes fail the level', () {
      final g = game(strikes: true);
      toKarafuda(g);
      expect(g.giveUp(), isNotNull);
      expect([g.answers.last.gaveUp, g.answers.last.karafuda, g.strikes], [true, true, 1]);
      g.promptRevealed(t);
      g.pressKarafuda(t + at);
      g.end();
      expect(g.cleared, isFalse, reason: 'ended early');
    });

    test('cards and からふだ are counted apart', () {
      final g = game();
      g.promptRevealed(t);
      while (g.phase == AnkirenPhase.recall) {
        g.isKarafuda(g.current!) ? g.pressKarafuda(t + at) : g.tap(g.current!, t + at);
        g.promptRevealed(t);
      }
      expect([g.firstTries, g.cardAnswers.length, g.karafudaAnswers.length], [6, 6, 2]);
      final tally = g.karafudaTally;
      expect([tally.called, tally.right, tally.late, tally.missed, tally.touched, tally.wrongPresses], [2, 2, 0, 0, 0, 0]);
      expect(g.answers.last.karafuda, isFalse, reason: 'a game ends on a card');
    });

    test('a ranked score counts the からふだ, out of every call', () {
      final rng = math.Random(2);
      final field = AnkirenDealer.ofPoems().deal([for (final p in poems.all) p.id], 25, rng);
      final picks = KarafudaPicker.ofPoems.pick(field.cards, [for (final p in poems.all) p.id], 15, rng);
      final g = AnkirenGame(field: field, setup: const AnkirenSetup.ranked(), rng: rng, karafuda: picks)..startRecall();
      g.promptRevealed(t);
      while (g.phase == AnkirenPhase.recall) {
        g.isKarafuda(g.current!) ? g.pressKarafuda(t + at) : g.tap(g.current!, t + at);
        g.promptRevealed(t);
      }
      final score = g.score!;
      final perCall = AnkirenScore.pointsOf(const [TapProximity.card], at.inMicroseconds);
      expect(score.recall, 65 * perCall);
      expect(score.karafuda, 15 * perCall);
      expect(score.max, AnkirenScore.totalOf(AnkirenScore.maxFor(65), AnkirenScore.maxFor(65), 1));
      expect(AnkirenScore.firstTryTotal(const AnkirenSetup.ranked(), responseMs: 300), score.recall);
    });
  });

  group('xp', () {
    AnkirenXpAnswer call(List<TapProximity> taps, {bool karafuda = false, int ms = 300}) => (
          wrongTaps: taps.length - 1,
          responseUs: taps.lastOrNull == TapProximity.card ? ms * 1000 : null,
          taps: taps,
          firstTapUs: taps.isEmpty ? null : ms * 1000,
          karafuda: karafuda,
        );
    XpAward award(List<AnkirenXpAnswer> answers) => AnkirenXp().score(AnkirenXpRun(
          runId: 1,
          startedAt: DateTime(2026),
          ranked: false,
          completed: true,
          level: 4,
          score: null,
          answers: answers,
        ));

    test('a からふだ earns as a card does, on a line of its own', () {
      const card = [TapProximity.card];
      final cards = award([call(card), call(card)]);
      final mixed = award([call(card), call(card, karafuda: true)]);
      int xp(XpAward a, XpSource source) => a.parts.where((p) => p.source == source).fold(0, (n, p) => n + p.xp);
      expect(mixed.total, cards.total);
      expect(xp(mixed, XpSource.karafuda), xp(cards, XpSource.firstTap) ~/ 2 + xp(cards, XpSource.speed) ~/ 2);
      expect(mixed.parts.firstWhere((p) => p.source == XpSource.karafuda).count, 1);
      final wrong = award([call(card), call(const [TapProximity.otherSide], karafuda: true)]);
      expect(xp(wrong, XpSource.karafuda), AnkirenXpTuning.perMiss, reason: 'tried, as a missed card');
      expect(award([call(card)]).parts.any((p) => p.source == XpSource.karafuda), isFalse);
    });
  });

  group('settings', () {
    test('custom からふだ are kept, following the formula until set', () {
      const fresh = AnkirenSettings(customPerSide: 9);
      expect(fresh.freeLevel, isNotNull);
      final custom = fresh.withFreeSetup(const AnkirenSetup.custom(perSide: 9, memorise: Duration(minutes: 2), karafuda: 3));
      expect(AnkirenSettings.fromJson(custom.toJson()).freeSetup.karafuda, 3);
      final none = fresh.withFreeSetup(const AnkirenSetup.custom(perSide: 9, memorise: Duration(minutes: 2)));
      expect(AnkirenSettings.fromJson(none.toJson()).freeSetup.karafuda, 0, reason: '0 turns them off');
      final old = AnkirenSettings.fromJson({...custom.toJson()}..remove('customKarafuda'));
      expect(old.freeSetup.karafuda, AnkirenSetup.customKarafuda(9), reason: 'unset, it follows the formula');
      const app = AppSettings(teiichi: TeiichiSettings(customCards: 12, customKarafuda: 2));
      expect(AppSettings.fromJson(app.toJson()).teiichi.customKarafuda, 2);
      expect(AppSettings.fromJson(const AppSettings().toJson()).teiichi.customKarafuda, isNull);
    });
  });

  group('storage', () {
    test('a game keeps its からふだ and the presses, and reads back apart from its cards', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      final rng = math.Random(4);
      final setup = AnkirenSetup.forLevel(4);
      final known = [for (final pm in poems.all) pm.id];
      final field = AnkirenDealer.ofPoems().deal(known, setup.perSide, rng);
      final picks = KarafudaPicker.ofPoems.pick(field.cards, known, setup.karafuda, rng);
      final g = AnkirenGame(field: field, setup: setup, rng: rng, karafuda: picks, countsStrikes: true)..startRecall();
      const t = Duration(seconds: 10);
      var first = true;
      g.promptRevealed(t);
      while (g.phase == AnkirenPhase.recall) {
        final asked = g.current!;
        if (g.isKarafuda(asked)) {
          if (first) g.tap(field.cards.firstWhere((c) => !g.isDone(c)), t + const Duration(milliseconds: 200));
          first = false;
          g.pressKarafuda(t + const Duration(milliseconds: 400));
        } else {
          g.tap(asked, t + const Duration(milliseconds: 400));
        }
        g.promptRevealed(t);
      }
      await p.recordAnkiren(g, startedAt: DateTime(2026, 10, 31, 9));

      final again = await Progress.open(db);
      final trips = again.sideTrips;
      final run = trips.runs.single;
      expect((jsonDecode(run.meta) as Map)[AnkirenMeta.karafudaKey], picks);
      expect(trips.cardsIn(run), 20);
      expect(trips.poemsOf(run).toSet(), field.cards.toSet());
      expect(trips.missesIn(run), 0);
      expect(trips.strikesIn(run), 1);
      expect([for (final a in trips.answersOf(run)) if (a.karafuda) a], hasLength(6));
      final record = trips.recordOf(run);
      expect([record.cards.length, record.karafuda.length, record.calls.length], [20, 6, 26]);
      expect(record.karafuda.map((c) => c.poemId).toSet(), picks.toSet());
      expect(record.karafuda.expand((c) => c.tapped).where((id) => id == Karafuda.button), hasLength(6));
      final tally = record.karafudaTally;
      expect([tally.called, tally.right, tally.late, tally.touched], [6, 5, 1, 1]);
      expect(record.calls.last.karafuda, isFalse);
      expect(again.sideTripsHub()[SideTrip.ankiren].ladder.isCleared(4), isTrue);
      await db.close();
    });

    test('a game without からふだ keeps its meta as before', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await Progress.open(db);
      await p.setLearningMode(LearningMode.allKnown);
      final rng = math.Random(4);
      final field = AnkirenDealer.ofPoems().deal([for (final pm in poems.all) pm.id], 3, rng);
      final g = AnkirenGame(field: field, setup: AnkirenSetup.forLevel(1), rng: rng)..startRecall();
      g.end();
      await p.recordAnkiren(g, startedAt: DateTime(2026, 10, 31, 9));
      final run = p.sideTrips.runs.single;
      expect((jsonDecode(run.meta) as Map).containsKey(AnkirenMeta.karafudaKey), isFalse);
      expect(p.sideTrips.recordOf(run).karafudaTally.none, isTrue);
      await db.close();
    });
  });
}