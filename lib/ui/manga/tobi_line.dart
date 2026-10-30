import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import 'balloon.dart';
import 'tobi.dart';

/// Tobi saying [line] in a balloon to his right. With [phrases], Japanese
/// breaks its lines only where the line marks its phrases ([Phrases]).
class TobiLine extends StatelessWidget {
  const TobiLine(this.line, {super.key, this.pose = TobiPose.standard, this.phrases = false});

  final String line;
  final TobiPose pose;
  final bool phrases;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        SizedBox.fromSize(size: TobiLineLayout.tobi, child: Tobi(pose: pose)),
        const SizedBox(width: TobiLineLayout.balloonGap),
        Expanded(
          child: SpeechBalloon(
            speaker: TobiLineLayout.speakerLeft,
            padding: TobiLineLayout.balloonPadding,
            child: BalloonText(line, style: const TextStyle(fontSize: TobiLineLayout.balloonFont), phrases: phrases),
          ),
        ),
      ]);
}
