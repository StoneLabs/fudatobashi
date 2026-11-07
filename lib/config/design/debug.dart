part of '../design.dart';

/// The debug Simulation page's summary and per-day charts.
abstract final class SimulationStyle {
  static const double labelWidth = 150;
  static const double chartHeight = 110;
  static const double chartGap = 20;
  static const double legendGap = 12;
  static const double swatch = 10;
}

/// The developer's side-trip tools pages (`AnkirenToolsPage`,
/// `TeiichiToolsPage`): their margins, sections, tables, charts and
/// spacing.
abstract final class AnkirenToolsStyle {
  static const EdgeInsets padding = EdgeInsets.all(16);
  static const double sectionGap = 32;

  /// A table cell's room (`DebugGrid`): before the next column, and above
  /// and below.
  static const EdgeInsets cellPadding = EdgeInsets.only(right: 10, top: 2, bottom: 2);

  static const double chartHeight = 120;
  static const double curveStroke = 2;
  static const double markerStroke = 1.5;
  static const double targetRadius = 3;
  static const double gap = 8;

  /// The total-points graph: its height, the margins that hold the axis
  /// labels, and the lines' stroke and label size.
  static const double graphHeight = 240;
  static const EdgeInsets graphMargin = EdgeInsets.fromLTRB(44, 8, 30, 18);
  static const double lineStroke = 1.5;
  static const double axisFont = 10;

  /// Between an axis, or a line's end, and its label.
  static const double axisLabelGap = 3;

  /// A class border's dashed line and its label at the plot's right edge;
  /// labels closer than [classLabelHeight] are pushed apart.
  static const double classStroke = 1;
  static const double dotRadius = 4;
  static const double classDash = 4;
  static const double classDashGap = 3;
  static const double classLabelHeight = 10;
  static const double classOpacity = 0.7;
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

/// The developer's からふだ page (`KarafudaDevPage`): its margins, the gap
/// between its parts, and the mark of a candidate that was picked.
abstract final class KarafudaDevStyle {
  static const EdgeInsets padding = EdgeInsets.all(16);
  static const double gap = 8;
  static const Color picked = Palette.seaSoft;
}


/// The developer's 一騎打ち pages (`IkkiuchiCurvesPage`,
/// `IkkiuchiLayoutPage`): margins and gaps; the rating header pinned over
/// each page, its rating, its slider's track and thumb, and the rating
/// classes under the slider; and the layout's field, its ground, its card
/// pitch within [minPitch] and [maxPitch] dp (scrolling sideways past the
/// page's width), a home not on Tobi's side dimmed, a tint for each first
/// sound and a band for each look-alike family.
abstract final class IkkiuchiToolsStyle {
  static const EdgeInsets padding = EdgeInsets.all(16);
  static const double gap = 8;
  static const double sectionGap = 32;

  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(16, 10, 16, 8);
  static const double ratingFont = 24;
  static const double sliderTrack = 6;
  static const double sliderThumb = 10;
  static const double sliderOverlay = 18;
  static const EdgeInsets sliderPadding = EdgeInsets.fromLTRB(10, 16, 10, 6);
  static const Color sliderActive = Palette.ink;
  static const Color sliderInactive = Palette.inkShadow;
  static const Color headerRule = Palette.desk;

  /// The rating classes under the slider: a segment for each, [rankGap]
  /// apart, its name in [rankFont], the class at the rating inked.
  static const double rankHeight = 16;
  static const double rankFont = 10;
  static const double rankGap = 1;
  static const double rankLabelPadding = 1;
  static const Color rankFill = Palette.desk;
  static const Color rankText = soft;
  static const Color rankOnFill = Palette.ink;
  static const Color rankOnText = Palette.paper;

  /// Secondary text: notes, axis labels, the head of a table.
  static const Color soft = Color(0xFF6A6862);

  /// The layout page's controls: a row of chips after its label, and the
  /// facts about the match's layout, inked when he keeps a group together.
  static const double choiceLabelWidth = 100;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets chipLabelPadding = EdgeInsets.symmetric(horizontal: 4);
  static const EdgeInsets factPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const double factRadius = 4;

  /// The strikes page's controls under its board, kept tight so the board
  /// gets the room: their text, spacing and padding, and the pickers'
  /// corners and arrows.
  static const EdgeInsets controlsPadding = EdgeInsets.fromLTRB(6, 6, 6, 6);
  static const double controlFont = 11;
  static const double controlSpacing = 4;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 5);
  static const double menuRadius = 4;
  static const String menuMark = ' ▼';
  static const double menuMarkFont = 8;

