import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../manga/manga.dart';

/// A message from Tobi on a dimmed screen: a [title] on an ink tag over the
/// panel's top edge, Tobi in [pose] beside the [body], an optional [note] in
/// small print, and the [actions] under them. It scrolls when it doesn't
/// fit.
class TobiNotice extends StatelessWidget {
  const TobiNotice({
    super.key,
    required this.title,
    required this.body,
    this.note,
    this.pose = TobiPose.tryHard,
    required this.actions,
  });

  final String title, body;
  final String? note;
  final TobiPose pose;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tag =
        FittedBox(fit: BoxFit.scaleDown, child: InkBanner(Phrases.spoken(title), fontSize: TobiNoticeStyle.tagFont));
    const padding = TobiNoticeStyle.panelPadding;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: TobiNoticeStyle.scrim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: TobiNoticeStyle.margin,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: TobiNoticeStyle.maxWidth),
                child: Stack(clipBehavior: Clip.none, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: TobiNoticeStyle.tagRise),
                    child: MangaPanel(
                      shadow: TobiNoticeStyle.panelShadow,
                      padding: padding,
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Overhang(rise: TobiNoticeStyle.tagRise + padding.top, child: ExcludeSemantics(child: tag)),
                        ),
                        const SizedBox(height: TobiNoticeStyle.gap),
                        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          SizedBox.fromSize(size: TobiNoticeStyle.tobi, child: Tobi(pose: pose)),
                          const SizedBox(width: TobiNoticeStyle.gap),
                          Expanded(
                            child: Text.rich(Phrases.span(body),
                                style: const TextStyle(
                                    fontWeight: Weights.bold,
                                    fontSize: TobiNoticeStyle.bodyFont,
                                    height: TobiNoticeStyle.bodyLineHeight)),
                          ),
                        ]),
                        if (note != null) ...[
                          const SizedBox(height: TobiNoticeStyle.gap),
                          Text.rich(Phrases.span(note!),
                              style: const TextStyle(
                                  fontWeight: Weights.bold,
                                  fontSize: TobiNoticeStyle.noteFont,
                                  height: TobiNoticeStyle.noteLineHeight,
                                  color: Palette.inkSoft)),
                        ],
                        const SizedBox(height: TobiNoticeStyle.gap),
                        for (final (i, action) in actions.indexed) ...[
                          if (i > 0) const SizedBox(height: TobiNoticeStyle.buttonGap),
                          action,
                        ],
                      ]),
                    ),
                  ),
                  Positioned(
                    left: padding.left,
                    right: padding.right,
                    top: 0,
                    child: Align(alignment: Alignment.centerLeft, child: Semantics(header: true, child: tag)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The plain ink button of a [TobiNotice], for an answer that isn't its
/// shout.
class TobiNoticeButton extends StatelessWidget {
  const TobiNoticeButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: TobiNoticeStyle.buttonHeight,
        child: InkButton(
          onTap: onTap,
          semanticLabel: label,
          padding: const EdgeInsets.symmetric(horizontal: Gaps.inner),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: const TextStyle(fontWeight: Weights.black, fontSize: TobiNoticeStyle.buttonFont)),
          ),
        ),
      );
}
