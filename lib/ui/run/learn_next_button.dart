import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'run_launcher.dart';

/// Results' "Learn next cards →": unlocks the next batch now and swaps
/// Results for a training round with it (see [startLearnNext]).
class LearnNextButton extends StatelessWidget {
  const LearnNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LearnNextStyle.height),
      child: InkButton(
        color: Palette.sun,
        padding: LearnNextStyle.padding,
        semanticLabel: s.learnNext,
        onTap: () => startLearnNext(context),
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
