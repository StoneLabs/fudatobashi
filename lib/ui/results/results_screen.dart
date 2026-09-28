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
import '../run/learn_next_button.dart';
import 'celebration_sequence.dart';
import 'celebrations.dart';

/// Results (spec phone 5): a splash of the run's numbers and the round's new
/// cards, then the earned celebrations in sequence, each
/// tap-anywhere-to-skip.
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

  @override
  void initState() {
    super.initState();
    if (_celebrations.isNotEmpty) {
      final personalBest = widget.report.personalBest && widget.report.total != null;
      _timer = Timer(ResultsLayout.overlayStagger + (personalBest ? PersonalBestMotion.length : Duration.zero), () {
        if (mounted) setState(() => _celebrating = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _home(BuildContext context) => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Palette.paper,
        body: Stack(children: [
          SafeArea(child: _Splash(report: widget.report, config: widget.config, onHome: () => _home(context))),
          if (_celebrating)
            Positioned.fill(
              child: CelebrationSequence(
                pages: _celebrations,
                onDone: () => setState(() => _celebrating = false),
              ),
            ),
        ]),
      );
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
          InkTag('${_modeLabel(s, config.mode)} · ${s.cardsCount(attempts.length)}'),
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
              IntrinsicHeight(
                child: Row(children: [
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
              ),
              if (report.newCards.isNotEmpty) ...[
                const SizedBox(height: Gaps.panel),
                _CardShelf(
                  heading: s.newCardsHeading,
                  label: s.newCardsLabel,
                  note: s.newCardsNote,
                  cards: [for (final id in report.newCards) _NewCard(id)],
                ),
              ],
              if (toughest.isNotEmpty) ...[
                const SizedBox(height: Gaps.panel),
                _CardShelf(
                  heading: s.toughestHeading,
                  label: s.slowest,
                  note: s.toughestNote,
                  cards: [for (final a in toughest.take(ResultsLayout.toughCount)) _ToughCard(a)],
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: Gaps.section),
        if (config.tracked && progress.canLearnMore) ...[
          const LearnNextButton(),
          const SizedBox(height: Gaps.panel),
        ],
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

/// The run's total on a sunburst splash. A personal best plays out on it:
/// the time ticks down from the previous best, the PERSONAL BEST sticker
/// stamps on with ドン! and a jolt, and Tobi hops for joy.
class _TimePanel extends StatelessWidget {
  const _TimePanel({required this.report});
  final SessionReport report;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final total = report.total;
    final best = report.personalBest && total != null;
    final panel = MangaPanel(
      shape: const PanelShape(bottomRight: Offset(0, ResultsLayout.splashCut)),
      art: const [
        RadialLayer(center: Backdrops.skyCenter, colors: Backdrops.skyColors, stops: Backdrops.skyStops),
        BurstLayer(ResultsLayout.splashBurst),
      ],
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ResultsLayout.splashHeight - 36),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(total == null ? s.endedEarly : s.totalTime.toUpperCase(),
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: ResultsLayout.splashLabelFont,
                    letterSpacing: ResultsLayout.splashLabelTracking * ResultsLayout.splashLabelFont)),
            const SizedBox(height: Gaps.small),
            if (total != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.inner),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: best ? _TickingTime(from: report.previousBest, to: total) : _RunTime(total),
                ),
              ),
            if (best) ...[
              const SizedBox(height: PersonalBestLayout.stickerGap),
              _BestSticker(s.personalBest.toUpperCase()),
              const SizedBox(height: PersonalBestLayout.noteGap),
              Entrance(PersonalBestMotion.note, child: _PreviousBest(previous: report.previousBest, now: total)),
            ],
          ]),
        ),
      ),
    );
    if (!best) return panel;
    return EntranceStage(
      length: PersonalBestMotion.length,
      child: Jolt(
        PersonalBestMotion.jolt,
        reach: PersonalBestMotion.joltReach,
        steps: PersonalBestMotion.joltSteps,
        seed: PersonalBestMotion.joltSeed,
        child: Stack(clipBehavior: Clip.none, children: [
          panel,
          Positioned(
            left: PersonalBestLayout.sfxAt.dx,
            top: PersonalBestLayout.sfxAt.dy,
            child: Entrance(
              PersonalBestMotion.sfx,
              child: Transform.rotate(
                angle: PersonalBestLayout.sfxTurnDeg * math.pi / 180,
                child: const SfxText(PersonalBestLayout.sfx,
                    size: PersonalBestLayout.sfxFont, seed: PersonalBestLayout.sfxSeed, outline: NewCardLayout.sfxOutline),
              ),
            ),
          ),
          const Placed(
            PersonalBestLayout.tobi,
            child: Entrance(
              PersonalBestMotion.tobi,
              child: Hop(
                height: PersonalBestMotion.hopHeight,
                period: PersonalBestMotion.hopPeriod,
                airShare: PersonalBestMotion.hopAirShare,
                child: Tobi(pose: TobiPose.cheering),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _RunTime extends StatelessWidget {
  const _RunTime(this.time);
  final Duration time;

  @override
  Widget build(BuildContext context) => OutlinedText(formatRunTime(time),
      style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.splashTimeFont, height: 1),
      outlineWidth: ResultsLayout.splashTimeOutline);
}

/// The new best ticking down from the previous one (straight in on a first
/// run), in a box as wide as the wider of the two so it holds still.
class _TickingTime extends StatelessWidget {
  const _TickingTime({required this.from, required this.to});
  final Duration? from;
  final Duration to;

  @override
  Widget build(BuildContext context) {
    final start = from ?? to;
    return Stack(alignment: Alignment.center, children: [
      Opacity(opacity: 0, child: _RunTime(start > to ? start : to)),
      EntranceBuilder(
        PersonalBestMotion.count,
        builder: (context, t, _) => _RunTime(start - (start - to) * t),
      ),
    ]);
  }
}

/// PERSONAL BEST stamped on over a burst of focus lines.
class _BestSticker extends StatelessWidget {
  const _BestSticker(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        const Positioned.fill(
          child: ImpactBurst(
            PersonalBestMotion.burst,
            burst: PersonalBestLayout.impactBurst,
            size: PersonalBestLayout.impactSize,
            fromScale: PersonalBestLayout.impactFromScale,
            toScale: PersonalBestLayout.impactToScale,
          ),
        ),
        Entrance(
          PersonalBestMotion.sticker,
          child: Sticker(
            color: Palette.pink,
            tilt: PersonalBestLayout.stickerTilt,
            padding: PersonalBestLayout.stickerPadding,
            child: Text(label, style: const TextStyle(fontFamily: Fonts.display, fontSize: PersonalBestLayout.stickerFont)),
          ),
        ),
      ]);
}

/// "previous 00:15.380" and the time saved, or the first recorded run.
class _PreviousBest extends StatelessWidget {
  const _PreviousBest({required this.previous, required this.now});
  final Duration? previous;
  final Duration now;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const style = TextStyle(fontWeight: Weights.black, fontSize: PersonalBestLayout.noteFont);
    final previous = this.previous;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ColoredBox(
        color: Palette.paper,
        child: Padding(
          padding: PersonalBestLayout.notePadding,
          child: Text(previous == null ? s.firstRecordedRun : '${s.previousBest} ${formatRunTime(previous)}', style: style),
        ),
      ),
      if (previous != null) ...[
        const SizedBox(height: PersonalBestLayout.gainGap),
        Entrance(
          PersonalBestMotion.gain,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Palette.sun,
              border: Border.all(color: Palette.ink, width: PersonalBestLayout.gainBorder),
            ),
            child: Padding(
              padding: PersonalBestLayout.gainPadding,
              child: Text(s.timeSaved(((previous - now).inMicroseconds / 1e6).toStringAsFixed(3)), style: style),
            ),
          ),
        ),
      ],
    ]);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
          ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            Text('${before?.round() ?? s.newBadge} → ${after!.round()} · ${band.label}',
                style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.statNoteFont)),
        ],
      ),
    );
  }
}

