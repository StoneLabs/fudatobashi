part of '../design.dart';

/// The graduation exam's run (`ExamScreen`): Tobi's side of the mat above,
/// the scoreboard strip, the player's side below, and the lettering of its
/// opening and end.
abstract final class ExamLayout {
  /// Tobi's side and the player's, sharing the height over the buttons.
  static const int tobiFlex = 2;
  static const int playerFlex = 3;

  /// Tobi's side, across the mat: a muted desk.
  static const Color tobiSide = Palette.desk;
  static const ToneSpec tobiTone = Tones.inkLight;

  /// Tobi's height as a share of his side's, and his card's.
  static const double tobiShare = 0.8;
  static const double tobiLeft = 10;
  static const double cardShare = 0.7;

  /// His deck's centre across his side (−1 left … 1 right).
  static const double deckAt = 0.3;

  /// The blank card under his top one peeks out on his side of it.
  static const double underPeek = 7;

  /// A card of his leaves sideways: how far it travels, rises and turns
  /// (radians) on its way out, and how far it is nudged just before.
  static const double flyDistance = 150;
  static const double flyRise = 34;
  static const double flySpin = 0.8;
  static const double reach = 9;

  /// The scoreboard strip between the two sides.
  static const Color strip = Palette.ink;
  static const Color stripLabel = Palette.sun;
  static const Color stripText = Palette.paper;
  static const EdgeInsets stripPadding = EdgeInsets.fromLTRB(12, 6, 12, 7);
  static const double stripLabelFont = 11;
  static const double stripCountFont = 15;
  static const double stripClockFont = 22;
  static const double stripLineGap = 2;
  static const double stripVsFont = 16;
  static const double stripVsGap = 10;

  /// The "+10 s" that rises toward the player's clock at each miss, and
  /// over Tobi's deck (this share of the way down it, this much larger) at
  /// each of his.
  static const double popFont = 20;
  static const double popRise = 26;
  static const double popOutline = 6;
  static const double tobiPopAt = 0.3;
  static const double tobiPopScale = 1.5;

  /// A quick card of Tobi's: a burst behind his deck, reaching this share of
  /// the card's length past it and growing from [quickBurstFrom] of that;
  /// speed lines across his side at the deck's height; and its sound
  /// lettered over the deck, [quickWordAt] of the way down it.
  static const BurstSpec quickBurst = BurstSpec(
      box: Size(200, 200), center: Offset(100, 100), count: 44, innerMin: 34, innerMax: 52, width: 4, seed: 43,
      color: Palette.sun);
  static const double quickBurstReach = 0.35;
  static const double quickBurstFrom = 0.7;
  static const SpeedLinesSpec quickLines = SpeedLinesSpec(count: 16, seed: 47);
  static const String quickWord = 'シュッ';
  static const double quickWordAt = 0.08;
  static const double quickWordFont = 30;
  static const double quickWordOutline = 7;
  static const double quickWordTurnDeg = 8;
  static const double quickWordFrom = 0.4;

  /// Tobi's "Hmm…" over a slow card: its corner on him (shares of his box,
  /// from his top left), its tail toward him, and its lettering.
  static const Offset thinkAt = Offset(0.62, -0.02);
  static const Alignment thinkSpeaker = Alignment(-1.5, 1.3);
  static const EdgeInsets thinkPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 3);
  static const double thinkFont = 13;

  /// "Waiting for Tobi…" over the player's side once they are done.
  static const double waitWidth = 300;
  static const double waitCut = 10;
  static const EdgeInsets waitPadding = EdgeInsets.fromLTRB(16, 12, 16, 14);
  static const double waitTitleFont = 24;
  static const double waitTitleGap = 8;
  static const double waitLabelFont = 13;
  static const double waitClockFont = 26;
  static const double waitRowGap = 6;

  /// The kimariji chip's row over the player's deck.
  static const EdgeInsets chipRow = EdgeInsets.fromLTRB(Gaps.gutter, 10, Gaps.gutter, 2);

  /// Over the board until GO, and behind the end lettering.
  static const Color scrim = Color(0xC4141414);
  static const Color endScrim = Color(0x8C141414);

  static const String greeting = 'よろしく\nお願いします';
  static const double greetingFont = 44;
  static const double greetingOutline = 11;
  static const double greetingLineHeight = 1.15;
  static const Size greetingTobi = Size(134, 160);
  static const double greetingGap = 14;
  static const double greetingTurnDeg = -4;

  static const double countFont = 170;
  static const double countOutline = 14;
  static const String go = 'GO!';
  static const double goFont = 120;
  static const double shoutFont = 46;
  static const double shoutOutline = 11;
  static const double shoutTurnDeg = -5;

  /// The focus lines behind each number, GO! and the end lettering.
  static const BurstSpec burst = BurstSpec(
      box: Size(390, 844), center: Offset(195, 422), count: 120, innerMin: 120, innerMax: 170, width: 4, seed: 31,
      color: Palette.paper);
  static const double burstFrom = 0.6;
  static const double burstTo = 1.5;
}

/// The exam's timeline: the greeting, the count of three, GO!, and the
/// pause on the board once the race is decided.
abstract final class ExamMotion {
  static const Duration greeting = Duration(milliseconds: 2400);
  static const greetingTobi = EntranceSpec(Entrances.pop,
      duration: Duration(milliseconds: 400), delay: Duration(milliseconds: 100), curve: Entrances.bouncy);
  static const greetingFirst = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 350), curve: Entrances.springy);
  static const greetingSecond = EntranceSpec(Entrances.slam,
      duration: Duration(milliseconds: 420), delay: Duration(milliseconds: 650), curve: Entrances.springy);
  static const greetingSub =
      EntranceSpec(Entrances.pop, duration: Duration(milliseconds: 300), delay: Duration(milliseconds: 1000));

  /// Each of 3, 2, 1, slamming in at the start of its beat.
  static const int count = 3;
  static const Duration beat = Duration(milliseconds: 800);
  static const number = EntranceSpec(Entrances.thump, duration: Duration(milliseconds: 280), curve: Entrances.springy);
  static const burst = EntranceSpec(Entrances.custom, duration: Duration(milliseconds: 520), curve: Curves.easeOut);

  /// GO! lands as play starts, then fades off the board.
  static const goIn = EntranceSpec(Entrances.thump, duration: Duration(milliseconds: 240), curve: Entrances.springy);
  static const Duration go = Duration(milliseconds: 750);

  static Duration get start => greeting + beat * count;

  static const shout = EntranceSpec(Entrances.slam, duration: Duration(milliseconds: 450), curve: Entrances.springy);
  static Duration get shoutLength => shout.end > burst.end ? shout.end : burst.end;
  static const Duration won = Duration(milliseconds: 2000);
  static const Duration lost = Duration(milliseconds: 1600);

  /// A card of Tobi's: nudged for this long before it goes, then flying.
  static const Duration reach = Duration(milliseconds: 160);
  static const Duration fly = Duration(milliseconds: 320);

  /// A quick card of his flashes for this long as it goes; a mistake of
  /// his has him shocked for this long.
  static const Duration quickFlash = Duration(milliseconds: 420);
  static const Duration tobiShock = Duration(milliseconds: 1000);

  static const Duration penaltyPop = Duration(milliseconds: 900);
}

/// The exam's sheets (`exam_sheets.dart`), on the ranked sheets' metrics.
abstract final class ExamSheetStyle {
  static const Color tag = Palette.ink;
  static const Color tagText = Palette.sun;
}
