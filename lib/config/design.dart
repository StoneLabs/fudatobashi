import 'dart:ui' show lerpDouble;

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
  static const orange = Color(0xFFFF9A2E);
  static const sunSoft = Color(0xFFFFF4BF);
  static const violet = Color(0xFF9A5BC2);
  static const violetSoft = Color(0xFFF1E6F7);
  static const violetDeep = Color(0xFF6E2C8C);

  /// Alarm red, for warnings, and its darker flash.
  static const alarm = Color(0xFFE8202A);
  static const alarmDeep = Color(0xFFB0101C);

  /// Torifuda colours as used in illustrations (Tobi, pips, fanned cards).
  static const cardFrame = Color(0xFF6A9354);
  static const cardPaper = Color(0xFFEAEAEA);

  /// The start card's black lacquer, gold leaf and vermilion (朱).
  static const lacquer = Color(0xFF120E0D);
  static const lacquerGlow = Color(0xFF3B2923);
  static const gold = Color(0xFFD8B25A);
  static const goldLight = Color(0xFFF7E4A3);
  static const goldDeep = Color(0xFF8E6B26);
  static const vermilion = Color(0xFFD13A22);
  static const vermilionDeep = Color(0xFF8F2012);

  /// Speed tiers, fastest first (see [SpeedTiers]).
  static const tiers = [sun, orange, pink, violetDeep];
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

/// A gradation tone (階調トーン): the dots of a [ToneSpec] lattice swell
/// along the line from [begin] to [end], through [radii] at [stops], the way
/// a manga page fades a tone in.
@immutable
class GradationSpec {
  const GradationSpec({
    required this.dot,
    required this.spacing,
    required this.begin,
    required this.end,
    required this.radii,
    this.stops = const [0, 1],
    this.phase = 0.5,
  });

  final Color dot;
  final double spacing;
  final Alignment begin;
  final Alignment end;

  /// One radius per stop.
  final List<double> radii;
  final List<double> stops;
  final double phase;

  /// The dot radius a fraction [t] of the way from [begin] to [end].
  double radiusAt(double t) {
    if (t <= stops.first) return radii.first;
    for (var i = 1; i < stops.length; i++) {
      if (t <= stops[i]) return radii[i - 1] + (radii[i] - radii[i - 1]) * (t - stops[i - 1]) / (stops[i] - stops[i - 1]);
    }
    return radii.last;
  }

  @override
  bool operator ==(Object other) =>
      other is GradationSpec &&
      other.dot == dot &&
      other.spacing == spacing &&
      other.begin == begin &&
      other.end == end &&
      listEquals(other.radii, radii) &&
      listEquals(other.stops, stops) &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(dot, spacing, begin, end, Object.hashAll(radii), Object.hashAll(stops), phase);
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

  /// Gradation tones smaller than this radius are left out.
  static const double gradationMinRadius = 0.15;

  /// Gradation images kept for reuse (one per box size and pixel density).
  static const int gradationCacheSize = 3;

  /// Home's backdrop, behind its panels and buttons: sun dots under the
  /// header that fade out down the screen and swell again toward the tab bar.
  static const home = GradationSpec(
    dot: Palette.sun,
    spacing: groundSpacing,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    radii: [1.3, 0.3, 0, 0.5, 1.3],
    stops: [0, 0.13, 0.3, 0.6, 1],
  );

  /// Home's backdrop in the sea's blue, bare at the top and swelling toward
  /// the bottom, behind 暗記練's page.
  static const homeSea = GradationSpec(
    dot: Palette.sea,
    spacing: groundSpacing,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    radii: [0, 0, 0.5, 1.3],
    stops: [0, 0.3, 0.6, 1],
  );
  static const double groundSpacing = 6;
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

  /// Brush lettering, cut down to the start card's few characters
  /// (`scripts/joka_font.sh`).
  static const joka = 'Joka';
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

  /// Recorded torifuda glyph layers: a full 暗記練 field (50 cards) and a
  /// few more.
  static const int torifudaGlyphs = 64;
}

abstract final class TabBarStyle {
  static const double lineHeight = 1.15;
  static const double height = 62;
  static const double gap = 8;
  static const double icon = 21;
  static const double iconGap = 4;
  static const double label = 14;

  /// How much of a blocked tile's icon and label shows through.
  static const double blockedOpacity = 0.4;
}

/// A locked tab's chains and padlock (`TabChains`), and how they break
/// when the tab opens.
abstract final class TabLockStyle {
  static const Color steel = Color(0xFFA9B0B8);
  static const Color steelLight = Color(0xFFE6EAEE);

  /// The chain: a link every [link] px, each [linkLength] long so they
  /// overlap, [linkWidth] wide lying flat and [linkEdge] seen edge-on.
  static const double link = 9;
  static const double linkLength = 12;
  static const double linkWidth = 6;
  static const double linkEdge = 2.6;
  static const double linkStroke = 1.6;
  static const double linkShineInset = 1.9;

  /// How far the crossed chains reach past the tile's corners.
  static const double chainReach = 4;

  /// The padlock over the tile's icon: its body, the shackle's radius and
  /// thickness, and where it floats (an [Alignment] in the tile).
  static const Size lockBody = Size(24, 18);
  static const double lockRadius = 3.5;
  static const double shackle = 7;
  static const double shackleWidth = 3.4;
  static const double keyhole = 2.6;
  static const Alignment lockAt = Alignment(0, -0.22);

  /// The padlock bobs by [bob] px and rocks by [rockDeg] each [bobPeriod].
  static const Duration bobPeriod = Duration(milliseconds: 1800);
  static const double bob = 2.5;
  static const double rockDeg = 5;

  /// The break: the padlock rattles until [snapAt] (share of [breakTime]),
  /// then its shackle flips open and everything falls away, flung out at
  /// [fling] px/s, pulled down at [gravity] px/s² and spinning at [spin]
  /// rad/s, while [sparks] focus lines burst out to [sparkReach] px.
  static const Duration breakTime = Duration(milliseconds: 1000);
  static const double snapAt = 0.22;
  static const double rattle = 2.2;
  static const double rattleHz = 18;
  static const double shackleOpenDeg = 50;
  static const double fling = 130;
  static const double gravity = 1400;
  static const double spin = 5;
  static const double chainSpin = 1.7;
  static const int sparks = 12;
  static const double sparkFrom = 12;
  static const double sparkReach = 46;
  static const double sparkLength = 16;
  static const double sparkWidth = 2.6;

  /// Tobi's balloon on a tapped locked tab.
  static const Size balloon = Size(200, 92);
  static const Duration balloonLife = Duration(milliseconds: 2600);
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

/// The kimariji speaker button (`KimarijiSpeakerButton`): a round sun ink
/// button, a full touch target around a slightly smaller disc.
abstract final class VoiceLayout {
  static const double speakerTarget = 48;
  static const double speakerDisc = 42;
  static const double speakerIcon = 22;
  static const double speakerStroke = 2.4;
}

/// A card's kimariji as one unit (`KimarijiHeading`, new-card page and card
/// detail): the KIMARIJI tag over the kimariji, the speaker right after it.
/// Each screen sets the kimariji's own size.
abstract final class KimarijiHeadingStyle {
  static const double tagFont = 11;
  static const double tagGap = 7;

  /// Between the romaji and the kana under it.
  static const double kanaGap = 2;
  static const double speakerGap = 6;
}

abstract final class LangToggleStyle {
  static const double height = 34;
  static const double padding = 11;
  static const double font = 12.5;
}

/// The language list shared by the first-open picker and Settings' Language
/// row (`LanguageCard`, `LanguageScreen`, `LanguagePickerScreen`).
abstract final class LanguageLayout {
  static const double cardHeight = ButtonMetrics.rowHeight;
  static const double cardFont = TypeScale.button;
  static const double pickerTopGap = 32;
  static const double pickerTobiHeight = 120;
  static const double pickerTitleFont = 22;
}

/// Home's level readout, where the language toggle used to sit: the level
/// itself is the button that opens My Profile (see `LevelButton`).
abstract final class LevelButtonStyle {
  static const double height = LangToggleStyle.height;
  static const double padding = 12;
  static const double font = 15;
}

/// My Profile (opened from Home's level button): Tobi's welcome, rank,
/// learned/well-remembered counts, level progress and the first-swipe line.
abstract final class ProfileLayout {
  static const double tobiWidth = 76;
  static const double tobiHeight = 90;
  static const double greetingFont = 14;
  static const double statLabelFont = 13;
  static const double statNumberFont = 20;
  static const double levelFont = 28;
  static const double levelBarHeight = 14;

  /// The side trips' ranks under the main one, smaller: a class badge, the
  /// trip's name and its rating.
  static const double tripGap = 8;
  static const double tripLabelFont = 11;
  static const double tripLabelTracking = 0.14;
  static const double tripBadgeFont = 15;
  static const double tripBadgeSuffixFont = 10;
  static const EdgeInsets tripBadgePadding = EdgeInsets.fromLTRB(7, 3, 7, 4);
  static const double tripNameFont = 18;
  static const double tripRatingFont = 20;
  static const double tripUnrankedFont = 14;
}

abstract final class TagStyle {
  static const double lineHeight = 1.15;
  static const double bannerLineHeight = 1.2;
  static const double font = 12;
  static const double tracking = 0.12;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(10, 5, 10, 5);
  static const EdgeInsets compactPadding = EdgeInsets.fromLTRB(8, 3, 8, 4);

  /// The skewed display-font banner (TRAINING, WELCOME ABOARD), and its
  /// other-language sub's size as a share of its own.
  static const double bannerFont = 15;
  static const double bannerTracking = 0.16;
  static const double bannerSubScale = 0.7;
  static const EdgeInsets bannerPadding = EdgeInsets.fromLTRB(12, 5, 11, 6);
}

/// Furigana (`RubyText`): readings above their kanji.
abstract final class RubyStyle {
  /// Reading size as a fraction of the base text's.
  static const double readingScale = 0.55;
  static const double readingHeight = 1;
  static const double readingGap = 1;
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

  /// A sub-label under the lettering, and how far both keep off the sides.
  static const double subFont = 11;
  static const double subGap = 3;
  static const double subInset = 18;

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

  /// Width over height of Tobi's box.
  static const double aspect = 84 / 100;
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

  static const EdgeInsets progressPadding = EdgeInsets.fromLTRB(12, 6, 12, 8);
  static const double islandTitle = 20;
  static const double nowFont = 12;
  static const EdgeInsets nowPadding = EdgeInsets.fromLTRB(6, 1, 6, 1);
  static const double learnedFont = 14;
  static const double learnedNumber = 18;
  static const double pipWidth = 21;
  static const double pipHeight = 24;
  static const double pipAspect = pipHeight / pipWidth;
  static const double pipGap = 6;
  static const double pipTop = 8;
  static const double pipRadius = 3;
  static const double pipInset = 3;

  /// The known-card speed tag (`KnownSpeedTag`), on Home.
  static const double knownSpeedFont = 12;
  static const double knownSpeedNumber = 14;
  static const double knownSpeedTrendIcon = 11;
  static const double knownSpeedGap = 4;

  /// Above the known-card speed under the journey's card pips.
  static const double pipsSpeedGap = 8;

  /// Today's plan beside Learn ahead: two tight lines.
  static const double planLineHeight = 1.1;

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

  /// A button beside the hero's narration (journey's Learn ahead): its
  /// smallest and largest share of the row.
  static const double heroBesideMinShare = 0.3;
  static const double heroBesideMaxShare = 0.42;
  static const double heroBesideGap = 8;

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

  /// The free-play and 苦手 panels under the hero; free play, one of the
  /// main ways in besides 修行, takes the wider share.
  static const double modeHeight = 124;
  static const double modeSlant = 22;
  static const double modeGutter = 10;

  /// Where the free-play panel ends, as a fraction of the row width.
  static const double modeSplit = 204 / 358;
  static const double nigateTextLeft = 16;
  static const double modeTitleGap = 1;
  static const double modeNoteGap = 2;
  static const double modeTitle = 25;
  static const double modeSub = 15;
  static const double modeNote = 12.5;
  static const Offset modeTextAt = Offset(14, 30);
  static const double modeIcon = 34;
  static const Offset modeIconAt = Offset(150, 30);
  static const Offset modeBadgeAt = Offset(104, 22);

  /// The slim guest bar under the known-mode panels.
  static const double guestHeight = 40;
  static const EdgeInsets guestPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
  static const double guestIcon = 20;
  static const double guestChevron = 16;
  static const double guestTitle = 14;
  static const double guestSub = 12.5;

  static const double rowJpFont = 17;
  static const double rowLineHeight = 1.1;
  static const double rowSubFont = 12;
  static const double untrackedFont = 12;
  static const double untrackedTracking = 0.08;
  static const EdgeInsets untrackedPadding = EdgeInsets.fromLTRB(5, 1, 5, 2);
  static const double untrackedGap = 4;
}

/// Journey Home's today box (`TodayBox`): today's set as one bar, in the
/// slanted panel between the map and the hero. Its height is fixed, so the
/// map keeps its size; text that grows with the font scale shrinks to fit.
abstract final class TodayBoxLayout {
  static const double height = 137.6;
  static const double headerHeight = 38;
  static const double barHeight = 22;
  static const double legendHeight = 29;
  static const double sectionGap = 7;

  /// The largest font scale its text follows: as much as a legend row holds.
  static const double maxTextScale = legendRow / legendFont;

