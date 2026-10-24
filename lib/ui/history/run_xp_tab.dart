import 'package:flutter/material.dart';

import '../../l10n/run_tab_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import 'review_parts.dart';

/// The training view's XP tab: the run's experience as a hero with the
/// level it left, where it came from, and that the run doesn't change rank.
class RunXpTab extends StatelessWidget {
  const RunXpTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewColumn(children: [
      ...xpParts(s, detail.xp),
      ReviewCaption(detail.run.mode == PlayMode.training ? s.runTrainingNoRank : s.runPracticeNoRank),
    ]);
  }
}
