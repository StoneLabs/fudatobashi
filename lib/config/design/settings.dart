part of '../design.dart';

/// Settings › Card size: the live preview card above its slider.
abstract final class CardSizeLayout {
  static const double percentFont = 28;
  static const double percentGap = Gaps.small;
}

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

/// Settings' "Day starts at" sheet: the title, the hours in a grid (the
/// chosen one sun-lit and tilted), and a note on when a change applies.
abstract final class DayStartPickerLayout {
  static const double cut = 12;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(19, 25, 19, 19);
  static const double title = 22;
  static const double sub = 13;
  static const double subGap = 3;
  static const double gridGap = 12;
  static const int columns = 5;
  static const double cellGap = 7;
  static const double cellHeight = 38;
  static const double cellFont = 15;
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(horizontal: 4);
  static const double selectedTurnDeg = -2;
  static const double noteGap = 12;
  static const double note = 12.5;
  static const double noteLineHeight = 1.35;
  static const Color barrier = Color(0x8C141414);
}

/// The "Licenses & credits" screen, reached from Settings.
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

/// The plain message sheet about the data (`showDataProblem`: a backup that
/// can't be restored or saved).
abstract final class DataSheetLayout {
  static const EdgeInsets padding = EdgeInsets.fromLTRB(19, 22, 19, 19);
  static const double title = 22;
  static const double body = 14;
  static const double lineHeight = 1.4;
  static const double gap = 14;
  static const Color barrier = DayStartPickerLayout.barrier;
}

/// The recovery screen (`RecoveryScreen`): shown when the data won't open.
abstract final class RecoveryLayout {
  static const Size tobi = Size(84, 100);
  static const double bodyFont = 14;
  static const double bodyLineHeight = 1.45;
  static const double errorFont = 11.5;
  static const double errorLineHeight = 1.35;
  static const EdgeInsets errorPadding = EdgeInsets.all(10);
  static const double errorMaxHeight = 180;
  static const String errorFamily = 'monospace';
}

/// The notice an upgrade leaves for the player (`migration_notice.dart`): an
/// ink-dimmed Home, a panel with a title on an ink slab, Tobi with the
/// message and an OK shout.
abstract final class MigrationNoticeStyle {
  static const Color scrim = Color(0xB3141414);
  static const double maxWidth = 380;
  static const EdgeInsets margin = EdgeInsets.symmetric(horizontal: Gaps.gutter, vertical: Gaps.section);
  static const EdgeInsets panelPadding = EdgeInsets.fromLTRB(14, 0, 14, 10);
  static const Offset panelShadow = Offset(4, 5);

  /// The title's tag rises [tagRise] over the panel's top edge, in line
  /// with the panel's content.
  static const double tagRise = 16;
  static const double tagFont = 18;

  static const Size tobi = Size(78, 94);
  static const double bodyFont = 15;
  static const double bodyLineHeight = 1.45;
  static const double gap = 12;
}
