import '../../domain/trainer.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../manga/manga.dart';
import 'tour_anchor.dart';

/// One stop of Tobi's tour: what Tobi says, in which pose, and what the
/// spotlight is on (nothing for a stop that is just Tobi talking). The
/// [practice] stop plays the tutorial round before the tour goes on.
class TourStep {
  const TourStep(this.line, this.pose, {this.spot, this.practice = false});

  final String Function(S s) line;
  final TobiPose pose;
  final TourSpot? spot;
  final bool practice;

  /// The tour of Home in [mode]: what 札飛ばし is, then its buttons (the
  /// journey's islands, or all-known mode's own), the practice round, and
  /// off to 修行.
  static List<TourStep> of(LearningMode mode) => [
        TourStep((s) => s.tourWelcome, TobiPose.waving, spot: TourSpot.brand),
        TourStep((s) => s.tourWhat, TobiPose.fired),
        if (mode == LearningMode.journey)
          TourStep((s) => s.tourSrsJourney, TobiPose.relaxed)
        else
          TourStep((s) => s.tourSrsKnown, TobiPose.relaxed),
        if (mode == LearningMode.journey) ...[
          TourStep((s) => s.tourTraining, TobiPose.pointing, spot: TourSpot.training),
          TourStep((s) => s.tourMap, TobiPose.pointing, spot: TourSpot.map),
          TourStep((s) => s.tourIslandPlan, TobiPose.pointing, spot: TourSpot.islandPlan),
        ] else ...[
          TourStep((s) => s.tourRank, TobiPose.pointing, spot: TourSpot.rank),
          TourStep((s) => s.tourTraining, TobiPose.pointing, spot: TourSpot.training),
          TourStep((s) => s.tourModes, TobiPose.pointing, spot: TourSpot.modes),
          TourStep((s) => s.tourGuest, TobiPose.pointing, spot: TourSpot.guest),
        ],
        TourStep((s) => s.tourLevel, TobiPose.pointing, spot: TourSpot.level),
        TourStep((s) => s.tourTabs, TobiPose.pointing, spot: TourSpot.tabs),
        TourStep((s) => s.tourSettings, TobiPose.pointing, spot: TourSpot.settings),
        TourStep((s) => s.tourPractice, TobiPose.tryHard, practice: true),
        TourStep((s) => s.tourFinale, TobiPose.cheering, spot: TourSpot.training),
      ];
}
