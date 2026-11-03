part of '../config.dart';

/// 一騎打ち (a full match against Tobi): every value Tobi plays with comes
/// from his rating through these curves (`IkkiuchiTobi`). Each curve is
/// anchor points (rating, value), joined by a smooth curve that passes
/// through each point and never overshoots, times smoothed on a log scale,
/// and held flat past both ends (`IkkiuchiCurve`).
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
  static const takeMs = IkkiuchiCurve.log([
    (0, 3400), (400, 2900), (800, 2350), (1200, 1800), (1600, 1300), (2000, 880),
    (2400, 600), (2800, 400), (3200, 260), (3400, 215), (3600, 180),
  ]);

  /// The card-to-card spread of [takeMs]: the standard deviation of its
  /// natural log (a log-normal draw). A strong Tobi is steadier.
  static const takeSpread = IkkiuchiCurve([(0, 0.55), (1200, 0.5), (2400, 0.42), (3600, 0.35)]);

  /// The chance per field card read that he doesn't know its spot at once
  /// and has to look for it (a blank).
  static const blankChance = IkkiuchiCurve([
    (0, 0.97), (400, 0.95), (600, 0.84), (800, 0.71), (1200, 0.48), (1600, 0.29),
    (2000, 0.13), (2400, 0.04), (2800, 0.015), (3200, 0.006), (3400, 0.004), (3600, 0.003),
  ]);

  /// What a blank adds to [takeMs]: a log-normal draw with this median, ms,
  /// and [searchSpread].
  static const searchMs = IkkiuchiCurve.log([(0, 4500), (1600, 3000), (3600, 1500)]);
  static const double searchSpread = 0.5;

  /// The chance per call that he goes for a look-alike of the called card
  /// first, when one is on the field: a 友札, on which he goes one kana
  /// early, or a card whose torifuda looks alike.
  static const lookAlikePull = IkkiuchiCurve([
    (0, 0.3), (800, 0.22), (1600, 0.14), (2400, 0.07), (2800, 0.035), (3600, 0.008),
  ]);

  /// On a からふだ with no look-alike on the field, his chance to touch a
  /// card anyway, as a share of [lookAlikePull].
  static const double strayShare = 0.15;

  /// After touching a wrong card, he goes for the right one this much later.
  static const Duration correction = Duration(milliseconds: 350);

  /// His arm's swing at the average distance, ms: part of [takeMs]. A card
  /// at distance d takes swing × (1 + [armDistanceWeight] × (d / mean − 1)).
  static const armMs = IkkiuchiCurve.log([(0, 330), (1600, 220), (2800, 150), (3600, 100)]);
  static const double armDistanceWeight = 0.5;

  /// The take's animation, from the start of his reach to the hit, ms. No
  /// hit's reach is ever shorter than [reachFloorMs], even when a quick
  /// take squeezes it.
  static const reachMs = IkkiuchiCurve([(0, 1000), (3600, 150)]);
  static const double reachFloorMs = 130;

  /// The chance a 送り札 he sends splits a look-alike pair (its look-alike
  /// stays on his side); otherwise he sends a random card.
  static const smartSend = IkkiuchiCurve([(0, 0), (800, 0), (2000, 0.5), (2800, 0.85), (3600, 0.95)]);

  /// How long he takes to lay out his side before the match, while the
  /// player lays out theirs, in seconds.
  static const placingSeconds = IkkiuchiCurve.log([
    (0, 100), (1000, 78), (1800, 55), (2400, 39), (2786, 30), (3600, 24),
  ]);

  /// His arm move for each card, drawn at random: the clean row sweep (払い)
  /// takes [sweepShare], and the rest is split between the three wild moves
  /// by [wildMoves]. A move changes only the look and how the cards fly:
  /// it is picked after his time is set, its animation is fitted into his
  /// reach, and the cards it knocks never count as touches.
  static const sweepShare = IkkiuchiCurve([
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
  static const soundGrouping = IkkiuchiCurve([
    (0, 1), (1200, 0.31), (2000, 0.1), (2600, 0.034), (3000, 0.016), (3600, 0.0047),
  ]);
  static const tomofudaGrouping = IkkiuchiCurve([
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

/// The developer's 一騎打ち pages (`IkkiuchiCurvesPage`,
/// `IkkiuchiLayoutPage`): their rating slider, the graphs' rating ticks and
/// sampling step, the standard deviations the curves page gives each
/// value's range at, and the layout page's choice of cards a side and the
/// seeds it starts from.
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
}
