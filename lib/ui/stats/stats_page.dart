import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';

/// A page opened from Stats or Home (rank, SRS, calendar): the back button
/// and title over [body], on the Stats dots behind the header.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.title, this.sub, this.trailing, required this.body});
  final String title;
  final String? sub;

  /// Beside the title, on the right.
  final Widget? trailing;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: GradationBox(Tones.statsPage)),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HeaderStyle.topGap),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
                child: IntrinsicHeight(
                  child: Row(children: [
                    InkIconButton(icon: IconArt.back, semanticLabel: s.back, onTap: () => Navigator.maybePop(context)),
                    const SizedBox(width: Gaps.section),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ScreenTitle(title, sub: sub),
                      ),
                    ),
                    if (trailing case final trailing?) ...[const SizedBox(width: Gaps.small), trailing],
                  ]),
                ),
              ),
              const SizedBox(height: Gaps.section),
              Expanded(child: body),
            ],
          ),
        ),
      ]),
    );
  }
}

/// A scrolling page body: its sections with the page gutter.
class StatsPageList extends StatelessWidget {
  const StatsPageList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(Gaps.gutter, Gaps.tight, Gaps.gutter, StatsPageLayout.bottomPad),
        children: children,
      );
}
