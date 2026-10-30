// The guides lay out and scroll to their end without overflow on two phones
// (384 dp, and 360 dp at font scale 1.3), in both languages and both kana
// settings. With RENDER_SCREENS=1 they are written, a screen at a time, to
// build/screens/guides/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/l10n/articles.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/l10n/teiichi_strings.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/help/guide_screen.dart';
import 'package:fudatobashi/ui/manga/manga.dart';

import 'test_card_pages.dart';
import 'test_screens.dart';

const _phones = [(usersPhone, 1.0), (narrowPhone, 1.3)];

/// Each guide, by its article, as its screen opens it.
final _guides = <String, GuideScreen Function(S s)>{
  Articles.teiichiGuide: (s) =>
      GuideScreen(article: Articles.teiichiGuide, title: s.teiichiGuideTitle, sub: s.sub?.teiichiGuideTitle),
};

void main() {
  loadCardPageData();
  setUpAll(loadAppFonts);

  for (final MapEntry(key: article, value: guide) in _guides.entries) {
    for (final lang in ['en', 'ja']) {
      for (final (phone, textScale) in _phones) {
        for (final script in [KimarijiScript.hiragana, KimarijiScript.romaji]) {
          final tag = '${lang}_${phone.name}_${textScale}_${script.name}';
          testWidgets('the $article guide scrolls to its end without overflow ($tag)', (tester) async {
            await loadCardArt(tester);
            final p = await openPlayer(tester, lang);
            await tester.runAsync(() async {
              await p.updateSettings(p.settings.copyWith(kimarijiScript: script));
              await Articles.load(lang, article);
              await ArticlePictures.load();
            });
            await showPage(tester, p, guide(S(lang)), screen: phone, textScale: textScale);
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
            await settle(tester);
            expect(find.byType(MarkdownProse), findsOneWidget);

            final page = find.descendant(of: find.byType(GuideScreen), matching: find.byType(Scrollable)).first;
            var end = false;
            for (var i = 0; i < 60 && !end; i++) {
              await captureScreen(tester, 'guides/$article',
                  lang: lang, variant: '${script.name}_step${i.toString().padLeft(2, '0')}');
              final before = tester.state<ScrollableState>(page).position.pixels;
              await tester.drag(page, Offset(0, -phone.size.height * 0.6));
              await settle(tester);
              end = tester.state<ScrollableState>(page).position.pixels == before;
            }
            expect(end, isTrue, reason: 'scrolled to the end');
            await tester.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
