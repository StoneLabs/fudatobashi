import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../l10n/exam_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../run/question_sheet.dart';

/// Asks before a try at the graduation exam, Tobi saying what it is, with
/// the warning that there is one try an hour and a try left early is still
/// used. True to start; a tap on the backdrop closes it.
Future<bool> confirmExamStart(BuildContext context) async {
  final s = S.of(context);
  final ok = await showMangaSheet<bool>(
    context,
    barrierColor: RankedSheetStyle.barrier,
    barrierLabel: s.cancel,
    builder: (_) => QuestionSheet(
      tag: InkTag(s.examTag, color: ExamSheetStyle.tag, textColor: ExamSheetStyle.tagText),
      title: s.examStartTitle,
      body: s.examStartBody(ExamTuning.missPenaltyMs ~/ Duration.millisecondsPerSecond),
      warning: s.examRuleTry,
      yes: s.examStart,
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
    builder: (_) => QuestionSheet(
      tag: InkTag(s.examTag, color: ExamSheetStyle.tag, textColor: ExamSheetStyle.tagText),
      title: s.examLeaveTitle,
      body: s.examLeaveBody,
      yes: s.examLeaveYes,
      no: s.examLeaveNo,
      tobi: TobiPose.shocked,
      yesIsPlain: true,
    ),
  );
  return ok == true;
}
