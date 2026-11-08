import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/ankiren_geometry.dart';
import '../../domain/ankiren_level.dart';
import '../../l10n/ankiren_strings.dart';
import '../../l10n/strings.dart';
import '../side_trips/field_preview.dart';

/// [setup]'s field as it will lie, face down on the play screen's tatami:
/// its usual shape ([AnkirenDealer.typical]), the opponent's half over a
/// band and the own half under it, folded and opened up to span the box
/// like the portrait play screen's, every card as big as the box allows
/// up to [AnkirenPageLayout.previewMaxCardW], in the side trips' preview
/// frame ([FieldPreview]). It fills the room it is given inside
/// [AnkirenPageLayout.previewMargin], asks for none, and shows nothing
/// when that is less than [AnkirenPageLayout.previewMinHeight].
class AnkirenFieldPreview extends StatelessWidget {
  const AnkirenFieldPreview(this.setup, {super.key});

  final AnkirenSetup setup;

  static const _spec = FieldPreviewSpec(
    margin: AnkirenPageLayout.previewMargin,
    minHeight: AnkirenPageLayout.previewMinHeight,
    ground: AnkirenPageLayout.previewGround,
    tatami: AnkirenPlayLayout.tatami,
    tatamiScale: AnkirenPlayLayout.tatamiScale,
    border: AnkirenPageLayout.previewBorder,
    padding: AnkirenPageLayout.previewPadding,
    band: AnkirenPageLayout.previewBand,
    bandColor: AnkirenPlayLayout.bandColor,
    bandRule: AnkirenPageLayout.previewBandRule,
    backFill: AnkirenPlayLayout.backFill,
    backBorder: AnkirenPlayLayout.backBorder,
    backBorderWidth: AnkirenPlayLayout.backBorderWidth,
  );

  @override
  Widget build(BuildContext context) {
    final field = AnkirenDealer.typical(setup.perSide, allInMiddle: setup.allInMiddle);
    return FieldPreview(
      spec: _spec,
      semanticLabel: S.of(context).ankirenPreviewLabel(setup.perSide),
      layOut: (area) => _laidOut(field, area),
    );
  }

  /// The band and every card of [field] in [area].
  static FieldPreviewLayout _laidOut(AnkirenField field, Rect area) {
    const band = AnkirenPageLayout.previewBand;
    const bandGap = AnkirenPageLayout.previewBandGap;
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
    return (
      bandTop: bandTop,
      cards: [
        for (final side in FieldSide.values)
          for (final MapEntry(value: r) in g.half(side).entries)
            Rect.fromLTWH(
              left + r.x * scale,
              (side == FieldSide.opponent ? top : bandTop + band + bandGap) + r.y * scale,
              r.w * scale,
              r.h * scale,
            ),
      ],
    );
  }
}
