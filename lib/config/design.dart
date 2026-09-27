import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Design tokens of the manga world (`research/design/final.html`). Sizes are
/// logical pixels on the spec's 390 × 844 phone; letter spacing is in em.

abstract final class Palette {
  static const ink = Color(0xFF141414);
  static const paper = Color(0xFFFFFFFF);
  static const desk = Color(0xFFE4E1DB);
  static const mute = Color(0xFF333333);
  static const inkSoft = Color(0xFF2B2B2B);
  static const inkBody = Color(0xFF1D1D1D);

  static const pink = Color(0xFFFF3D7F);
  static const pinkDeep = Color(0xFFE0246A);
  static const pinkSoft = Color(0xFFFFE1EB);
  static const sea = Color(0xFF2B9BFF);
  static const seaDeep = Color(0xFF1463C4);
  static const seaSoft = Color(0xFFDCEFFF);
  static const shallow = Color(0xFFA9DCFF);
  static const land = Color(0xFF8ED462);
  static const landDeep = Color(0xFF5E8C47);
  static const landSoft = Color(0xFFE5F6D8);
  static const sun = Color(0xFFFFD83A);
  static const sunSoft = Color(0xFFFFF4BF);
  static const violet = Color(0xFF9A5BC2);
  static const violetSoft = Color(0xFFF1E6F7);

  /// Torifuda colours as used in illustrations (Tobi, pips, fanned cards).
  static const cardFrame = Color(0xFF6A9354);
  static const cardPaper = Color(0xFFEAEAEA);

  /// Speed tiers, fastest first (see [SpeedTiers]).
  static const tiers = [Color(0xFFFFD83A), Color(0xFFFF9A2E), Color(0xFFFF3D7F), Color(0xFF6E2C8C)];
  static const tierText = [ink, ink, ink, paper];
}

/// Tier boundaries for colouring a card by its speed, ms.
abstract final class SpeedTiers {
  static const List<double> upperMs = [500, 650, 800];

  static int of(double ms) {
    for (var i = 0; i < upperMs.length; i++) {
      if (ms < upperMs[i]) return i;
    }
    return upperMs.length;
  }
}

/// Coloured screentone dot patterns. Two dots per [spacing] cell, the second
/// offset by half a cell diagonally.
@immutable
class ToneSpec {
  const ToneSpec({
    required this.dot,
    required this.radius,
    required this.spacing,
    this.background,
    this.phase = 0.5,
  });

  final Color dot;
  final double radius;
  final double spacing;
  final Color? background;

  /// Position of the first dot inside its cell, as a fraction of [spacing]
  /// (0.5 for CSS radial-gradient tones, 0.25 for the spec's SVG patterns).
  final double phase;

  @override
  bool operator ==(Object other) =>
      other is ToneSpec &&
      other.dot == dot &&
      other.radius == radius &&
      other.spacing == spacing &&
      other.background == background &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(dot, radius, spacing, background, phase);
}

/// Where an overlay (Tobi, a balloon) sits in its panel: two edges and a size.
@immutable
class Placement {
  const Placement({this.left, this.top, this.right, this.bottom, required this.size});
  final double? left, top, right, bottom;
  final Size size;
}

abstract final class Tones {
  /// Tiles are cached per pixel density rounded to 1 / this.
  static const int densitySteps = 100;
  static const int minTilePx = 2;
  static const int maxTilePx = 4096;
  /// Anti-aliasing fringe added to each dot's radius (the CSS tones fade out
  /// over 0.6 px).
  static const double softEdge = 0.3;