  /// "Today:", the total in looks and "cards in one run". The two labels
  /// shrink (down to [minLabelScale]) before the whole line does.
  static const double labelFont = 12.5;
  static const double labelLineHeight = 1.08;
  static const double number = 36;
  static const double numberLineHeight = 38 / 36;
  static const double headerGap = 7;
  static const double todayGap = 5;
  static const double minLabelScale = 0.75;

  /// Segments are split by hairlines and never narrower than [minSegment].
  static const double barBorder = Strokes.control;
  static const double barSeparator = Strokes.hairline;
  static const double minSegment = 5;

  /// The legend: two rows of two cells, each a swatch, a label and a number.
  static const double legendRow = 14;
  static const double legendColumnGap = 12;
  static const double legendFont = 12;
  static const double legendNumber = 13.5;
  static const double valueGap = 4;
  static const double swatch = 11;
  static const double swatchBorder = 1.8;
  static const double swatchGap = 5;

  /// Diagonal sun and paper stripes of the paused new cards' swatch.
  static const double hatch = 2;
  static const Color pausedText = Color(0xFF666666);

  /// Week stamps: circles with their weekday under them. The ring sizes are
  /// shares of the circle.
  static const double stamp = 15;
  static const double stampGap = 4;
  static const double stampBorder = 0.12;
  static const double missedBorder = 0.1;
  static const double todayRing = 0.15;
  static const double todayRingOuter = 0.24;
  static const double check = 11;
  static const double checkStroke = 4.4;
  static const double weekdayGap = 2.5;
  static const double weekdayFont = 8.5;
  static const double weekdayHeight = 9;

  /// The 本日完了 hanko of a done day, centred over the bar: its centre this
  /// far below the top of the inside, a paper face and a double rule.
  static const double doneStampCenter = 56;
  static const double doneStampFont = 25;
  static const double doneStampTracking = 0.06;
  static const double doneStampTurn = -7;
  static const double doneStampBorder = Strokes.button;
  static const double doneStampRule = 2;
  static const double doneStampInnerRule = 1.6;
  static const double doneStampPaper = 0.86;
  static const double doneStampRuleOpacity = 0.92;
  static const EdgeInsets doneStampPadding = EdgeInsets.fromLTRB(13, 6, 13, 8);
}

/// The sheet that offers to pause today's new cards when reviews pile up.
abstract final class PauseSheetLayout {
  static const double cut = 14;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(20, 33, 20, 20);
  static const double title = 22;
  static const double sub = 13;
  static const double subGap = 3;
  static const double body = 14;
  static const double bodyLineHeight = 1.45;
  static const double bodyGap = 12;
  static const double note = 12.5;
  static const double noteGap = 4;
  static const double shoutGap = 14;
  static const double shoutHeight = 64;
  static const double shoutFont = 17;
  static const shout = ShoutSpec(spikes: 26, outer: 7);
  static const double keepGap = 8;
  static const double keepHeight = 48;
  static const double keepFont = 15;
  static const double keepSub = 11.5;
  static const double keepSubGap = 8;
  static const Placement tobi = Placement(right: 14, top: -50, size: Size(76, 90));
  static const Color barrier = Color(0x8C141414);
}

/// The Stats screen (spec phone 6): the archipelago map, its legend, and the
/// slowest-island panel.
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

  /// The slowest-island panel: text on the left, Tobi under his balloon
  /// (pointing down at him) in a column on the right.
  static const double focusCut = 6;
  static const EdgeInsets focusPadding = EdgeInsets.fromLTRB(14, 12, 10, 12);
  static const double focusGap = 4;
  static const double focusNameFont = 40;
  static const double focusSpeedFont = 17;
  static const EdgeInsets focusSpeedPadding = EdgeInsets.fromLTRB(7, 2, 7, 3);
  static const double focusLineFont = 13;
  static const double focusButtonGap = 10;
  static const Size focusTobi = Size(62, 74);
  static const Size focusBalloon = Size(92, 50);
  static const Alignment focusBalloonSpeaker = Alignment(0.2, 2.2);
  static const double focusBalloonFont = 13;

  static const double playButtonHeight = 40;
  static const EdgeInsets playButtonPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double playButtonFont = 14;

  /// Locked (not fully uncovered): the lock icon beside the label, and the
  /// balloon explaining why, sized like Home's "Learn ahead" lock.
  static const double playButtonIcon = 16;
  static const double playButtonIconGap = 5;
  static const Size playButtonBalloon = Size(270, 96);
  static const Duration playButtonBalloonLife = Duration(milliseconds: 2800);
}

/// The History tab: each run's mode tag, timestamp, card/miss count and
/// total time, laid out for high contrast — ink on paper, unlike the
/// original app's dim grey-on-green history text.
abstract final class HistoryLayout {
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const double rowDateFont = 12.5;
  static const double rowTimeFont = 18;
  static const EdgeInsets emptyPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}

/// History's header under its title: the record strip summing up the runs
/// on show, and the run-kind filter, a segmented control whose segments wrap
/// into as few rows as fit.
abstract final class HistoryHeaderLayout {
  /// The record strip: a sun-toned panel with its right edge cut in, each
  /// stat a tracked label over its number, split by ink rules.
  static const double stripCut = 14;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(14, 9, 14 + stripCut, 10);
  static const double statLabelFont = 11;
  static const double statLabelTracking = 0.14;
  static const double statGap = 2;
  static const double statFont = 26;
  static const double statRuleInset = 12;

  /// Between the strip and the filter.
  static const double filterGap = 10;
  static const double segmentHeight = 40;
  static const double segmentPadding = 10;
  static const double segmentFont = 13;
}

/// Small charts shared by the island list (a per-card sparkline) and the card
/// detail screen (the attempt chart).
abstract final class ChartStyle {
  static const double sparklineWidth = 96;
  static const double sparklineHeight = 24;
  static const double dotRadius = 2.6;
  static const double lineStroke = 1.8;

  /// Opacity of a toggled-off series tile (spec's `aria-pressed=false`).
  static const double dimOpacity = 0.45;

  /// The attempt chart (spec phone 8). The plot keeps its height; the axis
  /// labels add their own rows around it, so they grow with the font scale.
  static const double plotHeight = 140;
  static const double labelFont = 12;
  static const double tickLabelGap = 6;
  static const double plotTopGap = 5;
  static const double xLabelGap = 6;
  static const double plotRightPad = 12;
  static const Color grid = Color(0xFFE0E0E0);

  static const double attemptDotRadius = 2.9;
  static const double attemptDotRim = 0.9;

  /// A "don't know" marker: a ▽ in the top label row, above its attempt.
  static const Size missMarker = Size(10, 8);
  static const double missMarkerStroke = 1.4;

  static const Color bandFill = Color(0xFFCFE6FF);
  static const Color bandEdge = Color(0xFF7FB8F0);
  static const double bandEdgeStroke = 1;

  static const Color shortAverage = Palette.pink;
  static const double shortAverageStroke = 1.8;
  static const Color midAverage = Palette.ink;
  static const double midAverageStroke = 2.2;
  static const Color longAverage = Palette.violetDeep;
  static const double longAverageStroke = 4.2;
  static const double longAverageHalo = 7.5;

  /// TOP SPEED: a dashed line across the plot, a star on the attempt nearest
  /// to it, and its label beside the star (below the line, above it when the
  /// plot has no room below).
  static const Color topSpeedLine = Palette.landDeep;
  static const Color topSpeedText = Color(0xFF3E6B2C);
  static const double topSpeedStroke = 1.6;
  static const double topSpeedDash = 4;
  static const double starRadius = 9;
  static const double starInnerRatio = 0.45;
  static const double starStroke = 1.1;
  static const double starLabelGap = 12;
  static const double starLabelDrop = 3;

  static const Color latestRing = Palette.pink;
  static const double latestRingRadius = 6;
  static const double latestRingStroke = 2.4;

  /// `DailyChart`: a bar's share of its day's width, the dash of a dashed
  /// line, and the grid's stroke.
  static const double dailyBarShare = 0.6;
  static const double dash = 4;
  static const double gridStroke = 1;
}

/// The island detail screen (spec phone 7): the zoomed mini-map, this
/// island's stat summary, the sort chips and the scrollable card list. The
/// sort chip and card row tokens are shared with the Stats "All" tab
/// (`CardListView`, `CardTile` in `card_list.dart`).
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

  /// The kana under the romaji, in romaji mode.
  static const double kimarijiKanaFont = 16;
  static const double captionFont = 11.5;

  static const double authorFont = 14;

  /// The whole poem under the card, 上の句 then 下の句, with readings.
  static const double poemFont = 16;
  static const double poemLineHeight = 1.25;
  static const double verseGap = 2;

  /// A look-alike (友札) chip: a miniature torifuda, its kimariji, a chevron.
  static const EdgeInsets lookAlikePadding = EdgeInsets.fromLTRB(5, 5, 8, 5);
  static const double lookAlikeCardWidth = 26;
  static const double lookAlikeKimarijiFont = 17;
  static const double lookAlikeChevron = 14;

  static const double modeFont = 13;

  static const EdgeInsets chartPadding = EdgeInsets.fromLTRB(4, 6, 4, 4);
  static const EdgeInsets chartEmptyPadding = EdgeInsets.symmetric(vertical: 40);

  static const double seriesTileValueFont = 15;
  static const double seriesTileLabelFont = 11;
  static const EdgeInsets seriesTilePadding = EdgeInsets.fromLTRB(8, 5, 8, 6);
  static const double seriesSwatchHeight = 4;

  static const double memPadding = 12;
  static const double memHeadingFont = 12.5;

  /// The figures of the speed strip and the memory panel.
  static const double statLabelFont = 11.5;
  static const double statValueFont = 21;
  static const double statSuffixFont = 13;
  static const EdgeInsets statPadding = EdgeInsets.fromLTRB(9, 4, 9, 5);

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

  /// The lock beside the badge of a class still ahead.
  static const double lockIcon = 20;
  static const double lockGap = 10;
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

/// The start card on top of every run's deck (`StartCard`), drawn in the
/// torifuda's card units (374 × 525) and scaled to the card's size.
abstract final class StartCardStyle {
  static const Size size = Size(374, 525);
  static const double radius = 12;

  /// The lacquer's soft glow, brightest at [glowCenter] (an [Alignment]).
  static const Alignment glowCenter = Alignment(-0.35, -0.6);
  static const double glowRadius = 1.25;

  /// The gold frame: a heavy outer line and a fine inner one, with gold
  /// brackets in the inner corners.
  static const double outerFrameInset = 13;
  static const double outerFrameWidth = 4.5;
  static const double innerFrameInset = 23;
  static const double innerFrameWidth = 1.6;
  static const double cornerBracket = 24;
  static const double cornerBracketWidth = 3;
  static const double cornerBracketInset = 5;
  static const List<Color> goldLeaf = [Palette.goldLight, Palette.gold, Palette.goldDeep, Palette.gold];

  static const EdgeInsets padding = EdgeInsets.fromLTRB(40, 40, 40, 38);
  static const double titleFont = 25;
  static const double titleTracking = 0.7;
  static const double titleRule = 58;
  static const double titleRuleGap = 12;
  static const double titleGap = 16;

  /// The 序歌 in 散らし書き (scattered writing): five columns, right to
  /// left, each dropped by its share of a character from the top.
  static const double jokaFont = 42;
  static const double jokaLineHeight = 1.06;
  static const double jokaColumnGap = 13;
  static const List<double> jokaDrops = [0, 1.15, 0.35, 1.5, 0.75];

  /// The seal pressed beside the poem's last column, [sealDrop]
  /// characters down.
  static const String sealText = '飛';
  static const double seal = 42;
  static const double sealRadius = 5;
  static const double sealDrop = 5.2;
  static const double sealFont = 27;
  static const double sealTurnDeg = -6;

  /// The vermilion band with the greeting and the swipe cue.
  static const double bandGap = 18;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(10, 12, 10, 12);
  static const double bandRule = 1.4;
  static const double greetingFont = 27;
  static const double cueGap = 6;
  static const double cueFont = 14;
  static const double cueTracking = 0.26;
  static const String cueMarks = '›';
  static const double cueMarkGap = 10;

  /// A glint sweeping across the lacquer every [sheenPeriod], taking
  /// [sheenSweep] to cross; frozen off the card under reduced motion.
  static const Duration sheenPeriod = Duration(milliseconds: 3600);
  static const Duration sheenSweep = Duration(milliseconds: 1200);
  static const double sheenWidth = 120;
  static const double sheenTurnDeg = 24;
  static const double sheenAlpha = 0.2;
}

/// The tutorial round's practice cards (`TestCard`): a TV test pattern
/// crossed with a karuta card, in the torifuda's card units (374 × 525).
abstract final class TestCardStyle {
  static const Size size = Size(374, 525);
  static const double radius = 12;

  /// Each card's big kana, one per card of the round: テ, ス, ト.
  static const List<String> kana = ['テ', 'ス', 'ト'];

  /// The colour bars (75% SMPTE), then the thin strip of reversed bars
  /// under them.
  static const List<Color> bars = [
    Color(0xFFC0C0C0),
    Color(0xFFC0C000),
    Color(0xFF00C0C0),
    Color(0xFF00C000),
    Color(0xFFC000C0),
    Color(0xFFC00000),
    Color(0xFF0000C0),
  ];
  static const List<Color> reverseBars = [
    Color(0xFF0000C0),
    Palette.ink,
    Color(0xFFC000C0),
    Palette.ink,
    Color(0xFF00C0C0),
    Palette.ink,
    Color(0xFFC0C0C0),
  ];
  static const double inset = 12;
  static const double barsHeight = 318;
  static const double reverseBarsHeight = 30;

