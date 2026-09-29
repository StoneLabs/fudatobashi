import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../db/database.dart' show Session;
import '../../l10n/history_strings.dart';
import '../../l10n/strings.dart';
import '../../state/scope.dart';
import '../manga/manga.dart';
import '../play/time_format.dart';
import '../run/run_labels.dart';

/// The History tab: every past run, newest first, high-contrast ink on paper
/// (unlike the original app's dim grey-on-green history text). Opening a run
/// for detail is a later task.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final progress = ProgressScope.of(context);
    final entries = [
      for (final session in progress.sessions.reversed) _HistoryEntry(session: session, misses: progress.missesIn(session.id)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MangaHeader(title: ScreenTitle(s.history, sub: s.other.history)),
          const SizedBox(height: Gaps.section),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: DashedBox(
                      padding: HistoryLayout.emptyPadding,
                      child: Text(s.noRunsYet, style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.body)),
                    ),
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gaps.panel),
                    itemBuilder: (context, i) => _HistoryRow(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One session bundled with its miss count (not stored on [Session] itself;
/// see `Progress.missesIn`).
class _HistoryEntry {
  const _HistoryEntry({required this.session, required this.misses});
  final Session session;
  final int misses;
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final session = entry.session;
    final total = session.completed && session.totalUs != null
        ? formatRunTime(Duration(microseconds: session.totalUs!))
        : s.runEndedEarly;
    return MangaPanel(
      padding: HistoryLayout.rowPadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(child: InkTag(runLabel(s, ProgressScope.of(context).configOf(session)))),
                  const SizedBox(width: Gaps.panel),
                  Flexible(
                    child: Text(s.sessionDate(session.startedAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: Weights.bold, fontSize: HistoryLayout.rowDateFont)),
                  ),
                ]),
                const SizedBox(height: Gaps.tight),
                NumberedText(
                  s.historyLineTemplate,
                  [session.cardCount, entry.misses],
                  style: const TextStyle(fontWeight: Weights.bold, fontSize: TypeScale.small),
                  numberStyle: const TextStyle(fontFamily: Fonts.display, fontWeight: Weights.black, fontSize: TypeScale.small),
                ),
              ],
            ),
          ),
          const SizedBox(width: Gaps.panel),
          Text(total, style: const TextStyle(fontFamily: Fonts.display, fontSize: HistoryLayout.rowTimeFont, height: 1)),
        ],
      ),
    );
  }
}
