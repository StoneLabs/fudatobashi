part of '../design.dart';

/// The 五色百人一首 colour groups, by the name the poem data gives them.
abstract final class CardColorGroups {
  static const Map<String, Color> colors = {
    '青': Palette.sea,
    '桃': Palette.pink,
    '黄': Palette.sun,
    '緑': Palette.land,
    '橙': Palette.orange,
  };

  static Color of(String group) => colors[group] ?? Palette.sun;
}

/// A card's About page (`AboutCardScreen`): the cards on a desk panel, the
/// kimariji, the poem, the card's facts, its sound ladder and look-alikes,
/// then the explanation, the link to its stats and the next cards. Section
/// markers take the card's colour group.
abstract final class AboutCardLayout {
  static const double sectionGap = MarkerHeadingStyle.sectionGap;
  static const double headingGap = 10;

  /// The desk panel: a dotted desk under an ink border and hard shadow, the
  /// front card at [frontAt] from its centre and the other card tucked
  /// behind at [backAt], turned [backTurn] degrees and dimmed to
  /// [backBrightness].
  static const double panelHeight = 312;
  static const double panelBorder = Strokes.panel;
  static const double panelShadow = 4;
  static const ToneSpec panelTone = ToneSpec(dot: Color(0x21141414), radius: 0.9, spacing: 8.5, background: Palette.desk);
  static const double cardWidth = 186;
  static const Offset frontAt = Offset(-18, 0);
  static const Offset backAt = Offset(40, 6);
  static const double backTurn = 7;
  static const double backBrightness = 0.93;
  static const BoxShadow cardShadow =
      BoxShadow(color: Color(0x73000000), offset: Offset(0, 12), blurRadius: 18, spreadRadius: -10);

  /// The SWIPE sticker in the panel's corner until the first swipe.
  static const double stickerInset = 10;
  static const double stickerTurn = -3;
  static const double stickerBorder = Strokes.label;
  static const EdgeInsets stickerPadding = EdgeInsets.fromLTRB(8, 2, 8, 3);
  static const double stickerFont = 11;
  static const double stickerTracking = 0.1;
  static const double stickerIcon = 16;
  static const double stickerIconStroke = 2.6;
  static const double stickerIconGap = 5;
  static const Duration stickerFade = Duration(milliseconds: 200);

  /// The Taking card / Reading card switch under the panel.
  static const double switchGap = 14;
  static const double switchHeight = 38;
  static const double switchBorder = Strokes.button;
  static const double switchFont = TypeScale.button;
  static const double switchSubFont = 11;

  /// The reading card's key under the switch: a swatch of the card per
  /// mark, two to a row.
  static const double keyGap = 10;
  static const double keyRowGap = 5;
  static const double keyColumnGap = 12;
  static const Size keySwatch = Size(28, 24);
  static const double keySwatchBorder = 1.5;
  static const double keySwatchFont = 15;
  static const double keyRubyFont = 8;
  static const double keyDashWidth = 2;
  static const double keyDashHeight = 14;
  static const Size keyEnd = Size(7, 18);
  static const double keyLabelGap = 7;
  static const double keyFont = TypeScale.small;

  /// The kimariji: big, pink in an ink outline, shrinking rather than
  /// wrapping; the speaker after it, the card's number tag at the right.
  static const double kimarijiGap = 20;
  static const double kimarijiFont = 44;
  static const double kimarijiOutline = 7;
  static const double kimarijiLineHeight = 1.05;
  static const double numberFont = 18;
  static const EdgeInsets numberPadding = EdgeInsets.fromLTRB(10, 2, 10, 4);
  static const double numberGap = 12;
  static const double soundsFont = TypeScale.button;
  static const double soundsGap = 4;

  /// The poem: a desk panel with the halves' tags, a Kana / Romaji switch
  /// and the poet at the end; the kimariji in pink.
  static const EdgeInsets poemPadding = EdgeInsets.fromLTRB(14, 14, 12, 12);
  static const double poemFont = 19;
  static const double poemLineHeight = 1.25;
  static const double romajiFont = 17;
  static const double romajiLineHeight = 1.35;
  static const double verseGap = 0.85;
  static const double verseRunGap = 2;
  static const EdgeInsets linesPadding = EdgeInsets.only(top: 7, bottom: 12);
  static const double poetFont = 17;
  static const double romajiPoetFont = TypeScale.button;
  static const Color kimariji = Palette.pinkDeep;

