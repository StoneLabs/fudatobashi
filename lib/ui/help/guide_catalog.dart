import 'package:flutter/widgets.dart';

import '../../l10n/all_guides_strings.dart';
import '../../l10n/articles.dart';
import '../../l10n/first_sounds_strings.dart';
import '../../l10n/guide_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';
import '../manga/manga.dart';
import 'guide_screen.dart';

/// One guide: its [article], texts in the player's language and how its
/// [GuideScreen] is set. A new guide needs one entry in [Guides.all]; Help's
/// list of guides and every place that opens a guide read it from there.
class GuideInfo {
  const GuideInfo({
    required this.article,
    required this.title,
    required this.note,
    this.subAlways = false,
    this.kanaBesideRomaji = false,
  });

  final String article;
  final String Function(S s) title;
  final String Function(S s) note;

  /// Whether the guide's own header shows the other language's title even in
  /// an English UI.
  final bool subAlways;
  final bool kanaBesideRomaji;

  String? subOf(S s) {
    final other = subAlways ? s.other : s.sub;
    return other == null ? null : title(other);
  }

  Future<void> open(BuildContext context) {
    final s = S.of(context);
    return Navigator.of(context).push(MangaRoute<void>(
      builder: (_) => GuideScreen(article: article, title: title(s), sub: subOf(s), kanaBesideRomaji: kanaBesideRomaji),
    ));
  }
}

class Guides {
  const Guides._();

  static final karuta = GuideInfo(
    article: Articles.karutaGuide,
    title: (s) => s.guideTitle,
    note: (s) => s.guideRowNote,
    subAlways: true,
    kanaBesideRomaji: true,
  );
  static final kimariji = GuideInfo(
    article: Articles.kimarijiGuide,
    title: (s) => s.firstSoundsTitle,
    note: (s) => s.firstSoundsGuideNote,
    subAlways: true,
  );
  static final teiichi = GuideInfo(
    article: Articles.teiichiGuide,
    title: (s) => s.teiichiGuideTitle,
    note: (s) => s.teiichiGuideNote,
  );

  static final all = [karuta, kimariji, teiichi];
}
