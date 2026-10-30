import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../manga/manga.dart';

/// One guide or tool: its [title] in display type, the English [sub] under it in a
/// Japanese UI, a [note] on what it is, and [icon] at the end. Stamps when
/// tapped.
class HelpEntry extends StatelessWidget {
  const HelpEntry({super.key, required this.title, this.sub, required this.note, required this.icon, required this.onTap});

  final String title;
  final String? sub;
  final String note;
  final VectorArt icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        drop: 0,
        turn: 0,
        scale: Press.panelScale,
        builder: (context, pressed) => Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: pressed ? Tones.stampOpacity : 0,
                duration: Motion.stampFade,
                child: const ToneBox(Tones.stamp),
              ),
            ),
            Padding(
              padding: HelpLayout.entryPadding,
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontFamily: Fonts.display,
                              fontSize: HelpLayout.titleFont,
                              height: HelpLayout.titleLineHeight)),
                      if (sub case final sub?)
                        Text(sub.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: Weights.black,
                                fontSize: HelpLayout.subFont,
                                letterSpacing: HelpLayout.subFont * HelpLayout.subTracking,
                                color: Palette.inkSoft)),
                      const SizedBox(height: HelpLayout.noteGap),
                      Text.rich(Phrases.span(note),
                          style: const TextStyle(
                              fontWeight: Weights.medium,
                              fontSize: HelpLayout.noteFont,
                              height: HelpLayout.noteLineHeight,
                              color: Palette.inkSoft)),
                    ],
                  ),
                ),
                const SizedBox(width: HelpLayout.iconGap),
                MangaIcon(icon, size: HelpLayout.icon),
              ]),
            ),
          ],
        ),
      );
}

class HelpRule extends StatelessWidget {
  const HelpRule({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: HelpLayout.rule, child: ColoredBox(color: Palette.ink));
}
