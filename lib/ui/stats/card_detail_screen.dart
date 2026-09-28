import 'package:flutter/material.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../data/fuda_sets.dart';
import '../../data/islands.dart';
import '../../data/poem.dart';
import '../../domain/card_stats.dart';
import '../../domain/trainer.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../../state/play_config.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../torifuda/torifuda_painter.dart';
import 'stats_charts.dart';

/// Which attempts feed the chart, the stat tiles and the TOP SPEED badge:
/// 修行 only, free play + 苦手 combined (guest attempts are never stored), or
/// every attempt. Defaults to "All" so a freshly tapped card shows everything
/// it has, however it was played.
enum _ModeFilter { training, free, all }

/// A card's own record (spec phone 8): the torifuda, its kimariji, the
/// attempt chart with toggleable stat tiles, and its FSRS memory panel.
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.itemKey});

  final ItemKey itemKey;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late bool _inverted = widget.itemKey.inverted;
  _ModeFilter _mode = _ModeFilter.all;
  Set<ChartSeries> _visible = {ChartSeries.avg5, ChartSeries.avg10, ChartSeries.avg50, ChartSeries.band};

  ItemKey get _key => ItemKey(widget.itemKey.poemId, _inverted);

  void _toggleSeries(ChartSeries series) => setState(() {
        _visible = {..._visible};
        if (!_visible.remove(series)) _visible.add(series);
      });

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final poem = poems[widget.itemKey.poemId];
    final key = _key;
    final state = progress.trainer.items[key]!;
    final all = progress.attemptsOf(key);
    final filtered = switch (_mode) {
      _ModeFilter.training => [for (final a in all) if (a.mode == PlayMode.training) a],
      _ModeFilter.free => [for (final a in all) if (a.mode != PlayMode.training) a],
      _ModeFilter.all => all,
    };
    final stats = CardStats(filtered);
    final chartData = AttemptChartData(filtered, stats);
    final islandName = archipelago.islands[Trainer.islandOf(poem)].name;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              _TopBar(islandName: islandName, poemId: poem.id),
              const SizedBox(height: Gaps.tight),
              Align(
                alignment: Alignment.centerRight,
                child: _OrientationToggle(inverted: _inverted, onChanged: (v) => setState(() => _inverted = v)),
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(poem: poem, inverted: _inverted, topSpeedMs: stats.topSpeedMs),
                      const SizedBox(height: Gaps.section),
                      _ModeToggle(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
                      const SizedBox(height: Gaps.panel),
                      SizedBox(
                        height: CardDetailLayout.chartHeight,
                        child: MangaPanel(
                          padding: CardDetailLayout.chartPadding,
                          child: AttemptChart(data: chartData, visible: _visible),
                        ),
                      ),
                      const SizedBox(height: Gaps.panel),
                      _SeriesRow(stats: stats, visible: _visible, onToggle: _toggleSeries),
                      const SizedBox(height: Gaps.section),
                      _MemoryPanel(state: state, trainer: progress.trainer, itemKey: key, now: now),
                      if (state.reviewed) ...[
                        const SizedBox(height: Gaps.section),
                        _SeeYouBanner(due: state.card.due),
                      ],
                      const SizedBox(height: Gaps.section),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.islandName, required this.poemId});
  final String islandName;
  final int poemId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: CardDetailLayout.topBarHeight,
      child: Row(
        children: [
          InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: Gaps.small),
          Expanded(
            child: Text(s.islandCrumb(islandName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: Weights.black, fontSize: CardDetailLayout.crumbFont)),
          ),
          const SizedBox(width: Gaps.small),
          InkTag('#$poemId'),
        ],
      ),
    );
  }
}

class _OrientationToggle extends StatelessWidget {
  const _OrientationToggle({required this.inverted, required this.onChanged});
  final bool inverted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      height: CardDetailLayout.orientationHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(color: Palette.ink, width: Strokes.control),
        borderRadius: BorderRadius.circular(CardDetailLayout.orientationHeight / 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Seg(s.uprightLabel, selected: !inverted, onTap: () => onChanged(false)),
        _Seg(s.invertedLabel, selected: inverted, onTap: () => onChanged(true)),
      ]),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});
  final _ModeFilter mode;
  final ValueChanged<_ModeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      height: StatsLayout.segHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
      child: Row(children: [
        Expanded(child: _Seg(s.training, selected: mode == _ModeFilter.training, onTap: () => onChanged(_ModeFilter.training))),
        Expanded(child: _Seg(s.freePlay, selected: mode == _ModeFilter.free, onTap: () => onChanged(_ModeFilter.free))),
        Expanded(child: _Seg(s.allModes, selected: mode == _ModeFilter.all, onTap: () => onChanged(_ModeFilter.all))),
      ]),
    );
  }
}

