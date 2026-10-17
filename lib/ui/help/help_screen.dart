import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/guide_strings.dart';
import '../../l10n/help_strings.dart';
import '../../l10n/rules_strings.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../history/history_widgets.dart';
import '../manga/manga.dart';
import '../tour/tour_overlay.dart';
import 'karuta_guide_screen.dart';
import 'karuta_rules_screen.dart';

/// Help (opened from Home's "?" button). Guides: Tobi's tour of Home
/// again, the guide to how karuta works and the full competition rules.
/// Tools: none yet, a slot says they are coming.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final o = s.sub;
    void open(Widget page) => Navigator.of(context).push(MangaRoute<void>(builder: (_) => page));
    final guides = [
      _Entry(
        title: s.replayTour,
        sub: o?.replayTour,
        note: s.replayTourNote,
        icon: IconArt.refresh,
        onTap: () => replayTour(context),
      ),
      _Entry(
        title: s.guideTitle,
        sub: o?.guideTitle,
        note: s.guideRowNote,
        icon: IconArt.arrow,
        onTap: () => open(const KarutaGuideScreen()),
      ),
      _Entry(
        title: s.rulesTitle,
        sub: o?.rulesTitle,
        note: s.rulesRowNote,
        icon: IconArt.arrow,
        onTap: () => open(const KarutaRulesScreen()),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              MangaHeader(
                title: ScreenTitle(s.help, sub: s.other.help),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
              const SizedBox(height: Gaps.section),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: Gaps.tight, bottom: ProseLayout.bottomPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Heading(s.helpGuides, o?.helpGuides),
                      for (final entry in guides) ...[entry, const _Rule()],
                      const SizedBox(height: HelpLayout.sectionGap),
                      _Heading(s.helpTools, o?.helpTools),
                      const SizedBox(height: HelpLayout.soonGap),
                      _ToolsSoon(s.helpToolsSoon),
                    ],
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

/// One guide: its [title] in display type, the English [sub] under it in a
/// Japanese UI, a [note] on what it is, and [icon] at the end. Stamps when
/// tapped.
class _Entry extends StatelessWidget {
  const _Entry({required this.title, this.sub, required this.note, required this.icon, required this.onTap});

  final String title;
  final String? sub;
  final String note;
  final VectorArt icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        drop: 0,
        turn: 0,
        scale: Press.panelScale,
        builder: (context, pressed) => Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: pressed ? Tones.stampOpacity : 0,
                duration: Motion.stampFade,
                child: const ToneBox(Tones.stamp),
              ),
            ),
            Padding(
              padding: HelpLayout.entryPadding,
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontFamily: Fonts.display,
                              fontSize: HelpLayout.titleFont,
                              height: HelpLayout.titleLineHeight)),
                      if (sub case final sub?)
                        Text(sub.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: Weights.black,
                                fontSize: HelpLayout.subFont,
                                letterSpacing: HelpLayout.subFont * HelpLayout.subTracking,
                                color: Palette.inkSoft)),
                      const SizedBox(height: HelpLayout.noteGap),
                      Text.rich(Phrases.span(note),
                          style: const TextStyle(
                              fontWeight: Weights.medium,
                              fontSize: HelpLayout.noteFont,
                              height: HelpLayout.noteLineHeight,
                              color: Palette.inkSoft)),
                    ],
                  ),
                ),
                const SizedBox(width: HelpLayout.iconGap),
                MangaIcon(icon, size: HelpLayout.icon),
              ]),
            ),
          ],
        ),
      );
}

/// A section heading in the run pages' marker style.
class _Heading extends StatelessWidget {
  const _Heading(this.title, this.sub);

  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: HistoryHeading(
          title: title,
          sub: sub,
          accent: HelpLayout.markerColor,
          titleFont: HelpLayout.headingFont,
          subFont: HelpLayout.headingSubFont,
        ),
      );
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: HelpLayout.rule, child: ColoredBox(color: Palette.ink));
}

/// The tools still to come: [line] centred in a dashed slot.
class _ToolsSoon extends StatelessWidget {
  const _ToolsSoon(this.line);

  final String line;

  @override
  Widget build(BuildContext context) => DashedBox(
        color: HelpLayout.soonFill,
        border: HelpLayout.soonBorder,
        padding: HelpLayout.soonPadding,
        child: Text.rich(
          Phrases.span(line),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: Weights.black,
            fontSize: HelpLayout.soonFont,
            letterSpacing: HelpLayout.soonFont * HelpLayout.soonTracking,
            height: HelpLayout.soonLineHeight,
            color: Palette.inkSoft,
          ),
        ),
      );
}
