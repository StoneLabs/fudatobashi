import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/side_trips.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/migrations/notices.dart';
import 'package:fudatobashi/migrations/v3_to_v4.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/history/history_filter.dart';
import 'package:fudatobashi/ui/shell/migration_notice.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

/// The 暗記練 rework's upgrade step (schema 3 → 4) and the notice it leaves.
void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() async {
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  AppDatabase memory() => AppDatabase(NativeDatabase.memory());

  Future<int> add(AppDatabase db, {required bool ranked, int? level, double? rating, bool completed = true}) =>
      db.into(db.sideTripRuns).insert(SideTripRunsCompanion.insert(
            game: SideTrip.ankiren,
            startedAt: DateTime(2026, 10, 12, 9),
            endedAt: DateTime(2026, 10, 12, 9, 5),
            day: 20261012,
            ranked: ranked,
            level: Value(level),
            score: Value(level == null && !ranked ? null : 300),
            maxScore: Value(level == null && !ranked ? null : 400),
            completed: completed,
            rating: Value(rating),
            performance: Value(rating),
          ));

  Future<void> upgrade(AppDatabase db) => db.transaction(() => v3ToV4(db.createMigrator()));

  Future<List<(bool, int?, double?, double?, int?)>> games(AppDatabase db) async => [
        for (final r in await (db.select(db.sideTripRuns)..orderBy([(r) => OrderingTerm.asc(r.id)])).get())
          (r.ranked, r.level, r.rating, r.performance, r.score),
      ];

  Future<String?> notices(AppDatabase db) async =>
      (await (db.select(db.keyValues)..where((k) => k.key.equals(noticesKey))).getSingleOrNull())?.value;

  group('the upgrade step', () {
    test('a ranked game with a level becomes a free game at it, and only ranked games keep their points', () async {
      final db = memory();
      await add(db, ranked: true, level: 3, rating: 800);
      await add(db, ranked: true, rating: 900);
      await add(db, ranked: false, level: 2);
      await add(db, ranked: false);
      await upgrade(db);
      expect(await games(db), [
        (false, 3, null, null, null),
        (true, null, 900, 900, 300),
        (false, 2, null, null, null),
        (false, null, null, null, null),
      ]);
      expect([for (final r in await db.select(db.sideTripRuns).get()) r.maxScore], [null, 400, null, null],
          reason: 'only ranked games keep points');
      await db.close();
    });

    test('running it again changes nothing, and queues the notice once', () async {
      final db = memory();
      await add(db, ranked: true, level: 3, rating: 800);
      await upgrade(db);
      final once = await games(db);
      await upgrade(db);
      expect(await games(db), once);
      expect(await notices(db), '["$ankirenReworkNotice"]');
      await db.close();
    });

    test('a player with no 暗記練 game is not told', () async {
      final db = memory();
      await upgrade(db);
      expect(await notices(db), isNull);
      await db.close();
    });

    test('any game, even a free one, earns the notice', () async {
      final db = memory();
      await add(db, ranked: false, level: 0);
      await upgrade(db);
      expect(await notices(db), '["$ankirenReworkNotice"]');
      await db.close();
    });

    test('after it, the rank is Unranked with placement at 0 everywhere, and the old games are free games', () async {
      final db = memory();
      for (final rating in [900.0, 1100.0, 1300.0, 1500.0]) {
        await add(db, ranked: true, level: 5, rating: rating);
      }
      await upgrade(db);
      final p = await Progress.open(db);
      final trips = p.sideTrips;
      expect(trips.ratingOf(SideTrip.ankiren), isNull);
      expect(trips.rankedGames(SideTrip.ankiren), 0);
      final entry = p.sideTripsHub()[SideTrip.ankiren];
      expect([entry.ranked, entry.rating], [false, null]);
      expect(trips.ladderOf(SideTrip.ankiren).cleared, isEmpty, reason: 'everyone starts at Lv 0');
      for (final run in trips.runsOf(SideTrip.ankiren)) {
        expect(AnkirenKind.of(run), AnkirenKind.free);
        expect(trips.recordOf(run).scored, isFalse);
      }
      expect(p.pendingNotice, ankirenReworkNotice);
      await db.close();
    });
  });

  group('the notice', () {
    test('shows once, one after another, and stays gone after it is dismissed', () async {
      final db = memory();
      await db.into(db.keyValues).insert(KeyValuesCompanion.insert(key: noticesKey, value: '["a","b"]'));
      final p = await Progress.open(db);
      expect(p.pendingNotice, 'a');
      await p.dismissNotice('a');
      expect(p.pendingNotice, 'b');
      expect(await notices(db), '["b"]');
      await p.dismissNotice('b');
      expect(p.pendingNotice, isNull);
      expect(await notices(db), isNull);
      expect((await Progress.open(db)).pendingNotice, isNull);
      await db.close();
    });

    test('a fresh install has none', () async {
      final db = memory();
      expect((await Progress.open(db)).pendingNotice, isNull);
      expect(await notices(db), isNull);
      await db.close();
    });

    for (final ja in [false, true]) {
      final lang = ja ? 'ja' : 'en';
      for (final (phone, fontScale) in [(usersPhone, 1.0), (narrowTallPhone, 1.3), (shortNarrowPhone, 1.3)]) {
        testWidgets('Home shows it over everything until OK, then no more ($lang, ${phone.name} dp, font scale $fontScale)',
            (tester) async {
          final s = S(lang);
          late Progress p;
          await tester.runAsync(() async {
            final db = memory();
            await db.into(db.keyValues).insert(KeyValuesCompanion.insert(key: noticesKey, value: '["$ankirenReworkNotice"]'));
            p = await Progress.open(db);
            p.tabsAlwaysOpen = true;
            await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
            await p.setLearningMode(LearningMode.allKnown);
          });
          useScreen(tester, phone, fontScale: fontScale);
          await tester.pumpWidget(RepaintBoundary(key: const ValueKey('screen'), child: FudatobashiApp(progress: p)));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          expect(find.byType(MigrationNotice), findsOneWidget);
          expect(find.text(s.t('noticeAnkirenReworkTitle')), findsOneWidget);
          expect(find.textContaining(s.t('noticeAnkirenReworkBody').replaceAll('\u200b', ''), findRichText: true), findsOneWidget);
          await captureScreen(tester, 'migration_notice', lang: lang);

          await tester.tap(find.text(s.noticeOk));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.byType(MigrationNotice), findsNothing);
          expect(p.pendingNotice, isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    testWidgets('a fresh install shows no notice', (tester) async {
      late Progress p;
      await tester.runAsync(() async {
        p = await Progress.open(memory());
        p.tabsAlwaysOpen = true;
        await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true));
        await p.setLearningMode(LearningMode.allKnown);
      });
      useScreen(tester, usersPhone);
      await tester.pumpWidget(FudatobashiApp(progress: p));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(MigrationNotice), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
