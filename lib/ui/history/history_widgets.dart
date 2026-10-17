import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/side_trips.dart';
import '../../l10n/free_strings.dart';
import '../../l10n/history_strings.dart';
import '../../l10n/run_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';

/// A run's kind as a coloured tag: Training, Free play, Weak cards, Ranked
/// or the exam.
class RunKindTag extends StatelessWidget {
  const RunKindTag(this.mode, {super.key});
  final PlayMode mode;

  /// The colours that mark [mode]'s runs beyond the tag: a list row's
  /// edge, a run page's tabs, titles and headline.
  static KindLook lookOf(PlayMode mode) => switch (mode) {
        PlayMode.ranked => HistoryLooks.ranked,
        PlayMode.exam => HistoryLooks.exam,
        PlayMode.free || PlayMode.guest => HistoryLooks.free,
        PlayMode.nigate => HistoryLooks.weak,
        PlayMode.training => HistoryLooks.training,
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final (fill, text, outlined) = switch (mode) {
      PlayMode.ranked => (Palette.pink, Palette.ink, true),
      PlayMode.exam => (Palette.ink, Palette.sun, false),
      PlayMode.free || PlayMode.guest => (Palette.seaSoft, Palette.ink, true),
      PlayMode.nigate => (Palette.sun, Palette.ink, true),
      PlayMode.training => (Palette.ink, Palette.paper, false),
    };
    return KindTag(runKindLabel(s, mode), fill: fill, textColor: text, edge: outlined ? Palette.ink : null);
  }
}

/// The small tag a run or game is labelled with in History's lists and at
/// the top of its page: [fill] behind, an [edge] inside its border if any.
class KindTag extends StatelessWidget {
  const KindTag(this.text, {super.key, required this.fill, required this.textColor, this.edge});
  final String text;
  final Color fill, textColor;
  final Color? edge;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: edge == null ? null : Border.all(color: edge!, width: Strokes.label),
        ),
        child: Padding(
          padding: HistoryRunStyle.kindPadding,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: HistoryRunStyle.kindFont,
                    letterSpacing: HistoryRunStyle.kindTracking,
                    height: HistoryRunStyle.kindLineHeight,
                    color: textColor)),
          ),
        ),
      );
}

/// A run kind's short name, as its tag and the filter show it.
String runKindLabel(S s, PlayMode mode) => switch (mode) {
      PlayMode.ranked => s.rankedRun,
      PlayMode.exam => s.runExamTag,
      PlayMode.free || PlayMode.guest => s.freePlay,
      PlayMode.nigate => s.weakCards,
      PlayMode.training => s.training,
    };

/// A 暗記練 game's kind as a tag: ranked in pink, free play outlined, with
/// its level or "custom".
class AnkirenKindTag extends StatelessWidget {
  const AnkirenKindTag({super.key, required this.ranked, required this.level});
  final bool ranked;
  final int? level;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mode = switch ((ranked, level)) {
      (true, final int level) => s.sideTripRankedLevel(level),
      (true, null) => s.sideTripRanked,
      (false, final int level) => s.historyFreeLevel(level),
      (false, null) => '${s.freePlay} · ${s.deckCustom}',
    };
    return KindTag('${s.tripName(SideTrip.ankiren)} · $mode',
        fill: ranked ? Palette.pink : Palette.paper,
        textColor: ranked ? Palette.ink : Palette.pinkDeep,
        edge: ranked ? Palette.ink : Palette.pinkDeep);
  }
}

/// A small result badge beside a run's kind: a placement, a new class, a
/// forfeit, who won the exam, a best.
class ResultBadge extends StatelessWidget {
  const ResultBadge(this.text, {super.key, this.color = Palette.sun, this.muted = false, this.cheer = false});
  final String text;
  final Color color;

  /// Drawn as an outline in grey (a forfeit, a loss).
  final bool muted;

