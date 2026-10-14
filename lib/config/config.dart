import 'package:flutter/painting.dart';

import '../domain/ankiren_field.dart';
import '../domain/ankiren_level.dart';
import '../domain/card_mask.dart';
import '../domain/learning_pace.dart';
import '../domain/xp.dart';
import '../state/play_config.dart';
import '../state/settings.dart';
import 'design.dart';

/// The app's tuning constants and defaults, grouped by the system they drive.
/// This is the one place to look for (and change) a magic number.

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
}

/// When the tabs a new player starts without open up (`TabLock`).
abstract final class TabLockTuning {
  static const int historyRounds = 3;

  /// All-known mode's stand-in for finishing the first island.
  static const int statsFinishedRounds = 1;
}

/// The tour's practice round (`PlayScreen.tutorial`).
abstract final class TutorialTuning {
  /// How long Tobi's last line stays up before the round closes.
  static const Duration doneLinger = Duration(milliseconds: 1800);
}

/// Tobi's tour balloon (`TourOverlay`): how its text types itself out.
abstract final class TourTuning {
  /// Time to reveal each visible character of a line — slow enough to read
  /// as it goes, and never skippable.
  static const Duration charInterval = Duration(milliseconds: 28);
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

  /// Cards in a 修行 round: journey mode, and all-known mode (a player who
  /// knows every card gets a longer round).
  static const int defaultSessionLength = 30;
  static const int allKnownSessionLength = 50;

  /// A correct answer at or under this time, ms, is graded Easy, whatever
  /// the goal.
  static const int defaultEasyMs = 300;

  /// Debug page range of [defaultEasyMs], ms.
  static const int easyMsMin = 100;
  static const int easyMsMax = 1000;
  static const int easyMsStep = 50;

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
/// capable player needs to keep up (the pacing simulations' routine). With
/// more than [pauseNewOver] reviews in today's set, Home asks whether to
/// pause today's new cards.
class PaceProfile {
  const PaceProfile({
    required this.daysToAll,
    required this.dailyAutoCap,
    required this.dailyRounds,
    required this.pauseNewOver,
  });
  final int daysToAll;
  final int dailyAutoCap;
  final int dailyRounds;
  final int pauseNewOver;
}

/// Journey pacing: when new cards arrive (`Trainer.unlockEarned`,
/// `Trainer.paceStatus`).
///
/// A new batch auto-unlocks when the player is ready (most unlocked cards are
/// solid and the latest batch has been practised) and the unlocked count is
/// behind the pace curve. So the goal is flexible: a capable player on the
/// pace's routine keeps up with the curve, while one who keeps forgetting is
/// held back until the cards they have are solid. Home's "Learn ahead"
/// pulls cards in ahead of the curve (see [LearnAheadTuning]).
abstract final class PaceTuning {
  static const LearningPace defaultPace = LearningPace.month;
  static const PaceProfile month = PaceProfile(daysToAll: 28, dailyAutoCap: 10, dailyRounds: 3, pauseNewOver: 75);
  static const PaceProfile sprint = PaceProfile(daysToAll: 15, dailyAutoCap: 16, dailyRounds: 6, pauseNewOver: 150);

  /// The pace curve: (share of the pace's days elapsed, share of all cards
  /// expected unlocked), linearly interpolated. Front-loaded, since the
  /// one-kana island and the first islands are the easiest.
  static const List<(double, double)> curve = [(0, 0.06), (0.25, 0.31), (0.5, 0.6), (1, 1)];

  /// Share of unlocked upright cards that must be solid before more arrive.
  static const double readySolidFraction = 0.8;

  /// Journey days the debug page's pace table looks ahead of today.
  static const int debugLookaheadDays = 3;
}

/// Home's "Learn ahead" (`Trainer.learnAhead`), for players who learn
/// faster than their pace: it opens only once every unlocked card is well
/// remembered and the pace has no new cards left for today.
abstract final class LearnAheadTuning {
  /// Latest attempts a well-remembered card is judged over: at most this share
  /// of them missed, and their median time within the goal.
  static const int recentWindow = 5;
  static const double maxRecentMissRate = 0.2;
}

/// Journey's today's set (`TodaySet`) and the runs that play it (`StepPlan`):
/// every card in the set needs a few looks today, counted in cards rather
/// than minutes, and a miss brings a card back until it is answered right a
/// few times in a row. The day starts at a local hour of the player's choice.
abstract final class TodaySetTuning {
  static const int defaultDayStartHour = 4;
  static const int firstDayStartHour = 0;
  static const int lastDayStartHour = 9;

  /// Moving the day start later never makes a day shorter than this.
  static const Duration shortestDay = Duration(hours: 12);

  /// Correct looks a card needs today: a due review, and a new card.
  static const int reviewLooks = 2;
  static const int newLooks = 4;

  /// After a miss, correct answers in a row that settle the card for today.
  static const int relearnLooks = 2;

