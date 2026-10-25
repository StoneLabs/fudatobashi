import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/xp.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/run_tab_strings.dart';
import '../../l10n/review_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../results/run_summary.dart';
import 'history_widgets.dart';

/// A run tab's panels stacked down the page inside the gutters, scrolling
/// when they are taller than it: [children] [ReviewLayout.gap] apart, then
/// [fill], which reaches down to the bottom of the page and is never
/// shorter than [fillMinHeight] (nor than its contents).
class ReviewColumn extends StatelessWidget {
  const ReviewColumn({super.key, required this.children, this.fill, this.fillMinHeight = ReviewLayout.minFillHeight});
  final List<Widget> children;
  final Widget? fill;
  final double fillMinHeight;

  @override
  Widget build(BuildContext context) {
    const side = EdgeInsets.symmetric(horizontal: Gaps.gutter);
    final fill = this.fill;
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: side.copyWith(top: ReviewLayout.topGap, bottom: fill == null ? ReviewLayout.bottomGap : 0),
        sliver: SliverList.list(children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: ReviewLayout.gap),
            child,
          ],
        ]),
      ),
      if (fill != null)
        SliverPadding(
          padding: side,
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.only(top: children.isEmpty ? 0 : ReviewLayout.gap, bottom: ReviewLayout.bottomGap),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: fillMinHeight),
                child: fill,
              ),
            ),
          ),
        ),
    ]);
  }
}

/// A panel of a run tab's stack ([SlantPanel]) on [color]: a heading row
/// ([title] with its [sub] word over a marker in [mark], and a [note] on
/// the right), then [child], which takes the rest of the panel when it
/// [expands]. Its top edge is slanted unless [flatTop], its bottom unless
/// [flatBottom].
class ReviewSlab extends StatelessWidget {
  const ReviewSlab({
    super.key,
    this.title,
    this.sub,
    this.note,
    this.mark = HistoryRunStyle.headingMark,
    this.color = Palette.paper,
    this.flatTop = false,
    this.flatBottom = false,
    this.expands = false,
    this.padding = ReviewLayout.panelPadding,
    required this.child,
  });

  final String? title, sub, note;
  final Color mark, color;
  final bool flatTop, flatBottom, expands;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return SlantPanel(
      slantTop: !flatTop,
      slantBottom: !flatBottom,
      cut: ReviewLayout.cut,
      color: color,
      padding: padding,
      child: title == null && !expands
          ? child
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (title != null) ...[
                HistoryHeading(title: title, sub: sub, note: note, accent: mark, titleFont: ReviewLayout.headingFont),
                const SizedBox(height: ReviewLayout.headingGap),
              ],
              if (expands) Expanded(child: child) else child,
            ]),
    );
  }
}

/// A run tab's prose: bold, with [strong] parts in black.
class ReviewText extends StatelessWidget {
  const ReviewText(this.text, {super.key, this.strong, this.strongColor});
  final String text;

  /// Said after [text], in black and [strongColor].
  final String? strong;
  final Color? strongColor;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: text),
          if (strong case final strong?)
            TextSpan(text: ' $strong', style: TextStyle(fontWeight: Weights.black, color: strongColor)),
        ]),
        style: const TextStyle(
            fontWeight: Weights.bold, fontSize: ReviewLayout.textFont, height: ReviewLayout.textHeight),
      );
}

/// A small centred caption under a panel.
class ReviewCaption extends StatelessWidget {
  const ReviewCaption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: TextAlign.center,
      style: const TextStyle(
          fontWeight: Weights.bold,
          fontSize: ReviewLayout.captionFont,
          height: ReviewLayout.captionHeight,
          color: Palette.inkSoft));
}

/// A tab's one loud button: [label] with [icon] before it, or the arrow
/// after it.
class ReviewShout extends StatelessWidget {
  const ReviewShout({super.key, required this.label, this.icon, required this.onTap});
  final String label;
  final VectorArt? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: ReviewLayout.shoutHeight,
        child: ShoutButton(
          label: label.toUpperCase(),
          icon: icon,
          arrow: icon == null,
          spec: SummaryActionLayout.shout,
          fontSize: ReviewLayout.shoutFont,
          inset: ReviewLayout.shoutInset,
          onTap: onTap,
        ),
      );
}