  /// The test pattern's circle, with the kana on its crosshair.
  static const Offset circleCenter = Offset(187, 176);
  static const double circleRadius = 112;
  static const double circleStroke = 6;
  static const double crosshairStroke = 2.5;

  /// The inner ring's radius, as a share of the circle's.
  static const double innerRing = 0.68;
  static const double kanaFont = 150;

  /// The channel bug in the bars' lower-left corner (the play chrome
  /// covers the card's top corners).
  static const String channel = 'TOBI TV';
  static const Offset channelAt = Offset(22, 290);
  static const EdgeInsets channelPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const double channelFont = 15;

  /// The label under the bars.
  static const String title = '練習札';
  static const String sub = 'TEST CARD';
  static const double titleFont = 44;
  static const double subFont = 14;
  static const double subTracking = 0.3;
  static const double numberFont = 30;
  static const EdgeInsets labelPadding = EdgeInsets.fromLTRB(26, 0, 26, 8);
}

/// The tutorial round's coach: Tobi below the card with a balloon
/// (`TutorialCoach`).
abstract final class TutorialStyle {
  static const double tobiHeight = 104;
  static const double gap = 4;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(Gaps.gutter, Gaps.small, Gaps.gutter, 0);
  static const Alignment speaker = Alignment(-1.3, 0.35);
  static const EdgeInsets balloonPadding = EdgeInsets.symmetric(vertical: 4);
  static const double font = 14;
  static const Duration linePop = Duration(milliseconds: 220);
  static const double linePopFrom = 0.8;
}

/// Tobi's tour of Home (`TourOverlay`): a greyed-out screen with a
/// spotlight, Tobi large with a balloon, a spray of hand-scribbled arrows
/// and a marquee arrow with chasing bulbs, all pointing at the spot.
abstract final class TourStyle {
  /// The greyed-out wall: lighter near the spotlight, darker at the edges,
  /// fading over [dimReach] of the screen's longer side.
  static const Color dimNear = Color(0xDCD6D9DD);
  static const Color dimFar = Color(0xF0868C94);
  static const double dimReach = 0.95;

  /// The spotlight: its margin around the spot, corner radius, and a paper
  /// ring with an ink line around it.
  static const double spotPad = 6;
  static const double spotRadius = 10;
  static const double spotRing = 7;
  static const double spotInk = 3;

  /// Gaps between the spotlight, the marquee and Tobi's block.
  static const double gap = 10;

  /// Tobi's block (Tobi and his balloon): beside the balloon, at most
  /// [block] tall and at least [blockMin] where room is short; from
  /// [stackAt] up, under a full-width balloon instead, [blockStacked] tall
  /// beside a spotlight with room for it and [blockTall] with none. Tobi
  /// takes [besideTobi] of the block's height beside the balloon, and
  /// [stackedTobi] under it.
  static const double block = 196;
  static const double blockMin = 136;
  static const double stackAt = 250;
  static const double blockStacked = 320;
  static const double blockTall = 390;
  static const double besideTobi = 0.9;
  static const double stackedTobi = 0.56;
  static const Alignment speakerLeft = Alignment(-1.22, 0.38);
  static const Alignment speakerRight = Alignment(1.22, 0.38);
  static const Alignment speakerBelowLeft = Alignment(-0.62, 1.25);
  static const Alignment speakerBelowRight = Alignment(0.62, 1.25);
  static const EdgeInsets balloonPadding = EdgeInsets.symmetric(horizontal: 2, vertical: 2);
  static const double font = 15.5;
  static const double hintFont = 11.5;
  static const double hintGap = 5;
  static const Duration pop = Duration(milliseconds: 380);
  static const double popFrom = 0.6;

  /// Hand-scribbled arrows around the spotlight: up to [scribbles] of
  /// them, [scribbleMin]–[scribbleMax] px long, their tips on
  /// [scribbleRings] (px off the spotlight), turned up to
  /// [scribbleTurnDeg] off square.
  static const int scribbles = 10;
  static const double scribbleMin = 40;
  static const double scribbleMax = 66;
  static const List<double> scribbleRings = [14, 44, 76];
  static const double scribbleTurnDeg = 30;
  static const double scribbleMargin = 9;
  static const List<double> scribbleAlongTop = [0.1, 0.3, 0.5, 0.7, 0.9];
  static const List<double> scribbleAlongSide = [0.25, 0.5, 0.75];

  /// How one is drawn: two marker passes [scribblePass] px apart (the
  /// second thinner), a shaft
  /// bent by up to [scribbleBend] px and a head of two strokes.
  static const Color scribbleInk = Palette.alarm;
  static const double scribbleWidth = 3.8;
  static const double scribbleWidthThin = 2.6;
  static const double scribblePass = 1.7;
  static const double scribbleBend = 7;
  static const double scribbleHead = 19;
  static const double scribbleHeadDeg = 27;

  /// Stop-motion boil: the lines are redrawn every [boil], cycling through
  /// [boilFrames] drawings, each wobbling by up to [boilJitter] px.
  static const Duration boil = Duration(milliseconds: 120);
  static const int boilFrames = 3;
  static const double boilJitter = 1.8;

  /// Each arrow stamps in over [scribbleIn] from [scribbleInFrom] of its
  /// size, [scribbleStagger] after the one before, then jabs at the spot by
  /// [jab] px every [jabPeriod].
  static const Duration scribbleIn = Duration(milliseconds: 170);
  static const Duration scribbleStagger = Duration(milliseconds: 45);
  static const double scribbleInFrom = 1.6;
  static const Duration jabPeriod = Duration(milliseconds: 700);
  static const double jab = 5;

  /// The marquee arrow: a fat red arrow [marqueeLength] long with a head
  /// [marqueeHead] long and [marqueeHeadHeight] tall on a [marqueeBody]
  /// tall body, placed [marqueeShift] px to one side of the spot's centre
  /// in a band [marqueeRoom] tall.
  static const double marqueeLength = 132;
  static const double marqueeHead = 50;
  static const double marqueeHeadHeight = 76;
  static const double marqueeBody = 40;
  static const double marqueeStroke = 3;
  static const double marqueeRoom = 150;
  static const double marqueeShift = 72;
  static const Color marqueeFill = Palette.alarmDeep;
  static const double marqueeFont = 16;

  /// The label is only on a marquee within this of level, so it reads.
  static const double marqueeLabelMaxDeg = 50;

  /// Its light bulbs, [bulbPitch] px apart just inside its outline; every
  /// [chaseEvery]th is lit, and the lit ones move on every [chase].
  static const double bulb = 3.2;
  static const double bulbGlow = 6.5;
  static const double bulbPitch = 12.5;
  static const double bulbInset = 7;
  static const Color bulbOn = Palette.goldLight;
  static const Color bulbOff = Color(0xFF5A3714);
  static const Color bulbHalo = Color(0x66FFE9A0);
  static const Duration chase = Duration(milliseconds: 90);
  static const int chaseEvery = 3;

  /// The typed-out line's still-to-come tail: laid out like the rest, just
  /// invisible, so the balloon never resizes as it types.
  static const Color typingHidden = Color(0x00000000);

  /// A tap that misses the target jolts the arrows [nudgeCycles] times over
  /// [nudgeDuration], decaying from [nudgeAmount] px — cheap (a composited
  /// translate, no repaint) and skipped under reduced motion.
  static const Duration nudgeDuration = Duration(milliseconds: 260);
  static const double nudgeAmount = 10;
  static const double nudgeCycles = 3;

  /// The balloon's continue control (steps with nothing to tap): faded out
  /// and untappable until the line has finished typing.
  static const Duration continueFade = Duration(milliseconds: 200);
}

/// Results (spec phone 5) and its celebration overlays.
abstract final class ResultsLayout {
  static const double topBarHeight = 44;

  /// The dashed "not recorded" / "not counted" note under the top bar.
  static const EdgeInsets notePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const double splashHeight = 268;
  static const double splashCut = 28;
  static const splashBurst = BurstSpec(
      box: Size(370, 268), center: Offset(185, 132), count: 170, innerMin: 94, innerMax: 128, width: 4, seed: 5);
  static const double splashLabelFont = 13;
  static const double splashLabelTracking = 0.2;
  static const double splashTimeFont = 48;
  static const double splashTimeOutline = 11;
  static const double splashPartialFont = 28;
  static const double splashSumFont = 13;
  static const EdgeInsets splashSumPadding = EdgeInsets.fromLTRB(9, 3, 9, 4);

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
  static const int toughCount = 3;
  static const double toughTimeFont = 12;
  static const EdgeInsets toughTimePadding = EdgeInsets.fromLTRB(5, 2, 5, 3);
  static const double toughKimarijiFont = 12.5;

  static const double actionRowHeight = 58;
  static const double guestNoteFont = 13;

  /// The confusable-siblings heads-up (a 決まり字 look-alike warning).
  static const int confusableMaxSiblings = 2;
  static const double confusableTitleFont = 26;
  static const double confusableCardWidth = 96;
  static const double confusableKimarijiFont = 15;
  static const Placement confusableTobi = Placement(right: 18, bottom: tobiAboveCta, size: Size(70, 86));

  static const double goalTitleFont = 30;
  static const double goalNoteFont = 14;
  static const Placement goalTobi = Placement(right: 18, bottom: tobiAboveCta, size: Size(70, 86));

  /// Tobi stands just above a celebration's pinned CTA.
  static const double tobiAboveCta = PlayLayout.buttonRowHeight + Gaps.section * 2;

  static const Duration overlayFade = Duration(milliseconds: 220);
  static const Duration overlayStagger = Duration(milliseconds: 500);
}

/// A personal best on the Results splash (`_TimePanel`): the PERSONAL BEST
/// sticker, ドン!, Tobi, and the previous best with the time saved.
abstract final class PersonalBestLayout {
  static const double stickerFont = 14;
  static const EdgeInsets stickerPadding = EdgeInsets.fromLTRB(10, 4, 10, 5);
  static const double stickerTilt = -2;
  static const double stickerGap = 12;
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(120, 60), count: 36, innerMin: 44, innerMax: 58, width: 4, seed: 41);
  static const Size impactSize = Size(240, 120);
  static const double impactFromScale = 0.5;
  static const double impactToScale = 1.4;

  static const double noteGap = 8;
  static const double noteFont = 13;
  static const EdgeInsets notePadding = EdgeInsets.fromLTRB(6, 1, 6, 2);
  static const double gainGap = 4;
  static const double gainBorder = 2;
  static const EdgeInsets gainPadding = EdgeInsets.fromLTRB(6, 1, 6, 2);

  static const String sfx = 'ドン!';
  static const double sfxFont = 44;
  static const int sfxSeed = 4;
  static const double sfxTurnDeg = -12;
  static const Offset sfxAt = Offset(0, 0);
  static const Placement tobi = Placement(right: 8, bottom: 4, size: Size(58, 70));
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

/// The first-launch screen (spec phone 1).
abstract final class OnboardingLayout {
  static const double topGap = 4;
  static const double bottomGap = 8;

  /// Display lettering (titles, headlines) grows with the system text size
  /// only up to this factor.
  static const double letteringMaxScale = 1.1;

  // The welcome panel. Tobi, the balloon and the sea keep their places from
  // the top, so a shorter panel (down to [skyMinHeight]) crops the sea.
  static const double skyHeight = 344;
  static const double skyMinHeight = 266;
  static const double skyCut = 26;
  static const double title = 50;
  static const double titleOutline = 12;
  static const Offset titleAt = Offset(18, 14);
  static const double titleBannerGap = 4;
  static const double langInset = 10;
  static const Placement tobi = Placement(left: 20, top: 118, size: Size(120, 143));
  static const Placement balloon = Placement(right: 0, top: 130, size: Size(210, 122));
  static const double balloonTitle = 18;
  static const double balloonBody = 14.5;
  static const double balloonSmall = 12;
  static const double balloonGap = 4;
  static const Alignment balloonSpeaker = Alignment(-1.65, 0);

  // The mode choices: at least [choiceHeight] tall, taller at large text.
  static const double choiceHeight = 150;
  static const double choiceCut = 10;
  static const double illustration = 108;
  static const double illustrationInset = 10;
  static const EdgeInsets textInsets = EdgeInsets.fromLTRB(126, 12, 12, 12);
  static const double choiceTitle = 26;
  static const double choiceTitleGap = 5;
  static const double choiceSub = 15;
  static const double choiceSubGap = 3;
  static const double choiceNote = 12.5;
  static const double choiceNoteGap = 4;
  static const double choiceNoteLineHeight = 1.35;

  /// Between a choice's note and its go button.
  static const double goGap = 8;

  static const double noteIcon = 24;
  static const double noteFont = 14;
  static const double noteLineHeight = 1.35;
  static const EdgeInsets notePadding = EdgeInsets.fromLTRB(12, 10, 12, 10);

  // The pace question.
  static const EdgeInsets paceHeaderInsets = EdgeInsets.fromLTRB(14, 12, 10, 16);
  static const double paceHeaderCut = 14;
  static const double paceQuestion = 30;
  static const double paceQuestionOutline = 9;
  static const double paceQuestionGap = 10;
  static const double paceOther = 12.5;
  static const double paceOtherGap = 2;

