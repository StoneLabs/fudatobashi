import 'package:flutter/widgets.dart';

import '../../l10n/articles.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../help/guide_screen.dart';
import '../manga/manga.dart';

/// Opens 定位置's guide to building a layout.
Future<void> openTeiichiGuide(BuildContext context) {
  final s = S.of(context);
  return Navigator.of(context).push(MangaRoute<void>(
    builder: (_) => GuideScreen(article: Articles.teiichiGuide, title: s.teiichiGuideTitle, sub: s.sub?.teiichiGuideTitle),
  ));
}
