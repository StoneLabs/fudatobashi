import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// One run (札落とし session). Guest runs are never stored.
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();

  /// PlayMode index.
  IntColumn get mode => integer()();

  /// JSON list of FudaSet ids that defined the deck (empty for training;
  /// `PlayConfig.knownDeckId` for free practice's default deck). A
  /// hand-picked deck's cards are in [meta] as `cardIds`.
  TextColumn get setIds => text().withDefault(const Constant('[]'))();

  /// The old free-play orientation setting (0 random, 1 upright only, 2
  /// inverted only); new runs store 0.
  IntColumn get orientation => integer()();
  IntColumn get cardCount => integer()();

  /// First reveal → last swipe, µs. Null when the run was ended early.
  IntColumn get totalUs => integer().nullable()();
  BoolColumn get completed => boolean()();

  /// Free-form JSON (mask settings, goal at the time, …).
  TextColumn get meta => text().withDefault(const Constant('{}'))();
}

/// One swipe of one card.
@DataClassName('AttemptRow')
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  IntColumn get seq => integer()();
  IntColumn get poemId => integer()();
  BoolColumn get inverted => boolean()();
  IntColumn get maskLevel => integer().withDefault(const Constant(0))();

  /// Reveal → response, µs.
  IntColumn get responseUs => integer()();

  /// Outcome index: 0 known, 1 don't know.
  IntColumn get outcome => integer()();
  BoolColumn get wrong => boolean().withDefault(const Constant(false))();
  BoolColumn get tainted => boolean().withDefault(const Constant(false))();
  BoolColumn get undone => boolean().withDefault(const Constant(false))();
  IntColumn get deckSize => integer()();
  DateTimeColumn get at => dateTime()();

  /// FSRS rating applied for this attempt (1–4), null if none.
  IntColumn get grade => integer().nullable()();
}

/// Training state per card × orientation.
class Items extends Table {
  IntColumn get poemId => integer()();
  BoolColumn get inverted => boolean()();
  BoolColumn get unlocked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  /// fsrs Card.toMap() as JSON.
  TextColumn get fsrs => text().nullable()();
  IntColumn get maskLevel => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {poemId, inverted};
}

class RatingPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  RealColumn get rating => real()();
  RealColumn get performance => real()();

  /// Projected 100-card time, ms.
  IntColumn get projectedMs => integer()();
  IntColumn get sessionId => integer().nullable()();
}

/// Settings and small app state as JSON values.
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Sessions, Attempts, Items, RatingPoints, KeyValues])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'fudatobashi'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX attempts_poem ON attempts (poem_id, inverted)');
          await customStatement('CREATE INDEX attempts_session ON attempts (session_id)');
        },
      );
}