  /// Cards shown before a card comes back: after a new card's 1st, 2nd and
  /// 3rd correct look (the last repeats), after a review's correct look,
  /// after a miss and then each correct look in a row (the last repeats),
  /// and between the picks of one card in a batch of 30.
  static const List<int> newGaps = [3, 8, 20];
  static const List<int> reviewGaps = [20];
  static const List<int> relearnGaps = [4, 12];
  static const int batchGap = 4;

  /// A new card's first look comes at least this many cards after the
  /// previous new card's, while reviews are left to show in between.
  static const int newSpacing = 4;

  /// The morning's guess at the extra looks misses will add: the recent miss
  /// rate over this many training swipes (this rate without any), times the
  /// set's looks, at least [missGuessMin].
  static const int missGuessWindow = 200;
  static const double missGuessDefault = 1 / 12;
  static const int missGuessMin = 1;

  /// Days on Home's week stamps.
  static const int weekDays = 7;
}

/// Free practice (始める): locked in journey mode until this many cards are
/// well remembered at once (`Trainer.wellRemembered`); from then on it stays
/// open for good.
abstract final class FreePracticeTuning {
  static const int unlockRemembered = 50;
}

/// When the side trips (寄り道, `SideTripUnlocks`) open in journey mode: once
/// this many cards are well remembered at once, free practice's counter;
/// from then on they stay open for good. All-known mode opens them all.
abstract final class SideTripTuning {
  /// The Side Trips tab.
  static const int tabRemembered = 25;

  /// 暗記練, its ranked games and free play together; ranked always has
  /// enough known cards to deal from by then.
  static const int ankirenRemembered = 50;
}

/// How a swipe turns the Side Trips tab's ring of islands (`SideTripRing`).
abstract final class SideTripRingTuning {
  /// A drag across this share of the screen's width turns the ring one
  /// step, so the entries ride under the finger.
  static const double dragPerStep = 1;

  /// A release at least this fast, px/s, turns on to the next step in its
  /// direction; a slower one settles on the nearest.
  static const double flingSpeed = 320;

  /// Under reduced motion nothing follows the finger: a swipe at least
  /// this long, px (or a fling), turns the ring a step.
  static const double stillSwipe = 48;
}

/// The full-screen warnings before what can't be undone (`HoldWarningScreen`:
/// Settings' journey → all-known switch, Reset all data): confirming takes a
/// deliberate hold instead of a tap.
abstract final class HoldWarningTuning {
  static const Duration holdDuration = Duration(seconds: 15);
}

/// `HoldToConfirmButton`'s haptics: buzzes that come faster and harder as
/// the hold nears the end, like arming something. The gap between buzzes
/// shrinks from [buzzFirst] to [buzzLast]; past each of [strengthSteps]
/// (shares of the hold) a buzz steps up from a click to a light, a medium
/// and a heavy impact.
abstract final class HoldConfirmTuning {
  static const Duration buzzFirst = Duration(milliseconds: 1000);
  static const Duration buzzLast = Duration(milliseconds: 90);
  static const List<double> strengthSteps = [0.35, 0.65, 0.88];
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
}

/// Fixed ranges of the FSRS model, for display.
abstract final class FsrsScale {
  /// FSRS difficulty runs from 1 to this.
  static const int difficultyMax = 10;
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

/// The rating page after a run (`RatingOverlay`).
abstract final class RatingScreenTuning {
  /// Shown only when a run raised the displayed (rounded) rating by at
  /// least this many points.
  static const int minGain = 1;

  /// Rating points spanned by the track of a class without a lower bound
  /// (入門, up to the next class) or an upper one (the top class, up from
  /// its own threshold).
  static const double openSpan = 400;
}

/// Experience (XP, `XpLedger`): effort rewarded on every tracked run, apart
/// from the rating's measure of skill. Derived from the recorded history, so
/// a change here re-scores every past run too.
abstract final class XpTuning {
  static const int perCorrect = 10;

  /// A card swiped away as "don't know" or marked wrong (undone swipes earn
  /// nothing: their redo is what counts).
  static const int perMiss = 2;

  /// Extra for a correct, cleanly timed swipe at or under the goal time of
  /// its run, more at or under [blazingRatio] of it.
  static const int speedAtGoal = 5;
  static const int speedBlazing = 10;
  static const double blazingRatio = 0.75;

  /// Extra for a due review answered correctly (FSRS graded it).
  static const int perReview = 5;

  /// A card met for the first time in a run that counts.
  static const int perNewCard = 25;

  /// A run played to its last card.
  static const int clear = 20;

  /// The first run of a day, plus [perStreakDay] for each day of the streak
  /// before it, up to [streakCapDays].
  static const int daily = 100;
  static const int perStreakDay = 10;
  static const int streakCapDays = 10;

  /// A completed run faster than the best before it with the same setup.
  static const int personalBest = 200;
  static const int perIsland = 10000;

  /// Finishing today's set (journey mode), once a day.
  static const int dayDone = 1000;

  /// Learning the 100th card, the end of the journey.
  static const int graduation = 100000;

