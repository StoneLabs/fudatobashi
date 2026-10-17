import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../manga/manga.dart';

/// A sheet asking before a ranked run or an exam try: its [tag], a title, a
/// body, an optional warning box, and the answers: "yes" alone, or both.
/// [yesIsPlain] makes the plain button the "yes" one and puts the shout on
/// "no", so a quick tap keeps playing. Closes with the answer.
class QuestionSheet extends StatelessWidget {
  const QuestionSheet({
    super.key,
    required this.tag,
    required this.title,
    required this.body,
    required this.yes,
    required this.tobi,
    this.no,
    this.warning,
    this.yesIsPlain = false,
  });

  final Widget tag;
  final String title, body, yes;
  final String? no;
  final String? warning;
  final TobiPose tobi;
  final bool yesIsPlain;

  @override
  Widget build(BuildContext context) {
    Widget shout(String label, bool answer) => SizedBox(
          height: RankedSheetStyle.shoutHeight,
          child: ShoutButton(
            label: label,
            color: Palette.pink,
            pressedColor: Palette.pinkDeep,
            onTap: () => Navigator.pop(context, answer),
          ),
        );
    Widget plain(String label, bool answer) => SizedBox(
          height: RankedSheetStyle.plainHeight,
          child: InkButton(
            onTap: () => Navigator.pop(context, answer),
            child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
          ),
        );
    const bodyStyle = TextStyle(
        fontSize: RankedSheetStyle.body, fontWeight: Weights.bold, height: RankedSheetStyle.bodyLineHeight);
    final warning = this.warning;
    final no = this.no;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MangaPanel(
                  shape: const PanelShape(topLeft: Offset(0, RankedSheetStyle.cut)),
                  padding: RankedSheetStyle.padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [tag]),
                      const SizedBox(height: Gaps.small),
                      Text.rich(Phrases.span(
                        title,
                        style: const TextStyle(
                            fontFamily: Fonts.display, fontSize: RankedSheetStyle.title, height: TypeScale.displayLineHeight),
                      )),
                      const SizedBox(height: Gaps.small),
                      Text.rich(Phrases.span(body, style: bodyStyle)),
                      if (warning != null) ...[
                        const SizedBox(height: Gaps.section),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: RankedSheetStyle.warningFill,
                            border: Border.all(color: Palette.ink, width: Strokes.label),
                          ),
                          child: Padding(
                            padding: RankedSheetStyle.warningPadding,
                            child: Text.rich(Phrases.span(warning,
                                style: const TextStyle(fontSize: RankedSheetStyle.body, fontWeight: Weights.black))),
                          ),
                        ),
                      ],
                      const SizedBox(height: Gaps.section),
                      if (no == null)
                        shout(yes, true)
                      else ...[
                        if (yesIsPlain) shout(no, false) else shout(yes, true),
                        const SizedBox(height: Gaps.panel),
                        if (yesIsPlain) plain(yes, true) else plain(no, false),
                      ],
                    ],
                  ),
                ),
                Placed(RankedSheetStyle.tobi, child: Tobi(pose: tobi)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
