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

  /// The sea dot pattern with no fill, for a faint wash over paper (Play's
  /// bottom band).
  static const seaFaint = ToneSpec(dot: Color(0xFF5FB6FF), radius: 1.5, spacing: 6);

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
  /// The text area: this share of the oval's width and height, centred
  /// (0.78² + 0.62² < 1, so its corners stay inside the oval).
  static const double textWidth = 0.78;
  static const double textHeight = 0.62;

  /// The tail: how far it reaches past the oval, its width where it leaves
  /// the oval, how much it curls (share of its length) and how deep its root
  /// sinks into the oval so the two merge cleanly.
  static const double tailLength = 16;
  static const double tailBase = 16;
  static const double tailBend = 0.18;
  static const double tailInset = 4;
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

  /// A flag planted on a card site (`SiteMark.flag`), map units, and where
  /// its pole's foot sits in that box (the art's 16 × 22 box has it at
  /// 2.5, 21).
  static const Size siteFlag = Size(6.3, 8.6);
  static const Offset siteFlagFoot = Offset(1, 8.2);
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

  /// The known-card speed tag (`KnownSpeedTag`), on Home.
  static const double knownSpeedFont = 12;
  static const double knownSpeedNumber = 14;
  static const double knownSpeedTrendIcon = 11;
  static const double knownSpeedGap = 4;

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
  static const Alignment journeyBalloonSpeaker = Alignment(1.9, -0.3);

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
  static const Alignment heroBalloonSpeaker = Alignment(1.8, -0.5);

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
  static const double rowSubFont = 12;
  static const double untrackedFont = 12;
  static const double untrackedTracking = 0.08;
  static const EdgeInsets untrackedPadding = EdgeInsets.fromLTRB(5, 1, 5, 2);
  static const double untrackedGap = 4;
}

/// The Stats screen (spec phone 6): the archipelago map, its legend, the
/// slowest-island panel, and the Runs list.
abstract final class StatsLayout {
  static const double segHeight = 36;
  static const double segPadding = 12;
  static const double segFont = 13;

  static const double summaryFont = 13.5;
  static const double summaryNumberFont = 15;

  /// Small corner cuts on the map panel (eyeballed from the spec's `data-pts`).
  static const double mapCut = 8;

  static const double legendHeight = 58;
  static const EdgeInsets legendPadding = EdgeInsets.fromLTRB(12, 7, 12, 0);
  static const double legendHeadingFont = 12;
  static const double legendRowGap = 5;
  static const double legendFont = 12.5;
  static const double legendSwatch = 14;
  static const double legendSwatchBorder = 1.6;
  static const double legendItemGap = 4;

  /// The slowest-island panel is laid out with [Positioned] (not a `Column`)
  /// so its fixed [focusHeight] can never overflow: each element sits at its
  /// own `top`, sized to its own content.
  static const double focusHeight = 152;
  static const double focusCut = 6;
  static const EdgeInsets focusPadding = EdgeInsets.fromLTRB(14, 12, 14, 12);
  static const double focusNameTop = 26;
  static const double focusNameFont = 40;
  static const double focusSpeedFont = 17;
  static const EdgeInsets focusSpeedPadding = EdgeInsets.fromLTRB(7, 2, 7, 3);
  static const double focusLineTop = 70;
  static const double focusLineFont = 13;
  static const double focusButtonTop = 86;
  static const Placement focusTobi = Placement(right: 6, top: 4, size: Size(70, 84));
  static const Placement focusBalloon = Placement(right: 66, top: 10, size: Size(96, 52));
  static const Alignment focusBalloonSpeaker = Alignment(1.5, 0.4);
  static const double focusBalloonFont = 13;

  static const double playButtonHeight = 40;
  static const EdgeInsets playButtonPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double playButtonFont = 14;

  static const double runRowSpeedFont = 18;
  static const double runRowDateFont = 12.5;
}