  /// XP from level L to L+1: [levelBase] × √L. Levels come quickly at
  /// first and keep coming: unlike the rank, a level never stalls.
  static const double levelBase = 300;
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
  static const String language = 'system';
  static const bool languagePicked = false;
  static const DontKnowInput dontKnowInput = DontKnowInput.hold;
  static const bool showPoemNumber = true;
  static const bool haptics = true;
  static const bool sfxEffects = true;
  static const bool music = true;
  static const double musicVolume = 0.5;
  static const bool swipeSound = true;
  static const bool effectSounds = true;
  static const bool showRunningTimer = false;
  static const FreePracticeSetup freePractice = FreePracticeSetup();

  /// 苦手 deck size: how many of the slowest/shakiest cards it draws from.
  static const int nigateCount = 10;
  static const MaskStyle maskStyle = MaskStyle.scramble;
  static const bool debugMode = false;
  static const bool onboarded = false;
  static const bool toured = false;
  static const bool playOverlay = false;
  static const bool showPerformanceOverlay = false;
  static const KimarijiScript kimarijiScript = KimarijiScript.auto;
  static const bool accessibilityMode = false;

  /// 暗記練 (Settings › 寄り道 › 暗記練), and its free play's last setup.
  static const AnkirenSettings ankiren = AnkirenSettings();
  static const AnkirenLayout ankirenLayout = AnkirenLayout.portrait;
  static const AnkirenPrompt ankirenPrompt = AnkirenPrompt.textAndVoice;
  static const int ankirenFreeLevel = 0;
  static const int ankirenCustomPerSide = 8;
  static const Duration ankirenCustomMemorise = Duration(minutes: 1);
  static const bool ankirenRulesSeen = false;
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

  /// A table readout: its labels dimmer than the values, the line starting
  /// each part brighter, the gap between a label and its value, and between
  /// tables side by side.
  static const Color labelColor = Color(0xFF8FBF80);
  static const Color headColor = Color(0xFFFFE08A);
  static const double columnGap = 10;
  static const double tableGap = 16;
}

/// The hidden developer-mode unlock (tapping the About version).
abstract final class DevModeTuning {
  static const int tapsRequired = 10;

  /// Below this many taps left, a countdown toast appears.
  static const int countdownFrom = 3;
}

/// How one kind of simulated player (`SyntheticLearner`) learns: response
/// times, how memories of cards fade and grow, and how it mixes cards up.
/// Each value notes its source; "guess" marks the ones to calibrate against
/// real players.
class LearnerProfile {
  const LearnerProfile({
    required this.firstMs,
    required this.firstPerKanaMs,
    required this.floorMs,
    required this.floorPerKanaMs,
    required this.practiceExponent,
    required this.firstStability,
    required this.recallGrowth,
    required this.cardSpread,
    required this.mixUpRate,
    required this.lookAlikeRate,
    required this.lookAlikeFadeDays,
    required this.slipRate,
    required this.rushSlipRate,
  });

  /// First-sight response time, ms, plus this much per extra kimariji kana.
  final double firstMs;
  final double firstPerKanaMs;

  /// Practised-to-the-limit response time, ms, plus this much per extra kana.
  final double floorMs;
  final double floorPerKanaMs;

  /// Power law of practice: after n repetitions the gap to the floor is
  /// (1 + n)^-[practiceExponent] of the first one.
  final double practiceExponent;

  /// Memory stability (the gap after which recall falls to 90%) of a card
  /// just introduced and answered once.
  final Duration firstStability;

  /// Stability gain from a correct recall at recall chance R:
  /// S × ([SyntheticLearnerTuning.massedGrowth] + recallGrowth ×
  /// (e^([SyntheticLearnerTuning.spacingGrowth] × (1 − R)) − 1)), so a recall
  /// after a long gap does far more than one minutes later.
  final double recallGrowth;

  /// How differently single cards stick: the σ of a log-normal factor on
  /// each card's first stability.
  final double cardSpread;

  /// Chance of mixing a card just met (or relearned after a miss) up with
  /// the cards met around it, kept by [SyntheticLearnerTuning.mixUpKept]
  /// with each correct answer.
  final double mixUpRate;

  /// Chance of taking a card for one of its 友札 once it has met that 友札,
  /// fading by e over [lookAlikeFadeDays] days with a correct answer.
  final double lookAlikeRate;
  final double lookAlikeFadeDays;

