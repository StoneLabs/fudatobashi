import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';

/// Tobi's [rating] on an ink tag: his name, then the rating.
class IkkiuchiTobiTag extends StatelessWidget {
  const IkkiuchiTobiTag(this.rating, {super.key});

  final int rating;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(color: Palette.ink),
        child: Padding(
          padding: IkkiuchiTobiTagStyle.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(S.of(context).ikkiuchiTobi,
                  style: const TextStyle(
                      fontWeight: Weights.black,
                      fontSize: IkkiuchiTobiTagStyle.nameFont,
                      height: 1,
                      color: IkkiuchiTobiTagStyle.name)),
              const SizedBox(width: IkkiuchiTobiTagStyle.gap),
              Text('$rating',
                  style: const TextStyle(
                      fontFamily: Fonts.display, fontSize: IkkiuchiTobiTagStyle.font, height: 1, color: Palette.paper)),
            ],
          ),
        ),
      );
}
