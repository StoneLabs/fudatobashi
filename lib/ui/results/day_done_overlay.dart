import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/today_set.dart';
import '../../domain/xp.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';
import 'celebration_chrome.dart';

/// "Today's set done" (本日完了!!), after the run that finished today's set:
/// over boiling focus lines the day's bar sweeps its last bit green and the
/// 完了 hanko slams onto it with ドン!, Tobi hops in cheering, and the day's
/// numbers and its XP rise into view.
class DayDoneOverlay extends StatelessWidget {
  const DayDoneOverlay({super.key, required this.day, required this.onNext});
  final DayDone day;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return EntranceStage(
      length: DayDoneMotion.length,
      child: CelebrationChrome(
        color: DayDoneLayout.color,
        onNext: onNext,
        art: const [
          RadialLayer(center: DayDoneLayout.glowAt, colors: DayDoneLayout.glowColors, stops: DayDoneLayout.glowStops),
        ],
        backdrop: const [
          BoilingLines(DayDoneLayout.focus, frames: NewCardMotion.linesFrames, step: NewCardMotion.linesStep),
        ],
        child: Jolt(
          DayDoneMotion.jolt,
          reach: DayDoneMotion.joltReach,
          steps: DayDoneMotion.joltSteps,
          seed: DayDoneMotion.joltSeed,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: DayDoneLayout.topGap),
                const Entrance(DayDoneMotion.title, child: _Title()),
                const SizedBox(height: DayDoneLayout.bandGap),
                _Band(s.dayDoneBand),
                const SizedBox(height: DayDoneLayout.barGap),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DayDoneLayout.barInset),
                  child: _StampedBar(day),
                ),
                const Flexible(child: _CheeringTobi()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DayDoneLayout.statsInset),
                  child: Entrance(DayDoneMotion.stats, child: _Stats(day)),
                ),
              ]),
            ),
            const SizedBox(height: DayDoneLayout.ctaGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: Entrance(
                DayDoneMotion.cta,
                child: DecoratedBox(
                  decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Palette.ink, offset: DayDoneLayout.ctaShadow)]),
                  child: CelebrationCta(
                    label: s.xpCta,
                    sub: s.sub?.xpCta,
                    onTap: onNext,
                    height: DayDoneLayout.ctaHeight,
                    fontSize: DayDoneLayout.ctaFont,
                    subFontSize: DayDoneLayout.ctaSubFont,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gaps.section),
          ]),
        ),
      ),
    );
  }
}

/// 本日完了!! in ink with a thick paper outline.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: Gaps.gutter),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: OutlinedText(
            DayDoneLayout.title,
            style: TextStyle(fontFamily: Fonts.display, fontSize: DayDoneLayout.titleFont, color: Palette.ink, height: 1),
            outlineWidth: DayDoneLayout.titleOutline,
          ),
        ),
      );
}

/// The ink band sliding in under the title, with ドン! bursting out at its
/// lower right.
class _Band extends StatelessWidget {
  const _Band(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    const turn = DayDoneLayout.bandTurnDeg * math.pi / 180;
    const skew = DayDoneLayout.bandSkewDeg * math.pi / 180;
    final band = Transform.rotate(
      angle: turn,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.skewX(skew),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.ink,
            border: Border.all(
                color: Palette.paper, width: DayDoneLayout.bandEdge, strokeAlign: BorderSide.strokeAlignOutside),
          ),
          child: Padding(
            padding: DayDoneLayout.bandPadding,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(-skew),
              child: Text(text,
                  softWrap: false,
                  style: const TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: DayDoneLayout.bandFont,
                      letterSpacing: DayDoneLayout.bandTracking * DayDoneLayout.bandFont,
                      color: Palette.paper,
                      height: DayDoneLayout.bandLineHeight)),
            ),
          ),
        ),
      ),
    );
    return Stack(clipBehavior: Clip.none, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: Entrance(DayDoneMotion.band, child: band)),
        ),
      ),
      Positioned(
        right: DayDoneLayout.sfxRight,
        top: DayDoneLayout.sfxTop,
        child: Entrance(
          DayDoneMotion.sfx,
          child: Transform.rotate(
            angle: DayDoneLayout.sfxTurnDeg * math.pi / 180,
            child: MediaQuery.withNoTextScaling(
              child: const SfxText(DayDoneLayout.sfx,
                  size: DayDoneLayout.sfxFont, seed: DayDoneLayout.sfxSeed, outline: DayDoneLayout.sfxOutline),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// The day's bar, its last bit sweeping green, with the 完了 hanko slammed
/// onto its middle.
class _StampedBar extends StatelessWidget {
  const _StampedBar(this.day);
  final DayDone day;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        _Bar(day.bar),
        Positioned.fill(
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Entrance(
              DayDoneMotion.stamp,
              child: Transform.rotate(
                angle: DayDoneLayout.stampTurnDeg * math.pi / 180,
                child: MediaQuery.withNoTextScaling(child: _Hanko(day.date)),
              ),
            ),
          ),
        ),
      ]);
}

/// Reviews, new cards and misses as on Home, under the green sweep.
class _Bar extends StatelessWidget {
  const _Bar(this.bar);
  final SetBar bar;

  @override
  Widget build(BuildContext context) {
    final segments = [
      for (final (looks, color) in [
        (bar.reviews, Palette.paper),
        (bar.fresh, Palette.sun),
        (bar.extra, Palette.pink),
      ])
        if (looks > 0) Expanded(flex: looks, child: ColoredBox(color: color)),
    ];
    return Container(
      height: DayDoneLayout.barHeight,
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(color: Palette.ink, width: DayDoneLayout.barBorder),
        boxShadow: const [BoxShadow(color: Palette.paper, spreadRadius: DayDoneLayout.barEdge)],
      ),
      child: Stack(fit: StackFit.expand, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, segment) in segments.indexed) ...[
            if (i > 0) const SizedBox(width: Strokes.hairline, child: ColoredBox(color: Palette.ink)),
            segment,
          ],
        ]),
        EntranceBuilder(
          DayDoneMotion.sweep,
          child: const ColoredBox(color: Palette.land),
          builder: (context, t, child) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: lerpDouble(DayDoneLayout.sweepFrom, 1, t),
            child: child,
          ),
        ),
      ]),
    );
  }
}