  /// Miss chance on a card it does remember: any time, plus [rushSlipRate]
  /// when answering faster than its usual pace for the card
  /// ([SyntheticLearnerTuning.rushRatio]).
  final double slipRate;
  final double rushSlipRate;
}

/// The synthetic player (`SyntheticLearner`) behind the pacing simulations,
/// the debug page's Simulation and dev-mode demo data.
abstract final class SyntheticLearnerTuning {
  /// Picks up cards fast, and they stick.
  static const LearnerProfile quick = LearnerProfile(
    firstMs: 3000, // guess
    firstPerKanaMs: 300, // guess
    floorMs: 600, // guess
    floorPerKanaMs: 80, // guess
    practiceExponent: 0.6, // power law of practice: 0.2–0.6 (Newell & Rosenbloom 1981)
    firstStability: Duration(minutes: 90), // guess
    recallGrowth: 22, // FSRS-6 defaults: ~16 for a card first failed (D 7), ~25 at D 5
    cardSpread: 0.5, // guess
    mixUpRate: 0.2, // guess
    lookAlikeRate: 0.1, // guess
    lookAlikeFadeDays: 3, // guess
    slipRate: 0.01, // easy choice-reaction tasks: 1–3% errors
    rushSlipRate: 0.03, // guess
  );

  /// The player the pace curve is tuned for (and the demo data's).
  static const LearnerProfile average = LearnerProfile(
    firstMs: 3400, // guess
    firstPerKanaMs: 350, // guess
    floorMs: 700, // guess
    floorPerKanaMs: 90, // guess
    practiceExponent: 0.5, // power law of practice: 0.2–0.6 (Newell & Rosenbloom 1981)
    firstStability: Duration(hours: 1), // guess
    recallGrowth: 16, // FSRS-6 defaults: ~16 for a card first failed (D 7)
    cardSpread: 0.6, // guess
    mixUpRate: 0.25, // guess
    lookAlikeRate: 0.15, // guess
    lookAlikeFadeDays: 5, // guess
    slipRate: 0.015, // easy choice-reaction tasks: 1–3% errors
    rushSlipRate: 0.04, // guess
  );

  /// Slow to get quick and forgetful: the pace must stretch for them.
  static const LearnerProfile slow = LearnerProfile(
    firstMs: 4200, // guess
    firstPerKanaMs: 450, // guess
    floorMs: 1000, // guess
    floorPerKanaMs: 120, // guess
    practiceExponent: 0.4, // power law of practice: 0.2–0.6 (Newell & Rosenbloom 1981)
    firstStability: Duration(minutes: 30), // guess
    recallGrowth: 10, // FSRS-6 defaults: ~16 for a card first failed (D 7), ~8 at D 9
    cardSpread: 0.7, // guess
    mixUpRate: 0.4, // guess
    lookAlikeRate: 0.25, // guess
    lookAlikeFadeDays: 7, // guess
    slipRate: 0.03, // easy choice-reaction tasks: 1–3% errors
    rushSlipRate: 0.05, // guess
  );

  /// Recall at a gap equal to the memory's stability (FSRS's definition).
  static const double stabilityRecall = 0.9;

  /// Recall after a gap t at stability S: (1 + f × t / S)^-forgettingDecay,
  /// f set so that recall is [stabilityRecall] at t = S. 1 is FSRS v4's
  /// curve, steeper than FSRS-6's whole-deck 0.2, which is flattened by
  /// cards that differ.
  static const double forgettingDecay = 1;

  /// Stability growth from a recall minutes after the last look (FSRS-6
  /// same-day reviews: ×1.3 for a one-day memory).
  static const double massedGrowth = 1.2;

  /// How steeply recall growth rises as the recall chance falls (FSRS-6
  /// default w10).
  static const double spacingGrowth = 1.0178;

  /// Share of stability kept after forgetting a card (FSRS-6 defaults:
  /// 20–50% of a 1–10 day memory).
  static const double lapseKept = 0.3;

  /// Share of the mix-up chance left after each correct answer (guess).
  static const double mixUpKept = 0.6;

  /// Spread (σ) of log response times (choice reaction times vary by
  /// 20–30%).
  static const double timeNoise = 0.25;

  /// An answer quicker than this share of the usual time is a rush (guess).
  static const double rushRatio = 0.8;

  /// Upside-down cards are this much slower (guess).
  static const double invertedFactor = 1.2;

  /// Share of practice (repetitions) kept overnight, and after forgetting
  /// (guess).
  static const double overnightRepsKept = 0.85;
  static const double forgottenRepsKept = 0.5;

  /// Practice counted for a missed answer, against 1 for a correct one.
  static const double missRep = 0.5;

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

  /// The learner's and planner's seed. With FSRS's interval fuzz off, a
  /// rerun replays exactly.
  static const int seed = 1;

  /// Local hour at which a simulated day's set is looked at (any hour of
  /// the day's practice window).
  static const int setCheckHour = 12;

  /// Time between one simulated sitting's end and the next one's start.
  static const Duration sittingGap = Duration(hours: 2);

  /// Safety stop on the sittings a simulated day plays to finish its set.
  static const int maxSittingsPerDay = 20;
}

/// Dev-mode demo data (`seedDemoData`): a journey player's recent history,
/// simulated day by day through the real training path.
abstract final class DemoDataTuning {
  /// Days simulated, ending yesterday.
  static const int days = 14;

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

  /// The rank-up from `Rating.bands[rankFrom]` (F上級) to the next class:
  /// from [rankBelow] points under its threshold to [rankAbove] over it.
  static const int rankFrom = 2;
  static const double rankBelow = 58;
  static const double rankAbove = 14;

