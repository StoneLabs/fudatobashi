import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/torifuda_spec.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../domain/xp.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/summary_strings.dart';
import '../../state/progress.dart';
import '../history/history_widgets.dart';
import '../home/today_box.dart';
import '../manga/geometry.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../shell/header_actions.dart';
import '../torifuda/torifuda_painter.dart';

/// A part of the hero's bar: [units] of it in [color]. The [done] parts come
/// first, and Tobi stands where they end; a [marked] part is split from the
/// one before by a dashed rule (this run's share of the day).
@immutable
class BarPart {
  const BarPart(this.color, this.units, {this.done = false, this.marked = false});

  final Color color;
  final num units;
  final bool done, marked;
}

/// A label on the hero's bar: at the start of the bar's [part], or with
/// [end] ending where that part ends. One at the start of a part too narrow
/// for it runs on over the parts after it with [runOn], or else sits just
/// past it when the bar's empty rest follows, with no label of its own; any
/// other label that doesn't fit inside its part, or beside the ones before
/// it, is left out.
@immutable
class BarLabel {
  const BarLabel(this.text, {this.part = 0, this.end = false, this.runOn = false, this.color});

  final String text;
  final int part;
  final bool end, runOn;

  /// Its text's colour, ink when null.
  final Color? color;
}

/// The hero of a summary: [banner] over [body] (a [HeroCount], [HeroWord]
/// or [HeroTime]), the [bar] along its slanted bottom edge with its
/// [labels] (or, when any of them doesn't fit, its [fallbackLabels] if
/// those all do) and [ticks] (shares of the bar), and Tobi in [pose]
/// standing where the bar's done part ends, saying [balloon]; no Tobi
/// without a [pose]. A goal reached brings the focus lines of [burst], and
/// [stamp] lies over the bar, or at the top right with [stampOnTop],
/// shrinking when it would reach the banner. The panel is [color].
@immutable
class SummaryHero {
  const SummaryHero({
    required this.banner,
    required this.body,
    required this.bar,
    this.labels = const [],
    this.fallbackLabels = const [],
    this.ticks = const [],
    this.pose = TobiPose.standard,
    this.balloon,
    this.burst,
    this.stamp,
    this.stampOnTop = false,
    this.color = Palette.paper,
  });

  final String banner;
  final Widget body;
  final List<BarPart> bar;
  final List<BarLabel> labels, fallbackLabels;
  final List<double> ticks;
  final TobiPose? pose;
  final String? balloon;
  final BurstSpec? burst;
  final Widget? stamp;
  final bool stampOnTop;
  final Color color;
}

/// One of a summary's three tiles: [label] over [big] (often a
/// [TileFigure]) over [note], on [color] or the band's next colour.
@immutable
class SummaryTile {
  const SummaryTile({required this.label, required this.big, required this.note, this.color});

  final String label;
  final Widget big;
  final String note;
  final Color? color;
}

/// The summary every game ends on: the mode as the header's [title] over
/// its [sub], with the level box (or UNTRACKED when [untracked]); the
/// [hero]; three [tiles]; the card panel's [rows], spread out to fill it;
/// and [home] beside the [shout], on Home's dotted ground.
class RunSummary extends StatelessWidget {
  const RunSummary({
    super.key,
    required this.title,
    required this.sub,
    this.untracked = false,
    required this.hero,
    required this.tiles,
    required this.rows,
    required this.home,
    required this.onHome,
    required this.shout,
    required this.onShout,
  });

