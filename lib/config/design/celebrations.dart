part of '../design.dart';

/// "A new card appears" (spec phone 5, `NewCardOverlay`).
abstract final class NewCardLayout {
  static const focus = BurstSpec(
      box: Size(390, 844), center: Offset(195, 350), count: 220, innerMin: 190, innerMax: 250, width: 4.5, seed: 8,
      color: Palette.paper);

  /// The flash behind the card: a radial glow of [glowSize] at [focus]'s
  /// centre.
  static const Alignment glowAt = Alignment(0, -0.17);
  static const double glowSize = 560;
  static const List<Color> glowColors = [Color(0xFFFFF6C2), Color(0xE6FFD83A), Color(0x00FFD83A)];
  static const List<double> glowStops = [0.3, 0.46, 1];

  static const double topGap = 8;
  static const double shoutHeight = 96;
  static const shout = ShoutSpec(spikes: 26, outer: 12, inner: 5, roundness: 3, seed: 21);
  static const double shoutFont = 25;
  static const EdgeInsets shoutPadding = EdgeInsets.symmetric(horizontal: 34, vertical: 22);
  static const double bandGap = 8;
  static const double bandIndent = 8;
  static const double bandFont = 13;
  static const double bandTracking = 0.24;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(10, 3, 10, 4);

  /// ババーン!! at the band's right, raised [bangLift] over the shout's
  /// lower right, at least [bangGap] clear of the band.
  static const String bang = 'ババーン!!';
  static const double bangLift = 24;
  static const double bangGap = 8;
  static const double bangFont = 33;
  static const double bangTurnDeg = -7;
  static const int bangSeed = 7;

  /// The rumble lettering either side of the card, dropped this share of
  /// the card's height below its top.
  static const String rumbleLeft = 'ゴゴゴゴ';
  static const String rumbleRight = 'ドドドド';
  static const int rumbleLeftSeed = 2;
  static const int rumbleRightSeed = 6;
  static const double rumbleFont = 40;
  static const double rumbleOutline = 7;
  static const double rumbleLeftDrop = 0.13;
  static const double rumbleRightDrop = 0.16;
  static const double sfxOutline = 7;

  /// The card takes up to this share of the width, less if the height runs
  /// short, keeping [cardMargin] above and below.
  static const double cardWidthShare = 0.66;
  static const double cardMargin = 12;
  static const BoxShadow cardShadow =
      BoxShadow(color: Color(0x99000000), blurRadius: 30, spreadRadius: -14, offset: Offset(0, 18));

  /// The info panel's top-left corner drops this much (a tilted top edge).
  static const Offset infoCut = Offset(0, 12);
  static const EdgeInsets infoPadding = EdgeInsets.fromLTRB(16, 16, 14, 12);
  static const double kimarijiFont = 33;
  static const double kimarijiOutline = 7;

  /// The kana under the romaji, in romaji mode.
  static const double kimarijiKanaFont = 15;
  static const double metaGap = 8;
  static const double metaFont = 14;
  static const double tipGap = 7;
  static const double tipFont = 13;
  static const EdgeInsets tipKanaPadding = EdgeInsets.symmetric(horizontal: 3);
  static const double tipKanaBorder = 1.5;

  /// Tobi, shocked, and his !? peek over the info panel's top right.
  static const Placement tobi = Placement(right: -17, top: -60, size: Size(66, 80));
  static const Placement exclaim = Placement(right: 26, top: -82, size: Size(44, 40));
  static const String exclaimText = '!?';
  static const double exclaimFont = 28;
  static const double exclaimTurnDeg = 10;

  static const double actionsGap = 12;
  static const double actionHeight = 62;
  static const int learnFlex = 2;
  static const int acceptFlex = 3;
  static const double learnFont = 13.5;
  static const double acceptFont = 19;
  static const double acceptSubFont = 13;
}

/// "Rank up" (昇級!!, `RankUpOverlay`): spec phone 9's two-page spread
/// crossing the gutter, the old class struck off on the left page and the
/// new one stamped on the right, then the rating and the next class.
abstract final class RankUpLayout {
  /// The left page's speed lines stream in from the gutter.
  static const leftSpeed = SpeedLinesSpec(count: 44, seed: 12, fromEdge: true);

  /// The right page: a sun glow under boiling focus lines, with a pink tone
  /// fading in toward the bottom.
  static const Alignment rightGlowAt = Alignment(0, 0.08);
  static const List<Color> rightGlowColors = [Color(0xFFFFFBE3), Color(0xFFFFE77A), Palette.sun];
  static const List<double> rightGlowStops = [0, 0.5, 1];
  static const rightFocus = BurstSpec(
      box: Size(195, 844), center: Offset(97, 450), count: 120, innerMin: 90, innerMax: 120, width: 4, seed: 14);
  static const double rightToneAngle = 180;
  static const List<double> rightToneStops = [0.45, 0.9];

  /// The shadow in the gutter between the two pages.
  static const double gutterWidth = 52;
  static const List<Color> gutterColors = [
    Color(0x00000000),
    Color(0x29000000),
    Color(0x47000000),
    Color(0x29000000),
    Color(0x00000000),
  ];
  static const List<double> gutterStops = [0, 0.46, 0.5, 0.54, 1];

  static const double topGap = 8;
  static const String title = '昇級!!';
  static const double titleFont = 104;

