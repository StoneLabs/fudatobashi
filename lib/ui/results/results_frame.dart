import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../sound/sounds.dart';
import 'celebration_sequence.dart';
import 'celebrations.dart';

/// A game's results screen around its summary ([child]): the game's
/// [celebrations] play over it first, each tap-anywhere-to-skip.
class ResultsFrame extends StatefulWidget {
  const ResultsFrame({super.key, required this.celebrations, required this.child});

  /// The pages to play, in order; none when the game earned none.
  final List<Celebration> celebrations;
  final Widget child;

  @override
  State<ResultsFrame> createState() => _ResultsFrameState();
}

class _ResultsFrameState extends State<ResultsFrame> {
  late final List<Celebration> _celebrations = widget.celebrations;
  bool _celebrating = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_celebrations.isNotEmpty) {
      // Kept silent (the game already faded the music out) until the
      // celebration, which has its own jingles, is done; and upright, as
      // its pages are laid out for, after a game played in landscape too.
      music.leaveMenu();
      unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.app));
      _timer = Timer(ResultsLayout.overlayStagger, () {
        if (mounted) setState(() => _celebrating = true);
      });
    } else {
      music.enterMenu();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_celebrations.isNotEmpty && !_celebrated) _releaseOrientation();
    super.dispose();
  }

  /// The celebration has played to its end.
  bool _celebrated = false;

  static void _releaseOrientation() => unawaited(SystemChrome.setPreferredOrientations(OrientationTuning.app));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.paper,
        body: SoundCues(
          cues: const [(Sfx.results, Duration.zero)],
          child: Stack(children: [
            widget.child,
            if (_celebrating)
              Positioned.fill(
                child: CelebrationSequence(
                  pages: _celebrations,
                  onDone: () {
                    setState(() {
                      _celebrating = false;
                      _celebrated = true;
                    });
                    music.enterMenu();
                    _releaseOrientation();
                  },
                ),
              ),
          ]),
        ),
      );
}