/// A label tracked in capitals, as over a shelf of cards.
class ShelfLabel extends StatelessWidget {
  const ShelfLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      maxLines: 1,
      style: const TextStyle(
          fontWeight: Weights.black,
          fontSize: ReviewLayout.shelfLabelFont,
          letterSpacing: ReviewLayout.shelfLabelTracking * ReviewLayout.shelfLabelFont,
          height: 1));
}

/// One of [CountTiles]: a count, what it counts and its icon, on [color].
class CountTile {
  const CountTile(this.value, this.label, {required this.icon, required this.color});
  final String value, label;
  final VectorArt icon;
  final Color color;
}

/// Small counts side by side as tilted tiles: each number with its icon,
/// over its label; as tall as the tallest, and at least
/// [ReviewTileLayout.countHeight].
class CountTiles extends StatelessWidget {
  const CountTiles(this.tiles, {super.key});
  final List<CountTile> tiles;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: ReviewTileLayout.countHeight),
        child: SlantRow(
          cut: ReviewLayout.cut,
          gap: ReviewLayout.gap,
          padding: ReviewTileLayout.countPadding,
          colors: [for (final t in tiles) t.color],
          children: [
            for (final t in tiles)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(t.value,
                            maxLines: 1,
                            style: const TextStyle(
                                fontFamily: Fonts.display, fontSize: ReviewTileLayout.countFont, height: 1)),
                      ),
                    ),
                    MangaIcon(t.icon, size: ReviewTileLayout.countIcon, strokeWidth: ReviewTileLayout.countIconStroke),
                  ]),
                  Text(t.label.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: Weights.black,
                          fontSize: ReviewTileLayout.countLabelFont,
                          letterSpacing: ReviewTileLayout.countLabelTracking * ReviewTileLayout.countLabelFont,
                          height: ReviewTileLayout.countLabelHeight)),
                ],
              ),
          ],
        ),
      );
}

/// A figure as a hero's answer: [value] in display type at [size], [top]
/// from the hero's top, with a small [unit] after it, then a [badge] and a
/// quiet [line].
class HeroFigure extends StatelessWidget {
  const HeroFigure(
    this.value, {
    super.key,
    this.unit,
    this.badge,
    this.line,
    this.top = ReviewHeroLayout.figureTop,
    this.size = ReviewHeroLayout.figureFont,
  });

  final String value;
  final String? unit, line;
  final Widget? badge;
  final double top, size;

  @override
  Widget build(BuildContext context) {
    const gap = WidgetSpan(child: SizedBox(width: ReviewHeroLayout.figureGap));
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Align(
        alignment: Alignment.topLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: size,
                      letterSpacing: SummaryHeroLayout.countTracking * size)),
              if (unit case final unit?) ...[
                gap,
                TextSpan(
                    text: unit,
                    style: const TextStyle(fontWeight: Weights.black, fontSize: ReviewHeroLayout.figureUnitFont)),
              ],
              if (badge case final badge?) ...[
                gap,
                WidgetSpan(alignment: PlaceholderAlignment.middle, child: badge),
              ],
              if (line case final line?) ...[
                gap,
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Text(line,
                      style: const TextStyle(
                          fontWeight: Weights.bold,
                          fontSize: ReviewHeroLayout.figureLineFont,
                          color: Palette.inkSoft)),
                ),
              ],
            ]),
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(height: 1),
          ),
        ),
      ),
    );
  }
}

/// A hero of a run tab, [height] tall: [hero] laid out by [metrics].
class ReviewHero extends StatelessWidget {
  const ReviewHero(this.hero,
      {super.key, this.height = ReviewLayout.heroHeight, this.metrics = ReviewHeroLayout.metrics});
  final SummaryHero hero;
  final double height;
  final HeroMetrics metrics;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, child: HeroPanel(hero, metrics: metrics));
}

/// A label and its value on a line over a dotted rule, [badge] after the
/// value; the [total] line sits under an ink rule with a bigger value.
class ValueLine extends StatelessWidget {
  const ValueLine(this.label, this.value, {super.key, this.badge, this.total = false});
  final String label, value;
  final Widget? badge;
  final bool total;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    final row = Padding(
      padding: total ? ValueLineStyle.totalPadding : ValueLineStyle.padding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: Weights.bold, fontSize: ValueLineStyle.font, height: 1))),
        const SizedBox(width: Gaps.panel),
        Text(value,
            style: TextStyle(
                fontFamily: Fonts.display,
                fontSize: total ? ValueLineStyle.totalFont : ValueLineStyle.valueFont,
                height: 1)),
        if (badge != null) ...[const SizedBox(width: Gaps.small), badge],
      ]),
    );
    if (total) {
      return DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Palette.ink, width: Strokes.label))),
        child: row,
      );
    }
    return CustomPaint(foregroundPainter: const _DottedRule(), child: row);
  }
}

