import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ikkiuchi_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// 一騎打ち's bots, from free play, on the side trips' page frame: a line
/// about them over their list, which holds no bots yet.
class IkkiuchiBotsPage extends StatelessWidget {
  const IkkiuchiBotsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: GradationBox(Tones.homeSea)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
            child: ListView(padding: EdgeInsets.zero, children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.ikkiuchiBots, sub: s.ikkiuchiBotsTag),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              Padding(
                padding: IkkiuchiBotsLayout.introPadding,
                child: Text.rich(
                  Phrases.span(s.ikkiuchiBotsIntro),
                  style: const TextStyle(
                      fontWeight: Weights.bold,
                      fontSize: IkkiuchiBotsLayout.introFont,
                      height: IkkiuchiBotsLayout.introLineHeight),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