  static const ink = ToneSpec(dot: Palette.ink, radius: 1, spacing: 5);
  static const inkLight = ToneSpec(dot: Palette.ink, radius: 0.7, spacing: 6);
  static const inkMid = ToneSpec(dot: Palette.ink, radius: 1.35, spacing: 5);
  static const inkDark = ToneSpec(dot: Palette.ink, radius: 1.85, spacing: 5);
  static const inkReverse = ToneSpec(dot: Palette.paper, radius: 1.05, spacing: 5, background: Palette.ink);
  static const pink = ToneSpec(dot: Palette.pink, radius: 1.6, spacing: 6);
  static const sea = ToneSpec(dot: Color(0xFF5FB6FF), radius: 1.5, spacing: 6, background: Palette.seaSoft);
  static const seaDeep = ToneSpec(dot: Color(0xFF0F4E9E), radius: 1.5, spacing: 6, background: Palette.sea);
  static const land = ToneSpec(dot: Color(0xFF8CCB67), radius: 1.5, spacing: 6, background: Palette.landSoft);
  static const sun = ToneSpec(dot: Color(0xFFFFC400), radius: 1.6, spacing: 6, background: Palette.sunSoft);
  static const violet = ToneSpec(dot: Color(0xFFA77CC0), radius: 1.5, spacing: 6, background: Palette.violetSoft);

  /// The ink stamp shown on a pressed button.
  static const stamp = ToneSpec(dot: Palette.ink, radius: 1.3, spacing: 5);
  static const double stampOpacity = 0.28;

  // Map patterns (sea, island land, unexplored shoal).
  static const mapSea = ToneSpec(dot: Color(0xFF2386E6), radius: 1.1, spacing: 7, background: Color(0xFF3FA5FF), phase: 0.25);
  static const mapLand = ToneSpec(dot: Color(0xFF71BA4B), radius: 0.95, spacing: 5, background: Color(0xFF9BDB70), phase: 0.25);
  static const mapShoal = ToneSpec(dot: Color(0xFF7FC6FB), radius: 0.9, spacing: 6, background: Color(0xFFA6DAFF), phase: 0.25);
  static const mapInk = ToneSpec(dot: Palette.ink, radius: 0.85, spacing: 4, phase: 0.25);
}

abstract final class Strokes {
  static const double panel = 3;
  static const double button = 3;
  static const double control = 2.5;
  static const double label = 2;
  static const double hairline = 1.5;

  /// Default outline behind title lettering.
  static const double outline = 10;

  /// Border thickening of a pressed button (inset shadow in the spec).
  static const double pressed = 3;
  static const List<double> dash = [5, 4];
  static const List<double> fineDash = [2.6, 2];
}

abstract final class Gaps {
  static const double gutter = 16;
  static const double panel = 8;
  static const double panelWide = 10;
  static const double section = 12;
  static const double inner = 12;
  static const double tight = 4;
  static const double small = 6;
}

abstract final class Fonts {
  static const display = 'Dela';
  static const sfx = 'Reggae';
  static const ui = 'ZenKaku';
}

abstract final class Weights {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const bold = FontWeight.w700;
  static const black = FontWeight.w900;
}

abstract final class TypeScale {
  /// Line height of display-type titles.
  static const double displayLineHeight = 1.05;
  static const double body = 14;
  static const double small = 12.5;
  static const double tiny = 12;
  static const double label = 13;
  static const double button = 15;
  static const double title = 20;
}

/// Tilts and skews, degrees.
abstract final class Tilt {
  static const double tagSkew = -12;
  static const double sticker = -2;
  static const double pressButton = -0.7;
  static const double pressShout = -1.2;
  static const double bob = -1.5;
}

abstract final class Motion {
  static const press = Duration(milliseconds: 70);
  static const stampFade = Duration(milliseconds: 120);
  static const pressCurve = Curves.easeOut;
  static const route = Duration(milliseconds: 320);
  static const routeReverse = Duration(milliseconds: 240);
  static const routeCurve = Curves.easeOutCubic;
  static const tab = Duration(milliseconds: 180);
  static const sheet = Duration(milliseconds: 260);

  /// Horizontal slide of a pushed page, as a fraction of its width.
  static const double routeSlide = 0.18;

  /// Scale a pushed modal page starts from.
  static const double routeZoom = 0.94;
}

/// How far pressed controls move.
abstract final class Press {
  static const double buttonDrop = 2;
  static const double buttonScale = 0.97;
  static const double shoutScale = 0.95;
  static const double tabScale = 0.96;
  static const double panelScale = 0.985;
}

