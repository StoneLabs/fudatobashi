// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DaysTable extends Days with TableInfo<$DaysTable, DayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startsAtMeta = const VerificationMeta(
    'startsAt',
  );
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
    'starts_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
    'ends_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _builtAtMeta = const VerificationMeta(
    'builtAt',
  );
  @override
  late final GeneratedColumn<DateTime> builtAt = GeneratedColumn<DateTime>(
    'built_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missGuessMeta = const VerificationMeta(
    'missGuess',
  );
  @override
  late final GeneratedColumn<int> missGuess = GeneratedColumn<int>(
    'miss_guess',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _newPausedMeta = const VerificationMeta(
    'newPaused',
  );
  @override
  late final GeneratedColumn<bool> newPaused = GeneratedColumn<bool>(
    'new_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("new_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _pauseAskedMeta = const VerificationMeta(
    'pauseAsked',
  );
  @override
  late final GeneratedColumn<bool> pauseAsked = GeneratedColumn<bool>(
    'pause_asked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pause_asked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    day,
    startsAt,
    endsAt,
    builtAt,
    missGuess,
    newPaused,
    pauseAsked,
    doneAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'days';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('starts_at')) {
      context.handle(
        _startsAtMeta,
        startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(
        _endsAtMeta,
        endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('built_at')) {
      context.handle(
        _builtAtMeta,
        builtAt.isAcceptableOrUnknown(data['built_at']!, _builtAtMeta),
      );
    }
    if (data.containsKey('miss_guess')) {
      context.handle(
        _missGuessMeta,
        missGuess.isAcceptableOrUnknown(data['miss_guess']!, _missGuessMeta),
      );
    }
    if (data.containsKey('new_paused')) {
      context.handle(
        _newPausedMeta,
        newPaused.isAcceptableOrUnknown(data['new_paused']!, _newPausedMeta),
      );
    }
    if (data.containsKey('pause_asked')) {
      context.handle(
        _pauseAskedMeta,
        pauseAsked.isAcceptableOrUnknown(data['pause_asked']!, _pauseAskedMeta),
      );
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      startsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}starts_at'],
      )!,
      endsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ends_at'],
      )!,
      builtAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}built_at'],
      ),
      missGuess: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}miss_guess'],
      )!,
      newPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}new_paused'],
      )!,
      pauseAsked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pause_asked'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      ),
    );
  }

  @override
  $DaysTable createAlias(String alias) {
    return $DaysTable(attachedDatabase, alias);
  }
}

class DayRow extends DataClass implements Insertable<DayRow> {
  /// The day's date as yyyymmdd.
  final int day;
  final DateTime startsAt;
  final DateTime endsAt;

  /// When today's set was built; null on a day without one.
  final DateTime? builtAt;

  /// The morning's guess at the extra looks misses will add.
  final int missGuess;
  final bool newPaused;
  final bool pauseAsked;
  final DateTime? doneAt;
  const DayRow({
    required this.day,
    required this.startsAt,
    required this.endsAt,
    this.builtAt,
    required this.missGuess,
    required this.newPaused,
    required this.pauseAsked,
    this.doneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<int>(day);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['ends_at'] = Variable<DateTime>(endsAt);
    if (!nullToAbsent || builtAt != null) {
      map['built_at'] = Variable<DateTime>(builtAt);
    }
    map['miss_guess'] = Variable<int>(missGuess);
    map['new_paused'] = Variable<bool>(newPaused);
    map['pause_asked'] = Variable<bool>(pauseAsked);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    return map;
  }

  DaysCompanion toCompanion(bool nullToAbsent) {
    return DaysCompanion(
      day: Value(day),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      builtAt: builtAt == null && nullToAbsent
          ? const Value.absent()
          : Value(builtAt),
      missGuess: Value(missGuess),
      newPaused: Value(newPaused),
      pauseAsked: Value(pauseAsked),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
    );
  }

  factory DayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayRow(
      day: serializer.fromJson<int>(json['day']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime>(json['endsAt']),
      builtAt: serializer.fromJson<DateTime?>(json['builtAt']),
      missGuess: serializer.fromJson<int>(json['missGuess']),
      newPaused: serializer.fromJson<bool>(json['newPaused']),
      pauseAsked: serializer.fromJson<bool>(json['pauseAsked']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<int>(day),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'endsAt': serializer.toJson<DateTime>(endsAt),
      'builtAt': serializer.toJson<DateTime?>(builtAt),
      'missGuess': serializer.toJson<int>(missGuess),
      'newPaused': serializer.toJson<bool>(newPaused),
      'pauseAsked': serializer.toJson<bool>(pauseAsked),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
    };
  }

  DayRow copyWith({
    int? day,
    DateTime? startsAt,
    DateTime? endsAt,
    Value<DateTime?> builtAt = const Value.absent(),
    int? missGuess,
    bool? newPaused,
    bool? pauseAsked,
    Value<DateTime?> doneAt = const Value.absent(),
  }) => DayRow(
    day: day ?? this.day,
    startsAt: startsAt ?? this.startsAt,
    endsAt: endsAt ?? this.endsAt,
    builtAt: builtAt.present ? builtAt.value : this.builtAt,
    missGuess: missGuess ?? this.missGuess,
    newPaused: newPaused ?? this.newPaused,
    pauseAsked: pauseAsked ?? this.pauseAsked,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
  );
  DayRow copyWithCompanion(DaysCompanion data) {
    return DayRow(
      day: data.day.present ? data.day.value : this.day,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      builtAt: data.builtAt.present ? data.builtAt.value : this.builtAt,
      missGuess: data.missGuess.present ? data.missGuess.value : this.missGuess,
      newPaused: data.newPaused.present ? data.newPaused.value : this.newPaused,
      pauseAsked: data.pauseAsked.present
          ? data.pauseAsked.value
          : this.pauseAsked,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayRow(')
          ..write('day: $day, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('builtAt: $builtAt, ')
          ..write('missGuess: $missGuess, ')
          ..write('newPaused: $newPaused, ')
          ..write('pauseAsked: $pauseAsked, ')
          ..write('doneAt: $doneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    day,
    startsAt,
    endsAt,
    builtAt,
    missGuess,
    newPaused,
    pauseAsked,
    doneAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayRow &&
          other.day == this.day &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.builtAt == this.builtAt &&
          other.missGuess == this.missGuess &&
          other.newPaused == this.newPaused &&
          other.pauseAsked == this.pauseAsked &&
          other.doneAt == this.doneAt);
}

class DaysCompanion extends UpdateCompanion<DayRow> {
  final Value<int> day;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<DateTime?> builtAt;
  final Value<int> missGuess;
  final Value<bool> newPaused;
  final Value<bool> pauseAsked;
  final Value<DateTime?> doneAt;
  const DaysCompanion({
    this.day = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.builtAt = const Value.absent(),
    this.missGuess = const Value.absent(),
    this.newPaused = const Value.absent(),
    this.pauseAsked = const Value.absent(),
    this.doneAt = const Value.absent(),
  });
  DaysCompanion.insert({
    this.day = const Value.absent(),
    required DateTime startsAt,
    required DateTime endsAt,
    this.builtAt = const Value.absent(),
    this.missGuess = const Value.absent(),
    this.newPaused = const Value.absent(),
    this.pauseAsked = const Value.absent(),
    this.doneAt = const Value.absent(),
  }) : startsAt = Value(startsAt),
       endsAt = Value(endsAt);
  static Insertable<DayRow> custom({
    Expression<int>? day,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<DateTime>? builtAt,
    Expression<int>? missGuess,
    Expression<bool>? newPaused,
    Expression<bool>? pauseAsked,
    Expression<DateTime>? doneAt,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (builtAt != null) 'built_at': builtAt,
      if (missGuess != null) 'miss_guess': missGuess,
      if (newPaused != null) 'new_paused': newPaused,
      if (pauseAsked != null) 'pause_asked': pauseAsked,
      if (doneAt != null) 'done_at': doneAt,
    });
  }

  DaysCompanion copyWith({
    Value<int>? day,
    Value<DateTime>? startsAt,
    Value<DateTime>? endsAt,
    Value<DateTime?>? builtAt,
    Value<int>? missGuess,
    Value<bool>? newPaused,
    Value<bool>? pauseAsked,
    Value<DateTime?>? doneAt,
  }) {
    return DaysCompanion(
      day: day ?? this.day,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      builtAt: builtAt ?? this.builtAt,
      missGuess: missGuess ?? this.missGuess,
      newPaused: newPaused ?? this.newPaused,
      pauseAsked: pauseAsked ?? this.pauseAsked,
      doneAt: doneAt ?? this.doneAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (builtAt.present) {
      map['built_at'] = Variable<DateTime>(builtAt.value);
    }
    if (missGuess.present) {
      map['miss_guess'] = Variable<int>(missGuess.value);
    }
    if (newPaused.present) {
      map['new_paused'] = Variable<bool>(newPaused.value);
    }
    if (pauseAsked.present) {
      map['pause_asked'] = Variable<bool>(pauseAsked.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaysCompanion(')
          ..write('day: $day, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('builtAt: $builtAt, ')
          ..write('missGuess: $missGuess, ')
          ..write('newPaused: $newPaused, ')
          ..write('pauseAsked: $pauseAsked, ')
          ..write('doneAt: $doneAt')
          ..write(')'))
        .toString();
  }
}

class $RunsTable extends Runs with TableInfo<$RunsTable, RunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlayMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PlayMode>($RunsTable.$convertermode);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (day)',
    ),
  );
  static const VerificationMeta _allKnownMeta = const VerificationMeta(
    'allKnown',
  );
  @override
  late final GeneratedColumn<bool> allKnown = GeneratedColumn<bool>(
    'all_known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_known" IN (0, 1))',
    ),
  );
  static const VerificationMeta _setIdsMeta = const VerificationMeta('setIds');
  @override
  late final GeneratedColumn<String> setIds = GeneratedColumn<String>(
    'set_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _cardIdsMeta = const VerificationMeta(
    'cardIds',
  );
  @override
  late final GeneratedColumn<String> cardIds = GeneratedColumn<String>(
    'card_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maskLevelMeta = const VerificationMeta(
    'maskLevel',
  );
  @override
  late final GeneratedColumn<int> maskLevel = GeneratedColumn<int>(
    'mask_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _goalMsMeta = const VerificationMeta('goalMs');
  @override
  late final GeneratedColumn<int> goalMs = GeneratedColumn<int>(
    'goal_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMeta = const VerificationMeta(
    'planned',
  );
  @override
  late final GeneratedColumn<int> planned = GeneratedColumn<int>(
    'planned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _clockUsMeta = const VerificationMeta(
    'clockUs',
  );
  @override
  late final GeneratedColumn<int> clockUs = GeneratedColumn<int>(
    'clock_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoredMsMeta = const VerificationMeta(
    'scoredMs',
  );
  @override
  late final GeneratedColumn<int> scoredMs = GeneratedColumn<int>(
    'scored_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _performanceMeta = const VerificationMeta(
    'performance',
  );
  @override
  late final GeneratedColumn<double> performance = GeneratedColumn<double>(
    'performance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tobiMsMeta = const VerificationMeta('tobiMs');
  @override
  late final GeneratedColumn<int> tobiMs = GeneratedColumn<int>(
    'tobi_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tobiLineMeta = const VerificationMeta(
    'tobiLine',
  );
  @override
  late final GeneratedColumn<String> tobiLine = GeneratedColumn<String>(
    'tobi_line',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _graduatedMeta = const VerificationMeta(
    'graduated',
  );
  @override
  late final GeneratedColumn<bool> graduated = GeneratedColumn<bool>(
    'graduated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("graduated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dayDoneMeta = const VerificationMeta(
    'dayDone',
  );
  @override
  late final GeneratedColumn<bool> dayDone = GeneratedColumn<bool>(
    'day_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("day_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mode,
    startedAt,
    endedAt,
    day,
    allKnown,
    setIds,
    cardIds,
    maskLevel,
    goalMs,
    planned,
    completed,
    clockUs,
    scoredMs,
    rating,
    performance,
    tobiMs,
    tobiLine,
    graduated,
    dayDone,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('all_known')) {
      context.handle(
        _allKnownMeta,
        allKnown.isAcceptableOrUnknown(data['all_known']!, _allKnownMeta),
      );
    } else if (isInserting) {
      context.missing(_allKnownMeta);
    }
    if (data.containsKey('set_ids')) {
      context.handle(
        _setIdsMeta,
        setIds.isAcceptableOrUnknown(data['set_ids']!, _setIdsMeta),
      );
    }
    if (data.containsKey('card_ids')) {
      context.handle(
        _cardIdsMeta,
        cardIds.isAcceptableOrUnknown(data['card_ids']!, _cardIdsMeta),
      );
    }
    if (data.containsKey('mask_level')) {
      context.handle(
        _maskLevelMeta,
        maskLevel.isAcceptableOrUnknown(data['mask_level']!, _maskLevelMeta),
      );
    }
    if (data.containsKey('goal_ms')) {
      context.handle(
        _goalMsMeta,
        goalMs.isAcceptableOrUnknown(data['goal_ms']!, _goalMsMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMsMeta);
    }
    if (data.containsKey('planned')) {
      context.handle(
        _plannedMeta,
        planned.isAcceptableOrUnknown(data['planned']!, _plannedMeta),
      );
    } else if (isInserting) {
      context.missing(_plannedMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('clock_us')) {
      context.handle(
        _clockUsMeta,
        clockUs.isAcceptableOrUnknown(data['clock_us']!, _clockUsMeta),
      );
    }
    if (data.containsKey('scored_ms')) {
      context.handle(
        _scoredMsMeta,
        scoredMs.isAcceptableOrUnknown(data['scored_ms']!, _scoredMsMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('performance')) {
      context.handle(
        _performanceMeta,
        performance.isAcceptableOrUnknown(
          data['performance']!,
          _performanceMeta,
        ),
      );
    }
    if (data.containsKey('tobi_ms')) {
      context.handle(
        _tobiMsMeta,
        tobiMs.isAcceptableOrUnknown(data['tobi_ms']!, _tobiMsMeta),
      );
    }
    if (data.containsKey('tobi_line')) {
      context.handle(
        _tobiLineMeta,
        tobiLine.isAcceptableOrUnknown(data['tobi_line']!, _tobiLineMeta),
      );
    }
    if (data.containsKey('graduated')) {
      context.handle(
        _graduatedMeta,
        graduated.isAcceptableOrUnknown(data['graduated']!, _graduatedMeta),
      );
    }
    if (data.containsKey('day_done')) {
      context.handle(
        _dayDoneMeta,
        dayDone.isAcceptableOrUnknown(data['day_done']!, _dayDoneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mode: $RunsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      allKnown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_known'],
      )!,
      setIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_ids'],
      )!,
      cardIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_ids'],
      ),
      maskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mask_level'],
      )!,
      goalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_ms'],
      )!,
      planned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      clockUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clock_us'],
      ),
      scoredMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scored_ms'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      performance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}performance'],
      ),
      tobiMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tobi_ms'],
      ),
      tobiLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tobi_line'],
      ),
      graduated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}graduated'],
      )!,
      dayDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}day_done'],
      )!,
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlayMode, String, String> $convertermode =
      const EnumNameConverter<PlayMode>(PlayMode.values);
}

class RunRow extends DataClass implements Insertable<RunRow> {
  final int id;
  final PlayMode mode;
  final DateTime startedAt;

  /// When it was played to its end, ended early or forfeited.
  final DateTime endedAt;

  /// The practice day it was played on (see `DayWindow`), yyyymmdd.
  final int day;

  /// Played in all-known mode (else journey mode).
  final bool allKnown;

  /// JSON list of FudaSet ids that defined the deck (empty for training;
  /// `PlayConfig.knownDeckId` for free practice's default deck).
  final String setIds;

  /// JSON list of a hand-picked deck's cards; null for a deck of sets.
  final String? cardIds;

  /// 隠し字 level (0 = off).
  final int maskLevel;

  /// The goal time per card when it was played, ms.
  final int goalMs;

  /// Cards it was planned with (more than were swiped when it ended early).
  final int planned;

  /// Played to its last card.
  final bool completed;

  /// First reveal → last swipe, less breaks, µs: the total, or the time so
  /// far of a run ended early. Null when it is no measurement.
  final int? clockUs;

  /// A ranked run's or an exam try's time with its penalties
  /// (`RankedScore.scored`), ms.
  final int? scoredMs;

  /// A ranked run's rating after it and the performance it played at; null
  /// for every other run.
  final double? rating;
  final double? performance;

  /// An exam try's Tobi: his time, and his time as each card went (JSON
  /// list of ms).
  final int? tobiMs;
  final String? tobiLine;

  /// It passed the graduation exam (once ever; developer mode can clear it).
  final bool graduated;

  /// It finished journey mode's set for the day.
  final bool dayDone;
  const RunRow({
    required this.id,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    required this.day,
    required this.allKnown,
    required this.setIds,
    this.cardIds,
    required this.maskLevel,
    required this.goalMs,
    required this.planned,
    required this.completed,
    this.clockUs,
    this.scoredMs,
    this.rating,
    this.performance,
    this.tobiMs,
    this.tobiLine,
    required this.graduated,
    required this.dayDone,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['mode'] = Variable<String>($RunsTable.$convertermode.toSql(mode));
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['day'] = Variable<int>(day);
    map['all_known'] = Variable<bool>(allKnown);
    map['set_ids'] = Variable<String>(setIds);
    if (!nullToAbsent || cardIds != null) {
      map['card_ids'] = Variable<String>(cardIds);
    }
    map['mask_level'] = Variable<int>(maskLevel);
    map['goal_ms'] = Variable<int>(goalMs);
    map['planned'] = Variable<int>(planned);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || clockUs != null) {
      map['clock_us'] = Variable<int>(clockUs);
    }
    if (!nullToAbsent || scoredMs != null) {
      map['scored_ms'] = Variable<int>(scoredMs);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || performance != null) {
      map['performance'] = Variable<double>(performance);
    }
    if (!nullToAbsent || tobiMs != null) {
      map['tobi_ms'] = Variable<int>(tobiMs);
    }
    if (!nullToAbsent || tobiLine != null) {
      map['tobi_line'] = Variable<String>(tobiLine);
    }
    map['graduated'] = Variable<bool>(graduated);
    map['day_done'] = Variable<bool>(dayDone);
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      id: Value(id),
      mode: Value(mode),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      day: Value(day),
      allKnown: Value(allKnown),
      setIds: Value(setIds),
      cardIds: cardIds == null && nullToAbsent
          ? const Value.absent()
          : Value(cardIds),
      maskLevel: Value(maskLevel),
      goalMs: Value(goalMs),
      planned: Value(planned),
      completed: Value(completed),
      clockUs: clockUs == null && nullToAbsent
          ? const Value.absent()
          : Value(clockUs),
      scoredMs: scoredMs == null && nullToAbsent
          ? const Value.absent()
          : Value(scoredMs),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      performance: performance == null && nullToAbsent
          ? const Value.absent()
          : Value(performance),
      tobiMs: tobiMs == null && nullToAbsent
          ? const Value.absent()
          : Value(tobiMs),
      tobiLine: tobiLine == null && nullToAbsent
          ? const Value.absent()
          : Value(tobiLine),
      graduated: Value(graduated),
      dayDone: Value(dayDone),
    );
  }

  factory RunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunRow(
      id: serializer.fromJson<int>(json['id']),
      mode: $RunsTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      day: serializer.fromJson<int>(json['day']),
      allKnown: serializer.fromJson<bool>(json['allKnown']),
      setIds: serializer.fromJson<String>(json['setIds']),
      cardIds: serializer.fromJson<String?>(json['cardIds']),
      maskLevel: serializer.fromJson<int>(json['maskLevel']),
      goalMs: serializer.fromJson<int>(json['goalMs']),
      planned: serializer.fromJson<int>(json['planned']),
      completed: serializer.fromJson<bool>(json['completed']),
      clockUs: serializer.fromJson<int?>(json['clockUs']),
      scoredMs: serializer.fromJson<int?>(json['scoredMs']),
      rating: serializer.fromJson<double?>(json['rating']),
      performance: serializer.fromJson<double?>(json['performance']),
      tobiMs: serializer.fromJson<int?>(json['tobiMs']),
      tobiLine: serializer.fromJson<String?>(json['tobiLine']),
      graduated: serializer.fromJson<bool>(json['graduated']),
      dayDone: serializer.fromJson<bool>(json['dayDone']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mode': serializer.toJson<String>($RunsTable.$convertermode.toJson(mode)),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'day': serializer.toJson<int>(day),
      'allKnown': serializer.toJson<bool>(allKnown),
      'setIds': serializer.toJson<String>(setIds),
      'cardIds': serializer.toJson<String?>(cardIds),
      'maskLevel': serializer.toJson<int>(maskLevel),
      'goalMs': serializer.toJson<int>(goalMs),
      'planned': serializer.toJson<int>(planned),
      'completed': serializer.toJson<bool>(completed),
      'clockUs': serializer.toJson<int?>(clockUs),
      'scoredMs': serializer.toJson<int?>(scoredMs),
      'rating': serializer.toJson<double?>(rating),
      'performance': serializer.toJson<double?>(performance),
      'tobiMs': serializer.toJson<int?>(tobiMs),
      'tobiLine': serializer.toJson<String?>(tobiLine),
      'graduated': serializer.toJson<bool>(graduated),
      'dayDone': serializer.toJson<bool>(dayDone),
    };
  }

