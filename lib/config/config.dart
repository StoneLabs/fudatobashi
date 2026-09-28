import 'package:flutter/painting.dart';

import '../domain/card_mask.dart';
import '../domain/learning_pace.dart';
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

  /// Scheduling weight of a new card: never seen, or seen but with fewer than
  /// [newCardMinTimed] timed attempts.
  static const double freshWeight = 6;

  /// Timed attempts that end a card's "new" status. The next batch also waits
  /// until every card of the latest batch has this many.
  static const int newCardMinTimed = 3;

  /// Share of a session that new cards' reserved slots may fill.
  static const double newCardMaxShare = 0.5;

  /// A run opens with this many swipes of known cards before a new card's
  /// first appearance (when that many are in the session).
  static const int newCardHoldBack = 5;

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

/// One journey pace: how many days it targets for all 100 cards, how many
/// new cards it may auto-unlock in one day (catching up after days off), and
/// the daily practice it is built for: [dailyRounds] training rounds, which a
/// capable player needs to keep up (the pacing simulations' routine).
class PaceProfile {
  const PaceProfile({required this.daysToAll, required this.dailyAutoCap, required this.dailyRounds});
  final int daysToAll;
  final int dailyAutoCap;
  final int dailyRounds;
}

/// Journey pacing: when new cards arrive (`Trainer.unlockEarned`,
/// `Trainer.paceStatus`).
///
/// A new batch auto-unlocks when the player is ready (most unlocked cards are
/// solid and the latest batch has been practised) and the unlocked count is
/// behind the pace curve. So the goal is flexible: a capable player on the
/// pace's routine keeps up with the curve, while one who keeps forgetting is
/// held back until the cards they have are solid. Home's "Learn next cards"
/// pulls cards in ahead of the curve (see [LearnAheadTuning]).
abstract final class PaceTuning {
  static const LearningPace defaultPace = LearningPace.month;
  static const PaceProfile month = PaceProfile(daysToAll: 28, dailyAutoCap: 10, dailyRounds: 3);
  static const PaceProfile sprint = PaceProfile(daysToAll: 15, dailyAutoCap: 16, dailyRounds: 6);

  /// The pace curve: (share of the pace's days elapsed, share of all cards
  /// expected unlocked), linearly interpolated. Front-loaded, since the
  /// one-kana island and the first islands are the easiest.
  static const List<(double, double)> curve = [(0, 0.06), (0.25, 0.31), (0.5, 0.6), (1, 1)];

  /// Share of unlocked upright cards that must be solid before more arrive.
  static const double readySolidFraction = 0.8;

  /// Journey days the debug page's pace table looks ahead of today.
  static const int debugLookaheadDays = 3;
}

/// Home's "Learn next cards" (`Trainer.learnAhead`), for players who learn
/// faster than their pace: it opens only once every unlocked card is well
/// remembered and the pace has no new cards left for today.
abstract final class LearnAheadTuning {
  /// Latest attempts a well-remembered card is judged over: at most this share
  /// of them missed, and their median time within the goal.
  static const int recentWindow = 5;
  static const double maxRecentMissRate = 0.2;
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

  /// TOP SPEED (card detail): the fast end of a card's recent times, this
  /// percentile of its last [topSpeedWindow] timed attempts. Steadier than
  /// the single best time, which one lucky swipe sets for good.
  static const double topSpeedPercentile = 5;
  static const int topSpeedWindow = 100;
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

/// The card detail's attempt chart (`AttemptChart` in
/// `lib/ui/stats/stats_charts.dart`).
abstract final class AttemptChartTuning {
  /// The rolling averages (avg5, avg10, avg50): each line starts once its
  /// window of timed attempts is full.
  static const int shortAverage = 5;
  static const int midAverage = 10;
  static const int longAverage = 50;

  /// The band: these percentiles of the last [bandWindow] timed attempts,
  /// drawn from the [bandMinCount]th timed attempt on.
  static const double bandLow = 5;
  static const double bandHigh = 95;
  static const int bandWindow = 20;
  static const int bandMinCount = 10;

