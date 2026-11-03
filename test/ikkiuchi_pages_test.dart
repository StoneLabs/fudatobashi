// 一騎打ち's developer pages, Tobi's curves, his layout and his strikes,
// opened from Settings' developer section. With RENDER_SCREENS=1 it writes
// their PNGs to build/screens/ikkiuchi/.
import 'dart:io';
import 'dart:math' as math;

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
import 'package:fudatobashi/domain/ikkiuchi_cards.dart';
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_read.dart';
import 'package:fudatobashi/domain/ikkiuchi_strike.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_curves_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_graphs.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_layout_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_rating_header.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_strikes_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_values.dart';
import 'package:fudatobashi/ui/history/ankiren_field_tab.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_painter.dart';
import 'package:fudatobashi/ui/manga/theme.dart';
import 'package:fudatobashi/ui/settings/settings_screen.dart';
import 'package:fudatobashi/ui/sound/sounds.dart';
import 'package:fudatobashi/ui/torifuda/card_faces.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_l10n.dart';
import 'test_screens.dart';
import 'test_vector_art.dart';

class _Quiet extends Sounds {
  @override
  Future<void> play(Sfx sfx) async {}

  @override
  Future<void> playKimarijiVoice(int poemId) async {}
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$f').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  loadTestVectorArt();
  loadTestL10n();
  poems = Poems.fromJsonString(File('assets/data/poems.json').readAsStringSync());
  fudaSets = FudaSets(poems);
  archipelago = Archipelago.fromJsonString(File('assets/data/islands.json').readAsStringSync());
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final real = sounds;
  setUp(() => sounds = _Quiet());
  tearDown(() => sounds = real);

  setUpAll(() async {
    await loadRenderMonoFont();
    await _loadFont('Dela', ['DelaGothicOne-Regular.ttf']);
    await _loadFont('Reggae', ['ReggaeOne-Regular.ttf']);
    if (renderScreens) {
      await _loadFont('Torifuda', ['YujiSyuku-Regular.ttf']);
      await _loadFont('TorifudaNumber', ['TeXGyreSchola-Regular.otf']);
    }
    await CardFaces.load([TorifudaStyle.standard.background], read: (a) => File(a).readAsBytes());
    await _loadFont('ZenKaku', [
      'ZenKakuGothicNew-Regular.ttf',
      'ZenKakuGothicNew-Medium.ttf',
      'ZenKakuGothicNew-Bold.ttf',
      'ZenKakuGothicNew-Black.ttf',
    ]);
  });

  // A player in developer mode who reads kimariji in hiragana.
  Future<Progress> open(WidgetTester tester) async {
    late Progress p;
    await tester.runAsync(() async {
      p = await Progress.open(AppDatabase(NativeDatabase.memory()));
      await p.updateSettings(p.settings.copyWith(
          language: 'en',
          languagePicked: true,
          toured: true,
          debugMode: true,
          kimarijiScript: KimarijiScript.hiragana));
    });
    return p;
  }

