import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../state/scope.dart';
import '../sound/sounds.dart';
import 'celebration_overlays.dart';
import 'celebrations.dart';
import 'island_complete_overlay.dart';
import 'new_card_overlay.dart';
import 'rank_up_overlay.dart';
import 'xp_overlay.dart';

/// Celebration [pages] one after another over an opaque backdrop: the
/// sequence fades in, cross-fades between pages, and after the last one
/// fades out and lets go of the screen, calling [onDone] once it is fully
/// gone (play resumes only then).
class CelebrationSequence extends StatefulWidget {
  const CelebrationSequence({super.key, required this.pages, required this.onDone});

  final List<Celebration> pages;
  final VoidCallback onDone;

  @override
  State<CelebrationSequence> createState() => _CelebrationSequenceState();
}

class _CelebrationSequenceState extends State<CelebrationSequence> with SingleTickerProviderStateMixin {
  late final _presence = AnimationController(vsync: this, duration: ResultsLayout.overlayFade);
  int _shown = 0;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_leaving) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _presence.value = 1;
    } else if (_presence.isDismissed) {
      _presence.forward();
    }
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  /// Page [from] is done; a late tap on a page already fading out is ignored.
  void _next(int from) {
    if (from != _shown || _leaving) return;
    if (_shown + 1 < widget.pages.length) {
      setState(() => _shown++);
      return;
    }
    setState(() => _leaving = true);
    if (MediaQuery.disableAnimationsOf(context)) {
      widget.onDone();
      return;
    }
    _presence.reverse().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    final i = _shown;
    return IgnorePointer(
      ignoring: _leaving,
      child: FadeTransition(
        opacity: _presence,
        child: ColoredBox(
          color: Palette.paper,
          child: AnimatedSwitcher(
            duration: ResultsLayout.overlayFade,
            child: SoundCues(
              key: ValueKey(i),
              cues: _soundsOf(widget.pages[i]),
              child: _page(widget.pages[i], () => _next(i)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _page(Celebration c, VoidCallback onNext) {
    final progress = ProgressScope.read(context);
    return switch (c) {
      NewCardCelebration() => NewCardOverlay(data: c, onNext: onNext),
      ConfusableWarningCelebration() => ConfusableWarningOverlay(data: c, onNext: onNext),
      IslandCompleteCelebration() => IslandCompleteOverlay(
          islandIndex: c.islandIndex,
          islandsDone: progress.islands.where((i) => i.complete).length,
          cardsUnlocked: progress.trainer.unlocked.where((s) => !s.key.inverted).length,
          onNext: onNext,
        ),
      RankUpCelebration() => RankUpOverlay(data: c, onNext: onNext),
      GoalUpCelebration() => GoalUpOverlay(goalMs: progress.trainer.goalMs.round(), onNext: onNext),
      GraduationCelebration() => GoalUpOverlay(goalMs: progress.trainer.goalMs.round(), onNext: onNext),
      XpCelebration() => XpOverlay(gain: c.gain, onNext: onNext),
      LevelUpCelebration() => GoalUpOverlay(goalMs: progress.trainer.goalMs.round(), onNext: onNext),
    };
  }
}

/// Each page's sounds, in step with its entrance.
List<(Sfx, Duration)> _soundsOf(Celebration c) => switch (c) {
      NewCardCelebration() => const [(Sfx.cardAppears, NewCardMotion.landAt)],
      ConfusableWarningCelebration() => const [(Sfx.lookAlike, Duration.zero)],
      IslandCompleteCelebration() => [(Sfx.island, IslandCompleteMotion.title.delay)],
      RankUpCelebration() => const [(Sfx.stamp, RankUpMotion.impactAt), (Sfx.rankUp, RankUpMotion.impactAt)],
      GoalUpCelebration() => const [(Sfx.goalUp, Duration.zero)],
      GraduationCelebration() => const [],
      XpCelebration() => XpTimeline(c.gain).sounds,
      LevelUpCelebration() => const [],
    };
