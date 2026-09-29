import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/torifuda_spec.dart';
import '../../data/poem.dart';
import '../../domain/play_session.dart';
import '../../state/settings.dart';
import '../torifuda/torifuda_painter.dart';
import 'swipe_gesture.dart';

/// The stack of cards the player flicks away.
///
/// Timing contract (see PlaySession):
/// * reveal = vsync timestamp of the first frame that paints the top card's
///   glyphs. The card underneath is drawn blank until then, so nothing can be
///   read early.
/// * response = pointer-down timestamp of the committing touch, or, if that
///   finger was already down before the reveal, its first movement after it.
///
/// Don't know is marked per [dontKnowInput] (see [SwipeGesture]), or from
/// outside with [SwipeDeckState.markDontKnow].
///
/// A [startCard] lies on top of the deck until it is swiped away, in any
/// direction; the first card stays blank under it, so its timing only starts
/// once the start card is gone. The start card is never an attempt.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.session,
    required this.live,
    this.dontKnowInput = DefaultSettings.dontKnowInput,
    this.showNumber = true,
    this.haptics = true,
    this.onCommitted,
    this.startCard,
    this.onStarted,
    this.cardFace,
  });

  final PlaySession session;

  /// False keeps the top card blank (while the play screen shows something
  /// else, e.g. a new card's introduction).
  final bool live;

  final DontKnowInput dontKnowInput;
  final bool showNumber;

  /// Follows `settings.haptics`; never affects the timing contract below.
  final bool haptics;
  final ValueChanged<Attempt>? onCommitted;

  final Widget? startCard;

  /// The start card has been swiped away.
  final VoidCallback? onStarted;

  /// Draws a card instead of its torifuda (see [CardFace]).
  final CardFace? cardFace;

  @override
  State<SwipeDeck> createState() => SwipeDeckState();
}

/// Draws [card]; blank, so nothing can be read early, unless [text].
typedef CardFace = Widget Function(CardRef card, bool text);

class _Pointer {
  _Pointer(this.id, this.downTs, this.downPos, this.downBeforeReveal) : pos = downPos;
  final int id;
  final Duration downTs;
  final Offset downPos;
  final bool downBeforeReveal;
  final VelocityTracker tracker = VelocityTracker.withKind(PointerDeviceKind.touch);
  Offset pos;
  Offset? posAtReveal;
  Duration? moveAfterRevealTs;
  bool consumed = false;
}

class _Flying {
  _Flying(this.face, this.from, this.dir, this.speed, this.start, this.tilt);
  final Widget face;
  final Offset from;
  final Offset dir;
  final double speed;
  final Duration start;
  final double tilt;
}

class SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _now = Duration.zero;
  Duration _lastTick = Duration.zero;

  final _pointers = <int, _Pointer>{};
  int? _dragger;
  Offset _dragBase = Offset.zero;
  Offset _drag = Offset.zero;
  bool _springing = false;
  final _flying = <_Flying>[];
  bool _revealScheduled = false;
  Size _card = Size.zero;
  late bool _startCardUp = widget.startCard != null;

  /// While a drag is parked in the don't-know hold: when it began, in ticker
  /// time (drives the feedback) and in pointer time (the commit timestamp).
  Duration? _holdStart;
  Duration? _holdStartTs;

  PlaySession get _s => widget.session;

  /// The top card follows the finger: the start card, or a revealed card.
  bool get _draggable => _startCardUp || _s.currentRevealed;

  double get _commitDistance =>
      math.max(SwipeTuning.commitDistanceMin, _card.width * SwipeTuning.commitDistanceWidthFraction);

  /// The start card goes whichever way it is swiped.
  SwipeGesture get _gesture => SwipeGesture(
        input: _startCardUp ? DontKnowInput.off : widget.dontKnowInput,
        commitDistance: _commitDistance,
      );

  double get _holdProgress => _holdStart == null ? 0 : SwipeGesture.holdProgress(_now - _holdStart!);

  @override
  void initState() {
    super.initState();
    _s.addListener(_onSession);
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onSession);
      widget.session.addListener(_onSession);
    }
  }

  @override
  void dispose() {
    _s.removeListener(_onSession);
    _ticker.dispose();
    super.dispose();
  }

  void _onSession() => setState(() {});

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _now = elapsed;
    _flying.removeWhere((f) => (_now - f.start).inMicroseconds / 1e6 > SwipeTuning.flyDuration);
    if (_holdStart != null && _gesture.onHold(_now - _holdStart!) == SwipeVerdict.dontKnow) {
      _commitHeld();
    }
    if (_springing) {
      _drag *= math.exp(-dt * SwipeTuning.springDecay);
      if (_drag.distance < 0.5) {
        _drag = Offset.zero;
        _springing = false;
      }
    }
    if (_flying.isEmpty && !_springing && _holdStart == null) _ticker.stop();
    setState(() {});
  }

  void _animate() {
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _now = Duration.zero;
      _ticker.start();
    }
  }

  void _scheduleRevealIfNeeded() {
    if (!widget.live || _startCardUp || _s.finished || _s.currentRevealed || _revealScheduled) return;
    _revealScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted || !widget.live || _s.currentRevealed) return;
      _s.revealed(SchedulerBinding.instance.currentSystemFrameTimeStamp);
      for (final p in _pointers.values) {
        p.posAtReveal = p.pos;
      }
    });
  }

  // ---------------------------------------------------------------- input

  void _onDown(PointerDownEvent e) {
    final p = _Pointer(e.pointer, e.timeStamp, e.localPosition, !_s.currentRevealed);
    p.tracker.addPosition(e.timeStamp, e.localPosition);
    _pointers[e.pointer] = p;
    if (_dragger == null && _draggable) {
      _dragger = e.pointer;
      _springing = false;
      _dragBase = _drag;
    }
  }

  void _onMove(PointerMoveEvent e) {
    final p = _pointers[e.pointer];
    if (p == null) return;
    p.pos = e.localPosition;
    p.tracker.addPosition(e.timeStamp, e.localPosition);
    if (p.consumed || !_draggable) return;
    if (_s.currentRevealed && p.downBeforeReveal && p.moveAfterRevealTs == null) {
      if ((p.pos - (p.posAtReveal ?? p.downPos)).distance > SwipeTuning.revealMoveSlop) {
        p.moveAfterRevealTs = e.timeStamp;
      }
    }
    if (_dragger == null) {
      _dragger = p.id;
      _springing = false;
      _dragBase = _drag - (p.pos - p.downPos);
    }
    if (_dragger != p.id) return;
    setState(() => _drag = _dragBase + (p.pos - p.downPos));
    switch (_gesture.onMove(_drag, holding: _holdStart != null)) {
      case SwipeVerdict.hold:
        if (_holdStart == null) _startHold(e.timeStamp);
      case SwipeVerdict.known:
        _commitPointer(p, e.timeStamp, p.tracker.getVelocity().pixelsPerSecond, Outcome.known);
      default:
        _holdStart = null;
    }
  }

  void _onUp(PointerUpEvent e) {
    final p = _pointers.remove(e.pointer);
    if (p == null) return;
    if (!p.consumed && _dragger == p.id && _draggable) {
      final v = p.tracker.getVelocity().pixelsPerSecond;
      if (_gesture.onRelease(_drag, v) == SwipeVerdict.known) {
        _commitPointer(p, e.timeStamp, v, Outcome.known);
      } else {
        _release();
      }
    }
    if (_dragger == p.id) _dragger = null;
  }

  void _onCancel(PointerCancelEvent e) {
    final p = _pointers.remove(e.pointer);
    if (p != null && _dragger == p.id) {
      _dragger = null;
      _release();
    }
  }

  void _release() {
    _holdStart = null;
    _springing = true;
    _animate();
  }

  void _startHold(Duration ts) {
    _animate();
    _holdStart = _now;
    _holdStartTs = ts;
  }

  /// The held finger waited out the dwell: the card drops as don't know.
  void _commitHeld() {
    final p = _pointers[_dragger];
    if (p == null) return;
    _commitPointer(p, _holdStartTs! + SwipeTuning.dontKnowHoldDwell, Offset.zero, Outcome.dontKnow);
  }

  void _commitPointer(_Pointer p, Duration ts, Offset velocity, Outcome outcome) {
    p.consumed = true;
    if (_startCardUp) {
      _dismissStartCard(velocity);
      return;
    }
    final responseTs = p.downBeforeReveal ? (p.moveAfterRevealTs ?? ts) : p.downTs;
    _commit(responseTs, ts, velocity, outcome);
  }

  /// The start card flies off and the first card can be revealed: on the
  /// next frame, like any card after a commit.
  void _dismissStartCard(Offset velocity) {
    _launch(_Shadowed(child: widget.startCard!), velocity);
    setState(() => _startCardUp = false);
    if (widget.haptics) HapticFeedback.selectionClick();
    widget.onStarted?.call();
  }

  /// Marks the card on top as don't know (the play screen's button), timed
  /// from [responseTs], the button's pointer-down.
  void markDontKnow(Duration responseTs) {
    if (!_s.currentRevealed) return;
    final p = _pointers[_dragger];
    if (p != null) p.consumed = true;
    _commit(responseTs, responseTs, const Offset(0, SwipeTuning.minFlySpeed), Outcome.dontKnow);
  }

  void _commit(Duration responseTs, Duration commitTs, Offset velocity, Outcome outcome) {
    final card = _s.current;
    if (card == null) return;
    final face = _face(card, text: true);
    _launch(
      outcome == Outcome.dontKnow ? Stack(fit: StackFit.expand, children: [face, const _DontKnowMark(progress: 1)]) : face,
      velocity,
    );
    _s.commit(responseTs: responseTs, commitTs: commitTs, outcome: outcome);
    if (widget.haptics) {
      outcome == Outcome.dontKnow ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick();
    }
    final a = _s.lastAttempt;
    if (a != null) widget.onCommitted?.call(a);
  }

  /// Sends the top card, drawn as [face], flying off from where it was
  /// dragged to.
  void _launch(Widget face, Offset velocity) {
    final dirVec = _drag.distance > 12 ? _drag : (velocity.distance > 0 ? velocity : _drag);
    final dir = dirVec.distance == 0 ? const Offset(1, 0) : dirVec / dirVec.distance;
    _flying.add(_Flying(
      face,
      _drag,
      dir,
      math.max(velocity.distance, SwipeTuning.minFlySpeed),
      _ticker.isActive ? _now : Duration.zero,
      _tiltFor(_drag),
    ));
    _dragger = null;
    _drag = Offset.zero;
    _springing = false;
    _holdStart = null;
    _animate();
  }

  Widget _face(CardRef ref, {required bool text}) => _Shadowed(
        child: widget.cardFace?.call(ref, text) ??
            TorifudaCard(
              poem: poems[ref.poemId],
              inverted: ref.inverted,
              mask: ref.mask,
              showText: text,
              showNumber: widget.showNumber,
            ),
      );

  double _tiltFor(Offset d) => _card.width == 0 ? 0 : (d.dx / _card.width) * SwipeTuning.tiltFactor;

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    _scheduleRevealIfNeeded();
    return LayoutBuilder(builder: (context, c) {
      final maxH = c.maxHeight * SwipeTuning.cardHeightFraction / TorifudaSpec.aspect;
      final w = math.min(c.maxWidth * SwipeTuning.cardWidthFraction, maxH);
      _card = Size(w, w * TorifudaSpec.aspect);
      final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
      final current = _s.current;
      // Under the top card, blank: the card up next, and on a deck of three
      // or more, one more peeking out below the stack for depth.
      final under = _startCardUp ? current : _s.next;
      final stacked = _s.cards.length - _s.index + (_startCardUp ? 1 : 0);
      final progress = (_drag.distance / _commitDistance).clamp(0.0, 1.0);

      Widget place(Widget child, {Offset offset = Offset.zero, double angle = 0, double scale = 1, double opacity = 1}) {
        Widget w = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(offset.dx, offset.dy, 0, 1)
            ..rotateZ(angle)
            ..scaleByDouble(scale, scale, 1, 1),
          child: child,
        );
        if (opacity < 1) w = Opacity(opacity: opacity.clamp(0, 1), child: w);
        return Positioned(
          left: center.dx - _card.width / 2,
          top: center.dy - _card.height / 2,
          width: _card.width,
          height: _card.height,
          child: w,
        );
      }

      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (under != null && stacked > 2)
              place(_face(under, text: false),
                  offset: const Offset(0, SwipeTuning.depthCardOffsetY),
                  scale: SwipeTuning.depthCardScale,
                  opacity: SwipeTuning.depthCardOpacity),
            if (under != null)
              place(_face(under, text: false),
                  offset: Offset(0, SwipeTuning.nextCardOffsetY * (1 - progress)),
                  scale: SwipeTuning.nextCardScaleBase + SwipeTuning.nextCardScaleRange * progress),
            if (_startCardUp)
              place(_Shadowed(child: widget.startCard!), offset: _drag, angle: _tiltFor(_drag))
            else if (current != null)
              place(
                // Always a Stack, so the card is never remounted when the
                // hold mark comes and goes.
                Stack(fit: StackFit.expand, children: [
                  _face(current, text: widget.live),
                  if (_holdStart != null) _DontKnowMark(progress: _holdProgress),
                ]),
                offset: _drag,
                angle: _tiltFor(_drag),
              ),
            for (final f in _flying) _buildFlying(f, place),
          ],
        ),
      );
    });
  }

  Widget _buildFlying(
    _Flying f,
    Widget Function(Widget, {Offset offset, double angle, double scale, double opacity}) place,
  ) {
    final t = ((_now - f.start).inMicroseconds / 1e6).clamp(0.0, SwipeTuning.flyDuration);
    final dist = f.speed * t + SwipeTuning.flyAcceleration * t * t;
    final spin = f.dir.dx.sign * t * SwipeTuning.flySpin;
    return place(
      f.face,
      offset: f.from + f.dir * dist,
      angle: f.tilt + spin,
      opacity: 1 - t / SwipeTuning.flyDuration,
    );
  }
}