  /// "Preview rating": [ratingInto] points into the same class, gaining
  /// [ratingGain].
  static const double ratingInto = 250;
  static const double ratingGain = 26;

  /// The personal best: [cards] cards averaging [averageUs], spread evenly
  /// [spreadUs] apart, [total] in all against a [previousBest].
  static const int cards = 20;
  static const int averageUs = 642000;
  static const int spreadUs = 20000;
  static const total = Duration(milliseconds: 14906);
  static const previousBest = Duration(milliseconds: 15380);

  /// The run's XP, one line per source (count, XP), landing [levelInto]
  /// XP into [level] before it.
  static const List<(XpSource, int, int)> xp = [
    (XpSource.correct, 27, 270),
    (XpSource.missed, 3, 6),
    (XpSource.speed, 15, 110),
    (XpSource.reviews, 9, 45),
    (XpSource.newCards, 3, 75),
    (XpSource.clear, 1, 20),
    (XpSource.daily, 5, 90),
    (XpSource.best, 1, 100),
    (XpSource.island, 1, 300),
    (XpSource.graduation, 1, 1000),
  ];
  static const int level = 7;
  static const int levelInto = 500;

  /// "Preview XP": a typical round's XP, landing [roundInto] XP into
  /// [level] before it and reaching no new level.
  static const List<(XpSource, int, int)> xpRound = [
    (XpSource.correct, 28, 280),
    (XpSource.missed, 2, 4),
    (XpSource.speed, 12, 85),
    (XpSource.reviews, 8, 40),
    (XpSource.clear, 1, 20),
    (XpSource.daily, 3, 70),
  ];
  static const int roundInto = 150;

  /// "Preview AnkiRen XP": a ranked 暗記練 game's XP, one line per source
  /// (count, XP), landing [ankirenRoundInto] XP into [ankirenLevel] and
  /// reaching no new level, or [ankirenLevelInto] in and reaching one.
  static const List<(XpSource, int, int)> ankirenXp = [
    (XpSource.firstTap, 12, 960),
    (XpSource.nearMiss, 3, 100),
    (XpSource.missed, 1, 2),
    (XpSource.speed, 15, 320),
    (XpSource.clear, 1, 20),
    (XpSource.ranked, 1, 50),
    (XpSource.best, 1, 200),
  ];
  static const int ankirenLevel = 40;
  static const int ankirenRoundInto = 60;
  static const int ankirenLevelInto = 1000;

  /// 暗記練's rating page: [ankirenInto] points into `Rating.bands[ankirenClass]`
  /// (E下級), moving [ankirenMove]; a breakthrough or a fall crosses its
  /// threshold by [ankirenCross]. Placement: the games' scores, the rating
  /// after the second and after the third, and the game played after
  /// placement.
  static const int ankirenClass = 3;
  static const double ankirenInto = 60;
  static const double ankirenMove = 58;
  static const double ankirenCross = 24;
  static const List<int> ankirenPlacementScores = [612, 845, 903];
  static const double ankirenPlacing = 1010;
  static const double ankirenPlaced = 1180;
  static const int ankirenGame = 9;

  /// Today's set done (the mock's day): the bar's looks for reviews, new
  /// cards and misses, over [dayRounds] runs, with [dayNewCards] new cards,
  /// [dayMisses] misses fixed and a goal streak of [dayStreak] days.
  static const int dayReviewLooks = 22;
  static const int dayNewLooks = 16;
  static const int dayExtraLooks = 6;
  static const int dayRounds = 2;
  static const int dayNewCards = 4;
  static const int dayMisses = 6;
  static const int dayStreak = 5;
}

/// Sound pooling (`lib/ui/sound/sounds.dart`): concurrent, identically
/// loaded players kept per asset, so a sound that can retrigger faster than
/// one play of it lasts (a card flick during a swiping streak) overlaps
/// instead of cutting itself off.
abstract final class SoundTuning {
  static const int cardFlickPoolSize = 3;

  /// The XP counter ticks faster than one tick lasts.
  static const int xpTickPoolSize = 4;

  /// Fireworks, breakdown pops and the rating's heartbeat can land on top
  /// of each other.
  static const int burstPoolSize = 2;

  /// The rating's ratchet clicks faster than one click lasts.
  static const int ratingTickPoolSize = 4;

  /// 暗記練's takes and wrong taps can follow each other faster than one
  /// lasts.
  static const int ankirenTapPoolSize = 2;
}

/// Background music (`Music` in `lib/ui/sound/sounds.dart`): a single
/// looping track, playing only on menu screens (Home and its tabs, Settings,
/// onboarding, the tour) and faded out for a play/swipe screen and a run's
/// celebration.
abstract final class MusicTuning {
  static const String asset = 'sounds/bgm_fun_022824.m4a';

  /// How long a fade takes either way.
  static const Duration fadeIn = Duration(milliseconds: 900);
  static const Duration fadeOut = Duration(milliseconds: 600);