  /// Thin enough to keep the counters of 級 open.
  static const double titleOutline = 9;
  static const double bandGap = 6;
  static const double bandInset = 40;
  static const double bandFont = 20;
  static const double bandTracking = 0.3;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 7, 8, 8);
  static const double bandTurnDeg = -2.5;

  /// BEFORE / NOW above each page's class.
  static const double pageLabelFont = 12;
  static const double pageLabelTracking = 0.2;
  static const EdgeInsets pageLabelPadding = EdgeInsets.fromLTRB(5, 1, 5, 2);
  static const double pageLabelGap = 4;

  /// The old class, struck off with a pink bar reaching past both ends and
  /// stamped CLEAR at its lower right.
  static const double oldFont = 34;
  static const double oldSuffixFont = 18;
  static const EdgeInsets oldPadding = EdgeInsets.fromLTRB(8, 4, 8, 6);
  static const double strikeHeight = 6;
  static const double strikeBorder = 2;
  static const double strikeTurnDeg = -8;
  static const double strikeOverhangLeft = 6;
  static const double strikeOverhangRight = 10;
  static const Offset clearOffset = Offset(22, 18);

  /// The new class stamp, in its rung colour, with focus lines bursting
  /// out from behind it as it lands.
  static const double newFont = 50;
  static const double newSuffixFont = 26;
  static const EdgeInsets newPadding = EdgeInsets.fromLTRB(14, 8, 14, 10);
  static const double newBorder = 3.5;
  static const double newTurnDeg = -4;
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(140, 140), count: 44, innerMin: 70, innerMax: 92, width: 5, seed: 23);
  static const Size impactSize = Size(280, 280);
  static const double impactFromScale = 0.6;
  static const double impactToScale = 1.35;

  static const String sfx = 'ドドン!!';
  static const double sfxFont = 36;
  static const int sfxSeed = 3;
  static const double sfxTurnDeg = 9;

  static const Size tobi = Size(76, 92);
  static const double tobiGap = 8;

  /// The rating box: the old rating, the new one counting up, the gain.
  static const double rateFont = 20;
  static const double rateBorder = 3;
  static const EdgeInsets ratePadding = EdgeInsets.fromLTRB(14, 7, 14, 8);
  static const double rateGap = 10;
  static const double gainFont = 13;
  static const double gainBorder = 2;
  static const EdgeInsets gainPadding = EdgeInsets.fromLTRB(6, 1, 6, 2);

  /// The next class: its badge, its 100-card time and how far is left.
  static const Offset nextCut = Offset(0, 10);
  static const EdgeInsets nextPadding = EdgeInsets.fromLTRB(12, 16, 12, 10);
  static const double nextGap = 12;
  static const double nextTagFont = 12;
  static const double nextBadgeFont = 30;
  static const double nextBadgeSuffixFont = 16;
  static const double nextTargetFont = 16;
  static const double nextNoteFont = 12.5;
  static const double barHeight = 12;
  static const double barGap = 6;

  static const double sectionGap = 12;
  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

/// "Island complete" (制覇!!, `IslandCompleteOverlay`).
abstract final class IslandCompleteLayout {
  static const Color sea = Color(0xFF3FA5FF);
  static const int seaSeed = 21;
  static const focus = BurstSpec(
      box: Size(390, 844), center: Offset(195, 402), count: 200, innerMin: 150, innerMax: 210, width: 4, seed: 19,
      color: Palette.paper);
  static const double focusOpacity = 0.9;
  static const Alignment glowAt = Alignment(0, -0.05);
  static const double glowSize = 440;
  static const List<Color> glowColors = [Color(0xFFFFF7CC), Color(0xF2FFD83A), Color(0x00FFD83A)];
  static const List<double> glowStops = [0.2, 0.46, 1];

  /// Confetti rains through the top of the page, down to this share of it.
  static const double confettiShare = 0.66;

  static const double topGap = 4;
  static const String title = '制覇!!';
  static const double titleFont = 96;

  /// Thin enough to keep the dense strokes of 覇 apart.
  static const double titleOutline = 8;
  static const double bandInset = 12;
  static const double bandFont = 19;
  static const double bandTracking = 0.14;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 7, 8, 8);
  static const double bandTurnDeg = -2.5;
  static const double subGap = 10;
  static const double subFont = 15;
  static const double subBorder = 2.5;
  static const EdgeInsets subPadding = EdgeInsets.fromLTRB(12, 4, 12, 5);

  /// The island takes up to this share of the width, in a view of its
  /// bounds grown by [islandPad] map units.
  static const double islandShare = 0.64;
  static const double islandPad = 10;
  static const String sfx = 'ドドーン!!';
  static const double sfxFont = 34;
  static const double sfxTurnDeg = -10;
  static const int sfxSeed = 12;
  static const Offset sfxAt = Offset(-2, 6);
  static const Placement tobi = Placement(right: 6, top: 38, size: Size(82, 98));

  static const Offset nextCut = Offset(0, 10);
  static const EdgeInsets nextPadding = EdgeInsets.fromLTRB(8, 14, 12, 10);
  static const Size nextArt = Size(104, 92);
  static const double nextGap = 12;
  static const double nextBoxBorder = 2;
  static const EdgeInsets nextBoxPadding = EdgeInsets.fromLTRB(9, 7, 9, 7);
  static const double nextTagFont = 12;
  static const double nextNameFont = 30;
  static const double nextNoteFont = 12.5;

  static const double lineGap = 12;
  static const double lineFont = 14;
  static const double lineBorder = 2;
  static const EdgeInsets linePadding = EdgeInsets.fromLTRB(10, 3, 10, 4);
  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

/// The placement page (ランク決定!!, `placement_overlay.dart`), on the
/// rank-up page's timing (`RankUpMotion`) and most of its sizes: one page
/// in a sun glow under boiling focus lines, a pink tone fading in toward
/// the bottom.
abstract final class PlacementLayout {
  static const String title = 'ランク決定!!';
  static const double titleFont = 72;
  static const double titleOutline = 9;
  static const Alignment glowAt = Alignment(0, -0.1);
  static const List<Color> glowColors = RankUpLayout.rightGlowColors;
  static const List<double> glowStops = RankUpLayout.rightGlowStops;
  static const double toneAngle = 180;
  static const List<double> toneStops = [0.55, 0.95];
  static const focus = BurstSpec(
      box: Size(390, 844), center: Offset(195, 380), count: 150, innerMin: 120, innerMax: 150, width: 4, seed: 41);
  static const double classFont = 60;
  static const double classSuffixFont = 30;
  static const Size tobi = Size(84, 102);
  static const double rateLabelFont = 13;
  static const double rateLabelTracking = 0.14;
}