/// Tide rings pulsing around the current island.
abstract final class Tide {
  static const period = Duration(milliseconds: 2600);
  static const curve = Cubic(0.2, 0.7, 0.3, 1);
  static const double scaleFrom = 0.9;
  static const double scaleTo = 1.32;

  /// Fraction of the period after which a ring has faded out.
  static const double fadeEnd = 0.75;
  static const double stroke = 3;

  /// Extra radius beyond the island's half extent.
  static const double margin = 7;
}

abstract final class ToastStyle {
  static const hold = Duration(milliseconds: 2600);
  static const fade = Duration(milliseconds: 220);

  /// Distance above the bottom inset, clearing the tab bar.
  static const double bottom = 96;

  /// Start offset of the drop-in, as a fraction of the toast's height.
  static const double slide = 0.4;
}

/// How many rendered bitmaps each cache keeps.
abstract final class CacheLimits {
  static const int staticArt = 12;
  static const int mapLayers = 8;
}

abstract final class TabBarStyle {
  static const double lineHeight = 1.15;
  static const double height = 62;
  static const double gap = 8;
  static const double icon = 21;
  static const double iconGap = 2;
  static const double label = 13;
  static const double sub = 12;
}

abstract final class ButtonMetrics {
  static const double iconButton = 44;
  static const double icon = 22;
  static const double iconStroke = 2.4;
  static const double goButton = 44;
  static const double goIcon = 22;
  static const double goIconStroke = 3;
  static const double rowHeight = 60;
  static const double rowIcon = 26;
  static const double rowPadding = 12;
  static const double rowGap = 10;
}

abstract final class LangToggleStyle {
  static const double height = 34;
  static const double padding = 11;
  static const double font = 12.5;
}

abstract final class TagStyle {
  static const double lineHeight = 1.15;
  static const double bannerLineHeight = 1.2;
  static const double font = 12;
  static const double tracking = 0.12;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(10, 5, 10, 5);
  static const EdgeInsets compactPadding = EdgeInsets.fromLTRB(8, 3, 8, 4);

  /// The skewed display-font banner (TRAINING, WELCOME ABOARD).
  static const double bannerFont = 15;
  static const double bannerTracking = 0.16;
  static const EdgeInsets bannerPadding = EdgeInsets.fromLTRB(12, 5, 11, 6);
}

abstract final class PillStyle {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(8, 2, 8, 3);
  static const double lineHeight = 1.2;
}

abstract final class StickerStyle {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(8, 4, 8, 6);
  static const double badgeSize = 32;
  static const double badgeFont = 16;
  static const double badgePadding = 6;
}

abstract final class NarrationStyle {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(11, 6, 11, 6);
  static const double font = 14;
  static const double number = 17;
  static const double lineHeight = 1.4;
}

abstract final class BalloonStyle {
  static const double tail = 14;

  /// Tail rotation that points straight down, degrees.
  static const double tailDown = 45;

  /// The CSS tail box sits this much higher than its root point.
  static const double tailLift = 1;
  static const double tailSkew = 8;
  static const double lineHeight = 1.15;
}

/// The spiky outline of a shout balloon.
@immutable
class ShoutSpec {
  const ShoutSpec({this.spikes = 28, this.outer = 8, this.inner = 3, this.roundness = 5, this.seed = 11});

  final int spikes;

  /// How far spikes reach out and notches cut in, px.
  final double outer, inner;

  /// Superellipse exponent: higher is boxier.
  final double roundness;
  final int seed;

  @override
  bool operator ==(Object other) =>
      other is ShoutSpec &&
      other.spikes == spikes &&
      other.outer == outer &&
      other.inner == inner &&
      other.roundness == roundness &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(spikes, outer, inner, roundness, seed);
}

/// The START TRAINING shout.
abstract final class ShoutStyle {
  static const double font = 20;
  static const double tracking = 0.02;
  static const double gap = 10;
  static const double icon = 24;
  static const double iconStroke = 3.2;
  static const double stroke = 3;
  static const double strokePressed = 5;

  /// Superellipse samples used to place the spikes.
  static const int samples = 720;

