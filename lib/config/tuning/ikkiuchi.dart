part of '../config.dart';

/// 一騎打ち (a full match against Tobi): every value Tobi plays with comes
/// from his rating through these curves (`IkkiuchiTobi`). Each curve is
/// anchor points (rating, value), joined by a smooth curve that passes
/// through each point and never overshoots, times smoothed on a log scale,
/// and held flat past both ends (`TuningCurve`).
/// Times count from the end of the called card's deciding sound in its
/// voice clip.
abstract final class IkkiuchiTuning {
  /// The ratings the curves cover.
  static const double ratingMin = 0;
  static const double ratingMax = 3600;

  /// Median time to land on a card he knows at the average arm distance,
  /// ms: reaction plus swing. 400 at 2800 is a sharp reaction and a quick
  /// swing; 180 at 3600 is about the fastest that still reads as reacting
  /// to the sound rather than guessing.
  static const takeMs = TuningCurve.log([
    (0, 3400), (400, 2900), (800, 2350), (1200, 1800), (1600, 1300), (2000, 880),
    (2400, 600), (2800, 400), (3200, 260), (3400, 215), (3600, 180),
  ]);

  /// The card-to-card spread of [takeMs]: the standard deviation of its
  /// natural log (a log-normal draw). A strong Tobi is steadier.
  static const takeSpread = TuningCurve([(0, 0.55), (1200, 0.5), (2400, 0.42), (3600, 0.35)]);

  /// The chance per field card read that he doesn't know its spot at once
  /// and has to look for it (a blank).
  static const blankChance = TuningCurve([
    (0, 0.97), (400, 0.95), (600, 0.84), (800, 0.71), (1200, 0.48), (1600, 0.29),
    (2000, 0.13), (2400, 0.04), (2800, 0.015), (3200, 0.006), (3400, 0.004), (3600, 0.003),
  ]);

  /// What a blank adds to [takeMs]: a log-normal draw with this median, ms,
  /// and [searchSpread].
  static const searchMs = TuningCurve.log([(0, 4500), (1600, 3000), (3600, 1500)]);
  static const double searchSpread = 0.5;

  /// The chance per call that he goes for a look-alike of the called card
  /// first, when one is on the field: a 友札, on which he goes one kana
  /// early, or a card whose torifuda looks alike.
  static const lookAlikePull = TuningCurve([
    (0, 0.3), (800, 0.22), (1600, 0.14), (2400, 0.07), (2800, 0.035), (3600, 0.008),
  ]);

  /// On a からふだ with no look-alike on the field, his chance to touch a
  /// card anyway, as a share of [lookAlikePull].
  static const double strayShare = 0.15;

  /// After touching a wrong card, he goes for the right one this much later.
  static const Duration correction = Duration(milliseconds: 350);

  /// His arm's swing at the average distance, ms: part of [takeMs]. A card
  /// at distance d takes swing × (1 + [armDistanceWeight] × (d / mean − 1)).
  static const armMs = TuningCurve.log([(0, 330), (1600, 220), (2800, 150), (3600, 100)]);
  static const double armDistanceWeight = 0.5;

  /// The take's animation, from the start of his reach to the hit, ms. No
  /// hit's reach is ever shorter than [reachFloorMs], even when a quick
  /// take squeezes it.
  static const reachMs = TuningCurve([(0, 1000), (1800, 287.5), (3600, 150)]);
  static const double reachFloorMs = 130;

  /// The chance a 送り札 he sends splits a look-alike pair (its look-alike
  /// stays on his side); otherwise he sends a random card.
  static const smartSend = TuningCurve([(0, 0), (800, 0), (2000, 0.5), (2800, 0.85), (3600, 0.95)]);

  /// How long he takes to lay out his side before the match, while the
  /// player lays out theirs, in seconds.
  static const placingSeconds = TuningCurve.log([
    (0, 100), (1000, 78), (1800, 55), (2400, 39), (2786, 30), (3600, 24),
  ]);

