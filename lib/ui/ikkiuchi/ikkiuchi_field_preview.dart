import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../side_trips/field_preview.dart';

/// A field of [perSide] cards a side in [rows] rows as a match deals it,
/// face down on the match's tatami: each side in the usual shape of its
/// rows ([IkkiuchiLayout.usualShape]), Tobi's over a band and the player's
/// under it, their groups at the field's edges, every card as big as the
/// box allows up to [IkkiuchiPageLayout.previewMaxCardW], in the side
/// trips' preview frame ([FieldPreview]). It fills the room it is given
/// inside [IkkiuchiPageLayout.previewMargin], and asks for at least
/// [IkkiuchiPageLayout.previewMinHeight].
class IkkiuchiFieldPreview extends StatelessWidget {
  const IkkiuchiFieldPreview(this.perSide, {super.key, required this.rows});

  final int perSide, rows;

  static const _spec = FieldPreviewSpec(
    margin: IkkiuchiPageLayout.previewMargin,
    minHeight: IkkiuchiPageLayout.previewMinHeight,
    keepsMinHeight: true,
    ground: IkkiuchiPageLayout.previewGround,
    tatami: IkkiuchiBoardStyle.tatami,
    tatamiScale: IkkiuchiBoardStyle.tatamiScale,
    border: IkkiuchiPageLayout.previewBorder,
    padding: IkkiuchiPageLayout.previewPadding,
    band: IkkiuchiPageLayout.previewBand,
    bandColor: IkkiuchiPageLayout.previewBandColor,
    bandRule: IkkiuchiPageLayout.previewBandRule,
    backFill: IkkiuchiPageLayout.previewBack,
    backBorder: IkkiuchiPageLayout.previewBackBorder,
    backBorderWidth: IkkiuchiPageLayout.previewBackBorderWidth,
  );

  @override
  Widget build(BuildContext context) {
    var next = 0;
    final side = [
      for (final row in IkkiuchiLayout.usualShape(perSide, rows))
        IkkiuchiRow([for (var i = 0; i < row.left; i++) next++], [for (var i = 0; i < row.right; i++) next++]),
    ];
    final field = IkkiuchiField(tobi: side, player: side);
    return FieldPreview(
      spec: _spec,
      semanticLabel: S.of(context).ikkiuchiPreviewLabel(perSide),
      layOut: (area) => _laidOut(field, area),
    );
  }

  /// The band and every card of [field] in [area], the field spanning it.
  static FieldPreviewLayout _laidOut(IkkiuchiField field, Rect area) {
    const band = IkkiuchiPageLayout.previewBand;
    const bandGap = IkkiuchiPageLayout.previewBandGap;
    final half = field.halfHeight;
    final scale = [
      area.width / field.leastWidth(),
      (area.height - band - 2 * bandGap) / (2 * half),
      IkkiuchiPageLayout.previewMaxCardW,
    ].reduce(math.min);
    final gap = (band + 2 * bandGap) / scale;
    final top = area.top + (area.height - (2 * half + gap) * scale) / 2;
    return (
      bandTop: top + half * scale + bandGap,
      cards: [
        for (final card in field.layOut(area.width / scale, gap: gap))
          Rect.fromCenter(
            center: Offset(area.left + card.box.centre.x * scale, top + card.box.centre.y * scale),
            width: 2 * card.box.hw * scale,
            height: 2 * card.box.hh * scale,
          ),
      ],
    );
  }
}