  // The pace choices, side by side. Each pulls its inner edge in by
  // [paceSlant] at one end, leaving a slanted gutter between them.
  static const double paceSlant = 12;
  static const EdgeInsets paceInsets = EdgeInsets.fromLTRB(12, 12, 12, 8);

  /// Tobi's largest box (84:100); he shrinks to fit the art area, which
  /// gets no shorter than [paceArtMin].
  static const Size paceTobi = Size(147, 175);
  static const EdgeInsets paceTobiPadding = EdgeInsets.fromLTRB(4, 0, 4, 4);
  static const double paceArtMin = 150;

  /// Tobi's line above him: a soft balloon for the relaxed pace, a shout for
  /// the sprint.
  static const double paceCall = 16;
  static const EdgeInsets paceCallPadding = EdgeInsets.symmetric(vertical: 8);
  static const Alignment paceCallSpeaker = Alignment(0, 2);
  static const EdgeInsets paceShoutPadding = EdgeInsets.fromLTRB(18, 16, 18, 16);
  static const sprintShout = ShoutSpec(spikes: 22, outer: 7, inner: 3, seed: 4);

  /// Room between the call and Tobi's head (the balloon's tail).
  static const double paceCallGap = 14;

  /// The caption band along the bottom: headline, subtitle and note.
  static const EdgeInsets paceBandInsets = EdgeInsets.fromLTRB(12, 8, 12, 12);
  static const Color relaxedBand = Palette.seaSoft;
  static const Color sprintBand = Palette.pinkSoft;
  static const double paceFigure = 58;
  static const double paceUnit = 20;
  static const double paceSub = 14.5;
  static const double paceSubGap = 4;
  static const double paceNote = 12.5;
  static const double paceNoteGap = 6;
  static const double paceNoteLineHeight = 1.35;
  static const Color sprintGo = Palette.sun;
}

/// The welcome panel's sea, in the panel's coordinates from its top (see
/// [OnboardingLayout]): a pale far sea from the horizon behind Tobi, the
/// map's sea from [swell] on, Tobi's island under his feet, a boat and the
/// surf along the front. At [OnboardingLayout.skyMinHeight] only the far
/// sea and the island show.
abstract final class WelcomeSeaLayout {
  static const double horizon = 222;
  static const double horizonStroke = Strokes.label;
  static const ToneSpec far = Tones.mapShoal;

  /// Short flat ripples on the far sea, longer nearer the front: one per
  /// [rippleDensity] square px.
  static const int rippleSeed = 11;
  static const double rippleDensity = 700;
  static const double rippleMin = 5;
  static const double rippleMax = 16;
  static const double rippleStroke = 1.5;
  static const double rippleInset = 4;

  /// The top of the map's sea: a long low swell.
  static const double swell = 262;
  static const double swellHeight = 2.5;
  static const double swellLength = 70;
  static const int seaSeed = 5;

  /// A far island standing on the horizon left of Tobi, clear of the balloon.
  static const Rect farIsle = Rect.fromLTRB(0, horizon - 12, 44, horizon);

  /// Tobi's island, its flat under his feet ([OnboardingLayout.tobi]).
  static const Rect isle = Rect.fromLTWH(0, 214, 160, 68);

  /// The boat rocks at anchor over its wake.
  static const Placement boat = Placement(left: 176, top: 254, size: MapStyle.boat);
  static const Rect boatWake = Rect.fromLTWH(170, 280, 48, 9);
  static const double boatTurnDeg = 5;
  static const double boatLift = 1.5;
  static const Duration boatPeriod = Duration(milliseconds: 3800);

  /// The surf's top sits [surfRise] above the panel's bottom, but no higher
  /// than [surfTopMin] (over the island's shore, below Tobi's feet). Its
  /// crests drift in a slow orbit, [surfOrbit] px across and up.
  static const double surfRise = 58;
  static const double surfTopMin = 264;
  static const Offset surfOrbit = Offset(6, 1.5);
  static const Duration surfPeriod = Duration(seconds: 8);
}

/// Onboarding's step change: the pieces of the step on show slide off one
/// side in turn, [stagger] apart, while the next step's pieces slide in from
/// the other.
abstract final class OnboardingMotion {
  static const exit = Duration(milliseconds: 220);
  static const exitCurve = Curves.easeInCubic;
  static const enter = Duration(milliseconds: 300);
  static const enterCurve = Entrances.lift;

  /// The next step starts coming in this long after the old one starts
  /// leaving.
  static const enterDelay = Duration(milliseconds: 150);
  static const stagger = Duration(milliseconds: 45);

  /// Pieces per step: the top panel, two choices, the note row.
  static const int pieces = 4;

  static Duration get length => enterDelay + stagger * (pieces - 1) + enter;
}

/// The 正 tally of the streak: strokes of one 正 in writing order, in a
/// 70 × 32 box holding two characters.
abstract final class Tally {
  static const Size box = Size(70, 32);

  /// Loaded from `assets/svg/tally.svg`, in writing order.
  static late final List<String> strokes;
  static const double glyphAdvance = 38;

  /// 正 characters drawn: the tally stops growing at this many.
  static const int glyphs = 2;
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

/// Free practice (始める): its setup sheet (`free_practice_sheet.dart`), the
/// island / card / 友札 pickers behind it, and the balloon of its lock.
abstract final class FreePracticeLayout {
  static const EdgeInsets sheetPadding = EdgeInsets.fromLTRB(18, 18, 18, 18);
  static const double sheetCut = 14;
  static const Placement tobi = Placement(right: 18, top: -66, size: Size(78, 93));
  static const double title = 30;
  static const double deckFont = 14;
  static const double deckNumber = 22;
  static const double titleGap = 2;

  /// The island / card / 友札 rows.
  static const double rowMinHeight = 46;
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(12, 6, 10, 6);
  static const double rowLabelFont = 15;
  static const double rowValueFont = 13.5;
  static const double rowChevron = 16;
  static const double rowGap = 6;

  /// 隠し字's level chips.
  static const double maskChip = 31;
  static const double maskChipFont = 14;
  static const double maskGap = 4;
  static const double maskNoteFont = 12.5;

  /// The counts / custom strip above the start button.
  static const EdgeInsets statusPadding = EdgeInsets.fromLTRB(10, 7, 8, 8);
  static const double statusNoteFont = 12.5;
  static const double resetMinHeight = 34;
  static const EdgeInsets resetPadding = EdgeInsets.symmetric(horizontal: 9, vertical: 4);
  static const double resetIcon = 15;
  static const double resetFont = 13;
  static const double shoutHeight = 64;
  static const Color barrier = Color(0x8C141414);

  /// Pickers: the header count, hint, section titles and the footer buttons.
  static const double hintFont = 12.5;
  static const double sectionFont = 18;
  static const double sectionGap = 14;
  static const double footerMinHeight = 48;
  static const double footerFont = 15;

  /// A card chip (its kimariji), in the card and 友札 pickers.
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(9, 5, 9, 6);
  static const double chipFont = 16;
  static const double chipSmallFont = 13.5;
  static const EdgeInsets chipSmallPadding = EdgeInsets.fromLTRB(7, 3, 7, 4);
  static const double chipMinHeight = 40;
  static const double chipGap = 6;

  /// The all / some / none box of an island or 友札 set.
  static const double coverageBox = 28;
  static const double coverageIcon = 20;
  static const Size coverageDash = Size(12, 3.5);
  static const EdgeInsets setRowPadding = EdgeInsets.fromLTRB(10, 8, 10, 8);

  /// The island picker's legend.
  static const double legendDot = 12;
  static const double legendFont = 12;
  static const double legendGap = 12;

  static const Size lockBalloon = Size(270, 96);
  static const Duration lockBalloonLife = Duration(milliseconds: 2800);
}

/// Home's "Learn ahead" (`LearnAheadButton`) beside the training hero's
/// narration, and the balloon that says why it is locked.
abstract final class LearnAheadStyle {
  static const double minHeight = 36;
  static const double font = 13;
  static const double icon = 16;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
  static const double iconGap = 5;
  static const Size balloon = Size(270, 96);
  static const Duration balloonLife = Duration(milliseconds: 2800);
}

/// The stand-in for screens still being built.
abstract final class ComingSoonStyle {
  static const Size box = Size(300, 220);
  static const Placement tobi = Placement(left: 20, bottom: 0, size: Size(120, 143));
  static const Placement balloon = Placement(right: 0, top: 0, size: Size(150, 80));
  static const Alignment speaker = Alignment(-1.9, 2.7);
}

/// One picture of a scene: its asset (a lossless 3× render) and where it
/// sits, in the scene's design units (the picture's pixel size ÷ 3).
@immutable
class ScenePiece {
  const ScenePiece(this.asset, this.rect);
  final String asset;
  final Rect rect;
}

/// The dojo scene at the top of the Side Trips tab (`DojoScene`,
/// `research/design/sidetrips_b2.html`): pictures from
/// `assets/images/sidetrips/scene/`, back to front, in a design frame [width]
/// units wide whose top is the screen's top, scaled to the screen's width.
/// The islands stand in a ring (`DojoRingLayout`).
abstract final class DojoSceneLayout {
  static const double width = 390;
  static const _dir = 'assets/images/sidetrips/scene';

  static const sky = ScenePiece('$_dir/sky.webp', Rect.fromLTWH(0, 0, 390, 200));

  /// The clouds, drifting right across the sky and round again: each
  /// crosses the frame and its own width [DriftingPiece.laps] times per
  /// [cloudLoop]. They keep their place when the scene lifts.
  static const clouds = [
    DriftingPiece(ScenePiece('$_dir/cloud-small.webp', Rect.fromLTWH(184, 39, 58, 24)), laps: 2),
    DriftingPiece(ScenePiece('$_dir/cloud-large.webp', Rect.fromLTWH(276, 61, 95, 40)), laps: 1),
  ];
  static const cloudLoop = Duration(minutes: 6);
  static const cloudStep = Duration(milliseconds: 50);

  static const sea = ScenePiece('$_dir/sea.webp', Rect.fromLTWH(0, 200, 390, 644));
  static const toriiLocked = ScenePiece('$_dir/torii-locked.webp', Rect.fromLTWH(280, 338, 104, 140));
  static const toriiOpen = ScenePiece('$_dir/torii-open.webp', Rect.fromLTWH(280, 338, 104, 140));
  static const boat = ScenePiece('$_dir/tobi-boat.webp', Rect.fromLTWH(114, 374, 124, 110));

  /// The near swell that carries each island's entry, at its own top
  /// left: the front of the sea's paper layers. Its crest line runs no
  /// deeper than [crest] below its top, and sits [crestGap] dp above the
  /// entry. Below the picture, its plain halftone [fill] (a whole number of
  /// dot rows) repeats.
  static const seaNear = ScenePiece('$_dir/wave-1.webp', Rect.fromLTWH(0, 0, 390, 320));
  static const double crest = 60;
  static const double crestGap = 2;
  static const Rect fill = Rect.fromLTWH(0, 170, 390, 150);

  /// The paper layers behind the near swell, back to front, sharing its
  /// box; Tobi's boat sails between them and the swell. Each repeats
  /// across the frame, slides [WaveLayer.speed] times as far as the swell
  /// when the ring turns, and bobs [WaveLayer.bob] units once per
  /// [WaveLayer.period] (still under reduced motion), redrawn every
  /// [waveStep].
  static const backWaves = [
    WaveLayer(ScenePiece('$_dir/wave-4.webp', Rect.fromLTWH(0, 0, 390, 320)),
        speed: 0.25, bob: 0.8, period: Duration(milliseconds: 7300)),
    WaveLayer(ScenePiece('$_dir/wave-3.webp', Rect.fromLTWH(0, 0, 390, 320)),
        speed: 0.45, bob: 1, period: Duration(milliseconds: 5900)),
    WaveLayer(ScenePiece('$_dir/wave-2.webp', Rect.fromLTWH(0, 0, 390, 320)),
        speed: 0.7, bob: 1.2, period: Duration(milliseconds: 4700)),
  ];
  static const waveStep = Duration(milliseconds: 40);

  /// The bottom of the boat's hull, and how far below the swell's top its
  /// crest line runs under the hull. A screen too short to show the hull
  /// above the swell lifts the scene by up to [maxLift]; beyond that the
  /// swell rises over the boat.
  static const double foreground = 474;
  static const double hullTrough = 50;
  static const double maxLift = 60;

  /// The least of the scene kept above the entry; a screen too short for
  /// it and the entry scrolls.
  static const double minHeight = 360;

  /// The torii and Tobi's boat bob (and the boat rocks) once per period.
  static const double toriiLift = 2;
  static const toriiPeriod = Duration(milliseconds: 5200);
  static const double boatLift = 3;
  static const double boatTurnDeg = 1.5;
  static const boatPeriod = Duration(milliseconds: 3800);
}

/// One of the sea's paper layers behind the near swell
/// ([DojoSceneLayout.backWaves]): its [piece], how far it slides for the
/// swell's every unit ([speed]), and its gentle [bob] up and down, in
/// units, once per [period].
@immutable
class WaveLayer {
  const WaveLayer(this.piece, {required this.speed, required this.bob, required this.period});
  final ScenePiece piece;
  final double speed, bob;
  final Duration period;
}

/// A picture that drifts sideways across the scene and round again, [laps]
/// times per loop.
@immutable
class DriftingPiece {
  const DriftingPiece(this.piece, {required this.laps});
  final ScenePiece piece;
  final int laps;
}

/// Where an island stands in one slot of the ring ([DojoRingLayout]): its
/// canvas's [DojoRingLayout.foot] at [foot] on the scene, at [scale]; in
/// colour or blue [haze] (0–1); its label shown by [label] (0–1), a "coming
/// soon" tag pinned by its [tagAlign] point to [tag] on the canvas; and its
/// [depth], the deepest painted first.
@immutable
class RingSlotSpec {
  const RingSlotSpec({
    required this.foot,
    required this.scale,
    required this.haze,
    required this.label,
    required this.tag,
    required this.tagAlign,
    required this.depth,
  });
  final Offset foot, tag;
  final double scale, haze, label, depth;
  final Alignment tagAlign;

