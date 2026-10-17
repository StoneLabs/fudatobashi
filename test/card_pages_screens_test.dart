// Lays out the card browser, two cards' About pages, First sounds and Help
// on three phones (384 dp, 360 dp, and 360 dp at font scale 1.3) in both
// languages, failing on any layout error. With RENDER_SCREENS=1 it writes
// each screen to build/screens/cards/ for visual checks.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/card_info_strings.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/ui/cards/about_card_screen.dart';
import 'package:fudatobashi/ui/cards/card_browser_screen.dart';
import 'package:fudatobashi/ui/cards/card_panel.dart';
import 'package:fudatobashi/ui/cards/first_sounds_screen.dart';
import 'package:fudatobashi/ui/help/help_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';

import 'test_card_pages.dart';

final _render = Platform.environment['RENDER_SCREENS'] == '1';

const _phones = [(Size(384, 832), 1.0), (Size(360, 780), 1.0), (Size(360, 780), 1.3)];

void main() {
  loadCardPageData();
  setUpAll(loadAppFonts);

  for (final lang in ['en', 'ja']) {
    final s = S(lang);
    for (final (size, textScale) in _phones) {
      final tag = '${lang}_${size.width.round()}${textScale == 1 ? '' : '_scaled'}';
      Future<void> shot(WidgetTester tester, String name) async {
        expect(tester.takeException(), isNull);
        if (_render) await capture(tester, '${name}_$tag');
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
        await showPage(tester, p, const CardBrowserScreen(), size: size, textScale: textScale);
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
          await showPage(tester, p, AboutCardScreen(poemId: id), size: size, textScale: textScale);
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

      testWidgets('First sounds and Help ($tag)', (tester) async {
        final p = await openPlayer(tester, lang);
        await showPage(tester, p, const FirstSoundsScreen(), size: size, textScale: textScale);
        await shot(tester, 'first_sounds');
        await showPage(tester, p, const HelpScreen(), size: size, textScale: textScale);
        await shot(tester, 'help');
      });
    }
  }
}