  final String title, sub;
  final bool untracked;
  final SummaryHero hero;
  final List<SummaryTile> tiles;
  final List<Widget> rows;
  final String home, shout;
  final VoidCallback onHome, onShout;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: SummaryLayout.maxTextScale,
      child: Stack(children: [
        const Positioned.fill(child: GradationBox(Tones.home)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: BrandTitle(title: title, sub: sub),
                actions: [
                  untracked
                      ? InkTag(
                          s.untrackedTag,
                          fontSize: HomeLayout.untrackedFont,
                          tracking: HomeLayout.untrackedTracking,
                          padding: SummaryLayout.untrackedPadding,
                        )
                      : const LevelButton(),
                ],
              ),
              const SizedBox(height: SummaryLayout.headerGap),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: _Body(
                        cardsHeight: math.max(SummaryLayout.minCardsHeight, box.maxHeight - _Body.cardsTop),
                        hero: HeroPanel(hero),
                        tiles: TileBand(tiles),
                        cards: _CardPanel(rows),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SummaryLayout.actionGap),
              SizedBox(
                height: SummaryActionLayout.height,
                child: Row(children: [
                  SizedBox.fromSize(
                    size: SummaryActionLayout.home,
                    child: InkButton(
                      onTap: onHome,
                      semanticLabel: home,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        MangaIcon(IconArt.home, size: SummaryActionLayout.homeIcon),
                        const SizedBox(height: SummaryActionLayout.homeGap),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(home,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontWeight: Weights.black, fontSize: SummaryActionLayout.homeFont, height: 1)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: SummaryActionLayout.gap),
                  Expanded(
                    child: ShoutButton(
                      label: shout,
                      spec: SummaryActionLayout.shout,
                      fontSize: SummaryActionLayout.shoutFont,
                      inset: SummaryActionLayout.shoutInset,
                      onTap: onShout,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: SummaryLayout.bottomGap),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// The hero at the top, the tiles under it and the card panel in the rest,
/// each panel's slanted edge [SummaryLayout.gap] from the next one's. The
/// card panel is at least [cardsHeight] tall and as tall as its rows need;
/// when that is more than the screen has, the panels scroll together.
class _Body extends StatelessWidget {
  const _Body({required this.cardsHeight, required this.hero, required this.tiles, required this.cards});

  static const tilesTop = SummaryLayout.heroHeight + SummaryLayout.gap;
  static const cardsTop = tilesTop + SummaryLayout.tileHeight + SummaryLayout.gap - SummaryLayout.cut;

  final double cardsHeight;
  final Widget hero, tiles, cards;

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned(left: 0, right: 0, top: 0, height: SummaryLayout.heroHeight, child: hero),
        Positioned(left: 0, right: 0, top: tilesTop, height: SummaryLayout.tileHeight, child: tiles),
        Padding(
          padding: const EdgeInsets.only(top: cardsTop),
          child: ConstrainedBox(constraints: BoxConstraints(minHeight: cardsHeight), child: cards),
        ),
      ]);
}

/// Where the hero's bar and its parts are in a hero of [size]: its top
/// edge rises with the panel's bottom edge, [cut] over the width.
class _BarGeometry {
  _BarGeometry(this.parts, this.size, this.cut) {
    final total = parts.fold<num>(0, (sum, p) => sum + p.units);
    var at = 0.0;
    xs = [0];
    for (final (i, p) in parts.indexed) {
      at += total == 0 ? 0 : p.units / total * size.width;
      xs.add(i == parts.length - 1 ? size.width : at);
    }
  }

  final List<BarPart> parts;
  final Size size;
  final double cut;

  /// Where each part starts, and the last one ends.
  late final List<double> xs;

  double get slope => cut / size.width;

  double topAt(double x) => size.height - Strokes.panel - SummaryHeroLayout.bar - slope * x;

  /// Where the done parts end, as a share of the width.
  double get front {
    var end = 0.0;
    for (final (i, p) in parts.indexed) {
      if (p.done) end = xs[i + 1];
    }
    return end / size.width;
  }
}

/// A [SummaryHero] in a panel with a flat top and a bottom edge rising
/// [SummaryLayout.cut] (or a [SlantCut]'s) over its width, laid out by
/// [metrics].
class HeroPanel extends StatelessWidget {
  const HeroPanel(this.hero, {super.key, this.metrics = SummaryHeroLayout.metrics});
  final SummaryHero hero;
  final HeroMetrics metrics;

  static const _labelStyle = TextStyle(fontWeight: Weights.black, fontSize: SummaryHeroLayout.labelFont, height: 1);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final bar = _BarGeometry(hero.bar, box.biggest, SlantCut.of(context, SummaryLayout.cut));
        final tobi = metrics.tobi;
        final tobiX = math.min(
          math.max(bar.front, SummaryHeroLayout.tobiMinFront) * bar.size.width,
          bar.size.width - SummaryHeroLayout.tobiRightInset - tobi.width / 2,
        );
        final balloon = hero.balloon;
        final banner = InkBanner(hero.banner, fontSize: SummaryHeroLayout.bannerFont);
        final stamp = hero.stamp;
        final pose = hero.pose;
        final bodyWidth = math.min(
          math.min(metrics.bodyWidth, bar.size.width - 2 * SummaryHeroLayout.bodyLeft),
          pose == null || !metrics.clearOfTobi ? double.infinity : tobiX - tobi.width / 2 - SummaryHeroLayout.bodyLeft,
        );
        return MangaPanel(
          shape: PanelShape(bottomRight: Offset(0, bar.cut)),
          color: hero.color,
          art: [if (hero.burst case final burst?) BurstLayer(burst)],
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: CustomPaint(painter: _BarPainter(bar, hero.ticks))),
            ..._labels(context, bar),
            if (stamp == null || !hero.stampOnTop)
              Positioned(
                left: SummaryHeroLayout.bannerAt.dx,
                top: SummaryHeroLayout.bannerAt.dy,
                child: banner,
              ),
            Positioned(
              left: SummaryHeroLayout.bodyLeft,
              top: 0,
              bottom: 0,
              width: bodyWidth,
              child: hero.body,
            ),
            if (stamp != null)
              hero.stampOnTop
                  ? Positioned(
                      left: SummaryHeroLayout.bannerAt.dx,
                      top: SummaryHeroLayout.bannerAt.dy,
                      right: metrics.topStampInset.dx,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        banner,
                        const SizedBox(width: SummaryHeroLayout.topStampGap),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: math.max(0, metrics.topStampInset.dy - SummaryHeroLayout.bannerAt.dy)),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.topRight, child: stamp),
                            ),
                          ),
                        ),
                      ]),
                    )
                  : Positioned(left: metrics.stampAt.dx, top: metrics.stampAt.dy, child: stamp),
            if (pose != null)
              Positioned(
                left: tobiX - tobi.width / 2,
                top: bar.topAt(tobiX) - tobi.height * SummaryHeroLayout.tobiFeet,
                width: tobi.width,
                height: tobi.height,
                child: Tobi(pose: pose),
              ),
            if (balloon != null)
              Positioned(
                left: tobiX + SummaryHeroLayout.balloonLeft,
                top: SummaryHeroLayout.balloonTop,
                width: SummaryHeroLayout.balloon.width,
                height: SummaryHeroLayout.balloon.height,
                child: SpeechBalloon(
                  speaker: SummaryHeroLayout.balloonSpeaker,
                  child: Text(balloon, style: const TextStyle(fontSize: SummaryHeroLayout.balloonFont)),
                ),
              ),
          ]),
        );
      });

  /// The bar's labels, each along the bar's slant and inside a part (see
  /// [BarLabel]); the fallback ones when any of them doesn't fit and those
  /// all do.
  List<Widget> _labels(BuildContext context, _BarGeometry bar) {
    final placed = _place(context, bar, hero.labels);
    if (placed.length == hero.labels.length || hero.fallbackLabels.isEmpty) return placed;
    final fallback = _place(context, bar, hero.fallbackLabels);
    return fallback.length == hero.fallbackLabels.length ? fallback : placed;
  }

  List<Widget> _place(BuildContext context, _BarGeometry bar, List<BarLabel> labels) {
    const start = SummaryHeroLayout.labelStart, inset = SummaryHeroLayout.labelInset;
    final width = bar.size.width;
    (double, double) room(int part) {
      final from = bar.xs[part], to = bar.xs[part + 1];
      return (from <= 0 ? start : from + inset, to >= width ? width - start : to - inset);
    }

    final rest = bar.parts.length - 1;
    final restFree = !bar.parts[rest].done && labels.every((l) => l.part != rest);
    final taken = <(double, double)>[];
    final placed = <Widget>[];
    bool clashes(double left, double right) => taken.any((t) => left < t.$2 + inset && right + inset > t.$1);
    for (final label in labels) {
      final w = _widthOf(context, label.text);
      var (lo, hi) = room(label.part);
      if (!label.end && lo + w > hi) {
        if (label.runOn) {
          hi = room(rest).$2;
        } else if (restFree && label.part == rest - 1) {
          (lo, hi) = room(rest);
        }
      }
      var left = label.end ? hi - w : lo;
      if (!label.end) {
        for (final t in [...taken]..sort((a, b) => a.$1.compareTo(b.$1))) {
          if (left < t.$2 + inset && left + w + inset > t.$1) left = t.$2 + inset;
        }
      }
      if (left < lo || left + w > hi || clashes(left, left + w)) continue;
      taken.add((left, left + w));
      placed.add(Positioned(
        left: left,
        top: bar.topAt(left),
        height: SummaryHeroLayout.bar,
        child: Transform.rotate(
          angle: -math.atan(bar.slope),
          alignment: Alignment.topLeft,
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(label.text,
                maxLines: 1,
                softWrap: false,
                style: label.color == null ? _labelStyle : _labelStyle.copyWith(color: label.color)),
          ),
        ),
      ));
    }
    return placed;
  }

  static double _widthOf(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(_labelStyle)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }
}

