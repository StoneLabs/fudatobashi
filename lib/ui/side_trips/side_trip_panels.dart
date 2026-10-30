import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../manga/manga.dart';
import '../shell/tab_chains.dart';
import 'side_trip_entry.dart';

/// [text] in black type, then [sub] (the other language's) in small tracked
/// capitals, each breaking only between words.
class PanelLabel extends StatelessWidget {
  const PanelLabel(this.text, this.sub, {super.key, this.fontSize = AnkirenPageLayout.labelFont, this.color = Palette.ink});

  final String text;
  final String? sub;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          Phrases.span(text),
          if (sub != null) ...[
            const TextSpan(text: ' '),
            Phrases.span(
              sub!.toUpperCase(),
              style: const TextStyle(
                fontSize: AnkirenPageLayout.labelFont,
                letterSpacing: AnkirenPageLayout.labelTracking * AnkirenPageLayout.labelFont,
              ),
            ),
          ],
        ]),
        style: TextStyle(
          fontWeight: Weights.black,
          fontSize: fontSize,
          height: AnkirenPageLayout.labelLineHeight,
          color: color,
        ),
      );
}

/// Cells side by side, split by ink rules (none after the first unless
/// [firstRuled], for a boxed first cell): each as wide as it is on one
/// line, the room left shared out evenly when the row [fills] its width,
/// and all as tall as the tallest. When the row is too narrow for
/// that, the cells give up width in proportion to what they can spare
/// before a word would break, and past that all narrow in proportion.
class CellRow extends MultiChildRenderObjectWidget {
  const CellRow({super.key, required super.children, this.firstRuled = true, this.fills = false});

  final bool firstRuled, fills;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderCellRow(firstRuled, fills);

  @override
  void updateRenderObject(BuildContext context, RenderCellRow renderObject) => renderObject
    ..firstRuled = firstRuled
    ..fills = fills;
}

class CellRowParentData extends ContainerBoxParentData<RenderBox> {}

class RenderCellRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, CellRowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, CellRowParentData> {
  RenderCellRow(this._firstRuled, this._fills);

  bool _firstRuled;
  set firstRuled(bool value) {
    if (value == _firstRuled) return;
    _firstRuled = value;
    markNeedsLayout();
  }

  bool _fills;
  set fills(bool value) {
    if (value == _fills) return;
    _fills = value;
    markNeedsLayout();
  }

  /// The room between two cells, the rule in its middle.
  static const _between = 2 * AnkirenPageLayout.cellGap + Strokes.control;

