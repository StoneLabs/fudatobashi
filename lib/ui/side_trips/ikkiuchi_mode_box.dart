import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_mode.dart';
import '../../domain/ikkiuchi_rating.dart';
import '../../domain/ikkiuchi_record.dart';
import '../../domain/ikkiuchi_review.dart';
import '../../domain/rating.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/results_strings.dart';
import '../../l10n/side_trip_strings.dart';
import '../../l10n/strings.dart';
import '../../state/ikkiuchi_records.dart';
import '../home/home_widgets.dart';
import '../ikkiuchi/ikkiuchi_field_picture.dart';
import '../ikkiuchi/ikkiuchi_match_screen.dart';
import '../ikkiuchi/ikkiuchi_tobi_tag.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import 'burst_button.dart';
import 'ikkiuchi_rating_curve.dart';
import 'side_trip_entry.dart';
import 'side_trip_panels.dart';

/// [mode]'s colours on 一騎打ち's page.
IkkiuchiModeTone ikkiuchiModeTone(IkkiuchiMode mode) => switch (mode) {
      IkkiuchiMode.bullet => IkkiuchiPageLayout.bullet,
      IkkiuchiMode.blitz => IkkiuchiPageLayout.blitz,
      IkkiuchiMode.rapid => IkkiuchiPageLayout.rapid,
    };

/// The ranked modes' tabs over the [chosen] mode's box, [child]: the
/// chosen tab stands higher, in its mode's halftone, and opens into the box
/// as one ink outline; the others stand lower in their mode's tint, behind
/// the box's top line. A tab tapped calls [onPick] with its mode.
class IkkiuchiModeTabs extends StatelessWidget {
  const IkkiuchiModeTabs({super.key, required this.chosen, required this.onPick, required this.child});

  final IkkiuchiMode chosen;
  final ValueChanged<IkkiuchiMode> onPick;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _FramePainter(chosen.index, MediaQuery.devicePixelRatioOf(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: IkkiuchiPageLayout.tabHeight,
              child: Row(children: [
                for (final (i, mode) in IkkiuchiMode.values.indexed) ...[
                  if (i > 0) const SizedBox(width: IkkiuchiPageLayout.tabGap),
                  Expanded(child: _Tab(mode, chosen: mode == chosen, onTap: () => onPick(mode))),
                ],
              ]),
            ),
            child,
          ],
        ),
      );
}

/// A mode's tab: its name over its cards a side, big and in ink when
/// [chosen], smaller and greyed otherwise.
class _Tab extends StatelessWidget {
  const _Tab(this.mode, {required this.chosen, required this.onTap});

