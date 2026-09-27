import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/play_session.dart';
import '../../domain/rating.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_launcher.dart';
import '../torifuda/torifuda_painter.dart';
import 'celebration_overlays.dart';
import 'celebrations.dart';

/// Results (spec phone 5): a splash of the run's numbers, then the earned
/// celebrations in sequence, each tap-anywhere-to-skip.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.report, required this.config});

  final SessionReport report;
  final PlayConfig config;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final List<Celebration> _celebrations;
  int _shown = -1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _celebrations = celebrationsFor(widget.report, ProgressScope.read(context));
    if (_celebrations.isNotEmpty) {
      _timer = Timer(ResultsLayout.overlayStagger, () {
        if (mounted) setState(() => _shown = 0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _advance() => setState(() => _shown++);

  void _home(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final overlayWidget =
        _shown >= 0 && _shown < _celebrations.length ? _buildOverlay(_celebrations[_shown], progress) : null;
    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(children: [
        SafeArea(child: _Splash(report: widget.report, config: widget.config, onHome: () => _home(context))),
        AnimatedSwitcher(
          duration: ResultsLayout.overlayFade,
          child: overlayWidget == null
              ? const SizedBox.shrink(key: ValueKey('none'))
              : KeyedSubtree(key: ValueKey(_shown), child: overlayWidget),
        ),
      ]),
    );
  }

  Widget _buildOverlay(Celebration c, Progress progress) => switch (c) {
        NewCardCelebration() => NewCardOverlay(data: c, onNext: _advance),
        ConfusableWarningCelebration() => ConfusableWarningOverlay(data: c, onNext: _advance),
        IslandCompleteCelebration() => IslandCompleteOverlay(
            islandIndex: c.islandIndex,
            islandsDone: progress.islands.where((i) => i.complete).length,
            cardsUnlocked: progress.trainer.unlocked.where((s) => !s.key.inverted).length,
            onNext: _advance,
          ),
        RankUpCelebration() => RankUpOverlay(data: c, onNext: _advance),
        GoalUpCelebration() => GoalUpOverlay(goalMs: progress.trainer.goalMs.round(), onNext: _advance),
      };
}

class _Splash extends StatelessWidget {
  const _Splash({required this.report, required this.config, required this.onHome});
  final SessionReport report;
  final PlayConfig config;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final attempts = report.attempts;
    final known = attempts.where((a) => !a.isMiss).length;
    final avgMs = attempts.isEmpty ? 0.0 : attempts.map((a) => a.responseUs / 1000).reduce((a, b) => a + b) / attempts.length;
    final toughest = [
      for (final a in attempts)
        if (!a.tainted && !a.isMiss) a,
    ]..sort((a, b) => b.responseUs.compareTo(a.responseUs));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: HeaderStyle.topGap),
        Row(children: [
          InkTag('${_modeLabel(s, config.mode)} Β· ${s.cardsCount(attempts.length)}'),
          const Spacer(),
          InkIconButton(icon: IconArt.close, semanticLabel: s.home, onTap: onHome),
        ]),
        if (progress.knownCardSpeedMs != null) ...[
          const SizedBox(height: ResultsLayout.knownSpeedGap),
          _KnownSpeedNote(ms: progress.knownCardSpeedMs!, weekAgoMs: progress.knownCardSpeedTrendAgo),
        ],
        const SizedBox(height: Gaps.section),
        if (!config.tracked) ...[
          DashedBox(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Text(s.guestNotRecorded)),
          const SizedBox(height: Gaps.section),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _TimePanel(report: report),
              const SizedBox(height: Gaps.panel),
              Row(children: [
                Expanded(
                  child: _StatPanel(
                    label: s.avgPerCardLabel,
                    big: (avgMs / 1000).toStringAsFixed(3),
                    unit: 's',
                    note: s.knownOf(known, attempts.length),
                  ),
                ),
                const SizedBox(width: Gaps.panel),
                Expanded(child: _RatingPanel(before: report.ratingBefore, after: report.ratingAfter)),
              ]),
              if (toughest.isNotEmpty) ...[
                const SizedBox(height: Gaps.panel),
                _ToughestPanel(attempts: toughest.take(3).toList()),
              ],
            ]),
          ),
        ),
        const SizedBox(height: Gaps.section),
        SizedBox(
          height: ResultsLayout.actionRowHeight,
          child: Row(children: [
            Expanded(child: ActionRowButton(icon: IconArt.home, label: s.home, sub: s.homeSub, onTap: onHome)),
            const SizedBox(width: PlayLayout.buttonGap),
            Expanded(
              flex: 2,
              child: ActionRowButton(
                icon: IconArt.refresh,
                label: s.keepGoing,
                sub: s.keepGoingSub,
                color: Palette.pink,
                onTap: () => keepGoing(context, config),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  static String _modeLabel(S s, PlayMode mode) => switch (mode) {
        PlayMode.training => s.training,
        PlayMode.nigate => s.weakCards,
        PlayMode.free => s.freePlay,
        PlayMode.guest => s.guest,
      };
}

/// A subtle line for `Progress.knownCardSpeedMs`, with a small up/down arrow
/// against a week ago (faster now points up).
class _KnownSpeedNote extends StatelessWidget {
  const _KnownSpeedNote({required this.ms, required this.weekAgoMs});
  final double ms;
  final double? weekAgoMs;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final weekAgo = weekAgoMs;
    final faster = weekAgo != null && ms < weekAgo;
    final slower = weekAgo != null && ms > weekAgo;
    const noteStyle =
        TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.knownSpeedNoteFont, color: Palette.inkSoft);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      NumberedText(
        s.knownSpeedNote,
        [(ms / 1000).toStringAsFixed(2)],
        style: noteStyle,
        numberStyle: noteStyle.copyWith(fontFamily: Fonts.display, fontWeight: Weights.regular),
      ),
      if (faster || slower) ...[
        const SizedBox(width: ResultsLayout.knownSpeedGap),
        Transform.rotate(
          angle: (faster ? -90 : 90) * math.pi / 180,
          child: const MangaIcon(IconArt.chevron, size: ResultsLayout.knownSpeedTrendIcon, color: Palette.inkSoft),
        ),
      ],
    ]);
  }
}

