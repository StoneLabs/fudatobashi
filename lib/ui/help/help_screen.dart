import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/strings.dart';
import '../manga/manga.dart';
import '../shell/coming_soon.dart';

/// The Help tab (placeholder).
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        children: [
          MangaHeader(title: ScreenTitle(s.help, sub: s.other.help)),
          Expanded(child: ComingSoon(message: s.comingSoon)),
        ],
      ),
    );
  }
}
