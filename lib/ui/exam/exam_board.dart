import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/torifuda_spec.dart';
import '../../data/poem.dart';
import '../../domain/play_session.dart';
import '../../domain/ranked.dart';
import '../../l10n/exam_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';

/// Tobi's side of the mat: Tobi, and his deck turned to face him like an
/// opponent's across the mat. Each of his cards is nudged, then flies off
/// sideways at its time in [pace]; [race] is the time since GO.
class TobiSide extends StatelessWidget {
  const TobiSide({super.key, required this.pace, required this.cards, required this.race, required this.pose});

  final TobiPace pace;
  final List<CardRef> cards;
  final ValueListenable<Duration> race;

  /// His pose with [done] of his cards gone.
  final TobiPose Function(int done) pose;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: ExamLayout.tobiSide,
        child: Stack(fit: StackFit.expand, children: [
          const StaticArt([ToneLayer(ExamLayout.tobiTone, fadeAngle: 0, fadeStops: [0, 1])]),
          LayoutBuilder(builder: (context, box) {
            final card = Size(box.maxHeight * ExamLayout.cardShare / TorifudaSpec.aspect, box.maxHeight * ExamLayout.cardShare);
            final tobi = Size(box.maxHeight * ExamLayout.tobiShare * TobiStyle.aspect, box.maxHeight * ExamLayout.tobiShare);
            final center = Offset(box.maxWidth * (1 + ExamLayout.deckAt) / 2, box.maxHeight / 2);
            return ValueListenableBuilder<Duration>(
              valueListenable: race,
              builder: (context, t, _) {
                final done = pace.doneAt(t);
                Widget place(CardRef ref, {required bool text, Offset offset = Offset.zero, double angle = 0, double opacity = 1}) =>
                    Positioned(
                      left: center.dx - card.width / 2 + offset.dx,
                      top: center.dy - card.height / 2 + offset.dy,
                      width: card.width,
                      height: card.height,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: math.pi + angle,
                          child: TorifudaCard(poem: poems[ref.poemId], inverted: ref.inverted, showText: text, showNumber: false),
                        ),
                      ),
                    );
                final flying = [
                  for (var i = math.max(0, done - 1); i < done; i++)
                    if (t - pace.cardEnds[i] < ExamMotion.fly) i,
                ];
                return Stack(clipBehavior: Clip.none, children: [
                  Positioned(left: ExamLayout.tobiLeft, bottom: 0, width: tobi.width, height: tobi.height, child: Tobi(pose: pose(done))),
                  if (done + 1 < cards.length) place(cards[done + 1], text: false, offset: const Offset(0, -ExamLayout.underPeek)),
                  if (done < cards.length)
                    place(cards[done], text: t > Duration.zero, offset: Offset(_side(done) * ExamLayout.reach * _reach(t, done), 0)),
                  for (final i in flying) _flying(place, i, t),
                ]);
              },
            );
          }),
        ]),
      );

  /// Card [i] leaves to the left (−1) or the right (1).
  static double _side(int i) => i.isEven ? -1 : 1;

  /// How far into its nudge card [i] is at [t], 0–1.
  double _reach(Duration t, int i) {
    final left = pace.cardEnds[i] - t;
    if (left >= ExamMotion.reach || left <= Duration.zero) return 0;
    return 1 - left.inMicroseconds / ExamMotion.reach.inMicroseconds;
  }

  Widget _flying(
      Widget Function(CardRef, {required bool text, Offset offset, double angle, double opacity}) place, int i, Duration t) {
    final p = Curves.easeIn.transform((t - pace.cardEnds[i]).inMicroseconds / ExamMotion.fly.inMicroseconds);
    final side = _side(i);
    return place(
      cards[i],
      text: true,
      offset: Offset(side * (ExamLayout.reach + ExamLayout.flyDistance * p), -ExamLayout.flyRise * p),
      angle: side * ExamLayout.flySpin * p,
      opacity: 1 - p,
    );
  }
}