  /// The ms axis: the dots' range widened by these margins, then rounded out
  /// to the smallest of [axisSteps] that needs at most [maxGridLines]
  /// gridlines (doubling the largest step if none does).
  static const double axisPadBelowMs = 60;
  static const double axisPadAboveMs = 40;
  static const List<int> axisSteps = [50, 100, 200, 250, 500, 1000, 2000, 5000];
  static const int maxGridLines = 5;
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
  static const DontKnowInput dontKnowInput = DontKnowInput.hold;
  static const bool showPoemNumber = true;
  static const bool haptics = true;
  static const bool leadIn = true;
  static const bool sfxEffects = true;
  static const bool sounds = true;
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

/// How one kind of simulated player (`SyntheticLearner`) learns: response
/// times, first-sight misses and how long memories last.
class LearnerProfile {
  const LearnerProfile({
    required this.firstMs,
    required this.firstPerKanaMs,
    required this.floorMs,
    required this.floorPerKanaMs,
    required this.learnReps,
    required this.firstSightMissRate,
    required this.firstSightMissDecayReps,
    required this.slipRate,
    required this.initialStrengthDays,
    required this.strengthGrowth,
  });

  /// First-sight response time, ms, plus this much per extra kimariji kana.
  final double firstMs;
  final double firstPerKanaMs;

  /// Practised-to-the-limit response time, ms, plus this much per extra kana.
  final double floorMs;
  final double floorPerKanaMs;

  /// Repetitions over which the gap to the floor shrinks by a factor of e.
  final double learnReps;

  /// Miss chance on first sight, fading with repetitions (e-folding count),
  /// on top of a constant slip rate.
  final double firstSightMissRate;
  final double firstSightMissDecayReps;
  final double slipRate;

  /// Memory strength (days) after the first day of practice; recall after a
  /// gap of g days is exp(-g / strength). Each further day of practice
  /// multiplies it by [strengthGrowth].
  final double initialStrengthDays;
  final double strengthGrowth;
}

/// The synthetic player (`SyntheticLearner`) behind the pacing simulations,
/// the debug page's Simulation and dev-mode demo data.
abstract final class SyntheticLearnerTuning {
  /// Picks up cards fast and rarely forgets them.
  static const LearnerProfile quick = LearnerProfile(
    firstMs: 3000,
    firstPerKanaMs: 300,
    floorMs: 600,
    floorPerKanaMs: 80,
    learnReps: 3.5,
    firstSightMissRate: 0.25,
    firstSightMissDecayReps: 1.2,
    slipRate: 0.01,
    initialStrengthDays: 8,
    strengthGrowth: 2.5,
  );

  /// The player the pace curve is tuned for (and the demo data's).
  static const LearnerProfile average = LearnerProfile(
    firstMs: 3400,
    firstPerKanaMs: 350,
    floorMs: 700,
    floorPerKanaMs: 90,
    learnReps: 5,
    firstSightMissRate: 0.35,
    firstSightMissDecayReps: 1.5,
    slipRate: 0.015,
    initialStrengthDays: 5,
    strengthGrowth: 2,
  );

  /// Slow to get quick and forgetful: the pace must stretch for them.
  static const LearnerProfile slow = LearnerProfile(
    firstMs: 4200,
    firstPerKanaMs: 450,
    floorMs: 1000,
    floorPerKanaMs: 120,
    learnReps: 8,
    firstSightMissRate: 0.5,
    firstSightMissDecayReps: 2.5,
    slipRate: 0.03,
    initialStrengthDays: 1.5,
    strengthGrowth: 1.5,
  );

  /// Upside-down cards are this much slower.
  static const double invertedFactor = 1.2;

  /// Response times vary by up to this factor either way.
  static const double timeJitter = 1.25;

  /// Share of practice (repetitions) kept overnight, and after forgetting.
  static const double overnightRepsKept = 0.85;
  static const double forgottenRepsKept = 0.5;

  /// Gap between two cards' wall-clock timestamps beyond the response time.
  static const Duration cardGap = Duration(milliseconds: 250);

