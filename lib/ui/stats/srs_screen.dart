import 'dart:math' as math;

import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/stats_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../side_trips/dojo_scene.dart';

/// The SRS page, opened from the Stats header. Still being built: Side
/// Trips' construction site says so until the real page replaces this one.
class SrsScreen extends StatelessWidget {
  const SrsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: Row(children: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                  const SizedBox(width: Gaps.section),
                  Expanded(child: ScreenTitle(s.srs)),
                ]),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      LayoutBuilder(builder: (context, box) {
                        final width = math.min(box.maxWidth, SrsLayout.artMaxWidth);
                        return ScenePicture(DojoRingLayout.building.colour,
                            size: Size(width, width / SrsLayout.artAspect));
                      }),
                      const SizedBox(height: SrsLayout.titleGap),
                      Text(
                        s.srsSoonTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: Fonts.display, fontSize: SrsLayout.titleFont),
                      ),
                      const SizedBox(height: SrsLayout.lineGap),
                      Text.rich(
                        Phrases.span(s.srsSoonLine),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: Weights.bold, fontSize: SrsLayout.lineFont),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