  // [page] afresh, its state and scrolling new.
  Future<void> show(WidgetTester tester, Progress p, Widget page) async {
    useScreen(tester, usersPhone);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(RepaintBoundary(
      key: screenKey,
      child: ProgressScope(
        progress: p,
        child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildMangaTheme(), home: page),
      ),
    ));
    await tester.pump();
  }

  // Scrolls the page's list down a screen at a time, rendering each stop as
  // [name]_1, _2, … until its end.
  Future<void> captureDown(WidgetTester tester, String name) async {
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    for (var i = 1;; i++) {
      await captureScreen(tester, '${name}_$i');
      if (list.pixels >= list.maxScrollExtent) break;
      list.jumpTo((list.pixels + list.viewportDimension * 0.9).clamp(0, list.maxScrollExtent));
      await tester.pump();
    }
  }

  testWidgets("Settings' developer section opens Tobi's curves and his layout", (tester) async {
    PackageInfo.setMockInitialValues(
        appName: 'Fudatobashi', packageName: 'dev.fudatobashi', version: '1.0.0', buildNumber: '1', buildSignature: '');
    final p = await open(tester);
    await tester.binding.setSurfaceSize(usersPhone.size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        ProgressScope(progress: p, child: MaterialApp(theme: buildMangaTheme(), home: const SettingsScreen())));
    for (final (label, page) in [
      ("Comp - Tobi's curves", IkkiuchiCurvesPage),
      ("Comp - Tobi's layout", IkkiuchiLayoutPage),
      ("Comp - Tobi's strikes", IkkiuchiStrikesPage),
    ]) {
      await tester.scrollUntilVisible(find.text(label), 200);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump(Motion.route * 2);
      expect(find.byType(page), findsOneWidget, reason: label);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(page))).pop();
      await tester.pump();
      await tester.pump(Motion.route * 2);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi's curves: his values and their ranges at the slider's rating, and a graph of each",
      (tester) async {
    final p = await open(tester);
    final take = ikkiuchiValueGroups.expand((g) => g.rows).firstWhere((v) => v.name == 'take time');
    for (final rating in [0.0, 1700.0, 3600.0]) {
      await show(tester, p, IkkiuchiCurvesPage(rating: rating));
      expect(tester.takeException(), isNull);
      final r = rating.round();
      expect(find.text('rating $r'), findsOneWidget);
      expect(find.text('at $r'), findsOneWidget);
      expect(find.text(take.unit.format(IkkiuchiTobi(rating).takeMs)), findsWidgets, reason: 'take time at $r');
      for (final s in IkkiuchiToolsTuning.sigmas) {
        expect(find.text(take.matchRangeText(rating, s)), findsWidgets, reason: 'take time per match, $s sd');
        expect(find.text(take.cardRangeText(rating, s)), findsWidgets, reason: 'take time per card, $s sd');
      }
      expect(find.text(ikkiuchiNoRange), findsWidgets, reason: 'fixed values');
      expect(find.text(ikkiuchiAnyInGame), findsWidgets, reason: 'under the chances per group');
      final sound = ikkiuchiValueGroups.expand((g) => g.rows).firstWhere((v) => v.name == 'sound grouping');
      expect(find.text(sound.anyInGame!.unit.format(sound.anyInGame!.at(rating))), findsWidgets, reason: '$r');
      await captureDown(tester, 'ikkiuchi/curves_$r');
      expect(tester.takeException(), isNull);
      expect(find.byType(IkkiuchiSharesGraph), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi's curves: the classes under the slider, and Export copies a curve as Dart", (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final p = await open(tester);
    await show(tester, p, const IkkiuchiCurvesPage(rating: 1700));

    final header = find.byType(IkkiuchiRatingHeader);
    for (final name in ['入門', 'F下級', 'F上級', 'D級', 'A級']) {
      expect(find.descendant(of: header, matching: find.text(name)), findsOneWidget, reason: name);
    }
    final on = tester.widget<Text>(find.descendant(of: header, matching: find.textContaining(Rating.bandOf(1700).stem)));
    expect(on.style?.fontWeight, Weights.bold, reason: 'the class at 1700 stands out');

    final list = find.byType(Scrollable).first;
    for (final (title, curve) in [
      ('Take time', IkkiuchiTuning.takeMs),
      ('Arm moves', IkkiuchiTuning.sweepShare),
    ]) {
      await tester.scrollUntilVisible(find.text(title), 300, scrollable: list);
      final export = find.descendant(
        of: find.ancestor(of: find.text(title), matching: find.byType(Row)).first,
        matching: find.text('Export'),
      );
      await tester.tap(export);
      await tester.pump();
      expect(copied.last, curve.toDart(), reason: title);
    }
    await tester.scrollUntilVisible(find.text('Stray touch'), -300, scrollable: list);
    expect(
      find.descendant(
          of: find.ancestor(of: find.text('Stray touch'), matching: find.byType(Row)).first,
          matching: find.text('Export')),
      findsNothing,
      reason: 'a curve worked out from another has none of its own to export',
    );
    await tester.pump(ToastStyle.hold + ToastStyle.fade);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("Tobi's layout: his side by rating, the full layout, and the controls", (tester) async {
    final p = await open(tester);
    const perSide = IkkiuchiToolsTuning.perSideStart;
    Finder page() => find.byType(Scrollable).first;
    Future<void> toTop() async {
      tester.state<ScrollableState>(page()).position.jumpTo(0);
      await tester.pump();
    }

    // The cards on the page's field, scrolled into sight with the row
    // counts under it.
    Future<Set<int>> fieldCards() async {
      await toTop();
      await tester.scrollUntilVisible(find.text('homes L'), 200, scrollable: page());
      return tester.widgetList<FieldWordCard>(find.byType(FieldWordCard)).map((c) => c.poemId).toSet();
    }

    // The field's sideways scrolling.
    ScrollPosition field() => tester
        .state<ScrollableState>(
            find.ancestor(of: find.byType(FieldWordCard).first, matching: find.byType(Scrollable)).first)
        .position;

    for (final rating in [0.0, 1700.0, 2600.0, 3000.0, 3600.0]) {
      final r = rating.round();
      final deck = [for (final poem in poems.all) poem.id]..shuffle(math.Random(3));
      final homes = IkkiuchiLayout.ofPoems().generate(
          rating: rating, own: deck.sublist(0, perSide), others: deck.sublist(perSide, 2 * perSide), rows: 3, seed: 3);

      await show(tester, p, IkkiuchiLayoutPage(rating: rating, seed: 3));
      expect(tester.takeException(), isNull);
      expect(find.text('seed 3'), findsOneWidget);
      String kept(Map<Object, bool> groups) => '${groups.values.where((k) => k).length} / ${groups.length}';
      expect(find.text('sound groups together ${kept(homes.soundGroups)}'), findsOneWidget, reason: '$r');
      expect(find.text('友札 together ${kept(homes.tomofudaGroups)}'), findsOneWidget, reason: '$r');
      final start = homes.start;
      final left = start.fold(0, (n, row) => n + row.left.length);
      expect(find.text('left $left · right ${perSide - left}'), findsOneWidget, reason: '$r');
      expect(find.textContaining('${IkkiuchiToolsTuning.wideRows.first}+ '), findsOneWidget, reason: 'wide rows');
      await captureDown(tester, 'ikkiuchi/layout_$r');
      expect(await fieldCards(), hasLength(perSide), reason: 'his side alone');

      await show(tester, p, IkkiuchiLayoutPage(rating: rating, seed: 3, full: true));
      expect(tester.takeException(), isNull);
      await captureDown(tester, 'ikkiuchi/layout_${r}_full');
      expect(await fieldCards(), hasLength(2 * perSide), reason: 'every card dealt');
      expect(field().maxScrollExtent, 0, reason: 'the full layout fits the phone at $r');
    }

    await show(tester, p, const IkkiuchiLayoutPage(rating: 1600, seed: 3));
    await tester.tap(find.text('Full teiichi'));
    await tester.pump();
    expect(await fieldCards(), hasLength(2 * perSide), reason: 'Full teiichi shows every card dealt');

    await show(tester, p, const IkkiuchiLayoutPage(rating: 1600, seed: 3));
    Future<void> tapChip(String label) async {
      await toTop();
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
    }

    ChoiceChip rows(int n) => tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '$n'));
    expect(rows(1).onSelected, isNull, reason: '25 cards are too many for 1 row');
    expect(rows(2).onSelected, isNull, reason: '25 cards are too many for 2 rows');
    await tapChip('${IkkiuchiLayoutTuning.oneRowUpTo}');
    expect(await fieldCards(), hasLength(IkkiuchiLayoutTuning.oneRowUpTo));
    await tapChip('1');
    expect(rows(1).selected, isTrue);
    await captureScreen(tester, 'ikkiuchi/layout_1600_one_row');
    await tapChip('25');
    expect(rows(IkkiuchiLayoutTuning.rows).selected, isTrue, reason: 'back to the rows 25 cards may take');
    await tester.tap(find.text('Reroll'));
    await tester.pump();
    expect(find.text('seed 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  group("Tobi's strikes", () {
    const frame = Duration(milliseconds: 16);
    IkkiuchiBoardScene scene(WidgetTester tester) =>
        tester.state<IkkiuchiStrikesPageState>(find.byType(IkkiuchiStrikesPage)).scene!;

    // Taps the board at [at], in board dp, through any turn of the board.
    Future<void> tapBoard(WidgetTester tester, Vec at) async {
      final view = tester.renderObject<RenderBox>(find.byType(IkkiuchiBoardView));
      await tester.tapAt(view.localToGlobal(Offset(at.x, at.y)));
      await tester.pump();
    }

    // A card of the player's in the middle row's left group.
    int playerCard(IkkiuchiBoardScene s) {
      final cards = s.layout.cards.where((c) => c.side == IkkiuchiSide.player).toList()
        ..sort((a, b) => a.box.centre.y.compareTo(b.box.centre.y) * 10 + a.box.centre.x.compareTo(b.box.centre.x));
      return cards[cards.length ~/ 2 - 2].id;
    }

    // Runs the page on until [at] ms into the strike playing now.
    Future<void> pumpTo(WidgetTester tester, double at) async {
      final s = scene(tester);
      final run = s.board.runs.last;
      final ms = at - run.at(s.board.now);
      if (ms > 0) await tester.pump(Duration(microseconds: (ms * Duration.microsecondsPerMillisecond).round()));
    }

    // Leaves only the move named [name] on, turning the others off.
    Future<void> onlyMove(WidgetTester tester, String name) async {
      for (final other in ['sweep', 'whip', 'coil', 'smear']) {
        if (other != name) await tester.tap(find.widgetWithText(ChoiceChip, other));
      }
      await tester.pump(frame);
    }

    bool moveOn(WidgetTester tester, String name) => tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, name)).selected;

    // Renders the page once the tatami has loaded.
    Future<void> capture(WidgetTester tester, String name) async {
      if (!renderScreens) return;
      await tester.runAsync(() async {
        final context = tester.element(find.byType(IkkiuchiStrikesPage));
        await precacheImage(const AssetImage(IkkiuchiBoardStyle.tatami), context);
      });
      await tester.pump();
      await tester.pump();
      await captureScreen(tester, 'ikkiuchi/$name');
    }

    testWidgets('the board in portrait and landscape, and its controls', (tester) async {
      final p = await open(tester);
      for (final landscape in [false, true]) {
        await show(tester, p, IkkiuchiStrikesPage(rating: 2000, seed: 3, landscape: landscape));
        await tester.pump(frame);
        expect(tester.takeException(), isNull);
        final s = scene(tester);
        expect(s.layout.landscape, landscape);
        expect(s.board.field, hasLength(2 * IkkiuchiToolsTuning.strikesPerSide));
        expect(find.byType(RotatedBox), landscape ? findsOneWidget : findsNothing);
        await capture(tester, 'strikes_${landscape ? 'landscape' : 'portrait'}');
      }

      await show(tester, p, const IkkiuchiStrikesPage(rating: 2000, seed: 3));
      await tester.pump(frame);
      final s = scene(tester);
      final card = playerCard(s);
      await tapBoard(tester, s.board.cards.card(card).box.centre);
      expect(s.board.read?.called, card, reason: 'a tap reads the card under it');
      for (var i = 0; i < 200 && s.note == null; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(s.note, contains('reaction'), reason: 'his reaction and reach on the band once he struck');
      expect(s.note, contains('reach'));
      expect(s.board.cards.card(card).taken, isTrue);
      expect(s.board.faults, isEmpty);

      // The next tap sets the board out again first, and reads the card
      // under the finger there: the taken card, back at its spot.
      await tapBoard(tester, s.board.cards.card(card).home.centre);
      expect(s.board.field, hasLength(2 * IkkiuchiToolsTuning.strikesPerSide), reason: 'a fresh board');
      expect(s.board.read?.called, card, reason: 'the card under the finger on the fresh board');
      for (var i = 0; i < 200 && s.board.active == null; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(s.board.active, isNotNull, reason: 'he strikes');
      final struck = s.board;
      final next = s.layout.cards.firstWhere((c) => c.id != card && c.side == IkkiuchiSide.tobi).id;
      await tapBoard(tester, s.board.cards.card(next).home.centre);
      expect(s.board, isNot(same(struck)), reason: 'a tap during a strike cancels it');
      expect(s.board.read?.called, next);
      expect(s.board.runs, isEmpty, reason: 'his new strike is still to come');
      expect(s.board.field, hasLength(2 * IkkiuchiToolsTuning.strikesPerSide));
      await tester.tap(find.text('Reset'));
      await tester.pump(frame);
      expect(scene(tester).board.field, hasLength(2 * IkkiuchiToolsTuning.strikesPerSide), reason: 'Reset sets out the board again');

      await tester.tap(find.text('Strike now'));
      await tester.tap(find.text('Random'));
      await tester.pump(frame);
      expect(scene(tester).board.read?.reactionMs, 0, reason: 'strikes now, with no reaction');
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Karafuda'));
      await tester.pump(frame);
      expect(scene(tester).board.read?.onField, isFalse);
      await tester.pump(const Duration(seconds: 3));
      for (final name in ['sweep', 'whip', 'coil', 'smear']) {
        expect(moveOn(tester, name), isTrue, reason: 'every move on to begin with');
      }
      await onlyMove(tester, 'smear');
      await tester.tap(find.widgetWithText(ChoiceChip, 'smear'));
      await tester.pump(frame);
      expect(moveOn(tester, 'smear'), isTrue, reason: 'the last move on stays on');
      expect(moveOn(tester, 'whip'), isFalse);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Random'));
        await tester.pump(frame);
        expect(scene(tester).board.read?.move, IkkiuchiMove.smear, reason: 'only the moves on');
      }
      await tester.tap(find.text('Rotate'));
      await tester.pump(frame);
      expect(find.byType(RotatedBox), findsOneWidget, reason: 'only the board turns');
      expect(scene(tester).layout.landscape, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a strike of each move, frame by frame', (tester) async {
      final p = await open(tester);
      for (final (move, chip) in [
        (IkkiuchiMove.whip, 'whip'),
        (IkkiuchiMove.coilLunge, 'coil'),
        (IkkiuchiMove.smear, 'smear'),
        (IkkiuchiMove.sweep, 'sweep'),
      ]) {
        await show(tester, p, const IkkiuchiStrikesPage(rating: 2000, seed: 3));
        await tester.pump(frame);
        await tester.tap(find.text('Strike now'));
        await onlyMove(tester, chip);
        await tester.pump(frame);
        final s = scene(tester);
        final card = playerCard(s);
        await tapBoard(tester, s.board.cards.card(card).box.centre);
        await tester.pump(frame);
        final strike = s.board.runs.last.strike;
        expect(strike.move, move);
        expect(strike.hitAt, closeTo(IkkiuchiTobi(2000).reachMs, 0.01));
        await pumpTo(tester, strike.hitAt * 0.7);
        await capture(tester, 'strikes_${chip}_1_reach');
        await pumpTo(tester, strike.hitAt + strike.hitStop / 2);
        await capture(tester, 'strikes_${chip}_2_hit');
        await pumpTo(tester, (strike.liveFrom + strike.liveUntil) / 2);
        await capture(tester, 'strikes_${chip}_3_follow');
        await pumpTo(tester, strike.end + 300);
        await capture(tester, 'strikes_${chip}_4_after');
        expect(s.board.cards.card(card).taken, isTrue);
        expect(s.board.faults, isEmpty, reason: '$chip: a clean take');
        expect(tester.takeException(), isNull);
      }

      await show(tester, p, const IkkiuchiStrikesPage(rating: 2000, seed: 3, landscape: true));
      await tester.pump(frame);
      await tester.tap(find.text('Strike now'));
      await onlyMove(tester, 'whip');
      await tester.pump(frame);
      final s = scene(tester);
      await tapBoard(tester, s.board.cards.card(playerCard(s)).box.centre);
      await tester.pump(frame);
      final strike = s.board.runs.last.strike;
      await pumpTo(tester, strike.hitAt + strike.hitStop / 2);
      await capture(tester, 'strikes_landscape_hit');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a stray touch on a からふだ is marked お手つき', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiStrikesPage(rating: 0, seed: 3));
      await tester.pump(frame);
      final s = scene(tester);
      final onField = s.board.field.keys.toSet();
      final away = poems.all.map((poem) => poem.id).firstWhere((id) => !onField.contains(id));
      final touched = playerCard(s);
      s.board.call(IkkiuchiRead(
        called: away,
        onField: false,
        move: IkkiuchiMove.whip,
        reachMs: IkkiuchiTobi(0).reachMs,
        correctionReachMs: IkkiuchiTobi(0).reachMs,
        wrong: touched,
        slip: IkkiuchiSlip.stray,
      ));
      s.show(poems[away].kimariji, karafuda: 'からふだ');
      await tester.pump(frame);
      final strike = s.board.runs.last.strike;
      await pumpTo(tester, strike.liveUntil + 200);
      await capture(tester, 'strikes_fault');
      expect(s.board.faults.keys, contains(touched));
      expect(s.board.cards.card(touched).taken, isFalse, reason: 'a touch takes nothing');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
