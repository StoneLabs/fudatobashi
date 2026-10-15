import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// 暗記練's sheets' frame: free practice's floating panel, its top edge
/// tilted, at the bottom of the screen. Its head is [title] in display
/// type with the other language's [sub], each breaking only between
/// words, an optional [line] under them and a close button; then [body],
/// a block at a time, scrolling when the screen is short; then [footer],
/// which stays in view.
class AnkirenSheet extends StatelessWidget {
  const AnkirenSheet({super.key, required this.title, this.sub, this.line, required this.body, this.footer});

  final String title;
  final String? sub;
  final String? line;
  final List<Widget> body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final line = this.line;
    final footer = this.footer;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: MangaPanel(
              shape: const PanelShape(topLeft: Offset(0, FreePracticeLayout.sheetCut)),
              padding: AnkirenSheetLayout.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Semantics(
                          header: true,
                          child: Text.rich(
                            TextSpan(children: [
                              Phrases.span(title),
                              if (sub != null) ...[
                                const TextSpan(text: '  '),
                                Phrases.span(
                                  sub!.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: Fonts.ui,
                                    fontWeight: Weights.black,
                                    fontSize: AnkirenSheetLayout.titleSubFont,
                                    letterSpacing: AnkirenSheetLayout.titleSubTracking * AnkirenSheetLayout.titleSubFont,
                                  ),
                                ),
                              ],
                            ]),
                            style: const TextStyle(
                                fontFamily: Fonts.display,
                                fontSize: AnkirenSheetLayout.titleFont,
                                height: TypeScale.displayLineHeight),
                          ),
                        ),
                        if (line != null) ...[
                          const SizedBox(height: AnkirenSheetLayout.lineGap),
                          Text.rich(
                            Phrases.span(line),
                            style: const TextStyle(
                                fontWeight: Weights.bold, fontSize: AnkirenSheetLayout.lineFont, color: Palette.mute),
                          ),
                        ],
                      ]),
                    ),
                    const SizedBox(width: AnkirenSheetLayout.headGap),
                    InkIconButton(icon: IconArt.close, semanticLabel: s.close, onTap: () => Navigator.pop(context)),
                  ]),
                  const SizedBox(height: AnkirenSheetLayout.gap),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, block) in body.indexed) ...[
                            if (i > 0) const SizedBox(height: AnkirenSheetLayout.gap),
                            block,
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (footer != null) ...[const SizedBox(height: AnkirenSheetLayout.gap), footer],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
