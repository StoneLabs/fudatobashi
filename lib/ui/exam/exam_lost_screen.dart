import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/exam_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/celebration_sequence.dart';
import '../results/celebrations.dart';
import '../sound/sounds.dart';

/// The page when Tobi wins a try at the graduation exam: both times, how far
/// the player got, the XP earned, and the time until the next try, counting
/// down. The XP pages play over it first, as on Results.
class ExamLostScreen extends StatefulWidget {
  const ExamLostScreen({
    super.key,
    required this.report,
    required this.tobi,
    required this.clock,
    required this.misses,
    required this.done,
    required this.total,
  });

  final SessionReport report;
  final Duration tobi;

  /// The player's clock when the try ended, before penalties.
  final Duration clock;
  final int misses;

  /// Cards swiped, of [total].
  final int done, total;

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
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
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

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cooldown = ProgressScope.of(context).exam().cooldown;
    final penaltyMs = widget.misses * ExamTuning.missPenaltyMs;
    final xp = widget.report.xp?.award.total ?? 0;
    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: HeaderStyle.topGap),
              Row(children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: InkTag(s.examTag, color: ExamSheetStyle.tag, textColor: ExamSheetStyle.tagText),
                    ),
                  ),
                ),
                const SizedBox(width: Gaps.panel),
                InkIconButton(icon: IconArt.close, semanticLabel: s.home, onTap: _home),
              ]),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _Banner(title: s.examLostTitle),
                    const SizedBox(height: Gaps.panel),
                    _Pair(
                      _Stat(
                        label: s.examTobiTime,
                        value: formatRunTime(widget.tobi),
                        color: ExamLostLayout.tobiFill,
                        tone: ExamLostLayout.tobiTone,
                      ),
                      _Stat(
                        label: s.examYourTime,
                        value: formatRunTime(widget.clock + Duration(milliseconds: penaltyMs)),
                        notes: [
                          if (widget.done < widget.total) s.examCardsLine(widget.done, widget.total),
                          s.examMissesLine(widget.misses, penaltyMs ~/ Duration.millisecondsPerSecond),
                        ],
                      ),
                    ),
                    const SizedBox(height: Gaps.panel),
                    _Pair(
                      _Stat(label: s.examXpEarned, value: '+$xp XP', color: ExamLostLayout.xpFill, tone: ExamLostLayout.xpTone),
                      _Stat(
                        label: cooldown == null ? s.examReady : s.examNextTry,
                        value: cooldown == null ? null : formatMinutes(cooldown),
                        color: ExamLostLayout.nextFill,
                        tone: ExamLostLayout.nextTone,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: Gaps.section),
              SizedBox(
                height: ResultsLayout.actionRowHeight,
                child: ActionRowButton(icon: IconArt.home, label: s.home, sub: s.homeSub, onTap: _home),
              ),
              const SizedBox(height: Gaps.section),
            ]),
          ),
        ),
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
}

/// "Tobi wins" on a sunburst, Tobi hopping for joy beside it.
class _Banner extends StatelessWidget {
  const _Banner({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        MangaPanel(
          shape: const PanelShape(bottomRight: Offset(0, ResultsLayout.splashCut)),
          color: ExamLostLayout.bannerFill,
          tone: ExamLostLayout.bannerTone,
          art: const [BurstLayer(ResultsLayout.splashBurst)],
          padding: ExamLostLayout.bannerPadding,
          child: Container(
            constraints: const BoxConstraints(minHeight: ExamLostLayout.bannerHeight),
            padding: EdgeInsets.only(right: ExamLostLayout.tobi.size.width + ExamLostLayout.titleGap),
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: OutlinedText(title,
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: ExamLostLayout.titleFont, height: 1),
                  outlineWidth: ExamLostLayout.titleOutline),
            ),
          ),
        ),
        const Placed(
          ExamLostLayout.tobi,
          child: Hop(
            height: PersonalBestMotion.hopHeight,
            period: PersonalBestMotion.hopPeriod,
            airShare: PersonalBestMotion.hopAirShare,
            child: Tobi(pose: TobiPose.cheering),
          ),
        ),
      ]);
}

/// Two panels side by side, as tall as the taller.
class _Pair extends StatelessWidget {
  const _Pair(this.left, this.right);
  final Widget left, right;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: left),
          const SizedBox(width: Gaps.panel),
          Expanded(child: right),
        ]),
      );
}

/// A panel: a label over a big value, and any notes under it.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.notes = const [], this.color = Palette.paper, this.tone});
  final String label;
  final String? value;
  final List<String> notes;
  final Color color;
  final ToneSpec? tone;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    return MangaPanel(
      color: color,
      tone: tone,
      padding: ExamLostLayout.panelPadding,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontWeight: Weights.black,
                fontSize: ExamLostLayout.labelFont,
                letterSpacing: ExamLostLayout.labelTracking * ExamLostLayout.labelFont)),
        if (value != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontFamily: Fonts.display, fontSize: ExamLostLayout.bigFont, height: 1.15)),
          ),
        for (final note in notes)
          Text(note, style: const TextStyle(fontWeight: Weights.bold, fontSize: ExamLostLayout.noteFont)),
      ]),
    );
  }
}