  /// His arm move for each card, drawn at random: the clean row sweep (払い)
  /// takes [sweepShare], and the rest is split between the three wild moves
  /// by [wildMoves]. A move changes only the look and how the cards fly:
  /// it is picked after his time is set, its animation is fitted into his
  /// reach, and the cards it knocks never count as touches.
  static const sweepShare = TuningCurve([
    (0, 0), (800, 0.05), (1600, 0.2), (2400, 0.45), (2800, 0.6), (3600, 0.75),
  ]);
  static const ({double whip, double coilLunge, double smear}) wildMoves = (whip: 0.4, coilLunge: 0.35, smear: 0.25);

  /// His form for a match: a normal draw with standard deviation [formSd],
  /// drawn again whenever it lands more than [formCutOff] away, added to his
  /// rating before every curve is read, in ranked and free matches alike.
  /// It is drawn from the match's seed plus [formSeedOffset], apart from
  /// the deal.
  static const double formSd = 100;
  static const double formCutOff = 200;
  static const int formSeedOffset = 1299709;
}

/// Tobi's own fixed layout for a match (`IkkiuchiLayout`): a home spot for every
/// card that may come to his side, from his rating.
abstract final class IkkiuchiLayoutTuning {
  /// The chance that one group stays together, decided from the match's
  /// seed for each group on its own; set so that about 20% of games at 2600
  /// (25 cards a side from all 100) have at least one group together.
  /// - [soundGrouping]: a group of cards with the same first sound (the
  ///   one-sound cards as one group) lies together, its 友札 side by side.
  /// - [tomofudaGrouping]: a family of look-alikes (友札) lies side by side
  ///   when its sound group doesn't. A family he splits is spread apart.
  static const soundGrouping = TuningCurve([
    (0, 1), (1200, 0.31), (2000, 0.1), (2600, 0.034), (3000, 0.016), (3600, 0.0047),
  ]);
  static const tomofudaGrouping = TuningCurve([
    (0, 1), (1200, 0.81), (2000, 0.28), (2600, 0.127), (3000, 0.06), (3600, 0.0175),
  ]);

  /// His own cards' shape, drawn each match, the same at every rating. Each
  /// row gets one card, then the rest go by each row's share: its [rowLean]
  /// (下段 first) times a random factor within 1 ± [rowJitter]. Each row's
  /// left share is a half, plus the match's lean to one side within
  /// ±[sideLean], plus the row's own within ±[splitJitter].
  static const List<double> rowLean = [1.1, 1, 0.9];
  static const double rowJitter = 0.45;
  static const double sideLean = 0.1;
  static const double splitJitter = 0.15;

  /// A side has [rows] rows; 2 only with at most [twoRowsUpTo] cards a
  /// side, 1 only with at most [oneRowUpTo].
  static const int rows = 3;
  static const int twoRowsUpTo = 16;
  static const int oneRowUpTo = 8;

  /// A row is at most [rowSlots] card pitches (card and gap) across, its
  /// left and right groups at least [groupGap] apart.
  static const double rowSlots = 16.5;
  static const double groupGap = 0.5;

  /// Two cards are look-alikes (友札) when their kimariji share at least
  /// [lookAlikeShared] opening sounds and all but the last of the shorter.
  static const int lookAlikeShared = 2;

  /// Cards whose kimariji has at most [nearRowSounds] sounds count as one
  /// group, and go to 下段, nearest his hand, while it has room.
  static const int nearRowSounds = 1;
}

/// The player's side as they lay it out (`IkkiuchiSides.rules`): the open
/// middle of [middleRow], the front row by the centre line, takes cards,
/// each at least [middleMargin] card pitches clear of the row's groups. It
/// takes taps and drops over [openMiddleShare] of the room between the
/// groups, in its middle, and over its middle cards. Tobi keeps his open
/// middles empty.
abstract final class IkkiuchiPlacingTuning {
  static const FieldRow middleRow = FieldRow.upper;
  static const double middleMargin = 0.5;
  static const double openMiddleShare = 1 / 3;
}

/// The 一騎打ち field as it lies on the board (`IkkiuchiField`), in card
/// widths: a card's height (a torifuda's, 73 × 52 mm), and the gaps between
/// the cards of a group and between rows. A row's groups are at least
/// [IkkiuchiLayoutTuning.groupGap] card pitches apart.
abstract final class IkkiuchiFieldTuning {
  static const double cardAspect = 1.404;
  static const double cardGap = 0.02;
  static const double rowGap = 0.19;