  static RingSlotSpec lerp(RingSlotSpec a, RingSlotSpec b, double t) => RingSlotSpec(
        foot: Offset.lerp(a.foot, b.foot, t)!,
        scale: lerpDouble(a.scale, b.scale, t)!,
        haze: lerpDouble(a.haze, b.haze, t)!,
        label: lerpDouble(a.label, b.label, t)!,
        tag: Offset.lerp(a.tag, b.tag, t)!,
        tagAlign: Alignment.lerp(a.tagAlign, b.tagAlign, t)!,
        depth: lerpDouble(a.depth, b.depth, t)!,
      );
}

/// One arm of the ring's track beyond the screen's left edge, run along
/// from a slot (at 0) to [exit] (at 1), out of sight: the island's foot
/// on the curve from the slot's toward [bend] and on to [exit]'s; the rest
/// part of the way between the slot's and [exit]'s.
@immutable
class RingArmSpec {
  const RingArmSpec({required this.exit, required this.bend});
  final RingSlotSpec exit;
  final Offset bend;

  /// [t] of the way along the arm from [slot].
  RingSlotSpec at(RingSlotSpec slot, double t) {
    final spec = RingSlotSpec.lerp(slot, exit, t);
    final u = 1 - t;
    final foot = slot.foot * (u * u) + bend * (2 * u * t) + exit.foot * (t * t);
    return RingSlotSpec(
      foot: foot,
      scale: spec.scale,
      haze: spec.haze,
      label: spec.label,
      tag: spec.tag,
      tagAlign: spec.tagAlign,
      depth: spec.depth,
    );
  }
}

/// One island of the ring: its picture in [colour] and the same drawing in
/// blue [haze], both filling the island canvas.
@immutable
class RingIsleArt {
  const RingIsleArt(this.colour, this.haze);
  final String colour, haze;
}

/// The ring of islands on the dojo scene (`SideTripRing`). Every island is
/// drawn on one [canvas] (units as the scene's) and stands on its
/// waterline at [foot]; each slot of the ring ([slots], in `RingSlot`
/// order: front, right, back, left) puts it somewhere on the scene. An
/// island between two slots is part of the way between the two. In front
/// its tag hangs in the water under its left end; elsewhere it floats over
/// the island, clear of the one in front.
///
/// The track is a parabola opening to the left, its tip near the right
/// slot: its [near] arm runs on from the front and its [far] arm from the
/// left slot, both past the screen's left edge. An island between the
/// front and the left slot shows on both at once, the same share of the
/// way out along one as in along the other: leaving the front past the
/// viewer, growing a little, as its blue twin comes into the left slot.
abstract final class DojoRingLayout {
  static const _dir = 'assets/images/sidetrips/islands';
  static const Size canvas = Size(370, 226);
  static const Offset foot = Offset(185, 213);

  static const slots = [
    RingSlotSpec(
        foot: Offset(169, 397), scale: 1, haze: 0, label: 1, tag: _under, tagAlign: Alignment.topLeft, depth: 3),
    RingSlotSpec(
        foot: Offset(334, 248), scale: 0.36, haze: 0, label: 1, tag: _over, tagAlign: Alignment.bottomCenter, depth: 2),
    RingSlotSpec(
        foot: Offset(208, 200), scale: 0.26, haze: 1, label: 0, tag: _over, tagAlign: Alignment.bottomCenter, depth: 0),
    RingSlotSpec(
        foot: Offset(30, 201), scale: 0.16, haze: 1, label: 0, tag: _over, tagAlign: Alignment.bottomCenter, depth: 1),
  ];
  static const _under = Offset(36, 231);
  static const _over = Offset(185, -4);

  static const near = RingArmSpec(
    exit: RingSlotSpec(
        foot: Offset(-212, 422), scale: 1.12, haze: 0, label: 0, tag: _under, tagAlign: Alignment.topLeft, depth: 4),
    bend: Offset(-21.5, 422),
  );
  static const far = RingArmSpec(
    exit: RingSlotSpec(
        foot: Offset(-28, 199), scale: 0.12, haze: 1, label: 0, tag: _over, tagAlign: Alignment.bottomCenter, depth: 1),
    bend: Offset(1, 200),
  );

  static const ankiren = RingIsleArt('$_dir/ankiren.webp', '$_dir/ankiren-haze.webp');
  static const building = RingIsleArt('$_dir/construction.webp', '$_dir/construction-haze.webp');
  static const fuji = RingIsleArt('$_dir/fuji.webp', '$_dir/fuji-haze.webp');
  static const lighthouse = RingIsleArt('$_dir/lighthouse.webp', '$_dir/lighthouse-haze.webp');

  /// 暗記練's banner on its island's grass, once it is open: its label.
  static const nobori = ScenePiece('assets/images/sidetrips/ankiren/nobori.webp', Rect.fromLTWH(277.2, 56, 30, 100));
}

/// How the ring of islands turns (`SideTripsScreen`).
abstract final class DojoRingMotion {
  /// The settle onto a step, from wherever the swipe let go: critically
  /// damped, so it clicks into place.
  static const settle = SpringDescription(mass: 1, stiffness: 420, damping: 41);

  /// Under reduced motion the islands and entries crossfade instead.
  static const crossfade = Duration(milliseconds: 220);

  /// How far Tobi's boat drifts with a whole step, in scene units, and the
  /// spring that brings it back once the ring stops.
  static const double boatDrift = 16;
  static const boatReturn = SpringDescription(mass: 1, stiffness: 55, damping: 8);
}

/// The tab's title lettering over the sky, and the scene's "coming soon"
/// tags (`DojoScene`). In dp, not scaled with the scene.
abstract final class DojoSceneStyle {
  /// The title's top left corner, below the status bar.
  static const Offset title = Offset(16, 6);
  static const double titleFont = 42;
  static const double titleOutline = 10;
  static const double titleBannerFont = 11;
  static const double titleBannerGap = 6;

  static const double tagFont = 11;
  static const double tagLineHeight = 1.2;
  static const double tagBorder = 1.8;
  static const EdgeInsets tagPadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
  static const double chipFont = 9.5;
  static const double chipTracking = 0.08;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 4);
  static const double chipGap = 4;
}

/// The unlock moment, once, when 暗記練 first opens on the hub: the
/// padlocked torii rattles, snaps at [snapAt] of [unlock], and gives way to
/// the open one popping in while the banner rises.
abstract final class DojoUnlockMotion {
  static const unlock = Duration(milliseconds: 1100);
  static const double snapAt = 0.45;
  static const double rattle = 3;
  static const double rattleHz = 14;

  /// The torii's swell at the swap, a share of its size.
  static const double pop = 0.14;

  /// How far the banner rises into place, in scene units.
  static const double banner = 24;
}

/// The Side Trips tab's entry for 暗記練 under the dojo scene
/// (`research/design/sidetrips_c.html`): its lettering and rank stamp
/// breaking out over the panel's top; the rating and next game and the
/// burst to the trip's page, or while it is locked the cards still to
/// remember and under them the rules.
abstract final class SideTripsLayout {
  /// The entry never grows wider than this (a landscape screen).
  static const double maxWidth = 480;

  /// Left between the entry and the tab bar.
  static const double bottomGap = 12;

  /// Display lettering (the tab's title, the trip's name, the scene's tags)
  /// grows with the system text size only up to this factor.
  static const double letteringMaxScale = 1.1;

  /// How far the lettering and stamp hang over the panel's top.
  static const double overlap = 13;
  static const double headInset = 6;
  static const double letteringFont = 37;
  static const double letteringOutline = 10;
  static const double letteringGap = 8;
  static const double letteringDrop = 4;
  static const double bannerFont = 11;

  /// The rank stamp pressed on the panel's top right corner: tilted clockwise
  /// (degrees), its class lettered big with 級 small inside a double rule,
  /// lifted [stampLift] off the head's foot so it stays off the panel's rows,
  /// and hanging [stampHang] out past the panel's right edge.
  static const double stampTilt = 10;
  static const double stampFont = 18;
  static const double stampSuffixFont = 13;
  static const double stampGap = 2;
  static const EdgeInsets stampPadding = EdgeInsets.symmetric(horizontal: 7, vertical: 4);
  static const double stampLift = 4;
  static const double stampHang = 8;

  /// How far the panel's top-left corner is cut down.
  static const double cut = 12;

  /// The rows inside the panel: a label (with its other-language sub) over
  /// a value, side by side when there are two, split by a rule.
  static const EdgeInsets rowPadding = EdgeInsets.fromLTRB(14, 4, 6, 4);
  static const double rowMinHeight = 56;
  static const double lockedRowMinHeight = 50;
  static const double rowGap = 12;
  static const double ruleWidth = 2;
  static const double ruleInset = 8;
  static const int ratingFlex = 5;
  static const int nextFlex = 6;
  static const double labelFont = 12;
  static const double labelLineHeight = 1.2;
  static const double subFont = 11;
  static const double subTracking = 0.14;
  static const double labelGap = 3;
  static const double valueFont = 22;
  static const double unrankedFont = 20;
  static const double valueGap = 6;
  static const double factsFont = 13.5;
  static const double factsNumber = 15;

  /// The last game's rating change: ▲ on ink, ▼ on paper.
  static const double deltaFont = 12.5;
  static const EdgeInsets deltaPadding = EdgeInsets.fromLTRB(4, 3, 5, 4);

  /// The ranked burst (`burst.svg`): one fixed piece, scaled down only to
  /// fit a narrow panel; its label in the art's safe box.
  static const Size burst = Size(344, 64);
  static const Rect burstLabel = Rect.fromLTRB(34, 17, 310, 47);
  static const EdgeInsets burstMargin = EdgeInsets.fromLTRB(0, 6, 0, 8);
  static const double burstFont = 21;
  static const double burstSubFont = 11;
  static const double burstSubTracking = 0.12;
  static const double burstGap = 8;
  static const double burstIcon = 22;
  static const double burstIconStroke = 3.2;

  /// While locked: the cards to remember as rows of pips, then a grey bar
  /// where the burst will be.
  static const EdgeInsets pipsPadding = EdgeInsets.fromLTRB(14, 2, 14, 0);
  static const int pipsPerRow = 25;
  static const double pipGap = 3;
  static const double pipRowGap = 3;

  /// Narrow pips keep a card's shape.
  static const double pipAspect = 1.45;
  static const double lockTop = 8;
  static const double lockMinHeight = 60;
  static const EdgeInsets lockPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 8);
  static const double lockIcon = 24;
  static const double lockIconStroke = 2.6;
  static const double lockGap = 10;
  static const double lockTitleFont = 18;
  static const double lockLineFont = 12;
  static const double lockLineNumber = 14;

  /// Between the pair of buttons on the trip's page.
  static const double pairGap = Gaps.panelWide;

  static const Size lockBalloon = Size(270, 96);
  static const Duration lockBalloonLife = Duration(milliseconds: 2800);

  /// An island still being built: smaller lettering over a small panel
  /// that says so.
  static const double soonLetteringFont = 30;
  static const EdgeInsets soonPadding = EdgeInsets.fromLTRB(14, 4, 14, 12);
  static const double soonTitleFont = 16;
  static const double soonLineFont = 13;
  static const double soonLineGap = 3;
}

/// 暗記練's rules sheet (遊び方, `ankiren_rules_sheet.dart`): its three steps
/// in pictures with a line on each, then the rules and the scoring as
/// lists, each line with the other language's under it.
abstract final class AnkirenRulesLayout {
  static const String memorise = 'assets/images/sidetrips/ankiren/howto-memorize.webp';
  static const String flip = 'assets/images/sidetrips/ankiren/howto-flip.webp';
  static const String take = 'assets/images/sidetrips/ankiren/howto-take.webp';

  /// The scoring rules print a share of the points to this many decimal
  /// places at most.
  static const int shareDecimals = 2;

  /// A step: its picture on desk grey, then its number and name, then its
  /// line.
  static const double pictureHeight = 90;
  static const double pictureBorder = Strokes.label;
  static const double stepGap = 6;
  static const double stepInnerGap = 5;
  static const double stepFont = 14;
  static const double numberBox = 18;
  static const double numberFont = 11;
  static const double stepLineFont = 12;
  static const double stepSubFont = 11;
  static const double lineHeight = 1.35;

  /// A list row: a marked box, then the line.
  static const double markBox = 28;
  static const double markBorder = Strokes.label;
  static const double markFont = 12;
  static const double markIcon = 17;
  static const double markIconStroke = 2.6;
  static const double markGap = 10;
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(vertical: 8);
  static const double ruleLineFont = 13;
  static const double ruleSubFont = 11.5;

