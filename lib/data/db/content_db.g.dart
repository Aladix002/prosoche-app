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

class $SurahsTable extends Surahs with TableInfo<$SurahsTable, SurahRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> nameAr = GeneratedColumn<String>(
    'name_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> nameTranslit = GeneratedColumn<String>(
    'name_translit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> revelationPlace = GeneratedColumn<String>(
    'revelation_place',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> revelationOrder = GeneratedColumn<int>(
    'revelation_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> ayahCount = GeneratedColumn<int>(
    'ayah_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<bool> bismillahPre = GeneratedColumn<bool>(
    'bismillah_pre',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bismillah_pre" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumn<String> bismillahUthmani = GeneratedColumn<String>(
    'bismillah_uthmani',
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
    id,
    nameAr,
    nameTranslit,
    revelationPlace,
    revelationOrder,
    ayahCount,
    bismillahPre,
    bismillahUthmani,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surah';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurahRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurahRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nameAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_ar'],
      )!,
      nameTranslit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_translit'],
      )!,
      revelationPlace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revelation_place'],
      )!,
      revelationOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revelation_order'],
      )!,
      ayahCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_count'],
      )!,
      bismillahPre: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bismillah_pre'],
      )!,
      bismillahUthmani: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bismillah_uthmani'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $SurahsTable createAlias(String alias) {
    return $SurahsTable(attachedDatabase, alias);
  }
}

