import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../l10n/exam_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// Asks before a try at the graduation exam: one try an hour, and a try
/// left early is still used. True to start.
Future<bool> confirmExamStart(BuildContext context) async {
  final s = S.of(context);
  final ok = await showMangaSheet<bool>(
    context,
    barrierColor: RankedSheetStyle.barrier,
    barrierLabel: s.cancel,
    builder: (_) => _ExamSheet(
      title: s.examStartTitle,
      rules: [s.examRuleCards, s.examRuleBeat, s.examRulePenalty(ExamTuning.missPenaltyMs ~/ 1000)],
      warning: s.examRuleTry,
      yes: s.examStart,
      no: s.examNotNow,
      tobi: TobiPose.fired,
    ),
  );
  return ok == true;
}

/// Asks before leaving a try under way, which Tobi then wins. True to leave.
Future<bool> confirmExamLeave(BuildContext context) async {
  final s = S.of(context);
  final ok = await showMangaSheet<bool>(
    context,
    barrierColor: RankedSheetStyle.barrier,
    barrierLabel: s.cancel,
    builder: (_) => _ExamSheet(
      title: s.examLeaveTitle,
      rules: [s.examLeaveBody],
      yes: s.examLeaveYes,
      no: s.examLeaveNo,
      tobi: TobiPose.shocked,
      yesIsPlain: true,
    ),
  );
  return ok == true;
}

/// A sheet of the exam's questions: the exam's tag, a title, the rules as
/// a list, an optional warning box, and the two answers. [yesIsPlain] puts
/// the shout on "no", so a quick tap keeps playing.
class _ExamSheet extends StatelessWidget {
  const _ExamSheet({
    required this.title,
    required this.rules,
    required this.yes,
    required this.no,
    required this.tobi,
    this.warning,
    this.yesIsPlain = false,
  });

  final String title, yes, no;
  final List<String> rules;
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
    const body = TextStyle(
        fontSize: RankedSheetStyle.body, fontWeight: Weights.bold, height: RankedSheetStyle.bodyLineHeight);
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
                      Row(children: [InkTag(s.examTag, color: ExamSheetStyle.tag, textColor: ExamSheetStyle.tagText)]),
                      const SizedBox(height: Gaps.small),
                      Text.rich(Phrases.span(
                        title,
                        style: const TextStyle(
                            fontFamily: Fonts.display, fontSize: RankedSheetStyle.title, height: TypeScale.displayLineHeight),
                      )),
                      const SizedBox(height: Gaps.small),
                      for (final (i, rule) in rules.indexed) ...[
                        if (i > 0) const SizedBox(height: ExamSheetStyle.ruleGap),
                        rules.length == 1
                            ? Text.rich(Phrases.span(rule, style: body))
                            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: ExamSheetStyle.bulletTop),
                                  child: SizedBox.square(
                                      dimension: ExamSheetStyle.bullet, child: ColoredBox(color: Palette.ink)),
                                ),
                                const SizedBox(width: ExamSheetStyle.bulletGap),
                                Expanded(child: Text.rich(Phrases.span(rule, style: body))),
                              ]),
                      ],
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
