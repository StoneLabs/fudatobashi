// Lays out the card browser, two cards' and the 序歌's About pages, First
// sounds and Help on three phones (384 dp, 360 dp, and 360 dp at font scale
// 1.3) in both languages, failing on any layout error. With RENDER_SCREENS=1
// it writes each screen to build/screens/cards/ for visual checks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/articles.dart';
import 'package:fudatobashi/l10n/card_info_strings.dart';
import 'package:fudatobashi/l10n/first_sounds_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/cards/about_card_screen.dart';
import 'package:fudatobashi/ui/cards/card_browser_screen.dart';
import 'package:fudatobashi/ui/cards/card_panel.dart';
import 'package:fudatobashi/ui/help/guide_screen.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';

import 'test_card_pages.dart';
import 'test_screens.dart';

const _phones = [(usersPhone, 1.0), (narrowPhone, 1.0), (narrowPhone, 1.3)];

void main() {
  loadCardPageData();
  setUpAll(loadAppFonts);

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    for (final (phone, textScale) in _phones) {
      final tag = '${lang}_${phone.name}${textScale == 1 ? '' : '_scaled'}';
      Future<void> shot(WidgetTester tester, String name, {String? variant}) async {
        expect(tester.takeException(), isNull);
        await captureScreen(tester, 'cards/$name', lang: lang, variant: variant);
      }

      Future<void> scrollTo(WidgetTester tester, Finder target) async {
        await tester.ensureVisible(target);
        await tester.pump();
        final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).last);
        final top = tester.getTopLeft(target).dy - tester.getTopLeft(find.byType(Scrollable).last).dy;
        scrollable.position.jumpTo(
            (scrollable.position.pixels + top).clamp(0.0, scrollable.position.maxScrollExtent));
        await settle(tester);
      }

      testWidgets('card browser: all cards, a search, no match ($tag)', (tester) async {
        await loadCardArt(tester);
        final p = await openPlayer(tester, lang);
        await showPage(tester, p, const CardBrowserScreen(), screen: phone, textScale: textScale);
        await shot(tester, 'browser');
        await tester.enterText(find.byType(TextField), 'わ');
        await settle(tester);
        await shot(tester, 'browser_search');
        await tester.enterText(find.byType(TextField), 'ぱ');
        await settle(tester);
        expect(find.text(s.cardSearchClear), findsOneWidget);
        await shot(tester, 'browser_none');
      });

      for (final id in [1, 20]) {
        testWidgets('About #$id: both cards, the ladder and the explanation ($tag)', (tester) async {
          await loadCardArt(tester);
          final p = await openPlayer(tester, lang);
          await showPage(tester, p, AboutCardScreen(poemId: id), screen: phone, textScale: textScale);
          await shot(tester, 'about${id}_taking');
          if (id == 1) {
            await tester.tap(find.textContaining(s.aboutReadingCard).first);
          } else {
            await tester.drag(find.descendant(of: find.byType(CardPanel), matching: find.byType(TorifudaCard)),
                const Offset(-120, 0));
          }
          await settle(tester);
          await shot(tester, 'about${id}_reading');
          await scrollTo(tester, find.textContaining(s.aboutSimilar));
          await shot(tester, 'about${id}_ladder');
          await scrollTo(tester, find.textContaining(s.aboutPoemPart));
          await shot(tester, 'about${id}_explanation');
          await scrollTo(tester, find.byType(LinkRow));
          await shot(tester, 'about${id}_end');
        });
      }

      testWidgets('About the 序歌: its reading card and key, its name, the poem, its facts and explanation, '
          'in English also in kana ($tag)', (tester) async {
        await loadCardArt(tester);
        final p = await openPlayer(tester, lang);
        for (final kana in [false, if (!s.ja) true]) {
          final variant = kana ? 'kana' : null;
          if (kana) await p.updateSettings(p.settings.copyWith(kimarijiScript: KimarijiScript.hiragana));
          await showPage(tester, p, const AboutCardScreen.joka(), screen: phone, textScale: textScale);
          await shot(tester, 'about_joka', variant: variant);
          await scrollTo(tester, find.textContaining(s.aboutFacts));
          await shot(tester, 'about_joka_facts', variant: variant);
          await scrollTo(tester, find.textContaining(s.aboutPoemPart));
          await shot(tester, 'about_joka_explanation', variant: variant);
        }
      });

      testWidgets('First sounds, a screen at a time, and Help ($tag)', (tester) async {
        await loadCardArt(tester);
        final p = await openPlayer(tester, lang);
        await tester.runAsync(() => Articles.load(lang, Articles.kimarijiGuide));
        await showPage(
            tester,
            p,
            GuideScreen(article: Articles.kimarijiGuide, title: s.firstSoundsTitle, sub: s.other.firstSoundsTitle),
            screen: phone,
            textScale: textScale);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await settle(tester);
        final page = find.byType(Scrollable).first;
        var end = false;
        for (var i = 0; i < 40 && !end; i++) {
          await shot(tester, 'first_sounds', variant: 'step${i.toString().padLeft(2, '0')}');
          final before = tester.state<ScrollableState>(page).position.pixels;
          await tester.drag(page, Offset(0, -phone.size.height * 0.6));
          await settle(tester);
          end = tester.state<ScrollableState>(page).position.pixels == before;
        }
        expect(end, isTrue, reason: 'scrolled to the end');
        await showPage(tester, p, const HelpScreen(), screen: phone, textScale: textScale);
        await shot(tester, 'help');
      });
    }
  }
}