  RunRow copyWith({
    int? id,
    PlayMode? mode,
    DateTime? startedAt,
    DateTime? endedAt,
    int? day,
    bool? allKnown,
    String? setIds,
    Value<String?> cardIds = const Value.absent(),
    int? maskLevel,
    int? goalMs,
    int? planned,
    bool? completed,
    Value<int?> clockUs = const Value.absent(),
    Value<int?> scoredMs = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<double?> performance = const Value.absent(),
    Value<int?> tobiMs = const Value.absent(),
    Value<String?> tobiLine = const Value.absent(),
    bool? graduated,
    bool? dayDone,
  }) => RunRow(
    id: id ?? this.id,
    mode: mode ?? this.mode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    day: day ?? this.day,
    allKnown: allKnown ?? this.allKnown,
    setIds: setIds ?? this.setIds,
    cardIds: cardIds.present ? cardIds.value : this.cardIds,
    maskLevel: maskLevel ?? this.maskLevel,
    goalMs: goalMs ?? this.goalMs,
    planned: planned ?? this.planned,
    completed: completed ?? this.completed,
    clockUs: clockUs.present ? clockUs.value : this.clockUs,
    scoredMs: scoredMs.present ? scoredMs.value : this.scoredMs,
    rating: rating.present ? rating.value : this.rating,
    performance: performance.present ? performance.value : this.performance,
    tobiMs: tobiMs.present ? tobiMs.value : this.tobiMs,
    tobiLine: tobiLine.present ? tobiLine.value : this.tobiLine,
    graduated: graduated ?? this.graduated,
    dayDone: dayDone ?? this.dayDone,
  );
  RunRow copyWithCompanion(RunsCompanion data) {
    return RunRow(
      id: data.id.present ? data.id.value : this.id,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      day: data.day.present ? data.day.value : this.day,
      allKnown: data.allKnown.present ? data.allKnown.value : this.allKnown,
      setIds: data.setIds.present ? data.setIds.value : this.setIds,
      cardIds: data.cardIds.present ? data.cardIds.value : this.cardIds,
      maskLevel: data.maskLevel.present ? data.maskLevel.value : this.maskLevel,
      goalMs: data.goalMs.present ? data.goalMs.value : this.goalMs,
      planned: data.planned.present ? data.planned.value : this.planned,
      completed: data.completed.present ? data.completed.value : this.completed,
      clockUs: data.clockUs.present ? data.clockUs.value : this.clockUs,
      scoredMs: data.scoredMs.present ? data.scoredMs.value : this.scoredMs,
      rating: data.rating.present ? data.rating.value : this.rating,
      performance: data.performance.present
          ? data.performance.value
          : this.performance,
      tobiMs: data.tobiMs.present ? data.tobiMs.value : this.tobiMs,
      tobiLine: data.tobiLine.present ? data.tobiLine.value : this.tobiLine,
      graduated: data.graduated.present ? data.graduated.value : this.graduated,
      dayDone: data.dayDone.present ? data.dayDone.value : this.dayDone,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunRow(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('day: $day, ')
          ..write('allKnown: $allKnown, ')
          ..write('setIds: $setIds, ')
          ..write('cardIds: $cardIds, ')
          ..write('maskLevel: $maskLevel, ')
          ..write('goalMs: $goalMs, ')
          ..write('planned: $planned, ')
          ..write('completed: $completed, ')
          ..write('clockUs: $clockUs, ')
          ..write('scoredMs: $scoredMs, ')
          ..write('rating: $rating, ')
          ..write('performance: $performance, ')
          ..write('tobiMs: $tobiMs, ')
          ..write('tobiLine: $tobiLine, ')
          ..write('graduated: $graduated, ')
          ..write('dayDone: $dayDone')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mode,
    startedAt,
    endedAt,
    day,
    allKnown,
    setIds,
    cardIds,
    maskLevel,
    goalMs,
    planned,
    completed,
    clockUs,
    scoredMs,
    rating,
    performance,
    tobiMs,
    tobiLine,
    graduated,
    dayDone,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunRow &&
          other.id == this.id &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.day == this.day &&
          other.allKnown == this.allKnown &&
          other.setIds == this.setIds &&
          other.cardIds == this.cardIds &&
          other.maskLevel == this.maskLevel &&
          other.goalMs == this.goalMs &&
          other.planned == this.planned &&
          other.completed == this.completed &&
          other.clockUs == this.clockUs &&
          other.scoredMs == this.scoredMs &&
          other.rating == this.rating &&
          other.performance == this.performance &&
          other.tobiMs == this.tobiMs &&
          other.tobiLine == this.tobiLine &&
          other.graduated == this.graduated &&
          other.dayDone == this.dayDone);
}

class RunsCompanion extends UpdateCompanion<RunRow> {
  final Value<int> id;
  final Value<PlayMode> mode;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> day;
  final Value<bool> allKnown;
  final Value<String> setIds;
  final Value<String?> cardIds;
  final Value<int> maskLevel;
  final Value<int> goalMs;
  final Value<int> planned;
  final Value<bool> completed;
  final Value<int?> clockUs;
  final Value<int?> scoredMs;
  final Value<double?> rating;
  final Value<double?> performance;
  final Value<int?> tobiMs;
  final Value<String?> tobiLine;
  final Value<bool> graduated;
  final Value<bool> dayDone;
  const RunsCompanion({
    this.id = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.day = const Value.absent(),
    this.allKnown = const Value.absent(),
    this.setIds = const Value.absent(),
    this.cardIds = const Value.absent(),
    this.maskLevel = const Value.absent(),
    this.goalMs = const Value.absent(),
    this.planned = const Value.absent(),
    this.completed = const Value.absent(),
    this.clockUs = const Value.absent(),
    this.scoredMs = const Value.absent(),
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.tobiMs = const Value.absent(),
    this.tobiLine = const Value.absent(),
    this.graduated = const Value.absent(),
    this.dayDone = const Value.absent(),
  });
  RunsCompanion.insert({
    this.id = const Value.absent(),
    required PlayMode mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required int day,
    required bool allKnown,
    this.setIds = const Value.absent(),
    this.cardIds = const Value.absent(),
    this.maskLevel = const Value.absent(),
    required int goalMs,
    required int planned,
    required bool completed,
    this.clockUs = const Value.absent(),
    this.scoredMs = const Value.absent(),
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.tobiMs = const Value.absent(),
    this.tobiLine = const Value.absent(),
    this.graduated = const Value.absent(),
    this.dayDone = const Value.absent(),
  }) : mode = Value(mode),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       day = Value(day),
       allKnown = Value(allKnown),
       goalMs = Value(goalMs),
       planned = Value(planned),
       completed = Value(completed);
  static Insertable<RunRow> custom({
    Expression<int>? id,
    Expression<String>? mode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? day,
    Expression<bool>? allKnown,
    Expression<String>? setIds,
    Expression<String>? cardIds,
    Expression<int>? maskLevel,
    Expression<int>? goalMs,
    Expression<int>? planned,
    Expression<bool>? completed,
    Expression<int>? clockUs,
    Expression<int>? scoredMs,
    Expression<double>? rating,
    Expression<double>? performance,
    Expression<int>? tobiMs,
    Expression<String>? tobiLine,
    Expression<bool>? graduated,
    Expression<bool>? dayDone,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (day != null) 'day': day,
      if (allKnown != null) 'all_known': allKnown,
      if (setIds != null) 'set_ids': setIds,
      if (cardIds != null) 'card_ids': cardIds,
      if (maskLevel != null) 'mask_level': maskLevel,
      if (goalMs != null) 'goal_ms': goalMs,
      if (planned != null) 'planned': planned,
      if (completed != null) 'completed': completed,
      if (clockUs != null) 'clock_us': clockUs,
      if (scoredMs != null) 'scored_ms': scoredMs,
      if (rating != null) 'rating': rating,
      if (performance != null) 'performance': performance,
      if (tobiMs != null) 'tobi_ms': tobiMs,
      if (tobiLine != null) 'tobi_line': tobiLine,
      if (graduated != null) 'graduated': graduated,
      if (dayDone != null) 'day_done': dayDone,
    });
  }

  RunsCompanion copyWith({
    Value<int>? id,
    Value<PlayMode>? mode,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? day,
    Value<bool>? allKnown,
    Value<String>? setIds,
    Value<String?>? cardIds,
    Value<int>? maskLevel,
    Value<int>? goalMs,
    Value<int>? planned,
    Value<bool>? completed,
    Value<int?>? clockUs,
    Value<int?>? scoredMs,
    Value<double?>? rating,
    Value<double?>? performance,
    Value<int?>? tobiMs,
    Value<String?>? tobiLine,
    Value<bool>? graduated,
    Value<bool>? dayDone,
  }) {
    return RunsCompanion(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      day: day ?? this.day,
      allKnown: allKnown ?? this.allKnown,
      setIds: setIds ?? this.setIds,
      cardIds: cardIds ?? this.cardIds,
      maskLevel: maskLevel ?? this.maskLevel,
      goalMs: goalMs ?? this.goalMs,
      planned: planned ?? this.planned,
      completed: completed ?? this.completed,
      clockUs: clockUs ?? this.clockUs,
      scoredMs: scoredMs ?? this.scoredMs,
      rating: rating ?? this.rating,
      performance: performance ?? this.performance,
      tobiMs: tobiMs ?? this.tobiMs,
      tobiLine: tobiLine ?? this.tobiLine,
      graduated: graduated ?? this.graduated,
      dayDone: dayDone ?? this.dayDone,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $RunsTable.$convertermode.toSql(mode.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (allKnown.present) {
      map['all_known'] = Variable<bool>(allKnown.value);
    }
    if (setIds.present) {
      map['set_ids'] = Variable<String>(setIds.value);
    }
    if (cardIds.present) {
      map['card_ids'] = Variable<String>(cardIds.value);
    }
    if (maskLevel.present) {
      map['mask_level'] = Variable<int>(maskLevel.value);
    }
    if (goalMs.present) {
      map['goal_ms'] = Variable<int>(goalMs.value);
    }
    if (planned.present) {
      map['planned'] = Variable<int>(planned.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (clockUs.present) {
      map['clock_us'] = Variable<int>(clockUs.value);
    }
    if (scoredMs.present) {
      map['scored_ms'] = Variable<int>(scoredMs.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (performance.present) {
      map['performance'] = Variable<double>(performance.value);
    }
    if (tobiMs.present) {
      map['tobi_ms'] = Variable<int>(tobiMs.value);
    }
    if (tobiLine.present) {
      map['tobi_line'] = Variable<String>(tobiLine.value);
    }
    if (graduated.present) {
      map['graduated'] = Variable<bool>(graduated.value);
    }
    if (dayDone.present) {
      map['day_done'] = Variable<bool>(dayDone.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunsCompanion(')
          ..write('id: $id, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('day: $day, ')
          ..write('allKnown: $allKnown, ')
          ..write('setIds: $setIds, ')
          ..write('cardIds: $cardIds, ')
          ..write('maskLevel: $maskLevel, ')
          ..write('goalMs: $goalMs, ')
          ..write('planned: $planned, ')
          ..write('completed: $completed, ')
          ..write('clockUs: $clockUs, ')
          ..write('scoredMs: $scoredMs, ')
          ..write('rating: $rating, ')
          ..write('performance: $performance, ')
          ..write('tobiMs: $tobiMs, ')
          ..write('tobiLine: $tobiLine, ')
          ..write('graduated: $graduated, ')
          ..write('dayDone: $dayDone')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts
    with TableInfo<$AttemptsTable, AttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<int> runId = GeneratedColumn<int>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES runs (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<int> poemId = GeneratedColumn<int>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invertedMeta = const VerificationMeta(
    'inverted',
  );
  @override
  late final GeneratedColumn<bool> inverted = GeneratedColumn<bool>(
    'inverted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("inverted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _maskLevelMeta = const VerificationMeta(
    'maskLevel',
  );
  @override
  late final GeneratedColumn<int> maskLevel = GeneratedColumn<int>(
    'mask_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Outcome, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Outcome>($AttemptsTable.$converteroutcome);
  static const VerificationMeta _wrongMeta = const VerificationMeta('wrong');
  @override
  late final GeneratedColumn<bool> wrong = GeneratedColumn<bool>(
    'wrong',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wrong" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taintedMeta = const VerificationMeta(
    'tainted',
  );
  @override
  late final GeneratedColumn<bool> tainted = GeneratedColumn<bool>(
    'tainted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tainted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _undoneMeta = const VerificationMeta('undone');
  @override
  late final GeneratedColumn<bool> undone = GeneratedColumn<bool>(
    'undone',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("undone" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deckSizeMeta = const VerificationMeta(
    'deckSize',
  );
  @override
  late final GeneratedColumn<int> deckSize = GeneratedColumn<int>(
    'deck_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revealAtUsMeta = const VerificationMeta(
    'revealAtUs',
  );
  @override
  late final GeneratedColumn<int> revealAtUs = GeneratedColumn<int>(
    'reveal_at_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responseUsMeta = const VerificationMeta(
    'responseUs',
  );
  @override
  late final GeneratedColumn<int> responseUs = GeneratedColumn<int>(
    'response_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commitUsMeta = const VerificationMeta(
    'commitUs',
  );
  @override
  late final GeneratedColumn<int> commitUs = GeneratedColumn<int>(
    'commit_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsRecallMeta = const VerificationMeta(
    'fsrsRecall',
  );
  @override
  late final GeneratedColumn<double> fsrsRecall = GeneratedColumn<double>(
    'fsrs_recall',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<fsrs.State?, String> fsrsState =
      GeneratedColumn<String>(
        'fsrs_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<fsrs.State?>($AttemptsTable.$converterfsrsStaten);
  static const VerificationMeta _fsrsStepMeta = const VerificationMeta(
    'fsrsStep',
  );
  @override
  late final GeneratedColumn<int> fsrsStep = GeneratedColumn<int>(
    'fsrs_step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsStabilityMeta = const VerificationMeta(
    'fsrsStability',
  );
  @override
  late final GeneratedColumn<double> fsrsStability = GeneratedColumn<double>(
    'fsrs_stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsDifficultyMeta = const VerificationMeta(
    'fsrsDifficulty',
  );
  @override
  late final GeneratedColumn<double> fsrsDifficulty = GeneratedColumn<double>(
    'fsrs_difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsDueMeta = const VerificationMeta(
    'fsrsDue',
  );
  @override
  late final GeneratedColumn<DateTime> fsrsDue = GeneratedColumn<DateTime>(
    'fsrs_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    seq,
    poemId,
    inverted,
    maskLevel,
    outcome,
    wrong,
    tainted,
    undone,
    deckSize,
    at,
    revealAtUs,
    responseUs,
    commitUs,
    grade,
    fsrsRecall,
    fsrsState,
    fsrsStep,
    fsrsStability,
    fsrsDifficulty,
    fsrsDue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('poem_id')) {
      context.handle(
        _poemIdMeta,
        poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('inverted')) {
      context.handle(
        _invertedMeta,
        inverted.isAcceptableOrUnknown(data['inverted']!, _invertedMeta),
      );
    } else if (isInserting) {
      context.missing(_invertedMeta);
    }
    if (data.containsKey('mask_level')) {
      context.handle(
        _maskLevelMeta,
        maskLevel.isAcceptableOrUnknown(data['mask_level']!, _maskLevelMeta),
      );
    }
    if (data.containsKey('wrong')) {
      context.handle(
        _wrongMeta,
        wrong.isAcceptableOrUnknown(data['wrong']!, _wrongMeta),
      );
    }
    if (data.containsKey('tainted')) {
      context.handle(
        _taintedMeta,
        tainted.isAcceptableOrUnknown(data['tainted']!, _taintedMeta),
      );
    }
    if (data.containsKey('undone')) {
      context.handle(
        _undoneMeta,
        undone.isAcceptableOrUnknown(data['undone']!, _undoneMeta),
      );
    }
    if (data.containsKey('deck_size')) {
      context.handle(
        _deckSizeMeta,
        deckSize.isAcceptableOrUnknown(data['deck_size']!, _deckSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_deckSizeMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('reveal_at_us')) {
      context.handle(
        _revealAtUsMeta,
        revealAtUs.isAcceptableOrUnknown(
          data['reveal_at_us']!,
          _revealAtUsMeta,
        ),
      );
    }
    if (data.containsKey('response_us')) {
      context.handle(
        _responseUsMeta,
        responseUs.isAcceptableOrUnknown(data['response_us']!, _responseUsMeta),
      );
    } else if (isInserting) {
      context.missing(_responseUsMeta);
    }
    if (data.containsKey('commit_us')) {
      context.handle(
        _commitUsMeta,
        commitUs.isAcceptableOrUnknown(data['commit_us']!, _commitUsMeta),
      );
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('fsrs_recall')) {
      context.handle(
        _fsrsRecallMeta,
        fsrsRecall.isAcceptableOrUnknown(data['fsrs_recall']!, _fsrsRecallMeta),
      );
    }
    if (data.containsKey('fsrs_step')) {
      context.handle(
        _fsrsStepMeta,
        fsrsStep.isAcceptableOrUnknown(data['fsrs_step']!, _fsrsStepMeta),
      );
    }
    if (data.containsKey('fsrs_stability')) {
      context.handle(
        _fsrsStabilityMeta,
        fsrsStability.isAcceptableOrUnknown(
          data['fsrs_stability']!,
          _fsrsStabilityMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_difficulty')) {
      context.handle(
        _fsrsDifficultyMeta,
        fsrsDifficulty.isAcceptableOrUnknown(
          data['fsrs_difficulty']!,
          _fsrsDifficultyMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_due')) {
      context.handle(
        _fsrsDueMeta,
        fsrsDue.isAcceptableOrUnknown(data['fsrs_due']!, _fsrsDueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      poemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}poem_id'],
      )!,
      inverted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}inverted'],
      )!,
      maskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mask_level'],
      )!,
      outcome: $AttemptsTable.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        )!,
      ),
      wrong: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wrong'],
      )!,
      tainted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tainted'],
      )!,
      undone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}undone'],
      )!,
      deckSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deck_size'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      revealAtUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reveal_at_us'],
      ),
      responseUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_us'],
      )!,
      commitUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}commit_us'],
      ),
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      ),
      fsrsRecall: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_recall'],
      ),
      fsrsState: $AttemptsTable.$converterfsrsStaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fsrs_state'],
        ),
      ),
      fsrsStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fsrs_step'],
      ),
      fsrsStability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_stability'],
      ),
      fsrsDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_difficulty'],
      ),
      fsrsDue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fsrs_due'],
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Outcome, String, String> $converteroutcome =
      const EnumNameConverter<Outcome>(Outcome.values);
  static JsonTypeConverter2<fsrs.State, String, String> $converterfsrsState =
      const EnumNameConverter<fsrs.State>(fsrs.State.values);
  static JsonTypeConverter2<fsrs.State?, String?, String?>
  $converterfsrsStaten = JsonTypeConverter2.asNullable($converterfsrsState);
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  final int id;
  final int runId;

  /// Order within the run.
  final int seq;
  final int poemId;
  final bool inverted;

  /// The run's 隠し字 level when the card had kana hidden, else 0.
  final int maskLevel;
  final Outcome outcome;

  /// Marked wrong afterwards (kimariji chip tap or ひとつ前).
  final bool wrong;

  /// The time is not a clean measurement (see `Attempt.tainted`).
  final bool tainted;

  /// Taken back with ひとつ前 (it counts as a miss).
  final bool undone;

  /// The run's queue length at the swipe.
  final int deckSize;

  /// Wall-clock time of the swipe.
  final DateTime at;

  /// The card's reveal, µs after the run's first reveal (breaks included);
  /// null for a swipe from before it was kept.
  final int? revealAtUs;

  /// Reveal → response (the touch that swiped it), µs, as measured.
  final int responseUs;

  /// Reveal → the swipe let go, µs; null like [revealAtUs].
  final int? commitUs;

  /// The FSRS grade it was given (1–4); null when it was no review. The
  /// fsrs columns are null with it.
  final int? grade;

  /// FSRS's chance of recall just before the review; null for a card's
  /// first.
  final double? fsrsRecall;

  /// The card's FSRS state after the review.
  final fsrs.State? fsrsState;
  final int? fsrsStep;
  final double? fsrsStability;
  final double? fsrsDifficulty;
  final DateTime? fsrsDue;
  const AttemptRow({
    required this.id,
    required this.runId,
    required this.seq,
    required this.poemId,
    required this.inverted,
    required this.maskLevel,
    required this.outcome,
    required this.wrong,
    required this.tainted,
    required this.undone,
    required this.deckSize,
    required this.at,
    this.revealAtUs,
    required this.responseUs,
    this.commitUs,
    this.grade,
    this.fsrsRecall,
    this.fsrsState,
    this.fsrsStep,
    this.fsrsStability,
    this.fsrsDifficulty,
    this.fsrsDue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<int>(runId);
    map['seq'] = Variable<int>(seq);
    map['poem_id'] = Variable<int>(poemId);
    map['inverted'] = Variable<bool>(inverted);
    map['mask_level'] = Variable<int>(maskLevel);
    {
      map['outcome'] = Variable<String>(
        $AttemptsTable.$converteroutcome.toSql(outcome),
      );
    }
    map['wrong'] = Variable<bool>(wrong);
    map['tainted'] = Variable<bool>(tainted);
    map['undone'] = Variable<bool>(undone);
    map['deck_size'] = Variable<int>(deckSize);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || revealAtUs != null) {
      map['reveal_at_us'] = Variable<int>(revealAtUs);
    }
    map['response_us'] = Variable<int>(responseUs);
    if (!nullToAbsent || commitUs != null) {
      map['commit_us'] = Variable<int>(commitUs);
    }
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<int>(grade);
    }
    if (!nullToAbsent || fsrsRecall != null) {
      map['fsrs_recall'] = Variable<double>(fsrsRecall);
    }
    if (!nullToAbsent || fsrsState != null) {
      map['fsrs_state'] = Variable<String>(
        $AttemptsTable.$converterfsrsStaten.toSql(fsrsState),
      );
    }
    if (!nullToAbsent || fsrsStep != null) {
      map['fsrs_step'] = Variable<int>(fsrsStep);
    }
    if (!nullToAbsent || fsrsStability != null) {
      map['fsrs_stability'] = Variable<double>(fsrsStability);
    }
    if (!nullToAbsent || fsrsDifficulty != null) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty);
    }
    if (!nullToAbsent || fsrsDue != null) {
      map['fsrs_due'] = Variable<DateTime>(fsrsDue);
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      runId: Value(runId),
      seq: Value(seq),
      poemId: Value(poemId),
      inverted: Value(inverted),
      maskLevel: Value(maskLevel),
      outcome: Value(outcome),
      wrong: Value(wrong),
      tainted: Value(tainted),
      undone: Value(undone),
      deckSize: Value(deckSize),
      at: Value(at),
      revealAtUs: revealAtUs == null && nullToAbsent
          ? const Value.absent()
          : Value(revealAtUs),
      responseUs: Value(responseUs),
      commitUs: commitUs == null && nullToAbsent
          ? const Value.absent()
          : Value(commitUs),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
      fsrsRecall: fsrsRecall == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsRecall),
      fsrsState: fsrsState == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsState),
      fsrsStep: fsrsStep == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsStep),
      fsrsStability: fsrsStability == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsStability),
      fsrsDifficulty: fsrsDifficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsDifficulty),
      fsrsDue: fsrsDue == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsDue),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<int>(json['runId']),
      seq: serializer.fromJson<int>(json['seq']),
      poemId: serializer.fromJson<int>(json['poemId']),
      inverted: serializer.fromJson<bool>(json['inverted']),
      maskLevel: serializer.fromJson<int>(json['maskLevel']),
      outcome: $AttemptsTable.$converteroutcome.fromJson(
        serializer.fromJson<String>(json['outcome']),
      ),
      wrong: serializer.fromJson<bool>(json['wrong']),
      tainted: serializer.fromJson<bool>(json['tainted']),
      undone: serializer.fromJson<bool>(json['undone']),
      deckSize: serializer.fromJson<int>(json['deckSize']),
      at: serializer.fromJson<DateTime>(json['at']),
      revealAtUs: serializer.fromJson<int?>(json['revealAtUs']),
      responseUs: serializer.fromJson<int>(json['responseUs']),
      commitUs: serializer.fromJson<int?>(json['commitUs']),
      grade: serializer.fromJson<int?>(json['grade']),
      fsrsRecall: serializer.fromJson<double?>(json['fsrsRecall']),
      fsrsState: $AttemptsTable.$converterfsrsStaten.fromJson(
        serializer.fromJson<String?>(json['fsrsState']),
      ),
      fsrsStep: serializer.fromJson<int?>(json['fsrsStep']),
      fsrsStability: serializer.fromJson<double?>(json['fsrsStability']),
      fsrsDifficulty: serializer.fromJson<double?>(json['fsrsDifficulty']),
      fsrsDue: serializer.fromJson<DateTime?>(json['fsrsDue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<int>(runId),
      'seq': serializer.toJson<int>(seq),
      'poemId': serializer.toJson<int>(poemId),
      'inverted': serializer.toJson<bool>(inverted),
      'maskLevel': serializer.toJson<int>(maskLevel),
      'outcome': serializer.toJson<String>(
        $AttemptsTable.$converteroutcome.toJson(outcome),
      ),
      'wrong': serializer.toJson<bool>(wrong),
      'tainted': serializer.toJson<bool>(tainted),
      'undone': serializer.toJson<bool>(undone),
      'deckSize': serializer.toJson<int>(deckSize),
      'at': serializer.toJson<DateTime>(at),
      'revealAtUs': serializer.toJson<int?>(revealAtUs),
      'responseUs': serializer.toJson<int>(responseUs),
      'commitUs': serializer.toJson<int?>(commitUs),
      'grade': serializer.toJson<int?>(grade),
      'fsrsRecall': serializer.toJson<double?>(fsrsRecall),
      'fsrsState': serializer.toJson<String?>(
        $AttemptsTable.$converterfsrsStaten.toJson(fsrsState),
      ),
      'fsrsStep': serializer.toJson<int?>(fsrsStep),
      'fsrsStability': serializer.toJson<double?>(fsrsStability),
      'fsrsDifficulty': serializer.toJson<double?>(fsrsDifficulty),
      'fsrsDue': serializer.toJson<DateTime?>(fsrsDue),
    };
  }

  AttemptRow copyWith({
    int? id,
    int? runId,
    int? seq,
    int? poemId,
    bool? inverted,
    int? maskLevel,
    Outcome? outcome,
    bool? wrong,
    bool? tainted,
    bool? undone,
    int? deckSize,
    DateTime? at,
    Value<int?> revealAtUs = const Value.absent(),
    int? responseUs,
    Value<int?> commitUs = const Value.absent(),
    Value<int?> grade = const Value.absent(),
    Value<double?> fsrsRecall = const Value.absent(),
    Value<fsrs.State?> fsrsState = const Value.absent(),
    Value<int?> fsrsStep = const Value.absent(),
    Value<double?> fsrsStability = const Value.absent(),
    Value<double?> fsrsDifficulty = const Value.absent(),
    Value<DateTime?> fsrsDue = const Value.absent(),
  }) => AttemptRow(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    seq: seq ?? this.seq,
    poemId: poemId ?? this.poemId,
    inverted: inverted ?? this.inverted,
    maskLevel: maskLevel ?? this.maskLevel,
    outcome: outcome ?? this.outcome,
    wrong: wrong ?? this.wrong,
    tainted: tainted ?? this.tainted,
    undone: undone ?? this.undone,
    deckSize: deckSize ?? this.deckSize,
    at: at ?? this.at,
    revealAtUs: revealAtUs.present ? revealAtUs.value : this.revealAtUs,
    responseUs: responseUs ?? this.responseUs,
    commitUs: commitUs.present ? commitUs.value : this.commitUs,
    grade: grade.present ? grade.value : this.grade,
    fsrsRecall: fsrsRecall.present ? fsrsRecall.value : this.fsrsRecall,
    fsrsState: fsrsState.present ? fsrsState.value : this.fsrsState,
    fsrsStep: fsrsStep.present ? fsrsStep.value : this.fsrsStep,
    fsrsStability: fsrsStability.present
        ? fsrsStability.value
        : this.fsrsStability,
    fsrsDifficulty: fsrsDifficulty.present
        ? fsrsDifficulty.value
        : this.fsrsDifficulty,
    fsrsDue: fsrsDue.present ? fsrsDue.value : this.fsrsDue,
  );
  AttemptRow copyWithCompanion(AttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      seq: data.seq.present ? data.seq.value : this.seq,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      inverted: data.inverted.present ? data.inverted.value : this.inverted,
      maskLevel: data.maskLevel.present ? data.maskLevel.value : this.maskLevel,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      wrong: data.wrong.present ? data.wrong.value : this.wrong,
      tainted: data.tainted.present ? data.tainted.value : this.tainted,
      undone: data.undone.present ? data.undone.value : this.undone,
      deckSize: data.deckSize.present ? data.deckSize.value : this.deckSize,
      at: data.at.present ? data.at.value : this.at,
      revealAtUs: data.revealAtUs.present
          ? data.revealAtUs.value
          : this.revealAtUs,
      responseUs: data.responseUs.present
          ? data.responseUs.value
          : this.responseUs,
      commitUs: data.commitUs.present ? data.commitUs.value : this.commitUs,
      grade: data.grade.present ? data.grade.value : this.grade,
      fsrsRecall: data.fsrsRecall.present
          ? data.fsrsRecall.value
          : this.fsrsRecall,
      fsrsState: data.fsrsState.present ? data.fsrsState.value : this.fsrsState,
      fsrsStep: data.fsrsStep.present ? data.fsrsStep.value : this.fsrsStep,
      fsrsStability: data.fsrsStability.present
          ? data.fsrsStability.value
          : this.fsrsStability,
      fsrsDifficulty: data.fsrsDifficulty.present
          ? data.fsrsDifficulty.value
          : this.fsrsDifficulty,
      fsrsDue: data.fsrsDue.present ? data.fsrsDue.value : this.fsrsDue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('seq: $seq, ')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('maskLevel: $maskLevel, ')
          ..write('outcome: $outcome, ')
          ..write('wrong: $wrong, ')
          ..write('tainted: $tainted, ')
          ..write('undone: $undone, ')
          ..write('deckSize: $deckSize, ')
          ..write('at: $at, ')
          ..write('revealAtUs: $revealAtUs, ')
          ..write('responseUs: $responseUs, ')
          ..write('commitUs: $commitUs, ')
          ..write('grade: $grade, ')
          ..write('fsrsRecall: $fsrsRecall, ')
          ..write('fsrsState: $fsrsState, ')
          ..write('fsrsStep: $fsrsStep, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsDue: $fsrsDue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    runId,
    seq,
    poemId,
    inverted,
    maskLevel,
    outcome,
    wrong,
    tainted,
    undone,
    deckSize,
    at,
    revealAtUs,
    responseUs,
    commitUs,
    grade,
    fsrsRecall,
    fsrsState,
    fsrsStep,
    fsrsStability,
    fsrsDifficulty,
    fsrsDue,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.seq == this.seq &&
          other.poemId == this.poemId &&
          other.inverted == this.inverted &&
          other.maskLevel == this.maskLevel &&
          other.outcome == this.outcome &&
          other.wrong == this.wrong &&
          other.tainted == this.tainted &&
          other.undone == this.undone &&
          other.deckSize == this.deckSize &&
          other.at == this.at &&
          other.revealAtUs == this.revealAtUs &&
          other.responseUs == this.responseUs &&
          other.commitUs == this.commitUs &&
          other.grade == this.grade &&
          other.fsrsRecall == this.fsrsRecall &&
          other.fsrsState == this.fsrsState &&
          other.fsrsStep == this.fsrsStep &&
          other.fsrsStability == this.fsrsStability &&
          other.fsrsDifficulty == this.fsrsDifficulty &&
          other.fsrsDue == this.fsrsDue);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<int> id;
  final Value<int> runId;
  final Value<int> seq;
  final Value<int> poemId;
  final Value<bool> inverted;
  final Value<int> maskLevel;
  final Value<Outcome> outcome;
  final Value<bool> wrong;
  final Value<bool> tainted;
  final Value<bool> undone;
  final Value<int> deckSize;
  final Value<DateTime> at;
  final Value<int?> revealAtUs;
  final Value<int> responseUs;
  final Value<int?> commitUs;
  final Value<int?> grade;
  final Value<double?> fsrsRecall;
  final Value<fsrs.State?> fsrsState;
  final Value<int?> fsrsStep;
  final Value<double?> fsrsStability;
  final Value<double?> fsrsDifficulty;
  final Value<DateTime?> fsrsDue;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.seq = const Value.absent(),
    this.poemId = const Value.absent(),
    this.inverted = const Value.absent(),
    this.maskLevel = const Value.absent(),
    this.outcome = const Value.absent(),
    this.wrong = const Value.absent(),
    this.tainted = const Value.absent(),
    this.undone = const Value.absent(),
    this.deckSize = const Value.absent(),
    this.at = const Value.absent(),
    this.revealAtUs = const Value.absent(),
    this.responseUs = const Value.absent(),
    this.commitUs = const Value.absent(),
    this.grade = const Value.absent(),
    this.fsrsRecall = const Value.absent(),
    this.fsrsState = const Value.absent(),
    this.fsrsStep = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsDue = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int runId,
    required int seq,
    required int poemId,
    required bool inverted,
    this.maskLevel = const Value.absent(),
    required Outcome outcome,
    this.wrong = const Value.absent(),
    this.tainted = const Value.absent(),
    this.undone = const Value.absent(),
    required int deckSize,
    required DateTime at,
    this.revealAtUs = const Value.absent(),
    required int responseUs,
    this.commitUs = const Value.absent(),
    this.grade = const Value.absent(),
    this.fsrsRecall = const Value.absent(),
    this.fsrsState = const Value.absent(),
    this.fsrsStep = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsDue = const Value.absent(),
  }) : runId = Value(runId),
       seq = Value(seq),
       poemId = Value(poemId),
       inverted = Value(inverted),
       outcome = Value(outcome),
       deckSize = Value(deckSize),
       at = Value(at),
       responseUs = Value(responseUs);
  static Insertable<AttemptRow> custom({
    Expression<int>? id,
    Expression<int>? runId,
    Expression<int>? seq,
    Expression<int>? poemId,
    Expression<bool>? inverted,
    Expression<int>? maskLevel,
    Expression<String>? outcome,
    Expression<bool>? wrong,
    Expression<bool>? tainted,
    Expression<bool>? undone,
    Expression<int>? deckSize,
    Expression<DateTime>? at,
    Expression<int>? revealAtUs,
    Expression<int>? responseUs,
    Expression<int>? commitUs,
    Expression<int>? grade,
    Expression<double>? fsrsRecall,
    Expression<String>? fsrsState,
    Expression<int>? fsrsStep,
    Expression<double>? fsrsStability,
    Expression<double>? fsrsDifficulty,
    Expression<DateTime>? fsrsDue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (seq != null) 'seq': seq,
      if (poemId != null) 'poem_id': poemId,
      if (inverted != null) 'inverted': inverted,
      if (maskLevel != null) 'mask_level': maskLevel,
      if (outcome != null) 'outcome': outcome,
      if (wrong != null) 'wrong': wrong,
      if (tainted != null) 'tainted': tainted,
      if (undone != null) 'undone': undone,
      if (deckSize != null) 'deck_size': deckSize,
      if (at != null) 'at': at,
      if (revealAtUs != null) 'reveal_at_us': revealAtUs,
      if (responseUs != null) 'response_us': responseUs,
      if (commitUs != null) 'commit_us': commitUs,
      if (grade != null) 'grade': grade,
      if (fsrsRecall != null) 'fsrs_recall': fsrsRecall,
      if (fsrsState != null) 'fsrs_state': fsrsState,
      if (fsrsStep != null) 'fsrs_step': fsrsStep,
      if (fsrsStability != null) 'fsrs_stability': fsrsStability,
      if (fsrsDifficulty != null) 'fsrs_difficulty': fsrsDifficulty,
      if (fsrsDue != null) 'fsrs_due': fsrsDue,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? runId,
    Value<int>? seq,
    Value<int>? poemId,
    Value<bool>? inverted,
    Value<int>? maskLevel,
    Value<Outcome>? outcome,
    Value<bool>? wrong,
    Value<bool>? tainted,
    Value<bool>? undone,
    Value<int>? deckSize,
    Value<DateTime>? at,
    Value<int?>? revealAtUs,
    Value<int>? responseUs,
    Value<int?>? commitUs,
    Value<int?>? grade,
    Value<double?>? fsrsRecall,
    Value<fsrs.State?>? fsrsState,
    Value<int?>? fsrsStep,
    Value<double?>? fsrsStability,
    Value<double?>? fsrsDifficulty,
    Value<DateTime?>? fsrsDue,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      seq: seq ?? this.seq,
      poemId: poemId ?? this.poemId,
      inverted: inverted ?? this.inverted,
      maskLevel: maskLevel ?? this.maskLevel,
      outcome: outcome ?? this.outcome,
      wrong: wrong ?? this.wrong,
      tainted: tainted ?? this.tainted,
      undone: undone ?? this.undone,
      deckSize: deckSize ?? this.deckSize,
      at: at ?? this.at,
      revealAtUs: revealAtUs ?? this.revealAtUs,
      responseUs: responseUs ?? this.responseUs,
      commitUs: commitUs ?? this.commitUs,
      grade: grade ?? this.grade,
      fsrsRecall: fsrsRecall ?? this.fsrsRecall,
      fsrsState: fsrsState ?? this.fsrsState,
      fsrsStep: fsrsStep ?? this.fsrsStep,
      fsrsStability: fsrsStability ?? this.fsrsStability,
      fsrsDifficulty: fsrsDifficulty ?? this.fsrsDifficulty,
      fsrsDue: fsrsDue ?? this.fsrsDue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<int>(runId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (poemId.present) {
      map['poem_id'] = Variable<int>(poemId.value);
    }
    if (inverted.present) {
      map['inverted'] = Variable<bool>(inverted.value);
    }
    if (maskLevel.present) {
      map['mask_level'] = Variable<int>(maskLevel.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $AttemptsTable.$converteroutcome.toSql(outcome.value),
      );
    }
    if (wrong.present) {
      map['wrong'] = Variable<bool>(wrong.value);
    }
    if (tainted.present) {
      map['tainted'] = Variable<bool>(tainted.value);
    }
    if (undone.present) {
      map['undone'] = Variable<bool>(undone.value);
    }
    if (deckSize.present) {
      map['deck_size'] = Variable<int>(deckSize.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (revealAtUs.present) {
      map['reveal_at_us'] = Variable<int>(revealAtUs.value);
    }
    if (responseUs.present) {
      map['response_us'] = Variable<int>(responseUs.value);
    }
    if (commitUs.present) {
      map['commit_us'] = Variable<int>(commitUs.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (fsrsRecall.present) {
      map['fsrs_recall'] = Variable<double>(fsrsRecall.value);
    }
    if (fsrsState.present) {
      map['fsrs_state'] = Variable<String>(
        $AttemptsTable.$converterfsrsStaten.toSql(fsrsState.value),
      );
    }
    if (fsrsStep.present) {
      map['fsrs_step'] = Variable<int>(fsrsStep.value);
    }
    if (fsrsStability.present) {
      map['fsrs_stability'] = Variable<double>(fsrsStability.value);
    }
    if (fsrsDifficulty.present) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty.value);
    }
    if (fsrsDue.present) {
      map['fsrs_due'] = Variable<DateTime>(fsrsDue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('seq: $seq, ')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('maskLevel: $maskLevel, ')
          ..write('outcome: $outcome, ')
          ..write('wrong: $wrong, ')
          ..write('tainted: $tainted, ')
          ..write('undone: $undone, ')
          ..write('deckSize: $deckSize, ')
          ..write('at: $at, ')
          ..write('revealAtUs: $revealAtUs, ')
          ..write('responseUs: $responseUs, ')
          ..write('commitUs: $commitUs, ')
          ..write('grade: $grade, ')
          ..write('fsrsRecall: $fsrsRecall, ')
          ..write('fsrsState: $fsrsState, ')
          ..write('fsrsStep: $fsrsStep, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsDue: $fsrsDue')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, ItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<int> poemId = GeneratedColumn<int>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invertedMeta = const VerificationMeta(
    'inverted',
  );
  @override
  late final GeneratedColumn<bool> inverted = GeneratedColumn<bool>(
    'inverted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("inverted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _unlockedMeta = const VerificationMeta(
    'unlocked',
  );
  @override
  late final GeneratedColumn<bool> unlocked = GeneratedColumn<bool>(
    'unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<fsrs.State?, String> fsrsState =
      GeneratedColumn<String>(
        'fsrs_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<fsrs.State?>($ItemsTable.$converterfsrsStaten);
  static const VerificationMeta _fsrsStepMeta = const VerificationMeta(
    'fsrsStep',
  );
  @override
  late final GeneratedColumn<int> fsrsStep = GeneratedColumn<int>(
    'fsrs_step',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsStabilityMeta = const VerificationMeta(
    'fsrsStability',
  );
  @override
  late final GeneratedColumn<double> fsrsStability = GeneratedColumn<double>(
    'fsrs_stability',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsDifficultyMeta = const VerificationMeta(
    'fsrsDifficulty',
  );
  @override
  late final GeneratedColumn<double> fsrsDifficulty = GeneratedColumn<double>(
    'fsrs_difficulty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsDueMeta = const VerificationMeta(
    'fsrsDue',
  );
  @override
  late final GeneratedColumn<DateTime> fsrsDue = GeneratedColumn<DateTime>(
    'fsrs_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsLastReviewMeta = const VerificationMeta(
    'fsrsLastReview',
  );
  @override
  late final GeneratedColumn<DateTime> fsrsLastReview =
      GeneratedColumn<DateTime>(
        'fsrs_last_review',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    poemId,
    inverted,
    unlocked,
    unlockedAt,
    fsrsState,
    fsrsStep,
    fsrsStability,
    fsrsDifficulty,
    fsrsDue,
    fsrsLastReview,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('poem_id')) {
      context.handle(
        _poemIdMeta,
        poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('inverted')) {
      context.handle(
        _invertedMeta,
        inverted.isAcceptableOrUnknown(data['inverted']!, _invertedMeta),
      );
    } else if (isInserting) {
      context.missing(_invertedMeta);
    }
    if (data.containsKey('unlocked')) {
      context.handle(
        _unlockedMeta,
        unlocked.isAcceptableOrUnknown(data['unlocked']!, _unlockedMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    }
    if (data.containsKey('fsrs_step')) {
      context.handle(
        _fsrsStepMeta,
        fsrsStep.isAcceptableOrUnknown(data['fsrs_step']!, _fsrsStepMeta),
      );
    }
    if (data.containsKey('fsrs_stability')) {
      context.handle(
        _fsrsStabilityMeta,
        fsrsStability.isAcceptableOrUnknown(
          data['fsrs_stability']!,
          _fsrsStabilityMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_difficulty')) {
      context.handle(
        _fsrsDifficultyMeta,
        fsrsDifficulty.isAcceptableOrUnknown(
          data['fsrs_difficulty']!,
          _fsrsDifficultyMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_due')) {
      context.handle(
        _fsrsDueMeta,
        fsrsDue.isAcceptableOrUnknown(data['fsrs_due']!, _fsrsDueMeta),
      );
    }
    if (data.containsKey('fsrs_last_review')) {
      context.handle(
        _fsrsLastReviewMeta,
        fsrsLastReview.isAcceptableOrUnknown(
          data['fsrs_last_review']!,
          _fsrsLastReviewMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {poemId, inverted};
  @override
  ItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemRow(
      poemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}poem_id'],
      )!,
      inverted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}inverted'],
      )!,
      unlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unlocked'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      ),
      fsrsState: $ItemsTable.$converterfsrsStaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fsrs_state'],
        ),
      ),
      fsrsStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fsrs_step'],
      ),
      fsrsStability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_stability'],
      ),
      fsrsDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fsrs_difficulty'],
      ),
      fsrsDue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fsrs_due'],
      ),
      fsrsLastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fsrs_last_review'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<fsrs.State, String, String> $converterfsrsState =
      const EnumNameConverter<fsrs.State>(fsrs.State.values);
  static JsonTypeConverter2<fsrs.State?, String?, String?>
  $converterfsrsStaten = JsonTypeConverter2.asNullable($converterfsrsState);
}

class ItemRow extends DataClass implements Insertable<ItemRow> {
  final int poemId;
  final bool inverted;
  final bool unlocked;
  final DateTime? unlockedAt;

  /// Null until its first review, with the other fsrs columns.
  final fsrs.State? fsrsState;
  final int? fsrsStep;
  final double? fsrsStability;
  final double? fsrsDifficulty;
  final DateTime? fsrsDue;
  final DateTime? fsrsLastReview;
  const ItemRow({
    required this.poemId,
    required this.inverted,
    required this.unlocked,
    this.unlockedAt,
    this.fsrsState,
    this.fsrsStep,
    this.fsrsStability,
    this.fsrsDifficulty,
    this.fsrsDue,
    this.fsrsLastReview,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['poem_id'] = Variable<int>(poemId);
    map['inverted'] = Variable<bool>(inverted);
    map['unlocked'] = Variable<bool>(unlocked);
    if (!nullToAbsent || unlockedAt != null) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    }
    if (!nullToAbsent || fsrsState != null) {
      map['fsrs_state'] = Variable<String>(
        $ItemsTable.$converterfsrsStaten.toSql(fsrsState),
      );
    }
    if (!nullToAbsent || fsrsStep != null) {
      map['fsrs_step'] = Variable<int>(fsrsStep);
    }
    if (!nullToAbsent || fsrsStability != null) {
      map['fsrs_stability'] = Variable<double>(fsrsStability);
    }
    if (!nullToAbsent || fsrsDifficulty != null) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty);
    }
    if (!nullToAbsent || fsrsDue != null) {
      map['fsrs_due'] = Variable<DateTime>(fsrsDue);
    }
    if (!nullToAbsent || fsrsLastReview != null) {
      map['fsrs_last_review'] = Variable<DateTime>(fsrsLastReview);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      poemId: Value(poemId),
      inverted: Value(inverted),
      unlocked: Value(unlocked),
      unlockedAt: unlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAt),
      fsrsState: fsrsState == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsState),
      fsrsStep: fsrsStep == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsStep),
      fsrsStability: fsrsStability == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsStability),
      fsrsDifficulty: fsrsDifficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsDifficulty),
      fsrsDue: fsrsDue == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsDue),
      fsrsLastReview: fsrsLastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsLastReview),
    );
  }

  factory ItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemRow(
      poemId: serializer.fromJson<int>(json['poemId']),
      inverted: serializer.fromJson<bool>(json['inverted']),
      unlocked: serializer.fromJson<bool>(json['unlocked']),
      unlockedAt: serializer.fromJson<DateTime?>(json['unlockedAt']),
      fsrsState: $ItemsTable.$converterfsrsStaten.fromJson(
        serializer.fromJson<String?>(json['fsrsState']),
      ),
      fsrsStep: serializer.fromJson<int?>(json['fsrsStep']),
      fsrsStability: serializer.fromJson<double?>(json['fsrsStability']),
      fsrsDifficulty: serializer.fromJson<double?>(json['fsrsDifficulty']),
      fsrsDue: serializer.fromJson<DateTime?>(json['fsrsDue']),
      fsrsLastReview: serializer.fromJson<DateTime?>(json['fsrsLastReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'poemId': serializer.toJson<int>(poemId),
      'inverted': serializer.toJson<bool>(inverted),
      'unlocked': serializer.toJson<bool>(unlocked),
      'unlockedAt': serializer.toJson<DateTime?>(unlockedAt),
      'fsrsState': serializer.toJson<String?>(
        $ItemsTable.$converterfsrsStaten.toJson(fsrsState),
      ),
      'fsrsStep': serializer.toJson<int?>(fsrsStep),
      'fsrsStability': serializer.toJson<double?>(fsrsStability),
      'fsrsDifficulty': serializer.toJson<double?>(fsrsDifficulty),
      'fsrsDue': serializer.toJson<DateTime?>(fsrsDue),
      'fsrsLastReview': serializer.toJson<DateTime?>(fsrsLastReview),
    };
  }

  ItemRow copyWith({
    int? poemId,
    bool? inverted,
    bool? unlocked,
    Value<DateTime?> unlockedAt = const Value.absent(),
    Value<fsrs.State?> fsrsState = const Value.absent(),
    Value<int?> fsrsStep = const Value.absent(),
    Value<double?> fsrsStability = const Value.absent(),
    Value<double?> fsrsDifficulty = const Value.absent(),
    Value<DateTime?> fsrsDue = const Value.absent(),
    Value<DateTime?> fsrsLastReview = const Value.absent(),
  }) => ItemRow(
    poemId: poemId ?? this.poemId,
    inverted: inverted ?? this.inverted,
    unlocked: unlocked ?? this.unlocked,
    unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
    fsrsState: fsrsState.present ? fsrsState.value : this.fsrsState,
    fsrsStep: fsrsStep.present ? fsrsStep.value : this.fsrsStep,
    fsrsStability: fsrsStability.present
        ? fsrsStability.value
        : this.fsrsStability,
    fsrsDifficulty: fsrsDifficulty.present
        ? fsrsDifficulty.value
        : this.fsrsDifficulty,
    fsrsDue: fsrsDue.present ? fsrsDue.value : this.fsrsDue,
    fsrsLastReview: fsrsLastReview.present
        ? fsrsLastReview.value
        : this.fsrsLastReview,
  );
  ItemRow copyWithCompanion(ItemsCompanion data) {
    return ItemRow(
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      inverted: data.inverted.present ? data.inverted.value : this.inverted,
      unlocked: data.unlocked.present ? data.unlocked.value : this.unlocked,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      fsrsState: data.fsrsState.present ? data.fsrsState.value : this.fsrsState,
      fsrsStep: data.fsrsStep.present ? data.fsrsStep.value : this.fsrsStep,
      fsrsStability: data.fsrsStability.present
          ? data.fsrsStability.value
          : this.fsrsStability,
      fsrsDifficulty: data.fsrsDifficulty.present
          ? data.fsrsDifficulty.value
          : this.fsrsDifficulty,
      fsrsDue: data.fsrsDue.present ? data.fsrsDue.value : this.fsrsDue,
      fsrsLastReview: data.fsrsLastReview.present
          ? data.fsrsLastReview.value
          : this.fsrsLastReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemRow(')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('unlocked: $unlocked, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('fsrsState: $fsrsState, ')
          ..write('fsrsStep: $fsrsStep, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsDue: $fsrsDue, ')
          ..write('fsrsLastReview: $fsrsLastReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    poemId,
    inverted,
    unlocked,
    unlockedAt,
    fsrsState,
    fsrsStep,
    fsrsStability,
    fsrsDifficulty,
    fsrsDue,
    fsrsLastReview,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemRow &&
          other.poemId == this.poemId &&
          other.inverted == this.inverted &&
          other.unlocked == this.unlocked &&
          other.unlockedAt == this.unlockedAt &&
          other.fsrsState == this.fsrsState &&
          other.fsrsStep == this.fsrsStep &&
          other.fsrsStability == this.fsrsStability &&
          other.fsrsDifficulty == this.fsrsDifficulty &&
          other.fsrsDue == this.fsrsDue &&
          other.fsrsLastReview == this.fsrsLastReview);
}

class ItemsCompanion extends UpdateCompanion<ItemRow> {
  final Value<int> poemId;
  final Value<bool> inverted;
  final Value<bool> unlocked;
  final Value<DateTime?> unlockedAt;
  final Value<fsrs.State?> fsrsState;
  final Value<int?> fsrsStep;
  final Value<double?> fsrsStability;
  final Value<double?> fsrsDifficulty;
  final Value<DateTime?> fsrsDue;
  final Value<DateTime?> fsrsLastReview;
  final Value<int> rowid;
  const ItemsCompanion({
    this.poemId = const Value.absent(),
    this.inverted = const Value.absent(),
    this.unlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.fsrsState = const Value.absent(),
    this.fsrsStep = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsDue = const Value.absent(),
    this.fsrsLastReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required int poemId,
    required bool inverted,
    this.unlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.fsrsState = const Value.absent(),
    this.fsrsStep = const Value.absent(),
    this.fsrsStability = const Value.absent(),
    this.fsrsDifficulty = const Value.absent(),
    this.fsrsDue = const Value.absent(),
    this.fsrsLastReview = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : poemId = Value(poemId),
       inverted = Value(inverted);
  static Insertable<ItemRow> custom({
    Expression<int>? poemId,
    Expression<bool>? inverted,
    Expression<bool>? unlocked,
    Expression<DateTime>? unlockedAt,
    Expression<String>? fsrsState,
    Expression<int>? fsrsStep,
    Expression<double>? fsrsStability,
    Expression<double>? fsrsDifficulty,
    Expression<DateTime>? fsrsDue,
    Expression<DateTime>? fsrsLastReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (poemId != null) 'poem_id': poemId,
      if (inverted != null) 'inverted': inverted,
      if (unlocked != null) 'unlocked': unlocked,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (fsrsState != null) 'fsrs_state': fsrsState,
      if (fsrsStep != null) 'fsrs_step': fsrsStep,
      if (fsrsStability != null) 'fsrs_stability': fsrsStability,
      if (fsrsDifficulty != null) 'fsrs_difficulty': fsrsDifficulty,
      if (fsrsDue != null) 'fsrs_due': fsrsDue,
      if (fsrsLastReview != null) 'fsrs_last_review': fsrsLastReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? poemId,
    Value<bool>? inverted,
    Value<bool>? unlocked,
    Value<DateTime?>? unlockedAt,
    Value<fsrs.State?>? fsrsState,
    Value<int?>? fsrsStep,
    Value<double?>? fsrsStability,
    Value<double?>? fsrsDifficulty,
    Value<DateTime?>? fsrsDue,
    Value<DateTime?>? fsrsLastReview,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      poemId: poemId ?? this.poemId,
      inverted: inverted ?? this.inverted,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      fsrsState: fsrsState ?? this.fsrsState,
      fsrsStep: fsrsStep ?? this.fsrsStep,
      fsrsStability: fsrsStability ?? this.fsrsStability,
      fsrsDifficulty: fsrsDifficulty ?? this.fsrsDifficulty,
      fsrsDue: fsrsDue ?? this.fsrsDue,
      fsrsLastReview: fsrsLastReview ?? this.fsrsLastReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (poemId.present) {
      map['poem_id'] = Variable<int>(poemId.value);
    }
    if (inverted.present) {
      map['inverted'] = Variable<bool>(inverted.value);
    }
    if (unlocked.present) {
      map['unlocked'] = Variable<bool>(unlocked.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (fsrsState.present) {
      map['fsrs_state'] = Variable<String>(
        $ItemsTable.$converterfsrsStaten.toSql(fsrsState.value),
      );
    }
    if (fsrsStep.present) {
      map['fsrs_step'] = Variable<int>(fsrsStep.value);
    }
    if (fsrsStability.present) {
      map['fsrs_stability'] = Variable<double>(fsrsStability.value);
    }
    if (fsrsDifficulty.present) {
      map['fsrs_difficulty'] = Variable<double>(fsrsDifficulty.value);
    }
    if (fsrsDue.present) {
      map['fsrs_due'] = Variable<DateTime>(fsrsDue.value);
    }
    if (fsrsLastReview.present) {
      map['fsrs_last_review'] = Variable<DateTime>(fsrsLastReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('unlocked: $unlocked, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('fsrsState: $fsrsState, ')
          ..write('fsrsStep: $fsrsStep, ')
          ..write('fsrsStability: $fsrsStability, ')
          ..write('fsrsDifficulty: $fsrsDifficulty, ')
          ..write('fsrsDue: $fsrsDue, ')
          ..write('fsrsLastReview: $fsrsLastReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IslandCompletionsTable extends IslandCompletions
    with TableInfo<$IslandCompletionsTable, IslandCompletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IslandCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _islandMeta = const VerificationMeta('island');
  @override
  late final GeneratedColumn<int> island = GeneratedColumn<int>(
    'island',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<int> runId = GeneratedColumn<int>(
    'run_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES runs (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [island, at, runId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'island_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<IslandCompletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('island')) {
      context.handle(
        _islandMeta,
        island.isAcceptableOrUnknown(data['island']!, _islandMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {island};
  @override
  IslandCompletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IslandCompletionRow(
      island: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}island'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_id'],
      ),
    );
  }

  @override
  $IslandCompletionsTable createAlias(String alias) {
    return $IslandCompletionsTable(attachedDatabase, alias);
  }
}

class IslandCompletionRow extends DataClass
    implements Insertable<IslandCompletionRow> {
  final int island;
  final DateTime at;

  /// The journey run that completed it (it was celebrated, and earned
  /// experience); null when it was marked without one (in all-known mode,
  /// or by the switch to it).
  final int? runId;
  const IslandCompletionRow({
    required this.island,
    required this.at,
    this.runId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['island'] = Variable<int>(island);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || runId != null) {
      map['run_id'] = Variable<int>(runId);
    }
    return map;
  }

  IslandCompletionsCompanion toCompanion(bool nullToAbsent) {
    return IslandCompletionsCompanion(
      island: Value(island),
      at: Value(at),
      runId: runId == null && nullToAbsent
          ? const Value.absent()
          : Value(runId),
    );
  }

  factory IslandCompletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IslandCompletionRow(
      island: serializer.fromJson<int>(json['island']),
      at: serializer.fromJson<DateTime>(json['at']),
      runId: serializer.fromJson<int?>(json['runId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'island': serializer.toJson<int>(island),
      'at': serializer.toJson<DateTime>(at),
      'runId': serializer.toJson<int?>(runId),
    };
  }

  IslandCompletionRow copyWith({
    int? island,
    DateTime? at,
    Value<int?> runId = const Value.absent(),
  }) => IslandCompletionRow(
    island: island ?? this.island,
    at: at ?? this.at,
    runId: runId.present ? runId.value : this.runId,
  );
  IslandCompletionRow copyWithCompanion(IslandCompletionsCompanion data) {
    return IslandCompletionRow(
      island: data.island.present ? data.island.value : this.island,
      at: data.at.present ? data.at.value : this.at,
      runId: data.runId.present ? data.runId.value : this.runId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IslandCompletionRow(')
          ..write('island: $island, ')
          ..write('at: $at, ')
          ..write('runId: $runId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(island, at, runId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IslandCompletionRow &&
          other.island == this.island &&
          other.at == this.at &&
          other.runId == this.runId);
}

class IslandCompletionsCompanion extends UpdateCompanion<IslandCompletionRow> {
  final Value<int> island;
  final Value<DateTime> at;
  final Value<int?> runId;
  const IslandCompletionsCompanion({
    this.island = const Value.absent(),
    this.at = const Value.absent(),
    this.runId = const Value.absent(),
  });
  IslandCompletionsCompanion.insert({
    this.island = const Value.absent(),
    required DateTime at,
    this.runId = const Value.absent(),
  }) : at = Value(at);
  static Insertable<IslandCompletionRow> custom({
    Expression<int>? island,
    Expression<DateTime>? at,
    Expression<int>? runId,
  }) {
    return RawValuesInsertable({
      if (island != null) 'island': island,
      if (at != null) 'at': at,
      if (runId != null) 'run_id': runId,
    });
  }

  IslandCompletionsCompanion copyWith({
    Value<int>? island,
    Value<DateTime>? at,
    Value<int?>? runId,
  }) {
    return IslandCompletionsCompanion(
      island: island ?? this.island,
      at: at ?? this.at,
      runId: runId ?? this.runId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (island.present) {
      map['island'] = Variable<int>(island.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<int>(runId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IslandCompletionsCompanion(')
          ..write('island: $island, ')
          ..write('at: $at, ')
          ..write('runId: $runId')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SideTripRunsTable extends SideTripRuns
    with TableInfo<$SideTripRunsTable, SideTripRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SideTripRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SideTrip, String> game =
      GeneratedColumn<String>(
        'game',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SideTrip>($SideTripRunsTable.$convertergame);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (day)',
    ),
  );
  static const VerificationMeta _rankedMeta = const VerificationMeta('ranked');
  @override
  late final GeneratedColumn<bool> ranked = GeneratedColumn<bool>(
    'ranked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ranked" IN (0, 1))',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxScoreMeta = const VerificationMeta(
    'maxScore',
  );
  @override
  late final GeneratedColumn<int> maxScore = GeneratedColumn<int>(
    'max_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _performanceMeta = const VerificationMeta(
    'performance',
  );
  @override
  late final GeneratedColumn<double> performance = GeneratedColumn<double>(
    'performance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metaMeta = const VerificationMeta('meta');
  @override
  late final GeneratedColumn<String> meta = GeneratedColumn<String>(
    'meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    game,
    startedAt,
    endedAt,
    day,
    ranked,
    level,
    score,
    maxScore,
    completed,
    rating,
    performance,
    meta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'side_trip_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SideTripRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('ranked')) {
      context.handle(
        _rankedMeta,
        ranked.isAcceptableOrUnknown(data['ranked']!, _rankedMeta),
      );
    } else if (isInserting) {
      context.missing(_rankedMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('max_score')) {
      context.handle(
        _maxScoreMeta,
        maxScore.isAcceptableOrUnknown(data['max_score']!, _maxScoreMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('performance')) {
      context.handle(
        _performanceMeta,
        performance.isAcceptableOrUnknown(
          data['performance']!,
          _performanceMeta,
        ),
      );
    }
    if (data.containsKey('meta')) {
      context.handle(
        _metaMeta,
        meta.isAcceptableOrUnknown(data['meta']!, _metaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SideTripRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SideTripRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      game: $SideTripRunsTable.$convertergame.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}game'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      ranked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ranked'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      maxScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_score'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      performance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}performance'],
      ),
      meta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta'],
      )!,
    );
  }

  @override
  $SideTripRunsTable createAlias(String alias) {
    return $SideTripRunsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SideTrip, String, String> $convertergame =
      const EnumNameConverter<SideTrip>(SideTrip.values);
}

class SideTripRun extends DataClass implements Insertable<SideTripRun> {
  final int id;
  final SideTrip game;
  final DateTime startedAt;
  final DateTime endedAt;

  /// The practice day it was played on, yyyymmdd.
  final int day;
  final bool ranked;

  /// The level played; null for a custom setup.
  final int? level;

  /// The score and the most the game could score; null for a custom setup,
  /// which is not scored.
  final int? score;
  final int? maxScore;

  /// Played to the last prompt (false for a game ended early).
  final bool completed;

  /// The trip's rating after this game, and the game's performance on the
  /// same scale; null for free play.
  final double? rating;
  final double? performance;

  /// The trip's own details as JSON (暗記練: `AnkirenMeta`).
  final String meta;
  const SideTripRun({
    required this.id,
    required this.game,
    required this.startedAt,
    required this.endedAt,
    required this.day,
    required this.ranked,
    this.level,
    this.score,
    this.maxScore,
    required this.completed,
    this.rating,
    this.performance,
    required this.meta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['game'] = Variable<String>(
        $SideTripRunsTable.$convertergame.toSql(game),
      );
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['day'] = Variable<int>(day);
    map['ranked'] = Variable<bool>(ranked);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<int>(level);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || maxScore != null) {
      map['max_score'] = Variable<int>(maxScore);
    }
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || performance != null) {
      map['performance'] = Variable<double>(performance);
    }
    map['meta'] = Variable<String>(meta);
    return map;
  }

  SideTripRunsCompanion toCompanion(bool nullToAbsent) {
    return SideTripRunsCompanion(
      id: Value(id),
      game: Value(game),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      day: Value(day),
      ranked: Value(ranked),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      maxScore: maxScore == null && nullToAbsent
          ? const Value.absent()
          : Value(maxScore),
      completed: Value(completed),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      performance: performance == null && nullToAbsent
          ? const Value.absent()
          : Value(performance),
      meta: Value(meta),
    );
  }

  factory SideTripRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SideTripRun(
      id: serializer.fromJson<int>(json['id']),
      game: $SideTripRunsTable.$convertergame.fromJson(
        serializer.fromJson<String>(json['game']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      day: serializer.fromJson<int>(json['day']),
      ranked: serializer.fromJson<bool>(json['ranked']),
      level: serializer.fromJson<int?>(json['level']),
      score: serializer.fromJson<int?>(json['score']),
      maxScore: serializer.fromJson<int?>(json['maxScore']),
      completed: serializer.fromJson<bool>(json['completed']),
      rating: serializer.fromJson<double?>(json['rating']),
      performance: serializer.fromJson<double?>(json['performance']),
      meta: serializer.fromJson<String>(json['meta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'game': serializer.toJson<String>(
        $SideTripRunsTable.$convertergame.toJson(game),
      ),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'day': serializer.toJson<int>(day),
      'ranked': serializer.toJson<bool>(ranked),
      'level': serializer.toJson<int?>(level),
      'score': serializer.toJson<int?>(score),
      'maxScore': serializer.toJson<int?>(maxScore),
      'completed': serializer.toJson<bool>(completed),
      'rating': serializer.toJson<double?>(rating),
      'performance': serializer.toJson<double?>(performance),
      'meta': serializer.toJson<String>(meta),
    };
  }

  SideTripRun copyWith({
    int? id,
    SideTrip? game,
    DateTime? startedAt,
    DateTime? endedAt,
    int? day,
    bool? ranked,
    Value<int?> level = const Value.absent(),
    Value<int?> score = const Value.absent(),
    Value<int?> maxScore = const Value.absent(),
    bool? completed,
    Value<double?> rating = const Value.absent(),
    Value<double?> performance = const Value.absent(),
    String? meta,
  }) => SideTripRun(
    id: id ?? this.id,
    game: game ?? this.game,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    day: day ?? this.day,
    ranked: ranked ?? this.ranked,
    level: level.present ? level.value : this.level,
    score: score.present ? score.value : this.score,
    maxScore: maxScore.present ? maxScore.value : this.maxScore,
    completed: completed ?? this.completed,
    rating: rating.present ? rating.value : this.rating,
    performance: performance.present ? performance.value : this.performance,
    meta: meta ?? this.meta,
  );
  SideTripRun copyWithCompanion(SideTripRunsCompanion data) {
    return SideTripRun(
      id: data.id.present ? data.id.value : this.id,
      game: data.game.present ? data.game.value : this.game,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      day: data.day.present ? data.day.value : this.day,
      ranked: data.ranked.present ? data.ranked.value : this.ranked,
      level: data.level.present ? data.level.value : this.level,
      score: data.score.present ? data.score.value : this.score,
      maxScore: data.maxScore.present ? data.maxScore.value : this.maxScore,
      completed: data.completed.present ? data.completed.value : this.completed,
      rating: data.rating.present ? data.rating.value : this.rating,
      performance: data.performance.present
          ? data.performance.value
          : this.performance,
      meta: data.meta.present ? data.meta.value : this.meta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SideTripRun(')
          ..write('id: $id, ')
          ..write('game: $game, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('day: $day, ')
          ..write('ranked: $ranked, ')
          ..write('level: $level, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('completed: $completed, ')
          ..write('rating: $rating, ')
          ..write('performance: $performance, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    game,
    startedAt,
    endedAt,
    day,
    ranked,
    level,
    score,
    maxScore,
    completed,
    rating,
    performance,
    meta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SideTripRun &&
          other.id == this.id &&
          other.game == this.game &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.day == this.day &&
          other.ranked == this.ranked &&
          other.level == this.level &&
          other.score == this.score &&
          other.maxScore == this.maxScore &&
          other.completed == this.completed &&
          other.rating == this.rating &&
          other.performance == this.performance &&
          other.meta == this.meta);
}

class SideTripRunsCompanion extends UpdateCompanion<SideTripRun> {
  final Value<int> id;
  final Value<SideTrip> game;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> day;
  final Value<bool> ranked;
  final Value<int?> level;
  final Value<int?> score;
  final Value<int?> maxScore;
  final Value<bool> completed;
  final Value<double?> rating;
  final Value<double?> performance;
  final Value<String> meta;
  const SideTripRunsCompanion({
    this.id = const Value.absent(),
    this.game = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.day = const Value.absent(),
    this.ranked = const Value.absent(),
    this.level = const Value.absent(),
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.completed = const Value.absent(),
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.meta = const Value.absent(),
  });
  SideTripRunsCompanion.insert({
    this.id = const Value.absent(),
    required SideTrip game,
    required DateTime startedAt,
    required DateTime endedAt,
    required int day,
    required bool ranked,
    this.level = const Value.absent(),
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    required bool completed,
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.meta = const Value.absent(),
  }) : game = Value(game),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       day = Value(day),
       ranked = Value(ranked),
       completed = Value(completed);
  static Insertable<SideTripRun> custom({
    Expression<int>? id,
    Expression<String>? game,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? day,
    Expression<bool>? ranked,
    Expression<int>? level,
    Expression<int>? score,
    Expression<int>? maxScore,
    Expression<bool>? completed,
    Expression<double>? rating,
    Expression<double>? performance,
    Expression<String>? meta,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (game != null) 'game': game,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (day != null) 'day': day,
      if (ranked != null) 'ranked': ranked,
      if (level != null) 'level': level,
      if (score != null) 'score': score,
      if (maxScore != null) 'max_score': maxScore,
      if (completed != null) 'completed': completed,
      if (rating != null) 'rating': rating,
      if (performance != null) 'performance': performance,
      if (meta != null) 'meta': meta,
    });
  }

  SideTripRunsCompanion copyWith({
    Value<int>? id,
    Value<SideTrip>? game,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? day,
    Value<bool>? ranked,
    Value<int?>? level,
    Value<int?>? score,
    Value<int?>? maxScore,
    Value<bool>? completed,
    Value<double?>? rating,
    Value<double?>? performance,
    Value<String>? meta,
  }) {
    return SideTripRunsCompanion(
      id: id ?? this.id,
      game: game ?? this.game,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      day: day ?? this.day,
      ranked: ranked ?? this.ranked,
      level: level ?? this.level,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      completed: completed ?? this.completed,
      rating: rating ?? this.rating,
      performance: performance ?? this.performance,
      meta: meta ?? this.meta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (game.present) {
      map['game'] = Variable<String>(
        $SideTripRunsTable.$convertergame.toSql(game.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (ranked.present) {
      map['ranked'] = Variable<bool>(ranked.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (maxScore.present) {
      map['max_score'] = Variable<int>(maxScore.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (performance.present) {
      map['performance'] = Variable<double>(performance.value);
    }
    if (meta.present) {
      map['meta'] = Variable<String>(meta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SideTripRunsCompanion(')
          ..write('id: $id, ')
          ..write('game: $game, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('day: $day, ')
          ..write('ranked: $ranked, ')
          ..write('level: $level, ')
          ..write('score: $score, ')
          ..write('maxScore: $maxScore, ')
          ..write('completed: $completed, ')
          ..write('rating: $rating, ')
          ..write('performance: $performance, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }
}

class $SideTripAnswersTable extends SideTripAnswers
    with TableInfo<$SideTripAnswersTable, SideTripAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SideTripAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<int> runId = GeneratedColumn<int>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES side_trip_runs (id)',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<int> poemId = GeneratedColumn<int>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrongTapsMeta = const VerificationMeta(
    'wrongTaps',
  );
  @override
  late final GeneratedColumn<int> wrongTaps = GeneratedColumn<int>(
    'wrong_taps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gaveUpMeta = const VerificationMeta('gaveUp');
  @override
  late final GeneratedColumn<bool> gaveUp = GeneratedColumn<bool>(
    'gave_up',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gave_up" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _responseUsMeta = const VerificationMeta(
    'responseUs',
  );
  @override
  late final GeneratedColumn<int> responseUs = GeneratedColumn<int>(
    'response_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TapProximity?, String> firstTap =
      GeneratedColumn<String>(
        'first_tap',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TapProximity?>($SideTripAnswersTable.$converterfirstTapn);
  static const VerificationMeta _firstTapCardMeta = const VerificationMeta(
    'firstTapCard',
  );
  @override
  late final GeneratedColumn<int> firstTapCard = GeneratedColumn<int>(
    'first_tap_card',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstTapUsMeta = const VerificationMeta(
    'firstTapUs',
  );
  @override
  late final GeneratedColumn<int> firstTapUs = GeneratedColumn<int>(
    'first_tap_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TapProximity?, String> secondTap =
      GeneratedColumn<String>(
        'second_tap',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TapProximity?>(
        $SideTripAnswersTable.$convertersecondTapn,
      );
  static const VerificationMeta _secondTapCardMeta = const VerificationMeta(
    'secondTapCard',
  );
  @override
  late final GeneratedColumn<int> secondTapCard = GeneratedColumn<int>(
    'second_tap_card',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    seq,
    poemId,
    wrongTaps,
    gaveUp,
    responseUs,
    at,
    firstTap,
    firstTapCard,
    firstTapUs,
    secondTap,
    secondTapCard,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'side_trip_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SideTripAnswerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('poem_id')) {
      context.handle(
        _poemIdMeta,
        poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('wrong_taps')) {
      context.handle(
        _wrongTapsMeta,
        wrongTaps.isAcceptableOrUnknown(data['wrong_taps']!, _wrongTapsMeta),
      );
    } else if (isInserting) {
      context.missing(_wrongTapsMeta);
    }
    if (data.containsKey('gave_up')) {
      context.handle(
        _gaveUpMeta,
        gaveUp.isAcceptableOrUnknown(data['gave_up']!, _gaveUpMeta),
      );
    }
    if (data.containsKey('response_us')) {
      context.handle(
        _responseUsMeta,
        responseUs.isAcceptableOrUnknown(data['response_us']!, _responseUsMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('first_tap_card')) {
      context.handle(
        _firstTapCardMeta,
        firstTapCard.isAcceptableOrUnknown(
          data['first_tap_card']!,
          _firstTapCardMeta,
        ),
      );
    }
    if (data.containsKey('first_tap_us')) {
      context.handle(
        _firstTapUsMeta,
        firstTapUs.isAcceptableOrUnknown(
          data['first_tap_us']!,
          _firstTapUsMeta,
        ),
      );
    }
    if (data.containsKey('second_tap_card')) {
      context.handle(
        _secondTapCardMeta,
        secondTapCard.isAcceptableOrUnknown(
          data['second_tap_card']!,
          _secondTapCardMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SideTripAnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SideTripAnswerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      poemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}poem_id'],
      )!,
      wrongTaps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_taps'],
      )!,
      gaveUp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gave_up'],
      )!,
      responseUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_us'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      firstTap: $SideTripAnswersTable.$converterfirstTapn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}first_tap'],
        ),
      ),
      firstTapCard: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_tap_card'],
      ),
      firstTapUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_tap_us'],
      ),
      secondTap: $SideTripAnswersTable.$convertersecondTapn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}second_tap'],
        ),
      ),
      secondTapCard: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}second_tap_card'],
      ),
    );
  }

  @override
  $SideTripAnswersTable createAlias(String alias) {
    return $SideTripAnswersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TapProximity, String, String> $converterfirstTap =
      const EnumNameConverter<TapProximity>(TapProximity.values);
  static JsonTypeConverter2<TapProximity?, String?, String?>
  $converterfirstTapn = JsonTypeConverter2.asNullable($converterfirstTap);
  static JsonTypeConverter2<TapProximity, String, String> $convertersecondTap =
      const EnumNameConverter<TapProximity>(TapProximity.values);
  static JsonTypeConverter2<TapProximity?, String?, String?>
  $convertersecondTapn = JsonTypeConverter2.asNullable($convertersecondTap);
}

class SideTripAnswerRow extends DataClass
    implements Insertable<SideTripAnswerRow> {
  final int id;
  final int runId;
  final int seq;
  final int poemId;

  /// Other cards tapped while this one was asked.
  final int wrongTaps;

  /// The player gave it up ("don't know"). Never found and not given up:
  /// the game ended first.
  final bool gaveUp;

  /// Prompt → the tap on its card, µs; null when it was never found.
  final int? responseUs;

  /// When it was found or given up, or the game ended.
  final DateTime at;

  /// The first tap while it was asked: where it landed, the card it hit and
  /// prompt → tap, µs; null when no card was tapped.
  final TapProximity? firstTap;
  final int? firstTapCard;
  final int? firstTapUs;

  /// The second tap: where it landed and the card it hit; null when there
  /// was none.
  final TapProximity? secondTap;
  final int? secondTapCard;
  const SideTripAnswerRow({
    required this.id,
    required this.runId,
    required this.seq,
    required this.poemId,
    required this.wrongTaps,
    required this.gaveUp,
    this.responseUs,
    required this.at,
    this.firstTap,
    this.firstTapCard,
    this.firstTapUs,
    this.secondTap,
    this.secondTapCard,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<int>(runId);
    map['seq'] = Variable<int>(seq);
    map['poem_id'] = Variable<int>(poemId);
    map['wrong_taps'] = Variable<int>(wrongTaps);
    map['gave_up'] = Variable<bool>(gaveUp);
    if (!nullToAbsent || responseUs != null) {
      map['response_us'] = Variable<int>(responseUs);
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || firstTap != null) {
      map['first_tap'] = Variable<String>(
        $SideTripAnswersTable.$converterfirstTapn.toSql(firstTap),
      );
    }
    if (!nullToAbsent || firstTapCard != null) {
      map['first_tap_card'] = Variable<int>(firstTapCard);
    }
    if (!nullToAbsent || firstTapUs != null) {
      map['first_tap_us'] = Variable<int>(firstTapUs);
    }
    if (!nullToAbsent || secondTap != null) {
      map['second_tap'] = Variable<String>(
        $SideTripAnswersTable.$convertersecondTapn.toSql(secondTap),
      );
    }
    if (!nullToAbsent || secondTapCard != null) {
      map['second_tap_card'] = Variable<int>(secondTapCard);
    }
    return map;
  }

  SideTripAnswersCompanion toCompanion(bool nullToAbsent) {
    return SideTripAnswersCompanion(
      id: Value(id),
      runId: Value(runId),
      seq: Value(seq),
      poemId: Value(poemId),
      wrongTaps: Value(wrongTaps),
      gaveUp: Value(gaveUp),
      responseUs: responseUs == null && nullToAbsent
          ? const Value.absent()
          : Value(responseUs),
      at: Value(at),
      firstTap: firstTap == null && nullToAbsent
          ? const Value.absent()
          : Value(firstTap),
      firstTapCard: firstTapCard == null && nullToAbsent
          ? const Value.absent()
          : Value(firstTapCard),
      firstTapUs: firstTapUs == null && nullToAbsent
          ? const Value.absent()
          : Value(firstTapUs),
      secondTap: secondTap == null && nullToAbsent
          ? const Value.absent()
          : Value(secondTap),
      secondTapCard: secondTapCard == null && nullToAbsent
          ? const Value.absent()
          : Value(secondTapCard),
    );
  }

  factory SideTripAnswerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SideTripAnswerRow(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<int>(json['runId']),
      seq: serializer.fromJson<int>(json['seq']),
      poemId: serializer.fromJson<int>(json['poemId']),
      wrongTaps: serializer.fromJson<int>(json['wrongTaps']),
      gaveUp: serializer.fromJson<bool>(json['gaveUp']),
      responseUs: serializer.fromJson<int?>(json['responseUs']),
      at: serializer.fromJson<DateTime>(json['at']),
      firstTap: $SideTripAnswersTable.$converterfirstTapn.fromJson(
        serializer.fromJson<String?>(json['firstTap']),
      ),
      firstTapCard: serializer.fromJson<int?>(json['firstTapCard']),
      firstTapUs: serializer.fromJson<int?>(json['firstTapUs']),
      secondTap: $SideTripAnswersTable.$convertersecondTapn.fromJson(
        serializer.fromJson<String?>(json['secondTap']),
      ),
      secondTapCard: serializer.fromJson<int?>(json['secondTapCard']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<int>(runId),
      'seq': serializer.toJson<int>(seq),
      'poemId': serializer.toJson<int>(poemId),
      'wrongTaps': serializer.toJson<int>(wrongTaps),
      'gaveUp': serializer.toJson<bool>(gaveUp),
      'responseUs': serializer.toJson<int?>(responseUs),
      'at': serializer.toJson<DateTime>(at),
      'firstTap': serializer.toJson<String?>(
        $SideTripAnswersTable.$converterfirstTapn.toJson(firstTap),
      ),
      'firstTapCard': serializer.toJson<int?>(firstTapCard),
      'firstTapUs': serializer.toJson<int?>(firstTapUs),
      'secondTap': serializer.toJson<String?>(
        $SideTripAnswersTable.$convertersecondTapn.toJson(secondTap),
      ),
      'secondTapCard': serializer.toJson<int?>(secondTapCard),
    };
  }

  SideTripAnswerRow copyWith({
    int? id,
    int? runId,
    int? seq,
    int? poemId,
    int? wrongTaps,
    bool? gaveUp,
    Value<int?> responseUs = const Value.absent(),
    DateTime? at,
    Value<TapProximity?> firstTap = const Value.absent(),
    Value<int?> firstTapCard = const Value.absent(),
    Value<int?> firstTapUs = const Value.absent(),
    Value<TapProximity?> secondTap = const Value.absent(),
    Value<int?> secondTapCard = const Value.absent(),
  }) => SideTripAnswerRow(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    seq: seq ?? this.seq,
    poemId: poemId ?? this.poemId,
    wrongTaps: wrongTaps ?? this.wrongTaps,
    gaveUp: gaveUp ?? this.gaveUp,
    responseUs: responseUs.present ? responseUs.value : this.responseUs,
    at: at ?? this.at,
    firstTap: firstTap.present ? firstTap.value : this.firstTap,
    firstTapCard: firstTapCard.present ? firstTapCard.value : this.firstTapCard,
    firstTapUs: firstTapUs.present ? firstTapUs.value : this.firstTapUs,
    secondTap: secondTap.present ? secondTap.value : this.secondTap,
    secondTapCard: secondTapCard.present
        ? secondTapCard.value
        : this.secondTapCard,
  );
  SideTripAnswerRow copyWithCompanion(SideTripAnswersCompanion data) {
    return SideTripAnswerRow(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      seq: data.seq.present ? data.seq.value : this.seq,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      wrongTaps: data.wrongTaps.present ? data.wrongTaps.value : this.wrongTaps,
      gaveUp: data.gaveUp.present ? data.gaveUp.value : this.gaveUp,
      responseUs: data.responseUs.present
          ? data.responseUs.value
          : this.responseUs,
      at: data.at.present ? data.at.value : this.at,
      firstTap: data.firstTap.present ? data.firstTap.value : this.firstTap,
      firstTapCard: data.firstTapCard.present
          ? data.firstTapCard.value
          : this.firstTapCard,
      firstTapUs: data.firstTapUs.present
          ? data.firstTapUs.value
          : this.firstTapUs,
      secondTap: data.secondTap.present ? data.secondTap.value : this.secondTap,
      secondTapCard: data.secondTapCard.present
          ? data.secondTapCard.value
          : this.secondTapCard,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SideTripAnswerRow(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('seq: $seq, ')
          ..write('poemId: $poemId, ')
          ..write('wrongTaps: $wrongTaps, ')
          ..write('gaveUp: $gaveUp, ')
          ..write('responseUs: $responseUs, ')
          ..write('at: $at, ')
          ..write('firstTap: $firstTap, ')
          ..write('firstTapCard: $firstTapCard, ')
          ..write('firstTapUs: $firstTapUs, ')
          ..write('secondTap: $secondTap, ')
          ..write('secondTapCard: $secondTapCard')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    seq,
    poemId,
    wrongTaps,
    gaveUp,
    responseUs,
    at,
    firstTap,
    firstTapCard,
    firstTapUs,
    secondTap,
    secondTapCard,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SideTripAnswerRow &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.seq == this.seq &&
          other.poemId == this.poemId &&
          other.wrongTaps == this.wrongTaps &&
          other.gaveUp == this.gaveUp &&
          other.responseUs == this.responseUs &&
          other.at == this.at &&
          other.firstTap == this.firstTap &&
          other.firstTapCard == this.firstTapCard &&
          other.firstTapUs == this.firstTapUs &&
          other.secondTap == this.secondTap &&
          other.secondTapCard == this.secondTapCard);
}

class SideTripAnswersCompanion extends UpdateCompanion<SideTripAnswerRow> {
  final Value<int> id;
  final Value<int> runId;
  final Value<int> seq;
  final Value<int> poemId;
  final Value<int> wrongTaps;
  final Value<bool> gaveUp;
  final Value<int?> responseUs;
  final Value<DateTime> at;
  final Value<TapProximity?> firstTap;
  final Value<int?> firstTapCard;
  final Value<int?> firstTapUs;
  final Value<TapProximity?> secondTap;
  final Value<int?> secondTapCard;
  const SideTripAnswersCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.seq = const Value.absent(),
    this.poemId = const Value.absent(),
    this.wrongTaps = const Value.absent(),
    this.gaveUp = const Value.absent(),
    this.responseUs = const Value.absent(),
    this.at = const Value.absent(),
    this.firstTap = const Value.absent(),
    this.firstTapCard = const Value.absent(),
    this.firstTapUs = const Value.absent(),
    this.secondTap = const Value.absent(),
    this.secondTapCard = const Value.absent(),
  });
  SideTripAnswersCompanion.insert({
    this.id = const Value.absent(),
    required int runId,
    required int seq,
    required int poemId,
    required int wrongTaps,
    this.gaveUp = const Value.absent(),
    this.responseUs = const Value.absent(),
    required DateTime at,
    this.firstTap = const Value.absent(),
    this.firstTapCard = const Value.absent(),
    this.firstTapUs = const Value.absent(),
    this.secondTap = const Value.absent(),
    this.secondTapCard = const Value.absent(),
  }) : runId = Value(runId),
       seq = Value(seq),
       poemId = Value(poemId),
       wrongTaps = Value(wrongTaps),
       at = Value(at);
  static Insertable<SideTripAnswerRow> custom({
    Expression<int>? id,
    Expression<int>? runId,
    Expression<int>? seq,
    Expression<int>? poemId,
    Expression<int>? wrongTaps,
    Expression<bool>? gaveUp,
    Expression<int>? responseUs,
    Expression<DateTime>? at,
    Expression<String>? firstTap,
    Expression<int>? firstTapCard,
    Expression<int>? firstTapUs,
    Expression<String>? secondTap,
    Expression<int>? secondTapCard,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (seq != null) 'seq': seq,
      if (poemId != null) 'poem_id': poemId,
      if (wrongTaps != null) 'wrong_taps': wrongTaps,
      if (gaveUp != null) 'gave_up': gaveUp,
      if (responseUs != null) 'response_us': responseUs,
      if (at != null) 'at': at,
      if (firstTap != null) 'first_tap': firstTap,
      if (firstTapCard != null) 'first_tap_card': firstTapCard,
      if (firstTapUs != null) 'first_tap_us': firstTapUs,
      if (secondTap != null) 'second_tap': secondTap,
      if (secondTapCard != null) 'second_tap_card': secondTapCard,
    });
  }

  SideTripAnswersCompanion copyWith({
    Value<int>? id,
    Value<int>? runId,
    Value<int>? seq,
    Value<int>? poemId,
    Value<int>? wrongTaps,
    Value<bool>? gaveUp,
    Value<int?>? responseUs,
    Value<DateTime>? at,
    Value<TapProximity?>? firstTap,
    Value<int?>? firstTapCard,
    Value<int?>? firstTapUs,
    Value<TapProximity?>? secondTap,
    Value<int?>? secondTapCard,
  }) {
    return SideTripAnswersCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      seq: seq ?? this.seq,
      poemId: poemId ?? this.poemId,
      wrongTaps: wrongTaps ?? this.wrongTaps,
      gaveUp: gaveUp ?? this.gaveUp,
      responseUs: responseUs ?? this.responseUs,
      at: at ?? this.at,
      firstTap: firstTap ?? this.firstTap,
      firstTapCard: firstTapCard ?? this.firstTapCard,
      firstTapUs: firstTapUs ?? this.firstTapUs,
      secondTap: secondTap ?? this.secondTap,
      secondTapCard: secondTapCard ?? this.secondTapCard,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<int>(runId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (poemId.present) {
      map['poem_id'] = Variable<int>(poemId.value);
    }
    if (wrongTaps.present) {
      map['wrong_taps'] = Variable<int>(wrongTaps.value);
    }
    if (gaveUp.present) {
      map['gave_up'] = Variable<bool>(gaveUp.value);
    }
    if (responseUs.present) {
      map['response_us'] = Variable<int>(responseUs.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (firstTap.present) {
      map['first_tap'] = Variable<String>(
        $SideTripAnswersTable.$converterfirstTapn.toSql(firstTap.value),
      );
    }
    if (firstTapCard.present) {
      map['first_tap_card'] = Variable<int>(firstTapCard.value);
    }
    if (firstTapUs.present) {
      map['first_tap_us'] = Variable<int>(firstTapUs.value);
    }
    if (secondTap.present) {
      map['second_tap'] = Variable<String>(
        $SideTripAnswersTable.$convertersecondTapn.toSql(secondTap.value),
      );
    }
    if (secondTapCard.present) {
      map['second_tap_card'] = Variable<int>(secondTapCard.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SideTripAnswersCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('seq: $seq, ')
          ..write('poemId: $poemId, ')
          ..write('wrongTaps: $wrongTaps, ')
          ..write('gaveUp: $gaveUp, ')
          ..write('responseUs: $responseUs, ')
          ..write('at: $at, ')
          ..write('firstTap: $firstTap, ')
          ..write('firstTapCard: $firstTapCard, ')
          ..write('firstTapUs: $firstTapUs, ')
          ..write('secondTap: $secondTap, ')
          ..write('secondTapCard: $secondTapCard')
          ..write(')'))
        .toString();
  }
}

class $DayCardsTable extends DayCards
    with TableInfo<$DayCardsTable, DayCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES days (day)',
    ),
  );
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<int> poemId = GeneratedColumn<int>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invertedMeta = const VerificationMeta(
    'inverted',
  );
  @override
  late final GeneratedColumn<bool> inverted = GeneratedColumn<bool>(
    'inverted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("inverted" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<StepKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StepKind>($DayCardsTable.$converterkind);
  @override
  List<GeneratedColumn> get $columns => [day, poemId, inverted, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('poem_id')) {
      context.handle(
        _poemIdMeta,
        poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('inverted')) {
      context.handle(
        _invertedMeta,
        inverted.isAcceptableOrUnknown(data['inverted']!, _invertedMeta),
      );
    } else if (isInserting) {
      context.missing(_invertedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day, poemId, inverted};
  @override
  DayCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayCardRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day'],
      )!,
      poemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}poem_id'],
      )!,
      inverted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}inverted'],
      )!,
      kind: $DayCardsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
    );
  }

  @override
  $DayCardsTable createAlias(String alias) {
    return $DayCardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<StepKind, String, String> $converterkind =
      const EnumNameConverter<StepKind>(StepKind.values);
}

class DayCardRow extends DataClass implements Insertable<DayCardRow> {
  final int day;
  final int poemId;
  final bool inverted;

  /// A due review or a new card.
  final StepKind kind;
  const DayCardRow({
    required this.day,
    required this.poemId,
    required this.inverted,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<int>(day);
    map['poem_id'] = Variable<int>(poemId);
    map['inverted'] = Variable<bool>(inverted);
    {
      map['kind'] = Variable<String>($DayCardsTable.$converterkind.toSql(kind));
    }
    return map;
  }

  DayCardsCompanion toCompanion(bool nullToAbsent) {
    return DayCardsCompanion(
      day: Value(day),
      poemId: Value(poemId),
      inverted: Value(inverted),
      kind: Value(kind),
    );
  }

  factory DayCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayCardRow(
      day: serializer.fromJson<int>(json['day']),
      poemId: serializer.fromJson<int>(json['poemId']),
      inverted: serializer.fromJson<bool>(json['inverted']),
      kind: $DayCardsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<int>(day),
      'poemId': serializer.toJson<int>(poemId),
      'inverted': serializer.toJson<bool>(inverted),
      'kind': serializer.toJson<String>(
        $DayCardsTable.$converterkind.toJson(kind),
      ),
    };
  }

  DayCardRow copyWith({
    int? day,
    int? poemId,
    bool? inverted,
    StepKind? kind,
  }) => DayCardRow(
    day: day ?? this.day,
    poemId: poemId ?? this.poemId,
    inverted: inverted ?? this.inverted,
    kind: kind ?? this.kind,
  );
  DayCardRow copyWithCompanion(DayCardsCompanion data) {
    return DayCardRow(
      day: data.day.present ? data.day.value : this.day,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      inverted: data.inverted.present ? data.inverted.value : this.inverted,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayCardRow(')
          ..write('day: $day, ')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, poemId, inverted, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayCardRow &&
          other.day == this.day &&
          other.poemId == this.poemId &&
          other.inverted == this.inverted &&
          other.kind == this.kind);
}

class DayCardsCompanion extends UpdateCompanion<DayCardRow> {
  final Value<int> day;
  final Value<int> poemId;
  final Value<bool> inverted;
  final Value<StepKind> kind;
  final Value<int> rowid;
  const DayCardsCompanion({
    this.day = const Value.absent(),
    this.poemId = const Value.absent(),
    this.inverted = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayCardsCompanion.insert({
    required int day,
    required int poemId,
    required bool inverted,
    required StepKind kind,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       poemId = Value(poemId),
       inverted = Value(inverted),
       kind = Value(kind);
  static Insertable<DayCardRow> custom({
    Expression<int>? day,
    Expression<int>? poemId,
    Expression<bool>? inverted,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (poemId != null) 'poem_id': poemId,
      if (inverted != null) 'inverted': inverted,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayCardsCompanion copyWith({
    Value<int>? day,
    Value<int>? poemId,
    Value<bool>? inverted,
    Value<StepKind>? kind,
    Value<int>? rowid,
  }) {
    return DayCardsCompanion(
      day: day ?? this.day,
      poemId: poemId ?? this.poemId,
      inverted: inverted ?? this.inverted,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (poemId.present) {
      map['poem_id'] = Variable<int>(poemId.value);
    }
    if (inverted.present) {
      map['inverted'] = Variable<bool>(inverted.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $DayCardsTable.$converterkind.toSql(kind.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayCardsCompanion(')
          ..write('day: $day, ')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DaysTable days = $DaysTable(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $IslandCompletionsTable islandCompletions =
      $IslandCompletionsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $SideTripRunsTable sideTripRuns = $SideTripRunsTable(this);
  late final $SideTripAnswersTable sideTripAnswers = $SideTripAnswersTable(
    this,
  );
  late final $DayCardsTable dayCards = $DayCardsTable(this);
  late final Index runsDay = Index(
    'runs_day',
    'CREATE INDEX runs_day ON runs (day)',
  );
  late final Index runsMode = Index(
    'runs_mode',
    'CREATE INDEX runs_mode ON runs (mode, started_at)',
  );
  late final Index attemptsRun = Index(
    'attempts_run',
    'CREATE INDEX attempts_run ON attempts (run_id)',
  );
  late final Index attemptsItem = Index(
    'attempts_item',
    'CREATE INDEX attempts_item ON attempts (poem_id, inverted)',
  );
  late final Index sideTripRunsDay = Index(
    'side_trip_runs_day',
    'CREATE INDEX side_trip_runs_day ON side_trip_runs (day)',
  );
  late final Index sideTripAnswersRun = Index(
    'side_trip_answers_run',
    'CREATE INDEX side_trip_answers_run ON side_trip_answers (run_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    days,
    runs,
    attempts,
    items,
    islandCompletions,
    keyValues,
    sideTripRuns,
    sideTripAnswers,
    dayCards,
    runsDay,
    runsMode,
    attemptsRun,
    attemptsItem,
    sideTripRunsDay,
    sideTripAnswersRun,
  ];
}

typedef $$DaysTableCreateCompanionBuilder = DaysCompanion Function({
  Value<int> day,
  required DateTime startsAt,
  required DateTime endsAt,
  Value<DateTime?> builtAt,
  Value<int> missGuess,
  Value<bool> newPaused,
  Value<bool> pauseAsked,
  Value<DateTime?> doneAt,
});
typedef $$DaysTableUpdateCompanionBuilder = DaysCompanion Function({
  Value<int> day,
  Value<DateTime> startsAt,
  Value<DateTime> endsAt,
  Value<DateTime?> builtAt,
  Value<int> missGuess,
  Value<bool> newPaused,
  Value<bool> pauseAsked,
  Value<DateTime?> doneAt,
});

final class $$DaysTableReferences
    extends BaseReferences<_$AppDatabase, $DaysTable, DayRow> {
  $$DaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RunsTable, List<RunRow>> _runsRefsTable(
    _$AppDatabase db,
  ) =>
      MultiTypedResultKey.fromTable(db.runs, aliasName: 'days__day__runs__day');

  $$RunsTableProcessedTableManager get runsRefs {
    final manager = $$RunsTableTableManager(
      $_db,
      $_db.runs,
    ).filter((f) => f.day.day.sqlEquals($_itemColumn<int>('day')!));

    final cache = $_typedResult.readTableOrNull(_runsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SideTripRunsTable, List<SideTripRun>>
  _sideTripRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sideTripRuns,
    aliasName: 'days__day__side_trip_runs__day',
  );

  $$SideTripRunsTableProcessedTableManager get sideTripRunsRefs {
    final manager = $$SideTripRunsTableTableManager(
      $_db,
      $_db.sideTripRuns,
    ).filter((f) => f.day.day.sqlEquals($_itemColumn<int>('day')!));

    final cache = $_typedResult.readTableOrNull(_sideTripRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DayCardsTable, List<DayCardRow>>
  _dayCardsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dayCards,
    aliasName: 'days__day__day_cards__day',
  );

  $$DayCardsTableProcessedTableManager get dayCardsRefs {
    final manager = $$DayCardsTableTableManager(
      $_db,
      $_db.dayCards,
    ).filter((f) => f.day.day.sqlEquals($_itemColumn<int>('day')!));

    final cache = $_typedResult.readTableOrNull(_dayCardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DaysTableFilterComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get builtAt => $composableBuilder(
    column: $table.builtAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get missGuess => $composableBuilder(
    column: $table.missGuess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get newPaused => $composableBuilder(
    column: $table.newPaused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pauseAsked => $composableBuilder(
    column: $table.pauseAsked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> runsRefs(
    Expression<bool> Function($$RunsTableFilterComposer f) f,
  ) {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sideTripRunsRefs(
    Expression<bool> Function($$SideTripRunsTableFilterComposer f) f,
  ) {
    final $$SideTripRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.sideTripRuns,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SideTripRunsTableFilterComposer(
            $db: $db,
            $table: $db.sideTripRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dayCardsRefs(
    Expression<bool> Function($$DayCardsTableFilterComposer f) f,
  ) {
    final $$DayCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.dayCards,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayCardsTableFilterComposer(
            $db: $db,
            $table: $db.dayCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DaysTableOrderingComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
    column: $table.startsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
    column: $table.endsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get builtAt => $composableBuilder(
    column: $table.builtAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get missGuess => $composableBuilder(
    column: $table.missGuess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get newPaused => $composableBuilder(
    column: $table.newPaused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pauseAsked => $composableBuilder(
    column: $table.pauseAsked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get builtAt =>
      $composableBuilder(column: $table.builtAt, builder: (column) => column);

  GeneratedColumn<int> get missGuess =>
      $composableBuilder(column: $table.missGuess, builder: (column) => column);

  GeneratedColumn<bool> get newPaused =>
      $composableBuilder(column: $table.newPaused, builder: (column) => column);

  GeneratedColumn<bool> get pauseAsked => $composableBuilder(
    column: $table.pauseAsked,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  Expression<T> runsRefs<T extends Object>(
    Expression<T> Function($$RunsTableAnnotationComposer a) f,
  ) {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sideTripRunsRefs<T extends Object>(
    Expression<T> Function($$SideTripRunsTableAnnotationComposer a) f,
  ) {
    final $$SideTripRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.sideTripRuns,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SideTripRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.sideTripRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dayCardsRefs<T extends Object>(
    Expression<T> Function($$DayCardsTableAnnotationComposer a) f,
  ) {
    final $$DayCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.dayCards,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DayCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.dayCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DaysTable,
          DayRow,
          $$DaysTableFilterComposer,
          $$DaysTableOrderingComposer,
          $$DaysTableAnnotationComposer,
          $$DaysTableCreateCompanionBuilder,
          $$DaysTableUpdateCompanionBuilder,
          (DayRow, $$DaysTableReferences),
          DayRow,
          PrefetchHooks Function({
            bool runsRefs,
            bool sideTripRunsRefs,
            bool dayCardsRefs,
          })
        > {
  $$DaysTableTableManager(_$AppDatabase db, $DaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> day = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<DateTime> endsAt = const Value.absent(),
                Value<DateTime?> builtAt = const Value.absent(),
                Value<int> missGuess = const Value.absent(),
                Value<bool> newPaused = const Value.absent(),
                Value<bool> pauseAsked = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
              }) => DaysCompanion(
                day: day,
                startsAt: startsAt,
                endsAt: endsAt,
                builtAt: builtAt,
                missGuess: missGuess,
                newPaused: newPaused,
                pauseAsked: pauseAsked,
                doneAt: doneAt,
              ),
          createCompanionCallback:
              ({
                Value<int> day = const Value.absent(),
                required DateTime startsAt,
                required DateTime endsAt,
                Value<DateTime?> builtAt = const Value.absent(),
                Value<int> missGuess = const Value.absent(),
                Value<bool> newPaused = const Value.absent(),
                Value<bool> pauseAsked = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
              }) => DaysCompanion.insert(
                day: day,
                startsAt: startsAt,
                endsAt: endsAt,
                builtAt: builtAt,
                missGuess: missGuess,
                newPaused: newPaused,
                pauseAsked: pauseAsked,
                doneAt: doneAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DaysTable, DayRow>(table),
                  $$DaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                runsRefs = false,
                sideTripRunsRefs = false,
                dayCardsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (runsRefs) db.runs,
                    if (sideTripRunsRefs) db.sideTripRuns,
                    if (dayCardsRefs) db.dayCards,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (runsRefs)
                        await $_getPrefetchedData<DayRow, $DaysTable, RunRow>(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences._runsRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $$DaysTableReferences(db, table, p0).runsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.day == item.day),
                          typedResults: items,
                        ),
                      if (sideTripRunsRefs)
                        await $_getPrefetchedData<
                          DayRow,
                          $DaysTable,
                          SideTripRun
                        >(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._sideTripRunsRefsTable(db),
                          managerFromTypedResult: (p0) => $$DaysTableReferences(
                            db,
                            table,
                            p0,
                          ).sideTripRunsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.day == item.day),
                          typedResults: items,
                        ),
                      if (dayCardsRefs)
                        await $_getPrefetchedData<
                          DayRow,
                          $DaysTable,
                          DayCardRow
                        >(
                          currentTable: table,
                          referencedTable: $$DaysTableReferences
                              ._dayCardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DaysTableReferences(db, table, p0).dayCardsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.day == item.day),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DaysTable,
      DayRow,
      $$DaysTableFilterComposer,
      $$DaysTableOrderingComposer,
      $$DaysTableAnnotationComposer,
      $$DaysTableCreateCompanionBuilder,
      $$DaysTableUpdateCompanionBuilder,
      (DayRow, $$DaysTableReferences),
      DayRow,
      PrefetchHooks Function({
        bool runsRefs,
        bool sideTripRunsRefs,
        bool dayCardsRefs,
      })
    >;
typedef $$RunsTableCreateCompanionBuilder = RunsCompanion Function({
  Value<int> id,
  required PlayMode mode,
  required DateTime startedAt,
  required DateTime endedAt,
  required int day,
  required bool allKnown,
  Value<String> setIds,
  Value<String?> cardIds,
  Value<int> maskLevel,
  required int goalMs,
  required int planned,
  required bool completed,
  Value<int?> clockUs,
  Value<int?> scoredMs,
  Value<double?> rating,
  Value<double?> performance,
  Value<int?> tobiMs,
  Value<String?> tobiLine,
  Value<bool> graduated,
  Value<bool> dayDone,
});
typedef $$RunsTableUpdateCompanionBuilder = RunsCompanion Function({
  Value<int> id,
  Value<PlayMode> mode,
  Value<DateTime> startedAt,
  Value<DateTime> endedAt,
  Value<int> day,
  Value<bool> allKnown,
  Value<String> setIds,
  Value<String?> cardIds,
  Value<int> maskLevel,
  Value<int> goalMs,
  Value<int> planned,
  Value<bool> completed,
  Value<int?> clockUs,
  Value<int?> scoredMs,
  Value<double?> rating,
  Value<double?> performance,
  Value<int?> tobiMs,
  Value<String?> tobiLine,
  Value<bool> graduated,
  Value<bool> dayDone,
});

final class $$RunsTableReferences
    extends BaseReferences<_$AppDatabase, $RunsTable, RunRow> {
  $$RunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _dayTable(_$AppDatabase db) =>
      db.days.createAlias('runs__day__days__day');

  $$DaysTableProcessedTableManager get day {
    final $_column = $_itemColumn<int>('day')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.day.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttemptsTable, List<AttemptRow>>
  _attemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attempts,
    aliasName: 'runs__id__attempts__run_id',
  );

  $$AttemptsTableProcessedTableManager get attemptsRefs {
    final manager = $$AttemptsTableTableManager(
      $_db,
      $_db.attempts,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IslandCompletionsTable, List<IslandCompletionRow>>
  _islandCompletionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.islandCompletions,
        aliasName: 'runs__id__island_completions__run_id',
      );

  $$IslandCompletionsTableProcessedTableManager get islandCompletionsRefs {
    final manager = $$IslandCompletionsTableTableManager(
      $_db,
      $_db.islandCompletions,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _islandCompletionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RunsTableFilterComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlayMode, PlayMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allKnown => $composableBuilder(
    column: $table.allKnown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setIds => $composableBuilder(
    column: $table.setIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardIds => $composableBuilder(
    column: $table.cardIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maskLevel => $composableBuilder(
    column: $table.maskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalMs => $composableBuilder(
    column: $table.goalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planned => $composableBuilder(
    column: $table.planned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get clockUs => $composableBuilder(
    column: $table.clockUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoredMs => $composableBuilder(
    column: $table.scoredMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tobiMs => $composableBuilder(
    column: $table.tobiMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tobiLine => $composableBuilder(
    column: $table.tobiLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get graduated => $composableBuilder(
    column: $table.graduated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dayDone => $composableBuilder(
    column: $table.dayDone,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get day {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attemptsRefs(
    Expression<bool> Function($$AttemptsTableFilterComposer f) f,
  ) {
    final $$AttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableFilterComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> islandCompletionsRefs(
    Expression<bool> Function($$IslandCompletionsTableFilterComposer f) f,
  ) {
    final $$IslandCompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.islandCompletions,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IslandCompletionsTableFilterComposer(
            $db: $db,
            $table: $db.islandCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunsTableOrderingComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allKnown => $composableBuilder(
    column: $table.allKnown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setIds => $composableBuilder(
    column: $table.setIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardIds => $composableBuilder(
    column: $table.cardIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maskLevel => $composableBuilder(
    column: $table.maskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalMs => $composableBuilder(
    column: $table.goalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planned => $composableBuilder(
    column: $table.planned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get clockUs => $composableBuilder(
    column: $table.clockUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoredMs => $composableBuilder(
    column: $table.scoredMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tobiMs => $composableBuilder(
    column: $table.tobiMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tobiLine => $composableBuilder(
    column: $table.tobiLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get graduated => $composableBuilder(
    column: $table.graduated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dayDone => $composableBuilder(
    column: $table.dayDone,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get day {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlayMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get allKnown =>
      $composableBuilder(column: $table.allKnown, builder: (column) => column);

  GeneratedColumn<String> get setIds =>
      $composableBuilder(column: $table.setIds, builder: (column) => column);

  GeneratedColumn<String> get cardIds =>
      $composableBuilder(column: $table.cardIds, builder: (column) => column);

  GeneratedColumn<int> get maskLevel =>
      $composableBuilder(column: $table.maskLevel, builder: (column) => column);

  GeneratedColumn<int> get goalMs =>
      $composableBuilder(column: $table.goalMs, builder: (column) => column);

  GeneratedColumn<int> get planned =>
      $composableBuilder(column: $table.planned, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get clockUs =>
      $composableBuilder(column: $table.clockUs, builder: (column) => column);

  GeneratedColumn<int> get scoredMs =>
      $composableBuilder(column: $table.scoredMs, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<double> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tobiMs =>
      $composableBuilder(column: $table.tobiMs, builder: (column) => column);

  GeneratedColumn<String> get tobiLine =>
      $composableBuilder(column: $table.tobiLine, builder: (column) => column);

  GeneratedColumn<bool> get graduated =>
      $composableBuilder(column: $table.graduated, builder: (column) => column);

  GeneratedColumn<bool> get dayDone =>
      $composableBuilder(column: $table.dayDone, builder: (column) => column);

  $$DaysTableAnnotationComposer get day {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attemptsRefs<T extends Object>(
    Expression<T> Function($$AttemptsTableAnnotationComposer a) f,
  ) {
    final $$AttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> islandCompletionsRefs<T extends Object>(
    Expression<T> Function($$IslandCompletionsTableAnnotationComposer a) f,
  ) {
    final $$IslandCompletionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.islandCompletions,
          getReferencedColumn: (t) => t.runId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IslandCompletionsTableAnnotationComposer(
                $db: $db,
                $table: $db.islandCompletions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunsTable,
          RunRow,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (RunRow, $$RunsTableReferences),
          RunRow,
          PrefetchHooks Function({
            bool day,
            bool attemptsRefs,
            bool islandCompletionsRefs,
          })
        > {
  $$RunsTableTableManager(_$AppDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<PlayMode> mode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<bool> allKnown = const Value.absent(),
                Value<String> setIds = const Value.absent(),
                Value<String?> cardIds = const Value.absent(),
                Value<int> maskLevel = const Value.absent(),
                Value<int> goalMs = const Value.absent(),
                Value<int> planned = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int?> clockUs = const Value.absent(),
                Value<int?> scoredMs = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<double?> performance = const Value.absent(),
                Value<int?> tobiMs = const Value.absent(),
                Value<String?> tobiLine = const Value.absent(),
                Value<bool> graduated = const Value.absent(),
                Value<bool> dayDone = const Value.absent(),
              }) => RunsCompanion(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                day: day,
                allKnown: allKnown,
                setIds: setIds,
                cardIds: cardIds,
                maskLevel: maskLevel,
                goalMs: goalMs,
                planned: planned,
                completed: completed,
                clockUs: clockUs,
                scoredMs: scoredMs,
                rating: rating,
                performance: performance,
                tobiMs: tobiMs,
                tobiLine: tobiLine,
                graduated: graduated,
                dayDone: dayDone,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required PlayMode mode,
                required DateTime startedAt,
                required DateTime endedAt,
                required int day,
                required bool allKnown,
                Value<String> setIds = const Value.absent(),
                Value<String?> cardIds = const Value.absent(),
                Value<int> maskLevel = const Value.absent(),
                required int goalMs,
                required int planned,
                required bool completed,
                Value<int?> clockUs = const Value.absent(),
                Value<int?> scoredMs = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<double?> performance = const Value.absent(),
                Value<int?> tobiMs = const Value.absent(),
                Value<String?> tobiLine = const Value.absent(),
                Value<bool> graduated = const Value.absent(),
                Value<bool> dayDone = const Value.absent(),
              }) => RunsCompanion.insert(
                id: id,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                day: day,
                allKnown: allKnown,
                setIds: setIds,
                cardIds: cardIds,
                maskLevel: maskLevel,
                goalMs: goalMs,
                planned: planned,
                completed: completed,
                clockUs: clockUs,
                scoredMs: scoredMs,
                rating: rating,
                performance: performance,
                tobiMs: tobiMs,
                tobiLine: tobiLine,
                graduated: graduated,
                dayDone: dayDone,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RunsTable, RunRow>(table),
                  $$RunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                day = false,
                attemptsRefs = false,
                islandCompletionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attemptsRefs) db.attempts,
                    if (islandCompletionsRefs) db.islandCompletions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (day) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.day,
                            referencedTable: $$RunsTableReferences._dayTable(
                              db,
                            ),
                            referencedColumn: $$RunsTableReferences
                                ._dayTable(db)
                                .day,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attemptsRefs)
                        await $_getPrefetchedData<
                          RunRow,
                          $RunsTable,
                          AttemptRow
                        >(
                          currentTable: table,
                          referencedTable: $$RunsTableReferences
                              ._attemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RunsTableReferences(db, table, p0).attemptsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.runId == item.id),
                          typedResults: items,
                        ),
                      if (islandCompletionsRefs)
                        await $_getPrefetchedData<
                          RunRow,
                          $RunsTable,
                          IslandCompletionRow
                        >(
                          currentTable: table,
                          referencedTable: $$RunsTableReferences
                              ._islandCompletionsRefsTable(db),
                          managerFromTypedResult: (p0) => $$RunsTableReferences(
                            db,
                            table,
                            p0,
                          ).islandCompletionsRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.runId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunsTable,
      RunRow,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (RunRow, $$RunsTableReferences),
      RunRow,
      PrefetchHooks Function({
        bool day,
        bool attemptsRefs,
        bool islandCompletionsRefs,
      })
    >;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  required int runId,
  required int seq,
  required int poemId,
  required bool inverted,
  Value<int> maskLevel,
  required Outcome outcome,
  Value<bool> wrong,
  Value<bool> tainted,
  Value<bool> undone,
  required int deckSize,
  required DateTime at,
  Value<int?> revealAtUs,
  required int responseUs,
  Value<int?> commitUs,
  Value<int?> grade,
  Value<double?> fsrsRecall,
  Value<fsrs.State?> fsrsState,
  Value<int?> fsrsStep,
  Value<double?> fsrsStability,
  Value<double?> fsrsDifficulty,
  Value<DateTime?> fsrsDue,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  Value<int> runId,
  Value<int> seq,
  Value<int> poemId,
  Value<bool> inverted,
  Value<int> maskLevel,
  Value<Outcome> outcome,
  Value<bool> wrong,
  Value<bool> tainted,
  Value<bool> undone,
  Value<int> deckSize,
  Value<DateTime> at,
  Value<int?> revealAtUs,
  Value<int> responseUs,
  Value<int?> commitUs,
  Value<int?> grade,
  Value<double?> fsrsRecall,
  Value<fsrs.State?> fsrsState,
  Value<int?> fsrsStep,
  Value<double?> fsrsStability,
  Value<double?> fsrsDifficulty,
  Value<DateTime?> fsrsDue,
});

final class $$AttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow> {
  $$AttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RunsTable _runIdTable(_$AppDatabase db) =>
      db.runs.createAlias('attempts__run_id__runs__id');

  $$RunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<int>('run_id')!;

    final manager = $$RunsTableTableManager(
      $_db,
      $_db.runs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inverted => $composableBuilder(
    column: $table.inverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maskLevel => $composableBuilder(
    column: $table.maskLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Outcome, Outcome, String> get outcome =>
      $composableBuilder(
        column: $table.outcome,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get wrong => $composableBuilder(
    column: $table.wrong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tainted => $composableBuilder(
    column: $table.tainted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get undone => $composableBuilder(
    column: $table.undone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deckSize => $composableBuilder(
    column: $table.deckSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revealAtUs => $composableBuilder(
    column: $table.revealAtUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commitUs => $composableBuilder(
    column: $table.commitUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsRecall => $composableBuilder(
    column: $table.fsrsRecall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<fsrs.State?, fsrs.State, String>
  get fsrsState => $composableBuilder(
    column: $table.fsrsState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get fsrsStep => $composableBuilder(
    column: $table.fsrsStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fsrsDue => $composableBuilder(
    column: $table.fsrsDue,
    builder: (column) => ColumnFilters(column),
  );

  $$RunsTableFilterComposer get runId {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inverted => $composableBuilder(
    column: $table.inverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maskLevel => $composableBuilder(
    column: $table.maskLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wrong => $composableBuilder(
    column: $table.wrong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tainted => $composableBuilder(
    column: $table.tainted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get undone => $composableBuilder(
    column: $table.undone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deckSize => $composableBuilder(
    column: $table.deckSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revealAtUs => $composableBuilder(
    column: $table.revealAtUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commitUs => $composableBuilder(
    column: $table.commitUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsRecall => $composableBuilder(
    column: $table.fsrsRecall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fsrsState => $composableBuilder(
    column: $table.fsrsState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fsrsStep => $composableBuilder(
    column: $table.fsrsStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fsrsDue => $composableBuilder(
    column: $table.fsrsDue,
    builder: (column) => ColumnOrderings(column),
  );

  $$RunsTableOrderingComposer get runId {
    final $$RunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableOrderingComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get poemId =>
      $composableBuilder(column: $table.poemId, builder: (column) => column);

  GeneratedColumn<bool> get inverted =>
      $composableBuilder(column: $table.inverted, builder: (column) => column);

  GeneratedColumn<int> get maskLevel =>
      $composableBuilder(column: $table.maskLevel, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Outcome, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<bool> get wrong =>
      $composableBuilder(column: $table.wrong, builder: (column) => column);

  GeneratedColumn<bool> get tainted =>
      $composableBuilder(column: $table.tainted, builder: (column) => column);

  GeneratedColumn<bool> get undone =>
      $composableBuilder(column: $table.undone, builder: (column) => column);

  GeneratedColumn<int> get deckSize =>
      $composableBuilder(column: $table.deckSize, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get revealAtUs => $composableBuilder(
    column: $table.revealAtUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get commitUs =>
      $composableBuilder(column: $table.commitUs, builder: (column) => column);

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<double> get fsrsRecall => $composableBuilder(
    column: $table.fsrsRecall,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<fsrs.State?, String> get fsrsState =>
      $composableBuilder(column: $table.fsrsState, builder: (column) => column);

  GeneratedColumn<int> get fsrsStep =>
      $composableBuilder(column: $table.fsrsStep, builder: (column) => column);

  GeneratedColumn<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fsrsDue =>
      $composableBuilder(column: $table.fsrsDue, builder: (column) => column);

  $$RunsTableAnnotationComposer get runId {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptsTable,
          AttemptRow,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (AttemptRow, $$AttemptsTableReferences),
          AttemptRow,
          PrefetchHooks Function({bool runId})
        > {
  $$AttemptsTableTableManager(_$AppDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> runId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> poemId = const Value.absent(),
                Value<bool> inverted = const Value.absent(),
                Value<int> maskLevel = const Value.absent(),
                Value<Outcome> outcome = const Value.absent(),
                Value<bool> wrong = const Value.absent(),
                Value<bool> tainted = const Value.absent(),
                Value<bool> undone = const Value.absent(),
                Value<int> deckSize = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int?> revealAtUs = const Value.absent(),
                Value<int> responseUs = const Value.absent(),
                Value<int?> commitUs = const Value.absent(),
                Value<int?> grade = const Value.absent(),
                Value<double?> fsrsRecall = const Value.absent(),
                Value<fsrs.State?> fsrsState = const Value.absent(),
                Value<int?> fsrsStep = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<DateTime?> fsrsDue = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                runId: runId,
                seq: seq,
                poemId: poemId,
                inverted: inverted,
                maskLevel: maskLevel,
                outcome: outcome,
                wrong: wrong,
                tainted: tainted,
                undone: undone,
                deckSize: deckSize,
                at: at,
                revealAtUs: revealAtUs,
                responseUs: responseUs,
                commitUs: commitUs,
                grade: grade,
                fsrsRecall: fsrsRecall,
                fsrsState: fsrsState,
                fsrsStep: fsrsStep,
                fsrsStability: fsrsStability,
                fsrsDifficulty: fsrsDifficulty,
                fsrsDue: fsrsDue,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int runId,
                required int seq,
                required int poemId,
                required bool inverted,
                Value<int> maskLevel = const Value.absent(),
                required Outcome outcome,
                Value<bool> wrong = const Value.absent(),
                Value<bool> tainted = const Value.absent(),
                Value<bool> undone = const Value.absent(),
                required int deckSize,
                required DateTime at,
                Value<int?> revealAtUs = const Value.absent(),
                required int responseUs,
                Value<int?> commitUs = const Value.absent(),
                Value<int?> grade = const Value.absent(),
                Value<double?> fsrsRecall = const Value.absent(),
                Value<fsrs.State?> fsrsState = const Value.absent(),
                Value<int?> fsrsStep = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<DateTime?> fsrsDue = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                runId: runId,
                seq: seq,
                poemId: poemId,
                inverted: inverted,
                maskLevel: maskLevel,
                outcome: outcome,
                wrong: wrong,
                tainted: tainted,
                undone: undone,
                deckSize: deckSize,
                at: at,
                revealAtUs: revealAtUs,
                responseUs: responseUs,
                commitUs: commitUs,
                grade: grade,
                fsrsRecall: fsrsRecall,
                fsrsState: fsrsState,
                fsrsStep: fsrsStep,
                fsrsStability: fsrsStability,
                fsrsDifficulty: fsrsDifficulty,
                fsrsDue: fsrsDue,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, AttemptRow>(table),
                  $$AttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.runId,
                        referencedTable: $$AttemptsTableReferences._runIdTable(
                          db,
                        ),
                        referencedColumn: $$AttemptsTableReferences
                            ._runIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptsTable,
      AttemptRow,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (AttemptRow, $$AttemptsTableReferences),
      AttemptRow,
      PrefetchHooks Function({bool runId})
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required int poemId,
  required bool inverted,
  Value<bool> unlocked,
  Value<DateTime?> unlockedAt,
  Value<fsrs.State?> fsrsState,
  Value<int?> fsrsStep,
  Value<double?> fsrsStability,
  Value<double?> fsrsDifficulty,
  Value<DateTime?> fsrsDue,
  Value<DateTime?> fsrsLastReview,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> poemId,
  Value<bool> inverted,
  Value<bool> unlocked,
  Value<DateTime?> unlockedAt,
  Value<fsrs.State?> fsrsState,
  Value<int?> fsrsStep,
  Value<double?> fsrsStability,
  Value<double?> fsrsDifficulty,
  Value<DateTime?> fsrsDue,
  Value<DateTime?> fsrsLastReview,
  Value<int> rowid,
});

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inverted => $composableBuilder(
    column: $table.inverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unlocked => $composableBuilder(
    column: $table.unlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<fsrs.State?, fsrs.State, String>
  get fsrsState => $composableBuilder(
    column: $table.fsrsState,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get fsrsStep => $composableBuilder(
    column: $table.fsrsStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fsrsDue => $composableBuilder(
    column: $table.fsrsDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fsrsLastReview => $composableBuilder(
    column: $table.fsrsLastReview,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inverted => $composableBuilder(
    column: $table.inverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unlocked => $composableBuilder(
    column: $table.unlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fsrsState => $composableBuilder(
    column: $table.fsrsState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fsrsStep => $composableBuilder(
    column: $table.fsrsStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fsrsDue => $composableBuilder(
    column: $table.fsrsDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fsrsLastReview => $composableBuilder(
    column: $table.fsrsLastReview,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get poemId =>
      $composableBuilder(column: $table.poemId, builder: (column) => column);

  GeneratedColumn<bool> get inverted =>
      $composableBuilder(column: $table.inverted, builder: (column) => column);

  GeneratedColumn<bool> get unlocked =>
      $composableBuilder(column: $table.unlocked, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<fsrs.State?, String> get fsrsState =>
      $composableBuilder(column: $table.fsrsState, builder: (column) => column);

  GeneratedColumn<int> get fsrsStep =>
      $composableBuilder(column: $table.fsrsStep, builder: (column) => column);

  GeneratedColumn<double> get fsrsStability => $composableBuilder(
    column: $table.fsrsStability,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fsrsDifficulty => $composableBuilder(
    column: $table.fsrsDifficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fsrsDue =>
      $composableBuilder(column: $table.fsrsDue, builder: (column) => column);

  GeneratedColumn<DateTime> get fsrsLastReview => $composableBuilder(
    column: $table.fsrsLastReview,
    builder: (column) => column,
  );
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          ItemRow,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
          ItemRow,
          PrefetchHooks Function()
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> poemId = const Value.absent(),
                Value<bool> inverted = const Value.absent(),
                Value<bool> unlocked = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<fsrs.State?> fsrsState = const Value.absent(),
                Value<int?> fsrsStep = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<DateTime?> fsrsDue = const Value.absent(),
                Value<DateTime?> fsrsLastReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                poemId: poemId,
                inverted: inverted,
                unlocked: unlocked,
                unlockedAt: unlockedAt,
                fsrsState: fsrsState,
                fsrsStep: fsrsStep,
                fsrsStability: fsrsStability,
                fsrsDifficulty: fsrsDifficulty,
                fsrsDue: fsrsDue,
                fsrsLastReview: fsrsLastReview,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int poemId,
                required bool inverted,
                Value<bool> unlocked = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<fsrs.State?> fsrsState = const Value.absent(),
                Value<int?> fsrsStep = const Value.absent(),
                Value<double?> fsrsStability = const Value.absent(),
                Value<double?> fsrsDifficulty = const Value.absent(),
                Value<DateTime?> fsrsDue = const Value.absent(),
                Value<DateTime?> fsrsLastReview = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                poemId: poemId,
                inverted: inverted,
                unlocked: unlocked,
                unlockedAt: unlockedAt,
                fsrsState: fsrsState,
                fsrsStep: fsrsStep,
                fsrsStability: fsrsStability,
                fsrsDifficulty: fsrsDifficulty,
                fsrsDue: fsrsDue,
                fsrsLastReview: fsrsLastReview,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, ItemRow>(table),
                  BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      ItemRow,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (ItemRow, BaseReferences<_$AppDatabase, $ItemsTable, ItemRow>),
      ItemRow,
      PrefetchHooks Function()
    >;
typedef $$IslandCompletionsTableCreateCompanionBuilder =
    IslandCompletionsCompanion Function({
      Value<int> island,
      required DateTime at,
      Value<int?> runId,
    });
typedef $$IslandCompletionsTableUpdateCompanionBuilder =
    IslandCompletionsCompanion Function({
      Value<int> island,
      Value<DateTime> at,
      Value<int?> runId,
    });

final class $$IslandCompletionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IslandCompletionsTable,
          IslandCompletionRow
        > {
  $$IslandCompletionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RunsTable _runIdTable(_$AppDatabase db) =>
      db.runs.createAlias('island_completions__run_id__runs__id');

  $$RunsTableProcessedTableManager? get runId {
    final $_column = $_itemColumn<int>('run_id');
    if ($_column == null) return null;
    final manager = $$RunsTableTableManager(
      $_db,
      $_db.runs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IslandCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $IslandCompletionsTable> {
  $$IslandCompletionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get island => $composableBuilder(
    column: $table.island,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  $$RunsTableFilterComposer get runId {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IslandCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $IslandCompletionsTable> {
  $$IslandCompletionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get island => $composableBuilder(
    column: $table.island,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  $$RunsTableOrderingComposer get runId {
    final $$RunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableOrderingComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IslandCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IslandCompletionsTable> {
  $$IslandCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get island =>
      $composableBuilder(column: $table.island, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  $$RunsTableAnnotationComposer get runId {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IslandCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IslandCompletionsTable,
          IslandCompletionRow,
          $$IslandCompletionsTableFilterComposer,
          $$IslandCompletionsTableOrderingComposer,
          $$IslandCompletionsTableAnnotationComposer,
          $$IslandCompletionsTableCreateCompanionBuilder,
          $$IslandCompletionsTableUpdateCompanionBuilder,
          (IslandCompletionRow, $$IslandCompletionsTableReferences),
          IslandCompletionRow,
          PrefetchHooks Function({bool runId})
        > {
  $$IslandCompletionsTableTableManager(
    _$AppDatabase db,
    $IslandCompletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IslandCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IslandCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IslandCompletionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> island = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int?> runId = const Value.absent(),
              }) => IslandCompletionsCompanion(
                island: island,
                at: at,
                runId: runId,
              ),
          createCompanionCallback:
              ({
                Value<int> island = const Value.absent(),
                required DateTime at,
                Value<int?> runId = const Value.absent(),
              }) => IslandCompletionsCompanion.insert(
                island: island,
                at: at,
                runId: runId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IslandCompletionsTable, IslandCompletionRow>(
                    table,
                  ),
                  $$IslandCompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.runId,
                        referencedTable: $$IslandCompletionsTableReferences
                            ._runIdTable(db),
                        referencedColumn: $$IslandCompletionsTableReferences
                            ._runIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IslandCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IslandCompletionsTable,
      IslandCompletionRow,
      $$IslandCompletionsTableFilterComposer,
      $$IslandCompletionsTableOrderingComposer,
      $$IslandCompletionsTableAnnotationComposer,
      $$IslandCompletionsTableCreateCompanionBuilder,
      $$IslandCompletionsTableUpdateCompanionBuilder,
      (IslandCompletionRow, $$IslandCompletionsTableReferences),
      IslandCompletionRow,
      PrefetchHooks Function({bool runId})
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;
typedef $$SideTripRunsTableCreateCompanionBuilder =
    SideTripRunsCompanion Function({
      Value<int> id,
      required SideTrip game,
      required DateTime startedAt,
      required DateTime endedAt,
      required int day,
      required bool ranked,
      Value<int?> level,
      Value<int?> score,
      Value<int?> maxScore,
      required bool completed,
      Value<double?> rating,
      Value<double?> performance,
      Value<String> meta,
    });
typedef $$SideTripRunsTableUpdateCompanionBuilder =
    SideTripRunsCompanion Function({
      Value<int> id,
      Value<SideTrip> game,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> day,
      Value<bool> ranked,
      Value<int?> level,
      Value<int?> score,
      Value<int?> maxScore,
      Value<bool> completed,
      Value<double?> rating,
      Value<double?> performance,
      Value<String> meta,
    });

final class $$SideTripRunsTableReferences
    extends BaseReferences<_$AppDatabase, $SideTripRunsTable, SideTripRun> {
  $$SideTripRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _dayTable(_$AppDatabase db) =>
      db.days.createAlias('side_trip_runs__day__days__day');

  $$DaysTableProcessedTableManager get day {
    final $_column = $_itemColumn<int>('day')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.day.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SideTripAnswersTable, List<SideTripAnswerRow>>
  _sideTripAnswersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sideTripAnswers,
    aliasName: 'side_trip_runs__id__side_trip_answers__run_id',
  );

  $$SideTripAnswersTableProcessedTableManager get sideTripAnswersRefs {
    final manager = $$SideTripAnswersTableTableManager(
      $_db,
      $_db.sideTripAnswers,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sideTripAnswersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SideTripRunsTableFilterComposer
    extends Composer<_$AppDatabase, $SideTripRunsTable> {
  $$SideTripRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SideTrip, SideTrip, String> get game =>
      $composableBuilder(
        column: $table.game,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ranked => $composableBuilder(
    column: $table.ranked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnFilters(column),
  );

  $$DaysTableFilterComposer get day {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sideTripAnswersRefs(
    Expression<bool> Function($$SideTripAnswersTableFilterComposer f) f,
  ) {
    final $$SideTripAnswersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sideTripAnswers,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SideTripAnswersTableFilterComposer(
            $db: $db,
            $table: $db.sideTripAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SideTripRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $SideTripRunsTable> {
  $$SideTripRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ranked => $composableBuilder(
    column: $table.ranked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxScore => $composableBuilder(
    column: $table.maxScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get day {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SideTripRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SideTripRunsTable> {
  $$SideTripRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SideTrip, String> get game =>
      $composableBuilder(column: $table.game, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get ranked =>
      $composableBuilder(column: $table.ranked, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get maxScore =>
      $composableBuilder(column: $table.maxScore, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<double> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);

  $$DaysTableAnnotationComposer get day {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sideTripAnswersRefs<T extends Object>(
    Expression<T> Function($$SideTripAnswersTableAnnotationComposer a) f,
  ) {
    final $$SideTripAnswersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sideTripAnswers,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SideTripAnswersTableAnnotationComposer(
            $db: $db,
            $table: $db.sideTripAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SideTripRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SideTripRunsTable,
          SideTripRun,
          $$SideTripRunsTableFilterComposer,
          $$SideTripRunsTableOrderingComposer,
          $$SideTripRunsTableAnnotationComposer,
          $$SideTripRunsTableCreateCompanionBuilder,
          $$SideTripRunsTableUpdateCompanionBuilder,
          (SideTripRun, $$SideTripRunsTableReferences),
          SideTripRun,
          PrefetchHooks Function({bool day, bool sideTripAnswersRefs})
        > {
  $$SideTripRunsTableTableManager(_$AppDatabase db, $SideTripRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SideTripRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SideTripRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SideTripRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<SideTrip> game = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<bool> ranked = const Value.absent(),
                Value<int?> level = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> maxScore = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<double?> performance = const Value.absent(),
                Value<String> meta = const Value.absent(),
              }) => SideTripRunsCompanion(
                id: id,
                game: game,
                startedAt: startedAt,
                endedAt: endedAt,
                day: day,
                ranked: ranked,
                level: level,
                score: score,
                maxScore: maxScore,
                completed: completed,
                rating: rating,
                performance: performance,
                meta: meta,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required SideTrip game,
                required DateTime startedAt,
                required DateTime endedAt,
                required int day,
                required bool ranked,
                Value<int?> level = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> maxScore = const Value.absent(),
                required bool completed,
                Value<double?> rating = const Value.absent(),
                Value<double?> performance = const Value.absent(),
                Value<String> meta = const Value.absent(),
              }) => SideTripRunsCompanion.insert(
                id: id,
                game: game,
                startedAt: startedAt,
                endedAt: endedAt,
                day: day,
                ranked: ranked,
                level: level,
                score: score,
                maxScore: maxScore,
                completed: completed,
                rating: rating,
                performance: performance,
                meta: meta,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SideTripRunsTable, SideTripRun>(table),
                  $$SideTripRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({day = false, sideTripAnswersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sideTripAnswersRefs) db.sideTripAnswers,
              ],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (day) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.day,
                        referencedTable: $$SideTripRunsTableReferences
                            ._dayTable(db),
                        referencedColumn: $$SideTripRunsTableReferences
                            ._dayTable(db)
                            .day,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sideTripAnswersRefs)
                    await $_getPrefetchedData<
                      SideTripRun,
                      $SideTripRunsTable,
                      SideTripAnswerRow
                    >(
                      currentTable: table,
                      referencedTable: $$SideTripRunsTableReferences
                          ._sideTripAnswersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SideTripRunsTableReferences(
                            db,
                            table,
                            p0,
                          ).sideTripAnswersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.runId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SideTripRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SideTripRunsTable,
      SideTripRun,
      $$SideTripRunsTableFilterComposer,
      $$SideTripRunsTableOrderingComposer,
      $$SideTripRunsTableAnnotationComposer,
      $$SideTripRunsTableCreateCompanionBuilder,
      $$SideTripRunsTableUpdateCompanionBuilder,
      (SideTripRun, $$SideTripRunsTableReferences),
      SideTripRun,
      PrefetchHooks Function({bool day, bool sideTripAnswersRefs})
    >;
typedef $$SideTripAnswersTableCreateCompanionBuilder =
    SideTripAnswersCompanion Function({
      Value<int> id,
      required int runId,
      required int seq,
      required int poemId,
      required int wrongTaps,
      Value<bool> gaveUp,
      Value<int?> responseUs,
      required DateTime at,
      Value<TapProximity?> firstTap,
      Value<int?> firstTapCard,
      Value<int?> firstTapUs,
      Value<TapProximity?> secondTap,
      Value<int?> secondTapCard,
    });
typedef $$SideTripAnswersTableUpdateCompanionBuilder =
    SideTripAnswersCompanion Function({
      Value<int> id,
      Value<int> runId,
      Value<int> seq,
      Value<int> poemId,
      Value<int> wrongTaps,
      Value<bool> gaveUp,
      Value<int?> responseUs,
      Value<DateTime> at,
      Value<TapProximity?> firstTap,
      Value<int?> firstTapCard,
      Value<int?> firstTapUs,
      Value<TapProximity?> secondTap,
      Value<int?> secondTapCard,
    });

final class $$SideTripAnswersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SideTripAnswersTable,
          SideTripAnswerRow
        > {
  $$SideTripAnswersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SideTripRunsTable _runIdTable(_$AppDatabase db) => db.sideTripRuns
      .createAlias('side_trip_answers__run_id__side_trip_runs__id');

  $$SideTripRunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<int>('run_id')!;

    final manager = $$SideTripRunsTableTableManager(
      $_db,
      $_db.sideTripRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SideTripAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $SideTripAnswersTable> {
  $$SideTripAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongTaps => $composableBuilder(
    column: $table.wrongTaps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gaveUp => $composableBuilder(
    column: $table.gaveUp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TapProximity?, TapProximity, String>
  get firstTap => $composableBuilder(
    column: $table.firstTap,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get firstTapCard => $composableBuilder(
    column: $table.firstTapCard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstTapUs => $composableBuilder(
    column: $table.firstTapUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TapProximity?, TapProximity, String>
  get secondTap => $composableBuilder(
    column: $table.secondTap,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get secondTapCard => $composableBuilder(
    column: $table.secondTapCard,
    builder: (column) => ColumnFilters(column),
  );

  $$SideTripRunsTableFilterComposer get runId {
    final $$SideTripRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.sideTripRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SideTripRunsTableFilterComposer(
            $db: $db,
            $table: $db.sideTripRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SideTripAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $SideTripAnswersTable> {
  $$SideTripAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongTaps => $composableBuilder(
    column: $table.wrongTaps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gaveUp => $composableBuilder(
    column: $table.gaveUp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstTap => $composableBuilder(
    column: $table.firstTap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstTapCard => $composableBuilder(
    column: $table.firstTapCard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstTapUs => $composableBuilder(
    column: $table.firstTapUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondTap => $composableBuilder(
    column: $table.secondTap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get secondTapCard => $composableBuilder(
    column: $table.secondTapCard,
    builder: (column) => ColumnOrderings(column),
  );

  $$SideTripRunsTableOrderingComposer get runId {
    final $$SideTripRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.sideTripRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SideTripRunsTableOrderingComposer(
            $db: $db,
            $table: $db.sideTripRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SideTripAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SideTripAnswersTable> {
  $$SideTripAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get poemId =>
      $composableBuilder(column: $table.poemId, builder: (column) => column);

  GeneratedColumn<int> get wrongTaps =>
      $composableBuilder(column: $table.wrongTaps, builder: (column) => column);

  GeneratedColumn<bool> get gaveUp =>
      $composableBuilder(column: $table.gaveUp, builder: (column) => column);

  GeneratedColumn<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TapProximity?, String> get firstTap =>
      $composableBuilder(column: $table.firstTap, builder: (column) => column);

  GeneratedColumn<int> get firstTapCard => $composableBuilder(
    column: $table.firstTapCard,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstTapUs => $composableBuilder(
    column: $table.firstTapUs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TapProximity?, String> get secondTap =>
      $composableBuilder(column: $table.secondTap, builder: (column) => column);

  GeneratedColumn<int> get secondTapCard => $composableBuilder(
    column: $table.secondTapCard,
    builder: (column) => column,
  );

  $$SideTripRunsTableAnnotationComposer get runId {
    final $$SideTripRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.sideTripRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SideTripRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.sideTripRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SideTripAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SideTripAnswersTable,
          SideTripAnswerRow,
          $$SideTripAnswersTableFilterComposer,
          $$SideTripAnswersTableOrderingComposer,
          $$SideTripAnswersTableAnnotationComposer,
          $$SideTripAnswersTableCreateCompanionBuilder,
          $$SideTripAnswersTableUpdateCompanionBuilder,
          (SideTripAnswerRow, $$SideTripAnswersTableReferences),
          SideTripAnswerRow,
          PrefetchHooks Function({bool runId})
        > {
  $$SideTripAnswersTableTableManager(
    _$AppDatabase db,
    $SideTripAnswersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SideTripAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SideTripAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SideTripAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> runId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> poemId = const Value.absent(),
                Value<int> wrongTaps = const Value.absent(),
                Value<bool> gaveUp = const Value.absent(),
                Value<int?> responseUs = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<TapProximity?> firstTap = const Value.absent(),
                Value<int?> firstTapCard = const Value.absent(),
                Value<int?> firstTapUs = const Value.absent(),
                Value<TapProximity?> secondTap = const Value.absent(),
                Value<int?> secondTapCard = const Value.absent(),
              }) => SideTripAnswersCompanion(
                id: id,
                runId: runId,
                seq: seq,
                poemId: poemId,
                wrongTaps: wrongTaps,
                gaveUp: gaveUp,
                responseUs: responseUs,
                at: at,
                firstTap: firstTap,
                firstTapCard: firstTapCard,
                firstTapUs: firstTapUs,
                secondTap: secondTap,
                secondTapCard: secondTapCard,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int runId,
                required int seq,
                required int poemId,
                required int wrongTaps,
                Value<bool> gaveUp = const Value.absent(),
                Value<int?> responseUs = const Value.absent(),
                required DateTime at,
                Value<TapProximity?> firstTap = const Value.absent(),
                Value<int?> firstTapCard = const Value.absent(),
                Value<int?> firstTapUs = const Value.absent(),
                Value<TapProximity?> secondTap = const Value.absent(),
                Value<int?> secondTapCard = const Value.absent(),
              }) => SideTripAnswersCompanion.insert(
                id: id,
                runId: runId,
                seq: seq,
                poemId: poemId,
                wrongTaps: wrongTaps,
                gaveUp: gaveUp,
                responseUs: responseUs,
                at: at,
                firstTap: firstTap,
                firstTapCard: firstTapCard,
                firstTapUs: firstTapUs,
                secondTap: secondTap,
                secondTapCard: secondTapCard,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SideTripAnswersTable, SideTripAnswerRow>(table),
                  $$SideTripAnswersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.runId,
                        referencedTable: $$SideTripAnswersTableReferences
                            ._runIdTable(db),
                        referencedColumn: $$SideTripAnswersTableReferences
                            ._runIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SideTripAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SideTripAnswersTable,
      SideTripAnswerRow,
      $$SideTripAnswersTableFilterComposer,
      $$SideTripAnswersTableOrderingComposer,
      $$SideTripAnswersTableAnnotationComposer,
      $$SideTripAnswersTableCreateCompanionBuilder,
      $$SideTripAnswersTableUpdateCompanionBuilder,
      (SideTripAnswerRow, $$SideTripAnswersTableReferences),
      SideTripAnswerRow,
      PrefetchHooks Function({bool runId})
    >;
typedef $$DayCardsTableCreateCompanionBuilder = DayCardsCompanion Function({
  required int day,
  required int poemId,
  required bool inverted,
  required StepKind kind,
  Value<int> rowid,
});
typedef $$DayCardsTableUpdateCompanionBuilder = DayCardsCompanion Function({
  Value<int> day,
  Value<int> poemId,
  Value<bool> inverted,
  Value<StepKind> kind,
  Value<int> rowid,
});

final class $$DayCardsTableReferences
    extends BaseReferences<_$AppDatabase, $DayCardsTable, DayCardRow> {
  $$DayCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DaysTable _dayTable(_$AppDatabase db) =>
      db.days.createAlias('day_cards__day__days__day');

  $$DaysTableProcessedTableManager get day {
    final $_column = $_itemColumn<int>('day')!;

    final manager = $$DaysTableTableManager(
      $_db,
      $_db.days,
    ).filter((f) => f.day.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DayCardsTableFilterComposer
    extends Composer<_$AppDatabase, $DayCardsTable> {
  $$DayCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inverted => $composableBuilder(
    column: $table.inverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StepKind, StepKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$DaysTableFilterComposer get day {
    final $$DaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableFilterComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayCardsTable> {
  $$DayCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inverted => $composableBuilder(
    column: $table.inverted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  $$DaysTableOrderingComposer get day {
    final $$DaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableOrderingComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayCardsTable> {
  $$DayCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get poemId =>
      $composableBuilder(column: $table.poemId, builder: (column) => column);

  GeneratedColumn<bool> get inverted =>
      $composableBuilder(column: $table.inverted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<StepKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  $$DaysTableAnnotationComposer get day {
    final $$DaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.day,
      referencedTable: $db.days,
      getReferencedColumn: (t) => t.day,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DaysTableAnnotationComposer(
            $db: $db,
            $table: $db.days,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DayCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayCardsTable,
          DayCardRow,
          $$DayCardsTableFilterComposer,
          $$DayCardsTableOrderingComposer,
          $$DayCardsTableAnnotationComposer,
          $$DayCardsTableCreateCompanionBuilder,
          $$DayCardsTableUpdateCompanionBuilder,
          (DayCardRow, $$DayCardsTableReferences),
          DayCardRow,
          PrefetchHooks Function({bool day})
        > {
  $$DayCardsTableTableManager(_$AppDatabase db, $DayCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> day = const Value.absent(),
                Value<int> poemId = const Value.absent(),
                Value<bool> inverted = const Value.absent(),
                Value<StepKind> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayCardsCompanion(
                day: day,
                poemId: poemId,
                inverted: inverted,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int day,
                required int poemId,
                required bool inverted,
                required StepKind kind,
                Value<int> rowid = const Value.absent(),
              }) => DayCardsCompanion.insert(
                day: day,
                poemId: poemId,
                inverted: inverted,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayCardsTable, DayCardRow>(table),
                  $$DayCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({day = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (day) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.day,
                        referencedTable: $$DayCardsTableReferences._dayTable(
                          db,
                        ),
                        referencedColumn: $$DayCardsTableReferences
                            ._dayTable(db)
                            .day,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DayCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayCardsTable,
      DayCardRow,
      $$DayCardsTableFilterComposer,
      $$DayCardsTableOrderingComposer,
      $$DayCardsTableAnnotationComposer,
      $$DayCardsTableCreateCompanionBuilder,
      $$DayCardsTableUpdateCompanionBuilder,
      (DayCardRow, $$DayCardsTableReferences),
      DayCardRow,
      PrefetchHooks Function({bool day})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DaysTableTableManager get days => $$DaysTableTableManager(_db, _db.days);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$IslandCompletionsTableTableManager get islandCompletions =>
      $$IslandCompletionsTableTableManager(_db, _db.islandCompletions);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$SideTripRunsTableTableManager get sideTripRuns =>
      $$SideTripRunsTableTableManager(_db, _db.sideTripRuns);
  $$SideTripAnswersTableTableManager get sideTripAnswers =>
      $$SideTripAnswersTableTableManager(_db, _db.sideTripAnswers);
  $$DayCardsTableTableManager get dayCards =>
      $$DayCardsTableTableManager(_db, _db.dayCards);
}