  /// Led by a pink star, for something to celebrate (a best, a win).
  final bool cheer;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: muted ? Palette.paper : color,
          border: Border.all(color: muted ? HistoryRunStyle.muted : Palette.ink, width: Strokes.label),
        ),
        child: Padding(
          padding: HistoryRunStyle.badgePadding,
          child: DefaultTextStyle.merge(
            maxLines: 1,
            style: TextStyle(
                fontWeight: Weights.black,
                fontSize: HistoryRunStyle.badgeFont,
                color: muted ? HistoryRunStyle.muted : Palette.ink),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (cheer) const Text(HistoryRunStyle.cheerMark, style: TextStyle(color: Palette.pinkDeep)),
              Text(text),
            ]),
          ),
        ),
      );
}

/// A titled block of a run page: a heading with its other-language word
/// and a note on the right, then its contents.
class HistorySection extends StatelessWidget {
  const HistorySection({super.key, required this.title, this.sub, this.note, this.fill = false, required this.child});
  final String title;
  final String? sub, note;

  /// [child] takes the rest of the height the section is given.
  final bool fill;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HistoryRunStyle.sectionGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HistoryHeading(title: title, sub: sub, note: note),
            const SizedBox(height: Gaps.small),
            if (fill) Expanded(child: child) else child,
          ],
        ),
      );
}

/// The colours of the run or game a page shows ([KindLook]), for the parts
/// inside it.
class HistoryLook extends InheritedWidget {
  const HistoryLook({super.key, required this.look, required super.child});
  final KindLook look;

  /// The look around [context]; the exam's sun when there is none.
  static KindLook of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HistoryLook>()?.look ?? HistoryLooks.exam;

  @override
  bool updateShouldNotify(HistoryLook oldWidget) => oldWidget.look != look;
}

/// A section's heading row: the title over a slanted marker stripe in the
/// page's colour, with its other-language word, and a note on the right.
/// Outside a run page, [accent] and the font sizes are given.
class HistoryHeading extends StatelessWidget {
  const HistoryHeading({
    super.key,
    required this.title,
    this.sub,
    this.note,
    this.accent,
    this.titleFont = TypeScale.button,
    this.subFont = HistoryRunStyle.subFont,
  });
  final String title;
  final String? sub, note;
  final Color? accent;
  final double titleFont, subFont;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: CustomPaint(
                painter: _MarkerPainter(accent ?? HistoryLook.of(context).accent),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: title, style: TextStyle(fontWeight: Weights.black, fontSize: titleFont)),
                    if (sub != null)
                      TextSpan(
                          text: '  $sub',
                          style: TextStyle(fontWeight: Weights.black, fontSize: subFont)),
                  ]),
                ),
              ),
            ),
          ),
          if (note case final note?)
            Text(note, style: const TextStyle(fontWeight: Weights.bold, fontSize: HistoryRunStyle.noteFont)),
        ],
      );
}

/// A marker stroke under the bottom of a title, slanted like the manga
/// banners.
class _MarkerPainter extends CustomPainter {
  const _MarkerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const reach = HistoryRunStyle.titleMarkReach;
    final top = size.height * HistoryRunStyle.titleMarkTop;
    final bottom = size.height * HistoryRunStyle.titleMarkBottom;
    final lean = (bottom - top) * HistoryRunStyle.titleMarkSkew;
    canvas.drawPath(
      Path()
        ..moveTo(-reach / 2 - lean, top)
        ..lineTo(size.width + reach - lean, top)
        ..lineTo(size.width + reach, bottom)
        ..lineTo(-reach / 2, bottom)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.color != color;
}

/// A small caption under a chart or a table.
class HistoryCaption extends StatelessWidget {
  const HistoryCaption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Gaps.small),
        child: Text(text,
            style: const TextStyle(
                fontWeight: Weights.bold, fontSize: HistoryRunStyle.noteFont, color: HistoryRunStyle.muted)),
      );
}

/// One fact in a [FactGrid]: a big value over a small tracked label.
class Fact {
  const Fact(this.value, this.label, {this.color});
  final String value, label;
  final Color? color;
}

