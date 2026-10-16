import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
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
/// arrow pointing at it, and Tobi, large, saying what it is.
///
/// A stop moves on once the player taps anywhere, the spot and Tobi's
/// balloon included, after the line has finished typing. The scrim swallows
/// every tap, so nothing underneath is reached. The
/// practice stop's spot is 修行 itself, so advancing it plays
/// the tutorial round for real; the tour only ends once that round is won
/// ([onDone]).
/// The back button and the system back both step back one stop; the skip
/// button, when there is [onSkip], ends the tour on any stop.
///
/// A one-stop scene ([TourStep.examIntro]) passes [onElsewhere] instead: a
/// tap away from its spot, the balloon included, closes it.
class TourOverlay extends StatefulWidget {
  const TourOverlay({super.key, required this.steps, required this.keys, required this.onDone, this.onSkip, this.onElsewhere});

  final List<TourStep> steps;
  final TourKeys keys;
  final VoidCallback onDone;
  final VoidCallback? onSkip;
  final VoidCallback? onElsewhere;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  int _index = 0;
  Rect? _spot;
  bool _practising = false;

  /// The practice round was left before its end.
  bool _practiceLeft = false;

  /// Lines shown to the end already: instant if the player comes back to
  /// them with Back.
  final Set<String> _seenTexts = {};

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

  Future<void> _advance() async {
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

  void _back() {
    if (_index == 0 || _practising) return;
    setState(() {
      _index--;
      _spot = null;
      _practiceLeft = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
    final s = S.of(context);
    final step = _step;
    final text = _practiceLeft ? s.tourPracticeAgain : step.line(s);
    final ready = _seenTexts.contains(text);
    final safe = MediaQuery.paddingOf(context);

    // A tap anywhere on the scrim moves the tour on, the target included;
    // the exam intro closes instead, unless the tap is on its target.
    void onTap(TapUpDetails d) {
      if (!ready) return;
      final elsewhere = widget.onElsewhere;
      if (elsewhere == null || (_spot != null && _spot!.contains(d.localPosition))) {
        _advance();
      } else {
        elsewhere();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: LayoutBuilder(builder: (context, box) {
        final layout = TourLayout.of(size: box.biggest, safe: safe, spot: step.spot == null ? null : _spot, seed: _index);
        final tobiLeft = _index.isEven;
        return Stack(children: [
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTapUp: onTap)),
          // Purely visual: never absorbs a tap meant for the layers below it
          // (a plain CustomPaint otherwise claims its whole box).
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(child: CustomPaint(painter: _BackdropPainter(layout.hole))),
            ),
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
                text: text,
                ready: ready,
                hint: step.hint?.call(s) ??
                    (step.practice
                        ? s.tourTapPractice
                        : _index == widget.steps.length - 1
                            ? s.tourTapDone
                            : s.tourTapHint),
                pose: step.pose,
                tobiLeft: tobiLeft,
                onTextDone: () => setState(() => _seenTexts.add(text)),
                onContinue: widget.onElsewhere == null ? _advance : null,
              ),
            ),
          ),
          // Back and Skip sit over the brand title, which no stop spotlights,
          // clear of the level and Settings buttons on the right.
          Positioned(
            left: safe.left + Gaps.gutter,
            top: safe.top + Gaps.gutter,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_index > 0) InkIconButton(icon: IconArt.back, onTap: _back, semanticLabel: s.back),
              if (_index > 0 && widget.onSkip != null) const SizedBox(width: TourStyle.skipGap),
              if (widget.onSkip case final skip?)
                SizedBox(
                  height: ButtonMetrics.iconButton,
                  child: InkButton(
                    onTap: _practising ? null : skip,
                    padding: TourStyle.skipPadding,
                    child: Text(s.tourSkip, style: const TextStyle(fontWeight: Weights.black, fontSize: TourStyle.skipFont)),
                  ),
                ),
            ]),
          ),
        ]);
      }),
    );
  }
}

/// Tobi, large, with the balloon beside him.
class _TobiSays extends StatelessWidget {
  const _TobiSays({
    required this.text,
    required this.ready,
    required this.hint,
    required this.pose,
    required this.tobiLeft,
    required this.onTextDone,
    this.onContinue,
  });

  final String text, hint;

  /// The line has finished typing (or was already seen), so the target tap
  /// or continue button now works.
  final bool ready;
  final TobiPose pose;
  final bool tobiLeft;
  final VoidCallback onTextDone;

  /// Null when only the spot moves the stop on.
  final VoidCallback? onContinue;

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
      final content = SpeechBalloon(
        speaker: switch ((stacked, tobiLeft)) {
          (false, true) => TourStyle.speakerLeft,
          (false, false) => TourStyle.speakerRight,
          (true, true) => TourStyle.speakerBelowLeft,
          (true, false) => TourStyle.speakerBelowRight,
        },
        padding: TourStyle.balloonPadding,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(child: _TypingText(text: text, instant: ready, onDone: onTextDone)),
          const SizedBox(height: TourStyle.hintGap),
          _HintRow(hint: hint, ready: ready, dim: onContinue == null),
        ]),
      );
      // The whole balloon is the continue control, not just its hint line.
      final bubble = onContinue == null
          ? content
          : Pressable(onTap: ready ? onContinue : null, builder: (context, pressed) => content);
      final balloon = Expanded(
        child: Semantics(liveRegion: true, label: Phrases.spoken(text), child: bubble),
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

/// [text] typed out a character at a time, unskippably, at
/// [TourTuning.charInterval]. [instant] shows it already complete, for a
/// step the player has come back to with Back. It types even under reduced
/// motion — it is text, not motion.
class _TypingText extends StatefulWidget {
  const _TypingText({required this.text, required this.instant, required this.onDone});

  final String text;
  final bool instant;
  final VoidCallback onDone;

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  int _shown = 0;
  int _target = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(_TypingText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _restart();
  }

  void _restart() {
    _ticker.stop();
    _target = Phrases.visibleLength(widget.text);
    _shown = widget.instant ? _target : 0;
    if (!widget.instant) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final shown = (elapsed.inMicroseconds / TourTuning.charInterval.inMicroseconds).floor().clamp(0, _target);
    if (shown != _shown) setState(() => _shown = shown);
    if (shown >= _target) {
      _ticker.stop();
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text.rich(
        Phrases.typed(widget.text, _shown, hidden: TourStyle.typingHidden),
        style: const TextStyle(fontSize: TourStyle.font),
      );
}

/// The line's hint: what tapping does, faded in only once the line has
/// finished typing. At full ink when the balloon itself is a tap target,
/// dimmed when only the spot is.
class _HintRow extends StatelessWidget {
  const _HintRow({required this.hint, required this.ready, required this.dim});

  final String hint;
  final bool ready;
  final bool dim;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: ready ? 1 : 0,
        duration: TourStyle.continueFade,
        child: Text(hint,
            style: TextStyle(
              fontSize: TourStyle.hintFont,
              fontWeight: Weights.bold,
              color: dim ? Palette.inkSoft : null,
            )),
      );
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
