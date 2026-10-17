part of '../design.dart';

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