  /// The debug game's developer tools at the board's top left, over
  /// everything and see-through: the stage and Tobi's rating, each on a
  /// [readoutFill] chip in [readoutFont]; under them his rating slider,
  /// standing [sliderLength] tall at the very left (OFF at its top), and
  /// beside it the buttons, [gameButton] square and [gameButtonGap] apart
  /// in two rows under the panel's [gamePanelTitle]. It keeps [gameInset]
  /// inside the screen's safe area.
  static const double gameInset = 4;
  static const double readoutFont = 9;
  static const Color readoutFill = Color(0x99141414);
  static const Color readoutInk = Color(0xEBFFFFFF);
  static const EdgeInsets readoutPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 2);
  static const double readoutGap = 2;
  static const String ratingLabel = 'Tobi rating: ';
  static const String ratingOff = 'OFF';
  static const double sliderLength = 150;
  static const double sliderWidth = 22;
  static const double gameSliderTrack = 3;
  static const double gameSliderThumb = 6;
  static const double gameSliderOverlay = 11;
  static const Color gameSliderActive = Color(0xB3FFFFFF);
  static const Color gameSliderInactive = Color(0x4DFFFFFF);
  static const Color gameSliderThumbFill = Color(0xEBFFFFFF);
  static const double gameButton = 20;
  static const double gameButtonGap = 3;
  static const double gameButtonRadius = 3;
  static const double gameButtonFont = 9;
  static const Color gameButtonFill = Color(0x1FFFFFFF);
  static const Color gameButtonOnFill = Color(0x80FFD53D);
  static const Color gameButtonInk = Color(0xEBFFFFFF);
  static const Color gameButtonEdge = Color(0x73FFFFFF);
  static const double gameButtonEdgeWidth = 1;
  static const Color gamePanelFill = Color(0x99141414);
  static const double gamePanelRadius = 4;
  static const EdgeInsets gamePanelPadding = EdgeInsets.fromLTRB(4, 3, 4, 4);
  static const String gamePanelTitle = 'DEV';
  static const double gamePanelTitleFont = 7;
  static const double gamePanelTitleTracking = 0.2;
  static const double gamePanelTitleGap = 3;
  static const Color gamePanelTitleInk = Color(0x99FFFFFF);

  /// The buttons' labels: the board turned, a 送り札 to Tobi and from him,
  /// a からふだ next, the memory time ended, and the held match let go.
  static const String turnLabel = 'R';
  static const String sendLabel = '^';
  static const String receiveLabel = 'v';
  static const String karafudaLabel = '空';
  static const String startLabel = '始';
  static const String goLabel = '次';

  /// The debug game's name for each stage of the match.
  static const String memoryTime = 'Memory Time';
  static const String gameStart = 'Game Start';
  static const String yoka = 'Yoka';
  static const String kaminoku = '上の句';
  static const String waitingForHit = 'Waiting for card hit';
  static const String feedback = 'Feedback';
  static const String closingUp = 'Closing Up';
  static const String sendingCard = 'Sending Card';
  static const String tobiPlacingCard = 'Tobi Placing Card';
  static const String receivingCard = 'Receiving Card';
  static const String waitingForGo = 'Waiting for 次';
  static const String waitBeforeShimonoku = '1s wait';
  static const String shimonoku = '下の句';
  static const String movingCard = 'Moving Card';
  static const String breakAfterShimonoku = '1s break';
  static const String gameEnd = 'Game End';

  static const Color ground = Palette.desk;
  static const double minPitch = 30;
  static const double maxPitch = 46;

  /// The full layout narrows its cards down to this pitch before it
  /// scrolls sideways.
  static const double fullMinPitch = 20;
  static const double awayOpacity = 0.3;

  /// Each first sound's pale tint on its cards, the sounds with the most
  /// cards dealt first and round again, the one-sound cards on
  /// [shortTint]; and their legend's chips.
  static const List<Color> soundTints = [
    Palette.seaSoft,
    Palette.sunSoft,
    Palette.landSoft,
    Palette.pinkSoft,
    Palette.violetSoft,
    Palette.orangeSoft,
    Color(0xFFD2F1EC),
    Color(0xFFEEF2C4),
  ];
  static const Color shortTint = Palette.paper;
  static const EdgeInsets tintPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 1);
  static const double tintBorder = 0.5;
  static const double tintSpacing = 4;

  /// A 友札 family's band at the foot of its cards, each family one of
  /// [familyFills], and its legend.
  static const double familyBand = 5;
  static const double swatch = 12;
  static const double legendSpacing = 12;
  static const double legendRunSpacing = 2;
  static const List<Color> familyFills = [
    Palette.sun,
    Palette.shallow,
    Palette.pink,
    Palette.land,
    Palette.orange,
    Color(0xFFC59BE0),
    Color(0xFF6FE3D2),
    Color(0xFFE0B07A),
    Color(0xFFFF7A6B),
    Color(0xFFB8C24A),
    Color(0xFF9DB0FF),
    Color(0xFFB5B5B5),
  ];
}

