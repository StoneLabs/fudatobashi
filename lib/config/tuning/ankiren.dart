part of '../config.dart';

/// 暗記練 (the memorisation side trip): its levels and custom setups
/// (`AnkirenSetup`), how a field is dealt (`AnkirenDealer`), and a game's
/// prompts and points (`AnkirenGame`, `AnkirenScore`).
abstract final class AnkirenTuning {
  /// Free play's levels, 0 first: cards per side and memorise time. Level 0
  /// is for beginners: its cards lie spread out in the open middle (see
  /// [AnkirenLevel.allInMiddle]). The field grows to a real match's 25 a side
  /// at level 8, and the last levels cut the memorise time from 15 minutes,
  /// a real match's, to 5. They open one at a time (see `AnkirenLadder`).
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
    AnkirenLevel(25, Duration(minutes: 10)),
    AnkirenLevel(25, Duration(minutes: 5)),
  ];

  /// Ranked games all play a real match's field: [rankedPerSide] cards a
  /// side and [rankedMemorise] to memorise them.
  static const int rankedPerSide = 25;
  static const Duration rankedMemorise = Duration(minutes: 15);

  /// A free-play level is cleared by playing it to the end with fewer than
  /// [strikesOut] strikes: each wrong tap is one, and so is each "don't
  /// know". Every level plays to the end. Clearing a level opens the next; clearing [rankedAfterLevel] opens ranked (in
  /// all-known mode), and [customAfterLevel] the custom setups.
  static const int strikesOut = 3;
  static const int rankedAfterLevel = 4;
  static const int customAfterLevel = 8;

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
  static const int speedMax = 50;

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

  /// The speed bonus's curve over the response time t: a logistic curve over
  /// ln t, centred on [speedMidpoint] and as steep as [speedSteepness],
  /// stretched to be exactly [speedMax] at [speedFull] and 0 at [speedNone].
  /// Fitted to [speedTargets]: it gives 50, 44, 36, 28, 8.
  static const Duration speedFull = Duration(milliseconds: 100);
  static const Duration speedNone = Duration(seconds: 5);
  static const Duration speedMidpoint = Duration(milliseconds: 1650);
  static const double speedSteepness = 1.1;

  /// The response times (ms) the curve was fitted to, and their share of
  /// [speedMax].
  static const Map<int, double> speedTargets = {100: 1, 300: 0.9, 600: 0.75, 1000: 0.5, 3000: 0.2};
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

  /// The total-points graph: the time-left slider's start and step, and the
  /// gap between the x axis's labels.
  static const Duration timeLeftStart = Duration(minutes: 5);

  /// What a card not found with the first tap is assumed to earn, flat: a
  /// first tap next to the card, roughly.
  static const int wrongCardPoints = 60;

  /// The graph's fixed top, in points.
  static const int graphYMax = 12000;
  static const Duration timeLeftStep = Duration(seconds: 10);
  static const Duration responseTick = Duration(seconds: 1);
  static const int yDivisions = 4;

  static const List<int> simulationGames = [100, 1000, 5000];
  static const int simulationGamesStart = 1000;

  /// Seeds tried when looking for a game with middle cards.
  static const int seedSearchLimit = 20000;

  /// The developer tools' ranked class table also shows each class for a
  /// player ready at [classTableReadyAt] of ranked's memorise time.
  static const Duration classTableReadyAt = Duration(minutes: 10);
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
  /// The rating's floor, where the way to the first class starts before
  /// any ranked game.
  static const double start = 400;

  /// A ranked game's performance is [slope] × (F − [zero]), F its final
  /// score (card points times the early-finish multiplier). Two games with
  /// no early finish anchor it: all 50 cards right with the first tap at
  /// 0.5 s each performs at the A class line, and 25 right with the first
  /// tap at 2.5 s each, nothing for the other 25, at the F- line.
  static const double slope = 0.48319;
  static const double zero = 1133.5;

  /// The rating after each of the first [placementGames] ranked games is
  /// the mean of their performances; each later game moves it
  /// [establishedK] of the way to its own.
  static const int placementGames = 3;
  static const double establishedK = 0.35;
}

/// Experience from a 暗記練 game (`AnkirenXp`), on [XpTuning]'s scale. Most of
/// a game is memorising, about 10–18 s a card at every level, so its XP is
/// paid per card, by what its taps earned: a game finding about 70% of its
/// cards with the first tap earns about what main runs earn over the same
/// time (about 5½ XP a second; a level 2 game of about 2 minutes, some
/// 800). Derived from the recorded games, like [XpTuning].
abstract final class AnkirenXpTuning {
  /// A card found with the first tap at level 0, and what each level above
  /// adds. Any other card earns the same share of this as of its points
  /// (`AnkirenScore.share`).
  static const int firstTap = 70;
  static const int firstTapPerLevel = 5;

  /// A ranked game's cards earn what they would at [rankedLevel], the level
  /// with a real match's field.
  static const int rankedLevel = 8;

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