  /// The gap between a side's rows in landscape: two thirds of [rowGap].
  static const double landscapeRowGap = rowGap * 2 / 3;
}

/// Tobi's body in a strike, squashed and stretched about his feet: its
/// width and height as shares of his own, a turn toward the card (radians),
/// and a shift toward the card and down, in Tobi units (his art's units).
typedef IkkiuchiBodyPose = ({double sx, double sy, double turn, double forward, double down});

/// A spring that dies out: it decays by [decay] over its time and swings
/// [waves] half waves.
typedef IkkiuchiSpring = ({double decay, double waves});

/// Tobi's arm in a strike (`IkkiuchiStrike`): how the hand's path bends the
/// arm, when the fist touches, and how the follow-through and the way home
/// go. Lengths are card widths (a card's width on the board), so a strike
/// plays alike at any card size, unless they say Tobi units (his art's
/// units, k dp each) or dp; times are the move's own ms unless they say
/// screen ms.
abstract final class IkkiuchiArmTuning {
  /// Points along the arm's curve; more while it is wound into loops.
  static const int samples = 28;
  static const int coilSamples = 72;
  static const int coilLoops = 4;

  /// Each point along the arm shows where the hand was a little earlier,
  /// the most at the shoulder: the lag grows by this power from the hand.
  static const double lagPower = 1.1;

  /// The wave that travels along the arm: waves along it, and its period.
  static const double waveLength = 1.6;
  static const double wavePeriod = 170;

  /// The fist's radius, and how near its centre a card counts as touched,
  /// in fist radii.
  static const double fist = 0.22;
  static const double touch = 1.2;

  /// The point between his feet his body squashes and turns about, Tobi units.
  static const ({double x, double y}) feet = (x: 40, y: 93);

  /// A card more than [sideDeadZone] left or right of his middle is struck
  /// with the arm on that side; a nearer one by its id. He leans toward a
  /// card more than [leanDeadZone] from his middle, else toward his arm.
  static const double sideDeadZone = 0.11;
  static const double leanDeadZone = 0.33;

  /// The hand keeps [screenMargin] inside the board's edges, the smear's
  /// arc [arcMargin]; the row sweep stops [rowExitInset] short of the edge.
  static const double screenMargin = 0.44;
  static const double arcMargin = 0.28;
  static const double rowExitInset = 0.28;

  /// How far past its resting place the hand may fly on its way home.
  static const double overshootCap = 1.3;

  /// A strike plays its move faster or slower so the hit comes at its reach
  /// time; after the hit the follow-through and the way home go at the same
  /// pace, held between these, so a very fast or slow take still recoils
  /// readably.
  static const ({double min, double max}) afterPace = (min: 0.6, max: 1.4);

  /// The follow-through after the hit carries on outward or sideways, never
  /// toward the side without the called card. It grows with the take's
  /// speed (by the square root of how much faster than the move's own
  /// timing), held within [followScale]; turned sideways it keeps at least
  /// [followKeep] of its length; its bend toward the called card's side
  /// starts [followBendAt] along it.
  static const ({double min, double max}) followScale = (min: 0.85, max: 1.25);
  static const double followKeep = 0.5;
  static const double followBendAt = 0.6;

  /// The brake: the live fist's touch stays [clearance] from every card on
  /// the side without the called card. A hit that would land nearer moves
  /// toward the called card's side just far enough to keep it, and the
  /// follow-through stops short before it comes nearer. A follow-through
  /// cut short takes less time, by the square root of the share left, at
  /// least [brakeMin]. The path is searched in [brakeSamples] steps, then
  /// halved [brakeRefine] times; the hit's place is halved as often.
  static const double clearance = 0.22;
  static const double brakeMin = 0.45;
  static const int brakeSamples = 64;
  static const int brakeRefine = 12;

  /// The live fist's path is checked for touches this often, so none falls
  /// between two steps of the board.
  static const double touchStep = 2;

  /// His face turns from reaching to how the strike ended this long after
  /// the hit stop, and he keeps it [restFaceHold] after the strike; screen ms.
  static const double faceAfterHit = 130;
  static const double restFaceHold = 950;

  /// Over the strike's last [fistSettle] ms the fist turns into the end
  /// pose's hand.
  static const double fistSettle = 140;

