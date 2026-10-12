import 'package:drift/drift.dart';

import 'v1_to_v2.dart';

/// One schema upgrade, from a version to the next. Its SQL is written out as
/// that version had it, so a later change to a table never changes what an
/// older upgrade does.
typedef MigrationStep = Future<void> Function(Migrator m);

/// Every upgrade, in order: the step at index i takes schema version i + 1
/// to i + 2.
const List<MigrationStep> migrationSteps = [v1ToV2];

/// Takes a database from schema version [from] to [to], all in one
/// transaction, so an upgrade cut short leaves it as it was.
Future<void> migrate(Migrator m, int from, int to) => m.database.transaction(() async {
      for (var version = from; version < to; version++) {
        await migrationSteps[version - 1](m);
      }
    });
