import 'dart:convert';

import 'package:drift/drift.dart';

import '../config/config.dart';

/// Schema 2 → 3: `sessions` becomes `runs` with its `meta` JSON as typed
/// columns, enums are stored by name, items keep their FSRS card as columns,
/// island completions get a table, and runs and side-trip games store their
/// practice day.
Future<void> v2ToV3(Migrator m) async {
  final db = m.database;
  final kv = {
    for (final r in await db.customSelect('SELECT key, value FROM key_values').get())
      r.read<String>('key'): r.read<String>('value'),
  };
  Map<String, dynamic> jsonOf(String key) {
    try {
      return jsonDecode(kv[key] ?? '{}') as Map<String, dynamic>;
    } on Object {
      return const {};
    }
  }

  final settings = jsonOf('settings'), trainer = jsonOf('trainer');
  final hour = settings['dayStartHour'] is int ? settings['dayStartHour'] as int : TodaySetTuning.defaultDayStartHour;
  final allKnown = trainer['learningMode'] == 'allKnown' ? 1 : 0;
  final goals = trainer['goalsMs'] is List ? (trainer['goalsMs'] as List).whereType<int>().toList() : const <int>[];
  final goalsMs = goals.isEmpty ? TrainingTuning.defaultGoalsMs : goals;
  final goalMs = goalsMs[(int.tryParse(kv['goalLevel'] ?? '') ?? 0).clamp(0, goalsMs.length - 1)];

  // The practice day of unix time [t] (see `DayWindow.at`), and the window
  // of day [d], in local time.
  String dayOf(String t) => "CAST(strftime('%Y%m%d', $t, 'unixepoch', 'localtime', '-$hour hours') AS INTEGER)";
  String dayStart(String d, {int plusDays = 0}) =>
      "CAST(strftime('%s', printf('%04d-%02d-%02d', $d / 10000, $d / 100 % 100, $d % 100), "
      "'+$plusDays days', '+$hour hours', 'utc') AS INTEGER)";
  String daysOf(String table) => 'INSERT OR IGNORE INTO days (day, starts_at, ends_at) '
      'SELECT DISTINCT day, ${dayStart('day')}, ${dayStart('day', plusDays: 1)} FROM $table';
  String tap(String column) => "CASE $column WHEN 0 THEN 'card' WHEN 1 THEN 'neighbour' WHEN 2 THEN 'row' "
      "WHEN 3 THEN 'quadrant' WHEN 4 THEN 'side' WHEN 5 THEN 'otherSide' END";

  for (final sql in [
    for (final t in const ['attempts', 'items', 'side_trip_runs', 'side_trip_answers', 'days', 'day_cards'])
      'ALTER TABLE "$t" RENAME TO "v2_$t"',
    'CREATE TABLE "days" ("day" INTEGER NOT NULL, "starts_at" INTEGER NOT NULL, "ends_at" INTEGER NOT NULL, '
        '"built_at" INTEGER NULL, "miss_guess" INTEGER NOT NULL DEFAULT 0, '
        '"new_paused" INTEGER NOT NULL DEFAULT 0 CHECK ("new_paused" IN (0, 1)), '
        '"pause_asked" INTEGER NOT NULL DEFAULT 0 CHECK ("pause_asked" IN (0, 1)), "done_at" INTEGER NULL, '
        'PRIMARY KEY ("day"))',
    'CREATE TABLE "runs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "mode" TEXT NOT NULL, '
        '"started_at" INTEGER NOT NULL, "ended_at" INTEGER NOT NULL, "day" INTEGER NOT NULL REFERENCES days (day), '
        '"all_known" INTEGER NOT NULL CHECK ("all_known" IN (0, 1)), "set_ids" TEXT NOT NULL DEFAULT \'[]\', '
        '"card_ids" TEXT NULL, "mask_level" INTEGER NOT NULL DEFAULT 0, "goal_ms" INTEGER NOT NULL, '
        '"planned" INTEGER NOT NULL, "completed" INTEGER NOT NULL CHECK ("completed" IN (0, 1)), '
        '"clock_us" INTEGER NULL, "scored_ms" INTEGER NULL, "rating" REAL NULL, "performance" REAL NULL, '
        '"tobi_ms" INTEGER NULL, "tobi_line" TEXT NULL, '
        '"graduated" INTEGER NOT NULL DEFAULT 0 CHECK ("graduated" IN (0, 1)), '
        '"day_done" INTEGER NOT NULL DEFAULT 0 CHECK ("day_done" IN (0, 1)))',
    'CREATE TABLE "attempts" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        '"run_id" INTEGER NOT NULL REFERENCES runs (id), "seq" INTEGER NOT NULL, "poem_id" INTEGER NOT NULL, '
        '"inverted" INTEGER NOT NULL CHECK ("inverted" IN (0, 1)), "mask_level" INTEGER NOT NULL DEFAULT 0, '
        '"outcome" TEXT NOT NULL, "wrong" INTEGER NOT NULL DEFAULT 0 CHECK ("wrong" IN (0, 1)), '
        '"tainted" INTEGER NOT NULL DEFAULT 0 CHECK ("tainted" IN (0, 1)), '
        '"undone" INTEGER NOT NULL DEFAULT 0 CHECK ("undone" IN (0, 1)), "deck_size" INTEGER NOT NULL, '
        '"at" INTEGER NOT NULL, "reveal_at_us" INTEGER NULL, "response_us" INTEGER NOT NULL, '
        '"commit_us" INTEGER NULL, "grade" INTEGER NULL, "fsrs_recall" REAL NULL, "fsrs_state" TEXT NULL, '
        '"fsrs_step" INTEGER NULL, "fsrs_stability" REAL NULL, "fsrs_difficulty" REAL NULL, "fsrs_due" INTEGER NULL)',
    'CREATE TABLE "items" ("poem_id" INTEGER NOT NULL, "inverted" INTEGER NOT NULL CHECK ("inverted" IN (0, 1)), '
        '"unlocked" INTEGER NOT NULL DEFAULT 0 CHECK ("unlocked" IN (0, 1)), "unlocked_at" INTEGER NULL, '
        '"fsrs_state" TEXT NULL, "fsrs_step" INTEGER NULL, "fsrs_stability" REAL NULL, '
        '"fsrs_difficulty" REAL NULL, "fsrs_due" INTEGER NULL, "fsrs_last_review" INTEGER NULL, '
        'PRIMARY KEY ("poem_id", "inverted"))',
    'CREATE TABLE "island_completions" ("island" INTEGER NOT NULL, "at" INTEGER NOT NULL, '
        '"run_id" INTEGER NULL REFERENCES runs (id), PRIMARY KEY ("island"))',
    'CREATE TABLE "side_trip_runs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "game" TEXT NOT NULL, '
        '"started_at" INTEGER NOT NULL, "ended_at" INTEGER NOT NULL, "day" INTEGER NOT NULL REFERENCES days (day), '
        '"ranked" INTEGER NOT NULL CHECK ("ranked" IN (0, 1)), "level" INTEGER NULL, "score" INTEGER NULL, '
        '"max_score" INTEGER NULL, "completed" INTEGER NOT NULL CHECK ("completed" IN (0, 1)), '
        '"rating" REAL NULL, "performance" REAL NULL, "meta" TEXT NOT NULL DEFAULT \'{}\')',
    'CREATE TABLE "side_trip_answers" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
        '"run_id" INTEGER NOT NULL REFERENCES side_trip_runs (id), "seq" INTEGER NOT NULL, '
        '"poem_id" INTEGER NOT NULL, "wrong_taps" INTEGER NOT NULL, '
        '"gave_up" INTEGER NOT NULL DEFAULT 0 CHECK ("gave_up" IN (0, 1)), "response_us" INTEGER NULL, '
        '"at" INTEGER NOT NULL, "first_tap" TEXT NULL, "first_tap_card" INTEGER NULL, "first_tap_us" INTEGER NULL, '
        '"second_tap" TEXT NULL, "second_tap_card" INTEGER NULL)',
    'CREATE TABLE "day_cards" ("day" INTEGER NOT NULL REFERENCES days (day), "poem_id" INTEGER NOT NULL, '
        '"inverted" INTEGER NOT NULL CHECK ("inverted" IN (0, 1)), "kind" TEXT NOT NULL, '
        'PRIMARY KEY ("day", "poem_id", "inverted"))',
    'INSERT INTO days SELECT number, starts_at, ends_at, built_at, miss_guess, new_paused, pause_asked, done_at '
        'FROM v2_days',
    'INSERT INTO day_cards SELECT day, poem_id, inverted, '
        "CASE kind WHEN 0 THEN 'review' WHEN 1 THEN 'newCard' ELSE 'batch' END FROM v2_day_cards",
    // card_count was the queue length; a run ended early has no clock.
    'INSERT INTO runs (id, mode, started_at, ended_at, day, all_known, set_ids, card_ids, mask_level, goal_ms, '
        'planned, completed, clock_us, graduated, day_done) '
        "SELECT id, CASE mode WHEN 0 THEN 'free' WHEN 1 THEN 'nigate' ELSE 'training' END, started_at, "
        'COALESCE((SELECT MAX(at) FROM v2_attempts WHERE session_id = s.id), started_at + total_us / 1000000, '
        "started_at), COALESCE(json_extract(meta, '\$.day'), ${dayOf('started_at')}), $allKnown, set_ids, "
        "json_extract(meta, '\$.cardIds'), COALESCE(json_extract(meta, '\$.maskLevel'), 0), "
        "COALESCE(CAST(ROUND(json_extract(meta, '\$.goalMs')) AS INTEGER), $goalMs), card_count, completed, "
        "CASE WHEN total_us > 0 THEN total_us END, COALESCE(json_extract(meta, '\$.graduated'), 0), "
        "COALESCE(json_extract(meta, '\$.dayDone'), 0) FROM sessions s",
    daysOf('runs'),
    'INSERT INTO attempts (id, run_id, seq, poem_id, inverted, mask_level, outcome, wrong, tainted, undone, '
        'deck_size, at, response_us, grade) '
        "SELECT id, session_id, seq, poem_id, inverted, mask_level, CASE outcome WHEN 1 THEN 'dontKnow' "
        "ELSE 'known' END, wrong, tainted, undone, deck_size, at, response_us, grade FROM v2_attempts",
    'INSERT INTO items SELECT poem_id, inverted, unlocked, unlocked_at, '
        "CASE json_extract(f, '\$.state') WHEN 1 THEN 'learning' WHEN 2 THEN 'review' WHEN 3 THEN 'relearning' "
        "END, json_extract(f, '\$.step'), json_extract(f, '\$.stability'), json_extract(f, '\$.difficulty'), "
        "CAST(strftime('%s', json_extract(f, '\$.due')) AS INTEGER), "
        "CAST(strftime('%s', json_extract(f, '\$.lastReview')) AS INTEGER) "
        "FROM (SELECT *, CASE WHEN json_extract(fsrs, '\$.lastReview') IS NOT NULL THEN fsrs END AS f "
        'FROM v2_items)',
    // An island goes to the first run that celebrated it; one marked without
    // a run gets the latest swipe's time.
    'INSERT OR IGNORE INTO island_completions (island, at, run_id) '
        'SELECT i.value, r.ended_at, r.id FROM sessions s JOIN runs r ON r.id = s.id, '
        "json_each(s.meta, '\$.islandsCompleted') i ORDER BY r.id",
    'INSERT OR IGNORE INTO island_completions (island, at) '
        "SELECT i.value, COALESCE((SELECT MAX(at) FROM attempts), CAST(strftime('%s', 'now') AS INTEGER)) "
        "FROM key_values k, json_each(k.value) i WHERE k.key = 'islandsCelebrated' AND json_valid(k.value)",
    'INSERT INTO side_trip_runs SELECT id, game, started_at, '
        'COALESCE((SELECT MAX(at) FROM v2_side_trip_answers WHERE run_id = r.id), started_at), '
        '${dayOf('started_at')}, ranked, level, score, max_score, completed, rating, performance, meta '
        'FROM v2_side_trip_runs r',
    daysOf('side_trip_runs'),
    // Only a finished game tells a prompt given up from one never reached.
    'INSERT INTO side_trip_answers SELECT a.id, a.run_id, a.seq, a.poem_id, a.wrong_taps, '
        'COALESCE(r.completed AND a.response_us IS NULL, 0), a.response_us, a.at, ${tap('a.first_tap')}, NULL, '
        'a.first_tap_us, ${tap('a.second_tap')}, NULL '
        'FROM v2_side_trip_answers a LEFT JOIN v2_side_trip_runs r ON r.id = a.run_id',
    // The old rating is another model (a projected 100-card time), so
    // players start unplaced.
    'DROP TABLE rating_points',
    "DELETE FROM key_values WHERE key IN ('rating', 'islandsCelebrated')",
    for (final t in const ['side_trip_answers', 'side_trip_runs', 'attempts', 'items', 'day_cards', 'days'])
      'DROP TABLE "v2_$t"',
    'DROP TABLE sessions',
    'CREATE INDEX runs_day ON runs (day)',
    'CREATE INDEX runs_mode ON runs (mode, started_at)',
    'CREATE INDEX attempts_run ON attempts (run_id)',
    'CREATE INDEX attempts_item ON attempts (poem_id, inverted)',
    'CREATE INDEX side_trip_runs_day ON side_trip_runs (day)',
    'CREATE INDEX side_trip_answers_run ON side_trip_answers (run_id)',
  ]) {
    await db.customStatement(sql);
  }
}