class _Shadowed extends StatelessWidget {
  const _Shadowed({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: SwipeTuning.shadowColor, blurRadius: SwipeTuning.shadowBlur, offset: SwipeTuning.shadowOffset)
          ],
        ),
        child: child,
      );
}

/// The don't-know mark over a card: a tint, and a ? stamp that grows while
/// a ring around it fills with [progress] (the hold dwell); complete at 1.
class _DontKnowMark extends StatelessWidget {
  const _DontKnowMark({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    const size = SwipeTuning.dontKnowStampSize;
    const ring = size + 2 * (SwipeTuning.holdRingGap + SwipeTuning.holdRingWidth);
    final scale = SwipeTuning.holdStampStartScale + (1 - SwipeTuning.holdStampStartScale) * progress;
    return IgnorePointer(
      child: Stack(fit: StackFit.expand, children: [
        ColoredBox(color: SwipeTuning.dontKnowStampColor.withValues(alpha: SwipeTuning.holdTintOpacity * progress)),
        if (progress < 1)
          Center(child: CustomPaint(size: const Size.square(ring), painter: _HoldRingPainter(progress))),
        Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SwipeTuning.dontKnowStampColor,
                border: Border.all(
                    color: SwipeTuning.dontKnowStampContrastColor, width: SwipeTuning.dontKnowStampBorderWidth),
              ),
              alignment: Alignment.center,
              child: const Text('?',
                  style: TextStyle(
                      fontSize: SwipeTuning.dontKnowStampFontSize,
                      fontWeight: FontWeight.w900,
                      color: SwipeTuning.dontKnowStampContrastColor,
                      height: 1)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _HoldRingPainter extends CustomPainter {
  _HoldRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(SwipeTuning.holdRingWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SwipeTuning.holdRingWidth;
    canvas.drawOval(rect, paint..color = SwipeTuning.holdRingTrackColor);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false,
        paint
          ..color = SwipeTuning.holdRingColor
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_HoldRingPainter old) => old.progress != progress;
}