  /// Where each rule starts, from the last layout.
  List<double> _rules = const [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! CellRowParentData) child.parentData = CellRowParentData();
  }

  double get _gaps => _between * math.max(0, childCount - 1);

  /// Each cell's width in a row [width] wide.
  List<double> _widths(double width) {
    final cells = getChildrenAsList();
    final natural = [for (final cell in cells) cell.getMaxIntrinsicWidth(double.infinity)];
    final total = natural.fold(0.0, (sum, w) => sum + w);
    final room = math.max(0.0, width - _gaps);
    if (total <= room) {
      if (!_fills || !room.isFinite) return natural;
      return [for (final w in natural) w + (room - total) / natural.length];
    }
    final least = [
      for (final (i, cell) in cells.indexed) math.min(natural[i], cell.getMinIntrinsicWidth(double.infinity)),
    ];
    final slack = total - least.fold(0.0, (sum, w) => sum + w);
    final over = total - room;
    if (over <= slack) return [for (final (i, w) in natural.indexed) w - (w - least[i]) * over / slack];
    return [for (final w in natural) w * room / total];
  }

  double _tallest(double width, double Function(RenderBox cell, double width) heightOf) {
    final widths = _widths(width);
    return [for (final (i, cell) in getChildrenAsList().indexed) heightOf(cell, widths[i])].fold(0.0, math.max);
  }

  double _dryHeight(RenderBox cell, double width) => cell.getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _gaps + getChildrenAsList().fold(0.0, (sum, cell) => sum + cell.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _gaps + getChildrenAsList().fold(0.0, (sum, cell) => sum + cell.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) => _tallest(width, (cell, w) => cell.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) => _tallest(width, (cell, w) => cell.getMaxIntrinsicHeight(w));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final widths = _widths(constraints.maxWidth);
    final width = _gaps + widths.fold(0.0, (sum, w) => sum + w);
    return constraints.constrain(Size(width, _tallest(constraints.maxWidth, _dryHeight)));
  }

  @override
  void performLayout() {
    final widths = _widths(constraints.maxWidth);
    final height = _tallest(constraints.maxWidth, _dryHeight);
    final rules = <double>[];
    var x = 0.0;
    for (final (i, cell) in getChildrenAsList().indexed) {
      if (i > 0) {
        if (i > 1 || _firstRuled) rules.add(x + AnkirenPageLayout.cellGap);
        x += _between;
      }
      cell.layout(BoxConstraints(maxWidth: widths[i], minHeight: height, maxHeight: height));
      (cell.parentData! as CellRowParentData).offset = Offset(x, 0);
      x += widths[i];
    }
    _rules = rules;
    size = constraints.constrain(Size(x, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
    final ink = Paint()..color = Palette.ink;
    for (final left in _rules) {
      context.canvas.drawRect(Rect.fromLTWH(offset.dx + left, offset.dy, Strokes.control, size.height), ink);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A label over its value, the value on one line, shrinking rather than
/// overflowing; [inset] from the top and bottom.
class StatCell extends StatelessWidget {
  const StatCell({super.key, required this.label, required this.value, this.inset = 0});

  final Widget label, value;
  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: inset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            label,
            const SizedBox(height: AnkirenPageLayout.labelGap),
            _Shrinks(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: DefaultTextStyle.merge(softWrap: false, child: value),
              ),
            ),
          ],
        ),
      );
}

/// [child], which scales down to any width, so it sets no narrowest width
/// for its cell: there only the label's words count.
class _Shrinks extends SingleChildRenderObjectWidget {
  const _Shrinks({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderShrinks();
}

class _RenderShrinks extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;
}

/// A panel with the side trips' cut corner and [tag] on an ink banner over
/// its top edge, [heading] at the right beside the tag (or under it when
/// there is no room beside it), then [child]. With a [cover], the inside is
/// faded under it.
class TaggedPanel extends StatelessWidget {
  const TaggedPanel({super.key, required this.tag, required this.sub, this.heading, required this.child, this.cover});

  final String tag;
  final String? sub;
  final Widget? heading;
  final Widget child;
  final Widget? cover;

  @override
  Widget build(BuildContext context) {
    final banner = FittedBox(fit: BoxFit.scaleDown, child: InkBanner(tag, sub: sub));
    const head = AnkirenPageLayout.headPadding;
    final inside = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: head,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AnkirenPageLayout.headGap,
          runSpacing: AnkirenPageLayout.headGap,
          children: [
            Overhang(rise: AnkirenPageLayout.tagRise + head.top, child: ExcludeSemantics(child: banner)),
            ?heading,
          ],
        ),
      ),
      Flexible(child: child),
    ]);
    return Stack(clipBehavior: Clip.none, children: [
      Padding(
        padding: const EdgeInsets.only(top: AnkirenPageLayout.tagRise),
        child: MangaPanel(
          shape: const PanelShape(topLeft: Offset(0, SideTripsLayout.cut)),
          child: cover == null
              ? inside
              : Stack(children: [
                  IgnorePointer(child: Opacity(opacity: AnkirenPageLayout.lockedOpacity, child: inside)),
                  Positioned.fill(child: cover!),
                ]),
        ),
      ),
      Positioned(
        left: head.left,
        right: head.right,
        top: 0,
        child: Align(alignment: Alignment.centerLeft, child: Semantics(header: true, child: banner)),
      ),
    ]);
  }
}

