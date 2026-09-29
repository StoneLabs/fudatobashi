import '../../domain/trainer.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../manga/manga.dart';
import 'tour_anchor.dart';

/// One stop of Tobi's tour: what Tobi says, in which pose, and what the
/// spotlight is on. A stop with a [spot] only moves on once the player taps
/// it (a miss just jolts the arrows); a stop with none — just Tobi talking —
/// moves on with the balloon's own continue button instead. The [practice]
/// stop's spot is the real 修行 button: tapping it starts the tutorial
/// round for real, and the stop only moves on once that round is won.
class TourStep {
  const TourStep(this.line, this.pose, {this.spot, this.practice = false});

  final String Function(S s) line;
  final TobiPose pose;
  final TourSpot? spot;
  final bool practice;

  /// The tour of Home in [mode]: what 札飛ばし is, then its buttons (the
  /// journey's islands, or all-known mode's own), the tabs (chains only
  /// when some are [tabsLocked]) and Settings, then 修行 for the practice
  /// round, and a send-off.
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
        TourStep((s) => s.tourTraining, TobiPose.tryHard, spot: TourSpot.training, practice: true),
        TourStep((s) => s.tourFinale, TobiPose.cheering),
      ];
}