  /// A hand's speed is measured over this many ms.
  static const double speedWindow = 6;
}

/// The wide whip: the arm curls out wide to the side, cracks across the
/// card and snaps back on a spring. Phases in ms: the wind-up, the swing
/// out to the card, the follow-through and the way home.
abstract final class IkkiuchiWhipTuning {
  static const double windUp = 170;
  static const double out = 230;
  static const double follow = 130;
  static const double back = 420;
  static const double hitStop = 60;

  /// The wind-up draws the hand back and out, Tobi units.
  static const double windBack = 16;
  static const double windOut = 12;

  /// The swing's curve bows out by [bow] of the reach, at least [bowMin]
  /// card widths, from [bowAt] along the way to the card; it eases in by
  /// [outPower].
  static const double bowAt = 0.45;
  static const double bow = 0.42;
  static const double bowMin = 1.95;
  static const double outPower = 1.7;

  /// The follow-through runs on [followShare] of the reach, within
  /// [followMin]..[followMax] card widths.
  static const double followShare = 0.16;
  static const double followMin = 0.83;
  static const double followMax = 2.2;
  static const IkkiuchiSpring home = (decay: 4.6, waves: 2.6);

  /// The arm's lag in each phase (at rest, wind-up, out, follow-through,
  /// home), ms; its wave and bulge, Tobi units.
  static const double lagRest = 20;
  static const double lagWind = 30;
  static const double lagOut = 88;
  static const double lagFollow = 90;
  static const double lagHome = 64;
  static const double waveWind = 1.5;
  static const double waveOut = 3;
  static const double waveFollow = 5;
  static const double waveHome = 9;
  static const double bulgeWind = 8;
  static const double bulgeOut = 16;

  /// His body: wound up, struck, turned on through the follow-through; the
  /// strike's pose reached [strikeQuick] times faster than the swing.
  static const IkkiuchiBodyPose wound = (sx: 1.05, sy: 0.93, turn: -0.08, forward: -2, down: 2);
  static const IkkiuchiBodyPose struck = (sx: 0.95, sy: 1.07, turn: 0.11, forward: 4, down: -5);
  static const double followTurn = 0.15;
  static const double strikeQuick = 2.2;
}

/// The coil and lunge: the arm winds into a spring beside him while he
/// squashes down and shakes, then shoots out straight and sweeps the card
/// off its row. Phases in ms: the coil, the shaking hold, the lunge, the
/// sweep across the card, the way home.
abstract final class IkkiuchiCoilTuning {
  static const double coil = 300;
  static const double hold = 60;
  static const double lunge = 110;
  static const double sweep = 100;
  static const double back = 340;
  static const double hitStop = 60;

  /// The coil winds about a point [coilOut] out and [coilForward] forward of
  /// his shoulder, [turns] times, down to [coilRadius]; Tobi units.
  static const double coilOut = 20;
  static const double coilForward = 4;
  static const double turns = 1.6;
  static const double coilRadius = 14;

  /// The hold shakes the hand [shake] Tobi units at [shakeRate] radians per
  /// ms, and his body [bodyShake] dp at [bodyShakeRate].
  static const double shake = 1.3;
  static const double shakeRate = 0.55;
  static const double bodyShake = 1.2;
  static const double bodyShakeRate = 0.9;

  /// The lunge lands [landOut] outside the card and [landBack] short of it;
  /// the sweep crosses to [sweepOut] past its other side and [sweepOn] on;
  /// the hit comes [hitInto] into the sweep. Card widths.
  static const double landOut = 0.85;
  static const double landBack = 0.2;
  static const double sweepOut = 1.6;
  static const double sweepOn = 0.38;
  static const double hitInto = 0.85;

  /// The way home overshoots by this much (a back-out ease).
  static const double homeOvershoot = 1.6;

  /// The arm's lag in each phase, ms (easing from [lagCoil] to [lagLunge]
  /// over the lunge); its wave and its coil's loops, Tobi units.
  static const double lagRest = 20;
  static const double lagCoil = 40;
  static const double lagLunge = 14;
  static const double lagSweep = 30;
  static const double lagHome = 26;
  static const double waveSweep = 2;
  static const double waveHome = 5;
  static const double coilLoop = 7;

  /// The coil's loops unwind [unwindQuick] times faster than the lunge.
  static const double unwindQuick = 2.2;