  /// Volume steps a fade is split into; smooth without waking up too often.
  static const int fadeSteps = 20;

  /// The volume slider is perceptual, the player's gain a linear amplitude:
  /// the gain is the slider's position to this power, so halfway sounds
  /// about half as loud (−12 dB) instead of hardly quieter than full (−6 dB).
  static const double volumeExponent = 2;
}

/// What a sound belongs to. Each category has its own Settings switch
/// (`AppSettings.plays`), and silent or vibrate mode mutes them all.
enum SoundCategory {
  /// Background music (see [Music]), switched by [AppSettings.music] and
  /// its volume slider ([AppSettings.musicVolume]).
  music,

  /// A card being swiped away: every card that leaves the deck during play,
  /// and the new-card page's flick.
  swipe,

  /// Every other sound: new cards and islands, XP, level-ups, the rating,
  /// rank-ups, graduation and Results.
  effects,
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
    category: SoundCategory.swipe,
  ),
  lookAlike(['sounds/look_alike.wav'], 0.7),
  island(['sounds/island.wav'], 0.8),
  stamp(['sounds/stamp.wav'], 0.9),
  rankUp(['sounds/rank_up.wav'], 0.8),
  goalUp(['sounds/goal_up.wav'], 0.8),
  best(['sounds/best.wav'], 0.8),
  results(['sounds/results.wav'], 0.5),
  xpTick(['sounds/xp_tick.wav'], 0.45, poolSize: SoundTuning.xpTickPoolSize),
  xpPop(['sounds/xp_pop.wav'], 0.6, poolSize: SoundTuning.burstPoolSize),
  xpDone(['sounds/xp_done.wav'], 0.8),
  levelUp(['sounds/level_up.wav'], 0.8),
  ratingTick(['sounds/rating_tick.wav'], 0.4, poolSize: SoundTuning.ratingTickPoolSize),
  ratingUp(['sounds/rating_up.wav'], 0.8),
  ratingStrain(['sounds/rating_strain.wav'], 0.9, poolSize: SoundTuning.burstPoolSize),
  ratingBreak(['sounds/rating_break.wav'], 0.9),
  graduation(['sounds/graduation.wav'], 0.85),

  /// 暗記練: the card asked for taken, another one tapped, the field turning
  /// face down, and the first card asked.
  ankirenTake(
    ['sounds/ankiren_take_0.wav', 'sounds/ankiren_take_1.wav', 'sounds/ankiren_take_2.wav'],
    0.8,
    poolSize: SoundTuning.ankirenTapPoolSize,
  ),
  ankirenWrong(['sounds/ankiren_wrong.wav'], 0.75, poolSize: SoundTuning.ankirenTapPoolSize),
  ankirenFlip(['sounds/ankiren_flip.wav'], 0.7),
  ankirenRecall(['sounds/ankiren_recall.wav'], 0.6),
  firework(
    ['sounds/firework_0.wav', 'sounds/firework_1.wav', 'sounds/firework_2.wav'],
    0.6,
    poolSize: SoundTuning.burstPoolSize,
  );

  const Sfx(this.assets, this.volume, {this.poolSize = 1, this.category = SoundCategory.effects});
  final List<String> assets;
  final double volume;

  /// Whose Settings switch it plays under.
  final SoundCategory category;

  /// Players preloaded per asset (see [SoundTuning]); 1 unless a sound needs
  /// to overlap itself.
  final int poolSize;
}

/// The pre-generated kimariji readouts (`scripts/kimariji_voice.py`), one
/// clip per poem, played on demand by the speaker button next to a card's
/// kimariji — never preloaded like [Sfx], since only one plays at a time and
/// it's never on the play loop's critical path.
abstract final class VoiceTuning {
  static String kimarijiAsset(int poemId) => 'voice/kimariji/${poemId.toString().padLeft(3, '0')}.m4a';
  static const double volume = 1;
}

/// 暗記練 (the memorisation side trip): its levels and custom setups
/// (`AnkirenSetup`), how a field is dealt (`AnkirenDealer`), and a game's
/// prompts and points (`AnkirenGame`, `AnkirenScore`).
abstract final class AnkirenTuning {
  /// The levels, 0 first: cards per side and memorise time. Level 0 is for
  /// beginners: its cards lie spread out in the open middle (see
  /// [AnkirenLevel.allInMiddle]). The field grows to a real match's 25 a side
  /// at level 8, and the last levels cut the memorise time from 15 minutes,
  /// a real match's, to 8. Ranked play moves through them by rating.
  static const List<AnkirenLevel> levels = [
    AnkirenLevel(3, Duration(minutes: 1, seconds: 30), allInMiddle: true),
    AnkirenLevel(4, Duration(minutes: 1, seconds: 30)),
    AnkirenLevel(5, Duration(minutes: 2, seconds: 30)),
    AnkirenLevel(7, Duration(minutes: 4)),
    AnkirenLevel(10, Duration(minutes: 6)),
    AnkirenLevel(13, Duration(minutes: 6)),
    AnkirenLevel(18, Duration(minutes: 10)),
    AnkirenLevel(21, Duration(minutes: 12)),
    AnkirenLevel(25, Duration(minutes: 15)),
    AnkirenLevel(25, Duration(minutes: 12)),
    AnkirenLevel(25, Duration(minutes: 8)),
  ];