/// "A new card appears" (spec phone 5): entrance timeline and the flick that
/// sends the card off when the player accepts it.
abstract final class NewCardMotion {
  static const lines = EntranceSpec(Entrances.flin, duration: Duration(milliseconds: 550), curve: Entrances.settle);
  static const flash = EntranceSpec(Entrances.flash,
      duration: Duration(milliseconds: 700), delay: Duration(milliseconds: 120), curve: Curves.easeOut);
  static const shout = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 50), curve: Entrances.springy);
  /// The card flies in from off-screen at the lower left, along the path
  /// the accept flick carries on (out at the upper right), with a speed
  /// streak trailing it that fades as it lands at [landAt].
  static const card = EntranceSpec(EntranceFrom(offset: Offset(-470, 620), turnDeg: -32, scale: 0.7, opaqueAt: 0.15),
      duration: _flyInLength, delay: _flyInDelay, curve: Entrances.lift);
  static const _flyInLength = Duration(milliseconds: 600);
  static const _flyInDelay = Duration(milliseconds: 200);

  /// The streak runs on the card's clock, fully drawn for the first
  /// [flyStreakHold] of it, then fading out as the card settles. Sun, to
  /// stand out from the white focus lines.
  static const flyStreakFade =
      EntranceSpec(Entrances.custom, duration: _flyInLength, delay: _flyInDelay, curve: Curves.linear);
  static const double flyStreakHold = 0.5;
  static const flyStreak = SpeedLinesSpec(count: 26, seed: 8, color: Palette.sun);

  /// When the card first reaches its spot (the lift curve arrives about
  /// half-way through, then overshoots and settles).
  static const landAt = Duration(milliseconds: 520);
  static const jolt = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 260), delay: landAt, curve: Curves.linear);
  static const double joltReach = 5;
  static const int joltSteps = 7;
  static const int joltSeed = 9;
  static const info = EntranceSpec(Entrances.slideL,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 600), curve: Entrances.glide);
  static const sfx = EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 400), delay: landAt, curve: Entrances.bouncy);

  /// Tobi leaps up in shock as the card lands, then keeps trembling.
  static const tobi = EntranceSpec(EntranceFrom(offset: Offset(0, 30), scale: 0.5, turnDeg: 12),
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 560), curve: Entrances.bouncy);
  static const double tobiTremble = 1.3;
  static const tobiTrembleStep = Duration(milliseconds: 70);
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 800), curve: Entrances.springy);

  /// Background once the entrance is over: the glow and focus lines throb.
  static const throbPeriod = Duration(milliseconds: 1600);
  static const double glowThrob = 0.07;
  static const double linesThrob = 0.025;

  /// The focus lines boil: redrawn every [linesStep] from [linesFrames]
  /// drawings.
  static const int linesFrames = 3;
  static const linesStep = Duration(milliseconds: 90);

  /// ゴゴゴゴ / ドドドド rumble: a jolt of up to [rumbleReach] px every
  /// [rumbleStep].
  static const double rumbleReach = 2.2;
  static const rumbleStep = Duration(milliseconds: 50);

  /// The card sways by up to [swayDeg] and bobs by up to [swayLift] px.
  static const double swayDeg = 1.2;
  static const double swayLift = 3;
  static const swayPeriod = Duration(milliseconds: 3200);

  /// The accept flick (the play loop's card flick): the card flies to
  /// [flickTo] (spec px) with [flickTurnDeg] of spin while the SFX pops and a
  /// speed streak flashes behind it; the next page follows at [flickLength].
  static const flickLength = Duration(milliseconds: 250);
  static const flyLength = Duration(milliseconds: 230);
  static const flyCurve = Cubic(0.3, 0.55, 0.35, 1);
  static const Offset flickTo = Offset(470, -620);
  static const double flickTurnDeg = 30;
  static const streakLength = Duration(milliseconds: 420);

  /// The streak peaks at this fraction of [streakLength], then fades.
  static const double streakPeak = 0.18;
  static const streak = SpeedLinesSpec(count: 26, seed: 5, color: Palette.paper);
  static const Size streakBox = Size(640, 230);
  static const double streakBack = 150;
  static const String flickWord = 'バシッ!';
  static const double flickWordFont = 54;
  static const double flickWordTurnDeg = -9;
}

/// "Rank up" (昇級!!): the pages slide together, the old class is struck
/// off, the new one slams down with a jolt at [impactAt], then the rating
/// counts up and the next class's bar fills.
abstract final class RankUpMotion {
  static const pages = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 500), curve: Entrances.glide);
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 250), curve: Entrances.springy);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 500));
  static const before = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 400), curve: Entrances.glide);
  static const strike = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 220), delay: Duration(milliseconds: 800), curve: Curves.easeOut);
  static const clear = EntranceSpec(Entrances.thump,
      duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 950), curve: Entrances.springy);
  static const now =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 850));
  static const stamp = EntranceSpec(Entrances.stamp,
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 1000), curve: Entrances.springy);

  /// When the stamp first lands (the springy curve reaches rest about a
  /// quarter of the way through).
  static const impactAt = Duration(milliseconds: 1110);
  static const jolt = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 320), delay: impactAt, curve: Curves.linear);
  static const double joltReach = 7;
  static const int joltSteps = 9;
  static const int joltSeed = 31;
  static const burst = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 450), delay: impactAt, curve: Curves.easeOut);
  static const sfx = EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 400), delay: impactAt, curve: Entrances.bouncy);
  static const tobi = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1160), curve: Entrances.bouncy);

  static const rate = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 1250), curve: Entrances.springy);
  static const count = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 900), delay: Duration(milliseconds: 1350), curve: Curves.easeOutCubic);
  static const gain = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 2250), curve: Entrances.bouncy);
  static const next = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 1600), curve: Entrances.glide);
  static const fill = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 700), delay: Duration(milliseconds: 2000), curve: Curves.easeOutCubic);
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1900), curve: Entrances.springy);

  static Duration get length => fill.end;

  /// Afterwards Tobi keeps hopping and the right page's focus lines boil.
  static const double hopHeight = 12;
  static const hopPeriod = Duration(milliseconds: 1100);
  static const double hopAirShare = 0.4;
}

/// "Island complete" (制覇!!): entrance timeline and the next island rising.
abstract final class IslandCompleteMotion {
  static const lines = NewCardMotion.lines;
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 150), curve: Entrances.springy);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 450));
  static const sub =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 550));
  static const island = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 100), curve: Entrances.swell);
  static const sfx = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 400), curve: Entrances.bouncy);
  static const tobi = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 700), curve: Entrances.bouncy);
  static const next = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 800), curve: Entrances.glide);
  static const rising = EntranceSpec(Entrances.isrise,
      duration: Duration(milliseconds: 1100), delay: Duration(milliseconds: 1000), curve: Entrances.swell);
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1100), curve: Entrances.springy);
}

/// The XP page (経験値!!, `XpOverlay`): violet, lit from behind the counter.
abstract final class XpLayout {
  static const Color color = Palette.violet;
  static const List<Color> skyColors = [Color(0xFFB98AD6), Palette.violet, Color(0xFF7A3FA3)];
  static const List<double> skyStops = [0, 0.55, 1];
  static const Alignment skyCenter = Alignment(0, -0.45);
  static const double toneAngle = 180;
  static const List<double> toneStops = [0.55, 1];
  static const focus = BurstSpec(
      box: Size(390, 844), center: Offset(195, 215), count: 150, innerMin: 110, innerMax: 150, width: 4, seed: 41,
      color: Palette.paper);
  static const double focusOpacity = 0.85;
  static const Alignment glowAt = Alignment(0, -0.5);
  static const double glowSize = 420;
  static const List<Color> glowColors = [Color(0xFFFFF7CC), Color(0xE6FFD83A), Color(0x00FFD83A)];
  static const List<double> glowStops = [0.15, 0.42, 1];

