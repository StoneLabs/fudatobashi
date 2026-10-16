import 'package:flutter/widgets.dart';

import '../../config/vector_art.dart';
import '../../l10n/srs_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../history/history_widgets.dart';
import '../manga/manga.dart';
import 'srs_details_screen.dart';
import 'srs_sections.dart';
import 'stats_page.dart';

/// The SRS page, opened from the Stats header: how well the cards are
/// remembered (at a glance, known cards over time, the 100-card wall,
/// memory strength), the time practised, the speed and the two sides, then
/// a button to the advanced FSRS table.
class SrsScreen extends StatelessWidget {
  const SrsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    return StatsPage(
      title: s.srsTitle,
      sub: s.other.srsTitle,
      body: StatsPageList(children: [
        SrsGlance(progress),
        SrsKnownOverTime(progress),
        SrsWall(progress),
        SrsStrength(progress),
        SrsTimePractised(progress),
        SrsSpeed(progress),
        SrsSides(progress),
        HistoryButton(
          icon: IconArt.arrow,
          label: s.srsDetailsButton,
          sub: s.sub?.srsDetailsButton,
          onTap: () => Navigator.push(context, MangaRoute<void>(builder: (_) => const SrsDetailsScreen())),
        ),
      ]),
    );
  }
}