  /// A custom free-play setup's cards per side (and at most half the known
  /// cards).
  static const int customMinPerSide = 2;
  static const int customMaxPerSide = 25;

  /// A custom setup's memorise times: [customFineStep]s up to
  /// [customFineUntil], [customCoarseStep]s after.
  static const Duration customMinMemorise = Duration(seconds: 10);
  static const Duration customMaxMemorise = Duration(minutes: 15);
  static const Duration customFineStep = Duration(seconds: 10);
  static const Duration customFineUntil = Duration(minutes: 1);
  static const Duration customCoarseStep = Duration(seconds: 30);

  /// Middle cards: a side splits a 友札 pair (e.g. なげき and なげけ) by putting
  /// one of them in the open middle of its 上段, the row at the centre line.
  /// With [middleChancePerSide], a side that holds such a pair puts
  /// [middleMin] to [middleMax] cards there, each with a 友札 left in its
  /// clusters. Only a side of at least [middleMinPerSide] cards does, and
  /// keeps at least [middleMinClustered] in its clusters. At a real match's
  /// 25 a side (4 sides in 5 hold a pair) about 1 game in 5 has some.
  static const double middleChancePerSide = 0.13;
  static const int tomofudaMinShared = 2;
  static const int middleMin = 1;
  static const int middleMax = 5;
  static const int middleMinPerSide = 21;
  static const int middleMinClustered = 10;
  static const FieldRow middleRow = FieldRow.upper;

  /// A side's cluster cards take 下段 alone up to [singleRowUpTo] cards, 下段
  /// and 中段 (half each, 下段 the odd one) up to [twoRowsUpTo], and all three
  /// rows above that, like a real 定位置 being built up from 下段.
  static const int singleRowUpTo = 4;
  static const int twoRowsUpTo = 8;

  /// With all three rows: 中段's share, in percent and rounded up, of the
  /// cards left after 下段 (a third, rounded up); never more than 下段. 上段
  /// takes the rest.
  static const int middleRowPercent = 55;

  /// No two deals take the same shape: a side's rows may each differ from
  /// the shape above by up to [rowJitter] cards, and each row's split
  /// between the left and right clusters leans one card further to a side
  /// with [splitLean] (see `AnkirenDealer.rowShapes`, `leftOf`).
  static const int rowJitter = 1;
  static const double splitLean = 0.25;

  /// The most cards a row holds, its middle cards counted, so a folded
  /// field is at most [rowMax] + 1 cards wide (see `FieldGeometry`). 上段
  /// passes any cards over to 下段 and 中段 to keep room for its middle cards.
  static const int rowMax = 9;

  /// Wrong taps on one prompt after which its card is shown.
  static const int revealAfterWrong = 2;

  /// Points per card (see `AnkirenScore`): a tap on it earns [cardPoints],
  /// and a speed bonus of up to [speedMax] when it was the first tap.
  static const int cardPoints = 100;
  static const int speedMax = 100;

  /// The share of [cardPoints] a tap earns by where it lands, from the card
  /// asked to the other side.
  static const Map<TapProximity, double> tapShare = {
    TapProximity.card: 1,
    TapProximity.neighbour: 0.6,
    TapProximity.row: 0.4,
    TapProximity.quadrant: 0.25,
    TapProximity.side: 0.15,
    TapProximity.otherSide: 0,
  };

  /// How much each tap while a card is asked counts, in order: the first
  /// in full, the second a fifth; any later tap adds nothing. The second
  /// is weighted so little that a wrong first tap, however near, and a
  /// right second one earn less than the card found with the first.
  static const List<double> tapWeights = [1, 0.2];

  /// Being ready before the memorise time is up multiplies the points by up
  /// to 1 + [earlyBonus], in proportion to the share of the time left.
  static const double earlyBonus = 0.5;

  /// Each level below the top multiplies the score by [levelFactor] once
  /// more, so being ready early at a level never beats the next level's
  /// shorter time played in full (level 9 ended at 8 minutes scores below
  /// level 10).
  static const double levelFactor = 0.85;

  /// The speed bonus's curve over the response time t: a logistic curve over
  /// ln t, centred on [speedMidpoint] and as steep as [speedSteepness],
  /// stretched to be exactly [speedMax] at [speedFull] and 0 at [speedNone].
  /// Fitted to [speedTargets]: it gives 100, 88, 72, 56, 16.
  static const Duration speedFull = Duration(milliseconds: 100);
  static const Duration speedNone = Duration(seconds: 5);
  static const Duration speedMidpoint = Duration(milliseconds: 1650);
  static const double speedSteepness = 1.1;

