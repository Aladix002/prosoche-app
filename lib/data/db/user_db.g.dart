// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_db.dart';

// ignore_for_file: type=lint
class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String valueJson;
  const SettingRow({required this.key, required this.valueJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), valueJson: Value(valueJson));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
    };
  }

  SettingRow copyWith({String? key, String? valueJson}) =>
      SettingRow(key: key ?? this.key, valueJson: valueJson ?? this.valueJson);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailySetsTable extends DailySets
    with TableInfo<$DailySetsTable, DailySetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailySetsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($DailySetsTable.$converterdate);
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> cardsJson = GeneratedColumn<String>(
    'cards_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DailySetsTable.$converterstartedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> completedAt =
      GeneratedColumn<int>(
        'completed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DailySetsTable.$convertercompletedAtn);
  @override
  late final GeneratedColumn<int> generatorVersion = GeneratedColumn<int>(
    'generator_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
    'tz',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DayPhase, String> phase =
      GeneratedColumn<String>(
        'phase',
        aliasedName,
        false,
        check: () => phase.isIn(DayPhase.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DayPhase>($DailySetsTable.$converterphase);
  @override
  List<GeneratedColumn> get $columns => [
    date,
    seed,
    cardsJson,
    cursor,
    startedAt,
    completedAt,
    generatorVersion,
    contentVersion,
    tz,
    phase,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_set';
  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailySetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailySetRow(
      date: $DailySetsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      seed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
      cardsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cards_json'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
      startedAt: $DailySetsTable.$converterstartedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        ),
      ),
      completedAt: $DailySetsTable.$convertercompletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}completed_at'],
        ),
      ),
      generatorVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}generator_version'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
      tz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tz'],
      )!,
      phase: $DailySetsTable.$converterphase.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}phase'],
        )!,
      ),
    );
  }

  @override
  $DailySetsTable createAlias(String alias) {
    return $DailySetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocalDate, String, String> $converterdate =
      const LocalDateConverter();
  static JsonTypeConverter2<DateTime, int, int> $converterstartedAt =
      const UtcMillisConverter();
  static JsonTypeConverter2<DateTime?, int?, int?> $converterstartedAtn =
      JsonTypeConverter2.asNullable($converterstartedAt);
  static JsonTypeConverter2<DateTime, int, int> $convertercompletedAt =
      const UtcMillisConverter();
  static JsonTypeConverter2<DateTime?, int?, int?> $convertercompletedAtn =
      JsonTypeConverter2.asNullable($convertercompletedAt);
  static JsonTypeConverter2<DayPhase, String, String> $converterphase =
      const WireEnumConverter(DayPhase.values);
}

