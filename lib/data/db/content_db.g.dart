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
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> translator = GeneratedColumn<String>(
    'translator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> translatorDied = GeneratedColumn<int>(
    'translator_died',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<int> editionYear = GeneratedColumn<int>(
    'edition_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  late final GeneratedColumn<String> licenseNote = GeneratedColumn<String>(
    'license_note',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    name,
    translator,
    translatorDied,
    editionYear,
    version,
    license,
    licenseNote,
    attribution,
    url,
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
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      translator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translator'],
      ),
      translatorDied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}translator_died'],
      ),
      editionYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edition_year'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      license: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license'],
      )!,
      licenseNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_note'],
      )!,
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
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
  final String name;
  final String? translator;
  final int? translatorDied;
  final int? editionYear;
  final String version;
  final String license;
  final String licenseNote;
  final String attribution;
  final String? url;
  final String? sha256;
  const SourceRow({
    required this.id,
    required this.kind,
    required this.name,
    this.translator,
    this.translatorDied,
    this.editionYear,
    required this.version,
    required this.license,
    required this.licenseNote,
    required this.attribution,
    this.url,
    this.sha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || translator != null) {
      map['translator'] = Variable<String>(translator);
    }
    if (!nullToAbsent || translatorDied != null) {
      map['translator_died'] = Variable<int>(translatorDied);
    }
    if (!nullToAbsent || editionYear != null) {
      map['edition_year'] = Variable<int>(editionYear);
    }
    map['version'] = Variable<String>(version);
    map['license'] = Variable<String>(license);
    map['license_note'] = Variable<String>(licenseNote);
    map['attribution'] = Variable<String>(attribution);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      translator: translator == null && nullToAbsent
          ? const Value.absent()
          : Value(translator),
      translatorDied: translatorDied == null && nullToAbsent
          ? const Value.absent()
          : Value(translatorDied),
      editionYear: editionYear == null && nullToAbsent
          ? const Value.absent()
          : Value(editionYear),
      version: Value(version),
      license: Value(license),
      licenseNote: Value(licenseNote),
      attribution: Value(attribution),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
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
      name: serializer.fromJson<String>(json['name']),
      translator: serializer.fromJson<String?>(json['translator']),
      translatorDied: serializer.fromJson<int?>(json['translatorDied']),
      editionYear: serializer.fromJson<int?>(json['editionYear']),
      version: serializer.fromJson<String>(json['version']),
      license: serializer.fromJson<String>(json['license']),
      licenseNote: serializer.fromJson<String>(json['licenseNote']),
      attribution: serializer.fromJson<String>(json['attribution']),
      url: serializer.fromJson<String?>(json['url']),
      sha256: serializer.fromJson<String?>(json['sha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'translator': serializer.toJson<String?>(translator),
      'translatorDied': serializer.toJson<int?>(translatorDied),
      'editionYear': serializer.toJson<int?>(editionYear),
      'version': serializer.toJson<String>(version),
      'license': serializer.toJson<String>(license),
      'licenseNote': serializer.toJson<String>(licenseNote),
      'attribution': serializer.toJson<String>(attribution),
      'url': serializer.toJson<String?>(url),
      'sha256': serializer.toJson<String?>(sha256),
    };
  }

  SourceRow copyWith({
    String? id,
    String? kind,
    String? name,
    Value<String?> translator = const Value.absent(),
    Value<int?> translatorDied = const Value.absent(),
    Value<int?> editionYear = const Value.absent(),
    String? version,
    String? license,
    String? licenseNote,
    String? attribution,
    Value<String?> url = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
  }) => SourceRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    translator: translator.present ? translator.value : this.translator,
    translatorDied: translatorDied.present
        ? translatorDied.value
        : this.translatorDied,
    editionYear: editionYear.present ? editionYear.value : this.editionYear,
    version: version ?? this.version,
    license: license ?? this.license,
    licenseNote: licenseNote ?? this.licenseNote,
    attribution: attribution ?? this.attribution,
    url: url.present ? url.value : this.url,
    sha256: sha256.present ? sha256.value : this.sha256,
  );
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      translator: data.translator.present
          ? data.translator.value
          : this.translator,
      translatorDied: data.translatorDied.present
          ? data.translatorDied.value
          : this.translatorDied,
      editionYear: data.editionYear.present
          ? data.editionYear.value
          : this.editionYear,
      version: data.version.present ? data.version.value : this.version,
      license: data.license.present ? data.license.value : this.license,
      licenseNote: data.licenseNote.present
          ? data.licenseNote.value
          : this.licenseNote,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      url: data.url.present ? data.url.value : this.url,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('translator: $translator, ')
          ..write('translatorDied: $translatorDied, ')
          ..write('editionYear: $editionYear, ')
          ..write('version: $version, ')
          ..write('license: $license, ')
          ..write('licenseNote: $licenseNote, ')
          ..write('attribution: $attribution, ')
          ..write('url: $url, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    translator,
    translatorDied,
    editionYear,
    version,
    license,
    licenseNote,
    attribution,
    url,
    sha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.translator == this.translator &&
          other.translatorDied == this.translatorDied &&
          other.editionYear == this.editionYear &&
          other.version == this.version &&
          other.license == this.license &&
          other.licenseNote == this.licenseNote &&
          other.attribution == this.attribution &&
          other.url == this.url &&
          other.sha256 == this.sha256);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> translator;
  final Value<int?> translatorDied;
  final Value<int?> editionYear;
  final Value<String> version;
  final Value<String> license;
  final Value<String> licenseNote;
  final Value<String> attribution;
  final Value<String?> url;
  final Value<String?> sha256;
  final Value<int> rowid;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.translator = const Value.absent(),
    this.translatorDied = const Value.absent(),
    this.editionYear = const Value.absent(),
    this.version = const Value.absent(),
    this.license = const Value.absent(),
    this.licenseNote = const Value.absent(),
    this.attribution = const Value.absent(),
    this.url = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourcesCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.translator = const Value.absent(),
    this.translatorDied = const Value.absent(),
    this.editionYear = const Value.absent(),
    required String version,
    required String license,
    required String licenseNote,
    required String attribution,
    this.url = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name),
       version = Value(version),
       license = Value(license),
       licenseNote = Value(licenseNote),
       attribution = Value(attribution);
  static Insertable<SourceRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? translator,
    Expression<int>? translatorDied,
    Expression<int>? editionYear,
    Expression<String>? version,
    Expression<String>? license,
    Expression<String>? licenseNote,
    Expression<String>? attribution,
    Expression<String>? url,
    Expression<String>? sha256,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (translator != null) 'translator': translator,
      if (translatorDied != null) 'translator_died': translatorDied,
      if (editionYear != null) 'edition_year': editionYear,
      if (version != null) 'version': version,
      if (license != null) 'license': license,
      if (licenseNote != null) 'license_note': licenseNote,
      if (attribution != null) 'attribution': attribution,
      if (url != null) 'url': url,
      if (sha256 != null) 'sha256': sha256,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? translator,
    Value<int?>? translatorDied,
    Value<int?>? editionYear,
    Value<String>? version,
    Value<String>? license,
    Value<String>? licenseNote,
    Value<String>? attribution,
    Value<String?>? url,
    Value<String?>? sha256,
    Value<int>? rowid,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      translator: translator ?? this.translator,
      translatorDied: translatorDied ?? this.translatorDied,
      editionYear: editionYear ?? this.editionYear,
      version: version ?? this.version,
      license: license ?? this.license,
      licenseNote: licenseNote ?? this.licenseNote,
      attribution: attribution ?? this.attribution,
      url: url ?? this.url,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (translator.present) {
      map['translator'] = Variable<String>(translator.value);
    }
    if (translatorDied.present) {
      map['translator_died'] = Variable<int>(translatorDied.value);
    }
    if (editionYear.present) {
      map['edition_year'] = Variable<int>(editionYear.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (licenseNote.present) {
      map['license_note'] = Variable<String>(licenseNote.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
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
          ..write('name: $name, ')
          ..write('translator: $translator, ')
          ..write('translatorDied: $translatorDied, ')
          ..write('editionYear: $editionYear, ')
          ..write('version: $version, ')
          ..write('license: $license, ')
          ..write('licenseNote: $licenseNote, ')
          ..write('attribution: $attribution, ')
          ..write('url: $url, ')
          ..write('sha256: $sha256, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuthorsTable extends Authors with TableInfo<$AuthorsTable, AuthorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthorsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> lifespan = GeneratedColumn<String>(
    'lifespan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> ord = GeneratedColumn<int>(
    'ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, fullName, lifespan, ord];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'author';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuthorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuthorRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      lifespan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifespan'],
      )!,
      ord: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ord'],
      )!,
    );
  }

  @override
  $AuthorsTable createAlias(String alias) {
    return $AuthorsTable(attachedDatabase, alias);
  }
}

