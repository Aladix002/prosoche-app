// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hadith_extra_db.dart';

// ignore_for_file: type=lint
class $ExtraMetaTable extends ExtraMeta
    with TableInfo<$ExtraMetaTable, ExtraMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtraMetaTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const String $name = 'meta';
  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ExtraMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtraMetaRow(
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
  $ExtraMetaTable createAlias(String alias) {
    return $ExtraMetaTable(attachedDatabase, alias);
  }
}

class ExtraMetaRow extends DataClass implements Insertable<ExtraMetaRow> {
  final String key;
  final String value;
  const ExtraMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ExtraMetaCompanion toCompanion(bool nullToAbsent) {
    return ExtraMetaCompanion(key: Value(key), value: Value(value));
  }

  factory ExtraMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtraMetaRow(
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

  ExtraMetaRow copyWith({String? key, String? value}) =>
      ExtraMetaRow(key: key ?? this.key, value: value ?? this.value);
  ExtraMetaRow copyWithCompanion(ExtraMetaCompanion data) {
    return ExtraMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtraMetaRow(')
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
      (other is ExtraMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class ExtraMetaCompanion extends UpdateCompanion<ExtraMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ExtraMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtraMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<ExtraMetaRow> custom({
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

  ExtraMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ExtraMetaCompanion(
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
    return (StringBuffer('ExtraMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtraSourcesTable extends ExtraSources
    with TableInfo<$ExtraSourcesTable, ExtraSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtraSourcesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
    'license',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> licenseUrl = GeneratedColumn<String>(
    'license_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> licenseText = GeneratedColumn<String>(
    'license_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> commercialStatus = GeneratedColumn<String>(
    'commercial_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    lang,
    name,
    version,
    license,
    licenseUrl,
    licenseText,
    attribution,
    url,
    commercialStatus,
    sha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtraSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtraSourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      license: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license'],
      )!,
      licenseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_url'],
      ),
      licenseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_text'],
      )!,
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      commercialStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commercial_status'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
    );
  }

  @override
  $ExtraSourcesTable createAlias(String alias) {
    return $ExtraSourcesTable(attachedDatabase, alias);
  }
}

class ExtraSourceRow extends DataClass implements Insertable<ExtraSourceRow> {
  final String id;
  final String kind;
  final String? lang;
  final String name;
  final String version;
  final String license;
  final String? licenseUrl;
  final String licenseText;
  final String attribution;
  final String url;
  final String commercialStatus;
  final String? sha256;
  const ExtraSourceRow({
    required this.id,
    required this.kind,
    this.lang,
    required this.name,
    required this.version,
    required this.license,
    this.licenseUrl,
    required this.licenseText,
    required this.attribution,
    required this.url,
    required this.commercialStatus,
    this.sha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || lang != null) {
      map['lang'] = Variable<String>(lang);
    }
    map['name'] = Variable<String>(name);
    map['version'] = Variable<String>(version);
    map['license'] = Variable<String>(license);
    if (!nullToAbsent || licenseUrl != null) {
      map['license_url'] = Variable<String>(licenseUrl);
    }
    map['license_text'] = Variable<String>(licenseText);
    map['attribution'] = Variable<String>(attribution);
    map['url'] = Variable<String>(url);
    map['commercial_status'] = Variable<String>(commercialStatus);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    return map;
  }

  ExtraSourcesCompanion toCompanion(bool nullToAbsent) {
    return ExtraSourcesCompanion(
      id: Value(id),
      kind: Value(kind),
      lang: lang == null && nullToAbsent ? const Value.absent() : Value(lang),
      name: Value(name),
      version: Value(version),
      license: Value(license),
      licenseUrl: licenseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseUrl),
      licenseText: Value(licenseText),
      attribution: Value(attribution),
      url: Value(url),
      commercialStatus: Value(commercialStatus),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
    );
  }

  factory ExtraSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtraSourceRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      lang: serializer.fromJson<String?>(json['lang']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<String>(json['version']),
      license: serializer.fromJson<String>(json['license']),
      licenseUrl: serializer.fromJson<String?>(json['licenseUrl']),
      licenseText: serializer.fromJson<String>(json['licenseText']),
      attribution: serializer.fromJson<String>(json['attribution']),
      url: serializer.fromJson<String>(json['url']),
      commercialStatus: serializer.fromJson<String>(json['commercialStatus']),
      sha256: serializer.fromJson<String?>(json['sha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'lang': serializer.toJson<String?>(lang),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<String>(version),
      'license': serializer.toJson<String>(license),
      'licenseUrl': serializer.toJson<String?>(licenseUrl),
      'licenseText': serializer.toJson<String>(licenseText),
      'attribution': serializer.toJson<String>(attribution),
      'url': serializer.toJson<String>(url),
      'commercialStatus': serializer.toJson<String>(commercialStatus),
      'sha256': serializer.toJson<String?>(sha256),
    };
  }

  ExtraSourceRow copyWith({
    String? id,
    String? kind,
    Value<String?> lang = const Value.absent(),
    String? name,
    String? version,
    String? license,
    Value<String?> licenseUrl = const Value.absent(),
    String? licenseText,
    String? attribution,
    String? url,
    String? commercialStatus,
    Value<String?> sha256 = const Value.absent(),
  }) => ExtraSourceRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    lang: lang.present ? lang.value : this.lang,
    name: name ?? this.name,
    version: version ?? this.version,
    license: license ?? this.license,
    licenseUrl: licenseUrl.present ? licenseUrl.value : this.licenseUrl,
    licenseText: licenseText ?? this.licenseText,
    attribution: attribution ?? this.attribution,
    url: url ?? this.url,
    commercialStatus: commercialStatus ?? this.commercialStatus,
    sha256: sha256.present ? sha256.value : this.sha256,
  );
  ExtraSourceRow copyWithCompanion(ExtraSourcesCompanion data) {
    return ExtraSourceRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      lang: data.lang.present ? data.lang.value : this.lang,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      license: data.license.present ? data.license.value : this.license,
      licenseUrl: data.licenseUrl.present
          ? data.licenseUrl.value
          : this.licenseUrl,
      licenseText: data.licenseText.present
          ? data.licenseText.value
          : this.licenseText,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      url: data.url.present ? data.url.value : this.url,
      commercialStatus: data.commercialStatus.present
          ? data.commercialStatus.value
          : this.commercialStatus,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtraSourceRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('lang: $lang, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('license: $license, ')
          ..write('licenseUrl: $licenseUrl, ')
          ..write('licenseText: $licenseText, ')
          ..write('attribution: $attribution, ')
          ..write('url: $url, ')
          ..write('commercialStatus: $commercialStatus, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    lang,
    name,
    version,
    license,
    licenseUrl,
    licenseText,
    attribution,
    url,
    commercialStatus,
    sha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtraSourceRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.lang == this.lang &&
          other.name == this.name &&
          other.version == this.version &&
          other.license == this.license &&
          other.licenseUrl == this.licenseUrl &&
          other.licenseText == this.licenseText &&
          other.attribution == this.attribution &&
          other.url == this.url &&
          other.commercialStatus == this.commercialStatus &&
          other.sha256 == this.sha256);
}

class ExtraSourcesCompanion extends UpdateCompanion<ExtraSourceRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> lang;
  final Value<String> name;
  final Value<String> version;
  final Value<String> license;
  final Value<String?> licenseUrl;
  final Value<String> licenseText;
  final Value<String> attribution;
  final Value<String> url;
  final Value<String> commercialStatus;
  final Value<String?> sha256;
  final Value<int> rowid;
  const ExtraSourcesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.lang = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.license = const Value.absent(),
    this.licenseUrl = const Value.absent(),
    this.licenseText = const Value.absent(),
    this.attribution = const Value.absent(),
    this.url = const Value.absent(),
    this.commercialStatus = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtraSourcesCompanion.insert({
    required String id,
    required String kind,
    this.lang = const Value.absent(),
    required String name,
    required String version,
    required String license,
    this.licenseUrl = const Value.absent(),
    required String licenseText,
    required String attribution,
    required String url,
    required String commercialStatus,
    this.sha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name),
       version = Value(version),
       license = Value(license),
       licenseText = Value(licenseText),
       attribution = Value(attribution),
       url = Value(url),
       commercialStatus = Value(commercialStatus);
  static Insertable<ExtraSourceRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? lang,
    Expression<String>? name,
    Expression<String>? version,
    Expression<String>? license,
    Expression<String>? licenseUrl,
    Expression<String>? licenseText,
    Expression<String>? attribution,
    Expression<String>? url,
    Expression<String>? commercialStatus,
    Expression<String>? sha256,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (lang != null) 'lang': lang,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (license != null) 'license': license,
      if (licenseUrl != null) 'license_url': licenseUrl,
      if (licenseText != null) 'license_text': licenseText,
      if (attribution != null) 'attribution': attribution,
      if (url != null) 'url': url,
      if (commercialStatus != null) 'commercial_status': commercialStatus,
      if (sha256 != null) 'sha256': sha256,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtraSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? lang,
    Value<String>? name,
    Value<String>? version,
    Value<String>? license,
    Value<String?>? licenseUrl,
    Value<String>? licenseText,
    Value<String>? attribution,
    Value<String>? url,
    Value<String>? commercialStatus,
    Value<String?>? sha256,
    Value<int>? rowid,
  }) {
    return ExtraSourcesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      lang: lang ?? this.lang,
      name: name ?? this.name,
      version: version ?? this.version,
      license: license ?? this.license,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      licenseText: licenseText ?? this.licenseText,
      attribution: attribution ?? this.attribution,
      url: url ?? this.url,
      commercialStatus: commercialStatus ?? this.commercialStatus,
      sha256: sha256 ?? this.sha256,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (licenseUrl.present) {
      map['license_url'] = Variable<String>(licenseUrl.value);
    }
    if (licenseText.present) {
      map['license_text'] = Variable<String>(licenseText.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (commercialStatus.present) {
      map['commercial_status'] = Variable<String>(commercialStatus.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtraSourcesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('lang: $lang, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('license: $license, ')
          ..write('licenseUrl: $licenseUrl, ')
          ..write('licenseText: $licenseText, ')
          ..write('attribution: $attribution, ')
          ..write('url: $url, ')
          ..write('commercialStatus: $commercialStatus, ')
          ..write('sha256: $sha256, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HadithExplanationsTable extends HadithExplanations
    with TableInfo<$HadithExplanationsTable, HadithExplanationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HadithExplanationsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> hadithId = GeneratedColumn<int>(
    'hadith_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> hints = GeneratedColumn<String>(
    'hints',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES source (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    hadithId,
    lang,
    explanation,
    hints,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadith_explanation';
  @override
  Set<GeneratedColumn> get $primaryKey => {hadithId, lang};
  @override
  HadithExplanationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HadithExplanationRow(
      hadithId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hadith_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      hints: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hints'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $HadithExplanationsTable createAlias(String alias) {
    return $HadithExplanationsTable(attachedDatabase, alias);
  }
}

class HadithExplanationRow extends DataClass
    implements Insertable<HadithExplanationRow> {
  final int hadithId;
  final String lang;
  final String? explanation;

  /// JSON pole retazcov zo zdroja.
  final String? hints;
  final String sourceId;
  const HadithExplanationRow({
    required this.hadithId,
    required this.lang,
    this.explanation,
    this.hints,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hadith_id'] = Variable<int>(hadithId);
    map['lang'] = Variable<String>(lang);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || hints != null) {
      map['hints'] = Variable<String>(hints);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  HadithExplanationsCompanion toCompanion(bool nullToAbsent) {
    return HadithExplanationsCompanion(
      hadithId: Value(hadithId),
      lang: Value(lang),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      hints: hints == null && nullToAbsent
          ? const Value.absent()
          : Value(hints),
      sourceId: Value(sourceId),
    );
  }

  factory HadithExplanationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HadithExplanationRow(
      hadithId: serializer.fromJson<int>(json['hadithId']),
      lang: serializer.fromJson<String>(json['lang']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      hints: serializer.fromJson<String?>(json['hints']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hadithId': serializer.toJson<int>(hadithId),
      'lang': serializer.toJson<String>(lang),
      'explanation': serializer.toJson<String?>(explanation),
      'hints': serializer.toJson<String?>(hints),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  HadithExplanationRow copyWith({
    int? hadithId,
    String? lang,
    Value<String?> explanation = const Value.absent(),
    Value<String?> hints = const Value.absent(),
    String? sourceId,
  }) => HadithExplanationRow(
    hadithId: hadithId ?? this.hadithId,
    lang: lang ?? this.lang,
    explanation: explanation.present ? explanation.value : this.explanation,
    hints: hints.present ? hints.value : this.hints,
    sourceId: sourceId ?? this.sourceId,
  );
  HadithExplanationRow copyWithCompanion(HadithExplanationsCompanion data) {
    return HadithExplanationRow(
      hadithId: data.hadithId.present ? data.hadithId.value : this.hadithId,
      lang: data.lang.present ? data.lang.value : this.lang,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      hints: data.hints.present ? data.hints.value : this.hints,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HadithExplanationRow(')
          ..write('hadithId: $hadithId, ')
          ..write('lang: $lang, ')
          ..write('explanation: $explanation, ')
          ..write('hints: $hints, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(hadithId, lang, explanation, hints, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HadithExplanationRow &&
          other.hadithId == this.hadithId &&
          other.lang == this.lang &&
          other.explanation == this.explanation &&
          other.hints == this.hints &&
          other.sourceId == this.sourceId);
}

class HadithExplanationsCompanion
    extends UpdateCompanion<HadithExplanationRow> {
  final Value<int> hadithId;
  final Value<String> lang;
  final Value<String?> explanation;
  final Value<String?> hints;
  final Value<String> sourceId;
  final Value<int> rowid;
  const HadithExplanationsCompanion({
    this.hadithId = const Value.absent(),
    this.lang = const Value.absent(),
    this.explanation = const Value.absent(),
    this.hints = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HadithExplanationsCompanion.insert({
    required int hadithId,
    required String lang,
    this.explanation = const Value.absent(),
    this.hints = const Value.absent(),
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : hadithId = Value(hadithId),
       lang = Value(lang),
       sourceId = Value(sourceId);
  static Insertable<HadithExplanationRow> custom({
    Expression<int>? hadithId,
    Expression<String>? lang,
    Expression<String>? explanation,
    Expression<String>? hints,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hadithId != null) 'hadith_id': hadithId,
      if (lang != null) 'lang': lang,
      if (explanation != null) 'explanation': explanation,
      if (hints != null) 'hints': hints,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HadithExplanationsCompanion copyWith({
    Value<int>? hadithId,
    Value<String>? lang,
    Value<String?>? explanation,
    Value<String?>? hints,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return HadithExplanationsCompanion(
      hadithId: hadithId ?? this.hadithId,
      lang: lang ?? this.lang,
      explanation: explanation ?? this.explanation,
      hints: hints ?? this.hints,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hadithId.present) {
      map['hadith_id'] = Variable<int>(hadithId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (hints.present) {
      map['hints'] = Variable<String>(hints.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HadithExplanationsCompanion(')
          ..write('hadithId: $hadithId, ')
          ..write('lang: $lang, ')
          ..write('explanation: $explanation, ')
          ..write('hints: $hints, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$HadithExtraDb extends GeneratedDatabase {
  _$HadithExtraDb(QueryExecutor e) : super(e);
  late final $ExtraMetaTable extraMeta = $ExtraMetaTable(this);
  late final $ExtraSourcesTable extraSources = $ExtraSourcesTable(this);
  late final $HadithExplanationsTable hadithExplanations =
      $HadithExplanationsTable(this);
  late final HadithExtraDao hadithExtraDao = HadithExtraDao(
    this as HadithExtraDb,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    extraMeta,
    extraSources,
    hadithExplanations,
  ];
}