class _DottedRule extends CustomPainter {
  const _DottedRule();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ValueLineStyle.rule
      ..strokeWidth = 1;
    final y = size.height - 0.5;
    const step = ValueLineStyle.dots;
    for (var x = 0.0; x < size.width; x += step[0] + step[1]) {
      canvas.drawLine(Offset(x, y), Offset(x + step[0], y), paint);
    }
  }

  @override
  bool shouldRepaint(_DottedRule old) => false;
}

/// A rating's change as a small badge: green up, pink down.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge(this.change, {super.key});
  final num change;

  @override
  Widget build(BuildContext context) => Container(
        height: ChangeBadgeStyle.height,
        padding: ChangeBadgeStyle.padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: change.round() < 0 ? Palette.pink : Palette.land,
          border: Border.all(width: Strokes.label),
        ),
        child: Text(signedPoints(change),
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(fontWeight: Weights.black, fontSize: ChangeBadgeStyle.font, height: 1)),
      );
}

/// Points gained or lost, as +44 or −1002.
String signedPoints(num change) {
  final n = change.round();
  return '${n < 0 ? '−' : '+'}${n.abs()}';
}

/// A game's experience: a hero whose bar is the level reached, and the
/// panel of where it came from; a line saying so for a game that earned
/// none.
List<Widget> xpParts(S s, XpGain? gain) =>
    gain == null || gain.award.total == 0 ? [ReviewCaption(s.runNoXp)] : [XpHero(gain), XpSources(gain)];

/// The experience a game earned as a hero: the total, the level bar as its
/// bar, and a stamp for a level gained.
class XpHero extends StatelessWidget {
  const XpHero(this.gain, {super.key});
  final XpGain gain;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final level = gain.levelAfter;
    final gained = gain.levelsGained > 0;
    final at = s.levelShort(level.level);
    final next = s.xpToNext(level.toNext, level.level + 1);
    return ReviewHero(
      height: ReviewHeroLayout.xpHeight,
      metrics: gained ? ReviewHeroLayout.xpUpMetrics : ReviewHeroLayout.xpMetrics,
      SummaryHero(
        banner: s.runXpLabel.toUpperCase(),
        body: HeroFigure('+${groupDigits(gain.award.total)}',
            unit: s.xpUnit,
            top: gained ? ReviewHeroLayout.xpUpTop : ReviewHeroLayout.xpTop,
            size: gained ? ReviewHeroLayout.xpUpFont : ReviewHeroLayout.xpFont),
        bar: [BarPart(Palette.pink, level.into), BarPart(Palette.paper, level.toNext)],
        labels: [BarLabel(at), BarLabel(next, part: 1, end: true)],
        fallbackLabels: [BarLabel('$at · $next')],
        pose: gained ? null : TobiPose.standard,
        stamp: gained ? RunStamp(s.levelUpBand, sub: s.runLevelFrom(gain.levelBefore.level), fontSize: RunStampStyle.xpFont) : null,
        stampOnTop: true,
      ),
    );
  }
}

/// Where a game's experience came from, a line each, and the total.
class XpSources extends StatelessWidget {
  const XpSources(this.gain, {super.key});
  final XpGain gain;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ReviewSlab(
      title: s.reviewXpSources,
      sub: s.sub?.reviewXpSources,
      mark: Palette.paper,
      color: Palette.sunSoft,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final part in gain.award.parts)
          ValueLine([s.xpSource(part.source), ?s.xpCount(part)].join(' '), groupDigits(part.xp)),
        ValueLine(s.runXpTotal, groupDigits(gain.award.total), total: true),
      ]),
    );
  }
}

/// The tile of what a game earned: the level reached when it went up,
/// else the XP and the level it left.
SummaryTile xpTile(S s, XpGain? xp) {
  if (xp == null) return SummaryTile(label: s.xpUnit, big: const TileFigure(missingTime), note: '');
  final earned = groupDigits(xp.award.total);
  final level = xp.levelAfter.level;
  return xp.levelsGained > 0
      ? SummaryTile(label: s.levelUpBand, big: levelFigure(s, level), note: s.summaryXpGained(earned))
      : SummaryTile(label: s.xpUnit, big: TileFigure('+$earned'), note: s.levelShort(level));
}