  /// His body: squashed by the coil, stretched by the lunge, twisted by
  /// the sweep, and its spring home.
  static const IkkiuchiBodyPose squashed = (sx: 1.08, sy: 0.86, turn: -0.06, forward: 0, down: 4);
  static const IkkiuchiBodyPose stretched = (sx: 0.93, sy: 1.1, turn: 0.12, forward: 5, down: -6);
  static const double sweepTurn = 0.2;
  static const IkkiuchiSpring bodyHome = (decay: 5, waves: 2.4);
}

/// The smear swing: a huge hammer swing with smear afterimages, a big
/// impact, then a floppy rubber-band recoil. Phases in ms: the draw back,
/// the arc down onto the card, the follow-through and the way home.
abstract final class IkkiuchiSmearTuning {
  static const double draw = 150;
  static const double arc = 200;
  static const double follow = 150;
  static const double back = 460;
  static const double hitStop = 90;

  /// The arc is half an ellipse about the middle of the way to the card:
  /// it bows out by [bow] of the reach, at least [bowMin] and [edgeRoom]
  /// short of the board's edge, in card widths. It starts [overhead]
  /// radians past straight back and eases in by [arcPower].
  static const double bow = 0.55;
  static const double bowMin = 1.15;
  static const double edgeRoom = 0.39;
  static const double overhead = 0.35;
  static const double arcPower = 2.1;

  /// The follow-through runs [followShare] of the bow across the card and
  /// curls [curl] of the half-reach in toward the called card's side.
  static const double followShare = 0.8;
  static const double curl = 0.42;
  static const IkkiuchiSpring home = (decay: 3.6, waves: 3.2);

  /// The smear fades in from [smearFrom] of the arc, [smearRise] times as
  /// fast as the arc.
  static const double smearFrom = 0.35;
  static const double smearRise = 3;

  /// The arm's lag in each phase, ms; its wave, Tobi units.
  static const double lagRest = 20;
  static const double lagDraw = 30;
  static const double lagArc = 46;
  static const double lagFollow = 64;
  static const double lagHome = 115;
  static const double waveArc = 2;
  static const double waveFollow = 3;
  static const double waveHome = 12;

  /// His body: drawn back, then swung.
  static const IkkiuchiBodyPose drawn = (sx: 1.04, sy: 0.94, turn: -0.12, forward: -3, down: 1);
  static const IkkiuchiBodyPose swung = (sx: 0.94, sy: 1.08, turn: 0.16, forward: 5, down: -6);
  static const IkkiuchiSpring bodyHome = (decay: 4, waves: 3);
}

/// The row sweep (払い), a top player's take: the arm comes in low and flat
/// beside the card and brushes along the row, sending it and the cards
/// beside it off the side in a clean line. Phases in ms: the lift, the
/// approach to the row, the sweep along it, the way home.
abstract final class IkkiuchiSweepTuning {
  static const double lift = 90;
  static const double approach = 170;
  static const double sweep = 140;
  static const double back = 320;
  static const double hitStop = 35;

  /// The hit comes this long into the sweep.
  static const double hitInto = 3;

  /// The sweep starts [inside] in from the card's inner edge; the approach
  /// bows in from [bow] of the reach (at most [bowMax]) along the row and
  /// [rise] above it, easing in by [approachPower]; card widths. The lift
  /// draws the hand back by [liftBack] and up by [liftUp] Tobi units.
  static const double inside = 0.14;
  static const double bow = 0.5;
  static const double bowMax = 3.3;
  static const double rise = 0.17;
  static const double approachPower = 1.35;
  static const double liftBack = 6;
  static const double liftUp = 3;

  /// The sweep slows by this power; the way home overshoots by this much.
  static const double sweepPower = 1.6;
  static const double homeOvershoot = 1.1;

  /// The arm's lag in each phase, ms; its bulge, Tobi units.
  static const double lagRest = 20;
  static const double lagLift = 24;
  static const double lagApproach = 30;
  static const double lagSweep = 16;
  static const double lagHome = 28;
  static const double bulge = 5;

