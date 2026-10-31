// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_db.dart';

// ignore_for_file: type=lint
class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
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
      ).withConverter<LocalDate>($JournalEntriesTable.$converterdate);
  @override
  late final GeneratedColumnWithTypeConverter<JournalKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        check: () => kind.isIn(JournalKind.values.map((e) => e.wire)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<JournalKind>($JournalEntriesTable.$converterkind);
  @override
  late final GeneratedColumn<String> promptId = GeneratedColumn<String>(
    'prompt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($JournalEntriesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($JournalEntriesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    kind,
    promptId,
    prompt,
    body,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entry';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: $JournalEntriesTable.$converterdate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}date'],
        )!,
      ),
      kind: $JournalEntriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      promptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_id'],
      ),
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: $JournalEntriesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $JournalEntriesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocalDate, String, String> $converterdate =
      const LocalDateConverter();
  static JsonTypeConverter2<JournalKind, String, String> $converterkind =
      const WireEnumConverter(JournalKind.values);
  static JsonTypeConverter2<DateTime, int, int> $convertercreatedAt =
      const UtcMillisConverter();
  static JsonTypeConverter2<DateTime, int, int> $converterupdatedAt =
      const UtcMillisConverter();
}

class JournalEntryRow extends DataClass implements Insertable<JournalEntryRow> {
  final int id;
  final LocalDate date;
  final JournalKind kind;

  /// `card.id` otazky (prompt), ak zaznam odpoveda na otazku z obsahu.
  final String? promptId;

  /// Text otazky v case zapisu (export je citatelny aj bez content.db).
  final String? prompt;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  const JournalEntryRow({
    required this.id,
    required this.date,
    required this.kind,
    this.promptId,
    this.prompt,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['date'] = Variable<String>(
        $JournalEntriesTable.$converterdate.toSql(date),
      );
    }
    {
      map['kind'] = Variable<String>(
        $JournalEntriesTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || promptId != null) {
      map['prompt_id'] = Variable<String>(promptId);
    }
    if (!nullToAbsent || prompt != null) {
      map['prompt'] = Variable<String>(prompt);
    }
    map['body'] = Variable<String>(body);
    {
      map['created_at'] = Variable<int>(
        $JournalEntriesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $JournalEntriesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      date: Value(date),
      kind: Value(kind),
      promptId: promptId == null && nullToAbsent
          ? const Value.absent()
          : Value(promptId),
      prompt: prompt == null && nullToAbsent
          ? const Value.absent()
          : Value(prompt),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory JournalEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryRow(
      id: serializer.fromJson<int>(json['id']),
      date: $JournalEntriesTable.$converterdate.fromJson(
        serializer.fromJson<String>(json['date']),
      ),
      kind: $JournalEntriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      promptId: serializer.fromJson<String?>(json['promptId']),
      prompt: serializer.fromJson<String?>(json['prompt']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: $JournalEntriesTable.$convertercreatedAt.fromJson(
        serializer.fromJson<int>(json['createdAt']),
      ),
      updatedAt: $JournalEntriesTable.$converterupdatedAt.fromJson(
        serializer.fromJson<int>(json['updatedAt']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(
        $JournalEntriesTable.$converterdate.toJson(date),
      ),
      'kind': serializer.toJson<String>(
        $JournalEntriesTable.$converterkind.toJson(kind),
      ),
      'promptId': serializer.toJson<String?>(promptId),
      'prompt': serializer.toJson<String?>(prompt),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<int>(
        $JournalEntriesTable.$convertercreatedAt.toJson(createdAt),
      ),
      'updatedAt': serializer.toJson<int>(
        $JournalEntriesTable.$converterupdatedAt.toJson(updatedAt),
      ),
    };
  }

  JournalEntryRow copyWith({
    int? id,
    LocalDate? date,
    JournalKind? kind,
    Value<String?> promptId = const Value.absent(),
    Value<String?> prompt = const Value.absent(),
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => JournalEntryRow(
    id: id ?? this.id,
    date: date ?? this.date,
    kind: kind ?? this.kind,
    promptId: promptId.present ? promptId.value : this.promptId,
    prompt: prompt.present ? prompt.value : this.prompt,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  JournalEntryRow copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntryRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      promptId: data.promptId.present ? data.promptId.value : this.promptId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('promptId: $promptId, ')
          ..write('prompt: $prompt, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, kind, promptId, prompt, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.promptId == this.promptId &&
          other.prompt == this.prompt &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntryRow> {
  final Value<int> id;
  final Value<LocalDate> date;
  final Value<JournalKind> kind;
  final Value<String?> promptId;
  final Value<String?> prompt;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.promptId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required LocalDate date,
    required JournalKind kind,
    this.promptId = const Value.absent(),
    this.prompt = const Value.absent(),
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : date = Value(date),
       kind = Value(kind),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<JournalEntryRow> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? kind,
    Expression<String>? promptId,
    Expression<String>? prompt,
    Expression<String>? body,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (promptId != null) 'prompt_id': promptId,
      if (prompt != null) 'prompt': prompt,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<LocalDate>? date,
    Value<JournalKind>? kind,
    Value<String?>? promptId,
    Value<String?>? prompt,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      promptId: promptId ?? this.promptId,
      prompt: prompt ?? this.prompt,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        $JournalEntriesTable.$converterdate.toSql(date.value),
      );
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $JournalEntriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (promptId.present) {
      map['prompt_id'] = Variable<String>(promptId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $JournalEntriesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $JournalEntriesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('promptId: $promptId, ')
          ..write('prompt: $prompt, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$JournalDb extends GeneratedDatabase {
  _$JournalDb(QueryExecutor e) : super(e);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final Index journalEntryDate = Index(
    'journal_entry_date',
    'CREATE INDEX journal_entry_date ON journal_entry (date)',
  );
  late final JournalDao journalDao = JournalDao(this as JournalDb);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    journalEntries,
    journalEntryDate,
  ];
}