  /// Swipe duration from the response (finger moving) to the commit.
  static const Duration responseToCommit = Duration(milliseconds: 80);
  static const Duration commitToNextReveal = Duration(milliseconds: 120);

  /// A simulated day's rounds are spread between these local hours, each
  /// starting up to [roundStartJitterMinutes] late.
  static const int firstRoundHour = 8;
  static const int lastRoundHour = 21;
  static const int roundStartJitterMinutes = 40;
}

/// The debug Simulation page (`simulatePace`): a journey played by a
/// simulated learner, day by day, on a throwaway database.
abstract final class SimulationTuning {
  static const int defaultDays = 30;
  static const int minDays = 7;
  static const int maxDays = 60;

  /// The learner's and planner's seed, fixed so runs compare (FSRS still
  /// fuzzes its intervals, so they differ a little).
  static const int seed = 1;
}

/// Dev-mode demo data (`seedDemoData`): a journey player's recent history,
/// simulated day by day through the real training path.
abstract final class DemoDataTuning {
  /// Days simulated, ending yesterday.
  static const int days = 14;
  static const int minRoundsPerDay = 2;
  static const int maxRoundsPerDay = 4;

  /// A free-play run happens every this many simulated days.
  static const int freeRunEvery = 3;
  static const int freeCards = 10;

  /// Fixed default seed, so seeding the same device twice (and this
  /// feature's own test) reproduces the same journey.
  static const int seed = 1179;
}

/// Settings › Developer › "Preview celebrations": the spec mock's numbers.
abstract final class CelebrationPreviewTuning {
  /// The island completed (the mock's 3rd).
  static const int island = 2;

  /// The rank-up from `Rating.bands[rankFrom]` (F上級) to the next class,
  /// gaining [rankGain] points across its threshold.
  static const int rankFrom = 2;
  static const double rankGain = 26;

  /// The personal best: [cards] cards averaging [averageUs], spread evenly
  /// [spreadUs] apart, [total] in all against a [previousBest].
  static const int cards = 20;
  static const int averageUs = 642000;
  static const int spreadUs = 20000;
  static const total = Duration(milliseconds: 14906);
  static const previousBest = Duration(milliseconds: 15380);
}

/// Sound pooling (`lib/ui/sound/sounds.dart`): concurrent, identically
/// loaded players kept per asset, so a sound that can retrigger faster than
/// one play of it lasts (a card flick during a swiping streak) overlaps
/// instead of cutting itself off.
abstract final class SoundTuning {
  static const int cardFlickPoolSize = 3;
}

/// The app's sound effects (Kenney, CC0; provenance in
/// `assets/sounds/License.txt`): each one's assets under `assets/` and its
/// playback volume, 0–1. A sound with several assets plays a random one of
/// them each time. Celebration pages and Results play their cues on a
/// schedule; [cardFlick] also plays once for every card that leaves the
/// deck during play.
enum Sfx {
  cardAppears(['sounds/card_appears.wav'], 0.8),
  cardFlick(
    [
      'sounds/card_flick_0.wav',
      'sounds/card_flick_1.wav',
      'sounds/card_flick_2.wav',
      'sounds/card_flick_3.wav',
      'sounds/card_flick_4.wav',
    ],
    0.85,
    poolSize: SoundTuning.cardFlickPoolSize,
  ),
  lookAlike(['sounds/look_alike.wav'], 0.7),
  island(['sounds/island.wav'], 0.8),
  stamp(['sounds/stamp.wav'], 0.9),
  rankUp(['sounds/rank_up.wav'], 0.8),
  goalUp(['sounds/goal_up.wav'], 0.8),
  best(['sounds/best.wav'], 0.8),
  results(['sounds/results.wav'], 0.5);

  const Sfx(this.assets, this.volume, {this.poolSize = 1});
  final List<String> assets;
  final double volume;

  /// Players preloaded per asset (see [SoundTuning]); 1 unless a sound needs
  /// to overlap itself.
  final int poolSize;
}