class SurahRow extends DataClass implements Insertable<SurahRow> {
  final int id;
  final String nameAr;
  final String nameTranslit;
  final String revelationPlace;
  final int revelationOrder;
  final int ayahCount;
  final bool bismillahPre;
  final String? bismillahUthmani;
  final String sourceId;
  const SurahRow({
    required this.id,
    required this.nameAr,
    required this.nameTranslit,
    required this.revelationPlace,
    required this.revelationOrder,
    required this.ayahCount,
    required this.bismillahPre,
    this.bismillahUthmani,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name_ar'] = Variable<String>(nameAr);
    map['name_translit'] = Variable<String>(nameTranslit);
    map['revelation_place'] = Variable<String>(revelationPlace);
    map['revelation_order'] = Variable<int>(revelationOrder);
    map['ayah_count'] = Variable<int>(ayahCount);
    map['bismillah_pre'] = Variable<bool>(bismillahPre);
    if (!nullToAbsent || bismillahUthmani != null) {
      map['bismillah_uthmani'] = Variable<String>(bismillahUthmani);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      id: Value(id),
      nameAr: Value(nameAr),
      nameTranslit: Value(nameTranslit),
      revelationPlace: Value(revelationPlace),
      revelationOrder: Value(revelationOrder),
      ayahCount: Value(ayahCount),
      bismillahPre: Value(bismillahPre),
      bismillahUthmani: bismillahUthmani == null && nullToAbsent
          ? const Value.absent()
          : Value(bismillahUthmani),
      sourceId: Value(sourceId),
    );
  }

  factory SurahRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurahRow(
      id: serializer.fromJson<int>(json['id']),
      nameAr: serializer.fromJson<String>(json['nameAr']),
      nameTranslit: serializer.fromJson<String>(json['nameTranslit']),
      revelationPlace: serializer.fromJson<String>(json['revelationPlace']),
      revelationOrder: serializer.fromJson<int>(json['revelationOrder']),
      ayahCount: serializer.fromJson<int>(json['ayahCount']),
      bismillahPre: serializer.fromJson<bool>(json['bismillahPre']),
      bismillahUthmani: serializer.fromJson<String?>(json['bismillahUthmani']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nameAr': serializer.toJson<String>(nameAr),
      'nameTranslit': serializer.toJson<String>(nameTranslit),
      'revelationPlace': serializer.toJson<String>(revelationPlace),
      'revelationOrder': serializer.toJson<int>(revelationOrder),
      'ayahCount': serializer.toJson<int>(ayahCount),
      'bismillahPre': serializer.toJson<bool>(bismillahPre),
      'bismillahUthmani': serializer.toJson<String?>(bismillahUthmani),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  SurahRow copyWith({
    int? id,
    String? nameAr,
    String? nameTranslit,
    String? revelationPlace,
    int? revelationOrder,
    int? ayahCount,
    bool? bismillahPre,
    Value<String?> bismillahUthmani = const Value.absent(),
    String? sourceId,
  }) => SurahRow(
    id: id ?? this.id,
    nameAr: nameAr ?? this.nameAr,
    nameTranslit: nameTranslit ?? this.nameTranslit,
    revelationPlace: revelationPlace ?? this.revelationPlace,
    revelationOrder: revelationOrder ?? this.revelationOrder,
    ayahCount: ayahCount ?? this.ayahCount,
    bismillahPre: bismillahPre ?? this.bismillahPre,
    bismillahUthmani: bismillahUthmani.present
        ? bismillahUthmani.value
        : this.bismillahUthmani,
    sourceId: sourceId ?? this.sourceId,
  );
  SurahRow copyWithCompanion(SurahsCompanion data) {
    return SurahRow(
      id: data.id.present ? data.id.value : this.id,
      nameAr: data.nameAr.present ? data.nameAr.value : this.nameAr,
      nameTranslit: data.nameTranslit.present
          ? data.nameTranslit.value
          : this.nameTranslit,
      revelationPlace: data.revelationPlace.present
          ? data.revelationPlace.value
          : this.revelationPlace,
      revelationOrder: data.revelationOrder.present
          ? data.revelationOrder.value
          : this.revelationOrder,
      ayahCount: data.ayahCount.present ? data.ayahCount.value : this.ayahCount,
      bismillahPre: data.bismillahPre.present
          ? data.bismillahPre.value
          : this.bismillahPre,
      bismillahUthmani: data.bismillahUthmani.present
          ? data.bismillahUthmani.value
          : this.bismillahUthmani,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurahRow(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameTranslit: $nameTranslit, ')
          ..write('revelationPlace: $revelationPlace, ')
          ..write('revelationOrder: $revelationOrder, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('bismillahPre: $bismillahPre, ')
          ..write('bismillahUthmani: $bismillahUthmani, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nameAr,
    nameTranslit,
    revelationPlace,
    revelationOrder,
    ayahCount,
    bismillahPre,
    bismillahUthmani,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurahRow &&
          other.id == this.id &&
          other.nameAr == this.nameAr &&
          other.nameTranslit == this.nameTranslit &&
          other.revelationPlace == this.revelationPlace &&
          other.revelationOrder == this.revelationOrder &&
          other.ayahCount == this.ayahCount &&
          other.bismillahPre == this.bismillahPre &&
          other.bismillahUthmani == this.bismillahUthmani &&
          other.sourceId == this.sourceId);
}

class SurahsCompanion extends UpdateCompanion<SurahRow> {
  final Value<int> id;
  final Value<String> nameAr;
  final Value<String> nameTranslit;
  final Value<String> revelationPlace;
  final Value<int> revelationOrder;
  final Value<int> ayahCount;
  final Value<bool> bismillahPre;
  final Value<String?> bismillahUthmani;
  final Value<String> sourceId;
  const SurahsCompanion({
    this.id = const Value.absent(),
    this.nameAr = const Value.absent(),
    this.nameTranslit = const Value.absent(),
    this.revelationPlace = const Value.absent(),
    this.revelationOrder = const Value.absent(),
    this.ayahCount = const Value.absent(),
    this.bismillahPre = const Value.absent(),
    this.bismillahUthmani = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.id = const Value.absent(),
    required String nameAr,
    required String nameTranslit,
    required String revelationPlace,
    required int revelationOrder,
    required int ayahCount,
    required bool bismillahPre,
    this.bismillahUthmani = const Value.absent(),
    required String sourceId,
  }) : nameAr = Value(nameAr),
       nameTranslit = Value(nameTranslit),
       revelationPlace = Value(revelationPlace),
       revelationOrder = Value(revelationOrder),
       ayahCount = Value(ayahCount),
       bismillahPre = Value(bismillahPre),
       sourceId = Value(sourceId);
  static Insertable<SurahRow> custom({
    Expression<int>? id,
    Expression<String>? nameAr,
    Expression<String>? nameTranslit,
    Expression<String>? revelationPlace,
    Expression<int>? revelationOrder,
    Expression<int>? ayahCount,
    Expression<bool>? bismillahPre,
    Expression<String>? bismillahUthmani,
    Expression<String>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameAr != null) 'name_ar': nameAr,
      if (nameTranslit != null) 'name_translit': nameTranslit,
      if (revelationPlace != null) 'revelation_place': revelationPlace,
      if (revelationOrder != null) 'revelation_order': revelationOrder,
      if (ayahCount != null) 'ayah_count': ayahCount,
      if (bismillahPre != null) 'bismillah_pre': bismillahPre,
      if (bismillahUthmani != null) 'bismillah_uthmani': bismillahUthmani,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  SurahsCompanion copyWith({
    Value<int>? id,
    Value<String>? nameAr,
    Value<String>? nameTranslit,
    Value<String>? revelationPlace,
    Value<int>? revelationOrder,
    Value<int>? ayahCount,
    Value<bool>? bismillahPre,
    Value<String?>? bismillahUthmani,
    Value<String>? sourceId,
  }) {
    return SurahsCompanion(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameTranslit: nameTranslit ?? this.nameTranslit,
      revelationPlace: revelationPlace ?? this.revelationPlace,
      revelationOrder: revelationOrder ?? this.revelationOrder,
      ayahCount: ayahCount ?? this.ayahCount,
      bismillahPre: bismillahPre ?? this.bismillahPre,
      bismillahUthmani: bismillahUthmani ?? this.bismillahUthmani,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nameAr.present) {
      map['name_ar'] = Variable<String>(nameAr.value);
    }
    if (nameTranslit.present) {
      map['name_translit'] = Variable<String>(nameTranslit.value);
    }
    if (revelationPlace.present) {
      map['revelation_place'] = Variable<String>(revelationPlace.value);
    }
    if (revelationOrder.present) {
      map['revelation_order'] = Variable<int>(revelationOrder.value);
    }
    if (ayahCount.present) {
      map['ayah_count'] = Variable<int>(ayahCount.value);
    }
    if (bismillahPre.present) {
      map['bismillah_pre'] = Variable<bool>(bismillahPre.value);
    }
    if (bismillahUthmani.present) {
      map['bismillah_uthmani'] = Variable<String>(bismillahUthmani.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('id: $id, ')
          ..write('nameAr: $nameAr, ')
          ..write('nameTranslit: $nameTranslit, ')
          ..write('revelationPlace: $revelationPlace, ')
          ..write('revelationOrder: $revelationOrder, ')
          ..write('ayahCount: $ayahCount, ')
          ..write('bismillahPre: $bismillahPre, ')
          ..write('bismillahUthmani: $bismillahUthmani, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

class $SurahTextsTable extends SurahTexts
    with TableInfo<$SurahTextsTable, SurahTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurahTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surah (id)',
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
  late final GeneratedColumn<String> nameMeaning = GeneratedColumn<String>(
    'name_meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [surahId, lang, nameMeaning, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surah_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {surahId, lang};
  @override
  SurahTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurahTextRow(
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      nameMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_meaning'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $SurahTextsTable createAlias(String alias) {
    return $SurahTextsTable(attachedDatabase, alias);
  }
}

class SurahTextRow extends DataClass implements Insertable<SurahTextRow> {
  final int surahId;
  final String lang;
  final String nameMeaning;
  final String sourceId;
  const SurahTextRow({
    required this.surahId,
    required this.lang,
    required this.nameMeaning,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['surah_id'] = Variable<int>(surahId);
    map['lang'] = Variable<String>(lang);
    map['name_meaning'] = Variable<String>(nameMeaning);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  SurahTextsCompanion toCompanion(bool nullToAbsent) {
    return SurahTextsCompanion(
      surahId: Value(surahId),
      lang: Value(lang),
      nameMeaning: Value(nameMeaning),
      sourceId: Value(sourceId),
    );
  }

  factory SurahTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurahTextRow(
      surahId: serializer.fromJson<int>(json['surahId']),
      lang: serializer.fromJson<String>(json['lang']),
      nameMeaning: serializer.fromJson<String>(json['nameMeaning']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'surahId': serializer.toJson<int>(surahId),
      'lang': serializer.toJson<String>(lang),
      'nameMeaning': serializer.toJson<String>(nameMeaning),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  SurahTextRow copyWith({
    int? surahId,
    String? lang,
    String? nameMeaning,
    String? sourceId,
  }) => SurahTextRow(
    surahId: surahId ?? this.surahId,
    lang: lang ?? this.lang,
    nameMeaning: nameMeaning ?? this.nameMeaning,
    sourceId: sourceId ?? this.sourceId,
  );
  SurahTextRow copyWithCompanion(SurahTextsCompanion data) {
    return SurahTextRow(
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      lang: data.lang.present ? data.lang.value : this.lang,
      nameMeaning: data.nameMeaning.present
          ? data.nameMeaning.value
          : this.nameMeaning,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurahTextRow(')
          ..write('surahId: $surahId, ')
          ..write('lang: $lang, ')
          ..write('nameMeaning: $nameMeaning, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(surahId, lang, nameMeaning, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurahTextRow &&
          other.surahId == this.surahId &&
          other.lang == this.lang &&
          other.nameMeaning == this.nameMeaning &&
          other.sourceId == this.sourceId);
}

class SurahTextsCompanion extends UpdateCompanion<SurahTextRow> {
  final Value<int> surahId;
  final Value<String> lang;
  final Value<String> nameMeaning;
  final Value<String> sourceId;
  final Value<int> rowid;
  const SurahTextsCompanion({
    this.surahId = const Value.absent(),
    this.lang = const Value.absent(),
    this.nameMeaning = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurahTextsCompanion.insert({
    required int surahId,
    required String lang,
    required String nameMeaning,
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : surahId = Value(surahId),
       lang = Value(lang),
       nameMeaning = Value(nameMeaning),
       sourceId = Value(sourceId);
  static Insertable<SurahTextRow> custom({
    Expression<int>? surahId,
    Expression<String>? lang,
    Expression<String>? nameMeaning,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (surahId != null) 'surah_id': surahId,
      if (lang != null) 'lang': lang,
      if (nameMeaning != null) 'name_meaning': nameMeaning,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurahTextsCompanion copyWith({
    Value<int>? surahId,
    Value<String>? lang,
    Value<String>? nameMeaning,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return SurahTextsCompanion(
      surahId: surahId ?? this.surahId,
      lang: lang ?? this.lang,
      nameMeaning: nameMeaning ?? this.nameMeaning,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (nameMeaning.present) {
      map['name_meaning'] = Variable<String>(nameMeaning.value);
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
    return (StringBuffer('SurahTextsCompanion(')
          ..write('surahId: $surahId, ')
          ..write('lang: $lang, ')
          ..write('nameMeaning: $nameMeaning, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AyahsTable extends Ayahs with TableInfo<$AyahsTable, AyahRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AyahsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> surahId = GeneratedColumn<int>(
    'surah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surah (id)',
    ),
  );
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> textUthmani = GeneratedColumn<String>(
    'text_uthmani',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> textSimple = GeneratedColumn<String>(
    'text_simple',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> juz = GeneratedColumn<int>(
    'juz',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> hizbQuarter = GeneratedColumn<int>(
    'hizb_quarter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> sajda = GeneratedColumn<String>(
    'sajda',
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
  late final GeneratedColumn<String> simpleSourceId = GeneratedColumn<String>(
    'simple_source_id',
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
    surahId,
    number,
    textUthmani,
    textSimple,
    juz,
    hizbQuarter,
    page,
    sajda,
    sourceId,
    simpleSourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ayah';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {surahId, number},
  ];
  @override
  AyahRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AyahRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      textUthmani: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_uthmani'],
      )!,
      textSimple: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_simple'],
      )!,
      juz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}juz'],
      )!,
      hizbQuarter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hizb_quarter'],
      )!,
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      sajda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sajda'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      simpleSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}simple_source_id'],
      )!,
    );
  }

  @override
  $AyahsTable createAlias(String alias) {
    return $AyahsTable(attachedDatabase, alias);
  }
}

class AyahRow extends DataClass implements Insertable<AyahRow> {
  final int id;
  final int surahId;
  final int number;
  final String textUthmani;
  final String textSimple;
  final int juz;
  final int hizbQuarter;
  final int page;
  final String? sajda;
  final String sourceId;
  final String simpleSourceId;
  const AyahRow({
    required this.id,
    required this.surahId,
    required this.number,
    required this.textUthmani,
    required this.textSimple,
    required this.juz,
    required this.hizbQuarter,
    required this.page,
    this.sajda,
    required this.sourceId,
    required this.simpleSourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['surah_id'] = Variable<int>(surahId);
    map['number'] = Variable<int>(number);
    map['text_uthmani'] = Variable<String>(textUthmani);
    map['text_simple'] = Variable<String>(textSimple);
    map['juz'] = Variable<int>(juz);
    map['hizb_quarter'] = Variable<int>(hizbQuarter);
    map['page'] = Variable<int>(page);
    if (!nullToAbsent || sajda != null) {
      map['sajda'] = Variable<String>(sajda);
    }
    map['source_id'] = Variable<String>(sourceId);
    map['simple_source_id'] = Variable<String>(simpleSourceId);
    return map;
  }

  AyahsCompanion toCompanion(bool nullToAbsent) {
    return AyahsCompanion(
      id: Value(id),
      surahId: Value(surahId),
      number: Value(number),
      textUthmani: Value(textUthmani),
      textSimple: Value(textSimple),
      juz: Value(juz),
      hizbQuarter: Value(hizbQuarter),
      page: Value(page),
      sajda: sajda == null && nullToAbsent
          ? const Value.absent()
          : Value(sajda),
      sourceId: Value(sourceId),
      simpleSourceId: Value(simpleSourceId),
    );
  }

  factory AyahRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AyahRow(
      id: serializer.fromJson<int>(json['id']),
      surahId: serializer.fromJson<int>(json['surahId']),
      number: serializer.fromJson<int>(json['number']),
      textUthmani: serializer.fromJson<String>(json['textUthmani']),
      textSimple: serializer.fromJson<String>(json['textSimple']),
      juz: serializer.fromJson<int>(json['juz']),
      hizbQuarter: serializer.fromJson<int>(json['hizbQuarter']),
      page: serializer.fromJson<int>(json['page']),
      sajda: serializer.fromJson<String?>(json['sajda']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      simpleSourceId: serializer.fromJson<String>(json['simpleSourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahId': serializer.toJson<int>(surahId),
      'number': serializer.toJson<int>(number),
      'textUthmani': serializer.toJson<String>(textUthmani),
      'textSimple': serializer.toJson<String>(textSimple),
      'juz': serializer.toJson<int>(juz),
      'hizbQuarter': serializer.toJson<int>(hizbQuarter),
      'page': serializer.toJson<int>(page),
      'sajda': serializer.toJson<String?>(sajda),
      'sourceId': serializer.toJson<String>(sourceId),
      'simpleSourceId': serializer.toJson<String>(simpleSourceId),
    };
  }

  AyahRow copyWith({
    int? id,
    int? surahId,
    int? number,
    String? textUthmani,
    String? textSimple,
    int? juz,
    int? hizbQuarter,
    int? page,
    Value<String?> sajda = const Value.absent(),
    String? sourceId,
    String? simpleSourceId,
  }) => AyahRow(
    id: id ?? this.id,
    surahId: surahId ?? this.surahId,
    number: number ?? this.number,
    textUthmani: textUthmani ?? this.textUthmani,
    textSimple: textSimple ?? this.textSimple,
    juz: juz ?? this.juz,
    hizbQuarter: hizbQuarter ?? this.hizbQuarter,
    page: page ?? this.page,
    sajda: sajda.present ? sajda.value : this.sajda,
    sourceId: sourceId ?? this.sourceId,
    simpleSourceId: simpleSourceId ?? this.simpleSourceId,
  );
  AyahRow copyWithCompanion(AyahsCompanion data) {
    return AyahRow(
      id: data.id.present ? data.id.value : this.id,
      surahId: data.surahId.present ? data.surahId.value : this.surahId,
      number: data.number.present ? data.number.value : this.number,
      textUthmani: data.textUthmani.present
          ? data.textUthmani.value
          : this.textUthmani,
      textSimple: data.textSimple.present
          ? data.textSimple.value
          : this.textSimple,
      juz: data.juz.present ? data.juz.value : this.juz,
      hizbQuarter: data.hizbQuarter.present
          ? data.hizbQuarter.value
          : this.hizbQuarter,
      page: data.page.present ? data.page.value : this.page,
      sajda: data.sajda.present ? data.sajda.value : this.sajda,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      simpleSourceId: data.simpleSourceId.present
          ? data.simpleSourceId.value
          : this.simpleSourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AyahRow(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('number: $number, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textSimple: $textSimple, ')
          ..write('juz: $juz, ')
          ..write('hizbQuarter: $hizbQuarter, ')
          ..write('page: $page, ')
          ..write('sajda: $sajda, ')
          ..write('sourceId: $sourceId, ')
          ..write('simpleSourceId: $simpleSourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    surahId,
    number,
    textUthmani,
    textSimple,
    juz,
    hizbQuarter,
    page,
    sajda,
    sourceId,
    simpleSourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AyahRow &&
          other.id == this.id &&
          other.surahId == this.surahId &&
          other.number == this.number &&
          other.textUthmani == this.textUthmani &&
          other.textSimple == this.textSimple &&
          other.juz == this.juz &&
          other.hizbQuarter == this.hizbQuarter &&
          other.page == this.page &&
          other.sajda == this.sajda &&
          other.sourceId == this.sourceId &&
          other.simpleSourceId == this.simpleSourceId);
}

class AyahsCompanion extends UpdateCompanion<AyahRow> {
  final Value<int> id;
  final Value<int> surahId;
  final Value<int> number;
  final Value<String> textUthmani;
  final Value<String> textSimple;
  final Value<int> juz;
  final Value<int> hizbQuarter;
  final Value<int> page;
  final Value<String?> sajda;
  final Value<String> sourceId;
  final Value<String> simpleSourceId;
  const AyahsCompanion({
    this.id = const Value.absent(),
    this.surahId = const Value.absent(),
    this.number = const Value.absent(),
    this.textUthmani = const Value.absent(),
    this.textSimple = const Value.absent(),
    this.juz = const Value.absent(),
    this.hizbQuarter = const Value.absent(),
    this.page = const Value.absent(),
    this.sajda = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.simpleSourceId = const Value.absent(),
  });
  AyahsCompanion.insert({
    this.id = const Value.absent(),
    required int surahId,
    required int number,
    required String textUthmani,
    required String textSimple,
    required int juz,
    required int hizbQuarter,
    required int page,
    this.sajda = const Value.absent(),
    required String sourceId,
    required String simpleSourceId,
  }) : surahId = Value(surahId),
       number = Value(number),
       textUthmani = Value(textUthmani),
       textSimple = Value(textSimple),
       juz = Value(juz),
       hizbQuarter = Value(hizbQuarter),
       page = Value(page),
       sourceId = Value(sourceId),
       simpleSourceId = Value(simpleSourceId);
  static Insertable<AyahRow> custom({
    Expression<int>? id,
    Expression<int>? surahId,
    Expression<int>? number,
    Expression<String>? textUthmani,
    Expression<String>? textSimple,
    Expression<int>? juz,
    Expression<int>? hizbQuarter,
    Expression<int>? page,
    Expression<String>? sajda,
    Expression<String>? sourceId,
    Expression<String>? simpleSourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surahId != null) 'surah_id': surahId,
      if (number != null) 'number': number,
      if (textUthmani != null) 'text_uthmani': textUthmani,
      if (textSimple != null) 'text_simple': textSimple,
      if (juz != null) 'juz': juz,
      if (hizbQuarter != null) 'hizb_quarter': hizbQuarter,
      if (page != null) 'page': page,
      if (sajda != null) 'sajda': sajda,
      if (sourceId != null) 'source_id': sourceId,
      if (simpleSourceId != null) 'simple_source_id': simpleSourceId,
    });
  }

  AyahsCompanion copyWith({
    Value<int>? id,
    Value<int>? surahId,
    Value<int>? number,
    Value<String>? textUthmani,
    Value<String>? textSimple,
    Value<int>? juz,
    Value<int>? hizbQuarter,
    Value<int>? page,
    Value<String?>? sajda,
    Value<String>? sourceId,
    Value<String>? simpleSourceId,
  }) {
    return AyahsCompanion(
      id: id ?? this.id,
      surahId: surahId ?? this.surahId,
      number: number ?? this.number,
      textUthmani: textUthmani ?? this.textUthmani,
      textSimple: textSimple ?? this.textSimple,
      juz: juz ?? this.juz,
      hizbQuarter: hizbQuarter ?? this.hizbQuarter,
      page: page ?? this.page,
      sajda: sajda ?? this.sajda,
      sourceId: sourceId ?? this.sourceId,
      simpleSourceId: simpleSourceId ?? this.simpleSourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surahId.present) {
      map['surah_id'] = Variable<int>(surahId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (textUthmani.present) {
      map['text_uthmani'] = Variable<String>(textUthmani.value);
    }
    if (textSimple.present) {
      map['text_simple'] = Variable<String>(textSimple.value);
    }
    if (juz.present) {
      map['juz'] = Variable<int>(juz.value);
    }
    if (hizbQuarter.present) {
      map['hizb_quarter'] = Variable<int>(hizbQuarter.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (sajda.present) {
      map['sajda'] = Variable<String>(sajda.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (simpleSourceId.present) {
      map['simple_source_id'] = Variable<String>(simpleSourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AyahsCompanion(')
          ..write('id: $id, ')
          ..write('surahId: $surahId, ')
          ..write('number: $number, ')
          ..write('textUthmani: $textUthmani, ')
          ..write('textSimple: $textSimple, ')
          ..write('juz: $juz, ')
          ..write('hizbQuarter: $hizbQuarter, ')
          ..write('page: $page, ')
          ..write('sajda: $sajda, ')
          ..write('sourceId: $sourceId, ')
          ..write('simpleSourceId: $simpleSourceId')
          ..write(')'))
        .toString();
  }
}

class $TranslationsTable extends Translations
    with TableInfo<$TranslationsTable, TranslationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayah (id)',
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
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> footnotes = GeneratedColumn<String>(
    'footnotes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ayahId,
    lang,
    sourceId,
    textContent,
    footnotes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translation';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ayahId, lang, sourceId},
  ];
  @override
  TranslationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranslationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      footnotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}footnotes'],
      ),
    );
  }

  @override
  $TranslationsTable createAlias(String alias) {
    return $TranslationsTable(attachedDatabase, alias);
  }
}

class TranslationRow extends DataClass implements Insertable<TranslationRow> {
  final int id;
  final int ayahId;
  final String lang;
  final String sourceId;
  final String textContent;
  final String? footnotes;
  const TranslationRow({
    required this.id,
    required this.ayahId,
    required this.lang,
    required this.sourceId,
    required this.textContent,
    this.footnotes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['lang'] = Variable<String>(lang);
    map['source_id'] = Variable<String>(sourceId);
    map['text'] = Variable<String>(textContent);
    if (!nullToAbsent || footnotes != null) {
      map['footnotes'] = Variable<String>(footnotes);
    }
    return map;
  }

  TranslationsCompanion toCompanion(bool nullToAbsent) {
    return TranslationsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      lang: Value(lang),
      sourceId: Value(sourceId),
      textContent: Value(textContent),
      footnotes: footnotes == null && nullToAbsent
          ? const Value.absent()
          : Value(footnotes),
    );
  }

  factory TranslationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranslationRow(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      lang: serializer.fromJson<String>(json['lang']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      textContent: serializer.fromJson<String>(json['textContent']),
      footnotes: serializer.fromJson<String?>(json['footnotes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'lang': serializer.toJson<String>(lang),
      'sourceId': serializer.toJson<String>(sourceId),
      'textContent': serializer.toJson<String>(textContent),
      'footnotes': serializer.toJson<String?>(footnotes),
    };
  }

  TranslationRow copyWith({
    int? id,
    int? ayahId,
    String? lang,
    String? sourceId,
    String? textContent,
    Value<String?> footnotes = const Value.absent(),
  }) => TranslationRow(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    lang: lang ?? this.lang,
    sourceId: sourceId ?? this.sourceId,
    textContent: textContent ?? this.textContent,
    footnotes: footnotes.present ? footnotes.value : this.footnotes,
  );
  TranslationRow copyWithCompanion(TranslationsCompanion data) {
    return TranslationRow(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      lang: data.lang.present ? data.lang.value : this.lang,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      footnotes: data.footnotes.present ? data.footnotes.value : this.footnotes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranslationRow(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('lang: $lang, ')
          ..write('sourceId: $sourceId, ')
          ..write('textContent: $textContent, ')
          ..write('footnotes: $footnotes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, ayahId, lang, sourceId, textContent, footnotes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranslationRow &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.lang == this.lang &&
          other.sourceId == this.sourceId &&
          other.textContent == this.textContent &&
          other.footnotes == this.footnotes);
}

class TranslationsCompanion extends UpdateCompanion<TranslationRow> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<String> lang;
  final Value<String> sourceId;
  final Value<String> textContent;
  final Value<String?> footnotes;
  const TranslationsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.lang = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.textContent = const Value.absent(),
    this.footnotes = const Value.absent(),
  });
  TranslationsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required String lang,
    required String sourceId,
    required String textContent,
    this.footnotes = const Value.absent(),
  }) : ayahId = Value(ayahId),
       lang = Value(lang),
       sourceId = Value(sourceId),
       textContent = Value(textContent);
  static Insertable<TranslationRow> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<String>? lang,
    Expression<String>? sourceId,
    Expression<String>? textContent,
    Expression<String>? footnotes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (lang != null) 'lang': lang,
      if (sourceId != null) 'source_id': sourceId,
      if (textContent != null) 'text': textContent,
      if (footnotes != null) 'footnotes': footnotes,
    });
  }

  TranslationsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<String>? lang,
    Value<String>? sourceId,
    Value<String>? textContent,
    Value<String?>? footnotes,
  }) {
    return TranslationsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      lang: lang ?? this.lang,
      sourceId: sourceId ?? this.sourceId,
      textContent: textContent ?? this.textContent,
      footnotes: footnotes ?? this.footnotes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (footnotes.present) {
      map['footnotes'] = Variable<String>(footnotes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('lang: $lang, ')
          ..write('sourceId: $sourceId, ')
          ..write('textContent: $textContent, ')
          ..write('footnotes: $footnotes')
          ..write(')'))
        .toString();
  }
}

class $LemmasTable extends Lemmas with TableInfo<$LemmasTable, LemmaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LemmasTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> textAr = GeneratedColumn<String>(
    'text_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> translit = GeneratedColumn<String>(
    'translit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> root = GeneratedColumn<String>(
    'root',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> frequency = GeneratedColumn<int>(
    'frequency',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    id,
    textAr,
    translit,
    root,
    frequency,
    rank,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lemma';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LemmaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LemmaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      textAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_ar'],
      )!,
      translit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translit'],
      ),
      root: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frequency'],
      ),
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $LemmasTable createAlias(String alias) {
    return $LemmasTable(attachedDatabase, alias);
  }
}

class LemmaRow extends DataClass implements Insertable<LemmaRow> {
  final int id;
  final String textAr;
  final String? translit;
  final String? root;
  final int? frequency;
  final int? rank;
  final String sourceId;
  const LemmaRow({
    required this.id,
    required this.textAr,
    this.translit,
    this.root,
    this.frequency,
    this.rank,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['text_ar'] = Variable<String>(textAr);
    if (!nullToAbsent || translit != null) {
      map['translit'] = Variable<String>(translit);
    }
    if (!nullToAbsent || root != null) {
      map['root'] = Variable<String>(root);
    }
    if (!nullToAbsent || frequency != null) {
      map['frequency'] = Variable<int>(frequency);
    }
    if (!nullToAbsent || rank != null) {
      map['rank'] = Variable<int>(rank);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  LemmasCompanion toCompanion(bool nullToAbsent) {
    return LemmasCompanion(
      id: Value(id),
      textAr: Value(textAr),
      translit: translit == null && nullToAbsent
          ? const Value.absent()
          : Value(translit),
      root: root == null && nullToAbsent ? const Value.absent() : Value(root),
      frequency: frequency == null && nullToAbsent
          ? const Value.absent()
          : Value(frequency),
      rank: rank == null && nullToAbsent ? const Value.absent() : Value(rank),
      sourceId: Value(sourceId),
    );
  }

  factory LemmaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LemmaRow(
      id: serializer.fromJson<int>(json['id']),
      textAr: serializer.fromJson<String>(json['textAr']),
      translit: serializer.fromJson<String?>(json['translit']),
      root: serializer.fromJson<String?>(json['root']),
      frequency: serializer.fromJson<int?>(json['frequency']),
      rank: serializer.fromJson<int?>(json['rank']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'textAr': serializer.toJson<String>(textAr),
      'translit': serializer.toJson<String?>(translit),
      'root': serializer.toJson<String?>(root),
      'frequency': serializer.toJson<int?>(frequency),
      'rank': serializer.toJson<int?>(rank),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  LemmaRow copyWith({
    int? id,
    String? textAr,
    Value<String?> translit = const Value.absent(),
    Value<String?> root = const Value.absent(),
    Value<int?> frequency = const Value.absent(),
    Value<int?> rank = const Value.absent(),
    String? sourceId,
  }) => LemmaRow(
    id: id ?? this.id,
    textAr: textAr ?? this.textAr,
    translit: translit.present ? translit.value : this.translit,
    root: root.present ? root.value : this.root,
    frequency: frequency.present ? frequency.value : this.frequency,
    rank: rank.present ? rank.value : this.rank,
    sourceId: sourceId ?? this.sourceId,
  );
  LemmaRow copyWithCompanion(LemmasCompanion data) {
    return LemmaRow(
      id: data.id.present ? data.id.value : this.id,
      textAr: data.textAr.present ? data.textAr.value : this.textAr,
      translit: data.translit.present ? data.translit.value : this.translit,
      root: data.root.present ? data.root.value : this.root,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      rank: data.rank.present ? data.rank.value : this.rank,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LemmaRow(')
          ..write('id: $id, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('root: $root, ')
          ..write('frequency: $frequency, ')
          ..write('rank: $rank, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, textAr, translit, root, frequency, rank, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LemmaRow &&
          other.id == this.id &&
          other.textAr == this.textAr &&
          other.translit == this.translit &&
          other.root == this.root &&
          other.frequency == this.frequency &&
          other.rank == this.rank &&
          other.sourceId == this.sourceId);
}

class LemmasCompanion extends UpdateCompanion<LemmaRow> {
  final Value<int> id;
  final Value<String> textAr;
  final Value<String?> translit;
  final Value<String?> root;
  final Value<int?> frequency;
  final Value<int?> rank;
  final Value<String> sourceId;
  const LemmasCompanion({
    this.id = const Value.absent(),
    this.textAr = const Value.absent(),
    this.translit = const Value.absent(),
    this.root = const Value.absent(),
    this.frequency = const Value.absent(),
    this.rank = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  LemmasCompanion.insert({
    this.id = const Value.absent(),
    required String textAr,
    this.translit = const Value.absent(),
    this.root = const Value.absent(),
    this.frequency = const Value.absent(),
    this.rank = const Value.absent(),
    required String sourceId,
  }) : textAr = Value(textAr),
       sourceId = Value(sourceId);
  static Insertable<LemmaRow> custom({
    Expression<int>? id,
    Expression<String>? textAr,
    Expression<String>? translit,
    Expression<String>? root,
    Expression<int>? frequency,
    Expression<int>? rank,
    Expression<String>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textAr != null) 'text_ar': textAr,
      if (translit != null) 'translit': translit,
      if (root != null) 'root': root,
      if (frequency != null) 'frequency': frequency,
      if (rank != null) 'rank': rank,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  LemmasCompanion copyWith({
    Value<int>? id,
    Value<String>? textAr,
    Value<String?>? translit,
    Value<String?>? root,
    Value<int?>? frequency,
    Value<int?>? rank,
    Value<String>? sourceId,
  }) {
    return LemmasCompanion(
      id: id ?? this.id,
      textAr: textAr ?? this.textAr,
      translit: translit ?? this.translit,
      root: root ?? this.root,
      frequency: frequency ?? this.frequency,
      rank: rank ?? this.rank,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (textAr.present) {
      map['text_ar'] = Variable<String>(textAr.value);
    }
    if (translit.present) {
      map['translit'] = Variable<String>(translit.value);
    }
    if (root.present) {
      map['root'] = Variable<String>(root.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<int>(frequency.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LemmasCompanion(')
          ..write('id: $id, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('root: $root, ')
          ..write('frequency: $frequency, ')
          ..write('rank: $rank, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

class $LemmaMeaningsTable extends LemmaMeanings
    with TableInfo<$LemmaMeaningsTable, LemmaMeaningRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LemmaMeaningsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> lemmaId = GeneratedColumn<int>(
    'lemma_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lemma (id)',
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
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [lemmaId, lang, meaning, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lemma_meaning';
  @override
  Set<GeneratedColumn> get $primaryKey => {lemmaId, lang};
  @override
  LemmaMeaningRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LemmaMeaningRow(
      lemmaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lemma_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $LemmaMeaningsTable createAlias(String alias) {
    return $LemmaMeaningsTable(attachedDatabase, alias);
  }
}

class LemmaMeaningRow extends DataClass implements Insertable<LemmaMeaningRow> {
  final int lemmaId;
  final String lang;
  final String meaning;
  final String sourceId;
  const LemmaMeaningRow({
    required this.lemmaId,
    required this.lang,
    required this.meaning,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lemma_id'] = Variable<int>(lemmaId);
    map['lang'] = Variable<String>(lang);
    map['meaning'] = Variable<String>(meaning);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  LemmaMeaningsCompanion toCompanion(bool nullToAbsent) {
    return LemmaMeaningsCompanion(
      lemmaId: Value(lemmaId),
      lang: Value(lang),
      meaning: Value(meaning),
      sourceId: Value(sourceId),
    );
  }

  factory LemmaMeaningRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LemmaMeaningRow(
      lemmaId: serializer.fromJson<int>(json['lemmaId']),
      lang: serializer.fromJson<String>(json['lang']),
      meaning: serializer.fromJson<String>(json['meaning']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lemmaId': serializer.toJson<int>(lemmaId),
      'lang': serializer.toJson<String>(lang),
      'meaning': serializer.toJson<String>(meaning),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  LemmaMeaningRow copyWith({
    int? lemmaId,
    String? lang,
    String? meaning,
    String? sourceId,
  }) => LemmaMeaningRow(
    lemmaId: lemmaId ?? this.lemmaId,
    lang: lang ?? this.lang,
    meaning: meaning ?? this.meaning,
    sourceId: sourceId ?? this.sourceId,
  );
  LemmaMeaningRow copyWithCompanion(LemmaMeaningsCompanion data) {
    return LemmaMeaningRow(
      lemmaId: data.lemmaId.present ? data.lemmaId.value : this.lemmaId,
      lang: data.lang.present ? data.lang.value : this.lang,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LemmaMeaningRow(')
          ..write('lemmaId: $lemmaId, ')
          ..write('lang: $lang, ')
          ..write('meaning: $meaning, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lemmaId, lang, meaning, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LemmaMeaningRow &&
          other.lemmaId == this.lemmaId &&
          other.lang == this.lang &&
          other.meaning == this.meaning &&
          other.sourceId == this.sourceId);
}

class LemmaMeaningsCompanion extends UpdateCompanion<LemmaMeaningRow> {
  final Value<int> lemmaId;
  final Value<String> lang;
  final Value<String> meaning;
  final Value<String> sourceId;
  final Value<int> rowid;
  const LemmaMeaningsCompanion({
    this.lemmaId = const Value.absent(),
    this.lang = const Value.absent(),
    this.meaning = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LemmaMeaningsCompanion.insert({
    required int lemmaId,
    required String lang,
    required String meaning,
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : lemmaId = Value(lemmaId),
       lang = Value(lang),
       meaning = Value(meaning),
       sourceId = Value(sourceId);
  static Insertable<LemmaMeaningRow> custom({
    Expression<int>? lemmaId,
    Expression<String>? lang,
    Expression<String>? meaning,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lemmaId != null) 'lemma_id': lemmaId,
      if (lang != null) 'lang': lang,
      if (meaning != null) 'meaning': meaning,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LemmaMeaningsCompanion copyWith({
    Value<int>? lemmaId,
    Value<String>? lang,
    Value<String>? meaning,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return LemmaMeaningsCompanion(
      lemmaId: lemmaId ?? this.lemmaId,
      lang: lang ?? this.lang,
      meaning: meaning ?? this.meaning,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lemmaId.present) {
      map['lemma_id'] = Variable<int>(lemmaId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
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
    return (StringBuffer('LemmaMeaningsCompanion(')
          ..write('lemmaId: $lemmaId, ')
          ..write('lang: $lang, ')
          ..write('meaning: $meaning, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, WordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> ayahId = GeneratedColumn<int>(
    'ayah_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayah (id)',
    ),
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> textAr = GeneratedColumn<String>(
    'text_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> translit = GeneratedColumn<String>(
    'translit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> lemmaId = GeneratedColumn<int>(
    'lemma_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lemma (id)',
    ),
  );
  @override
  late final GeneratedColumn<int> charStart = GeneratedColumn<int>(
    'char_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> charEnd = GeneratedColumn<int>(
    'char_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    id,
    ayahId,
    position,
    textAr,
    translit,
    lemmaId,
    charStart,
    charEnd,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ayahId, position},
  ];
  @override
  WordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ayahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      textAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_ar'],
      )!,
      translit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translit'],
      ),
      lemmaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lemma_id'],
      ),
      charStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_start'],
      ),
      charEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_end'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class WordRow extends DataClass implements Insertable<WordRow> {
  final int id;
  final int ayahId;
  final int position;
  final String textAr;
  final String? translit;
  final int? lemmaId;
  final int? charStart;
  final int? charEnd;
  final String sourceId;
  const WordRow({
    required this.id,
    required this.ayahId,
    required this.position,
    required this.textAr,
    this.translit,
    this.lemmaId,
    this.charStart,
    this.charEnd,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ayah_id'] = Variable<int>(ayahId);
    map['position'] = Variable<int>(position);
    map['text_ar'] = Variable<String>(textAr);
    if (!nullToAbsent || translit != null) {
      map['translit'] = Variable<String>(translit);
    }
    if (!nullToAbsent || lemmaId != null) {
      map['lemma_id'] = Variable<int>(lemmaId);
    }
    if (!nullToAbsent || charStart != null) {
      map['char_start'] = Variable<int>(charStart);
    }
    if (!nullToAbsent || charEnd != null) {
      map['char_end'] = Variable<int>(charEnd);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      ayahId: Value(ayahId),
      position: Value(position),
      textAr: Value(textAr),
      translit: translit == null && nullToAbsent
          ? const Value.absent()
          : Value(translit),
      lemmaId: lemmaId == null && nullToAbsent
          ? const Value.absent()
          : Value(lemmaId),
      charStart: charStart == null && nullToAbsent
          ? const Value.absent()
          : Value(charStart),
      charEnd: charEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(charEnd),
      sourceId: Value(sourceId),
    );
  }

  factory WordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordRow(
      id: serializer.fromJson<int>(json['id']),
      ayahId: serializer.fromJson<int>(json['ayahId']),
      position: serializer.fromJson<int>(json['position']),
      textAr: serializer.fromJson<String>(json['textAr']),
      translit: serializer.fromJson<String?>(json['translit']),
      lemmaId: serializer.fromJson<int?>(json['lemmaId']),
      charStart: serializer.fromJson<int?>(json['charStart']),
      charEnd: serializer.fromJson<int?>(json['charEnd']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ayahId': serializer.toJson<int>(ayahId),
      'position': serializer.toJson<int>(position),
      'textAr': serializer.toJson<String>(textAr),
      'translit': serializer.toJson<String?>(translit),
      'lemmaId': serializer.toJson<int?>(lemmaId),
      'charStart': serializer.toJson<int?>(charStart),
      'charEnd': serializer.toJson<int?>(charEnd),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  WordRow copyWith({
    int? id,
    int? ayahId,
    int? position,
    String? textAr,
    Value<String?> translit = const Value.absent(),
    Value<int?> lemmaId = const Value.absent(),
    Value<int?> charStart = const Value.absent(),
    Value<int?> charEnd = const Value.absent(),
    String? sourceId,
  }) => WordRow(
    id: id ?? this.id,
    ayahId: ayahId ?? this.ayahId,
    position: position ?? this.position,
    textAr: textAr ?? this.textAr,
    translit: translit.present ? translit.value : this.translit,
    lemmaId: lemmaId.present ? lemmaId.value : this.lemmaId,
    charStart: charStart.present ? charStart.value : this.charStart,
    charEnd: charEnd.present ? charEnd.value : this.charEnd,
    sourceId: sourceId ?? this.sourceId,
  );
  WordRow copyWithCompanion(WordsCompanion data) {
    return WordRow(
      id: data.id.present ? data.id.value : this.id,
      ayahId: data.ayahId.present ? data.ayahId.value : this.ayahId,
      position: data.position.present ? data.position.value : this.position,
      textAr: data.textAr.present ? data.textAr.value : this.textAr,
      translit: data.translit.present ? data.translit.value : this.translit,
      lemmaId: data.lemmaId.present ? data.lemmaId.value : this.lemmaId,
      charStart: data.charStart.present ? data.charStart.value : this.charStart,
      charEnd: data.charEnd.present ? data.charEnd.value : this.charEnd,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordRow(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('position: $position, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('lemmaId: $lemmaId, ')
          ..write('charStart: $charStart, ')
          ..write('charEnd: $charEnd, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ayahId,
    position,
    textAr,
    translit,
    lemmaId,
    charStart,
    charEnd,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordRow &&
          other.id == this.id &&
          other.ayahId == this.ayahId &&
          other.position == this.position &&
          other.textAr == this.textAr &&
          other.translit == this.translit &&
          other.lemmaId == this.lemmaId &&
          other.charStart == this.charStart &&
          other.charEnd == this.charEnd &&
          other.sourceId == this.sourceId);
}

class WordsCompanion extends UpdateCompanion<WordRow> {
  final Value<int> id;
  final Value<int> ayahId;
  final Value<int> position;
  final Value<String> textAr;
  final Value<String?> translit;
  final Value<int?> lemmaId;
  final Value<int?> charStart;
  final Value<int?> charEnd;
  final Value<String> sourceId;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.ayahId = const Value.absent(),
    this.position = const Value.absent(),
    this.textAr = const Value.absent(),
    this.translit = const Value.absent(),
    this.lemmaId = const Value.absent(),
    this.charStart = const Value.absent(),
    this.charEnd = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required int ayahId,
    required int position,
    required String textAr,
    this.translit = const Value.absent(),
    this.lemmaId = const Value.absent(),
    this.charStart = const Value.absent(),
    this.charEnd = const Value.absent(),
    required String sourceId,
  }) : ayahId = Value(ayahId),
       position = Value(position),
       textAr = Value(textAr),
       sourceId = Value(sourceId);
  static Insertable<WordRow> custom({
    Expression<int>? id,
    Expression<int>? ayahId,
    Expression<int>? position,
    Expression<String>? textAr,
    Expression<String>? translit,
    Expression<int>? lemmaId,
    Expression<int>? charStart,
    Expression<int>? charEnd,
    Expression<String>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ayahId != null) 'ayah_id': ayahId,
      if (position != null) 'position': position,
      if (textAr != null) 'text_ar': textAr,
      if (translit != null) 'translit': translit,
      if (lemmaId != null) 'lemma_id': lemmaId,
      if (charStart != null) 'char_start': charStart,
      if (charEnd != null) 'char_end': charEnd,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<int>? ayahId,
    Value<int>? position,
    Value<String>? textAr,
    Value<String?>? translit,
    Value<int?>? lemmaId,
    Value<int?>? charStart,
    Value<int?>? charEnd,
    Value<String>? sourceId,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      ayahId: ayahId ?? this.ayahId,
      position: position ?? this.position,
      textAr: textAr ?? this.textAr,
      translit: translit ?? this.translit,
      lemmaId: lemmaId ?? this.lemmaId,
      charStart: charStart ?? this.charStart,
      charEnd: charEnd ?? this.charEnd,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ayahId.present) {
      map['ayah_id'] = Variable<int>(ayahId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (textAr.present) {
      map['text_ar'] = Variable<String>(textAr.value);
    }
    if (translit.present) {
      map['translit'] = Variable<String>(translit.value);
    }
    if (lemmaId.present) {
      map['lemma_id'] = Variable<int>(lemmaId.value);
    }
    if (charStart.present) {
      map['char_start'] = Variable<int>(charStart.value);
    }
    if (charEnd.present) {
      map['char_end'] = Variable<int>(charEnd.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('ayahId: $ayahId, ')
          ..write('position: $position, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('lemmaId: $lemmaId, ')
          ..write('charStart: $charStart, ')
          ..write('charEnd: $charEnd, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

class $WordMeaningsTable extends WordMeanings
    with TableInfo<$WordMeaningsTable, WordMeaningRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordMeaningsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES word (id)',
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
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [wordId, lang, meaning, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_meaning';
  @override
  Set<GeneratedColumn> get $primaryKey => {wordId, lang};
  @override
  WordMeaningRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordMeaningRow(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $WordMeaningsTable createAlias(String alias) {
    return $WordMeaningsTable(attachedDatabase, alias);
  }
}

class WordMeaningRow extends DataClass implements Insertable<WordMeaningRow> {
  final int wordId;
  final String lang;
  final String meaning;
  final String sourceId;
  const WordMeaningRow({
    required this.wordId,
    required this.lang,
    required this.meaning,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['lang'] = Variable<String>(lang);
    map['meaning'] = Variable<String>(meaning);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  WordMeaningsCompanion toCompanion(bool nullToAbsent) {
    return WordMeaningsCompanion(
      wordId: Value(wordId),
      lang: Value(lang),
      meaning: Value(meaning),
      sourceId: Value(sourceId),
    );
  }

  factory WordMeaningRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordMeaningRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      lang: serializer.fromJson<String>(json['lang']),
      meaning: serializer.fromJson<String>(json['meaning']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'lang': serializer.toJson<String>(lang),
      'meaning': serializer.toJson<String>(meaning),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  WordMeaningRow copyWith({
    int? wordId,
    String? lang,
    String? meaning,
    String? sourceId,
  }) => WordMeaningRow(
    wordId: wordId ?? this.wordId,
    lang: lang ?? this.lang,
    meaning: meaning ?? this.meaning,
    sourceId: sourceId ?? this.sourceId,
  );
  WordMeaningRow copyWithCompanion(WordMeaningsCompanion data) {
    return WordMeaningRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      lang: data.lang.present ? data.lang.value : this.lang,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordMeaningRow(')
          ..write('wordId: $wordId, ')
          ..write('lang: $lang, ')
          ..write('meaning: $meaning, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, lang, meaning, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordMeaningRow &&
          other.wordId == this.wordId &&
          other.lang == this.lang &&
          other.meaning == this.meaning &&
          other.sourceId == this.sourceId);
}

class WordMeaningsCompanion extends UpdateCompanion<WordMeaningRow> {
  final Value<int> wordId;
  final Value<String> lang;
  final Value<String> meaning;
  final Value<String> sourceId;
  final Value<int> rowid;
  const WordMeaningsCompanion({
    this.wordId = const Value.absent(),
    this.lang = const Value.absent(),
    this.meaning = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordMeaningsCompanion.insert({
    required int wordId,
    required String lang,
    required String meaning,
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : wordId = Value(wordId),
       lang = Value(lang),
       meaning = Value(meaning),
       sourceId = Value(sourceId);
  static Insertable<WordMeaningRow> custom({
    Expression<int>? wordId,
    Expression<String>? lang,
    Expression<String>? meaning,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (lang != null) 'lang': lang,
      if (meaning != null) 'meaning': meaning,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordMeaningsCompanion copyWith({
    Value<int>? wordId,
    Value<String>? lang,
    Value<String>? meaning,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return WordMeaningsCompanion(
      wordId: wordId ?? this.wordId,
      lang: lang ?? this.lang,
      meaning: meaning ?? this.meaning,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
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
    return (StringBuffer('WordMeaningsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('lang: $lang, ')
          ..write('meaning: $meaning, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HadithsTable extends Hadiths with TableInfo<$HadithsTable, HadithRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HadithsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> textAr = GeneratedColumn<String>(
    'text_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> introAr = GeneratedColumn<String>(
    'intro_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> narratorAr = GeneratedColumn<String>(
    'narrator_ar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> gradeAr = GeneratedColumn<String>(
    'grade_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    collection,
    number,
    textAr,
    introAr,
    narratorAr,
    grade,
    gradeAr,
    tags,
    categories,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadith';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HadithRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HadithRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      ),
      textAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_ar'],
      )!,
      introAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intro_ar'],
      ),
      narratorAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrator_ar'],
      ),
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      gradeAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade_ar'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $HadithsTable createAlias(String alias) {
    return $HadithsTable(attachedDatabase, alias);
  }
}

class HadithRow extends DataClass implements Insertable<HadithRow> {
  final int id;
  final String collection;
  final String? number;
  final String textAr;
  final String? introAr;
  final String? narratorAr;
  final String grade;
  final String gradeAr;
  final String? tags;
  final String categories;
  final String sourceId;
  const HadithRow({
    required this.id,
    required this.collection,
    this.number,
    required this.textAr,
    this.introAr,
    this.narratorAr,
    required this.grade,
    required this.gradeAr,
    this.tags,
    required this.categories,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collection'] = Variable<String>(collection);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<String>(number);
    }
    map['text_ar'] = Variable<String>(textAr);
    if (!nullToAbsent || introAr != null) {
      map['intro_ar'] = Variable<String>(introAr);
    }
    if (!nullToAbsent || narratorAr != null) {
      map['narrator_ar'] = Variable<String>(narratorAr);
    }
    map['grade'] = Variable<String>(grade);
    map['grade_ar'] = Variable<String>(gradeAr);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['categories'] = Variable<String>(categories);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  HadithsCompanion toCompanion(bool nullToAbsent) {
    return HadithsCompanion(
      id: Value(id),
      collection: Value(collection),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      textAr: Value(textAr),
      introAr: introAr == null && nullToAbsent
          ? const Value.absent()
          : Value(introAr),
      narratorAr: narratorAr == null && nullToAbsent
          ? const Value.absent()
          : Value(narratorAr),
      grade: Value(grade),
      gradeAr: Value(gradeAr),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      categories: Value(categories),
      sourceId: Value(sourceId),
    );
  }

  factory HadithRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HadithRow(
      id: serializer.fromJson<int>(json['id']),
      collection: serializer.fromJson<String>(json['collection']),
      number: serializer.fromJson<String?>(json['number']),
      textAr: serializer.fromJson<String>(json['textAr']),
      introAr: serializer.fromJson<String?>(json['introAr']),
      narratorAr: serializer.fromJson<String?>(json['narratorAr']),
      grade: serializer.fromJson<String>(json['grade']),
      gradeAr: serializer.fromJson<String>(json['gradeAr']),
      tags: serializer.fromJson<String?>(json['tags']),
      categories: serializer.fromJson<String>(json['categories']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collection': serializer.toJson<String>(collection),
      'number': serializer.toJson<String?>(number),
      'textAr': serializer.toJson<String>(textAr),
      'introAr': serializer.toJson<String?>(introAr),
      'narratorAr': serializer.toJson<String?>(narratorAr),
      'grade': serializer.toJson<String>(grade),
      'gradeAr': serializer.toJson<String>(gradeAr),
      'tags': serializer.toJson<String?>(tags),
      'categories': serializer.toJson<String>(categories),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  HadithRow copyWith({
    int? id,
    String? collection,
    Value<String?> number = const Value.absent(),
    String? textAr,
    Value<String?> introAr = const Value.absent(),
    Value<String?> narratorAr = const Value.absent(),
    String? grade,
    String? gradeAr,
    Value<String?> tags = const Value.absent(),
    String? categories,
    String? sourceId,
  }) => HadithRow(
    id: id ?? this.id,
    collection: collection ?? this.collection,
    number: number.present ? number.value : this.number,
    textAr: textAr ?? this.textAr,
    introAr: introAr.present ? introAr.value : this.introAr,
    narratorAr: narratorAr.present ? narratorAr.value : this.narratorAr,
    grade: grade ?? this.grade,
    gradeAr: gradeAr ?? this.gradeAr,
    tags: tags.present ? tags.value : this.tags,
    categories: categories ?? this.categories,
    sourceId: sourceId ?? this.sourceId,
  );
  HadithRow copyWithCompanion(HadithsCompanion data) {
    return HadithRow(
      id: data.id.present ? data.id.value : this.id,
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      number: data.number.present ? data.number.value : this.number,
      textAr: data.textAr.present ? data.textAr.value : this.textAr,
      introAr: data.introAr.present ? data.introAr.value : this.introAr,
      narratorAr: data.narratorAr.present
          ? data.narratorAr.value
          : this.narratorAr,
      grade: data.grade.present ? data.grade.value : this.grade,
      gradeAr: data.gradeAr.present ? data.gradeAr.value : this.gradeAr,
      tags: data.tags.present ? data.tags.value : this.tags,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HadithRow(')
          ..write('id: $id, ')
          ..write('collection: $collection, ')
          ..write('number: $number, ')
          ..write('textAr: $textAr, ')
          ..write('introAr: $introAr, ')
          ..write('narratorAr: $narratorAr, ')
          ..write('grade: $grade, ')
          ..write('gradeAr: $gradeAr, ')
          ..write('tags: $tags, ')
          ..write('categories: $categories, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collection,
    number,
    textAr,
    introAr,
    narratorAr,
    grade,
    gradeAr,
    tags,
    categories,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HadithRow &&
          other.id == this.id &&
          other.collection == this.collection &&
          other.number == this.number &&
          other.textAr == this.textAr &&
          other.introAr == this.introAr &&
          other.narratorAr == this.narratorAr &&
          other.grade == this.grade &&
          other.gradeAr == this.gradeAr &&
          other.tags == this.tags &&
          other.categories == this.categories &&
          other.sourceId == this.sourceId);
}

class HadithsCompanion extends UpdateCompanion<HadithRow> {
  final Value<int> id;
  final Value<String> collection;
  final Value<String?> number;
  final Value<String> textAr;
  final Value<String?> introAr;
  final Value<String?> narratorAr;
  final Value<String> grade;
  final Value<String> gradeAr;
  final Value<String?> tags;
  final Value<String> categories;
  final Value<String> sourceId;
  const HadithsCompanion({
    this.id = const Value.absent(),
    this.collection = const Value.absent(),
    this.number = const Value.absent(),
    this.textAr = const Value.absent(),
    this.introAr = const Value.absent(),
    this.narratorAr = const Value.absent(),
    this.grade = const Value.absent(),
    this.gradeAr = const Value.absent(),
    this.tags = const Value.absent(),
    this.categories = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  HadithsCompanion.insert({
    this.id = const Value.absent(),
    required String collection,
    this.number = const Value.absent(),
    required String textAr,
    this.introAr = const Value.absent(),
    this.narratorAr = const Value.absent(),
    required String grade,
    required String gradeAr,
    this.tags = const Value.absent(),
    required String categories,
    required String sourceId,
  }) : collection = Value(collection),
       textAr = Value(textAr),
       grade = Value(grade),
       gradeAr = Value(gradeAr),
       categories = Value(categories),
       sourceId = Value(sourceId);
  static Insertable<HadithRow> custom({
    Expression<int>? id,
    Expression<String>? collection,
    Expression<String>? number,
    Expression<String>? textAr,
    Expression<String>? introAr,
    Expression<String>? narratorAr,
    Expression<String>? grade,
    Expression<String>? gradeAr,
    Expression<String>? tags,
    Expression<String>? categories,
    Expression<String>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collection != null) 'collection': collection,
      if (number != null) 'number': number,
      if (textAr != null) 'text_ar': textAr,
      if (introAr != null) 'intro_ar': introAr,
      if (narratorAr != null) 'narrator_ar': narratorAr,
      if (grade != null) 'grade': grade,
      if (gradeAr != null) 'grade_ar': gradeAr,
      if (tags != null) 'tags': tags,
      if (categories != null) 'categories': categories,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  HadithsCompanion copyWith({
    Value<int>? id,
    Value<String>? collection,
    Value<String?>? number,
    Value<String>? textAr,
    Value<String?>? introAr,
    Value<String?>? narratorAr,
    Value<String>? grade,
    Value<String>? gradeAr,
    Value<String?>? tags,
    Value<String>? categories,
    Value<String>? sourceId,
  }) {
    return HadithsCompanion(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      number: number ?? this.number,
      textAr: textAr ?? this.textAr,
      introAr: introAr ?? this.introAr,
      narratorAr: narratorAr ?? this.narratorAr,
      grade: grade ?? this.grade,
      gradeAr: gradeAr ?? this.gradeAr,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (textAr.present) {
      map['text_ar'] = Variable<String>(textAr.value);
    }
    if (introAr.present) {
      map['intro_ar'] = Variable<String>(introAr.value);
    }
    if (narratorAr.present) {
      map['narrator_ar'] = Variable<String>(narratorAr.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (gradeAr.present) {
      map['grade_ar'] = Variable<String>(gradeAr.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HadithsCompanion(')
          ..write('id: $id, ')
          ..write('collection: $collection, ')
          ..write('number: $number, ')
          ..write('textAr: $textAr, ')
          ..write('introAr: $introAr, ')
          ..write('narratorAr: $narratorAr, ')
          ..write('grade: $grade, ')
          ..write('gradeAr: $gradeAr, ')
          ..write('tags: $tags, ')
          ..write('categories: $categories, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

class $HadithTextsTable extends HadithTexts
    with TableInfo<$HadithTextsTable, HadithTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HadithTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> hadithId = GeneratedColumn<int>(
    'hadith_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES hadith (id)',
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
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> intro = GeneratedColumn<String>(
    'intro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> narrator = GeneratedColumn<String>(
    'narrator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  late final GeneratedColumn<String> gradeLabel = GeneratedColumn<String>(
    'grade_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    title,
    textContent,
    intro,
    narrator,
    attribution,
    gradeLabel,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hadith_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {hadithId, lang};
  @override
  HadithTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HadithTextRow(
      hadithId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hadith_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      intro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intro'],
      ),
      narrator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrator'],
      ),
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      gradeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade_label'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $HadithTextsTable createAlias(String alias) {
    return $HadithTextsTable(attachedDatabase, alias);
  }
}

class HadithTextRow extends DataClass implements Insertable<HadithTextRow> {
  final int hadithId;
  final String lang;
  final String title;
  final String textContent;
  final String? intro;
  final String? narrator;
  final String attribution;
  final String gradeLabel;
  final String sourceId;
  const HadithTextRow({
    required this.hadithId,
    required this.lang,
    required this.title,
    required this.textContent,
    this.intro,
    this.narrator,
    required this.attribution,
    required this.gradeLabel,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hadith_id'] = Variable<int>(hadithId);
    map['lang'] = Variable<String>(lang);
    map['title'] = Variable<String>(title);
    map['text'] = Variable<String>(textContent);
    if (!nullToAbsent || intro != null) {
      map['intro'] = Variable<String>(intro);
    }
    if (!nullToAbsent || narrator != null) {
      map['narrator'] = Variable<String>(narrator);
    }
    map['attribution'] = Variable<String>(attribution);
    map['grade_label'] = Variable<String>(gradeLabel);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  HadithTextsCompanion toCompanion(bool nullToAbsent) {
    return HadithTextsCompanion(
      hadithId: Value(hadithId),
      lang: Value(lang),
      title: Value(title),
      textContent: Value(textContent),
      intro: intro == null && nullToAbsent
          ? const Value.absent()
          : Value(intro),
      narrator: narrator == null && nullToAbsent
          ? const Value.absent()
          : Value(narrator),
      attribution: Value(attribution),
      gradeLabel: Value(gradeLabel),
      sourceId: Value(sourceId),
    );
  }

  factory HadithTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HadithTextRow(
      hadithId: serializer.fromJson<int>(json['hadithId']),
      lang: serializer.fromJson<String>(json['lang']),
      title: serializer.fromJson<String>(json['title']),
      textContent: serializer.fromJson<String>(json['textContent']),
      intro: serializer.fromJson<String?>(json['intro']),
      narrator: serializer.fromJson<String?>(json['narrator']),
      attribution: serializer.fromJson<String>(json['attribution']),
      gradeLabel: serializer.fromJson<String>(json['gradeLabel']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hadithId': serializer.toJson<int>(hadithId),
      'lang': serializer.toJson<String>(lang),
      'title': serializer.toJson<String>(title),
      'textContent': serializer.toJson<String>(textContent),
      'intro': serializer.toJson<String?>(intro),
      'narrator': serializer.toJson<String?>(narrator),
      'attribution': serializer.toJson<String>(attribution),
      'gradeLabel': serializer.toJson<String>(gradeLabel),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  HadithTextRow copyWith({
    int? hadithId,
    String? lang,
    String? title,
    String? textContent,
    Value<String?> intro = const Value.absent(),
    Value<String?> narrator = const Value.absent(),
    String? attribution,
    String? gradeLabel,
    String? sourceId,
  }) => HadithTextRow(
    hadithId: hadithId ?? this.hadithId,
    lang: lang ?? this.lang,
    title: title ?? this.title,
    textContent: textContent ?? this.textContent,
    intro: intro.present ? intro.value : this.intro,
    narrator: narrator.present ? narrator.value : this.narrator,
    attribution: attribution ?? this.attribution,
    gradeLabel: gradeLabel ?? this.gradeLabel,
    sourceId: sourceId ?? this.sourceId,
  );
  HadithTextRow copyWithCompanion(HadithTextsCompanion data) {
    return HadithTextRow(
      hadithId: data.hadithId.present ? data.hadithId.value : this.hadithId,
      lang: data.lang.present ? data.lang.value : this.lang,
      title: data.title.present ? data.title.value : this.title,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      intro: data.intro.present ? data.intro.value : this.intro,
      narrator: data.narrator.present ? data.narrator.value : this.narrator,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      gradeLabel: data.gradeLabel.present
          ? data.gradeLabel.value
          : this.gradeLabel,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HadithTextRow(')
          ..write('hadithId: $hadithId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('intro: $intro, ')
          ..write('narrator: $narrator, ')
          ..write('attribution: $attribution, ')
          ..write('gradeLabel: $gradeLabel, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hadithId,
    lang,
    title,
    textContent,
    intro,
    narrator,
    attribution,
    gradeLabel,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HadithTextRow &&
          other.hadithId == this.hadithId &&
          other.lang == this.lang &&
          other.title == this.title &&
          other.textContent == this.textContent &&
          other.intro == this.intro &&
          other.narrator == this.narrator &&
          other.attribution == this.attribution &&
          other.gradeLabel == this.gradeLabel &&
          other.sourceId == this.sourceId);
}

class HadithTextsCompanion extends UpdateCompanion<HadithTextRow> {
  final Value<int> hadithId;
  final Value<String> lang;
  final Value<String> title;
  final Value<String> textContent;
  final Value<String?> intro;
  final Value<String?> narrator;
  final Value<String> attribution;
  final Value<String> gradeLabel;
  final Value<String> sourceId;
  final Value<int> rowid;
  const HadithTextsCompanion({
    this.hadithId = const Value.absent(),
    this.lang = const Value.absent(),
    this.title = const Value.absent(),
    this.textContent = const Value.absent(),
    this.intro = const Value.absent(),
    this.narrator = const Value.absent(),
    this.attribution = const Value.absent(),
    this.gradeLabel = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HadithTextsCompanion.insert({
    required int hadithId,
    required String lang,
    required String title,
    required String textContent,
    this.intro = const Value.absent(),
    this.narrator = const Value.absent(),
    required String attribution,
    required String gradeLabel,
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : hadithId = Value(hadithId),
       lang = Value(lang),
       title = Value(title),
       textContent = Value(textContent),
       attribution = Value(attribution),
       gradeLabel = Value(gradeLabel),
       sourceId = Value(sourceId);
  static Insertable<HadithTextRow> custom({
    Expression<int>? hadithId,
    Expression<String>? lang,
    Expression<String>? title,
    Expression<String>? textContent,
    Expression<String>? intro,
    Expression<String>? narrator,
    Expression<String>? attribution,
    Expression<String>? gradeLabel,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hadithId != null) 'hadith_id': hadithId,
      if (lang != null) 'lang': lang,
      if (title != null) 'title': title,
      if (textContent != null) 'text': textContent,
      if (intro != null) 'intro': intro,
      if (narrator != null) 'narrator': narrator,
      if (attribution != null) 'attribution': attribution,
      if (gradeLabel != null) 'grade_label': gradeLabel,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HadithTextsCompanion copyWith({
    Value<int>? hadithId,
    Value<String>? lang,
    Value<String>? title,
    Value<String>? textContent,
    Value<String?>? intro,
    Value<String?>? narrator,
    Value<String>? attribution,
    Value<String>? gradeLabel,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return HadithTextsCompanion(
      hadithId: hadithId ?? this.hadithId,
      lang: lang ?? this.lang,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      intro: intro ?? this.intro,
      narrator: narrator ?? this.narrator,
      attribution: attribution ?? this.attribution,
      gradeLabel: gradeLabel ?? this.gradeLabel,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (intro.present) {
      map['intro'] = Variable<String>(intro.value);
    }
    if (narrator.present) {
      map['narrator'] = Variable<String>(narrator.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (gradeLabel.present) {
      map['grade_label'] = Variable<String>(gradeLabel.value);
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
    return (StringBuffer('HadithTextsCompanion(')
          ..write('hadithId: $hadithId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('intro: $intro, ')
          ..write('narrator: $narrator, ')
          ..write('attribution: $attribution, ')
          ..write('gradeLabel: $gradeLabel, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuasTable extends Duas with TableInfo<$DuasTable, DuaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuasTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> textAr = GeneratedColumn<String>(
    'text_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> translit = GeneratedColumn<String>(
    'translit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> repeatCount = GeneratedColumn<int>(
    'repeat_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
    'source_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    category,
    title,
    textAr,
    translit,
    repeatCount,
    timeOfDay,
    sourceRef,
    sourceId,
    reviewedBy,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dua';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DuaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      textAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_ar'],
      )!,
      translit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translit'],
      ),
      repeatCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repeat_count'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_ref'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
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
  $DuasTable createAlias(String alias) {
    return $DuasTable(attachedDatabase, alias);
  }
}

class DuaRow extends DataClass implements Insertable<DuaRow> {
  final String id;
  final String category;
  final String? title;
  final String textAr;
  final String? translit;
  final int repeatCount;
  final String timeOfDay;
  final String sourceRef;
  final String sourceId;
  final String? reviewedBy;
  final String? reviewedAt;
  const DuaRow({
    required this.id,
    required this.category,
    this.title,
    required this.textAr,
    this.translit,
    required this.repeatCount,
    required this.timeOfDay,
    required this.sourceRef,
    required this.sourceId,
    this.reviewedBy,
    this.reviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['text_ar'] = Variable<String>(textAr);
    if (!nullToAbsent || translit != null) {
      map['translit'] = Variable<String>(translit);
    }
    map['repeat_count'] = Variable<int>(repeatCount);
    map['time_of_day'] = Variable<String>(timeOfDay);
    map['source_ref'] = Variable<String>(sourceRef);
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || reviewedBy != null) {
      map['reviewed_by'] = Variable<String>(reviewedBy);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<String>(reviewedAt);
    }
    return map;
  }

  DuasCompanion toCompanion(bool nullToAbsent) {
    return DuasCompanion(
      id: Value(id),
      category: Value(category),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      textAr: Value(textAr),
      translit: translit == null && nullToAbsent
          ? const Value.absent()
          : Value(translit),
      repeatCount: Value(repeatCount),
      timeOfDay: Value(timeOfDay),
      sourceRef: Value(sourceRef),
      sourceId: Value(sourceId),
      reviewedBy: reviewedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedBy),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
    );
  }

  factory DuaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuaRow(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String?>(json['title']),
      textAr: serializer.fromJson<String>(json['textAr']),
      translit: serializer.fromJson<String?>(json['translit']),
      repeatCount: serializer.fromJson<int>(json['repeatCount']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      reviewedBy: serializer.fromJson<String?>(json['reviewedBy']),
      reviewedAt: serializer.fromJson<String?>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String?>(title),
      'textAr': serializer.toJson<String>(textAr),
      'translit': serializer.toJson<String?>(translit),
      'repeatCount': serializer.toJson<int>(repeatCount),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'sourceRef': serializer.toJson<String>(sourceRef),
      'sourceId': serializer.toJson<String>(sourceId),
      'reviewedBy': serializer.toJson<String?>(reviewedBy),
      'reviewedAt': serializer.toJson<String?>(reviewedAt),
    };
  }

  DuaRow copyWith({
    String? id,
    String? category,
    Value<String?> title = const Value.absent(),
    String? textAr,
    Value<String?> translit = const Value.absent(),
    int? repeatCount,
    String? timeOfDay,
    String? sourceRef,
    String? sourceId,
    Value<String?> reviewedBy = const Value.absent(),
    Value<String?> reviewedAt = const Value.absent(),
  }) => DuaRow(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title.present ? title.value : this.title,
    textAr: textAr ?? this.textAr,
    translit: translit.present ? translit.value : this.translit,
    repeatCount: repeatCount ?? this.repeatCount,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    sourceRef: sourceRef ?? this.sourceRef,
    sourceId: sourceId ?? this.sourceId,
    reviewedBy: reviewedBy.present ? reviewedBy.value : this.reviewedBy,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
  );
  DuaRow copyWithCompanion(DuasCompanion data) {
    return DuaRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      textAr: data.textAr.present ? data.textAr.value : this.textAr,
      translit: data.translit.present ? data.translit.value : this.translit,
      repeatCount: data.repeatCount.present
          ? data.repeatCount.value
          : this.repeatCount,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
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
    return (StringBuffer('DuaRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('repeatCount: $repeatCount, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sourceId: $sourceId, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    title,
    textAr,
    translit,
    repeatCount,
    timeOfDay,
    sourceRef,
    sourceId,
    reviewedBy,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuaRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.title == this.title &&
          other.textAr == this.textAr &&
          other.translit == this.translit &&
          other.repeatCount == this.repeatCount &&
          other.timeOfDay == this.timeOfDay &&
          other.sourceRef == this.sourceRef &&
          other.sourceId == this.sourceId &&
          other.reviewedBy == this.reviewedBy &&
          other.reviewedAt == this.reviewedAt);
}

class DuasCompanion extends UpdateCompanion<DuaRow> {
  final Value<String> id;
  final Value<String> category;
  final Value<String?> title;
  final Value<String> textAr;
  final Value<String?> translit;
  final Value<int> repeatCount;
  final Value<String> timeOfDay;
  final Value<String> sourceRef;
  final Value<String> sourceId;
  final Value<String?> reviewedBy;
  final Value<String?> reviewedAt;
  final Value<int> rowid;
  const DuasCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.textAr = const Value.absent(),
    this.translit = const Value.absent(),
    this.repeatCount = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuasCompanion.insert({
    required String id,
    required String category,
    this.title = const Value.absent(),
    required String textAr,
    this.translit = const Value.absent(),
    this.repeatCount = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    required String sourceRef,
    required String sourceId,
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       textAr = Value(textAr),
       sourceRef = Value(sourceRef),
       sourceId = Value(sourceId);
  static Insertable<DuaRow> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? textAr,
    Expression<String>? translit,
    Expression<int>? repeatCount,
    Expression<String>? timeOfDay,
    Expression<String>? sourceRef,
    Expression<String>? sourceId,
    Expression<String>? reviewedBy,
    Expression<String>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (textAr != null) 'text_ar': textAr,
      if (translit != null) 'translit': translit,
      if (repeatCount != null) 'repeat_count': repeatCount,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (sourceId != null) 'source_id': sourceId,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuasCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String?>? title,
    Value<String>? textAr,
    Value<String?>? translit,
    Value<int>? repeatCount,
    Value<String>? timeOfDay,
    Value<String>? sourceRef,
    Value<String>? sourceId,
    Value<String?>? reviewedBy,
    Value<String?>? reviewedAt,
    Value<int>? rowid,
  }) {
    return DuasCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      textAr: textAr ?? this.textAr,
      translit: translit ?? this.translit,
      repeatCount: repeatCount ?? this.repeatCount,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      sourceRef: sourceRef ?? this.sourceRef,
      sourceId: sourceId ?? this.sourceId,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (textAr.present) {
      map['text_ar'] = Variable<String>(textAr.value);
    }
    if (translit.present) {
      map['translit'] = Variable<String>(translit.value);
    }
    if (repeatCount.present) {
      map['repeat_count'] = Variable<int>(repeatCount.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
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
    return (StringBuffer('DuasCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('repeatCount: $repeatCount, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('sourceId: $sourceId, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuaTextsTable extends DuaTexts
    with TableInfo<$DuaTextsTable, DuaTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuaTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> duaId = GeneratedColumn<String>(
    'dua_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dua (id)',
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
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [duaId, lang, textContent, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dua_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {duaId, lang};
  @override
  DuaTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuaTextRow(
      duaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dua_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $DuaTextsTable createAlias(String alias) {
    return $DuaTextsTable(attachedDatabase, alias);
  }
}

class DuaTextRow extends DataClass implements Insertable<DuaTextRow> {
  final String duaId;
  final String lang;
  final String textContent;
  final String sourceId;
  const DuaTextRow({
    required this.duaId,
    required this.lang,
    required this.textContent,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dua_id'] = Variable<String>(duaId);
    map['lang'] = Variable<String>(lang);
    map['text'] = Variable<String>(textContent);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  DuaTextsCompanion toCompanion(bool nullToAbsent) {
    return DuaTextsCompanion(
      duaId: Value(duaId),
      lang: Value(lang),
      textContent: Value(textContent),
      sourceId: Value(sourceId),
    );
  }

  factory DuaTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuaTextRow(
      duaId: serializer.fromJson<String>(json['duaId']),
      lang: serializer.fromJson<String>(json['lang']),
      textContent: serializer.fromJson<String>(json['textContent']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'duaId': serializer.toJson<String>(duaId),
      'lang': serializer.toJson<String>(lang),
      'textContent': serializer.toJson<String>(textContent),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  DuaTextRow copyWith({
    String? duaId,
    String? lang,
    String? textContent,
    String? sourceId,
  }) => DuaTextRow(
    duaId: duaId ?? this.duaId,
    lang: lang ?? this.lang,
    textContent: textContent ?? this.textContent,
    sourceId: sourceId ?? this.sourceId,
  );
  DuaTextRow copyWithCompanion(DuaTextsCompanion data) {
    return DuaTextRow(
      duaId: data.duaId.present ? data.duaId.value : this.duaId,
      lang: data.lang.present ? data.lang.value : this.lang,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuaTextRow(')
          ..write('duaId: $duaId, ')
          ..write('lang: $lang, ')
          ..write('textContent: $textContent, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(duaId, lang, textContent, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuaTextRow &&
          other.duaId == this.duaId &&
          other.lang == this.lang &&
          other.textContent == this.textContent &&
          other.sourceId == this.sourceId);
}

class DuaTextsCompanion extends UpdateCompanion<DuaTextRow> {
  final Value<String> duaId;
  final Value<String> lang;
  final Value<String> textContent;
  final Value<String> sourceId;
  final Value<int> rowid;
  const DuaTextsCompanion({
    this.duaId = const Value.absent(),
    this.lang = const Value.absent(),
    this.textContent = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuaTextsCompanion.insert({
    required String duaId,
    required String lang,
    required String textContent,
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : duaId = Value(duaId),
       lang = Value(lang),
       textContent = Value(textContent),
       sourceId = Value(sourceId);
  static Insertable<DuaTextRow> custom({
    Expression<String>? duaId,
    Expression<String>? lang,
    Expression<String>? textContent,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (duaId != null) 'dua_id': duaId,
      if (lang != null) 'lang': lang,
      if (textContent != null) 'text': textContent,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuaTextsCompanion copyWith({
    Value<String>? duaId,
    Value<String>? lang,
    Value<String>? textContent,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return DuaTextsCompanion(
      duaId: duaId ?? this.duaId,
      lang: lang ?? this.lang,
      textContent: textContent ?? this.textContent,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (duaId.present) {
      map['dua_id'] = Variable<String>(duaId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
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
    return (StringBuffer('DuaTextsCompanion(')
          ..write('duaId: $duaId, ')
          ..write('lang: $lang, ')
          ..write('textContent: $textContent, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NamesOfAllahTable extends NamesOfAllah
    with TableInfo<$NamesOfAllahTable, NameOfAllahRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NamesOfAllahTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> textAr = GeneratedColumn<String>(
    'text_ar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> translit = GeneratedColumn<String>(
    'translit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> refAyahId = GeneratedColumn<int>(
    'ref_ayah_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ayah (id)',
    ),
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
    textAr,
    translit,
    refAyahId,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'name_of_allah';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NameOfAllahRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NameOfAllahRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      textAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_ar'],
      )!,
      translit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translit'],
      ),
      refAyahId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ref_ayah_id'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $NamesOfAllahTable createAlias(String alias) {
    return $NamesOfAllahTable(attachedDatabase, alias);
  }
}

class NameOfAllahRow extends DataClass implements Insertable<NameOfAllahRow> {
  final int id;
  final String textAr;
  final String? translit;
  final int? refAyahId;
  final String sourceId;
  const NameOfAllahRow({
    required this.id,
    required this.textAr,
    this.translit,
    this.refAyahId,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['text_ar'] = Variable<String>(textAr);
    if (!nullToAbsent || translit != null) {
      map['translit'] = Variable<String>(translit);
    }
    if (!nullToAbsent || refAyahId != null) {
      map['ref_ayah_id'] = Variable<int>(refAyahId);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  NamesOfAllahCompanion toCompanion(bool nullToAbsent) {
    return NamesOfAllahCompanion(
      id: Value(id),
      textAr: Value(textAr),
      translit: translit == null && nullToAbsent
          ? const Value.absent()
          : Value(translit),
      refAyahId: refAyahId == null && nullToAbsent
          ? const Value.absent()
          : Value(refAyahId),
      sourceId: Value(sourceId),
    );
  }

  factory NameOfAllahRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NameOfAllahRow(
      id: serializer.fromJson<int>(json['id']),
      textAr: serializer.fromJson<String>(json['textAr']),
      translit: serializer.fromJson<String?>(json['translit']),
      refAyahId: serializer.fromJson<int?>(json['refAyahId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'textAr': serializer.toJson<String>(textAr),
      'translit': serializer.toJson<String?>(translit),
      'refAyahId': serializer.toJson<int?>(refAyahId),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  NameOfAllahRow copyWith({
    int? id,
    String? textAr,
    Value<String?> translit = const Value.absent(),
    Value<int?> refAyahId = const Value.absent(),
    String? sourceId,
  }) => NameOfAllahRow(
    id: id ?? this.id,
    textAr: textAr ?? this.textAr,
    translit: translit.present ? translit.value : this.translit,
    refAyahId: refAyahId.present ? refAyahId.value : this.refAyahId,
    sourceId: sourceId ?? this.sourceId,
  );
  NameOfAllahRow copyWithCompanion(NamesOfAllahCompanion data) {
    return NameOfAllahRow(
      id: data.id.present ? data.id.value : this.id,
      textAr: data.textAr.present ? data.textAr.value : this.textAr,
      translit: data.translit.present ? data.translit.value : this.translit,
      refAyahId: data.refAyahId.present ? data.refAyahId.value : this.refAyahId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NameOfAllahRow(')
          ..write('id: $id, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('refAyahId: $refAyahId, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, textAr, translit, refAyahId, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NameOfAllahRow &&
          other.id == this.id &&
          other.textAr == this.textAr &&
          other.translit == this.translit &&
          other.refAyahId == this.refAyahId &&
          other.sourceId == this.sourceId);
}

class NamesOfAllahCompanion extends UpdateCompanion<NameOfAllahRow> {
  final Value<int> id;
  final Value<String> textAr;
  final Value<String?> translit;
  final Value<int?> refAyahId;
  final Value<String> sourceId;
  const NamesOfAllahCompanion({
    this.id = const Value.absent(),
    this.textAr = const Value.absent(),
    this.translit = const Value.absent(),
    this.refAyahId = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  NamesOfAllahCompanion.insert({
    this.id = const Value.absent(),
    required String textAr,
    this.translit = const Value.absent(),
    this.refAyahId = const Value.absent(),
    required String sourceId,
  }) : textAr = Value(textAr),
       sourceId = Value(sourceId);
  static Insertable<NameOfAllahRow> custom({
    Expression<int>? id,
    Expression<String>? textAr,
    Expression<String>? translit,
    Expression<int>? refAyahId,
    Expression<String>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (textAr != null) 'text_ar': textAr,
      if (translit != null) 'translit': translit,
      if (refAyahId != null) 'ref_ayah_id': refAyahId,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  NamesOfAllahCompanion copyWith({
    Value<int>? id,
    Value<String>? textAr,
    Value<String?>? translit,
    Value<int?>? refAyahId,
    Value<String>? sourceId,
  }) {
    return NamesOfAllahCompanion(
      id: id ?? this.id,
      textAr: textAr ?? this.textAr,
      translit: translit ?? this.translit,
      refAyahId: refAyahId ?? this.refAyahId,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (textAr.present) {
      map['text_ar'] = Variable<String>(textAr.value);
    }
    if (translit.present) {
      map['translit'] = Variable<String>(translit.value);
    }
    if (refAyahId.present) {
      map['ref_ayah_id'] = Variable<int>(refAyahId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NamesOfAllahCompanion(')
          ..write('id: $id, ')
          ..write('textAr: $textAr, ')
          ..write('translit: $translit, ')
          ..write('refAyahId: $refAyahId, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

class $NameTextsTable extends NameTexts
    with TableInfo<$NameTextsTable, NameTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NameTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> nameId = GeneratedColumn<int>(
    'name_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES name_of_allah (id)',
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
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> shortNote = GeneratedColumn<String>(
    'short_note',
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
    nameId,
    lang,
    meaning,
    shortNote,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'name_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {nameId, lang};
  @override
  NameTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NameTextRow(
      nameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}name_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      shortNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_note'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $NameTextsTable createAlias(String alias) {
    return $NameTextsTable(attachedDatabase, alias);
  }
}

class NameTextRow extends DataClass implements Insertable<NameTextRow> {
  final int nameId;
  final String lang;
  final String meaning;
  final String? shortNote;
  final String sourceId;
  const NameTextRow({
    required this.nameId,
    required this.lang,
    required this.meaning,
    this.shortNote,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name_id'] = Variable<int>(nameId);
    map['lang'] = Variable<String>(lang);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || shortNote != null) {
      map['short_note'] = Variable<String>(shortNote);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  NameTextsCompanion toCompanion(bool nullToAbsent) {
    return NameTextsCompanion(
      nameId: Value(nameId),
      lang: Value(lang),
      meaning: Value(meaning),
      shortNote: shortNote == null && nullToAbsent
          ? const Value.absent()
          : Value(shortNote),
      sourceId: Value(sourceId),
    );
  }

  factory NameTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NameTextRow(
      nameId: serializer.fromJson<int>(json['nameId']),
      lang: serializer.fromJson<String>(json['lang']),
      meaning: serializer.fromJson<String>(json['meaning']),
      shortNote: serializer.fromJson<String?>(json['shortNote']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nameId': serializer.toJson<int>(nameId),
      'lang': serializer.toJson<String>(lang),
      'meaning': serializer.toJson<String>(meaning),
      'shortNote': serializer.toJson<String?>(shortNote),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  NameTextRow copyWith({
    int? nameId,
    String? lang,
    String? meaning,
    Value<String?> shortNote = const Value.absent(),
    String? sourceId,
  }) => NameTextRow(
    nameId: nameId ?? this.nameId,
    lang: lang ?? this.lang,
    meaning: meaning ?? this.meaning,
    shortNote: shortNote.present ? shortNote.value : this.shortNote,
    sourceId: sourceId ?? this.sourceId,
  );
  NameTextRow copyWithCompanion(NameTextsCompanion data) {
    return NameTextRow(
      nameId: data.nameId.present ? data.nameId.value : this.nameId,
      lang: data.lang.present ? data.lang.value : this.lang,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      shortNote: data.shortNote.present ? data.shortNote.value : this.shortNote,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NameTextRow(')
          ..write('nameId: $nameId, ')
          ..write('lang: $lang, ')
          ..write('meaning: $meaning, ')
          ..write('shortNote: $shortNote, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(nameId, lang, meaning, shortNote, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NameTextRow &&
          other.nameId == this.nameId &&
          other.lang == this.lang &&
          other.meaning == this.meaning &&
          other.shortNote == this.shortNote &&
          other.sourceId == this.sourceId);
}

class NameTextsCompanion extends UpdateCompanion<NameTextRow> {
  final Value<int> nameId;
  final Value<String> lang;
  final Value<String> meaning;
  final Value<String?> shortNote;
  final Value<String> sourceId;
  final Value<int> rowid;
  const NameTextsCompanion({
    this.nameId = const Value.absent(),
    this.lang = const Value.absent(),
    this.meaning = const Value.absent(),
    this.shortNote = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NameTextsCompanion.insert({
    required int nameId,
    required String lang,
    required String meaning,
    this.shortNote = const Value.absent(),
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : nameId = Value(nameId),
       lang = Value(lang),
       meaning = Value(meaning),
       sourceId = Value(sourceId);
  static Insertable<NameTextRow> custom({
    Expression<int>? nameId,
    Expression<String>? lang,
    Expression<String>? meaning,
    Expression<String>? shortNote,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nameId != null) 'name_id': nameId,
      if (lang != null) 'lang': lang,
      if (meaning != null) 'meaning': meaning,
      if (shortNote != null) 'short_note': shortNote,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NameTextsCompanion copyWith({
    Value<int>? nameId,
    Value<String>? lang,
    Value<String>? meaning,
    Value<String?>? shortNote,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return NameTextsCompanion(
      nameId: nameId ?? this.nameId,
      lang: lang ?? this.lang,
      meaning: meaning ?? this.meaning,
      shortNote: shortNote ?? this.shortNote,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nameId.present) {
      map['name_id'] = Variable<int>(nameId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (shortNote.present) {
      map['short_note'] = Variable<String>(shortNote.value);
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
    return (StringBuffer('NameTextsCompanion(')
          ..write('nameId: $nameId, ')
          ..write('lang: $lang, ')
          ..write('meaning: $meaning, ')
          ..write('shortNote: $shortNote, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReflectionsTable extends Reflections
    with TableInfo<$ReflectionsTable, ReflectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> anchorJson = GeneratedColumn<String>(
    'anchor_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> season = GeneratedColumn<String>(
    'season',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    tags,
    facetsJson,
    anchorJson,
    season,
    reviewedBy,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflection';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReflectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReflectionRow(
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
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      facetsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facets_json'],
      ),
      anchorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_json'],
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season'],
      ),
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
  $ReflectionsTable createAlias(String alias) {
    return $ReflectionsTable(attachedDatabase, alias);
  }
}

class ReflectionRow extends DataClass implements Insertable<ReflectionRow> {
  final String id;
  final int version;
  final String status;
  final String origin;
  final String tags;
  final String? facetsJson;
  final String? anchorJson;
  final String? season;
  final String? reviewedBy;
  final String? reviewedAt;
  const ReflectionRow({
    required this.id,
    required this.version,
    required this.status,
    required this.origin,
    required this.tags,
    this.facetsJson,
    this.anchorJson,
    this.season,
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
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || facetsJson != null) {
      map['facets_json'] = Variable<String>(facetsJson);
    }
    if (!nullToAbsent || anchorJson != null) {
      map['anchor_json'] = Variable<String>(anchorJson);
    }
    if (!nullToAbsent || season != null) {
      map['season'] = Variable<String>(season);
    }
    if (!nullToAbsent || reviewedBy != null) {
      map['reviewed_by'] = Variable<String>(reviewedBy);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<String>(reviewedAt);
    }
    return map;
  }

  ReflectionsCompanion toCompanion(bool nullToAbsent) {
    return ReflectionsCompanion(
      id: Value(id),
      version: Value(version),
      status: Value(status),
      origin: Value(origin),
      tags: Value(tags),
      facetsJson: facetsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(facetsJson),
      anchorJson: anchorJson == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorJson),
      season: season == null && nullToAbsent
          ? const Value.absent()
          : Value(season),
      reviewedBy: reviewedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedBy),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
    );
  }

  factory ReflectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReflectionRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      origin: serializer.fromJson<String>(json['origin']),
      tags: serializer.fromJson<String>(json['tags']),
      facetsJson: serializer.fromJson<String?>(json['facetsJson']),
      anchorJson: serializer.fromJson<String?>(json['anchorJson']),
      season: serializer.fromJson<String?>(json['season']),
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
      'tags': serializer.toJson<String>(tags),
      'facetsJson': serializer.toJson<String?>(facetsJson),
      'anchorJson': serializer.toJson<String?>(anchorJson),
      'season': serializer.toJson<String?>(season),
      'reviewedBy': serializer.toJson<String?>(reviewedBy),
      'reviewedAt': serializer.toJson<String?>(reviewedAt),
    };
  }

  ReflectionRow copyWith({
    String? id,
    int? version,
    String? status,
    String? origin,
    String? tags,
    Value<String?> facetsJson = const Value.absent(),
    Value<String?> anchorJson = const Value.absent(),
    Value<String?> season = const Value.absent(),
    Value<String?> reviewedBy = const Value.absent(),
    Value<String?> reviewedAt = const Value.absent(),
  }) => ReflectionRow(
    id: id ?? this.id,
    version: version ?? this.version,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    tags: tags ?? this.tags,
    facetsJson: facetsJson.present ? facetsJson.value : this.facetsJson,
    anchorJson: anchorJson.present ? anchorJson.value : this.anchorJson,
    season: season.present ? season.value : this.season,
    reviewedBy: reviewedBy.present ? reviewedBy.value : this.reviewedBy,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
  );
  ReflectionRow copyWithCompanion(ReflectionsCompanion data) {
    return ReflectionRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      origin: data.origin.present ? data.origin.value : this.origin,
      tags: data.tags.present ? data.tags.value : this.tags,
      facetsJson: data.facetsJson.present
          ? data.facetsJson.value
          : this.facetsJson,
      anchorJson: data.anchorJson.present
          ? data.anchorJson.value
          : this.anchorJson,
      season: data.season.present ? data.season.value : this.season,
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
    return (StringBuffer('ReflectionRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('tags: $tags, ')
          ..write('facetsJson: $facetsJson, ')
          ..write('anchorJson: $anchorJson, ')
          ..write('season: $season, ')
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
    tags,
    facetsJson,
    anchorJson,
    season,
    reviewedBy,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReflectionRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.status == this.status &&
          other.origin == this.origin &&
          other.tags == this.tags &&
          other.facetsJson == this.facetsJson &&
          other.anchorJson == this.anchorJson &&
          other.season == this.season &&
          other.reviewedBy == this.reviewedBy &&
          other.reviewedAt == this.reviewedAt);
}

class ReflectionsCompanion extends UpdateCompanion<ReflectionRow> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> status;
  final Value<String> origin;
  final Value<String> tags;
  final Value<String?> facetsJson;
  final Value<String?> anchorJson;
  final Value<String?> season;
  final Value<String?> reviewedBy;
  final Value<String?> reviewedAt;
  final Value<int> rowid;
  const ReflectionsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.origin = const Value.absent(),
    this.tags = const Value.absent(),
    this.facetsJson = const Value.absent(),
    this.anchorJson = const Value.absent(),
    this.season = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReflectionsCompanion.insert({
    required String id,
    this.version = const Value.absent(),
    required String status,
    required String origin,
    required String tags,
    this.facetsJson = const Value.absent(),
    this.anchorJson = const Value.absent(),
    this.season = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       origin = Value(origin),
       tags = Value(tags);
  static Insertable<ReflectionRow> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? status,
    Expression<String>? origin,
    Expression<String>? tags,
    Expression<String>? facetsJson,
    Expression<String>? anchorJson,
    Expression<String>? season,
    Expression<String>? reviewedBy,
    Expression<String>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (origin != null) 'origin': origin,
      if (tags != null) 'tags': tags,
      if (facetsJson != null) 'facets_json': facetsJson,
      if (anchorJson != null) 'anchor_json': anchorJson,
      if (season != null) 'season': season,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReflectionsCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? status,
    Value<String>? origin,
    Value<String>? tags,
    Value<String?>? facetsJson,
    Value<String?>? anchorJson,
    Value<String?>? season,
    Value<String?>? reviewedBy,
    Value<String?>? reviewedAt,
    Value<int>? rowid,
  }) {
    return ReflectionsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      tags: tags ?? this.tags,
      facetsJson: facetsJson ?? this.facetsJson,
      anchorJson: anchorJson ?? this.anchorJson,
      season: season ?? this.season,
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
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (facetsJson.present) {
      map['facets_json'] = Variable<String>(facetsJson.value);
    }
    if (anchorJson.present) {
      map['anchor_json'] = Variable<String>(anchorJson.value);
    }
    if (season.present) {
      map['season'] = Variable<String>(season.value);
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
    return (StringBuffer('ReflectionsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('tags: $tags, ')
          ..write('facetsJson: $facetsJson, ')
          ..write('anchorJson: $anchorJson, ')
          ..write('season: $season, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReflectionTextsTable extends ReflectionTexts
    with TableInfo<$ReflectionTextsTable, ReflectionTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReflectionTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> reflectionId = GeneratedColumn<String>(
    'reflection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reflection (id)',
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
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
    'question',
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
    reflectionId,
    lang,
    textContent,
    question,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reflection_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {reflectionId, lang};
  @override
  ReflectionTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReflectionTextRow(
      reflectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reflection_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      question: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $ReflectionTextsTable createAlias(String alias) {
    return $ReflectionTextsTable(attachedDatabase, alias);
  }
}

class ReflectionTextRow extends DataClass
    implements Insertable<ReflectionTextRow> {
  final String reflectionId;
  final String lang;
  final String textContent;
  final String? question;
  final String sourceId;
  const ReflectionTextRow({
    required this.reflectionId,
    required this.lang,
    required this.textContent,
    this.question,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reflection_id'] = Variable<String>(reflectionId);
    map['lang'] = Variable<String>(lang);
    map['text'] = Variable<String>(textContent);
    if (!nullToAbsent || question != null) {
      map['question'] = Variable<String>(question);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  ReflectionTextsCompanion toCompanion(bool nullToAbsent) {
    return ReflectionTextsCompanion(
      reflectionId: Value(reflectionId),
      lang: Value(lang),
      textContent: Value(textContent),
      question: question == null && nullToAbsent
          ? const Value.absent()
          : Value(question),
      sourceId: Value(sourceId),
    );
  }

  factory ReflectionTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReflectionTextRow(
      reflectionId: serializer.fromJson<String>(json['reflectionId']),
      lang: serializer.fromJson<String>(json['lang']),
      textContent: serializer.fromJson<String>(json['textContent']),
      question: serializer.fromJson<String?>(json['question']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reflectionId': serializer.toJson<String>(reflectionId),
      'lang': serializer.toJson<String>(lang),
      'textContent': serializer.toJson<String>(textContent),
      'question': serializer.toJson<String?>(question),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  ReflectionTextRow copyWith({
    String? reflectionId,
    String? lang,
    String? textContent,
    Value<String?> question = const Value.absent(),
    String? sourceId,
  }) => ReflectionTextRow(
    reflectionId: reflectionId ?? this.reflectionId,
    lang: lang ?? this.lang,
    textContent: textContent ?? this.textContent,
    question: question.present ? question.value : this.question,
    sourceId: sourceId ?? this.sourceId,
  );
  ReflectionTextRow copyWithCompanion(ReflectionTextsCompanion data) {
    return ReflectionTextRow(
      reflectionId: data.reflectionId.present
          ? data.reflectionId.value
          : this.reflectionId,
      lang: data.lang.present ? data.lang.value : this.lang,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      question: data.question.present ? data.question.value : this.question,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReflectionTextRow(')
          ..write('reflectionId: $reflectionId, ')
          ..write('lang: $lang, ')
          ..write('textContent: $textContent, ')
          ..write('question: $question, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(reflectionId, lang, textContent, question, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReflectionTextRow &&
          other.reflectionId == this.reflectionId &&
          other.lang == this.lang &&
          other.textContent == this.textContent &&
          other.question == this.question &&
          other.sourceId == this.sourceId);
}

class ReflectionTextsCompanion extends UpdateCompanion<ReflectionTextRow> {
  final Value<String> reflectionId;
  final Value<String> lang;
  final Value<String> textContent;
  final Value<String?> question;
  final Value<String> sourceId;
  final Value<int> rowid;
  const ReflectionTextsCompanion({
    this.reflectionId = const Value.absent(),
    this.lang = const Value.absent(),
    this.textContent = const Value.absent(),
    this.question = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReflectionTextsCompanion.insert({
    required String reflectionId,
    required String lang,
    required String textContent,
    this.question = const Value.absent(),
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : reflectionId = Value(reflectionId),
       lang = Value(lang),
       textContent = Value(textContent),
       sourceId = Value(sourceId);
  static Insertable<ReflectionTextRow> custom({
    Expression<String>? reflectionId,
    Expression<String>? lang,
    Expression<String>? textContent,
    Expression<String>? question,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reflectionId != null) 'reflection_id': reflectionId,
      if (lang != null) 'lang': lang,
      if (textContent != null) 'text': textContent,
      if (question != null) 'question': question,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReflectionTextsCompanion copyWith({
    Value<String>? reflectionId,
    Value<String>? lang,
    Value<String>? textContent,
    Value<String?>? question,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return ReflectionTextsCompanion(
      reflectionId: reflectionId ?? this.reflectionId,
      lang: lang ?? this.lang,
      textContent: textContent ?? this.textContent,
      question: question ?? this.question,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reflectionId.present) {
      map['reflection_id'] = Variable<String>(reflectionId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
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
    return (StringBuffer('ReflectionTextsCompanion(')
          ..write('reflectionId: $reflectionId, ')
          ..write('lang: $lang, ')
          ..write('textContent: $textContent, ')
          ..write('question: $question, ')
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
  late final GeneratedColumn<String> evidenceJson = GeneratedColumn<String>(
    'evidence_json',
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
    evidenceJson,
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
      evidenceJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_json'],
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
  final String? evidenceJson;
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
    this.evidenceJson,
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
    if (!nullToAbsent || evidenceJson != null) {
      map['evidence_json'] = Variable<String>(evidenceJson);
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
      evidenceJson: evidenceJson == null && nullToAbsent
          ? const Value.absent()
          : Value(evidenceJson),
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
      evidenceJson: serializer.fromJson<String?>(json['evidenceJson']),
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
      'evidenceJson': serializer.toJson<String?>(evidenceJson),
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
    Value<String?> evidenceJson = const Value.absent(),
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
    evidenceJson: evidenceJson.present ? evidenceJson.value : this.evidenceJson,
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
      evidenceJson: data.evidenceJson.present
          ? data.evidenceJson.value
          : this.evidenceJson,
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
          ..write('evidenceJson: $evidenceJson, ')
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
    evidenceJson,
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
          other.evidenceJson == this.evidenceJson &&
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
  final Value<String?> evidenceJson;
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
    this.evidenceJson = const Value.absent(),
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
    this.evidenceJson = const Value.absent(),
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
    Expression<String>? evidenceJson,
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
      if (evidenceJson != null) 'evidence_json': evidenceJson,
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
    Value<String?>? evidenceJson,
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
      evidenceJson: evidenceJson ?? this.evidenceJson,
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
    if (evidenceJson.present) {
      map['evidence_json'] = Variable<String>(evidenceJson.value);
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
          ..write('evidenceJson: $evidenceJson, ')
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

class $IslamicEventsTable extends IslamicEvents
    with TableInfo<$IslamicEventsTable, IslamicEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IslamicEventsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  late final GeneratedColumn<String> questOverridesJson =
      GeneratedColumn<String>(
        'quest_overrides_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumn<String> cardOverridesJson =
      GeneratedColumn<String>(
        'card_overrides_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumn<String> testsJson = GeneratedColumn<String>(
    'tests_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    category,
    priority,
    ruleJson,
    questOverridesJson,
    cardOverridesJson,
    testsJson,
    reviewedBy,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'islamic_event';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IslamicEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IslamicEventRow(
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
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      ruleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_json'],
      )!,
      questOverridesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quest_overrides_json'],
      ),
      cardOverridesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_overrides_json'],
      ),
      testsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tests_json'],
      ),
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
  $IslamicEventsTable createAlias(String alias) {
    return $IslamicEventsTable(attachedDatabase, alias);
  }
}

class IslamicEventRow extends DataClass implements Insertable<IslamicEventRow> {
  final String id;
  final int version;
  final String status;
  final String origin;
  final String category;
  final int priority;
  final String ruleJson;
  final String? questOverridesJson;
  final String? cardOverridesJson;
  final String? testsJson;
  final String? reviewedBy;
  final String? reviewedAt;
  const IslamicEventRow({
    required this.id,
    required this.version,
    required this.status,
    required this.origin,
    required this.category,
    required this.priority,
    required this.ruleJson,
    this.questOverridesJson,
    this.cardOverridesJson,
    this.testsJson,
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
    map['category'] = Variable<String>(category);
    map['priority'] = Variable<int>(priority);
    map['rule_json'] = Variable<String>(ruleJson);
    if (!nullToAbsent || questOverridesJson != null) {
      map['quest_overrides_json'] = Variable<String>(questOverridesJson);
    }
    if (!nullToAbsent || cardOverridesJson != null) {
      map['card_overrides_json'] = Variable<String>(cardOverridesJson);
    }
    if (!nullToAbsent || testsJson != null) {
      map['tests_json'] = Variable<String>(testsJson);
    }
    if (!nullToAbsent || reviewedBy != null) {
      map['reviewed_by'] = Variable<String>(reviewedBy);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<String>(reviewedAt);
    }
    return map;
  }

  IslamicEventsCompanion toCompanion(bool nullToAbsent) {
    return IslamicEventsCompanion(
      id: Value(id),
      version: Value(version),
      status: Value(status),
      origin: Value(origin),
      category: Value(category),
      priority: Value(priority),
      ruleJson: Value(ruleJson),
      questOverridesJson: questOverridesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(questOverridesJson),
      cardOverridesJson: cardOverridesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(cardOverridesJson),
      testsJson: testsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(testsJson),
      reviewedBy: reviewedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedBy),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
    );
  }

  factory IslamicEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IslamicEventRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      origin: serializer.fromJson<String>(json['origin']),
      category: serializer.fromJson<String>(json['category']),
      priority: serializer.fromJson<int>(json['priority']),
      ruleJson: serializer.fromJson<String>(json['ruleJson']),
      questOverridesJson: serializer.fromJson<String?>(
        json['questOverridesJson'],
      ),
      cardOverridesJson: serializer.fromJson<String?>(
        json['cardOverridesJson'],
      ),
      testsJson: serializer.fromJson<String?>(json['testsJson']),
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
      'category': serializer.toJson<String>(category),
      'priority': serializer.toJson<int>(priority),
      'ruleJson': serializer.toJson<String>(ruleJson),
      'questOverridesJson': serializer.toJson<String?>(questOverridesJson),
      'cardOverridesJson': serializer.toJson<String?>(cardOverridesJson),
      'testsJson': serializer.toJson<String?>(testsJson),
      'reviewedBy': serializer.toJson<String?>(reviewedBy),
      'reviewedAt': serializer.toJson<String?>(reviewedAt),
    };
  }

  IslamicEventRow copyWith({
    String? id,
    int? version,
    String? status,
    String? origin,
    String? category,
    int? priority,
    String? ruleJson,
    Value<String?> questOverridesJson = const Value.absent(),
    Value<String?> cardOverridesJson = const Value.absent(),
    Value<String?> testsJson = const Value.absent(),
    Value<String?> reviewedBy = const Value.absent(),
    Value<String?> reviewedAt = const Value.absent(),
  }) => IslamicEventRow(
    id: id ?? this.id,
    version: version ?? this.version,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    ruleJson: ruleJson ?? this.ruleJson,
    questOverridesJson: questOverridesJson.present
        ? questOverridesJson.value
        : this.questOverridesJson,
    cardOverridesJson: cardOverridesJson.present
        ? cardOverridesJson.value
        : this.cardOverridesJson,
    testsJson: testsJson.present ? testsJson.value : this.testsJson,
    reviewedBy: reviewedBy.present ? reviewedBy.value : this.reviewedBy,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
  );
  IslamicEventRow copyWithCompanion(IslamicEventsCompanion data) {
    return IslamicEventRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      origin: data.origin.present ? data.origin.value : this.origin,
      category: data.category.present ? data.category.value : this.category,
      priority: data.priority.present ? data.priority.value : this.priority,
      ruleJson: data.ruleJson.present ? data.ruleJson.value : this.ruleJson,
      questOverridesJson: data.questOverridesJson.present
          ? data.questOverridesJson.value
          : this.questOverridesJson,
      cardOverridesJson: data.cardOverridesJson.present
          ? data.cardOverridesJson.value
          : this.cardOverridesJson,
      testsJson: data.testsJson.present ? data.testsJson.value : this.testsJson,
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
    return (StringBuffer('IslamicEventRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('questOverridesJson: $questOverridesJson, ')
          ..write('cardOverridesJson: $cardOverridesJson, ')
          ..write('testsJson: $testsJson, ')
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
    category,
    priority,
    ruleJson,
    questOverridesJson,
    cardOverridesJson,
    testsJson,
    reviewedBy,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IslamicEventRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.status == this.status &&
          other.origin == this.origin &&
          other.category == this.category &&
          other.priority == this.priority &&
          other.ruleJson == this.ruleJson &&
          other.questOverridesJson == this.questOverridesJson &&
          other.cardOverridesJson == this.cardOverridesJson &&
          other.testsJson == this.testsJson &&
          other.reviewedBy == this.reviewedBy &&
          other.reviewedAt == this.reviewedAt);
}

class IslamicEventsCompanion extends UpdateCompanion<IslamicEventRow> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> status;
  final Value<String> origin;
  final Value<String> category;
  final Value<int> priority;
  final Value<String> ruleJson;
  final Value<String?> questOverridesJson;
  final Value<String?> cardOverridesJson;
  final Value<String?> testsJson;
  final Value<String?> reviewedBy;
  final Value<String?> reviewedAt;
  final Value<int> rowid;
  const IslamicEventsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.origin = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.ruleJson = const Value.absent(),
    this.questOverridesJson = const Value.absent(),
    this.cardOverridesJson = const Value.absent(),
    this.testsJson = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IslamicEventsCompanion.insert({
    required String id,
    this.version = const Value.absent(),
    required String status,
    required String origin,
    required String category,
    required int priority,
    required String ruleJson,
    this.questOverridesJson = const Value.absent(),
    this.cardOverridesJson = const Value.absent(),
    this.testsJson = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       origin = Value(origin),
       category = Value(category),
       priority = Value(priority),
       ruleJson = Value(ruleJson);
  static Insertable<IslamicEventRow> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? status,
    Expression<String>? origin,
    Expression<String>? category,
    Expression<int>? priority,
    Expression<String>? ruleJson,
    Expression<String>? questOverridesJson,
    Expression<String>? cardOverridesJson,
    Expression<String>? testsJson,
    Expression<String>? reviewedBy,
    Expression<String>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (origin != null) 'origin': origin,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (ruleJson != null) 'rule_json': ruleJson,
      if (questOverridesJson != null)
        'quest_overrides_json': questOverridesJson,
      if (cardOverridesJson != null) 'card_overrides_json': cardOverridesJson,
      if (testsJson != null) 'tests_json': testsJson,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IslamicEventsCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? status,
    Value<String>? origin,
    Value<String>? category,
    Value<int>? priority,
    Value<String>? ruleJson,
    Value<String?>? questOverridesJson,
    Value<String?>? cardOverridesJson,
    Value<String?>? testsJson,
    Value<String?>? reviewedBy,
    Value<String?>? reviewedAt,
    Value<int>? rowid,
  }) {
    return IslamicEventsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      ruleJson: ruleJson ?? this.ruleJson,
      questOverridesJson: questOverridesJson ?? this.questOverridesJson,
      cardOverridesJson: cardOverridesJson ?? this.cardOverridesJson,
      testsJson: testsJson ?? this.testsJson,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (ruleJson.present) {
      map['rule_json'] = Variable<String>(ruleJson.value);
    }
    if (questOverridesJson.present) {
      map['quest_overrides_json'] = Variable<String>(questOverridesJson.value);
    }
    if (cardOverridesJson.present) {
      map['card_overrides_json'] = Variable<String>(cardOverridesJson.value);
    }
    if (testsJson.present) {
      map['tests_json'] = Variable<String>(testsJson.value);
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
    return (StringBuffer('IslamicEventsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('questOverridesJson: $questOverridesJson, ')
          ..write('cardOverridesJson: $cardOverridesJson, ')
          ..write('testsJson: $testsJson, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IslamicEventTextsTable extends IslamicEventTexts
    with TableInfo<$IslamicEventTextsTable, IslamicEventTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IslamicEventTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES islamic_event (id)',
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
  List<GeneratedColumn> get $columns => [eventId, lang, title, body, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'islamic_event_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, lang};
  @override
  IslamicEventTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IslamicEventTextRow(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
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
  $IslamicEventTextsTable createAlias(String alias) {
    return $IslamicEventTextsTable(attachedDatabase, alias);
  }
}

class IslamicEventTextRow extends DataClass
    implements Insertable<IslamicEventTextRow> {
  final String eventId;
  final String lang;
  final String title;
  final String? body;
  final String sourceId;
  const IslamicEventTextRow({
    required this.eventId,
    required this.lang,
    required this.title,
    this.body,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['lang'] = Variable<String>(lang);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  IslamicEventTextsCompanion toCompanion(bool nullToAbsent) {
    return IslamicEventTextsCompanion(
      eventId: Value(eventId),
      lang: Value(lang),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      sourceId: Value(sourceId),
    );
  }

  factory IslamicEventTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IslamicEventTextRow(
      eventId: serializer.fromJson<String>(json['eventId']),
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
      'eventId': serializer.toJson<String>(eventId),
      'lang': serializer.toJson<String>(lang),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  IslamicEventTextRow copyWith({
    String? eventId,
    String? lang,
    String? title,
    Value<String?> body = const Value.absent(),
    String? sourceId,
  }) => IslamicEventTextRow(
    eventId: eventId ?? this.eventId,
    lang: lang ?? this.lang,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    sourceId: sourceId ?? this.sourceId,
  );
  IslamicEventTextRow copyWithCompanion(IslamicEventTextsCompanion data) {
    return IslamicEventTextRow(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      lang: data.lang.present ? data.lang.value : this.lang,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IslamicEventTextRow(')
          ..write('eventId: $eventId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, lang, title, body, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IslamicEventTextRow &&
          other.eventId == this.eventId &&
          other.lang == this.lang &&
          other.title == this.title &&
          other.body == this.body &&
          other.sourceId == this.sourceId);
}

class IslamicEventTextsCompanion extends UpdateCompanion<IslamicEventTextRow> {
  final Value<String> eventId;
  final Value<String> lang;
  final Value<String> title;
  final Value<String?> body;
  final Value<String> sourceId;
  final Value<int> rowid;
  const IslamicEventTextsCompanion({
    this.eventId = const Value.absent(),
    this.lang = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IslamicEventTextsCompanion.insert({
    required String eventId,
    required String lang,
    required String title,
    this.body = const Value.absent(),
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       lang = Value(lang),
       title = Value(title),
       sourceId = Value(sourceId);
  static Insertable<IslamicEventTextRow> custom({
    Expression<String>? eventId,
    Expression<String>? lang,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (lang != null) 'lang': lang,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IslamicEventTextsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? lang,
    Value<String>? title,
    Value<String?>? body,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return IslamicEventTextsCompanion(
      eventId: eventId ?? this.eventId,
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
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
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
    return (StringBuffer('IslamicEventTextsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntroCardsTable extends IntroCards
    with TableInfo<$IntroCardsTable, IntroCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntroCardsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES islamic_event (id)',
    ),
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
    eventId,
    reviewedBy,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intro_card';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntroCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntroCardRow(
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
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      ),
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
  $IntroCardsTable createAlias(String alias) {
    return $IntroCardsTable(attachedDatabase, alias);
  }
}

class IntroCardRow extends DataClass implements Insertable<IntroCardRow> {
  final String id;
  final int version;
  final String status;
  final String origin;
  final String? eventId;
  final String? reviewedBy;
  final String? reviewedAt;
  const IntroCardRow({
    required this.id,
    required this.version,
    required this.status,
    required this.origin,
    this.eventId,
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
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || reviewedBy != null) {
      map['reviewed_by'] = Variable<String>(reviewedBy);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<String>(reviewedAt);
    }
    return map;
  }

  IntroCardsCompanion toCompanion(bool nullToAbsent) {
    return IntroCardsCompanion(
      id: Value(id),
      version: Value(version),
      status: Value(status),
      origin: Value(origin),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      reviewedBy: reviewedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedBy),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
    );
  }

  factory IntroCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntroCardRow(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      status: serializer.fromJson<String>(json['status']),
      origin: serializer.fromJson<String>(json['origin']),
      eventId: serializer.fromJson<String?>(json['eventId']),
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
      'eventId': serializer.toJson<String?>(eventId),
      'reviewedBy': serializer.toJson<String?>(reviewedBy),
      'reviewedAt': serializer.toJson<String?>(reviewedAt),
    };
  }

  IntroCardRow copyWith({
    String? id,
    int? version,
    String? status,
    String? origin,
    Value<String?> eventId = const Value.absent(),
    Value<String?> reviewedBy = const Value.absent(),
    Value<String?> reviewedAt = const Value.absent(),
  }) => IntroCardRow(
    id: id ?? this.id,
    version: version ?? this.version,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    eventId: eventId.present ? eventId.value : this.eventId,
    reviewedBy: reviewedBy.present ? reviewedBy.value : this.reviewedBy,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
  );
  IntroCardRow copyWithCompanion(IntroCardsCompanion data) {
    return IntroCardRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      origin: data.origin.present ? data.origin.value : this.origin,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
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
    return (StringBuffer('IntroCardRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('eventId: $eventId, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, version, status, origin, eventId, reviewedBy, reviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntroCardRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.status == this.status &&
          other.origin == this.origin &&
          other.eventId == this.eventId &&
          other.reviewedBy == this.reviewedBy &&
          other.reviewedAt == this.reviewedAt);
}

class IntroCardsCompanion extends UpdateCompanion<IntroCardRow> {
  final Value<String> id;
  final Value<int> version;
  final Value<String> status;
  final Value<String> origin;
  final Value<String?> eventId;
  final Value<String?> reviewedBy;
  final Value<String?> reviewedAt;
  final Value<int> rowid;
  const IntroCardsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.origin = const Value.absent(),
    this.eventId = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntroCardsCompanion.insert({
    required String id,
    this.version = const Value.absent(),
    required String status,
    required String origin,
    this.eventId = const Value.absent(),
    this.reviewedBy = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       origin = Value(origin);
  static Insertable<IntroCardRow> custom({
    Expression<String>? id,
    Expression<int>? version,
    Expression<String>? status,
    Expression<String>? origin,
    Expression<String>? eventId,
    Expression<String>? reviewedBy,
    Expression<String>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (origin != null) 'origin': origin,
      if (eventId != null) 'event_id': eventId,
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntroCardsCompanion copyWith({
    Value<String>? id,
    Value<int>? version,
    Value<String>? status,
    Value<String>? origin,
    Value<String?>? eventId,
    Value<String?>? reviewedBy,
    Value<String?>? reviewedAt,
    Value<int>? rowid,
  }) {
    return IntroCardsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      eventId: eventId ?? this.eventId,
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
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
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
    return (StringBuffer('IntroCardsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('eventId: $eventId, ')
          ..write('reviewedBy: $reviewedBy, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntroCardTextsTable extends IntroCardTexts
    with TableInfo<$IntroCardTextsTable, IntroCardTextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntroCardTextsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> introId = GeneratedColumn<String>(
    'intro_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES intro_card (id)',
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
  List<GeneratedColumn> get $columns => [introId, lang, title, body, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intro_card_text';
  @override
  Set<GeneratedColumn> get $primaryKey => {introId, lang};
  @override
  IntroCardTextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntroCardTextRow(
      introId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intro_id'],
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
  $IntroCardTextsTable createAlias(String alias) {
    return $IntroCardTextsTable(attachedDatabase, alias);
  }
}

class IntroCardTextRow extends DataClass
    implements Insertable<IntroCardTextRow> {
  final String introId;
  final String lang;
  final String title;
  final String? body;
  final String sourceId;
  const IntroCardTextRow({
    required this.introId,
    required this.lang,
    required this.title,
    this.body,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['intro_id'] = Variable<String>(introId);
    map['lang'] = Variable<String>(lang);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  IntroCardTextsCompanion toCompanion(bool nullToAbsent) {
    return IntroCardTextsCompanion(
      introId: Value(introId),
      lang: Value(lang),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      sourceId: Value(sourceId),
    );
  }

  factory IntroCardTextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntroCardTextRow(
      introId: serializer.fromJson<String>(json['introId']),
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
      'introId': serializer.toJson<String>(introId),
      'lang': serializer.toJson<String>(lang),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  IntroCardTextRow copyWith({
    String? introId,
    String? lang,
    String? title,
    Value<String?> body = const Value.absent(),
    String? sourceId,
  }) => IntroCardTextRow(
    introId: introId ?? this.introId,
    lang: lang ?? this.lang,
    title: title ?? this.title,
    body: body.present ? body.value : this.body,
    sourceId: sourceId ?? this.sourceId,
  );
  IntroCardTextRow copyWithCompanion(IntroCardTextsCompanion data) {
    return IntroCardTextRow(
      introId: data.introId.present ? data.introId.value : this.introId,
      lang: data.lang.present ? data.lang.value : this.lang,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntroCardTextRow(')
          ..write('introId: $introId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(introId, lang, title, body, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntroCardTextRow &&
          other.introId == this.introId &&
          other.lang == this.lang &&
          other.title == this.title &&
          other.body == this.body &&
          other.sourceId == this.sourceId);
}

class IntroCardTextsCompanion extends UpdateCompanion<IntroCardTextRow> {
  final Value<String> introId;
  final Value<String> lang;
  final Value<String> title;
  final Value<String?> body;
  final Value<String> sourceId;
  final Value<int> rowid;
  const IntroCardTextsCompanion({
    this.introId = const Value.absent(),
    this.lang = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntroCardTextsCompanion.insert({
    required String introId,
    required String lang,
    required String title,
    this.body = const Value.absent(),
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : introId = Value(introId),
       lang = Value(lang),
       title = Value(title),
       sourceId = Value(sourceId);
  static Insertable<IntroCardTextRow> custom({
    Expression<String>? introId,
    Expression<String>? lang,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (introId != null) 'intro_id': introId,
      if (lang != null) 'lang': lang,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntroCardTextsCompanion copyWith({
    Value<String>? introId,
    Value<String>? lang,
    Value<String>? title,
    Value<String?>? body,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return IntroCardTextsCompanion(
      introId: introId ?? this.introId,
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
    if (introId.present) {
      map['intro_id'] = Variable<String>(introId.value);
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
    return (StringBuffer('IntroCardTextsCompanion(')
          ..write('introId: $introId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CountriesTable extends Countries
    with TableInfo<$CountriesTable, CountryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountriesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> iso2 = GeneratedColumn<String>(
    'iso2',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [iso2, name, sourceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'country';
  @override
  Set<GeneratedColumn> get $primaryKey => {iso2};
  @override
  CountryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CountryRow(
      iso2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iso2'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $CountriesTable createAlias(String alias) {
    return $CountriesTable(attachedDatabase, alias);
  }
}

class CountryRow extends DataClass implements Insertable<CountryRow> {
  final String iso2;
  final String name;
  final String sourceId;
  const CountryRow({
    required this.iso2,
    required this.name,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['iso2'] = Variable<String>(iso2);
    map['name'] = Variable<String>(name);
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  CountriesCompanion toCompanion(bool nullToAbsent) {
    return CountriesCompanion(
      iso2: Value(iso2),
      name: Value(name),
      sourceId: Value(sourceId),
    );
  }

  factory CountryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CountryRow(
      iso2: serializer.fromJson<String>(json['iso2']),
      name: serializer.fromJson<String>(json['name']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'iso2': serializer.toJson<String>(iso2),
      'name': serializer.toJson<String>(name),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  CountryRow copyWith({String? iso2, String? name, String? sourceId}) =>
      CountryRow(
        iso2: iso2 ?? this.iso2,
        name: name ?? this.name,
        sourceId: sourceId ?? this.sourceId,
      );
  CountryRow copyWithCompanion(CountriesCompanion data) {
    return CountryRow(
      iso2: data.iso2.present ? data.iso2.value : this.iso2,
      name: data.name.present ? data.name.value : this.name,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CountryRow(')
          ..write('iso2: $iso2, ')
          ..write('name: $name, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(iso2, name, sourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CountryRow &&
          other.iso2 == this.iso2 &&
          other.name == this.name &&
          other.sourceId == this.sourceId);
}

class CountriesCompanion extends UpdateCompanion<CountryRow> {
  final Value<String> iso2;
  final Value<String> name;
  final Value<String> sourceId;
  final Value<int> rowid;
  const CountriesCompanion({
    this.iso2 = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountriesCompanion.insert({
    required String iso2,
    required String name,
    required String sourceId,
    this.rowid = const Value.absent(),
  }) : iso2 = Value(iso2),
       name = Value(name),
       sourceId = Value(sourceId);
  static Insertable<CountryRow> custom({
    Expression<String>? iso2,
    Expression<String>? name,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (iso2 != null) 'iso2': iso2,
      if (name != null) 'name': name,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountriesCompanion copyWith({
    Value<String>? iso2,
    Value<String>? name,
    Value<String>? sourceId,
    Value<int>? rowid,
  }) {
    return CountriesCompanion(
      iso2: iso2 ?? this.iso2,
      name: name ?? this.name,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (iso2.present) {
      map['iso2'] = Variable<String>(iso2.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
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
    return (StringBuffer('CountriesCompanion(')
          ..write('iso2: $iso2, ')
          ..write('name: $name, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CitiesTable extends Cities with TableInfo<$CitiesTable, CityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CitiesTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  late final GeneratedColumn<String> asciiName = GeneratedColumn<String>(
    'ascii_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES country (iso2)',
    ),
  );
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
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
  late final GeneratedColumn<int> population = GeneratedColumn<int>(
    'population',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
    id,
    name,
    asciiName,
    countryCode,
    lat,
    lng,
    tz,
    population,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'city';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CityRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      asciiName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ascii_name'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      tz: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tz'],
      )!,
      population: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}population'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
    );
  }

  @override
  $CitiesTable createAlias(String alias) {
    return $CitiesTable(attachedDatabase, alias);
  }
}

class CityRow extends DataClass implements Insertable<CityRow> {
  final int id;
  final String name;
  final String asciiName;
  final String countryCode;
  final double lat;
  final double lng;
  final String tz;
  final int? population;
  final String sourceId;
  const CityRow({
    required this.id,
    required this.name,
    required this.asciiName,
    required this.countryCode,
    required this.lat,
    required this.lng,
    required this.tz,
    this.population,
    required this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['ascii_name'] = Variable<String>(asciiName);
    map['country_code'] = Variable<String>(countryCode);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['tz'] = Variable<String>(tz);
    if (!nullToAbsent || population != null) {
      map['population'] = Variable<int>(population);
    }
    map['source_id'] = Variable<String>(sourceId);
    return map;
  }

  CitiesCompanion toCompanion(bool nullToAbsent) {
    return CitiesCompanion(
      id: Value(id),
      name: Value(name),
      asciiName: Value(asciiName),
      countryCode: Value(countryCode),
      lat: Value(lat),
      lng: Value(lng),
      tz: Value(tz),
      population: population == null && nullToAbsent
          ? const Value.absent()
          : Value(population),
      sourceId: Value(sourceId),
    );
  }

  factory CityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CityRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      asciiName: serializer.fromJson<String>(json['asciiName']),
      countryCode: serializer.fromJson<String>(json['countryCode']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      tz: serializer.fromJson<String>(json['tz']),
      population: serializer.fromJson<int?>(json['population']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'asciiName': serializer.toJson<String>(asciiName),
      'countryCode': serializer.toJson<String>(countryCode),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'tz': serializer.toJson<String>(tz),
      'population': serializer.toJson<int?>(population),
      'sourceId': serializer.toJson<String>(sourceId),
    };
  }

  CityRow copyWith({
    int? id,
    String? name,
    String? asciiName,
    String? countryCode,
    double? lat,
    double? lng,
    String? tz,
    Value<int?> population = const Value.absent(),
    String? sourceId,
  }) => CityRow(
    id: id ?? this.id,
    name: name ?? this.name,
    asciiName: asciiName ?? this.asciiName,
    countryCode: countryCode ?? this.countryCode,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    tz: tz ?? this.tz,
    population: population.present ? population.value : this.population,
    sourceId: sourceId ?? this.sourceId,
  );
  CityRow copyWithCompanion(CitiesCompanion data) {
    return CityRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      asciiName: data.asciiName.present ? data.asciiName.value : this.asciiName,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      tz: data.tz.present ? data.tz.value : this.tz,
      population: data.population.present
          ? data.population.value
          : this.population,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CityRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('asciiName: $asciiName, ')
          ..write('countryCode: $countryCode, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('tz: $tz, ')
          ..write('population: $population, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    asciiName,
    countryCode,
    lat,
    lng,
    tz,
    population,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CityRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.asciiName == this.asciiName &&
          other.countryCode == this.countryCode &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.tz == this.tz &&
          other.population == this.population &&
          other.sourceId == this.sourceId);
}

class CitiesCompanion extends UpdateCompanion<CityRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> asciiName;
  final Value<String> countryCode;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String> tz;
  final Value<int?> population;
  final Value<String> sourceId;
  const CitiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.asciiName = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.tz = const Value.absent(),
    this.population = const Value.absent(),
    this.sourceId = const Value.absent(),
  });
  CitiesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String asciiName,
    required String countryCode,
    required double lat,
    required double lng,
    required String tz,
    this.population = const Value.absent(),
    required String sourceId,
  }) : name = Value(name),
       asciiName = Value(asciiName),
       countryCode = Value(countryCode),
       lat = Value(lat),
       lng = Value(lng),
       tz = Value(tz),
       sourceId = Value(sourceId);
  static Insertable<CityRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? asciiName,
    Expression<String>? countryCode,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? tz,
    Expression<int>? population,
    Expression<String>? sourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (asciiName != null) 'ascii_name': asciiName,
      if (countryCode != null) 'country_code': countryCode,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (tz != null) 'tz': tz,
      if (population != null) 'population': population,
      if (sourceId != null) 'source_id': sourceId,
    });
  }

  CitiesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? asciiName,
    Value<String>? countryCode,
    Value<double>? lat,
    Value<double>? lng,
    Value<String>? tz,
    Value<int?>? population,
    Value<String>? sourceId,
  }) {
    return CitiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      asciiName: asciiName ?? this.asciiName,
      countryCode: countryCode ?? this.countryCode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      tz: tz ?? this.tz,
      population: population ?? this.population,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (asciiName.present) {
      map['ascii_name'] = Variable<String>(asciiName.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (population.present) {
      map['population'] = Variable<int>(population.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CitiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('asciiName: $asciiName, ')
          ..write('countryCode: $countryCode, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('tz: $tz, ')
          ..write('population: $population, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDb extends GeneratedDatabase {
  _$ContentDb(QueryExecutor e) : super(e);
  late final $ContentMetaTable contentMeta = $ContentMetaTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $SurahsTable surahs = $SurahsTable(this);
  late final $SurahTextsTable surahTexts = $SurahTextsTable(this);
  late final $AyahsTable ayahs = $AyahsTable(this);
  late final $TranslationsTable translations = $TranslationsTable(this);
  late final $LemmasTable lemmas = $LemmasTable(this);
  late final $LemmaMeaningsTable lemmaMeanings = $LemmaMeaningsTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordMeaningsTable wordMeanings = $WordMeaningsTable(this);
  late final $HadithsTable hadiths = $HadithsTable(this);
  late final $HadithTextsTable hadithTexts = $HadithTextsTable(this);
  late final $DuasTable duas = $DuasTable(this);
  late final $DuaTextsTable duaTexts = $DuaTextsTable(this);
  late final $NamesOfAllahTable namesOfAllah = $NamesOfAllahTable(this);
  late final $NameTextsTable nameTexts = $NameTextsTable(this);
  late final $ReflectionsTable reflections = $ReflectionsTable(this);
  late final $ReflectionTextsTable reflectionTexts = $ReflectionTextsTable(
    this,
  );
  late final $QuestTemplatesTable questTemplates = $QuestTemplatesTable(this);
  late final $QuestTextsTable questTexts = $QuestTextsTable(this);
  late final $IslamicEventsTable islamicEvents = $IslamicEventsTable(this);
  late final $IslamicEventTextsTable islamicEventTexts =
      $IslamicEventTextsTable(this);
  late final $IntroCardsTable introCards = $IntroCardsTable(this);
  late final $IntroCardTextsTable introCardTexts = $IntroCardTextsTable(this);
  late final $CountriesTable countries = $CountriesTable(this);
  late final $CitiesTable cities = $CitiesTable(this);
  late final ContentMetaDao contentMetaDao = ContentMetaDao(this as ContentDb);
  late final QuranDao quranDao = QuranDao(this as ContentDb);
  late final HadithDao hadithDao = HadithDao(this as ContentDb);
  late final CuratedDao curatedDao = CuratedDao(this as ContentDb);
  late final WordsDao wordsDao = WordsDao(this as ContentDb);
  late final PlacesDao placesDao = PlacesDao(this as ContentDb);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contentMeta,
    sources,
    surahs,
    surahTexts,
    ayahs,
    translations,
    lemmas,
    lemmaMeanings,
    words,
    wordMeanings,
    hadiths,
    hadithTexts,
    duas,
    duaTexts,
    namesOfAllah,
    nameTexts,
    reflections,
    reflectionTexts,
    questTemplates,
    questTexts,
    islamicEvents,
    islamicEventTexts,
    introCards,
    introCardTexts,
    countries,
    cities,
  ];
}
