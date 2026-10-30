import 'package:flutter/widgets.dart';

import '../../config/design.dart';

/// A picture in an article, as wide as the text, and its [caption] under
/// it. [src] is the exact file.
class ArticlePicture extends StatelessWidget {
  const ArticlePicture({super.key, required this.src, this.caption = ''});

  final String src;
  final String caption;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Image.asset(
          src,
          fit: BoxFit.fitWidth,
          semanticLabel: caption,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: MarkdownLayout.captionGap),
          Text(caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: Weights.bold, fontSize: MarkdownLayout.captionFont, color: MarkdownLayout.captionColor)),
        ],
      ]);
}
