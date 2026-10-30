import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/articles.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../cards/page_frame.dart';
import '../manga/manga.dart';

/// A guide under its [title] (and [sub]): article [article] (see
/// `Articles`) in the player's language, set as prose in numbered chapters
/// (`ProseStyle.guide`) with Tobi's lines and pictures. Kana marks follow
/// the player's kana setting; with [kanaBesideRomaji], romaji keeps its
/// kana in front.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key, required this.article, required this.title, this.sub, this.kanaBesideRomaji = false});

  final String article;
  final String title;
  final String? sub;
  final bool kanaBesideRomaji;

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String? _code;
  late Future<String> _source;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = S.of(context).code;
    if (code == _code) return;
    _code = code;
    _source = Articles.load(code, widget.article);
  }

  @override
  Widget build(BuildContext context) {
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    return PageFrame(
      title: widget.title,
      sub: widget.sub,
      body: FutureBuilder<String>(
        future: _source,
        builder: (context, snapshot) => switch (snapshot.data) {
          final source? => SingleChildScrollView(
              padding: PageFrame.padding + const EdgeInsets.only(right: GuideLayout.shadowRoom),
              child: MarkdownProse(
                source,
                blocks: ProseBlocks(
                  style: ProseStyle.guide,
                  accent: GuideLayout.accent,
                  options: MarkdownOptions(
                    language: S.of(context).code,
                    romaji: romaji,
                    kanaBesideRomaji: widget.kanaBesideRomaji,
                    phrases: source.contains(Phrases.end),
                  ),
                ),
              ),
            ),
          null => const SizedBox.shrink(),
        },
      ),
    );
  }
}