  static const double topGap = 4;
  static const String title = '経験値!!';
  static const double titleFont = 84;
  static const double titleOutline = 8;
  static const double bandInset = 40;

  /// The band sits left of centre, leaving room for ドン!! on its right.
  static const double bandShift = 70;
  static const double bandFont = 20;
  static const double bandTracking = 0.3;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 7, 8, 8);
  static const double bandTurnDeg = -2.5;

  /// The counter: "+482 XP" in sun lettering, pulsing as it lands.
  static const double counterGap = 6;
  static const double counterFont = 78;
  static const double counterUnitFont = 30;
  static const double counterOutline = 10;
  static const double finishPulse = 0.18;
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(170, 110), count: 48, innerMin: 70, innerMax: 96, width: 5, seed: 43);
  static const Size impactSize = Size(340, 220);
  static const double impactFromScale = 0.6;
  static const double impactToScale = 1.3;
  /// Kept clear of the counter on either side, with Tobi on the right
  /// under ドン!! (up beside the band, from the counter's top right).
  static const double counterSide = 58;
  static const String sfx = 'ドン!!';
  static const double sfxFont = 30;
  static const int sfxSeed = 8;
  static const double sfxTurnDeg = 10;
  static const Offset sfxAt = Offset(-2, -62);
  static const Placement tobi = Placement(right: -4, bottom: -6, size: Size(64, 76));

  /// The level bar: LV badge, the bar filling in pink, what's left below.
  static const double barGap = 16;
  static const double badgeFont = 22;
  static const EdgeInsets badgePadding = EdgeInsets.fromLTRB(9, 3, 9, 5);
  static const double badgeTurnDeg = -4;
  static const double badgePop = 0.45;
  static const double barBadgeGap = 10;
  static const double barHeight = 26;
  static const double barBorder = 3;
  static const Color barTrack = Palette.paper;
  static const Color barFill = Palette.pink;

  /// A lighter band across the top of the fill.
  static const Color barSheen = Color(0x66FFFFFF);
  static const double barSheenShare = 0.32;
  static const Color barFlash = Palette.sun;
  static const double noteGap = 6;
  static const double noteFont = 13;
  static const double noteBorder = 2;
  static const EdgeInsets notePadding = EdgeInsets.fromLTRB(10, 2, 10, 3);
  static const double flashFont = 13;
  static const double flashTurnDeg = -6;

  /// Lettering thrown off the bar's tip as each line counts in, cycling
  /// through these.
  static const List<String> tipWords = ['ギュン!', 'キラッ', 'ピコン!', 'シュバッ', 'ギュイン!', 'バシッ'];
  static const List<Color> tipWordColors = [Palette.sun, Palette.paper, Palette.pink];
  static const List<double> tipWordTurnDeg = [-10, 6, -4, 9, -7];
  static const double tipWordFont = 20;

  /// Words lean off the tip alternately to the left and right: the share
  /// of a word's width on the far side.
  static const double tipWordLean = 0.8;
  static const int tipWordSeed = 60;
  static const double tipWordRise = 46;
  static const double tipWordPopShare = 0.15;
  static const double tipWordFadeFrom = 0.55;

  /// The breakdown: one strip per source, tilted either way in turn.
  static const double listGap = 14;
  static const double rowGap = 6;
  static const double rowBorder = 2.5;
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(10, 3, 10, 4);
  static const double rowTurnDeg = 0.8;
  static const double rowLabelFont = 16;
  static const double rowCountFont = 13;
  static const double rowXpFont = 20;
  static const double rowCountGap = 8;

  static const double actionGap = 12;
  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

/// The XP page's timeline: the lines pop in one after another, each
/// counting its XP into the total as the bar fills, then the total lands.
abstract final class XpMotion {
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100), curve: Entrances.springy);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 350));
  static const counter = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 450), curve: Entrances.springy);
  static const bar = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 550), curve: Entrances.glide);

  /// The first line pops in at [rowsAt], the next every [rowStep]; each
  /// takes [rowIn] to land and counts its XP in over [rowCount].
  static const rowsAt = Duration(milliseconds: 850);
  static const rowStep = Duration(milliseconds: 170);
  static const rowIn = Duration(milliseconds: 350);
  static const rowCount = Duration(milliseconds: 320);
  static const Curve rowCurve = Entrances.bouncy;
  static const Curve countCurve = Curves.easeOutCubic;

  /// The counter ticks this often while it counts.
  static const tickStep = Duration(milliseconds: 55);

  /// The total lands this long after the count ends, then the rest follows.
  static const finishGap = Duration(milliseconds: 120);
  static const finishPulse = Duration(milliseconds: 380);
  static const jolt = Duration(milliseconds: 320);
  static const double joltReach = 6;
  static const int joltSteps = 9;
  static const int joltSeed = 47;
  static const burst = Duration(milliseconds: 450);
  static const sfx = Duration(milliseconds: 400);
  static const tobiAfter = Duration(milliseconds: 60);
  static const tobi = Duration(milliseconds: 400);
  static const actionsAfter = Duration(milliseconds: 250);
  static const actions = Duration(milliseconds: 400);

  /// The bar flashes and the badge pops at each new level.
  static const levelFlash = Duration(milliseconds: 420);

  /// Each line's lettering leaves the tip this long after the line pops,
  /// and flies for [tipWord].
  static const tipWordAt = Duration(milliseconds: 60);
  static const tipWord = Duration(milliseconds: 560);

  static const double hopHeight = 10;
  static const hopPeriod = Duration(milliseconds: 1000);
  static const double hopAirShare = 0.4;
}

/// The sparks flying off the tip of the filling XP bar (`XpOverlay`), in px.
abstract final class XpSparks {
  static const spawnStep = Duration(milliseconds: 16);
  static const int seed = 53;
  static const double minLife = 0.5, lifeRange = 0.35;

  /// Launch angles (degrees, 0 = right, -90 = up) and speeds (px/s).
  static const double minAngle = -170, angleRange = 150;
  static const double minSpeed = 110, speedRange = 190;
  static const double gravity = 620;
  static const double minSize = 5, sizeRange = 6;
  static const double spin = 6;
  static const double stroke = 1.5;

  /// Opacity holds until this share of a spark's life, then fades out,
  /// shrinking to [fadedSize] of its size.
  static const double fadeFrom = 0.55;
  static const double fadedSize = 0.4;

  /// Every this-many sparks is a square rather than a star.
  static const int squareEvery = 3;
  static const List<Color> colors = [Palette.sun, Palette.paper, Palette.sun, Palette.pink, Palette.sea];

  /// The glint riding the tip while it fills.
  static const double glint = 13;

  /// A star's inner points, as a share of its size.
  static const double starWaist = 0.16;

