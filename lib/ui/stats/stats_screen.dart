import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../shell/coming_soon.dart';

/// The Stats tab (placeholder).
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        children: [
          MangaHeader(title: ScreenTitle(s.stats, sub: s.other.stats)),
          Expanded(child: ComingSoon(message: s.comingSoon)),
        ],
      ),
    );
  }
}
