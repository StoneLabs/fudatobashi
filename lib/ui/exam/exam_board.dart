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
/// sideways at its time in [pace]; [race] is the time since GO. A quick
/// card leaves in a flash of speed lines, a slow one has him thinking it
/// over, and a mistake pops its penalty over his deck.
class TobiSide extends StatelessWidget {
  const TobiSide({super.key, required this.pace, required this.cards, required this.race, required this.pose});

  final TobiPace pace;
  final List<CardRef> cards;
  final ValueListenable<Duration> race;

  /// His pose at [race]'s time.
  final TobiPose Function(Duration t) pose;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: ExamLayout.tobiSide,
        child: Stack(fit: StackFit.expand, children: [
          const StaticArt([ToneLayer(ExamLayout.tobiTone, fadeAngle: 0, fadeStops: [0, 1])]),
          LayoutBuilder(builder: (context, box) {
            final card = Size(box.maxHeight * ExamLayout.cardShare / TorifudaSpec.aspect, box.maxHeight * ExamLayout.cardShare);
            final tobi = Size(box.maxHeight * ExamLayout.tobiShare * TobiStyle.aspect, box.maxHeight * ExamLayout.tobiShare);
            final center = Offset(box.maxWidth * (1 + ExamLayout.deckAt) / 2, box.maxHeight / 2);
            final deck = Rect.fromCenter(center: center, width: card.width, height: card.height);
            return ValueListenableBuilder<Duration>(
              valueListenable: race,
              builder: (context, t, _) {
                final done = pace.doneAt(t);
                Widget place(CardRef ref, {required bool text, Offset offset = Offset.zero, double angle = 0, double opacity = 1}) =>
                    Positioned.fromRect(
                      rect: deck.shift(offset),
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
                final quick = _since(t, done, ExamMotion.quickFlash, (i) => pace.beatOf(i) == TobiBeat.quick);
                final blunder = _since(t, done, ExamMotion.penaltyPop, pace.misses.contains);
                final thinking = done < cards.length &&
                    pace.beatOf(done) == TobiBeat.slow &&
                    t - pace.startOf(done) >= ExamTuning.tobiThinkAfter;
                return Stack(clipBehavior: Clip.none, children: [
                  if (quick != null) ..._quickLines(box.biggest, deck, quick),
                  Positioned(left: ExamLayout.tobiLeft, bottom: 0, width: tobi.width, height: tobi.height, child: Tobi(pose: pose(t))),
                  if (done + 1 < cards.length) place(cards[done + 1], text: false, offset: const Offset(0, -ExamLayout.underPeek)),
                  if (done < cards.length)
                    place(cards[done], text: t > Duration.zero, offset: Offset(_side(done) * ExamLayout.reach * _reach(t, done), 0)),
                  for (final i in flying) _flying(place, i, t),
                  if (quick != null) _quickWord(deck, quick),
                  if (thinking)
                    Positioned(
                      left: ExamLayout.tobiLeft + tobi.width * ExamLayout.thinkAt.dx,
                      top: box.maxHeight - tobi.height + tobi.height * ExamLayout.thinkAt.dy,
                      child: SpeechBalloon(
                        speaker: ExamLayout.thinkSpeaker,
                        padding: ExamLayout.thinkPadding,
                        child: Text(S.of(context).examTobiThinking,
                            style: const TextStyle(fontWeight: Weights.black, fontSize: ExamLayout.thinkFont)),
                      ),
                    ),
                  if (blunder != null)
                    Positioned(
                      left: deck.left,
                      right: box.maxWidth - deck.right,
                      top: deck.top + deck.height * ExamLayout.tobiPopAt,
                      child: Center(child: PenaltyLettering(progress: blunder.$2)),
                    ),
                ]);
              },
            );
          }),
        ]),
      );

  /// Card [i] leaves to the left (−1) or the right (1).
  static double _side(int i) => i.isEven ? -1 : 1;

  /// The latest of his cards gone by [t] that [which] picks, if it went
  /// less than [length] ago, with how far into [length] it is, 0–1.
  (int, double)? _since(Duration t, int done, Duration length, bool Function(int i) which) {
    for (var i = done - 1; i >= 0 && t - pace.cardEnds[i] < length; i--) {
      if (which(i)) return (i, (t - pace.cardEnds[i]).inMicroseconds / length.inMicroseconds);
    }
    return null;
  }