  /// How far past the bar the sparks may fly before they're cut off.
  static const EdgeInsets reach = EdgeInsets.fromLTRB(40, 120, 40, 60);
}

/// "Level up" (`LevelUpOverlay`): the new level number slams down on a sun
/// page under boiling focus lines.
abstract final class LevelUpLayout {
  static const Color color = Palette.sun;
  static const Alignment glowAt = Alignment(0, -0.1);
  static const List<Color> glowColors = [Palette.paper, Color(0xFFFFF1A8), Palette.sun];
  static const List<double> glowStops = [0, 0.35, 1];
  static const double toneAngle = 180;
  static const List<double> toneStops = [0.62, 1];
  static const focus = BurstSpec(
      box: Size(390, 844), center: Offset(195, 400), count: 160, innerMin: 130, innerMax: 170, width: 4, seed: 71);

  static const double topGap = 8;
  static const String title = 'LEVEL UP!!';
  static const double titleFont = 64;
  static const double titleOutline = 9;
  static const double bandInset = 70;
  static const double bandFont = 20;
  static const double bandTracking = 0.3;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 7, 8, 8);
  static const double bandTurnDeg = -2.5;

  /// The level left behind, struck off above the new one.
  static const double fromFont = 26;
  static const double fromBorder = 2.5;
  static const EdgeInsets fromPadding = EdgeInsets.fromLTRB(10, 2, 10, 4);
  static const double fromGap = 6;

  /// The new level: "LV" over a huge number, stamped at a tilt.
  static const double lvFont = 34;
  static const double numberFont = 150;
  static const double numberOutline = 14;
  static const double lvOutline = 8;
  static const double stampTurnDeg = -5;
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(170, 170), count: 52, innerMin: 90, innerMax: 118, width: 5, seed: 73);
  static const Size impactSize = Size(340, 340);
  static const double impactFromScale = 0.6;
  static const double impactToScale = 1.4;
  static const String sfx = 'ドドーン!!';
  static const double sfxFont = 38;
  static const int sfxSeed = 9;
  static const double sfxTurnDeg = -10;

  /// ドドーン!! bursts out of the number's lower left, Tobi hops at its
  /// lower right.
  static const Offset sfxAt = Offset(-54, -14);
  static const Placement tobi = Placement(right: -66, bottom: -4, size: Size(84, 100));
  static const double levelsFont = 18;
  static const double levelsGap = 18;

  /// What's next: the XP left to the next level and a bar filling to it.
  static const Offset nextCut = Offset(0, 10);
  static const EdgeInsets nextPadding = EdgeInsets.fromLTRB(12, 14, 12, 12);
  static const double nextTagFont = 12;
  static const double nextNoteFont = 15;
  static const double barHeight = 14;
  static const double barGap = 8;

  static const double sectionGap = 12;
  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

abstract final class LevelUpMotion {
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 150), curve: Entrances.springy);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 450));
  static const from = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 450), curve: Entrances.glide);
  static const strike = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 200), delay: Duration(milliseconds: 650), curve: Curves.easeOut);
  static const stamp = EntranceSpec(Entrances.stamp,
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 750), curve: Entrances.springy);

  /// When the stamp first lands.
  static const impactAt = Duration(milliseconds: 860);
  static const jolt = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 360), delay: impactAt, curve: Curves.linear);
  static const double joltReach = 9;
  static const int joltSteps = 10;
  static const int joltSeed = 77;
  static const burst = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 500), delay: impactAt, curve: Curves.easeOut);
  static const sfx = EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 400), delay: impactAt, curve: Entrances.bouncy);
  static const tobi = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 920), curve: Entrances.bouncy);
  static const levels = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 1100), curve: Entrances.bouncy);
  static const next = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 1150), curve: Entrances.glide);
  static const fill = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 700), delay: Duration(milliseconds: 1450), curve: Curves.easeOutCubic);
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1350), curve: Entrances.springy);

  static Duration get length => fill.end;

  static const double hopHeight = 14;
  static const hopPeriod = Duration(milliseconds: 900);
  static const double hopAirShare = 0.4;
}

/// The rating page (実力UP!!, `RatingOverlay`): an orange page with streaks
/// rising to the top, a segmented power gauge for the class's track capped by
/// a hazard-striped gate, and a needle tag carrying the rating up it.
abstract final class RatingLayout {
  static const Color color = Palette.orange;
  static const Alignment glowAt = Alignment(-0.2, -0.05);
  static const List<Color> glowColors = [Color(0xFFFFE9A6), Color(0xFFFFBE55), Palette.orange];
  static const List<double> glowStops = [0, 0.45, 1];
  static const tone = ToneSpec(dot: Color(0xFFE8740C), radius: 1.6, spacing: 6);
  static const double toneAngle = 180;
  static const List<double> toneStops = [0.5, 1];

  /// Streaks shooting up from the bottom (speed lines turned on end).
  static const streaks = SpeedLinesSpec(count: 46, seed: 17, fromEdge: true, color: Color(0x8CFFFFFF));