/// The bar's parts along the hero's slanted bottom edge, split by rules and
/// crossed by its [ticks], under an ink rule along its top.
class _BarPainter extends CustomPainter {
  _BarPainter(this.bar, this.ticks);
  final _BarGeometry bar;
  final List<double> ticks;

  @override
  void paint(Canvas canvas, Size size) {
    final xs = bar.xs;
    for (final (i, part) in bar.parts.indexed) {
      if (xs[i + 1] <= xs[i]) continue;
      canvas.drawPath(
        Polygon.path([
          Offset(xs[i], bar.topAt(xs[i])),
          Offset(xs[i + 1], bar.topAt(xs[i + 1])),
          Offset(xs[i + 1], size.height),
          Offset(xs[i], size.height),
        ]),
        Paint()..color = part.color,
      );
    }
    final split = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = SummaryHeroLayout.split;
    for (final (i, part) in bar.parts.indexed) {
      final x = xs[i];
      if (x <= 0 || xs[i + 1] <= x) continue;
      final rule = Path()
        ..moveTo(x, bar.topAt(x))
        ..lineTo(x, size.height);
      canvas.drawPath(part.marked ? Dashes.of(rule, SummaryHeroLayout.markedSplit) : rule, split);
    }
    final w = size.width;
    final tick = Paint()
      ..color = Palette.ink
      ..strokeWidth = SummaryHeroLayout.tick;
    for (final t in ticks) {
      final x = t * w;
      canvas.drawLine(Offset(x, bar.topAt(x) - SummaryHeroLayout.tickReach), Offset(x, size.height), tick);
    }
    canvas.drawPath(
      Polygon.path([
        Offset(0, bar.topAt(0) - SummaryHeroLayout.rule),
        Offset(w, bar.topAt(w) - SummaryHeroLayout.rule),
        Offset(w, bar.topAt(w)),
        Offset(0, bar.topAt(0)),
      ]),
      Paint()..color = Palette.ink,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.bar.size != bar.size || old.bar.cut != bar.cut || old.bar.parts != bar.parts || old.ticks != ticks;
}

/// A count as the hero's answer: the big [value] with its [label] and
/// [note] beside it. The number gives way first when they are wide.
class HeroCount extends StatelessWidget {
  const HeroCount(this.value,
      {super.key, required this.label, required this.note, this.metrics = SummaryHeroLayout.metrics});

  final String value, label, note;
  final HeroMetrics metrics;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: metrics.countTop),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: metrics.countFont,
            child: Row(children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontFamily: Fonts.display,
                      fontSize: metrics.countFont,
                      letterSpacing: SummaryHeroLayout.countTracking * metrics.countFont,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: SummaryHeroLayout.countGap),
              ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: SummaryHeroLayout.bodyWidth * SummaryHeroLayout.countLabelShare),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(label,
                        maxLines: 1,
                        style: const TextStyle(fontWeight: Weights.black, fontSize: SummaryHeroLayout.countLabelFont)),
                    const SizedBox(height: SummaryHeroLayout.countNoteGap),
                    Text(note,
                        maxLines: 1,
                        style: const TextStyle(
                            fontWeight: Weights.bold, fontSize: SummaryHeroLayout.countNoteFont, color: Palette.inkSoft)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// A word as the hero's answer, outlined for a goal reached and plain
/// otherwise, with [sub] on a line under it.
class HeroWord extends StatelessWidget {
  const HeroWord(this.word, {super.key, this.outlined = false, this.sub, this.metrics = SummaryHeroLayout.metrics});

  final String word;
  final bool outlined;
  final Widget? sub;
  final HeroMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: Fonts.display,
      fontSize: outlined ? SummaryHeroLayout.wordFont : metrics.plainWordFont,
      height: 1,
    );
    final sub = this.sub;
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: SummaryHeroLayout.wordInset,
        top: outlined ? metrics.wordTop : metrics.plainWordTop,
        width: metrics.wordWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: MediaQuery.withNoTextScaling(
            child: outlined
                ? OutlinedText(word, style: style, outlineWidth: SummaryHeroLayout.wordOutline)
                : Text(word, maxLines: 1, style: style),
          ),
        ),
      ),
      if (sub != null)
        Positioned(
          left: SummaryHeroLayout.wordInset,
          top: metrics.subTop,
          width: SummaryHeroLayout.bodyWidth - SummaryHeroLayout.wordInset,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontWeight: Weights.bold, fontSize: SummaryHeroLayout.subFont),
              child: sub,
            ),
          ),
        ),
    ]);
  }
}