  /// His body: low for the approach, leaning along the row.
  static const IkkiuchiBodyPose low = (sx: 1.02, sy: 0.96, turn: -0.03, forward: 0, down: 2);
  static const IkkiuchiBodyPose leaning = (sx: 0.97, sy: 1.04, turn: 0.09, forward: 3, down: -2);
  static const IkkiuchiSpring bodyHome = (decay: 6, waves: 2);
}

/// The 一騎打ち board in play (`IkkiuchiBoardScene`): how long after the
/// player's finger lifts the cards it knocked set off home ([tidyWait]),
/// and their glide there; the glide of every card to its new place and
/// size when the sides change ([relayoutGlide]), as after a 送り札; how
/// long a からふだ's read goes on after its last sound ([karafudaPause]);
/// and how near together two takes of a card count as at the same time
/// ([sameTime]), shorter than any strike's hit stop.
abstract final class IkkiuchiPlayTuning {
  static const Duration tidyWait = Duration(milliseconds: 1000);
  static const Duration tidyGlide = Duration(milliseconds: 250);
  static const Curve tidyCurve = Curves.easeInOutCubic;
  static const Duration relayoutGlide = Duration(milliseconds: 420);
  static const Curve relayoutCurve = Curves.easeInOutCubic;
  static const Duration karafudaPause = Duration(seconds: 5);
  static const Duration sameTime = Duration(microseconds: 16660);
}

/// The reader's pace on a card whose recording is not timed yet
/// (`IkkiuchiCall`): its kimariji's first sound comes [lead] into the call,
/// and each next one [perSound] after the last.
abstract final class IkkiuchiReaderTuning {
  static const Duration lead = Duration(milliseconds: 300);
  static const Duration perSound = Duration(milliseconds: 450);
}

/// A match's run (`IkkiuchiMatchFlow`): the memory time before play when
/// it is given none ([memorise]); the greeting ([greeting]); the 序歌
/// ([yoka]); after each read, how it ended shown ([feedbackIn], held
/// [feedbackHold], [feedbackOut]); a moment once the cards are at rest
/// ([waitBeforeShimonoku]), the 下の句 ([shimonoku]) and a moment after it
/// ([breakAfterShimonoku]); and its からふだ, `karafuda` for every `field`
/// cards on the field. 終了 ends the match once held [endHold]
/// (`IkkiuchiMatchColumn`). The match runs on frame by frame, by
/// [longestStep] at most at once. Tobi lays out his side in his placing
/// time (`IkkiuchiTuning.placingSeconds`), squeezed when it is longer, so
/// that he is done [tobiPlacingLead] before the memory time is up.
abstract final class IkkiuchiMatchTuning {
  static const Duration memorise = Duration(minutes: 15);
  static const Duration tobiPlacingLead = Duration(seconds: 5);
  static const Duration greeting = Duration(milliseconds: 2600);
  static const Duration yoka = Duration(seconds: 5);
  static const Duration feedbackIn = Duration(milliseconds: 380);
  static const Duration feedbackHold = Duration(milliseconds: 1200);
  static const Duration feedbackOut = Duration(milliseconds: 320);
  static Duration get feedback => feedbackIn + feedbackHold + feedbackOut;
  static const Duration waitBeforeShimonoku = Duration(seconds: 1);
  static const Duration shimonoku = Duration(seconds: 7);
  static const Duration breakAfterShimonoku = Duration(seconds: 1);
  static const ({int karafuda, int field}) karafuda = (karafuda: 10, field: 25);
  static const Duration endHold = Duration(milliseconds: 1200);
  static const Duration longestStep = Duration(milliseconds: 250);
}

/// When 一騎打ち's island, the hall, opens (`SideTripUnlocks.hallLock`): once
/// the player knows [known] cards (`Progress.knownCards`), every one.
abstract final class IkkiuchiUnlockTuning {
  static const int known = 100;
}

