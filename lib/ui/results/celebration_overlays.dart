import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/poem.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';
import 'celebration_chrome.dart';
import 'celebrations.dart';

/// A newly unlocked card looks alike to one already known: shown right
/// after that card's [NewCardOverlay].
class ConfusableWarningOverlay extends StatelessWidget {
  const ConfusableWarningOverlay({super.key, required this.data, required this.onNext});
  final ConfusableWarningCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ids = [data.poemId, ...data.knownSiblings.take(ResultsLayout.confusableMaxSiblings)];
    return CelebrationChrome(
      color: Palette.sun,
      onNext: onNext,
      cta: s.gotIt,
      child: Stack(children: [
        Align(alignment: const Alignment(0, -0.62), child: InkTag(s.lookAlikeBand)),
        Align(
          alignment: const Alignment(0, -0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: Text(s.mixUpWarning,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.confusableTitleFont, height: 1.1)),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.02),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final (i, id) in ids.indexed) ...[
              if (i > 0) const SizedBox(width: Gaps.section),
              _ConfusableCard(poemId: id, isNew: i == 0),
            ],
          ]),
        ),
        const Placed(ResultsLayout.confusableTobi, child: Tobi(pose: TobiPose.pointing)),
      ]),
    );
  }
}

class _ConfusableCard extends StatelessWidget {
  const _ConfusableCard({required this.poemId, required this.isNew});
  final int poemId;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (isNew) ...[
        InkTag(s.newBadge, color: Palette.pink),
        const SizedBox(height: Gaps.tight),
      ],
      SizedBox(width: ResultsLayout.confusableCardWidth, child: TorifudaCard(poem: poems[poemId])),
      const SizedBox(height: Gaps.tight),
      Text(poems[poemId].kimariji, style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.confusableKimarijiFont)),
    ]);
  }
}

/// A tighter goal ladder rung: the player has earned a faster target.
class GoalUpOverlay extends StatelessWidget {
  const GoalUpOverlay({super.key, required this.goalMs, required this.onNext});
  final int goalMs;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return CelebrationChrome(
      color: Palette.sun,
      onNext: onNext,
      cta: s.nicePace,
      art: const [BurstLayer(BurstSpec(
          box: Size(390, 844), center: Offset(195, 380), count: 140, innerMin: 120, innerMax: 170, width: 4, seed: 15))],
      child: Stack(children: [
        Align(
          alignment: const Alignment(0, -0.3),
          child: OutlinedText(s.goalUp,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.goalTitleFont, height: 1)),
        ),
        Align(
          alignment: const Alignment(0, -0.1),
          child: InkTag(s.goalUpBand),
        ),
        Align(
          alignment: const Alignment(0, 0.06),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Palette.paper),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(s.goalUpNote(goalMs), style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.goalNoteFont)),
            ),
          ),
        ),
        const Placed(ResultsLayout.goalTobi, child: Tobi(pose: TobiPose.fired)),
      ]),
    );
  }
}