  static const double topGap = 4;
  static const String title = '実力UP!!';
  static const double titleFont = 84;
  static const double titleOutline = 9;
  static const double bandInset = 50;
  static const double bandFont = 20;
  static const double bandTracking = 0.3;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 7, 8, 8);
  static const double bandTurnDeg = 2;
  static const double gaugeGap = 10;

  /// The gauge: the tower's centre sits at [towerAt] of the width, with
  /// room for the next class above it and the current one below.
  static const double towerAt = 0.34;
  static const double towerWidth = 60;
  static const double topRoom = 66;
  static const double bottomRoom = 50;
  static const double badgeGap = 10;
  static const double nextBadgeFont = 26;
  static const double nextBadgeSuffixFont = 15;
  static const double bandBadgeFont = 18;
  static const double bandBadgeSuffixFont = 11;

  /// The tower: an ink column of lit cells, cool at the bottom and hot at
  /// the top. Unlit cells keep a hint of their colour.
  static const int cells = 12;
  static const double towerPadding = 5;
  static const double cellGap = 4;
  static const List<Color> cellColors = [Palette.shallow, Palette.land, Palette.sun, Palette.pink];
  static const double cellOffTint = 0.2;

  /// Cells lit by this run get a paper sheen down their left side, and the
  /// cell at the needle flickers while it climbs.
  static const Color gainSheen = Color(0x8CFFFFFF);
  static const double gainSheenShare = 0.3;
  static const double tipGlow = 0.55;

  /// The flash of light running up the lit cells as the needle lands.
  static const double surgeHeight = 70;
  static const double surgeGlow = 0.8;
  static const double oldMarkStroke = 2;

  /// Ticks beside the tower at every cell boundary.
  static const double tickLength = 8;
  static const double tickGap = 3;
  static const double tickStroke = 2;

  /// The track's ends and the old rating, left of the tower.
  static const double scaleFont = 13;
  static const double scaleGap = 16;

  /// A scale label is dropped when the old rating's marker comes this
  /// close to it.
  static const double scaleClear = 24;
  static const double oldFont = 15;
  static const double oldArrow = 9;
  static const double oldArrowGap = 4;

  /// The gate: a sun and ink hazard bar across the top of the tower,
  /// reaching past it on both sides, bowing and cracking under the needle.
  static const double gateHeight = 13;
  static const double gateOverhang = 12;
  static const double gateStripe = 9;
  static const double gateBorder = 2.5;
  static const double gateBow = 12;
  static const double crackFrom = 0.45;
  static const double crackStroke = 2;

  /// The needle: an ink arrow and a paper tag with the rating, [needleGap]
  /// right of the tower.
  static const double needleGap = 8;
  static const Size needleArrow = Size(16, 26);
  static const double needleFont = 40;
  static const double needleBorder = 3;
  static const EdgeInsets needlePadding = EdgeInsets.fromLTRB(10, 3, 12, 6);
  static const double landPulse = 0.16;
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(130, 90), count: 40, innerMin: 54, innerMax: 76, width: 5, seed: 81);
  static const Size impactSize = Size(260, 180);
  static const double impactFromScale = 0.6;
  static const double impactToScale = 1.3;

  /// The gain, slapped onto the tag's lower right as it lands, hanging
  /// [gainDrop] px below it.
  static const double gainFont = 24;
  static const EdgeInsets gainPadding = EdgeInsets.fromLTRB(9, 2, 9, 4);
  static const double gainTurnDeg = -7;
  static const double gainDrop = 24;
  static const String landSfx = 'グンッ!!';
  static const double landSfxFont = 26;
  static const int landSfxSeed = 12;
  static const double landSfxTurnDeg = -8;
  static const Offset landSfxAt = Offset(14, -44);

  /// What's left to the next class, with Tobi at its right end.
  static const double stripGap = 12;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(12, 8, 70, 9);
  static const double stripFont = 17;
  static const double stripNumberFont = 26;
  static const Placement tobi = Placement(right: -2, bottom: 2, size: Size(64, 76));
  static const double tobiTremble = 2.5;

  /// The suspense before a breakthrough: the page darkens around the gauge
  /// (title and band dim to [dimTo]), the tag strains up against the gate
  /// and everything rumbles, with ゴゴゴゴ down both sides.
  static const double darkness = 0.8;
  static const double dimTo = 0.3;
  static const double strainPush = 9;
  static const double strainJitter = 2.5;
  static const double rumbleReach = 3.5;
  static const int rumbleSeed = 91;
  static const double beatPulse = 0.03;
  static const String rumble = 'ゴゴゴゴ';
  static const double rumbleFont = 34;
  static const int rumbleSeedLeft = 5, rumbleSeedRight = 6;
  static const Color rumbleColor = Palette.violet;
  static const double rumbleSide = 8;
  static const Alignment rumbleAt = Alignment(0, 0.1);
  static const double rumbleShake = 2;

  /// The beat of silence: …!? hangs in display lettering right of the
  /// tower, [hushAt] from its top right, under the straining needle.
  static const String hush = '…!?';
  static const double hushFont = 58;
  static const double hushOutline = 9;
  static const double hushTurnDeg = -8;
  static const Offset hushAt = Offset(20, 44);

  /// The breakthrough: the needle leaps [leap] px through the shattering
  /// gate with バキィン!! and a burst, then the page flashes white.
  static const double leap = 44;
  static const String breakSfx = 'バキィン!!';
  static const double breakSfxFont = 40;
  static const int breakSfxSeed = 14;
  static const double breakSfxTurnDeg = -9;
  static const breakBurst = BurstSpec(
      box: breakSize, center: Offset(180, 180), count: 56, innerMin: 60, innerMax: 90, width: 5, seed: 83);
  static const Size breakSize = Size(360, 360);
  static const Color flash = Palette.paper;

  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

/// The rating page's timeline. The needle climbs from [climbAt]; landing, or
/// on a rank-up reaching the gate, it strains there for [strain], hangs in
/// silence for [hush] and breaks through, handing over to the rank-up at
/// the peak of the flash.
abstract final class RatingMotion {
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100), curve: Entrances.springy);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 350));
  static const gauge = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 400), curve: Entrances.glide);
  static const needle = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 700), curve: Entrances.springy);
  static const strip = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 650), curve: Entrances.glide);

  static const climbAt = Duration(milliseconds: 1000);
  static const climb = Duration(milliseconds: 1300);
  static const climbToGate = Duration(milliseconds: 1100);
  static const Curve climbCurve = Curves.easeOutCubic;

  /// A ratchet click each time the number goes up, at most this often.
  static const tickStep = Duration(milliseconds: 60);

  /// The tip cell flickers this often while climbing, and at [overload]
  /// while straining.
  static const flicker = Duration(milliseconds: 90);
  static const overload = Duration(milliseconds: 60);

  /// Landing: the tag pulses with a burst and light surges up the lit
  /// cells, then the gain, グンッ!! and the button follow.
  static const landPulse = Duration(milliseconds: 380);
  static const surge = Duration(milliseconds: 420);
  static const burst = Duration(milliseconds: 450);
  static const gainAfter = Duration(milliseconds: 80);
  static const gain = Duration(milliseconds: 400);
  static const sfx = Duration(milliseconds: 400);
  static const tobi = Duration(milliseconds: 400);
  static const actionsAfter = Duration(milliseconds: 250);
  static const actions = Duration(milliseconds: 400);

  /// Straining against the gate, with a heartbeat thud at each of [beats].
  static const strain = Duration(milliseconds: 1300);
  static const List<Duration> beats = [
    Duration.zero,
    Duration(milliseconds: 480),
    Duration(milliseconds: 860),
    Duration(milliseconds: 1160),
  ];
  static const beatPulse = Duration(milliseconds: 220);
  static const strainPeriod = Duration(milliseconds: 140);
  static const rumbleStep = Duration(milliseconds: 40);
  static const Curve darken = Curves.easeIn;

  /// The beat of silence, with …!? popping in [hushPop] into it.
  static const hush = Duration(milliseconds: 650);
  static const hushPop = Duration(milliseconds: 120);
  static const hushIn = Duration(milliseconds: 300);

  /// The break: the gate shatters over [shatter] while the needle leaps;
  /// [flashAt] in, the page flashes white over [flashIn] and holds for
  /// [flashHold] before the cut.
  static const shatter = Duration(milliseconds: 600);
  static const leap = Duration(milliseconds: 260);
  static const flashAt = Duration(milliseconds: 260);
  static const flashIn = Duration(milliseconds: 110);
  static const flashHold = Duration(milliseconds: 60);
  static const double joltReach = 8;
  static const int joltSteps = 9;
  static const int joltSeed = 87;
  static const jolt = Duration(milliseconds: 300);

  static const double hopHeight = 10;
  static const hopPeriod = Duration(milliseconds: 1000);
  static const double hopAirShare = 0.4;
}

