import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/torifuda_spec.dart';
import '../../data/poem.dart';
import '../../domain/play_session.dart';
import '../torifuda/torifuda_painter.dart';

/// The stack of cards the player flicks away.
///
/// Timing contract (see PlaySession):
/// * reveal = vsync timestamp of the first frame that paints the top card's
///   glyphs. The card underneath is drawn blank until then, so nothing can be
///   read early.
/// * response = pointer-down timestamp of the committing touch, or, if that
///   finger was already down before the reveal, its first movement after it.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.session,
    required this.live,
    this.grading = true,
    this.downToleranceDeg = DefaultSettings.downToleranceDeg,
    this.showNumber = true,
    this.haptics = true,
    this.onCommitted,
  });

  final PlaySession session;

  /// False keeps the top card blank (before the start / countdown).
  final bool live;

  /// Straight-down swipes mean "don't know".
  final bool grading;
  final double downToleranceDeg;
  final bool showNumber;

  /// Follows `settings.haptics`; never affects the timing contract below.
  final bool haptics;
  final ValueChanged<Attempt>? onCommitted;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

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
  _Flying(this.card, this.from, this.dir, this.speed, this.start, this.outcome, this.tilt);
  final CardRef card;
  final Offset from;
  final Offset dir;
  final double speed;
  final Duration start;
  final Outcome outcome;
  final double tilt;
}

class _SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
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

  PlaySession get _s => widget.session;

  double get _commitDistance =>
      math.max(SwipeTuning.commitDistanceMin, _card.width * SwipeTuning.commitDistanceWidthFraction);

  @override
  void initState() {
    super.initState();
    _s.addListener(_onSession);
  }

  @override
  void didUpdateWidget(SwipeDeck old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session.removeListener(_onSession);
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
    if (_springing) {
      _drag *= math.exp(-dt * SwipeTuning.springDecay);
      if (_drag.distance < 0.5) {
        _drag = Offset.zero;
        _springing = false;
      }
    }
    if (_flying.isEmpty && !_springing) _ticker.stop();
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
    if (!widget.live || _s.finished || _s.currentRevealed || _revealScheduled) return;
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
    if (_dragger == null && _s.currentRevealed) {
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
    if (p.consumed || !_s.currentRevealed) return;
    if (p.downBeforeReveal && p.moveAfterRevealTs == null) {
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
    if (_drag.distance >= _commitDistance) {
      _commit(p, e.timeStamp, p.tracker.getVelocity().pixelsPerSecond);
    }
  }

  void _onUp(PointerUpEvent e) {
    final p = _pointers.remove(e.pointer);
    if (p == null) return;
    if (!p.consumed && _dragger == p.id && _s.currentRevealed) {
      final v = p.tracker.getVelocity().pixelsPerSecond;
      final flick =
          _drag.distance >= _commitDistance * SwipeTuning.flickDistanceRatio && v.distance > SwipeTuning.flickMinSpeed;
      if (flick) {
        _commit(p, e.timeStamp, v);
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
    _springing = true;
    _animate();
  }

  bool _isDown(Offset d) {
    if (d.dy <= 0) return false;
    final angle = math.atan2(d.dx.abs(), d.dy) * 180 / math.pi;
    return angle <= widget.downToleranceDeg;
  }

  void _commit(_Pointer p, Duration ts, Offset velocity) {
    final card = _s.current;
    if (card == null) return;
    final responseTs = p.downBeforeReveal ? (p.moveAfterRevealTs ?? ts) : p.downTs;
    final dirVec = _drag.distance > 12 ? _drag : (velocity.distance > 0 ? velocity : _drag);
    final dir = dirVec.distance == 0 ? const Offset(1, 0) : dirVec / dirVec.distance;
    final outcome = widget.grading && _isDown(dirVec) ? Outcome.dontKnow : Outcome.known;
    _flying.add(_Flying(
      card,
      _drag,
      dir,
      math.max(velocity.distance, SwipeTuning.minFlySpeed),
      _ticker.isActive ? _now : Duration.zero,
      outcome,
      _tiltFor(_drag),
    ));
    p.consumed = true;
    _dragger = null;
    _drag = Offset.zero;
    _springing = false;
    _animate();
    _s.commit(responseTs: responseTs, commitTs: ts, outcome: outcome);
    if (widget.haptics) HapticFeedback.selectionClick();
    final a = _s.lastAttempt;
    if (a != null) widget.onCommitted?.call(a);
  }

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
      final next = _s.next;
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

      Widget cardFor(CardRef ref, {required bool text}) => _Shadowed(
            child: TorifudaCard(
              poem: poems[ref.poemId],
              inverted: ref.inverted,
              mask: ref.mask,
              showText: text,
              showNumber: widget.showNumber,
            ),
          );

      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Depth: a blank card peeking out below the stack.
            if (next != null && _s.index + 2 < _s.cards.length)
              place(cardFor(next, text: false),
                  offset: const Offset(0, SwipeTuning.depthCardOffsetY),
                  scale: SwipeTuning.depthCardScale,
                  opacity: SwipeTuning.depthCardOpacity),
            if (next != null)
              place(cardFor(next, text: false),
                  offset: Offset(0, SwipeTuning.nextCardOffsetY * (1 - progress)),
                  scale: SwipeTuning.nextCardScaleBase + SwipeTuning.nextCardScaleRange * progress),
            if (current != null)
              place(
                cardFor(current, text: widget.live),
                offset: _drag,
                angle: _tiltFor(_drag),
              ),
            for (final f in _flying) _buildFlying(f, place, cardFor),
          ],
        ),
      );
    });
  }

  Widget _buildFlying(
    _Flying f,
    Widget Function(Widget, {Offset offset, double angle, double scale, double opacity}) place,
    Widget Function(CardRef, {required bool text}) cardFor,
  ) {
    final t = ((_now - f.start).inMicroseconds / 1e6).clamp(0.0, SwipeTuning.flyDuration);
    final dist = f.speed * t + SwipeTuning.flyAcceleration * t * t;
    final spin = f.dir.dx.sign * t * SwipeTuning.flySpin;
    Widget child = cardFor(f.card, text: true);
    if (f.outcome == Outcome.dontKnow) {
      child = Stack(fit: StackFit.expand, children: [child, const _DontKnowStamp()]);
    }
    return place(
      child,
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

class _DontKnowStamp extends StatelessWidget {
  const _DontKnowStamp();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: SwipeTuning.dontKnowStampSize,
          height: SwipeTuning.dontKnowStampSize,
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
      );
}
