// 一騎打ち's developer pages, Tobi's curves, his layout, his strikes and the
// field, opened from Settings' developer section. With RENDER_SCREENS=1 it writes
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
import 'package:fudatobashi/domain/ikkiuchi_board.dart';
import 'package:fudatobashi/domain/ikkiuchi_cards.dart';
import 'package:fudatobashi/domain/ikkiuchi_geometry.dart';
import 'package:fudatobashi/domain/ikkiuchi_layout.dart';
import 'package:fudatobashi/domain/ikkiuchi_read.dart';
import 'package:fudatobashi/domain/ikkiuchi_strike.dart';
import 'package:fudatobashi/domain/ikkiuchi_tobi.dart';
import 'package:fudatobashi/domain/placing.dart';
import 'package:fudatobashi/domain/rating.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/progress.dart';
import 'package:fudatobashi/state/scope.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_curves_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_field_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_graphs.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_layout_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_rating_header.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_strikes_page.dart';
import 'package:fudatobashi/ui/debug/ikkiuchi_values.dart';
import 'package:fudatobashi/ui/history/ankiren_field_tab.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_painter.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_board_scene.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_call_strip.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_column.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_match_layers.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_reader.dart';
import 'package:fudatobashi/ui/ikkiuchi/ikkiuchi_send_flow.dart';
import 'package:fudatobashi/ui/manga/balloon.dart';
import 'package:fudatobashi/ui/manga/hold_confirm.dart';
import 'package:fudatobashi/ui/manga/theme.dart';
import 'package:fudatobashi/ui/placing/placing_widgets.dart';
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

  // [page] afresh on [screen], its state and scrolling new.
  Future<void> show(WidgetTester tester, Progress p, Widget page, {Screen screen = usersPhone}) async {
    useScreen(tester, screen);
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
      ('Comp - Field', IkkiuchiFieldPage),
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

  // Renders the page on show once its board's tatami has loaded.
  Future<void> capture(WidgetTester tester, String name) async {
    if (!renderScreens) return;
    await tester.runAsync(() async {
      final context = tester.element(find.byType(IkkiuchiBoardView));
      await precacheImage(const AssetImage(IkkiuchiBoardStyle.tatami), context);
    });
    await tester.pump();
    await tester.pump();
    await captureScreen(tester, 'ikkiuchi/$name');
  }

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

    testWidgets('New seed deals a new board; a fixed seed deals the same', (tester) async {
      final p = await open(tester);
      List<int> ids(IkkiuchiBoardScene s) => [for (final c in s.board.cards.cards) c.id];
      await show(tester, p, const IkkiuchiStrikesPage(rating: 2000, seed: 3));
      await tester.pump(frame);
      final first = ids(scene(tester));
      expect(find.textContaining('seed 3 · you '), findsOneWidget);
      await show(tester, p, const IkkiuchiStrikesPage(rating: 2000, seed: 3));
      await tester.pump(frame);
      expect(ids(scene(tester)), first);
      var changed = false;
      for (var i = 0; i < 5 && !changed; i++) {
        await tester.tap(find.text('New seed'));
        await tester.pump(frame);
        changed = !find.textContaining('seed 3 · ').evaluate().isNotEmpty && ids(scene(tester)).toString() != first.toString();
      }
      expect(changed, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the board in portrait and landscape, and its controls', (tester) async {
      final p = await open(tester);
      for (final landscape in [false, true]) {
        await show(tester, p, IkkiuchiStrikesPage(rating: 2000, seed: 3, landscape: landscape));
        await tester.pump(frame);
        expect(tester.takeException(), isNull);
        final s = scene(tester);
        expect(s.layout.landscape, landscape);
        expect(s.board.field, hasLength(2 * IkkiuchiToolsTuning.dealPerSide));
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
      expect(s.board.field, hasLength(2 * IkkiuchiToolsTuning.dealPerSide), reason: 'a fresh board');
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
      expect(s.board.field, hasLength(2 * IkkiuchiToolsTuning.dealPerSide));
      await tester.tap(find.text('Reset'));
      await tester.pump(frame);
      expect(scene(tester).board.field, hasLength(2 * IkkiuchiToolsTuning.dealPerSide), reason: 'Reset sets out the board again');

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

    testWidgets('the field grows toward the middle: a wide row, short rows, and a tablet', (tester) async {
      final p = await open(tester);
      // Seed 153 deals Tobi a row of 14 cards; seed 144 no row over 9.
      for (final (seed, screen, name) in [(153, usersPhone, 'wide'), (144, usersPhone, 'short'), (144, ipadPortrait, 'tablet')]) {
        for (final landscape in [false, true]) {
          await show(tester, p, IkkiuchiStrikesPage(rating: 2000, seed: seed, landscape: landscape), screen: screen);
          await tester.pump(frame);
          expect(tester.takeException(), isNull);
          final s = scene(tester);
          expect(s.layout.cards.map((c) => 2 * c.box.hw), everyElement(closeTo(s.layout.cardW, 1e-6)));
          if (name == 'tablet' && !landscape) {
            expect(s.layout.cardW, IkkiuchiBoardStyle.maxCardW, reason: 'a tablet grows the cards to their widest');
          }
          await capture(tester, 'strikes_${name}_${landscape ? 'landscape' : 'portrait'}');
        }
      }

      // A hit on the tablet's large cards.
      await show(tester, p, const IkkiuchiStrikesPage(rating: 2000, seed: 144), screen: ipadPortrait);
      await tester.pump(frame);
      await tester.tap(find.text('Strike now'));
      await onlyMove(tester, 'smear');
      final s = scene(tester);
      await tapBoard(tester, s.board.cards.card(playerCard(s)).box.centre);
      await tester.pump(frame);
      final strike = s.board.runs.last.strike;
      await pumpTo(tester, strike.hitAt + strike.hitStop / 2);
      await capture(tester, 'strikes_tablet_hit');
      await pumpTo(tester, strike.end + 300);
      await capture(tester, 'strikes_tablet_after');
      expect(s.board.faults, isEmpty);
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

  group('The field', () {
    const frame = Duration(milliseconds: 16);
    IkkiuchiBoardScene scene(WidgetTester tester) =>
        tester.state<IkkiuchiFieldPageState>(find.byType(IkkiuchiFieldPage)).scene!;
    List<int> ids(IkkiuchiBoardScene s) => [for (final c in s.board.cards.cards) c.id];

    // The developer's button [label].
    Finder tool(String label) => find.descendant(of: find.byType(IkkiuchiFieldTools), matching: find.text(label));

    // Where board dp [at] is on the screen, through any turn of the board.
    Offset onScreen(WidgetTester tester, Vec at) =>
        tester.renderObject<RenderBox>(find.byType(IkkiuchiBoardView)).localToGlobal(Offset(at.x, at.y));

    // The screen's rect around what [finder] finds, through any turn.
    Rect screenRect(WidgetTester tester, Finder finder) =>
        Rect.fromPoints(tester.getTopLeft(finder), tester.getBottomRight(finder));

    // The screen's rect around [rect] on the board.
    Rect boardRectOnScreen(WidgetTester tester, Rect rect) =>
        Rect.fromPoints(onScreen(tester, Vec(rect.left, rect.top)), onScreen(tester, Vec(rect.right, rect.bottom)));

    // The screen's rect around [box] on the board.
    Rect rectOnScreen(WidgetTester tester, CardBox box) {
      final corners = [for (final c in box.corners) onScreen(tester, c)];
      return Rect.fromPoints(
        Offset(corners.map((c) => c.dx).reduce(math.min), corners.map((c) => c.dy).reduce(math.min)),
        Offset(corners.map((c) => c.dx).reduce(math.max), corners.map((c) => c.dy).reduce(math.max)),
      );
    }

    // Every system UI mode the page asks for, in order.
    List<String> watchBars(WidgetTester tester) {
      final modes = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setEnabledSystemUIMode') modes.add(call.arguments as String);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
      return modes;
    }

    testWidgets('fills the screen with Tobi and both sides, a card marked and read, the bars hidden while open',
        (tester) async {
      final p = await open(tester);
      final bars = watchBars(tester);
      for (final landscape in [false, true]) {
        await show(tester, p, IkkiuchiFieldPage(seed: 3, landscape: landscape));
        await tester.pump(frame);
        expect(tester.takeException(), isNull);
        expect(find.byType(AppBar), findsNothing);
        final s = scene(tester);
        final why = landscape ? 'landscape' : 'portrait';
        expect(s.layout.landscape, landscape);
        expect(tester.getSize(find.byType(IkkiuchiBoardView)), landscape ? usersPhone.size.flipped : usersPhone.size,
            reason: '$why: the board is the whole screen');
        expect(find.byType(RotatedBox), landscape ? findsOneWidget : findsNothing);
        for (final side in IkkiuchiSide.values) {
          expect(s.board.cards.cards.where((c) => c.side == side), hasLength(IkkiuchiToolsTuning.dealPerSide),
              reason: '$why: ${side.name}');
        }
        final tobi = s.layout.tobi;
        final tops = s.layout.cards.map((c) => c.box.centre.y - c.box.hh);
        expect(tobi.origin.y, greaterThanOrEqualTo(0), reason: '$why: Tobi on the board');
        if (!landscape) expect(tobi.feet.y, lessThan(tops.reduce(math.min)), reason: 'Tobi stands above his side');
        final marked = s.marked;
        expect(s.board.field.keys, contains(marked));
        expect(s.kimariji, poems[marked!].kimariji, reason: '$why: the band reads the marked card');
        for (final part in [IkkiuchiCallLayer, IkkiuchiColumnLayer]) {
          expect(find.byType(part), landscape ? findsOneWidget : findsNothing,
              reason: "$why: the match's own parts in landscape");
        }
        for (final label in ['R', ...IkkiuchiToolsTuning.fieldCounts.map((n) => '$n'), '^', 'v']) {
          final button = screenRect(tester, tool(label));
          for (final c in s.layout.cards) {
            expect(button.overlaps(rectOnScreen(tester, c.box)), isFalse, reason: '$why: $label clear of card ${c.id}');
          }
          if (!landscape) continue;
          expect(button.overlaps(screenRect(tester, find.byType(IkkiuchiMatchColumn))), isFalse,
              reason: '$label clear of the game column');
          expect(button.overlaps(boardRectOnScreen(tester, s.layout.band.inflate(IkkiuchiCallStyle.bleed))), isFalse,
              reason: '$label clear of the call');
        }
        await capture(tester, 'field_$why');
      }
      expect(bars, ['SystemUiMode.immersiveSticky', 'SystemUiMode.edgeToEdge', 'SystemUiMode.immersiveSticky']);
      await tester.pumpWidget(const SizedBox());
      expect(bars.last, 'SystemUiMode.edgeToEdge', reason: 'the bars come back on leaving');
    });

    testWidgets('a number deals anew with that many cards a side and R turns the board', (tester) async {
      final p = await open(tester);
      await show(tester, p, const IkkiuchiFieldPage(seed: 3, landscape: false));
      await tester.pump(frame);
      final first = ids(scene(tester));
      expect(first, hasLength(2 * IkkiuchiToolsTuning.dealPerSide));
      for (final n in IkkiuchiToolsTuning.fieldCounts) {
        await tester.tap(tool('$n'));
        await tester.pump(frame);
        for (final side in IkkiuchiSide.values) {
          expect(scene(tester).board.cards.cards.where((c) => c.side == side), hasLength(n), reason: '$n: ${side.name}');
        }
      }
      await tester.tap(tool('10'));
      await tester.pump(frame);
      expect(ids(scene(tester)).toString(), isNot(first.toString()));
      await tester.tap(tool('5'));
      await tester.pump(frame);
      await capture(tester, 'field_5_portrait');
      await tester.tap(tool('R'));
      await tester.pump(frame);
      await capture(tester, 'field_5_landscape');
      await tester.tap(tool('R'));
      await tester.pump(frame);
      expect(scene(tester).marked, isNotNull, reason: 'a new deal marks a card');
      expect(scene(tester).layout.landscape, isFalse);
      await tester.tap(tool('R'));
      await tester.pump(frame);
      expect(scene(tester).layout.landscape, isTrue);
      expect(find.byType(RotatedBox), findsOneWidget, reason: 'only the board turns');
      expect(tester.getSize(find.byType(IkkiuchiBoardView)), usersPhone.size.flipped);
      await tester.tap(tool('15'));
      await tester.pump(frame);
      await capture(tester, 'field_15_landscape');
      await tester.tap(tool('R'));
      await tester.pump(frame);
      expect(scene(tester).layout.landscape, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a swipe knocks cards about; after the wait they glide home and another card is marked',
        (tester) async {
      final p = await open(tester);
      // Swipes from the band through the player's card nearest it and the
      // middle across, clear of the buttons at the band's end, three cards'
      // heights on, rendering [name] halfway.
      Future<IkkiuchiCard> swipe(String name) async {
        final s = scene(tester);
        final middle = s.layout.size.x / 2;
        double across(IkkiuchiCard c) => (c.home.centre.x - middle).abs();
        final player = s.board.cards.cards.where((c) => c.side == IkkiuchiSide.player).toList()
          ..sort((a, b) {
            final down = a.home.centre.y.compareTo(b.home.centre.y);
            return down != 0 ? down : across(a).compareTo(across(b));
          });
        final card = player.first;
        final reach = card.home.hh + IkkiuchiPhysicsTuning.finger * s.layout.cardW;
        final from = card.home.centre - Vec(0, reach + s.layout.band.height / 4);
        final gesture = await tester.startGesture(onScreen(tester, from));
        await tester.pump(frame);
        const moves = 8;
        for (var i = 1; i <= moves; i++) {
          await gesture.moveTo(onScreen(tester, from + Vec(0, 6 * card.home.hh * i / moves)));
          await tester.pump(frame);
          if (i == moves ~/ 2) await capture(tester, name);
        }
        await gesture.up();
        await tester.pump(frame);
        expect(card.movedFrom(card.home, dp: 2, radians: 0.02), isTrue, reason: '$name: the swipe knocked it');
        return card;
      }

      // Every card on its spot and at rest. The sim keeps positions in
      // single floats, as when the board was set out.
      bool allHome(IkkiuchiBoardScene s) => s.board.cards.cards.every((c) =>
          c.onBoard &&
          c.velocity.length < 1e-6 &&
          c.spin.abs() < 1e-6 &&
          c.box.centre.distanceTo(c.home.centre) < 1e-3 &&
          turnBetween(c.box.angle, c.home.angle).abs() < 1e-6);

      await show(tester, p, const IkkiuchiFieldPage(seed: 3, landscape: false));
      await tester.pump(frame);
      final s = scene(tester);
      final marked = s.marked;
      final card = await swipe('field_swipe');
      expect(s.board.cards.fingerOn, isFalse, reason: 'the finger leaves the board as it lifts');

      // A touch in the band during the wait starts it again.
      const wait = IkkiuchiPlayTuning.tidyWait, glide = IkkiuchiPlayTuning.tidyGlide;
      await tester.pump(wait * 0.6);
      await tester.tapAt(onScreen(tester, Vec(s.layout.band.left + s.layout.cardW, s.layout.band.center.dy)));
      await tester.pump(wait * 0.6);
      expect(s.board.cards.gliding, isFalse, reason: 'still waiting');
      expect(card.movedFrom(card.home, dp: 2, radians: 0.02), isTrue);
      expect(s.marked, marked);
      await tester.pump(wait * 0.5);
      expect(s.board.cards.gliding, isTrue, reason: 'on the way home once the wait is over');
      await tester.pump(glide);
      await tester.pump(frame);
      expect(s.board.cards.gliding, isFalse);
      expect(allHome(s), isTrue, reason: 'every card back on its spot');
      expect(s.marked, isNot(marked), reason: 'another card marked');
      expect(s.kimariji, poems[s.marked!].kimariji);

      // The same in landscape, where the board lies turned under the finger.
      await tester.tap(tool('R'));
      await tester.pump(frame);
      final turned = scene(tester);
      expect(turned.layout.landscape, isTrue);
      await swipe('field_swipe_landscape');
      await tester.pump(wait);
      await tester.pump(glide);
      await tester.pump(frame);
      expect(allHome(turned), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the read card turns green once taken; ^ sends Tobi a card and v has him send one to place',
        (tester) async {
      final p = await open(tester);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(language: 'ja')));
      for (final landscape in [false, true]) {
        final o = landscape ? 'landscape' : 'portrait';
        await show(tester, p, IkkiuchiFieldPage(seed: 8, landscape: landscape));
        await tester.pump(frame);
        final s = scene(tester);

        // A touch on the read card takes it: its outline turns green until
        // the board has settled and another card is read.
        final read = s.marked!;
        final at = s.board.cards.card(read).box.centre;
        final touch = await tester.startGesture(onScreen(tester, at));
        await tester.pump(frame);
        await touch.up();
        await tester.pump(frame);
        expect(s.board.take?.card, read, reason: '$o: taken by the touch');
        expect(s.board.take?.way, IkkiuchiTakeWay.touched);
        await capture(tester, 'field_taken_$o');
        await tester.pump(IkkiuchiPlayTuning.tidyWait);
        await tester.pump(IkkiuchiPlayTuning.tidyGlide);
        await tester.pump(frame);
        expect(s.board.take, isNull, reason: '$o: a new read');
        expect(s.marked, isNot(read));

        // ^: the player drags a card of theirs across the band to Tobi.
        await tester.tap(tool('^'));
        await tester.pump(frame);
        expect(s.send.stage, IkkiuchiSendStage.sending);
        expect(s.marked, isNull, reason: '$o: no card read while sending');
        expect(find.text('送り札'), findsOneWidget, reason: '$o: the band says so, or in landscape the call strip');
        expect(find.text(landscape ? '1枚​トビへ​送る' : '自分の​札を​1枚、​トビの​陣へ​ドラッグ'), findsOneWidget,
            reason: o);
        final sent = s.sides!.player[0].left.last;
        final from = s.board.cards.card(sent).box.centre;
        final drag = await tester.startGesture(onScreen(tester, from));
        await tester.pump(frame);
        // The card rides above the finger: just past the band, it is over
        // his side.
        final over = Vec(from.x, s.layout.band.top + s.layout.cardW / 2);
        for (var i = 1; i <= 6; i++) {
          await drag.moveTo(onScreen(tester, from.lerp(over, i / 6)));
          await tester.pump(frame);
        }
        expect(s.send.overTobi, isTrue, reason: o);
        expect(find.byType(PlacingRiding), findsOneWidget);
        await capture(tester, 'field_send_drag_$o');
        await drag.up();
        await tester.pump(frame);
        expect(s.sides!.tobiCards, contains(sent), reason: '$o: his now');
        await tester.pump(IkkiuchiPlayTuning.relayoutGlide);
        await tester.pump(frame);
        final home = s.layout.cards.firstWhere((c) => c.id == sent).box;
        expect(s.board.cards.card(sent).box.centre.distanceTo(home.centre), lessThan(1e-3),
            reason: '$o: at its home on his side');
        expect(s.marked, isNotNull, reason: '$o: the reading goes on');

        // v: Tobi's arm carries a card of his to the waiting spot.
        await tester.tap(tool('v'));
        await tester.pump(frame);
        expect(s.send.stage, IkkiuchiSendStage.carrying);
        final carry = s.board.carry!;
        await tester.pump(Duration(milliseconds: (carry.pickAt + carry.setAt) ~/ 2));
        await capture(tester, 'field_tobi_carries_$o');
        await tester.pump(Duration(milliseconds: carry.end.ceil()));
        await tester.pump(IkkiuchiPlayTuning.relayoutGlide);
        await tester.pump(frame);
        expect(s.send.stage, IkkiuchiSendStage.waiting, reason: o);
        expect(find.byType(PlacingStack), findsOneWidget, reason: '$o: his card waits');
        expect(find.text('どうぞ！'), findsOneWidget);
        expect(find.text('トビからの​札を​置く'), findsOneWidget, reason: '$o: on the band, or the call strip');
        expect(find.byType(PlacingSpots), findsOneWidget);
        final wait = s.wait;
        final corners = [
          for (final c in [wait.topLeft, wait.bottomRight]) onScreen(tester, Vec(c.dx, c.dy)),
        ];
        final balloon = screenRect(tester, find.byType(SpeechBalloon));
        for (final label in ['R', ...IkkiuchiToolsTuning.fieldCounts.map((n) => '$n'), '^', 'v']) {
          final button = screenRect(tester, tool(label));
          expect(button.overlaps(Rect.fromPoints(corners[0], corners[1])), isFalse,
              reason: '$o: $label clear of the waiting card');
          expect(button.overlaps(balloon), isFalse, reason: "$o: $label clear of Tobi's balloon");
        }
        await capture(tester, 'field_tobi_sent_$o');

        // The player drags it onto a spot; the landing tag names the spot.
        final card = s.send.card!;
        final (_, spot) = s.send.targets().freeSpots.first;
        final place = await tester.startGesture(onScreen(tester, Vec(wait.center.dx, wait.center.dy)));
        await tester.pump(frame);
        final target = Vec(spot.x + spot.w / 2, spot.y + spot.h / 2);
        final start = Vec(wait.center.dx, wait.center.dy);
        for (var i = 1; i <= 6; i++) {
          await place.moveTo(onScreen(tester, start.lerp(target, i / 6)));
          await tester.pump(frame);
        }
        expect(s.send.drag?.spot, isNotNull, reason: o);
        expect(tester.widget<PlacingRiding>(find.byType(PlacingRiding)).landing, isNotNull);
        expect(find.byType(PlacingLanding), findsOneWidget);
        await capture(tester, 'field_placing_$o');
        await place.up();
        await tester.pump(frame);
        expect(s.send.active, isFalse, reason: '$o: placed');
        expect(s.sides!.playerCards, contains(card));
        await tester.pump(IkkiuchiPlayTuning.relayoutGlide);
        await tester.pump(frame);
        await capture(tester, 'field_placed_$o');
        expect(s.marked, isNotNull, reason: '$o: the reading goes on');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
    // A seed whose deal has a card of [long] sounds and one of [short], as
    // the page deals it.
    int seedWith({required int long, required int short}) {
      for (var seed = 0;; seed++) {
        final deck = [for (final p in poems.all) p.id]..shuffle(math.Random(seed));
        final dealt = deck.take(2 * IkkiuchiToolsTuning.dealPerSide).map((id) => poems[id].kimariji.length);
        if (dealt.contains(long) && dealt.contains(short)) return seed;
      }
    }

    // Runs the page on [ms] in frames, as a phone would.
    Future<void> run(WidgetTester tester, double ms) async {
      for (var t = 0.0; t < ms; t += frame.inMilliseconds) {
        await tester.pump(frame);
      }
    }

    // The words the call strip shows now; none while it fades out.
    String stripWords(WidgetTester tester) {
      final strip = find.byType(IkkiuchiCallStrip);
      if (tester.widget<AnimatedOpacity>(find.descendant(of: strip, matching: find.byType(AnimatedOpacity))).opacity == 0) {
        return '';
      }
      return [for (final t in tester.widgetList<Text>(find.descendant(of: strip, matching: find.byType(Text)))) t.data].join();
    }

    IkkiuchiMatchColumn column(WidgetTester tester) => tester.widget(find.byType(IkkiuchiMatchColumn));

    testWidgets('landscape reads the kimariji kana by kana in the gap, centred on the field', (tester) async {
      final p = await open(tester);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(language: 'ja')));
      await show(tester, p, IkkiuchiFieldPage(seed: seedWith(long: 6, short: 1)));
      await tester.pump(frame);
      final s = scene(tester);
      final context = tester.element(find.byType(IkkiuchiBoardView));
      for (final length in [6, 1]) {
        final id = s.board.field.keys.firstWhere((id) => poems[id].kimariji.length == length);
        final call = IkkiuchiReader.callFor(context, id);
        s.callCard(id, kimarijiFor(context, id), call: call);
        await tester.pump();
        expect(s.marked, id, reason: 'the card read stays marked');
        expect(call.sounds, hasLength(length));
        expect(stripWords(tester), isEmpty, reason: 'nothing yet: the old call cleared');
        // The clock stepped to just before each sound, then onto it.
        var at = 0.0;
        Future<void> stepTo(double ms) async {
          await tester.pump(Duration(microseconds: ((ms - at) * Duration.microsecondsPerMillisecond).round()));
          at = ms;
        }

        for (var i = 0; i < length; i++) {
          final onset = call.onsets[i];
          await stepTo(onset - 1);
          expect(stripWords(tester), call.sounds.take(i).join(), reason: '$length: just before sound ${i + 1}');
          await stepTo(onset);
          expect(stripWords(tester), call.sounds.take(i + 1).join(), reason: '$length: sound ${i + 1} heard');
          if (length == 6 && i == 2) {
            await run(tester, IkkiuchiCallStyle.kanaIn.inMilliseconds / 2);
            await capture(tester, 'field_reading_landscape');
            at += (IkkiuchiCallStyle.kanaIn.inMilliseconds / 2 / frame.inMilliseconds).ceil() * frame.inMilliseconds;
          }
        }
        await run(tester, IkkiuchiCallStyle.kanaIn.inMilliseconds * 2.0);
        expect(stripWords(tester), poems[id].kimariji);

        // In the gap, reaching no more than its bleed into the rows, and
        // centred on the field.
        final band = s.layout.band;
        const bleed = IkkiuchiCallStyle.bleed;
        expect(bleed, inInclusiveRange(2, 3));
        expect(tester.getSize(find.byType(IkkiuchiCallStrip)).height, closeTo(band.height + 2 * bleed, 1e-6));
        final centre = tester.getCenter(find.byType(IkkiuchiCallStrip));
        final want = onScreen(tester, Vec(s.layout.field.center.dx, band.center.dy));
        expect((centre - want).distance, lessThan(0.5), reason: '$length: centred on the field');
        await capture(tester, 'field_kimariji_${length}_landscape');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('landscape: the column counts each side, 終了 deals anew only once held, 並べ替え waits out a 送り札',
        (tester) async {
      final p = await open(tester);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(language: 'ja')));
      await show(tester, p, const IkkiuchiFieldPage(seed: 8));
      await tester.pump(frame);
      var s = scene(tester);
      const per = IkkiuchiToolsTuning.dealPerSide;
      expect((column(tester).tobi, column(tester).player), (per, per));
      expect(find.descendant(of: find.byType(IkkiuchiMatchColumn), matching: find.text('$per')), findsNWidgets(2));
      expect(find.text('トビ'), findsOneWidget);
      expect(find.text('あなた'), findsOneWidget);

      // The column at the right edge, the field left of it.
      final edge = s.layout.column!;
      expect(edge.right, closeTo(s.layout.size.x - IkkiuchiColumnStyle.edge, 1e-6));
      expect(s.layout.field.right, lessThan(edge.left));

      // Tobi sends a card: it counts as the player's at once, and 並べ替え
      // takes no tap until it is placed.
      await tester.tap(tool('v'));
      await tester.pump(frame);
      expect(s.send.stage, IkkiuchiSendStage.carrying);
      await tester.pump(frame);
      expect((column(tester).tobi, column(tester).player), (per - 1, per + 1));
      expect(column(tester).onArrange, isNull, reason: 'greyed while a 送り札 goes on');
      await tester.pump(Duration(milliseconds: s.board.carry!.end.ceil()));
      await tester.pump(IkkiuchiPlayTuning.relayoutGlide);
      await tester.pump(frame);
      expect(s.send.stage, IkkiuchiSendStage.waiting);
      expect(column(tester).onArrange, isNull, reason: 'greyed while his card waits');
      await tester.tap(find.text('並べ替え'), warnIfMissed: false);
      await tester.pump(frame);
      expect(s.arrange.active, isFalse);
      await capture(tester, 'field_sent_column_landscape');
      final (spot, _) = s.send.targets().freeSpots.first;
      await tester.tapAt(onScreen(tester, Vec(s.send.rectOf(spot)!.center.dx, s.send.rectOf(spot)!.center.dy)));
      await tester.pump(frame);
      expect(s.send.active, isFalse, reason: 'placed');
      await tester.pump(IkkiuchiPlayTuning.relayoutGlide);
      await tester.pump(frame);
      expect((column(tester).tobi, column(tester).player), (per - 1, per + 1));
      expect(column(tester).onArrange, isNotNull, reason: 'free again');

      // 終了: a tap or a short hold does nothing; held through, a new deal.
      final end = tester.getCenter(find.byType(HoldToConfirmButton));
      await tester.tapAt(end);
      await tester.pump(frame);
      expect(scene(tester), same(s), reason: 'a tap ends nothing');
      final short = await tester.startGesture(end);
      await run(tester, IkkiuchiMatchTuning.endHold.inMilliseconds / 2);
      await capture(tester, 'field_end_held_landscape');
      await short.up();
      await run(tester, IkkiuchiMatchTuning.endHold.inMilliseconds.toDouble());
      expect(scene(tester), same(s), reason: 'let go early, nothing ends');
      final held = await tester.startGesture(end);
      await run(tester, IkkiuchiMatchTuning.endHold.inMilliseconds + 100.0);
      await held.up();
      await tester.pump(frame);
      expect(scene(tester), isNot(same(s)), reason: 'held through, the field is dealt anew');
      s = scene(tester);
      expect((column(tester).tobi, column(tester).player), (per, per));
      expect(s.marked, isNotNull, reason: 'and a card read');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('landscape: 並べ替え moves a placed card to a free spot, and 完了 lets the reading go on',
        (tester) async {
      final p = await open(tester);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(language: 'ja')));
      await show(tester, p, const IkkiuchiFieldPage(seed: 8));
      await tester.pump(frame);
      final s = scene(tester);
      final before = s.sides!.playerCards.toSet();
      await tester.tap(find.text('並べ替え'));
      await tester.pump(frame);
      expect(s.arrange.active, isTrue);
      expect(s.marked, isNull, reason: 'nothing read meanwhile');
      expect(find.text('並べ替え中'), findsOneWidget, reason: 'the call strip says so');
      expect(find.text('完了'), findsOneWidget, reason: '並べ替え turns 完了');
      expect(find.byType(PlacingSpots), findsOneWidget);
      expect(column(tester).onArrange, isNull);
      await tester.tap(tool('v'));
      await tester.pump(frame);
      expect(s.send.active, isFalse, reason: 'no 送り札 while arranging');

      // Drag the outer card of a group to a free spot in another row.
      final card = s.sides!.player.expand((r) => [if (r.right.isNotEmpty) r.right.first]).first;
      final from = s.sides!.playerBoard.side.placeOf(card)!;
      final (spot, rect) = s.arrange.spots
          .targets(moving: card)
          .freeSpots
          .firstWhere((e) => (e.$1 as ClusterEnd).row != from.row);
      final start = s.board.cards.card(card).box.centre;
      final drag = await tester.startGesture(onScreen(tester, start));
      await tester.pump(frame);
      expect(s.board.cards.fingerOn, isFalse, reason: "the finger doesn't push the cards meanwhile");
      final target = Vec(rect.x + rect.w / 2, rect.y + rect.h / 2);
      for (var i = 1; i <= 8; i++) {
        await drag.moveTo(onScreen(tester, start.lerp(target, i / 8)));
        await tester.pump(frame);
      }
      expect(s.arrange.drag?.spot, spot);
      expect(find.byType(PlacingLanding), findsOneWidget);
      expect(tester.widget<PlacingRiding>(find.byType(PlacingRiding)).landing, isNotNull);
      await capture(tester, 'field_arrange_landscape');
      await drag.up();
      await tester.pump(frame);
      final to = (spot as ClusterEnd);
      final now = s.sides!.playerBoard.side.placeOf(card)!;
      expect((now.row, now.part), (to.row, to.part), reason: 'moved to the spot');
      expect(s.sides!.playerCards.toSet(), before, reason: 'the same cards');
      await tester.pump(IkkiuchiPlayTuning.relayoutGlide);
      await tester.pump(frame);
      expect(s.marked, isNull, reason: 'still arranging once the cards are home');
      await capture(tester, 'field_arranged_landscape');

      await tester.tap(find.text('完了'));
      await tester.pump(frame);
      await tester.pump(frame);
      expect(s.arrange.active, isFalse);
      expect(find.text('並べ替え'), findsOneWidget);
      expect(s.marked, isNotNull, reason: 'the reading goes on');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('landscape fits a small phone and a tablet', (tester) async {
      final p = await open(tester);
      await tester.runAsync(() => p.updateSettings(p.settings.copyWith(language: 'ja')));
      const small = Screen('360 short', Size(360, 640), 3);
      for (final (screen, name) in [(small, 'small'), (ipadPortrait, 'tablet')]) {
        await show(tester, p, const IkkiuchiFieldPage(seed: 8), screen: screen);
        await tester.pump(frame);
        expect(tester.takeException(), isNull, reason: '$name: nothing overflows');
        final s = scene(tester);
        final board = Offset.zero & Size(s.layout.size.x, s.layout.size.y);
        expect(board.contains(s.layout.column!.topLeft) && board.contains(s.layout.column!.bottomRight), isTrue);
        final columnRect = screenRect(tester, find.byType(IkkiuchiMatchColumn));
        for (final part in [find.byType(HoldToConfirmButton), find.text('並べ替え'), find.text('あなた')]) {
          final r = screenRect(tester, part);
          expect(columnRect.inflate(1).contains(r.topLeft) && columnRect.inflate(1).contains(r.bottomRight), isTrue,
              reason: '$name: in the column');
        }
        for (final label in ['R', '25', 'v']) {
          final button = screenRect(tester, tool(label));
          expect(button.overlaps(columnRect), isFalse, reason: '$name: $label clear of the column');
          for (final c in s.layout.cards) {
            expect(button.overlaps(rectOnScreen(tester, c.box)), isFalse, reason: '$name: $label clear of card ${c.id}');
          }
        }
        await run(tester, 2000);
        await capture(tester, 'field_${name}_landscape');
        await tester.tap(tool('v'));
        await run(tester, 3000);
        expect(s.send.stage, IkkiuchiSendStage.waiting);
        expect(tester.takeException(), isNull, reason: '$name: nothing overflows');
        await capture(tester, 'field_${name}_sent_landscape');
      }
      await tester.pumpWidget(const SizedBox());
    });
  });
}