/// Small charts shared by the island list (a per-card sparkline) and the card
/// detail screen (the attempt scatter and the forgetting curve).
abstract final class ChartStyle {
  static const double sparklineWidth = 96;
  static const double sparklineHeight = 24;
  static const double dotRadius = 2.6;
  static const double dotStroke = 1;
  static const double missSize = 4.2;
  static const double missStroke = 1.6;
  static const double bestStarRadius = 7;
  static const double bestStarStroke = 1.4;
  static const double lineStroke = 1.8;
  static const double bandOpacity = 0.55;
  static const double axisPad = 0.08;

  /// Opacity of a toggled-off series tile (spec's `aria-pressed=false`).
  static const double dimOpacity = 0.45;
}

/// The island detail screen (spec phone 7): the zoomed mini-map, this
/// island's stat summary, the sort chips and the scrollable card list.
abstract final class IslandDetailLayout {
  static const double titleFont = 26;
  static const double subFont = 12.5;

  static const double heroHeight = 150;
  static const double heroCut = 8;
  static const double heroMapMargin = 22;
  static const double mapWidth = 150;
  static const EdgeInsets summaryPadding = EdgeInsets.fromLTRB(12, 10, 12, 10);
  static const double summaryLabelFont = 12;
  static const double summaryAvgFont = 25;
  static const double summaryAvgUnitFont = 14;
  static const EdgeInsets summaryAvgPadding = EdgeInsets.fromLTRB(7, 2, 7, 3);

  static const double distHeight = 14;
  static const double distBorder = 1.5;
  static const double dueLineFont = 13;

  static const double sortButtonFont = 13;
  static const EdgeInsets sortButtonPadding = EdgeInsets.fromLTRB(11, 4, 11, 5);

  static const double rowHeight = 82;
  static const double rowImageWidth = 42;
  static const double rowKimarijiFont = 21;
  static const double rowDueFont = 11.5;
  static const EdgeInsets rowDuePadding = EdgeInsets.fromLTRB(6, 1, 6, 2);
  static const double rowSpeedFont = 16;
  static const double rowSpeedSmallFont = 11.5;
  static const EdgeInsets rowSpeedPadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
}

/// The card detail screen (spec phone 8): the card's own header, the mode
/// filter, the attempt chart and its toggleable stat tiles, and the FSRS
/// memory panel.
abstract final class CardDetailLayout {
  static const double topBarHeight = 40;
  static const double crumbFont = 13.5;
  static const double orientationFont = 12;
  static const double orientationHeight = 30;
  static const double orientationPadding = 10;

  static const double cardImageWidth = 104;
  static const double kimarijiFont = 44;
  static const double kimarijiCaptionFont = 11.5;
  static const double bestWidth = 92;
  static const double bestLabelFont = 11.5;
  static const double bestValueFont = 18;

  static const double kamiFont = 13.5;
  static const double authorFont = 12.5;

  static const double modeFont = 13;

  static const double chartHeight = 190;
  static const EdgeInsets chartPadding = EdgeInsets.fromLTRB(8, 10, 8, 20);

  static const double seriesTileValueFont = 15;
  static const double seriesTileLabelFont = 11;
  static const EdgeInsets seriesTilePadding = EdgeInsets.fromLTRB(8, 5, 8, 6);
  static const double seriesSwatchHeight = 4;

  static const double memPadding = 12;
  static const double memHeadingFont = 12.5;
  static const double memGridLabelFont = 11.5;
  static const double memGridValueFont = 19;
  static const EdgeInsets memGridPadding = EdgeInsets.fromLTRB(9, 4, 9, 5);
  static const double curveHeight = 52;

  static const double balloonFont = 13;
  static const Alignment balloonSpeaker = Alignment(1.3, -0.2);
  static const double tobiWidth = 60;
  static const double tobiHeight = 72;
}

/// The rank ladder screen (spec phone 9): nine class rungs running top to
/// bottom from A級 down to 入門, each a step of the class's colour
/// progression, with the player's own rung, the next threshold and every
/// cleared class marked, plus a rank-up preview reachable from the next rung.
abstract final class RankLayout {
  static const double ratingLabelFont = 12;
  static const double ratingLabelTracking = 0.14;
  static const double ratingFont = 26;

