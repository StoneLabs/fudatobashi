import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fudatobashi/config/design.dart';
import 'package:fudatobashi/config/torifuda_spec.dart';
import 'package:fudatobashi/config/vector_art.dart';
import 'package:fudatobashi/data/poem.dart';
import 'package:fudatobashi/l10n/romaji.dart';
import 'package:fudatobashi/l10n/strings.dart';
import 'package:fudatobashi/state/settings.dart';
import 'package:fudatobashi/ui/manga/manga.dart';
import 'package:fudatobashi/ui/torifuda/torifuda_painter.dart';

import 'figure_layout.dart';

/// One kana as a tile, red when it is the sound that decides, grey when
/// its card has been read; the romaji of how it's read under it when the
/// player reads romaji.
class KanaTile extends StatelessWidget {
  const KanaTile(this.kana, this.reading, {super.key, this.decides = false, this.faded = false});

  final String kana, reading;
  final bool decides, faded;

  @override
  Widget build(BuildContext context) {
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox.square(
        dimension: KimarijiFigureLayout.tile,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: decides ? Palette.alarm : (faded ? Palette.desk : Palette.paper),
            border: Border.all(color: faded ? Palette.mute : Palette.ink, width: KimarijiFigureLayout.tileBorder),
          ),
          child: Center(
            child: Text(kana,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: KimarijiFigureLayout.tileFont,
                    height: 1,
                    color: decides ? Palette.paper : (faded ? Palette.mute : Palette.ink))),
          ),
        ),
      ),
      if (romaji) ...[
        const SizedBox(height: KimarijiFigureLayout.romajiGap),
        Text(hepburn(reading),
            style: const TextStyle(fontWeight: Weights.bold, fontSize: KimarijiFigureLayout.romajiFont)),
      ],
    ]);
  }
}

/// One line of a kimariji picture: [kimariji] as tiles, its last kana
/// red, an arrow and [poem]'s taking card. A [read] card is shown already
/// gone: grey tiles and a faded card under a stamp.
class KimarijiRow {
  const KimarijiRow({required this.poem, required this.kimariji, this.read = false});

  final Poem poem;
  final String kimariji;
  final bool read;
}

/// Kimariji lines one under another, their arrows lined up.
class KimarijiRows extends StatelessWidget {
  const KimarijiRows({super.key, required this.rows});

  final List<KimarijiRow> rows;

  @override
  Widget build(BuildContext context) {
    final stamp = FigureWords.read[S.of(context).code]!;
    final most = rows.map((r) => r.kimariji.length).reduce(math.max);
    const cardHeight = KimarijiFigureLayout.card / (TorifudaSpec.width / TorifudaSpec.height);
    return Column(children: [
      for (final (i, row) in rows.indexed) ...[
        if (i > 0) const SizedBox(height: KimarijiFigureLayout.rowGap),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: most * KimarijiFigureLayout.tile + (most - 1) * KimarijiFigureLayout.tileGap,
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              for (var k = 0; k < row.kimariji.length; k++) ...[
                if (k > 0) const SizedBox(width: KimarijiFigureLayout.tileGap),
                KanaTile(row.kimariji[k], row.poem.kamiReading[k],
                    decides: !row.read && k == row.kimariji.length - 1, faded: row.read),
              ],
            ]),
          ),
          const SizedBox(width: KimarijiFigureLayout.arrowGap),
          MangaIcon(IconArt.arrow, size: KimarijiFigureLayout.arrow, color: row.read ? Palette.mute : Palette.ink),
          const SizedBox(width: KimarijiFigureLayout.arrowGap),
          SizedBox(
            width: KimarijiFigureLayout.card,
            height: cardHeight,
            child: row.read
                ? Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                    Opacity(
                      opacity: KimarijiFigureLayout.readOpacity,
                      child: TorifudaCard(poem: row.poem, showNumber: false),
                    ),
                    _Stamp(stamp),
                  ])
                : TorifudaCard(poem: row.poem, showNumber: false),
          ),
        ]),
      ],
    ]);
  }
}

/// A red hanko-style stamp across a card that has been read.
class _Stamp extends StatelessWidget {
  const _Stamp(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: KimarijiFigureLayout.stampTurn,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper,
            border: Border.all(color: Palette.alarm, width: KimarijiFigureLayout.stampBorder),
          ),
          child: Padding(
            padding: KimarijiFigureLayout.stampPadding,
            child: Text(text.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: KimarijiFigureLayout.stampFont, color: Palette.alarm)),
          ),
        ),
      );
}
