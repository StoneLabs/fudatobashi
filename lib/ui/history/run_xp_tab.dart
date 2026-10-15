import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/xp.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/strings.dart';
import '../../state/past_runs.dart';
import '../../state/play_config.dart';
import '../manga/manga.dart';
import '../results/xp_overlay.dart';
import 'history_widgets.dart';

/// The training view's XP tab: where the run's experience came from, and
/// the level it left.
class RunXpTab extends StatelessWidget {
  const RunXpTab(this.detail, {super.key});
  final RunDetail detail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return RunTabList(children: [
      XpPanel(detail.xp),
      HistoryCaption(detail.run.mode == PlayMode.training ? s.runTrainingNoRank : s.runPracticeNoRank),
    ]);
  }
}

/// A run's experience: a line for each source, the total, and the level
/// bar with the levels gained and the XP to the next level.
class XpPanel extends StatelessWidget {
  const XpPanel(this.gain, {super.key});

  /// Null for a run that earned none.
  final XpGain? gain;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final gain = this.gain;
    if (gain == null) return HistoryCaption(s.runNoXp);
    final level = gain.levelAfter;
    final from = gain.levelBefore.level;
    return RunPanel(children: [
      TrackedLabel(s.runXpLabel, sub: s.sub?.runXpLabel),
      RunBigValue('+${gain.award.total}', unit: s.xpUnit),
      const SizedBox(height: Gaps.small),
      for (final part in gain.award.parts)
        RunValueLine([s.xpSource(part.source), ?s.xpCount(part)].join(' '), '${part.xp}'),
      RunValueLine(s.runXpTotal, '${gain.award.total}', total: true),
      const SizedBox(height: Gaps.panel),
      SizedBox(height: RunTabsStyle.levelBarHeight, child: CustomPaint(painter: XpBarPainter(level.fraction))),
      const SizedBox(height: Gaps.small),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Gaps.panel,
        runSpacing: Gaps.tight,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Gaps.small,
            runSpacing: Gaps.tight,
            children: [
              Text(s.levelShort(level.level), style: RunTabsStyle.lineStyle),
              if (gain.levelsGained > 0)
                ResultBadge(gain.levelsGained == 1 ? s.runLevelFrom(from) : s.runLevelsFrom(gain.levelsGained, from)),
            ],
          ),
          Text(s.xpToNext(level.toNext, level.level + 1), style: RunTabsStyle.lineStyle),
        ],
      ),
    ]);
  }
}

/// A run tab's ink-bordered panel, its [children] in a column, with a
/// section's gap under it unless [gap] is false (inside a section).
class RunPanel extends StatelessWidget {
  const RunPanel({super.key, required this.children, this.color = Palette.paper, this.gap = true});
  final List<Widget> children;
  final Color color;
  final bool gap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: gap ? HistoryRunStyle.sectionGap : 0),
        child: MangaPanel(
          border: RunTabsStyle.panelBorder,
          color: color,
          padding: RunTabsStyle.panelPadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      );
}

/// A big number in display type, with a small [unit] after it.
class RunBigValue extends StatelessWidget {
  const RunBigValue(this.value, {super.key, this.unit});
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(text: value, style: RunTabsStyle.bigStyle),
        if (unit case final unit?) TextSpan(text: '  $unit', style: RunTabsStyle.lineStyle),
      ]));
}

/// A label and its value on one line over a dotted rule; the [total] line
/// sits under a solid rule with a bigger value.
class RunValueLine extends StatelessWidget {
  const RunValueLine(this.label, this.value, {super.key, this.total = false});
  final String label, value;
  final bool total;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border: total
              ? const Border(top: BorderSide(color: Palette.ink, width: Strokes.label))
              : const Border(bottom: BorderSide(color: RunTabsStyle.rule, width: 1)),
        ),
        child: Padding(
          padding: RunTabsStyle.linePadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(label, style: RunTabsStyle.lineStyle)),
              const SizedBox(width: Gaps.panel),
              Text(value, style: total ? RunTabsStyle.totalStyle : RunTabsStyle.valueStyle),
            ],
          ),
        ),
      );
}
