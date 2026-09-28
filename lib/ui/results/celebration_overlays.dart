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

/// The band changed: a two-page spread crossing the gutter.
class RankUpOverlay extends StatelessWidget {
  const RankUpOverlay({super.key, required this.data, required this.onNext});
  final RankUpCelebration data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return CelebrationChrome(
      color: Palette.paper,
      onNext: onNext,
      cta: s.onward,
      backdrop: [
        Row(children: [
          Expanded(
            child: ColoredBox(
              color: Palette.seaSoft,
              child: Stack(children: [
                const Positioned.fill(child: ToneBox(Tones.sea)),
                Positioned(
                  left: 16,
                  top: 340,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.beforeBandLabel, style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.rankOldLabelFont)),
                    const SizedBox(height: Gaps.tight),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Palette.paper,
                        border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.control)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                        child: Text(data.before.label,
                            style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankOldFont, color: Palette.mute)),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          // The gutter shadow between the two pages.
          const SizedBox(
            width: 4,
            child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0x00000000), Color(0x33000000), Color(0x00000000)]),
            )),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.1),
                  radius: 1,
                  colors: [Color(0xFFFFFBE3), Color(0xFFFFE77A), Palette.sun],
                ),
              ),
              child: Stack(children: [
                Positioned(
                  left: 16,
                  top: 388,
                  right: 16,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(color: Palette.ink),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 2, 6, 3),
                        child: Text(s.nowBandLabel, style: const TextStyle(color: Palette.paper, fontWeight: Weights.black, fontSize: ResultsLayout.rankNewLabelFont)),
                      ),
                    ),
                    const SizedBox(height: Gaps.tight),
                    OutlinedText(data.after.label,
                        style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankNewFont, color: Palette.sun),
                        outlineWidth: 8),
                  ]),
                ),
                const Placed(ResultsLayout.rankTobi, child: Tobi(pose: TobiPose.cheering)),
              ]),
            ),
          ),
        ]),
      ],
      child: Stack(children: [
        Align(
          alignment: const Alignment(0, -0.6),
          child: OutlinedText('昇級!!',
              style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankTitleFont, height: 1),
              outlineWidth: ResultsLayout.rankTitleOutline),
        ),
        Align(
          alignment: const Alignment(0, -0.36),
          child: InkTag(s.rankUpBand, fontSize: ResultsLayout.rankBandFont, color: Palette.ink, textColor: Palette.sun),
        ),
        Align(
          alignment: const Alignment(0, 0.42),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Palette.paper,
              border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.panel)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Text('${data.ratingBefore.round()} → ${data.ratingAfter.round()}',
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.rankRateFont)),
            ),
          ),
        ),
      ]),
    );
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