  final IkkiuchiMode mode;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = s.ikkiuchiModeName(mode);
    final cards = s.ikkiuchiTabPerSide(mode.perSide);
    final size = switch ((chosen, s.ja)) {
      (true, true) => IkkiuchiPageLayout.tabName,
      (false, true) => IkkiuchiPageLayout.quietTabName,
      (true, false) => IkkiuchiPageLayout.tabNameLatin,
      (false, false) => IkkiuchiPageLayout.quietTabNameLatin,
    };
    return Semantics(
      selected: chosen,
      child: Pressable(
        onTap: onTap,
        drop: 0,
        scale: 1,
        turn: 0,
        semanticLabel: '$name $cards',
        builder: (context, _) => ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.only(top: chosen ? IkkiuchiPageLayout.tabTop : IkkiuchiPageLayout.quietTabTop),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(name,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: Fonts.display,
                        fontSize: size,
                        height: 1,
                        letterSpacing: s.ja ? 0 : IkkiuchiPageLayout.tabNameLatinTracking,
                        color: chosen ? Palette.ink : IkkiuchiPageLayout.quietName,
                      )),
                  const SizedBox(height: IkkiuchiPageLayout.tabSubGap),
                  Text(cards,
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: chosen ? Weights.black : Weights.bold,
                        fontSize: IkkiuchiPageLayout.tabSub,
                        height: 1,
                        letterSpacing: IkkiuchiPageLayout.tabSubTracking,
                        color: chosen ? Palette.ink : IkkiuchiPageLayout.quietSub,
                      )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tabs' and the box's ink. The tabs' tops lie on one line falling
/// toward the left; the quiet tabs stand [IkkiuchiPageLayout.tabDrop] under
/// it, tinted, down to the box's top. The chosen tab and the box are one
/// outline on paper, the tab filled with its mode's tone.
class _FramePainter extends CustomPainter {
  _FramePainter(this.chosen, this.pixelRatio);

  final int chosen;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    const edge = IkkiuchiPageLayout.frameStroke / 2;
    const top = IkkiuchiPageLayout.tabHeight;
    const drop = IkkiuchiPageLayout.tabDrop;
    final w = size.width, h = size.height;
    const tabs = IkkiuchiMode.values;
    final tabW = (w - (tabs.length - 1) * IkkiuchiPageLayout.tabGap) / tabs.length;
    double lineAt(double x) => IkkiuchiPageLayout.tabSlant * (1 - x / w) + edge;
    Path shape(List<Offset> corners) => Path()..addPolygon(corners, true);
    final quietInk = Paint()
      ..color = Palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = IkkiuchiPageLayout.quietStroke
      ..strokeJoin = StrokeJoin.miter;
    late double x0, x1;
    for (final (i, mode) in tabs.indexed) {
      final left = i * (tabW + IkkiuchiPageLayout.tabGap), right = left + tabW;
      if (i == chosen) {
        (x0, x1) = (left, right);
        continue;
      }
      final tab = shape([
        Offset(left + edge, top),
        Offset(left + edge, lineAt(left) + drop),
        Offset(right - edge, lineAt(right) + drop),
        Offset(right - edge, top),
      ]);
      canvas
        ..drawPath(tab, Paint()..color = ikkiuchiModeTone(mode).tint)
        ..drawPath(tab, quietInk);
    }
    final tabTop = [Offset(x0 + edge, lineAt(x0)), Offset(x1 - edge, lineAt(x1))];
    final outline = shape([
      const Offset(edge, top + edge),
      Offset(x0 + edge, top + edge),
      ...tabTop,
      Offset(x1 - edge, top + edge),
      Offset(w - edge, top + edge),
      Offset(w - edge, h - edge),
      Offset(edge, h - edge),
    ]);
    canvas
      ..drawPath(outline, Paint()..color = Palette.paper)
      ..drawPath(shape([...tabTop, Offset(x1 - edge, top + edge), Offset(x0 + edge, top + edge)]),
          Screentone.paint(ikkiuchiModeTone(tabs[chosen]).tone, pixelRatio))
      ..drawPath(
          outline,
          Paint()
            ..color = Palette.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = IkkiuchiPageLayout.frameStroke
            ..strokeJoin = StrokeJoin.miter);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.chosen != chosen || old.pixelRatio != pixelRatio;
}

/// A ranked mode's box: the player's standing in it ([records]), the curve
/// of their rating (while placing, a note in its room), then the mode's
/// match, each side laid out in [rows], and the burst that starts it
/// against Tobi at the rating it shows.
class IkkiuchiRankedBox extends StatelessWidget {
  const IkkiuchiRankedBox(this.records, {super.key, required this.rows});

  final IkkiuchiModeRecords records;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mode = records.mode;
    final tone = ikkiuchiModeTone(mode);
    final setup = records.rankedSetup(rows: rows);
    final tobi = setup.opponentRating.round();
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: IkkiuchiPageLayout.standPadding,
        child: Row(children: [
          _Badge(records.band, tone: tone.tone),
          const SizedBox(width: IkkiuchiPageLayout.standGap),
          Expanded(child: records.placing ? _Placement(records) : _Standing(records, tone: tone)),
        ]),
      ),
      Padding(
        padding: IkkiuchiPageLayout.curveMargin,
        child: records.placing ? const IkkiuchiCurveNote() : IkkiuchiRatingCurve(records.curve, tone: tone),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: IkkiuchiPageLayout.splitInset),
        child: SizedBox(
          height: IkkiuchiPageLayout.splitHeight,
          child: ColoredBox(color: IkkiuchiPageLayout.lightRule),
        ),
      ),
      Padding(padding: IkkiuchiPageLayout.factsPadding, child: _Match(mode, rows: rows)),
      Padding(
        padding: IkkiuchiPageLayout.burstMargin,
        child: BurstButton(
          title: s.sideTripRanked,
          tag: IkkiuchiTobiTag(tobi),
          semanticLabel: '${s.ikkiuchiModeRanked(mode)} ${s.ikkiuchiTobi} $tobi',
          onTap: () => startIkkiuchiMatch(context, setup),
        ),
      ),
    ]);
  }
}

