import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'run_launcher.dart';

/// "Learn next cards →": unlocks the next batch now and starts a training
/// round with it (see [startLearnNext]). [replace]: from Results, swapping it
/// for the round.
class LearnNextButton extends StatelessWidget {
  const LearnNextButton({super.key, this.replace = false, this.height = LearnNextStyle.height});

  final bool replace;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: height,
      child: InkButton(
        color: Palette.sun,
        padding: LearnNextStyle.padding,
        semanticLabel: s.learnNext,
        onTap: () => startLearnNext(context, replace: replace),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(
              s.learnNext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: Weights.black, fontSize: LearnNextStyle.font),
            ),
          ),
          const SizedBox(width: LearnNextStyle.iconGap),
          const MangaIcon(IconArt.arrow, size: LearnNextStyle.icon),
        ]),
      ),
    );
  }
}