/// The gate's shards flying off as it breaks (`RatingOverlay`), in px.
abstract final class RatingShards {
  static const int count = 12;
  static const int seed = 97;

  /// Launch angles (degrees, -90 = up) and speeds (px/s).
  static const double minAngle = -165, angleRange = 150;
  static const double minSpeed = 260, speedRange = 320;
  static const double gravity = 900;
  static const double minSize = 7, sizeRange = 9;
  static const double spin = 9;
  static const double stroke = 1.5;
  static const List<Color> colors = [Palette.sun, Palette.ink, Palette.sun, Palette.paper];
}

/// Graduation (卒業!!, `GraduationOverlay`): a night sky with fireworks,
/// Tobi flying over the moon, and the journey's stamps.
abstract final class GraduationLayout {
  static const Color night = Color(0xFF1C1640);
  static const List<Color> skyColors = [Color(0xFF120E2E), Color(0xFF2B1D5C), Palette.violetDeep];
  static const List<double> skyStops = [0, 0.55, 1];
  static const double skyAngle = 180;

  /// A starry screentone over the sky, fading out toward the bottom.
  static const stars = ToneSpec(dot: Color(0x66FFFFFF), radius: 0.9, spacing: 11);
  static const double starsAngle = 0;
  static const List<double> starsStops = [0.35, 1];

  static const double topGap = 4;
  static const String title = '卒業!!';
  static const double titleFont = 104;
  static const double titleOutline = 10;
  static const double bandInset = 18;
  static const double bandFont = 18;
  static const double bandTracking = 0.16;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 7, 8, 8);
  static const double bandTurnDeg = -2.5;

  /// The moon fills this share of the space between the band and the
  /// message, glowing.
  static const double moonShare = 0.7;
  static const Color moon = Color(0xFFFFF4BF);

  /// Craters and the shaded rim are sun screentone.
  static const crater = ToneSpec(dot: Color(0xFFF2C200), radius: 1.5, spacing: 5, background: Color(0xFFFFE680));
  static const shade = ToneSpec(dot: Color(0xFFE8B800), radius: 1.2, spacing: 5);

  /// The rim shade: a crescent on the lower right, cut by a disc this far
  /// off centre (share of the radius).
  static const Offset shadeCut = Offset(-0.16, -0.14);
  static const double moonBorder = 3.5;

  /// Craters as (x, y, radius), in shares of the moon's radius from its
  /// centre.
  static const List<(double, double, double)> craters = [(-0.38, -0.28, 0.2), (0.3, 0.22, 0.26), (-0.12, 0.48, 0.12)];
  static const double glowScale = 2.1;
  static const List<Color> glowColors = [Color(0xF2FFF1A8), Color(0x99FFD83A), Color(0x00FFD83A)];
  static const List<double> glowStops = [0.42, 0.62, 1];

  /// Tobi flies up from off the lower left, over the moon, and hangs in
  /// front of its upper right; all in shares of the moon's radius from its
  /// centre, Tobi's height included.
  static const Offset flyFrom = Offset(-1.7, 1.2);
  static const Offset flyVia = Offset(-0.8, -1.3);
  static const Offset flyTo = Offset(0.35, -0.3);
  static const double flyFromTurnDeg = -30;
  static const double flyToTurnDeg = -8;
  static const double tobiShare = 0.8;

  /// The stamps: 100/100 at the moon's lower left, 皆伝 at its upper
  /// right.
  static const String fullStamp = '100/100';
  static const String kaidenStamp = '皆伝';
  static const Alignment fullStampAt = Alignment(-0.95, 0.9);
  static const Alignment kaidenStampAt = Alignment(0.95, -0.95);
  static const double fullStampTurnDeg = -12;
  static const double kaidenStampTurnDeg = 10;
  static const double stampFont = 32;
  static const double stampBorder = 4;
  static const double stampRadius = 8;
  static const EdgeInsets stampPadding = EdgeInsets.fromLTRB(12, 4, 12, 8);
  static const double hankoSize = 94;

  /// パーン!! by the first firework.
  static const String sfx = 'パーン!!';
  static const double sfxFont = 34;
  static const int sfxSeed = 14;
  static const double sfxTurnDeg = -12;
  static const Offset sfxAt = Offset(0, 6);
  static const Color stampInk = Palette.pinkDeep;
  static const Color stampPaper = Color(0xE6FFFFFF);

  /// The message: off to a real かるた会, and the switch to all-known.
  static const Offset messageCut = Offset(0, 10);
  static const EdgeInsets messagePadding = EdgeInsets.fromLTRB(14, 14, 14, 12);
  static const double kaiFont = 22;
  static const double kaiNoteFont = 14;
  static const double switchFont = 13;
  static const double switchGap = 8;

  static const double sectionGap = 12;
  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

abstract final class GraduationMotion {
  static const moon = EntranceSpec(Entrances.isrise,
      duration: Duration(milliseconds: 900), delay: Duration(milliseconds: 100), curve: Entrances.swell);
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 500), curve: Entrances.springy);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 800));
  static const fly = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 1400), delay: Duration(milliseconds: 600), curve: Entrances.glide);
  static const sfx = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 250), curve: Entrances.bouncy);

  /// The two stamps land one after the other, each with a jolt.
  static const fullStamp = EntranceSpec(Entrances.stamp,
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 1300), curve: Entrances.springy);
  static const kaidenStamp = EntranceSpec(Entrances.stamp,
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 1700), curve: Entrances.springy);
  static const fullImpactAt = Duration(milliseconds: 1410);
  static const kaidenImpactAt = Duration(milliseconds: 1810);
  static const jolt = Duration(milliseconds: 320);
  static const double joltReach = 7;
  static const int joltSteps = 9;
  static const int joltSeed = 83;

  static const message = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 2000), curve: Entrances.glide);
  static const switchNote = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 2300), curve: Entrances.bouncy);
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 2450), curve: Entrances.springy);

  static Duration get length => actions.end;

  /// The first this-many fireworks pop out loud (the rest burst silently).
  static const int fireworkSounds = 3;

  /// Once there, Tobi keeps floating.
  static const double swayTurnDeg = 4;
  static const double swayLift = 7;
  static const swayPeriod = Duration(milliseconds: 1800);
}

