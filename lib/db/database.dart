import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../domain/ankiren_field.dart';
import '../domain/play_session.dart';
import '../domain/side_trips.dart';
import '../domain/step_plan.dart';
import '../migrations/migrations.dart';
import '../state/play_config.dart';

part 'database.g.dart';

// Enums are stored by name, so renaming a value needs a migration.

/// One run of the main game (札落とし), stored when it ends. Guest runs are
/// never stored. Whatever a run shows that can be worked out from its
/// attempts (cards swiped, misses, placement, an exam won) is not stored.
@DataClassName('RunRow')
@TableIndex(name: 'runs_day', columns: {#day})
@TableIndex(name: 'runs_mode', columns: {#mode, #startedAt})
class Runs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mode => textEnum<PlayMode>()();
  DateTimeColumn get startedAt => dateTime()();

  /// When it was played to its end, ended early or forfeited.
  DateTimeColumn get endedAt => dateTime()();

  /// The practice day it was played on (see `DayWindow`), yyyymmdd.
  IntColumn get day => integer().references(Days, #day)();

  /// Played in all-known mode (else journey mode).
  BoolColumn get allKnown => boolean()();

  /// JSON list of FudaSet ids that defined the deck (empty for training;
  /// `PlayConfig.knownDeckId` for free practice's default deck).
  TextColumn get setIds => text().withDefault(const Constant('[]'))();

  /// JSON list of a hand-picked deck's cards; null for a deck of sets.
  TextColumn get cardIds => text().nullable()();

  /// 隠し字 level (0 = off).
  IntColumn get maskLevel => integer().withDefault(const Constant(0))();

  /// The goal time per card when it was played, ms.
  IntColumn get goalMs => integer()();

  /// Cards it was planned with (more than were swiped when it ended early).
  IntColumn get planned => integer()();

  /// Played to its last card.
  BoolColumn get completed => boolean()();

  /// First reveal → last swipe, less breaks, µs: the total, or the time so
  /// far of a run ended early. Null when it is no measurement.
  IntColumn get clockUs => integer().nullable()();

  /// A ranked run's or an exam try's time with its penalties
  /// (`RankedScore.scored`), ms.
  IntColumn get scoredMs => integer().nullable()();

  /// A ranked run's rating after it and the performance it played at; null
  /// for every other run.
  RealColumn get rating => real().nullable()();
  RealColumn get performance => real().nullable()();

  /// An exam try's Tobi: his time, and his time as each card went (JSON
  /// list of ms).
  IntColumn get tobiMs => integer().nullable()();
  TextColumn get tobiLine => text().nullable()();

  /// It passed the graduation exam (once ever; developer mode can clear it).
  BoolColumn get graduated => boolean().withDefault(const Constant(false))();

  /// It finished journey mode's set for the day.
  BoolColumn get dayDone => boolean().withDefault(const Constant(false))();
}

/// One swipe of one card, undone ones included.
@DataClassName('AttemptRow')
@TableIndex(name: 'attempts_run', columns: {#runId})
@TableIndex(name: 'attempts_item', columns: {#poemId, #inverted})
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get runId => integer().references(Runs, #id)();

  /// Order within the run.
  IntColumn get seq => integer()();
  IntColumn get poemId => integer()();
  BoolColumn get inverted => boolean()();

  /// The run's 隠し字 level when the card had kana hidden, else 0.
  IntColumn get maskLevel => integer().withDefault(const Constant(0))();
  TextColumn get outcome => textEnum<Outcome>()();

  /// Marked wrong afterwards (kimariji chip tap or ひとつ前).
  BoolColumn get wrong => boolean().withDefault(const Constant(false))();

  /// The time is not a clean measurement (see `Attempt.tainted`).
  BoolColumn get tainted => boolean().withDefault(const Constant(false))();

  /// Taken back with ひとつ前 (it counts as a miss).
  BoolColumn get undone => boolean().withDefault(const Constant(false))();

  /// The run's queue length at the swipe.
  IntColumn get deckSize => integer()();

  /// Wall-clock time of the swipe.
  DateTimeColumn get at => dateTime()();

  /// The card's reveal, µs after the run's first reveal (breaks included);
  /// null for a swipe from before it was kept.
  IntColumn get revealAtUs => integer().nullable()();

  /// Reveal → response (the touch that swiped it), µs, as measured.
  IntColumn get responseUs => integer()();

  /// Reveal → the swipe let go, µs; null like [revealAtUs].
  IntColumn get commitUs => integer().nullable()();

  /// The FSRS grade it was given (1–4); null when it was no review. The
  /// fsrs columns are null with it.
  IntColumn get grade => integer().nullable()();

  /// FSRS's chance of recall just before the review; null for a card's
  /// first.
  RealColumn get fsrsRecall => real().nullable()();

  /// The card's FSRS state after the review.
  TextColumn get fsrsState => textEnum<fsrs.State>().nullable()();
  IntColumn get fsrsStep => integer().nullable()();
  RealColumn get fsrsStability => real().nullable()();
  RealColumn get fsrsDifficulty => real().nullable()();
  DateTimeColumn get fsrsDue => dateTime().nullable()();
}

/// Training state per card × orientation: whether it is unlocked, and its
/// FSRS state now (the state after its latest graded attempt).
@DataClassName('ItemRow')
class Items extends Table {
  IntColumn get poemId => integer()();
  BoolColumn get inverted => boolean()();
  BoolColumn get unlocked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  /// Null until its first review, with the other fsrs columns.
  TextColumn get fsrsState => textEnum<fsrs.State>().nullable()();
  IntColumn get fsrsStep => integer().nullable()();
  RealColumn get fsrsStability => real().nullable()();
  RealColumn get fsrsDifficulty => real().nullable()();
  DateTimeColumn get fsrsDue => dateTime().nullable()();
  DateTimeColumn get fsrsLastReview => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {poemId, inverted};
}

/// The islands counted as complete (journey mode's island celebration).
@DataClassName('IslandCompletionRow')
class IslandCompletions extends Table {
  IntColumn get island => integer()();
  DateTimeColumn get at => dateTime()();

  /// The journey run that completed it (it was celebrated, and earned
  /// experience); null when it was marked without one (in all-known mode,
  /// or by the switch to it).
  IntColumn get runId => integer().nullable().references(Runs, #id)();

  @override
  Set<Column> get primaryKey => {island};
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
@TableIndex(name: 'side_trip_runs_day', columns: {#day})
class SideTripRuns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get game => textEnum<SideTrip>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();

  /// The practice day it was played on, yyyymmdd.
  IntColumn get day => integer().references(Days, #day)();
  BoolColumn get ranked => boolean()();

  /// The level played; null for a custom setup.
  IntColumn get level => integer().nullable()();

  /// The score and the most the game could score; null for a custom setup,
  /// which is not scored.
  IntColumn get score => integer().nullable()();
  IntColumn get maxScore => integer().nullable()();

  /// Played to the last prompt (false for a game ended early).
  BoolColumn get completed => boolean()();

  /// The trip's rating after this game, and the game's performance on the
  /// same scale; null for free play.
  RealColumn get rating => real().nullable()();
  RealColumn get performance => real().nullable()();

  /// The trip's own details as JSON (暗記練: `AnkirenMeta`).
  TextColumn get meta => text().withDefault(const Constant('{}'))();
}

/// One prompt of a side-trip game and how it was answered; every prompt
/// of a game has one.
@DataClassName('SideTripAnswerRow')
@TableIndex(name: 'side_trip_answers_run', columns: {#runId})
class SideTripAnswers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get runId => integer().references(SideTripRuns, #id)();
  IntColumn get seq => integer()();
  IntColumn get poemId => integer()();

  /// Other cards tapped while this one was asked.
  IntColumn get wrongTaps => integer()();

  /// The player gave it up ("don't know"). Never found and not given up:
  /// the game ended first.
  BoolColumn get gaveUp => boolean().withDefault(const Constant(false))();

  /// Prompt → the tap on its card, µs; null when it was never found.
  IntColumn get responseUs => integer().nullable()();

  /// When it was found or given up, or the game ended.
  DateTimeColumn get at => dateTime()();

  /// The first tap while it was asked: where it landed, the card it hit and
  /// prompt → tap, µs; null when no card was tapped.
  TextColumn get firstTap => textEnum<TapProximity>().nullable()();
  IntColumn get firstTapCard => integer().nullable()();
  IntColumn get firstTapUs => integer().nullable()();

  /// The second tap: where it landed and the card it hit; null when there
  /// was none.
  TextColumn get secondTap => textEnum<TapProximity>().nullable()();
  IntColumn get secondTapCard => integer().nullable()();
}

/// One practice day (see `DayWindow`): journey mode's today's set and
/// whether it was done. Stored the first time the day is needed, and for
/// every day with a run or a side-trip game.
@DataClassName('DayRow')
class Days extends Table {
  /// The day's date as yyyymmdd.
  IntColumn get day => integer()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();

  /// When today's set was built; null on a day without one.
  DateTimeColumn get builtAt => dateTime().nullable()();

  /// The morning's guess at the extra looks misses will add.
  IntColumn get missGuess => integer().withDefault(const Constant(0))();
  BoolColumn get newPaused => boolean().withDefault(const Constant(false))();
  BoolColumn get pauseAsked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get doneAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {day};
}

/// A card of a day's set.
@DataClassName('DayCardRow')
class DayCards extends Table {
  IntColumn get day => integer().references(Days, #day)();
  IntColumn get poemId => integer()();
  BoolColumn get inverted => boolean()();

  /// A due review or a new card.
  TextColumn get kind => textEnum<StepKind>()();

  @override
  Set<Column> get primaryKey => {day, poemId, inverted};
}

@DriftDatabase(
    tables: [Runs, Attempts, Items, IslandCompletions, KeyValues, SideTripRuns, SideTripAnswers, Days, DayCards])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'fudatobashi'));

  /// Raised with each new upgrade step in `lib/migrations/` ([migrationSteps]).
  /// Version 3 has no upgrade step yet, so an older database fails to open.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: migrate,
      );
}