/// Facts side by side in ink-ruled cells, [perRow] to a row.
class FactGrid extends StatelessWidget {
  const FactGrid(this.facts, {super.key, this.perRow = 4, this.fill = Palette.paper});
  final List<Fact> facts;
  final int perRow;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final rows = [for (var i = 0; i < facts.length; i += perRow) facts.sublist(i, (i + perRow).clamp(0, facts.length))];
    const side = BorderSide(color: Palette.ink, width: Strokes.label);
    return DecoratedBox(
      decoration: BoxDecoration(color: fill, border: Border.all(color: Palette.ink, width: Strokes.label)),
      child: Column(
        children: [
          for (final (r, row) in rows.indexed)
            DecoratedBox(
              decoration: BoxDecoration(border: r == 0 ? null : const Border(top: side)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < perRow; i++)
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(border: i == 0 ? null : const Border(left: side)),
                          child: i < row.length ? _FactCell(row[i]) : const SizedBox(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell(this.fact);
  final Fact fact;

  @override
  Widget build(BuildContext context) => Padding(
        padding: HistoryRunStyle.factPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(fact.value,
                  maxLines: 1,
                  style: TextStyle(fontFamily: Fonts.display, fontSize: HistoryRunStyle.factFont, height: 1.1, color: fact.color)),
            ),
            const SizedBox(height: Gaps.tight),
            Text(fact.label.toUpperCase(),
                style: const TextStyle(
                    fontWeight: Weights.black, fontSize: HistoryRunStyle.labelFont, letterSpacing: HistoryRunStyle.labelTracking)),
          ],
        ),
      );
}

/// One count in a [StatChips] row: the number, what it counts, a small
/// icon and the colour of its bar.
class StatChip {
  const StatChip(this.value, this.label, {required this.icon, required this.color, required this.fill});
  final String value, label;
  final VectorArt icon;

  /// The bar's colour, and the chip's lighter fill to match.
  final Color color, fill;
}

/// A row of small counts side by side, each in its own chip with a
/// coloured bar along the top, all as tall as the tallest.
class StatChips extends StatelessWidget {
  const StatChips(this.chips, {super.key});
  final List<StatChip> chips;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, c) in chips.indexed) ...[
            if (i > 0) const SizedBox(width: StatChipStyle.gap),
            Expanded(child: _Chip(c)),
          ],
        ]),
      );
}

class _Chip extends StatelessWidget {
  const _Chip(this.chip);
  final StatChip chip;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: chip.fill,
          border: Border.all(color: Palette.ink, width: Strokes.label),
          boxShadow: const [BoxShadow(color: Palette.inkShadow, offset: StatChipStyle.shadow)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: StatChipStyle.bar, color: chip.color),
          Padding(
            padding: StatChipStyle.padding,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(chip.value,
                        maxLines: 1, style: const TextStyle(fontFamily: Fonts.display, fontSize: StatChipStyle.font, height: 1.1)),
                  ),
                ),
                MangaIcon(chip.icon, size: StatChipStyle.icon, strokeWidth: StatChipStyle.iconStroke),
              ]),
              const SizedBox(height: Gaps.tight),
              Text(chip.label.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: StatChipStyle.labelFont,
                      height: StatChipStyle.labelHeight,
                      letterSpacing: StatChipStyle.labelTracking)),
            ]),
          ),
        ]),
      );
}

/// A run or game page's headline: a halftone panel in the page's colour,
/// cut in at the bottom right like the list's 7-day strip, on a hard
/// shadow.
class HeadlinePanel extends StatelessWidget {
  const HeadlinePanel({super.key, this.plain, required this.child});

  /// A flat fill instead of the page's halftone (a game not scored).
  final Color? plain;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tone = HistoryLook.of(context).tone;
    return MangaPanel(
      shape: const PanelShape(bottomRight: Offset(HeadlineStyle.cut, 0)),
      tone: plain == null ? tone : null,
      color: plain ?? tone.background ?? Palette.paper,
      padding: HeadlineStyle.padding,
      shadow: HistoryRunStyle.panelShadow,
      child: child,
    );
  }
}