  static const double rungHeight = 84;
  static const double rungGap = 8;
  static const EdgeInsets rungPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 8);

  static const EdgeInsets badgePadding = EdgeInsets.fromLTRB(10, 5, 10, 6);
  static const double badgeFont = 22;
  static const double badgeSuffixFont = 13;

  static const double tagLabelFont = 11;
  static const double tagLabelTracking = 0.14;
  static const double tagNumberFont = 17;
  static const EdgeInsets tagPadding = EdgeInsets.fromLTRB(8, 3, 8, 4);

  static const double topNoteFont = 12.5;
  static const double topNoteTracking = 0.18;

  static const double stampFont = 14;
  static const EdgeInsets stampPadding = EdgeInsets.fromLTRB(8, 4, 8, 5);
  static const double stampTurn = -11;
  static const double stampRadius = 5;
  static const double stampRight = 20;

  static const Placement tobiPlacement = Placement(right: -4, top: -18, size: Size(58, 70));
  static const Placement balloonPlacement = Placement(right: 50, top: -20, size: Size(96, 46));
  static const double balloonFont = 12.5;
  static const Alignment balloonSpeaker = Alignment(1.5, 0.6);

  static const double previewGap = 8;
  static const double previewFont = 12.5;
  static const EdgeInsets previewPadding = EdgeInsets.fromLTRB(10, 4, 10, 5);

  /// The small "Rank ›" entry point in the Stats header.
  static const double statsEntryIconSize = 14;
}

/// Play, mid-run (spec phone 4).
abstract final class PlayLayout {
  static const double toneBandHeight = 230;

  static const double chipHeight = 48;
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(14, 0, 15, 0);
  static const double chipRadius = 24;
  static const double chipKanaFont = 23;
  static const double chipBracketFont = 20;
  static const double chipTimeFont = 15;
  static const double chipTimeUnitFont = 12;
  static const double chipGap = 6;
  static const Size chipTail = Size(13, 13);
  static const Offset chipTailAt = Offset(24, 6);
  static const Duration chipBumpDuration = Duration(milliseconds: 260);
  static const double chipBumpScale = 1.08;

  static const double counterHeight = 48;
  static const EdgeInsets counterPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double counterNumberFont = 28;
  static const double counterSlashFont = 15;
  static const double counterOutline = 1.2;
  static const double counterGap = 6;

  static const double buttonRowHeight = 62;
  static const double buttonGap = 14;
}

/// Results (spec phone 5) and its celebration overlays.
abstract final class ResultsLayout {
  static const double topBarHeight = 44;
  static const double splashHeight = 268;
  static const double splashCut = 28;
  static const splashBurst = BurstSpec(
      box: Size(370, 268), center: Offset(185, 132), count: 170, innerMin: 94, innerMax: 128, width: 4, seed: 5);
  static const double splashLabelFont = 13;
  static const double splashLabelTracking = 0.2;
  static const double splashTimeFont = 48;
  static const double splashTimeOutline = 11;
  static const double splashPartialFont = 28;
  static const double splashPbFont = 14;
  static const EdgeInsets splashPbPadding = EdgeInsets.fromLTRB(10, 4, 10, 5);
  static const double splashPbNoteFont = 13;
  static const double splashSumFont = 13;
  static const EdgeInsets splashSumPadding = EdgeInsets.fromLTRB(9, 3, 9, 4);
  static const Placement splashTobi = Placement(right: 8, bottom: -34, size: Size(66, 80));

  static const double statLabelFont = 12;
  static const double statLabelTracking = 0.16;
  static const double statBigFont = 32;
  static const double statBigUnitFont = 17;
  static const double statNoteFont = 12.5;

  /// The known-card speed note (`_KnownSpeedNote`), under the splash header.
  static const double knownSpeedNoteFont = 12.5;
  static const double knownSpeedTrendIcon = 11;
  static const double knownSpeedGap = 4;

