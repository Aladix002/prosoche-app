// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_db.dart';

// ignore_for_file: type=lint
class $ContentMetaTable extends ContentMeta
    with TableInfo<$ContentMetaTable, MetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentMetaTable(this.attachedDatabase, [this._alias]);
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
  MetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetaRow(
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
  $ContentMetaTable createAlias(String alias) {
    return $ContentMetaTable(attachedDatabase, alias);
  }
}

class MetaRow extends DataClass implements Insertable<MetaRow> {
  final String key;
  final String value;
  const MetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ContentMetaCompanion toCompanion(bool nullToAbsent) {
    return ContentMetaCompanion(key: Value(key), value: Value(value));
  }

  factory MetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetaRow(
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

  MetaRow copyWith({String? key, String? value}) =>
      MetaRow(key: key ?? this.key, value: value ?? this.value);
  MetaRow copyWithCompanion(ContentMetaCompanion data) {
    return MetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetaRow(')
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
      (other is MetaRow && other.key == this.key && other.value == this.value);
}

class ContentMetaCompanion extends UpdateCompanion<MetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ContentMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MetaRow> custom({
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

  ContentMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ContentMetaCompanion(
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
    return (StringBuffer('ContentMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourcesTable extends Sources with TableInfo<$SourcesTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
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
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
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
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
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
  const SourceRow({
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

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
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

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
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

  SourceRow copyWith({
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
  }) => SourceRow(
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
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
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
    return (StringBuffer('SourceRow(')
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
      (other is SourceRow &&
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

class SourcesCompanion extends UpdateCompanion<SourceRow> {
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
  const SourcesCompanion({
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
  SourcesCompanion.insert({
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
  static Insertable<SourceRow> custom({
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

  SourcesCompanion copyWith({
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
    return SourcesCompanion(
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
    return (StringBuffer('SourcesCompanion(')
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

class $QuotesTable extends Quotes with TableInfo<$QuotesTable, QuoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> work = GeneratedColumn<String>(
    'work',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('any'),
  );
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    id,
    status,
    origin,
    textContent,
    author,
    work,
    ref,
    tags,
    timeOfDay,
    weight,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quote';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      work: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $QuotesTable createAlias(String alias) {
    return $QuotesTable(attachedDatabase, alias);
  }
}

class QuoteRow extends DataClass implements Insertable<QuoteRow> {
  final String id;
  final String status;
  final String origin;
  final String textContent;
  final String author;
  final String work;
  final String? ref;
  final String tags;
  final String timeOfDay;
  final double weight;
  final String sourceId;
  const QuoteRow({
    required this.id,
    required this.status,
    required this.origin,
    required this.textContent,
    required this.author,
    required this.work,
    this.ref,
    required this.tags,
    required this.timeOfDay,
    required this.weight,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['origin'] = Variable<String>(origin);
    map['text'] = Variable<String>(textContent);
    map['author'] = Variable<String>(author);
    map['work'] = Variable<String>(work);
    if (!nullToAbsent || ref != null) {
      map['ref'] = Variable<String>(ref);
    }
    map['tags'] = Variable<String>(tags);
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['weight'] = Variable<double>(weight);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  QuotesCompanion toCompanion(bool nullToAbsent) {
    return QuotesCompanion(
      id: Value(id),
      status: Value(status),
      origin: Value(origin),
      textContent: Value(textContent),
      author: Value(author),
      work: Value(work),
      ref: ref == null && nullToAbsent ? const Value.absent() : Value(ref),
      tags: Value(tags),
      timeOfDay: Value(timeOfDay),
      weight: Value(weight),
      sourceId: Value(sourceId),
    );
  }

  factory QuoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteRow(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      origin: serializer.fromJson<String>(json['origin']),
      textContent: serializer.fromJson<String>(json['textContent']),
      author: serializer.fromJson<String>(json['author']),
      work: serializer.fromJson<String>(json['work']),
      ref: serializer.fromJson<String?>(json['ref']),
      tags: serializer.fromJson<String>(json['tags']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      weight: serializer.fromJson<double>(json['weight']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'origin': serializer.toJson<String>(origin),
      'textContent': serializer.toJson<String>(textContent),
      'author': serializer.toJson<String>(author),
      'work': serializer.toJson<String>(work),
      'ref': serializer.toJson<String?>(ref),
      'tags': serializer.toJson<String>(tags),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'weight': serializer.toJson<double>(weight),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  QuoteRow copyWith({
    String? id,
    String? status,
    String? origin,
    String? textContent,
    String? author,
    String? work,
    Value<String?> ref = const Value.absent(),
    String? tags,
    String? timeOfDay,
    double? weight,
    String? sourceId,
  }) => QuoteRow(
    id: id ?? this.id,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    textContent: textContent ?? this.textContent,
    author: author ?? this.author,
    work: work ?? this.work,
    ref: ref.present ? ref.value : this.ref,
    tags: tags ?? this.tags,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    weight: weight ?? this.weight,
    sourceId: sourceId ?? this.sourceId,
  );
  QuoteRow copyWithCompanion(QuotesCompanion data) {
    return QuoteRow(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      origin: data.origin.present ? data.origin.value : this.origin,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      author: data.author.present ? data.author.value : this.author,
      work: data.work.present ? data.work.value : this.work,
      ref: data.ref.present ? data.ref.value : this.ref,
      tags: data.tags.present ? data.tags.value : this.tags,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      weight: data.weight.present ? data.weight.value : this.weight,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteRow(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('textContent: $textContent, ')
          ..write('author: $author, ')
          ..write('work: $work, ')
          ..write('ref: $ref, ')
          ..write('tags: $tags, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('weight: $weight, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    origin,
    textContent,
    author,
    work,
    ref,
    tags,
    timeOfDay,
    weight,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteRow &&
          other.id == this.id &&
          other.status == this.status &&
          other.origin == this.origin &&
          other.textContent == this.textContent &&
          other.author == this.author &&
          other.work == this.work &&
          other.ref == this.ref &&
          other.tags == this.tags &&
          other.timeOfDay == this.timeOfDay &&
          other.weight == this.weight &&
          other.sourceId == this.sourceId);
}

class QuotesCompanion extends UpdateCompanion<QuoteRow> {
  final Value<String> id;
  final Value<String> status;
  final Value<String> origin;
  final Value<String> textContent;
  final Value<String> author;
  final Value<String> work;
  final Value<String?> ref;
  final Value<String> tags;
  final Value<String> timeOfDay;
  final Value<double> weight;
  final Value<String> sourceId;
  final Value<int> rowid;
  const QuotesCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.origin = const Value.absent(),
    this.textContent = const Value.absent(),
    this.author = const Value.absent(),
    this.work = const Value.absent(),
    this.ref = const Value.absent(),
    this.tags = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.weight = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuotesCompanion.insert({
    required String id,
    required String status,
    required String origin,
    required String textContent,
    required String author,
    required String work,
    this.ref = const Value.absent(),
    required String tags,
    this.timeOfDay = const Value.absent(),
    this.weight = const Value.absent(),
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       origin = Value(origin),
       textContent = Value(textContent),
       author = Value(author),
       work = Value(work),
       tags = Value(tags),
       sourceId = Value(sourceId);
  static Insertable<QuoteRow> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? origin,
    Expression<String>? textContent,
    Expression<String>? author,
    Expression<String>? work,
    Expression<String>? ref,
    Expression<String>? tags,
    Expression<String>? timeOfDay,
    Expression<double>? weight,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (origin != null) 'origin': origin,
      if (textContent != null) 'text': textContent,
      if (author != null) 'author': author,
      if (work != null) 'work': work,
      if (ref != null) 'ref': ref,
      if (tags != null) 'tags': tags,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (weight != null) 'weight': weight,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuotesCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<String>? origin,
    Value<String>? textContent,
    Value<String>? author,
    Value<String>? work,
    Value<String?>? ref,
    Value<String>? tags,
    Value<String>? timeOfDay,
    Value<double>? weight,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return QuotesCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      textContent: textContent ?? this.textContent,
      author: author ?? this.author,
      work: work ?? this.work,
      ref: ref ?? this.ref,
      tags: tags ?? this.tags,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      weight: weight ?? this.weight,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (work.present) {
      map['work'] = Variable<String>(work.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
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
    return (StringBuffer('QuotesCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('textContent: $textContent, ')
          ..write('author: $author, ')
          ..write('work: $work, ')
          ..write('ref: $ref, ')
          ..write('tags: $tags, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('weight: $weight, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestTemplatesTable extends QuestTemplates
    with TableInfo<$QuestTemplatesTable, QuestTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestTemplatesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> ruleJson = GeneratedColumn<String>(
    'rule_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> facetsJson = GeneratedColumn<String>(
    'facets_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumn<int> cooldownDays = GeneratedColumn<int>(
    'cooldown_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(21),
  );
  @override
  late final GeneratedColumn<String> reviewedBy = GeneratedColumn<String>(
    'reviewed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> reviewedAt = GeneratedColumn<String>(
    'reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    status,
    origin,
    slot,
    ruleJson,
    tags,
    facetsJson,
    weight,
    cooldownDays,
    reviewedBy,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_template';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      ruleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_json'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      facetsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facets_json'],
      ),
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight'],
      )!,
      cooldownDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cooldown_days'],
      )!,
      reviewedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_at'],
      ),
    );
  }

  @override
  $QuestTemplatesTable createAlias(String alias) {
    return $QuestTemplatesTable(attachedDatabase, alias);
  }
}

class QuestTemplateRow extends DataClass
    implements Insertable<QuestTemplateRow> {
  final String id;
  final int version;
  final String status;
  final String origin;
  final String slot;
  final String ruleJson;
  final String tags;
  final String? facetsJson;
  final double weight;
  final int cooldownDays;
  final String? reviewedBy;
  final String? reviewedAt;
  const QuestTemplateRow({
    required this.id,
    required this.version,
    required this.status,
    required this.origin,
    required this.slot,
    required this.ruleJson,
    required this.tags,
    this.facetsJson,
    required this.weight,
    required this.cooldownDays,
    this.reviewedBy,
    this.reviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version'] = Variable<int>(version);
    map['status'] = Variable<String>(status);
    map['origin'] = Variable<String>(origin);
    map['slot'] = Variable<String>(slot);
    map['rule_json'] = Variable<String>(ruleJson);
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || facetsJson != null) {
      map['facets_json'] = Variable<String>(facetsJson);
    }
    map['weight'] = Variable<double>(weight);
    map['cooldown_days'] = Variable<int>(cooldownDays);
    if (!nullToAbsent || reviewedBy != null) {
      map['reviewed_by'] = Variable<String>(reviewedBy);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<String>(reviewedAt);
    }
    return map;
  }

  QuestTemplatesCompanion toCompanion(bool nullToAbsent) {
    return QuestTemplatesCompanion(
      id: Value(id),
      version: Value(version),
      status: Value(status),
      origin: Value(origin),
      slot: Value(slot),
      ruleJson: Value(ruleJson),
      tags: Value(tags),
      facetsJson: facetsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(facetsJson),
      weight: Value(weight),
      cooldownDays: Value(cooldownDays),
      reviewedBy: reviewedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedBy),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
    );
  }

  factory QuestTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      origin: serializer.fromJson<String>(json['origin']),
      slot: serializer.fromJson<String>(json['slot']),
      ruleJson: serializer.fromJson<String>(json['ruleJson']),
      tags: serializer.fromJson<String>(json['tags']),
      facetsJson: serializer.fromJson<String?>(json['facetsJson']),
      weight: serializer.fromJson<double>(json['weight']),
      cooldownDays: serializer.fromJson<int>(json['cooldownDays']),
      reviewedBy: serializer.fromJson<String?>(json['reviewedBy']),
      reviewedAt: serializer.fromJson<String?>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<int>(version),
      'status': serializer.toJson<String>(status),
      'origin': serializer.toJson<String>(origin),
      'slot': serializer.toJson<String>(slot),
      'ruleJson': serializer.toJson<String>(ruleJson),
      'tags': serializer.toJson<String>(tags),
      'facetsJson': serializer.toJson<String?>(facetsJson),
      'weight': serializer.toJson<double>(weight),
      'cooldownDays': serializer.toJson<int>(cooldownDays),
      'reviewedBy': serializer.toJson<String?>(reviewedBy),
      'reviewedAt': serializer.toJson<String?>(reviewedAt),
    };
  }

  QuestTemplateRow copyWith({
    String? id,
    int? version,
    String? status,
    String? origin,
    String? slot,
    String? ruleJson,
    String? tags,
    Value<String?> facetsJson = const Value.absent(),
    double? weight,
    int? cooldownDays,
    Value<String?> reviewedBy = const Value.absent(),
    Value<String?> reviewedAt = const Value.absent(),
  }) => QuestTemplateRow(
    id: id ?? this.id,
    version: version ?? this.version,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    slot: slot ?? this.slot,
    ruleJson: ruleJson ?? this.ruleJson,
    tags: tags ?? this.tags,
    facetsJson: facetsJson.present ? facetsJson.value : this.facetsJson,
    weight: weight ?? this.weight,
    cooldownDays: cooldownDays ?? this.cooldownDays,
    reviewedBy: reviewedBy.present ? reviewedBy.value : this.reviewedBy,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
  );
  QuestTemplateRow copyWithCompanion(QuestTemplatesCompanion data) {
    return QuestTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      origin: data.origin.present ? data.origin.value : this.origin,
      slot: data.slot.present ? data.slot.value : this.slot,
      ruleJson: data.ruleJson.present ? data.ruleJson.value : this.ruleJson,
      tags: data.tags.present ? data.tags.value : this.tags,
      facetsJson: data.facetsJson.present
          ? data.facetsJson.value
          : this.facetsJson,
      weight: data.weight.present ? data.weight.value : this.weight,
      cooldownDays: data.cooldownDays.present
          ? data.cooldownDays.value
          : this.cooldownDays,
      reviewedBy: data.reviewedBy.present
          ? data.reviewedBy.value
          : this.reviewedBy,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestTemplateRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('slot: $slot, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('tags: $tags, ')
          ..write('facetsJson: $facetsJson, ')
          ..write('weight: $weight, ')
          ..write('cooldownDays: $cooldownDays, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    version,
    status,
    origin,
    slot,
    ruleJson,
    tags,
    facetsJson,
    weight,
    cooldownDays,
    reviewedBy,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestTemplateRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.status == this.status &&
          other.origin == this.origin &&
          other.slot == this.slot &&
          other.ruleJson == this.ruleJson &&
          other.tags == this.tags &&
          other.facetsJson == this.facetsJson &&
          other.weight == this.weight &&
          other.cooldownDays == this.cooldownDays &&
          other.reviewedBy == this.reviewedBy &&
          other.reviewedAt == this.reviewedAt);
}

class QuestTemplatesCompanion extends UpdateCompanion<QuestTemplateRow> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> status;
  final Value<String> origin;
  final Value<String> slot;
  final Value<String> ruleJson;
  final Value<String> tags;
  final Value<String?> facetsJson;
  final Value<double> weight;
  final Value<int> cooldownDays;
  final Value<String?> reviewedBy;
  final Value<String?> reviewedAt;
  final Value<int> rowid;
  const QuestTemplatesCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.origin = const Value.absent(),
    this.slot = const Value.absent(),
    this.ruleJson = const Value.absent(),
    this.tags = const Value.absent(),
    this.facetsJson = const Value.absent(),
    this.weight = const Value.absent(),
    this.cooldownDays = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestTemplatesCompanion.insert({
    required String id,
    this.version = const Value.absent(),
    required String status,
    required String origin,
    required String slot,
    required String ruleJson,
    required String tags,
    this.facetsJson = const Value.absent(),
    this.weight = const Value.absent(),
    this.cooldownDays = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       origin = Value(origin),
       slot = Value(slot),
       ruleJson = Value(ruleJson),
       tags = Value(tags);
  static Insertable<QuestTemplateRow> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? status,
    Expression<String>? origin,
    Expression<String>? slot,
    Expression<String>? ruleJson,
    Expression<String>? tags,
    Expression<String>? facetsJson,
    Expression<double>? weight,
    Expression<int>? cooldownDays,
    Expression<String>? reviewedBy,
    Expression<String>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (origin != null) 'origin': origin,
      if (slot != null) 'slot': slot,
      if (ruleJson != null) 'rule_json': ruleJson,
      if (tags != null) 'tags': tags,
      if (facetsJson != null) 'facets_json': facetsJson,
      if (weight != null) 'weight': weight,
      if (cooldownDays != null) 'cooldown_days': cooldownDays,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestTemplatesCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? status,
    Value<String>? origin,
    Value<String>? slot,
    Value<String>? ruleJson,
    Value<String>? tags,
    Value<String?>? facetsJson,
    Value<double>? weight,
    Value<int>? cooldownDays,
    Value<String?>? reviewedBy,
    Value<String?>? reviewedAt,
    Value<int>? rowid,
  }) {
    return QuestTemplatesCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      slot: slot ?? this.slot,
      ruleJson: ruleJson ?? this.ruleJson,
      tags: tags ?? this.tags,
      facetsJson: facetsJson ?? this.facetsJson,
      weight: weight ?? this.weight,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (ruleJson.present) {
      map['rule_json'] = Variable<String>(ruleJson.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (facetsJson.present) {
      map['facets_json'] = Variable<String>(facetsJson.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (cooldownDays.present) {
      map['cooldown_days'] = Variable<int>(cooldownDays.value);
    }
    if (reviewedBy.present) {
      map['reviewed_by'] = Variable<String>(reviewedBy.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<String>(reviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('slot: $slot, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('tags: $tags, ')
          ..write('facetsJson: $facetsJson, ')
          ..write('weight: $weight, ')
          ..write('cooldownDays: $cooldownDays, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestTextsTable extends QuestTexts
    with TableInfo<$QuestTextsTable, QuestTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> questId = GeneratedColumn<String>(
    'quest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quest_template (id)',
    ),
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
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
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
  List<GeneratedColumn> get $columns => [questId, lang, title, body, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quest_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {questId, lang};
  @override
  QuestTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestTextRow(
      questId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $QuestTextsTable createAlias(String alias) {
    return $QuestTextsTable(attachedDatabase, alias);
  }
}

class QuestTextRow extends DataClass implements Insertable<QuestTextRow> {
  final String questId;
  final String lang;
  final String title;
  final String? body;
  final String sourceId;
  const QuestTextRow({
    required this.questId,
    required this.lang,
    required this.title,
    this.body,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['quest_id'] = Variable<String>(questId);
    map['lang'] = Variable<String>(lang);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  QuestTextsCompanion toCompanion(bool nullToAbsent) {
    return QuestTextsCompanion(
      questId: Value(questId),
      lang: Value(lang),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      sourceId: Value(sourceId),
    );
  }

  factory QuestTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestTextRow(
      questId: serializer.fromJson<String>(json['questId']),
      lang: serializer.fromJson<String>(json['lang']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questId': serializer.toJson<String>(questId),
      'lang': serializer.toJson<String>(lang),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  QuestTextRow copyWith({
    String? questId,
    String? lang,
    String? title,
    Value<String?> body = const Value.absent(),
    String? sourceId,
  }) => QuestTextRow(
    questId: questId ?? this.questId,
    lang: lang ?? this.lang,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    sourceId: sourceId ?? this.sourceId,
  );
  QuestTextRow copyWithCompanion(QuestTextsCompanion data) {
    return QuestTextRow(
      questId: data.questId.present ? data.questId.value : this.questId,
      lang: data.lang.present ? data.lang.value : this.lang,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestTextRow(')
          ..write('questId: $questId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(questId, lang, title, body, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestTextRow &&
          other.questId == this.questId &&
          other.lang == this.lang &&
          other.title == this.title &&
          other.body == this.body &&
          other.sourceId == this.sourceId);
}

class QuestTextsCompanion extends UpdateCompanion<QuestTextRow> {
  final Value<String> questId;
  final Value<String> lang;
  final Value<String> title;
  final Value<String?> body;
  final Value<String> sourceId;
  final Value<int> rowid;
  const QuestTextsCompanion({
    this.questId = const Value.absent(),
    this.lang = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestTextsCompanion.insert({
    required String questId,
    required String lang,
    required String title,
    this.body = const Value.absent(),
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : questId = Value(questId),
       lang = Value(lang),
       title = Value(title),
       sourceId = Value(sourceId);
  static Insertable<QuestTextRow> custom({
    Expression<String>? questId,
    Expression<String>? lang,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questId != null) 'quest_id': questId,
      if (lang != null) 'lang': lang,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestTextsCompanion copyWith({
    Value<String>? questId,
    Value<String>? lang,
    Value<String>? title,
    Value<String?>? body,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return QuestTextsCompanion(
      questId: questId ?? this.questId,
      lang: lang ?? this.lang,
      title: title ?? this.title,
      body: body ?? this.body,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questId.present) {
      map['quest_id'] = Variable<String>(questId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
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
    return (StringBuffer('QuestTextsCompanion(')
          ..write('questId: $questId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDb extends GeneratedDatabase {
  _$ContentDb(QueryExecutor e) : super(e);
  late final $ContentMetaTable contentMeta = $ContentMetaTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $QuotesTable quotes = $QuotesTable(this);
  late final $QuestTemplatesTable questTemplates = $QuestTemplatesTable(this);
  late final $QuestTextsTable questTexts = $QuestTextsTable(this);
  late final ContentMetaDao contentMetaDao = ContentMetaDao(this as ContentDb);
  late final CuratedDao curatedDao = CuratedDao(this as ContentDb);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contentMeta,
    sources,
    quotes,
    questTemplates,
    questTexts,
  ];
}
