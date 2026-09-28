import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/settings_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// A full-screen, hard-to-miss warning before Settings' journey → all-known
/// switch: unlocking every card can't be undone. Pops `true` once the hold
/// confirms it, `false` (or a back gesture) leaves everything unchanged.
class AllKnownWarningScreen extends StatelessWidget {
  const AllKnownWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: Palette.pinkSoft,
      body: SafeArea(
        child: Padding(
          padding: AllKnownWarningStyle.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkIconButton(icon: IconArt.back, semanticLabel: s.cancel, onTap: () => Navigator.of(context).pop(false)),
              const SizedBox(height: Gaps.section),
              Text(
                s.allKnownWarningTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: Fonts.display,
                  fontSize: AllKnownWarningStyle.titleFont,
                  height: TypeScale.displayLineHeight,
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(height: AllKnownWarningStyle.tobiHeight, child: const Tobi(pose: TobiPose.shocked)),
                ),
              ),
              Text(
                s.allKnownWarningBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: Weights.bold,
                  fontSize: AllKnownWarningStyle.bodyFont,
                  height: AllKnownWarningStyle.bodyLineHeight,
                ),
              ),
              const SizedBox(height: Gaps.section),
              Center(
                child: HoldToConfirmButton(
                  duration: AllKnownSwitchTuning.holdDuration,
                  label: s.allKnownWarningHold,
                  icon: MangaIcon(IconArt.lock, size: HoldConfirmStyle.icon),
                  onConfirmed: () => Navigator.of(context).pop(true),
                ),
              ),
              const SizedBox(height: Gaps.section),
            ],
          ),
        ),
      ),
    );
  }
}
