// Tobi's offer of daily reminders over Results: once, in journey mode only,
// after the first day's set (or an existing player's next training run),
// after any celebration; its answers; the note when the phone refuses; and
// the Settings switch. With RENDER_SCREENS=1 it renders the offer, the note
// and the switch, in English and Japanese, at text scale 1.0 and 1.3.
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/today_set.dart';
import 'package:fudatobashi/domain/trainer.dart';
import 'package:fudatobashi/l10n/reminder_strings.dart';
import 'package:fudatobashi/l10n/settings_strings.dart';
import 'package:fudatobashi/l10n/home_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/play_config.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/reminders.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/app.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/results/celebration_sequence.dart';
import 'package:fudatobashi/ui/results/reminder_offer.dart';
import 'package:fudatobashi/ui/results/results_screen.dart';
import 'package:fudatobashi/ui/settings/settings_rows.dart';
import 'package:fudatobashi/ui/shell/header_actions.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'test_l10n.dart';
import 'test_reminders.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

class _QuietSounds extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
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

/// A recorded training run's report, no personal best, finishing the day's
/// set when [dayDone].
SessionReport _report({bool dayDone = false}) => SessionReport(
      runId: 1,
      completed: true,
      total: const Duration(seconds: 30),
      attempts: const [],
      previousBest: const Duration(seconds: 10),
      ratingBefore: null,
      ratingAfter: null,
      goalRaised: false,
      mode: PlayMode.training,
      dayDone: dayDone ? _dayDone : null,
    );

