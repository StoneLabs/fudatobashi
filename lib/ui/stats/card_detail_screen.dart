import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

/// A card's own record (spec phone 8): the torifuda, its kimariji, TOP SPEED
/// and the cards it is easily confused with, the attempt chart with
/// toggleable stat tiles, and its FSRS memory panel.
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.itemKey});

  final ItemKey itemKey;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late bool _inverted = widget.itemKey.inverted;
  _ModeFilter _mode = _ModeFilter.all;
  Set<ChartSeries> _visible = {...ChartSeries.values};
  AttemptChartData? _chart;

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
    var chart = _chart;
    if (chart == null || !listEquals(chart.attempts, filtered)) chart = _chart = AttemptChartData(filtered);
    final s = S.of(context);
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
                      _Header(poem: poem, inverted: _inverted, stats: chart.stats),
                      const SizedBox(height: Gaps.section),
                      _ModeToggle(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
                      const SizedBox(height: Gaps.panel),
                      MangaPanel(
                        padding: CardDetailLayout.chartPadding,
                        child: chart.attempts.isEmpty
                            ? Padding(
                                padding: CardDetailLayout.chartEmptyPadding,
                                child: Text(s.noAttemptsYet,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small)),
                              )
                            : AttemptChart(
                                data: chart,
                                visible: _visible,
                                attemptsLabel: s.attemptsAxis,
                                topSpeedLabel: s.topSpeedChartLabel),
                      ),
                      const SizedBox(height: Gaps.panel),
                      _SeriesRow(chart: chart, visible: _visible, onToggle: _toggleSeries),
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

/// The card itself, in reading order: the torifuda beside its kimariji and
/// poet, how fast the player takes it (TOP SPEED and the attempt count), the
/// whole poem with readings (上の句, then 下の句), then the cards it is easily
/// confused with.
class _Header extends StatelessWidget {
  const _Header({required this.poem, required this.inverted, required this.stats});
  final Poem poem;
  final bool inverted;
  final CardStats stats;

  static const _verse = TextStyle(
      fontWeight: Weights.bold, fontSize: CardDetailLayout.poemFont, height: CardDetailLayout.poemLineHeight);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lookAlikes = fudaSets.tomofuda(poem.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: CardDetailLayout.cardImageWidth, child: TorifudaCard(poem: poem, inverted: inverted)),
            const SizedBox(width: Gaps.section),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(poem.kimariji,
                        maxLines: 1,
                        style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.kimarijiFont, height: 1)),
                  ),
                  _Caption(s.kimarijiCaption),
                  const SizedBox(height: Gaps.small),
                  RubyText(poem.authorRuby,
                      style: const TextStyle(fontWeight: Weights.bold, fontSize: CardDetailLayout.authorFont, color: Palette.mute)),
                  const SizedBox(height: Gaps.panel),
                  _SpeedLine(stats: stats),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Gaps.section),
        RubyText(poem.kamiRuby, style: _verse),
        const SizedBox(height: CardDetailLayout.verseGap),
        RubyText(poem.shimoRuby, style: _verse),
        if (lookAlikes.isNotEmpty) ...[
          const SizedBox(height: Gaps.section),
          _Caption(s.lookAlikesLabel),
          const SizedBox(height: Gaps.tight),
          Wrap(
            spacing: Gaps.tight,
            runSpacing: Gaps.tight,
            children: [for (final id in lookAlikes) _LookAlikeChip(poem: poems[id], inverted: inverted)],
          ),
        ],
      ],
    );
  }
}

/// A small spaced-capitals caption ("KIMARIJI · 決まり字").
class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: Weights.black,
          fontSize: CardDetailLayout.captionFont,
          letterSpacing: TagStyle.tracking * CardDetailLayout.captionFont));
}

/// TOP SPEED beside how many attempts it comes from.
class _SpeedLine extends StatelessWidget {
  const _SpeedLine({required this.stats});
  final CardStats stats;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final misses = stats.all.where((a) => a.miss).length;
    const countStyle = TextStyle(fontWeight: Weights.bold, fontSize: CardDetailLayout.countFont, color: Palette.mute);
    return Wrap(
      spacing: Gaps.panel,
      runSpacing: Gaps.tight,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _TopSpeedBadge(ms: stats.topSpeedMs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.attemptCount(stats.count), style: countStyle),
            if (misses > 0) Text(s.dontKnowCount(misses), style: countStyle),
          ],
        ),
      ],
    );
  }
}

/// A card this one is easily confused with: its torifuda in miniature and its
/// kimariji; a tap opens its own detail page.
class _LookAlikeChip extends StatelessWidget {
  const _LookAlikeChip({required this.poem, required this.inverted});
  final Poem poem;
  final bool inverted;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: poem.kimariji,
        onTap: () => Navigator.push(
          context,
          MangaRoute<void>(builder: (_) => CardDetailScreen(itemKey: ItemKey(poem.id, inverted))),
        ),
        builder: (context, pressed) => Container(
          padding: CardDetailLayout.lookAlikePadding,
          decoration: BoxDecoration(
              color: pressed ? Palette.sunSoft : Palette.paper,
              border: Border.all(color: Palette.ink, width: Strokes.control)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: CardDetailLayout.lookAlikeCardWidth, child: TorifudaCard(poem: poem, inverted: inverted)),
            const SizedBox(width: Gaps.small),
            Text(poem.kimariji,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.lookAlikeKimarijiFont)),
            const SizedBox(width: Gaps.tight),
            MangaIcon(IconArt.chevron, size: CardDetailLayout.lookAlikeChevron),
          ]),
        ),
      );
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

