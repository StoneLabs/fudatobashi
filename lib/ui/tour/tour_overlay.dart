import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/play_screen.dart';
import 'tour_anchor.dart';
import 'tour_arrows.dart';
import 'tour_layout.dart';
import 'tour_steps.dart';

/// Takes Tobi's tour of Home again: back to the tabs, where it starts.
void replayTour(BuildContext context) {
  final progress = ProgressScope.read(context);
  Navigator.of(context).popUntil((r) => r.isFirst);
  progress.updateSettings(progress.settings.copyWith(toured: false));
}

/// Tobi's tour of Home, over it: the screen greyed out but for a spotlight
/// on each [TourSpot] in turn, a spray of scribbled arrows and a marquee
/// arrow pointing at it, and Tobi, large, saying what it is. A tap moves
/// on; the practice stop plays the tutorial round and stays until it is
/// done, so the tour ends only after it ([onDone]).
class TourOverlay extends StatefulWidget {
  const TourOverlay({super.key, required this.steps, required this.keys, required this.onDone});

  final List<TourStep> steps;
  final TourKeys keys;
  final VoidCallback onDone;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  int _index = 0;
  Rect? _spot;
  bool _practising = false;

  /// The practice round was left before its end.
  bool _practiceLeft = false;

  TourStep get _step => widget.steps[_index];

  /// Where the current spot is laid out, checked after every frame this
  /// builds, so the spotlight follows the real layout.
  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final spot = _step.spot;
    final rect = spot == null || box is! RenderBox ? null : widget.keys.rectOf(spot, box);
    if (rect != _spot) setState(() => _spot = rect);
  }

  Future<void> _next() async {
    if (_practising) return;
    if (_step.practice) {
      _practising = true;
      final done = await Navigator.of(context).push<bool>(
        MangaRoute(transition: MangaTransition.zoom, builder: (_) => PlayScreen.tutorial()),
      );
      _practising = false;
      if (!mounted) return;
      if (done != true) {
        setState(() => _practiceLeft = true);
        return;
      }
    }
    if (_index == widget.steps.length - 1) {
      widget.onDone();
      return;
    }
    setState(() {
      _index++;
      _spot = null;
      _practiceLeft = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
    final s = S.of(context);
    final step = _step;
    return LayoutBuilder(builder: (context, box) {
      final layout = TourLayout.of(
        size: box.biggest,
        safe: MediaQuery.paddingOf(context),
        spot: step.spot == null ? null : _spot,
        seed: _index,
      );
      final tobiLeft = _index.isEven;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Stack(children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _BackdropPainter(layout.hole))),
          ),
          Positioned.fill(
            child: TourArrows(
              key: ValueKey(('arrows', _index, layout.hole)),
              scribbles: layout.scribbles,
              marquee: layout.marquee,
              label: s.tourHere,
            ),
          ),
          Positioned.fromRect(
            rect: layout.block,
            child: _PopIn(
              key: ValueKey(('tobi', _index, _practiceLeft)),
              child: _TobiSays(
                text: _practiceLeft ? s.tourPracticeAgain : step.line(s),
                hint: step.practice
                    ? s.tourTapPractice
                    : _index == widget.steps.length - 1
                        ? s.tourTapDone
                        : s.tourTapHint,
                pose: step.pose,
                tobiLeft: tobiLeft,
              ),
            ),
          ),
        ]),
      );
    });
  }
}

/// Tobi, large, with the balloon beside him.
class _TobiSays extends StatelessWidget {
  const _TobiSays({required this.text, required this.hint, required this.pose, required this.tobiLeft});

  final String text, hint;
  final TobiPose pose;
  final bool tobiLeft;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final stacked = box.maxHeight >= TourStyle.stackAt;
      final tobiHeight = box.maxHeight * (stacked ? TourStyle.stackedTobi : TourStyle.besideTobi);
      // Tobi faces the balloon.
      final tobi = SizedBox(
        height: tobiHeight,
        width: tobiHeight * TobiStyle.aspect,
        child: Transform.flip(flipX: !tobiLeft, child: Tobi(key: ValueKey(pose), pose: pose)),
      );
      final balloon = Expanded(
        child: Semantics(
          liveRegion: true,
          child: SpeechBalloon(
            speaker: switch ((stacked, tobiLeft)) {
              (false, true) => TourStyle.speakerLeft,
              (false, false) => TourStyle.speakerRight,
              (true, true) => TourStyle.speakerBelowLeft,
              (true, false) => TourStyle.speakerBelowRight,
            },
            padding: TourStyle.balloonPadding,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text.rich(Phrases.span(text), style: const TextStyle(fontSize: TourStyle.font)),
              const SizedBox(height: TourStyle.hintGap),
              Text(
                hint,
                style: const TextStyle(fontSize: TourStyle.hintFont, fontWeight: Weights.bold, color: Palette.inkSoft),
              ),
            ]),
          ),
        ),
      );
      if (stacked) {
        return Column(children: [
          balloon,
          Align(alignment: tobiLeft ? Alignment.centerLeft : Alignment.centerRight, child: tobi),
        ]);
      }
      return Row(children: tobiLeft ? [tobi, balloon] : [balloon, tobi]);
    });
  }
}

/// [child] popping in, springy (at rest under reduced motion).
class _PopIn extends StatelessWidget {
  const _PopIn({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : TourStyle.pop,
        curve: Curves.easeOutBack,
        child: child,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: TourStyle.popFrom + (1 - TourStyle.popFrom) * t, child: child),
        ),
      );
}

/// The greyed-out screen, lit around the spotlight [hole], and the
/// spotlight's paper-and-ink ring.
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.hole);
  final RRect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final hole = this.hole;
    final wall = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screen);
    if (hole != null) wall.addRRect(hole);
    final glowAt = hole?.center ?? screen.center;
    canvas.drawPath(
      wall,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(glowAt.dx / size.width * 2 - 1, glowAt.dy / size.height * 2 - 1),
          radius: TourStyle.dimReach * size.longestSide / size.shortestSide,
          colors: const [TourStyle.dimNear, TourStyle.dimFar],
        ).createShader(screen),
    );
    if (hole == null) return;
    final ring = Paint()..style = PaintingStyle.stroke;
    canvas.drawRRect(
      hole.inflate(TourStyle.spotRing / 2),
      ring
        ..color = Palette.paper
        ..strokeWidth = TourStyle.spotRing,
    );
    canvas.drawRRect(
      hole.inflate(TourStyle.spotRing),
      ring
        ..color = Palette.ink
        ..strokeWidth = TourStyle.spotInk,
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.hole != hole;
}
