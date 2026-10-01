import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../data/poem.dart';
import '../../l10n/strings.dart';
import '../../state/settings.dart';
import '../manga/manga.dart';
import '../sound/sounds.dart';

/// A card's kimariji as one unit: the KIMARIJI tag over it, the kimariji in
/// the player's script — in romaji with its kana under it, since the cards
/// are kana — and the speaker button right after it. A long kimariji
/// shrinks to fit, apart from its kana; the speaker never does.
class KimarijiHeading extends StatelessWidget {
  const KimarijiHeading({
    super.key,
    required this.poemId,
    required this.fontSize,
    required this.kanaFontSize,
    this.color = Palette.ink,
    this.outline,
  });

  final int poemId;
  final double fontSize;
  final double kanaFontSize;
  final Color color;

  /// The width of an ink outline around the kimariji, if any.
  final double? outline;

  @override
  Widget build(BuildContext context) {
    final text = kimarijiFor(context, poemId);
    final style = TextStyle(fontFamily: Fonts.display, fontSize: fontSize, color: color, height: 1);
    final outline = this.outline;
    Widget fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      InkTag(S.of(context).kimarijiCaption, fontSize: KimarijiHeadingStyle.tagFont, padding: TagStyle.compactPadding),
      const SizedBox(height: KimarijiHeadingStyle.tagGap),
      Row(children: [
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            fit(outline == null
                ? Text(text, maxLines: 1, style: style)
                : OutlinedText(text, style: style, outline: Palette.ink, outlineWidth: outline)),
            if (resolvedKimarijiScript(context) == KimarijiScript.romaji) ...[
              const SizedBox(height: KimarijiHeadingStyle.kanaGap),
              fit(Text(poems[poemId].kimariji,
                  maxLines: 1, style: TextStyle(fontFamily: Fonts.ui, fontWeight: Weights.bold, fontSize: kanaFontSize))),
            ],
          ]),
        ),
        const SizedBox(width: KimarijiHeadingStyle.speakerGap),
        KimarijiSpeakerButton(poemId: poemId),
      ]),
    ]);
  }
}
