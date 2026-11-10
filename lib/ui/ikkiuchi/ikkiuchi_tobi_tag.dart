import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';

/// Tobi's [rating] on an ink tag: his name, then the rating, at
/// [IkkiuchiTobiTagStyle]'s sizes unless given others.
class IkkiuchiTobiTag extends StatelessWidget {
  const IkkiuchiTobiTag(
    this.rating, {
    super.key,
    this.nameFont = IkkiuchiTobiTagStyle.nameFont,
    this.font = IkkiuchiTobiTagStyle.font,
    this.padding = IkkiuchiTobiTagStyle.padding,
  });

  final int rating;
  final double nameFont, font;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(S.of(context).ikkiuchiTobi,
                  style: TextStyle(
                      fontWeight: Weights.black,
                      fontSize: nameFont,
                      height: 1,
                      color: IkkiuchiTobiTagStyle.name)),
              const SizedBox(width: IkkiuchiTobiTagStyle.gap),
              Text('$rating',
                  style: TextStyle(fontFamily: Fonts.display, fontSize: font, height: 1, color: Palette.paper)),
            ],
          ),
        ),
      );
}