  /// Room left between the spikes' outer reach and the box edge.
  static const double edgeRoom = 2;
  static const double outerMin = 0.55;
  static const double outerRange = 0.9;
  static const double innerMin = 0.4;
  static const double innerRange = 0.8;
  static const double jitter = 0.3;
}

/// SFX lettering: per-character jitter and outline.
abstract final class SfxStyle {
  static const double rotationDeg = 16;
  static const double shift = 8;
  static const double firstScale = 1.12;
  static const double scaleMin = 0.9;
  static const double scaleRange = 0.22;
  static const double overlap = -0.04;
  static const double outline = 8;
  static const double halo = 9;
}

/// Speed and focus line generation.
abstract final class LineStyle {
  /// Focus lines reach this far past the farthest corner.
  static const double focusOverreach = 20;
  static const double focusJitter = 1.1;
  static const double focusLongChance = 0.25;
  static const double focusLongFactor = 1.9;
  static const double focusThickChance = 0.2;
  static const double focusBaseWidth = 0.5;
  static const double speedMinLength = 0.35;
  static const double speedMinThickness = 0.6;
  static const double speedThicknessRange = 3.2;
  static const double speedTaper = 6;

  /// A free streak starts this far back from the right edge (fraction of its
  /// length, plus a random share of the range) and spans this much of it.
  static const double streakStartMin = 0.6;
  static const double streakStartRange = 0.4;
  static const double streakSpan = 0.9;
}

abstract final class HeaderStyle {
  static const double height = 54;
  static const double logo = 27;
  static const double logoTracking = 0.02;
  static const double sub = 12;
  static const double subTracking = 0.24;
  static const double titleSub = 15;
  static const double subGap = 4;
  static const double actionGap = 10;
  static const double topGap = 4;
}

abstract final class TobiStyle {
  /// Idle bob: rise and tilt at mid-cycle.
  static const bobPeriod = Duration(milliseconds: 1900);
  static const double bobRise = 4;
  static const blinkEvery = Duration(milliseconds: 3800);
  static const blinkLength = Duration(milliseconds: 140);

  /// Eye height at the bottom of a blink.
  static const double blinkSquash = 0.1;
}

/// Island map rendering (`IslandMap`).
abstract final class MapStyle {
  static const double coastStroke = 2.6;
  static const double shoalStroke = 1.8;
  static const List<double> shoalDash = [5, 4];
  static const double surf = 9;
  static const double treeStroke = 1.3;
  static const double treeMaxRadius = 5.2;
  static const double treeInset = 0.3;
  static const double treeHighlightOffset = 0.34;
  static const double treeHighlightRadius = 0.3;
  static const Color tree = Palette.landDeep;
  static const Color treeHighlight = Color(0xFFB5E68F);
  static const double dotStroke = 1.4;
  static const double pendingStroke = 1.5;
  static const double hollowStroke = 1.6;
  static const double hollowInset = 0.4;
  static const double waveStroke = 2;
  static const double waveOpacity = 0.85;

  /// One wave squiggle per this many square map units.
  static const double waveDensity = 4200;
  static const double waveHalf = 4;
  static const double waveHeight = 4.5;
  static const double routeStroke = 3.6;
  static const List<double> routeDoneDash = [9, 6];
  static const List<double> routeAheadDash = [0.1, 8];

  /// Where the route starts, relative to the first island's centre.
  static const Offset routeStart = Offset(-46, 56);
  static const Size flag = Size(19, 26);
  static const Offset flagOffset = Offset(10, -14);
  static const Size boat = Size(36, 33);

  /// Boat anchor above the route point, as a fraction of its height.
  static const double boatLift = 0.7;

  /// How far along the last sailed leg the boat floats.
  static const double boatAlong = 0.5;
  static const double plateFont = 14;
  static const double plateFontLong = 13;
  static const double platePad = 6;
  static const double plateExtraHeight = 9;
  static const double plateRadius = 4;
  static const double plateStroke = 2;
  static const double plateStrokeCurrent = 2.6;
  static const List<double> plateDash = [4, 3];
  static const double chipScale = 0.9;
  static const double chipPad = 10;
  static const double chipGap = 4;
  static const double chipRadius = 3;
  static const double chipStroke = 1.3;
  static const double chipInset = 3;
  static const double tapSlop = 6;
}