class _TimePanel extends StatelessWidget {
  const _TimePanel({required this.report});
  final SessionReport report;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final total = report.total;
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, ResultsLayout.splashCut)),
      art: const [
        RadialLayer(center: Backdrops.skyCenter, colors: Backdrops.skyColors, stops: Backdrops.skyStops),
        BurstLayer(ResultsLayout.splashBurst),
      ],
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: SizedBox(
        height: ResultsLayout.splashHeight - 36,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(total == null ? s.endedEarly : s.totalTime.toUpperCase(),
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: ResultsLayout.splashLabelFont,
                  letterSpacing: ResultsLayout.splashLabelTracking * ResultsLayout.splashLabelFont)),
          const SizedBox(height: Gaps.small),
          if (total != null)
            OutlinedText(formatRunTime(total),
                style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.splashTimeFont, height: 1),
                outlineWidth: ResultsLayout.splashTimeOutline),
          if (report.personalBest && total != null) ...[
            const SizedBox(height: Gaps.section),
            Sticker(
              child: Text(s.personalBest.toUpperCase(),
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.splashPbFont)),
            ),
            const SizedBox(height: Gaps.tight),
            Text(
              report.previousBest == null ? s.firstRecordedRun : '${s.previousBest} ${formatRunTime(report.previousBest!)}',
              style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.splashPbNoteFont),
            ),
          ],
        ]),
      ),
    );
  }
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({required this.label, required this.big, required this.unit, required this.note});
  final String label, big, unit, note;

  @override
  Widget build(BuildContext context) => MangaPanel(
        color: Palette.seaSoft,
        tone: Tones.sea,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SizedBox(
          height: ResultsLayout.statPanelHeight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: ResultsLayout.statLabelFont,
                    letterSpacing: ResultsLayout.statLabelTracking * ResultsLayout.statLabelFont)),
            Text.rich(TextSpan(children: [
              TextSpan(text: big, style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.statBigFont, height: 1.05)),
              TextSpan(text: ' $unit', style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.statBigUnitFont, height: 1)),
            ])),
            Text(note, style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.statNoteFont)),
          ]),
        ),
      );
}

