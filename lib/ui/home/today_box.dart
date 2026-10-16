import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../domain/today_set.dart';
import '../../l10n/home_strings.dart';
import '../../l10n/strings.dart';
import '../../state/progress.dart';
import '../manga/manga.dart';
import '../stats/practice_calendar.dart';

/// Journey Home's today box: today's set as one bar in looks (done green,
/// then reviews, new cards and the room misses take), a legend with the
/// looks, and the week's stamps. A done day gets a solid green bar and the
/// 本日完了 hanko. It sits between the map and the hero at a fixed height.
class TodayBox extends StatelessWidget {
  const TodayBox({super.key, required this.set, required this.week});

  /// Null until today's set is built.
  final TodaySet? set;
  final List<WeekStamp> week;

  static const _empty = SetBar(reviews: 0, reviewsDone: 0, fresh: 0, freshDone: 0, extra: 0, extraDone: 0, extraKnown: 0);

  @override
  Widget build(BuildContext context) {
    final set = this.set;
    final bar = set?.bar ?? _empty;
    final done = set?.done ?? false;
    // Its top and bottom edges run parallel to the map's slanted bottom and
    // the hero's slanted top, so both gutters are even.
    return SizedBox(
      height: TodayBoxLayout.height,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: TodayBoxLayout.maxTextScale,
        child: MangaPanel(
          shape: const PanelShape(
            topLeft: Offset(0, HomeLayout.mapCut),
            bottomRight: Offset(0, HomeLayout.journeyHeroCut),
          ),
          padding: HomeLayout.progressPadding + const EdgeInsets.only(top: HomeLayout.mapCut, bottom: HomeLayout.journeyHeroCut),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: TodayBoxLayout.headerHeight, child: _Header(total: bar.total, week: week)),
                  const SizedBox(height: TodayBoxLayout.sectionGap),
                  SizedBox(
                    height: TodayBoxLayout.barHeight,
                    child: _Bar(done
                        ? [(Palette.land, 1)]
                        : [
                            (Palette.land, bar.done),
                            (Palette.paper, bar.reviews - bar.reviewsDone),
                            (Palette.sun, bar.fresh - bar.freshDone),
                            (Palette.pink, bar.extra - bar.extraDone),
                          ]),
                  ),
                  const SizedBox(height: TodayBoxLayout.sectionGap),
                  SizedBox(height: TodayBoxLayout.legendHeight, child: _Legend(set: set)),
                ],
              ),
              if (done)
                const Positioned(
                  left: 0,
                  right: 0,
                  top: TodayBoxLayout.doneStampCenter,
                  child: FractionalTranslation(translation: Offset(0, -0.5), child: Center(child: _DoneStamp())),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [text]'s width in [style] here, at the font scale in use unless [scaler]
/// says otherwise.
double _widthOf(BuildContext context, String text, TextStyle style, {TextScaler? scaler}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
    textDirection: Directionality.of(context),
    textScaler: scaler ?? MediaQuery.textScalerOf(context),
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// "Today: 41 cards in one run" and the week stamps. The big number keeps
/// its size at any font scale; when the line is too wide, its two labels
/// shrink first, then the whole line.
class _Header extends StatelessWidget {
  const _Header({required this.total, required this.week});

  final int total;
  final List<WeekStamp> week;

  static const _label = TextStyle(
    fontWeight: Weights.black,
    fontSize: TodayBoxLayout.labelFont,
    height: TodayBoxLayout.labelLineHeight,
  );
  static const _number = TextStyle(
    fontFamily: Fonts.display,
    fontSize: TodayBoxLayout.number,
    height: TodayBoxLayout.numberLineHeight,
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final labels = _widthOf(context, s.todayLabel, _label) + _widthOf(context, s.todayCardsInRun, _label);
            final room = box.maxWidth -
                _widthOf(context, '$total', _number, scaler: TextScaler.noScaling) -
                TodayBoxLayout.todayGap -
                TodayBoxLayout.headerGap;
            final scale = (room / labels).clamp(TodayBoxLayout.minLabelScale, 1.0);
            final label = _label.copyWith(fontSize: TodayBoxLayout.labelFont * scale);
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.todayLabel, maxLines: 1, style: label),
                  const SizedBox(width: TodayBoxLayout.todayGap),
                  Text('$total', maxLines: 1, style: _number, textScaler: TextScaler.noScaling),
                  const SizedBox(width: TodayBoxLayout.headerGap),
                  Text(s.todayCardsInRun, style: label),
                ],
              ),
            );
          }),
        ),
        const SizedBox(width: TodayBoxLayout.headerGap),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openPracticeCalendar(context),
          child: _WeekStamps(week),
        ),
      ],
    );
  }
}

