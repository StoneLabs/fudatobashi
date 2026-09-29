import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../l10n/strings.dart';
import '../../l10n/tour_strings.dart';
import '../manga/manga.dart';
import '../settings/settings_rows.dart';
import '../shell/coming_soon.dart';
import '../tour/tour_overlay.dart';

/// The Help tab: Tobi's tour of Home again, and the guides to come.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MangaHeader(title: ScreenTitle(s.help, sub: s.other.help)),
          const SizedBox(height: Gaps.section),
          SettingsGroup(children: [
            SettingsTapRow(title: s.replayTour, note: s.replayTourNote, onTap: () => replayTour(context)),
          ]),
          Expanded(child: ComingSoon(message: s.comingSoon)),
        ],
      ),
    );
  }
}