class _RatingPanel extends StatelessWidget {
  const _RatingPanel({required this.before, required this.after});
  final double? before, after;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final delta = (before != null && after != null) ? (after! - before!).round() : null;
    final band = after == null ? null : Rating.bandOf(after!);
    return MangaPanel(
      color: Palette.pinkSoft,
      tone: Tones.pink,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SizedBox(
        height: ResultsLayout.statPanelHeight,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(s.rating.toUpperCase(),
              style: const TextStyle(
                  fontWeight: Weights.black,
                  fontSize: ResultsLayout.statLabelFont,
                  letterSpacing: ResultsLayout.statLabelTracking * ResultsLayout.statLabelFont)),
          OutlinedText(
            delta == null ? '—' : (delta >= 0 ? '+$delta' : '$delta'),
            style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.statBigFont, color: Palette.pink, height: 1.05),
            outline: Palette.ink,
            outlineWidth: 1.4,
          ),
          if (after != null && band != null)
            Text('${before?.round() ?? s.newBadge} β†’ ${after!.round()} Β· ${band.label}',
                style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.statNoteFont)),
        ]),
      ),
    );
  }
}

class _ToughestPanel extends StatelessWidget {
  const _ToughestPanel({required this.attempts});
  final List<Attempt> attempts;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MangaPanel(
      padding: ResultsLayout.toughPadding,
      child: SizedBox(
        height: ResultsLayout.toughHeight - 24,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: ResultsLayout.toughHeaderWidth,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(s.toughestHeading, style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.toughHeadingFont, height: 1)),
              const SizedBox(height: Gaps.tight),
              Text(s.slowest, style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.toughLabelFont)),
              const SizedBox(height: Gaps.tight),
              Text(s.toughestNote, style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.toughNoteFont, color: Palette.inkSoft)),
            ]),
          ),
          const SizedBox(width: Gaps.section),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final a in attempts) _ToughCard(a)],
            ),
          ),
        ]),
      ),
    );
  }
}

class _ToughCard extends StatelessWidget {
  const _ToughCard(this.attempt);
  final Attempt attempt;

  @override
  Widget build(BuildContext context) {
    final ms = attempt.responseUs / 1000;
    final tier = SpeedTiers.of(ms);
    return SizedBox(
      width: ResultsLayout.toughCardWidth,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TorifudaCard(poem: poems[attempt.card.poemId], inverted: attempt.card.inverted),
        const SizedBox(height: Gaps.tight),
        DecoratedBox(
          decoration: BoxDecoration(color: Palette.tiers[tier], border: Border.all(color: Palette.ink, width: Strokes.control)),
          child: Padding(
            padding: ResultsLayout.toughTimePadding,
            child: Text.rich(TextSpan(children: [
              TextSpan(text: (ms / 1000).toStringAsFixed(3), style: const TextStyle(fontFamily: Fonts.display)),
              const TextSpan(text: 's', style: TextStyle(fontFamily: Fonts.display)),
            ]), style: TextStyle(fontSize: ResultsLayout.toughTimeFont, color: Palette.tierText[tier], height: 1)),
          ),
        ),
        const SizedBox(height: Gaps.tight),
        Text(poems[attempt.card.poemId].kimariji,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.toughKimarijiFont)),
      ]),
    );
  }
}
