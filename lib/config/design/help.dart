part of '../design.dart';

/// Help (`HelpScreen`): chapters headed like the Help pages', the guides as
/// entries in display type split by ink rules, and the tools to come in a
/// dashed slot.
abstract final class HelpLayout {
  /// An entry: its title (and, in Japanese, its English name), a note
  /// under it and an icon at the end.
  static const double entryPad = 16;
  static const EdgeInsets entryPadding = EdgeInsets.symmetric(vertical: entryPad);
  static const double titleFont = 18;
  static const double titleLineHeight = 1.25;
  static const double subFont = ProseLayout.headingSubFont;
  static const double subTracking = ProseLayout.headingSubTracking;
  static const double noteGap = 4;
  static const double noteFont = TypeScale.body;
  static const double noteLineHeight = 1.45;
  static const double icon = 22;
  static const double iconGap = 14;
  static const double rule = Strokes.hairline;

  /// The tools to come: a desk-grey slot with a dashed ink border, the line
  /// centred in tracked capitals.
  static const double soonGap = entryPad;
  static const EdgeInsets soonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 22);
  static const Color soonFill = Palette.desk;
  static const double soonBorder = Strokes.label;
  static const double soonFont = TypeScale.label;
  static const double soonTracking = TagStyle.tracking;
  static const double soonLineHeight = 1.5;
}

/// The poems the karuta guide (`KarutaGuideScreen`) shows, by id.
abstract final class KarutaGuideExamples {
  /// The poem split into its halves and shown as both kinds of card.
  static const int poem = 2;

  /// Two poems that share their first sounds: [readFirst] is read, and
  /// then [shortened] needs fewer.
  static const int readFirst = 2;
  static const int shortened = 67;

  /// The one-sound cards in the order players learn them.
  static const String oneSound = 'むすめふさほせ';

  /// The starts the longest kimariji share, two poems each.
  static const List<String> sixSound = ['あさぼらけ', 'わたのはら', 'きみがため'];

  /// How many steps (`guideStep1` …) a match takes in the guide.
  static const int steps = 7;
}

/// The text of the Help pages and Contact (`ProseChapter`, `ProseBody`):
/// numbered chapter headings over body paragraphs, an action row under them.
abstract final class ProseLayout {
  static const double bottomPad = 32;
  static const double chapterGap = 30;
  static const double paragraphGap = 10;
  static const double bodyFont = 15;
  static const double bodyLineHeight = 1.55;

  /// The gap from a paragraph to the link or action rows under it.
  static const double actionGap = KarutaRulesLayout.blockGap;

  /// A chapter's heading: its number in a pink box, the title, then (in
  /// Japanese) its English name, over an ink rule.
  static const double numberBox = 34;
  static const double numberFont = 18;
  static const double headingFont = 21;
  static const double headingLineHeight = 1.2;
  static const double headingGap = 10;
  static const double headingSubFont = 11;
  static const double headingSubTracking = 0.14;
  static const double headingRule = 3;
  static const double headingRuleGap = 8;
}

/// Markdown set as prose (`MarkdownProse`, the card explanations): the body
/// is [ProseLayout]'s; headings are display type, then bold.
abstract final class MarkdownLayout {
  static const double h1Font = 21;
  static const double h2Font = 18;
  static const double h3Font = 15.5;
  static const double h4Font = 14;
  static const double headingLineHeight = 1.3;

  /// The space above a block: a heading's, or any other block's.
  static const double h1Gap = 26;
  static const double h2Gap = 22;
  static const double h3Gap = 16;
  static const double blockGap = 10;

  /// A list: its markers in a column of their own, a diamond in the accent
  /// colour or the item's number.
  static const double markerColumn = 22;
  static const double itemGap = 6;
  static const double diamond = 8;
  static const double diamondTop = 8;
  static const double diamondLeft = 3;
  static const double numberFont = 14;
  static const double numberLineHeight = 1.4;

  /// A quote: desk grey behind it, an ink rule on its left.
  static const EdgeInsets quotePadding = EdgeInsets.fromLTRB(14, 10, 14, 10);
  static const double quoteRule = 5;

  /// A poem in a `verse` fence: its lines with furigana in a ruled box.
  static const EdgeInsets versePadding = EdgeInsets.fromLTRB(14, 12, 14, 12);
  static const double verseLineGap = 4;
  static const TextStyle verseStyle = TextStyle(fontWeight: Weights.bold, fontSize: 17, height: 1.3, color: Palette.ink);

  /// A picture: no taller than this, its caption under it.
  static const double pictureMaxHeight = 140;
  static const double captionGap = 6;
  static const double captionFont = TypeScale.small;
  static const Color captionColor = Palette.inkSoft;

  /// How much of the accent colour tints emphasised text.
  static const double highlight = 0.45;
}

/// The karuta guide (`KarutaGuideScreen`): its numbered chapters, Tobi's
/// lines and the pictures.
abstract final class KarutaGuideLayout {
  static const double figureGap = 14;
  static const double subheadFont = 13;