  /// A small pill switch (Kana / Romaji, Sounds / Kana).
  static const double pillHeight = 28;
  static const double pillBorder = Strokes.control;
  static const double pillFont = TypeScale.tiny;
  static const double pillPadding = 10;

  /// The facts table: labels in a column of their own.
  static const double factsBorder = Strokes.button;
  static const double factsRule = Strokes.hairline;
  static const EdgeInsets factPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const double factLabelColumn = 104;
  static const double factLabelGap = 10;
  static const double factLabelFont = 10.5;
  static const double factLabelLineHeight = 1.35;
  static const double factFont = TypeScale.button;
  static const double factLineHeight = 1.4;
  static const double chip = 14;
  static const double chipGap = 6;

  /// The row under the ladder's heading: the explanation link and the
  /// ladder switch.
  static const double barGap = 10;
  static const double linkFont = TypeScale.label;
  static const double linkIcon = 15;
  static const double linkIconStroke = 2.6;
  static const double linkIconGap = 5;
  static const double linkRule = Strokes.label;
  static const double leadFont = 14.5;
  static const double leadLineHeight = 1.5;
  static const double leadGap = 10;

  /// The look-alike torifuda: two to a row.
  static const double lookAlikeLabelGap = 14;
  static const double lookAlikeLabelFont = 11.5;
  static const double lookAlikeGap = 8;
  static const double lookAlikeBorder = Strokes.control;
  static const EdgeInsets lookAlikePadding = EdgeInsets.fromLTRB(5, 5, 6, 5);
  static const double lookAlikeCard = 26;
  static const double lookAlikeFont = 15;
  static const double lookAlikeSubFont = 11;
  static const double lookAlikeChevron = 14;

  /// "About the poem": a part heading over a heavy rule, a size up from the
  /// section markers.
  static const double partGap = 44;
  static const double partRule = 4;
  static const double partRuleGap = 16;
  static const double partFont = 30;
  static const double partSubFont = TypeScale.button;
  static const double partBottomGap = 14;

  /// The link to the card's stats page, and the previous / next cards.
  static const double linkRowGap = 30;
  static const EdgeInsets linkRowPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const double linkRowHeight = 60;
  static const double linkRowFont = TypeScale.button;
  static const double linkRowNoteFont = TypeScale.small;
  static const double linkRowChevron = 16;
  static const double neighbourGap = 10;
  static const double neighbourHeight = 52;
  static const EdgeInsets neighbourPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);
  static const double neighbourFont = TypeScale.button;
  static const double neighbourLabelFont = 11;
  static const double neighbourChevron = 16;
  static const double neighbourChevronGap = 6;
  static const double bottomPad = 32;

  static const Color mutedText = Color(0xFF4A4844);
}

/// The sound ladder (`SoundLadderView`): a staircase of steps going down to
/// the right, each a count badge, the sound and a line on when it is
/// enough, with chips for the cards that join at that step.
abstract final class SoundLadderLayout {
  static const double indent = 16;
  static const double rule = Strokes.button;
  static const EdgeInsets stepPadding = EdgeInsets.fromLTRB(10, 10, 0, 14);
  static const double badge = 48;
  static const double badgeBorder = Strokes.control;
  static const double badgeFont = 20;
  static const double badgeLabelFont = 9;
  static const double badgeLabelGap = 3;
  static const double badgeGap = 10;
  static const double soundFont = 26;
  static const double soundLineHeight = 1.1;
  static const double fadedStroke = 1.3;
  static const Color faded = Color(0xFFB3AFA8);
  static const double kanaFont = TypeScale.label;
  static const double kanaGap = 8;
  static const Color kanaColor = Color(0xFF55534F);
  static const double captionGap = 5;
  static const double captionFont = TypeScale.label;
  static const double captionLineHeight = 1.4;
  static const double chipsGap = 7;
  static const double chipSpacing = 5;
  static const double chipBorder = Strokes.label;
  static const EdgeInsets chipPadding = EdgeInsets.fromLTRB(7, 2, 7, 3);
  static const double chipFont = TypeScale.label;
  static const double chipNumberFont = 10;
  static const double chipNumberGap = 4;
  static const Color chipNumber = Color(0xFF6A6862);
  static const double moreFont = TypeScale.tiny;
}
