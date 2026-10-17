part of '../config.dart';

/// Swipe-deck gesture and animation tuning (`lib/ui/play/swipe_deck.dart`).
abstract final class SwipeTuning {
  /// How long a flicked-away card stays on screen, seconds.
  static const double flyDuration = 0.26;

  /// Minimum initial speed of a flicked card, px/s (so even a slow release
  /// still reads as a deliberate flick).
  static const double minFlySpeed = 2600;

  /// Constant acceleration applied to a flying card, px/s².
  static const double flyAcceleration = 1800;

  /// Extra spin of a flying card, radians per second of flight.
  static const double flySpin = 2.2;

  /// Drag tilt, radians per unit of drag-distance / card-width.
  static const double tiltFactor = 0.35;

  /// Exponential decay rate of the spring-back drag, per second.
  static const double springDecay = 22;

  /// Minimum drag distance that commits a card, px.
  static const double commitDistanceMin = 40;

  /// Commit distance as a fraction of the card width; the larger of this and
  /// [commitDistanceMin] applies.
  static const double commitDistanceWidthFraction = 0.16;

  /// A release counts as a flick once dragged this fraction of the commit
  /// distance, provided it clears [flickMinSpeed].
  static const double flickDistanceRatio = 0.35;

  /// Minimum release speed counted as a flick, px/s.
  static const double flickMinSpeed = 350;

  /// Movement past the reveal, px, before a finger already down counts as the
  /// response (filters out the hand settling).
  static const double revealMoveSlop = 3;

  /// The swipe itself, from the touch to the let go, is free up to this
  /// long; anything longer counts towards the card's time (a finger held
  /// down to think). See `CardTime`.
  static const Duration gestureBudget = Duration(milliseconds: 150);

  /// Card width as a fraction of the available width.
  static const double cardWidthFraction = 0.82;

  /// Card height as a fraction of the available height.
  static const double cardHeightFraction = 0.9;

  /// The player's card size setting, as a share of the full card size: its
  /// range and step (the slider in Settings › Card size).
  static const double cardScaleMin = 0.25;
  static const double cardScaleMax = 1;
  static const double cardScaleStep = 0.05;

  /// Scale of the next card at the start of a drag, growing toward
  /// [nextCardScaleBase] + [nextCardScaleRange] as the drag nears commit.
  static const double nextCardScaleBase = 0.965;
  static const double nextCardScaleRange = 0.035;

  /// Vertical offset of the next card at the start of a drag, px.
  static const double nextCardOffsetY = 5;

  /// Vertical offset of the blank card peeking out below the stack, px.
  static const double depthCardOffsetY = 10;
  static const double depthCardScale = 0.93;
  static const double depthCardOpacity = 0.55;

  static const double shadowBlur = 14;
  static const Offset shadowOffset = Offset(0, 6);
  static const Color shadowColor = Color(0x33000000);

  /// Degrees either side of straight down that start a don't-know hold.
  static const double downToleranceDeg = 25;

  /// Once holding, the finger may wander this far from straight down before
  /// the drag turns back into an ordinary known swipe.
  static const double holdExitToleranceDeg = 40;

  /// How long a drag must stay in the down position to mean "don't know"
  /// (`DontKnowInput.hold`). Released sooner, it is a known flick.
  static const Duration dontKnowHoldDwell = Duration(milliseconds: 420);

  static const double dontKnowStampSize = 96;
  static const double dontKnowStampBorderWidth = 4;
  static const double dontKnowStampFontSize = 60;
  static const Color dontKnowStampColor = Color(0xCCE94B6A);
  static const Color dontKnowStampContrastColor = Color(0xFFFFFFFF);

  /// Hold feedback: the ? stamp grows from this scale, a ring around it fills
  /// up, and the card takes on up to [holdTintOpacity] of [dontKnowStampColor].
  static const double holdStampStartScale = 0.35;
  static const double holdTintOpacity = 0.28;
  static const double holdRingWidth = 7;
  static const double holdRingGap = 6;
  static const Color holdRingColor = Palette.ink;
  static const Color holdRingTrackColor = Color(0xB3FFFFFF);
}

/// Coloured SFX lettering that pops around the card on each flick
/// (`lib/ui/play/sfx_overlay.dart`), never over it.
abstract final class PlaySfxTuning {
  static const List<String> knownWords = ['バシッ', 'シュッ', 'パシッ', 'スパッ', 'ビシッ', 'タンッ'];
  static const String dontKnowWord = 'スカッ';
  static const Color knownColor = Palette.pink;
  static const Color dontKnowColor = Palette.sea;
  static const double fontSize = 40;
  static const Duration duration = Duration(milliseconds: 900);

  /// Oldest pop is dropped once this many are on screen at once.
  static const int maxConcurrent = 3;

  /// Horizontal placement, as a fraction of the play area's width (kept off
  /// the very edges). Vertical placement is computed from the card's own
  /// geometry (see `SwipeTuning`), landing in the clear strip above or below
  /// it, never over it.
  static const double horizontalMin = 0.12;
  static const double horizontalMax = 0.88;

  /// How far into the clear strip above/below the card a pop sits, as a
  /// fraction from the card's edge toward the play area's edge (kept low so
  /// it doesn't reach the header chip/counter or the footer buttons).
  static const double bandBias = 0.4;
  static const double maxRotationDeg = 10;

  // Timeline fractions (of [duration]), matching the spec's sfxpop keyframes:
  // pop in with overshoot, settle, hold, then fade while drifting up.
  static const double popInEnd = 0.14;
  static const double settleEnd = 0.26;
  static const double holdEnd = 0.72;
  static const double startScale = 0.35;
  static const double popScale = 1.12;
  static const double settleScale = 1.0;
  static const double endScale = 1.04;
  static const double endTranslateY = -6;

  /// A correct card only pops its SFX when at or under this fraction of the
  /// baseline response time (the card's own average, or else this run's).
  static const double fastRatio = 0.85;

  /// Timed attempts a card needs before its own average is trusted as the
  /// baseline; fewer than this falls back to the run's average so far.
  static const int minCardSamplesForBaseline = 3;
}

/// 隠し字 masking: the uniqueness search (`Masking`) and the scramble style's
/// tile rendering (`TorifudaGlyphs`).
abstract final class MaskingTuning {
  /// Minimum visible-position distance every mask must keep from every other
  /// card (see `Masking` for the full uniqueness rule).
  static const int minDistance = 2;
  static const int maxLevel = 7;

  /// Resample attempts for a random mask before falling back to repair.
  static const int resampleTries = 40;

  /// A scramble tile is cut from the glyph rendered into a box this much
  /// larger than the em box, so strokes near the edge aren't clipped.
  static const double scrambleBoxPad = 1.1;

  /// Multiplies the mask seed when mixing the scramble tile RNG seed, so it
  /// doesn't correlate with the poem id.
  static const int scrambleSeedMix = 131;
}

/// Glyph-atlas rendering (`tool/render_glyphs_test.dart`, loaded by
/// `GlyphAtlas`).
abstract final class AtlasTuning {
  /// Pixels per em to render each glyph at.
  static const double emPx = 256;

  /// Image side / em (headroom so strokes aren't clipped at the edges).
  static const double pad = 1.1;

  /// Outline growth, in em, matching the original cards' slightly heavier
  /// ink.
  static const double inkSpreadEm = 0.0018;
}
