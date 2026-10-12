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

/// One game of a side trip (寄り道), ranked or free play. Every trip shares
/// this table; [game] says which one it was.
@DataClassName('SideTripRun')
class SideTripRuns extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `SideTrip.name`, e.g. `ankiren`.
  TextColumn get game => text()();
  DateTimeColumn get startedAt => dateTime()();
  BoolColumn get ranked => boolean()();

  /// The level played; null for a custom setup.
  IntColumn get level => integer().nullable()();

  /// Prompts asked.
  IntColumn get cardCount => integer()();
  IntColumn get score => integer()();
  IntColumn get maxScore => integer()();

  /// Played to the last prompt (false for a game ended early).
  BoolColumn get completed => boolean()();

  /// The trip's rating after this game, and the game's performance on the
  /// same scale; null for free play.
  RealColumn get rating => real().nullable()();
  RealColumn get performance => real().nullable()();

  /// Free-form JSON (cards per side, memorise time, …).
  TextColumn get meta => text().withDefault(const Constant('{}'))();
}

/// One prompt of a side-trip game and how it was answered.
@DataClassName('SideTripAnswerRow')
class SideTripAnswers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get runId => integer().references(SideTripRuns, #id)();
  IntColumn get seq => integer()();
  IntColumn get poemId => integer()();

  /// Other cards tapped while this one was asked.
  IntColumn get wrongTaps => integer()();

  /// Prompt → the tap on its card, µs; null when it was never found.
  IntColumn get responseUs => integer().nullable()();
  DateTimeColumn get at => dateTime()();
}

@DriftDatabase(tables: [Sessions, Attempts, Items, RatingPoints, KeyValues, SideTripRuns, SideTripAnswers])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'fudatobashi'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX attempts_poem ON attempts (poem_id, inverted)');
          await customStatement('CREATE INDEX attempts_session ON attempts (session_id)');
          await customStatement(_sideTripAnswersIndex);
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(sideTripRuns);
            await m.createTable(sideTripAnswers);
            await customStatement(_sideTripAnswersIndex);
          }
        },
      );

  static const _sideTripAnswersIndex = 'CREATE INDEX side_trip_answers_run ON side_trip_answers (run_id)';
}
