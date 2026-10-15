import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../manga/manga.dart';

/// A shout on `burst.svg`: pink, deep pink while pressed, desk grey when
/// [onTap] is null; its [title], the other language's [sub] and an arrow
/// in the art's safe box. It keeps the art's own size, or scales down whole
/// to fit a narrower box.
class BurstButton extends StatelessWidget {
  const BurstButton({super.key, required this.title, this.sub, required this.onTap});

  final String title;
  final String? sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const size = SideTripsLayout.burst;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox.fromSize(
          size: size,
          child: Pressable(
            onTap: onTap,
            drop: 0,
            scale: Press.shoutScale,
            turn: Tilt.pressShout,
            semanticLabel: sub == null ? title : '$title $sub',
            builder: (context, pressed) => Stack(children: [
              VectorArtBox(
                SideTripArt.burst,
                size: size,
                color: onTap == null
                    ? Palette.desk
                    : pressed
                        ? Palette.pinkDeep
                        : Palette.pink,
              ),
              Positioned.fromRect(
                rect: SideTripsLayout.burstLabel,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(fontFamily: Fonts.display, fontSize: SideTripsLayout.burstFont, height: 1)),
                      if (sub != null) ...[
                        const SizedBox(width: SideTripsLayout.burstGap),
                        Text(
                          sub!,
                          style: const TextStyle(
                            fontWeight: Weights.black,
                            fontSize: SideTripsLayout.burstSubFont,
                            letterSpacing: SideTripsLayout.burstSubTracking * SideTripsLayout.burstSubFont,
                            height: 1,
                          ),
                        ),
                      ],
                      const SizedBox(width: SideTripsLayout.burstGap),
                      MangaIcon(IconArt.arrow,
                          size: SideTripsLayout.burstIcon, strokeWidth: SideTripsLayout.burstIconStroke),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
