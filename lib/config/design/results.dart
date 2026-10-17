part of '../design.dart';

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

  /// 苦手's splash: the cleared count instead of the time.
  static const EdgeInsets clearedPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 18);
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

  /// A celebration's colour covers its art under the status bar, then fades
  /// out over this much, so the clock and icons stay readable.
  static const double statusScrimFade = 18;

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

/// Results after a ranked run: the scored time with its sum (clock, misses,
/// a forfeit's cards left), a forfeit's note, and the rating's arrow.
abstract final class RankedResultsLayout {
  static const EdgeInsets splashPadding = EdgeInsets.fromLTRB(18, 18, 18, 26);
  static const double sumGap = 12;
  static const EdgeInsets sumPadding = EdgeInsets.fromLTRB(10, 7, 10, 8);
  static const double rowFont = 13;
  static const double rowGap = 3;
  static const Color forfeitFill = Palette.pinkSoft;
  static const double arrow = 16;
  static const double arrowGap = 4;
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
