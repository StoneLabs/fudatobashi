part of '../design.dart';

abstract final class Palette {
  static const ink = Color(0xFF141414);

  /// The hard drop shadow behind panels and chips: ink, lightened so text beside it reads.
  static const inkShadow = Color(0x66141414);

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
  static const orangeSoft = Color(0xFFFFE8CF);
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
    this.mix = const [],
  });

  final Color dot;
  final double spacing;
  final Alignment begin;
  final Alignment end;

  /// More dot colours, scattered dot by dot among [dot]'s (the seed is
  /// [Tones.gradationMixSeed]).
  final List<Color> mix;

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
      other.phase == phase &&
      listEquals(other.mix, mix);

  @override
  int get hashCode =>
      Object.hash(dot, spacing, begin, end, Object.hashAll(radii), Object.hashAll(stops), phase, Object.hashAll(mix));
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

  /// The Stats tab's backdrop: Home's fade (thick under the header, gone
  /// before the summary line, swelling again toward the tab bar) in every
  /// colour of the map's speed dots and more, bigger and further apart.
  static const stats = GradationSpec(
    dot: Palette.pink,
    mix: [Palette.sun, Palette.sea, Palette.land, Palette.orange, Palette.violet],
    spacing: 9,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    radii: [2.2, 0.7, 0, 0, 1.2, 2.6],
    stops: [0, 0.06, 0.09, 0.55, 0.8, 1],
  );

  /// History's backdrop, behind the list: the voyage log's sea, island
  /// and sun dots, thick along the top and the bottom, leaning to the
  /// right, and gone behind the middle of the page.
  static const history = GradationSpec(
    dot: Palette.sea,
    mix: [Palette.land, Palette.sea, Palette.sun, Palette.pink],
    spacing: 8,
    begin: Alignment(0.6, -1),
    end: Alignment(-0.6, 1),
    radii: [1.9, 0.9, 0, 0, 0.8, 1.9],
    stops: [0, 0.08, 0.19, 0.7, 0.84, 1],
  );

  /// A page opened from Stats: the Stats dots behind its header only.
  static const statsPage = GradationSpec(
    dot: Palette.pink,
    mix: [Palette.sun, Palette.sea, Palette.land, Palette.orange, Palette.violet],
    spacing: 9,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    radii: [2.2, 0.7, 0, 0],
    stops: [0, 0.06, 0.09, 1],
  );

  /// The practice calendar's days: a little, a usual day, a lot.
  static const calendarLittle = ToneSpec(dot: Palette.pink, radius: 0.9, spacing: 6);
  static const calendarUsual = ToneSpec(dot: Palette.pink, radius: 1.5, spacing: 6);
  static const calendarLot = ToneSpec(dot: Palette.pink, radius: 2.1, spacing: 6, background: Palette.pinkSoft);

  /// Picks which colour of a gradation's `mix` each dot takes.
  static const int gradationMixSeed = 7;
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

  /// The journey Home's gaps between the map, today's set and Training:
  /// a third under [panel], the map taking the height.
  static const double journeyPanel = 5.36;

  static const double panelWide = 10;
  static const double section = 12;
  static const double inner = 12;
  static const double tight = 4;
  static const double small = 6;
}

abstract final class Fonts {
  static const display = 'Dela';
  static const sfx = 'Reggae';

  /// Brush lettering: the start card and the reading cards.
  static const brush = 'YujiSyuku';
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

  /// A whole-word heading shrunk to fit its longest word keeps this share
  /// of the room, as glyph widths don't scale quite in proportion.
  static const double wordFitShare = 0.98;
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

/// A section heading on the Help and credits pages (`MarkerHeading`): the
/// run pages' marker style at a larger size.
abstract final class MarkerHeadingStyle {
  static const Color color = Palette.sun;
  static const double titleFont = 24;
  static const double subFont = 12;
  static const double sectionGap = 30;

  /// The space above an other-language sub on a line of its own.
  static const double subLineGap = 4;
}

/// A feature still to come (`ComingSoonSlot`): a desk-grey slot with a
/// dashed ink border, its line centred in tracked capitals.
abstract final class ComingSoonStyle {
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 20, vertical: 22);
  static const Color fill = Palette.desk;
  static const double border = Strokes.label;
  static const double font = TypeScale.label;
  static const double tracking = TagStyle.tracking;
  static const double lineHeight = 1.5;
}

/// A boxed link to another page (`LinkRow`): a bold title over a note, a
/// chevron at the end.
abstract final class LinkRowStyle {
  static const double border = Strokes.button;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const double minHeight = 60;
  static const double font = TypeScale.button;
  static const double noteFont = TypeScale.small;
  static const double noteLineHeight = 1.3;
  static const Color note = Color(0xFF4A4844);
  static const double chevron = 16;
  static const double chevronGap = 12;
}

/// Text marked as found (`MarkedText`, the card browser's search): a sun
/// marker behind the lower part of the matched characters, from [top] to
/// [bottom] of the line's height.
abstract final class TextMarkStyle {
  static const Color color = Palette.sun;
  static const double top = 0.45;
  static const double bottom = 0.94;

  /// How far the marker reaches past the characters on each side.
  static const double reach = 1;
}

/// A switch between two or more choices (`PillSwitch`): a round-ended ink
/// box, the chosen one filled ink.
abstract final class PillSwitchStyle {
  static const double subGap = 5;
  static const double subTracking = 0.04;
}
