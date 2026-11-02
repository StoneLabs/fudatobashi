import 'package:drift/drift.dart';

import 'v1_to_v2.dart';
import 'v2_to_v3.dart';
import 'v3_to_v4.dart';
import 'v4_to_v5.dart';

/// One schema upgrade, from a version to the next. Its SQL is written out as
/// that version had it, so a later change to a table never changes what an
/// older upgrade does.
typedef MigrationStep = Future<void> Function(Migrator m);

/// Every upgrade, in order: the step at index i takes schema version i + 1
/// to i + 2.
const List<MigrationStep> migrationSteps = [v1ToV2, v2ToV3, v3ToV4, v4ToV5];

/// Takes a database from schema version [from] to [to], all in one
/// transaction, so an upgrade cut short leaves it as it was.
Future<void> migrate(Migrator m, int from, int to) => m.database.transaction(() async {
      for (var version = from; version < to; version++) {
        await migrationSteps[version - 1](m);
      }
    });

/// The schema version [migrationSteps] lead up to (`AppDatabase.schemaVersion`).
int get latestSchemaVersion => migrationSteps.length + 1;

/// The tables a database of each schema version has (a backup is checked
/// against them before it is restored).
const Map<int, Set<String>> schemaTables = {
  1: {'sessions', 'attempts', 'items', 'rating_points', 'key_values'},
  2: {
    'sessions', 'attempts', 'items', 'rating_points', 'key_values',
    'side_trip_runs', 'side_trip_answers', 'days', 'day_cards',
  },
  3: {
    'runs', 'attempts', 'items', 'island_completions', 'key_values',
    'side_trip_runs', 'side_trip_answers', 'days', 'day_cards',
  },
  4: {
    'runs', 'attempts', 'items', 'island_completions', 'key_values',
    'side_trip_runs', 'side_trip_answers', 'days', 'day_cards',
  },
  5: {
    'runs', 'attempts', 'items', 'island_completions', 'key_values',
    'side_trip_runs', 'side_trip_answers', 'teiichi_placings', 'days', 'day_cards',
  },
};