/// A rubber stamp on a headline, tilted, with a double ring: a best, a
/// placement, a finished set, a game not scored. [sub] is the small line
/// under it (the other language in Japanese).
class RunStamp extends StatelessWidget {
  const RunStamp(this.text, {super.key, this.sub, this.color = Palette.pinkDeep});
  final String text;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: HeadlineStyle.stampMaxScale,
        child: Transform.rotate(
          angle: HeadlineStyle.stampTilt * math.pi / 180,
          child: Container(
            padding: const EdgeInsets.all(HeadlineStyle.stampRingGap),
            decoration: BoxDecoration(
              color: HeadlineStyle.stampPaper,
              border: Border.all(color: color, width: HeadlineStyle.stampBorder),
            ),
            child: Container(
              padding: HeadlineStyle.stampPadding,
              decoration: BoxDecoration(border: Border.all(color: color, width: HeadlineStyle.stampRing)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(text,
                    maxLines: 1,
                    style: TextStyle(fontFamily: Fonts.display, fontSize: HeadlineStyle.stampFont, height: 1.1, color: color)),
                if (sub case final sub?)
                  Text(sub.toUpperCase(),
                      maxLines: 1,
                      style: TextStyle(
                          fontWeight: Weights.black,
                          fontSize: HeadlineStyle.stampSubFont,
                          letterSpacing: HeadlineStyle.stampSubTracking,
                          height: 1.2,
                          color: color)),
              ]),
            ),
          ),
        ),
      );
}

/// A headline's corner: a [stamp] beside Tobi in [pose], reacting to the
/// run (cheering a best, shocked to lose the exam), or the stamp alone.
class HeadlineCheer extends StatelessWidget {
  const HeadlineCheer({super.key, this.stamp, this.pose});
  final Widget? stamp;
  final TobiPose? pose;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: HeadlineStyle.stampGap),
          ?stamp,
          if (pose case final pose?) ...[
            const SizedBox(width: HeadlineStyle.tobiGap),
            SizedBox.fromSize(size: HeadlineStyle.tobi, child: Tobi(pose: pose, animate: false)),
          ],
        ],
      );
}

/// A pink action button on a hard shadow: an icon, the [label] and a
/// smaller [sub] after it (the Cards tab's Practise, the Field's Start
/// review).
class HistoryButton extends StatelessWidget {
  const HistoryButton({super.key, required this.icon, required this.label, this.sub, required this.onTap});
  final VectorArt icon;
  final String label;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: HistoryRunStyle.buttonHeight),
        margin: const EdgeInsets.only(right: HistoryRunStyle.buttonShadow, bottom: HistoryRunStyle.buttonShadow),
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Palette.inkShadow, offset: Offset(HistoryRunStyle.buttonShadow, HistoryRunStyle.buttonShadow)),
          ],
        ),
        child: InkButton(
          onTap: onTap,
          color: Palette.pink,
          padding: HistoryRunStyle.buttonPadding,
          semanticLabel: [label, ?sub].join(', '),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MangaIcon(icon, size: HistoryRunStyle.buttonIcon),
              const SizedBox(width: Gaps.panel),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: label, style: const TextStyle(fontSize: HistoryRunStyle.buttonFont)),
                    if (sub case final sub?)
                      TextSpan(
                          text: '  $sub',
                          style: const TextStyle(fontWeight: Weights.bold, fontSize: HistoryRunStyle.buttonSubFont)),
                  ]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: Weights.black, color: Palette.ink),
                ),
              ),
            ],
          ),
        ),
      );
}

/// A tracked small-caps label, as over a headline's big number.
class TrackedLabel extends StatelessWidget {
  const TrackedLabel(this.text, {super.key, this.sub});
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) => Text(
        [text.toUpperCase(), ?sub].join('  '),
        style: const TextStyle(
            fontWeight: Weights.black, fontSize: HistoryRunStyle.labelFont, letterSpacing: HistoryRunStyle.labelTracking),
      );
}

/// A scrolling run tab: its sections with the page gutter.
class RunTabList extends StatelessWidget {
  const RunTabList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(Gaps.gutter, Gaps.section, Gaps.gutter, Gaps.gutter),
        children: children,
      );
}

/// The time a past run is shown by: its scored time or clock, "Forfeit"
/// for a forfeit, which has none, or "—".
String runTimeText(S s, PastRun run) => switch (run.time) {
      _ when run.forfeit => s.historyForfeit,
      final t? => formatTenths(t),
      null => missingTime,
    };

/// A rating's change as ▲383, ▼582 or ±0.
String ratingChangeText(num change) {
  final n = change.round();
  return '${n > 0 ? '▲' : n < 0 ? '▼' : '±'}${n.abs()}';
}