  /// A table under a rule's line: points by where a tap lands.
  static const double belowGap = 6;
  static const EdgeInsets tierCellPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 4);
  static const double tierHeadFont = 11;
  static const double tierFont = 12.5;
  static const double tierSubFont = 10.5;
}

/// The debug Simulation page's summary and per-day charts.
abstract final class SimulationStyle {
  static const double labelWidth = 150;
  static const double chartHeight = 110;
  static const double chartGap = 20;
  static const double legendGap = 12;
  static const double swatch = 10;
}

/// The developer's 暗記練 tools page (`AnkirenToolsPage`): its charts and
/// spacing.
abstract final class AnkirenToolsStyle {
  static const double chartHeight = 120;
  static const double curveStroke = 2;
  static const double markerStroke = 1.5;
  static const double targetRadius = 3;
  static const double gap = 8;

  /// The total-points graphs: their height, the margins that hold the axis
  /// labels, the lines' stroke and label size, and the hues one line per
  /// level runs through (level 0 at [hueStart], the top level at [hueEnd]).
  static const double graphHeight = 240;
  static const EdgeInsets graphMargin = EdgeInsets.fromLTRB(44, 8, 20, 18);
  static const double lineStroke = 1.5;
  static const double axisFont = 10;

  /// Between an axis, or a line's end, and its label.
  static const double axisLabelGap = 3;
  static const double hueStart = 0;
  static const double hueEnd = 290;
  static const double lineSaturation = 0.75;
  static const double lineLightness = 0.42;
}

/// The developer's 暗記練 test game (`AnkirenDebugGame`): its debug bar and
/// the debug layer over the field, drawn like Flutter's own debug paint:
/// hairlines and small monospace labels in high-contrast colours.
abstract final class AnkirenDebugStyle {
  static const String mono = 'monospace';
  static const double barFont = 11;
  static const double labelFont = 9;
  static const Color barBackground = Color(0xFF101010);
  static const Color barText = Color(0xFFE6E6E6);
  static const Color barMute = Color(0xFF8A8A8A);
  static const Color chipOn = Color(0xFF00E5FF);
  static const Color chipOnText = Color(0xFF000000);
  static const double chipMinWidth = 26;
  static const double chipHeight = 28;
  static const double chipGap = 3;
  static const double chipRadius = 3;
  static const double chipBorder = 1;
  static const EdgeInsets barPadding = EdgeInsets.fromLTRB(6, 4, 6, 6);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 6);
  static const double rowGap = 4;

  /// The layer's strokes: each half, each row's band, the open middle
  /// between the clusters, a middle card's lines to its 友札, and the card
  /// asked for.
  static const Color half = Color(0xFF00E5FF);
  static const Color row = Color(0xFFFFB300);
  static const Color middle = Color(0xFFFF2BD6);
  static const double middleFillOpacity = 0.14;
  static const Color tomofuda = Color(0xFFFF2BD6);
  static const Color asked = Color(0xFFFFF200);
  static const double hairline = 1;
  static const double strong = 2;
  static const double dot = 3;

  /// A card's solution (its kimariji) on a dark chip.
  static const Color labelBackground = Color(0xDD000000);
  static const Color labelText = Color(0xFFFFFFFF);
  static const EdgeInsets labelPadding = EdgeInsets.symmetric(horizontal: 2, vertical: 1);
}

/// A balloon popping out of a tapped control (`BalloonPop`, e.g. "coming
/// soon"): its default size, the gap to the control (the tail bridges it),
/// how long it stays by default, and how it pops in and fades.
abstract final class BalloonPopStyle {
  static const Size size = Size(150, 64);
  static const double gap = 12;

  /// With Tobi saying it: Tobi's height, the gap to the balloon, and where
  /// the tail points (at Tobi, left of the balloon).
  static const double tobi = 74;
  static const double tobiGap = 2;
  static const Alignment tobiSpeaker = Alignment(-1.3, 0.45);
  static const Duration life = Duration(milliseconds: 1600);
  static const Duration fade = Duration(milliseconds: 260);
  static const pop = EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 320), curve: Entrances.springy);
}

/// Sky and hero backgrounds: radial and linear gradients (CSS angles, degrees).
abstract final class Backdrops {
  static const skyCenter = Alignment(-0.46, 0.24);
  static const skyColors = [Color(0xFFFFFBE6), Color(0xFFFFF1A8), Palette.sun];
  static const skyStops = [0.0, 0.38, 1.0];

  /// The pace question: the sky, lit from its lower right.
  static const paceSkyCenter = Alignment(0.7, 0.6);

  /// The relaxed pace: calm sea blues, sea dots rising toward Tobi's feet.
  static const relaxedCenter = Alignment(0, -0.45);
  static const relaxedColors = [Palette.paper, Palette.seaSoft, Palette.shallow];
  static const relaxedStops = [0.0, 0.42, 1.0];
  static const double relaxedToneAngle = 180;
  static const relaxedToneStops = [0.3, 0.75];

  /// The sprint pace: hot pink, glowing around Tobi.
  static const sprintCenter = Alignment(0, -0.19);
  static const sprintColors = [Palette.pinkSoft, Palette.pink, Palette.pinkDeep];
  static const sprintStops = [0.0, 0.5, 1.0];

  static const heroCenter = Alignment(0.6, -0.64);
  static const heroColors = [Palette.paper, Color(0xFFFFF6CC), Color(0xFFFFE36B)];
  static const heroStops = [0.0, 0.4, 1.0];

  /// The pink hero tone fades in toward the bottom left.
  static const double heroToneAngle = 198;
  static const heroToneStops = [0.46, 0.9];

  static const double freePlayAngle = 100;
  static const freePlayStops = [0.52, 1.0];
  static const nigateStops = [0.7, 1.0];

  /// A half-white mist over the top of the journey map.
  static const double mapFogHeight = 74;
  static const mapFogStops = [0.0, 0.38, 1.0];
  static const mapFogAlpha = [0.5, 0.46, 0.0];
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

  /// The same burst drawn with other random lines.
  BurstSpec reseeded(int offset) => BurstSpec(
      box: box,
      center: center,
      count: count,
      innerMin: innerMin,
      innerMax: innerMax,
      width: width,
      seed: seed + offset,
      color: color);

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
  static const sprint =
      BurstSpec(box: Size(170, 540), center: Offset(85, 220), count: 64, innerMin: 64, innerMax: 84, width: 2.8, seed: 5);
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
  static const slideL = EntranceFrom(offset: Offset(-60, 0));
  static const pop = EntranceFrom(scale: 0.4);
  static const up = EntranceFrom(offset: Offset(0, 22));
  static const isrise = EntranceFrom(scale: 0.15, opaqueAt: 0.3);
  static const thump = EntranceFrom(scale: 2.4, opaqueAt: 0.3);
  static const stamp = EntranceFrom(scale: 2.6, turnDeg: -14, opaqueAt: 0.3);

  /// For an `EntranceBuilder`, which draws its own motion from the progress.
  static const custom = EntranceFrom(opacity: 1);

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

/// A personal best: the time ticks down from the previous best, then the
/// PERSONAL BEST sticker stamps on at [impactAt] with ドン!, a jolt and Tobi.
abstract final class PersonalBestMotion {
  static const count = EntranceSpec(Entrances.custom,
      duration: Duration(milliseconds: 750), delay: Duration(milliseconds: 150), curve: Curves.easeOutCubic);
  static const sticker = EntranceSpec(Entrances.thump,
      duration: Duration(milliseconds: 380), delay: Duration(milliseconds: 850), curve: Entrances.springy);

  /// When the sticker first lands (a quarter of the way into the springy
  /// curve).
  static const impactAt = Duration(milliseconds: 950);
  static const jolt = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 280), delay: impactAt, curve: Curves.linear);
  static const double joltReach = 5;
  static const int joltSteps = 8;
  static const int joltSeed = 17;
  static const burst = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 420), delay: impactAt, curve: Curves.easeOut);
  static const sfx = EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 400), delay: impactAt, curve: Entrances.bouncy);
  static const tobi = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 1000), curve: Entrances.bouncy);
  static const note = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 1100), curve: Entrances.glide);
  static const gain = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 1300), curve: Entrances.bouncy);

  static Duration get length => gain.end;

  /// Afterwards Tobi keeps hopping.
  static const double hopHeight = 8;
  static const hopPeriod = Duration(milliseconds: 1300);
  static const double hopAirShare = 0.35;
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

/// The "Licenses & credits" screen, reached from Settings.
/// Settings (`SettingsScreen`): sections under ink banners with a rule
/// running out to the edge; each setting is named, with a one-line note
/// under its name, and switches and links sit in ink panels split by
/// hairlines.
abstract final class SettingsLayout {
  static const double sectionGap = 28;
  static const double headerFont = 16;

  /// Keeps the skewed banner's foot inside the gutter.
  static const double headerInset = 4;
  static const double headerSubFont = TypeScale.label;
  static const double headerSubGap = 8;

  /// The sub's share of the room beside the banner, against the rule's 1.
  static const int headerSubFlex = 4;
  static const double headerRule = Strokes.control;
  static const double headerGap = 12;
  static const double itemGap = 18;
  static const double labelGap = 8;
  static const double titleFont = TypeScale.button;
  static const double noteFont = TypeScale.small;
  static const double noteLineHeight = 1.3;
  static const double noteGap = 2;
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: Gaps.small);
  static const double rowGap = Gaps.panelWide;
  static const double rowMinHeight = ButtonMetrics.rowHeight;
  static const double valueFont = TypeScale.body;
  static const double chevron = 16;
  static const double footnoteGap = Gaps.small;

  /// A row with a slider (the music volume) under its title: the slider
  /// sits right under the title/note, no extra top gap of its own.
  static const double sliderTrackHeight = 4;
  static const double sliderThumbRadius = 9;
  static const double sliderOverlayRadius = 16;

  /// Dims a row that a switch above it has turned moot (the music volume
  /// slider while Music itself is off).
  static const double disabledOpacity = 0.4;
}

abstract final class CreditsLayout {
  static const double chevron = 16;
  static const double rowSubtitleGap = 2;
  static const double licenseTextLineHeight = 1.4;
}

/// A press-and-hold confirm button (`HoldToConfirmButton`), built like the
/// arming button of something dangerous: an alarm-red dome inside a hazard
/// striped bezel and an ink ring. Held, the ring fills from sun to paper,
/// the dome counts down the seconds, the bezel spins up and the whole
/// button rattles and glows harder toward the end. Releasing early drains
/// it back to empty.
abstract final class HoldConfirmStyle {
  static const double ringSize = 148;
  static const double ringStroke = 13;
  static const double fillStroke = 7;
  static const List<Color> fillColors = [Palette.sun, Palette.orange, Palette.paper];
  static const double bezel = 14;
  static const double bezelStripe = 7;

  /// Full turns the bezel's stripes make over a whole hold, speeding up.
  static const double bezelTurns = 4;
  static const Color dome = Palette.alarm;
  static const Color domeLit = Color(0xFFFF5A4E);
  static const Alignment domeLight = Alignment(-0.35, -0.45);
  static const double domeLightRadius = 0.95;
  static const double domeBorder = 3;

  /// The shine on the dome, in shares of its radius from its centre.
  static const Offset shineAt = Offset(-0.34, -0.5);
  static const Size shineSize = Size(0.52, 0.26);
  static const double shineOpacity = 0.55;

  /// The dome sinks a little while pressed.
  static const double pressedScale = 0.94;
  static const double icon = 34;
  static const double countFont = 50;
  static const double countOutline = 8;

  /// The rattle, [shakeReach] px at the very end, growing with the square
  /// of the progress, re-rolled every [shakeStep].
  static const double shakeReach = 5;
  static const Duration shakeStep = Duration(milliseconds: 35);

  /// The glow around the ring, reaching this share of its radius past it
  /// at the end.
  static const double glowReach = 0.45;

  /// Where the glow starts, as a share of the ring's radius.
  static const double glowFrom = 0.9;
  static const List<Color> glowColors = [Color(0xE6FFF1A8), Color(0x99FFD83A), Color(0x00FFD83A)];
  static const Duration drain = Duration(milliseconds: 260);
  static const double labelGap = 10;
  static const double labelFont = TypeScale.button;
  static const EdgeInsets labelPadding = EdgeInsets.fromLTRB(12, 6, 12, 7);
}

/// The full-screen alarm before what can't be undone (`HoldWarningScreen`:
/// Settings' journey → all-known switch, Reset all data). Alarm red flashing
/// once per [flashPeriod], marching hazard tape round the edges, 警告!!
/// between two warning lamps, and Tobi panicking in a siren glow that grows
/// (with a darkening round the edges) as the hold arms.
abstract final class HoldWarningStyle {
  static const Duration flashPeriod = Duration(milliseconds: 900);
  static const tone = ToneSpec(dot: Color(0xFF8E0A14), radius: 1.4, spacing: 6);
  static const double toneOpacity = 0.55;
  static const double armedDarkness = 0.55;

  /// The hazard tape framing the screen, marching one stripe pair per
  /// [tapeMarch].
  static const double tapeWidth = 14;
  static const double tapeStripe = 12;
  static const double tapeBorder = 2.5;
  static const Duration tapeMarch = Duration(milliseconds: 1400);
  static const EdgeInsets padding = EdgeInsets.fromLTRB(12, 10, 12, 12);