/// The Home screens (spec phones 2 and 3).
abstract final class HomeLayout {
  static const double mapCut = 12;
  static const EdgeInsets mapLabelInsets = EdgeInsets.fromLTRB(12, 10, 12, 0);
  static const double mapBannerFont = 14;
  static const double mapCountTop = 44;
  static const double mapCountFont = 13;
  static const double mapCountNumber = 15;
  static const EdgeInsets mapCountPadding = EdgeInsets.fromLTRB(9, 3, 9, 3);
  static const double mapMistFont = 12.5;
  static const EdgeInsets mapMistPadding = EdgeInsets.fromLTRB(8, 3, 8, 3);

  static const double progressHeight = 70;
  static const EdgeInsets progressPadding = EdgeInsets.fromLTRB(12, 8, 12, 0);
  static const double islandTitle = 20;
  static const double nowFont = 12;
  static const EdgeInsets nowPadding = EdgeInsets.fromLTRB(6, 1, 6, 1);
  static const double learnedFont = 14;
  static const double learnedNumber = 18;
  static const double pipWidth = 21;
  static const double pipHeight = 24;
  static const double pipGap = 6;
  static const double pipTop = 8;
  static const double pipRadius = 3;
  static const double pipInset = 3;

  static const double journeyHeroHeight = 206;
  static const double journeyHeroCut = 8;
  static const double journeyTitle = 52;
  static const double journeyTitleOutline = 11;
  static const EdgeInsets journeyHeroPadding = EdgeInsets.fromLTRB(18, 12, 18, 6);
  static const double journeyNarrationGap = 0;
  static const double journeyShoutHeight = 58;
  static const double journeyShoutLeft = 14;
  static const double journeyShoutRight = 18;
  static const journeyShout = ShoutSpec(spikes: 28, outer: 7);
  static const Placement journeyTobi = Placement(right: 8, top: -16, size: Size(96, 114));
  static const Placement journeyBalloon = Placement(right: 102, top: 22, size: Size(100, 54));
  static const double journeyBalloonFont = 13.5;
  static const Alignment journeyBalloonTail = Alignment(0.84, 0.4);
  static const double journeyBalloonTailTurn = -30;

  static const double rankHeight = 92;

  /// Widths of the rating and streak panels on the spec's 358-wide row.
  static const int rankFlex = 250;
  static const int streakFlex = 108;
  static const double rankSlant = 10;
  static const double rankGap = 12;
  static const double classFont = 32;
  static const double classSuffixFont = 18;
  static const double ratingLabelFont = 12;
  static const double ratingLabelTracking = 0.14;
  static const double ratingFont = 26;
  static const double ratingBarWidth = 112;
  static const double ratingBarHeight = 12;
  static const double ratingBarGap = 4;
  static const double ratingNoteFont = 12.5;
  static const double streakNumber = 15;
  static const double streakFont = 12.5;
  static const double streakGap = 4;
  static const EdgeInsets streakLabelPadding = EdgeInsets.fromLTRB(4, 1, 4, 1);

  static const double heroGap = 10;
  static const double heroCut = 22;
  static const double heroTitle = 68;
  static const double heroTitleOutline = 12;
  static const EdgeInsets heroPadding = EdgeInsets.fromLTRB(22, 14, 18, 32);
  static const double heroNarrationIndent = -4;
  static const double heroNarrationGap = 19;
  static const double heroShoutHeight = 74;
  static const double heroShoutLeft = 14;
  static const double heroShoutRight = 14;
  static const heroShout = ShoutSpec(spikes: 30);
  static const Placement heroTobi = Placement(right: 12, top: -20, size: Size(118, 140));
  static const Placement heroBalloon = Placement(right: 110, top: 38, size: Size(94, 50));
  static const double heroBalloonFont = 14.5;
  static const Alignment heroBalloonTail = Alignment(0.88, 0.48);
  static const double heroBalloonTailTurn = -24;