class AuthorRow extends DataClass implements Insertable<AuthorRow> {
  final String id;
  final String name;
  final String fullName;
  final String lifespan;
  final int ord;
  const AuthorRow({
    required this.id,
    required this.name,
    required this.fullName,
    required this.lifespan,
    required this.ord,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['full_name'] = Variable<String>(fullName);
    map['lifespan'] = Variable<String>(lifespan);
    map['ord'] = Variable<int>(ord);
    return map;
  }

  AuthorsCompanion toCompanion(bool nullToAbsent) {
    return AuthorsCompanion(
      id: Value(id),
      name: Value(name),
      fullName: Value(fullName),
      lifespan: Value(lifespan),
      ord: Value(ord),
    );
  }

  factory AuthorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuthorRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fullName: serializer.fromJson<String>(json['fullName']),
      lifespan: serializer.fromJson<String>(json['lifespan']),
      ord: serializer.fromJson<int>(json['ord']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'fullName': serializer.toJson<String>(fullName),
      'lifespan': serializer.toJson<String>(lifespan),
      'ord': serializer.toJson<int>(ord),
    };
  }

  AuthorRow copyWith({
    String? id,
    String? name,
    String? fullName,
    String? lifespan,
    int? ord,
  }) => AuthorRow(
    id: id ?? this.id,
    name: name ?? this.name,
    fullName: fullName ?? this.fullName,
    lifespan: lifespan ?? this.lifespan,
    ord: ord ?? this.ord,
  );
  AuthorRow copyWithCompanion(AuthorsCompanion data) {
    return AuthorRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      lifespan: data.lifespan.present ? data.lifespan.value : this.lifespan,
      ord: data.ord.present ? data.ord.value : this.ord,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuthorRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fullName: $fullName, ')
          ..write('lifespan: $lifespan, ')
          ..write('ord: $ord')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, fullName, lifespan, ord);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthorRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.fullName == this.fullName &&
          other.lifespan == this.lifespan &&
          other.ord == this.ord);
}

