import 'package:flutter/painting.dart';

import '../domain/card_mask.dart';
import '../state/play_config.dart';
import '../state/settings.dart';
import 'design.dart';

/// The app's tuning constants and defaults, grouped by the system they drive.
/// This is the one place to look for (and change) a magic number.

/// Swipe-deck gesture and animation tuning (`lib/ui/play/swipe_deck.dart`),
/// plus the temporary `PlayScreen`'s lead-in.
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

  /// Card width as a fraction of the available width.
  static const double cardWidthFraction = 0.82;

  /// Card height as a fraction of the available height.
  static const double cardHeightFraction = 0.9;

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

  static const double dontKnowStampSize = 96;
  static const double dontKnowStampBorderWidth = 4;
  static const double dontKnowStampFontSize = 60;
  static const Color dontKnowStampColor = Color(0xCCE94B6A);
  static const Color dontKnowStampContrastColor = Color(0xFFFFFFFF);

  /// Lead-in before the first card's reveal, letting the route transition
  /// settle.
  static const Duration leadIn = Duration(milliseconds: 450);
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

/// The spaced-repetition trainer: `TrainerConfig` defaults, the session
/// planner's scoring weights, and `PlaySession`'s in-training requeue policy.
abstract final class TrainingTuning {
  static const int defaultBatchSize = 3;
  static const int defaultSessionLength = 30;

  /// Time / goal at or below which a correct answer is graded Easy.
  static const double defaultEasyRatio = 0.75;

  /// Time / goal at or below which a correct answer is graded Good (else Hard).
  static const double defaultGoodRatio = 1.5;
  static const double defaultDesiredRetention = 0.9;

  /// FSRS stability (days) needed, together with being solid, to count as
  /// mastered.
  static const double defaultMasteryStabilityDays = 2;

  /// Goal ladder: projected 100-card time (ms), loosest to tightest.
  static const List<int> defaultGoalsMs = [3000, 2500, 2000, 1500, 1200, 1000, 800, 600];

  /// Share of a session reserved for due reviews.
  static const double dueShare = 0.6;

  /// Scheduling weight of a never-seen card.
  static const double freshWeight = 6;

  /// Clamp on the ewma/goal "slowness" ratio used in the scheduling weight.
  static const double slownessClampMin = 0.3;
  static const double slownessClampMax = 4.0;

  /// Extra scheduling weight per unit of recent miss rate.
  static const double missWeightFactor = 3;

  /// Days since last seen after which the recency boost stops growing.
  static const double recencyCapDays = 2;

  /// Extra scheduling weight for unlocked-but-not-yet-solid cards.
  static const double unsolidWeightMultiplier = 2;

  /// Scheduling weight for solid cards kept only for maintenance.
  static const double maintenanceWeightMultiplier = 0.5;

  /// How many of the most recent picks a card must clear before it may repeat.
  static const int recentRepeatWindow = 3;

  /// A session queue may grow at most this much beyond its planned length
  /// (training's in-session requeue after a miss).
  static const double requeueCapGrowth = 1.5;

  /// Default gap, in cards, before a requeued card reappears.
  static const int requeueGap = 4;
}

/// `CardStats`: how recent response times and misses are summarised.
abstract final class StatsTuning {
  /// Attempts at which the EWMA's weight on an old sample halves.
  static const int ewmaHalfLifeAttempts = 5;

  /// `1 - 2^(-1/ewmaHalfLifeAttempts)`, precomputed since `dart:math`'s `pow`
  /// is not a const function.
  static const double ewmaAlpha = 0.12944943670387588;

  /// Minimum timed attempts before a card can be judged "solid".
  static const int solidMinTimed = 3;

  /// Attempts window "solid" is judged over: all correct, median within goal.
  static const int solidWindow = 5;

  /// Default window for `missRate`.
  static const int missWindowDefault = 10;

  /// Assumed time (ms) for a miss or an unseen card, in expected-time and
  /// rating projections.
  static const double unknownMs = 6000;

  /// How far back `Progress.knownCardSpeedTrendAgo` looks, to compare against
  /// `Progress.knownCardSpeedMs`.
  static const int knownSpeedTrendDays = 7;

  /// The archipelago map (Stats): fewer training attempts than this and a
  /// card's dot is hollow ("too few attempts to judge") instead of coloured
  /// by speed.
  static const int mapHollowMinTries = 5;
}

