import 'package:flutter/material.dart';

import '../../config/design.dart';
import '../../config/vector_art.dart';
import '../../l10n/all_guides_strings.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import 'guide_catalog.dart';
import 'help_entry.dart';

/// Every guide of the app in one list (`Guides.all`), opened from Help.
class AllGuidesScreen extends StatelessWidget {
  const AllGuidesScreen({super.key});

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
                title: ScreenTitle(s.allGuidesTitle, sub: s.other.allGuidesTitle),
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
                      for (final guide in Guides.all) ...[
                        HelpEntry(
                          title: guide.title(s),
                          sub: s.sub == null ? null : guide.title(s.sub!),
                          note: guide.note(s),
                          icon: IconArt.arrow,
                          onTap: () => guide.open(context),
                        ),
                        const HelpRule(),
                      ],
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