/// The combined "toggle a series / read its value" row: the three rolling
/// averages and the band are both stat tiles (each series' latest value) and
/// the chart's series-visibility buttons.
class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.chart, required this.visible, required this.onToggle});
  final AttemptChartData chart;
  final Set<ChartSeries> visible;
  final ValueChanged<ChartSeries> onToggle;

  static String _label(ChartSeries series) => switch (series) {
        ChartSeries.band => 'p${AttemptChartTuning.bandHigh.round()}',
        _ => 'avg${series.window}',
      };

  static Color _swatch(ChartSeries series) => switch (series) {
        ChartSeries.shortAverage => ChartStyle.shortAverage,
        ChartSeries.midAverage => ChartStyle.midAverage,
        ChartSeries.longAverage => ChartStyle.longAverage,
        ChartSeries.band => ChartStyle.bandEdge,
      };

  Widget _tile(ChartSeries series) {
    final on = visible.contains(series);
    final value = chart.latest(series);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: CardDetailLayout.seriesSwatchHeight, color: _swatch(series)),
        const SizedBox(height: 3),
        Text(_label(series),
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontWeight: Weights.black, fontSize: CardDetailLayout.seriesTileLabelFont)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value == null ? '—' : '${formatChipSeconds(value)}s',
              maxLines: 1,
              style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.seriesTileValueFont)),
        ),
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
  Widget build(BuildContext context) => Row(children: [
        for (final (i, series) in ChartSeries.values.indexed) ...[
          if (i > 0) const SizedBox(width: Gaps.tight),
          _tile(series),
        ],
      ]);
}

class _MemoryPanel extends StatelessWidget {
  const _MemoryPanel({required this.state, required this.trainer, required this.itemKey, required this.now});
  final ItemState state;
  final Trainer trainer;
  final ItemKey itemKey;
  final DateTime now;

  /// NEXT DUE: the date and how far off it is, or "Today" once it is due.
  _MemTile _dueTile(S s, DateTime due) {
    final days = Trainer.daysBetween(now, due);
    if (days <= 0) return _MemTile(label: s.nextDueLabel, value: s.dueTodayValue, highlight: true);
    return _MemTile(
        label: s.nextDueLabel,
        value: s.shortDate(due),
        suffix: days == 1 ? s.dueTomorrow : s.dueInDaysSuffix(days),
        highlight: true);
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
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Gaps.small,
              runSpacing: Gaps.tight,
              children: [
                InkTag(s.memoryTag),
                Text(reviewed ? s.lastReviewedOn(s.shortDate(card.lastReview!)) : s.neverReviewed,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: CardDetailLayout.memHeadingFont)),
              ],
            ),
          ),
          const SizedBox(height: Gaps.panel),
          _MemRow(
            _MemTile(
                label: s.stabilityLabel,
                value: card.stability?.toStringAsFixed(1) ?? '—',
                suffix: card.stability == null ? null : s.stabilityUnit),
            _MemTile(
                label: s.difficultyLabel,
                value: card.difficulty?.toStringAsFixed(1) ?? '—',
                suffix: card.difficulty == null ? null : s.outOf(FsrsScale.difficultyMax)),
          ),
          const SizedBox(height: Gaps.tight),
          _MemRow(
            _MemTile(
                label: s.retrievabilityLabel,
                value: reviewed ? '${(trainer.retrievability(itemKey, now) * 100).round()}' : '—',
                suffix: reviewed ? s.retrievabilityNow : null),
            reviewed ? _dueTile(s, card.due) : _MemTile(label: s.nextDueLabel, value: s.notScheduled, highlight: true),
          ),
        ],
      ),
    );
  }
}

/// Two memory tiles side by side, as tall as the taller one.
class _MemRow extends StatelessWidget {
  const _MemRow(this.left, this.right);
  final _MemTile left;
  final _MemTile right;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: left),
          const SizedBox(width: Gaps.tight),
          Expanded(child: right),
        ]),
      );
}

/// A memory figure: its label, then the number in display type with a small
/// unit after it ("11.2 days", "6.2 / 10"). The unit wraps under the number
/// when both don't fit.
class _MemTile extends StatelessWidget {
  const _MemTile({required this.label, required this.value, this.suffix, this.highlight = false});
  final String label;
  final String value;
  final String? suffix;
  final bool highlight;

  static const _nbsp = '\u00A0';

  @override
  Widget build(BuildContext context) => Container(
        padding: CardDetailLayout.memGridPadding,
        decoration: BoxDecoration(
            color: highlight ? Palette.pink : Palette.paper, border: Border.all(color: Palette.ink, width: Strokes.control)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  maxLines: 1,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: CardDetailLayout.memGridLabelFont,
                      letterSpacing: TagStyle.tracking * CardDetailLayout.memGridLabelFont)),
            ),
            Text.rich(TextSpan(children: [
              Phrases.span(value.replaceAll(' ', _nbsp),
                  style: const TextStyle(fontFamily: Fonts.display, fontSize: CardDetailLayout.memGridValueFont)),
              if (suffix != null)
                Phrases.span(' ${suffix!.replaceAll(' ', _nbsp)}',
                    style: const TextStyle(fontWeight: Weights.bold, fontSize: CardDetailLayout.memGridSuffixFont)),
            ])),
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
