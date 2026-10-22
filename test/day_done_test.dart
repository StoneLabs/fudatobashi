// The 本日完了!! page after the run that finishes today's set: its numbers,
// its stop-motion entrance and reduced motion, and that it fits 360, 384 and
// 412 dp phones at text scale 1.0 and 1.3 in English and Japanese; the
// developer preview row plays it.
//
// With RENDER_SCREENS=1 it also renders the page, at rest and mid-entrance,
// with real fonts and art, to build/screens/daily_set/.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
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
import 'package:fudatobashi/domain/xp.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/results/celebration_chrome.dart';
import 'package:fudatobashi/ui/results/day_done_overlay.dart';
import 'package:fudatobashi/ui/settings/settings_screen.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

class _QuietSounds extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}

/// The mock's day: 44 looks over 2 rounds, 4 new cards, 6 misses fixed, a
/// 5-day goal streak.
DayDone _day({int reviews = 22, int fresh = 16, int extra = 6, int rounds = 2, int newCards = 4, int misses = 6, int streak = 5}) =>
    DayDone(
      date: DateTime.utc(2026, 10, 14),
      bar: SetBar(reviews: reviews, reviewsDone: reviews, fresh: fresh, freshDone: fresh, extra: extra, extraDone: extra, extraKnown: extra),
      rounds: rounds,
      newCards: newCards,
      missesFixed: misses,
      goalStreak: streak,
      xp: XpTuning.dayDone,
    );

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final real = sounds;
  setUp(() => sounds = _QuietSounds());
  tearDown(() => sounds = real);

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

  Future<Progress> open(WidgetTester tester, String lang) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: lang, languagePicked: true, toured: true));
    });
    return p;
  }

  // Shows the page for [day] on [phone] at [fontScale], [at] into its
  // entrance from the start (at rest by default).
  Future<void> showPage(
    WidgetTester tester,
    String lang,
    Screen phone, {
    double fontScale = 1,
    DayDone? day,
    Duration? at,
    VoidCallback? onNext,
  }) async {
    final p = await open(tester, lang);
    await tester.pumpWidget(const SizedBox());
    useScreen(tester, phone, fontScale: fontScale);
    await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('screen'),
      child: ProgressScope(
        progress: p,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildMangaTheme(),
          builder: (context, child) => DefaultTextStyle(style: Theme.of(context).textTheme.bodyMedium!, child: child!),
          home: Scaffold(body: DayDoneOverlay(day: day ?? _day(), onNext: onNext ?? () {})),
        ),
      ),
    ));
    await tester.pump(at ?? DayDoneMotion.length);
    expect(tester.takeException(), isNull);
  }

  Finder numbered(String template, List<Object> values) => find.byWidgetPredicate(
      (w) => w is NumberedText && w.template == template && w.values.join(',') == values.join(','));

  // How far the bar's green has swept, and how opaque the hanko is.
  double sweep(WidgetTester tester) => tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor!;
  double opacityOf(WidgetTester tester, Finder f) =>
      tester.widget<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity)).first).opacity;

  for (final lang in ['en', 'ja']) {
    testWidgets('the day in numbers, the hanko with its date, +1000 XP and the button ($lang)', (tester) async {
      var advanced = false;
      await showPage(tester, lang, usersPhone, onNext: () => advanced = true);
      final s = S(lang);
      expect(find.text(DayDoneLayout.title), findsWidgets);
      expect(find.text(s.dayDoneBand), findsOneWidget);
      expect(numbered(s.dayDoneCleared(2), [44, 2]), findsOneWidget);
      expect(numbered(s.dayDoneNew(4), [4]), findsOneWidget);
      expect(numbered(s.dayDoneMisses(6), [6]), findsOneWidget);
      expect(numbered(s.dayDoneStreak(5), [5]), findsOneWidget);
      expect(find.text(DayDoneLayout.stamp), findsOneWidget);
      expect(find.text('2026.10.14'), findsOneWidget);
      expect(find.text(s.xpSource(XpSource.dayDone)), findsOneWidget);
      expect(find.text('+1000 XP'), findsNWidgets(2), reason: 'the count over its width keeper');
      final cta = find.byType(CelebrationCta);
      expect(find.descendant(of: cta, matching: find.text(s.xpCta)), findsOneWidget);
      final beside = find.descendant(of: cta, matching: find.text(s.other.xpCta));
      if (s.ja) {
        expect(beside, findsOneWidget);
        expect(tester.getSize(find.text(s.xpCta)).height, greaterThan(tester.getSize(beside).height),
            reason: 'the UI language big, the other one as the sub');
      } else {
        expect(beside, findsNothing, reason: 'an English button has no Japanese beside it');
      }
      await tester.tap(cta);
      expect(advanced, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('lines that would read badly change or go: one round, one new card, no misses, a first streak day',
      (tester) async {
    const s = S('en');
    await showPage(tester, 'en', usersPhone, day: _day(rounds: 1, newCards: 1, fresh: 4, extra: 0, misses: 0, streak: 1));
    expect(numbered(s.dayDoneCleared(1), [26, 1]), findsOneWidget);
    expect(find.text('26 cards cleared in 1 round', findRichText: true), findsOneWidget);
    expect(find.text('1 new card met and seen again', findRichText: true), findsOneWidget);
    expect(find.text('No misses', findRichText: true), findsOneWidget);
    expect(find.text('Goal streak starts today', findRichText: true), findsOneWidget);

    await showPage(tester, 'en', usersPhone, day: _day(fresh: 0, newCards: 0));
    expect(find.byWidgetPredicate((w) => w is NumberedText && w.template == s.dayDoneNew(0)), findsNothing,
        reason: 'no new cards today: no line for them');

    await showPage(tester, 'en', usersPhone, day: _day(reviews: 0, fresh: 0, extra: 0, newCards: 0, misses: 0, rounds: 1));
    expect(find.byType(NumberedText), findsOneWidget, reason: 'an empty set: only the streak');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('enters in steps: the bar sweeps its last bit green, then the hanko slams down and the XP counts up',
      (tester) async {
    await showPage(tester, 'en', usersPhone, at: DayDoneMotion.sweep.delay);
    expect(sweep(tester), DayDoneLayout.sweepFrom, reason: 'the last bit not green yet');
    expect(opacityOf(tester, find.text(DayDoneLayout.stamp)), 0);
    expect(find.text('+0 XP'), findsOneWidget);
    final sweeping = <double>{};
    for (var t = Duration.zero; t < DayDoneMotion.sweep.duration; t += const Duration(milliseconds: 20)) {
      await tester.pump(const Duration(milliseconds: 20));
      sweeping.add(sweep(tester));
    }
    expect(sweeping.length, lessThanOrEqualTo(8 + 1), reason: 'stop-motion: a handful of steps, not a glide');
    await tester.pump(DayDoneMotion.stamp.end - DayDoneMotion.sweep.end);
    expect(sweep(tester), 1);
    expect(opacityOf(tester, find.text(DayDoneLayout.stamp)), 1);
    await tester.pump(DayDoneMotion.xp.delay + DayDoneMotion.xp.duration ~/ 2 - DayDoneMotion.stamp.end);
    expect(find.text('+500 XP'), findsOneWidget, reason: 'half way through the count');
    await tester.pump(DayDoneMotion.length);
    expect(find.text('+1000 XP'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion: one still drawing, the bar green, the hanko and ドン! down, +1000 XP at once',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await showPage(tester, 'en', usersPhone, at: Duration.zero);
    expect(sweep(tester), 1);
    expect(opacityOf(tester, find.text(DayDoneLayout.stamp)), 1);
    expect(find.text('+1000 XP'), findsNWidgets(2));
    expect(find.byType(SfxText), findsOneWidget);
    for (final text in [DayDoneLayout.stamp, '2026.10.14']) {
      expect(opacityOf(tester, find.text(text)), 1);
    }
    await tester.pumpWidget(const SizedBox());
  });

  group('fits', () {
    for (final phone in [narrowPhone, usersPhone, widePhone]) {
      for (final lang in ['en', 'ja']) {
        for (final fontScale in [1.0, 1.3]) {
          testWidgets('${phone.name} dp, $lang, text × $fontScale', (tester) async {
            await showPage(tester, lang, phone, fontScale: fontScale);
            final safe = Rect.fromLTRB(0, phone.bars.top, phone.size.width, phone.size.height - phone.bars.bottom);
            final cta = tester.getRect(find.byType(CelebrationCta));
            final stats = tester.getRect(find.byType(MangaPanel));
            final title = tester.getRect(find.byType(OutlinedText));
            expect(title.top, greaterThanOrEqualTo(safe.top));
            expect(title.left >= Gaps.gutter - 0.5 && title.right <= phone.size.width - Gaps.gutter + 0.5, isTrue);
            expect(cta.left, moreOrLessEquals(Gaps.gutter));
            expect(cta.right, moreOrLessEquals(phone.size.width - Gaps.gutter));
            expect(cta.bottom, lessThanOrEqualTo(safe.bottom - Gaps.section + 0.5));
            expect(cta.height, greaterThanOrEqualTo(DayDoneLayout.ctaHeight));
            expect(stats.left, moreOrLessEquals(DayDoneLayout.statsInset));
            expect(stats.bottom, lessThanOrEqualTo(cta.top - DayDoneLayout.ctaGap + 0.5));
            for (final line in find.byType(NumberedText).evaluate()) {
              final r = tester.getRect(find.byWidget(line.widget));
              expect(r.left >= stats.left && r.right <= stats.right, isTrue, reason: (line.widget as NumberedText).template);
            }
            if (fontScale == 1.0) expect(find.byType(Tobi), findsOneWidget);
            if (find.byType(Tobi).evaluate().isNotEmpty) {
              expect(tester.getRect(find.byType(Tobi)).height, greaterThanOrEqualTo(DayDoneLayout.tobiMinHeight - 0.5),
                  reason: 'Tobi never shrinks to a speck');
            }
            if (fontScale == 1.0 && phone != narrowPhone) {
              final tobi = tester.getRect(find.byType(Tobi));
              expect(tobi.width, moreOrLessEquals(DayDoneLayout.tobi.width), reason: 'full size where there is room');
              expect(tobi.height, moreOrLessEquals(DayDoneLayout.tobi.height));
            }
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  });

  testWidgets("settings, developer: 'Preview today's set done' plays the page and comes back", (tester) async {
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    final p = await open(tester, 'en');
    await tester.runAsync(() => p.updateSettings(p.settings.copyWith(debugMode: true)));
    await tester.binding.setSurfaceSize(usersPhone.size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProgressScope(progress: p, child: MaterialApp(theme: buildMangaTheme(), home: const SettingsScreen())));
    const label = "Preview today's set done";
    await tester.scrollUntilVisible(find.text(label), 200);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DayDoneOverlay), findsOneWidget);
    await tester.pump(DayDoneMotion.length);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(DayDoneOverlay));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(DayDoneOverlay), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(p.runs, isEmpty, reason: 'a preview touches no progress');
    await tester.pumpWidget(const SizedBox());
  });

  group('renders', skip: !renderScreens, () {
    Future<void> capture(WidgetTester tester, String name, String lang) async {
      await tester.runAsync(() async {
        final context = tester.element(find.byType(DayDoneOverlay));
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, context);
        }
      });
      await tester.pump();
      await captureScreen(tester, 'daily_set/day_done_$name', lang: lang);
    }

    for (final lang in ['en', 'ja']) {
      testWidgets('day_done_$lang', (tester) async {
        for (final (name, at) in [
          ('sweep', DayDoneMotion.sweep.delay + const Duration(milliseconds: 100)),
          ('impact', DayDoneMotion.impactAt + const Duration(milliseconds: 40)),
          ('rest', DayDoneMotion.length),
        ]) {
          await showPage(tester, lang, usersPhone, at: at);
          await capture(tester, name, lang);
        }
        for (final phone in [narrowPhone, widePhone]) {
          for (final fontScale in [1.0, 1.3]) {
            await showPage(tester, lang, phone, fontScale: fontScale);
            await capture(tester, 'rest', lang);
          }
        }
        await showPage(tester, lang, usersPhone, fontScale: 1.3);
        await capture(tester, 'rest', lang);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
