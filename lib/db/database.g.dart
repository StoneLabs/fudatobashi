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
  late final GeneratedColumn<int> mode = GeneratedColumn<int>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
        DriftSqlType.int,
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

  /// PlayMode index.
  final int mode;

  /// JSON list of FudaSet ids that defined the deck (empty for training).
  final String setIds;

  /// 0 random, 1 upright only, 2 inverted only.
  final int orientation;
  final int cardCount;

  /// First reveal → last swipe, µs. Null when the run was ended early.
  final int? totalUs;
  final bool completed;

  /// Free-form JSON (mask settings, goal at the time, …).
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
    map['mode'] = Variable<int>(mode);
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
      mode: serializer.fromJson<int>(json['mode']),
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
      'mode': serializer.toJson<int>(mode),
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
    int? mode,
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
  final Value<int> mode;
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
    required int mode,
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
    Expression<int>? mode,
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
    Value<int>? mode,
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
      map['mode'] = Variable<int>(mode.value);
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
  static const VerificationMeta _projectedMsMeta = const VerificationMeta(
    'projectedMs',
  );
  @override
  late final GeneratedColumn<int> projectedMs = GeneratedColumn<int>(
    'projected_ms',
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
    projectedMs,
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
    if (data.containsKey('projected_ms')) {
      context.handle(
        _projectedMsMeta,
        projectedMs.isAcceptableOrUnknown(
          data['projected_ms']!,
          _projectedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectedMsMeta);
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
      projectedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}projected_ms'],
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

  /// Projected 100-card time, ms.
  final int projectedMs;
  final int? sessionId;
  const RatingPoint({
    required this.id,
    required this.at,
    required this.rating,
    required this.performance,
    required this.projectedMs,
    this.sessionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['rating'] = Variable<double>(rating);
    map['performance'] = Variable<double>(performance);
    map['projected_ms'] = Variable<int>(projectedMs);
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
      projectedMs: Value(projectedMs),
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
      projectedMs: serializer.fromJson<int>(json['projectedMs']),
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
      'projectedMs': serializer.toJson<int>(projectedMs),
      'sessionId': serializer.toJson<int?>(sessionId),
    };
  }

  RatingPoint copyWith({
    int? id,
    DateTime? at,
    double? rating,
    double? performance,
    int? projectedMs,
    Value<int?> sessionId = const Value.absent(),
  }) => RatingPoint(
    id: id ?? this.id,
    at: at ?? this.at,
    rating: rating ?? this.rating,
    performance: performance ?? this.performance,
    projectedMs: projectedMs ?? this.projectedMs,
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
      projectedMs: data.projectedMs.present
          ? data.projectedMs.value
          : this.projectedMs,
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
          ..write('projectedMs: $projectedMs, ')
          ..write('sessionId: $sessionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, at, rating, performance, projectedMs, sessionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingPoint &&
          other.id == this.id &&
          other.at == this.at &&
          other.rating == this.rating &&
          other.performance == this.performance &&
          other.projectedMs == this.projectedMs &&
          other.sessionId == this.sessionId);
}

class RatingPointsCompanion extends UpdateCompanion<RatingPoint> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<double> rating;
  final Value<double> performance;
  final Value<int> projectedMs;
  final Value<int?> sessionId;
  const RatingPointsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.rating = const Value.absent(),
    this.performance = const Value.absent(),
    this.projectedMs = const Value.absent(),
    this.sessionId = const Value.absent(),
  });
  RatingPointsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required double rating,
    required double performance,
    required int projectedMs,
    this.sessionId = const Value.absent(),
  }) : at = Value(at),
       rating = Value(rating),
       performance = Value(performance),
       projectedMs = Value(projectedMs);
  static Insertable<RatingPoint> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<double>? rating,
    Expression<double>? performance,
    Expression<int>? projectedMs,
    Expression<int>? sessionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (rating != null) 'rating': rating,
      if (performance != null) 'performance': performance,
      if (projectedMs != null) 'projected_ms': projectedMs,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  RatingPointsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<double>? rating,
    Value<double>? performance,
    Value<int>? projectedMs,
    Value<int?>? sessionId,
  }) {
    return RatingPointsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      rating: rating ?? this.rating,
      performance: performance ?? this.performance,
      projectedMs: projectedMs ?? this.projectedMs,
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
    if (projectedMs.present) {
      map['projected_ms'] = Variable<int>(projectedMs.value);
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
          ..write('projectedMs: $projectedMs, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $RatingPointsTable ratingPoints = $RatingPointsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
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
  ];
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  Value<int> id,
  required DateTime startedAt,
  required int mode,
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
  Value<int> mode,
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

  ColumnFilters<int> get mode => $composableBuilder(
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

  ColumnOrderings<int> get mode => $composableBuilder(
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

  GeneratedColumn<int> get mode =>
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
                Value<int> mode = const Value.absent(),
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
                required int mode,
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
      required int projectedMs,
      Value<int?> sessionId,
    });
typedef $$RatingPointsTableUpdateCompanionBuilder =
    RatingPointsCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<double> rating,
      Value<double> performance,
      Value<int> projectedMs,
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

  ColumnFilters<int> get projectedMs => $composableBuilder(
    column: $table.projectedMs,
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

  ColumnOrderings<int> get projectedMs => $composableBuilder(
    column: $table.projectedMs,
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

  GeneratedColumn<int> get projectedMs => $composableBuilder(
    column: $table.projectedMs,
    builder: (column) => column,
  );

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
                Value<int> projectedMs = const Value.absent(),
                Value<int?> sessionId = const Value.absent(),
              }) => RatingPointsCompanion(
                id: id,
                at: at,
                rating: rating,
                performance: performance,
                projectedMs: projectedMs,
                sessionId: sessionId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required double rating,
                required double performance,
                required int projectedMs,
                Value<int?> sessionId = const Value.absent(),
              }) => RatingPointsCompanion.insert(
                id: id,
                at: at,
                rating: rating,
                performance: performance,
                projectedMs: projectedMs,
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
}