class _WeekStamps extends StatelessWidget {
  const _WeekStamps(this.week);
  final List<WeekStamp> week;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, day) in week.indexed) ...[
          if (i > 0) const SizedBox(width: TodayBoxLayout.stampGap),
          SizedBox(
            width: TodayBoxLayout.stamp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DayStamp(day),
                const SizedBox(height: TodayBoxLayout.weekdayGap),
                SizedBox(
                  height: TodayBoxLayout.weekdayHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s.weekdayLetter(day.date.weekday),
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: Weights.black,
                        fontSize: TodayBoxLayout.weekdayFont,
                        height: 1,
                        color: day.today ? Palette.pinkDeep : Palette.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A day's circle: checked when its set was done, dashed when it passed
/// without, ringed in sun and ink when it is today.
class _DayStamp extends StatelessWidget {
  const _DayStamp(this.day);
  final WeekStamp day;

  @override
  Widget build(BuildContext context) {
    const size = TodayBoxLayout.stamp;
    if (day.missed) {
      return const DashedBox(
        border: size * TodayBoxLayout.missedBorder,
        dash: Strokes.fineDash,
        radius: size / 2,
        child: SizedBox.square(dimension: size),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: day.done ? Palette.pink : Palette.paper,
        border: Border.all(color: Palette.ink, width: size * TodayBoxLayout.stampBorder),
        boxShadow: day.today
            ? const [
                BoxShadow(color: Palette.ink, spreadRadius: size * TodayBoxLayout.todayRingOuter),
                BoxShadow(color: Palette.sun, spreadRadius: size * TodayBoxLayout.todayRing),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: day.done
          ? MangaIcon(
              IconArt.check,
              size: TodayBoxLayout.check,
              color: Palette.paper,
              strokeWidth: TodayBoxLayout.checkStroke,
            )
          : null,
    );
  }
}

/// The bar: [parts] (a colour and its looks) side by side in proportion,
/// split by hairlines; an empty part is left out.
class _Bar extends StatelessWidget {
  const _Bar(this.parts);
  final List<(Color, int)> parts;

  /// Widths for [units] in [space], none under [TodayBoxLayout.minSegment]:
  /// parts that would be narrower get the minimum, the rest share what is
  /// left in proportion.
  static List<double> _widths(List<int> units, double space) {
    const min = TodayBoxLayout.minSegment;
    final pinned = <int>{};
    while (true) {
      final free = space - pinned.length * min;
      final rest = [for (final (i, u) in units.indexed) if (!pinned.contains(i)) u].fold(0, (a, b) => a + b);
      final under = [
        for (final (i, u) in units.indexed)
          if (!pinned.contains(i) && free * u / rest < min) i,
      ];
      if (under.isEmpty) {
        return [for (final (i, u) in units.indexed) pinned.contains(i) ? min : free * u / rest];
      }
      pinned.addAll(under);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = [for (final p in parts) if (p.$2 > 0) p];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.paper,
        border: Border.all(color: Palette.ink, width: TodayBoxLayout.barBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TodayBoxLayout.barBorder),
        child: LayoutBuilder(builder: (context, box) {
          final widths = _widths(
            [for (final p in shown) p.$2],
            box.maxWidth - TodayBoxLayout.barSeparator * math.max(0, shown.length - 1),
          );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, p) in shown.indexed) ...[
                if (i > 0) const ColoredBox(color: Palette.ink, child: SizedBox(width: TodayBoxLayout.barSeparator)),
                SizedBox(width: widths[i], child: ColoredBox(color: p.$1)),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// What the bar's colours stand for, with their looks, in two aligned
/// columns: reviews and new cards, then misses and the looks done. All four
/// labels share one size, the largest at which each fits its column.
class _Legend extends StatelessWidget {
  const _Legend({required this.set});

  final TodaySet? set;

  static const _label = TextStyle(fontWeight: Weights.bold, fontSize: TodayBoxLayout.legendFont, height: 1);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final set = this.set;
    final reviews = set?.reviews ?? 0;
    final fresh = set?.newCards ?? 0;
    final paused = set?.newPaused ?? false;
    final cells = [
      reviews == 0
          ? _Cell(Palette.paper, s.todayNoReviews, muted: true)
          : _Cell(Palette.paper, s.todayReviews(reviews, TodaySetTuning.reviewLooks)),
      fresh > 0
          ? _Cell(Palette.sun, s.todayNew(fresh, TodaySetTuning.newLooks))
          : _Cell(Palette.sun, paused ? s.todayNewPaused : s.todayNoNew, muted: true, hatched: paused),
      _Cell(Palette.pink, s.todayMisses),
      _Cell(Palette.land, s.todayDone),
    ];
    return LayoutBuilder(builder: (context, box) {
      final column = (box.maxWidth - TodayBoxLayout.legendColumnGap) / 2;
      final room = column - TodayBoxLayout.swatch - TodayBoxLayout.swatchGap;
      var scale = 1.0;
      for (final c in cells) {
        scale = math.min(scale, room / _widthOf(context, c.label, _label));
      }
      final label = _label.copyWith(fontSize: TodayBoxLayout.legendFont * scale.clamp(TodayBoxLayout.minLabelScale, 1.0));
      Widget row(_Cell a, _Cell b) => SizedBox(
            height: TodayBoxLayout.legendRow,
            child: Row(children: [
              Expanded(child: a.withLabel(label)),
              const SizedBox(width: TodayBoxLayout.legendColumnGap),
              Expanded(child: b.withLabel(label)),
            ]),
          );
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [row(cells[0], cells[1]), row(cells[2], cells[3])],
      );
    });
  }
}

/// A legend cell: its swatch and its label.
class _Cell extends StatelessWidget {
  const _Cell(this.color, this.label, {this.muted = false, this.hatched = false, this.labelStyle});

  final Color color;
  final String label;
  final bool muted, hatched;
  final TextStyle? labelStyle;

  _Cell withLabel(TextStyle style) => _Cell(color, label, muted: muted, hatched: hatched, labelStyle: style);

  @override
  Widget build(BuildContext context) {
    final style = labelStyle ?? _Legend._label;
    return Row(
      children: [
        _Swatch(color, hatched: hatched),
        const SizedBox(width: TodayBoxLayout.swatchGap),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: style.copyWith(color: muted ? TodayBoxLayout.pausedText : Palette.ink),
            ),
          ),
        ),
      ],
    );
  }
}

/// A legend swatch; [hatched] stripes it with paper, for paused new cards.
class _Swatch extends StatelessWidget {
  const _Swatch(this.color, {this.hatched = false});

  final Color color;
  final bool hatched;

  @override
  Widget build(BuildContext context) {
    // One paper and one coloured stripe per period, across the diagonal; in
    // the gradient's units, where the swatch is 2 wide.
    const period = 2 * TodayBoxLayout.hatch / math.sqrt2 / (TodayBoxLayout.swatch / 2);
    return Container(
      width: TodayBoxLayout.swatch,
      height: TodayBoxLayout.swatch,
      decoration: BoxDecoration(
        color: hatched ? null : color,
        gradient: hatched
            ? LinearGradient(
                begin: Alignment.bottomLeft,
                end: const Alignment(-1 + period, 1 - period),
                colors: [Palette.paper, Palette.paper, color, color],
                stops: const [0, 0.5, 0.5, 1],
                tileMode: TileMode.repeated,
              )
            : null,
        border: Border.all(color: Palette.ink, width: TodayBoxLayout.swatchBorder),
      ),
    );
  }
}

/// The 本日完了 hanko: pink-deep lettering on paper, in a border with a thin
/// paper and pink-deep rule inside it.
class _DoneStamp extends StatelessWidget {
  const _DoneStamp();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const rules = TodayBoxLayout.doneStampRule + TodayBoxLayout.doneStampInnerRule;
    return Transform.rotate(
      angle: TodayBoxLayout.doneStampTurn * math.pi / 180,
      child: Container(
        decoration: BoxDecoration(
          color: Palette.paper.withValues(alpha: TodayBoxLayout.doneStampPaper),
          border: Border.all(color: Palette.pinkDeep, width: TodayBoxLayout.doneStampBorder),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Palette.paper.withValues(alpha: TodayBoxLayout.doneStampRuleOpacity),
              width: TodayBoxLayout.doneStampRule,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Palette.pinkDeep, width: TodayBoxLayout.doneStampInnerRule),
            ),
            padding: TodayBoxLayout.doneStampPadding - const EdgeInsets.all(rules),
            child: Text(
              s.dayDoneStamp,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: Fonts.display,
                fontSize: TodayBoxLayout.doneStampFont,
                letterSpacing: TodayBoxLayout.doneStampTracking * TodayBoxLayout.doneStampFont,
                color: Palette.pinkDeep,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
