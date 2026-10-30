import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../manga/manga.dart';

/// Opens 定位置's guide ([TeiichiGuideScreen]).
Future<void> openTeiichiGuide(BuildContext context) =>
    Navigator.of(context).push(MangaRoute<void>(builder: (_) => const TeiichiGuideScreen()));

/// 定位置's guide to building a layout: for now its title, and that it is
/// still to come.
class TeiichiGuideScreen extends StatelessWidget {
  const TeiichiGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: Palette.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: HeaderStyle.topGap),
            MangaHeader(
              title: ScreenTitle(s.teiichiGuideTitle, sub: s.sub?.teiichiGuideTitle),
              actions: [
                InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
              ],
            ),
            const SizedBox(height: Gaps.section),
            Text.rich(
              Phrases.span(s.teiichiGuideSoon),
              style: const TextStyle(fontWeight: Weights.bold, fontSize: TeiichiPageLayout.guideLineFont),
            ),
          ]),
        ),
      ),
    );
  }
}