/// A time as the hero's answer, its milliseconds smaller; with [tenths],
/// as m:ss.d.
class HeroTime extends StatelessWidget {
  const HeroTime(this.time, {super.key, this.tenths = false, this.metrics = SummaryHeroLayout.metrics});

  final Duration time;
  final bool tenths;
  final HeroMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final text = tenths ? formatTenths(time) : formatRunTime(time);
    final dot = text.lastIndexOf('.');
    return Padding(
      padding: EdgeInsets.only(top: metrics.timeTop),
      child: Align(
        alignment: Alignment.topLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: text.substring(0, dot)),
              TextSpan(
                text: text.substring(dot),
                style: TextStyle(fontSize: metrics.timeFont * SummaryHeroLayout.timeFractionShare),
              ),
            ]),
            maxLines: 1,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: Fonts.display,
              fontSize: metrics.timeFont,
              letterSpacing: SummaryHeroLayout.countTracking * metrics.timeFont,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile's figure: [value] in display type at [size], with a smaller
/// [unit] after it or [prefix] before it, in [color].
class TileFigure extends StatelessWidget {
  const TileFigure(this.value, {super.key, this.unit, this.prefix, this.size = SummaryTileLayout.bigFont, this.color});

  final String value;
  final String? unit, prefix;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(fontSize: size * SummaryTileLayout.bigSmallFont / SummaryTileLayout.bigFont);
    return Text.rich(
      TextSpan(children: [
        if (prefix case final prefix?) TextSpan(text: prefix, style: small),
        TextSpan(text: value),
        if (unit case final unit?) TextSpan(text: unit, style: small),
      ]),
      maxLines: 1,
      style: TextStyle(fontFamily: Fonts.display, fontSize: size, height: 1, color: color),
    );
  }
}

