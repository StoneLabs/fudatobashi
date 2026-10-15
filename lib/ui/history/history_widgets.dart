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
import '../play/time_format.dart';

/// A run's kind as a coloured tag: Training, Free play, Weak cards, Ranked
/// or the exam.
class RunKindTag extends StatelessWidget {
  const RunKindTag(this.mode, {super.key});
  final PlayMode mode;

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
  const ResultBadge(this.text, {super.key, this.color = Palette.sun, this.muted = false});
  final String text;
  final Color color;

  /// Drawn as an outline in grey (a forfeit, a loss).
  final bool muted;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: muted ? Palette.paper : color,
          border: Border.all(color: muted ? HistoryRunStyle.muted : Palette.ink, width: Strokes.label),
        ),
        child: Padding(
          padding: HistoryRunStyle.badgePadding,
          child: Text(text,
              maxLines: 1,
              style: TextStyle(
                  fontWeight: Weights.black,
                  fontSize: HistoryRunStyle.badgeFont,
                  color: muted ? HistoryRunStyle.muted : Palette.ink)),
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

/// A section's heading row: the title with its other-language word, and a
/// note on the right.
class HistoryHeading extends StatelessWidget {
  const HistoryHeading({super.key, required this.title, this.sub, this.note});
  final String title;
  final String? sub, note;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: title, style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
                if (sub != null)
                  TextSpan(
                      text: '  $sub',
                      style: const TextStyle(fontWeight: Weights.black, fontSize: HistoryRunStyle.subFont)),
              ]),
            ),
          ),
          if (note case final note?)
            Text(note, style: const TextStyle(fontWeight: Weights.bold, fontSize: HistoryRunStyle.noteFont)),
        ],
      );
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

/// The time a past run is shown by: its scored time or clock, or "—".
String runTimeText(PastRun run) => switch (run.time) {
      final t? => formatTenths(t),
      null => missingTime,
    };

/// A rating's change as ▲383, ▼582 or ±0.
String ratingChangeText(num change) {
  final n = change.round();
  return '${n > 0 ? '▲' : n < 0 ? '▼' : '±'}${n.abs()}';
}
