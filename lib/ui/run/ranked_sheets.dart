import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// Asks before a ranked run: the rank can go either way, and leaving early
/// is a forfeit. True to start.
Future<bool> confirmRankedStart(BuildContext context) async {
  final s = S.of(context);
  final ok = await showMangaSheet<bool>(
    context,
    barrierColor: RankedSheetStyle.barrier,
    barrierLabel: s.cancel,
    builder: (_) => _RankedSheet(
      title: s.rankedStartTitle,
      body: s.rankedStartBody,
      warning: s.rankedForfeitWarning,
      yes: s.rankedStart,
      no: s.back,
      tobi: TobiPose.fired,
    ),
  );
  return ok == true;
}

/// Asks before leaving a ranked run under way. True to forfeit.
Future<bool> confirmForfeit(BuildContext context) async {
  final s = S.of(context);
  final ok = await showMangaSheet<bool>(
    context,
    barrierColor: RankedSheetStyle.barrier,
    barrierLabel: s.cancel,
    builder: (_) => _RankedSheet(
      title: s.forfeitTitle,
      body: s.forfeitBody,
      yes: s.forfeitYes,
      no: s.forfeitNo,
      tobi: TobiPose.shocked,
      yesIsPlain: true,
    ),
  );
  return ok == true;
}

/// A sheet of the ranked-run questions: the RANKED tag, a title, a body, an
/// optional warning box, and the two answers. [yesIsPlain] makes the plain
/// button the "yes" one and puts the shout on "no", so a quick tap keeps
/// playing.
class _RankedSheet extends StatelessWidget {
  const _RankedSheet({
    required this.title,
    required this.body,
    required this.yes,
    required this.no,
    required this.tobi,
    this.warning,
    this.yesIsPlain = false,
  });

  final String title, body, yes, no;
  final String? warning;
  final TobiPose tobi;
  final bool yesIsPlain;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
    final warning = this.warning;
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
                      Row(children: [InkTag(s.rankedTag, color: Palette.pink)]),
                      const SizedBox(height: Gaps.small),
                      Text(
                        title,
                        style: const TextStyle(
                            fontFamily: Fonts.display, fontSize: RankedSheetStyle.title, height: TypeScale.displayLineHeight),
                      ),
                      const SizedBox(height: Gaps.small),
                      Text(
                        body,
                        style: const TextStyle(
                            fontSize: RankedSheetStyle.body,
                            fontWeight: Weights.bold,
                            height: RankedSheetStyle.bodyLineHeight),
                      ),
                      if (warning != null) ...[
                        const SizedBox(height: Gaps.section),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: RankedSheetStyle.warningFill,
                            border: Border.all(color: Palette.ink, width: Strokes.label),
                          ),
                          child: Padding(
                            padding: RankedSheetStyle.warningPadding,
                            child: Text(warning,
                                style: const TextStyle(fontSize: RankedSheetStyle.body, fontWeight: Weights.black)),
                          ),
                        ),
                      ],
                      const SizedBox(height: Gaps.section),
                      if (yesIsPlain) shout(no, false) else shout(yes, true),
                      const SizedBox(height: Gaps.panel),
                      if (yesIsPlain) plain(yes, true) else plain(no, false),
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
