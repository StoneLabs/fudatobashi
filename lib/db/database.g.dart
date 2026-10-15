// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _orientationMeta = const VerificationMeta(
    'orientation',
  );
  @override
  late final GeneratedColumn<int> orientation = GeneratedColumn<int>(
    'orientation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardCountMeta = const VerificationMeta(
    'cardCount',
  );
  @override
  late final GeneratedColumn<int> cardCount = GeneratedColumn<int>(
    'card_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalUsMeta = const VerificationMeta(
    'totalUs',
  );
  @override
  late final GeneratedColumn<int> totalUs = GeneratedColumn<int>(
    'total_us',
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
    startedAt,
    mode,
    setIds,
    orientation,
    cardCount,
    totalUs,
    completed,
    meta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
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
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('set_ids')) {
      context.handle(
        _setIdsMeta,
        setIds.isAcceptableOrUnknown(data['set_ids']!, _setIdsMeta),
      );
    }
    if (data.containsKey('orientation')) {
      context.handle(
        _orientationMeta,
        orientation.isAcceptableOrUnknown(
          data['orientation']!,
          _orientationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orientationMeta);
    }
    if (data.containsKey('card_count')) {
      context.handle(
        _cardCountMeta,
        cardCount.isAcceptableOrUnknown(data['card_count']!, _cardCountMeta),
      );
    } else if (isInserting) {
      context.missing(_cardCountMeta);
    }
    if (data.containsKey('total_us')) {
      context.handle(
        _totalUsMeta,
        totalUs.isAcceptableOrUnknown(data['total_us']!, _totalUsMeta),
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
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      setIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_ids'],
      )!,
      orientation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orientation'],
      )!,
      cardCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_count'],
      )!,
      totalUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_us'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      meta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final DateTime startedAt;

  /// `PlayMode.name`: training, free, nigate, ranked or exam.
  final String mode;

  /// JSON list of FudaSet ids that defined the deck (empty for training;
  /// `PlayConfig.knownDeckId` for free practice's default deck). A
  /// hand-picked deck's cards are in [meta] as `cardIds`.
  final String setIds;

  /// The old free-play orientation setting (0 random, 1 upright only, 2
  /// inverted only); new runs store 0.
  final int orientation;
  final int cardCount;

  /// First reveal → last swipe, µs. Null when the run was ended early.
  final int? totalUs;
  final bool completed;

  /// Free-form JSON (mask settings, goal at the time, a ranked run's or an
  /// exam try's misses and scored time, …).
  final String meta;
  const Session({
    required this.id,
    required this.startedAt,
    required this.mode,
    required this.setIds,
    required this.orientation,
    required this.cardCount,
    this.totalUs,
    required this.completed,
    required this.meta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['mode'] = Variable<String>(mode);
    map['set_ids'] = Variable<String>(setIds);
    map['orientation'] = Variable<int>(orientation);
    map['card_count'] = Variable<int>(cardCount);
    if (!nullToAbsent || totalUs != null) {
      map['total_us'] = Variable<int>(totalUs);
    }
    map['completed'] = Variable<bool>(completed);
    map['meta'] = Variable<String>(meta);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      mode: Value(mode),
      setIds: Value(setIds),
      orientation: Value(orientation),
      cardCount: Value(cardCount),
      totalUs: totalUs == null && nullToAbsent
          ? const Value.absent()
          : Value(totalUs),
      completed: Value(completed),
      meta: Value(meta),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      mode: serializer.fromJson<String>(json['mode']),
      setIds: serializer.fromJson<String>(json['setIds']),
      orientation: serializer.fromJson<int>(json['orientation']),
      cardCount: serializer.fromJson<int>(json['cardCount']),
      totalUs: serializer.fromJson<int?>(json['totalUs']),
      completed: serializer.fromJson<bool>(json['completed']),
      meta: serializer.fromJson<String>(json['meta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'mode': serializer.toJson<String>(mode),
      'setIds': serializer.toJson<String>(setIds),
      'orientation': serializer.toJson<int>(orientation),
      'cardCount': serializer.toJson<int>(cardCount),
      'totalUs': serializer.toJson<int?>(totalUs),
      'completed': serializer.toJson<bool>(completed),
      'meta': serializer.toJson<String>(meta),
    };
  }

  Session copyWith({
    int? id,
    DateTime? startedAt,
    String? mode,
    String? setIds,
    int? orientation,
    int? cardCount,
    Value<int?> totalUs = const Value.absent(),
    bool? completed,
    String? meta,
  }) => Session(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    mode: mode ?? this.mode,
    setIds: setIds ?? this.setIds,
    orientation: orientation ?? this.orientation,
    cardCount: cardCount ?? this.cardCount,
    totalUs: totalUs.present ? totalUs.value : this.totalUs,
    completed: completed ?? this.completed,
    meta: meta ?? this.meta,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      mode: data.mode.present ? data.mode.value : this.mode,
      setIds: data.setIds.present ? data.setIds.value : this.setIds,
      orientation: data.orientation.present
          ? data.orientation.value
          : this.orientation,
      cardCount: data.cardCount.present ? data.cardCount.value : this.cardCount,
      totalUs: data.totalUs.present ? data.totalUs.value : this.totalUs,
      completed: data.completed.present ? data.completed.value : this.completed,
      meta: data.meta.present ? data.meta.value : this.meta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('mode: $mode, ')
          ..write('setIds: $setIds, ')
          ..write('orientation: $orientation, ')
          ..write('cardCount: $cardCount, ')
          ..write('totalUs: $totalUs, ')
          ..write('completed: $completed, ')
          ..write('meta: $meta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    mode,
    setIds,
    orientation,
    cardCount,
    totalUs,
    completed,
    meta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.mode == this.mode &&
          other.setIds == this.setIds &&
          other.orientation == this.orientation &&
          other.cardCount == this.cardCount &&
          other.totalUs == this.totalUs &&
          other.completed == this.completed &&
          other.meta == this.meta);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<String> mode;
  final Value<String> setIds;
  final Value<int> orientation;
  final Value<int> cardCount;
  final Value<int?> totalUs;
  final Value<bool> completed;
  final Value<String> meta;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.mode = const Value.absent(),
    this.setIds = const Value.absent(),
    this.orientation = const Value.absent(),
    this.cardCount = const Value.absent(),
    this.totalUs = const Value.absent(),
    this.completed = const Value.absent(),
    this.meta = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    required String mode,
    this.setIds = const Value.absent(),
    required int orientation,
    required int cardCount,
    this.totalUs = const Value.absent(),
    required bool completed,
    this.meta = const Value.absent(),
  }) : startedAt = Value(startedAt),
       mode = Value(mode),
       orientation = Value(orientation),
       cardCount = Value(cardCount),
       completed = Value(completed);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<String>? mode,
    Expression<String>? setIds,
    Expression<int>? orientation,
    Expression<int>? cardCount,
    Expression<int>? totalUs,
    Expression<bool>? completed,
    Expression<String>? meta,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (mode != null) 'mode': mode,
      if (setIds != null) 'set_ids': setIds,
      if (orientation != null) 'orientation': orientation,
      if (cardCount != null) 'card_count': cardCount,
      if (totalUs != null) 'total_us': totalUs,
      if (completed != null) 'completed': completed,
      if (meta != null) 'meta': meta,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<String>? mode,
    Value<String>? setIds,
    Value<int>? orientation,
    Value<int>? cardCount,
    Value<int?>? totalUs,
    Value<bool>? completed,
    Value<String>? meta,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      mode: mode ?? this.mode,
      setIds: setIds ?? this.setIds,
      orientation: orientation ?? this.orientation,
      cardCount: cardCount ?? this.cardCount,
      totalUs: totalUs ?? this.totalUs,
      completed: completed ?? this.completed,
      meta: meta ?? this.meta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (setIds.present) {
      map['set_ids'] = Variable<String>(setIds.value);
    }
    if (orientation.present) {
      map['orientation'] = Variable<int>(orientation.value);
    }
    if (cardCount.present) {
      map['card_count'] = Variable<int>(cardCount.value);
    }
    if (totalUs.present) {
      map['total_us'] = Variable<int>(totalUs.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (meta.present) {
      map['meta'] = Variable<String>(meta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('mode: $mode, ')
          ..write('setIds: $setIds, ')
          ..write('orientation: $orientation, ')
          ..write('cardCount: $cardCount, ')
          ..write('totalUs: $totalUs, ')
          ..write('completed: $completed, ')
          ..write('meta: $meta')
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
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
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
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<int> outcome = GeneratedColumn<int>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    seq,
    poemId,
    inverted,
    maskLevel,
    responseUs,
    outcome,
    wrong,
    tainted,
    undone,
    deckSize,
    at,
    grade,
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
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
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
    if (data.containsKey('response_us')) {
      context.handle(
        _responseUsMeta,
        responseUs.isAcceptableOrUnknown(data['response_us']!, _responseUsMeta),
      );
    } else if (isInserting) {
      context.missing(_responseUsMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
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
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
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
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
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
      responseUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_us'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outcome'],
      )!,
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
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  final int id;
  final int sessionId;
  final int seq;
  final int poemId;
  final bool inverted;
  final int maskLevel;

  /// Reveal → response, µs.
  final int responseUs;

  /// Outcome index: 0 known, 1 don't know.
  final int outcome;
  final bool wrong;
  final bool tainted;
  final bool undone;
  final int deckSize;
  final DateTime at;

  /// FSRS rating applied for this attempt (1–4), null if none.
  final int? grade;
  const AttemptRow({
    required this.id,
    required this.sessionId,
    required this.seq,
    required this.poemId,
    required this.inverted,
    required this.maskLevel,
    required this.responseUs,
    required this.outcome,
    required this.wrong,
    required this.tainted,
    required this.undone,
    required this.deckSize,
    required this.at,
    this.grade,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['seq'] = Variable<int>(seq);
    map['poem_id'] = Variable<int>(poemId);
    map['inverted'] = Variable<bool>(inverted);
    map['mask_level'] = Variable<int>(maskLevel);
    map['response_us'] = Variable<int>(responseUs);
    map['outcome'] = Variable<int>(outcome);
    map['wrong'] = Variable<bool>(wrong);
    map['tainted'] = Variable<bool>(tainted);
    map['undone'] = Variable<bool>(undone);
    map['deck_size'] = Variable<int>(deckSize);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<int>(grade);
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      seq: Value(seq),
      poemId: Value(poemId),
      inverted: Value(inverted),
      maskLevel: Value(maskLevel),
      responseUs: Value(responseUs),
      outcome: Value(outcome),
      wrong: Value(wrong),
      tainted: Value(tainted),
      undone: Value(undone),
      deckSize: Value(deckSize),
      at: Value(at),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      seq: serializer.fromJson<int>(json['seq']),
      poemId: serializer.fromJson<int>(json['poemId']),
      inverted: serializer.fromJson<bool>(json['inverted']),
      maskLevel: serializer.fromJson<int>(json['maskLevel']),
      responseUs: serializer.fromJson<int>(json['responseUs']),
      outcome: serializer.fromJson<int>(json['outcome']),
      wrong: serializer.fromJson<bool>(json['wrong']),
      tainted: serializer.fromJson<bool>(json['tainted']),
      undone: serializer.fromJson<bool>(json['undone']),
      deckSize: serializer.fromJson<int>(json['deckSize']),
      at: serializer.fromJson<DateTime>(json['at']),
      grade: serializer.fromJson<int?>(json['grade']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'seq': serializer.toJson<int>(seq),
      'poemId': serializer.toJson<int>(poemId),
      'inverted': serializer.toJson<bool>(inverted),
      'maskLevel': serializer.toJson<int>(maskLevel),
      'responseUs': serializer.toJson<int>(responseUs),
      'outcome': serializer.toJson<int>(outcome),
      'wrong': serializer.toJson<bool>(wrong),
      'tainted': serializer.toJson<bool>(tainted),
      'undone': serializer.toJson<bool>(undone),
      'deckSize': serializer.toJson<int>(deckSize),
      'at': serializer.toJson<DateTime>(at),
      'grade': serializer.toJson<int?>(grade),
    };
  }

  AttemptRow copyWith({
    int? id,
    int? sessionId,
    int? seq,
    int? poemId,
    bool? inverted,
    int? maskLevel,
    int? responseUs,
    int? outcome,
    bool? wrong,
    bool? tainted,
    bool? undone,
    int? deckSize,
    DateTime? at,
    Value<int?> grade = const Value.absent(),
  }) => AttemptRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    seq: seq ?? this.seq,
    poemId: poemId ?? this.poemId,
    inverted: inverted ?? this.inverted,
    maskLevel: maskLevel ?? this.maskLevel,
    responseUs: responseUs ?? this.responseUs,
    outcome: outcome ?? this.outcome,
    wrong: wrong ?? this.wrong,
    tainted: tainted ?? this.tainted,
    undone: undone ?? this.undone,
    deckSize: deckSize ?? this.deckSize,
    at: at ?? this.at,
    grade: grade.present ? grade.value : this.grade,
  );
  AttemptRow copyWithCompanion(AttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      seq: data.seq.present ? data.seq.value : this.seq,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      inverted: data.inverted.present ? data.inverted.value : this.inverted,
      maskLevel: data.maskLevel.present ? data.maskLevel.value : this.maskLevel,
      responseUs: data.responseUs.present
          ? data.responseUs.value
          : this.responseUs,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      wrong: data.wrong.present ? data.wrong.value : this.wrong,
      tainted: data.tainted.present ? data.tainted.value : this.tainted,
      undone: data.undone.present ? data.undone.value : this.undone,
      deckSize: data.deckSize.present ? data.deckSize.value : this.deckSize,
      at: data.at.present ? data.at.value : this.at,
      grade: data.grade.present ? data.grade.value : this.grade,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('maskLevel: $maskLevel, ')
          ..write('responseUs: $responseUs, ')
          ..write('outcome: $outcome, ')
          ..write('wrong: $wrong, ')
          ..write('tainted: $tainted, ')
          ..write('undone: $undone, ')
          ..write('deckSize: $deckSize, ')
          ..write('at: $at, ')
          ..write('grade: $grade')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    seq,
    poemId,
    inverted,
    maskLevel,
    responseUs,
    outcome,
    wrong,
    tainted,
    undone,
    deckSize,
    at,
    grade,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.seq == this.seq &&
          other.poemId == this.poemId &&
          other.inverted == this.inverted &&
          other.maskLevel == this.maskLevel &&
          other.responseUs == this.responseUs &&
          other.outcome == this.outcome &&
          other.wrong == this.wrong &&
          other.tainted == this.tainted &&
          other.undone == this.undone &&
          other.deckSize == this.deckSize &&
          other.at == this.at &&
          other.grade == this.grade);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> seq;
  final Value<int> poemId;
  final Value<bool> inverted;
  final Value<int> maskLevel;
  final Value<int> responseUs;
  final Value<int> outcome;
  final Value<bool> wrong;
  final Value<bool> tainted;
  final Value<bool> undone;
  final Value<int> deckSize;
  final Value<DateTime> at;
  final Value<int?> grade;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.seq = const Value.absent(),
    this.poemId = const Value.absent(),
    this.inverted = const Value.absent(),
    this.maskLevel = const Value.absent(),
    this.responseUs = const Value.absent(),
    this.outcome = const Value.absent(),
    this.wrong = const Value.absent(),
    this.tainted = const Value.absent(),
    this.undone = const Value.absent(),
    this.deckSize = const Value.absent(),
    this.at = const Value.absent(),
    this.grade = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int seq,
    required int poemId,
    required bool inverted,
    this.maskLevel = const Value.absent(),
    required int responseUs,
    required int outcome,
    this.wrong = const Value.absent(),
    this.tainted = const Value.absent(),
    this.undone = const Value.absent(),
    required int deckSize,
    required DateTime at,
    this.grade = const Value.absent(),
  }) : sessionId = Value(sessionId),
       seq = Value(seq),
       poemId = Value(poemId),
       inverted = Value(inverted),
       responseUs = Value(responseUs),
       outcome = Value(outcome),
       deckSize = Value(deckSize),
       at = Value(at);
  static Insertable<AttemptRow> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? seq,
    Expression<int>? poemId,
    Expression<bool>? inverted,
    Expression<int>? maskLevel,
    Expression<int>? responseUs,
    Expression<int>? outcome,
    Expression<bool>? wrong,
    Expression<bool>? tainted,
    Expression<bool>? undone,
    Expression<int>? deckSize,
    Expression<DateTime>? at,
    Expression<int>? grade,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (seq != null) 'seq': seq,
      if (poemId != null) 'poem_id': poemId,
      if (inverted != null) 'inverted': inverted,
      if (maskLevel != null) 'mask_level': maskLevel,
      if (responseUs != null) 'response_us': responseUs,
      if (outcome != null) 'outcome': outcome,
      if (wrong != null) 'wrong': wrong,
      if (tainted != null) 'tainted': tainted,
      if (undone != null) 'undone': undone,
      if (deckSize != null) 'deck_size': deckSize,
      if (at != null) 'at': at,
      if (grade != null) 'grade': grade,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? seq,
    Value<int>? poemId,
    Value<bool>? inverted,
    Value<int>? maskLevel,
    Value<int>? responseUs,
    Value<int>? outcome,
    Value<bool>? wrong,
    Value<bool>? tainted,
    Value<bool>? undone,
    Value<int>? deckSize,
    Value<DateTime>? at,
    Value<int?>? grade,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      seq: seq ?? this.seq,
      poemId: poemId ?? this.poemId,
      inverted: inverted ?? this.inverted,
      maskLevel: maskLevel ?? this.maskLevel,
      responseUs: responseUs ?? this.responseUs,
      outcome: outcome ?? this.outcome,
      wrong: wrong ?? this.wrong,
      tainted: tainted ?? this.tainted,
      undone: undone ?? this.undone,
      deckSize: deckSize ?? this.deckSize,
      at: at ?? this.at,
      grade: grade ?? this.grade,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
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
    if (responseUs.present) {
      map['response_us'] = Variable<int>(responseUs.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<int>(outcome.value);
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
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('seq: $seq, ')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('maskLevel: $maskLevel, ')
          ..write('responseUs: $responseUs, ')
          ..write('outcome: $outcome, ')
          ..write('wrong: $wrong, ')
          ..write('tainted: $tainted, ')
          ..write('undone: $undone, ')
          ..write('deckSize: $deckSize, ')
          ..write('at: $at, ')
          ..write('grade: $grade')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
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
  static const VerificationMeta _fsrsMeta = const VerificationMeta('fsrs');
  @override
  late final GeneratedColumn<String> fsrs = GeneratedColumn<String>(
    'fsrs',
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
  @override
  List<GeneratedColumn> get $columns => [
    poemId,
    inverted,
    unlocked,
    unlockedAt,
    fsrs,
    maskLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
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
    if (data.containsKey('fsrs')) {
      context.handle(
        _fsrsMeta,
        fsrs.isAcceptableOrUnknown(data['fsrs']!, _fsrsMeta),
      );
    }
    if (data.containsKey('mask_level')) {
      context.handle(
        _maskLevelMeta,
        maskLevel.isAcceptableOrUnknown(data['mask_level']!, _maskLevelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {poemId, inverted};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
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
      fsrs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fsrs'],
      ),
      maskLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mask_level'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final int poemId;
  final bool inverted;
  final bool unlocked;
  final DateTime? unlockedAt;

  /// fsrs Card.toMap() as JSON.
  final String? fsrs;
  final int maskLevel;
  const Item({
    required this.poemId,
    required this.inverted,
    required this.unlocked,
    this.unlockedAt,
    this.fsrs,
    required this.maskLevel,
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
    if (!nullToAbsent || fsrs != null) {
      map['fsrs'] = Variable<String>(fsrs);
    }
    map['mask_level'] = Variable<int>(maskLevel);
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
      fsrs: fsrs == null && nullToAbsent ? const Value.absent() : Value(fsrs),
      maskLevel: Value(maskLevel),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      poemId: serializer.fromJson<int>(json['poemId']),
      inverted: serializer.fromJson<bool>(json['inverted']),
      unlocked: serializer.fromJson<bool>(json['unlocked']),
      unlockedAt: serializer.fromJson<DateTime?>(json['unlockedAt']),
      fsrs: serializer.fromJson<String?>(json['fsrs']),
      maskLevel: serializer.fromJson<int>(json['maskLevel']),
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
      'fsrs': serializer.toJson<String?>(fsrs),
      'maskLevel': serializer.toJson<int>(maskLevel),
    };
  }

  Item copyWith({
    int? poemId,
    bool? inverted,
    bool? unlocked,
    Value<DateTime?> unlockedAt = const Value.absent(),
    Value<String?> fsrs = const Value.absent(),
    int? maskLevel,
  }) => Item(
    poemId: poemId ?? this.poemId,
    inverted: inverted ?? this.inverted,
    unlocked: unlocked ?? this.unlocked,
    unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
    fsrs: fsrs.present ? fsrs.value : this.fsrs,
    maskLevel: maskLevel ?? this.maskLevel,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      inverted: data.inverted.present ? data.inverted.value : this.inverted,
      unlocked: data.unlocked.present ? data.unlocked.value : this.unlocked,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      fsrs: data.fsrs.present ? data.fsrs.value : this.fsrs,
      maskLevel: data.maskLevel.present ? data.maskLevel.value : this.maskLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('poemId: $poemId, ')
          ..write('inverted: $inverted, ')
          ..write('unlocked: $unlocked, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('fsrs: $fsrs, ')
          ..write('maskLevel: $maskLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(poemId, inverted, unlocked, unlockedAt, fsrs, maskLevel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.poemId == this.poemId &&
          other.inverted == this.inverted &&
          other.unlocked == this.unlocked &&
          other.unlockedAt == this.unlockedAt &&
          other.fsrs == this.fsrs &&
          other.maskLevel == this.maskLevel);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> poemId;
  final Value<bool> inverted;
  final Value<bool> unlocked;
  final Value<DateTime?> unlockedAt;
  final Value<String?> fsrs;
  final Value<int> maskLevel;
  final Value<int> rowid;
  const ItemsCompanion({
    this.poemId = const Value.absent(),
    this.inverted = const Value.absent(),
    this.unlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.fsrs = const Value.absent(),
    this.maskLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required int poemId,
    required bool inverted,
    this.unlocked = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.fsrs = const Value.absent(),
    this.maskLevel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : poemId = Value(poemId),
       inverted = Value(inverted);
  static Insertable<Item> custom({
    Expression<int>? poemId,
    Expression<bool>? inverted,
    Expression<bool>? unlocked,
    Expression<DateTime>? unlockedAt,
    Expression<String>? fsrs,
    Expression<int>? maskLevel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (poemId != null) 'poem_id': poemId,
      if (inverted != null) 'inverted': inverted,
      if (unlocked != null) 'unlocked': unlocked,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (fsrs != null) 'fsrs': fsrs,
      if (maskLevel != null) 'mask_level': maskLevel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? poemId,
    Value<bool>? inverted,
    Value<bool>? unlocked,
    Value<DateTime?>? unlockedAt,
    Value<String?>? fsrs,
    Value<int>? maskLevel,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      poemId: poemId ?? this.poemId,
      inverted: inverted ?? this.inverted,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      fsrs: fsrs ?? this.fsrs,
      maskLevel: maskLevel ?? this.maskLevel,
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
    if (fsrs.present) {
      map['fsrs'] = Variable<String>(fsrs.value);
    }
    if (maskLevel.present) {
      map['mask_level'] = Variable<int>(maskLevel.value);
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
          ..write('fsrs: $fsrs, ')
          ..write('maskLevel: $maskLevel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatingPointsTable extends RatingPoints
    with TableInfo<$RatingPointsTable, RatingPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingPointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _performanceMeta = const VerificationMeta(
    'performance',
  );
  @override
  late final GeneratedColumn<double> performance = GeneratedColumn<double>(
    'performance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoredMsMeta = const VerificationMeta(
    'scoredMs',
  );
  @override
  late final GeneratedColumn<int> scoredMs = GeneratedColumn<int>(
    'scored_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    rating,
    performance,
    scoredMs,
    sessionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rating_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<RatingPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('performance')) {
      context.handle(
        _performanceMeta,
        performance.isAcceptableOrUnknown(
          data['performance']!,
          _performanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_performanceMeta);
    }
    if (data.containsKey('scored_ms')) {
      context.handle(
        _scoredMsMeta,
        scoredMs.isAcceptableOrUnknown(data['scored_ms']!, _scoredMsMeta),
      );
    } else if (isInserting) {
      context.missing(_scoredMsMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RatingPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      performance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}performance'],
      )!,
      scoredMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scored_ms'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      ),
    );
  }

  @override
  $RatingPointsTable createAlias(String alias) {
    return $RatingPointsTable(attachedDatabase, alias);
  }
}

class RatingPoint extends DataClass implements Insertable<RatingPoint> {
  final int id;
  final DateTime at;
  final double rating;
  final double performance;

  /// The run's scored time (`RankedScore.scored`), ms.
  final int scoredMs;
  final int? sessionId;
  const RatingPoint({
    required this.id,
    required this.at,
    required this.rating,
    required this.performance,
    required this.scoredMs,
    this.sessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['rating'] = Variable<double>(rating);
    map['performance'] = Variable<double>(performance);
    map['scored_ms'] = Variable<int>(scoredMs);
    if (!nullToAbsent || sessionId != null) {
      map['session_id'] = Variable<int>(sessionId);
    }
    return map;
  }

  RatingPointsCompanion toCompanion(bool nullToAbsent) {
    return RatingPointsCompanion(
      id: Value(id),
      at: Value(at),
      rating: Value(rating),
      performance: Value(performance),
      scoredMs: Value(scoredMs),
      sessionId: sessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionId),
    );
  }

  factory RatingPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingPoint(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      rating: serializer.fromJson<double>(json['rating']),
      performance: serializer.fromJson<double>(json['performance']),
      scoredMs: serializer.fromJson<int>(json['scoredMs']),
      sessionId: serializer.fromJson<int?>(json['sessionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'rating': serializer.toJson<double>(rating),
      'performance': serializer.toJson<double>(performance),
      'scoredMs': serializer.toJson<int>(scoredMs),
      'sessionId': serializer.toJson<int?>(sessionId),
    };
  }

  RatingPoint copyWith({
    int? id,
    DateTime? at,
    double? rating,
    double? performance,
    int? scoredMs,
    Value<int?> sessionId = const Value.absent(),
  }) => RatingPoint(
    id: id ?? this.id,
    at: at ?? this.at,
    rating: rating ?? this.rating,
    performance: performance ?? this.performance,
    scoredMs: scoredMs ?? this.scoredMs,
    sessionId: sessionId.present ? sessionId.value : this.sessionId,
  );
  RatingPoint copyWithCompanion(RatingPointsCompanion data) {
    return RatingPoint(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      rating: data.rating.present ? data.rating.value : this.rating,
      performance: data.performance.present
          ? data.performance.value
          : this.performance,
      scoredMs: data.scoredMs.present ? data.scoredMs.value : this.scoredMs,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingPoint(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('rating: $rating, ')
          ..write('performance: $performance, ')
          ..write('scoredMs: $scoredMs, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, at, rating, performance, scoredMs, sessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingPoint &&
          other.id == this.id &&
          other.at == this.at &&
          other.rating == this.rating &&
          other.performance == this.performance &&
          other.scoredMs == this.scoredMs &&
          other.sessionId == this.sessionId);
}

class RatingPointsCompanion extends UpdateCompanion<RatingPoint> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<double> rating;
  final Value<double> performance;
  final Value<int> scoredMs;
  final Value<int?> sessionId;
  const RatingPointsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.scoredMs = const Value.absent(),
    this.sessionId = const Value.absent(),
  });
  RatingPointsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required double rating,
    required double performance,
    required int scoredMs,
    this.sessionId = const Value.absent(),
  }) : at = Value(at),
       rating = Value(rating),
       performance = Value(performance),
       scoredMs = Value(scoredMs);
  static Insertable<RatingPoint> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<double>? rating,
    Expression<double>? performance,
    Expression<int>? scoredMs,
    Expression<int>? sessionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (rating != null) 'rating': rating,
      if (performance != null) 'performance': performance,
      if (scoredMs != null) 'scored_ms': scoredMs,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  RatingPointsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<double>? rating,
    Value<double>? performance,
    Value<int>? scoredMs,
    Value<int?>? sessionId,
  }) {
    return RatingPointsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      rating: rating ?? this.rating,
      performance: performance ?? this.performance,
      scoredMs: scoredMs ?? this.scoredMs,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (performance.present) {
      map['performance'] = Variable<double>(performance.value);
    }
    if (scoredMs.present) {
      map['scored_ms'] = Variable<int>(scoredMs.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingPointsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('rating: $rating, ')
          ..write('performance: $performance, ')
          ..write('scoredMs: $scoredMs, ')
          ..write('sessionId: $sessionId')
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
  static const VerificationMeta _gameMeta = const VerificationMeta('game');
  @override
  late final GeneratedColumn<String> game = GeneratedColumn<String>(
    'game',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _cardCountMeta = const VerificationMeta(
    'cardCount',
  );
  @override
  late final GeneratedColumn<int> cardCount = GeneratedColumn<int>(
    'card_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    ranked,
    level,
    cardCount,
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
    if (data.containsKey('game')) {
      context.handle(
        _gameMeta,
        game.isAcceptableOrUnknown(data['game']!, _gameMeta),
      );
    } else if (isInserting) {
      context.missing(_gameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
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
    if (data.containsKey('card_count')) {
      context.handle(
        _cardCountMeta,
        cardCount.isAcceptableOrUnknown(data['card_count']!, _cardCountMeta),
      );
    } else if (isInserting) {
      context.missing(_cardCountMeta);
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
      game: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      ranked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ranked'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      ),
      cardCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_count'],
      )!,
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
}

class SideTripRun extends DataClass implements Insertable<SideTripRun> {
  final int id;

  /// `SideTrip.name`, e.g. `ankiren`.
  final String game;
  final DateTime startedAt;
  final bool ranked;

  /// The level played; null for a custom setup.
  final int? level;

  /// Prompts asked.
  final int cardCount;

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

  /// Free-form JSON (cards per side, memorise time, …).
  final String meta;
  const SideTripRun({
    required this.id,
    required this.game,
    required this.startedAt,
    required this.ranked,
    this.level,
    required this.cardCount,
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
    map['game'] = Variable<String>(game);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ranked'] = Variable<bool>(ranked);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<int>(level);
    }
    map['card_count'] = Variable<int>(cardCount);
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
      ranked: Value(ranked),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
      cardCount: Value(cardCount),
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
      game: serializer.fromJson<String>(json['game']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      ranked: serializer.fromJson<bool>(json['ranked']),
      level: serializer.fromJson<int?>(json['level']),
      cardCount: serializer.fromJson<int>(json['cardCount']),
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
      'game': serializer.toJson<String>(game),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'ranked': serializer.toJson<bool>(ranked),
      'level': serializer.toJson<int?>(level),
      'cardCount': serializer.toJson<int>(cardCount),
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
    String? game,
    DateTime? startedAt,
    bool? ranked,
    Value<int?> level = const Value.absent(),
    int? cardCount,
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
    ranked: ranked ?? this.ranked,
    level: level.present ? level.value : this.level,
    cardCount: cardCount ?? this.cardCount,
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
      ranked: data.ranked.present ? data.ranked.value : this.ranked,
      level: data.level.present ? data.level.value : this.level,
      cardCount: data.cardCount.present ? data.cardCount.value : this.cardCount,
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
          ..write('ranked: $ranked, ')
          ..write('level: $level, ')
          ..write('cardCount: $cardCount, ')
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
    ranked,
    level,
    cardCount,
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
          other.ranked == this.ranked &&
          other.level == this.level &&
          other.cardCount == this.cardCount &&
          other.score == this.score &&
          other.maxScore == this.maxScore &&
          other.completed == this.completed &&
          other.rating == this.rating &&
          other.performance == this.performance &&
          other.meta == this.meta);
}

class SideTripRunsCompanion extends UpdateCompanion<SideTripRun> {
  final Value<int> id;
  final Value<String> game;
  final Value<DateTime> startedAt;
  final Value<bool> ranked;
  final Value<int?> level;
  final Value<int> cardCount;
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
    this.ranked = const Value.absent(),
    this.level = const Value.absent(),
    this.cardCount = const Value.absent(),
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    this.completed = const Value.absent(),
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.meta = const Value.absent(),
  });
  SideTripRunsCompanion.insert({
    this.id = const Value.absent(),
    required String game,
    required DateTime startedAt,
    required bool ranked,
    this.level = const Value.absent(),
    required int cardCount,
    this.score = const Value.absent(),
    this.maxScore = const Value.absent(),
    required bool completed,
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.meta = const Value.absent(),
  }) : game = Value(game),
       startedAt = Value(startedAt),
       ranked = Value(ranked),
       cardCount = Value(cardCount),
       completed = Value(completed);
  static Insertable<SideTripRun> custom({
    Expression<int>? id,
    Expression<String>? game,
    Expression<DateTime>? startedAt,
    Expression<bool>? ranked,
    Expression<int>? level,
    Expression<int>? cardCount,
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
      if (ranked != null) 'ranked': ranked,
      if (level != null) 'level': level,
      if (cardCount != null) 'card_count': cardCount,
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
    Value<String>? game,
    Value<DateTime>? startedAt,
    Value<bool>? ranked,
    Value<int?>? level,
    Value<int>? cardCount,
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
      ranked: ranked ?? this.ranked,
      level: level ?? this.level,
      cardCount: cardCount ?? this.cardCount,
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
      map['game'] = Variable<String>(game.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (ranked.present) {
      map['ranked'] = Variable<bool>(ranked.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (cardCount.present) {
      map['card_count'] = Variable<int>(cardCount.value);
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
          ..write('ranked: $ranked, ')
          ..write('level: $level, ')
          ..write('cardCount: $cardCount, ')
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
  static const VerificationMeta _firstTapMeta = const VerificationMeta(
    'firstTap',
  );
  @override
  late final GeneratedColumn<int> firstTap = GeneratedColumn<int>(
    'first_tap',
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
  static const VerificationMeta _secondTapMeta = const VerificationMeta(
    'secondTap',
  );
  @override
  late final GeneratedColumn<int> secondTap = GeneratedColumn<int>(
    'second_tap',
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
    responseUs,
    at,
    firstTap,
    firstTapUs,
    secondTap,
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
    if (data.containsKey('first_tap')) {
      context.handle(
        _firstTapMeta,
        firstTap.isAcceptableOrUnknown(data['first_tap']!, _firstTapMeta),
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
    if (data.containsKey('second_tap')) {
      context.handle(
        _secondTapMeta,
        secondTap.isAcceptableOrUnknown(data['second_tap']!, _secondTapMeta),
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
      responseUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_us'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      firstTap: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_tap'],
      ),
      firstTapUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_tap_us'],
      ),
      secondTap: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}second_tap'],
      ),
    );
  }

  @override
  $SideTripAnswersTable createAlias(String alias) {
    return $SideTripAnswersTable(attachedDatabase, alias);
  }
}

class SideTripAnswerRow extends DataClass
    implements Insertable<SideTripAnswerRow> {
  final int id;
  final int runId;
  final int seq;
  final int poemId;

  /// Other cards tapped while this one was asked.
  final int wrongTaps;

  /// Prompt → the tap on its card, µs; null when it was never found.
  final int? responseUs;
  final DateTime at;

  /// Where the first tap while it was asked landed (`TapProximity.index`),
  /// and prompt → that tap, µs; null when no card was tapped.
  final int? firstTap;
  final int? firstTapUs;

  /// Where the second tap landed; null when there was none.
  final int? secondTap;
  const SideTripAnswerRow({
    required this.id,
    required this.runId,
    required this.seq,
    required this.poemId,
    required this.wrongTaps,
    this.responseUs,
    required this.at,
    this.firstTap,
    this.firstTapUs,
    this.secondTap,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<int>(runId);
    map['seq'] = Variable<int>(seq);
    map['poem_id'] = Variable<int>(poemId);
    map['wrong_taps'] = Variable<int>(wrongTaps);
    if (!nullToAbsent || responseUs != null) {
      map['response_us'] = Variable<int>(responseUs);
    }
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || firstTap != null) {
      map['first_tap'] = Variable<int>(firstTap);
    }
    if (!nullToAbsent || firstTapUs != null) {
      map['first_tap_us'] = Variable<int>(firstTapUs);
    }
    if (!nullToAbsent || secondTap != null) {
      map['second_tap'] = Variable<int>(secondTap);
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
      responseUs: responseUs == null && nullToAbsent
          ? const Value.absent()
          : Value(responseUs),
      at: Value(at),
      firstTap: firstTap == null && nullToAbsent
          ? const Value.absent()
          : Value(firstTap),
      firstTapUs: firstTapUs == null && nullToAbsent
          ? const Value.absent()
          : Value(firstTapUs),
      secondTap: secondTap == null && nullToAbsent
          ? const Value.absent()
          : Value(secondTap),
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
      responseUs: serializer.fromJson<int?>(json['responseUs']),
      at: serializer.fromJson<DateTime>(json['at']),
      firstTap: serializer.fromJson<int?>(json['firstTap']),
      firstTapUs: serializer.fromJson<int?>(json['firstTapUs']),
      secondTap: serializer.fromJson<int?>(json['secondTap']),
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
      'responseUs': serializer.toJson<int?>(responseUs),
      'at': serializer.toJson<DateTime>(at),
      'firstTap': serializer.toJson<int?>(firstTap),
      'firstTapUs': serializer.toJson<int?>(firstTapUs),
      'secondTap': serializer.toJson<int?>(secondTap),
    };
  }

  SideTripAnswerRow copyWith({
    int? id,
    int? runId,
    int? seq,
    int? poemId,
    int? wrongTaps,
    Value<int?> responseUs = const Value.absent(),
    DateTime? at,
    Value<int?> firstTap = const Value.absent(),
    Value<int?> firstTapUs = const Value.absent(),
    Value<int?> secondTap = const Value.absent(),
  }) => SideTripAnswerRow(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    seq: seq ?? this.seq,
    poemId: poemId ?? this.poemId,
    wrongTaps: wrongTaps ?? this.wrongTaps,
    responseUs: responseUs.present ? responseUs.value : this.responseUs,
    at: at ?? this.at,
    firstTap: firstTap.present ? firstTap.value : this.firstTap,
    firstTapUs: firstTapUs.present ? firstTapUs.value : this.firstTapUs,
    secondTap: secondTap.present ? secondTap.value : this.secondTap,
  );
  SideTripAnswerRow copyWithCompanion(SideTripAnswersCompanion data) {
    return SideTripAnswerRow(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      seq: data.seq.present ? data.seq.value : this.seq,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      wrongTaps: data.wrongTaps.present ? data.wrongTaps.value : this.wrongTaps,
      responseUs: data.responseUs.present
          ? data.responseUs.value
          : this.responseUs,
      at: data.at.present ? data.at.value : this.at,
      firstTap: data.firstTap.present ? data.firstTap.value : this.firstTap,
      firstTapUs: data.firstTapUs.present
          ? data.firstTapUs.value
          : this.firstTapUs,
      secondTap: data.secondTap.present ? data.secondTap.value : this.secondTap,
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
          ..write('responseUs: $responseUs, ')
          ..write('at: $at, ')
          ..write('firstTap: $firstTap, ')
          ..write('firstTapUs: $firstTapUs, ')
          ..write('secondTap: $secondTap')
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
    responseUs,
    at,
    firstTap,
    firstTapUs,
    secondTap,
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
          other.responseUs == this.responseUs &&
          other.at == this.at &&
          other.firstTap == this.firstTap &&
          other.firstTapUs == this.firstTapUs &&
          other.secondTap == this.secondTap);
}

class SideTripAnswersCompanion extends UpdateCompanion<SideTripAnswerRow> {
  final Value<int> id;
  final Value<int> runId;
  final Value<int> seq;
  final Value<int> poemId;
  final Value<int> wrongTaps;
  final Value<int?> responseUs;
  final Value<DateTime> at;
  final Value<int?> firstTap;
  final Value<int?> firstTapUs;
  final Value<int?> secondTap;
  const SideTripAnswersCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.seq = const Value.absent(),
    this.poemId = const Value.absent(),
    this.wrongTaps = const Value.absent(),
    this.responseUs = const Value.absent(),
    this.at = const Value.absent(),
    this.firstTap = const Value.absent(),
    this.firstTapUs = const Value.absent(),
    this.secondTap = const Value.absent(),
  });
  SideTripAnswersCompanion.insert({
    this.id = const Value.absent(),
    required int runId,
    required int seq,
    required int poemId,
    required int wrongTaps,
    this.responseUs = const Value.absent(),
    required DateTime at,
    this.firstTap = const Value.absent(),
    this.firstTapUs = const Value.absent(),
    this.secondTap = const Value.absent(),
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
    Expression<int>? responseUs,
    Expression<DateTime>? at,
    Expression<int>? firstTap,
    Expression<int>? firstTapUs,
    Expression<int>? secondTap,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (seq != null) 'seq': seq,
      if (poemId != null) 'poem_id': poemId,
      if (wrongTaps != null) 'wrong_taps': wrongTaps,
      if (responseUs != null) 'response_us': responseUs,
      if (at != null) 'at': at,
      if (firstTap != null) 'first_tap': firstTap,
      if (firstTapUs != null) 'first_tap_us': firstTapUs,
      if (secondTap != null) 'second_tap': secondTap,
    });
  }

  SideTripAnswersCompanion copyWith({
    Value<int>? id,
    Value<int>? runId,
    Value<int>? seq,
    Value<int>? poemId,
    Value<int>? wrongTaps,
    Value<int?>? responseUs,
    Value<DateTime>? at,
    Value<int?>? firstTap,
    Value<int?>? firstTapUs,
    Value<int?>? secondTap,
  }) {
    return SideTripAnswersCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      seq: seq ?? this.seq,
      poemId: poemId ?? this.poemId,
      wrongTaps: wrongTaps ?? this.wrongTaps,
      responseUs: responseUs ?? this.responseUs,
      at: at ?? this.at,
      firstTap: firstTap ?? this.firstTap,
      firstTapUs: firstTapUs ?? this.firstTapUs,
      secondTap: secondTap ?? this.secondTap,
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
    if (responseUs.present) {
      map['response_us'] = Variable<int>(responseUs.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (firstTap.present) {
      map['first_tap'] = Variable<int>(firstTap.value);
    }
    if (firstTapUs.present) {
      map['first_tap_us'] = Variable<int>(firstTapUs.value);
    }
    if (secondTap.present) {
      map['second_tap'] = Variable<int>(secondTap.value);
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
          ..write('responseUs: $responseUs, ')
          ..write('at: $at, ')
          ..write('firstTap: $firstTap, ')
          ..write('firstTapUs: $firstTapUs, ')
          ..write('secondTap: $secondTap')
          ..write(')'))
        .toString();
  }
}

class $DaysTable extends Days with TableInfo<$DaysTable, DayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
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
    number,
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
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
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
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  DayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayRow(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
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
  final int number;
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
    required this.number,
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
    map['number'] = Variable<int>(number);
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
      number: Value(number),
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
      number: serializer.fromJson<int>(json['number']),
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
      'number': serializer.toJson<int>(number),
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
    int? number,
    DateTime? startsAt,
    DateTime? endsAt,
    Value<DateTime?> builtAt = const Value.absent(),
    int? missGuess,
    bool? newPaused,
    bool? pauseAsked,
    Value<DateTime?> doneAt = const Value.absent(),
  }) => DayRow(
    number: number ?? this.number,
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
      number: data.number.present ? data.number.value : this.number,
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
          ..write('number: $number, ')
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
    number,
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
          other.number == this.number &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.builtAt == this.builtAt &&
          other.missGuess == this.missGuess &&
          other.newPaused == this.newPaused &&
          other.pauseAsked == this.pauseAsked &&
          other.doneAt == this.doneAt);
}

class DaysCompanion extends UpdateCompanion<DayRow> {
  final Value<int> number;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<DateTime?> builtAt;
  final Value<int> missGuess;
  final Value<bool> newPaused;
  final Value<bool> pauseAsked;
  final Value<DateTime?> doneAt;
  const DaysCompanion({
    this.number = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.builtAt = const Value.absent(),
    this.missGuess = const Value.absent(),
    this.newPaused = const Value.absent(),
    this.pauseAsked = const Value.absent(),
    this.doneAt = const Value.absent(),
  });
  DaysCompanion.insert({
    this.number = const Value.absent(),
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
    Expression<int>? number,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<DateTime>? builtAt,
    Expression<int>? missGuess,
    Expression<bool>? newPaused,
    Expression<bool>? pauseAsked,
    Expression<DateTime>? doneAt,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
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
    Value<int>? number,
    Value<DateTime>? startsAt,
    Value<DateTime>? endsAt,
    Value<DateTime?>? builtAt,
    Value<int>? missGuess,
    Value<bool>? newPaused,
    Value<bool>? pauseAsked,
    Value<DateTime?>? doneAt,
  }) {
    return DaysCompanion(
      number: number ?? this.number,
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
    if (number.present) {
      map['number'] = Variable<int>(number.value);
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
          ..write('number: $number, ')
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
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
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $DayCardsTable createAlias(String alias) {
    return $DayCardsTable(attachedDatabase, alias);
  }
}

class DayCardRow extends DataClass implements Insertable<DayCardRow> {
  final int day;
  final int poemId;
  final bool inverted;

  /// `StepKind` index: a due review or a new card.
  final int kind;
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
    map['kind'] = Variable<int>(kind);
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
      kind: serializer.fromJson<int>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<int>(day),
      'poemId': serializer.toJson<int>(poemId),
      'inverted': serializer.toJson<bool>(inverted),
      'kind': serializer.toJson<int>(kind),
    };
  }

  DayCardRow copyWith({int? day, int? poemId, bool? inverted, int? kind}) =>
      DayCardRow(
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
  final Value<int> kind;
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
    required int kind,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       poemId = Value(poemId),
       inverted = Value(inverted),
       kind = Value(kind);
  static Insertable<DayCardRow> custom({
    Expression<int>? day,
    Expression<int>? poemId,
    Expression<bool>? inverted,
    Expression<int>? kind,
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
    Value<int>? kind,
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
      map['kind'] = Variable<int>(kind.value);
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
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $RatingPointsTable ratingPoints = $RatingPointsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $SideTripRunsTable sideTripRuns = $SideTripRunsTable(this);
  late final $SideTripAnswersTable sideTripAnswers = $SideTripAnswersTable(
    this,
  );
  late final $DaysTable days = $DaysTable(this);
  late final $DayCardsTable dayCards = $DayCardsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    attempts,
    items,
    ratingPoints,
    keyValues,
    sideTripRuns,
    sideTripAnswers,
    days,
    dayCards,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required DateTime startedAt,
  required String mode,
  Value<String> setIds,
  required int orientation,
  required int cardCount,
  Value<int?> totalUs,
  required bool completed,
  Value<String> meta,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  Value<DateTime> startedAt,
  Value<String> mode,
  Value<String> setIds,
  Value<int> orientation,
  Value<int> cardCount,
  Value<int?> totalUs,
  Value<bool> completed,
  Value<String> meta,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttemptsTable, List<AttemptRow>>
  _attemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attempts,
    aliasName: 'sessions__id__attempts__session_id',
  );

  $$AttemptsTableProcessedTableManager get attemptsRefs {
    final manager = $$AttemptsTableTableManager(
      $_db,
      $_db.attempts,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setIds => $composableBuilder(
    column: $table.setIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cardCount => $composableBuilder(
    column: $table.cardCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalUs => $composableBuilder(
    column: $table.totalUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attemptsRefs(
    Expression<bool> Function($$AttemptsTableFilterComposer f) f,
  ) {
    final $$AttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.sessionId,
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
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setIds => $composableBuilder(
    column: $table.setIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardCount => $composableBuilder(
    column: $table.cardCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalUs => $composableBuilder(
    column: $table.totalUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meta => $composableBuilder(
    column: $table.meta,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get setIds =>
      $composableBuilder(column: $table.setIds, builder: (column) => column);

  GeneratedColumn<int> get orientation => $composableBuilder(
    column: $table.orientation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cardCount =>
      $composableBuilder(column: $table.cardCount, builder: (column) => column);

  GeneratedColumn<int> get totalUs =>
      $composableBuilder(column: $table.totalUs, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get meta =>
      $composableBuilder(column: $table.meta, builder: (column) => column);

  Expression<T> attemptsRefs<T extends Object>(
    Expression<T> Function($$AttemptsTableAnnotationComposer a) f,
  ) {
    final $$AttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.sessionId,
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
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool attemptsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> setIds = const Value.absent(),
                Value<int> orientation = const Value.absent(),
                Value<int> cardCount = const Value.absent(),
                Value<int?> totalUs = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String> meta = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                mode: mode,
                setIds: setIds,
                orientation: orientation,
                cardCount: cardCount,
                totalUs: totalUs,
                completed: completed,
                meta: meta,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                required String mode,
                Value<String> setIds = const Value.absent(),
                required int orientation,
                required int cardCount,
                Value<int?> totalUs = const Value.absent(),
                required bool completed,
                Value<String> meta = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                mode: mode,
                setIds: setIds,
                orientation: orientation,
                cardCount: cardCount,
                totalUs: totalUs,
                completed: completed,
                meta: meta,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, Session>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attemptsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attemptsRefs) db.attempts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attemptsRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      AttemptRow
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._attemptsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SessionsTableReferences(db, table, p0).attemptsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool attemptsRefs})
    >;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  required int sessionId,
  required int seq,
  required int poemId,
  required bool inverted,
  Value<int> maskLevel,
  required int responseUs,
  required int outcome,
  Value<bool> wrong,
  Value<bool> tainted,
  Value<bool> undone,
  required int deckSize,
  required DateTime at,
  Value<int?> grade,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  Value<int> sessionId,
  Value<int> seq,
  Value<int> poemId,
  Value<bool> inverted,
  Value<int> maskLevel,
  Value<int> responseUs,
  Value<int> outcome,
  Value<bool> wrong,
  Value<bool> tainted,
  Value<bool> undone,
  Value<int> deckSize,
  Value<DateTime> at,
  Value<int?> grade,
});

final class $$AttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow> {
  $$AttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('attempts__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
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

  ColumnFilters<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
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

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
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

  ColumnOrderings<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outcome => $composableBuilder(
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

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
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

  GeneratedColumn<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outcome =>
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

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
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
          PrefetchHooks Function({bool sessionId})
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
                Value<int> sessionId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> poemId = const Value.absent(),
                Value<bool> inverted = const Value.absent(),
                Value<int> maskLevel = const Value.absent(),
                Value<int> responseUs = const Value.absent(),
                Value<int> outcome = const Value.absent(),
                Value<bool> wrong = const Value.absent(),
                Value<bool> tainted = const Value.absent(),
                Value<bool> undone = const Value.absent(),
                Value<int> deckSize = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int?> grade = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                sessionId: sessionId,
                seq: seq,
                poemId: poemId,
                inverted: inverted,
                maskLevel: maskLevel,
                responseUs: responseUs,
                outcome: outcome,
                wrong: wrong,
                tainted: tainted,
                undone: undone,
                deckSize: deckSize,
                at: at,
                grade: grade,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int seq,
                required int poemId,
                required bool inverted,
                Value<int> maskLevel = const Value.absent(),
                required int responseUs,
                required int outcome,
                Value<bool> wrong = const Value.absent(),
                Value<bool> tainted = const Value.absent(),
                Value<bool> undone = const Value.absent(),
                required int deckSize,
                required DateTime at,
                Value<int?> grade = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                sessionId: sessionId,
                seq: seq,
                poemId: poemId,
                inverted: inverted,
                maskLevel: maskLevel,
                responseUs: responseUs,
                outcome: outcome,
                wrong: wrong,
                tainted: tainted,
                undone: undone,
                deckSize: deckSize,
                at: at,
                grade: grade,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, AttemptRow>(table),
                  $$AttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
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
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$AttemptsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$AttemptsTableReferences
                            ._sessionIdTable(db)
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
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  required int poemId,
  required bool inverted,
  Value<bool> unlocked,
  Value<DateTime?> unlockedAt,
  Value<String?> fsrs,
  Value<int> maskLevel,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> poemId,
  Value<bool> inverted,
  Value<bool> unlocked,
  Value<DateTime?> unlockedAt,
  Value<String?> fsrs,
  Value<int> maskLevel,
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

  ColumnFilters<String> get fsrs => $composableBuilder(
    column: $table.fsrs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maskLevel => $composableBuilder(
    column: $table.maskLevel,
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

  ColumnOrderings<String> get fsrs => $composableBuilder(
    column: $table.fsrs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maskLevel => $composableBuilder(
    column: $table.maskLevel,
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

  GeneratedColumn<String> get fsrs =>
      $composableBuilder(column: $table.fsrs, builder: (column) => column);

  GeneratedColumn<int> get maskLevel =>
      $composableBuilder(column: $table.maskLevel, builder: (column) => column);
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
          Item,
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
                Value<String?> fsrs = const Value.absent(),
                Value<int> maskLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                poemId: poemId,
                inverted: inverted,
                unlocked: unlocked,
                unlockedAt: unlockedAt,
                fsrs: fsrs,
                maskLevel: maskLevel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int poemId,
                required bool inverted,
                Value<bool> unlocked = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<String?> fsrs = const Value.absent(),
                Value<int> maskLevel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                poemId: poemId,
                inverted: inverted,
                unlocked: unlocked,
                unlockedAt: unlockedAt,
                fsrs: fsrs,
                maskLevel: maskLevel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, Item>(table),
                  BaseReferences<_$AppDatabase, $ItemsTable, Item>(
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
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, BaseReferences<_$AppDatabase, $ItemsTable, Item>),
      Item,
      PrefetchHooks Function()
    >;
typedef $$RatingPointsTableCreateCompanionBuilder =
    RatingPointsCompanion Function({
      Value<int> id,
      required DateTime at,
      required double rating,
      required double performance,
      required int scoredMs,
      Value<int?> sessionId,
    });
typedef $$RatingPointsTableUpdateCompanionBuilder =
    RatingPointsCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<double> rating,
      Value<double> performance,
      Value<int> scoredMs,
      Value<int?> sessionId,
    });

class $$RatingPointsTableFilterComposer
    extends Composer<_$AppDatabase, $RatingPointsTable> {
  $$RatingPointsTableFilterComposer({
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

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
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

  ColumnFilters<int> get scoredMs => $composableBuilder(
    column: $table.scoredMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RatingPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingPointsTable> {
  $$RatingPointsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
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

  ColumnOrderings<int> get scoredMs => $composableBuilder(
    column: $table.scoredMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RatingPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingPointsTable> {
  $$RatingPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<double> get performance => $composableBuilder(
    column: $table.performance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scoredMs =>
      $composableBuilder(column: $table.scoredMs, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);
}

class $$RatingPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingPointsTable,
          RatingPoint,
          $$RatingPointsTableFilterComposer,
          $$RatingPointsTableOrderingComposer,
          $$RatingPointsTableAnnotationComposer,
          $$RatingPointsTableCreateCompanionBuilder,
          $$RatingPointsTableUpdateCompanionBuilder,
          (
            RatingPoint,
            BaseReferences<_$AppDatabase, $RatingPointsTable, RatingPoint>,
          ),
          RatingPoint,
          PrefetchHooks Function()
        > {
  $$RatingPointsTableTableManager(_$AppDatabase db, $RatingPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<double> performance = const Value.absent(),
                Value<int> scoredMs = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
              }) => RatingPointsCompanion(
                id: id,
                at: at,
                rating: rating,
                performance: performance,
                scoredMs: scoredMs,
                sessionId: sessionId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required double rating,
                required double performance,
                required int scoredMs,
                Value<int?> sessionId = const Value.absent(),
              }) => RatingPointsCompanion.insert(
                id: id,
                at: at,
                rating: rating,
                performance: performance,
                scoredMs: scoredMs,
                sessionId: sessionId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RatingPointsTable, RatingPoint>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $RatingPointsTable,
                    RatingPoint
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RatingPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingPointsTable,
      RatingPoint,
      $$RatingPointsTableFilterComposer,
      $$RatingPointsTableOrderingComposer,
      $$RatingPointsTableAnnotationComposer,
      $$RatingPointsTableCreateCompanionBuilder,
      $$RatingPointsTableUpdateCompanionBuilder,
      (
        RatingPoint,
        BaseReferences<_$AppDatabase, $RatingPointsTable, RatingPoint>,
      ),
      RatingPoint,
      PrefetchHooks Function()
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
      required String game,
      required DateTime startedAt,
      required bool ranked,
      Value<int?> level,
      required int cardCount,
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
      Value<String> game,
      Value<DateTime> startedAt,
      Value<bool> ranked,
      Value<int?> level,
      Value<int> cardCount,
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

  ColumnFilters<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
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

  ColumnFilters<int> get cardCount => $composableBuilder(
    column: $table.cardCount,
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

  ColumnOrderings<bool> get ranked => $composableBuilder(
    column: $table.ranked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cardCount => $composableBuilder(
    column: $table.cardCount,
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

  GeneratedColumn<String> get game =>
      $composableBuilder(column: $table.game, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<bool> get ranked =>
      $composableBuilder(column: $table.ranked, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get cardCount =>
      $composableBuilder(column: $table.cardCount, builder: (column) => column);

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
          PrefetchHooks Function({bool sideTripAnswersRefs})
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
                Value<String> game = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<bool> ranked = const Value.absent(),
                Value<int?> level = const Value.absent(),
                Value<int> cardCount = const Value.absent(),
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
                ranked: ranked,
                level: level,
                cardCount: cardCount,
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
                required String game,
                required DateTime startedAt,
                required bool ranked,
                Value<int?> level = const Value.absent(),
                required int cardCount,
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
                ranked: ranked,
                level: level,
                cardCount: cardCount,
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
          prefetchHooksCallback: ({sideTripAnswersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sideTripAnswersRefs) db.sideTripAnswers,
              ],
              addJoins: null,
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
      PrefetchHooks Function({bool sideTripAnswersRefs})
    >;
typedef $$SideTripAnswersTableCreateCompanionBuilder =
    SideTripAnswersCompanion Function({
      Value<int> id,
      required int runId,
      required int seq,
      required int poemId,
      required int wrongTaps,
      Value<int?> responseUs,
      required DateTime at,
      Value<int?> firstTap,
      Value<int?> firstTapUs,
      Value<int?> secondTap,
    });
typedef $$SideTripAnswersTableUpdateCompanionBuilder =
    SideTripAnswersCompanion Function({
      Value<int> id,
      Value<int> runId,
      Value<int> seq,
      Value<int> poemId,
      Value<int> wrongTaps,
      Value<int?> responseUs,
      Value<DateTime> at,
      Value<int?> firstTap,
      Value<int?> firstTapUs,
      Value<int?> secondTap,
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

  ColumnFilters<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstTap => $composableBuilder(
    column: $table.firstTap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstTapUs => $composableBuilder(
    column: $table.firstTapUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get secondTap => $composableBuilder(
    column: $table.secondTap,
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

  ColumnOrderings<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstTap => $composableBuilder(
    column: $table.firstTap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstTapUs => $composableBuilder(
    column: $table.firstTapUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get secondTap => $composableBuilder(
    column: $table.secondTap,
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

  GeneratedColumn<int> get responseUs => $composableBuilder(
    column: $table.responseUs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get firstTap =>
      $composableBuilder(column: $table.firstTap, builder: (column) => column);

  GeneratedColumn<int> get firstTapUs => $composableBuilder(
    column: $table.firstTapUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get secondTap =>
      $composableBuilder(column: $table.secondTap, builder: (column) => column);

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
                Value<int?> responseUs = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int?> firstTap = const Value.absent(),
                Value<int?> firstTapUs = const Value.absent(),
                Value<int?> secondTap = const Value.absent(),
              }) => SideTripAnswersCompanion(
                id: id,
                runId: runId,
                seq: seq,
                poemId: poemId,
                wrongTaps: wrongTaps,
                responseUs: responseUs,
                at: at,
                firstTap: firstTap,
                firstTapUs: firstTapUs,
                secondTap: secondTap,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int runId,
                required int seq,
                required int poemId,
                required int wrongTaps,
                Value<int?> responseUs = const Value.absent(),
                required DateTime at,
                Value<int?> firstTap = const Value.absent(),
                Value<int?> firstTapUs = const Value.absent(),
                Value<int?> secondTap = const Value.absent(),
              }) => SideTripAnswersCompanion.insert(
                id: id,
                runId: runId,
                seq: seq,
                poemId: poemId,
                wrongTaps: wrongTaps,
                responseUs: responseUs,
                at: at,
                firstTap: firstTap,
                firstTapUs: firstTapUs,
                secondTap: secondTap,
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
typedef $$DaysTableCreateCompanionBuilder = DaysCompanion Function({
  Value<int> number,
  required DateTime startsAt,
  required DateTime endsAt,
  Value<DateTime?> builtAt,
  Value<int> missGuess,
  Value<bool> newPaused,
  Value<bool> pauseAsked,
  Value<DateTime?> doneAt,
});
typedef $$DaysTableUpdateCompanionBuilder = DaysCompanion Function({
  Value<int> number,
  Value<DateTime> startsAt,
  Value<DateTime> endsAt,
  Value<DateTime?> builtAt,
  Value<int> missGuess,
  Value<bool> newPaused,
  Value<bool> pauseAsked,
  Value<DateTime?> doneAt,
});

class $$DaysTableFilterComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
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
}

class $$DaysTableOrderingComposer extends Composer<_$AppDatabase, $DaysTable> {
  $$DaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
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
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

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
          (DayRow, BaseReferences<_$AppDatabase, $DaysTable, DayRow>),
          DayRow,
          PrefetchHooks Function()
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
                Value<int> number = const Value.absent(),
                Value<DateTime> startsAt = const Value.absent(),
                Value<DateTime> endsAt = const Value.absent(),
                Value<DateTime?> builtAt = const Value.absent(),
                Value<int> missGuess = const Value.absent(),
                Value<bool> newPaused = const Value.absent(),
                Value<bool> pauseAsked = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
              }) => DaysCompanion(
                number: number,
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
                Value<int> number = const Value.absent(),
                required DateTime startsAt,
                required DateTime endsAt,
                Value<DateTime?> builtAt = const Value.absent(),
                Value<int> missGuess = const Value.absent(),
                Value<bool> newPaused = const Value.absent(),
                Value<bool> pauseAsked = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
              }) => DaysCompanion.insert(
                number: number,
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
                  BaseReferences<_$AppDatabase, $DaysTable, DayRow>(
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
      (DayRow, BaseReferences<_$AppDatabase, $DaysTable, DayRow>),
      DayRow,
      PrefetchHooks Function()
    >;
typedef $$DayCardsTableCreateCompanionBuilder = DayCardsCompanion Function({
  required int day,
  required int poemId,
  required bool inverted,
  required int kind,
  Value<int> rowid,
});
typedef $$DayCardsTableUpdateCompanionBuilder = DayCardsCompanion Function({
  Value<int> day,
  Value<int> poemId,
  Value<bool> inverted,
  Value<int> kind,
  Value<int> rowid,
});

class $$DayCardsTableFilterComposer
    extends Composer<_$AppDatabase, $DayCardsTable> {
  $$DayCardsTableFilterComposer({
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

  ColumnFilters<int> get poemId => $composableBuilder(
    column: $table.poemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inverted => $composableBuilder(
    column: $table.inverted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
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
  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
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

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
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
  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get poemId =>
      $composableBuilder(column: $table.poemId, builder: (column) => column);

  GeneratedColumn<bool> get inverted =>
      $composableBuilder(column: $table.inverted, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
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
          (
            DayCardRow,
            BaseReferences<_$AppDatabase, $DayCardsTable, DayCardRow>,
          ),
          DayCardRow,
          PrefetchHooks Function()
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
                Value<int> kind = const Value.absent(),
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
                required int kind,
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
                  BaseReferences<_$AppDatabase, $DayCardsTable, DayCardRow>(
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
      (DayCardRow, BaseReferences<_$AppDatabase, $DayCardsTable, DayCardRow>),
      DayCardRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$RatingPointsTableTableManager get ratingPoints =>
      $$RatingPointsTableTableManager(_db, _db.ratingPoints);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$SideTripRunsTableTableManager get sideTripRuns =>
      $$SideTripRunsTableTableManager(_db, _db.sideTripRuns);
  $$SideTripAnswersTableTableManager get sideTripAnswers =>
      $$SideTripAnswersTableTableManager(_db, _db.sideTripAnswers);
  $$DaysTableTableManager get days => $$DaysTableTableManager(_db, _db.days);
  $$DayCardsTableTableManager get dayCards =>
      $$DayCardsTableTableManager(_db, _db.dayCards);
}