  /// A quick card's flash: a burst behind his deck and speed lines across
  /// his side the way the card went, fading over [ExamMotion.quickFlash].
  List<Widget> _quickLines(Size side, Rect deck, (int, double) quick) {
    final (i, p) = quick;
    final fade = 1 - Curves.easeIn.transform(p);
    final burst = deck.inflate(deck.longestSide * ExamLayout.quickBurstReach);
    return [
      Positioned.fromRect(
        rect: burst,
        child: Opacity(
          opacity: fade,
          child: Transform.scale(
            scale: ExamLayout.quickBurstFrom + (1 - ExamLayout.quickBurstFrom) * Curves.easeOut.transform(p),
            child: const CustomPaint(painter: FocusLinesPainter(ExamLayout.quickBurst)),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: deck.top,
        height: deck.height,
        child: Opacity(
          opacity: fade,
          child: Transform.flip(
            flipX: _side(i) > 0,
            child: const CustomPaint(painter: SpeedLinesPainter(ExamLayout.quickLines)),
          ),
        ),
      ),
    ];
  }

  /// The quick card's sound, lettered over his deck as it flashes.
  Widget _quickWord(Rect deck, (int, double) quick) {
    final (i, p) = quick;
    return Positioned(
      left: deck.left,
      top: deck.top + deck.height * ExamLayout.quickWordAt,
      child: Opacity(
        opacity: (1 - p * p).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: _side(i) * ExamLayout.quickWordTurnDeg * math.pi / 180,
          child: Transform.scale(
            scale: ExamLayout.quickWordFrom + (1 - ExamLayout.quickWordFrom) * Curves.easeOutBack.transform(math.min(1, p * 3)),
            child: const OutlinedText(ExamLayout.quickWord,
                style: TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.quickWordFont, color: Palette.sun, height: 1),
                outline: Palette.ink,
                outlineWidth: ExamLayout.quickWordOutline),
          ),
        ),
      ),
    );
  }

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

/// The strip between the two sides: Tobi's count and time against the
/// player's. Both times carry the penalties so far; the player's holds at
/// [scored] once their last card is in.
class Scoreboard extends StatelessWidget {
  const Scoreboard({
    super.key,
    required this.pace,
    required this.race,
    required this.done,
    required this.total,
    required this.penalty,
    this.scored,
  });

  final TobiPace pace;
  final ValueListenable<Duration> race;

  /// The player's cards done, of [total].
  final int done, total;
  final Duration penalty;

  /// The player's time with penalties, once they are done.
  final Duration? scored;

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
                clock: pace.timeAt(t),
                alignment: CrossAxisAlignment.start,
              ),
            ),
            const SizedBox(width: ExamLayout.stripVsGap),
            const Text('VS',
                style: TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.stripVsFont, color: ExamLayout.stripLabel, height: 1)),
            const SizedBox(width: ExamLayout.stripVsGap),
            Expanded(
              child: _Side(
                  label: s.examYou, done: done, total: total, clock: scored ?? t + penalty, alignment: CrossAxisAlignment.end),
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

/// Over the player's side once their last card is in while Tobi plays on:
/// "Waiting for Tobi…", and the player's time against Tobi's, still
/// running, until his passes it or he finishes.
class WaitingForTobi extends StatelessWidget {
  const WaitingForTobi({super.key, required this.pace, required this.race, required this.scored});

  final TobiPace pace;
  final ValueListenable<Duration> race;

  /// The player's time with penalties.
  final Duration scored;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const clock = TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.waitClockFont, height: 1);
    const label = TextStyle(fontWeight: Weights.black, fontSize: ExamLayout.waitLabelFont);
    Widget row(String name, Widget time) => Row(children: [
          Expanded(child: Text(name, style: label)),
          const SizedBox(width: Gaps.small),
          time,
        ]);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: ExamLayout.waitWidth,
            child: MangaPanel(
              shape: const PanelShape(topLeft: Offset(0, ExamLayout.waitCut)),
              padding: ExamLayout.waitPadding,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(s.examWaiting,
                    style: const TextStyle(
                        fontFamily: Fonts.display, fontSize: ExamLayout.waitTitleFont, height: TypeScale.displayLineHeight)),
                const SizedBox(height: ExamLayout.waitTitleGap),
                row(s.examYourTime, RaceClock(scored, style: clock)),
                const SizedBox(height: ExamLayout.waitRowGap),
                ValueListenableBuilder<Duration>(
                  valueListenable: race,
                  builder: (context, t, _) =>
                      row(s.examTobiTime, RaceClock(pace.timeAt(t), style: clock.copyWith(color: Palette.pinkDeep))),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
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
class PenaltyPop extends StatefulWidget {
  const PenaltyPop({super.key});

  @override
  State<PenaltyPop> createState() => _PenaltyPopState();
}

class _PenaltyPopState extends State<PenaltyPop> with SingleTickerProviderStateMixin {
  late final _rise = AnimationController(vsync: this, duration: ExamMotion.penaltyPop)..forward();

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _rise,
        builder: (context, _) => PenaltyLettering(progress: _rise.isCompleted ? 1 : _rise.value),
      );
}

/// A penalty's "+10 s", [progress] (0–1) of the way through rising and
/// fading out: the player's, or Tobi's over his deck.
class PenaltyLettering extends StatelessWidget {
  const PenaltyLettering({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final rise = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    return IgnorePointer(
      child: Opacity(
        opacity: progress >= 1 ? 0 : (1 - progress * progress).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -ExamLayout.popRise * rise),
          child: OutlinedText(S.of(context).examPenaltyPop(ExamTuning.missPenaltyMs ~/ Duration.millisecondsPerSecond),
              style: const TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.popFont, color: Palette.pink, height: 1),
              outline: Palette.ink,
              outlineWidth: ExamLayout.popOutline),
        ),
      ),
    );
  }
}
