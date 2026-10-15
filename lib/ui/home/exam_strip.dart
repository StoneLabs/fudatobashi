import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';

/// The graduation exam (卒業試験) on journey Home, as the map's last stop: a
/// black strip along the bottom of the islands map, shown once the exam is
/// open. Its pill says where the exam stands: OPEN (a tap starts it), or a
/// countdown to the next try, which a tap explains.
class ExamStrip extends StatefulWidget {
  const ExamStrip({super.key});

  @override
  State<ExamStrip> createState() => _ExamStripState();
}

class _ExamStripState extends State<ExamStrip> {
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _tickWhile(bool waiting) {
    if (!waiting) {
      _tick?.cancel();
      _tick = null;
    } else {
      _tick ??= Timer.periodic(ExamStripStyle.tick, (_) => setState(() {}));
    }
  }

  void _onTap(ExamAccess exam) {
    final s = S.of(context);
    final wait = exam.cooldown;
    if (exam.canStart) {
      startExam(context);
    } else if (wait != null) {
      BalloonPop.show(context, s.examCooldownWhy(formatMinutes(wait)),
          size: ExamStripStyle.waitBalloon, life: ExamStripStyle.waitBalloonLife);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final exam = ProgressScope.of(context).exam();
    final wait = exam.cooldown;
    _tickWhile(wait != null);
    const paper = TextStyle(color: Palette.paper, fontWeight: Weights.bold, fontSize: ExamStripStyle.ruleFont);
    const number = TextStyle(fontFamily: Fonts.display, fontSize: ExamStripStyle.ruleNumber, color: Palette.paper);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: ExamStripStyle.maxTextScale,
      child: Pressable(
        onTap: () => _onTap(exam),
        semanticLabel: s.examRun,
        drop: 0,
        scale: 1,
        turn: 0,
        builder: (context, pressed) => DecoratedBox(
          decoration: const BoxDecoration(
            color: Palette.ink,
            border: Border(top: BorderSide(color: Palette.sun, width: ExamStripStyle.edge)),
          ),
          child: Padding(
            padding: ExamStripStyle.padding,
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.examStripLettering,
                      style: const TextStyle(
                        fontFamily: Fonts.display,
                        fontSize: ExamStripStyle.titleFont,
                        color: Palette.sun,
                        height: TypeScale.displayLineHeight,
                      ),
                    ),
                    Text(
                      s.examStripSub,
                      style: const TextStyle(
                          color: Palette.paper, fontWeight: Weights.bold, fontSize: ExamStripStyle.subFont),
                    ),
                  ],
                ),
                const SizedBox(width: ExamStripStyle.gap),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(height: ExamStripStyle.ruleLineHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NumberedText(s.examVsTobi, const [RankedTuning.cards], style: paper, numberStyle: number),
                          Text(
                            wait != null
                                ? s.examTryAgainIn
                                : s.examPenalty(ExamTuning.missPenaltyMs ~/ Duration.millisecondsPerSecond),
                            style: paper,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ExamStripStyle.gap),
                Padding(
                  padding: const EdgeInsets.only(bottom: ExamStripStyle.pillLift),
                  child: Transform.translate(
                    offset: Offset(0, pressed ? Press.buttonDrop : 0),
                    child: _StatusPill(exam),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The strip's state at a glance: OPEN, or the countdown to the next try.
class _StatusPill extends StatelessWidget {
  const _StatusPill(this.exam);
  final ExamAccess exam;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final wait = exam.cooldown;
    final (fill, content) = wait != null
        ? (
            ExamStripStyle.waitFill,
            Text(
              formatMinutes(wait),
              style: const TextStyle(
                  fontFamily: Fonts.display, fontSize: ExamStripStyle.pillTime, height: ExamStripStyle.pillLineHeight),
            ),
          )
        : (
            ExamStripStyle.openFill,
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                s.examOpenPill,
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: ExamStripStyle.pillFont, height: ExamStripStyle.pillLineHeight),
              ),
              const SizedBox(width: ExamStripStyle.pillIconGap),
              MangaIcon(IconArt.arrow, size: ExamStripStyle.pillIcon),
            ]),
          );
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, border: Border.all(color: Palette.paper, width: Strokes.label)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ExamStripStyle.pillHeight, minWidth: ExamStripStyle.pillHeight),
        child: Padding(padding: ExamStripStyle.pillPadding, child: Center(widthFactor: 1, heightFactor: 1, child: content)),
      ),
    );
  }
}
