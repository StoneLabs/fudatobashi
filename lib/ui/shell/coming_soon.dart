import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../manga/manga.dart';

/// Tobi holding the spot for a screen that is still being built.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox.fromSize(
          size: ComingSoonStyle.box,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Placed(ComingSoonStyle.tobi, child: Tobi(pose: TobiPose.pointing)),
              Placed(
                ComingSoonStyle.balloon,
                child: SpeechBalloon(
                  speaker: ComingSoonStyle.speaker,
                  child: Text(message, style: const TextStyle(fontSize: TypeScale.button)),
                ),
              ),
            ],
          ),
        ),
      );
}
