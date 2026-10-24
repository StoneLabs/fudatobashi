import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';
import '../results/main_summary.dart';
import '../sound/sounds.dart';

/// The page when Tobi wins a try at the graduation exam: the try's summary,
/// with the time until the next try counting down. The XP pages play over
/// it first, as on Results.
class ExamLostScreen extends StatefulWidget {
  const ExamLostScreen({super.key, required this.report, required this.config});

  final SessionReport report;
  final PlayConfig config;

  @override
  State<ExamLostScreen> createState() => _ExamLostScreenState();
}

class _ExamLostScreenState extends State<ExamLostScreen> {
  late final List<Celebration> _celebrations = xpCelebrations(widget.report.xp);
  bool _celebrating = false;
  Timer? _stagger;
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(ExamStripStyle.tick, (_) => setState(() {}));
    if (_celebrations.isEmpty) {
      music.enterMenu();
      return;
    }
    music.leaveMenu();
    _stagger = Timer(ResultsLayout.overlayStagger, () {
      if (mounted) setState(() => _celebrating = true);
    });
  }

  @override
  void dispose() {
    _stagger?.cancel();
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.paper,
        body: Stack(children: [
          MainRunSummary(report: widget.report, config: widget.config),
          if (_celebrating)
            Positioned.fill(
              child: CelebrationSequence(
                pages: _celebrations,
                onDone: () {
                  setState(() => _celebrating = false);
                  music.enterMenu();
                },
              ),
            ),
        ]),
      );
}
