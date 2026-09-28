import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../config/config.dart';
import '../../state/settings.dart';

/// What a drag of the top card means right now.
enum SwipeVerdict {
  /// Still following the finger.
  track,

  /// Parked straight down, waiting out the don't-know dwell.
  hold,

  /// Commit as known.
  known,

  /// Commit as don't know.
  dontKnow,

  /// Released short of a swipe: spring back.
  springBack,
}

/// Classifies drags of the top card. Pure, so the rules are unit-tested.
///
/// Any drag that crosses the commit distance commits as known at once, which
/// keeps known swipes exactly as fast as before. The one exception is
/// [DontKnowInput.hold]: straight down it parks in [SwipeVerdict.hold]
/// instead, turning into don't know after [SwipeTuning.dontKnowHoldDwell];
/// lifted or turned away sooner, it is an ordinary known swipe.
class SwipeGesture {
  const SwipeGesture({required this.input, required this.commitDistance});

  final DontKnowInput input;
  final double commitDistance;

  /// [drag] points within [toleranceDeg] of straight down.
  static bool isDown(Offset drag, double toleranceDeg) {
    if (drag.dy <= 0) return false;
    return math.atan2(drag.dx.abs(), drag.dy) * 180 / math.pi <= toleranceDeg;
  }

  /// While the finger moves; [holding] is whether it is already parked.
  SwipeVerdict onMove(Offset drag, {required bool holding}) {
    if (drag.distance < commitDistance) return SwipeVerdict.track;
    if (input != DontKnowInput.hold) return SwipeVerdict.known;
    final tolerance = holding ? SwipeTuning.holdExitToleranceDeg : SwipeTuning.downToleranceDeg;
    return isDown(drag, tolerance) ? SwipeVerdict.hold : SwipeVerdict.known;
  }

  /// While parked, [held] after the hold began.
  SwipeVerdict onHold(Duration held) =>
      held >= SwipeTuning.dontKnowHoldDwell ? SwipeVerdict.dontKnow : SwipeVerdict.hold;

  /// Share of the dwell done, 0–1, for the hold feedback.
  static double holdProgress(Duration held) =>
      (held.inMicroseconds / SwipeTuning.dontKnowHoldDwell.inMicroseconds).clamp(0.0, 1.0);

  /// When the finger lifts after dragging by [drag], moving at [velocity].
  SwipeVerdict onRelease(Offset drag, Offset velocity) {
    if (drag.distance >= commitDistance) return SwipeVerdict.known;
    final flick = drag.distance >= commitDistance * SwipeTuning.flickDistanceRatio &&
        velocity.distance > SwipeTuning.flickMinSpeed;
    return flick ? SwipeVerdict.known : SwipeVerdict.springBack;
  }
}