/// The developer's view of Tobi's curves (`IkkiuchiCurvesPage`).
abstract final class IkkiuchiCurvesStyle {
  /// The values table: names in the UI face, numbers in monospace, a
  /// column's room before it, each group's band and its tracked capitals,
  /// and the indent of a per-card row.
  static const double nameFont = 13;
  static const double numberFont = 12;
  static const double smallFont = 11;
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(vertical: 3);
  static const double columnGap = 12;
  static const double subIndent = 10;
  static const Color groupFill = Palette.desk;
  static const EdgeInsets groupPadding = EdgeInsets.fromLTRB(6, 4, 6, 4);
  static const double groupTracking = 1.4;

  /// A graph: its title and note, its height, the margins holding its axis
  /// labels and the marker's value, its value axis rounded up to one of
  /// [axisSteps] times a power of ten.
  static const double titleFont = 14;
  static const double titleGap = 4;
  static const double graphGap = 24;
  static const double graphHeight = 160;
  static const EdgeInsets graphMargin = EdgeInsets.fromLTRB(44, 24, 10, 18);
  static const double axisFont = 10;
  static const double axisLabelGap = 4;
  static const int valueDivisions = 4;
  static const List<double> axisSteps = [1, 2, 2.5, 5, 10];
  static const Color grid = Palette.desk;
  static const double gridStroke = 1;

  /// A graph's Export button, right of its title.
  static const double exportFont = 12;
  static const EdgeInsets exportPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const Color exportText = Palette.seaDeep;

  /// A faint dotted line up through each graph at each rating class's
  /// threshold, paler on the stacked shares.
  static const Color rankLine = Color(0x40141414);
  static const Color rankLineOnShares = Color(0x80FFFFFF);
  static const double rankStroke = 1;
  static const double rankDot = 2;
  static const double rankDotGap = 2;

  /// A curve: its line and the wash under it, its anchors as rings, a
  /// floor's dashes, and his form's reach around the chosen rating, each
  /// standard deviation another layer of [formBand]. A chance per group's
  /// second line, any in a game, is [anyLine], each line keyed in a legend
  /// [legendLine] long.
  static const Color line = Palette.seaDeep;
  static const double lineStroke = 2;
  static const Color lineWash = Color(0x1F1463C4);
  static const Color anyLine = Palette.vermilion;
  static const double legendLine = 16;
  static const double anchorRadius = 3;
  static const double anchorStroke = 1.5;
  static const Color anchorFill = Palette.paper;
  static const Color floor = Palette.alarm;
  static const double floorStroke = 1;
  static const double floorDash = 4;
  static const double floorDashGap = 3;
  static const Color formBand = Color(0x0F141414);

  /// The marker at the chosen rating: its line, its dot ringed in paper,
  /// and its value on an ink pill above the plot.
  static const Color marker = Palette.ink;
  static const double markerStroke = 1;
  static const double markerRadius = 4;
  static const double markerRing = 2;
  static const Color pillFill = Palette.ink;
  static const Color pillText = Palette.paper;
  static const EdgeInsets pillPadding = EdgeInsets.symmetric(horizontal: 5, vertical: 2);
  static const double pillRadius = 4;

  /// The stacked graph of shares: a fill for each share from the bottom,
  /// paper gaps between them, paper grid lines over them, and a label for
  /// each share at the marker, beside it on a paper pill with a swatch, at
  /// least [shareLabelSpacing] apart, tied to its band by a leader. The
  /// marker's line wears a paper halo.
  static const double sharesHeight = 220;
  static const List<Color> shareFills = [Palette.seaDeep, Palette.vermilion, Palette.violet, Palette.pink];
  static const double shareGap = 2;
  static const Color shareGrid = Color(0x59FFFFFF);
  static const double shareSwatch = 8;
  static const double shareLabelOffset = 14;
  static const double shareLabelSpacing = 3;
  static const double markerHalo = 3;
  static const Color shareLabelFill = Palette.paper;
  static const Color shareLabelBorder = Palette.ink;
  static const double legendSwatch = 10;
  static const double legendSpacing = 14;
}