  static const double modeHeight = 112;
  static const double modeSlant = 22;
  static const double modeGutter = 10;

  /// Where the free-play panel ends, as a fraction of the row width.
  static const double modeSplit = 180 / 358;
  static const double nigateTextLeft = 16;
  static const double modeTitleGap = 1;
  static const double modeNoteGap = 2;
  static const double modeTitle = 25;
  static const double modeSub = 15;
  static const double modeNote = 12.5;
  static const Offset modeTextAt = Offset(14, 30);
  static const double modeIcon = 34;
  static const Offset modeIconAt = Offset(124, 28);
  static const Offset modeBadgeAt = Offset(124, 22);

  static const double guestHeight = 104;
  static const double guestIconCircle = 40;
  static const double guestIcon = 22;
  static const double guestChevron = 18;
  static const double guestTitle = 15;
  static const double guestNote = 12.5;
  static const double guestNoteLineHeight = 1.38;
  static const double guestNoteGap = 3;
  static const int guestNoteLines = 3;

  static const double rowJpFont = 17;
  static const double rowLineHeight = 1.1;
  static const EdgeInsets balloonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const double rowSubFont = 12;
  static const double untrackedFont = 12;
  static const double untrackedTracking = 0.08;
  static const EdgeInsets untrackedPadding = EdgeInsets.fromLTRB(5, 1, 5, 2);
  static const double untrackedGap = 4;
}

/// The first-launch screen (spec phone 1).
abstract final class OnboardingLayout {
  static const double topGap = 4;
  static const double skyHeight = 344;
  static const double skyCut = 26;
  static const double title = 50;
  static const double titleOutline = 12;
  static const Offset titleAt = Offset(18, 14);
  static const double titleBannerGap = 4;
  static const double langInset = 10;
  static const Placement tobi = Placement(left: 20, bottom: 83, size: Size(120, 143));
  static const Placement balloon = Placement(right: 0, bottom: 92, size: Size(210, 122));
  static const double balloonPadding = 18;
  static const double balloonTitle = 18;
  static const double balloonBody = 14.5;
  static const double balloonSmall = 12;
  static const double balloonGap = 4;
  static const Alignment balloonTail = Alignment(-0.92, 0.24);
  static const double balloonTailTurn = 118;
  static const double seaHeight = 122;

  static const double choiceHeight = 150;
  static const double choiceCut = 10;
  static const double illustration = 108;
  static const Offset illustrationAt = Offset(10, 24);
  static const EdgeInsets textInsets = EdgeInsets.fromLTRB(126, 20, 12, 0);
  static const double choiceTitle = 26;
  static const double choiceTitleGap = 7;
  static const double choiceSub = 15;
  static const double choiceSubGap = 3;
  static const double choiceNote = 12.5;
  static const double choiceNoteGap = 5;
  static const double choiceNoteLineHeight = 1.35;
  static const double choiceNoteRightRoom = 44;
  static const double goInset = 12;
  static const double noteIcon = 24;
  static const double noteFont = 14;
  static const double noteLineHeight = 1.35;
  static const EdgeInsets notePadding = EdgeInsets.fromLTRB(12, 10, 12, 10);
}

/// The 正 tally of the streak: strokes of one 正 in writing order, in a
/// 70 × 32 box holding two characters.
abstract final class Tally {
  static const Size box = Size(70, 32);
  static const List<String> strokes = ['M3 4 H27', 'M15 4 V27', 'M15 15.5 H25', 'M7 13 V27', 'M2 27.5 H28'];
  static const double glyphAdvance = 38;
  static const double stroke = 3.2;
  static const double latestStroke = 3.8;
  static const double ghostStroke = 1.4;
  static const List<double> ghostDash = [2, 3];
  static const double ghostOpacity = 0.5;
}

/// The guest-mode confirmation sheet.
abstract final class GuestSheetStyle {
  static const double title = 22;
  static const double body = 14;
  static const double bodyLineHeight = 1.45;
  static const double shoutHeight = 64;
  static const double cancelHeight = 48;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 22, 20, 20);
  static const double cut = 14;
  static const Placement tobi = Placement(right: 18, top: -64, size: Size(76, 90));
  static const Color barrier = Color(0x8C141414);
}

