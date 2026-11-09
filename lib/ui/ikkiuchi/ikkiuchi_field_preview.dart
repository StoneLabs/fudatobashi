import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../domain/ikkiuchi_mode.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../side_trips/field_preview.dart';

/// A field of [perSide] cards a side in [rows] rows as a match deals it,
/// face down on the match's tatami: each side in the usual shape of its
/// rows ([IkkiuchiLayout.usualShape]), Tobi's over a band and the player's
/// under it, their groups at the field's edges, in the side trips' preview
/// frame ([FieldPreview]). It fills the box it is given, at the scale that
/// fits the fullest field there (the most cards a mode deals, in the most
/// rows), so a field of fewer rows or cards looks smaller.
class IkkiuchiFieldPreview extends StatelessWidget {
  const IkkiuchiFieldPreview(this.perSide, {super.key, required this.rows});

  final int perSide, rows;

  static const _spec = FieldPreviewSpec(
    margin: EdgeInsets.zero,
    minHeight: 0,
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

  /// Both sides of [perSide] cards in [rows] rows, the same shape.
  static IkkiuchiField _field(int perSide, int rows) {
    var next = 0;
    final side = [
      for (final row in IkkiuchiLayout.usualShape(perSide, rows))
        IkkiuchiRow([for (var i = 0; i < row.left; i++) next++], [for (var i = 0; i < row.right; i++) next++]),
    ];
    return IkkiuchiField(tobi: side, player: side);
  }

  /// The fullest field: the most cards a mode deals, in the most rows.
  static final _fullest = _field(IkkiuchiMode.values.map((m) => m.perSide).reduce(math.max), IkkiuchiLayoutTuning.rows);

  @override
  Widget build(BuildContext context) => FieldPreview(
        spec: _spec,
        semanticLabel: S.of(context).ikkiuchiPreviewLabel(perSide),
        layOut: (area) => _laidOut(_field(perSide, rows), area),
      );

  /// The band and every card of [field] in [area], at the scale that fits
  /// the fullest field there, the band across its middle.
  static FieldPreviewLayout _laidOut(IkkiuchiField field, Rect area) {
    const band = IkkiuchiPageLayout.previewBand;
    const bandGap = IkkiuchiPageLayout.previewBandGap;
    final scale = math.min(
      area.width / _fullest.leastWidth(),
      (area.height - band - 2 * bandGap) / (2 * _fullest.halfHeight),
    );
    final half = field.halfHeight;
    final gap = (band + 2 * bandGap) / scale;
    final top = area.top + (area.height - (2 * half + gap) * scale) / 2;
    final width = math.max(area.width / scale, field.leastWidth());
    final left = area.left + (area.width - width * scale) / 2;
    return (
      bandTop: top + half * scale + bandGap,
      cards: [
        for (final card in field.layOut(width, gap: gap))
          Rect.fromCenter(
            center: Offset(left + card.box.centre.x * scale, top + card.box.centre.y * scale),
            width: 2 * card.box.hw * scale,
            height: 2 * card.box.hh * scale,
          ),
      ],
    );
  }
}
