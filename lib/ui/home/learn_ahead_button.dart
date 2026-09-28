import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/trainer.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../run/run_launcher.dart';

/// Home's "Learn next cards" (journey): pulls the next batch in ahead of the
/// pace, for players who learn faster than it. Locked until every card is
/// well remembered and today's new cards are done (`Progress.learnAhead`);
/// a locked tap pops a balloon saying what is left.
class LearnAheadButton extends StatelessWidget {
  const LearnAheadButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ahead = ProgressScope.of(context).learnAhead();
    final open = ahead.open;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LearnAheadStyle.minHeight),
      child: InkButton(
        color: open ? Palette.sun : Palette.desk,
        padding: LearnAheadStyle.padding,
        semanticLabel: open ? s.learnNext : s.learnNextLocked,
        onTap: () => open
            ? startLearnNext(context)
            : BalloonPop.show(context, _whyLocked(s, ahead),
                size: LearnAheadStyle.balloon, life: LearnAheadStyle.balloonLife),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (!open) ...[
              MangaIcon(IconArt.lock, size: LearnAheadStyle.icon),
              const SizedBox(width: LearnAheadStyle.iconGap),
            ],
            Text(s.learnNext, style: const TextStyle(fontWeight: Weights.black, fontSize: LearnAheadStyle.font)),
            if (open) ...[
              const SizedBox(width: LearnAheadStyle.iconGap),
              MangaIcon(IconArt.arrow, size: LearnAheadStyle.icon),
            ],
          ]),
        ),
      ),
    );
  }

  static String _whyLocked(S s, LearnAhead ahead) => switch (ahead.lock) {
        LearnAheadLock.newCardsPending => s.learnNextPending,
        _ => s.learnNextShaky(ahead.shaky),
      };
}
