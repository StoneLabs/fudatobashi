import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../state/scope.dart';
import 'celebration_overlays.dart';
import 'celebrations.dart';
import 'island_complete_overlay.dart';
import 'new_card_overlay.dart';

/// Celebration [pages] one after another, cross-fading between them. After
/// the last one the sequence fades out and lets go of the screen, then calls
/// [onDone] once it is fully gone (play resumes only then).
class CelebrationSequence extends StatefulWidget {
  const CelebrationSequence({super.key, required this.pages, required this.onDone});

  final List<Celebration> pages;
  final VoidCallback onDone;

  @override
  State<CelebrationSequence> createState() => _CelebrationSequenceState();
}

class _CelebrationSequenceState extends State<CelebrationSequence> with SingleTickerProviderStateMixin {
  late final _presence = AnimationController(vsync: this, duration: ResultsLayout.overlayFade, value: 1);
  int _shown = 0;
  bool _leaving = false;

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
        child: AnimatedSwitcher(
          duration: ResultsLayout.overlayFade,
          child: KeyedSubtree(key: ValueKey(i), child: _page(widget.pages[i], () => _next(i))),
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
    };
  }
}
