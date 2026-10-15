import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/exam_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// The exam's opening over the board, on the time since the screen opened
/// ([clock]): Tobi's よろしくお願いします, the count of three, and GO! as
/// play starts (see [ExamMotion]). It takes no touches.
class ExamOpening extends StatelessWidget {
  const ExamOpening({super.key, required this.clock});
  final ValueListenable<Duration> clock;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: ValueListenableBuilder<Duration>(
          valueListenable: clock,
          builder: (context, t, _) {
            if (t < ExamMotion.greeting) return _scrimmed(_Greeting(t, still: still));
            if (t < ExamMotion.start) {
              final into = t - ExamMotion.greeting;
              final k = into.inMicroseconds ~/ ExamMotion.beat.inMicroseconds;
              final beat = into - ExamMotion.beat * k;
              return _scrimmed(_Lettering(
                '${ExamMotion.count - k}',
                at: beat,
                spec: ExamMotion.number,
                still: still,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.countFont, color: Palette.sun, height: 1),
                outline: ExamLayout.countOutline,
              ));
            }
            final go = t - ExamMotion.start;
            if (go >= ExamMotion.go) return const SizedBox.shrink();
            final fade = (go.inMicroseconds / ExamMotion.go.inMicroseconds);
            return Opacity(
              opacity: (1 - fade * fade).clamp(0.0, 1.0),
              child: _Lettering(
                ExamLayout.go,
                at: go,
                spec: ExamMotion.goIn,
                still: still,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: ExamLayout.goFont, color: Palette.pink, height: 1),
                outline: ExamLayout.countOutline,
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _scrimmed(Widget child) => ColoredBox(color: ExamLayout.scrim, child: child);
}

/// [spec]'s eased progress at [t] (at rest when [still]).
double _progress(EntranceSpec spec, Duration t, {required bool still}) {
  if (still) return 1;
  final x = ((t - spec.delay).inMicroseconds / spec.duration.inMicroseconds).clamp(0.0, 1.0);
  return x >= 1 ? 1 : spec.curve.transform(x);
}

/// Focus lines bursting out from the middle of the screen, [t] into
/// [ExamMotion.burst].
class _Burst extends StatelessWidget {
  const _Burst(this.t, {required this.still});
  final Duration t;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final p = _progress(ExamMotion.burst, t, still: still);
    if (p <= 0 || p >= 1) return const SizedBox.shrink();
    return Opacity(
      opacity: 1 - p,
      child: Transform.scale(
        scale: lerpDouble(ExamLayout.burstFrom, ExamLayout.burstTo, p)!,
        child: const CustomPaint(size: Size.infinite, painter: FocusLinesPainter(ExamLayout.burst)),
      ),
    );
  }
}

/// Big outlined lettering slamming into the middle of the screen with a
/// burst of focus lines behind it, [at] into its [spec].
class _Lettering extends StatelessWidget {
  const _Lettering(this.text, {required this.at, required this.spec, required this.still, required this.style, required this.outline});

  final String text;
  final Duration at;
  final EntranceSpec spec;
  final bool still;
  final TextStyle style;
  final double outline;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        _Burst(at, still: still),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: EntranceFrame(
                from: spec.from,
                progress: _progress(spec, at, still: still),
                child: OutlinedText(text, style: style, outline: Palette.ink, outlineWidth: outline),
              ),
            ),
          ),
        ),
      ]);
}

/// よろしくお願いします, a line at a time, over Tobi waving.
class _Greeting extends StatelessWidget {
  const _Greeting(this.t, {required this.still});
  final Duration t;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lines = ExamLayout.greeting.split('\n');
    const style = TextStyle(
        fontFamily: Fonts.display, fontSize: ExamLayout.greetingFont, color: Palette.sun, height: ExamLayout.greetingLineHeight);
    Widget enter(EntranceSpec spec, Widget child) =>
        EntranceFrame(from: spec.from, progress: _progress(spec, t, still: still), child: child);
    return Stack(fit: StackFit.expand, children: [
      _Burst(t - ExamMotion.greetingFirst.delay, still: still),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              enter(
                ExamMotion.greetingTobi,
                Transform.rotate(
                  angle: ExamLayout.greetingTurnDeg * math.pi / 180,
                  child: SizedBox.fromSize(size: ExamLayout.greetingTobi, child: const Tobi(pose: TobiPose.waving)),
                ),
              ),
              const SizedBox(height: ExamLayout.greetingGap),
              for (final (i, line) in lines.indexed)
                enter(
                  i == 0 ? ExamMotion.greetingFirst : ExamMotion.greetingSecond,
                  OutlinedText(line, style: style, outline: Palette.ink, outlineWidth: ExamLayout.greetingOutline),
                ),
              const SizedBox(height: ExamLayout.greetingGap),
              enter(ExamMotion.greetingSub, InkTag(s.examGreetingSub, color: Palette.pink, textColor: Palette.ink)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

/// The race's end over the frozen board: [text] slammed down with a burst
/// of focus lines.
class ExamShout extends StatelessWidget {
  const ExamShout(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ColoredBox(
          color: ExamLayout.endScrim,
          child: EntranceStage(
            length: ExamMotion.shoutLength,
            child: Stack(fit: StackFit.expand, children: [
              ImpactBurst(
                ExamMotion.burst,
                burst: ExamLayout.burst,
                size: MediaQuery.sizeOf(context),
                fromScale: ExamLayout.burstFrom,
                toScale: ExamLayout.burstTo,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Entrance(
                      ExamMotion.shout,
                      child: Transform.rotate(
                        angle: ExamLayout.shoutTurnDeg * math.pi / 180,
                        child: OutlinedText(text,
                            style: const TextStyle(
                                fontFamily: Fonts.display, fontSize: ExamLayout.shoutFont, color: Palette.sun, height: 1),
                            outline: Palette.ink,
                            outlineWidth: ExamLayout.shoutOutline),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}