  static const double shoutFont = 72;
  static const double shoutOutline = 11;
  static const double shoutTurnDeg = -4;
  static const Color shoutLit = Palette.sun;
  static const Color shoutDim = Palette.paper;
  /// The warning lamps either side of 警告!!, lit in turn like a railway
  /// crossing's. Their base, dome and rays are in shares of the lamp's box;
  /// rays point at [lampRays] degrees (0 = right, clockwise) from the
  /// dome's centre.
  static const double lampSize = 54;
  static const Color lampLit = Color(0xFFFF5A4E);
  static const Color lampDim = Palette.alarmDeep;
  static const Rect lampBase = Rect.fromLTRB(0.12, 0.76, 0.88, 0.95);
  static const Rect lampDome = Rect.fromLTRB(0.26, 0.36, 0.74, 0.8);
  static const Rect lampShine = Rect.fromLTRB(0.34, 0.44, 0.44, 0.62);
  static const List<double> lampRays = [-165, -128, -90, -52, -15];
  static const double lampRayFrom = 0.31, lampRayTo = 0.47;
  static const double lampRay = 4;
  static const double lampStroke = 2.5;
  static const double headlineFont = TypeScale.title;
  static const double headlineTurnDeg = -1.5;
  static const EdgeInsets headlinePadding = EdgeInsets.fromLTRB(12, 5, 12, 7);
  static const double bodyFont = TypeScale.body;
  static const double bodyLineHeight = 1.4;

  /// Tobi's box, scaled down when the page is short on room.
  static const Size tobi = Size(126, 150);
  static const double tobiTremble = 2;
  static const double tobiTrembleArmed = 7;
  static const Duration trembleStep = Duration(milliseconds: 55);
  /// Tobi's cry, set vertically down its right side.
  static const String sfx = 'ヒエェッ!!';
  static const String sfxArmed = 'ギャアッ!!';

  /// Past this share of the hold, Tobi's cry turns to [sfxArmed].
  static const double sfxArmedFrom = 0.6;
  static const double sfxFont = 22;
  static const int sfxSeed = 23;
  static const double sfxTurnDeg = 6;
  static const Offset sfxAt = Offset(108, -6);

  /// The siren glow behind Tobi, a share of its box's width across, pulsing
  /// with the flash and swelling as the hold arms.
  static const List<Color> glowColors = [Color(0xF2FFF1A8), Color(0xB3FFD83A), Color(0x00FF9A2E)];
  static const double glowSize = 1.9;
  static const double glowDim = 0.8;
  static const double glowArmed = 1.35;

  static const shout = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 480), delay: Duration(milliseconds: 120), curve: Entrances.springy);
  static const headline =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 320), delay: Duration(milliseconds: 380));
  static const Duration entranceLength = Duration(milliseconds: 700);
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

/// One looping firework: bursting at [center] (in the 390 × 844 spec box)
/// in [color], first after [delay] and then every [period] seconds.
@immutable
class FireworkSpec {
  const FireworkSpec(this.center, this.color, {required this.delay, required this.period, this.seed = 0});
  final Offset center;
  final Color color;
  final double delay, period;
  final int seed;
}

/// The fireworks over the graduation page (`Fireworks`), in the spec's px.
abstract final class FireworksStyle {
  static const List<FireworkSpec> bursts = [
    FireworkSpec(Offset(72, 200), Palette.pink, delay: 0.2, period: 2.1, seed: 1),
    FireworkSpec(Offset(322, 190), Palette.sun, delay: 0.55, period: 2.3, seed: 2),
    FireworkSpec(Offset(40, 470), Palette.land, delay: 0.9, period: 2.2, seed: 3),
    FireworkSpec(Offset(352, 450), Palette.paper, delay: 1.25, period: 2.5, seed: 4),
    FireworkSpec(Offset(196, 60), Palette.sea, delay: 1.6, period: 2.4, seed: 5),
    FireworkSpec(Offset(200, 580), Color(0xFFFF9A2E), delay: 1.95, period: 2.2, seed: 6),
  ];
  static const double specWidth = 390;
  static const double specHeight = 844;
  static const int sparks = 18;

  /// How far a spark's direction strays from even spacing, in shares of
  /// the gap between two.
  static const double jitter = 0.5;
  static const double minRadius = 70, radiusRange = 34;

  /// Seconds a burst lasts.
  static const double life = 1.5;

  /// How far the sparks droop by the end, px.
  static const double droop = 46;

  /// Each spark is a streak this share of its distance long, ending in a dot.
  static const double streak = 0.28;
  static const double streakWidth = 3.5;
  static const double dot = 3.8;

  /// Share of its size a spark's dot has lost by the end.
  static const double dotShrink = 0.5;
  static const double outline = 1.5;

  /// The flash at a burst's heart, over this share of its life.
  static const double flashShare = 0.18;
  static const double flashSize = 30;

  /// Opacity holds until this share of the life, then fades out.
  static const double fadeFrom = 0.6;

  /// Under reduced motion every burst hangs still at this share of its life.
  static const double stillAt = 0.45;
}

/// 暗記練's play screen (`lib/ui/ankiren/`): the field scaled into the screen
/// like the layout mock (`research/design/ankiren_layouts.html`), the band
/// across its centre, and the cards' backs and feedback.
abstract final class AnkirenPlayLayout {
  /// Kept clear around the field.
  static const double padding = 6;

  /// The centre band's height: in portrait, and in landscape, where it
  /// widens the real field's gap between the halves.
  static const double bandPortrait = 72;
  static const double bandLandscape = 40;

  /// A card is never drawn wider than [maxCardW] (portrait), and zoom never
  /// lets one get narrower than [minTapCardW], a comfortable tap.
  static const double maxCardW = 80;
  static const double minTapCardW = 48;

  /// Dev mode's scoring readout (the play overlay) has room of its own, so
  /// it never hides a card: a strip [readoutStrip] tall above the field in
  /// portrait, a column [readoutColumn] wide beside it in landscape. It is
  /// scaled down should it not fit.
  static const double readoutStrip = 158;
  static const double readoutColumn = 236;

  static const Color background = Palette.desk;

  /// A face-down card: a plain back in the torifuda's frame colour.
  static const Color backFill = Palette.cardFrame;
  static const Color backBorder = Palette.ink;
  static const double backBorderWidth = 1;

  /// Outlines over a card: just found, tapped wrongly, and (under reduced
  /// motion) shown after the wrong taps.
  static const Color rightGlow = Palette.land;
  static const Color wrongTint = Palette.alarm;
  static const double wrongTintOpacity = 0.75;
  static const Color revealGlow = Palette.sun;
  static const double glowWidth = 3;

  /// The band: a paper strip between ink rules, its controls inset.
  static const Color bandColor = Palette.paper;
  static const double bandRule = Strokes.panel;
  static const EdgeInsets bandPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
  static const EdgeInsets bandPaddingLandscape = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const double bandGap = 8;

  /// Each of the band's two control slots, either side of its centre.
  static const double sideSlot = 96;
  static const double timerFont = 34;
  static const double timerFontLandscape = 24;
  static const double promptFont = 32;
  static const double promptFontLandscape = 24;
  static const double labelFont = 12;
  static const double labelTracking = 0.14;
  static const double countFont = 13;
  static const double controlFont = 14;
  static const double controlIcon = 18;
  static const EdgeInsets controlPadding = EdgeInsets.symmetric(horizontal: 8);

  /// The kimariji just found, or just given up, while the next prompt
  /// waits.
  static const Color foundText = Palette.landDeep;
  static const Color givenUpText = Palette.violetDeep;

  /// The tatami behind the field: a seamless tile drawn for [tatamiScale]×
  /// density, on [background] until it loads.
  static const String tatami = 'assets/images/ankiren/tatami.webp';
  static const double tatamiScale = 3;
}

/// 暗記練's card animations.
abstract final class AnkirenMotion {
  /// A card turning over, both halves of the turn.
  static const Duration flip = Duration(milliseconds: 220);

  /// A right tap's glow fading out.
  static const Duration rightGlow = Duration(milliseconds: 650);

  /// A wrong tap: the tint fading out while the card shakes [wrongShakes]
  /// times, [wrongShakeReach] px to either side, settling.
  static const Duration wrongFlash = Duration(milliseconds: 450);
  static const int wrongShakes = 3;
  static const double wrongShakeReach = 5;

  /// The card shown after the wrong taps rumbles until it is tapped.
  static const double revealShakeReach = 4;
  static const Duration revealShakeStep = Duration(milliseconds: 50);
  static const int revealShakeSeed = 7;
}

/// 暗記練's results (`AnkirenResultsScreen`).
abstract final class AnkirenResultsLayout {
  static const double scoreFont = 56;
  static const double scoreOutline = 11;
  static const double scoreOfFont = 15;
  static const EdgeInsets splashPadding = EdgeInsets.symmetric(horizontal: Gaps.inner, vertical: 18);
  static const double splashMinHeight = 190;
  static const Size tobi = Size(64, 76);
  static const double noteFont = 13;
}

/// 暗記練's sheets (`ankiren_free_sheet.dart`, `ankiren_rules_sheet.dart`):
/// free practice's floating panel, its top edge tilted, a head with the
/// close button, and for free play the level keys and the steppers.
abstract final class AnkirenSheetLayout {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(14, 22, 14, 14);
  static const double gap = 12;

  /// The head: the title with its other-language sub, and a line under it.
  static const double titleFont = 26;
  static const double titleSubFont = 11;
  static const double titleSubTracking = 0.18;
  static const double lineFont = 12;
  static const double lineGap = 3;
  static const double headGap = 10;

  /// A section's label with its other-language sub.
  static const double labelFont = 13;
  static const double labelSubFont = 11;
  static const double labelSubTracking = 0.14;
  static const double labelGap = 6;

  /// The level keys, [keysPerRow] a row: the chosen one sun-lit with a
  /// thicker border, one the known cards cannot fill desk grey.
  static const int keysPerRow = 6;
  static const double keyGap = 5;
  static const double keyHeight = 50;
  static const double keyBorder = Strokes.control;
  static const double keyChosenBorder = 4;
  static const double keyFont = 19;
  static const double keySubFont = 11;
  static const double keyCustomFont = 11;
  static const double keyCustomSubFont = 9;
  static const double keyLabelGap = 4;
  static const EdgeInsets keyPadding = EdgeInsets.symmetric(horizontal: 2);

  /// − value +: a stepper beside its label, which gives way first.
  static const double stepperButton = 48;
  static const double stepperGap = 4;
  static const double stepperSignFont = 22;
  static const double stepperValueWidth = 84;
  static const double stepperValueFont = 24;
  static const double stepperUnitFont = 12;

  static const Size lockBalloon = Size(280, 96);
  static const Duration lockBalloonLife = Duration(milliseconds: 2800);
}

/// 暗記練's page (`ankiren_page.dart`): the record strip, the last games or
/// placement, the next ranked game's panel with a preview of its field and
/// the ranked burst, then Home's button pair.
abstract final class AnkirenPageLayout {
  /// Between the page's blocks; above the next game's panel, whose tag
  /// rises [tagRise] over its top edge; and under the pair.
  static const double gap = 12;
  static const double nextTop = 8;
  static const double bottomGap = 12;

  /// A label in black type, its other-language sub in small tracked
  /// capitals.
  static const double labelFont = 11;
  static const double labelTracking = 0.14;
  static const double labelLineHeight = 1.2;
  static const double labelGap = 3;

  /// The record strip (History's): the class and the rating split by an
  /// ink rule, over the gauge to the next class.
  static const double stripCut = HistoryHeaderLayout.stripCut;
  static const EdgeInsets cellsPadding = EdgeInsets.fromLTRB(14, 9, 14 + stripCut, 8);
  static const double cellGap = 12;
  static const double stripFont = 26;
  static const double classSuffixFont = 16;
  static const double valueGap = 6;
  static const EdgeInsets gaugePadding = EdgeInsets.fromLTRB(11, 7, 12 + stripCut, 8);
  static const double gaugeFont = 12;
  static const double gaugeNumber = 15;
  static const double gaugeGap = 10;

  /// The last games or the placement games, in a panel: a heading, then a
  /// column a game, split by light rules.
  static const EdgeInsets gamesPadding = EdgeInsets.fromLTRB(10, 6, 10, 6);
  static const int lastGames = 5;
  static const double headFont = 14;
  static const double headGap = 6;
  static const double countFont = 12;
  static const double countNumber = 15;
  static const double linkFont = 12.5;
  static const double linkIcon = 14;
  static const double linkIconStroke = 3;
  static const double linkGap = 3;
  static const double linkUnderline = 2;
  static const double scoreFont = 17;
  static const double gameLevelFont = 11;
  static const double gameGap = 4;
  static const EdgeInsets gamePadding = EdgeInsets.fromLTRB(2, 2, 2, 3);
  static const Color lightRule = Color(0xFFC9C6BF);
  static const double lightRuleWidth = Strokes.hairline;

  /// A placement game still to play: its number in a dashed slot, both
  /// greyed.
  static const double slot = 26;
  static const double slotFont = 13;
  static const double slotBorder = Strokes.label;
  static const Color slotInk = Color(0xFF8A8A8A);
  static const Color todo = Color(0xFF6B6B6B);

