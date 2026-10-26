// The card browser and a card's About page: how they open (Help, the
// new-card page, a card's stats page), the search, the previous / next
// cards, the ladder's chips, the switches and the card panel's swipe; the
// 序歌's row and page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/config/config.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/data/fuda_sets.dart';
import 'package:fudatobashi/data/joka.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/domain/card_stats.dart';
import 'package:fudatobashi/domain/sound_ladder.dart';
import 'package:fudatobashi/l10n/card_info_strings.dart';
import 'package:fudatobashi/l10n/results_strings.dart';
import 'package:fudatobashi/l10n/romaji.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/cards/about_card_screen.dart';
import 'package:fudatobashi/ui/cards/card_browser_screen.dart';
import 'package:fudatobashi/ui/cards/card_panel.dart';
import 'package:fudatobashi/ui/cards/first_sounds_screen.dart';
import 'package:fudatobashi/ui/cards/sound_ladder_view.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/results/celebrations.dart';
import 'package:fudatobashi/ui/results/new_card_overlay.dart';
import 'package:fudatobashi/ui/stats/card_detail_screen.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';
import 'package:fudatobashi/ui/torifuda/yomifuda_card.dart';

import 'test_card_pages.dart';

final _en = S('en');

/// The About page on top, for card [id].
Finder _aboutOf(int id) => find.byWidgetPredicate((w) => w is AboutCardScreen && w.poemId == id);

/// The front card in the panel: the last of its two cards to paint.
Finder _panelCard(Type type) => find.descendant(of: find.byType(CardPanel), matching: find.byType(type));

