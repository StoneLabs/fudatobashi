import 'dart:convert';

import '../db/database.dart';
import '../domain/card_stats.dart';
import '../domain/xp.dart';
import 'progress.dart';

/// Experience read off the recorded history: sessions with their attempts,
/// plus the milestones [noteMilestones] marks on a session (what its swipes
/// alone can't tell).
abstract final class XpHistory {
  static const _islandsKey = 'islandsCompleted';
  static const _graduatedKey = 'graduated';

  /// Every recorded run of [progress], oldest first.
  static XpLedger ledgerOf(Progress progress) {
    final bySession = <int, List<(ItemKey, AttemptRec)>>{};
    for (final k in progress.trainer.items.keys) {
      for (final a in progress.attemptsOf(k)) {
        if (a.sessionId != null) (bySession[a.sessionId!] ??= []).add((k, a));
      }
    }
    return XpLedger.of([for (final s in progress.sessions) runOf(progress, s, bySession[s.id] ?? const [])]);
  }

  /// Session [s] of [progress] with its attempts, looked up at the end of
  /// each card's log (for a run just recorded).
  static XpRun latestRunOf(Progress progress, Session s) {
    final attempts = <(ItemKey, AttemptRec)>[];
    for (final k in progress.trainer.items.keys) {
      for (final a in progress.attemptsOf(k).reversed) {
        if (a.sessionId != s.id) break;
        attempts.add((k, a));
      }
    }
    return runOf(progress, s, attempts);
  }

  static XpRun runOf(Progress progress, Session s, List<(ItemKey, AttemptRec)> attempts) {
    final meta = jsonDecode(s.meta) as Map<String, dynamic>;
    final config = progress.configOf(s);
    return XpRun(
      sessionId: s.id,
      startedAt: s.startedAt,
      setup: config.historyKey,
      total: s.completed && s.totalUs != null ? Duration(microseconds: s.totalUs!) : null,
      goalMs: (meta['goalMs'] as num?)?.toDouble() ?? progress.trainer.goalMs,
      counts: attempts.any((e) => e.$2.countsForSrs),
      swipes: [
        for (final (k, a) in [...attempts]..sort((x, y) => x.$2.at.compareTo(y.$2.at)))
          XpSwipe(poemId: k.poemId, correct: !a.miss, clean: a.clean, us: a.us, graded: a.grade != null),
      ],
      islands: (meta[_islandsKey] as List?)?.length ?? 0,
      graduated: meta[_graduatedKey] == true,
    );
  }

  /// Marks on session [s] the [islands] it completed and whether it
  /// [graduated], stored and returned as the updated session.
  static Future<Session> noteMilestones(AppDatabase db, Session s,
      {required List<int> islands, required bool graduated}) async {
    if (islands.isEmpty && !graduated) return s;
    final meta = jsonDecode(s.meta) as Map<String, dynamic>;
    final updated = s.copyWith(
      meta: jsonEncode({...meta, if (islands.isNotEmpty) _islandsKey: islands, if (graduated) _graduatedKey: true}),
    );
    await db.update(db.sessions).replace(updated);
    return updated;
  }
}
