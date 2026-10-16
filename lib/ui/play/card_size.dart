import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/torifuda_spec.dart';
import '../../state/scope.dart';

/// The size of a swipe card in a [box]: as big as fits, times the player's
/// [scale] (Settings › Card size). The one place a card's size is worked
/// out, for the deck, its SFX and the settings preview.
Size playCardSize(Size box, double scale) {
  final maxH = box.height * SwipeTuning.cardHeightFraction / TorifudaSpec.aspect;
  final w = math.min(box.width * SwipeTuning.cardWidthFraction, maxH) * scale;
  return Size(w, w * TorifudaSpec.aspect);
}

/// The player's card size setting, full size outside the app's data.
double cardScaleOf(BuildContext context) =>
    ProgressScope.maybeOf(context)?.settings.cardScale ?? DefaultSettings.cardScale;