/// A heading beside a shelf of small cards (the round's new cards, its
/// toughest ones).
class _CardShelf extends StatelessWidget {
  const _CardShelf({required this.heading, required this.label, required this.note, required this.cards});
  final String heading, label, note;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => MangaPanel(
        padding: ResultsLayout.toughPadding,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: ResultsLayout.toughHeaderWidth,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(heading, style: const TextStyle(fontFamily: Fonts.display, fontSize: ResultsLayout.toughHeadingFont, height: 1)),
              const SizedBox(height: Gaps.tight),
              Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.toughLabelFont)),
              const SizedBox(height: Gaps.tight),
              Text(note, style: const TextStyle(fontWeight: Weights.bold, fontSize: ResultsLayout.toughNoteFont, color: Palette.inkSoft)),
            ]),
          ),
          const SizedBox(width: Gaps.section),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: Gaps.small,
              runSpacing: Gaps.panel,
              children: cards,
            ),
          ),
        ]),
      );
}

/// A new card of the round with its kimariji.
class _NewCard extends StatelessWidget {
  const _NewCard(this.poemId);
  final int poemId;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: ResultsLayout.toughCardWidth,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TorifudaCard(poem: poems[poemId]),
          const SizedBox(height: Gaps.tight),
          Text(poems[poemId].kimariji,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: Weights.black, fontSize: ResultsLayout.toughKimarijiFont)),
        ]),
      );
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