/// 一騎打ち's custom matches (free play, `ikkiuchi_sheet.dart`): the cards a
/// side, the memory time and Tobi's rating, each from its least to its most
/// by its step, and the setup the first one starts on. The sheet's keys
/// set the cards to one of [perSideKeys], and Tobi's rating to the
/// threshold of one of [ratingClasses] (by the shared class scale's ids).
abstract final class IkkiuchiFreeTuning {
  static const int perSideMin = 1;
  static const int perSideMax = 25;
  static const int perSideStep = 1;
  static const int perSide = 25;
  static const List<int> perSideKeys = [8, 12, 16, 20, 25];
  static const Duration memoriseMin = Duration(minutes: 1);
  static const Duration memoriseMax = Duration(minutes: 15);
  static const Duration memoriseStep = Duration(minutes: 1);
  static const Duration memorise = Duration(minutes: 15);
  static const double ratingMin = 400;
  static const double ratingMax = 3600;
  static const double ratingStep = 50;
  static const double rating = 1600;
  static const List<String> ratingClasses = ['E+', 'D', 'C', 'B', 'A'];
}

/// 一騎打ち's ranked matches and the player's rating (`IkkiuchiRating`).
/// Every ranked match is the same: against Tobi, [perSide] cards a side
/// and [memorise] to learn the field. A win scores 1 and a loss 0, and the
/// expected score against Tobi d points higher is 1 / (1 + 10^(d /
/// [eloScale])). The rating stays inside Tobi's ratings
/// (`IkkiuchiTuning.ratingMin` to `ratingMax`).
///
/// Placement: every new player starts at [start] and plays Tobi at exactly
/// the current estimate, which each win moves up and each loss down by
/// [placementSteps] in turn; the last estimate is the first rating. The
/// steps add up to how far placement reaches (500 to 2700).
///
/// Then each match moves the rating by K × (score − expected score), K
/// being [provisionalK] for the [provisionalMatches] after placement and
/// [establishedK] after them. Tobi plays each at the player's rating plus a
/// normal draw with standard deviation [drawSd], drawn again when more than
/// [drawCutOff] away, so that 80% of matches are within ±300. The draw for
/// a match comes from [drawSeed] and the ranked matches played, so it
/// stays the same until the match is played.
abstract final class IkkiuchiRankedTuning {
  static const int perSide = 25;
  static const Duration memorise = Duration(minutes: 15);
  static const double start = 1600;
  static const List<double> placementSteps = [500, 300, 200, 100];
  static const double provisionalK = 64;
  static const int provisionalMatches = 15;
  static const double establishedK = 32;
  static const double eloScale = 400;
  static const double drawSd = 239;
  static const double drawCutOff = 600;
  static const int drawSeed = 1601;
}

/// The match screen (`IkkiuchiMatchScreen`), ranked or free: the rows a
/// side is laid out in; the seeds a deal is drawn from, and the offset that
/// draws the player's side apart from Tobi's; the system bars hidden while
/// a match is played (a swipe in from an edge shows them for a while); and
/// how long the screen stays once the match is over, for the players'
/// thanks.
abstract final class IkkiuchiScreenTuning {
  static const int rows = 3;
  static const int seeds = 1 << 30;
  static const int playerSeedOffset = 7919;
  static const SystemUiMode bars = SystemUiMode.immersiveSticky;
  static const Duration leaveAfter = Duration(seconds: 3);
}

/// Tobi's arm carrying a card (`IkkiuchiCarry`), as when he sends one: a
/// calm reach to it, the carry, and home, each this many ms. The arm lags
/// [lag] ms along its length and waves [wave] Tobi units at most; each way
/// bows out to his arm's side by [bow] of its length, at most [bowMax] card
/// widths. As he lays out his side each card starts in his hand, and its
/// carry and the way home take at most [layShare] of his time per card.
abstract final class IkkiuchiCarryTuning {
  static const double fetch = 380;
  static const double carry = 620;
  static const double back = 360;
  static const ({double carry, double back}) layShare = (carry: 0.62, back: 0.3);
  static const double lag = 34;
  static const double wave = 1.6;
  static const double bow = 0.22;
  static const double bowMax = 1.6;
}

/// The cards on the board as rigid bodies (`IkkiuchiCards`, Forge2D): no
/// gravity, the tatami's friction as damping. Lengths are card widths (a
/// card's width on the board) and speeds card widths a second, so the
/// cards move alike at any card size.
abstract final class IkkiuchiPhysicsTuning {
  /// One step of the sim in seconds, and how many metres a card's width
  /// is in it.
  static const double step = 1 / 240;
  static const double cardMetres = 0.72;

  /// The tatami slows a sliding card's speed and spin by these shares per
  /// second; the taken card, flying, by [launchDamping].
  static const double damping = 9;
  static const double spinDamping = 7;
  static const double launchDamping = 1.2;