/// A shared "one of N" segment (the language, tab, orientation and mode
/// toggles all use the same look: filled ink when selected).
class _Seg extends StatelessWidget {
  const _Seg(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.tab,
            color: selected ? Palette.ink : Palette.paper,
            padding: const EdgeInsets.symmetric(horizontal: CardDetailLayout.orientationPadding),
            alignment: Alignment.center,
            child: Text(label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: CardDetailLayout.orientationFont,
                    color: selected ? Palette.paper : Palette.ink)),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.poem, required this.inverted, required this.topSpeedMs});
  final Poem poem;
  final bool inverted;
  final double? topSpeedMs;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: CardDetailLayout.cardImageWidth, child: TorifudaCard(poem: poem, inverted: inverted)),
        const SizedBox(width: Gaps.section),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(poem.kimariji, style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.kimarijiFont, height: 1)),
              Text(s.kimarijiCaption,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: CardDetailLayout.kimarijiCaptionFont,
                      letterSpacing: TagStyle.tracking * CardDetailLayout.kimarijiCaptionFont)),
              const SizedBox(height: Gaps.small),
              Text(poem.kami, style: const TextStyle(fontWeight: Weights.black, fontSize: CardDetailLayout.kamiFont, height: 1.3)),
              const SizedBox(height: 2),
              Text(poem.author, style: const TextStyle(fontWeight: Weights.bold, fontSize: CardDetailLayout.authorFont, color: Palette.mute)),
              if (fudaSets.tomofuda(poem.id).isNotEmpty) ...[
                const SizedBox(height: Gaps.small),
                Wrap(
                  spacing: Gaps.tight,
                  runSpacing: Gaps.tight,
                  children: [for (final sib in fudaSets.tomofuda(poem.id)) Pill(poems[sib].kimariji)],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: Gaps.small),
        _TopSpeedBadge(ms: topSpeedMs),
      ],
    );
  }
}

class _TopSpeedBadge extends StatelessWidget {
  const _TopSpeedBadge({required this.ms});
  final double? ms;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: CardDetailLayout.topSpeedPadding,
      decoration: BoxDecoration(color: Palette.sun, border: Border.all(color: Palette.ink, width: Strokes.control)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(s.topSpeedLabel,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
                fontWeight: Weights.black,
                fontSize: CardDetailLayout.topSpeedLabelFont,
                letterSpacing: TagStyle.tracking * CardDetailLayout.topSpeedLabelFont)),
        const SizedBox(height: 2),
        Text(ms == null ? '—' : '${formatChipSeconds(ms!)} s',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.topSpeedValueFont)),
      ]),
    );
  }
}

/// The combined "toggle a series / read its value" row: avg5, avg10, avg50
/// and p95 are both stat tiles and the chart's series-visibility buttons.
class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.stats, required this.visible, required this.onToggle});
  final CardStats stats;
  final Set<ChartSeries> visible;
  final ValueChanged<ChartSeries> onToggle;

  Widget _tile(ChartSeries series, String label, double? value, Color swatch) {
    final on = visible.contains(series);
    final valueText = value == null ? '—' : '${formatChipSeconds(value)}s';
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: CardDetailLayout.seriesSwatchHeight, color: swatch),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: CardDetailLayout.seriesTileLabelFont)),
        Text(valueText, style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.seriesTileValueFont)),
      ],
    );
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onToggle(series),
        child: AnimatedOpacity(
          duration: Motion.tab,
          opacity: on ? 1 : ChartStyle.dimOpacity,
          child: on
              ? Container(
                  padding: CardDetailLayout.seriesTilePadding,
                  decoration: BoxDecoration(color: Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
                  child: content,
                )
              : DashedBox(padding: CardDetailLayout.seriesTilePadding, child: content),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p95 = stats.timed.isEmpty ? null : stats.percentile(stats.timed.length, 95);
    return Row(children: [
      _tile(ChartSeries.avg5, 'avg5', stats.mean(5), Palette.seaDeep),
      const SizedBox(width: Gaps.tight),
      _tile(ChartSeries.avg10, 'avg10', stats.mean(10), Palette.pink),
      const SizedBox(width: Gaps.tight),
      _tile(ChartSeries.avg50, 'avg50', stats.mean(50), Palette.violet),
      const SizedBox(width: Gaps.tight),
      _tile(ChartSeries.band, 'p95', p95, Palette.desk),
    ]);
  }
}

