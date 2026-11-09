import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../side_trips/field_preview.dart';

/// A small picture of a field of [perSide] cards a side in [rows] rows as a
/// match deals it, face down on the match's tatami ([FieldPreview]): each
/// side in the usual shape of its rows ([IkkiuchiLayout.usualShape]),
/// Tobi's over a band and the player's under it, their groups at the edges
/// of a row's full width ([IkkiuchiLayoutTuning.rowSlots]). Every field is
/// drawn at the one scale at which the most rows fill the picture, so a
/// field of fewer rows looks smaller. It fills the box it is given.
class IkkiuchiFieldPicture extends StatelessWidget {
  const IkkiuchiFieldPicture(this.perSide, {super.key, required this.rows});

  final int perSide, rows;

  static const _spec = FieldPreviewSpec(
    margin: EdgeInsets.zero,
    minHeight: 0,
    ground: IkkiuchiCustomLayout.pictureGround,
    tatami: IkkiuchiBoardStyle.tatami,
    tatamiScale: IkkiuchiBoardStyle.tatamiScale,
    border: IkkiuchiCustomLayout.pictureBorder,
    padding: IkkiuchiCustomLayout.picturePadding,
    band: IkkiuchiCustomLayout.pictureBand,
    bandColor: Palette.paper,
    bandRule: IkkiuchiCustomLayout.pictureBandRule,
    backFill: Palette.cardFrame,
    backBorder: Palette.ink,
    backBorderWidth: IkkiuchiCustomLayout.pictureCardEdge,
  );

  @override
  Widget build(BuildContext context) => FieldPreview(
        spec: _spec,
        semanticLabel: S.of(context).ikkiuchiPreviewLabel(perSide),
        layOut: (area) => _laidOut(_field(perSide, rows), area),
      );

  /// Both sides of [perSide] cards in [rows] rows, in their usual shape.
  static IkkiuchiField _field(int perSide, int rows) {
    var next = 0;
    final side = [
      for (final row in IkkiuchiLayout.usualShape(perSide, rows))
        IkkiuchiRow([for (var i = 0; i < row.left; i++) next++], [for (var i = 0; i < row.right; i++) next++]),
    ];
    return IkkiuchiField(tobi: side, player: side);
  }

  /// The band and every card of [field] in [area], at the scale at which
  /// the most cards in the most rows fill it, the field in its middle.
  static FieldPreviewLayout _laidOut(IkkiuchiField field, Rect area) {
    const band = IkkiuchiCustomLayout.pictureBand;
    const bandGap = IkkiuchiCustomLayout.pictureBandGap;
    final most = _field(IkkiuchiFreeTuning.perSideMax, IkkiuchiLayoutTuning.rows).halfHeight;
    const width = IkkiuchiLayoutTuning.rowSlots * IkkiuchiField.pitch;
    final scale = math.min((area.height - band - 2 * bandGap) / (2 * most), area.width / width);
    final gap = (band + 2 * bandGap) / scale;
    final half = field.halfHeight;
    final left = area.left + (area.width - width * scale) / 2;
    final top = area.top + (area.height - (2 * half + gap) * scale) / 2;
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
