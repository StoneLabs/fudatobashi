import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';
import '../../domain/ankiren_level.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';

/// [level]'s field as it will lie, face down on the play screen's tatami:
/// its usual shape ([AnkirenDealer.typical]), the opponent's half over a
/// band and the own half under it, folded and opened up to span the box
/// like the portrait play screen's, every card as big as the box allows
/// up to [AnkirenPageLayout.previewMaxCardW]. It fills the room it is
/// given inside [AnkirenPageLayout.previewMargin], asks for none, and
/// shows nothing when that is less than
/// [AnkirenPageLayout.previewMinHeight].
class AnkirenFieldPreview extends StatelessWidget {
  const AnkirenFieldPreview(this.level, {super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    final of = AnkirenLevels.of(level);
    final field = AnkirenDealer.typical(of.perSide, allInMiddle: of.allInMiddle);
    return _NoIntrinsicSize(
      child: LayoutBuilder(builder: (context, box) {
        const margin = AnkirenPageLayout.previewMargin;
        final frame = margin.deflateSize(box.biggest);
        if (frame.height < AnkirenPageLayout.previewMinHeight) return const SizedBox.shrink();
        return Semantics(
          image: true,
          label: S.of(context).ankirenPreviewLabel(of.perSide),
          excludeSemantics: true,
          child: Padding(
            padding: margin,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AnkirenPageLayout.previewGround,
                image: const DecorationImage(
                  image: AssetImage(AnkirenPlayLayout.tatami),
                  repeat: ImageRepeat.repeat,
                  scale: AnkirenPlayLayout.tatamiScale,
                ),
                border: Border.all(color: Palette.ink, width: AnkirenPageLayout.previewBorder),
              ),
              child: Stack(children: _laidOut(field, frame)),
            ),
          ),
        );
      }),
    );
  }

  /// The band and every card of [field] in a [frame] of that size.
  static List<Widget> _laidOut(AnkirenField field, Size frame) {
    const band = AnkirenPageLayout.previewBand;
    const bandGap = AnkirenPageLayout.previewBandGap;
    final inside = (Offset.zero & frame).deflate(AnkirenPageLayout.previewBorder);
    final area = inside.deflate(AnkirenPageLayout.previewPadding);
    final natural = FieldGeometry.of(field, folded: true);
    final scale = [
      area.width / natural.width,
      (area.height - band - 2 * bandGap) / (2 * natural.height),
      AnkirenPageLayout.previewMaxCardW / AnkirenFieldSize.cardW,
    ].reduce(math.min);
    final g = natural.width * scale < area.width
        ? FieldGeometry.of(field, folded: true, minWidth: area.width / scale)
        : natural;
    final half = g.height * scale;
    final top = area.top + (area.height - 2 * half - band - 2 * bandGap) / 2;
    final left = area.left + (area.width - g.width * scale) / 2;
    final bandTop = top + half + bandGap;
    const rule = BorderSide(color: Palette.ink, width: AnkirenPageLayout.previewBandRule);
    const back = BorderSide(color: AnkirenPlayLayout.backBorder, width: AnkirenPlayLayout.backBorderWidth);
    return [
      Positioned(
        left: inside.left,
        top: bandTop,
        width: inside.width,
        height: band,
        child: const DecoratedBox(
          decoration: BoxDecoration(color: AnkirenPlayLayout.bandColor, border: Border(top: rule, bottom: rule)),
        ),
      ),
      for (final side in FieldSide.values)
        for (final MapEntry(value: r) in g.half(side).entries)
          Positioned(
            left: left + r.x * scale,
            top: (side == FieldSide.opponent ? top : bandTop + band + bandGap) + r.y * scale,
            width: r.w * scale,
            height: r.h * scale,
            child: const DecoratedBox(
              decoration: BoxDecoration(color: AnkirenPlayLayout.backFill, border: Border.fromBorderSide(back)),
            ),
          ),
    ];
  }
}

/// [child] as it lays out, but asking for no room when its intrinsic size
/// is measured, so a column that measures its children leaves it only the
/// room that is left over.
class _NoIntrinsicSize extends SingleChildRenderObjectWidget {
  const _NoIntrinsicSize({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNoIntrinsicSize();
}

class _RenderNoIntrinsicSize extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}