  /// Card on card.
  static const double restitution = 0.32;
  static const double friction = 0.4;
  static const double density = 1;

  /// The taken card leaves at the hand's speed times [hitBoost], within
  /// [hitMin]..[hitMax], its way bent [hitForward] toward the card's far
  /// side; it keeps [hitSpin] of the spin of a blow off its centre, plus a
  /// kick of [hitSpinKick] rad/s, and spins [sweepSpin] rad/s off a sweep.
  /// No card spins faster than [maxSpin] rad/s.
  static const double hitBoost = 1.2;
  static const double hitMin = 50;
  static const double hitMax = 100;
  static const double hitForward = 0.15;
  static const double hitSpin = 0.32;
  static const double hitSpinKick = 6;
  static const double sweepSpin = 1.2;
  static const double maxSpin = 26;

  /// The taken card lands, and fades from the field, once it slows under
  /// [landSpeed]; it fades over [fadeMs].
  static const double landSpeed = 3.3;
  static const double fadeMs = 220;

  /// The fist pushes the cards it meets as if never faster than [pushMax],
  /// bouncing them [fistRestitution]; never toward the side without the
  /// called card.
  static const double pushMax = 50;
  static const double fistRestitution = 0.3;

  /// A card this far past the board's edge is gone.
  static const double offBoard = 6.7;

  /// The player's finger pushes the cards as a circle of this radius.
  static const double finger = 0.3;
}

/// The developer's 一騎打ち pages (`IkkiuchiCurvesPage`,
/// `IkkiuchiLayoutPage`, `IkkiuchiStrikesPage`, `IkkiuchiDebugGame`): their
/// rating slider, the graphs' rating ticks and sampling step, the standard
/// deviations the curves page gives each value's range at, the bands its
/// graphs of the ranked draw and his form mark, the layout page's choice of
/// cards a side and the seeds it starts from, the full fields the strikes
/// page and the debug game deal, the strikes page's slow motion speeds and
/// its reset once a strike is over, and the debug game's system bars.
abstract final class IkkiuchiToolsTuning {
  static const double ratingStart = 1600;
  static const double ratingStep = 50;
  static const double ratingTick = 600;
  static const double curveStep = 10;
  static const List<int> sigmas = [1, 2];

  /// The curves page's graphs of a draw added to a rating mark this far
  /// either side of it, with the share of draws inside: the ranked draw's
  /// ±[rankedBand], which its standard deviation is set for, and his
  /// form's ±[formBand]. A share held at an end of the ratings shows from
  /// [heldShown] up.
  static const double rankedBand = 300;
  static const double formBand = 100;
  static const double heldShown = 0.001;
  static const List<int> perSideChoices = [8, 12, 16, 20, 25];
  static const int perSideStart = 25;

  /// The curves page's "any in a game" lines are for games with this many
  /// cards on his side, dealt from all 100.
  static const int gamePerSide = 25;

  /// The layout page counts the starting layouts, one per seed, with a row
  /// of at least each of [wideRows] cards.
  static const List<int> wideRows = [12, 14];
  static const int seeds = 1000;

  /// Added to a deal's seed for the player's side, so its rating and layout
  /// are drawn apart from Tobi's; and for Tobi's rating where a page draws
  /// it at random.
  static const int playerSeedOffset = 7919;
  static const int tobiSeedOffset = 104729;

  /// A full field's cards a side and rows.
  static const int dealPerSide = 25;
  static const int dealRows = 3;

  /// The debug game's buttons for a new deal: the cards a side each deals.
  /// Its rating slider starts at [ratingStart], and one [ratingStep] above
  /// [IkkiuchiTuning.ratingMin] turns Tobi off.
  static const List<int> gameCounts = [5, 10, 15, 20, 25];

  /// The strikes page: its slow motion speeds, and how long after a strike
  /// ends, all cards still, the board resets.
  static const List<double> slowMotion = [1, 0.5, 0.25, 0.1];
  static const Duration autoReset = Duration(seconds: 3);

  /// The debug game: the system bars hidden while it is open (a swipe in
  /// from an edge shows them for a while).
  static const SystemUiMode gameBars = SystemUiMode.immersiveSticky;
}