  static const EdgeInsets toughPadding = EdgeInsets.fromLTRB(14, 12, 12, 12);
  static const double toughHeadingFont = 30;
  static const double toughLabelFont = 13;
  static const double toughNoteFont = 12;
  static const double toughHeaderWidth = 90;
  static const double toughCardWidth = 68;
  static const double toughTimeFont = 14;
  static const double toughTimeUnitFont = 11;
  static const EdgeInsets toughTimePadding = EdgeInsets.fromLTRB(5, 2, 5, 3);
  static const double toughKimarijiFont = 12.5;

  static const double actionRowHeight = 58;
  static const double guestNoteFont = 13;

  /// The confusable-siblings heads-up (a 決まり字 look-alike warning).
  static const int confusableMaxSiblings = 2;
  static const double confusableTitleFont = 26;
  static const double confusableCardWidth = 96;
  static const double confusableKimarijiFont = 15;
  static const Placement confusableTobi = Placement(right: 18, bottom: 4, size: Size(70, 86));

  static const double rankTitleFont = 88;
  static const double rankTitleOutline = 15;
  static const double rankBandFont = 19;
  static const double rankOldFont = 15;
  static const double rankOldLabelFont = 12;
  static const double rankNewFont = 40;
  static const double rankNewLabelFont = 12;
  static const double rankRateFont = 18;
  static const double rankRateSmallFont = 12.5;
  static const Placement rankTobi = Placement(right: 22, bottom: 4, size: Size(74, 92));

  static const double goalTitleFont = 30;
  static const double goalNoteFont = 14;
  static const Placement goalTobi = Placement(right: 18, bottom: 4, size: Size(70, 86));

  static const Duration overlayFade = Duration(milliseconds: 220);
  static const Duration overlayStagger = Duration(milliseconds: 500);
}

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

  /// ババーン!! over the shout's lower right, from the header's top right.
  static const String bang = 'ババーン!!';
  static const double bangTop = 80;
  static const double bangRight = 0;
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
  static const double labelFont = 12;
  static const double labelTracking = 0.12;
  static const double labelGap = 10;
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
  static const double titleOutline = 16;
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
  static const double nextPad = 8;
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
  static const double balloonTitle = 18;
  static const double balloonBody = 14.5;
  static const double balloonSmall = 12;
  static const double balloonGap = 4;
  static const Alignment balloonSpeaker = Alignment(-1.65, 0);
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

  /// Tobi as the sprint choice's illustration (Tobi's 84:100 box).
  static const Size sprintTobi = Size(88, 105);
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

/// "Learn next cards": the button (journey Home, Results) and its
/// shaky-cards warning, which borrows [GuestSheetStyle]'s sheet.
abstract final class LearnNextStyle {
  static const double height = 38;
  static const double resultsHeight = 44;
  static const double font = 14;
  static const double icon = 18;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 12);
  static const double iconGap = 6;

  /// Room between the known-speed tag and the button on journey Home, and
  /// between their lines when they wrap.
  static const double spacing = 8;
}

/// The stand-in for screens still being built.
abstract final class ComingSoonStyle {
  static const Size box = Size(300, 220);
  static const Placement tobi = Placement(left: 20, bottom: 0, size: Size(120, 143));
  static const Placement balloon = Placement(right: 0, top: 0, size: Size(150, 80));
  static const Alignment speaker = Alignment(-1.9, 2.7);

  /// The balloon popping out of a control that is not built yet
  /// (`ComingSoonBubble`): its size, the gap to the control (the tail
  /// bridges it), how long it stays, and how it pops in and fades.
  static const Size bubble = Size(150, 64);
  static const double bubbleGap = 12;
  static const Duration bubbleLife = Duration(milliseconds: 1600);
  static const Duration bubbleFade = Duration(milliseconds: 260);
  static const bubblePop =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 320), curve: Entrances.springy);
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

/// A CSS-style `from` keyframe: the state an element enters from before
/// settling at rest. Opacity reaches 1 at [opaqueAt] of the eased progress.
@immutable
class EntranceFrom {
  const EntranceFrom({this.opacity = 0, this.scale = 1, this.turnDeg = 0, this.offset = Offset.zero, this.opaqueAt = 1});
  final double opacity, scale, turnDeg;
  final Offset offset;
  final double opaqueAt;
}