/// "Today's set done" (本日完了!!, `DayDoneOverlay`): sea blue under a pale
/// glow and white focus lines; the day's bar, the 完了 hanko on it, Tobi
/// cheering and the day's numbers.
abstract final class DayDoneLayout {
  static const Color color = Palette.sea;
  static const Alignment glowAt = Alignment(0, -0.34);
  static const List<Color> glowColors = [Color(0xF2DCEFFF), Color(0x8CA9DCFF), Color(0x002B9BFF)];
  static const List<double> glowStops = [0, 0.2, 0.46];
  static const focus = BurstSpec(
      box: Size(384, 832),
      center: Offset(192, 246),
      count: 200,
      innerMin: 150,
      innerMax: 210,
      width: 4,
      seed: 19,
      color: Color(0xD9FFFFFF));

  static const double topGap = 26;
  static const String title = '本日完了!!';
  static const double titleFont = 52;
  static const double titleOutline = 16;

  /// The ink band under the title: a slanted parallelogram with a paper
  /// edge, its lettering upright; ドン! bursts out at its lower right,
  /// [sfxRight] from the screen's edge and [sfxTop] below the band's top.
  static const double bandGap = 18;
  static const double bandFont = 18.5;
  static const double bandTracking = 0.04;
  static const double bandLineHeight = 1.5;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(16, 5, 16, 7);
  static const double bandTurnDeg = -3.5;
  static const double bandSkewDeg = -12;
  static const double bandEdge = 3;
  static const String sfx = 'ドン!';
  static const double sfxFont = 40;
  static const double sfxOutline = 5;
  static const int sfxSeed = 5;
  static const double sfxTurnDeg = -12;
  static const double sfxRight = 14;
  static const double sfxTop = 34;

  /// The day's bar as on Home (reviews, new cards, misses), green from the
  /// left up to [sweepFrom] before its last bit sweeps green, with a paper
  /// edge round its ink border.
  static const double barGap = 30;
  static const double barInset = 24;
  static const double barHeight = 32;
  static const double barBorder = 3;
  static const double barEdge = 3;
  static const double sweepFrom = 0.8;

  /// The 完了 hanko slammed onto the bar, the day's date under it: a
  /// pink-deep border with a thin rule [stampRuleGap] inside it.
  static const String stamp = '完了';
  static const double stampFont = 32;
  static const double stampTracking = 0.12;
  static const Color stampPaper = Color(0xDBFFFFFF);
  static const double stampBorder = 3;
  static const double stampRuleGap = 2;
  static const double stampRule = 1.6;
  static const EdgeInsets stampPadding = EdgeInsets.fromLTRB(15, 3.5, 15, 1.5);
  static const double stampTurnDeg = -7;
  static const double dateFont = 10;
  static const double dateTracking = 0.14;
  static const double dateGap = 3;
  static const String dateSeparator = '.';

  /// Tobi cheering between the bar and the numbers; he shrinks when the
  /// numbers need the room, down to [tobiMinHeight].
  static const Size tobi = Size(118, 140);
  static const double tobiMinHeight = 64;
  static const double tobiGap = 24;
  static const double statsGap = 22;

  /// The day's numbers, one per row with dashed rules between, then the XP
  /// under an ink rule.
  static const double statsInset = 24;
  static const EdgeInsets statsPadding = EdgeInsets.fromLTRB(16, 12, 16, 14);
  static const double statFont = 14.5;
  static const double statNumberFont = 22;
  static const double statRowPadding = 4;
  static const Color statRule = Color(0xFFC9C6BF);
  static const double xpGap = 8;
  static const double xpRule = 3;
  static const double xpRuleGap = 10;
  static const double xpLabelFont = 13;
  static const double xpLabelGap = 8;

  /// "+1000 XP" on a sun chip, taking at most [xpChipShare] of the row;
  /// both it and its label shrink to fit.
  static const double xpChipFont = 26;
  static const EdgeInsets xpChipPadding = EdgeInsets.fromLTRB(12, 5, 12, 7);
  static const double xpChipTurnDeg = -2;
  static const double xpChipShare = 0.6;

  static const double ctaGap = 12;
  static const double ctaHeight = 66;
  static const double ctaFont = 28;
  static const double ctaSubFont = 15;
  static const Offset ctaShadow = Offset(5, 5);
}

/// The 本日完了!! entrance, all in stop-motion steps: the title drops, the
/// band slides in, the bar's last bit sweeps green, the hanko slams down
/// with ドン! and a jolt at [impactAt], Tobi hops in, then the numbers and
/// the button rise while the XP counts up.
abstract final class DayDoneMotion {
  static const title = EntranceSpec(EntranceFrom(offset: Offset(0, -40), scale: 1.25),
      duration: Duration(milliseconds: 260), curve: StepCurve(4));
  static const band = EntranceSpec(EntranceFrom(offset: Offset(-300, 0), opaqueAt: 0.3),
      duration: Duration(milliseconds: 200), delay: Duration(milliseconds: 160), curve: StepCurve(3));
  static const sweep = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 520), delay: Duration(milliseconds: 380), curve: StepCurve(8));
  static const stamp = EntranceSpec(EntranceFrom(scale: 2.6, turnDeg: -9),
      duration: Duration(milliseconds: 230), delay: Duration(milliseconds: 980), curve: Cubic(0.3, 1.6, 0.6, 1));
  static const sfx = EntranceSpec(EntranceFrom(scale: 0.2),
      duration: Duration(milliseconds: 260), delay: Duration(milliseconds: 1000), curve: StepCurve(3, Entrances.bouncy));

  static const impactAt = Duration(milliseconds: 1050);
  static const jolt = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 180), delay: impactAt, curve: Curves.linear);
  static const double joltReach = 4;
  static const int joltSteps = 4;
  static const int joltSeed = 23;

  static const tobi = EntranceSpec(EntranceFrom(offset: Offset(0, 30)),
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 1150), curve: StepCurve(4, Entrances.bouncy));
  static const stats = EntranceSpec(EntranceFrom(offset: Offset(0, 24)),
      duration: Duration(milliseconds: 260), delay: Duration(milliseconds: 1250), curve: StepCurve(4));
  static const xp = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 1300), curve: Curves.linear);
  static const cta = EntranceSpec(EntranceFrom(offset: Offset(0, 24)),
      duration: Duration(milliseconds: 260), delay: Duration(milliseconds: 1450), curve: StepCurve(4));

  static Duration get length => xp.end;
}
