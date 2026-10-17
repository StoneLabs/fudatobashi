import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// A page opened from Help: its [title] (and [sub]) beside the back button,
/// shrinking rather than cut short,
/// then [body] under it, which scrolls on its own and keeps to the gutters
/// itself, so shadows and rules can reach the screen's edges.
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, this.sub, required this.body});

  final String title;
  final String? sub;
  final Widget body;

  /// The padding a scrolling [body] keeps around its content.
  static const padding = EdgeInsets.fromLTRB(Gaps.gutter, Gaps.tight, Gaps.gutter, ProseLayout.bottomPad);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: HeaderStyle.topGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
              child: MangaHeader(
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ScreenTitle(title, sub: sub),
                ),
                actions: [
                  InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                ],
              ),
            ),
            const SizedBox(height: Gaps.section),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