  /// Tobi beside a balloon.
  static const Size tobi = Size(64, 76);
  static const double tobiGap = 6;
  static const Alignment speakerLeft = Alignment(-1.25, 0.7);
  static const EdgeInsets balloonPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 6);
  static const double balloonFont = 14;

  /// A picture's panel.
  static const EdgeInsets figurePadding = EdgeInsets.fromLTRB(12, 14, 12, 12);
  static const double figureShadow = 4;
  static const double captionFont = 12.5;
  static const double captionGap = 6;

  /// The opening picture: a few cards fanned out under Tobi.
  static const double fanCard = 58;
  static const List<int> fanPoems = [87, 2, 67, 77, 57];
  static const double fanStep = 34;
  static const double fanTurn = 0.13;
  static const double fanLift = 9;

  /// The poem in its two halves.
  static const double poemFont = 17;
  static const double halfGap = 10;

  /// A reading card and a taking card side by side.
  static const double cardWidth = 92;
  static const double cardArrow = 26;
  static const double cardArrowGap = 8;
  static const Color yomifudaPaper = Color(0xFFF6EFD9);
  static const Color yomifudaEdge = Palette.goldDeep;
  static const double yomifudaBorder = 1.5;
  static const EdgeInsets yomifudaPadding = EdgeInsets.fromLTRB(5, 8, 5, 8);
  static const double yomifudaFont = 10.5;
  static const double yomifudaAuthorFont = 7.5;
  static const double yomifudaLineHeight = 1.08;
  static const double yomifudaColumnGap = 2;

  /// The field: both sides' three rows of cards, the one just read in pink.
  static const List<int> fieldRows = [8, 8, 9];
  static const double fieldCardAspect = 0.72;
  static const double fieldCardGap = 0.18;
  static const double fieldMiddleGap = 1.4;
  static const double fieldRowGap = 0.22;
  static const double fieldCentre = 0.9;
  static const double fieldInset = 0.04;
  static const double fieldCardStroke = 1.2;
  static const double fieldLineStroke = 2;
  static const List<double> fieldLineDash = Strokes.dash;
  static const int fieldReadSide = 0, fieldReadRow = 2, fieldReadCard = 3;
  static const double fieldLegendSwatch = 14;

  /// A match's steps: a numbered circle, then the line.
  static const double stepNumber = 26;
  static const double stepNumberFont = 13;
  static const double stepGap = 10;
  static const double stepRowGap = 10;

  /// Kimariji pictures: kana tiles, an arrow, the card they mean.
  static const double tile = 34;
  static const double tileFont = 20;
  static const double tileGap = 4;
  static const double tileBorder = Strokes.label;
  static const double romajiFont = 10.5;
  static const double romajiGap = 2;
  static const double kimarijiCard = 66;
  static const double kimarijiArrow = 24;
  static const double kimarijiArrowGap = 10;
  static const double kimarijiRowGap = 14;
  static const double readOpacity = 0.35;
  static const double stampFont = 13;
  static const double stampTurn = -0.22;
  static const double stampBorder = 2.5;
  static const EdgeInsets stampPadding = EdgeInsets.fromLTRB(6, 2, 6, 3);
}

/// The full karuta rules (`KarutaRulesScreen`): where they come from on
/// top, then every chapter in an ink band and every article under its
/// number tag, numbered paragraphs hanging from their numbers.
abstract final class KarutaRulesLayout {
  static const double bottomPad = 32;
  static const double blockGap = 12;
  static const double sourceFont = 14;
  static const double sourceLineHeight = 1.5;

  /// Scrolling to a chapter picked from the contents.
  static const Duration jump = Duration(milliseconds: 420);

  /// The document's title over the association's name.
  static const double titleGap = 26;
  static const double titleFont = 22;
  static const double authorFont = 13;
  static const double authorGap = 6;

  /// A chapter's band: its number in sun, its title in paper.
  static const double chapterGap = 26;
  static const EdgeInsets bandPadding = EdgeInsets.fromLTRB(12, 9, 12, 9);
  static const double chapterNumberFont = 13;
  static const double chapterNumberTracking = 0.08;
  static const double chapterTitleFont = 17;
  static const double bandGap = 10;

  /// An article: its number tag and title, then its text; a thin rule
  /// between articles.
  static const double articlePad = 16;
  static const double articleTitleFont = 16.5;
  static const double articleTagFont = 12.5;
  static const double headingGap = 10;
  static const double headingTextGap = 8;
  static const double ruleHeight = 1;
  static const Color rule = Palette.desk;

  static const double bodyFont = 15;
  static const double bodyLineHeight = 1.65;

  /// The ink line over the contents, where the intro ends and the rules
  /// begin, with its space above and below.
  static const double startRuleHeight = 2;
  static const Color startRule = Palette.ink;
  static const double startRuleGapAbove = 22;
  static const double startRuleGapBelow = 16;

  /// The numbers of paragraphs (一, 1) and list entries (（1）) hang in a
  /// column of this width (scaled with the text) or their own.
  static const double labelColumn = 24;
  static const double listLabelGap = 4;
  static const double entryGap = 8;

  /// Supplementary notes: under a 補足 pill, set in from a desk-grey rule.
  static const double notesGap = 8;
  static const double notesRule = 2.5;
  static const double notesIndent = 10;
  static const double notesLabelGap = 6;
  static const double noteFont = 13.5;
  static const double noteLineHeight = 1.6;
  static const double noteGap = 4;
  static const double markGap = 4;
  static const String pointMark = '○';
  static const String remarkMark = '※';

  /// A dated notice (通達) a paragraph or note ends with.
  static const double noticeFont = 12;
  static const double noticeGap = 2;

  /// The lines after the last article, and the closing note on the source.
  static const double closingGap = 22;
  static const double footnoteGap = 26;
  static const double footnoteFont = TypeScale.small;
}
