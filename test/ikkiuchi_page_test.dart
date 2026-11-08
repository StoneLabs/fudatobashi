// 一騎打ち's page (IkkiuchiPage): its strip, ranked chained up as coming
// soon, free play's steppers, and a match started from it: held in
// landscape, played to the setup picked, recorded once over and closed,
// the page's strip counting it.
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/islands.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/domain/ikkiuchi_match.dart';
import 'package:fudatobashi/domain/ikkiuchi_record.dart';
import 'package:fudatobashi/l10n/ikkiuchi_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/side_trips/ankiren_sheet.dart';
import 'package:fudatobashi/ui/side_trips/ikkiuchi_page.dart';
import 'package:fudatobashi/ui/side_trips/side_trip_panels.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

class _Quiet extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}

  @override
  Future<void> stopKimarijiVoice() async {}
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  const s = S('en');
  final real = sounds;
  setUp(() => sounds = _Quiet());
  tearDown(() => sounds = real);
  setUpAll(() => CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes()));

  Future<Progress> open(WidgetTester tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(language: 'en', languagePicked: true, toured: true));
    });
    return p;
  }

  Future<void> showPage(WidgetTester tester, Progress p) async {
    useScreen(tester, usersPhone);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProgressScope(
      progress: p,
      child: MaterialApp(
        navigatorKey: navigator,
        theme: buildMangaTheme(),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    ));
    navigator.currentState!.push(MangaRoute<void>(builder: (_) => const IkkiuchiPage()));
    await tester.pump();
    await tester.pump(Motion.route);
  }

  String cell(WidgetTester tester, String label) {
    final stat = find.ancestor(of: find.text(label), matching: find.byType(StatCell)).first;
    return tester.widget<Text>(find.descendant(of: stat, matching: find.byType(Text)).last).data!;
  }

  Finder stepper(String label) => find.ancestor(of: find.text(label), matching: find.byType(SheetStepper));
  Finder sign(String label, String sign) => find.descendant(of: stepper(label), matching: find.text(sign));

  testWidgets('the strip, ranked chained as coming soon, and free play on the first match\'s setup', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    expect(tester.takeException(), isNull);
    expect([cell(tester, s.ikkiuchiPlayed), cell(tester, s.ikkiuchiWon), cell(tester, s.ikkiuchiLost)], ['0', '0', '0']);
    expect(find.byType(LockedPanel), findsOneWidget);
    expect(find.text(s.ikkiuchiRankedSoon), findsOneWidget);
    for (final (label, value) in [
      (s.ikkiuchiCards, '${IkkiuchiFreeTuning.perSide}'),
      (s.ikkiuchiMemoryTime, '15:00'),
      (s.ikkiuchiTobiRating, '${IkkiuchiFreeTuning.rating.round()}'),
    ]) {
      expect(find.descendant(of: stepper(label), matching: find.text(value)), findsOneWidget, reason: label);
    }

    await tester.tap(sign(s.ikkiuchiCards, '−'));
    await tester.tap(sign(s.ikkiuchiTobiRating, '+'));
    await tester.pump();
    expect(find.descendant(of: stepper(s.ikkiuchiCards), matching: find.text('20')), findsOneWidget);
    expect(find.descendant(of: stepper(s.ikkiuchiTobiRating), matching: find.text('2000')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('START plays the setup in landscape; a match given up is recorded, and the screen closes', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    List<Object?> orientations() =>
        [for (final c in calls) if (c.method == 'SystemChrome.setPreferredOrientations') c.arguments];

    final p = await open(tester);
    await showPage(tester, p);
    await tester.tap(sign(s.ikkiuchiMemoryTime, '−'));
    await tester.tap(sign(s.ikkiuchiCards, '−'));
    await tester.pump();
    await tester.tap(find.text(s.ikkiuchiStart));
    await tester.pump();
    await tester.pump(Motion.route);

    final screen = tester.state<IkkiuchiMatchScreenState>(find.byType(IkkiuchiMatchScreen));
    final flow = screen.flow!;
    expect(flow.stage, IkkiuchiStage.memoryTime);
    expect(flow.memoryTime, const Duration(minutes: 10));
    expect(flow.rating, IkkiuchiFreeTuning.rating);
    expect(flow.scene.sides!.playerCards, hasLength(20));
    expect(flow.scene.sides!.tobiCards, hasLength(20));
    expect(orientations().last, ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']);
    expect(tester.takeException(), isNull);

    flow.end();
    await tester.pump();
    expect(flow.stage, IkkiuchiStage.gameEnd);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(p.ikkiuchi.matches, hasLength(1));
    final match = p.ikkiuchi.matches.single;
    expect([match.result, match.perSide, match.memoriseMs, match.tobiRating, match.playerLeft, match.tobiLeft],
        [IkkiuchiResult.gaveUp, 20, 600000, IkkiuchiFreeTuning.rating, 20, 20]);

    await tester.pump(IkkiuchiFreeTuning.leaveAfter);
    await tester.pump(Motion.route);
    await tester.pump(Motion.route);
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
    expect(orientations().last, ['DeviceOrientation.portraitUp'], reason: 'portrait again once it closes');
    expect(p.ikkiuchi.matches, hasLength(1), reason: 'recorded once');
    expect([cell(tester, s.ikkiuchiPlayed), cell(tester, s.ikkiuchiLost)], ['1', '1']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving a match under way records it as given up', (tester) async {
    final p = await open(tester);
    await showPage(tester, p);
    await tester.tap(find.text(s.ikkiuchiStart));
    await tester.pump();
    await tester.pump(Motion.route);
    await tester.pump(const Duration(seconds: 2));
    Navigator.of(tester.element(find.byType(IkkiuchiMatchScreen))).pop();
    await tester.pump();
    await tester.pump(Motion.route);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(find.byType(IkkiuchiMatchScreen), findsNothing);
    expect([for (final m in p.ikkiuchi.matches) m.result], [IkkiuchiResult.gaveUp]);
    await tester.pumpWidget(const SizedBox());
  });

}