void main() {
  loadTestVectorArt();
  loadTestL10n();
  tz_data.initializeTimeZones();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final realSounds = sounds;
  final realReminders = reminders;
  late FakeReminderPlatform platform;
  setUp(() {
    sounds = _QuietSounds();
    platform = FakeReminderPlatform(tz.getLocation('Asia/Tokyo'));
    reminders = Reminders(platform: platform);
  });
  tearDown(() {
    sounds = realSounds;
    reminders = realReminders;
  });

  setUpAll(() async {
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  // A player in [lang] and [mode] who has taken the tour; [finishedADay]
  // gives them a day's set finished before the offer existed.
  Future<Progress> player(WidgetTester tester,
      {String lang = 'en', LearningMode mode = LearningMode.journey, bool finishedADay = false}) async {
    late Progress p;
    await tester.runAsync(() async {
      final db = AppDatabase(NativeDatabase.memory());
      if (finishedADay) {
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
      p = await Progress.open(db);
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
      await p.setLearningMode(mode);
    });
    return p;
  }

  // Lets the database work and the platform calls a tap started finish,
  // then the frames after.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump(Motion.sheet * 2);
  }

  // Results of [report] on [phone] at [fontScale], until the offer would
  // show if no celebration comes first.
  Future<void> showResults(WidgetTester tester, Progress p, SessionReport report,
      {Screen phone = usersPhone, double fontScale = 1}) async {
    useScreen(tester, phone, fontScale: fontScale);
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMangaTheme(),
          builder: withUiFont,
          home: ResultsScreen(report: report, config: const PlayConfig(mode: PlayMode.training)),
        ),
      ),
    ));
    await tester.pump(ResultsLayout.overlayStagger);
    await tester.pump(const Duration(seconds: 1));
  }

  Finder offer() => find.byType(ReminderOffer);
  Finder blocked() => find.byType(RemindersBlocked);
  Finder label(String text) => find.text(Phrases.spoken(text));

  group('on Results', () {
    testWidgets("after the first day's set it waits for the celebrations, then shows once", (tester) async {
      final p = await player(tester, finishedADay: true);
      await showResults(tester, p, _report(dayDone: true));
      expect(find.byType(CelebrationSequence), findsOneWidget);
      expect(offer(), findsNothing, reason: 'not over the celebrations');
      for (var i = 0; i < 10 && find.byType(CelebrationSequence).evaluate().isNotEmpty; i++) {
        await tester.tap(find.byType(CelebrationSequence), warnIfMissed: false);
        await tester.pump(const Duration(seconds: 2));
      }
      expect(find.byType(CelebrationSequence), findsNothing);
      expect(offer(), findsOneWidget);
      await settle(tester);
      expect(p.settings.remindersOffered, isTrue);

      await tester.pumpWidget(const SizedBox());
      await showResults(tester, p, _report());
      expect(offer(), findsNothing, reason: 'never twice');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a player who finished a day before: after their next training run; 'No thanks' leaves them off",
        (tester) async {
      final p = await player(tester, finishedADay: true);
      await showResults(tester, p, _report());
      expect(offer(), findsOneWidget);
      final s = S(p.settings.language);
      await tester.ensureVisible(find.text(s.reminderOfferNo));
      await tester.tap(find.text(s.reminderOfferNo));
      await settle(tester);
      expect(offer(), findsNothing);
      expect(p.settings.remindersOffered, isTrue);
      expect(p.settings.reminders, isFalse);
      expect(platform.asked, 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no day finished yet: no offer', (tester) async {
      final p = await player(tester);
      await showResults(tester, p, _report());
      expect(offer(), findsNothing);
      expect(p.settings.remindersOffered, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('all-known mode: never', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown, finishedADay: true);
      await showResults(tester, p, _report());
      expect(offer(), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("'Yes' asks for the permission and turns them on", (tester) async {
      final p = await player(tester, finishedADay: true);
      await showResults(tester, p, _report());
      final s = S(p.settings.language);
      await tester.ensureVisible(find.text(s.reminderOfferYes));
      await tester.tap(find.text(s.reminderOfferYes));
      await settle(tester);
      expect(platform.asked, 1);
      expect(p.settings.reminders, isTrue);
      expect(offer(), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("'Yes' refused: they stay off and a note says how to allow them", (tester) async {
      platform.granted = false;
      final p = await player(tester, finishedADay: true);
      await showResults(tester, p, _report());
      final s = S(p.settings.language);
      await tester.ensureVisible(find.text(s.reminderOfferYes));
      await tester.tap(find.text(s.reminderOfferYes));
      await settle(tester);
      expect(p.settings.reminders, isFalse);
      expect(blocked(), findsOneWidget);
      await tester.ensureVisible(find.text(s.reminderBlockedOpen));
      await tester.tap(find.text(s.reminderBlockedOpen));
      await settle(tester);
      expect(platform.settingsOpened, 1);
      await tester.ensureVisible(find.text(s.noticeOk));
      await tester.tap(find.text(s.noticeOk));
      await tester.pump();
      expect(blocked(), findsNothing);
      expect(offer(), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['en', 'ja']) {
      for (final (phone, fontScale) in [(usersPhone, 1.0), (narrowTallPhone, 1.3), (shortNarrowPhone, 1.3)]) {
        testWidgets('fits, buttons in reach ($lang, ${phone.name} × ${phone.size.height.round()} dp, font scale $fontScale)', (tester) async {
          platform.granted = false;
          final p = await player(tester, lang: lang, finishedADay: true);
          final s = S(lang);
          await showResults(tester, p, _report(), phone: phone, fontScale: fontScale);
          expect(tester.takeException(), isNull);
          expect(label(s.reminderOfferTitle), findsNWidgets(2));
          await captureScreen(tester, 'reminder_offer', lang: lang);
          for (final answer in [s.reminderOfferNo, s.reminderOfferYes]) {
            await tester.ensureVisible(find.text(answer));
            await tester.pump();
            expect(tester.getRect(find.text(answer)).bottom, lessThanOrEqualTo(phone.size.height));
          }
          await tester.tap(find.text(s.reminderOfferYes));
          await settle(tester);
          expect(tester.takeException(), isNull);
          expect(label(s.reminderBlockedTitle), findsNWidgets(2));
          await captureScreen(tester, 'reminders_blocked', lang: lang);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });

  group('in Settings', () {
    // Opens Settings from Home with the Learning section at the top.
    Future<void> showSettings(WidgetTester tester, Progress p, {Screen phone = usersPhone, double fontScale = 1}) async {
      useScreen(tester, phone, fontScale: fontScale);
      await tester.pumpWidget(RepaintBoundary(key: screenKey, child: FudatobashiApp(progress: p)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(SettingsButton));
      await tester.pump();
      await tester.pump(Motion.route * 2);
      final s = S(p.settings.language);
      final heading = find.text(s.sectionLearning.toUpperCase());
      await tester.ensureVisible(heading);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      scroll.jumpTo(scroll.pixels + tester.getRect(heading).top - tester.getRect(find.byType(Scrollable).first).top);
      await tester.pump();
    }

    Finder row(S s) => find.ancestor(of: find.text(s.remindersSetting), matching: find.byType(SettingsSwitch));

    testWidgets('journey mode: the switch asks for the permission, then turns them on and off', (tester) async {
      final p = await player(tester);
      await showSettings(tester, p);
      final s = S(p.settings.language);
      expect(tester.widget<SettingsSwitch>(row(s)).value, isFalse, reason: 'off until the player says yes');
      await tester.ensureVisible(row(s));
      await tester.tap(row(s));
      await settle(tester);
      expect(platform.asked, 1);
      expect(p.settings.reminders, isTrue);
      await tester.runAsync(() => reminders.idle);
      expect(platform.scheduled.last, hasLength(ReminderTuning.days));
      await tester.tap(row(s));
      await settle(tester);
      await tester.runAsync(() => reminders.idle);
      expect(p.settings.reminders, isFalse);
      expect(platform.scheduled.last, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('refused: the switch stays off and the note shows', (tester) async {
      platform.granted = false;
      final p = await player(tester);
      await showSettings(tester, p);
      final s = S(p.settings.language);
      await tester.ensureVisible(row(s));
      await tester.tap(row(s));
      await settle(tester);
      expect(p.settings.reminders, isFalse);
      expect(blocked(), findsOneWidget);
      await tester.tap(find.text(s.noticeOk));
      await settle(tester);
      expect(blocked(), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('on, but notifications blocked in the phone: a warning, gone once they are allowed again', (tester) async {
      platform.allowed = false;
      final p = await player(tester);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(reminders: true)));
      await showSettings(tester, p);
      await settle(tester);
      final s = S(p.settings.language);
      expect(find.text(s.remindersBlockedWarning), findsOneWidget);
      platform.allowed = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(find.text(s.remindersBlockedWarning), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('off: no warning, blocked or not', (tester) async {
      platform.allowed = false;
      final p = await player(tester);
      await showSettings(tester, p);
      await settle(tester);
      expect(find.text(S(p.settings.language).remindersBlockedWarning), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['en', 'ja']) {
      for (final fontScale in [1.0, 1.3]) {
        testWidgets('the warning fits ($lang, font scale $fontScale)', (tester) async {
          platform.allowed = false;
          final p = await player(tester, lang: lang);
          await tester.runAsync(() => p.updateSettings(p.settings.copyWith(reminders: true)));
          await showSettings(tester, p, phone: narrowTallPhone, fontScale: fontScale);
          await settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text(S(lang).remindersBlockedWarning), findsOneWidget);
          await captureScreen(tester, 'settings_reminders_blocked', lang: lang);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    testWidgets('all-known mode: the switch shows too', (tester) async {
      final p = await player(tester, mode: LearningMode.allKnown);
      await showSettings(tester, p);
      expect(find.text(S(p.settings.language).remindersSetting), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    for (final lang in ['en', 'ja']) {
      for (final fontScale in [1.0, 1.3]) {
        testWidgets('the switch fits ($lang, font scale $fontScale)', (tester) async {
          final p = await player(tester, lang: lang);
          await showSettings(tester, p, phone: narrowTallPhone, fontScale: fontScale);
          expect(tester.takeException(), isNull);
          final s = S(lang);
          await captureScreen(tester, 'settings_reminders', lang: lang);
          await tester.ensureVisible(row(s));
          await tester.pump();
          expect(find.text(s.remindersSettingNote), findsOneWidget);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  });
}