  /// The next game's panel: the side trips' cut corner, its tag breaking
  /// the top edge, then the stats, the hint, the field and the burst.
  static const double tagRise = 13;
  static const double tagLeft = 18;
  static const EdgeInsets statsPadding = EdgeInsets.fromLTRB(15, 22, 14, 0);
  static const double statFont = 28;
  static const double statUnitFont = 15;
  static const double statSuffixFont = 13;
  static const double statGap = 3;
  static const EdgeInsets hintPadding = EdgeInsets.fromLTRB(15, 9, 14, 0);
  static const double hintFont = 12;
  static const double hintNumber = 14;
  static const double hintIcon = 15;
  static const double hintIconStroke = 2.6;
  static const double hintGap = 4;
  static const EdgeInsets burstMargin = EdgeInsets.fromLTRB(6, 12, 6, 12);

  /// The field preview: the next game's shape, face down on the play
  /// screen's tatami, as big as the room left allows, cards at most
  /// [previewMaxCardW] wide; hidden below [previewMinHeight].
  static const EdgeInsets previewMargin = EdgeInsets.fromLTRB(14, 11, 14, 0);
  static const double previewMinHeight = 96;
  static const double previewBorder = Strokes.control;
  static const double previewPadding = 10;
  static const double previewBand = 9;
  static const double previewBandRule = Strokes.label;
  static const double previewBandGap = 7;
  static const double previewMaxCardW = 30;
  static const Color previewGround = Color(0xFF99A083);
}

/// 暗記練's rating page (`AnkirenRatingOverlay`): its rank flag hoisted up a
/// flagpole whose height is the class, the bottom its threshold and the
/// finial the next class's. Over it the reading (the old rating, the new
/// one counting, the change) or the placement slots; under it what's left
/// to the next class, with Tobi.
abstract final class AnkirenRatingLayout {
  /// A rise, a reveal or a breakthrough: a sea page with a light glow and
  /// streaks rising; a fall: a calmer, lighter page with neither.
  static const Color color = Palette.sea;
  static const Alignment glowAt = Alignment(0.1, -0.1);
  static const List<Color> glowColors = [Color(0xFFDDF1FF), Color(0xFF7CC4FF), Palette.sea];
  static const List<double> glowStops = [0, 0.45, 1];
  static const tone = ToneSpec(dot: Color(0xFF1E86E6), radius: 1.5, spacing: 6);
  static const double toneAngle = 180;
  static const List<double> toneStops = [0.55, 1];
  static const streaks = SpeedLinesSpec(count: 40, seed: 29, fromEdge: true, color: Color(0x73FFFFFF));
  static const Color calmColor = Palette.shallow;
  static const List<Color> calmGlowColors = [Palette.paper, Color(0xFFD6EEFF), Palette.shallow];
  static const calmTone = ToneSpec(dot: Color(0xFF8CCBFA), radius: 1.3, spacing: 6);

  /// The title: display lettering, sun for a rise, paper for a fall.
  static const double topGap = 4;
  static const String titleUp = '暗記力UP!!';
  static const String titleHeld = 'キープ!!';
  static const String titleDown = 'ドンマイ!';
  static const String titlePlacing = 'ランク判定';
  static const String titlePlaced = 'ランク決定!!';
  static const double titleFont = 72;
  static const double titleOutline = 9;
  static const double bandInset = 44;
  static const double bandFont = 18;
  static const double bandTracking = 0.24;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(8, 6, 8, 7);
  static const double bandTurnDeg = -2;
  static const double headGap = 10;

  /// The reading: the old rating, an arrow, the new one counting in big
  /// lettering, and the change slapped on its corner as it lands.
  static const double readingFont = 56;
  static const double readingOutline = 9;
  static const double oldFont = 22;
  static const double arrowFont = 20;
  static const double readingGap = 8;
  static const double changeFont = 20;
  static const EdgeInsets changePadding = EdgeInsets.fromLTRB(8, 2, 8, 4);
  static const double changeTurnDeg = -6;
  static const Offset changeAt = Offset(-6, -14);
  static const impactBurst = BurstSpec(
      box: impactSize, center: Offset(150, 70), count: 40, innerMin: 50, innerMax: 70, width: 5, seed: 33);
  static const Size impactSize = Size(300, 140);
  static const double impactFromScale = 0.6;
  static const double impactToScale = 1.3;
  static const double landPulse = 0.14;

  /// The placement slots: one panel a game, its number over its score, the
  /// games played stamped done; those to come dashed, the next one marked.
  static const double slotHeight = 64;
  static const double slotGap = 8;
  static const double slotLabelFont = 11;
  static const double slotLabelTracking = 0.14;
  static const double slotScoreFont = 24;
  static const double slotTodoFont = 22;
  static const double slotBorder = Strokes.control;
  static const Color slotInk = Color(0xFF6B6B6B);

  /// The stamp overhangs a played slot's top right corner by [stampAt],
  /// at [stampScale] of its size.
  static const Offset stampAt = Offset(-7, -9);
  static const double stampScale = 0.72;

  /// The stage: the flagpole's art (its box in pole units, scaled to the
  /// stage's height), its centre at [poleAt] of the stage's width.
  static const String pole = 'assets/images/sidetrips/ui/flagpole.webp';
  static const Size poleBox = Size(64, 440);
  static const double poleCentre = 32;
  static const double poleWidth = 7;
  static const double poleAt = 0.27;

  /// The cloth's frames, cycled in the wind: their box, where their rings
  /// meet the pole, and the calm field the class is written in, all in the
  /// art's own units; on the stage the cloth is [clothScale] times the
  /// pole's scale.
  static const List<String> cloth = [
    'assets/images/sidetrips/ui/rank-cloth-0.webp',
    'assets/images/sidetrips/ui/rank-cloth-1.webp',
    'assets/images/sidetrips/ui/rank-cloth-2.webp',
  ];
  static const Size clothBox = Size(168, 84);
  static const double clothPole = 5;
  static const Rect clothText = Rect.fromLTRB(30, 22, 122, 62);
  static const double clothScale = 1.25;
  static const double clothFont = 34;
  static const double clothSuffixFont = 22;
  static const String veiled = '?';

  /// The cloth's top travels from [hoistLow] (the floor) to [hoistHigh] (the
  /// finial: the next class), in pole units, its band clear of the collar
  /// and the base; the rating sits level with the band's top edge, [bandTop]
  /// into the cloth's box (art units).
  static const double hoistHigh = 15;
  static const double hoistLow = 311;
  static const double bandTop = 16;

  /// The veiled flag: the cloth drained of colour, with a question mark.
  static const List<double> veil = [
    0.33, 0.59, 0.11, 0, 12, //
    0.33, 0.59, 0.11, 0, 12,
    0.33, 0.59, 0.11, 0, 12,
    0, 0, 0, 1, 0,
  ];

  /// The scale left of the pole: the class's ends, the old rating with an
  /// arrow, and a class's line crossing the pole; the next class's badge
  /// at the stage's top right.
  static const double scaleFont = 13;

  /// An end of the class is left unlabelled when the old rating's mark
  /// comes this close to it.
  static const double scaleClear = 22;
  static const double tickLength = 8;
  static const double tickStroke = 2;
  static const double oldMarkFont = 15;
  static const double oldArrow = 9;
  static const double oldArrowGap = 4;
  static const double lineReach = 26;
  static const double lineStroke = 2.5;
  static const double lineDash = 5;
  static const double badgeFont = 22;
  static const double badgeSuffixFont = 13;
  static const double lineBadgeFont = 15;
  static const double lineBadgeSuffixFont = 10;

  /// The flag lands with バサッ!! over its fly end, kept on the page: its
  /// right edge [landSfxAt] in from the fly's (or the page's), and up from
  /// the cloth's top; or hanging from the cloth's bottom when the flag
  /// flies higher than [sfxBelowFrom] of the pole (ジャン!! too).
  static const String landSfx = 'バサッ!!';
  static const double landSfxFont = 26;
  static const int landSfxSeed = 18;
  static const double landSfxTurnDeg = 8;
  static const Offset landSfxAt = Offset(4, -34);
  static const double sfxBelowFrom = 0.55;

  /// The reveal: a white flash, ジャン!! over the flag ([revealSfxAt] of the
  /// way along it) and a burst behind it.
  static const double revealSfxAt = 0.4;
  static const String revealSfx = 'ジャン!!';
  static const double revealSfxFont = 38;
  static const int revealSfxSeed = 21;
  static const double revealSfxTurnDeg = -8;
  static const revealBurst = BurstSpec(
      box: revealSize, center: Offset(170, 170), count: 52, innerMin: 70, innerMax: 100, width: 5, seed: 37);
  static const Size revealSize = Size(340, 340);
  static const double revealFromScale = 0.5;
  static const double revealToScale = 1.4;

  /// The suspense before a reveal or a breakthrough: the page darkens and
  /// the title dims; on a breakthrough the flag strains against the finial.
  static const double darkness = 0.6;
  static const double dimTo = 0.35;
  static const double strainPush = 7;
  static const double strainJitter = 2;
  static const int rumbleSeed = 61;
  static const Color flash = Palette.paper;

  /// What's left to the next class, with Tobi at its right end.
  static const double stripGap = 10;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(12, 8, 70, 9);
  static const double stripFont = 16;
  static const double stripNumberFont = 24;
  static const Placement tobi = Placement(right: -2, bottom: 2, size: Size(64, 76));

  static const double actionHeight = 62;
  static const double ctaFont = 20;
  static const double ctaSubFont = 13;
}

/// The 暗記練 rating page's timeline. The flag moves from [moveAt]: it
/// climbs, or sinks more slowly, and lands; on a breakthrough it strains
/// against the finial and the page flashes into the rank-up; on the last
/// placement game a drumroll ends in the reveal and the rating counts up.
abstract final class AnkirenRatingMotion {
  static const title = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100), curve: Entrances.springy);
  static const calmTitle =
      EntranceSpec(Entrances.up, duration: Duration(milliseconds: 500), delay: Duration(milliseconds: 100), curve: Entrances.glide);
  static const band =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 350));
  static const head = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 350), delay: Duration(milliseconds: 450), curve: Entrances.springy);
  static const stage = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 400), curve: Entrances.glide);
  static const strip = EntranceSpec(Entrances.up,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 650), curve: Entrances.glide);

  static const moveAt = Duration(milliseconds: 1000);
  static const climb = Duration(milliseconds: 1300);
  static const climbToTop = Duration(milliseconds: 1100);
  static const sink = Duration(milliseconds: 1700);
  static const Curve climbCurve = Curves.easeOutCubic;
  static const Curve sinkCurve = Curves.easeInOutCubic;

  /// The cloth flutters a frame every [flutter]; a class it sinks into
  /// fades in over [relabel].
  static const flutter = Duration(milliseconds: 170);
  static const relabel = Duration(milliseconds: 300);

  /// A ratchet click each time the rating goes up, at most this often.
  static const tickStep = Duration(milliseconds: 60);

  /// Landing: the reading pulses with a burst, the change and バサッ!! pop
  /// on, then the button.
  static const landPulse = Duration(milliseconds: 380);
  static const burst = Duration(milliseconds: 450);
  static const change = Duration(milliseconds: 400);
  static const changeAfter = Duration(milliseconds: 80);
  static const sfx = Duration(milliseconds: 400);
  static const tobi = Duration(milliseconds: 400);
  static const jolt = Duration(milliseconds: 300);
  static const double joltReach = 6;
  static const int joltSteps = 9;
  static const int joltSeed = 67;
  static const actionsAfter = Duration(milliseconds: 250);
  static const actions = Duration(milliseconds: 400);

  /// Placement: this game's slot pops in at [slotAt] and is stamped done at
  /// [stampAt]; the veiled flag climbs its step meanwhile.
  static const slotAt = Duration(milliseconds: 700);
  static const slot = Duration(milliseconds: 350);
  static const stampAt = Duration(milliseconds: 1150);
  static const stamp = Duration(milliseconds: 300);

  /// The drumroll before the reveal, with a heartbeat at each of [beats]
  /// after the flag stops; the reveal flashes white over [flashIn], holds,
  /// and fades over [flashOut], and the rating counts up over [count].
  static const List<Duration> beats = [
    Duration(milliseconds: 150),
    Duration(milliseconds: 600),
    Duration(milliseconds: 980),
    Duration(milliseconds: 1280),
  ];
  static const drumroll = Duration(milliseconds: 1500);
  static const beatPulse = Duration(milliseconds: 220);
  static const double beatScale = 0.03;
  static const flashIn = Duration(milliseconds: 110);
  static const flashHold = Duration(milliseconds: 60);
  static const flashOut = Duration(milliseconds: 420);
  static const countAfter = Duration(milliseconds: 250);
  static const count = Duration(milliseconds: 1100);
  static const Curve countCurve = Curves.easeOutCubic;

  /// A breakthrough: the flag strains against the finial with heartbeats,
  /// then the page flashes into the rank-up.
  static const strain = Duration(milliseconds: 1000);
  static const List<Duration> strainBeats = [Duration.zero, Duration(milliseconds: 420), Duration(milliseconds: 760)];
  static const strainPeriod = Duration(milliseconds: 140);
  static const rumbleStep = Duration(milliseconds: 40);
  static const Curve darken = Curves.easeIn;

  static const double hopHeight = 10;
  static const hopPeriod = Duration(milliseconds: 1000);
  static const double hopAirShare = 0.4;
}

/// [curve] advancing in [count] whole steps, like CSS `steps(count, end)`:
/// the stop-motion of manga entrances.
class StepCurve extends Curve {
  const StepCurve(this.count, [this.curve = Curves.linear]);
  final int count;
  final Curve curve;

  @override
  double transformInternal(double t) => curve.transform((t * count).floor() / count);
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
