import '../../config/config.dart';
import '../../domain/trainer.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import 'tour_anchor.dart';

/// One stop of Tobi's tour: what Tobi says, in which pose, and what the
/// spotlight is on. A stop moves on once the player taps its [spot] or
/// Tobi's balloon (a tap elsewhere just jolts the arrows). The [practice]
/// stop's spot is the real 修行 button: tapping it starts the tutorial
/// round for real, and the stop only moves on once that round is won. The
/// [firstCard] stop plays the journey's first real card the same way.
class TourStep {
  const TourStep(this.line, this.pose, {this.spot, this.practice = false, this.firstCard = false, this.voice, this.hint});

  final String Function(S s) line;
  final TobiPose pose;
  final TourSpot? spot;
  final bool practice;
  final bool firstCard;

  /// The poem whose kimariji the reader reads out as this stop shows.
  final int? voice;

  /// The stop starts a round, which it waits for.
  bool get playsRound => practice || firstCard;

  /// The line under Tobi's words saying what a tap does, when not the
  /// tour's own.
  final String Function(S s)? hint;

  /// The tour of Home in [mode]: what 札飛ばし is, then its buttons (the
  /// journey's islands, or all-known mode's own), the tabs (chains only
  /// when some are [tabsLocked]) and Settings, then the big button (修行,
  /// or all-known mode's ランク戦) for the practice round, in the journey
  /// 修行 again for the first real card, and a send-off.
  static List<TourStep> of(LearningMode mode, {required bool tabsLocked}) => [
        TourStep((s) => s.tourWelcome, TobiPose.waving),
        TourStep((s) => s.tourWhat, TobiPose.fired),
        if (mode == LearningMode.journey)
          TourStep((s) => s.tourSrsJourney, TobiPose.relaxed)
        else
          TourStep((s) => s.tourSrsKnown, TobiPose.relaxed),
        if (mode == LearningMode.journey) ...[
          TourStep((s) => s.tourMap, TobiPose.pointing, spot: TourSpot.map),
          TourStep((s) => s.tourIslandPlan, TobiPose.pointing, spot: TourSpot.islandPlan),
        ] else ...[
          TourStep((s) => s.tourRank, TobiPose.pointing, spot: TourSpot.rank),
          TourStep((s) => s.tourModes, TobiPose.pointing, spot: TourSpot.modes),
          TourStep((s) => s.tourGuest, TobiPose.pointing, spot: TourSpot.guest),
        ],
        TourStep((s) => s.tourLevel, TobiPose.pointing, spot: TourSpot.level),
        TourStep((s) => tabsLocked ? s.tourTabs : s.tourTabsOpen, TobiPose.pointing, spot: TourSpot.tabs),
        TourStep((s) => s.tourSettings, TobiPose.pointing, spot: TourSpot.settings),
        TourStep((s) => s.tourHelp, TobiPose.relaxed, spot: TourSpot.settings),
        TourStep((s) => mode == LearningMode.journey ? s.tourTraining : s.tourRanked, TobiPose.tryHard,
            spot: TourSpot.training, practice: true),
        if (mode == LearningMode.journey)
          TourStep((s) => s.tourFirstCard, TobiPose.fired, spot: TourSpot.training, firstCard: true),
        TourStep((s) => mode == LearningMode.journey ? s.tourFinale : s.tourFinaleKnown, TobiPose.cheering),
      ];

  /// Tobi pointing at the exam strip as the exam first opens.
  static const examIntro = [TourStep(_examIntro, TobiPose.pointing, spot: TourSpot.exam, hint: _examIntroHint)];

  /// Tobi on the first real card's new card screen: what it is, the reader
  /// reading it out, its [kimariji], and how the app teaches every card.
  static List<TourStep> newCard(String kimariji) => [
        TourStep((s) => s.tourNewCard, TobiPose.waving, spot: TourSpot.newCard),
        TourStep((s) => s.tourReader, TobiPose.pointing, spot: TourSpot.newCardVoice, voice: TourTuning.firstCard),
        TourStep((s) => s.tourKimariji, TobiPose.relaxed, spot: TourSpot.newCardInfo),
        TourStep((s) => s.tourOneSound(kimariji), TobiPose.fired, spot: TourSpot.newCardVoice),
        TourStep((s) => s.tourAllCards, TobiPose.pointing, spot: TourSpot.newCardAccept, hint: _tapHint),
      ];

  /// Tobi in the practice round, before the card that practises marking a
  /// card forgotten: when and why to mark one the player's [input] way, and
  /// how to fix a wrong swipe with Undo.
  static List<TourStep> forgetting(DontKnowInput input) => [
        if (input == DontKnowInput.button)
          const TourStep(_whyForgetButton, TobiPose.relaxed)
        else
          const TourStep(_whyForgetHold, TobiPose.relaxed),
        const TourStep(_fixSwipe, TobiPose.pointing, spot: TourSpot.undo, hint: _tapHint),
      ];

  static String _whyForgetHold(S s) => s.tourWhyForgetHold;
  static String _whyForgetButton(S s) => s.tourWhyForgetButton;
  static String _fixSwipe(S s) => s.tourFixSwipe(s.undo);

  /// Tobi once the first real card is swiped: be honest, and mark a
  /// forgotten card the way the player's [input] does it.
  static List<TourStep> honesty(DontKnowInput input) => [
        const TourStep(_honest, TobiPose.relaxed),
        if (input == DontKnowInput.button)
          const TourStep(_forgotButton, TobiPose.pointing, spot: TourSpot.dontKnow)
        else
          const TourStep(_forgotHold, TobiPose.pointing),
        const TourStep(_learnAll, TobiPose.cheering, hint: _tapHint),
      ];

  static String _honest(S s) => s.tourHonest;
  static String _forgotButton(S s) => s.tourForgotButton;
  static String _forgotHold(S s) => s.tourForgotHold;
  static String _learnAll(S s) => s.tourLearnAll;
  static String _tapHint(S s) => s.tourTapHint;

  static String _examIntro(S s) => s.examIntro;
  static String _examIntroHint(S s) => s.examIntroHint;
}
