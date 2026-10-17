import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'question_sheet.dart';

/// Asks before a ranked run: the rank can go either way, and leaving early
/// is a forfeit. True to start.
Future<bool> confirmRankedStart(BuildContext context) async {
  final s = S.of(context);
  final ok = await showMangaSheet<bool>(
    context,
    barrierColor: RankedSheetStyle.barrier,
    barrierLabel: s.cancel,
    builder: (_) => QuestionSheet(
      tag: InkTag(s.rankedTag, color: Palette.pink),
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
    builder: (_) => QuestionSheet(
      tag: InkTag(s.rankedTag, color: Palette.pink),
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