/// One element's entrance on a celebration's timeline: [from] to rest over
/// [duration], starting [delay] after the page appears.
@immutable
class EntranceSpec {
  const EntranceSpec(this.from, {required this.duration, this.delay = Duration.zero, this.curve = Curves.ease});
  final EntranceFrom from;
  final Duration duration, delay;
  final Curve curve;

  Duration get end => delay + duration;
}

/// The spec's entrance keyframes and easing curves (`@keyframes` in
/// final.html).
abstract final class Entrances {
  static const flin = EntranceFrom(scale: 1.35);
  static const flash = EntranceFrom(scale: 0.4);
  static const slam = EntranceFrom(scale: 1.9, turnDeg: -7);
  static const rise = EntranceFrom(offset: Offset(0, 70), scale: 0.82);
  static const slideL = EntranceFrom(offset: Offset(-60, 0));
  static const pop = EntranceFrom(scale: 0.4);
  static const up = EntranceFrom(offset: Offset(0, 22));
  static const isrise = EntranceFrom(scale: 0.15, opaqueAt: 0.3);

  static const settle = Cubic(0.2, 0.8, 0.2, 1);
  static const springy = Cubic(0.2, 1.5, 0.4, 1);
  static const bouncy = Cubic(0.2, 1.6, 0.4, 1);
  static const lift = Cubic(0.15, 0.9, 0.25, 1.12);
  static const glide = Cubic(0.2, 0.9, 0.3, 1);
  static const swell = Cubic(0.2, 1.4, 0.4, 1);
}

/// "A new card appears" (spec phone 5): entrance timeline and the flick that
/// sends the card off when the player accepts it.
abstract final class NewCardMotion {
  static const lines = EntranceSpec(Entrances.flin, duration: Duration(milliseconds: 550), curve: Entrances.settle);
  static const flash = EntranceSpec(Entrances.flash,
      duration: Duration(milliseconds: 700), delay: Duration(milliseconds: 120), curve: Curves.easeOut);
  static const shout = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 50), curve: Entrances.springy);
  static const card = EntranceSpec(Entrances.rise,
      duration: Duration(milliseconds: 650), delay: Duration(milliseconds: 220), curve: Entrances.lift);
  static const info = EntranceSpec(Entrances.slideL,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 550), curve: Entrances.glide);
  static const sfx = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 400), curve: Entrances.bouncy);
  static const tobi = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 700), curve: Entrances.bouncy);
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 800), curve: Entrances.springy);

  /// Background once the entrance is over: the glow and focus lines throb.
  static const throbPeriod = Duration(milliseconds: 1600);
  static const double glowThrob = 0.07;
  static const double linesThrob = 0.025;

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
  static const sfx = NewCardMotion.sfx;
  static const tobi = NewCardMotion.tobi;
  static const next = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 450), delay: Duration(milliseconds: 800), curve: Entrances.glide);
  static const rising = EntranceSpec(Entrances.isrise,
      duration: Duration(milliseconds: 1100), delay: Duration(milliseconds: 1000), curve: Entrances.swell);
  static const actions = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1100), curve: Entrances.springy);
}

/// The confetti rain on the island-complete page (`ConfettiRain`), in the
/// spec's px.
abstract final class Confetti {
  static const int count = 30;
  static const int seed = 77;
  static const List<Color> colors = [
    Palette.pink,
    Palette.sun,
    Palette.land,
    Palette.paper,
    Palette.sea,
    Color(0xFFFF9A2E),
  ];

  /// Pieces are scattered across this width and scaled to the actual one.
  static const double specWidth = 390;
  static const double fall = 600;
  static const double drift = 90;
  static const double stroke = 2;

  /// Seconds.
  static const double minDuration = 2.2, durationRange = 1.8;
  static const double maxDelay = 2.4;
  static const double minTurns = 1, turnsRange = 1.5;
  static const Size minSize = Size(9, 12);
  static const Size sizeRange = Size(7, 8);

  /// Every this-many pieces is round.
  static const int roundEvery = 3;
}
