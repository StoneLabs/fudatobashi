import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import 'buttons.dart';
import 'phrases.dart';

/// A link to another page as a boxed row: [title] in bold over a [note] on
/// what is there, a chevron at the end.
class LinkRow extends StatelessWidget {
  const LinkRow({super.key, required this.title, required this.note, required this.onTap});

  final String title;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkButton(
        onTap: onTap,
        border: LinkRowStyle.border,
        padding: LinkRowStyle.padding + const EdgeInsets.all(LinkRowStyle.border),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minHeight: LinkRowStyle.minHeight - LinkRowStyle.padding.vertical - 2 * LinkRowStyle.border),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(Phrases.span(title),
                      style: const TextStyle(fontWeight: Weights.black, fontSize: LinkRowStyle.font)),
                  Text.rich(Phrases.span(note),
                      style: const TextStyle(
                          fontWeight: Weights.medium,
                          fontSize: LinkRowStyle.noteFont,
                          height: LinkRowStyle.noteLineHeight,
                          color: LinkRowStyle.note)),
                ],
              ),
            ),
            const SizedBox(width: LinkRowStyle.chevronGap),
            MangaIcon(IconArt.chevron, size: LinkRowStyle.chevron),
          ]),
        ),
      );
}