/// A small label in black type.
Widget _label(String text) => PanelLabel(text, null, fontSize: IkkiuchiPageLayout.labelFont);

/// The class badge in the mode's [tone]: the [band]'s name, the stem big
/// and 級 small after it; a question mark while there is no class yet.
class _Badge extends StatelessWidget {
  const _Badge(this.band, {required this.tone});

  final RankBand? band;
  final ToneSpec tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget name;
    if (band case final band?) {
      final stem = s.classStem(band);
      final long = stem.characters.length > 1;
      name = Text.rich(TextSpan(children: [
        TextSpan(text: stem),
        if (stem != s.className(band))
          TextSpan(
            text: RankBand.classSuffix,
            style: TextStyle(
                fontSize: long ? IkkiuchiPageLayout.longClassSuffixFont : IkkiuchiPageLayout.classSuffixFont),
          ),
      ]), style: TextStyle(fontSize: long ? IkkiuchiPageLayout.longClassFont : IkkiuchiPageLayout.classFont));
    } else {
      name = const Text(IkkiuchiPageLayout.unplaced, style: TextStyle(fontSize: IkkiuchiPageLayout.unplacedFont));
    }
    return SizedBox.square(
      dimension: IkkiuchiPageLayout.badge,
      child: Stack(fit: StackFit.expand, children: [
        ToneBox(tone),
        const DecoratedBox(
          decoration: BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: IkkiuchiPageLayout.badgeStroke)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: IkkiuchiPageLayout.badgeInset),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontFamily: Fonts.display, height: 1, color: Palette.ink),
                child: name,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// The rating with its last change, over the way to the next class and a
/// bar in the mode's colour; the bar's room stays empty in the top class.
class _Standing extends StatelessWidget {
  const _Standing(this.records, {required this.tone});

  final IkkiuchiModeRecords records;
  final IkkiuchiModeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rating = records.rating!;
    final change = records.ratingChange?.round();
    final progress = IkkiuchiReview.classProgress(rating);
    final next = progress.next;
    final up = (change ?? 0) > 0;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(s.rating),
      const SizedBox(height: IkkiuchiPageLayout.ratingTop),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${rating.round()}',
              style: const TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.ratingFont, height: 1)),
          if (change != null) ...[
            const SizedBox(width: IkkiuchiPageLayout.changeGap),
            RatingChangeTag(
              change,
              fontSize: IkkiuchiPageLayout.changeFont,
              // A rise's tag has no edge: as much more padding keeps both tags one size.
              padding: up
                  ? IkkiuchiPageLayout.changePadding + const EdgeInsets.all(IkkiuchiPageLayout.changeBorder)
                  : IkkiuchiPageLayout.changePadding,
              border: IkkiuchiPageLayout.changeBorder,
            ),
          ],
        ]),
      ),
      const SizedBox(height: IkkiuchiPageLayout.gaugeTop),
      SizedBox(
        height: IkkiuchiPageLayout.gaugeHeight,
        child: next == null
            ? null
            : LayoutBuilder(
                builder: (context, box) => Row(children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth * IkkiuchiPageLayout.gaugeWordsShare),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: NumberedText(
                        s.ratingToNext(s.className(next)),
                        [(next.minRating - rating).ceil()],
                        style: const TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiPageLayout.gaugeFont),
                        numberStyle:
                            const TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.gaugeNumber),
                      ),
                    ),
                  ),
                  const SizedBox(width: IkkiuchiPageLayout.barGap),
                  Expanded(
                    child: RatingBar(
                      progress.fraction,
                      width: double.infinity,
                      color: tone.deep,
                      height: IkkiuchiPageLayout.barHeight,
                      border: IkkiuchiPageLayout.barBorder,
                    ),
                  ),
                ]),
              ),
      ),
    ]);
  }
}

/// While the player is being placed in the mode: its placement matches as
/// slots (those played won or lost, the next one marked, the rest dashed),
/// over what the ones left decide.
class _Placement extends StatelessWidget {
  const _Placement(this.records);

