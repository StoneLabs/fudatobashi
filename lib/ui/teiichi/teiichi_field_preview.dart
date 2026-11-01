import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/ankiren_field.dart';
import '../../domain/teiichi.dart';
import '../../l10n/strings.dart';
import '../../l10n/teiichi_strings.dart';

/// [setup]'s side of the field as it will lie, face down on the play
/// screen's tatami: its usual shape ([TeiichiBoard.typical]) at true scale,
/// three rows high whatever the setup plays, as large as
/// [TeiichiPageLayout.previewHeight] and the width it is given allow,
/// centred.
class TeiichiFieldPreview extends StatelessWidget {
  const TeiichiFieldPreview(this.setup, {super.key});

  final TeiichiSetup setup;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const margin = AnkirenPageLayout.previewMargin;
        const inset = AnkirenPageLayout.previewBorder + TeiichiPageLayout.previewInset;
        final geometry = TeiichiTargets.geometryOf(TeiichiBoard.typical(setup).half);
        final across = box.maxWidth - margin.horizontal - 2 * inset;
        final scale = math.min(across / geometry.width, TeiichiPageLayout.previewHeight / geometry.height);
        final left = (across - geometry.width * scale) / 2;
        const back = BorderSide(color: AnkirenPlayLayout.backBorder, width: AnkirenPlayLayout.backBorderWidth);
        return Semantics(
          image: true,
          label: S.of(context).teiichiPreviewLabel(setup.cards, setup.rows),
          excludeSemantics: true,
          child: Padding(
            padding: margin,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AnkirenPageLayout.previewGround,
                image: const DecorationImage(
                  image: AssetImage(AnkirenPlayLayout.tatami),
                  repeat: ImageRepeat.repeat,
                  scale: AnkirenPlayLayout.tatamiScale,
                ),
                border: Border.all(color: Palette.ink, width: AnkirenPageLayout.previewBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(TeiichiPageLayout.previewInset),
                child: SizedBox(
                  height: geometry.height * scale,
                  child: Stack(children: [
                    for (final r in geometry.half(FieldSide.own).values)
                      Positioned(
                        left: left + r.x * scale,
                        top: r.y * scale,
                        width: r.w * scale,
                        height: r.h * scale,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(color: AnkirenPlayLayout.backFill, border: Border.fromBorderSide(back)),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        );
      });
}