/// The island detail and card detail screens (`lib/ui/stats/island_screen.dart`,
/// `lib/ui/stats/card_detail_screen.dart`).
abstract final class CardDetailTuning {
  /// Attempts shown in the island row's per-card sparkline.
  static const int sparklineTail = 12;

  /// A card due within this many days shows "in Nd" instead of a full date.
  static const int dueSoonDays = 6;

  /// Points sampled along the FSRS forgetting curve.
  static const int forgettingCurveSamples = 24;

  /// Lookahead window (days) when a card has no due date past now to sample
  /// up to (never reviewed, or overdue).
  static const int forgettingCurveFallbackDays = 30;
}

/// The Elo-style rating model (see `Rating`).
abstract final class RatingModel {
  /// Assumed slowdown for the inverted side of a card never practised
  /// inverted, relative to its upright expected time.
  static const double invertedPrior = 1.25;

  /// Rating points per doubling of the projected 100-card time (log2 scale).
  static const double pointsPerDoubling = 600;

  /// Reference time (s): performance is 0 at this projected 100-card time.
  static const double referenceSeconds = 1000;

  /// Smoothing K while still building confidence (first [provisionalSessions]
  /// sessions).
  static const double provisionalK = 0.5;

  /// Smoothing K once established.
  static const double establishedK = 0.25;
  static const int provisionalSessions = 10;

  // Rank-band thresholds: projected 100-card time (s) at or below which a
  // band is reached (see `Rating.bands`).
  static const double fLowerMaxSeconds = 400;
  static const double fUpperMaxSeconds = 245;
  static const double eLowerMaxSeconds = 150;
  static const double eUpperMaxSeconds = 116;
  static const double dMaxSeconds = 90;
  static const double cMaxSeconds = 60;
  static const double bMaxSeconds = 52;
  static const double aMaxSeconds = 40;
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

/// Defaults of `AppSettings`.
abstract final class DefaultSettings {
  static const AppLanguage language = AppLanguage.system;
  static const bool downMeansDontKnow = true;

  /// Degrees either side of straight down still counted as "don't know".
  static const double downToleranceDeg = 25;
  static const bool showPoemNumber = true;
  static const bool haptics = true;
  static const bool leadIn = true;
  static const bool sfxEffects = true;
  static const bool showRunningTimer = false;
  static const PlayConfig freePlay = PlayConfig(mode: PlayMode.free);

  /// 苦手 deck size: how many of the slowest/shakiest cards it draws from.
  static const int nigateCount = 10;
  static const MaskStyle maskStyle = MaskStyle.scramble;
  static const bool debugMode = false;
  static const bool onboarded = false;
  static const bool playOverlay = false;
  static const bool showPerformanceOverlay = false;
}

/// The dev-mode play overlay (`PlayDebugOverlay`).
abstract final class DebugOverlayStyle {
  static const Duration refresh = Duration(milliseconds: 400);
  static const double fontSize = 11;
  static const Color textColor = Color(0xFFB6FF9C);
  static const double lineHeight = 1.4;
  static const Color background = Color(0xB0000000);
  static const double radius = 6;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
}

/// The hidden developer-mode unlock (tapping the About version).
abstract final class DevModeTuning {
  static const int tapsRequired = 10;

  /// Below this many taps left, a countdown toast appears.
  static const int countdownFrom = 3;
}

/// `Progress.recordRun`-backed synthetic history for development builds.
abstract final class DemoDataTuning {
  // Each run persists its attempts one at a time (the same path a real game
  // does), so these stay modest: on-device this still takes real seconds.
  static const int days = 4;
  static const int minSessionsPerDay = 1;
  static const int maxSessionsPerDay = 1;

  /// A free-play run happens every this many simulated days.
  static const int freeRunEvery = 3;
  static const int trainingCards = 10;
  static const int freeCards = 8;

  /// Response-time target (ms) on the first and last simulated day; sampled
  /// attempts vary around the day's interpolated target.
  static const double startTargetMs = 2200;
  static const double endTargetMs = 550;
  static const double sampleSpreadLow = 0.6;
  static const double sampleSpreadHigh = 1.5;
  static const double startMissRate = 0.22;
  static const double endMissRate = 0.03;

  /// Gap between two cards' wall-clock timestamps beyond the response time.
  static const Duration cardGap = Duration(milliseconds: 250);
  static const Duration betweenCommitAndNextReveal = Duration(milliseconds: 120);
}