void main() {
  loadCardPageData();
  setUpAll(loadAppFonts);

  group('opening', () {
    testWidgets('Help › Card browser lists every card; a row opens its About page', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const HelpScreen());
      await tapOn(tester, find.text(_en.cardBrowserTitle));
      expect(find.byType(CardBrowserScreen), findsOneWidget);
      expect(find.text(_en.cardCountAll(100)), findsOneWidget);
      await tester.scrollUntilVisible(find.text('わび'), 300,
          scrollable: find.byType(Scrollable).first);
      await tapOn(tester, find.text('わび'));
      expect(_aboutOf(20), findsOneWidget);
      await tapOn(tester, find.bySemanticsLabel(_en.back).last);
      expect(find.byType(AboutCardScreen), findsNothing);
      expect(find.byType(CardBrowserScreen), findsOneWidget, reason: 'back returns to the browser');
    });

    testWidgets('the new-card page\'s "Learn about this card" opens the card\'s About page', (tester) async {
      final p = await openPlayer(tester, 'en');
      final card = poems.byKimariji('わび').id;
      await showPage(tester, p, NewCardOverlay(data: NewCardCelebration(card, fudaSets.tomofuda(card)), onNext: () {}));
      await tester.pump(const Duration(milliseconds: 1300));
      await tapOn(tester, find.text(_en.learnAboutCard));
      expect(_aboutOf(card), findsOneWidget);
    });

    testWidgets('a card\'s stats page links to its About page, which links back', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const CardDetailScreen(itemKey: ItemKey(20, false)));
      await tapOn(tester, find.text(_en.statsAboutCard));
      expect(_aboutOf(20), findsOneWidget);
      await tapOn(tester, find.text(_en.aboutMyRecord));
      expect(find.byType(CardDetailScreen, skipOffstage: false), findsNWidgets(2),
          reason: 'My record opens the stats page again');
    });
  });

  group('search', () {
    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(find.byType(TextField), query);
      await settle(tester);
    }

    List<int> rows(WidgetTester tester) => [
          for (final e in tester.widgetList<Semantics>(find.descendant(
              of: find.byType(CardBrowserScreen),
              matching: find.byWidgetPredicate((w) => w is Semantics && (w.properties.label ?? '').contains(' ')))))
            ?int.tryParse(e.properties.label!.split(' ').first),
        ];

    testWidgets('a number, kana, romaji and the second half find their cards; nothing shows the empty state',
        (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const CardBrowserScreen());
      await search(tester, '2');
      expect(find.text(_en.cardCountFound(11, 100)), findsOneWidget, reason: '2 and 20–29');
      await search(tester, 'わ');
      expect(rows(tester), [8, 11, 20, 38, 54, 76, 92]);
      await search(tester, 'kimi');
      expect(rows(tester), [15, 50]);
      await search(tester, 'わがころもでは');
      expect(rows(tester), [1], reason: 'the second half, tagged');
      expect(find.descendant(of: find.byType(InkTag), matching: find.text(_en.cardShimoTag)), findsOneWidget);
      await search(tester, 'ぱ');
      expect(find.text(Phrases.span(_en.cardNoneTitle('ぱ')).toPlainText()), findsOneWidget);
      await search(tester, '101');
      expect(find.text(_en.cardNoneNumberTitle('101')), findsOneWidget);
      await tapOn(tester, find.text(_en.cardSearchClear));
      expect(find.text(_en.cardCountAll(100)), findsOneWidget, reason: 'Clear search shows every card again');
    });
  });

  group('序歌', () {
    /// A row of the browser by what a screen reader says for it: the 序歌's
    /// starts with its name.
    Finder row([String label = jokaTitle]) => find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label?.startsWith(label) ?? false));

    testWidgets('sits over card 1 with its reading card while nothing is searched', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const CardBrowserScreen());
      expect(row(), findsOneWidget);
      expect(tester.getCenter(row()).dy, lessThan(tester.getTopLeft(row('1 ${poems[1].kimariji}')).dy));
      expect(find.descendant(of: row(), matching: find.byType(YomifudaCard)), findsOneWidget);
      expect(find.descendant(of: row(), matching: find.byType(TorifudaCard)), findsNothing);
      expect(find.text(_en.cardCountAll(100)), findsOneWidget, reason: 'it is not one of the cards');
    });

    for (final lang in ['en', 'ja']) {
      for (final script in [KimarijiScript.hiragana, KimarijiScript.romaji]) {
        testWidgets('its row says what it is beside its name outside Japanese ($lang, ${script.name})',
            (tester) async {
          final s = S(lang);
          final p = await openPlayer(tester, lang);
          await p.updateSettings(p.settings.copyWith(kimarijiScript: script));
          await showPage(tester, p, const CardBrowserScreen());
          final texts = [
            for (final text in tester.widgetList<Text>(find.descendant(of: row(), matching: find.byType(Text))))
              text.data,
          ];
          expect(texts, [
            if (script == KimarijiScript.romaji) hepburn(jokaTitleKana),
            jokaTitle,
            if (!s.ja) s.cardJokaGloss,
          ]);
        });
      }
    }

    testWidgets('never shows in search results', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const CardBrowserScreen());
      for (final query in ['序', '序歌', 'じょか', 'joka', 'なにわ', 'naniwa', 'わに', 'wani', '0', '1']) {
        await tester.enterText(find.byType(TextField), query);
        await settle(tester);
        expect(row(), findsNothing, reason: query);
      }
      await tester.enterText(find.byType(TextField), '');
      await settle(tester);
      expect(row(), findsOneWidget, reason: 'back once the search is empty');
    });

    testWidgets('its row opens its page: the reading card alone, the poem, its facts with a note and explanation',
        (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const CardBrowserScreen());
      await tapOn(tester, row());
      final page = find.byWidgetPredicate((w) => w is AboutCardScreen && w.poemId == null);
      expect(page, findsOneWidget);
      Finder onPage(Finder finder) => find.descendant(of: page, matching: finder, skipOffstage: false);
      expect(onPage(find.descendant(of: find.byType(CardDesk), matching: find.byType(YomifudaCard))), findsOneWidget);
      for (final cardOnly in [CardPanel, TorifudaCard, PillSwitch<CardFace>, SoundLadderView, LinkRow]) {
        expect(onPage(find.byType(cardOnly, skipOffstage: false)), findsNothing, reason: '$cardOnly');
      }
      for (final text in [_en.aboutFirstHalf, _en.aboutSource, _en.aboutJokaNote, _en.aboutPoemPart]) {
        expect(onPage(find.text(text, skipOffstage: false)), findsOneWidget, reason: text);
      }
      final note = onPage(find.text(_en.aboutJokaNote, skipOffstage: false));
      expect(tester.getTopLeft(note).dy,
          greaterThan(tester.getBottomLeft(onPage(find.text(_en.aboutSource, skipOffstage: false))).dy),
          reason: 'the note is under the facts');
      expect(tester.getBottomLeft(note).dy,
          lessThan(tester.getTopLeft(onPage(find.text(_en.aboutPoemPart, skipOffstage: false))).dy));
      expect(onPage(find.text(_en.aboutPrevious, skipOffstage: false)), findsNothing);
      await tapOn(tester, find.bySemanticsLabel(_en.back).last);
      expect(find.byType(CardBrowserScreen), findsOneWidget, reason: 'back returns to the browser');
    });

    testWidgets('only its page has the note on what it is', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const AboutCardScreen(poemId: 1));
      expect(find.text(_en.aboutJokaNote, skipOffstage: false), findsNothing);
    });
  });

  group('About page', () {
    testWidgets('previous and next replace the page and wrap from 1 to 100', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const AboutCardScreen(poemId: 1));
      await tapOn(tester, find.textContaining(_en.aboutPrevious));
      expect(_aboutOf(100), findsOneWidget);
      expect(find.byType(AboutCardScreen), findsOneWidget, reason: 'replaced, not stacked');
      await tapOn(tester, find.textContaining(_en.aboutNext));
      expect(_aboutOf(1), findsOneWidget);
      expect(find.byType(AboutCardScreen), findsOneWidget);
    });

    testWidgets('a ladder chip opens that card; a long step folds behind "+N more"', (tester) async {
      final p = await openPlayer(tester, 'en');
      final poem = poems.byKimariji('きみがためは');
      await showPage(tester, p, AboutCardScreen(poemId: poem.id));
      final last = SoundLadder.of(poem, poems.all).last;
      expect(last.joining.length, greaterThan(SoundLadderTuning.foldAfter), reason: 'k- brings many cards');
      String chip(int id) => '${_en.kimariji(id)}\uFFFC$id';
      final folded = last.joining[SoundLadderTuning.foldTo];
      final more = find.text(_en.ladderMore(last.joining.length - SoundLadderTuning.foldTo));
      expect(more, findsOneWidget);
      expect(find.text(chip(folded)), findsNothing);
      await tapOn(tester, more);
      expect(more, findsNothing);
      expect(find.text(chip(folded)), findsOneWidget, reason: 'unfolded');
      final kiri = poems.byKimariji('きり').id;
      await tapOn(tester, find.text(chip(kiri)));
      expect(_aboutOf(kiri), findsOneWidget);
      await tapOn(tester, find.bySemanticsLabel(_en.back).last);
      expect(_aboutOf(poems.byKimariji('きみがためは').id), findsOneWidget, reason: 'back returns to the first card');
    });

    testWidgets('Read an explanation opens First sounds', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const AboutCardScreen(poemId: 20));
      await tapOn(tester, find.text(_en.aboutReadExplanation));
      expect(find.byType(FirstSoundsScreen), findsOneWidget);
      await tapOn(tester, find.bySemanticsLabel(_en.back).last);
      expect(find.byType(FirstSoundsScreen), findsNothing);
      expect(_aboutOf(20), findsOneWidget, reason: 'back returns to the card');
    });

    testWidgets('the Taking / Reading switch brings each card forward; the key shows with the reading card',
        (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const AboutCardScreen(poemId: 20));
      expect(find.byType(ReadingCardKey), findsNothing);
      await tapOn(tester, find.textContaining(_en.aboutReadingCard).first);
      expect(find.byType(ReadingCardKey), findsOneWidget);
      expect(tester.widget<CardPanel>(find.byType(CardPanel)).front, CardFace.reading);
      expect(p.settings.cardPanelSwiped, isFalse, reason: 'the switch is not a swipe');
      await tapOn(tester, find.textContaining(_en.aboutTakingCard).first);
      expect(find.byType(ReadingCardKey), findsNothing);
    });

    testWidgets('the poem starts in the player\'s script; Kana / Romaji switches it', (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const AboutCardScreen(poemId: 20));
      final romaji = find.text('wabinureba');
      final poemBox = find.ancestor(of: find.text(_en.aboutFirstHalf), matching: find.byType(MangaPanel));
      expect(romaji, findsOneWidget, reason: 'English shows romaji');
      await tapOn(tester, find.descendant(of: poemBox, matching: find.text(_en.aboutKana)));
      expect(romaji, findsNothing);
      expect(find.descendant(of: poemBox, matching: find.byType(RubyText)), findsWidgets);
      await p.updateSettings(p.settings.copyWith(kimarijiScript: KimarijiScript.hiragana));
      await showPage(tester, p, const AboutCardScreen(poemId: 20));
      expect(romaji, findsNothing, reason: 'the hiragana script starts in kana');
    });

    testWidgets('the Sounds / Kana switch changes the ladder and is kept', (tester) async {
      final p = await openPlayer(tester, 'en');
      final id = poems.byKimariji('きみがためは').id;
      await showPage(tester, p, AboutCardScreen(poemId: id));
      expect(find.text('kimigatameh-'), findsOneWidget, reason: 'the top step is the shortest sound');
      final ladderBar = find.ancestor(of: find.text(_en.aboutLadderSounds), matching: find.byType(Row)).first;
      await tapOn(tester, find.descendant(of: ladderBar, matching: find.text(_en.aboutLadderKana)));
      expect(p.settings.soundLadder, SoundLadderMode.kana);
      expect(find.text('kimigatameh-'), findsNothing);
      expect(find.text(_en.aboutLadderLeadKana), findsOneWidget);
      await showPage(tester, p, AboutCardScreen(poemId: id));
      expect(tester.widget<SoundLadderView>(find.byType(SoundLadderView)).kanaOnly, isTrue, reason: 'kept');
    });
  });

  group('card panel', () {
    testWidgets('a swipe past the throw distance swaps the cards and hides the SWIPE sticker for good',
        (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const AboutCardScreen(poemId: 20));
      AnimatedOpacity sticker() => tester
          .widget<AnimatedOpacity>(find.ancestor(of: find.text(_en.aboutSwipe), matching: find.byType(AnimatedOpacity)));
      expect(sticker().opacity, 1);

      await tester.drag(_panelCard(TorifudaCard), const Offset(-(CardPanelTuning.throwDistance - 10), 0));
      await settle(tester);
      expect(tester.widget<CardPanel>(find.byType(CardPanel)).front, CardFace.taking, reason: 'too short: it snaps back');
      expect(p.settings.cardPanelSwiped, isFalse);

      await tester.drag(_panelCard(TorifudaCard), const Offset(-(CardPanelTuning.throwDistance + 30), 0));
      await settle(tester);
      expect(tester.widget<CardPanel>(find.byType(CardPanel)).front, CardFace.reading);
      expect(p.settings.cardPanelSwiped, isTrue);
      expect(sticker().opacity, 0);

      await showPage(tester, p, const AboutCardScreen(poemId: 1));
      expect(sticker().opacity, 0, reason: 'once swiped, never shown again');
    });

    testWidgets('a drag follows the finger; a tap on the card behind swaps; an up-and-down drag scrolls',
        (tester) async {
      final p = await openPlayer(tester, 'en');
      await showPage(tester, p, const AboutCardScreen(poemId: 20));
      final card = _panelCard(TorifudaCard);
      final start = tester.getCenter(card);
      final gesture = await tester.startGesture(start);
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(-10, 0));
        await tester.pump();
      }
      expect(tester.getCenter(card).dx, moreOrLessEquals(start.dx - 60, epsilon: 1), reason: 'follows 1:1');
      await gesture.up();
      await settle(tester);
      expect(tester.widget<CardPanel>(find.byType(CardPanel)).front, CardFace.reading);

      final behind = tester.getCenter(_panelCard(TorifudaCard));
      await tester.tapAt(behind + const Offset(AboutCardLayout.cardWidth * 0.38, 0));
      await settle(tester);
      expect(tester.widget<CardPanel>(find.byType(CardPanel)).front, CardFace.taking, reason: 'the card behind came forward');

      final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
      await tester.drag(_panelCard(TorifudaCard), const Offset(0, -200));
      await settle(tester);
      expect(scroll.position.pixels, greaterThan(100), reason: 'the page scrolled');
      expect(tester.widget<CardPanel>(find.byType(CardPanel)).front, CardFace.taking, reason: 'no swap');
    });
  });
}
