import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/articles.dart';

/// A picture in an article, as wide as the text, and its [caption] under
/// it: the version of [src] for a reader of [language] who reads kana in
/// [romaji] or not (see [ArticlePictures.pick]).
class ArticlePicture extends StatefulWidget {
  const ArticlePicture({super.key, required this.src, this.caption = '', required this.language, required this.romaji});

  final String src;
  final String caption;
  final String language;
  final bool romaji;

  @override
  State<ArticlePicture> createState() => _ArticlePictureState();
}

class _ArticlePictureState extends State<ArticlePicture> {
  late final Future<Set<String>> _files = ArticlePictures.load();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FutureBuilder<Set<String>>(
          future: _files,
          builder: (context, files) => switch (files.data) {
            final files? => Image.asset(
                ArticlePictures.pick(widget.src, files, language: widget.language, romaji: widget.romaji),
                fit: BoxFit.fitWidth,
                semanticLabel: widget.caption,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            null => const SizedBox.shrink(),
          },
        ),
        if (widget.caption.isNotEmpty) ...[
          const SizedBox(height: MarkdownLayout.captionGap),
          Text(widget.caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: Weights.bold, fontSize: MarkdownLayout.captionFont, color: MarkdownLayout.captionColor)),
        ],
      ]);
}
