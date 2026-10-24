import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/reminders.dart';
import '../../state/scope.dart';
import '../sound/sounds.dart';
import 'celebration_sequence.dart';
import 'celebrations.dart';
import 'main_summary.dart';
import 'reminder_offer.dart';

/// Results (spec phone 5): the run's summary, then the earned celebrations
/// over it in sequence, each tap-anywhere-to-skip, and after them, once
/// ever, Tobi's offer of daily reminders.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.report, required this.config});

  final SessionReport report;
  final PlayConfig config;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final List<Celebration> _celebrations = celebrationsFor(widget.report);
  bool _celebrating = false;
  Timer? _timer;

  /// Decided as the screen opens: offering marks the offer made.
  late final bool _offerDue;
  bool _offering = false;

  @override
  void initState() {
    super.initState();
    _offerDue = remindersOfferDue(ProgressScope.read(context), widget.report);
    if (_celebrations.isNotEmpty) {
      // Kept silent (the run's own PlayScreen already faded music out) until
      // the celebration, which has its own jingles, is done.
      music.leaveMenu();
      _timer = Timer(ResultsLayout.overlayStagger, () {
        if (mounted) setState(() => _celebrating = true);
      });
    } else {
      music.enterMenu();
      if (_offerDue) _timer = Timer(ResultsLayout.overlayStagger, _offerReminders);
    }
  }

  void _offerReminders() {
    if (!mounted) return;
    final progress = ProgressScope.read(context);
    unawaited(progress.updateSettings(progress.settings.copyWith(remindersOffered: true)));
    setState(() => _offering = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.paper,
        body: SoundCues(
          cues: const [(Sfx.results, Duration.zero)],
          child: Stack(children: [
            MainRunSummary(report: widget.report, config: widget.config),
            if (_celebrating)
              Positioned.fill(
                child: CelebrationSequence(
                  pages: _celebrations,
                  onDone: () {
                    setState(() => _celebrating = false);
                    music.enterMenu();
                    if (_offerDue) _offerReminders();
                  },
                ),
              ),
            if (_offering) Positioned.fill(child: ReminderOffer(onDone: () => setState(() => _offering = false))),
          ]),
        ),
      );
}
