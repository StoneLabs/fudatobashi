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

  /// His form for a match: a normal draw with this standard deviation added
  /// to his rating before every curve is read.
  static const double formSd = 200;
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

/// Tobi's body in a strike, squashed and stretched about his feet: its
/// width and height as shares of his own, a turn toward the card (radians),
/// and a shift toward the card and down, in Tobi units (his art's units).
typedef IkkiuchiBodyPose = ({double sx, double sy, double turn, double forward, double down});

/// A spring that dies out: it decays by [decay] over its time and swings
/// [waves] half waves.
typedef IkkiuchiSpring = ({double decay, double waves});

/// Tobi's arm in a strike (`IkkiuchiStrike`): how the hand's path bends the
/// arm, when the fist touches, and how the follow-through and the way home
/// go. Lengths are dp unless they say Tobi units (his art's units, k dp
/// each); times are the move's own ms unless they say screen ms.
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

  /// The fist's radius in Tobi units, and how near its centre a card counts
  /// as touched, in fist radii.
  static const double fist = 4.6;
  static const double touch = 1.2;

  /// The point between his feet his body squashes and turns about, Tobi units.
  static const ({double x, double y}) feet = (x: 40, y: 93);

  /// A card more than [sideDeadZone] left or right of his middle is struck
  /// with the arm on that side; a nearer one by its id. He leans toward a
  /// card more than [leanDeadZone] from his middle, else toward his arm.
  static const double sideDeadZone = 4;
  static const double leanDeadZone = 12;

  /// The hand keeps [screenMargin] inside the board's edges, the smear's
  /// arc [arcMargin]; the row sweep stops [rowExitInset] short of the edge.
  static const double screenMargin = 16;
  static const double arcMargin = 10;
  static const double rowExitInset = 10;

  /// How far past its resting place the hand may fly on its way home.
  static const double overshootCap = 46;

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
  /// the side without the called card. A follow-through cut short takes
  /// less time, by the square root of the share left, at least [brakeMin].
  /// The path is searched in [brakeSamples] steps, then halved
  /// [brakeRefine] times.
  static const double clearance = 8;
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

  /// The swing's curve bows out by [bow] of the reach, at least [bowMin],
  /// from [bowAt] along the way to the card; it eases in by [outPower].
  static const double bowAt = 0.45;
  static const double bow = 0.42;
  static const double bowMin = 70;
  static const double outPower = 1.7;

  /// The follow-through runs on [followShare] of the reach, within
  /// [followMin]..[followMax].
  static const double followShare = 0.16;
  static const double followMin = 30;
  static const double followMax = 80;
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
  /// the hit comes [hitInto] into the sweep. Tobi units.
  static const double landOut = 18;
  static const double landBack = 4;
  static const double sweepOut = 34;
  static const double sweepOn = 8;
  static const double hitInto = 18;

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
  /// it bows out by [bow] of the reach, at least [bowMin] Tobi units and
  /// [edgeRoom] dp short of the board's edge. It starts [overhead] radians
  /// past straight back and eases in by [arcPower].
  static const double bow = 0.55;
  static const double bowMin = 24;
  static const double edgeRoom = 14;
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

  /// The sweep starts [inside] dp in from the card's inner edge; the
  /// approach bows in from [bow] of the reach (at most [bowMax]) along the
  /// row and [rise] dp above it, easing in by [approachPower]. The lift
  /// draws the hand back by [liftBack] and up by [liftUp] Tobi units.
  static const double inside = 5;
  static const double bow = 0.5;
  static const double bowMax = 120;
  static const double rise = 6;
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

/// The cards on the board as rigid bodies (`IkkiuchiCards`, Forge2D): no
/// gravity, the tatami's friction as damping. Speeds are dp/s.
abstract final class IkkiuchiPhysicsTuning {
  /// One step of the sim in seconds, and how many dp make a metre in it.
  static const double step = 1 / 240;
  static const double dpPerMetre = 50;

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
  static const double hitMin = 1800;
  static const double hitMax = 3600;
  static const double hitForward = 0.15;
  static const double hitSpin = 0.32;
  static const double hitSpinKick = 6;
  static const double sweepSpin = 1.2;
  static const double maxSpin = 26;

  /// The taken card lands, and fades from the field, once it slows under
  /// [landSpeed]; it fades over [fadeMs].
  static const double landSpeed = 120;
  static const double fadeMs = 220;

  /// The fist pushes the cards it meets as if never faster than [pushMax],
  /// bouncing them [fistRestitution]; never toward the side without the
  /// called card.
  static const double pushMax = 1800;
  static const double fistRestitution = 0.3;

  /// A card this far past the board's edge is gone.
  static const double offBoard = 240;
}

/// The developer's 一騎打ち pages (`IkkiuchiCurvesPage`,
/// `IkkiuchiLayoutPage`, `IkkiuchiStrikesPage`): their rating slider, the
/// graphs' rating ticks and sampling step, the standard deviations the
/// curves page gives each value's range at, the layout page's choice of
/// cards a side and the seeds it starts from, and the strikes page's slow
/// motion speeds and its reset once a strike is over.
abstract final class IkkiuchiToolsTuning {
  static const double ratingStart = 1600;
  static const double ratingStep = 50;
  static const double ratingTick = 600;
  static const double curveStep = 10;
  static const List<int> sigmas = [1, 2];
  static const List<int> perSideChoices = [8, 12, 16, 20, 25];
  static const int perSideStart = 25;

  /// The curves page's "any in a game" lines are for games with this many
  /// cards on his side, dealt from all 100.
  static const int gamePerSide = 25;

  /// The layout page counts the starting layouts, one per seed, with a row
  /// of at least each of [wideRows] cards.
  static const List<int> wideRows = [12, 14];
  static const int seeds = 1000;

  /// The strikes page: its cards a side and rows, its slow motion speeds,
  /// and how long after a strike ends, all cards still, the board resets.
  static const int strikesPerSide = 25;
  static const int strikesRows = 3;
  static const List<double> slowMotion = [1, 0.5, 0.25, 0.1];
  static const Duration autoReset = Duration(seconds: 3);
}