class _MemoryPanel extends StatelessWidget {
  const _MemoryPanel({required this.state, required this.trainer, required this.itemKey, required this.now});
  final ItemState state;
  final Trainer trainer;
  final ItemKey itemKey;
  final DateTime now;

  static List<double> _curveSamples(Trainer trainer, ItemKey key, fsrs.Card card, DateTime now) {
    final start = card.lastReview!;
    final fallback = start.add(const Duration(days: CardDetailTuning.forgettingCurveFallbackDays));
    final end = card.due.isAfter(start) ? card.due : fallback;
    final span = end.difference(start);
    const n = CardDetailTuning.forgettingCurveSamples;
    return [for (var i = 0; i < n; i++) trainer.retrievability(key, start.add(span * (i / (n - 1))))];
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final card = state.card;
    final reviewed = state.reviewed;
    return MangaPanel(
      padding: const EdgeInsets.all(CardDetailLayout.memPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            InkTag(s.memoryTag),
            const SizedBox(width: Gaps.small),
            Expanded(
              child: Text(reviewed ? s.lastReviewedOn(s.shortDate(card.lastReview!)) : s.neverReviewed,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: Weights.black, fontSize: CardDetailLayout.memHeadingFont)),
            ),
          ]),
          const SizedBox(height: Gaps.panel),
          Row(children: [
            Expanded(
              child: _MemTile(
                  label: s.stabilityLabel, value: card.stability == null ? '—' : '${card.stability!.toStringAsFixed(1)}${s.daysUnit}'),
            ),
            const SizedBox(width: Gaps.tight),
            Expanded(child: _MemTile(label: s.difficultyLabel, value: card.difficulty?.toStringAsFixed(1) ?? '—')),
          ]),
          const SizedBox(height: Gaps.tight),
          Row(children: [
            Expanded(
              child: _MemTile(
                  label: s.retrievabilityLabel,
                  value: reviewed ? '${(trainer.retrievability(itemKey, now) * 100).round()}%' : '—'),
            ),
            const SizedBox(width: Gaps.tight),
            Expanded(
              child: _MemTile(
                  label: s.nextDueLabel, value: reviewed ? s.shortDate(card.due) : s.notScheduled, highlight: true),
            ),
          ]),
          const SizedBox(height: Gaps.section),
          SizedBox(
            height: CardDetailLayout.curveHeight,
            width: double.infinity,
            child: reviewed
                ? ForgettingCurve(samples: _curveSamples(trainer, itemKey, card, now), retentionGoal: trainer.config.desiredRetention)
                : Center(
                    child: Text(s.neverReviewed, style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small))),
          ),
        ],
      ),
    );
  }
}

class _MemTile extends StatelessWidget {
  const _MemTile({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
        padding: CardDetailLayout.memGridPadding,
        decoration: BoxDecoration(
            color: highlight ? Palette.pinkSoft : Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: Weights.black,
                    fontSize: CardDetailLayout.memGridLabelFont,
                    letterSpacing: TagStyle.tracking * CardDetailLayout.memGridLabelFont)),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.memGridValueFont)),
          ],
        ),
      );
}

class _SeeYouBanner extends StatelessWidget {
  const _SeeYouBanner({required this.due});
  final DateTime due;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: SpeechBalloon(
            speaker: CardDetailLayout.balloonSpeaker,
            child: Text(s.seeYouOn(s.shortDate(due)), style: const TextStyle(fontSize: CardDetailLayout.balloonFont)),
          ),
        ),
        const SizedBox(width: Gaps.panel),
        const SizedBox(
          width: CardDetailLayout.tobiWidth,
          height: CardDetailLayout.tobiHeight,
          child: Tobi(pose: TobiPose.standard),
        ),
      ],
    );
  }
}