class AuthorsCompanion extends UpdateCompanion<AuthorRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> fullName;
  final Value<String> lifespan;
  final Value<int> ord;
  final Value<int> rowid;
  const AuthorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fullName = const Value.absent(),
    this.lifespan = const Value.absent(),
    this.ord = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuthorsCompanion.insert({
    required String id,
    required String name,
    required String fullName,
    required String lifespan,
    required int ord,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       fullName = Value(fullName),
       lifespan = Value(lifespan),
       ord = Value(ord);
  static Insertable<AuthorRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? fullName,
    Expression<String>? lifespan,
    Expression<int>? ord,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fullName != null) 'full_name': fullName,
      if (lifespan != null) 'lifespan': lifespan,
      if (ord != null) 'ord': ord,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuthorsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? fullName,
    Value<String>? lifespan,
    Value<int>? ord,
    Value<int>? rowid,
  }) {
    return AuthorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      lifespan: lifespan ?? this.lifespan,
      ord: ord ?? this.ord,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (lifespan.present) {
      map['lifespan'] = Variable<String>(lifespan.value);
    }
    if (ord.present) {
      map['ord'] = Variable<int>(ord.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fullName: $fullName, ')
          ..write('lifespan: $lifespan, ')
          ..write('ord: $ord, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorksTable extends Works with TableInfo<$WorksTable, WorkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorksTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES author (id)',
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
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> translator = GeneratedColumn<String>(
    'translator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> shortRef = GeneratedColumn<String>(
    'short_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> bookCount = GeneratedColumn<int>(
    'book_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> sectionCount = GeneratedColumn<int>(
    'section_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> ord = GeneratedColumn<int>(
    'ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    authorId,
    sourceId,
    title,
    originalTitle,
    translator,
    shortRef,
    bookCount,
    sectionCount,
    ord,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      )!,
      translator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translator'],
      )!,
      shortRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_ref'],
      )!,
      bookCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_count'],
      )!,
      sectionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_count'],
      )!,
      ord: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ord'],
      )!,
    );
  }

  @override
  $WorksTable createAlias(String alias) {
    return $WorksTable(attachedDatabase, alias);
  }
}

