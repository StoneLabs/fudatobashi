import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/settings_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/card_size.dart';
import '../play/test_card.dart';
import 'settings_rows.dart';

/// Settings › Card size: one of the tutorial's test cards at the size the
/// swipe cards really get, resizing live under the slider.
class CardSizeScreen extends StatelessWidget {
  const CardSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final scale = progress.settings.cardScale;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.cardSize, sub: s.sub?.cardSize),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final card = playCardSize(c.biggest, scale);
                  return Center(
                    child: SizedBox(width: card.width, height: card.height, child: const TestCard(number: 0)),
                  );
                }),
              ),
              Text(
                '${(scale * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: Fonts.display, fontSize: CardSizeLayout.percentFont, height: 1),
              ),
              const SizedBox(height: CardSizeLayout.percentGap),
              SettingsSlider(
                title: s.cardSize,
                note: s.cardSizeNote,
                value: scale,
                min: SwipeTuning.cardScaleMin,
                max: SwipeTuning.cardScaleMax,
                divisions: ((SwipeTuning.cardScaleMax - SwipeTuning.cardScaleMin) / SwipeTuning.cardScaleStep).round(),
                enabled: true,
                onChanged: (v) => progress.updateSettings(progress.settings.copyWith(cardScale: v)),
              ),
              const SizedBox(height: Gaps.section),
            ],
          ),
        ),
      ),
    );
  }
}