/// Tiles side by side: slices of one band whose edges rise with the panels
/// above and below, each [SummaryTile] its label over its figure over its
/// note, laid out by [spec]; as tall as the tallest, and at least
/// [minHeight].
class TileBand extends StatelessWidget {
  const TileBand(this.tiles, {super.key, this.spec = SummaryTileLayout.spec, this.minHeight = 0});
  final List<SummaryTile> tiles;
  final TileSpec spec;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final label = TextStyle(
      fontWeight: Weights.black,
      fontSize: spec.labelFont,
      letterSpacing: spec.labelTracking * spec.labelFont,
      height: spec.lines > 1 ? SummaryTileLayout.lineHeight : 1,
    );
    final note = TextStyle(
        fontWeight: Weights.bold, fontSize: spec.noteFont, height: spec.lines > 1 ? SummaryTileLayout.lineHeight : 1);
    Widget lines(String text, TextStyle style) => spec.lines > 1
        ? Text(text, maxLines: spec.lines, overflow: TextOverflow.ellipsis, style: style)
        : _OneLine(Text(text, maxLines: 1, style: style));
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: SlantRow(
        cut: SummaryLayout.cut,
        gap: SummaryLayout.gap,
        padding: spec.padding,
        colors: [
          for (final (i, tile) in tiles.indexed)
            tile.color ?? SummaryTileLayout.colors[i % SummaryTileLayout.colors.length],
        ],
        children: [
          for (final tile in tiles)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                lines(tile.label, label),
                SizedBox(height: spec.rowGap),
                _OneLine(tile.big),
                if (tile.note.isNotEmpty) ...[
                  SizedBox(height: spec.rowGap),
                  lines(tile.note, note),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

/// One line that shrinks rather than wraps.
class _OneLine extends StatelessWidget {
  const _OneLine(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
}

/// The card panel: its rows spread out to fill it, dotted rules between
/// them; it is as tall as they need.
class _CardPanel extends StatelessWidget {
  const _CardPanel(this.rows);
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => MangaPanel(
        shape: const PanelShape(topLeft: Offset(0, SummaryLayout.cut)),
        padding: SummaryPanelLayout.padding,
        child: LayoutBuilder(
          builder: (context, box) => ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.minHeight),
            child: IntrinsicHeight(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) const Expanded(child: _RowRule()),
                  row,
                ],
              ]),
            ),
          ),
        ),
      );
}