/// A [TaggedPanel] that is still shut: chained up, its inside faded, with
/// [why] on a paper sticker over the chains; a tap says it again.
class LockedPanel extends StatelessWidget {
  const LockedPanel({super.key, required this.tag, required this.sub, this.heading, required this.why, required this.child});

  final String tag;
  final String? sub;
  final Widget? heading;
  final String why;
  final Widget child;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => BalloonPop.show(context, why,
            size: AnkirenPageLayout.lockBalloon, life: AnkirenPageLayout.lockBalloonLife),
        scale: 1,
        turn: 0,
        semanticLabel: '$tag: $why',
        builder: (context, _) => ExcludeSemantics(
          child: TaggedPanel(
            tag: tag,
            sub: sub,
            heading: heading,
            cover: Stack(children: [
              const Positioned.fill(child: ClipRect(child: TabChains(scale: AnkirenPageLayout.chainScale))),
              Positioned(
                left: AnkirenPageLayout.lockNoteInset,
                right: AnkirenPageLayout.lockNoteInset,
                bottom: AnkirenPageLayout.lockNoteBottom,
                child: Center(
                  child: Sticker(
                    color: Palette.paper,
                    tilt: AnkirenPageLayout.lockNoteTilt,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      MangaIcon(IconArt.lock,
                          size: AnkirenPageLayout.hintIcon, strokeWidth: AnkirenPageLayout.hintIconStroke),
                      const SizedBox(width: AnkirenPageLayout.hintGap),
                      Flexible(
                        child: Text.rich(Phrases.span(why),
                            style: const TextStyle(fontWeight: Weights.black, fontSize: AnkirenPageLayout.lockNoteFont)),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
            child: child,
          ),
        ),
      );
}

/// A ranked panel's bottom row: its one setup's [facts] over a [line] about
/// it, beside the ranked burst, which shrinks into the rest of the row and
/// is grey without an [onTap].
class RankedRow extends StatelessWidget {
  const RankedRow({super.key, required this.facts, required this.line, required this.onTap});

  final String facts, line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: AnkirenPageLayout.rankedRowPadding,
        child: Row(children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AnkirenPageLayout.factsMaxWidth),
            child: Text.rich(
              TextSpan(children: [
                Phrases.span(facts, style: const TextStyle(fontWeight: Weights.black, color: Palette.ink)),
                const TextSpan(text: '\n'),
                Phrases.span(line),
              ]),
              maxLines: AnkirenPageLayout.factsLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: Weights.bold, fontSize: AnkirenPageLayout.hintFont, color: Palette.mute),
            ),
          ),
          const SizedBox(width: AnkirenPageLayout.rankedRowGap),
          Expanded(
            child: SizedBox(height: AnkirenPageLayout.rankedBurst, child: RankedBurst(onTap: onTap)),
          ),
        ]),
      );
}

/// A [label] over its [value] in a boxed button with a drop mark after the
/// value, a full touch target tall, that calls [onTap].
class DropCellButton extends StatelessWidget {
  const DropCellButton(
      {super.key, required this.label, required this.value, required this.semanticLabel, required this.onTap});

  final Widget label, value;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AnkirenPageLayout.levelButtonHeight),
        child: InkButton(
          onTap: onTap,
          border: Strokes.control,
          padding: const EdgeInsets.symmetric(
              horizontal: AnkirenPageLayout.levelButtonPadding, vertical: AnkirenPageLayout.levelButtonInset),
          alignment: Alignment.centerLeft,
          semanticLabel: semanticLabel,
          child: StatCell(
            label: label,
            value: Row(mainAxisSize: MainAxisSize.min, children: [
              value,
              const SizedBox(width: AnkirenPageLayout.levelMarkGap),
              const Text(
                AnkirenPageLayout.levelMark,
                style: TextStyle(fontSize: AnkirenPageLayout.levelMarkFont, height: 1, color: Palette.ink),
              ),
            ]),
          ),
        ),
      );
}