class DailySetRow extends DataClass implements Insertable<DailySetRow> {
  final LocalDate date;
  final int seed;
  final String cardsJson;
  final int cursor;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int generatorVersion;
  final String contentVersion;
  final String tz;
  final DayPhase phase;
  const DailySetRow({
    required this.date,
    required this.seed,
    required this.cardsJson,
    required this.cursor,
    this.startedAt,
    this.completedAt,
    required this.generatorVersion,
    required this.contentVersion,
    required this.tz,
    required this.phase,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['date'] = Variable<String>(
        $DailySetsTable.$converterdate.toSql(date),
      );
    }
    map['seed'] = Variable<int>(seed);
    map['cards_json'] = Variable<String>(cardsJson);
    map['cursor'] = Variable<int>(cursor);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<int>(
        $DailySetsTable.$converterstartedAtn.toSql(startedAt),
      );
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(
        $DailySetsTable.$convertercompletedAtn.toSql(completedAt),
      );
    }
    map['generator_version'] = Variable<int>(generatorVersion);
    map['content_version'] = Variable<String>(contentVersion);
    map['tz'] = Variable<String>(tz);
    {
      map['phase'] = Variable<String>(
        $DailySetsTable.$converterphase.toSql(phase),
      );
    }
    return map;
  }

  DailySetsCompanion toCompanion(bool nullToAbsent) {
    return DailySetsCompanion(
      date: Value(date),
      seed: Value(seed),
      cardsJson: Value(cardsJson),
      cursor: Value(cursor),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      generatorVersion: Value(generatorVersion),
      contentVersion: Value(contentVersion),
      tz: Value(tz),
      phase: Value(phase),
    );
  }

  factory DailySetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailySetRow(
      date: $DailySetsTable.$converterdate.fromJson(
        serializer.fromJson<String>(json['date']),
      ),
      seed: serializer.fromJson<int>(json['seed']),
      cardsJson: serializer.fromJson<String>(json['cardsJson']),
      cursor: serializer.fromJson<int>(json['cursor']),
      startedAt: $DailySetsTable.$converterstartedAtn.fromJson(
        serializer.fromJson<int?>(json['startedAt']),
      ),
      completedAt: $DailySetsTable.$convertercompletedAtn.fromJson(
        serializer.fromJson<int?>(json['completedAt']),
      ),
      generatorVersion: serializer.fromJson<int>(json['generatorVersion']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
      tz: serializer.fromJson<String>(json['tz']),
      phase: $DailySetsTable.$converterphase.fromJson(
        serializer.fromJson<String>(json['phase']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(
        $DailySetsTable.$converterdate.toJson(date),
      ),
      'seed': serializer.toJson<int>(seed),
      'cardsJson': serializer.toJson<String>(cardsJson),
      'cursor': serializer.toJson<int>(cursor),
      'startedAt': serializer.toJson<int?>(
        $DailySetsTable.$converterstartedAtn.toJson(startedAt),
      ),
      'completedAt': serializer.toJson<int?>(
        $DailySetsTable.$convertercompletedAtn.toJson(completedAt),
      ),
      'generatorVersion': serializer.toJson<int>(generatorVersion),
      'contentVersion': serializer.toJson<String>(contentVersion),
      'tz': serializer.toJson<String>(tz),
      'phase': serializer.toJson<String>(
        $DailySetsTable.$converterphase.toJson(phase),
      ),
    };
  }

  DailySetRow copyWith({
    LocalDate? date,
    int? seed,
    String? cardsJson,
    int? cursor,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    int? generatorVersion,
    String? contentVersion,
    String? tz,
    DayPhase? phase,
  }) => DailySetRow(
    date: date ?? this.date,
    seed: seed ?? this.seed,
    cardsJson: cardsJson ?? this.cardsJson,
    cursor: cursor ?? this.cursor,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    generatorVersion: generatorVersion ?? this.generatorVersion,
    contentVersion: contentVersion ?? this.contentVersion,
    tz: tz ?? this.tz,
    phase: phase ?? this.phase,
  );
  DailySetRow copyWithCompanion(DailySetsCompanion data) {
    return DailySetRow(
      date: data.date.present ? data.date.value : this.date,
      seed: data.seed.present ? data.seed.value : this.seed,
      cardsJson: data.cardsJson.present ? data.cardsJson.value : this.cardsJson,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      generatorVersion: data.generatorVersion.present
          ? data.generatorVersion.value
          : this.generatorVersion,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
      tz: data.tz.present ? data.tz.value : this.tz,
      phase: data.phase.present ? data.phase.value : this.phase,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySetRow(')
          ..write('date: $date, ')
          ..write('seed: $seed, ')
          ..write('cardsJson: $cardsJson, ')
          ..write('cursor: $cursor, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('generatorVersion: $generatorVersion, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('tz: $tz, ')
          ..write('phase: $phase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    seed,
    cardsJson,
    cursor,
    startedAt,
    completedAt,
    generatorVersion,
    contentVersion,
    tz,
    phase,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySetRow &&
          other.date == this.date &&
          other.seed == this.seed &&
          other.cardsJson == this.cardsJson &&
          other.cursor == this.cursor &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.generatorVersion == this.generatorVersion &&
          other.contentVersion == this.contentVersion &&
          other.tz == this.tz &&
          other.phase == this.phase);
}

class DailySetsCompanion extends UpdateCompanion<DailySetRow> {
  final Value<LocalDate> date;
  final Value<int> seed;
  final Value<String> cardsJson;
  final Value<int> cursor;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> generatorVersion;
  final Value<String> contentVersion;
  final Value<String> tz;
  final Value<DayPhase> phase;
  final Value<int> rowid;
  const DailySetsCompanion({
    this.date = const Value.absent(),
    this.seed = const Value.absent(),
    this.cardsJson = const Value.absent(),
    this.cursor = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.generatorVersion = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.tz = const Value.absent(),
    this.phase = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySetsCompanion.insert({
    required LocalDate date,
    required int seed,
    required String cardsJson,
    this.cursor = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    required int generatorVersion,
    required String contentVersion,
    required String tz,
    required DayPhase phase,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       seed = Value(seed),
       cardsJson = Value(cardsJson),
       generatorVersion = Value(generatorVersion),
       contentVersion = Value(contentVersion),
       tz = Value(tz),
       phase = Value(phase);
  static Insertable<DailySetRow> custom({
    Expression<String>? date,
    Expression<int>? seed,
    Expression<String>? cardsJson,
    Expression<int>? cursor,
    Expression<int>? startedAt,
    Expression<int>? completedAt,
    Expression<int>? generatorVersion,
    Expression<String>? contentVersion,
    Expression<String>? tz,
    Expression<String>? phase,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (seed != null) 'seed': seed,
      if (cardsJson != null) 'cards_json': cardsJson,
      if (cursor != null) 'cursor': cursor,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (generatorVersion != null) 'generator_version': generatorVersion,
      if (contentVersion != null) 'content_version': contentVersion,
      if (tz != null) 'tz': tz,
      if (phase != null) 'phase': phase,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySetsCompanion copyWith({
    Value<LocalDate>? date,
    Value<int>? seed,
    Value<String>? cardsJson,
    Value<int>? cursor,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? generatorVersion,
    Value<String>? contentVersion,
    Value<String>? tz,
    Value<DayPhase>? phase,
    Value<int>? rowid,
  }) {
    return DailySetsCompanion(
      date: date ?? this.date,
      seed: seed ?? this.seed,
      cardsJson: cardsJson ?? this.cardsJson,
      cursor: cursor ?? this.cursor,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      generatorVersion: generatorVersion ?? this.generatorVersion,
      contentVersion: contentVersion ?? this.contentVersion,
      tz: tz ?? this.tz,
      phase: phase ?? this.phase,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(
        $DailySetsTable.$converterdate.toSql(date.value),
      );
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (cardsJson.present) {
      map['cards_json'] = Variable<String>(cardsJson.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $DailySetsTable.$converterstartedAtn.toSql(startedAt.value),
      );
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(
        $DailySetsTable.$convertercompletedAtn.toSql(completedAt.value),
      );
    }
    if (generatorVersion.present) {
      map['generator_version'] = Variable<int>(generatorVersion.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(
        $DailySetsTable.$converterphase.toSql(phase.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailySetsCompanion(')
          ..write('date: $date, ')
          ..write('seed: $seed, ')
          ..write('cardsJson: $cardsJson, ')
          ..write('cursor: $cursor, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('generatorVersion: $generatorVersion, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('tz: $tz, ')
          ..write('phase: $phase, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardEventsTable extends CardEvents
    with TableInfo<$CardEventsTable, CardEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardEventsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($CardEventsTable.$converterdate);
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CardType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        check: () => type.isIn(const [
          'intro',
          'quote',
          'passage',
          'practice',
          'prompt',
          'concept',
          'author',
          'done',
        ]),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CardType>($CardEventsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<CardContext, String> context =
      GeneratedColumn<String>(
        'context',
        aliasedName,
        false,
        check: () => context.isIn(CardContext.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CardContext>($CardEventsTable.$convertercontext);
  @override
  late final GeneratedColumnWithTypeConverter<CardAction, String> action =
      GeneratedColumn<String>(
        'action',
        aliasedName,
        false,
        check: () => action.isIn(CardAction.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CardAction>($CardEventsTable.$converteraction);
  @override
  late final GeneratedColumn<int> pos = GeneratedColumn<int>(
    'pos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> ts =
      GeneratedColumn<int>(
        'ts',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CardEventsTable.$converterts);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    cardId,
    type,
    context,
    action,
    pos,
    value,
    correct,
    ts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_event';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: $CardEventsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      type: $CardEventsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      context: $CardEventsTable.$convertercontext.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}context'],
        )!,
      ),
      action: $CardEventsTable.$converteraction.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}action'],
        )!,
      ),
      pos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pos'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      ),
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      ),
      ts: $CardEventsTable.$converterts.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}ts'],
        )!,
      ),
    );
  }

  @override
  $CardEventsTable createAlias(String alias) {
    return $CardEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocalDate, String, String> $converterdate =
      const LocalDateConverter();
  static JsonTypeConverter2<CardType, String, String> $convertertype =
      const CardTypeConverter();
  static JsonTypeConverter2<CardContext, String, String> $convertercontext =
      const WireEnumConverter(CardContext.values);
  static JsonTypeConverter2<CardAction, String, String> $converteraction =
      const WireEnumConverter(CardAction.values);
  static JsonTypeConverter2<DateTime, int, int> $converterts =
      const UtcMillisConverter();
}

class CardEventRow extends DataClass implements Insertable<CardEventRow> {
  final int id;
  final LocalDate date;
  final String cardId;
  final CardType type;
  final CardContext context;
  final CardAction action;
  final int? pos;
  final int? value;
  final bool? correct;
  final DateTime ts;
  const CardEventRow({
    required this.id,
    required this.date,
    required this.cardId,
    required this.type,
    required this.context,
    required this.action,
    this.pos,
    this.value,
    this.correct,
    required this.ts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['date'] = Variable<String>(
        $CardEventsTable.$converterdate.toSql(date),
      );
    }
    map['card_id'] = Variable<String>(cardId);
    {
      map['type'] = Variable<String>(
        $CardEventsTable.$convertertype.toSql(type),
      );
    }
    {
      map['context'] = Variable<String>(
        $CardEventsTable.$convertercontext.toSql(context),
      );
    }
    {
      map['action'] = Variable<String>(
        $CardEventsTable.$converteraction.toSql(action),
      );
    }
    if (!nullToAbsent || pos != null) {
      map['pos'] = Variable<int>(pos);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<int>(value);
    }
    if (!nullToAbsent || correct != null) {
      map['correct'] = Variable<bool>(correct);
    }
    {
      map['ts'] = Variable<int>($CardEventsTable.$converterts.toSql(ts));
    }
    return map;
  }

  CardEventsCompanion toCompanion(bool nullToAbsent) {
    return CardEventsCompanion(
      id: Value(id),
      date: Value(date),
      cardId: Value(cardId),
      type: Value(type),
      context: Value(context),
      action: Value(action),
      pos: pos == null && nullToAbsent ? const Value.absent() : Value(pos),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      correct: correct == null && nullToAbsent
          ? const Value.absent()
          : Value(correct),
      ts: Value(ts),
    );
  }

  factory CardEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardEventRow(
      id: serializer.fromJson<int>(json['id']),
      date: $CardEventsTable.$converterdate.fromJson(
        serializer.fromJson<String>(json['date']),
      ),
      cardId: serializer.fromJson<String>(json['cardId']),
      type: $CardEventsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      context: $CardEventsTable.$convertercontext.fromJson(
        serializer.fromJson<String>(json['context']),
      ),
      action: $CardEventsTable.$converteraction.fromJson(
        serializer.fromJson<String>(json['action']),
      ),
      pos: serializer.fromJson<int?>(json['pos']),
      value: serializer.fromJson<int?>(json['value']),
      correct: serializer.fromJson<bool?>(json['correct']),
      ts: $CardEventsTable.$converterts.fromJson(
        serializer.fromJson<int>(json['ts']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(
        $CardEventsTable.$converterdate.toJson(date),
      ),
      'cardId': serializer.toJson<String>(cardId),
      'type': serializer.toJson<String>(
        $CardEventsTable.$convertertype.toJson(type),
      ),
      'context': serializer.toJson<String>(
        $CardEventsTable.$convertercontext.toJson(context),
      ),
      'action': serializer.toJson<String>(
        $CardEventsTable.$converteraction.toJson(action),
      ),
      'pos': serializer.toJson<int?>(pos),
      'value': serializer.toJson<int?>(value),
      'correct': serializer.toJson<bool?>(correct),
      'ts': serializer.toJson<int>($CardEventsTable.$converterts.toJson(ts)),
    };
  }

  CardEventRow copyWith({
    int? id,
    LocalDate? date,
    String? cardId,
    CardType? type,
    CardContext? context,
    CardAction? action,
    Value<int?> pos = const Value.absent(),
    Value<int?> value = const Value.absent(),
    Value<bool?> correct = const Value.absent(),
    DateTime? ts,
  }) => CardEventRow(
    id: id ?? this.id,
    date: date ?? this.date,
    cardId: cardId ?? this.cardId,
    type: type ?? this.type,
    context: context ?? this.context,
    action: action ?? this.action,
    pos: pos.present ? pos.value : this.pos,
    value: value.present ? value.value : this.value,
    correct: correct.present ? correct.value : this.correct,
    ts: ts ?? this.ts,
  );
  CardEventRow copyWithCompanion(CardEventsCompanion data) {
    return CardEventRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      type: data.type.present ? data.type.value : this.type,
      context: data.context.present ? data.context.value : this.context,
      action: data.action.present ? data.action.value : this.action,
      pos: data.pos.present ? data.pos.value : this.pos,
      value: data.value.present ? data.value.value : this.value,
      correct: data.correct.present ? data.correct.value : this.correct,
      ts: data.ts.present ? data.ts.value : this.ts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardEventRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('cardId: $cardId, ')
          ..write('type: $type, ')
          ..write('context: $context, ')
          ..write('action: $action, ')
          ..write('pos: $pos, ')
          ..write('value: $value, ')
          ..write('correct: $correct, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    cardId,
    type,
    context,
    action,
    pos,
    value,
    correct,
    ts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardEventRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.cardId == this.cardId &&
          other.type == this.type &&
          other.context == this.context &&
          other.action == this.action &&
          other.pos == this.pos &&
          other.value == this.value &&
          other.correct == this.correct &&
          other.ts == this.ts);
}

class CardEventsCompanion extends UpdateCompanion<CardEventRow> {
  final Value<int> id;
  final Value<LocalDate> date;
  final Value<String> cardId;
  final Value<CardType> type;
  final Value<CardContext> context;
  final Value<CardAction> action;
  final Value<int?> pos;
  final Value<int?> value;
  final Value<bool?> correct;
  final Value<DateTime> ts;
  const CardEventsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.cardId = const Value.absent(),
    this.type = const Value.absent(),
    this.context = const Value.absent(),
    this.action = const Value.absent(),
    this.pos = const Value.absent(),
    this.value = const Value.absent(),
    this.correct = const Value.absent(),
    this.ts = const Value.absent(),
  });
  CardEventsCompanion.insert({
    this.id = const Value.absent(),
    required LocalDate date,
    required String cardId,
    required CardType type,
    required CardContext context,
    required CardAction action,
    this.pos = const Value.absent(),
    this.value = const Value.absent(),
    this.correct = const Value.absent(),
    required DateTime ts,
  }) : date = Value(date),
       cardId = Value(cardId),
       type = Value(type),
       context = Value(context),
       action = Value(action),
       ts = Value(ts);
  static Insertable<CardEventRow> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? cardId,
    Expression<String>? type,
    Expression<String>? context,
    Expression<String>? action,
    Expression<int>? pos,
    Expression<int>? value,
    Expression<bool>? correct,
    Expression<int>? ts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (cardId != null) 'card_id': cardId,
      if (type != null) 'type': type,
      if (context != null) 'context': context,
      if (action != null) 'action': action,
      if (pos != null) 'pos': pos,
      if (value != null) 'value': value,
      if (correct != null) 'correct': correct,
      if (ts != null) 'ts': ts,
    });
  }

  CardEventsCompanion copyWith({
    Value<int>? id,
    Value<LocalDate>? date,
    Value<String>? cardId,
    Value<CardType>? type,
    Value<CardContext>? context,
    Value<CardAction>? action,
    Value<int?>? pos,
    Value<int?>? value,
    Value<bool?>? correct,
    Value<DateTime>? ts,
  }) {
    return CardEventsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      cardId: cardId ?? this.cardId,
      type: type ?? this.type,
      context: context ?? this.context,
      action: action ?? this.action,
      pos: pos ?? this.pos,
      value: value ?? this.value,
      correct: correct ?? this.correct,
      ts: ts ?? this.ts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(
        $CardEventsTable.$converterdate.toSql(date.value),
      );
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CardEventsTable.$convertertype.toSql(type.value),
      );
    }
    if (context.present) {
      map['context'] = Variable<String>(
        $CardEventsTable.$convertercontext.toSql(context.value),
      );
    }
    if (action.present) {
      map['action'] = Variable<String>(
        $CardEventsTable.$converteraction.toSql(action.value),
      );
    }
    if (pos.present) {
      map['pos'] = Variable<int>(pos.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>($CardEventsTable.$converterts.toSql(ts.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardEventsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('cardId: $cardId, ')
          ..write('type: $type, ')
          ..write('context: $context, ')
          ..write('action: $action, ')
          ..write('pos: $pos, ')
          ..write('value: $value, ')
          ..write('correct: $correct, ')
          ..write('ts: $ts')
          ..write(')'))
        .toString();
  }
}

class $QuestLogsTable extends QuestLogs
    with TableInfo<$QuestLogsTable, QuestLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestLogsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($QuestLogsTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<QuestSlotKind, String> slot =
      GeneratedColumn<String>(
        'slot',
        aliasedName,
        false,
        check: () => slot.isIn(QuestSlotKind.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<QuestSlotKind>($QuestLogsTable.$converterslot);
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<QuestStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        check: () => status.isIn(QuestStatus.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('open'),
      ).withConverter<QuestStatus>($QuestLogsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> doneAt =
      GeneratedColumn<int>(
        'done_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($QuestLogsTable.$converterdoneAtn);
  @override
  List<GeneratedColumn> get $columns => [date, slot, questId, status, doneAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_log';
  @override
  Set<GeneratedColumn> get $primaryKey => {date, slot};
  @override
  QuestLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestLogRow(
      date: $QuestLogsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      slot: $QuestLogsTable.$converterslot.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}slot'],
        )!,
      ),
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
      status: $QuestLogsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      doneAt: $QuestLogsTable.$converterdoneAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}done_at'],
        ),
      ),
    );
  }

  @override
  $QuestLogsTable createAlias(String alias) {
    return $QuestLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocalDate, String, String> $converterdate =
      const LocalDateConverter();
  static JsonTypeConverter2<QuestSlotKind, String, String> $converterslot =
      const WireEnumConverter(QuestSlotKind.values);
  static JsonTypeConverter2<QuestStatus, String, String> $converterstatus =
      const WireEnumConverter(QuestStatus.values);
  static JsonTypeConverter2<DateTime, int, int> $converterdoneAt =
      const UtcMillisConverter();
  static JsonTypeConverter2<DateTime?, int?, int?> $converterdoneAtn =
      JsonTypeConverter2.asNullable($converterdoneAt);
}

class QuestLogRow extends DataClass implements Insertable<QuestLogRow> {
  final LocalDate date;
  final QuestSlotKind slot;
  final String questId;
  final QuestStatus status;
  final DateTime? doneAt;
  const QuestLogRow({
    required this.date,
    required this.slot,
    required this.questId,
    required this.status,
    this.doneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['date'] = Variable<String>(
        $QuestLogsTable.$converterdate.toSql(date),
      );
    }
    {
      map['slot'] = Variable<String>(
        $QuestLogsTable.$converterslot.toSql(slot),
      );
    }
    map['quest_id'] = Variable<String>(questId);
    {
      map['status'] = Variable<String>(
        $QuestLogsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<int>(
        $QuestLogsTable.$converterdoneAtn.toSql(doneAt),
      );
    }
    return map;
  }

  QuestLogsCompanion toCompanion(bool nullToAbsent) {
    return QuestLogsCompanion(
      date: Value(date),
      slot: Value(slot),
      questId: Value(questId),
      status: Value(status),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
    );
  }

  factory QuestLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestLogRow(
      date: $QuestLogsTable.$converterdate.fromJson(
        serializer.fromJson<String>(json['date']),
      ),
      slot: $QuestLogsTable.$converterslot.fromJson(
        serializer.fromJson<String>(json['slot']),
      ),
      questId: serializer.fromJson<String>(json['questId']),
      status: $QuestLogsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      doneAt: $QuestLogsTable.$converterdoneAtn.fromJson(
        serializer.fromJson<int?>(json['doneAt']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(
        $QuestLogsTable.$converterdate.toJson(date),
      ),
      'slot': serializer.toJson<String>(
        $QuestLogsTable.$converterslot.toJson(slot),
      ),
      'questId': serializer.toJson<String>(questId),
      'status': serializer.toJson<String>(
        $QuestLogsTable.$converterstatus.toJson(status),
      ),
      'doneAt': serializer.toJson<int?>(
        $QuestLogsTable.$converterdoneAtn.toJson(doneAt),
      ),
    };
  }

  QuestLogRow copyWith({
    LocalDate? date,
    QuestSlotKind? slot,
    String? questId,
    QuestStatus? status,
    Value<DateTime?> doneAt = const Value.absent(),
  }) => QuestLogRow(
    date: date ?? this.date,
    slot: slot ?? this.slot,
    questId: questId ?? this.questId,
    status: status ?? this.status,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
  );
  QuestLogRow copyWithCompanion(QuestLogsCompanion data) {
    return QuestLogRow(
      date: data.date.present ? data.date.value : this.date,
      slot: data.slot.present ? data.slot.value : this.slot,
      questId: data.questId.present ? data.questId.value : this.questId,
      status: data.status.present ? data.status.value : this.status,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestLogRow(')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('questId: $questId, ')
          ..write('status: $status, ')
          ..write('doneAt: $doneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, slot, questId, status, doneAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestLogRow &&
          other.date == this.date &&
          other.slot == this.slot &&
          other.questId == this.questId &&
          other.status == this.status &&
          other.doneAt == this.doneAt);
}

class QuestLogsCompanion extends UpdateCompanion<QuestLogRow> {
  final Value<LocalDate> date;
  final Value<QuestSlotKind> slot;
  final Value<String> questId;
  final Value<QuestStatus> status;
  final Value<DateTime?> doneAt;
  final Value<int> rowid;
  const QuestLogsCompanion({
    this.date = const Value.absent(),
    this.slot = const Value.absent(),
    this.questId = const Value.absent(),
    this.status = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestLogsCompanion.insert({
    required LocalDate date,
    required QuestSlotKind slot,
    required String questId,
    this.status = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       slot = Value(slot),
       questId = Value(questId);
  static Insertable<QuestLogRow> custom({
    Expression<String>? date,
    Expression<String>? slot,
    Expression<String>? questId,
    Expression<String>? status,
    Expression<int>? doneAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (slot != null) 'slot': slot,
      if (questId != null) 'quest_id': questId,
      if (status != null) 'status': status,
      if (doneAt != null) 'done_at': doneAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestLogsCompanion copyWith({
    Value<LocalDate>? date,
    Value<QuestSlotKind>? slot,
    Value<String>? questId,
    Value<QuestStatus>? status,
    Value<DateTime?>? doneAt,
    Value<int>? rowid,
  }) {
    return QuestLogsCompanion(
      date: date ?? this.date,
      slot: slot ?? this.slot,
      questId: questId ?? this.questId,
      status: status ?? this.status,
      doneAt: doneAt ?? this.doneAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(
        $QuestLogsTable.$converterdate.toSql(date.value),
      );
    }
    if (slot.present) {
      map['slot'] = Variable<String>(
        $QuestLogsTable.$converterslot.toSql(slot.value),
      );
    }
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $QuestLogsTable.$converterstatus.toSql(status.value),
      );
    }
    if (doneAt.present) {
      map['done_at'] = Variable<int>(
        $QuestLogsTable.$converterdoneAtn.toSql(doneAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestLogsCompanion(')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('questId: $questId, ')
          ..write('status: $status, ')
          ..write('doneAt: $doneAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayLogsTable extends DayLogs with TableInfo<$DayLogsTable, DayLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayLogsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate, String> date =
      GeneratedColumn<String>(
        'date',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocalDate>($DayLogsTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<DayStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        check: () => status.isIn(DayStatus.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DayStatus>($DayLogsTable.$converterstatus);
  @override
  late final GeneratedColumn<String> sources = GeneratedColumn<String>(
    'sources',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [date, status, sources];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_log';
  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DayLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayLogRow(
      date: $DayLogsTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      status: $DayLogsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      sources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources'],
      ),
    );
  }

  @override
  $DayLogsTable createAlias(String alias) {
    return $DayLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocalDate, String, String> $converterdate =
      const LocalDateConverter();
  static JsonTypeConverter2<DayStatus, String, String> $converterstatus =
      const WireEnumConverter(DayStatus.values);
}

class DayLogRow extends DataClass implements Insertable<DayLogRow> {
  final LocalDate date;
  final DayStatus status;
  final String? sources;
  const DayLogRow({required this.date, required this.status, this.sources});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['date'] = Variable<String>($DayLogsTable.$converterdate.toSql(date));
    }
    {
      map['status'] = Variable<String>(
        $DayLogsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || sources != null) {
      map['sources'] = Variable<String>(sources);
    }
    return map;
  }

  DayLogsCompanion toCompanion(bool nullToAbsent) {
    return DayLogsCompanion(
      date: Value(date),
      status: Value(status),
      sources: sources == null && nullToAbsent
          ? const Value.absent()
          : Value(sources),
    );
  }

  factory DayLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayLogRow(
      date: $DayLogsTable.$converterdate.fromJson(
        serializer.fromJson<String>(json['date']),
      ),
      status: $DayLogsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      sources: serializer.fromJson<String?>(json['sources']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(
        $DayLogsTable.$converterdate.toJson(date),
      ),
      'status': serializer.toJson<String>(
        $DayLogsTable.$converterstatus.toJson(status),
      ),
      'sources': serializer.toJson<String?>(sources),
    };
  }

  DayLogRow copyWith({
    LocalDate? date,
    DayStatus? status,
    Value<String?> sources = const Value.absent(),
  }) => DayLogRow(
    date: date ?? this.date,
    status: status ?? this.status,
    sources: sources.present ? sources.value : this.sources,
  );
  DayLogRow copyWithCompanion(DayLogsCompanion data) {
    return DayLogRow(
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      sources: data.sources.present ? data.sources.value : this.sources,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayLogRow(')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('sources: $sources')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, status, sources);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayLogRow &&
          other.date == this.date &&
          other.status == this.status &&
          other.sources == this.sources);
}

class DayLogsCompanion extends UpdateCompanion<DayLogRow> {
  final Value<LocalDate> date;
  final Value<DayStatus> status;
  final Value<String?> sources;
  final Value<int> rowid;
  const DayLogsCompanion({
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.sources = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayLogsCompanion.insert({
    required LocalDate date,
    required DayStatus status,
    this.sources = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       status = Value(status);
  static Insertable<DayLogRow> custom({
    Expression<String>? date,
    Expression<String>? status,
    Expression<String>? sources,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (sources != null) 'sources': sources,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayLogsCompanion copyWith({
    Value<LocalDate>? date,
    Value<DayStatus>? status,
    Value<String?>? sources,
    Value<int>? rowid,
  }) {
    return DayLogsCompanion(
      date: date ?? this.date,
      status: status ?? this.status,
      sources: sources ?? this.sources,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(
        $DayLogsTable.$converterdate.toSql(date.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DayLogsTable.$converterstatus.toSql(status.value),
      );
    }
    if (sources.present) {
      map['sources'] = Variable<String>(sources.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayLogsCompanion(')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('sources: $sources, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreakStatesTable extends StreakStates
    with TableInfo<$StreakStatesTable, StreakStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakStatesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> current = GeneratedColumn<int>(
    'current',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumn<int> longest = GeneratedColumn<int>(
    'longest',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumn<int> graceLeft = GeneratedColumn<int>(
    'grace_left',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  graceRefillAt = GeneratedColumn<String>(
    'grace_refill_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($StreakStatesTable.$convertergraceRefillAtn);
  @override
  late final GeneratedColumnWithTypeConverter<LocalDate?, String>
  lastEvaluatedDate = GeneratedColumn<String>(
    'last_evaluated_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<LocalDate?>($StreakStatesTable.$converterlastEvaluatedDaten);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    current,
    longest,
    graceLeft,
    graceRefillAt,
    lastEvaluatedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_state';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      current: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current'],
      )!,
      longest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest'],
      )!,
      graceLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grace_left'],
      )!,
      graceRefillAt: $StreakStatesTable.$convertergraceRefillAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}grace_refill_at'],
        ),
      ),
      lastEvaluatedDate: $StreakStatesTable.$converterlastEvaluatedDaten
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}last_evaluated_date'],
            ),
          ),
    );
  }

  @override
  $StreakStatesTable createAlias(String alias) {
    return $StreakStatesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocalDate, String, String> $convertergraceRefillAt =
      const LocalDateConverter();
  static JsonTypeConverter2<LocalDate?, String?, String?>
  $convertergraceRefillAtn = JsonTypeConverter2.asNullable(
    $convertergraceRefillAt,
  );
  static JsonTypeConverter2<LocalDate, String, String>
  $converterlastEvaluatedDate = const LocalDateConverter();
  static JsonTypeConverter2<LocalDate?, String?, String?>
  $converterlastEvaluatedDaten = JsonTypeConverter2.asNullable(
    $converterlastEvaluatedDate,
  );
}

class StreakStateRow extends DataClass implements Insertable<StreakStateRow> {
  final int id;
  final int current;
  final int longest;
  final int graceLeft;
  final LocalDate? graceRefillAt;
  final LocalDate? lastEvaluatedDate;
  const StreakStateRow({
    required this.id,
    required this.current,
    required this.longest,
    required this.graceLeft,
    this.graceRefillAt,
    this.lastEvaluatedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current'] = Variable<int>(current);
    map['longest'] = Variable<int>(longest);
    map['grace_left'] = Variable<int>(graceLeft);
    if (!nullToAbsent || graceRefillAt != null) {
      map['grace_refill_at'] = Variable<String>(
        $StreakStatesTable.$convertergraceRefillAtn.toSql(graceRefillAt),
      );
    }
    if (!nullToAbsent || lastEvaluatedDate != null) {
      map['last_evaluated_date'] = Variable<String>(
        $StreakStatesTable.$converterlastEvaluatedDaten.toSql(
          lastEvaluatedDate,
        ),
      );
    }
    return map;
  }

  StreakStatesCompanion toCompanion(bool nullToAbsent) {
    return StreakStatesCompanion(
      id: Value(id),
      current: Value(current),
      longest: Value(longest),
      graceLeft: Value(graceLeft),
      graceRefillAt: graceRefillAt == null && nullToAbsent
          ? const Value.absent()
          : Value(graceRefillAt),
      lastEvaluatedDate: lastEvaluatedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEvaluatedDate),
    );
  }

  factory StreakStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakStateRow(
      id: serializer.fromJson<int>(json['id']),
      current: serializer.fromJson<int>(json['current']),
      longest: serializer.fromJson<int>(json['longest']),
      graceLeft: serializer.fromJson<int>(json['graceLeft']),
      graceRefillAt: $StreakStatesTable.$convertergraceRefillAtn.fromJson(
        serializer.fromJson<String?>(json['graceRefillAt']),
      ),
      lastEvaluatedDate: $StreakStatesTable.$converterlastEvaluatedDaten
          .fromJson(serializer.fromJson<String?>(json['lastEvaluatedDate'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'current': serializer.toJson<int>(current),
      'longest': serializer.toJson<int>(longest),
      'graceLeft': serializer.toJson<int>(graceLeft),
      'graceRefillAt': serializer.toJson<String?>(
        $StreakStatesTable.$convertergraceRefillAtn.toJson(graceRefillAt),
      ),
      'lastEvaluatedDate': serializer.toJson<String?>(
        $StreakStatesTable.$converterlastEvaluatedDaten.toJson(
          lastEvaluatedDate,
        ),
      ),
    };
  }

  StreakStateRow copyWith({
    int? id,
    int? current,
    int? longest,
    int? graceLeft,
    Value<LocalDate?> graceRefillAt = const Value.absent(),
    Value<LocalDate?> lastEvaluatedDate = const Value.absent(),
  }) => StreakStateRow(
    id: id ?? this.id,
    current: current ?? this.current,
    longest: longest ?? this.longest,
    graceLeft: graceLeft ?? this.graceLeft,
    graceRefillAt: graceRefillAt.present
        ? graceRefillAt.value
        : this.graceRefillAt,
    lastEvaluatedDate: lastEvaluatedDate.present
        ? lastEvaluatedDate.value
        : this.lastEvaluatedDate,
  );
  StreakStateRow copyWithCompanion(StreakStatesCompanion data) {
    return StreakStateRow(
      id: data.id.present ? data.id.value : this.id,
      current: data.current.present ? data.current.value : this.current,
      longest: data.longest.present ? data.longest.value : this.longest,
      graceLeft: data.graceLeft.present ? data.graceLeft.value : this.graceLeft,
      graceRefillAt: data.graceRefillAt.present
          ? data.graceRefillAt.value
          : this.graceRefillAt,
      lastEvaluatedDate: data.lastEvaluatedDate.present
          ? data.lastEvaluatedDate.value
          : this.lastEvaluatedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakStateRow(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('graceLeft: $graceLeft, ')
          ..write('graceRefillAt: $graceRefillAt, ')
          ..write('lastEvaluatedDate: $lastEvaluatedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    current,
    longest,
    graceLeft,
    graceRefillAt,
    lastEvaluatedDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakStateRow &&
          other.id == this.id &&
          other.current == this.current &&
          other.longest == this.longest &&
          other.graceLeft == this.graceLeft &&
          other.graceRefillAt == this.graceRefillAt &&
          other.lastEvaluatedDate == this.lastEvaluatedDate);
}

class StreakStatesCompanion extends UpdateCompanion<StreakStateRow> {
  final Value<int> id;
  final Value<int> current;
  final Value<int> longest;
  final Value<int> graceLeft;
  final Value<LocalDate?> graceRefillAt;
  final Value<LocalDate?> lastEvaluatedDate;
  const StreakStatesCompanion({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.graceLeft = const Value.absent(),
    this.graceRefillAt = const Value.absent(),
    this.lastEvaluatedDate = const Value.absent(),
  });
  StreakStatesCompanion.insert({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.graceLeft = const Value.absent(),
    this.graceRefillAt = const Value.absent(),
    this.lastEvaluatedDate = const Value.absent(),
  });
  static Insertable<StreakStateRow> custom({
    Expression<int>? id,
    Expression<int>? current,
    Expression<int>? longest,
    Expression<int>? graceLeft,
    Expression<String>? graceRefillAt,
    Expression<String>? lastEvaluatedDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (current != null) 'current': current,
      if (longest != null) 'longest': longest,
      if (graceLeft != null) 'grace_left': graceLeft,
      if (graceRefillAt != null) 'grace_refill_at': graceRefillAt,
      if (lastEvaluatedDate != null) 'last_evaluated_date': lastEvaluatedDate,
    });
  }

  StreakStatesCompanion copyWith({
    Value<int>? id,
    Value<int>? current,
    Value<int>? longest,
    Value<int>? graceLeft,
    Value<LocalDate?>? graceRefillAt,
    Value<LocalDate?>? lastEvaluatedDate,
  }) {
    return StreakStatesCompanion(
      id: id ?? this.id,
      current: current ?? this.current,
      longest: longest ?? this.longest,
      graceLeft: graceLeft ?? this.graceLeft,
      graceRefillAt: graceRefillAt ?? this.graceRefillAt,
      lastEvaluatedDate: lastEvaluatedDate ?? this.lastEvaluatedDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (current.present) {
      map['current'] = Variable<int>(current.value);
    }
    if (longest.present) {
      map['longest'] = Variable<int>(longest.value);
    }
    if (graceLeft.present) {
      map['grace_left'] = Variable<int>(graceLeft.value);
    }
    if (graceRefillAt.present) {
      map['grace_refill_at'] = Variable<String>(
        $StreakStatesTable.$convertergraceRefillAtn.toSql(graceRefillAt.value),
      );
    }
    if (lastEvaluatedDate.present) {
      map['last_evaluated_date'] = Variable<String>(
        $StreakStatesTable.$converterlastEvaluatedDaten.toSql(
          lastEvaluatedDate.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakStatesCompanion(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('graceLeft: $graceLeft, ')
          ..write('graceRefillAt: $graceRefillAt, ')
          ..write('lastEvaluatedDate: $lastEvaluatedDate')
          ..write(')'))
        .toString();
  }
}

class $BlockedAppsTable extends BlockedApps
    with TableInfo<$BlockedAppsTable, BlockedAppRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlockedAppsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> platformRef = GeneratedColumn<String>(
    'platform_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> cardsRequired = GeneratedColumn<int>(
    'cards_required',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  @override
  late final GeneratedColumn<int> unlockMinutes = GeneratedColumn<int>(
    'unlock_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BlockedAppsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    platformRef,
    label,
    cardsRequired,
    unlockMinutes,
    enabled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blocked_app';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlockedAppRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockedAppRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      platformRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform_ref'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      cardsRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cards_required'],
      )!,
      unlockMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unlock_minutes'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: $BlockedAppsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $BlockedAppsTable createAlias(String alias) {
    return $BlockedAppsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, int, int> $convertercreatedAt =
      const UtcMillisConverter();
}

class BlockedAppRow extends DataClass implements Insertable<BlockedAppRow> {
  final int id;
  final String platformRef;
  final String? label;
  final int cardsRequired;
  final int unlockMinutes;
  final bool enabled;
  final DateTime createdAt;
  const BlockedAppRow({
    required this.id,
    required this.platformRef,
    this.label,
    required this.cardsRequired,
    required this.unlockMinutes,
    required this.enabled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['platform_ref'] = Variable<String>(platformRef);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['cards_required'] = Variable<int>(cardsRequired);
    map['unlock_minutes'] = Variable<int>(unlockMinutes);
    map['enabled'] = Variable<bool>(enabled);
    {
      map['created_at'] = Variable<int>(
        $BlockedAppsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  BlockedAppsCompanion toCompanion(bool nullToAbsent) {
    return BlockedAppsCompanion(
      id: Value(id),
      platformRef: Value(platformRef),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      cardsRequired: Value(cardsRequired),
      unlockMinutes: Value(unlockMinutes),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
    );
  }

  factory BlockedAppRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockedAppRow(
      id: serializer.fromJson<int>(json['id']),
      platformRef: serializer.fromJson<String>(json['platformRef']),
      label: serializer.fromJson<String?>(json['label']),
      cardsRequired: serializer.fromJson<int>(json['cardsRequired']),
      unlockMinutes: serializer.fromJson<int>(json['unlockMinutes']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: $BlockedAppsTable.$convertercreatedAt.fromJson(
        serializer.fromJson<int>(json['createdAt']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'platformRef': serializer.toJson<String>(platformRef),
      'label': serializer.toJson<String?>(label),
      'cardsRequired': serializer.toJson<int>(cardsRequired),
      'unlockMinutes': serializer.toJson<int>(unlockMinutes),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<int>(
        $BlockedAppsTable.$convertercreatedAt.toJson(createdAt),
      ),
    };
  }

  BlockedAppRow copyWith({
    int? id,
    String? platformRef,
    Value<String?> label = const Value.absent(),
    int? cardsRequired,
    int? unlockMinutes,
    bool? enabled,
    DateTime? createdAt,
  }) => BlockedAppRow(
    id: id ?? this.id,
    platformRef: platformRef ?? this.platformRef,
    label: label.present ? label.value : this.label,
    cardsRequired: cardsRequired ?? this.cardsRequired,
    unlockMinutes: unlockMinutes ?? this.unlockMinutes,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
  );
  BlockedAppRow copyWithCompanion(BlockedAppsCompanion data) {
    return BlockedAppRow(
      id: data.id.present ? data.id.value : this.id,
      platformRef: data.platformRef.present
          ? data.platformRef.value
          : this.platformRef,
      label: data.label.present ? data.label.value : this.label,
      cardsRequired: data.cardsRequired.present
          ? data.cardsRequired.value
          : this.cardsRequired,
      unlockMinutes: data.unlockMinutes.present
          ? data.unlockMinutes.value
          : this.unlockMinutes,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockedAppRow(')
          ..write('id: $id, ')
          ..write('platformRef: $platformRef, ')
          ..write('label: $label, ')
          ..write('cardsRequired: $cardsRequired, ')
          ..write('unlockMinutes: $unlockMinutes, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    platformRef,
    label,
    cardsRequired,
    unlockMinutes,
    enabled,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockedAppRow &&
          other.id == this.id &&
          other.platformRef == this.platformRef &&
          other.label == this.label &&
          other.cardsRequired == this.cardsRequired &&
          other.unlockMinutes == this.unlockMinutes &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt);
}

class BlockedAppsCompanion extends UpdateCompanion<BlockedAppRow> {
  final Value<int> id;
  final Value<String> platformRef;
  final Value<String?> label;
  final Value<int> cardsRequired;
  final Value<int> unlockMinutes;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  const BlockedAppsCompanion({
    this.id = const Value.absent(),
    this.platformRef = const Value.absent(),
    this.label = const Value.absent(),
    this.cardsRequired = const Value.absent(),
    this.unlockMinutes = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BlockedAppsCompanion.insert({
    this.id = const Value.absent(),
    required String platformRef,
    this.label = const Value.absent(),
    this.cardsRequired = const Value.absent(),
    this.unlockMinutes = const Value.absent(),
    this.enabled = const Value.absent(),
    required DateTime createdAt,
  }) : platformRef = Value(platformRef),
       createdAt = Value(createdAt);
  static Insertable<BlockedAppRow> custom({
    Expression<int>? id,
    Expression<String>? platformRef,
    Expression<String>? label,
    Expression<int>? cardsRequired,
    Expression<int>? unlockMinutes,
    Expression<bool>? enabled,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (platformRef != null) 'platform_ref': platformRef,
      if (label != null) 'label': label,
      if (cardsRequired != null) 'cards_required': cardsRequired,
      if (unlockMinutes != null) 'unlock_minutes': unlockMinutes,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BlockedAppsCompanion copyWith({
    Value<int>? id,
    Value<String>? platformRef,
    Value<String?>? label,
    Value<int>? cardsRequired,
    Value<int>? unlockMinutes,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
  }) {
    return BlockedAppsCompanion(
      id: id ?? this.id,
      platformRef: platformRef ?? this.platformRef,
      label: label ?? this.label,
      cardsRequired: cardsRequired ?? this.cardsRequired,
      unlockMinutes: unlockMinutes ?? this.unlockMinutes,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (platformRef.present) {
      map['platform_ref'] = Variable<String>(platformRef.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (cardsRequired.present) {
      map['cards_required'] = Variable<int>(cardsRequired.value);
    }
    if (unlockMinutes.present) {
      map['unlock_minutes'] = Variable<int>(unlockMinutes.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $BlockedAppsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlockedAppsCompanion(')
          ..write('id: $id, ')
          ..write('platformRef: $platformRef, ')
          ..write('label: $label, ')
          ..write('cardsRequired: $cardsRequired, ')
          ..write('unlockMinutes: $unlockMinutes, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GateSessionsTable extends GateSessions
    with TableInfo<$GateSessionsTable, GateSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GateSessionsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<int> blockedAppId = GeneratedColumn<int>(
    'blocked_app_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blocked_app (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> openedAt =
      GeneratedColumn<int>(
        'opened_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($GateSessionsTable.$converteropenedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> closedAt =
      GeneratedColumn<int>(
        'closed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($GateSessionsTable.$converterclosedAtn);
  @override
  late final GeneratedColumn<int> cardsSeen = GeneratedColumn<int>(
    'cards_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<GateResult?, String> result =
      GeneratedColumn<String>(
        'result',
        aliasedName,
        true,
        check: () => result.isIn(GateResult.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<GateResult?>($GateSessionsTable.$converterresultn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    blockedAppId,
    openedAt,
    closedAt,
    cardsSeen,
    result,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gate_session';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GateSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GateSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      blockedAppId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blocked_app_id'],
      ),
      openedAt: $GateSessionsTable.$converteropenedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}opened_at'],
        )!,
      ),
      closedAt: $GateSessionsTable.$converterclosedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}closed_at'],
        ),
      ),
      cardsSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cards_seen'],
      )!,
      result: $GateSessionsTable.$converterresultn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        ),
      ),
    );
  }

  @override
  $GateSessionsTable createAlias(String alias) {
    return $GateSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, int, int> $converteropenedAt =
      const UtcMillisConverter();
  static JsonTypeConverter2<DateTime, int, int> $converterclosedAt =
      const UtcMillisConverter();
  static JsonTypeConverter2<DateTime?, int?, int?> $converterclosedAtn =
      JsonTypeConverter2.asNullable($converterclosedAt);
  static JsonTypeConverter2<GateResult, String, String> $converterresult =
      const WireEnumConverter(GateResult.values);
  static JsonTypeConverter2<GateResult?, String?, String?> $converterresultn =
      JsonTypeConverter2.asNullable($converterresult);
}

class GateSessionRow extends DataClass implements Insertable<GateSessionRow> {
  final int id;
  final int? blockedAppId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int cardsSeen;
  final GateResult? result;
  const GateSessionRow({
    required this.id,
    this.blockedAppId,
    required this.openedAt,
    this.closedAt,
    required this.cardsSeen,
    this.result,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || blockedAppId != null) {
      map['blocked_app_id'] = Variable<int>(blockedAppId);
    }
    {
      map['opened_at'] = Variable<int>(
        $GateSessionsTable.$converteropenedAt.toSql(openedAt),
      );
    }
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(
        $GateSessionsTable.$converterclosedAtn.toSql(closedAt),
      );
    }
    map['cards_seen'] = Variable<int>(cardsSeen);
    if (!nullToAbsent || result != null) {
      map['result'] = Variable<String>(
        $GateSessionsTable.$converterresultn.toSql(result),
      );
    }
    return map;
  }

  GateSessionsCompanion toCompanion(bool nullToAbsent) {
    return GateSessionsCompanion(
      id: Value(id),
      blockedAppId: blockedAppId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockedAppId),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      cardsSeen: Value(cardsSeen),
      result: result == null && nullToAbsent
          ? const Value.absent()
          : Value(result),
    );
  }

  factory GateSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GateSessionRow(
      id: serializer.fromJson<int>(json['id']),
      blockedAppId: serializer.fromJson<int?>(json['blockedAppId']),
      openedAt: $GateSessionsTable.$converteropenedAt.fromJson(
        serializer.fromJson<int>(json['openedAt']),
      ),
      closedAt: $GateSessionsTable.$converterclosedAtn.fromJson(
        serializer.fromJson<int?>(json['closedAt']),
      ),
      cardsSeen: serializer.fromJson<int>(json['cardsSeen']),
      result: $GateSessionsTable.$converterresultn.fromJson(
        serializer.fromJson<String?>(json['result']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'blockedAppId': serializer.toJson<int?>(blockedAppId),
      'openedAt': serializer.toJson<int>(
        $GateSessionsTable.$converteropenedAt.toJson(openedAt),
      ),
      'closedAt': serializer.toJson<int?>(
        $GateSessionsTable.$converterclosedAtn.toJson(closedAt),
      ),
      'cardsSeen': serializer.toJson<int>(cardsSeen),
      'result': serializer.toJson<String?>(
        $GateSessionsTable.$converterresultn.toJson(result),
      ),
    };
  }

  GateSessionRow copyWith({
    int? id,
    Value<int?> blockedAppId = const Value.absent(),
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
    int? cardsSeen,
    Value<GateResult?> result = const Value.absent(),
  }) => GateSessionRow(
    id: id ?? this.id,
    blockedAppId: blockedAppId.present ? blockedAppId.value : this.blockedAppId,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    cardsSeen: cardsSeen ?? this.cardsSeen,
    result: result.present ? result.value : this.result,
  );
  GateSessionRow copyWithCompanion(GateSessionsCompanion data) {
    return GateSessionRow(
      id: data.id.present ? data.id.value : this.id,
      blockedAppId: data.blockedAppId.present
          ? data.blockedAppId.value
          : this.blockedAppId,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      cardsSeen: data.cardsSeen.present ? data.cardsSeen.value : this.cardsSeen,
      result: data.result.present ? data.result.value : this.result,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GateSessionRow(')
          ..write('id: $id, ')
          ..write('blockedAppId: $blockedAppId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('cardsSeen: $cardsSeen, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, blockedAppId, openedAt, closedAt, cardsSeen, result);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GateSessionRow &&
          other.id == this.id &&
          other.blockedAppId == this.blockedAppId &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.cardsSeen == this.cardsSeen &&
          other.result == this.result);
}

class GateSessionsCompanion extends UpdateCompanion<GateSessionRow> {
  final Value<int> id;
  final Value<int?> blockedAppId;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<int> cardsSeen;
  final Value<GateResult?> result;
  const GateSessionsCompanion({
    this.id = const Value.absent(),
    this.blockedAppId = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.cardsSeen = const Value.absent(),
    this.result = const Value.absent(),
  });
  GateSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.blockedAppId = const Value.absent(),
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
    this.cardsSeen = const Value.absent(),
    this.result = const Value.absent(),
  }) : openedAt = Value(openedAt);
  static Insertable<GateSessionRow> custom({
    Expression<int>? id,
    Expression<int>? blockedAppId,
    Expression<int>? openedAt,
    Expression<int>? closedAt,
    Expression<int>? cardsSeen,
    Expression<String>? result,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (blockedAppId != null) 'blocked_app_id': blockedAppId,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (cardsSeen != null) 'cards_seen': cardsSeen,
      if (result != null) 'result': result,
    });
  }

  GateSessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? blockedAppId,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
    Value<int>? cardsSeen,
    Value<GateResult?>? result,
  }) {
    return GateSessionsCompanion(
      id: id ?? this.id,
      blockedAppId: blockedAppId ?? this.blockedAppId,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      cardsSeen: cardsSeen ?? this.cardsSeen,
      result: result ?? this.result,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (blockedAppId.present) {
      map['blocked_app_id'] = Variable<int>(blockedAppId.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<int>(
        $GateSessionsTable.$converteropenedAt.toSql(openedAt.value),
      );
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(
        $GateSessionsTable.$converterclosedAtn.toSql(closedAt.value),
      );
    }
    if (cardsSeen.present) {
      map['cards_seen'] = Variable<int>(cardsSeen.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $GateSessionsTable.$converterresultn.toSql(result.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GateSessionsCompanion(')
          ..write('id: $id, ')
          ..write('blockedAppId: $blockedAppId, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('cardsSeen: $cardsSeen, ')
          ..write('result: $result')
          ..write(')'))
        .toString();
  }
}

class $UnlockEventsTable extends UnlockEvents
    with TableInfo<$UnlockEventsTable, UnlockEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnlockEventsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<int> blockedAppId = GeneratedColumn<int>(
    'blocked_app_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES blocked_app (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> ts =
      GeneratedColumn<int>(
        'ts',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($UnlockEventsTable.$converterts);
  @override
  late final GeneratedColumnWithTypeConverter<UnlockSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        check: () => source.isIn(UnlockSource.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<UnlockSource>($UnlockEventsTable.$convertersource);
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, blockedAppId, ts, source, minutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unlock_event';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnlockEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnlockEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      blockedAppId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blocked_app_id'],
      ),
      ts: $UnlockEventsTable.$converterts.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}ts'],
        )!,
      ),
      source: $UnlockEventsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
    );
  }

  @override
  $UnlockEventsTable createAlias(String alias) {
    return $UnlockEventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, int, int> $converterts =
      const UtcMillisConverter();
  static JsonTypeConverter2<UnlockSource, String, String> $convertersource =
      const WireEnumConverter(UnlockSource.values);
}

class UnlockEventRow extends DataClass implements Insertable<UnlockEventRow> {
  final int id;
  final int? blockedAppId;
  final DateTime ts;
  final UnlockSource source;
  final int minutes;
  const UnlockEventRow({
    required this.id,
    this.blockedAppId,
    required this.ts,
    required this.source,
    required this.minutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || blockedAppId != null) {
      map['blocked_app_id'] = Variable<int>(blockedAppId);
    }
    {
      map['ts'] = Variable<int>($UnlockEventsTable.$converterts.toSql(ts));
    }
    {
      map['source'] = Variable<String>(
        $UnlockEventsTable.$convertersource.toSql(source),
      );
    }
    map['minutes'] = Variable<int>(minutes);
    return map;
  }

  UnlockEventsCompanion toCompanion(bool nullToAbsent) {
    return UnlockEventsCompanion(
      id: Value(id),
      blockedAppId: blockedAppId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockedAppId),
      ts: Value(ts),
      source: Value(source),
      minutes: Value(minutes),
    );
  }

  factory UnlockEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnlockEventRow(
      id: serializer.fromJson<int>(json['id']),
      blockedAppId: serializer.fromJson<int?>(json['blockedAppId']),
      ts: $UnlockEventsTable.$converterts.fromJson(
        serializer.fromJson<int>(json['ts']),
      ),
      source: $UnlockEventsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      minutes: serializer.fromJson<int>(json['minutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'blockedAppId': serializer.toJson<int?>(blockedAppId),
      'ts': serializer.toJson<int>($UnlockEventsTable.$converterts.toJson(ts)),
      'source': serializer.toJson<String>(
        $UnlockEventsTable.$convertersource.toJson(source),
      ),
      'minutes': serializer.toJson<int>(minutes),
    };
  }

  UnlockEventRow copyWith({
    int? id,
    Value<int?> blockedAppId = const Value.absent(),
    DateTime? ts,
    UnlockSource? source,
    int? minutes,
  }) => UnlockEventRow(
    id: id ?? this.id,
    blockedAppId: blockedAppId.present ? blockedAppId.value : this.blockedAppId,
    ts: ts ?? this.ts,
    source: source ?? this.source,
    minutes: minutes ?? this.minutes,
  );
  UnlockEventRow copyWithCompanion(UnlockEventsCompanion data) {
    return UnlockEventRow(
      id: data.id.present ? data.id.value : this.id,
      blockedAppId: data.blockedAppId.present
          ? data.blockedAppId.value
          : this.blockedAppId,
      ts: data.ts.present ? data.ts.value : this.ts,
      source: data.source.present ? data.source.value : this.source,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnlockEventRow(')
          ..write('id: $id, ')
          ..write('blockedAppId: $blockedAppId, ')
          ..write('ts: $ts, ')
          ..write('source: $source, ')
          ..write('minutes: $minutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, blockedAppId, ts, source, minutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnlockEventRow &&
          other.id == this.id &&
          other.blockedAppId == this.blockedAppId &&
          other.ts == this.ts &&
          other.source == this.source &&
          other.minutes == this.minutes);
}

class UnlockEventsCompanion extends UpdateCompanion<UnlockEventRow> {
  final Value<int> id;
  final Value<int?> blockedAppId;
  final Value<DateTime> ts;
  final Value<UnlockSource> source;
  final Value<int> minutes;
  const UnlockEventsCompanion({
    this.id = const Value.absent(),
    this.blockedAppId = const Value.absent(),
    this.ts = const Value.absent(),
    this.source = const Value.absent(),
    this.minutes = const Value.absent(),
  });
  UnlockEventsCompanion.insert({
    this.id = const Value.absent(),
    this.blockedAppId = const Value.absent(),
    required DateTime ts,
    required UnlockSource source,
    required int minutes,
  }) : ts = Value(ts),
       source = Value(source),
       minutes = Value(minutes);
  static Insertable<UnlockEventRow> custom({
    Expression<int>? id,
    Expression<int>? blockedAppId,
    Expression<int>? ts,
    Expression<String>? source,
    Expression<int>? minutes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (blockedAppId != null) 'blocked_app_id': blockedAppId,
      if (ts != null) 'ts': ts,
      if (source != null) 'source': source,
      if (minutes != null) 'minutes': minutes,
    });
  }

  UnlockEventsCompanion copyWith({
    Value<int>? id,
    Value<int?>? blockedAppId,
    Value<DateTime>? ts,
    Value<UnlockSource>? source,
    Value<int>? minutes,
  }) {
    return UnlockEventsCompanion(
      id: id ?? this.id,
      blockedAppId: blockedAppId ?? this.blockedAppId,
      ts: ts ?? this.ts,
      source: source ?? this.source,
      minutes: minutes ?? this.minutes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (blockedAppId.present) {
      map['blocked_app_id'] = Variable<int>(blockedAppId.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(
        $UnlockEventsTable.$converterts.toSql(ts.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $UnlockEventsTable.$convertersource.toSql(source.value),
      );
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnlockEventsCompanion(')
          ..write('id: $id, ')
          ..write('blockedAppId: $blockedAppId, ')
          ..write('ts: $ts, ')
          ..write('source: $source, ')
          ..write('minutes: $minutes')
          ..write(')'))
        .toString();
  }
}

class $SavedCardsTable extends SavedCards
    with TableInfo<$SavedCardsTable, SavedCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedCardsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> savedAt =
      GeneratedColumn<int>(
        'saved_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SavedCardsTable.$convertersavedAt);
  @override
  List<GeneratedColumn> get $columns => [cardId, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_card';
  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  SavedCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedCardRow(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      savedAt: $SavedCardsTable.$convertersavedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}saved_at'],
        )!,
      ),
    );
  }

  @override
  $SavedCardsTable createAlias(String alias) {
    return $SavedCardsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DateTime, int, int> $convertersavedAt =
      const UtcMillisConverter();
}

class SavedCardRow extends DataClass implements Insertable<SavedCardRow> {
  final String cardId;
  final DateTime savedAt;
  const SavedCardRow({required this.cardId, required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    {
      map['saved_at'] = Variable<int>(
        $SavedCardsTable.$convertersavedAt.toSql(savedAt),
      );
    }
    return map;
  }

  SavedCardsCompanion toCompanion(bool nullToAbsent) {
    return SavedCardsCompanion(cardId: Value(cardId), savedAt: Value(savedAt));
  }

  factory SavedCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedCardRow(
      cardId: serializer.fromJson<String>(json['cardId']),
      savedAt: $SavedCardsTable.$convertersavedAt.fromJson(
        serializer.fromJson<int>(json['savedAt']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'savedAt': serializer.toJson<int>(
        $SavedCardsTable.$convertersavedAt.toJson(savedAt),
      ),
    };
  }

  SavedCardRow copyWith({String? cardId, DateTime? savedAt}) => SavedCardRow(
    cardId: cardId ?? this.cardId,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedCardRow copyWithCompanion(SavedCardsCompanion data) {
    return SavedCardRow(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedCardRow(')
          ..write('cardId: $cardId, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cardId, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedCardRow &&
          other.cardId == this.cardId &&
          other.savedAt == this.savedAt);
}

class SavedCardsCompanion extends UpdateCompanion<SavedCardRow> {
  final Value<String> cardId;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedCardsCompanion({
    this.cardId = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedCardsCompanion.insert({
    required String cardId,
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       savedAt = Value(savedAt);
  static Insertable<SavedCardRow> custom({
    Expression<String>? cardId,
    Expression<int>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedCardsCompanion copyWith({
    Value<String>? cardId,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return SavedCardsCompanion(
      cardId: cardId ?? this.cardId,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<int>(
        $SavedCardsTable.$convertersavedAt.toSql(savedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedCardsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDb extends GeneratedDatabase {
  _$UserDb(QueryExecutor e) : super(e);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $DailySetsTable dailySets = $DailySetsTable(this);
  late final $CardEventsTable cardEvents = $CardEventsTable(this);
  late final $QuestLogsTable questLogs = $QuestLogsTable(this);
  late final $DayLogsTable dayLogs = $DayLogsTable(this);
  late final $StreakStatesTable streakStates = $StreakStatesTable(this);
  late final $BlockedAppsTable blockedApps = $BlockedAppsTable(this);
  late final $GateSessionsTable gateSessions = $GateSessionsTable(this);
  late final $UnlockEventsTable unlockEvents = $UnlockEventsTable(this);
  late final $SavedCardsTable savedCards = $SavedCardsTable(this);
  late final Index cardEventDate = Index(
    'card_event_date',
    'CREATE INDEX card_event_date ON card_event (date)',
  );
  late final Index cardEventCardId = Index(
    'card_event_card_id',
    'CREATE INDEX card_event_card_id ON card_event (card_id)',
  );
  late final Index cardEventTypeAction = Index(
    'card_event_type_action',
    'CREATE INDEX card_event_type_action ON card_event (type, "action", card_id)',
  );
  late final Index cardEventSeenUnique = Index(
    'card_event_seen_unique',
    'CREATE UNIQUE INDEX card_event_seen_unique ON card_event (date, card_id, context) WHERE "action" = \'seen\'',
  );
  late final Index unlockEventTs = Index(
    'unlock_event_ts',
    'CREATE INDEX unlock_event_ts ON unlock_event (ts)',
  );
  late final Index savedCardSavedAt = Index(
    'saved_card_saved_at',
    'CREATE INDEX saved_card_saved_at ON saved_card (saved_at)',
  );
  late final SettingsDao settingsDao = SettingsDao(this as UserDb);
  late final DailySetDao dailySetDao = DailySetDao(this as UserDb);
  late final CardEventDao cardEventDao = CardEventDao(this as UserDb);
  late final QuestLogDao questLogDao = QuestLogDao(this as UserDb);
  late final StreakDao streakDao = StreakDao(this as UserDb);
  late final BlockerDao blockerDao = BlockerDao(this as UserDb);
  late final SavedCardDao savedCardDao = SavedCardDao(this as UserDb);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    dailySets,
    cardEvents,
    questLogs,
    dayLogs,
    streakStates,
    blockedApps,
    gateSessions,
    unlockEvents,
    savedCards,
    cardEventDate,
    cardEventCardId,
    cardEventTypeAction,
    cardEventSeenUnique,
    unlockEventTs,
    savedCardSavedAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'blocked_app',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gate_session', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'blocked_app',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('unlock_event', kind: UpdateKind.update)],
    ),
  ]);
}