/// The stand-in for screens still being built.
abstract final class ComingSoonStyle {
  static const Size box = Size(300, 220);
  static const Placement tobi = Placement(left: 20, bottom: 0, size: Size(120, 143));
  static const Placement balloon = Placement(right: 0, top: 0, size: Size(150, 80));
  static const Alignment tail = Alignment(-0.7, 0.9);
  static const double tailTurn = 100;
}

/// Sky and hero backgrounds: radial and linear gradients (CSS angles, degrees).
abstract final class Backdrops {
  static const skyCenter = Alignment(-0.46, 0.24);
  static const skyColors = [Color(0xFFFFFBE6), Color(0xFFFFF1A8), Palette.sun];
  static const skyStops = [0.0, 0.38, 1.0];

  static const heroCenter = Alignment(0.6, -0.64);
  static const heroColors = [Palette.paper, Color(0xFFFFF6CC), Color(0xFFFFE36B)];
  static const heroStops = [0.0, 0.4, 1.0];

  /// The pink hero tone fades in toward the bottom left.
  static const double heroToneAngle = 198;
  static const heroToneStops = [0.46, 0.9];

  static const double freePlayAngle = 100;
  static const freePlayStops = [0.52, 1.0];
  static const nigateStops = [0.7, 1.0];

  /// White mist over the top of the journey map.
  static const double mapFogHeight = 74;
  static const mapFogStops = [0.0, 0.38, 1.0];
  static const mapFogAlpha = [1.0, 0.93, 0.0];
}

/// A focus-line burst: [count] wedges converging on [center] (a point in a
/// box of [box] size; it scales with the actual box), starting between
/// [innerMin] and [innerMax] from it.
@immutable
class BurstSpec {
  const BurstSpec({
    required this.box,
    required this.center,
    required this.count,
    required this.innerMin,
    required this.innerMax,
    required this.width,
    required this.seed,
    this.color = Palette.ink,
  });

  final Size box;
  final Offset center;
  final int count;
  final double innerMin, innerMax, width;
  final int seed;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is BurstSpec &&
      other.box == box &&
      other.center == center &&
      other.count == count &&
      other.innerMin == innerMin &&
      other.innerMax == innerMax &&
      other.width == width &&
      other.seed == seed &&
      other.color == color;

  @override
  int get hashCode => Object.hash(box, center, count, innerMin, innerMax, width, seed, color);
}

/// A band of horizontal speed lines. Streaks float freely; [fromEdge] lines
/// all start at the right edge and taper off to the left.
@immutable
class SpeedLinesSpec {
  const SpeedLinesSpec({required this.count, required this.seed, this.fromEdge = false, this.color = Palette.ink});
  final int count;
  final int seed;
  final bool fromEdge;
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is SpeedLinesSpec &&
      other.count == count &&
      other.seed == seed &&
      other.fromEdge == fromEdge &&
      other.color == color;

  @override
  int get hashCode => Object.hash(count, seed, fromEdge, color);
}

/// Focus-line bursts of the spec's panels.
abstract final class Bursts {
  static const onboarding =
      BurstSpec(box: Size(358, 344), center: Offset(92, 206), count: 120, innerMin: 76, innerMax: 110, width: 3, seed: 7);
  static const journeyHero =
      BurstSpec(box: Size(358, 206), center: Offset(300, 40), count: 120, innerMin: 56, innerMax: 86, width: 3.2, seed: 3);
  static const hero =
      BurstSpec(box: Size(358, 318), center: Offset(290, 62), count: 130, innerMin: 66, innerMax: 96, width: 3.4, seed: 3);
}

/// The Home journey map: how much of the archipelago is visible.
abstract final class JourneyView {
  /// The current island sits this far down the visible span.
  static const double focus = 0.62;

  /// Sea seed for the wave squiggles.
  static const int seaSeed = 4;

  /// Upcoming islands that get a (dashed) name plate.
  static const int platesAhead = 3;
}
