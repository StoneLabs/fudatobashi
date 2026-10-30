import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/torifuda_spec.dart';
import '../../config/vector_art.dart';
import '../../data/poem.dart';
import '../../l10n/guide_strings.dart';
import '../../l10n/romaji.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../torifuda/torifuda_painter.dart';

/// First sounds' pictures (`FirstSoundsScreen`), drawn from the app's own
/// cards. They are pictures, so the font scale leaves their lettering alone;
/// captions around them still follow it. The frame they sit in, Tobi's lines
/// and the small headings are here too.

const _cardAspect = TorifudaSpec.width / TorifudaSpec.height;

/// A picture in a panel with a hard shadow, and its [caption] under it.
class GuideFigure extends StatelessWidget {
  const GuideFigure({super.key, required this.child, this.caption});

  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: KarutaGuideLayout.figureGap),
        child: MangaPanel(
          color: Palette.desk,
          shadow: const Offset(KarutaGuideLayout.figureShadow, KarutaGuideLayout.figureShadow),
          padding: KarutaGuideLayout.figurePadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            child,
            if (caption case final caption?) ...[
              const SizedBox(height: KarutaGuideLayout.captionGap),
              Text(caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: KarutaGuideLayout.captionFont)),
            ],
          ]),
        ),
      );
}

/// Tobi saying [line], with the space above it.
class GuideTobi extends StatelessWidget {
  const GuideTobi(this.line, {super.key, required this.pose, this.phrases = false});

  final String line;
  final TobiPose pose;
  final bool phrases;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: GuideLayout.tobiGap),
        child: TobiLine(line, pose: pose, phrases: phrases),
      );
}

/// A small heading inside a chapter, with the space above it.
class GuideSubhead extends StatelessWidget {
  const GuideSubhead(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: GuideLayout.subheadGap), child: ProseSubhead(text));
}

/// One kana as a tile, red when it is the sound that decides, grey when
/// its card has been read; the romaji of how it's read under it when the
/// player reads romaji.
class GuideKanaTile extends StatelessWidget {
  const GuideKanaTile(this.kana, this.reading, {super.key, this.decides = false, this.faded = false});

  final String kana, reading;
  final bool decides, faded;

  @override
  Widget build(BuildContext context) {
    final romaji = resolvedKimarijiScript(context) == KimarijiScript.romaji;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox.square(
        dimension: KarutaGuideLayout.tile,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: decides ? Palette.alarm : (faded ? Palette.desk : Palette.paper),
            border: Border.all(color: faded ? Palette.mute : Palette.ink, width: KarutaGuideLayout.tileBorder),
          ),
          child: Center(
            child: Text(kana,
                style: TextStyle(
                    fontWeight: Weights.black,
                    fontSize: KarutaGuideLayout.tileFont,
                    height: 1,
                    color: decides ? Palette.paper : (faded ? Palette.mute : Palette.ink))),
          ),
        ),
      ),
      if (romaji) ...[
        const SizedBox(height: KarutaGuideLayout.romajiGap),
        Text(hepburn(reading),
            style: const TextStyle(fontWeight: Weights.bold, fontSize: KarutaGuideLayout.romajiFont)),
      ],
    ]);
  }
}

/// One line of a kimariji picture: [kimariji] as tiles, its last kana
/// red, an arrow and [poem]'s taking card. A [read] card is shown already
/// gone: grey tiles and a faded card under a stamp.
class GuideKimarijiRow {
  const GuideKimarijiRow({required this.poem, required this.kimariji, this.read = false});

  final Poem poem;
  final String kimariji;
  final bool read;
}

/// Kimariji lines one under another, their arrows lined up.
class GuideKimarijiRows extends StatelessWidget {
  const GuideKimarijiRows({super.key, required this.rows});

  final List<GuideKimarijiRow> rows;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final most = rows.map((r) => r.kimariji.length).reduce(math.max);
    const cardHeight = KarutaGuideLayout.kimarijiCard / _cardAspect;
    return MediaQuery.withNoTextScaling(
      child: Column(children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: KarutaGuideLayout.kimarijiRowGap),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: most * KarutaGuideLayout.tile + (most - 1) * KarutaGuideLayout.tileGap,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                for (var k = 0; k < row.kimariji.length; k++) ...[
                  if (k > 0) const SizedBox(width: KarutaGuideLayout.tileGap),
                  GuideKanaTile(row.kimariji[k], row.poem.kamiReading[k],
                      decides: !row.read && k == row.kimariji.length - 1, faded: row.read),
                ],
              ]),
            ),
            const SizedBox(width: KarutaGuideLayout.kimarijiArrowGap),
            MangaIcon(IconArt.arrow,
                size: KarutaGuideLayout.kimarijiArrow, color: row.read ? Palette.mute : Palette.ink),
            const SizedBox(width: KarutaGuideLayout.kimarijiArrowGap),
            SizedBox(
              width: KarutaGuideLayout.kimarijiCard,
              height: cardHeight,
              child: row.read
                  ? Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                      Opacity(
                        opacity: KarutaGuideLayout.readOpacity,
                        child: TorifudaCard(poem: row.poem, showNumber: false),
                      ),
                      _Stamp(s.guideReadStamp),
                    ])
                  : TorifudaCard(poem: row.poem, showNumber: false),
            ),
          ]),
        ],
      ]),
    );
  }
}

/// A red hanko-style stamp across a card that has been read.
class _Stamp extends StatelessWidget {
  const _Stamp(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: KarutaGuideLayout.stampTurn,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Palette.paper,
            border: Border.all(color: Palette.alarm, width: KarutaGuideLayout.stampBorder),
          ),
          child: Padding(
            padding: KarutaGuideLayout.stampPadding,
            child: Text(text.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                    fontFamily: Fonts.display, fontSize: KarutaGuideLayout.stampFont, color: Palette.alarm)),
          ),
        ),
      );
}
