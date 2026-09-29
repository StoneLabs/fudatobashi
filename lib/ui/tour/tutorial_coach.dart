import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/play_session.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';

/// What Tobi says during the tutorial round.
enum CoachLine {
  startCard,
  knowIt,
  dontKnowHold,
  dontKnowButton,
  dontKnowOff,
  fast,
  done,
  retryKnow,
  retryHold,
  retryButton;

  String text(S s, String kana) => switch (this) {
        startCard => s.coachStartCard,
        knowIt => s.coachKnowIt(kana),
        dontKnowHold => s.coachDontKnowHold,
        dontKnowButton => s.coachDontKnowButton,
        dontKnowOff => s.coachDontKnowOff,
        fast => s.coachFast,
        done => s.coachDone,
        retryKnow => s.coachRetryKnow,
        retryHold => s.coachRetryHold,
        retryButton => s.coachRetryButton,
      };

  TobiPose get pose => switch (this) {
        startCard => TobiPose.waving,
        knowIt || dontKnowOff => TobiPose.pointing,
        dontKnowHold || dontKnowButton => TobiPose.relaxed,
        fast => TobiPose.fired,
        done => TobiPose.cheering,
        retryKnow || retryHold || retryButton => TobiPose.tryHard,
      };
}

/// The tutorial round's plan: the first card leaves as "I know it", the
/// second as "I don't remember" (the way the player's [input] marks it),
/// the third any way, fast. A card swiped the other way comes back for
/// another go.
class TutorialScript {
  const TutorialScript(this.input);

  final DontKnowInput input;

  /// How card [index] has to leave, or null for any way.
  Outcome? expected(int index) => switch (index) {
        0 => Outcome.known,
        1 when input != DontKnowInput.off => Outcome.dontKnow,
        _ => null,
      };

  /// Tobi's line before the start card is gone, on card [index], once the
  /// round is [finished], or while a card is back because it left as
  /// [retried].
  CoachLine line({required bool started, required int index, required bool finished, Outcome? retried}) {
    if (finished) return CoachLine.done;
    if (!started) return CoachLine.startCard;
    if (retried == Outcome.dontKnow) return CoachLine.retryKnow;
    if (retried == Outcome.known) return input == DontKnowInput.hold ? CoachLine.retryHold : CoachLine.retryButton;
    return switch (index) {
      0 => CoachLine.knowIt,
      1 => switch (input) {
          DontKnowInput.hold => CoachLine.dontKnowHold,
          DontKnowInput.button => CoachLine.dontKnowButton,
          DontKnowInput.off => CoachLine.dontKnowOff,
        },
      _ => CoachLine.fast,
    };
  }
}

/// Tobi under the tutorial round's card, saying [line]; each new line pops
/// in.
class TutorialCoach extends StatelessWidget {
  const TutorialCoach({super.key, required this.line, required this.kana});

  final CoachLine line;

  /// The kana of the card on top, for the lines that name it.
  final String kana;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: TutorialStyle.padding,
      child: Row(children: [
        SizedBox(
          height: TutorialStyle.tobiHeight,
          width: TutorialStyle.tobiHeight * TobiStyle.aspect,
          child: Tobi(key: ValueKey(line.pose), pose: line.pose),
        ),
        const SizedBox(width: TutorialStyle.gap),
        Expanded(
          child: AnimatedSwitcher(
            duration: still ? Duration.zero : TutorialStyle.linePop,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: TutorialStyle.linePopFrom, end: 1.0)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: SpeechBalloon(
              key: ValueKey(line),
              speaker: TutorialStyle.speaker,
              padding: TutorialStyle.balloonPadding,
              child: Text.rich(
                Phrases.span(line.text(S.of(context), kana)),
                style: const TextStyle(fontSize: TutorialStyle.font),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
