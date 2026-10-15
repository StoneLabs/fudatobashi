import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/ranked_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';

/// Journey Home once the exam is passed: a banner over the bottom of the
/// islands map offering all-known mode. A tap asks first
/// ([confirmSwitchToAllKnown]); the ✕ folds the banner into a square button
/// at its right end, which unfolds it again. The banner keeps its room while
/// folded, so the map above it does not move.
class SwitchBanner extends StatelessWidget {
  const SwitchBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final folded = progress.switchBannerCollapsed;
    final s = S.of(context);
    final banner = _Banner(onClose: progress.collapseSwitchBanner);
    final button = Pressable(
      onTap: progress.expandSwitchBanner,
      semanticLabel: s.switchBannerOpen,
      builder: (context, _) => Center(
        child: ExcludeSemantics(
          child: MediaQuery.withNoTextScaling(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              InkTag(s.rankedTag,
                  color: Palette.pink,
                  fontSize: SwitchBannerStyle.markTagFont,
                  padding: SwitchBannerStyle.markTagPadding),
              const SizedBox(height: SwitchBannerStyle.markGap),
              MangaIcon(IconArt.arrow, size: SwitchBannerStyle.markArrow),
            ]),
          ),
        ),
      ),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: SwitchBannerStyle.maxTextScale,
      child: Padding(
        padding: SwitchBannerStyle.margin,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: folded ? 0 : 1),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : SwitchBannerStyle.fold,
          curve: SwitchBannerStyle.foldCurve,
          builder: (context, open, _) => Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = _foldedSize(box.biggest, open);
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: SwitchBannerStyle.fill,
                            border: Border.fromBorderSide(BorderSide(color: Palette.ink, width: Strokes.control)),
                            boxShadow: [BoxShadow(color: Palette.ink, offset: SwitchBannerStyle.shadow)],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                ignoring: folded,
                child: ExcludeSemantics(
                  excluding: folded,
                  child: ClipRect(
                    clipper: _FoldClipper(open),
                    child: Opacity(opacity: SwitchBannerStyle.textShown.transform(open), child: banner),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !folded,
                child: ExcludeSemantics(
                  excluding: !folded,
                  child: Opacity(
                    opacity: 1 - SwitchBannerStyle.markHidden.transform(open),
                    child: SizedBox.square(dimension: SwitchBannerStyle.square, child: button),
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

/// The size of the banner's box at [open], 1 for the banner at [full] size
/// and 0 for the square button.
Size _foldedSize(Size full, double open) => Size(
      lerpDouble(SwitchBannerStyle.square, full.width, open)!,
      lerpDouble(SwitchBannerStyle.square, full.height, open)!,
    );

/// Shows what is inside the banner's box as it folds towards its bottom
/// right corner.
class _FoldClipper extends CustomClipper<Rect> {
  const _FoldClipper(this.open);

  final double open;

  @override
  Rect getClip(Size size) {
    final box = _foldedSize(size, open);
    return Rect.fromLTWH(size.width - box.width, size.height - box.height, box.width, box.height)
        .deflate(Strokes.control);
  }

  @override
  bool shouldReclip(_FoldClipper old) => old.open != open;
}

/// The unfolded banner's lettering, arrow and ✕, at full size inside the
/// border.
class _Banner extends StatelessWidget {
  const _Banner({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.all(Strokes.control),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SwitchBannerStyle.square - 2 * Strokes.control),
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
                onTap: onClose,
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
    );
  }
}

/// Asks whether to move to all-known mode now that the exam is passed, and
/// switches on yes. A tap on the backdrop closes it, changing nothing.
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
                      Text.rich(Phrases.span(s.switchBody), style: body),
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
