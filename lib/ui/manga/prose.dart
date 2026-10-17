import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'lettering.dart';
import 'phrases.dart';

/// The text of a paragraph on the Help pages.
const proseStyle = TextStyle(
  fontSize: ProseLayout.bodyFont,
  fontWeight: Weights.medium,
  height: ProseLayout.bodyLineHeight,
  color: Palette.inkBody,
);

/// A chapter's heading: its [number] in a pink box, the [title] (whole
/// words, shrinking rather than breaking one), the English [sub] under it
/// in a Japanese UI, and an ink rule. The [first] chapter of a page has no
/// gap above it.
class ProseChapter extends StatelessWidget {
  const ProseChapter(this.number, this.title, this.sub, {super.key, this.first = false});

  final int number;
  final String title;
  final String? sub;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: first ? 0 : ProseLayout.chapterGap),
        child: Semantics(
          header: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox.square(
                dimension: ProseLayout.numberBox,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.pink,
                    border: Border.all(color: Palette.ink, width: Strokes.label),
                  ),
                  child: Center(
                    child: Text('$number',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                            fontFamily: Fonts.display, fontSize: ProseLayout.numberFont, color: Palette.paper)),
                  ),
                ),
              ),
              const SizedBox(width: ProseLayout.headingGap),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WholeWordsText(title,
                      style: const TextStyle(
                          fontFamily: Fonts.display,
                          fontSize: ProseLayout.headingFont,
                          height: ProseLayout.headingLineHeight)),
                  if (sub case final sub?)
                    Text(sub.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: Weights.black,
                            fontSize: ProseLayout.headingSubFont,
                            letterSpacing: ProseLayout.headingSubFont * ProseLayout.headingSubTracking,
                            color: Palette.inkSoft)),
                ]),
              ),
            ]),
            const SizedBox(height: ProseLayout.headingRuleGap),
            const SizedBox(height: ProseLayout.headingRule, child: ColoredBox(color: Palette.ink)),
          ]),
        ),
      );
}

/// One paragraph. With [phrases], Japanese breaks its lines only where the
/// text marks its phrases ([Phrases]).
class ProseBody extends StatelessWidget {
  const ProseBody(this.text, {super.key, this.phrases = false});

  final String text;
  final bool phrases;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: ProseLayout.paragraphGap),
        child: phrases ? Text.rich(Phrases.span(text), style: proseStyle) : Text(text, style: proseStyle),
      );
}