  final IkkiuchiModeRecords records;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final played = records.matches;
    final total = IkkiuchiRating.placementMatches;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(s.ikkiuchiPlacementTitle),
      const SizedBox(height: IkkiuchiPageLayout.slotsTop),
      Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: IkkiuchiPageLayout.slotGap),
          if (i < played.length)
            _Slot.played(won: played[i].result == IkkiuchiResult.won)
          else
            _Slot.coming(i + 1, next: i == played.length),
        ],
      ]),
      const SizedBox(height: IkkiuchiPageLayout.noteTop),
      SizedBox(
        height: IkkiuchiPageLayout.gaugeHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: NumberedText(
              s.ikkiuchiPlacingLine(records.mode, first: played.isEmpty),
              [total - played.length],
              style: const TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiPageLayout.gaugeFont),
              numberStyle: const TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.gaugeNumber),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// A placement match: played (勝 on ink, or 負), or still to come, its
/// number in an ink box for the [next] one and in a dashed one after it.
class _Slot extends StatelessWidget {
  const _Slot.played({required bool this.won})
      : number = null,
        next = false;

  const _Slot.coming(int this.number, {required this.next}) : won = null;

  final bool? won;
  final int? number;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const dimension = IkkiuchiPageLayout.slot;
    if (won case final won?) {
      return SizedBox.square(
        dimension: dimension,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: won ? Palette.ink : Palette.paper,
            border: Border.all(color: Palette.ink, width: IkkiuchiPageLayout.slotBorder),
          ),
          child: Center(
            child: Text(won ? s.ikkiuchiSlotWon : s.ikkiuchiSlotLost,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: IkkiuchiPageLayout.slotFont,
                    height: 1,
                    color: won ? Palette.paper : IkkiuchiPageLayout.lostInk)),
          ),
        ),
      );
    }
    final text = Text('$number',
        style: TextStyle(
            fontFamily: Fonts.display,
            fontSize: IkkiuchiPageLayout.slotFont,
            height: 1,
            color: next ? Palette.ink : IkkiuchiPageLayout.slotInk));
    return SizedBox.square(
      dimension: dimension,
      child: next
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: Palette.paper,
                border: Border.all(color: Palette.ink, width: IkkiuchiPageLayout.nextSlotBorder),
              ),
              child: Center(child: text),
            )
          : DashedBox(
              ink: IkkiuchiPageLayout.slotInk,
              border: IkkiuchiPageLayout.slotBorder,
              child: Center(child: text),
            ),
    );
  }
}

/// The mode's match: its field in [rows] rows, its cards a side and its
/// memory time, split by an ink rule.
class _Match extends StatelessWidget {
  const _Match(this.mode, {required this.rows});

  final IkkiuchiMode mode;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const big = TextStyle(fontFamily: Fonts.display, fontSize: IkkiuchiPageLayout.factFont, height: 1);
    return SizedBox(
      height: IkkiuchiPageLayout.field.height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox.fromSize(size: IkkiuchiPageLayout.field, child: IkkiuchiFieldPicture(mode.perSide, rows: rows)),
        const SizedBox(width: IkkiuchiPageLayout.fieldGap),
        Expanded(
          child: _Fact(
            s.ikkiuchiPerSide,
            NumberedText(
              s.ikkiuchiBoxPerSide,
              [mode.perSide],
              style: const TextStyle(fontWeight: Weights.black, fontSize: IkkiuchiPageLayout.factUnitFont, height: 1),
              numberStyle: big,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
              horizontal: IkkiuchiPageLayout.factRuleGap, vertical: IkkiuchiPageLayout.factRuleInset),
          child: SizedBox(width: IkkiuchiPageLayout.factRule, child: ColoredBox(color: Palette.ink)),
        ),
        Expanded(child: _Fact(s.ikkiuchiMemoryTime, Text(formatMinutes(mode.memorise), style: big))),
      ]),
    );
  }
}

/// A fact of the match: its [label] over its [value], each on one line,
/// shrinking rather than overflow, the value toward its foot, keeping its
/// room.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle.merge(softWrap: false, child: _label(label)),
          ),
          const SizedBox(height: IkkiuchiPageLayout.factGap),
          SizedBox(
            height: IkkiuchiPageLayout.factFont,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: DefaultTextStyle.merge(softWrap: false, child: value),
            ),
          ),
        ],
      );
}