/// The strip between the two sides: Tobi's count and clock against the
/// player's, whose clock carries the penalties so far.
class Scoreboard extends StatelessWidget {
  const Scoreboard({
    super.key,
    required this.pace,
    required this.race,
    required this.done,
    required this.total,
    required this.penalty,
  });

  final TobiPace pace;
  final ValueListenable<Duration> race;

  /// The player's cards done, of [total].
  final int done, total;
  final Duration penalty;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ColoredBox(
      color: ExamLayout.strip,
      child: Padding(
        padding: ExamLayout.stripPadding,
        child: ValueListenableBuilder<Duration>(
          valueListenable: race,
          builder: (context, t, _) => Row(children: [
            Expanded(
              child: _Side(
                label: s.examTobi,
                done: pace.doneAt(t),
                total: total,
                clock: t < pace.total ? t : pace.total,
                alignment: CrossAxisAlignment.start,
              ),
            ),
            const SizedBox(width: ExamLayout.stripVsGap),
            const Text('VS',
                style: TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.stripVsFont, color: ExamLayout.stripLabel, height: 1)),
            const SizedBox(width: ExamLayout.stripVsGap),
            Expanded(
              child: _Side(label: s.examYou, done: done, total: total, clock: t + penalty, alignment: CrossAxisAlignment.end),
            ),
          ]),
        ),
      ),
    );
  }
}

/// One side of the [Scoreboard]: whose it is with their count, over their
/// clock.
class _Side extends StatelessWidget {
  const _Side({required this.label, required this.done, required this.total, required this.clock, required this.alignment});

  final String label;
  final int done, total;
  final Duration clock;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment == CrossAxisAlignment.start ? Alignment.centerLeft : Alignment.centerRight,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: alignment, children: [
          Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: ExamLayout.stripLabelFont, color: ExamLayout.stripLabel, height: 1)),
            const SizedBox(width: Gaps.small),
            Text('$done/$total',
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: ExamLayout.stripCountFont, color: ExamLayout.stripText, height: 1)),
          ]),
          const SizedBox(height: ExamLayout.stripLineGap),
          RaceClock(clock, style: const TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.stripClockFont, color: ExamLayout.stripText, height: 1)),
        ]),
      );
}

/// A running clock, mm:ss.d, in a box as wide as its widest reading so it
/// holds still while it ticks.
class RaceClock extends StatelessWidget {
  const RaceClock(this.time, {super.key, required this.style});
  final Duration time;
  final TextStyle style;

  /// [d] as mm:ss.d.
  static String format(Duration d) {
    final tenths = d.inMilliseconds ~/ 100;
    final m = tenths ~/ 600;
    final sec = tenths ~/ 10 % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.${tenths % 10}';
  }

  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.centerRight, children: [
        Opacity(opacity: 0, child: Text('00:00.0', style: style)),
        Text(format(time), style: style),
      ]);
}

/// "+10 s" rising toward the player's clock and fading: a new penalty.
/// Key it by the count of penalties, so each one pops anew.
class PenaltyPop extends StatelessWidget {
  const PenaltyPop({super.key});

  @override
  Widget build(BuildContext context) =>
      _Pop(text: S.of(context).examPenaltyPop(ExamTuning.missPenaltyMs ~/ Duration.millisecondsPerSecond));
}

class _Pop extends StatefulWidget {
  const _Pop({required this.text});
  final String text;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  late final _rise = AnimationController(vsync: this, duration: ExamMotion.penaltyPop)..forward();

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _rise,
          builder: (context, child) {
            final t = Curves.easeOut.transform(_rise.value);
            return Opacity(
              opacity: _rise.isCompleted ? 0 : (1 - _rise.value * _rise.value).clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, -ExamLayout.popRise * t), child: child),
            );
          },
          child: OutlinedText(widget.text,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.popFont, color: Palette.pink, height: 1),
              outline: Palette.ink,
              outlineWidth: ExamLayout.popOutline),
        ),
      );
}
