import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';

/// Reviews have piled up: offers to pause today's new cards, and records
/// the answer. Closing the sheet keeps them; either way it is asked once.
Future<void> askToPauseNewCards(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final set = progress.todaySet();
  if (set == null) return;
  final pause = await showMangaSheet<bool>(
    context,
    barrierColor: PauseSheetLayout.barrier,
    barrierLabel: S.of(context).pauseNo,
    builder: (_) => _PauseSheet(reviews: set.reviews),
  );
  await progress.answerPause(pause: pause ?? false);
}

class _PauseSheet extends StatelessWidget {
  const _PauseSheet({required this.reviews});

  final int reviews;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
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
                  shape: const PanelShape(topLeft: Offset(0, PauseSheetLayout.cut)),
                  padding: PauseSheetLayout.padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.pauseTitle(reviews),
                        style: const TextStyle(
                            fontFamily: Fonts.display, fontSize: PauseSheetLayout.title, height: TypeScale.displayLineHeight),
                      ),
                      const SizedBox(height: PauseSheetLayout.subGap),
                      Text(
                        s.other.pauseTitle(reviews),
                        style: const TextStyle(
                            fontWeight: Weights.black, fontSize: PauseSheetLayout.sub, color: Palette.inkSoft),
                      ),
                      const SizedBox(height: PauseSheetLayout.bodyGap),
                      Text(
                        s.pauseBody,
                        style: const TextStyle(
                          fontWeight: Weights.bold,
                          fontSize: PauseSheetLayout.body,
                          height: PauseSheetLayout.bodyLineHeight,
                        ),
                      ),
                      const SizedBox(height: PauseSheetLayout.noteGap),
                      Text(
                        s.pauseNote,
                        style: const TextStyle(
                            fontWeight: Weights.bold, fontSize: PauseSheetLayout.note, color: Palette.inkSoft),
                      ),
                      const SizedBox(height: PauseSheetLayout.shoutGap),
                      SizedBox(
                        height: PauseSheetLayout.shoutHeight,
                        child: ShoutButton(
                          label: s.pauseYes,
                          sub: s.other.pauseYes,
                          spec: PauseSheetLayout.shout,
                          fontSize: PauseSheetLayout.shoutFont,
                          color: Palette.sun,
                          pressedColor: Palette.sunSoft,
                          arrow: false,
                          onTap: () => Navigator.pop(context, true),
                        ),
                      ),
                      const SizedBox(height: PauseSheetLayout.keepGap),
                      SizedBox(
                        height: PauseSheetLayout.keepHeight,
                        child: InkButton(
                          onTap: () => Navigator.pop(context, false),
                          semanticLabel: s.pauseNo,
                          padding: const EdgeInsets.symmetric(horizontal: Gaps.inner),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(s.pauseNo,
                                    style: const TextStyle(fontWeight: Weights.black, fontSize: PauseSheetLayout.keepFont)),
                                const SizedBox(width: PauseSheetLayout.keepSubGap),
                                Text(s.other.pauseNo,
                                    style: const TextStyle(
                                        fontWeight: Weights.black,
                                        fontSize: PauseSheetLayout.keepSub,
                                        color: Palette.inkSoft)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Placed(PauseSheetLayout.tobi, child: Tobi(pose: TobiPose.relaxed)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