/// The dotted rule between two rows, in the middle of the room between
/// them.
class _RowRule extends StatelessWidget {
  const _RowRule();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SummaryPanelLayout.rowGap),
        child: const Center(
          child: SizedBox(
            height: SummaryPanelLayout.dot,
            width: double.infinity,
            child: CustomPaint(painter: _DotsPainter()),
          ),
        ),
      );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = SummaryPanelLayout.dotColor;
    const r = SummaryPanelLayout.dot / 2;
    for (var x = r; x < size.width; x += SummaryPanelLayout.dotStep) {
      canvas.drawCircle(Offset(x, size.height / 2), r, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}

/// A row of the card panel: a marker [heading] in [accent] with a [note]
/// under it, beside [child] (cards, the week's stamps, the levels), which
/// sits level with the heading's middle when [centered].
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.heading,
    required this.accent,
    this.note,
    required this.child,
    this.centered = false,
  });

  final String heading;
  final Color accent;
  final String? note;
  final Widget child;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    return Row(crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
      SizedBox(
        width: SummaryPanelLayout.headWidth,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(
              child: HistoryHeading(title: heading, accent: accent, titleFont: SummaryPanelLayout.headFont),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: SummaryPanelLayout.noteGap),
            Text(note,
                style: const TextStyle(
                    fontWeight: Weights.bold, fontSize: SummaryPanelLayout.noteFont, color: Palette.inkSoft)),
          ],
        ]),
      ),
      const SizedBox(width: SummaryPanelLayout.headGap),
      Expanded(child: centered ? Align(alignment: Alignment.centerLeft, child: child) : child),
    ]);
  }
}

/// A shelf of the card panel: a [heading] in [accent] with its [note],
/// beside its [cards] and the [tail] under them.
@immutable
class CardShelf {
  const CardShelf(this.heading, this.accent, this.note, this.cards, {this.tail});

  final String heading;
  final Color accent;
  final String note;
  final List<SummaryCard> cards;
  final String? tail;
}

/// [shelves] as rows of the card panel, the empty ones left out; a lone
/// shelf has two lines of cards.
List<Widget> shelfRows(List<CardShelf> shelves) {
  final shown = [for (final shelf in shelves) if (shelf.cards.isNotEmpty) shelf];
  return [
    for (final shelf in shown)
      SummaryRow(
        heading: shelf.heading,
        accent: shelf.accent,
        note: shelf.note,
        child: SummaryCards(shelf.cards, lines: shown.length == 1 ? 2 : 1, tail: shelf.tail),
      ),
  ];
}

/// A row of the card panel that is a dashed note across it.
class SummaryNote extends StatelessWidget {
  const SummaryNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => DashedBox(
        border: Strokes.label,
        padding: SummaryPanelLayout.noteBoxPadding,
        child: Text.rich(
          Phrases.span(text),
          style: const TextStyle(fontWeight: Weights.bold, fontSize: SummaryPanelLayout.noteBoxFont),
        ),
      );
}

/// A card in the card panel, with a badge under it: its time [ms] in its
/// speed tier's colours, or a [tag] in [tagColor].
@immutable
class SummaryCard {
  const SummaryCard(this.poemId, {this.inverted = false, this.ms, this.tag, this.tagColor = Palette.sun});

  final int poemId;
  final bool inverted;
  final double? ms;
  final String? tag;
  final Color tagColor;
}

/// Cards with their kimariji, [lines] lines of them at most (smaller ones
/// when there are more than a line of the larger holds), and a [tail]
/// under them.
class SummaryCards extends StatelessWidget {
  const SummaryCards(this.cards, {super.key, this.lines = 1, this.tail});

  final List<SummaryCard> cards;
  final int lines;
  final String? tail;

