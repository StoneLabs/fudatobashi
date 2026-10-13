import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/side_trips.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// 暗記練's rules (遊び方) in a sheet: what it is, its three steps in
/// pictures with a line on each, and how a game scores.
Future<void> openAnkirenRules(BuildContext context) => showMangaSheet<void>(
      context,
      barrierColor: FreePracticeLayout.barrier,
      barrierLabel: S.of(context).cancel,
      builder: (_) => const AnkirenRulesSheet(),
    );

class AnkirenRulesSheet extends StatelessWidget {
  const AnkirenRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final steps = [
      (AnkirenRulesLayout.memorise, s.ankirenStepMemorise, s.ankirenStepMemoriseNote),
      (AnkirenRulesLayout.flip, s.ankirenStepFlip, s.ankirenStepFlipNote),
      (AnkirenRulesLayout.take, s.ankirenStepTake, s.ankirenStepTakeNote),
    ];
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: MangaPanel(
              shape: const PanelShape(topLeft: Offset(0, FreePracticeLayout.sheetCut)),
              padding: FreePracticeLayout.sheetPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [InkTag(s.howToPlay.toUpperCase())]),
                        const SizedBox(height: Gaps.small),
                        Text(SideTrip.ankiren.label,
                            style: const TextStyle(
                                fontFamily: Fonts.display,
                                fontSize: AnkirenRulesLayout.title,
                                height: TypeScale.displayLineHeight)),
                        const SizedBox(height: Gaps.small),
                        Text.rich(Phrases.span(s.tripAbout(SideTrip.ankiren)),
                            style: const TextStyle(fontWeight: Weights.bold, fontSize: AnkirenRulesLayout.aboutFont)),
                        const SizedBox(height: Gaps.section),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (i, (picture, caption, _)) in steps.indexed) ...[
                              if (i > 0) const SizedBox(width: AnkirenRulesLayout.stepGap),
                              Expanded(child: _Step(number: i + 1, picture: picture, caption: caption)),
                            ],
                          ],
                        ),
                        const SizedBox(height: Gaps.section),
                        for (final (i, (_, _, note)) in steps.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AnkirenRulesLayout.noteGap),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Number(i + 1),
                                const SizedBox(width: AnkirenRulesLayout.captionGap),
                                Expanded(
                                  child: Text.rich(Phrases.span(note),
                                      style: const TextStyle(
                                          fontWeight: Weights.bold, fontSize: AnkirenRulesLayout.noteFont)),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: Gaps.small),
                        DashedBox(
                          padding: FreePracticeLayout.statusPadding,
                          child: Text.rich(Phrases.span(s.ankirenRulesScore),
                              style: const TextStyle(
                                  fontWeight: Weights.bold, fontSize: FreePracticeLayout.statusNoteFont)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: Gaps.section),
                  SizedBox(
                    height: AnkirenRulesLayout.doneHeight,
                    child: InkButton(
                      onTap: () => Navigator.pop(context),
                      child: Text(s.sideTripRulesDone,
                          style: const TextStyle(fontFamily: Fonts.display, fontSize: AnkirenRulesLayout.doneFont)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One step of the game: its picture over its number and name.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.picture, required this.caption});

  final int number;
  final String picture, caption;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
        child: Padding(
          padding: const EdgeInsets.all(Strokes.control),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: AnkirenRulesLayout.pictureAspect,
                child: Image.asset(picture, filterQuality: FilterQuality.medium, excludeFromSemantics: true),
              ),
              const SizedBox(height: Strokes.control, child: ColoredBox(color: Palette.ink)),
              Padding(
                padding: AnkirenRulesLayout.captionPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Number(number),
                    const SizedBox(width: AnkirenRulesLayout.captionGap),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(caption,
                            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenRulesLayout.captionFont)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// A step's number on an ink square.
class _Number extends StatelessWidget {
  const _Number(this.n);

  final int n;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: AnkirenRulesLayout.numberBox,
        child: ColoredBox(
          color: Palette.ink,
          child: Center(
            child: Text('$n',
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: AnkirenRulesLayout.numberFont, height: 1, color: Palette.paper)),
          ),
        ),
      );
}