  /// The response times (ms) the curve was fitted to, and their bonus.
  static const Map<int, int> speedTargets = {100: 100, 300: 90, 600: 75, 1000: 50, 3000: 20};
}

/// The developer's 暗記練 tools (`AnkirenToolsPage`): the points calculator's
/// response-time range and the middle-card simulator's game counts.
abstract final class AnkirenToolsTuning {
  static const Duration responseMin = Duration(milliseconds: 100);
  static const Duration responseMax = Duration(seconds: 6);
  static const Duration responseStep = Duration(milliseconds: 100);
  static const Duration responseStart = Duration(seconds: 1);

  /// The curve is drawn every [curveStepMs] ms.
  static const int curveStepMs = 25;

  /// The total-points graphs: the time-left sliders' step, and the gap
  /// between the x axis's labels.
  static const Duration timeLeftStep = Duration(seconds: 10);
  static const Duration timeLeftTick = Duration(minutes: 3);
  static const Duration responseTick = Duration(seconds: 1);
  static const int yDivisions = 4;

  /// The time-used graph's marker starts here: a 12:00 level ended at 8:00
  /// against the 8:00 level played in full.
  static const Duration timeUsedStart = Duration(minutes: 8);

  static const List<int> simulationGames = [100, 1000, 5000];
  static const int simulationGamesStart = 1000;

  /// Seeds tried when looking for a game with middle cards.
  static const int seedSearchLimit = 20000;
}

/// 暗記練's play screen (`AnkirenScreen`): its pace between prompts.
abstract final class AnkirenPlayTuning {
  /// Before each prompt shows: after the field turns face down, and after
  /// the card before it is found, so its flip and sound land first.
  static const Duration promptPause = Duration(milliseconds: 350);

  /// After the last card is found, before Results.
  static const Duration finishPause = Duration(milliseconds: 700);

  /// A card given up ("don't know") rumbles this long, then turns face up.
  static const Duration givenUpReveal = Duration(milliseconds: 900);

  /// The memorise countdown's step: it shows whole seconds.
  static const Duration clockTick = Duration(seconds: 1);
}

/// 暗記練's rating (see `AnkirenRating`), on the main rating's scale.
abstract final class AnkirenRatingModel {
  /// Each level's difficulty: a game at [par] holds the rating there. Level
  /// 0's is the start and the floor (入門).
  static const List<double> levelRatings = [400, 650, 900, 1150, 1400, 1650, 1900, 2150, 2400, 2650, 2900];

  /// Performance points per unit of score fraction above or below [par]. A
  /// game at par finds about 70% of the cards with the first tap, in 1.5 s,
  /// 10% with the second after a first tap in their row, and taps twice on
  /// the right side for the rest.
  static const double weight = 1000;
  static const double par = 0.54;

  /// Placement: the first [placementGames] ranked games stretch the
  /// performance by [placementStretch] and move the rating by [placementK]
  /// of the way to it; later games by [establishedK].
  static const int placementGames = 3;
  static const double placementStretch = 2;
  static const double placementK = 1;
  static const double establishedK = 0.35;
}

/// Experience from a 暗記練 game (`AnkirenXp`), on [XpTuning]'s scale. Most of
/// a game is memorising, about 10–18 s a card at every level, so its XP is
/// paid per card, by what its taps earned: a game at par earns about what
/// main runs earn over the same time (about 5½ XP a second; a level 2 game
/// of about 2 minutes, some 800). Derived from the recorded games, like
/// [XpTuning].
abstract final class AnkirenXpTuning {
  /// A card found with the first tap at level 0, and what each level above
  /// adds. Any other card earns the same share of this as of its points
  /// (`AnkirenScore.share`).
  static const int firstTap = 70;
  static const int firstTapPerLevel = 5;

  /// The speed bonus for the time of a first tap that found its card:
  /// `AnkirenScore.speedShare` of this.
  static const int speedMax = 40;

  /// Each card whose taps earned nothing, in a game played to the end.
  static const int perMiss = XpTuning.perMiss;

  /// A game played to the end; a ranked one earns [ranked] on top.
  static const int clear = XpTuning.clear;
  static const int ranked = 50;

  /// A completed game scoring higher than every earlier one with its setup.
  static const int personalBest = XpTuning.personalBest;

  /// The ranked game that finishes placement and reveals the first class.
  static const int placement = 300;
}

/// The real 競技かるた field that 暗記練 lays out (`FieldGeometry`), cm.
abstract final class AnkirenFieldSize {
  /// A torifuda.
  static const double cardW = 5.2;
  static const double cardH = 7.3;

  /// Between the cards of a row, and between rows.
  static const double cardGap = 0.1;
  static const double rowGap = 1;

  /// A half's true width and the card slots across it.
  static const double territoryW = 87;
  static const int slots = 16;

  /// The folded field's open middle, in card pitches (card + gap):
  /// [foldedHole], or room for a row's middle cards plus [middleMargin]
  /// either side.
  static const double foldedHole = 0.6;
  static const double middleMargin = 0.5;
}