  @override
  Widget build(BuildContext context) {
    final dense = cards.length > SummaryPanelLayout.perLine;
    final width = dense ? SummaryPanelLayout.denseCard : SummaryPanelLayout.card;
    final room = (dense ? SummaryPanelLayout.densePerLine : SummaryPanelLayout.perLine) * lines;
    final more = cards.length > room ? cards.length - room + 1 : 0;
    final tail = this.tail;
    final wrap = Wrap(
      spacing: dense ? SummaryPanelLayout.denseCardGap : SummaryPanelLayout.cardGap,
      runSpacing: SummaryPanelLayout.cardRunGap,
      children: [
        for (final card in cards.take(cards.length - more)) _Card(card, width: width),
        if (more > 0) _More(more, width: width),
      ],
    );
    if (tail == null) return wrap;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      wrap,
      const SizedBox(height: SummaryPanelLayout.tailGap),
      Text(tail,
          style: const TextStyle(fontWeight: Weights.bold, fontSize: SummaryPanelLayout.tailFont, color: Palette.inkSoft)),
    ]);
  }
}

class _Card extends StatelessWidget {
  const _Card(this.card, {required this.width});

  final SummaryCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final ms = card.ms;
    final tag = card.tag;
    final tier = ms == null ? null : SpeedTiers.of(ms);
    return SizedBox(
      width: width,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TorifudaCard(poem: poems[card.poemId], inverted: card.inverted),
        if (tier != null)
          _Badge(
            text: '${formatSeconds(ms!)}s',
            fill: Palette.tiers[tier],
            style: TextStyle(
                fontFamily: Fonts.display, fontSize: SummaryPanelLayout.badgeFont, color: Palette.tierText[tier], height: 1),
          )
        else if (tag != null)
          _Badge(
            text: tag,
            fill: card.tagColor,
            style: const TextStyle(fontWeight: Weights.black, fontSize: SummaryPanelLayout.tagFont, height: 1),
          ),
        const SizedBox(height: SummaryPanelLayout.kimarijiGap),
        _OneLine(Text(
          kimarijiFor(context, card.poemId),
          maxLines: 1,
          style: const TextStyle(fontWeight: Weights.black, fontSize: SummaryPanelLayout.kimarijiFont, height: 1),
        )),
      ]),
    );
  }
}

/// A card's time or tag, in a bordered box under it.
class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.fill, required this.style});

  final String text;
  final Color fill;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: SummaryPanelLayout.badgeGap),
        child: DecoratedBox(
          decoration:
              BoxDecoration(color: fill, border: Border.all(color: Palette.ink, width: SummaryPanelLayout.badgeBorder)),
          child: Padding(
            padding: SummaryPanelLayout.badgePadding,
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, softWrap: false, style: style)),
          ),
        ),
      );
}

/// In the last card's place, how many more cards there are.
class _More extends StatelessWidget {
  const _More(this.count, {required this.width});

  final int count;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * TorifudaSpec.aspect,
        child: DashedBox(
          border: Strokes.label,
          dash: Strokes.fineDash,
          padding: const EdgeInsets.all(Strokes.label),
          child: Center(
            child: Text(
              S.of(context).summaryMore(count),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: Weights.black, fontSize: SummaryPanelLayout.moreFont, height: 1.1),
            ),
          ),
        ),
      );
}

/// A level as a tile's figure: the level's number big, "LV" small.
TileFigure levelFigure(S s, int level) {
  final (before, after) = s.summaryLevelAround;
  return TileFigure('$level', prefix: before.isEmpty ? null : before, unit: after.isEmpty ? null : after);
}

/// The reward tile of a game that earned [xp]: the level reached when it
/// went up, else the XP and how far the next level is; for a game that
/// saved nothing, that it didn't.
SummaryTile rewardTile(S s, XpGain? xp) {
  if (xp == null) return SummaryTile(label: s.xpUnit, big: const TileFigure(missingTime), note: s.summaryNotSaved);
  final earned = groupDigits(xp.award.total);
  final level = xp.levelAfter;
  return xp.levelsGained > 0
      ? SummaryTile(label: s.levelUpBand, big: levelFigure(s, level.level), note: s.summaryXpGained(earned))
      : SummaryTile(
          label: s.xpUnit, big: TileFigure('+$earned'), note: s.summaryXpToLevel(groupDigits(level.toNext), level.level + 1));
}

/// The week's stamps in a row (see [DayStamp]).
class SummaryWeek extends StatelessWidget {
  const SummaryWeek(this.week, {super.key});

  final List<WeekStamp> week;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, day) in week.indexed) ...[
            if (i > 0) const SizedBox(width: SummaryPanelLayout.stampGap),
            DayStamp(day, size: SummaryPanelLayout.stamp),
          ],
        ]),
      );
}
