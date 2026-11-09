import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../domain/ikkiuchi_field.dart';
import '../../domain/ikkiuchi_layout.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../side_trips/field_preview.dart';
import 'ikkiuchi_board_layout.dart';
import 'ikkiuchi_tobi_art.dart';

/// A small picture of a field of [perSide] cards a side in [rows] rows as a
/// match lays it out in landscape, face down on the match's tatami
/// ([FieldPreview]): each side in the usual shape of its rows
/// ([IkkiuchiLayout.usualShape]), Tobi's over a band and the player's under
/// it, their groups at the field's edges. As in the match
/// ([IkkiuchiBoardLayout]), every field is a 3-row field, as wide and as
/// tall, and in 1 or 2 rows its cards are bigger
/// ([IkkiuchiBoardLayout.growth]), their rows lying by the band. The 3-row
/// field fills the box it is given.
class IkkiuchiFieldPicture extends StatelessWidget {
  const IkkiuchiFieldPicture(this.perSide, {super.key, required this.rows});

  final int perSide, rows;

  static const _spec = FieldPreviewSpec(
    margin: EdgeInsets.zero,
    minHeight: 0,
    ground: IkkiuchiFieldPictureStyle.ground,
    tatami: IkkiuchiBoardStyle.tatami,
    tatamiScale: IkkiuchiBoardStyle.tatamiScale,
    border: IkkiuchiFieldPictureStyle.border,
    padding: IkkiuchiFieldPictureStyle.padding,
    band: IkkiuchiFieldPictureStyle.band,
    bandColor: Palette.paper,
    bandRule: IkkiuchiFieldPictureStyle.bandRule,
    backFill: Palette.cardFrame,
    backBorder: Palette.ink,
    backBorderWidth: IkkiuchiFieldPictureStyle.cardEdge,
  );

  /// Where Tobi's arms are, which his room in a landscape match is sized by.
  static final _rig = IkkiuchiTobiArt.rig();

  @override
  Widget build(BuildContext context) => FieldPreview(
        spec: _spec,
        semanticLabel: S.of(context).ikkiuchiPreviewLabel(perSide),
        layOut: (area) => _laidOut(perSide, rows, area),
      );

  /// The band and every card of a field of [perSide] cards a side in
  /// [rows] rows in [area]: the 3-row field as big as fits it, in its
  /// middle, and the cards as many times a 3-row card as the match makes
  /// them.
  static FieldPreviewLayout _laidOut(int perSide, int rows, Rect area) {
    const band = IkkiuchiFieldPictureStyle.band;
    const bandGap = IkkiuchiFieldPictureStyle.bandGap;
    var next = 0;
    final side = [
      for (final row in IkkiuchiLayout.usualShape(perSide, rows))
        IkkiuchiRow([for (var i = 0; i < row.left; i++) next++], [for (var i = 0; i < row.right; i++) next++]),
    ];
    final field = IkkiuchiField(tobi: side, player: side, rowGap: IkkiuchiFieldTuning.landscapeRowGap);
    // The 3-row field's half and width, in this match's card widths.
    final grow = IkkiuchiBoardLayout.growth(rows, landscape: true, rig: _rig);
    final half = IkkiuchiField.halfOf(IkkiuchiLayoutTuning.rows, field.rowGap) / grow;
    final width = math.max(IkkiuchiLayoutTuning.rowSlots / grow, field.leastWidth());
    final cardW = math.min((area.height - band - 2 * bandGap) / (2 * half), area.width / width);
    final gap = (band + 2 * bandGap) / cardW;
    final left = area.left + (area.width - width * cardW) / 2;
    final top = area.top + (area.height - (2 * half + gap) * cardW) / 2;
    final rowsTop = top + (half - field.halfHeight) * cardW;
    return (
      bandTop: top + half * cardW + bandGap,
      cards: [
        for (final card in field.layOut(width, gap: gap))
          Rect.fromCenter(
            center: Offset(left + card.box.centre.x * cardW, rowsTop + card.box.centre.y * cardW),
            width: 2 * card.box.hw * cardW,
            height: 2 * card.box.hh * cardW,
          ),
      ],
    );
  }
}
