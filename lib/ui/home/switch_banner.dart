import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';

/// Journey Home once the exam is passed: a banner over the bottom of the
/// islands map offering all-known mode. A tap asks first
/// ([confirmSwitchToAllKnown]); the ✕ puts the banner away for good, since
/// Settings still offers the switch.
class SwitchBanner extends StatelessWidget {
  const SwitchBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: SwitchBannerStyle.maxTextScale,
      child: Padding(
        padding: SwitchBannerStyle.margin,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SwitchBannerStyle.fill,
            border: Border.all(color: Palette.ink, width: Strokes.control),
            boxShadow: const [BoxShadow(color: Palette.ink, offset: SwitchBannerStyle.shadow)],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => confirmSwitchToAllKnown(context),
                    semanticLabel: Phrases.spoken(s.switchBanner),
                    drop: 0,
                    scale: 1,
                    turn: 0,
                    builder: (context, pressed) => Padding(
                      padding: SwitchBannerStyle.padding,
                      child: Row(children: [
                        InkTag(s.rankedTag,
                            color: Palette.pink, fontSize: SwitchBannerStyle.tagFont, padding: TagStyle.compactPadding),
                        const SizedBox(width: SwitchBannerStyle.gap),
                        Expanded(
                          child: Text.rich(
                            Phrases.span(s.switchBanner),
                            style: const TextStyle(
                              fontWeight: Weights.black,
                              fontSize: SwitchBannerStyle.font,
                              height: SwitchBannerStyle.lineHeight,
                            ),
                          ),
                        ),
                        const SizedBox(width: SwitchBannerStyle.gap),
                        Transform.translate(
                          offset: Offset(pressed ? Press.buttonDrop : 0, 0),
                          child: MangaIcon(IconArt.arrow, size: SwitchBannerStyle.arrowIcon),
                        ),
                      ]),
                    ),
                  ),
                ),
                Pressable(
                  onTap: ProgressScope.read(context).closeSwitchBanner,
                  semanticLabel: s.close,
                  builder: (context, _) => SizedBox(
                    width: SwitchBannerStyle.closeTarget,
                    child: Center(child: MangaIcon(IconArt.close, size: SwitchBannerStyle.closeIcon)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Asks whether to move to all-known mode now that the exam is passed, and
/// switches on yes. "Not yet" changes nothing.
Future<void> confirmSwitchToAllKnown(BuildContext context) async {
  final progress = ProgressScope.read(context);
  final ok = await showMangaSheet<bool>(
    context,
    barrierColor: SwitchSheetStyle.barrier,
    barrierLabel: S.of(context).cancel,
    builder: (_) => const _SwitchSheet(),
  );
  if (ok == true) await progress.switchToAllKnown();
}

class _SwitchSheet extends StatelessWidget {
  const _SwitchSheet();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const body = TextStyle(
        fontSize: SwitchSheetStyle.body, fontWeight: Weights.bold, height: SwitchSheetStyle.lineHeight);
    Widget point(String text) => Padding(
          padding: const EdgeInsets.only(top: SwitchSheetStyle.pointGap),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: (SwitchSheetStyle.body * SwitchSheetStyle.lineHeight - SwitchSheetStyle.bulletSize) / 2),
              child: const SizedBox.square(
                dimension: SwitchSheetStyle.bulletSize,
                child: ColoredBox(color: Palette.ink),
              ),
            ),
            const SizedBox(width: SwitchSheetStyle.bulletGap),
            Expanded(child: Text.rich(Phrases.span(text), style: body)),
          ]),
        );
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Gaps.gutter),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MangaPanel(
                  shape: const PanelShape(topLeft: Offset(0, SwitchSheetStyle.cut)),
                  padding: SwitchSheetStyle.padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [InkTag(s.switchTag, color: Palette.land, textColor: Palette.ink)]),
                      const SizedBox(height: Gaps.small),
                      Text.rich(
                        Phrases.span(s.switchTitle),
                        style: const TextStyle(
                            fontFamily: Fonts.display, fontSize: SwitchSheetStyle.title, height: TypeScale.displayLineHeight),
                      ),
                      const SizedBox(height: Gaps.small),
                      point(s.switchPointRanked),
                      point(s.switchPointRank),
                      point(s.switchPointKeep),
                      const SizedBox(height: Gaps.section),
                      SizedBox(
                        height: SwitchSheetStyle.shoutHeight,
                        child: ShoutButton(
                          label: s.switchNow,
                          color: Palette.pink,
                          pressedColor: Palette.pinkDeep,
                          onTap: () => Navigator.pop(context, true),
                        ),
                      ),
                      const SizedBox(height: Gaps.panel),
                      SizedBox(
                        height: SwitchSheetStyle.plainHeight,
                        child: InkButton(
                          onTap: () => Navigator.pop(context, false),
                          child: Text(s.switchNotYet,
                              style: const TextStyle(fontWeight: Weights.black, fontSize: TypeScale.button)),
                        ),
                      ),
                      const SizedBox(height: Gaps.small),
                      Text.rich(
                        Phrases.span(s.switchLater),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: SwitchSheetStyle.note, fontWeight: Weights.bold),
                      ),
                    ],
                  ),
                ),
                const Placed(SwitchSheetStyle.tobi, child: Tobi(pose: TobiPose.cheering)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
