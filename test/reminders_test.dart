// The daily training reminders: when they go off (reminderTimes), how the
// service keeps the platform's schedule in step with the player's settings
// and mode, and when Results offers them.
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/reminder_schedule.dart';
import 'package:fudatobashi/domain/today_set.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/reminders.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'test_l10n.dart';
import 'test_reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  loadTestL10n();
  tz_data.initializeTimeZones();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('reminderTimes', () {
    final tokyo = tz.getLocation('Asia/Tokyo');

    List<tz.TZDateTime> times(
      tz.TZDateTime now, {
      LearningMode mode = LearningMode.journey,
      bool enabled = true,
      bool todayDone = false,
      int days = ReminderTuning.days,
    }) =>
        reminderTimes(
          now: now,
          mode: mode,
          enabled: enabled,
          todayDone: todayDone,
          // Days start at 4:00, so this one ends at 4:00 tomorrow.
          dayEnd: tz.TZDateTime(now.location, now.year, now.month, now.day + 1, 4),
          days: days,
        );

    // One at noon on each day from [first]'s.
    void expectNoons(List<tz.TZDateTime> got, tz.TZDateTime first) {
      expect(got, [
        for (var i = 0; i < ReminderTuning.days; i++)
          tz.TZDateTime(first.location, first.year, first.month, first.day + i, ReminderTuning.hour, ReminderTuning.minute),
      ]);
    }

    test('the morning of a day not trained yet: today at noon, then one a day', () {
      final now = tz.TZDateTime(tokyo, 2026, 10, 20, 9);
      expectNoons(times(now), tz.TZDateTime(tokyo, 2026, 10, 20, 12));
    });

    test('past noon: from tomorrow', () {
      final now = tz.TZDateTime(tokyo, 2026, 10, 20, 15);
      expectNoons(times(now), tz.TZDateTime(tokyo, 2026, 10, 21, 12));
    });

    test('noon itself is past', () {
      final now = tz.TZDateTime(tokyo, 2026, 10, 20, 12);
      expect(times(now).first, tz.TZDateTime(tokyo, 2026, 10, 21, 12));
    });

    test("today's set done before noon: none today, from tomorrow", () {
      final now = tz.TZDateTime(tokyo, 2026, 10, 20, 8);
      expectNoons(times(now, todayDone: true), tz.TZDateTime(tokyo, 2026, 10, 21, 12));
    });

    test("today's set done after noon: from tomorrow", () {
      final now = tz.TZDateTime(tokyo, 2026, 10, 20, 21);
      expectNoons(times(now, todayDone: true), tz.TZDateTime(tokyo, 2026, 10, 21, 12));
    });

    test('done after midnight, before the day starts: that day counts, the new day still gets its reminder', () {
      // 2:00 on the 21st still belongs to the 20th's practice day, which
      // ends at 4:00; noon on the 21st is a new day.
      final now = tz.TZDateTime(tokyo, 2026, 10, 21, 2);
      final got = reminderTimes(
        now: now,
        mode: LearningMode.journey,
        enabled: true,
        todayDone: true,
        dayEnd: tz.TZDateTime(tokyo, 2026, 10, 21, 4),
      );
      expect(got.first, tz.TZDateTime(tokyo, 2026, 10, 21, 12));
    });

    test('all-known mode: none', () {
      expect(times(tz.TZDateTime(tokyo, 2026, 10, 20, 9), mode: LearningMode.allKnown), isEmpty);
    });

    test('turned off: none', () {
      expect(times(tz.TZDateTime(tokyo, 2026, 10, 20, 9), enabled: false), isEmpty);
    });

    test('runs across a month end', () {
      final got = times(tz.TZDateTime(tokyo, 2026, 10, 30, 9), days: 4);
      expect([for (final t in got) '${t.month}/${t.day}'], ['10/30', '10/31', '11/1', '11/2']);
    });

    test('stays at local noon when the clocks go back (London, 25 October 2026)', () {
      final london = tz.getLocation('Europe/London');
      final got = times(tz.TZDateTime(london, 2026, 10, 24, 9), days: 3);
      expect([for (final t in got) t.hour], [12, 12, 12]);
      expect([for (final t in got) t.toUtc().hour], [11, 12, 12], reason: 'summer time, then winter time');
      expect(got[1].difference(got[0]), const Duration(hours: 25));
    });

    test('stays at local noon when the clocks go forward (New York, 14 March 2027)', () {
      final newYork = tz.getLocation('America/New_York');
      final got = times(tz.TZDateTime(newYork, 2027, 3, 13, 9), days: 2);
      expect([for (final t in got) t.hour], [12, 12]);
      expect(got[1].difference(got[0]), const Duration(hours: 23));
    });
  });

  group('the service', () {
    final tokyo = tz.getLocation('Asia/Tokyo');
    late FakeReminderPlatform platform;
    late Reminders service;
    late Progress progress;
    // A morning, so today's noon is still ahead.
    final morning = DateTime(2026, 10, 20, 9);

    setUp(() async {
      platform = FakeReminderPlatform(tokyo);
      service = Reminders(platform: platform, now: () => morning);
      progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await progress.updateSettings(progress.settings.copyWith(language: 'en', languagePicked: true));
      await progress.setLearningMode(LearningMode.journey);
      service.attach(progress);
      await service.idle;
    });

    tearDown(() async {
      service.detach(progress);
      await progress.db.close();
    });

    test('off by default: nothing is scheduled', () {
      expect(progress.settings.reminders, isFalse);
      expect(platform.scheduled.last, isEmpty);
    });

    test('turned on with permission: the next days at noon, in the player\'s language', () async {
      expect(await service.turnOn(progress), isTrue);
      await service.idle;
      expect(platform.asked, 1);
      expect(progress.settings.reminders, isTrue);
      final times = platform.scheduled.last;
      expect(times, hasLength(ReminderTuning.days));
      expect(times.every((t) => t.hour == ReminderTuning.hour && t.location == tokyo), isTrue);
      expect(platform.texts.last.body, isNotEmpty);
      await progress.updateSettings(progress.settings.copyWith(language: 'ja'));
      await service.idle;
      expect(platform.texts.last.body, isNot(platform.texts[platform.texts.length - 2].body),
          reason: 'a new language reschedules them in it');
    });

    test('turned on without permission: they stay off', () async {
      platform.granted = false;
      expect(await service.turnOn(progress), isFalse);
      await service.idle;
      expect(progress.settings.reminders, isFalse);
      expect(platform.scheduled.every((t) => t.isEmpty), isTrue);
    });

    test('turned off: every reminder is cancelled', () async {
      await service.turnOn(progress);
      await service.idle;
      await service.turnOff(progress);
      await service.idle;
      expect(progress.settings.reminders, isFalse);
      expect(platform.scheduled.last, isEmpty);
    });

    test('all-known mode cancels them, and back in journey mode they return', () async {
      await service.turnOn(progress);
      await service.idle;
      await progress.switchToAllKnown();
      await service.idle;
      expect(platform.scheduled.last, isEmpty);
      expect(progress.settings.reminders, isTrue, reason: 'the setting itself is kept');
      await progress.setLearningMode(LearningMode.journey);
      await service.idle;
      expect(platform.scheduled.last, hasLength(ReminderTuning.days));
    });

    test('a change that moves no reminder leaves the schedule alone', () async {
      await service.turnOn(progress);
      await service.idle;
      final calls = platform.scheduled.length;
      await progress.updateSettings(progress.settings.copyWith(haptics: !progress.settings.haptics));
      await service.idle;
      expect(platform.scheduled, hasLength(calls));
    });

    test('whether the phone lets the app notify: checked as it starts and each time the app comes back', () async {
      expect(service.notificationsAllowed.value, isTrue);
      platform.allowed = false;
      final binding = TestWidgetsFlutterBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await service.idle;
      await Future<void>.delayed(Duration.zero);
      expect(service.notificationsAllowed.value, isFalse);
      platform.granted = true;
      await service.turnOn(progress);
      expect(service.notificationsAllowed.value, isTrue, reason: 'asking again was answered yes');
    });

    test('a detached service no longer follows the player', () async {
      service.detach(progress);
      final calls = platform.scheduled.length;
      await progress.updateSettings(progress.settings.copyWith(reminders: true));
      await service.idle;
      expect(platform.scheduled, hasLength(calls));
      service.attach(progress);
    });
  });

  group('the offer on Results', () {
    late Progress progress;

    setUp(() async {
      progress = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await progress.updateSettings(progress.settings.copyWith(language: 'en', languagePicked: true));
      await progress.setLearningMode(LearningMode.journey);
    });

    tearDown(() => progress.db.close());

    SessionReport report({PlayMode mode = PlayMode.training, bool dayDone = false, int? runId = 1}) => SessionReport(
          runId: runId,
          completed: true,
          total: const Duration(seconds: 30),
          attempts: const [],
          previousBest: null,
          ratingBefore: null,
          ratingAfter: null,
          goalRaised: false,
          mode: mode,
          dayDone: dayDone ? _dayDone : null,
        );

    test("after the run that finishes the first day's set", () {
      expect(remindersOfferDue(progress, report(dayDone: true)), isTrue);
      expect(remindersOfferDue(progress, report()), isFalse, reason: 'no day done yet');
    });

    test('a player who finished a day before it existed: after their next training run', () async {
      await _addFinishedDay(progress);
      final again = await Progress.open(progress.db);
      expect(remindersOfferDue(again, report()), isTrue);
      expect(remindersOfferDue(again, report(mode: PlayMode.free)), isFalse);
    });

    test('never twice, never once reminders are on, never for an unrecorded run', () async {
      expect(remindersOfferDue(progress, report(dayDone: true, runId: null)), isFalse);
      await progress.updateSettings(progress.settings.copyWith(reminders: true));
      expect(remindersOfferDue(progress, report(dayDone: true)), isFalse);
      await progress.updateSettings(progress.settings.copyWith(reminders: false, remindersOffered: true));
      expect(remindersOfferDue(progress, report(dayDone: true)), isFalse);
    });

    test('never in all-known mode', () async {
      await progress.switchToAllKnown();
      expect(remindersOfferDue(progress, report(dayDone: true)), isFalse);
    });
  });
}

final _dayDone = DayDone(
  date: DateTime.utc(2026, 10, 14),
  bar: const SetBar(reviews: 0, reviewsDone: 0, fresh: 4, freshDone: 4, extra: 0, extraDone: 0, extraKnown: 0),
  rounds: 1,
  newCards: 4,
  missesFixed: 0,
  goalStreak: 1,
  xp: XpTuning.dayDone,
);

/// Stores a past practice day finished by a training run, as an existing
/// player's data has.
Future<void> _addFinishedDay(Progress progress) async {
  final db = progress.db;
  final start = DateTime(2026, 9, 1, 4);
  await db.into(db.days).insert(DaysCompanion.insert(
        day: const Value(20260901),
        startsAt: start,
        endsAt: start.add(const Duration(days: 1)),
        doneAt: Value(start.add(const Duration(hours: 6))),
      ));
  await db.into(db.runs).insert(RunsCompanion.insert(
        mode: PlayMode.training,
        startedAt: start.add(const Duration(hours: 5)),
        endedAt: start.add(const Duration(hours: 6)),
        day: 20260901,
        allKnown: false,
        goalMs: 1000,
        planned: 4,
        completed: true,
        dayDone: const Value(true),
      ));
}