/// 完了 over the day's date, in pink-deep with a double rule.
class _Hanko extends StatelessWidget {
  const _Hanko(this.date);

  /// The day (a UTC midnight).
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = [date.year, date.month, date.day].map((n) => '$n'.padLeft(2, '0')).join(DayDoneLayout.dateSeparator);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DayDoneLayout.stampPaper,
        border: Border.all(color: Palette.pinkDeep, width: DayDoneLayout.stampBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DayDoneLayout.stampRuleGap),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: Palette.pinkDeep, width: DayDoneLayout.stampRule)),
          child: Padding(
            padding: DayDoneLayout.stampPadding,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(DayDoneLayout.stamp,
                  style: TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: DayDoneLayout.stampFont,
                      letterSpacing: DayDoneLayout.stampTracking * DayDoneLayout.stampFont,
                      color: Palette.pinkDeep,
                      height: 1)),
              const SizedBox(height: DayDoneLayout.dateGap),
              Text(label,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: DayDoneLayout.dateFont,
                      letterSpacing: DayDoneLayout.dateTracking * DayDoneLayout.dateFont,
                      color: Palette.pinkDeep,
                      height: 1)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Tobi hopping in, cheering; shrinks to the room the numbers leave, and
/// stays away when that room gets too small for him.
class _CheeringTobi extends StatelessWidget {
  const _CheeringTobi();

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        const gaps = DayDoneLayout.tobiGap + DayDoneLayout.statsGap;
        if (constraints.maxHeight - gaps < DayDoneLayout.tobiMinHeight) {
          return const SizedBox(height: DayDoneLayout.statsGap);
        }
        return Padding(
          padding: const EdgeInsets.only(top: DayDoneLayout.tobiGap, bottom: DayDoneLayout.statsGap),
          child: Align(
            heightFactor: 1,
            child: FittedBox(
              child: SizedBox.fromSize(
                size: DayDoneLayout.tobi,
                child: const Entrance(DayDoneMotion.tobi, child: Tobi(pose: TobiPose.cheering)),
              ),
            ),
          ),
        );
      });
}

/// The day's numbers, a line each, and the XP the day earned.
class _Stats extends StatelessWidget {
  const _Stats(this.day);
  final DayDone day;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lines = [
      if (day.looks > 0) (s.dayDoneCleared(day.rounds), [day.looks, day.rounds]),
      if (day.newCards > 0) (s.dayDoneNew(day.newCards), [day.newCards]),
      if (day.looks > 0) (s.dayDoneMisses(day.missesFixed), [day.missesFixed]),
      (s.dayDoneStreak(day.goalStreak), [day.goalStreak]),
    ];
    const number = TextStyle(
        fontFamily: Fonts.display, fontWeight: Weights.regular, fontSize: DayDoneLayout.statNumberFont, height: 1);
    return MangaPanel(
      padding: DayDoneLayout.statsPadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        for (final (i, (template, values)) in lines.indexed) ...[
          if (i > 0) const _DashedRule(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DayDoneLayout.statRowPadding),
            child: NumberedText(template, values,
                style: const TextStyle(fontWeight: Weights.bold, fontSize: DayDoneLayout.statFont), numberStyle: number),
          ),
        ],
        const SizedBox(height: DayDoneLayout.xpGap),
        const SizedBox(height: DayDoneLayout.xpRule, child: ColoredBox(color: Palette.ink)),
        const SizedBox(height: DayDoneLayout.xpRuleGap),
        LayoutBuilder(
          builder: (context, constraints) => Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(s.xpSource(XpSource.dayDone),
                    style: const TextStyle(fontWeight: Weights.black, fontSize: DayDoneLayout.xpLabelFont)),
              ),
            ),
            const SizedBox(width: DayDoneLayout.xpLabelGap),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * DayDoneLayout.xpChipShare),
              child: FittedBox(fit: BoxFit.scaleDown, child: _XpChip(day.xp)),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// A dashed hairline between two of the day's numbers.
class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: Strokes.hairline, width: double.infinity, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawPath(
      Dashes.of(Path()..moveTo(0, y)..lineTo(size.width, y), Strokes.dash),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height
        ..color = DayDoneLayout.statRule,
    );
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

/// "+1000 XP" on a tilted sun chip, counting up from zero; it keeps the
/// width of the full number while counting.
class _XpChip extends StatelessWidget {
  const _XpChip(this.xp);
  final int xp;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    String label(int n) => '+$n ${s.xpUnit}';
    const style = TextStyle(fontFamily: Fonts.display, fontSize: DayDoneLayout.xpChipFont, height: 1);
    return Transform.rotate(
      angle: DayDoneLayout.xpChipTurnDeg * math.pi / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Palette.sun, border: Border.all(color: Palette.ink, width: Strokes.panel)),
        child: Padding(
          padding: DayDoneLayout.xpChipPadding,
          child: Stack(alignment: Alignment.center, children: [
            Opacity(opacity: 0, child: Text(label(xp), style: style)),
            EntranceBuilder(
              DayDoneMotion.xp,
              builder: (context, t, _) => Text(label((xp * t).round()), style: style),
            ),
          ]),
        ),
      ),
    );
  }
}