class WorkRow extends DataClass implements Insertable<WorkRow> {
  final String id;
  final String authorId;
  final String sourceId;
  final String title;
  final String originalTitle;
  final String translator;
  final String shortRef;
  final int bookCount;
  final int sectionCount;
  final int ord;
  const WorkRow({
    required this.id,
    required this.authorId,
    required this.sourceId,
    required this.title,
    required this.originalTitle,
    required this.translator,
    required this.shortRef,
    required this.bookCount,
    required this.sectionCount,
    required this.ord,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['author_id'] = Variable<String>(authorId);
    map['source_id'] = Variable<String>(sourceId);
    map['title'] = Variable<String>(title);
    map['original_title'] = Variable<String>(originalTitle);
    map['translator'] = Variable<String>(translator);
    map['short_ref'] = Variable<String>(shortRef);
    map['book_count'] = Variable<int>(bookCount);
    map['section_count'] = Variable<int>(sectionCount);
    map['ord'] = Variable<int>(ord);
    return map;
  }

  WorksCompanion toCompanion(bool nullToAbsent) {
    return WorksCompanion(
      id: Value(id),
      authorId: Value(authorId),
      sourceId: Value(sourceId),
      title: Value(title),
      originalTitle: Value(originalTitle),
      translator: Value(translator),
      shortRef: Value(shortRef),
      bookCount: Value(bookCount),
      sectionCount: Value(sectionCount),
      ord: Value(ord),
    );
  }

  factory WorkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkRow(
      id: serializer.fromJson<String>(json['id']),
      authorId: serializer.fromJson<String>(json['authorId']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String>(json['originalTitle']),
      translator: serializer.fromJson<String>(json['translator']),
      shortRef: serializer.fromJson<String>(json['shortRef']),
      bookCount: serializer.fromJson<int>(json['bookCount']),
      sectionCount: serializer.fromJson<int>(json['sectionCount']),
      ord: serializer.fromJson<int>(json['ord']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'authorId': serializer.toJson<String>(authorId),
      'sourceId': serializer.toJson<String>(sourceId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String>(originalTitle),
      'translator': serializer.toJson<String>(translator),
      'shortRef': serializer.toJson<String>(shortRef),
      'bookCount': serializer.toJson<int>(bookCount),
      'sectionCount': serializer.toJson<int>(sectionCount),
      'ord': serializer.toJson<int>(ord),
    };
  }

  WorkRow copyWith({
    String? id,
    String? authorId,
    String? sourceId,
    String? title,
    String? originalTitle,
    String? translator,
    String? shortRef,
    int? bookCount,
    int? sectionCount,
    int? ord,
  }) => WorkRow(
    id: id ?? this.id,
    authorId: authorId ?? this.authorId,
    sourceId: sourceId ?? this.sourceId,
    title: title ?? this.title,
    originalTitle: originalTitle ?? this.originalTitle,
    translator: translator ?? this.translator,
    shortRef: shortRef ?? this.shortRef,
    bookCount: bookCount ?? this.bookCount,
    sectionCount: sectionCount ?? this.sectionCount,
    ord: ord ?? this.ord,
  );
  WorkRow copyWithCompanion(WorksCompanion data) {
    return WorkRow(
      id: data.id.present ? data.id.value : this.id,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      translator: data.translator.present
          ? data.translator.value
          : this.translator,
      shortRef: data.shortRef.present ? data.shortRef.value : this.shortRef,
      bookCount: data.bookCount.present ? data.bookCount.value : this.bookCount,
      sectionCount: data.sectionCount.present
          ? data.sectionCount.value
          : this.sectionCount,
      ord: data.ord.present ? data.ord.value : this.ord,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkRow(')
          ..write('id: $id, ')
          ..write('authorId: $authorId, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('translator: $translator, ')
          ..write('shortRef: $shortRef, ')
          ..write('bookCount: $bookCount, ')
          ..write('sectionCount: $sectionCount, ')
          ..write('ord: $ord')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    authorId,
    sourceId,
    title,
    originalTitle,
    translator,
    shortRef,
    bookCount,
    sectionCount,
    ord,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkRow &&
          other.id == this.id &&
          other.authorId == this.authorId &&
          other.sourceId == this.sourceId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.translator == this.translator &&
          other.shortRef == this.shortRef &&
          other.bookCount == this.bookCount &&
          other.sectionCount == this.sectionCount &&
          other.ord == this.ord);
}

class WorksCompanion extends UpdateCompanion<WorkRow> {
  final Value<String> id;
  final Value<String> authorId;
  final Value<String> sourceId;
  final Value<String> title;
  final Value<String> originalTitle;
  final Value<String> translator;
  final Value<String> shortRef;
  final Value<int> bookCount;
  final Value<int> sectionCount;
  final Value<int> ord;
  final Value<int> rowid;
  const WorksCompanion({
    this.id = const Value.absent(),
    this.authorId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.translator = const Value.absent(),
    this.shortRef = const Value.absent(),
    this.bookCount = const Value.absent(),
    this.sectionCount = const Value.absent(),
    this.ord = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorksCompanion.insert({
    required String id,
    required String authorId,
    required String sourceId,
    required String title,
    required String originalTitle,
    required String translator,
    required String shortRef,
    required int bookCount,
    required int sectionCount,
    required int ord,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       authorId = Value(authorId),
       sourceId = Value(sourceId),
       title = Value(title),
       originalTitle = Value(originalTitle),
       translator = Value(translator),
       shortRef = Value(shortRef),
       bookCount = Value(bookCount),
       sectionCount = Value(sectionCount),
       ord = Value(ord);
  static Insertable<WorkRow> custom({
    Expression<String>? id,
    Expression<String>? authorId,
    Expression<String>? sourceId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<String>? translator,
    Expression<String>? shortRef,
    Expression<int>? bookCount,
    Expression<int>? sectionCount,
    Expression<int>? ord,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (authorId != null) 'author_id': authorId,
      if (sourceId != null) 'source_id': sourceId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (translator != null) 'translator': translator,
      if (shortRef != null) 'short_ref': shortRef,
      if (bookCount != null) 'book_count': bookCount,
      if (sectionCount != null) 'section_count': sectionCount,
      if (ord != null) 'ord': ord,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorksCompanion copyWith({
    Value<String>? id,
    Value<String>? authorId,
    Value<String>? sourceId,
    Value<String>? title,
    Value<String>? originalTitle,
    Value<String>? translator,
    Value<String>? shortRef,
    Value<int>? bookCount,
    Value<int>? sectionCount,
    Value<int>? ord,
    Value<int>? rowid,
  }) {
    return WorksCompanion(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      translator: translator ?? this.translator,
      shortRef: shortRef ?? this.shortRef,
      bookCount: bookCount ?? this.bookCount,
      sectionCount: sectionCount ?? this.sectionCount,
      ord: ord ?? this.ord,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (translator.present) {
      map['translator'] = Variable<String>(translator.value);
    }
    if (shortRef.present) {
      map['short_ref'] = Variable<String>(shortRef.value);
    }
    if (bookCount.present) {
      map['book_count'] = Variable<int>(bookCount.value);
    }
    if (sectionCount.present) {
      map['section_count'] = Variable<int>(sectionCount.value);
    }
    if (ord.present) {
      map['ord'] = Variable<int>(ord.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorksCompanion(')
          ..write('id: $id, ')
          ..write('authorId: $authorId, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('translator: $translator, ')
          ..write('shortRef: $shortRef, ')
          ..write('bookCount: $bookCount, ')
          ..write('sectionCount: $sectionCount, ')
          ..write('ord: $ord, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES work (id)',
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
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> sectionCount = GeneratedColumn<int>(
    'section_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [workId, number, title, sectionCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book';
  @override
  Set<GeneratedColumn> get $primaryKey => {workId, number};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sectionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_count'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final String workId;
  final int number;
  final String title;
  final int sectionCount;
  const BookRow({
    required this.workId,
    required this.number,
    required this.title,
    required this.sectionCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_id'] = Variable<String>(workId);
    map['number'] = Variable<int>(number);
    map['title'] = Variable<String>(title);
    map['section_count'] = Variable<int>(sectionCount);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      workId: Value(workId),
      number: Value(number),
      title: Value(title),
      sectionCount: Value(sectionCount),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      workId: serializer.fromJson<String>(json['workId']),
      number: serializer.fromJson<int>(json['number']),
      title: serializer.fromJson<String>(json['title']),
      sectionCount: serializer.fromJson<int>(json['sectionCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workId': serializer.toJson<String>(workId),
      'number': serializer.toJson<int>(number),
      'title': serializer.toJson<String>(title),
      'sectionCount': serializer.toJson<int>(sectionCount),
    };
  }

  BookRow copyWith({
    String? workId,
    int? number,
    String? title,
    int? sectionCount,
  }) => BookRow(
    workId: workId ?? this.workId,
    number: number ?? this.number,
    title: title ?? this.title,
    sectionCount: sectionCount ?? this.sectionCount,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      workId: data.workId.present ? data.workId.value : this.workId,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      sectionCount: data.sectionCount.present
          ? data.sectionCount.value
          : this.sectionCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('workId: $workId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('sectionCount: $sectionCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(workId, number, title, sectionCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.workId == this.workId &&
          other.number == this.number &&
          other.title == this.title &&
          other.sectionCount == this.sectionCount);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<String> workId;
  final Value<int> number;
  final Value<String> title;
  final Value<int> sectionCount;
  final Value<int> rowid;
  const BooksCompanion({
    this.workId = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.sectionCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String workId,
    required int number,
    required String title,
    required int sectionCount,
    this.rowid = const Value.absent(),
  }) : workId = Value(workId),
       number = Value(number),
       title = Value(title),
       sectionCount = Value(sectionCount);
  static Insertable<BookRow> custom({
    Expression<String>? workId,
    Expression<int>? number,
    Expression<String>? title,
    Expression<int>? sectionCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workId != null) 'work_id': workId,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (sectionCount != null) 'section_count': sectionCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? workId,
    Value<int>? number,
    Value<String>? title,
    Value<int>? sectionCount,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      workId: workId ?? this.workId,
      number: number ?? this.number,
      title: title ?? this.title,
      sectionCount: sectionCount ?? this.sectionCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sectionCount.present) {
      map['section_count'] = Variable<int>(sectionCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('workId: $workId, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('sectionCount: $sectionCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SectionsTable extends Sections
    with TableInfo<$SectionsTable, SectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectionsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES work (id)',
    ),
  );
  @override
  late final GeneratedColumn<int> book = GeneratedColumn<int>(
    'book',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
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
  late final GeneratedColumn<String> textContent = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<int> charCount = GeneratedColumn<int>(
    'char_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    key,
    workId,
    book,
    number,
    ref,
    title,
    textContent,
    charCount,
    sha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'section';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      charCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}char_count'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
    );
  }

  @override
  $SectionsTable createAlias(String alias) {
    return $SectionsTable(attachedDatabase, alias);
  }
}

class SectionRow extends DataClass implements Insertable<SectionRow> {
  final int id;
  final String key;
  final String workId;
  final int? book;
  final int number;
  final String ref;
  final String? title;
  final String textContent;
  final int charCount;
  final String sha256;
  const SectionRow({
    required this.id,
    required this.key,
    required this.workId,
    this.book,
    required this.number,
    required this.ref,
    this.title,
    required this.textContent,
    required this.charCount,
    required this.sha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['work_id'] = Variable<String>(workId);
    if (!nullToAbsent || book != null) {
      map['book'] = Variable<int>(book);
    }
    map['number'] = Variable<int>(number);
    map['ref'] = Variable<String>(ref);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['text'] = Variable<String>(textContent);
    map['char_count'] = Variable<int>(charCount);
    map['sha256'] = Variable<String>(sha256);
    return map;
  }

  SectionsCompanion toCompanion(bool nullToAbsent) {
    return SectionsCompanion(
      id: Value(id),
      key: Value(key),
      workId: Value(workId),
      book: book == null && nullToAbsent ? const Value.absent() : Value(book),
      number: Value(number),
      ref: Value(ref),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      textContent: Value(textContent),
      charCount: Value(charCount),
      sha256: Value(sha256),
    );
  }

  factory SectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SectionRow(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      workId: serializer.fromJson<String>(json['workId']),
      book: serializer.fromJson<int?>(json['book']),
      number: serializer.fromJson<int>(json['number']),
      ref: serializer.fromJson<String>(json['ref']),
      title: serializer.fromJson<String?>(json['title']),
      textContent: serializer.fromJson<String>(json['textContent']),
      charCount: serializer.fromJson<int>(json['charCount']),
      sha256: serializer.fromJson<String>(json['sha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'workId': serializer.toJson<String>(workId),
      'book': serializer.toJson<int?>(book),
      'number': serializer.toJson<int>(number),
      'ref': serializer.toJson<String>(ref),
      'title': serializer.toJson<String?>(title),
      'textContent': serializer.toJson<String>(textContent),
      'charCount': serializer.toJson<int>(charCount),
      'sha256': serializer.toJson<String>(sha256),
    };
  }

  SectionRow copyWith({
    int? id,
    String? key,
    String? workId,
    Value<int?> book = const Value.absent(),
    int? number,
    String? ref,
    Value<String?> title = const Value.absent(),
    String? textContent,
    int? charCount,
    String? sha256,
  }) => SectionRow(
    id: id ?? this.id,
    key: key ?? this.key,
    workId: workId ?? this.workId,
    book: book.present ? book.value : this.book,
    number: number ?? this.number,
    ref: ref ?? this.ref,
    title: title.present ? title.value : this.title,
    textContent: textContent ?? this.textContent,
    charCount: charCount ?? this.charCount,
    sha256: sha256 ?? this.sha256,
  );
  SectionRow copyWithCompanion(SectionsCompanion data) {
    return SectionRow(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      workId: data.workId.present ? data.workId.value : this.workId,
      book: data.book.present ? data.book.value : this.book,
      number: data.number.present ? data.number.value : this.number,
      ref: data.ref.present ? data.ref.value : this.ref,
      title: data.title.present ? data.title.value : this.title,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      charCount: data.charCount.present ? data.charCount.value : this.charCount,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SectionRow(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('workId: $workId, ')
          ..write('book: $book, ')
          ..write('number: $number, ')
          ..write('ref: $ref, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('charCount: $charCount, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    key,
    workId,
    book,
    number,
    ref,
    title,
    textContent,
    charCount,
    sha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SectionRow &&
          other.id == this.id &&
          other.key == this.key &&
          other.workId == this.workId &&
          other.book == this.book &&
          other.number == this.number &&
          other.ref == this.ref &&
          other.title == this.title &&
          other.textContent == this.textContent &&
          other.charCount == this.charCount &&
          other.sha256 == this.sha256);
}

class SectionsCompanion extends UpdateCompanion<SectionRow> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> workId;
  final Value<int?> book;
  final Value<int> number;
  final Value<String> ref;
  final Value<String?> title;
  final Value<String> textContent;
  final Value<int> charCount;
  final Value<String> sha256;
  const SectionsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.workId = const Value.absent(),
    this.book = const Value.absent(),
    this.number = const Value.absent(),
    this.ref = const Value.absent(),
    this.title = const Value.absent(),
    this.textContent = const Value.absent(),
    this.charCount = const Value.absent(),
    this.sha256 = const Value.absent(),
  });
  SectionsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String workId,
    this.book = const Value.absent(),
    required int number,
    required String ref,
    this.title = const Value.absent(),
    required String textContent,
    required int charCount,
    required String sha256,
  }) : key = Value(key),
       workId = Value(workId),
       number = Value(number),
       ref = Value(ref),
       textContent = Value(textContent),
       charCount = Value(charCount),
       sha256 = Value(sha256);
  static Insertable<SectionRow> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? workId,
    Expression<int>? book,
    Expression<int>? number,
    Expression<String>? ref,
    Expression<String>? title,
    Expression<String>? textContent,
    Expression<int>? charCount,
    Expression<String>? sha256,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (workId != null) 'work_id': workId,
      if (book != null) 'book': book,
      if (number != null) 'number': number,
      if (ref != null) 'ref': ref,
      if (title != null) 'title': title,
      if (textContent != null) 'text': textContent,
      if (charCount != null) 'char_count': charCount,
      if (sha256 != null) 'sha256': sha256,
    });
  }

  SectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? workId,
    Value<int?>? book,
    Value<int>? number,
    Value<String>? ref,
    Value<String?>? title,
    Value<String>? textContent,
    Value<int>? charCount,
    Value<String>? sha256,
  }) {
    return SectionsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      workId: workId ?? this.workId,
      book: book ?? this.book,
      number: number ?? this.number,
      ref: ref ?? this.ref,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      charCount: charCount ?? this.charCount,
      sha256: sha256 ?? this.sha256,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (book.present) {
      map['book'] = Variable<int>(book.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (charCount.present) {
      map['char_count'] = Variable<int>(charCount.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectionsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('workId: $workId, ')
          ..write('book: $book, ')
          ..write('number: $number, ')
          ..write('ref: $ref, ')
          ..write('title: $title, ')
          ..write('textContent: $textContent, ')
          ..write('charCount: $charCount, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES author (id)',
    ),
  );
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES work (id)',
    ),
  );
  @override
  late final GeneratedColumn<String> sectionKey = GeneratedColumn<String>(
    'section_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES section ("key")',
    ),
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
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
  late final GeneratedColumn<int> ord = GeneratedColumn<int>(
    'ord',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    authorId,
    workId,
    sectionKey,
    ref,
    title,
    subtitle,
    textContent,
    tags,
    status,
    sourceId,
    ord,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      ),
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      ),
      sectionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_key'],
      ),
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      textContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      ord: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ord'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final String id;
  final String type;
  final String? authorId;
  final String? workId;
  final String? sectionKey;
  final String? ref;
  final String? title;
  final String? subtitle;
  final String textContent;
  final String tags;
  final String status;
  final String sourceId;
  final int ord;
  const CardRow({
    required this.id,
    required this.type,
    this.authorId,
    this.workId,
    this.sectionKey,
    this.ref,
    this.title,
    this.subtitle,
    required this.textContent,
    required this.tags,
    required this.status,
    required this.sourceId,
    required this.ord,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || authorId != null) {
      map['author_id'] = Variable<String>(authorId);
    }
    if (!nullToAbsent || workId != null) {
      map['work_id'] = Variable<String>(workId);
    }
    if (!nullToAbsent || sectionKey != null) {
      map['section_key'] = Variable<String>(sectionKey);
    }
    if (!nullToAbsent || ref != null) {
      map['ref'] = Variable<String>(ref);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['text'] = Variable<String>(textContent);
    map['tags'] = Variable<String>(tags);
    map['status'] = Variable<String>(status);
    map['source_id'] = Variable<String>(sourceId);
    map['ord'] = Variable<int>(ord);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      type: Value(type),
      authorId: authorId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorId),
      workId: workId == null && nullToAbsent
          ? const Value.absent()
          : Value(workId),
      sectionKey: sectionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionKey),
      ref: ref == null && nullToAbsent ? const Value.absent() : Value(ref),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      textContent: Value(textContent),
      tags: Value(tags),
      status: Value(status),
      sourceId: Value(sourceId),
      ord: Value(ord),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      authorId: serializer.fromJson<String?>(json['authorId']),
      workId: serializer.fromJson<String?>(json['workId']),
      sectionKey: serializer.fromJson<String?>(json['sectionKey']),
      ref: serializer.fromJson<String?>(json['ref']),
      title: serializer.fromJson<String?>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      textContent: serializer.fromJson<String>(json['textContent']),
      tags: serializer.fromJson<String>(json['tags']),
      status: serializer.fromJson<String>(json['status']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      ord: serializer.fromJson<int>(json['ord']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'authorId': serializer.toJson<String?>(authorId),
      'workId': serializer.toJson<String?>(workId),
      'sectionKey': serializer.toJson<String?>(sectionKey),
      'ref': serializer.toJson<String?>(ref),
      'title': serializer.toJson<String?>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'textContent': serializer.toJson<String>(textContent),
      'tags': serializer.toJson<String>(tags),
      'status': serializer.toJson<String>(status),
      'sourceId': serializer.toJson<String>(sourceId),
      'ord': serializer.toJson<int>(ord),
    };
  }

  CardRow copyWith({
    String? id,
    String? type,
    Value<String?> authorId = const Value.absent(),
    Value<String?> workId = const Value.absent(),
    Value<String?> sectionKey = const Value.absent(),
    Value<String?> ref = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> subtitle = const Value.absent(),
    String? textContent,
    String? tags,
    String? status,
    String? sourceId,
    int? ord,
  }) => CardRow(
    id: id ?? this.id,
    type: type ?? this.type,
    authorId: authorId.present ? authorId.value : this.authorId,
    workId: workId.present ? workId.value : this.workId,
    sectionKey: sectionKey.present ? sectionKey.value : this.sectionKey,
    ref: ref.present ? ref.value : this.ref,
    title: title.present ? title.value : this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    textContent: textContent ?? this.textContent,
    tags: tags ?? this.tags,
    status: status ?? this.status,
    sourceId: sourceId ?? this.sourceId,
    ord: ord ?? this.ord,
  );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      workId: data.workId.present ? data.workId.value : this.workId,
      sectionKey: data.sectionKey.present
          ? data.sectionKey.value
          : this.sectionKey,
      ref: data.ref.present ? data.ref.value : this.ref,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      textContent: data.textContent.present
          ? data.textContent.value
          : this.textContent,
      tags: data.tags.present ? data.tags.value : this.tags,
      status: data.status.present ? data.status.value : this.status,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      ord: data.ord.present ? data.ord.value : this.ord,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('authorId: $authorId, ')
          ..write('workId: $workId, ')
          ..write('sectionKey: $sectionKey, ')
          ..write('ref: $ref, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('textContent: $textContent, ')
          ..write('tags: $tags, ')
          ..write('status: $status, ')
          ..write('sourceId: $sourceId, ')
          ..write('ord: $ord')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    authorId,
    workId,
    sectionKey,
    ref,
    title,
    subtitle,
    textContent,
    tags,
    status,
    sourceId,
    ord,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.authorId == this.authorId &&
          other.workId == this.workId &&
          other.sectionKey == this.sectionKey &&
          other.ref == this.ref &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.textContent == this.textContent &&
          other.tags == this.tags &&
          other.status == this.status &&
          other.sourceId == this.sourceId &&
          other.ord == this.ord);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> authorId;
  final Value<String?> workId;
  final Value<String?> sectionKey;
  final Value<String?> ref;
  final Value<String?> title;
  final Value<String?> subtitle;
  final Value<String> textContent;
  final Value<String> tags;
  final Value<String> status;
  final Value<String> sourceId;
  final Value<int> ord;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.authorId = const Value.absent(),
    this.workId = const Value.absent(),
    this.sectionKey = const Value.absent(),
    this.ref = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.textContent = const Value.absent(),
    this.tags = const Value.absent(),
    this.status = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.ord = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String type,
    this.authorId = const Value.absent(),
    this.workId = const Value.absent(),
    this.sectionKey = const Value.absent(),
    this.ref = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    required String textContent,
    this.tags = const Value.absent(),
    required String status,
    required String sourceId,
    required int ord,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       textContent = Value(textContent),
       status = Value(status),
       sourceId = Value(sourceId),
       ord = Value(ord);
  static Insertable<CardRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? authorId,
    Expression<String>? workId,
    Expression<String>? sectionKey,
    Expression<String>? ref,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? textContent,
    Expression<String>? tags,
    Expression<String>? status,
    Expression<String>? sourceId,
    Expression<int>? ord,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (authorId != null) 'author_id': authorId,
      if (workId != null) 'work_id': workId,
      if (sectionKey != null) 'section_key': sectionKey,
      if (ref != null) 'ref': ref,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (textContent != null) 'text': textContent,
      if (tags != null) 'tags': tags,
      if (status != null) 'status': status,
      if (sourceId != null) 'source_id': sourceId,
      if (ord != null) 'ord': ord,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String?>? authorId,
    Value<String?>? workId,
    Value<String?>? sectionKey,
    Value<String?>? ref,
    Value<String?>? title,
    Value<String?>? subtitle,
    Value<String>? textContent,
    Value<String>? tags,
    Value<String>? status,
    Value<String>? sourceId,
    Value<int>? ord,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      workId: workId ?? this.workId,
      sectionKey: sectionKey ?? this.sectionKey,
      ref: ref ?? this.ref,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      textContent: textContent ?? this.textContent,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      sourceId: sourceId ?? this.sourceId,
      ord: ord ?? this.ord,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (sectionKey.present) {
      map['section_key'] = Variable<String>(sectionKey.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (textContent.present) {
      map['text'] = Variable<String>(textContent.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (ord.present) {
      map['ord'] = Variable<int>(ord.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('authorId: $authorId, ')
          ..write('workId: $workId, ')
          ..write('sectionKey: $sectionKey, ')
          ..write('ref: $ref, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('textContent: $textContent, ')
          ..write('tags: $tags, ')
          ..write('status: $status, ')
          ..write('sourceId: $sourceId, ')
          ..write('ord: $ord, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ContentDb extends GeneratedDatabase {
  _$ContentDb(QueryExecutor e) : super(e);
  late final $ContentMetaTable contentMeta = $ContentMetaTable(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $AuthorsTable authors = $AuthorsTable(this);
  late final $WorksTable works = $WorksTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $SectionsTable sections = $SectionsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final ContentMetaDao contentMetaDao = ContentMetaDao(this as ContentDb);
  late final CardDao cardDao = CardDao(this as ContentDb);
  late final LibraryDao libraryDao = LibraryDao(this as ContentDb);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    contentMeta,
    sources,
    authors,
    works,
    books,
    sections,
    cards,
  ];
}
