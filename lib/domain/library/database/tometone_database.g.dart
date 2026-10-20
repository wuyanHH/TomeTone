// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tometone_database.dart';

// ignore_for_file: type=lint
class $LibraryRootsTable extends LibraryRoots
    with TableInfo<$LibraryRootsTable, LibraryRoot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryRootsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastScanAtMeta = const VerificationMeta(
    'lastScanAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastScanAt = GeneratedColumn<DateTime>(
    'last_scan_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    uri,
    displayName,
    lastScanAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_roots';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryRoot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('last_scan_at')) {
      context.handle(
        _lastScanAtMeta,
        lastScanAt.isAcceptableOrUnknown(
          data['last_scan_at']!,
          _lastScanAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibraryRoot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryRoot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      lastScanAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_scan_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LibraryRootsTable createAlias(String alias) {
    return $LibraryRootsTable(attachedDatabase, alias);
  }
}

class LibraryRoot extends DataClass implements Insertable<LibraryRoot> {
  /// ULID。
  final String id;

  /// `local` / `saf` / `webdav` / `smb` / `online`。
  final String type;

  /// 根 URI（本地绝对路径或 provider 句柄）。
  final String uri;

  /// 展示名。
  final String displayName;

  /// 最近一次扫描完成时间。
  final DateTime? lastScanAt;

  /// 加入时间。
  final DateTime createdAt;
  const LibraryRoot({
    required this.id,
    required this.type,
    required this.uri,
    required this.displayName,
    this.lastScanAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['uri'] = Variable<String>(uri);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || lastScanAt != null) {
      map['last_scan_at'] = Variable<DateTime>(lastScanAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LibraryRootsCompanion toCompanion(bool nullToAbsent) {
    return LibraryRootsCompanion(
      id: Value(id),
      type: Value(type),
      uri: Value(uri),
      displayName: Value(displayName),
      lastScanAt: lastScanAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScanAt),
      createdAt: Value(createdAt),
    );
  }

  factory LibraryRoot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryRoot(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      uri: serializer.fromJson<String>(json['uri']),
      displayName: serializer.fromJson<String>(json['displayName']),
      lastScanAt: serializer.fromJson<DateTime?>(json['lastScanAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'uri': serializer.toJson<String>(uri),
      'displayName': serializer.toJson<String>(displayName),
      'lastScanAt': serializer.toJson<DateTime?>(lastScanAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LibraryRoot copyWith({
    String? id,
    String? type,
    String? uri,
    String? displayName,
    Value<DateTime?> lastScanAt = const Value.absent(),
    DateTime? createdAt,
  }) => LibraryRoot(
    id: id ?? this.id,
    type: type ?? this.type,
    uri: uri ?? this.uri,
    displayName: displayName ?? this.displayName,
    lastScanAt: lastScanAt.present ? lastScanAt.value : this.lastScanAt,
    createdAt: createdAt ?? this.createdAt,
  );
  LibraryRoot copyWithCompanion(LibraryRootsCompanion data) {
    return LibraryRoot(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      uri: data.uri.present ? data.uri.value : this.uri,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      lastScanAt: data.lastScanAt.present
          ? data.lastScanAt.value
          : this.lastScanAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryRoot(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, uri, displayName, lastScanAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryRoot &&
          other.id == this.id &&
          other.type == this.type &&
          other.uri == this.uri &&
          other.displayName == this.displayName &&
          other.lastScanAt == this.lastScanAt &&
          other.createdAt == this.createdAt);
}

class LibraryRootsCompanion extends UpdateCompanion<LibraryRoot> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> uri;
  final Value<String> displayName;
  final Value<DateTime?> lastScanAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LibraryRootsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.uri = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lastScanAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryRootsCompanion.insert({
    required String id,
    required String type,
    required String uri,
    required String displayName,
    this.lastScanAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       uri = Value(uri),
       displayName = Value(displayName),
       createdAt = Value(createdAt);
  static Insertable<LibraryRoot> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? uri,
    Expression<String>? displayName,
    Expression<DateTime>? lastScanAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (uri != null) 'uri': uri,
      if (displayName != null) 'display_name': displayName,
      if (lastScanAt != null) 'last_scan_at': lastScanAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryRootsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? uri,
    Value<String>? displayName,
    Value<DateTime?>? lastScanAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LibraryRootsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      uri: uri ?? this.uri,
      displayName: displayName ?? this.displayName,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      createdAt: createdAt ?? this.createdAt,
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
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (lastScanAt.present) {
      map['last_scan_at'] = Variable<DateTime>(lastScanAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryRootsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookSourcesTable extends BookSources
    with TableInfo<$BookSourcesTable, BookSourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libraryRootIdMeta = const VerificationMeta(
    'libraryRootId',
  );
  @override
  late final GeneratedColumn<String> libraryRootId = GeneratedColumn<String>(
    'library_root_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_roots (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<int> sourceType = GeneratedColumn<int>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawJsonMeta = const VerificationMeta(
    'rawJson',
  );
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
    'raw_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headerJsonMeta = const VerificationMeta(
    'headerJson',
  );
  @override
  late final GeneratedColumn<String> headerJson = GeneratedColumn<String>(
    'header_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exploreUrlMeta = const VerificationMeta(
    'exploreUrl',
  );
  @override
  late final GeneratedColumn<String> exploreUrl = GeneratedColumn<String>(
    'explore_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchUrlMeta = const VerificationMeta(
    'searchUrl',
  );
  @override
  late final GeneratedColumn<String> searchUrl = GeneratedColumn<String>(
    'search_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsLibMeta = const VerificationMeta('jsLib');
  @override
  late final GeneratedColumn<String> jsLib = GeneratedColumn<String>(
    'js_lib',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
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
  static const VerificationMeta _enabledExploreMeta = const VerificationMeta(
    'enabledExplore',
  );
  @override
  late final GeneratedColumn<bool> enabledExplore = GeneratedColumn<bool>(
    'enabled_explore',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled_explore" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _customOrderMeta = const VerificationMeta(
    'customOrder',
  );
  @override
  late final GeneratedColumn<int> customOrder = GeneratedColumn<int>(
    'custom_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _concurrentRateMeta = const VerificationMeta(
    'concurrentRate',
  );
  @override
  late final GeneratedColumn<int> concurrentRate = GeneratedColumn<int>(
    'concurrent_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTestAtMeta = const VerificationMeta(
    'lastTestAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastTestAt = GeneratedColumn<DateTime>(
    'last_test_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTestOkMeta = const VerificationMeta(
    'lastTestOk',
  );
  @override
  late final GeneratedColumn<bool> lastTestOk = GeneratedColumn<bool>(
    'last_test_ok',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_test_ok" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consecutiveFailuresMeta =
      const VerificationMeta('consecutiveFailures');
  @override
  late final GeneratedColumn<int> consecutiveFailures = GeneratedColumn<int>(
    'consecutive_failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    libraryRootId,
    sourceUrl,
    name,
    groupName,
    sourceType,
    rawJson,
    headerJson,
    exploreUrl,
    searchUrl,
    jsLib,
    enabled,
    enabledExplore,
    customOrder,
    concurrentRate,
    lastTestAt,
    lastTestOk,
    lastError,
    consecutiveFailures,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookSourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('library_root_id')) {
      context.handle(
        _libraryRootIdMeta,
        libraryRootId.isAcceptableOrUnknown(
          data['library_root_id']!,
          _libraryRootIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryRootIdMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('raw_json')) {
      context.handle(
        _rawJsonMeta,
        rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('header_json')) {
      context.handle(
        _headerJsonMeta,
        headerJson.isAcceptableOrUnknown(data['header_json']!, _headerJsonMeta),
      );
    }
    if (data.containsKey('explore_url')) {
      context.handle(
        _exploreUrlMeta,
        exploreUrl.isAcceptableOrUnknown(data['explore_url']!, _exploreUrlMeta),
      );
    }
    if (data.containsKey('search_url')) {
      context.handle(
        _searchUrlMeta,
        searchUrl.isAcceptableOrUnknown(data['search_url']!, _searchUrlMeta),
      );
    }
    if (data.containsKey('js_lib')) {
      context.handle(
        _jsLibMeta,
        jsLib.isAcceptableOrUnknown(data['js_lib']!, _jsLibMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('enabled_explore')) {
      context.handle(
        _enabledExploreMeta,
        enabledExplore.isAcceptableOrUnknown(
          data['enabled_explore']!,
          _enabledExploreMeta,
        ),
      );
    }
    if (data.containsKey('custom_order')) {
      context.handle(
        _customOrderMeta,
        customOrder.isAcceptableOrUnknown(
          data['custom_order']!,
          _customOrderMeta,
        ),
      );
    }
    if (data.containsKey('concurrent_rate')) {
      context.handle(
        _concurrentRateMeta,
        concurrentRate.isAcceptableOrUnknown(
          data['concurrent_rate']!,
          _concurrentRateMeta,
        ),
      );
    }
    if (data.containsKey('last_test_at')) {
      context.handle(
        _lastTestAtMeta,
        lastTestAt.isAcceptableOrUnknown(
          data['last_test_at']!,
          _lastTestAtMeta,
        ),
      );
    }
    if (data.containsKey('last_test_ok')) {
      context.handle(
        _lastTestOkMeta,
        lastTestOk.isAcceptableOrUnknown(
          data['last_test_ok']!,
          _lastTestOkMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('consecutive_failures')) {
      context.handle(
        _consecutiveFailuresMeta,
        consecutiveFailures.isAcceptableOrUnknown(
          data['consecutive_failures']!,
          _consecutiveFailuresMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookSourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookSourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      libraryRootId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_root_id'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_type'],
      )!,
      rawJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json'],
      )!,
      headerJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header_json'],
      ),
      exploreUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explore_url'],
      ),
      searchUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_url'],
      ),
      jsLib: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}js_lib'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      enabledExplore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled_explore'],
      )!,
      customOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}custom_order'],
      )!,
      concurrentRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}concurrent_rate'],
      ),
      lastTestAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_test_at'],
      ),
      lastTestOk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_test_ok'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      consecutiveFailures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_failures'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BookSourcesTable createAlias(String alias) {
    return $BookSourcesTable(attachedDatabase, alias);
  }
}

class BookSourceRow extends DataClass implements Insertable<BookSourceRow> {
  /// ULID。
  final String id;

  /// 虚拟书库根。
  final String libraryRootId;

  /// 规范化后的书源地址（身份）。
  final String sourceUrl;

  /// 书源名。
  final String name;

  /// Legado `bookSourceGroup`。
  final String? groupName;

  /// 书源类型；本阶段只接受 1（听书源）。
  final int sourceType;

  /// 原始 Legado JSON（未知字段也保留）。
  final String rawJson;

  /// 规范化后的 header JSON；不在此层解密或记录。
  final String? headerJson;

  /// Legado `exploreUrl`。
  final String? exploreUrl;

  /// Legado `searchUrl`。
  final String? searchUrl;

  /// Legado `jsLib`。
  final String? jsLib;

  /// 是否参与自动刷新 / 发现。
  final bool enabled;

  /// 是否出现在发现页。
  final bool enabledExplore;

  /// 用户排序值。
  final int customOrder;

  /// Legado `concurrentRate`（毫秒）。
  final int? concurrentRate;

  /// 最近一次源级测试。
  final DateTime? lastTestAt;

  /// 最近一次源级测试是否成功。
  final bool? lastTestOk;

  /// 最近一次源级错误（已脱敏）。
  final String? lastError;

  /// 连续失败次数。
  final int consecutiveFailures;

  /// 导入时间。
  final DateTime createdAt;

  /// 最近更新时间。
  final DateTime updatedAt;

  /// 软删除时间；非空表示来源不可用，但书目与进度保留。
  final DateTime? deletedAt;
  const BookSourceRow({
    required this.id,
    required this.libraryRootId,
    required this.sourceUrl,
    required this.name,
    this.groupName,
    required this.sourceType,
    required this.rawJson,
    this.headerJson,
    this.exploreUrl,
    this.searchUrl,
    this.jsLib,
    required this.enabled,
    required this.enabledExplore,
    required this.customOrder,
    this.concurrentRate,
    this.lastTestAt,
    this.lastTestOk,
    this.lastError,
    required this.consecutiveFailures,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['library_root_id'] = Variable<String>(libraryRootId);
    map['source_url'] = Variable<String>(sourceUrl);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    map['source_type'] = Variable<int>(sourceType);
    map['raw_json'] = Variable<String>(rawJson);
    if (!nullToAbsent || headerJson != null) {
      map['header_json'] = Variable<String>(headerJson);
    }
    if (!nullToAbsent || exploreUrl != null) {
      map['explore_url'] = Variable<String>(exploreUrl);
    }
    if (!nullToAbsent || searchUrl != null) {
      map['search_url'] = Variable<String>(searchUrl);
    }
    if (!nullToAbsent || jsLib != null) {
      map['js_lib'] = Variable<String>(jsLib);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['enabled_explore'] = Variable<bool>(enabledExplore);
    map['custom_order'] = Variable<int>(customOrder);
    if (!nullToAbsent || concurrentRate != null) {
      map['concurrent_rate'] = Variable<int>(concurrentRate);
    }
    if (!nullToAbsent || lastTestAt != null) {
      map['last_test_at'] = Variable<DateTime>(lastTestAt);
    }
    if (!nullToAbsent || lastTestOk != null) {
      map['last_test_ok'] = Variable<bool>(lastTestOk);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['consecutive_failures'] = Variable<int>(consecutiveFailures);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  BookSourcesCompanion toCompanion(bool nullToAbsent) {
    return BookSourcesCompanion(
      id: Value(id),
      libraryRootId: Value(libraryRootId),
      sourceUrl: Value(sourceUrl),
      name: Value(name),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      sourceType: Value(sourceType),
      rawJson: Value(rawJson),
      headerJson: headerJson == null && nullToAbsent
          ? const Value.absent()
          : Value(headerJson),
      exploreUrl: exploreUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(exploreUrl),
      searchUrl: searchUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(searchUrl),
      jsLib: jsLib == null && nullToAbsent
          ? const Value.absent()
          : Value(jsLib),
      enabled: Value(enabled),
      enabledExplore: Value(enabledExplore),
      customOrder: Value(customOrder),
      concurrentRate: concurrentRate == null && nullToAbsent
          ? const Value.absent()
          : Value(concurrentRate),
      lastTestAt: lastTestAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTestAt),
      lastTestOk: lastTestOk == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTestOk),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      consecutiveFailures: Value(consecutiveFailures),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BookSourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookSourceRow(
      id: serializer.fromJson<String>(json['id']),
      libraryRootId: serializer.fromJson<String>(json['libraryRootId']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      name: serializer.fromJson<String>(json['name']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      sourceType: serializer.fromJson<int>(json['sourceType']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      headerJson: serializer.fromJson<String?>(json['headerJson']),
      exploreUrl: serializer.fromJson<String?>(json['exploreUrl']),
      searchUrl: serializer.fromJson<String?>(json['searchUrl']),
      jsLib: serializer.fromJson<String?>(json['jsLib']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      enabledExplore: serializer.fromJson<bool>(json['enabledExplore']),
      customOrder: serializer.fromJson<int>(json['customOrder']),
      concurrentRate: serializer.fromJson<int?>(json['concurrentRate']),
      lastTestAt: serializer.fromJson<DateTime?>(json['lastTestAt']),
      lastTestOk: serializer.fromJson<bool?>(json['lastTestOk']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      consecutiveFailures: serializer.fromJson<int>(
        json['consecutiveFailures'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'libraryRootId': serializer.toJson<String>(libraryRootId),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'name': serializer.toJson<String>(name),
      'groupName': serializer.toJson<String?>(groupName),
      'sourceType': serializer.toJson<int>(sourceType),
      'rawJson': serializer.toJson<String>(rawJson),
      'headerJson': serializer.toJson<String?>(headerJson),
      'exploreUrl': serializer.toJson<String?>(exploreUrl),
      'searchUrl': serializer.toJson<String?>(searchUrl),
      'jsLib': serializer.toJson<String?>(jsLib),
      'enabled': serializer.toJson<bool>(enabled),
      'enabledExplore': serializer.toJson<bool>(enabledExplore),
      'customOrder': serializer.toJson<int>(customOrder),
      'concurrentRate': serializer.toJson<int?>(concurrentRate),
      'lastTestAt': serializer.toJson<DateTime?>(lastTestAt),
      'lastTestOk': serializer.toJson<bool?>(lastTestOk),
      'lastError': serializer.toJson<String?>(lastError),
      'consecutiveFailures': serializer.toJson<int>(consecutiveFailures),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  BookSourceRow copyWith({
    String? id,
    String? libraryRootId,
    String? sourceUrl,
    String? name,
    Value<String?> groupName = const Value.absent(),
    int? sourceType,
    String? rawJson,
    Value<String?> headerJson = const Value.absent(),
    Value<String?> exploreUrl = const Value.absent(),
    Value<String?> searchUrl = const Value.absent(),
    Value<String?> jsLib = const Value.absent(),
    bool? enabled,
    bool? enabledExplore,
    int? customOrder,
    Value<int?> concurrentRate = const Value.absent(),
    Value<DateTime?> lastTestAt = const Value.absent(),
    Value<bool?> lastTestOk = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? consecutiveFailures,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => BookSourceRow(
    id: id ?? this.id,
    libraryRootId: libraryRootId ?? this.libraryRootId,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    name: name ?? this.name,
    groupName: groupName.present ? groupName.value : this.groupName,
    sourceType: sourceType ?? this.sourceType,
    rawJson: rawJson ?? this.rawJson,
    headerJson: headerJson.present ? headerJson.value : this.headerJson,
    exploreUrl: exploreUrl.present ? exploreUrl.value : this.exploreUrl,
    searchUrl: searchUrl.present ? searchUrl.value : this.searchUrl,
    jsLib: jsLib.present ? jsLib.value : this.jsLib,
    enabled: enabled ?? this.enabled,
    enabledExplore: enabledExplore ?? this.enabledExplore,
    customOrder: customOrder ?? this.customOrder,
    concurrentRate: concurrentRate.present
        ? concurrentRate.value
        : this.concurrentRate,
    lastTestAt: lastTestAt.present ? lastTestAt.value : this.lastTestAt,
    lastTestOk: lastTestOk.present ? lastTestOk.value : this.lastTestOk,
    lastError: lastError.present ? lastError.value : this.lastError,
    consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BookSourceRow copyWithCompanion(BookSourcesCompanion data) {
    return BookSourceRow(
      id: data.id.present ? data.id.value : this.id,
      libraryRootId: data.libraryRootId.present
          ? data.libraryRootId.value
          : this.libraryRootId,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      name: data.name.present ? data.name.value : this.name,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      headerJson: data.headerJson.present
          ? data.headerJson.value
          : this.headerJson,
      exploreUrl: data.exploreUrl.present
          ? data.exploreUrl.value
          : this.exploreUrl,
      searchUrl: data.searchUrl.present ? data.searchUrl.value : this.searchUrl,
      jsLib: data.jsLib.present ? data.jsLib.value : this.jsLib,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      enabledExplore: data.enabledExplore.present
          ? data.enabledExplore.value
          : this.enabledExplore,
      customOrder: data.customOrder.present
          ? data.customOrder.value
          : this.customOrder,
      concurrentRate: data.concurrentRate.present
          ? data.concurrentRate.value
          : this.concurrentRate,
      lastTestAt: data.lastTestAt.present
          ? data.lastTestAt.value
          : this.lastTestAt,
      lastTestOk: data.lastTestOk.present
          ? data.lastTestOk.value
          : this.lastTestOk,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      consecutiveFailures: data.consecutiveFailures.present
          ? data.consecutiveFailures.value
          : this.consecutiveFailures,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookSourceRow(')
          ..write('id: $id, ')
          ..write('libraryRootId: $libraryRootId, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('name: $name, ')
          ..write('groupName: $groupName, ')
          ..write('sourceType: $sourceType, ')
          ..write('rawJson: $rawJson, ')
          ..write('headerJson: $headerJson, ')
          ..write('exploreUrl: $exploreUrl, ')
          ..write('searchUrl: $searchUrl, ')
          ..write('jsLib: $jsLib, ')
          ..write('enabled: $enabled, ')
          ..write('enabledExplore: $enabledExplore, ')
          ..write('customOrder: $customOrder, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('lastTestAt: $lastTestAt, ')
          ..write('lastTestOk: $lastTestOk, ')
          ..write('lastError: $lastError, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    libraryRootId,
    sourceUrl,
    name,
    groupName,
    sourceType,
    rawJson,
    headerJson,
    exploreUrl,
    searchUrl,
    jsLib,
    enabled,
    enabledExplore,
    customOrder,
    concurrentRate,
    lastTestAt,
    lastTestOk,
    lastError,
    consecutiveFailures,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookSourceRow &&
          other.id == this.id &&
          other.libraryRootId == this.libraryRootId &&
          other.sourceUrl == this.sourceUrl &&
          other.name == this.name &&
          other.groupName == this.groupName &&
          other.sourceType == this.sourceType &&
          other.rawJson == this.rawJson &&
          other.headerJson == this.headerJson &&
          other.exploreUrl == this.exploreUrl &&
          other.searchUrl == this.searchUrl &&
          other.jsLib == this.jsLib &&
          other.enabled == this.enabled &&
          other.enabledExplore == this.enabledExplore &&
          other.customOrder == this.customOrder &&
          other.concurrentRate == this.concurrentRate &&
          other.lastTestAt == this.lastTestAt &&
          other.lastTestOk == this.lastTestOk &&
          other.lastError == this.lastError &&
          other.consecutiveFailures == this.consecutiveFailures &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BookSourcesCompanion extends UpdateCompanion<BookSourceRow> {
  final Value<String> id;
  final Value<String> libraryRootId;
  final Value<String> sourceUrl;
  final Value<String> name;
  final Value<String?> groupName;
  final Value<int> sourceType;
  final Value<String> rawJson;
  final Value<String?> headerJson;
  final Value<String?> exploreUrl;
  final Value<String?> searchUrl;
  final Value<String?> jsLib;
  final Value<bool> enabled;
  final Value<bool> enabledExplore;
  final Value<int> customOrder;
  final Value<int?> concurrentRate;
  final Value<DateTime?> lastTestAt;
  final Value<bool?> lastTestOk;
  final Value<String?> lastError;
  final Value<int> consecutiveFailures;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const BookSourcesCompanion({
    this.id = const Value.absent(),
    this.libraryRootId = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.name = const Value.absent(),
    this.groupName = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.headerJson = const Value.absent(),
    this.exploreUrl = const Value.absent(),
    this.searchUrl = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.enabled = const Value.absent(),
    this.enabledExplore = const Value.absent(),
    this.customOrder = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.lastTestAt = const Value.absent(),
    this.lastTestOk = const Value.absent(),
    this.lastError = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookSourcesCompanion.insert({
    required String id,
    required String libraryRootId,
    required String sourceUrl,
    required String name,
    this.groupName = const Value.absent(),
    required int sourceType,
    required String rawJson,
    this.headerJson = const Value.absent(),
    this.exploreUrl = const Value.absent(),
    this.searchUrl = const Value.absent(),
    this.jsLib = const Value.absent(),
    this.enabled = const Value.absent(),
    this.enabledExplore = const Value.absent(),
    this.customOrder = const Value.absent(),
    this.concurrentRate = const Value.absent(),
    this.lastTestAt = const Value.absent(),
    this.lastTestOk = const Value.absent(),
    this.lastError = const Value.absent(),
    this.consecutiveFailures = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       libraryRootId = Value(libraryRootId),
       sourceUrl = Value(sourceUrl),
       name = Value(name),
       sourceType = Value(sourceType),
       rawJson = Value(rawJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BookSourceRow> custom({
    Expression<String>? id,
    Expression<String>? libraryRootId,
    Expression<String>? sourceUrl,
    Expression<String>? name,
    Expression<String>? groupName,
    Expression<int>? sourceType,
    Expression<String>? rawJson,
    Expression<String>? headerJson,
    Expression<String>? exploreUrl,
    Expression<String>? searchUrl,
    Expression<String>? jsLib,
    Expression<bool>? enabled,
    Expression<bool>? enabledExplore,
    Expression<int>? customOrder,
    Expression<int>? concurrentRate,
    Expression<DateTime>? lastTestAt,
    Expression<bool>? lastTestOk,
    Expression<String>? lastError,
    Expression<int>? consecutiveFailures,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryRootId != null) 'library_root_id': libraryRootId,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (name != null) 'name': name,
      if (groupName != null) 'group_name': groupName,
      if (sourceType != null) 'source_type': sourceType,
      if (rawJson != null) 'raw_json': rawJson,
      if (headerJson != null) 'header_json': headerJson,
      if (exploreUrl != null) 'explore_url': exploreUrl,
      if (searchUrl != null) 'search_url': searchUrl,
      if (jsLib != null) 'js_lib': jsLib,
      if (enabled != null) 'enabled': enabled,
      if (enabledExplore != null) 'enabled_explore': enabledExplore,
      if (customOrder != null) 'custom_order': customOrder,
      if (concurrentRate != null) 'concurrent_rate': concurrentRate,
      if (lastTestAt != null) 'last_test_at': lastTestAt,
      if (lastTestOk != null) 'last_test_ok': lastTestOk,
      if (lastError != null) 'last_error': lastError,
      if (consecutiveFailures != null)
        'consecutive_failures': consecutiveFailures,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? libraryRootId,
    Value<String>? sourceUrl,
    Value<String>? name,
    Value<String?>? groupName,
    Value<int>? sourceType,
    Value<String>? rawJson,
    Value<String?>? headerJson,
    Value<String?>? exploreUrl,
    Value<String?>? searchUrl,
    Value<String?>? jsLib,
    Value<bool>? enabled,
    Value<bool>? enabledExplore,
    Value<int>? customOrder,
    Value<int?>? concurrentRate,
    Value<DateTime?>? lastTestAt,
    Value<bool?>? lastTestOk,
    Value<String?>? lastError,
    Value<int>? consecutiveFailures,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BookSourcesCompanion(
      id: id ?? this.id,
      libraryRootId: libraryRootId ?? this.libraryRootId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      name: name ?? this.name,
      groupName: groupName ?? this.groupName,
      sourceType: sourceType ?? this.sourceType,
      rawJson: rawJson ?? this.rawJson,
      headerJson: headerJson ?? this.headerJson,
      exploreUrl: exploreUrl ?? this.exploreUrl,
      searchUrl: searchUrl ?? this.searchUrl,
      jsLib: jsLib ?? this.jsLib,
      enabled: enabled ?? this.enabled,
      enabledExplore: enabledExplore ?? this.enabledExplore,
      customOrder: customOrder ?? this.customOrder,
      concurrentRate: concurrentRate ?? this.concurrentRate,
      lastTestAt: lastTestAt ?? this.lastTestAt,
      lastTestOk: lastTestOk ?? this.lastTestOk,
      lastError: lastError ?? this.lastError,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (libraryRootId.present) {
      map['library_root_id'] = Variable<String>(libraryRootId.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<int>(sourceType.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (headerJson.present) {
      map['header_json'] = Variable<String>(headerJson.value);
    }
    if (exploreUrl.present) {
      map['explore_url'] = Variable<String>(exploreUrl.value);
    }
    if (searchUrl.present) {
      map['search_url'] = Variable<String>(searchUrl.value);
    }
    if (jsLib.present) {
      map['js_lib'] = Variable<String>(jsLib.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (enabledExplore.present) {
      map['enabled_explore'] = Variable<bool>(enabledExplore.value);
    }
    if (customOrder.present) {
      map['custom_order'] = Variable<int>(customOrder.value);
    }
    if (concurrentRate.present) {
      map['concurrent_rate'] = Variable<int>(concurrentRate.value);
    }
    if (lastTestAt.present) {
      map['last_test_at'] = Variable<DateTime>(lastTestAt.value);
    }
    if (lastTestOk.present) {
      map['last_test_ok'] = Variable<bool>(lastTestOk.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (consecutiveFailures.present) {
      map['consecutive_failures'] = Variable<int>(consecutiveFailures.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookSourcesCompanion(')
          ..write('id: $id, ')
          ..write('libraryRootId: $libraryRootId, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('name: $name, ')
          ..write('groupName: $groupName, ')
          ..write('sourceType: $sourceType, ')
          ..write('rawJson: $rawJson, ')
          ..write('headerJson: $headerJson, ')
          ..write('exploreUrl: $exploreUrl, ')
          ..write('searchUrl: $searchUrl, ')
          ..write('jsLib: $jsLib, ')
          ..write('enabled: $enabled, ')
          ..write('enabledExplore: $enabledExplore, ')
          ..write('customOrder: $customOrder, ')
          ..write('concurrentRate: $concurrentRate, ')
          ..write('lastTestAt: $lastTestAt, ')
          ..write('lastTestOk: $lastTestOk, ')
          ..write('lastError: $lastError, ')
          ..write('consecutiveFailures: $consecutiveFailures, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libraryRootIdMeta = const VerificationMeta(
    'libraryRootId',
  );
  @override
  late final GeneratedColumn<String> libraryRootId = GeneratedColumn<String>(
    'library_root_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_roots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _narratorMeta = const VerificationMeta(
    'narrator',
  );
  @override
  late final GeneratedColumn<String> narrator = GeneratedColumn<String>(
    'narrator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesNameMeta = const VerificationMeta(
    'seriesName',
  );
  @override
  late final GeneratedColumn<String> seriesName = GeneratedColumn<String>(
    'series_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIndexMeta = const VerificationMeta(
    'seriesIndex',
  );
  @override
  late final GeneratedColumn<int> seriesIndex = GeneratedColumn<int>(
    'series_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootPathMeta = const VerificationMeta(
    'rootPath',
  );
  @override
  late final GeneratedColumn<String> rootPath = GeneratedColumn<String>(
    'root_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CoverSource, int>
  coverSourceType = GeneratedColumn<int>(
    'cover_source_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(CoverSource.typographyRank),
  ).withConverter<CoverSource>($BooksTable.$convertercoverSourceType);
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUriMeta = const VerificationMeta(
    'sourceUri',
  );
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
    'source_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalChaptersMeta = const VerificationMeta(
    'totalChapters',
  );
  @override
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
    'total_chapters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDurationMsMeta = const VerificationMeta(
    'totalDurationMs',
  );
  @override
  late final GeneratedColumn<int> totalDurationMs = GeneratedColumn<int>(
    'total_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onShelfMeta = const VerificationMeta(
    'onShelf',
  );
  @override
  late final GeneratedColumn<bool> onShelf = GeneratedColumn<bool>(
    'on_shelf',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_shelf" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES book_sources (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<String> wordCount = GeneratedColumn<String>(
    'word_count',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceStatusMeta = const VerificationMeta(
    'sourceStatus',
  );
  @override
  late final GeneratedColumn<String> sourceStatus = GeneratedColumn<String>(
    'source_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastChapterMeta = const VerificationMeta(
    'lastChapter',
  );
  @override
  late final GeneratedColumn<String> lastChapter = GeneratedColumn<String>(
    'last_chapter',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUpdatedAtMeta = const VerificationMeta(
    'sourceUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceUpdatedAt =
      GeneratedColumn<DateTime>(
        'source_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastRefreshAtMeta = const VerificationMeta(
    'lastRefreshAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRefreshAt =
      GeneratedColumn<DateTime>(
        'last_refresh_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastRefreshOkMeta = const VerificationMeta(
    'lastRefreshOk',
  );
  @override
  late final GeneratedColumn<bool> lastRefreshOk = GeneratedColumn<bool>(
    'last_refresh_ok',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("last_refresh_ok" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastRefreshErrorMeta = const VerificationMeta(
    'lastRefreshError',
  );
  @override
  late final GeneratedColumn<String> lastRefreshError = GeneratedColumn<String>(
    'last_refresh_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    libraryRootId,
    title,
    author,
    narrator,
    seriesName,
    seriesIndex,
    rootPath,
    coverPath,
    coverSourceType,
    sourceType,
    sourceUri,
    totalChapters,
    totalDurationMs,
    createdAt,
    updatedAt,
    onShelf,
    sourceId,
    coverUrl,
    description,
    kind,
    wordCount,
    sourceStatus,
    lastChapter,
    sourceUpdatedAt,
    lastRefreshAt,
    lastRefreshOk,
    lastRefreshError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('library_root_id')) {
      context.handle(
        _libraryRootIdMeta,
        libraryRootId.isAcceptableOrUnknown(
          data['library_root_id']!,
          _libraryRootIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryRootIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('narrator')) {
      context.handle(
        _narratorMeta,
        narrator.isAcceptableOrUnknown(data['narrator']!, _narratorMeta),
      );
    }
    if (data.containsKey('series_name')) {
      context.handle(
        _seriesNameMeta,
        seriesName.isAcceptableOrUnknown(data['series_name']!, _seriesNameMeta),
      );
    }
    if (data.containsKey('series_index')) {
      context.handle(
        _seriesIndexMeta,
        seriesIndex.isAcceptableOrUnknown(
          data['series_index']!,
          _seriesIndexMeta,
        ),
      );
    }
    if (data.containsKey('root_path')) {
      context.handle(
        _rootPathMeta,
        rootPath.isAcceptableOrUnknown(data['root_path']!, _rootPathMeta),
      );
    } else if (isInserting) {
      context.missing(_rootPathMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_uri')) {
      context.handle(
        _sourceUriMeta,
        sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta),
      );
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
        _totalChaptersMeta,
        totalChapters.isAcceptableOrUnknown(
          data['total_chapters']!,
          _totalChaptersMeta,
        ),
      );
    }
    if (data.containsKey('total_duration_ms')) {
      context.handle(
        _totalDurationMsMeta,
        totalDurationMs.isAcceptableOrUnknown(
          data['total_duration_ms']!,
          _totalDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('on_shelf')) {
      context.handle(
        _onShelfMeta,
        onShelf.isAcceptableOrUnknown(data['on_shelf']!, _onShelfMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    if (data.containsKey('source_status')) {
      context.handle(
        _sourceStatusMeta,
        sourceStatus.isAcceptableOrUnknown(
          data['source_status']!,
          _sourceStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_chapter')) {
      context.handle(
        _lastChapterMeta,
        lastChapter.isAcceptableOrUnknown(
          data['last_chapter']!,
          _lastChapterMeta,
        ),
      );
    }
    if (data.containsKey('source_updated_at')) {
      context.handle(
        _sourceUpdatedAtMeta,
        sourceUpdatedAt.isAcceptableOrUnknown(
          data['source_updated_at']!,
          _sourceUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_refresh_at')) {
      context.handle(
        _lastRefreshAtMeta,
        lastRefreshAt.isAcceptableOrUnknown(
          data['last_refresh_at']!,
          _lastRefreshAtMeta,
        ),
      );
    }
    if (data.containsKey('last_refresh_ok')) {
      context.handle(
        _lastRefreshOkMeta,
        lastRefreshOk.isAcceptableOrUnknown(
          data['last_refresh_ok']!,
          _lastRefreshOkMeta,
        ),
      );
    }
    if (data.containsKey('last_refresh_error')) {
      context.handle(
        _lastRefreshErrorMeta,
        lastRefreshError.isAcceptableOrUnknown(
          data['last_refresh_error']!,
          _lastRefreshErrorMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      libraryRootId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_root_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      narrator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrator'],
      ),
      seriesName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_name'],
      ),
      seriesIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_index'],
      ),
      rootPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_path'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      coverSourceType: $BooksTable.$convertercoverSourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}cover_source_type'],
        )!,
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_uri'],
      ),
      totalChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chapters'],
      )!,
      totalDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_duration_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      onShelf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_shelf'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_count'],
      ),
      sourceStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_status'],
      ),
      lastChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_chapter'],
      ),
      sourceUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_updated_at'],
      ),
      lastRefreshAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_refresh_at'],
      ),
      lastRefreshOk: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}last_refresh_ok'],
      ),
      lastRefreshError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_refresh_error'],
      ),
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }

  static TypeConverter<CoverSource, int> $convertercoverSourceType =
      const CoverSourceConverter();
}

class Book extends DataClass implements Insertable<Book> {
  /// ULID，不可变。
  final String id;

  /// 所属书库根。
  final String libraryRootId;

  /// 书名（可被元数据覆盖层覆盖）。
  final String title;

  /// 作者。
  final String? author;

  /// 演播者。
  final String? narrator;

  /// 系列名。
  final String? seriesName;

  /// 系列序号。
  final int? seriesIndex;

  /// 书根相对路径（NFC 规范化，相对 `library_roots.uri`）。
  final String rootPath;

  /// 封面路径（**相对书库根**，与 `chapters.file_path` 同语义）；
  /// 为空时由 UI 走几何字标兜底。
  final String? coverPath;

  /// 封面来源档位（§2.1 五级继承）。枚举顺序即优先级，见 [CoverSource]。
  ///
  /// SQL 默认 4 = `CoverSource.typography.rank`（字标兜底）。
  /// 静态类型是 `IntColumn`（DSL 的 `map` 只做标记），生成器会把 Dart 侧类型
  /// 提升为 `CoverSource`。
  final CoverSource coverSourceType;

  /// `local` / `saf` / `webdav`。
  final String sourceType;

  /// provider 侧源地址；本地源为空。
  final String? sourceUri;

  /// 章节总数（冗余，供书库列表直接展示）。
  final int totalChapters;

  /// 总时长毫秒（冗余，第二阶段异步回填）。
  final int totalDurationMs;

  /// 加入时间。
  final DateTime createdAt;

  /// 最近更新时间。
  final DateTime updatedAt;

  /// 是否在书架展示。在线书首次收听/加入书架后为 true；本机书默认 true。
  final bool onShelf;

  /// 在线书来源；本机书为空。
  final String? sourceId;

  /// 在线封面 URL；本机封面仍走 [coverPath]。
  final String? coverUrl;

  /// 在线简介（覆盖层优先）。
  final String? description;

  /// 在线书类型 / 标签（Legado bookInfo.kind）。
  final String? kind;

  /// 在线字数（原样文本，可能含“万字”）。
  final String? wordCount;

  /// 在线书状态（连载 / 完结等，原样文本）。
  final String? sourceStatus;

  /// 在线书最新章名（列表展示用）。
  final String? lastChapter;

  /// 源侧最近更新时间。
  final DateTime? sourceUpdatedAt;

  /// 最近一次刷新信息时间。
  final DateTime? lastRefreshAt;

  /// 最近一次刷新是否成功。
  final bool? lastRefreshOk;

  /// 最近一次刷新错误（已脱敏）。
  final String? lastRefreshError;
  const Book({
    required this.id,
    required this.libraryRootId,
    required this.title,
    this.author,
    this.narrator,
    this.seriesName,
    this.seriesIndex,
    required this.rootPath,
    this.coverPath,
    required this.coverSourceType,
    required this.sourceType,
    this.sourceUri,
    required this.totalChapters,
    required this.totalDurationMs,
    required this.createdAt,
    required this.updatedAt,
    required this.onShelf,
    this.sourceId,
    this.coverUrl,
    this.description,
    this.kind,
    this.wordCount,
    this.sourceStatus,
    this.lastChapter,
    this.sourceUpdatedAt,
    this.lastRefreshAt,
    this.lastRefreshOk,
    this.lastRefreshError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['library_root_id'] = Variable<String>(libraryRootId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || narrator != null) {
      map['narrator'] = Variable<String>(narrator);
    }
    if (!nullToAbsent || seriesName != null) {
      map['series_name'] = Variable<String>(seriesName);
    }
    if (!nullToAbsent || seriesIndex != null) {
      map['series_index'] = Variable<int>(seriesIndex);
    }
    map['root_path'] = Variable<String>(rootPath);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    {
      map['cover_source_type'] = Variable<int>(
        $BooksTable.$convertercoverSourceType.toSql(coverSourceType),
      );
    }
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceUri != null) {
      map['source_uri'] = Variable<String>(sourceUri);
    }
    map['total_chapters'] = Variable<int>(totalChapters);
    map['total_duration_ms'] = Variable<int>(totalDurationMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['on_shelf'] = Variable<bool>(onShelf);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || wordCount != null) {
      map['word_count'] = Variable<String>(wordCount);
    }
    if (!nullToAbsent || sourceStatus != null) {
      map['source_status'] = Variable<String>(sourceStatus);
    }
    if (!nullToAbsent || lastChapter != null) {
      map['last_chapter'] = Variable<String>(lastChapter);
    }
    if (!nullToAbsent || sourceUpdatedAt != null) {
      map['source_updated_at'] = Variable<DateTime>(sourceUpdatedAt);
    }
    if (!nullToAbsent || lastRefreshAt != null) {
      map['last_refresh_at'] = Variable<DateTime>(lastRefreshAt);
    }
    if (!nullToAbsent || lastRefreshOk != null) {
      map['last_refresh_ok'] = Variable<bool>(lastRefreshOk);
    }
    if (!nullToAbsent || lastRefreshError != null) {
      map['last_refresh_error'] = Variable<String>(lastRefreshError);
    }
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      libraryRootId: Value(libraryRootId),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      narrator: narrator == null && nullToAbsent
          ? const Value.absent()
          : Value(narrator),
      seriesName: seriesName == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesName),
      seriesIndex: seriesIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesIndex),
      rootPath: Value(rootPath),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      coverSourceType: Value(coverSourceType),
      sourceType: Value(sourceType),
      sourceUri: sourceUri == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUri),
      totalChapters: Value(totalChapters),
      totalDurationMs: Value(totalDurationMs),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      onShelf: Value(onShelf),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      wordCount: wordCount == null && nullToAbsent
          ? const Value.absent()
          : Value(wordCount),
      sourceStatus: sourceStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceStatus),
      lastChapter: lastChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(lastChapter),
      sourceUpdatedAt: sourceUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUpdatedAt),
      lastRefreshAt: lastRefreshAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefreshAt),
      lastRefreshOk: lastRefreshOk == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefreshOk),
      lastRefreshError: lastRefreshError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefreshError),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      libraryRootId: serializer.fromJson<String>(json['libraryRootId']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      narrator: serializer.fromJson<String?>(json['narrator']),
      seriesName: serializer.fromJson<String?>(json['seriesName']),
      seriesIndex: serializer.fromJson<int?>(json['seriesIndex']),
      rootPath: serializer.fromJson<String>(json['rootPath']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      coverSourceType: serializer.fromJson<CoverSource>(
        json['coverSourceType'],
      ),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceUri: serializer.fromJson<String?>(json['sourceUri']),
      totalChapters: serializer.fromJson<int>(json['totalChapters']),
      totalDurationMs: serializer.fromJson<int>(json['totalDurationMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      onShelf: serializer.fromJson<bool>(json['onShelf']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      description: serializer.fromJson<String?>(json['description']),
      kind: serializer.fromJson<String?>(json['kind']),
      wordCount: serializer.fromJson<String?>(json['wordCount']),
      sourceStatus: serializer.fromJson<String?>(json['sourceStatus']),
      lastChapter: serializer.fromJson<String?>(json['lastChapter']),
      sourceUpdatedAt: serializer.fromJson<DateTime?>(json['sourceUpdatedAt']),
      lastRefreshAt: serializer.fromJson<DateTime?>(json['lastRefreshAt']),
      lastRefreshOk: serializer.fromJson<bool?>(json['lastRefreshOk']),
      lastRefreshError: serializer.fromJson<String?>(json['lastRefreshError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'libraryRootId': serializer.toJson<String>(libraryRootId),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'narrator': serializer.toJson<String?>(narrator),
      'seriesName': serializer.toJson<String?>(seriesName),
      'seriesIndex': serializer.toJson<int?>(seriesIndex),
      'rootPath': serializer.toJson<String>(rootPath),
      'coverPath': serializer.toJson<String?>(coverPath),
      'coverSourceType': serializer.toJson<CoverSource>(coverSourceType),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceUri': serializer.toJson<String?>(sourceUri),
      'totalChapters': serializer.toJson<int>(totalChapters),
      'totalDurationMs': serializer.toJson<int>(totalDurationMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'onShelf': serializer.toJson<bool>(onShelf),
      'sourceId': serializer.toJson<String?>(sourceId),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'description': serializer.toJson<String?>(description),
      'kind': serializer.toJson<String?>(kind),
      'wordCount': serializer.toJson<String?>(wordCount),
      'sourceStatus': serializer.toJson<String?>(sourceStatus),
      'lastChapter': serializer.toJson<String?>(lastChapter),
      'sourceUpdatedAt': serializer.toJson<DateTime?>(sourceUpdatedAt),
      'lastRefreshAt': serializer.toJson<DateTime?>(lastRefreshAt),
      'lastRefreshOk': serializer.toJson<bool?>(lastRefreshOk),
      'lastRefreshError': serializer.toJson<String?>(lastRefreshError),
    };
  }

  Book copyWith({
    String? id,
    String? libraryRootId,
    String? title,
    Value<String?> author = const Value.absent(),
    Value<String?> narrator = const Value.absent(),
    Value<String?> seriesName = const Value.absent(),
    Value<int?> seriesIndex = const Value.absent(),
    String? rootPath,
    Value<String?> coverPath = const Value.absent(),
    CoverSource? coverSourceType,
    String? sourceType,
    Value<String?> sourceUri = const Value.absent(),
    int? totalChapters,
    int? totalDurationMs,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? onShelf,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    Value<String?> wordCount = const Value.absent(),
    Value<String?> sourceStatus = const Value.absent(),
    Value<String?> lastChapter = const Value.absent(),
    Value<DateTime?> sourceUpdatedAt = const Value.absent(),
    Value<DateTime?> lastRefreshAt = const Value.absent(),
    Value<bool?> lastRefreshOk = const Value.absent(),
    Value<String?> lastRefreshError = const Value.absent(),
  }) => Book(
    id: id ?? this.id,
    libraryRootId: libraryRootId ?? this.libraryRootId,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    narrator: narrator.present ? narrator.value : this.narrator,
    seriesName: seriesName.present ? seriesName.value : this.seriesName,
    seriesIndex: seriesIndex.present ? seriesIndex.value : this.seriesIndex,
    rootPath: rootPath ?? this.rootPath,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    coverSourceType: coverSourceType ?? this.coverSourceType,
    sourceType: sourceType ?? this.sourceType,
    sourceUri: sourceUri.present ? sourceUri.value : this.sourceUri,
    totalChapters: totalChapters ?? this.totalChapters,
    totalDurationMs: totalDurationMs ?? this.totalDurationMs,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    onShelf: onShelf ?? this.onShelf,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    description: description.present ? description.value : this.description,
    kind: kind.present ? kind.value : this.kind,
    wordCount: wordCount.present ? wordCount.value : this.wordCount,
    sourceStatus: sourceStatus.present ? sourceStatus.value : this.sourceStatus,
    lastChapter: lastChapter.present ? lastChapter.value : this.lastChapter,
    sourceUpdatedAt: sourceUpdatedAt.present
        ? sourceUpdatedAt.value
        : this.sourceUpdatedAt,
    lastRefreshAt: lastRefreshAt.present
        ? lastRefreshAt.value
        : this.lastRefreshAt,
    lastRefreshOk: lastRefreshOk.present
        ? lastRefreshOk.value
        : this.lastRefreshOk,
    lastRefreshError: lastRefreshError.present
        ? lastRefreshError.value
        : this.lastRefreshError,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      libraryRootId: data.libraryRootId.present
          ? data.libraryRootId.value
          : this.libraryRootId,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      narrator: data.narrator.present ? data.narrator.value : this.narrator,
      seriesName: data.seriesName.present
          ? data.seriesName.value
          : this.seriesName,
      seriesIndex: data.seriesIndex.present
          ? data.seriesIndex.value
          : this.seriesIndex,
      rootPath: data.rootPath.present ? data.rootPath.value : this.rootPath,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      coverSourceType: data.coverSourceType.present
          ? data.coverSourceType.value
          : this.coverSourceType,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      totalDurationMs: data.totalDurationMs.present
          ? data.totalDurationMs.value
          : this.totalDurationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      onShelf: data.onShelf.present ? data.onShelf.value : this.onShelf,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
      kind: data.kind.present ? data.kind.value : this.kind,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      sourceStatus: data.sourceStatus.present
          ? data.sourceStatus.value
          : this.sourceStatus,
      lastChapter: data.lastChapter.present
          ? data.lastChapter.value
          : this.lastChapter,
      sourceUpdatedAt: data.sourceUpdatedAt.present
          ? data.sourceUpdatedAt.value
          : this.sourceUpdatedAt,
      lastRefreshAt: data.lastRefreshAt.present
          ? data.lastRefreshAt.value
          : this.lastRefreshAt,
      lastRefreshOk: data.lastRefreshOk.present
          ? data.lastRefreshOk.value
          : this.lastRefreshOk,
      lastRefreshError: data.lastRefreshError.present
          ? data.lastRefreshError.value
          : this.lastRefreshError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('libraryRootId: $libraryRootId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('narrator: $narrator, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('rootPath: $rootPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('coverSourceType: $coverSourceType, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('onShelf: $onShelf, ')
          ..write('sourceId: $sourceId, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('description: $description, ')
          ..write('kind: $kind, ')
          ..write('wordCount: $wordCount, ')
          ..write('sourceStatus: $sourceStatus, ')
          ..write('lastChapter: $lastChapter, ')
          ..write('sourceUpdatedAt: $sourceUpdatedAt, ')
          ..write('lastRefreshAt: $lastRefreshAt, ')
          ..write('lastRefreshOk: $lastRefreshOk, ')
          ..write('lastRefreshError: $lastRefreshError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    libraryRootId,
    title,
    author,
    narrator,
    seriesName,
    seriesIndex,
    rootPath,
    coverPath,
    coverSourceType,
    sourceType,
    sourceUri,
    totalChapters,
    totalDurationMs,
    createdAt,
    updatedAt,
    onShelf,
    sourceId,
    coverUrl,
    description,
    kind,
    wordCount,
    sourceStatus,
    lastChapter,
    sourceUpdatedAt,
    lastRefreshAt,
    lastRefreshOk,
    lastRefreshError,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.libraryRootId == this.libraryRootId &&
          other.title == this.title &&
          other.author == this.author &&
          other.narrator == this.narrator &&
          other.seriesName == this.seriesName &&
          other.seriesIndex == this.seriesIndex &&
          other.rootPath == this.rootPath &&
          other.coverPath == this.coverPath &&
          other.coverSourceType == this.coverSourceType &&
          other.sourceType == this.sourceType &&
          other.sourceUri == this.sourceUri &&
          other.totalChapters == this.totalChapters &&
          other.totalDurationMs == this.totalDurationMs &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.onShelf == this.onShelf &&
          other.sourceId == this.sourceId &&
          other.coverUrl == this.coverUrl &&
          other.description == this.description &&
          other.kind == this.kind &&
          other.wordCount == this.wordCount &&
          other.sourceStatus == this.sourceStatus &&
          other.lastChapter == this.lastChapter &&
          other.sourceUpdatedAt == this.sourceUpdatedAt &&
          other.lastRefreshAt == this.lastRefreshAt &&
          other.lastRefreshOk == this.lastRefreshOk &&
          other.lastRefreshError == this.lastRefreshError);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String> libraryRootId;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> narrator;
  final Value<String?> seriesName;
  final Value<int?> seriesIndex;
  final Value<String> rootPath;
  final Value<String?> coverPath;
  final Value<CoverSource> coverSourceType;
  final Value<String> sourceType;
  final Value<String?> sourceUri;
  final Value<int> totalChapters;
  final Value<int> totalDurationMs;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> onShelf;
  final Value<String?> sourceId;
  final Value<String?> coverUrl;
  final Value<String?> description;
  final Value<String?> kind;
  final Value<String?> wordCount;
  final Value<String?> sourceStatus;
  final Value<String?> lastChapter;
  final Value<DateTime?> sourceUpdatedAt;
  final Value<DateTime?> lastRefreshAt;
  final Value<bool?> lastRefreshOk;
  final Value<String?> lastRefreshError;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.libraryRootId = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.narrator = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.rootPath = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.coverSourceType = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.onShelf = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.kind = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.sourceStatus = const Value.absent(),
    this.lastChapter = const Value.absent(),
    this.sourceUpdatedAt = const Value.absent(),
    this.lastRefreshAt = const Value.absent(),
    this.lastRefreshOk = const Value.absent(),
    this.lastRefreshError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String libraryRootId,
    required String title,
    this.author = const Value.absent(),
    this.narrator = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    required String rootPath,
    this.coverPath = const Value.absent(),
    this.coverSourceType = const Value.absent(),
    required String sourceType,
    this.sourceUri = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.onShelf = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.kind = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.sourceStatus = const Value.absent(),
    this.lastChapter = const Value.absent(),
    this.sourceUpdatedAt = const Value.absent(),
    this.lastRefreshAt = const Value.absent(),
    this.lastRefreshOk = const Value.absent(),
    this.lastRefreshError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       libraryRootId = Value(libraryRootId),
       title = Value(title),
       rootPath = Value(rootPath),
       sourceType = Value(sourceType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? libraryRootId,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? narrator,
    Expression<String>? seriesName,
    Expression<int>? seriesIndex,
    Expression<String>? rootPath,
    Expression<String>? coverPath,
    Expression<int>? coverSourceType,
    Expression<String>? sourceType,
    Expression<String>? sourceUri,
    Expression<int>? totalChapters,
    Expression<int>? totalDurationMs,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? onShelf,
    Expression<String>? sourceId,
    Expression<String>? coverUrl,
    Expression<String>? description,
    Expression<String>? kind,
    Expression<String>? wordCount,
    Expression<String>? sourceStatus,
    Expression<String>? lastChapter,
    Expression<DateTime>? sourceUpdatedAt,
    Expression<DateTime>? lastRefreshAt,
    Expression<bool>? lastRefreshOk,
    Expression<String>? lastRefreshError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryRootId != null) 'library_root_id': libraryRootId,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (narrator != null) 'narrator': narrator,
      if (seriesName != null) 'series_name': seriesName,
      if (seriesIndex != null) 'series_index': seriesIndex,
      if (rootPath != null) 'root_path': rootPath,
      if (coverPath != null) 'cover_path': coverPath,
      if (coverSourceType != null) 'cover_source_type': coverSourceType,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (totalDurationMs != null) 'total_duration_ms': totalDurationMs,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (onShelf != null) 'on_shelf': onShelf,
      if (sourceId != null) 'source_id': sourceId,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (description != null) 'description': description,
      if (kind != null) 'kind': kind,
      if (wordCount != null) 'word_count': wordCount,
      if (sourceStatus != null) 'source_status': sourceStatus,
      if (lastChapter != null) 'last_chapter': lastChapter,
      if (sourceUpdatedAt != null) 'source_updated_at': sourceUpdatedAt,
      if (lastRefreshAt != null) 'last_refresh_at': lastRefreshAt,
      if (lastRefreshOk != null) 'last_refresh_ok': lastRefreshOk,
      if (lastRefreshError != null) 'last_refresh_error': lastRefreshError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? libraryRootId,
    Value<String>? title,
    Value<String?>? author,
    Value<String?>? narrator,
    Value<String?>? seriesName,
    Value<int?>? seriesIndex,
    Value<String>? rootPath,
    Value<String?>? coverPath,
    Value<CoverSource>? coverSourceType,
    Value<String>? sourceType,
    Value<String?>? sourceUri,
    Value<int>? totalChapters,
    Value<int>? totalDurationMs,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? onShelf,
    Value<String?>? sourceId,
    Value<String?>? coverUrl,
    Value<String?>? description,
    Value<String?>? kind,
    Value<String?>? wordCount,
    Value<String?>? sourceStatus,
    Value<String?>? lastChapter,
    Value<DateTime?>? sourceUpdatedAt,
    Value<DateTime?>? lastRefreshAt,
    Value<bool?>? lastRefreshOk,
    Value<String?>? lastRefreshError,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      libraryRootId: libraryRootId ?? this.libraryRootId,
      title: title ?? this.title,
      author: author ?? this.author,
      narrator: narrator ?? this.narrator,
      seriesName: seriesName ?? this.seriesName,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      rootPath: rootPath ?? this.rootPath,
      coverPath: coverPath ?? this.coverPath,
      coverSourceType: coverSourceType ?? this.coverSourceType,
      sourceType: sourceType ?? this.sourceType,
      sourceUri: sourceUri ?? this.sourceUri,
      totalChapters: totalChapters ?? this.totalChapters,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      onShelf: onShelf ?? this.onShelf,
      sourceId: sourceId ?? this.sourceId,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      wordCount: wordCount ?? this.wordCount,
      sourceStatus: sourceStatus ?? this.sourceStatus,
      lastChapter: lastChapter ?? this.lastChapter,
      sourceUpdatedAt: sourceUpdatedAt ?? this.sourceUpdatedAt,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      lastRefreshOk: lastRefreshOk ?? this.lastRefreshOk,
      lastRefreshError: lastRefreshError ?? this.lastRefreshError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (libraryRootId.present) {
      map['library_root_id'] = Variable<String>(libraryRootId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (narrator.present) {
      map['narrator'] = Variable<String>(narrator.value);
    }
    if (seriesName.present) {
      map['series_name'] = Variable<String>(seriesName.value);
    }
    if (seriesIndex.present) {
      map['series_index'] = Variable<int>(seriesIndex.value);
    }
    if (rootPath.present) {
      map['root_path'] = Variable<String>(rootPath.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (coverSourceType.present) {
      map['cover_source_type'] = Variable<int>(
        $BooksTable.$convertercoverSourceType.toSql(coverSourceType.value),
      );
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (totalDurationMs.present) {
      map['total_duration_ms'] = Variable<int>(totalDurationMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (onShelf.present) {
      map['on_shelf'] = Variable<bool>(onShelf.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<String>(wordCount.value);
    }
    if (sourceStatus.present) {
      map['source_status'] = Variable<String>(sourceStatus.value);
    }
    if (lastChapter.present) {
      map['last_chapter'] = Variable<String>(lastChapter.value);
    }
    if (sourceUpdatedAt.present) {
      map['source_updated_at'] = Variable<DateTime>(sourceUpdatedAt.value);
    }
    if (lastRefreshAt.present) {
      map['last_refresh_at'] = Variable<DateTime>(lastRefreshAt.value);
    }
    if (lastRefreshOk.present) {
      map['last_refresh_ok'] = Variable<bool>(lastRefreshOk.value);
    }
    if (lastRefreshError.present) {
      map['last_refresh_error'] = Variable<String>(lastRefreshError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('libraryRootId: $libraryRootId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('narrator: $narrator, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('rootPath: $rootPath, ')
          ..write('coverPath: $coverPath, ')
          ..write('coverSourceType: $coverSourceType, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('onShelf: $onShelf, ')
          ..write('sourceId: $sourceId, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('description: $description, ')
          ..write('kind: $kind, ')
          ..write('wordCount: $wordCount, ')
          ..write('sourceStatus: $sourceStatus, ')
          ..write('lastChapter: $lastChapter, ')
          ..write('sourceUpdatedAt: $sourceUpdatedAt, ')
          ..write('lastRefreshAt: $lastRefreshAt, ')
          ..write('lastRefreshOk: $lastRefreshOk, ')
          ..write('lastRefreshError: $lastRefreshError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VolumesTable extends Volumes with TableInfo<$VolumesTable, Volume> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VolumesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeIndexMeta = const VerificationMeta(
    'volumeIndex',
  );
  @override
  late final GeneratedColumn<int> volumeIndex = GeneratedColumn<int>(
    'volume_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    title,
    volumeIndex,
    path,
    coverPath,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'volumes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Volume> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('volume_index')) {
      context.handle(
        _volumeIndexMeta,
        volumeIndex.isAcceptableOrUnknown(
          data['volume_index']!,
          _volumeIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_volumeIndexMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Volume map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Volume(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      volumeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume_index'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VolumesTable createAlias(String alias) {
    return $VolumesTable(attachedDatabase, alias);
  }
}

class Volume extends DataClass implements Insertable<Volume> {
  /// ULID，不可变。
  final String id;

  /// 所属书。
  final String bookId;

  /// 卷名。
  final String title;

  /// 卷序号（自然排序后的位置）。
  final int volumeIndex;

  /// 卷相对路径（相对书根；单卷平铺时为空串）。
  final String path;

  /// 卷封面路径。
  final String? coverPath;

  /// 最近更新时间。
  final DateTime updatedAt;
  const Volume({
    required this.id,
    required this.bookId,
    required this.title,
    required this.volumeIndex,
    required this.path,
    this.coverPath,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['title'] = Variable<String>(title);
    map['volume_index'] = Variable<int>(volumeIndex);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VolumesCompanion toCompanion(bool nullToAbsent) {
    return VolumesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      title: Value(title),
      volumeIndex: Value(volumeIndex),
      path: Value(path),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      updatedAt: Value(updatedAt),
    );
  }

  factory Volume.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Volume(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      title: serializer.fromJson<String>(json['title']),
      volumeIndex: serializer.fromJson<int>(json['volumeIndex']),
      path: serializer.fromJson<String>(json['path']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'title': serializer.toJson<String>(title),
      'volumeIndex': serializer.toJson<int>(volumeIndex),
      'path': serializer.toJson<String>(path),
      'coverPath': serializer.toJson<String?>(coverPath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Volume copyWith({
    String? id,
    String? bookId,
    String? title,
    int? volumeIndex,
    String? path,
    Value<String?> coverPath = const Value.absent(),
    DateTime? updatedAt,
  }) => Volume(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    title: title ?? this.title,
    volumeIndex: volumeIndex ?? this.volumeIndex,
    path: path ?? this.path,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Volume copyWithCompanion(VolumesCompanion data) {
    return Volume(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      title: data.title.present ? data.title.value : this.title,
      volumeIndex: data.volumeIndex.present
          ? data.volumeIndex.value
          : this.volumeIndex,
      path: data.path.present ? data.path.value : this.path,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Volume(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('volumeIndex: $volumeIndex, ')
          ..write('path: $path, ')
          ..write('coverPath: $coverPath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, title, volumeIndex, path, coverPath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Volume &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.title == this.title &&
          other.volumeIndex == this.volumeIndex &&
          other.path == this.path &&
          other.coverPath == this.coverPath &&
          other.updatedAt == this.updatedAt);
}

class VolumesCompanion extends UpdateCompanion<Volume> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> title;
  final Value<int> volumeIndex;
  final Value<String> path;
  final Value<String?> coverPath;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VolumesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.title = const Value.absent(),
    this.volumeIndex = const Value.absent(),
    this.path = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VolumesCompanion.insert({
    required String id,
    required String bookId,
    required String title,
    required int volumeIndex,
    required String path,
    this.coverPath = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       title = Value(title),
       volumeIndex = Value(volumeIndex),
       path = Value(path),
       updatedAt = Value(updatedAt);
  static Insertable<Volume> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? title,
    Expression<int>? volumeIndex,
    Expression<String>? path,
    Expression<String>? coverPath,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (title != null) 'title': title,
      if (volumeIndex != null) 'volume_index': volumeIndex,
      if (path != null) 'path': path,
      if (coverPath != null) 'cover_path': coverPath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VolumesCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? title,
    Value<int>? volumeIndex,
    Value<String>? path,
    Value<String?>? coverPath,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VolumesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      volumeIndex: volumeIndex ?? this.volumeIndex,
      path: path ?? this.path,
      coverPath: coverPath ?? this.coverPath,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (volumeIndex.present) {
      map['volume_index'] = Variable<int>(volumeIndex.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VolumesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('volumeIndex: $volumeIndex, ')
          ..write('path: $path, ')
          ..write('coverPath: $coverPath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters with TableInfo<$ChaptersTable, Chapter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _volumeIdMeta = const VerificationMeta(
    'volumeId',
  );
  @override
  late final GeneratedColumn<String> volumeId = GeneratedColumn<String>(
    'volume_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES volumes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _libraryRootIdMeta = const VerificationMeta(
    'libraryRootId',
  );
  @override
  late final GeneratedColumn<String> libraryRootId = GeneratedColumn<String>(
    'library_root_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES library_roots (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUriMeta = const VerificationMeta(
    'sourceUri',
  );
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
    'source_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missingMeta = const VerificationMeta(
    'missing',
  );
  @override
  late final GeneratedColumn<bool> missing = GeneratedColumn<bool>(
    'missing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("missing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _metadataAttemptsMeta = const VerificationMeta(
    'metadataAttempts',
  );
  @override
  late final GeneratedColumn<int> metadataAttempts = GeneratedColumn<int>(
    'metadata_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retiredMeta = const VerificationMeta(
    'retired',
  );
  @override
  late final GeneratedColumn<bool> retired = GeneratedColumn<bool>(
    'retired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isVipMeta = const VerificationMeta('isVip');
  @override
  late final GeneratedColumn<bool> isVip = GeneratedColumn<bool>(
    'is_vip',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_vip" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    volumeId,
    libraryRootId,
    title,
    chapterIndex,
    filePath,
    sourceUri,
    durationMs,
    sizeBytes,
    missing,
    metadataAttempts,
    retired,
    isVip,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chapter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('volume_id')) {
      context.handle(
        _volumeIdMeta,
        volumeId.isAcceptableOrUnknown(data['volume_id']!, _volumeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_volumeIdMeta);
    }
    if (data.containsKey('library_root_id')) {
      context.handle(
        _libraryRootIdMeta,
        libraryRootId.isAcceptableOrUnknown(
          data['library_root_id']!,
          _libraryRootIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryRootIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapter_index']!,
          _chapterIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterIndexMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('source_uri')) {
      context.handle(
        _sourceUriMeta,
        sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('missing')) {
      context.handle(
        _missingMeta,
        missing.isAcceptableOrUnknown(data['missing']!, _missingMeta),
      );
    }
    if (data.containsKey('metadata_attempts')) {
      context.handle(
        _metadataAttemptsMeta,
        metadataAttempts.isAcceptableOrUnknown(
          data['metadata_attempts']!,
          _metadataAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('retired')) {
      context.handle(
        _retiredMeta,
        retired.isAcceptableOrUnknown(data['retired']!, _retiredMeta),
      );
    }
    if (data.containsKey('is_vip')) {
      context.handle(
        _isVipMeta,
        isVip.isAcceptableOrUnknown(data['is_vip']!, _isVipMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chapter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chapter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      volumeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_id'],
      )!,
      libraryRootId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_root_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      chapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_index'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      sourceUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_uri'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      missing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}missing'],
      )!,
      metadataAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}metadata_attempts'],
      )!,
      retired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retired'],
      )!,
      isVip: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_vip'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class Chapter extends DataClass implements Insertable<Chapter> {
  /// ULID，不可变。
  final String id;

  /// 所属书。
  final String bookId;

  /// 所属卷。
  final String volumeId;

  /// 冗余书库根，用于对绑定键建唯一索引。
  final String libraryRootId;

  /// 章名。
  final String title;

  /// 章序号（自然排序后的位置）。
  final int chapterIndex;

  /// 绑定键：相对书库根的 NFC 规范化路径。
  final String filePath;

  /// provider 侧源地址；本地源为空。
  final String? sourceUri;

  /// 时长毫秒（第二阶段异步回填）。
  final int? durationMs;

  /// 文件字节数（重链特征匹配用，§8.2）。
  final int? sizeBytes;

  /// 文件是否缺失。缺失章节保留占位并高亮。
  final bool missing;

  /// 元信息回填尝试次数（Phase 2 内部记账）。
  ///
  /// 为什么需要：回填队列是 `duration_ms IS NULL` + 排序 + 限量。若某章永久读不出
  /// 时长（坏文件 / 编码异常），它会一直留在队首，**饿死**后面所有章节。
  /// 连续失败达到上限后跳过它，保证队列整体推进。
  final int metadataAttempts;

  /// 换源 / 目录刷新后标记旧章；只增不删，保留进度归属。
  final bool retired;

  /// 源侧标记的 VIP / 付费章；M1 只记录，不尝试绕过。
  final bool isVip;

  /// 最近更新时间。
  final DateTime updatedAt;
  const Chapter({
    required this.id,
    required this.bookId,
    required this.volumeId,
    required this.libraryRootId,
    required this.title,
    required this.chapterIndex,
    required this.filePath,
    this.sourceUri,
    this.durationMs,
    this.sizeBytes,
    required this.missing,
    required this.metadataAttempts,
    required this.retired,
    required this.isVip,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['volume_id'] = Variable<String>(volumeId);
    map['library_root_id'] = Variable<String>(libraryRootId);
    map['title'] = Variable<String>(title);
    map['chapter_index'] = Variable<int>(chapterIndex);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || sourceUri != null) {
      map['source_uri'] = Variable<String>(sourceUri);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['missing'] = Variable<bool>(missing);
    map['metadata_attempts'] = Variable<int>(metadataAttempts);
    map['retired'] = Variable<bool>(retired);
    map['is_vip'] = Variable<bool>(isVip);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      bookId: Value(bookId),
      volumeId: Value(volumeId),
      libraryRootId: Value(libraryRootId),
      title: Value(title),
      chapterIndex: Value(chapterIndex),
      filePath: Value(filePath),
      sourceUri: sourceUri == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUri),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      missing: Value(missing),
      metadataAttempts: Value(metadataAttempts),
      retired: Value(retired),
      isVip: Value(isVip),
      updatedAt: Value(updatedAt),
    );
  }

  factory Chapter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chapter(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      volumeId: serializer.fromJson<String>(json['volumeId']),
      libraryRootId: serializer.fromJson<String>(json['libraryRootId']),
      title: serializer.fromJson<String>(json['title']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sourceUri: serializer.fromJson<String?>(json['sourceUri']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      missing: serializer.fromJson<bool>(json['missing']),
      metadataAttempts: serializer.fromJson<int>(json['metadataAttempts']),
      retired: serializer.fromJson<bool>(json['retired']),
      isVip: serializer.fromJson<bool>(json['isVip']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'volumeId': serializer.toJson<String>(volumeId),
      'libraryRootId': serializer.toJson<String>(libraryRootId),
      'title': serializer.toJson<String>(title),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'filePath': serializer.toJson<String>(filePath),
      'sourceUri': serializer.toJson<String?>(sourceUri),
      'durationMs': serializer.toJson<int?>(durationMs),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'missing': serializer.toJson<bool>(missing),
      'metadataAttempts': serializer.toJson<int>(metadataAttempts),
      'retired': serializer.toJson<bool>(retired),
      'isVip': serializer.toJson<bool>(isVip),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Chapter copyWith({
    String? id,
    String? bookId,
    String? volumeId,
    String? libraryRootId,
    String? title,
    int? chapterIndex,
    String? filePath,
    Value<String?> sourceUri = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    bool? missing,
    int? metadataAttempts,
    bool? retired,
    bool? isVip,
    DateTime? updatedAt,
  }) => Chapter(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    volumeId: volumeId ?? this.volumeId,
    libraryRootId: libraryRootId ?? this.libraryRootId,
    title: title ?? this.title,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    filePath: filePath ?? this.filePath,
    sourceUri: sourceUri.present ? sourceUri.value : this.sourceUri,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    missing: missing ?? this.missing,
    metadataAttempts: metadataAttempts ?? this.metadataAttempts,
    retired: retired ?? this.retired,
    isVip: isVip ?? this.isVip,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Chapter copyWithCompanion(ChaptersCompanion data) {
    return Chapter(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      volumeId: data.volumeId.present ? data.volumeId.value : this.volumeId,
      libraryRootId: data.libraryRootId.present
          ? data.libraryRootId.value
          : this.libraryRootId,
      title: data.title.present ? data.title.value : this.title,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      missing: data.missing.present ? data.missing.value : this.missing,
      metadataAttempts: data.metadataAttempts.present
          ? data.metadataAttempts.value
          : this.metadataAttempts,
      retired: data.retired.present ? data.retired.value : this.retired,
      isVip: data.isVip.present ? data.isVip.value : this.isVip,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Chapter(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('volumeId: $volumeId, ')
          ..write('libraryRootId: $libraryRootId, ')
          ..write('title: $title, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('filePath: $filePath, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('missing: $missing, ')
          ..write('metadataAttempts: $metadataAttempts, ')
          ..write('retired: $retired, ')
          ..write('isVip: $isVip, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    volumeId,
    libraryRootId,
    title,
    chapterIndex,
    filePath,
    sourceUri,
    durationMs,
    sizeBytes,
    missing,
    metadataAttempts,
    retired,
    isVip,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Chapter &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.volumeId == this.volumeId &&
          other.libraryRootId == this.libraryRootId &&
          other.title == this.title &&
          other.chapterIndex == this.chapterIndex &&
          other.filePath == this.filePath &&
          other.sourceUri == this.sourceUri &&
          other.durationMs == this.durationMs &&
          other.sizeBytes == this.sizeBytes &&
          other.missing == this.missing &&
          other.metadataAttempts == this.metadataAttempts &&
          other.retired == this.retired &&
          other.isVip == this.isVip &&
          other.updatedAt == this.updatedAt);
}

class ChaptersCompanion extends UpdateCompanion<Chapter> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> volumeId;
  final Value<String> libraryRootId;
  final Value<String> title;
  final Value<int> chapterIndex;
  final Value<String> filePath;
  final Value<String?> sourceUri;
  final Value<int?> durationMs;
  final Value<int?> sizeBytes;
  final Value<bool> missing;
  final Value<int> metadataAttempts;
  final Value<bool> retired;
  final Value<bool> isVip;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.volumeId = const Value.absent(),
    this.libraryRootId = const Value.absent(),
    this.title = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.missing = const Value.absent(),
    this.metadataAttempts = const Value.absent(),
    this.retired = const Value.absent(),
    this.isVip = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String id,
    required String bookId,
    required String volumeId,
    required String libraryRootId,
    required String title,
    required int chapterIndex,
    required String filePath,
    this.sourceUri = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.missing = const Value.absent(),
    this.metadataAttempts = const Value.absent(),
    this.retired = const Value.absent(),
    this.isVip = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       volumeId = Value(volumeId),
       libraryRootId = Value(libraryRootId),
       title = Value(title),
       chapterIndex = Value(chapterIndex),
       filePath = Value(filePath),
       updatedAt = Value(updatedAt);
  static Insertable<Chapter> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? volumeId,
    Expression<String>? libraryRootId,
    Expression<String>? title,
    Expression<int>? chapterIndex,
    Expression<String>? filePath,
    Expression<String>? sourceUri,
    Expression<int>? durationMs,
    Expression<int>? sizeBytes,
    Expression<bool>? missing,
    Expression<int>? metadataAttempts,
    Expression<bool>? retired,
    Expression<bool>? isVip,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (volumeId != null) 'volume_id': volumeId,
      if (libraryRootId != null) 'library_root_id': libraryRootId,
      if (title != null) 'title': title,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (filePath != null) 'file_path': filePath,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (missing != null) 'missing': missing,
      if (metadataAttempts != null) 'metadata_attempts': metadataAttempts,
      if (retired != null) 'retired': retired,
      if (isVip != null) 'is_vip': isVip,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String>? volumeId,
    Value<String>? libraryRootId,
    Value<String>? title,
    Value<int>? chapterIndex,
    Value<String>? filePath,
    Value<String?>? sourceUri,
    Value<int?>? durationMs,
    Value<int?>? sizeBytes,
    Value<bool>? missing,
    Value<int>? metadataAttempts,
    Value<bool>? retired,
    Value<bool>? isVip,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      volumeId: volumeId ?? this.volumeId,
      libraryRootId: libraryRootId ?? this.libraryRootId,
      title: title ?? this.title,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      filePath: filePath ?? this.filePath,
      sourceUri: sourceUri ?? this.sourceUri,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      missing: missing ?? this.missing,
      metadataAttempts: metadataAttempts ?? this.metadataAttempts,
      retired: retired ?? this.retired,
      isVip: isVip ?? this.isVip,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (volumeId.present) {
      map['volume_id'] = Variable<String>(volumeId.value);
    }
    if (libraryRootId.present) {
      map['library_root_id'] = Variable<String>(libraryRootId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (missing.present) {
      map['missing'] = Variable<bool>(missing.value);
    }
    if (metadataAttempts.present) {
      map['metadata_attempts'] = Variable<int>(metadataAttempts.value);
    }
    if (retired.present) {
      map['retired'] = Variable<bool>(retired.value);
    }
    if (isVip.present) {
      map['is_vip'] = Variable<bool>(isVip.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('volumeId: $volumeId, ')
          ..write('libraryRootId: $libraryRootId, ')
          ..write('title: $title, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('filePath: $filePath, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('missing: $missing, ')
          ..write('metadataAttempts: $metadataAttempts, ')
          ..write('retired: $retired, ')
          ..write('isVip: $isVip, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookMetadataOverridesTable extends BookMetadataOverrides
    with TableInfo<$BookMetadataOverridesTable, BookMetadataOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookMetadataOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _narratorMeta = const VerificationMeta(
    'narrator',
  );
  @override
  late final GeneratedColumn<String> narrator = GeneratedColumn<String>(
    'narrator',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesNameMeta = const VerificationMeta(
    'seriesName',
  );
  @override
  late final GeneratedColumn<String> seriesName = GeneratedColumn<String>(
    'series_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIndexMeta = const VerificationMeta(
    'seriesIndex',
  );
  @override
  late final GeneratedColumn<int> seriesIndex = GeneratedColumn<int>(
    'series_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manualEditedAtMeta = const VerificationMeta(
    'manualEditedAt',
  );
  @override
  late final GeneratedColumn<DateTime> manualEditedAt =
      GeneratedColumn<DateTime>(
        'manual_edited_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    title,
    author,
    narrator,
    seriesName,
    seriesIndex,
    description,
    manualEditedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_metadata_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookMetadataOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('narrator')) {
      context.handle(
        _narratorMeta,
        narrator.isAcceptableOrUnknown(data['narrator']!, _narratorMeta),
      );
    }
    if (data.containsKey('series_name')) {
      context.handle(
        _seriesNameMeta,
        seriesName.isAcceptableOrUnknown(data['series_name']!, _seriesNameMeta),
      );
    }
    if (data.containsKey('series_index')) {
      context.handle(
        _seriesIndexMeta,
        seriesIndex.isAcceptableOrUnknown(
          data['series_index']!,
          _seriesIndexMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('manual_edited_at')) {
      context.handle(
        _manualEditedAtMeta,
        manualEditedAt.isAcceptableOrUnknown(
          data['manual_edited_at']!,
          _manualEditedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  BookMetadataOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookMetadataOverride(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      narrator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}narrator'],
      ),
      seriesName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_name'],
      ),
      seriesIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_index'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      manualEditedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}manual_edited_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BookMetadataOverridesTable createAlias(String alias) {
    return $BookMetadataOverridesTable(attachedDatabase, alias);
  }
}

class BookMetadataOverride extends DataClass
    implements Insertable<BookMetadataOverride> {
  /// 对应书。
  final String bookId;

  /// 覆盖书名。
  final String? title;

  /// 覆盖作者。
  final String? author;

  /// 覆盖演播者。
  final String? narrator;

  /// 覆盖系列名。
  final String? seriesName;

  /// 覆盖系列序号。
  final int? seriesIndex;

  /// 覆盖简介。
  final String? description;

  /// 最近一次手动编辑时间（区分"扫描自动写入"与"用户手改"，用于不覆盖用户编辑）。
  final DateTime? manualEditedAt;

  /// 最近更新时间。
  final DateTime updatedAt;
  const BookMetadataOverride({
    required this.bookId,
    this.title,
    this.author,
    this.narrator,
    this.seriesName,
    this.seriesIndex,
    this.description,
    this.manualEditedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || narrator != null) {
      map['narrator'] = Variable<String>(narrator);
    }
    if (!nullToAbsent || seriesName != null) {
      map['series_name'] = Variable<String>(seriesName);
    }
    if (!nullToAbsent || seriesIndex != null) {
      map['series_index'] = Variable<int>(seriesIndex);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || manualEditedAt != null) {
      map['manual_edited_at'] = Variable<DateTime>(manualEditedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BookMetadataOverridesCompanion toCompanion(bool nullToAbsent) {
    return BookMetadataOverridesCompanion(
      bookId: Value(bookId),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      narrator: narrator == null && nullToAbsent
          ? const Value.absent()
          : Value(narrator),
      seriesName: seriesName == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesName),
      seriesIndex: seriesIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesIndex),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      manualEditedAt: manualEditedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(manualEditedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BookMetadataOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookMetadataOverride(
      bookId: serializer.fromJson<String>(json['bookId']),
      title: serializer.fromJson<String?>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      narrator: serializer.fromJson<String?>(json['narrator']),
      seriesName: serializer.fromJson<String?>(json['seriesName']),
      seriesIndex: serializer.fromJson<int?>(json['seriesIndex']),
      description: serializer.fromJson<String?>(json['description']),
      manualEditedAt: serializer.fromJson<DateTime?>(json['manualEditedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'title': serializer.toJson<String?>(title),
      'author': serializer.toJson<String?>(author),
      'narrator': serializer.toJson<String?>(narrator),
      'seriesName': serializer.toJson<String?>(seriesName),
      'seriesIndex': serializer.toJson<int?>(seriesIndex),
      'description': serializer.toJson<String?>(description),
      'manualEditedAt': serializer.toJson<DateTime?>(manualEditedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BookMetadataOverride copyWith({
    String? bookId,
    Value<String?> title = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> narrator = const Value.absent(),
    Value<String?> seriesName = const Value.absent(),
    Value<int?> seriesIndex = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<DateTime?> manualEditedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => BookMetadataOverride(
    bookId: bookId ?? this.bookId,
    title: title.present ? title.value : this.title,
    author: author.present ? author.value : this.author,
    narrator: narrator.present ? narrator.value : this.narrator,
    seriesName: seriesName.present ? seriesName.value : this.seriesName,
    seriesIndex: seriesIndex.present ? seriesIndex.value : this.seriesIndex,
    description: description.present ? description.value : this.description,
    manualEditedAt: manualEditedAt.present
        ? manualEditedAt.value
        : this.manualEditedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BookMetadataOverride copyWithCompanion(BookMetadataOverridesCompanion data) {
    return BookMetadataOverride(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      narrator: data.narrator.present ? data.narrator.value : this.narrator,
      seriesName: data.seriesName.present
          ? data.seriesName.value
          : this.seriesName,
      seriesIndex: data.seriesIndex.present
          ? data.seriesIndex.value
          : this.seriesIndex,
      description: data.description.present
          ? data.description.value
          : this.description,
      manualEditedAt: data.manualEditedAt.present
          ? data.manualEditedAt.value
          : this.manualEditedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookMetadataOverride(')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('narrator: $narrator, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('description: $description, ')
          ..write('manualEditedAt: $manualEditedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    title,
    author,
    narrator,
    seriesName,
    seriesIndex,
    description,
    manualEditedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookMetadataOverride &&
          other.bookId == this.bookId &&
          other.title == this.title &&
          other.author == this.author &&
          other.narrator == this.narrator &&
          other.seriesName == this.seriesName &&
          other.seriesIndex == this.seriesIndex &&
          other.description == this.description &&
          other.manualEditedAt == this.manualEditedAt &&
          other.updatedAt == this.updatedAt);
}

class BookMetadataOverridesCompanion
    extends UpdateCompanion<BookMetadataOverride> {
  final Value<String> bookId;
  final Value<String?> title;
  final Value<String?> author;
  final Value<String?> narrator;
  final Value<String?> seriesName;
  final Value<int?> seriesIndex;
  final Value<String?> description;
  final Value<DateTime?> manualEditedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BookMetadataOverridesCompanion({
    this.bookId = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.narrator = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.description = const Value.absent(),
    this.manualEditedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookMetadataOverridesCompanion.insert({
    required String bookId,
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.narrator = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.description = const Value.absent(),
    this.manualEditedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       updatedAt = Value(updatedAt);
  static Insertable<BookMetadataOverride> custom({
    Expression<String>? bookId,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? narrator,
    Expression<String>? seriesName,
    Expression<int>? seriesIndex,
    Expression<String>? description,
    Expression<DateTime>? manualEditedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (narrator != null) 'narrator': narrator,
      if (seriesName != null) 'series_name': seriesName,
      if (seriesIndex != null) 'series_index': seriesIndex,
      if (description != null) 'description': description,
      if (manualEditedAt != null) 'manual_edited_at': manualEditedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookMetadataOverridesCompanion copyWith({
    Value<String>? bookId,
    Value<String?>? title,
    Value<String?>? author,
    Value<String?>? narrator,
    Value<String?>? seriesName,
    Value<int?>? seriesIndex,
    Value<String?>? description,
    Value<DateTime?>? manualEditedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BookMetadataOverridesCompanion(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      narrator: narrator ?? this.narrator,
      seriesName: seriesName ?? this.seriesName,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      description: description ?? this.description,
      manualEditedAt: manualEditedAt ?? this.manualEditedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (narrator.present) {
      map['narrator'] = Variable<String>(narrator.value);
    }
    if (seriesName.present) {
      map['series_name'] = Variable<String>(seriesName.value);
    }
    if (seriesIndex.present) {
      map['series_index'] = Variable<int>(seriesIndex.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (manualEditedAt.present) {
      map['manual_edited_at'] = Variable<DateTime>(manualEditedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookMetadataOverridesCompanion(')
          ..write('bookId: $bookId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('narrator: $narrator, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('description: $description, ')
          ..write('manualEditedAt: $manualEditedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookTagsTable extends BookTags with TableInfo<$BookTagsTable, BookTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [bookId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, tag};
  @override
  BookTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookTag(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $BookTagsTable createAlias(String alias) {
    return $BookTagsTable(attachedDatabase, alias);
  }
}

class BookTag extends DataClass implements Insertable<BookTag> {
  /// 对应书。
  final String bookId;

  /// 标签文本（已归一化）。
  final String tag;
  const BookTag({required this.bookId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  BookTagsCompanion toCompanion(bool nullToAbsent) {
    return BookTagsCompanion(bookId: Value(bookId), tag: Value(tag));
  }

  factory BookTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookTag(
      bookId: serializer.fromJson<String>(json['bookId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  BookTag copyWith({String? bookId, String? tag}) =>
      BookTag(bookId: bookId ?? this.bookId, tag: tag ?? this.tag);
  BookTag copyWithCompanion(BookTagsCompanion data) {
    return BookTag(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookTag(')
          ..write('bookId: $bookId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookTag &&
          other.bookId == this.bookId &&
          other.tag == this.tag);
}

class BookTagsCompanion extends UpdateCompanion<BookTag> {
  final Value<String> bookId;
  final Value<String> tag;
  final Value<int> rowid;
  const BookTagsCompanion({
    this.bookId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookTagsCompanion.insert({
    required String bookId,
    required String tag,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       tag = Value(tag);
  static Insertable<BookTag> custom({
    Expression<String>? bookId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookTagsCompanion copyWith({
    Value<String>? bookId,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return BookTagsCompanion(
      bookId: bookId ?? this.bookId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookTagsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackProgressTable extends PlaybackProgress
    with TableInfo<$PlaybackProgressTable, PlaybackProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    chapterId,
    positionMs,
    updatedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  PlaybackProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackProgressData(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $PlaybackProgressTable createAlias(String alias) {
    return $PlaybackProgressTable(attachedDatabase, alias);
  }
}

class PlaybackProgressData extends DataClass
    implements Insertable<PlaybackProgressData> {
  /// 对应书。
  final String bookId;

  /// 当前章。
  final String chapterId;

  /// 章内位置（毫秒）。
  final int positionMs;

  /// 最近更新时间 —— 书库"最近收听"排序依据。
  final DateTime updatedAt;

  /// 听完（finished）时间；`null` 表示尚未听完。
  final DateTime? finishedAt;
  const PlaybackProgressData({
    required this.bookId,
    required this.chapterId,
    required this.positionMs,
    required this.updatedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['position_ms'] = Variable<int>(positionMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  PlaybackProgressCompanion toCompanion(bool nullToAbsent) {
    return PlaybackProgressCompanion(
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      positionMs: Value(positionMs),
      updatedAt: Value(updatedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory PlaybackProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackProgressData(
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'chapterId': serializer.toJson<String>(chapterId),
      'positionMs': serializer.toJson<int>(positionMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  PlaybackProgressData copyWith({
    String? bookId,
    String? chapterId,
    int? positionMs,
    DateTime? updatedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => PlaybackProgressData(
    bookId: bookId ?? this.bookId,
    chapterId: chapterId ?? this.chapterId,
    positionMs: positionMs ?? this.positionMs,
    updatedAt: updatedAt ?? this.updatedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  PlaybackProgressData copyWithCompanion(PlaybackProgressCompanion data) {
    return PlaybackProgressData(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackProgressData(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(bookId, chapterId, positionMs, updatedAt, finishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackProgressData &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.positionMs == this.positionMs &&
          other.updatedAt == this.updatedAt &&
          other.finishedAt == this.finishedAt);
}

class PlaybackProgressCompanion extends UpdateCompanion<PlaybackProgressData> {
  final Value<String> bookId;
  final Value<String> chapterId;
  final Value<int> positionMs;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const PlaybackProgressCompanion({
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackProgressCompanion.insert({
    required String bookId,
    required String chapterId,
    required int positionMs,
    required DateTime updatedAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       chapterId = Value(chapterId),
       positionMs = Value(positionMs),
       updatedAt = Value(updatedAt);
  static Insertable<PlaybackProgressData> custom({
    Expression<String>? bookId,
    Expression<String>? chapterId,
    Expression<int>? positionMs,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (positionMs != null) 'position_ms': positionMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackProgressCompanion copyWith({
    Value<String>? bookId,
    Value<String>? chapterId,
    Value<int>? positionMs,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return PlaybackProgressCompanion(
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      positionMs: positionMs ?? this.positionMs,
      updatedAt: updatedAt ?? this.updatedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackProgressCompanion(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PerBookPrefsTable extends PerBookPrefs
    with TableInfo<$PerBookPrefsTable, PerBookPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PerBookPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _skipIntroSecMeta = const VerificationMeta(
    'skipIntroSec',
  );
  @override
  late final GeneratedColumn<int> skipIntroSec = GeneratedColumn<int>(
    'skip_intro_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skipOutroSecMeta = const VerificationMeta(
    'skipOutroSec',
  );
  @override
  late final GeneratedColumn<int> skipOutroSec = GeneratedColumn<int>(
    'skip_outro_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rewindOverrideMeta = const VerificationMeta(
    'rewindOverride',
  );
  @override
  late final GeneratedColumn<String> rewindOverride = GeneratedColumn<String>(
    'rewind_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    speed,
    skipIntroSec,
    skipOutroSec,
    rewindOverride,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'per_book_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PerBookPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('skip_intro_sec')) {
      context.handle(
        _skipIntroSecMeta,
        skipIntroSec.isAcceptableOrUnknown(
          data['skip_intro_sec']!,
          _skipIntroSecMeta,
        ),
      );
    }
    if (data.containsKey('skip_outro_sec')) {
      context.handle(
        _skipOutroSecMeta,
        skipOutroSec.isAcceptableOrUnknown(
          data['skip_outro_sec']!,
          _skipOutroSecMeta,
        ),
      );
    }
    if (data.containsKey('rewind_override')) {
      context.handle(
        _rewindOverrideMeta,
        rewindOverride.isAcceptableOrUnknown(
          data['rewind_override']!,
          _rewindOverrideMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  PerBookPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PerBookPref(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      skipIntroSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skip_intro_sec'],
      )!,
      skipOutroSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skip_outro_sec'],
      )!,
      rewindOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rewind_override'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PerBookPrefsTable createAlias(String alias) {
    return $PerBookPrefsTable(attachedDatabase, alias);
  }
}

class PerBookPref extends DataClass implements Insertable<PerBookPref> {
  /// 对应书。
  final String bookId;

  /// 倍速记忆（0.5–3.0）。
  final double speed;

  /// 片头跳过秒数。
  final int skipIntroSec;

  /// 片尾跳过秒数。
  final int skipOutroSec;

  /// 回退阶梯覆盖（JSON；`null` 表示沿用全局阶梯）。
  final String? rewindOverride;

  /// 最近更新时间。
  final DateTime updatedAt;
  const PerBookPref({
    required this.bookId,
    required this.speed,
    required this.skipIntroSec,
    required this.skipOutroSec,
    this.rewindOverride,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['speed'] = Variable<double>(speed);
    map['skip_intro_sec'] = Variable<int>(skipIntroSec);
    map['skip_outro_sec'] = Variable<int>(skipOutroSec);
    if (!nullToAbsent || rewindOverride != null) {
      map['rewind_override'] = Variable<String>(rewindOverride);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PerBookPrefsCompanion toCompanion(bool nullToAbsent) {
    return PerBookPrefsCompanion(
      bookId: Value(bookId),
      speed: Value(speed),
      skipIntroSec: Value(skipIntroSec),
      skipOutroSec: Value(skipOutroSec),
      rewindOverride: rewindOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(rewindOverride),
      updatedAt: Value(updatedAt),
    );
  }

  factory PerBookPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PerBookPref(
      bookId: serializer.fromJson<String>(json['bookId']),
      speed: serializer.fromJson<double>(json['speed']),
      skipIntroSec: serializer.fromJson<int>(json['skipIntroSec']),
      skipOutroSec: serializer.fromJson<int>(json['skipOutroSec']),
      rewindOverride: serializer.fromJson<String?>(json['rewindOverride']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'speed': serializer.toJson<double>(speed),
      'skipIntroSec': serializer.toJson<int>(skipIntroSec),
      'skipOutroSec': serializer.toJson<int>(skipOutroSec),
      'rewindOverride': serializer.toJson<String?>(rewindOverride),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PerBookPref copyWith({
    String? bookId,
    double? speed,
    int? skipIntroSec,
    int? skipOutroSec,
    Value<String?> rewindOverride = const Value.absent(),
    DateTime? updatedAt,
  }) => PerBookPref(
    bookId: bookId ?? this.bookId,
    speed: speed ?? this.speed,
    skipIntroSec: skipIntroSec ?? this.skipIntroSec,
    skipOutroSec: skipOutroSec ?? this.skipOutroSec,
    rewindOverride: rewindOverride.present
        ? rewindOverride.value
        : this.rewindOverride,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PerBookPref copyWithCompanion(PerBookPrefsCompanion data) {
    return PerBookPref(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      speed: data.speed.present ? data.speed.value : this.speed,
      skipIntroSec: data.skipIntroSec.present
          ? data.skipIntroSec.value
          : this.skipIntroSec,
      skipOutroSec: data.skipOutroSec.present
          ? data.skipOutroSec.value
          : this.skipOutroSec,
      rewindOverride: data.rewindOverride.present
          ? data.rewindOverride.value
          : this.rewindOverride,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PerBookPref(')
          ..write('bookId: $bookId, ')
          ..write('speed: $speed, ')
          ..write('skipIntroSec: $skipIntroSec, ')
          ..write('skipOutroSec: $skipOutroSec, ')
          ..write('rewindOverride: $rewindOverride, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    speed,
    skipIntroSec,
    skipOutroSec,
    rewindOverride,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PerBookPref &&
          other.bookId == this.bookId &&
          other.speed == this.speed &&
          other.skipIntroSec == this.skipIntroSec &&
          other.skipOutroSec == this.skipOutroSec &&
          other.rewindOverride == this.rewindOverride &&
          other.updatedAt == this.updatedAt);
}

class PerBookPrefsCompanion extends UpdateCompanion<PerBookPref> {
  final Value<String> bookId;
  final Value<double> speed;
  final Value<int> skipIntroSec;
  final Value<int> skipOutroSec;
  final Value<String?> rewindOverride;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PerBookPrefsCompanion({
    this.bookId = const Value.absent(),
    this.speed = const Value.absent(),
    this.skipIntroSec = const Value.absent(),
    this.skipOutroSec = const Value.absent(),
    this.rewindOverride = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PerBookPrefsCompanion.insert({
    required String bookId,
    this.speed = const Value.absent(),
    this.skipIntroSec = const Value.absent(),
    this.skipOutroSec = const Value.absent(),
    this.rewindOverride = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       updatedAt = Value(updatedAt);
  static Insertable<PerBookPref> custom({
    Expression<String>? bookId,
    Expression<double>? speed,
    Expression<int>? skipIntroSec,
    Expression<int>? skipOutroSec,
    Expression<String>? rewindOverride,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (speed != null) 'speed': speed,
      if (skipIntroSec != null) 'skip_intro_sec': skipIntroSec,
      if (skipOutroSec != null) 'skip_outro_sec': skipOutroSec,
      if (rewindOverride != null) 'rewind_override': rewindOverride,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PerBookPrefsCompanion copyWith({
    Value<String>? bookId,
    Value<double>? speed,
    Value<int>? skipIntroSec,
    Value<int>? skipOutroSec,
    Value<String?>? rewindOverride,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PerBookPrefsCompanion(
      bookId: bookId ?? this.bookId,
      speed: speed ?? this.speed,
      skipIntroSec: skipIntroSec ?? this.skipIntroSec,
      skipOutroSec: skipOutroSec ?? this.skipOutroSec,
      rewindOverride: rewindOverride ?? this.rewindOverride,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (skipIntroSec.present) {
      map['skip_intro_sec'] = Variable<int>(skipIntroSec.value);
    }
    if (skipOutroSec.present) {
      map['skip_outro_sec'] = Variable<int>(skipOutroSec.value);
    }
    if (rewindOverride.present) {
      map['rewind_override'] = Variable<String>(rewindOverride.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PerBookPrefsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('speed: $speed, ')
          ..write('skipIntroSec: $skipIntroSec, ')
          ..write('skipOutroSec: $skipOutroSec, ')
          ..write('rewindOverride: $rewindOverride, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListeningRecordsTable extends ListeningRecords
    with TableInfo<$ListeningRecordsTable, ListeningRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE CASCADE',
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
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    chapterId,
    startedAt,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListeningRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
    );
  }

  @override
  $ListeningRecordsTable createAlias(String alias) {
    return $ListeningRecordsTable(attachedDatabase, alias);
  }
}

class ListeningRecord extends DataClass implements Insertable<ListeningRecord> {
  /// ULID。
  final String id;

  /// 对应书。
  final String bookId;

  /// 对应章（可能为空：切章瞬间的切片归属不清）。
  final String? chapterId;

  /// 切片起始时间（UTC）。热力图按本地日期聚合。
  final DateTime startedAt;

  /// 切片时长（毫秒）。单条不超过 30_000 + 容差。
  final int durationMs;
  const ListeningRecord({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.startedAt,
    required this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || chapterId != null) {
      map['chapter_id'] = Variable<String>(chapterId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_ms'] = Variable<int>(durationMs);
    return map;
  }

  ListeningRecordsCompanion toCompanion(bool nullToAbsent) {
    return ListeningRecordsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: chapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterId),
      startedAt: Value(startedAt),
      durationMs: Value(durationMs),
    );
  }

  factory ListeningRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningRecord(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterId: serializer.fromJson<String?>(json['chapterId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'chapterId': serializer.toJson<String?>(chapterId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationMs': serializer.toJson<int>(durationMs),
    };
  }

  ListeningRecord copyWith({
    String? id,
    String? bookId,
    Value<String?> chapterId = const Value.absent(),
    DateTime? startedAt,
    int? durationMs,
  }) => ListeningRecord(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    chapterId: chapterId.present ? chapterId.value : this.chapterId,
    startedAt: startedAt ?? this.startedAt,
    durationMs: durationMs ?? this.durationMs,
  );
  ListeningRecord copyWithCompanion(ListeningRecordsCompanion data) {
    return ListeningRecord(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningRecord(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bookId, chapterId, startedAt, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningRecord &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.startedAt == this.startedAt &&
          other.durationMs == this.durationMs);
}

class ListeningRecordsCompanion extends UpdateCompanion<ListeningRecord> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String?> chapterId;
  final Value<DateTime> startedAt;
  final Value<int> durationMs;
  final Value<int> rowid;
  const ListeningRecordsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListeningRecordsCompanion.insert({
    required String id,
    required String bookId,
    this.chapterId = const Value.absent(),
    required DateTime startedAt,
    required int durationMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookId = Value(bookId),
       startedAt = Value(startedAt),
       durationMs = Value(durationMs);
  static Insertable<ListeningRecord> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? chapterId,
    Expression<DateTime>? startedAt,
    Expression<int>? durationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (startedAt != null) 'started_at': startedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListeningRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? bookId,
    Value<String?>? chapterId,
    Value<DateTime>? startedAt,
    Value<int>? durationMs,
    Value<int>? rowid,
  }) {
    return ListeningRecordsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      startedAt: startedAt ?? this.startedAt,
      durationMs: durationMs ?? this.durationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningRecordsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorageAccountsTable extends StorageAccounts
    with TableInfo<$StorageAccountsTable, StorageAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerTypeMeta = const VerificationMeta(
    'providerType',
  );
  @override
  late final GeneratedColumn<String> providerType = GeneratedColumn<String>(
    'provider_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialRefMeta = const VerificationMeta(
    'credentialRef',
  );
  @override
  late final GeneratedColumn<String> credentialRef = GeneratedColumn<String>(
    'credential_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshMetaMeta = const VerificationMeta(
    'refreshMeta',
  );
  @override
  late final GeneratedColumn<String> refreshMeta = GeneratedColumn<String>(
    'refresh_meta',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerType,
    baseUrl,
    credentialRef,
    refreshMeta,
    isDefault,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorageAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_type')) {
      context.handle(
        _providerTypeMeta,
        providerType.isAcceptableOrUnknown(
          data['provider_type']!,
          _providerTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerTypeMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialRefMeta);
    }
    if (data.containsKey('refresh_meta')) {
      context.handle(
        _refreshMetaMeta,
        refreshMeta.isAcceptableOrUnknown(
          data['refresh_meta']!,
          _refreshMetaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshMetaMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_type'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      credentialRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      )!,
      refreshMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_meta'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StorageAccountsTable createAlias(String alias) {
    return $StorageAccountsTable(attachedDatabase, alias);
  }
}

class StorageAccount extends DataClass implements Insertable<StorageAccount> {
  /// ULID。
  final String id;

  /// `webdav` / `smb` / `saf`。
  final String providerType;

  /// 服务地址。
  final String baseUrl;

  /// 平台安全存储中的凭据引用（不是凭据本身）。
  final String credentialRef;

  /// 刷新语义元数据（JSON：认证类型 / 客户端类型等）。
  final String refreshMeta;

  /// 是否为默认账户。
  final bool isDefault;

  /// 最近更新时间。
  final DateTime updatedAt;
  const StorageAccount({
    required this.id,
    required this.providerType,
    required this.baseUrl,
    required this.credentialRef,
    required this.refreshMeta,
    required this.isDefault,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_type'] = Variable<String>(providerType);
    map['base_url'] = Variable<String>(baseUrl);
    map['credential_ref'] = Variable<String>(credentialRef);
    map['refresh_meta'] = Variable<String>(refreshMeta);
    map['is_default'] = Variable<bool>(isDefault);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StorageAccountsCompanion toCompanion(bool nullToAbsent) {
    return StorageAccountsCompanion(
      id: Value(id),
      providerType: Value(providerType),
      baseUrl: Value(baseUrl),
      credentialRef: Value(credentialRef),
      refreshMeta: Value(refreshMeta),
      isDefault: Value(isDefault),
      updatedAt: Value(updatedAt),
    );
  }

  factory StorageAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageAccount(
      id: serializer.fromJson<String>(json['id']),
      providerType: serializer.fromJson<String>(json['providerType']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      credentialRef: serializer.fromJson<String>(json['credentialRef']),
      refreshMeta: serializer.fromJson<String>(json['refreshMeta']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerType': serializer.toJson<String>(providerType),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'credentialRef': serializer.toJson<String>(credentialRef),
      'refreshMeta': serializer.toJson<String>(refreshMeta),
      'isDefault': serializer.toJson<bool>(isDefault),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StorageAccount copyWith({
    String? id,
    String? providerType,
    String? baseUrl,
    String? credentialRef,
    String? refreshMeta,
    bool? isDefault,
    DateTime? updatedAt,
  }) => StorageAccount(
    id: id ?? this.id,
    providerType: providerType ?? this.providerType,
    baseUrl: baseUrl ?? this.baseUrl,
    credentialRef: credentialRef ?? this.credentialRef,
    refreshMeta: refreshMeta ?? this.refreshMeta,
    isDefault: isDefault ?? this.isDefault,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StorageAccount copyWithCompanion(StorageAccountsCompanion data) {
    return StorageAccount(
      id: data.id.present ? data.id.value : this.id,
      providerType: data.providerType.present
          ? data.providerType.value
          : this.providerType,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      refreshMeta: data.refreshMeta.present
          ? data.refreshMeta.value
          : this.refreshMeta,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageAccount(')
          ..write('id: $id, ')
          ..write('providerType: $providerType, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('refreshMeta: $refreshMeta, ')
          ..write('isDefault: $isDefault, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerType,
    baseUrl,
    credentialRef,
    refreshMeta,
    isDefault,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageAccount &&
          other.id == this.id &&
          other.providerType == this.providerType &&
          other.baseUrl == this.baseUrl &&
          other.credentialRef == this.credentialRef &&
          other.refreshMeta == this.refreshMeta &&
          other.isDefault == this.isDefault &&
          other.updatedAt == this.updatedAt);
}

class StorageAccountsCompanion extends UpdateCompanion<StorageAccount> {
  final Value<String> id;
  final Value<String> providerType;
  final Value<String> baseUrl;
  final Value<String> credentialRef;
  final Value<String> refreshMeta;
  final Value<bool> isDefault;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StorageAccountsCompanion({
    this.id = const Value.absent(),
    this.providerType = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.credentialRef = const Value.absent(),
    this.refreshMeta = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorageAccountsCompanion.insert({
    required String id,
    required String providerType,
    required String baseUrl,
    required String credentialRef,
    required String refreshMeta,
    this.isDefault = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerType = Value(providerType),
       baseUrl = Value(baseUrl),
       credentialRef = Value(credentialRef),
       refreshMeta = Value(refreshMeta),
       updatedAt = Value(updatedAt);
  static Insertable<StorageAccount> custom({
    Expression<String>? id,
    Expression<String>? providerType,
    Expression<String>? baseUrl,
    Expression<String>? credentialRef,
    Expression<String>? refreshMeta,
    Expression<bool>? isDefault,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerType != null) 'provider_type': providerType,
      if (baseUrl != null) 'base_url': baseUrl,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (refreshMeta != null) 'refresh_meta': refreshMeta,
      if (isDefault != null) 'is_default': isDefault,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorageAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? providerType,
    Value<String>? baseUrl,
    Value<String>? credentialRef,
    Value<String>? refreshMeta,
    Value<bool>? isDefault,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StorageAccountsCompanion(
      id: id ?? this.id,
      providerType: providerType ?? this.providerType,
      baseUrl: baseUrl ?? this.baseUrl,
      credentialRef: credentialRef ?? this.credentialRef,
      refreshMeta: refreshMeta ?? this.refreshMeta,
      isDefault: isDefault ?? this.isDefault,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerType.present) {
      map['provider_type'] = Variable<String>(providerType.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = Variable<String>(credentialRef.value);
    }
    if (refreshMeta.present) {
      map['refresh_meta'] = Variable<String>(refreshMeta.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageAccountsCompanion(')
          ..write('id: $id, ')
          ..write('providerType: $providerType, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('refreshMeta: $refreshMeta, ')
          ..write('isDefault: $isDefault, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioCacheEntriesTable extends AudioCacheEntries
    with TableInfo<$AudioCacheEntriesTable, AudioCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES book_sources (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _sourceUrlHashMeta = const VerificationMeta(
    'sourceUrlHash',
  );
  @override
  late final GeneratedColumn<String> sourceUrlHash = GeneratedColumn<String>(
    'source_url_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    chapterId,
    bookId,
    sourceId,
    sourceUrlHash,
    filePath,
    contentType,
    bytes,
    status,
    etag,
    createdAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('source_url_hash')) {
      context.handle(
        _sourceUrlHashMeta,
        sourceUrlHash.isAcceptableOrUnknown(
          data['source_url_hash']!,
          _sourceUrlHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlHashMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chapterId};
  @override
  AudioCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioCacheEntry(
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      sourceUrlHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url_hash'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      ),
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $AudioCacheEntriesTable createAlias(String alias) {
    return $AudioCacheEntriesTable(attachedDatabase, alias);
  }
}

class AudioCacheEntry extends DataClass implements Insertable<AudioCacheEntry> {
  /// 对应章（一章最多一条缓存）。
  final String chapterId;

  /// 冗余书，便于按书清理。
  final String bookId;

  /// 来源；来源硬删除时置空（当前只软删除）。
  final String? sourceId;

  /// 章 URL 的 SHA-256，用于失效判断。
  final String sourceUrlHash;

  /// 缓存文件相对路径。
  final String filePath;

  /// MIME 类型。
  final String? contentType;

  /// 文件字节数。
  final int bytes;

  /// `queued` / `downloading` / `ready` / `failed`。
  final String status;

  /// HTTP ETag（如有）。
  final String? etag;

  /// 创建时间。
  final DateTime createdAt;

  /// 最近访问时间（LRU 清理依据）。
  final DateTime lastAccessedAt;
  const AudioCacheEntry({
    required this.chapterId,
    required this.bookId,
    this.sourceId,
    required this.sourceUrlHash,
    required this.filePath,
    this.contentType,
    required this.bytes,
    required this.status,
    this.etag,
    required this.createdAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chapter_id'] = Variable<String>(chapterId);
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['source_url_hash'] = Variable<String>(sourceUrlHash);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || contentType != null) {
      map['content_type'] = Variable<String>(contentType);
    }
    map['bytes'] = Variable<int>(bytes);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    return map;
  }

  AudioCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return AudioCacheEntriesCompanion(
      chapterId: Value(chapterId),
      bookId: Value(bookId),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      sourceUrlHash: Value(sourceUrlHash),
      filePath: Value(filePath),
      contentType: contentType == null && nullToAbsent
          ? const Value.absent()
          : Value(contentType),
      bytes: Value(bytes),
      status: Value(status),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      createdAt: Value(createdAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory AudioCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioCacheEntry(
      chapterId: serializer.fromJson<String>(json['chapterId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      sourceUrlHash: serializer.fromJson<String>(json['sourceUrlHash']),
      filePath: serializer.fromJson<String>(json['filePath']),
      contentType: serializer.fromJson<String?>(json['contentType']),
      bytes: serializer.fromJson<int>(json['bytes']),
      status: serializer.fromJson<String>(json['status']),
      etag: serializer.fromJson<String?>(json['etag']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chapterId': serializer.toJson<String>(chapterId),
      'bookId': serializer.toJson<String>(bookId),
      'sourceId': serializer.toJson<String?>(sourceId),
      'sourceUrlHash': serializer.toJson<String>(sourceUrlHash),
      'filePath': serializer.toJson<String>(filePath),
      'contentType': serializer.toJson<String?>(contentType),
      'bytes': serializer.toJson<int>(bytes),
      'status': serializer.toJson<String>(status),
      'etag': serializer.toJson<String?>(etag),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
    };
  }

  AudioCacheEntry copyWith({
    String? chapterId,
    String? bookId,
    Value<String?> sourceId = const Value.absent(),
    String? sourceUrlHash,
    String? filePath,
    Value<String?> contentType = const Value.absent(),
    int? bytes,
    String? status,
    Value<String?> etag = const Value.absent(),
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  }) => AudioCacheEntry(
    chapterId: chapterId ?? this.chapterId,
    bookId: bookId ?? this.bookId,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    sourceUrlHash: sourceUrlHash ?? this.sourceUrlHash,
    filePath: filePath ?? this.filePath,
    contentType: contentType.present ? contentType.value : this.contentType,
    bytes: bytes ?? this.bytes,
    status: status ?? this.status,
    etag: etag.present ? etag.value : this.etag,
    createdAt: createdAt ?? this.createdAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  AudioCacheEntry copyWithCompanion(AudioCacheEntriesCompanion data) {
    return AudioCacheEntry(
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourceUrlHash: data.sourceUrlHash.present
          ? data.sourceUrlHash.value
          : this.sourceUrlHash,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      status: data.status.present ? data.status.value : this.status,
      etag: data.etag.present ? data.etag.value : this.etag,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheEntry(')
          ..write('chapterId: $chapterId, ')
          ..write('bookId: $bookId, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceUrlHash: $sourceUrlHash, ')
          ..write('filePath: $filePath, ')
          ..write('contentType: $contentType, ')
          ..write('bytes: $bytes, ')
          ..write('status: $status, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    chapterId,
    bookId,
    sourceId,
    sourceUrlHash,
    filePath,
    contentType,
    bytes,
    status,
    etag,
    createdAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioCacheEntry &&
          other.chapterId == this.chapterId &&
          other.bookId == this.bookId &&
          other.sourceId == this.sourceId &&
          other.sourceUrlHash == this.sourceUrlHash &&
          other.filePath == this.filePath &&
          other.contentType == this.contentType &&
          other.bytes == this.bytes &&
          other.status == this.status &&
          other.etag == this.etag &&
          other.createdAt == this.createdAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class AudioCacheEntriesCompanion extends UpdateCompanion<AudioCacheEntry> {
  final Value<String> chapterId;
  final Value<String> bookId;
  final Value<String?> sourceId;
  final Value<String> sourceUrlHash;
  final Value<String> filePath;
  final Value<String?> contentType;
  final Value<int> bytes;
  final Value<String> status;
  final Value<String?> etag;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastAccessedAt;
  final Value<int> rowid;
  const AudioCacheEntriesCompanion({
    this.chapterId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourceUrlHash = const Value.absent(),
    this.filePath = const Value.absent(),
    this.contentType = const Value.absent(),
    this.bytes = const Value.absent(),
    this.status = const Value.absent(),
    this.etag = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioCacheEntriesCompanion.insert({
    required String chapterId,
    required String bookId,
    this.sourceId = const Value.absent(),
    required String sourceUrlHash,
    required String filePath,
    this.contentType = const Value.absent(),
    required int bytes,
    required String status,
    this.etag = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : chapterId = Value(chapterId),
       bookId = Value(bookId),
       sourceUrlHash = Value(sourceUrlHash),
       filePath = Value(filePath),
       bytes = Value(bytes),
       status = Value(status),
       createdAt = Value(createdAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<AudioCacheEntry> custom({
    Expression<String>? chapterId,
    Expression<String>? bookId,
    Expression<String>? sourceId,
    Expression<String>? sourceUrlHash,
    Expression<String>? filePath,
    Expression<String>? contentType,
    Expression<int>? bytes,
    Expression<String>? status,
    Expression<String>? etag,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chapterId != null) 'chapter_id': chapterId,
      if (bookId != null) 'book_id': bookId,
      if (sourceId != null) 'source_id': sourceId,
      if (sourceUrlHash != null) 'source_url_hash': sourceUrlHash,
      if (filePath != null) 'file_path': filePath,
      if (contentType != null) 'content_type': contentType,
      if (bytes != null) 'bytes': bytes,
      if (status != null) 'status': status,
      if (etag != null) 'etag': etag,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioCacheEntriesCompanion copyWith({
    Value<String>? chapterId,
    Value<String>? bookId,
    Value<String?>? sourceId,
    Value<String>? sourceUrlHash,
    Value<String>? filePath,
    Value<String?>? contentType,
    Value<int>? bytes,
    Value<String>? status,
    Value<String?>? etag,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return AudioCacheEntriesCompanion(
      chapterId: chapterId ?? this.chapterId,
      bookId: bookId ?? this.bookId,
      sourceId: sourceId ?? this.sourceId,
      sourceUrlHash: sourceUrlHash ?? this.sourceUrlHash,
      filePath: filePath ?? this.filePath,
      contentType: contentType ?? this.contentType,
      bytes: bytes ?? this.bytes,
      status: status ?? this.status,
      etag: etag ?? this.etag,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourceUrlHash.present) {
      map['source_url_hash'] = Variable<String>(sourceUrlHash.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioCacheEntriesCompanion(')
          ..write('chapterId: $chapterId, ')
          ..write('bookId: $bookId, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourceUrlHash: $sourceUrlHash, ')
          ..write('filePath: $filePath, ')
          ..write('contentType: $contentType, ')
          ..write('bytes: $bytes, ')
          ..write('status: $status, ')
          ..write('etag: $etag, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  /// 设置键。
  final String key;

  /// JSON / 原始字符串值。
  final String value;

  /// 最近更新时间。
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TomeToneDatabase extends GeneratedDatabase {
  _$TomeToneDatabase(QueryExecutor e) : super(e);
  $TomeToneDatabaseManager get managers => $TomeToneDatabaseManager(this);
  late final $LibraryRootsTable libraryRoots = $LibraryRootsTable(this);
  late final $BookSourcesTable bookSources = $BookSourcesTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $VolumesTable volumes = $VolumesTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $BookMetadataOverridesTable bookMetadataOverrides =
      $BookMetadataOverridesTable(this);
  late final $BookTagsTable bookTags = $BookTagsTable(this);
  late final $PlaybackProgressTable playbackProgress = $PlaybackProgressTable(
    this,
  );
  late final $PerBookPrefsTable perBookPrefs = $PerBookPrefsTable(this);
  late final $ListeningRecordsTable listeningRecords = $ListeningRecordsTable(
    this,
  );
  late final $StorageAccountsTable storageAccounts = $StorageAccountsTable(
    this,
  );
  late final $AudioCacheEntriesTable audioCacheEntries =
      $AudioCacheEntriesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final Index libraryRootsType = Index(
    'library_roots_type',
    'CREATE INDEX library_roots_type ON library_roots (type)',
  );
  late final Index bookSourcesSourceUrl = Index(
    'book_sources_source_url',
    'CREATE UNIQUE INDEX book_sources_source_url ON book_sources (source_url)',
  );
  late final Index bookSourcesLibraryRoot = Index(
    'book_sources_library_root',
    'CREATE UNIQUE INDEX book_sources_library_root ON book_sources (library_root_id)',
  );
  late final Index bookSourcesDeletedAt = Index(
    'book_sources_deleted_at',
    'CREATE INDEX book_sources_deleted_at ON book_sources (deleted_at)',
  );
  late final Index booksRootPathUnique = Index(
    'books_root_path_unique',
    'CREATE UNIQUE INDEX books_root_path_unique ON books (library_root_id, root_path)',
  );
  late final Index booksSeries = Index(
    'books_series',
    'CREATE INDEX books_series ON books (series_name, series_index)',
  );
  late final Index volumesBookPathUnique = Index(
    'volumes_book_path_unique',
    'CREATE UNIQUE INDEX volumes_book_path_unique ON volumes (book_id, path)',
  );
  late final Index chaptersBindingUnique = Index(
    'chapters_binding_unique',
    'CREATE UNIQUE INDEX chapters_binding_unique ON chapters (library_root_id, file_path)',
  );
  late final Index chaptersBookIndex = Index(
    'chapters_book_index',
    'CREATE INDEX chapters_book_index ON chapters (book_id, chapter_index)',
  );
  late final Index chaptersVolumeIndex = Index(
    'chapters_volume_index',
    'CREATE INDEX chapters_volume_index ON chapters (volume_id, chapter_index)',
  );
  late final Index bookTagsTag = Index(
    'book_tags_tag',
    'CREATE INDEX book_tags_tag ON book_tags (tag)',
  );
  late final Index playbackProgressUpdated = Index(
    'playback_progress_updated',
    'CREATE INDEX playback_progress_updated ON playback_progress (updated_at)',
  );
  late final Index listeningRecordsStarted = Index(
    'listening_records_started',
    'CREATE INDEX listening_records_started ON listening_records (started_at)',
  );
  late final Index listeningRecordsBook = Index(
    'listening_records_book',
    'CREATE INDEX listening_records_book ON listening_records (book_id, started_at)',
  );
  late final Index storageAccountsDefault = Index(
    'storage_accounts_default',
    'CREATE INDEX storage_accounts_default ON storage_accounts (is_default)',
  );
  late final Index audioCacheBook = Index(
    'audio_cache_book',
    'CREATE INDEX audio_cache_book ON audio_cache_entries (book_id)',
  );
  late final Index audioCacheAccessed = Index(
    'audio_cache_accessed',
    'CREATE INDEX audio_cache_accessed ON audio_cache_entries (last_accessed_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryRoots,
    bookSources,
    books,
    volumes,
    chapters,
    bookMetadataOverrides,
    bookTags,
    playbackProgress,
    perBookPrefs,
    listeningRecords,
    storageAccounts,
    audioCacheEntries,
    appSettings,
    libraryRootsType,
    bookSourcesSourceUrl,
    bookSourcesLibraryRoot,
    bookSourcesDeletedAt,
    booksRootPathUnique,
    booksSeries,
    volumesBookPathUnique,
    chaptersBindingUnique,
    chaptersBookIndex,
    chaptersVolumeIndex,
    bookTagsTag,
    playbackProgressUpdated,
    listeningRecordsStarted,
    listeningRecordsBook,
    storageAccountsDefault,
    audioCacheBook,
    audioCacheAccessed,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_roots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('books', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'book_sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('books', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('volumes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'volumes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'library_roots',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_metadata_overrides', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('per_book_prefs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('listening_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('listening_records', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('audio_cache_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('audio_cache_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'book_sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('audio_cache_entries', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$LibraryRootsTableCreateCompanionBuilder =
    LibraryRootsCompanion Function({
      required String id,
      required String type,
      required String uri,
      required String displayName,
      Value<DateTime?> lastScanAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LibraryRootsTableUpdateCompanionBuilder =
    LibraryRootsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> uri,
      Value<String> displayName,
      Value<DateTime?> lastScanAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$LibraryRootsTableReferences
    extends
        BaseReferences<_$TomeToneDatabase, $LibraryRootsTable, LibraryRoot> {
  $$LibraryRootsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookSourcesTable, List<BookSourceRow>>
  _bookSourcesRefsTable(_$TomeToneDatabase db) => MultiTypedResultKey.fromTable(
    db.bookSources,
    aliasName: 'library_roots__id__book_sources__library_root_id',
  );

  $$BookSourcesTableProcessedTableManager get bookSourcesRefs {
    final manager = $$BookSourcesTableTableManager(
      $_db,
      $_db.bookSources,
    ).filter((f) => f.libraryRootId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookSourcesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BooksTable, List<Book>> _booksRefsTable(
    _$TomeToneDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.books,
    aliasName: 'library_roots__id__books__library_root_id',
  );

  $$BooksTableProcessedTableManager get booksRefs {
    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.libraryRootId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_booksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$TomeToneDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'library_roots__id__chapters__library_root_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.libraryRootId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LibraryRootsTableFilterComposer
    extends Composer<_$TomeToneDatabase, $LibraryRootsTable> {
  $$LibraryRootsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bookSourcesRefs(
    Expression<bool> Function($$BookSourcesTableFilterComposer f) f,
  ) {
    final $$BookSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.libraryRootId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableFilterComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> booksRefs(
    Expression<bool> Function($$BooksTableFilterComposer f) f,
  ) {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.libraryRootId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.libraryRootId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryRootsTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $LibraryRootsTable> {
  $$LibraryRootsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryRootsTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $LibraryRootsTable> {
  $$LibraryRootsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> bookSourcesRefs<T extends Object>(
    Expression<T> Function($$BookSourcesTableAnnotationComposer a) f,
  ) {
    final $$BookSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.libraryRootId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> booksRefs<T extends Object>(
    Expression<T> Function($$BooksTableAnnotationComposer a) f,
  ) {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.libraryRootId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.libraryRootId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LibraryRootsTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $LibraryRootsTable,
          LibraryRoot,
          $$LibraryRootsTableFilterComposer,
          $$LibraryRootsTableOrderingComposer,
          $$LibraryRootsTableAnnotationComposer,
          $$LibraryRootsTableCreateCompanionBuilder,
          $$LibraryRootsTableUpdateCompanionBuilder,
          (LibraryRoot, $$LibraryRootsTableReferences),
          LibraryRoot,
          PrefetchHooks Function({
            bool bookSourcesRefs,
            bool booksRefs,
            bool chaptersRefs,
          })
        > {
  $$LibraryRootsTableTableManager(
    _$TomeToneDatabase db,
    $LibraryRootsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryRootsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryRootsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryRootsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DateTime?> lastScanAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryRootsCompanion(
                id: id,
                type: type,
                uri: uri,
                displayName: displayName,
                lastScanAt: lastScanAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String uri,
                required String displayName,
                Value<DateTime?> lastScanAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LibraryRootsCompanion.insert(
                id: id,
                type: type,
                uri: uri,
                displayName: displayName,
                lastScanAt: lastScanAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryRootsTable, LibraryRoot>(table),
                  $$LibraryRootsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookSourcesRefs = false,
                booksRefs = false,
                chaptersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bookSourcesRefs) db.bookSources,
                    if (booksRefs) db.books,
                    if (chaptersRefs) db.chapters,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bookSourcesRefs)
                        await $_getPrefetchedData<
                          LibraryRoot,
                          $LibraryRootsTable,
                          BookSourceRow
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryRootsTableReferences
                              ._bookSourcesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryRootsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookSourcesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryRootId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (booksRefs)
                        await $_getPrefetchedData<
                          LibraryRoot,
                          $LibraryRootsTable,
                          Book
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryRootsTableReferences
                              ._booksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryRootsTableReferences(
                                db,
                                table,
                                p0,
                              ).booksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryRootId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          LibraryRoot,
                          $LibraryRootsTable,
                          Chapter
                        >(
                          currentTable: table,
                          referencedTable: $$LibraryRootsTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LibraryRootsTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.libraryRootId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LibraryRootsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $LibraryRootsTable,
      LibraryRoot,
      $$LibraryRootsTableFilterComposer,
      $$LibraryRootsTableOrderingComposer,
      $$LibraryRootsTableAnnotationComposer,
      $$LibraryRootsTableCreateCompanionBuilder,
      $$LibraryRootsTableUpdateCompanionBuilder,
      (LibraryRoot, $$LibraryRootsTableReferences),
      LibraryRoot,
      PrefetchHooks Function({
        bool bookSourcesRefs,
        bool booksRefs,
        bool chaptersRefs,
      })
    >;
typedef $$BookSourcesTableCreateCompanionBuilder =
    BookSourcesCompanion Function({
      required String id,
      required String libraryRootId,
      required String sourceUrl,
      required String name,
      Value<String?> groupName,
      required int sourceType,
      required String rawJson,
      Value<String?> headerJson,
      Value<String?> exploreUrl,
      Value<String?> searchUrl,
      Value<String?> jsLib,
      Value<bool> enabled,
      Value<bool> enabledExplore,
      Value<int> customOrder,
      Value<int?> concurrentRate,
      Value<DateTime?> lastTestAt,
      Value<bool?> lastTestOk,
      Value<String?> lastError,
      Value<int> consecutiveFailures,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$BookSourcesTableUpdateCompanionBuilder =
    BookSourcesCompanion Function({
      Value<String> id,
      Value<String> libraryRootId,
      Value<String> sourceUrl,
      Value<String> name,
      Value<String?> groupName,
      Value<int> sourceType,
      Value<String> rawJson,
      Value<String?> headerJson,
      Value<String?> exploreUrl,
      Value<String?> searchUrl,
      Value<String?> jsLib,
      Value<bool> enabled,
      Value<bool> enabledExplore,
      Value<int> customOrder,
      Value<int?> concurrentRate,
      Value<DateTime?> lastTestAt,
      Value<bool?> lastTestOk,
      Value<String?> lastError,
      Value<int> consecutiveFailures,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$BookSourcesTableReferences
    extends
        BaseReferences<_$TomeToneDatabase, $BookSourcesTable, BookSourceRow> {
  $$BookSourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LibraryRootsTable _libraryRootIdTable(_$TomeToneDatabase db) => db
      .libraryRoots
      .createAlias('book_sources__library_root_id__library_roots__id');

  $$LibraryRootsTableProcessedTableManager get libraryRootId {
    final $_column = $_itemColumn<String>('library_root_id')!;

    final manager = $$LibraryRootsTableTableManager(
      $_db,
      $_db.libraryRoots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryRootIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BooksTable, List<Book>> _booksRefsTable(
    _$TomeToneDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.books,
    aliasName: 'book_sources__id__books__source_id',
  );

  $$BooksTableProcessedTableManager get booksRefs {
    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_booksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AudioCacheEntriesTable, List<AudioCacheEntry>>
  _audioCacheEntriesRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.audioCacheEntries,
        aliasName: 'book_sources__id__audio_cache_entries__source_id',
      );

  $$AudioCacheEntriesTableProcessedTableManager get audioCacheEntriesRefs {
    final manager = $$AudioCacheEntriesTableTableManager(
      $_db,
      $_db.audioCacheEntries,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _audioCacheEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BookSourcesTableFilterComposer
    extends Composer<_$TomeToneDatabase, $BookSourcesTable> {
  $$BookSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headerJson => $composableBuilder(
    column: $table.headerJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exploreUrl => $composableBuilder(
    column: $table.exploreUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchUrl => $composableBuilder(
    column: $table.searchUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabledExplore => $composableBuilder(
    column: $table.enabledExplore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastTestAt => $composableBuilder(
    column: $table.lastTestAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastTestOk => $composableBuilder(
    column: $table.lastTestOk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryRootsTableFilterComposer get libraryRootId {
    final $$LibraryRootsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableFilterComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> booksRefs(
    Expression<bool> Function($$BooksTableFilterComposer f) f,
  ) {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> audioCacheEntriesRefs(
    Expression<bool> Function($$AudioCacheEntriesTableFilterComposer f) f,
  ) {
    final $$AudioCacheEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioCacheEntries,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioCacheEntriesTableFilterComposer(
            $db: $db,
            $table: $db.audioCacheEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BookSourcesTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $BookSourcesTable> {
  $$BookSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJson => $composableBuilder(
    column: $table.rawJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headerJson => $composableBuilder(
    column: $table.headerJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exploreUrl => $composableBuilder(
    column: $table.exploreUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchUrl => $composableBuilder(
    column: $table.searchUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsLib => $composableBuilder(
    column: $table.jsLib,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabledExplore => $composableBuilder(
    column: $table.enabledExplore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastTestAt => $composableBuilder(
    column: $table.lastTestAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastTestOk => $composableBuilder(
    column: $table.lastTestOk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryRootsTableOrderingComposer get libraryRootId {
    final $$LibraryRootsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookSourcesTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $BookSourcesTable> {
  $$BookSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<int> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<String> get headerJson => $composableBuilder(
    column: $table.headerJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exploreUrl => $composableBuilder(
    column: $table.exploreUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchUrl =>
      $composableBuilder(column: $table.searchUrl, builder: (column) => column);

  GeneratedColumn<String> get jsLib =>
      $composableBuilder(column: $table.jsLib, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get enabledExplore => $composableBuilder(
    column: $table.enabledExplore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get customOrder => $composableBuilder(
    column: $table.customOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get concurrentRate => $composableBuilder(
    column: $table.concurrentRate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastTestAt => $composableBuilder(
    column: $table.lastTestAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastTestOk => $composableBuilder(
    column: $table.lastTestOk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get consecutiveFailures => $composableBuilder(
    column: $table.consecutiveFailures,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$LibraryRootsTableAnnotationComposer get libraryRootId {
    final $$LibraryRootsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> booksRefs<T extends Object>(
    Expression<T> Function($$BooksTableAnnotationComposer a) f,
  ) {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> audioCacheEntriesRefs<T extends Object>(
    Expression<T> Function($$AudioCacheEntriesTableAnnotationComposer a) f,
  ) {
    final $$AudioCacheEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.audioCacheEntries,
          getReferencedColumn: (t) => t.sourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioCacheEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.audioCacheEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BookSourcesTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $BookSourcesTable,
          BookSourceRow,
          $$BookSourcesTableFilterComposer,
          $$BookSourcesTableOrderingComposer,
          $$BookSourcesTableAnnotationComposer,
          $$BookSourcesTableCreateCompanionBuilder,
          $$BookSourcesTableUpdateCompanionBuilder,
          (BookSourceRow, $$BookSourcesTableReferences),
          BookSourceRow,
          PrefetchHooks Function({
            bool libraryRootId,
            bool booksRefs,
            bool audioCacheEntriesRefs,
          })
        > {
  $$BookSourcesTableTableManager(_$TomeToneDatabase db, $BookSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> libraryRootId = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<int> sourceType = const Value.absent(),
                Value<String> rawJson = const Value.absent(),
                Value<String?> headerJson = const Value.absent(),
                Value<String?> exploreUrl = const Value.absent(),
                Value<String?> searchUrl = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> enabledExplore = const Value.absent(),
                Value<int> customOrder = const Value.absent(),
                Value<int?> concurrentRate = const Value.absent(),
                Value<DateTime?> lastTestAt = const Value.absent(),
                Value<bool?> lastTestOk = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookSourcesCompanion(
                id: id,
                libraryRootId: libraryRootId,
                sourceUrl: sourceUrl,
                name: name,
                groupName: groupName,
                sourceType: sourceType,
                rawJson: rawJson,
                headerJson: headerJson,
                exploreUrl: exploreUrl,
                searchUrl: searchUrl,
                jsLib: jsLib,
                enabled: enabled,
                enabledExplore: enabledExplore,
                customOrder: customOrder,
                concurrentRate: concurrentRate,
                lastTestAt: lastTestAt,
                lastTestOk: lastTestOk,
                lastError: lastError,
                consecutiveFailures: consecutiveFailures,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String libraryRootId,
                required String sourceUrl,
                required String name,
                Value<String?> groupName = const Value.absent(),
                required int sourceType,
                required String rawJson,
                Value<String?> headerJson = const Value.absent(),
                Value<String?> exploreUrl = const Value.absent(),
                Value<String?> searchUrl = const Value.absent(),
                Value<String?> jsLib = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> enabledExplore = const Value.absent(),
                Value<int> customOrder = const Value.absent(),
                Value<int?> concurrentRate = const Value.absent(),
                Value<DateTime?> lastTestAt = const Value.absent(),
                Value<bool?> lastTestOk = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> consecutiveFailures = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookSourcesCompanion.insert(
                id: id,
                libraryRootId: libraryRootId,
                sourceUrl: sourceUrl,
                name: name,
                groupName: groupName,
                sourceType: sourceType,
                rawJson: rawJson,
                headerJson: headerJson,
                exploreUrl: exploreUrl,
                searchUrl: searchUrl,
                jsLib: jsLib,
                enabled: enabled,
                enabledExplore: enabledExplore,
                customOrder: customOrder,
                concurrentRate: concurrentRate,
                lastTestAt: lastTestAt,
                lastTestOk: lastTestOk,
                lastError: lastError,
                consecutiveFailures: consecutiveFailures,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookSourcesTable, BookSourceRow>(table),
                  $$BookSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                libraryRootId = false,
                booksRefs = false,
                audioCacheEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (booksRefs) db.books,
                    if (audioCacheEntriesRefs) db.audioCacheEntries,
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
                        if (libraryRootId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryRootId,
                            referencedTable: $$BookSourcesTableReferences
                                ._libraryRootIdTable(db),
                            referencedColumn: $$BookSourcesTableReferences
                                ._libraryRootIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (booksRefs)
                        await $_getPrefetchedData<
                          BookSourceRow,
                          $BookSourcesTable,
                          Book
                        >(
                          currentTable: table,
                          referencedTable: $$BookSourcesTableReferences
                              ._booksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BookSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).booksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (audioCacheEntriesRefs)
                        await $_getPrefetchedData<
                          BookSourceRow,
                          $BookSourcesTable,
                          AudioCacheEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BookSourcesTableReferences
                              ._audioCacheEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BookSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).audioCacheEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BookSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $BookSourcesTable,
      BookSourceRow,
      $$BookSourcesTableFilterComposer,
      $$BookSourcesTableOrderingComposer,
      $$BookSourcesTableAnnotationComposer,
      $$BookSourcesTableCreateCompanionBuilder,
      $$BookSourcesTableUpdateCompanionBuilder,
      (BookSourceRow, $$BookSourcesTableReferences),
      BookSourceRow,
      PrefetchHooks Function({
        bool libraryRootId,
        bool booksRefs,
        bool audioCacheEntriesRefs,
      })
    >;
typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  required String libraryRootId,
  required String title,
  Value<String?> author,
  Value<String?> narrator,
  Value<String?> seriesName,
  Value<int?> seriesIndex,
  required String rootPath,
  Value<String?> coverPath,
  Value<CoverSource> coverSourceType,
  required String sourceType,
  Value<String?> sourceUri,
  Value<int> totalChapters,
  Value<int> totalDurationMs,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> onShelf,
  Value<String?> sourceId,
  Value<String?> coverUrl,
  Value<String?> description,
  Value<String?> kind,
  Value<String?> wordCount,
  Value<String?> sourceStatus,
  Value<String?> lastChapter,
  Value<DateTime?> sourceUpdatedAt,
  Value<DateTime?> lastRefreshAt,
  Value<bool?> lastRefreshOk,
  Value<String?> lastRefreshError,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<String> libraryRootId,
  Value<String> title,
  Value<String?> author,
  Value<String?> narrator,
  Value<String?> seriesName,
  Value<int?> seriesIndex,
  Value<String> rootPath,
  Value<String?> coverPath,
  Value<CoverSource> coverSourceType,
  Value<String> sourceType,
  Value<String?> sourceUri,
  Value<int> totalChapters,
  Value<int> totalDurationMs,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> onShelf,
  Value<String?> sourceId,
  Value<String?> coverUrl,
  Value<String?> description,
  Value<String?> kind,
  Value<String?> wordCount,
  Value<String?> sourceStatus,
  Value<String?> lastChapter,
  Value<DateTime?> sourceUpdatedAt,
  Value<DateTime?> lastRefreshAt,
  Value<bool?> lastRefreshOk,
  Value<String?> lastRefreshError,
  Value<int> rowid,
});

final class $$BooksTableReferences
    extends BaseReferences<_$TomeToneDatabase, $BooksTable, Book> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LibraryRootsTable _libraryRootIdTable(_$TomeToneDatabase db) =>
      db.libraryRoots.createAlias('books__library_root_id__library_roots__id');

  $$LibraryRootsTableProcessedTableManager get libraryRootId {
    final $_column = $_itemColumn<String>('library_root_id')!;

    final manager = $$LibraryRootsTableTableManager(
      $_db,
      $_db.libraryRoots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryRootIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BookSourcesTable _sourceIdTable(_$TomeToneDatabase db) =>
      db.bookSources.createAlias('books__source_id__book_sources__id');

  $$BookSourcesTableProcessedTableManager? get sourceId {
    final $_column = $_itemColumn<String>('source_id');
    if ($_column == null) return null;
    final manager = $$BookSourcesTableTableManager(
      $_db,
      $_db.bookSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$VolumesTable, List<Volume>> _volumesRefsTable(
    _$TomeToneDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.volumes,
    aliasName: 'books__id__volumes__book_id',
  );

  $$VolumesTableProcessedTableManager get volumesRefs {
    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_volumesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$TomeToneDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'books__id__chapters__book_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $BookMetadataOverridesTable,
    List<BookMetadataOverride>
  >
  _bookMetadataOverridesRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.bookMetadataOverrides,
        aliasName: 'books__id__book_metadata_overrides__book_id',
      );

  $$BookMetadataOverridesTableProcessedTableManager
  get bookMetadataOverridesRefs {
    final manager = $$BookMetadataOverridesTableTableManager(
      $_db,
      $_db.bookMetadataOverrides,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bookMetadataOverridesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookTagsTable, List<BookTag>> _bookTagsRefsTable(
    _$TomeToneDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bookTags,
    aliasName: 'books__id__book_tags__book_id',
  );

  $$BookTagsTableProcessedTableManager get bookTagsRefs {
    final manager = $$BookTagsTableTableManager(
      $_db,
      $_db.bookTags,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackProgressTable, List<PlaybackProgressData>>
  _playbackProgressRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackProgress,
        aliasName: 'books__id__playback_progress__book_id',
      );

  $$PlaybackProgressTableProcessedTableManager get playbackProgressRefs {
    final manager = $$PlaybackProgressTableTableManager(
      $_db,
      $_db.playbackProgress,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PerBookPrefsTable, List<PerBookPref>>
  _perBookPrefsRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.perBookPrefs,
        aliasName: 'books__id__per_book_prefs__book_id',
      );

  $$PerBookPrefsTableProcessedTableManager get perBookPrefsRefs {
    final manager = $$PerBookPrefsTableTableManager(
      $_db,
      $_db.perBookPrefs,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_perBookPrefsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ListeningRecordsTable, List<ListeningRecord>>
  _listeningRecordsRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.listeningRecords,
        aliasName: 'books__id__listening_records__book_id',
      );

  $$ListeningRecordsTableProcessedTableManager get listeningRecordsRefs {
    final manager = $$ListeningRecordsTableTableManager(
      $_db,
      $_db.listeningRecords,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _listeningRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AudioCacheEntriesTable, List<AudioCacheEntry>>
  _audioCacheEntriesRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.audioCacheEntries,
        aliasName: 'books__id__audio_cache_entries__book_id',
      );

  $$AudioCacheEntriesTableProcessedTableManager get audioCacheEntriesRefs {
    final manager = $$AudioCacheEntriesTableTableManager(
      $_db,
      $_db.audioCacheEntries,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _audioCacheEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BooksTableFilterComposer
    extends Composer<_$TomeToneDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narrator => $composableBuilder(
    column: $table.narrator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootPath => $composableBuilder(
    column: $table.rootPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CoverSource, CoverSource, int>
  get coverSourceType => $composableBuilder(
    column: $table.coverSourceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onShelf => $composableBuilder(
    column: $table.onShelf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceStatus => $composableBuilder(
    column: $table.sourceStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastChapter => $composableBuilder(
    column: $table.lastChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lastRefreshOk => $composableBuilder(
    column: $table.lastRefreshOk,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastRefreshError => $composableBuilder(
    column: $table.lastRefreshError,
    builder: (column) => ColumnFilters(column),
  );

  $$LibraryRootsTableFilterComposer get libraryRootId {
    final $$LibraryRootsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableFilterComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookSourcesTableFilterComposer get sourceId {
    final $$BookSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableFilterComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> volumesRefs(
    Expression<bool> Function($$VolumesTableFilterComposer f) f,
  ) {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookMetadataOverridesRefs(
    Expression<bool> Function($$BookMetadataOverridesTableFilterComposer f) f,
  ) {
    final $$BookMetadataOverridesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bookMetadataOverrides,
          getReferencedColumn: (t) => t.bookId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BookMetadataOverridesTableFilterComposer(
                $db: $db,
                $table: $db.bookMetadataOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> bookTagsRefs(
    Expression<bool> Function($$BookTagsTableFilterComposer f) f,
  ) {
    final $$BookTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookTags,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookTagsTableFilterComposer(
            $db: $db,
            $table: $db.bookTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackProgressRefs(
    Expression<bool> Function($$PlaybackProgressTableFilterComposer f) f,
  ) {
    final $$PlaybackProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackProgress,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackProgressTableFilterComposer(
            $db: $db,
            $table: $db.playbackProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> perBookPrefsRefs(
    Expression<bool> Function($$PerBookPrefsTableFilterComposer f) f,
  ) {
    final $$PerBookPrefsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.perBookPrefs,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PerBookPrefsTableFilterComposer(
            $db: $db,
            $table: $db.perBookPrefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listeningRecordsRefs(
    Expression<bool> Function($$ListeningRecordsTableFilterComposer f) f,
  ) {
    final $$ListeningRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningRecords,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListeningRecordsTableFilterComposer(
            $db: $db,
            $table: $db.listeningRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> audioCacheEntriesRefs(
    Expression<bool> Function($$AudioCacheEntriesTableFilterComposer f) f,
  ) {
    final $$AudioCacheEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioCacheEntries,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioCacheEntriesTableFilterComposer(
            $db: $db,
            $table: $db.audioCacheEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narrator => $composableBuilder(
    column: $table.narrator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootPath => $composableBuilder(
    column: $table.rootPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverSourceType => $composableBuilder(
    column: $table.coverSourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onShelf => $composableBuilder(
    column: $table.onShelf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceStatus => $composableBuilder(
    column: $table.sourceStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastChapter => $composableBuilder(
    column: $table.lastChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lastRefreshOk => $composableBuilder(
    column: $table.lastRefreshOk,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastRefreshError => $composableBuilder(
    column: $table.lastRefreshError,
    builder: (column) => ColumnOrderings(column),
  );

  $$LibraryRootsTableOrderingComposer get libraryRootId {
    final $$LibraryRootsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookSourcesTableOrderingComposer get sourceId {
    final $$BookSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BooksTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get narrator =>
      $composableBuilder(column: $table.narrator, builder: (column) => column);

  GeneratedColumn<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CoverSource, int> get coverSourceType =>
      $composableBuilder(
        column: $table.coverSourceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get onShelf =>
      $composableBuilder(column: $table.onShelf, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<String> get sourceStatus => $composableBuilder(
    column: $table.sourceStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastChapter => $composableBuilder(
    column: $table.lastChapter,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lastRefreshOk => $composableBuilder(
    column: $table.lastRefreshOk,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastRefreshError => $composableBuilder(
    column: $table.lastRefreshError,
    builder: (column) => column,
  );

  $$LibraryRootsTableAnnotationComposer get libraryRootId {
    final $$LibraryRootsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookSourcesTableAnnotationComposer get sourceId {
    final $$BookSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> volumesRefs<T extends Object>(
    Expression<T> Function($$VolumesTableAnnotationComposer a) f,
  ) {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookMetadataOverridesRefs<T extends Object>(
    Expression<T> Function($$BookMetadataOverridesTableAnnotationComposer a) f,
  ) {
    final $$BookMetadataOverridesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bookMetadataOverrides,
          getReferencedColumn: (t) => t.bookId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BookMetadataOverridesTableAnnotationComposer(
                $db: $db,
                $table: $db.bookMetadataOverrides,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> bookTagsRefs<T extends Object>(
    Expression<T> Function($$BookTagsTableAnnotationComposer a) f,
  ) {
    final $$BookTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookTags,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.bookTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackProgressRefs<T extends Object>(
    Expression<T> Function($$PlaybackProgressTableAnnotationComposer a) f,
  ) {
    final $$PlaybackProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackProgress,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.playbackProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> perBookPrefsRefs<T extends Object>(
    Expression<T> Function($$PerBookPrefsTableAnnotationComposer a) f,
  ) {
    final $$PerBookPrefsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.perBookPrefs,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PerBookPrefsTableAnnotationComposer(
            $db: $db,
            $table: $db.perBookPrefs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> listeningRecordsRefs<T extends Object>(
    Expression<T> Function($$ListeningRecordsTableAnnotationComposer a) f,
  ) {
    final $$ListeningRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningRecords,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListeningRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.listeningRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> audioCacheEntriesRefs<T extends Object>(
    Expression<T> Function($$AudioCacheEntriesTableAnnotationComposer a) f,
  ) {
    final $$AudioCacheEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.audioCacheEntries,
          getReferencedColumn: (t) => t.bookId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioCacheEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.audioCacheEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, $$BooksTableReferences),
          Book,
          PrefetchHooks Function({
            bool libraryRootId,
            bool sourceId,
            bool volumesRefs,
            bool chaptersRefs,
            bool bookMetadataOverridesRefs,
            bool bookTagsRefs,
            bool playbackProgressRefs,
            bool perBookPrefsRefs,
            bool listeningRecordsRefs,
            bool audioCacheEntriesRefs,
          })
        > {
  $$BooksTableTableManager(_$TomeToneDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> libraryRootId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> narrator = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<int?> seriesIndex = const Value.absent(),
                Value<String> rootPath = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<CoverSource> coverSourceType = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceUri = const Value.absent(),
                Value<int> totalChapters = const Value.absent(),
                Value<int> totalDurationMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> onShelf = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<String?> sourceStatus = const Value.absent(),
                Value<String?> lastChapter = const Value.absent(),
                Value<DateTime?> sourceUpdatedAt = const Value.absent(),
                Value<DateTime?> lastRefreshAt = const Value.absent(),
                Value<bool?> lastRefreshOk = const Value.absent(),
                Value<String?> lastRefreshError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                libraryRootId: libraryRootId,
                title: title,
                author: author,
                narrator: narrator,
                seriesName: seriesName,
                seriesIndex: seriesIndex,
                rootPath: rootPath,
                coverPath: coverPath,
                coverSourceType: coverSourceType,
                sourceType: sourceType,
                sourceUri: sourceUri,
                totalChapters: totalChapters,
                totalDurationMs: totalDurationMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                onShelf: onShelf,
                sourceId: sourceId,
                coverUrl: coverUrl,
                description: description,
                kind: kind,
                wordCount: wordCount,
                sourceStatus: sourceStatus,
                lastChapter: lastChapter,
                sourceUpdatedAt: sourceUpdatedAt,
                lastRefreshAt: lastRefreshAt,
                lastRefreshOk: lastRefreshOk,
                lastRefreshError: lastRefreshError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String libraryRootId,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String?> narrator = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<int?> seriesIndex = const Value.absent(),
                required String rootPath,
                Value<String?> coverPath = const Value.absent(),
                Value<CoverSource> coverSourceType = const Value.absent(),
                required String sourceType,
                Value<String?> sourceUri = const Value.absent(),
                Value<int> totalChapters = const Value.absent(),
                Value<int> totalDurationMs = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> onShelf = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> wordCount = const Value.absent(),
                Value<String?> sourceStatus = const Value.absent(),
                Value<String?> lastChapter = const Value.absent(),
                Value<DateTime?> sourceUpdatedAt = const Value.absent(),
                Value<DateTime?> lastRefreshAt = const Value.absent(),
                Value<bool?> lastRefreshOk = const Value.absent(),
                Value<String?> lastRefreshError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                libraryRootId: libraryRootId,
                title: title,
                author: author,
                narrator: narrator,
                seriesName: seriesName,
                seriesIndex: seriesIndex,
                rootPath: rootPath,
                coverPath: coverPath,
                coverSourceType: coverSourceType,
                sourceType: sourceType,
                sourceUri: sourceUri,
                totalChapters: totalChapters,
                totalDurationMs: totalDurationMs,
                createdAt: createdAt,
                updatedAt: updatedAt,
                onShelf: onShelf,
                sourceId: sourceId,
                coverUrl: coverUrl,
                description: description,
                kind: kind,
                wordCount: wordCount,
                sourceStatus: sourceStatus,
                lastChapter: lastChapter,
                sourceUpdatedAt: sourceUpdatedAt,
                lastRefreshAt: lastRefreshAt,
                lastRefreshOk: lastRefreshOk,
                lastRefreshError: lastRefreshError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, Book>(table),
                  $$BooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                libraryRootId = false,
                sourceId = false,
                volumesRefs = false,
                chaptersRefs = false,
                bookMetadataOverridesRefs = false,
                bookTagsRefs = false,
                playbackProgressRefs = false,
                perBookPrefsRefs = false,
                listeningRecordsRefs = false,
                audioCacheEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (volumesRefs) db.volumes,
                    if (chaptersRefs) db.chapters,
                    if (bookMetadataOverridesRefs) db.bookMetadataOverrides,
                    if (bookTagsRefs) db.bookTags,
                    if (playbackProgressRefs) db.playbackProgress,
                    if (perBookPrefsRefs) db.perBookPrefs,
                    if (listeningRecordsRefs) db.listeningRecords,
                    if (audioCacheEntriesRefs) db.audioCacheEntries,
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
                        if (libraryRootId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryRootId,
                            referencedTable: $$BooksTableReferences
                                ._libraryRootIdTable(db),
                            referencedColumn: $$BooksTableReferences
                                ._libraryRootIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: $$BooksTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: $$BooksTableReferences
                                ._sourceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (volumesRefs)
                        await $_getPrefetchedData<Book, $BooksTable, Volume>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._volumesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(db, table, p0).volumesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chaptersRefs)
                        await $_getPrefetchedData<Book, $BooksTable, Chapter>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookMetadataOverridesRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          BookMetadataOverride
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookMetadataOverridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookMetadataOverridesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookTagsRefs)
                        await $_getPrefetchedData<Book, $BooksTable, BookTag>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playbackProgressRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          PlaybackProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._playbackProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (perBookPrefsRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          PerBookPref
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._perBookPrefsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).perBookPrefsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listeningRecordsRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          ListeningRecord
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._listeningRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).listeningRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (audioCacheEntriesRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          AudioCacheEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._audioCacheEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).audioCacheEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, $$BooksTableReferences),
      Book,
      PrefetchHooks Function({
        bool libraryRootId,
        bool sourceId,
        bool volumesRefs,
        bool chaptersRefs,
        bool bookMetadataOverridesRefs,
        bool bookTagsRefs,
        bool playbackProgressRefs,
        bool perBookPrefsRefs,
        bool listeningRecordsRefs,
        bool audioCacheEntriesRefs,
      })
    >;
typedef $$VolumesTableCreateCompanionBuilder = VolumesCompanion Function({
  required String id,
  required String bookId,
  required String title,
  required int volumeIndex,
  required String path,
  Value<String?> coverPath,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$VolumesTableUpdateCompanionBuilder = VolumesCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> title,
  Value<int> volumeIndex,
  Value<String> path,
  Value<String?> coverPath,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$VolumesTableReferences
    extends BaseReferences<_$TomeToneDatabase, $VolumesTable, Volume> {
  $$VolumesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('volumes__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<Chapter>> _chaptersRefsTable(
    _$TomeToneDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'volumes__id__chapters__volume_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.volumeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VolumesTableFilterComposer
    extends Composer<_$TomeToneDatabase, $VolumesTable> {
  $$VolumesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volumeIndex => $composableBuilder(
    column: $table.volumeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VolumesTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $VolumesTable> {
  $$VolumesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volumeIndex => $composableBuilder(
    column: $table.volumeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VolumesTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $VolumesTable> {
  $$VolumesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get volumeIndex => $composableBuilder(
    column: $table.volumeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.volumeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VolumesTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $VolumesTable,
          Volume,
          $$VolumesTableFilterComposer,
          $$VolumesTableOrderingComposer,
          $$VolumesTableAnnotationComposer,
          $$VolumesTableCreateCompanionBuilder,
          $$VolumesTableUpdateCompanionBuilder,
          (Volume, $$VolumesTableReferences),
          Volume,
          PrefetchHooks Function({bool bookId, bool chaptersRefs})
        > {
  $$VolumesTableTableManager(_$TomeToneDatabase db, $VolumesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VolumesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VolumesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VolumesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> volumeIndex = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VolumesCompanion(
                id: id,
                bookId: bookId,
                title: title,
                volumeIndex: volumeIndex,
                path: path,
                coverPath: coverPath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String title,
                required int volumeIndex,
                required String path,
                Value<String?> coverPath = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VolumesCompanion.insert(
                id: id,
                bookId: bookId,
                title: title,
                volumeIndex: volumeIndex,
                path: path,
                coverPath: coverPath,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VolumesTable, Volume>(table),
                  $$VolumesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chaptersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chaptersRefs) db.chapters],
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
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$VolumesTableReferences._bookIdTable(
                          db,
                        ),
                        referencedColumn: $$VolumesTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chaptersRefs)
                    await $_getPrefetchedData<Volume, $VolumesTable, Chapter>(
                      currentTable: table,
                      referencedTable: $$VolumesTableReferences
                          ._chaptersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$VolumesTableReferences(db, table, p0).chaptersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.volumeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VolumesTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $VolumesTable,
      Volume,
      $$VolumesTableFilterComposer,
      $$VolumesTableOrderingComposer,
      $$VolumesTableAnnotationComposer,
      $$VolumesTableCreateCompanionBuilder,
      $$VolumesTableUpdateCompanionBuilder,
      (Volume, $$VolumesTableReferences),
      Volume,
      PrefetchHooks Function({bool bookId, bool chaptersRefs})
    >;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  required String id,
  required String bookId,
  required String volumeId,
  required String libraryRootId,
  required String title,
  required int chapterIndex,
  required String filePath,
  Value<String?> sourceUri,
  Value<int?> durationMs,
  Value<int?> sizeBytes,
  Value<bool> missing,
  Value<int> metadataAttempts,
  Value<bool> retired,
  Value<bool> isVip,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> volumeId,
  Value<String> libraryRootId,
  Value<String> title,
  Value<int> chapterIndex,
  Value<String> filePath,
  Value<String?> sourceUri,
  Value<int?> durationMs,
  Value<int?> sizeBytes,
  Value<bool> missing,
  Value<int> metadataAttempts,
  Value<bool> retired,
  Value<bool> isVip,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ChaptersTableReferences
    extends BaseReferences<_$TomeToneDatabase, $ChaptersTable, Chapter> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('chapters__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VolumesTable _volumeIdTable(_$TomeToneDatabase db) =>
      db.volumes.createAlias('chapters__volume_id__volumes__id');

  $$VolumesTableProcessedTableManager get volumeId {
    final $_column = $_itemColumn<String>('volume_id')!;

    final manager = $$VolumesTableTableManager(
      $_db,
      $_db.volumes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_volumeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LibraryRootsTable _libraryRootIdTable(_$TomeToneDatabase db) => db
      .libraryRoots
      .createAlias('chapters__library_root_id__library_roots__id');

  $$LibraryRootsTableProcessedTableManager get libraryRootId {
    final $_column = $_itemColumn<String>('library_root_id')!;

    final manager = $$LibraryRootsTableTableManager(
      $_db,
      $_db.libraryRoots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_libraryRootIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlaybackProgressTable, List<PlaybackProgressData>>
  _playbackProgressRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackProgress,
        aliasName: 'chapters__id__playback_progress__chapter_id',
      );

  $$PlaybackProgressTableProcessedTableManager get playbackProgressRefs {
    final manager = $$PlaybackProgressTableTableManager(
      $_db,
      $_db.playbackProgress,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ListeningRecordsTable, List<ListeningRecord>>
  _listeningRecordsRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.listeningRecords,
        aliasName: 'chapters__id__listening_records__chapter_id',
      );

  $$ListeningRecordsTableProcessedTableManager get listeningRecordsRefs {
    final manager = $$ListeningRecordsTableTableManager(
      $_db,
      $_db.listeningRecords,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _listeningRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AudioCacheEntriesTable, List<AudioCacheEntry>>
  _audioCacheEntriesRefsTable(_$TomeToneDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.audioCacheEntries,
        aliasName: 'chapters__id__audio_cache_entries__chapter_id',
      );

  $$AudioCacheEntriesTableProcessedTableManager get audioCacheEntriesRefs {
    final manager = $$AudioCacheEntriesTableTableManager(
      $_db,
      $_db.audioCacheEntries,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _audioCacheEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$TomeToneDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get metadataAttempts => $composableBuilder(
    column: $table.metadataAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVip => $composableBuilder(
    column: $table.isVip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VolumesTableFilterComposer get volumeId {
    final $$VolumesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableFilterComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryRootsTableFilterComposer get libraryRootId {
    final $$LibraryRootsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableFilterComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playbackProgressRefs(
    Expression<bool> Function($$PlaybackProgressTableFilterComposer f) f,
  ) {
    final $$PlaybackProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackProgress,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackProgressTableFilterComposer(
            $db: $db,
            $table: $db.playbackProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listeningRecordsRefs(
    Expression<bool> Function($$ListeningRecordsTableFilterComposer f) f,
  ) {
    final $$ListeningRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningRecords,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListeningRecordsTableFilterComposer(
            $db: $db,
            $table: $db.listeningRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> audioCacheEntriesRefs(
    Expression<bool> Function($$AudioCacheEntriesTableFilterComposer f) f,
  ) {
    final $$AudioCacheEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioCacheEntries,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AudioCacheEntriesTableFilterComposer(
            $db: $db,
            $table: $db.audioCacheEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get missing => $composableBuilder(
    column: $table.missing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get metadataAttempts => $composableBuilder(
    column: $table.metadataAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVip => $composableBuilder(
    column: $table.isVip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VolumesTableOrderingComposer get volumeId {
    final $$VolumesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableOrderingComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryRootsTableOrderingComposer get libraryRootId {
    final $$LibraryRootsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableOrderingComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
    column: $table.chapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<bool> get missing =>
      $composableBuilder(column: $table.missing, builder: (column) => column);

  GeneratedColumn<int> get metadataAttempts => $composableBuilder(
    column: $table.metadataAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retired =>
      $composableBuilder(column: $table.retired, builder: (column) => column);

  GeneratedColumn<bool> get isVip =>
      $composableBuilder(column: $table.isVip, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VolumesTableAnnotationComposer get volumeId {
    final $$VolumesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.volumeId,
      referencedTable: $db.volumes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VolumesTableAnnotationComposer(
            $db: $db,
            $table: $db.volumes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LibraryRootsTableAnnotationComposer get libraryRootId {
    final $$LibraryRootsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.libraryRootId,
      referencedTable: $db.libraryRoots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryRootsTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryRoots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playbackProgressRefs<T extends Object>(
    Expression<T> Function($$PlaybackProgressTableAnnotationComposer a) f,
  ) {
    final $$PlaybackProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackProgress,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.playbackProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> listeningRecordsRefs<T extends Object>(
    Expression<T> Function($$ListeningRecordsTableAnnotationComposer a) f,
  ) {
    final $$ListeningRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningRecords,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListeningRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.listeningRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> audioCacheEntriesRefs<T extends Object>(
    Expression<T> Function($$AudioCacheEntriesTableAnnotationComposer a) f,
  ) {
    final $$AudioCacheEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.audioCacheEntries,
          getReferencedColumn: (t) => t.chapterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AudioCacheEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.audioCacheEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $ChaptersTable,
          Chapter,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (Chapter, $$ChaptersTableReferences),
          Chapter,
          PrefetchHooks Function({
            bool bookId,
            bool volumeId,
            bool libraryRootId,
            bool playbackProgressRefs,
            bool listeningRecordsRefs,
            bool audioCacheEntriesRefs,
          })
        > {
  $$ChaptersTableTableManager(_$TomeToneDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> volumeId = const Value.absent(),
                Value<String> libraryRootId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> chapterIndex = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> sourceUri = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<bool> missing = const Value.absent(),
                Value<int> metadataAttempts = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                Value<bool> isVip = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                bookId: bookId,
                volumeId: volumeId,
                libraryRootId: libraryRootId,
                title: title,
                chapterIndex: chapterIndex,
                filePath: filePath,
                sourceUri: sourceUri,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                missing: missing,
                metadataAttempts: metadataAttempts,
                retired: retired,
                isVip: isVip,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                required String volumeId,
                required String libraryRootId,
                required String title,
                required int chapterIndex,
                required String filePath,
                Value<String?> sourceUri = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<bool> missing = const Value.absent(),
                Value<int> metadataAttempts = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                Value<bool> isVip = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChaptersCompanion.insert(
                id: id,
                bookId: bookId,
                volumeId: volumeId,
                libraryRootId: libraryRootId,
                title: title,
                chapterIndex: chapterIndex,
                filePath: filePath,
                sourceUri: sourceUri,
                durationMs: durationMs,
                sizeBytes: sizeBytes,
                missing: missing,
                metadataAttempts: metadataAttempts,
                retired: retired,
                isVip: isVip,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChaptersTable, Chapter>(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookId = false,
                volumeId = false,
                libraryRootId = false,
                playbackProgressRefs = false,
                listeningRecordsRefs = false,
                audioCacheEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playbackProgressRefs) db.playbackProgress,
                    if (listeningRecordsRefs) db.listeningRecords,
                    if (audioCacheEntriesRefs) db.audioCacheEntries,
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
                        if (bookId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.bookId,
                            referencedTable: $$ChaptersTableReferences
                                ._bookIdTable(db),
                            referencedColumn: $$ChaptersTableReferences
                                ._bookIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (volumeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.volumeId,
                            referencedTable: $$ChaptersTableReferences
                                ._volumeIdTable(db),
                            referencedColumn: $$ChaptersTableReferences
                                ._volumeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (libraryRootId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.libraryRootId,
                            referencedTable: $$ChaptersTableReferences
                                ._libraryRootIdTable(db),
                            referencedColumn: $$ChaptersTableReferences
                                ._libraryRootIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playbackProgressRefs)
                        await $_getPrefetchedData<
                          Chapter,
                          $ChaptersTable,
                          PlaybackProgressData
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._playbackProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackProgressRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listeningRecordsRefs)
                        await $_getPrefetchedData<
                          Chapter,
                          $ChaptersTable,
                          ListeningRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._listeningRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).listeningRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (audioCacheEntriesRefs)
                        await $_getPrefetchedData<
                          Chapter,
                          $ChaptersTable,
                          AudioCacheEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._audioCacheEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).audioCacheEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $ChaptersTable,
      Chapter,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (Chapter, $$ChaptersTableReferences),
      Chapter,
      PrefetchHooks Function({
        bool bookId,
        bool volumeId,
        bool libraryRootId,
        bool playbackProgressRefs,
        bool listeningRecordsRefs,
        bool audioCacheEntriesRefs,
      })
    >;
typedef $$BookMetadataOverridesTableCreateCompanionBuilder =
    BookMetadataOverridesCompanion Function({
      required String bookId,
      Value<String?> title,
      Value<String?> author,
      Value<String?> narrator,
      Value<String?> seriesName,
      Value<int?> seriesIndex,
      Value<String?> description,
      Value<DateTime?> manualEditedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BookMetadataOverridesTableUpdateCompanionBuilder =
    BookMetadataOverridesCompanion Function({
      Value<String> bookId,
      Value<String?> title,
      Value<String?> author,
      Value<String?> narrator,
      Value<String?> seriesName,
      Value<int?> seriesIndex,
      Value<String?> description,
      Value<DateTime?> manualEditedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BookMetadataOverridesTableReferences
    extends
        BaseReferences<
          _$TomeToneDatabase,
          $BookMetadataOverridesTable,
          BookMetadataOverride
        > {
  $$BookMetadataOverridesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('book_metadata_overrides__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookMetadataOverridesTableFilterComposer
    extends Composer<_$TomeToneDatabase, $BookMetadataOverridesTable> {
  $$BookMetadataOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get narrator => $composableBuilder(
    column: $table.narrator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get manualEditedAt => $composableBuilder(
    column: $table.manualEditedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookMetadataOverridesTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $BookMetadataOverridesTable> {
  $$BookMetadataOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get narrator => $composableBuilder(
    column: $table.narrator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get manualEditedAt => $composableBuilder(
    column: $table.manualEditedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookMetadataOverridesTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $BookMetadataOverridesTable> {
  $$BookMetadataOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get narrator =>
      $composableBuilder(column: $table.narrator, builder: (column) => column);

  GeneratedColumn<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get manualEditedAt => $composableBuilder(
    column: $table.manualEditedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookMetadataOverridesTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $BookMetadataOverridesTable,
          BookMetadataOverride,
          $$BookMetadataOverridesTableFilterComposer,
          $$BookMetadataOverridesTableOrderingComposer,
          $$BookMetadataOverridesTableAnnotationComposer,
          $$BookMetadataOverridesTableCreateCompanionBuilder,
          $$BookMetadataOverridesTableUpdateCompanionBuilder,
          (BookMetadataOverride, $$BookMetadataOverridesTableReferences),
          BookMetadataOverride,
          PrefetchHooks Function({bool bookId})
        > {
  $$BookMetadataOverridesTableTableManager(
    _$TomeToneDatabase db,
    $BookMetadataOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookMetadataOverridesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BookMetadataOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BookMetadataOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> narrator = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<int?> seriesIndex = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> manualEditedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookMetadataOverridesCompanion(
                bookId: bookId,
                title: title,
                author: author,
                narrator: narrator,
                seriesName: seriesName,
                seriesIndex: seriesIndex,
                description: description,
                manualEditedAt: manualEditedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                Value<String?> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String?> narrator = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<int?> seriesIndex = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> manualEditedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BookMetadataOverridesCompanion.insert(
                bookId: bookId,
                title: title,
                author: author,
                narrator: narrator,
                seriesName: seriesName,
                seriesIndex: seriesIndex,
                description: description,
                manualEditedAt: manualEditedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $BookMetadataOverridesTable,
                    BookMetadataOverride
                  >(table),
                  $$BookMetadataOverridesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
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
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$BookMetadataOverridesTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$BookMetadataOverridesTableReferences
                            ._bookIdTable(db)
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

typedef $$BookMetadataOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $BookMetadataOverridesTable,
      BookMetadataOverride,
      $$BookMetadataOverridesTableFilterComposer,
      $$BookMetadataOverridesTableOrderingComposer,
      $$BookMetadataOverridesTableAnnotationComposer,
      $$BookMetadataOverridesTableCreateCompanionBuilder,
      $$BookMetadataOverridesTableUpdateCompanionBuilder,
      (BookMetadataOverride, $$BookMetadataOverridesTableReferences),
      BookMetadataOverride,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$BookTagsTableCreateCompanionBuilder = BookTagsCompanion Function({
  required String bookId,
  required String tag,
  Value<int> rowid,
});
typedef $$BookTagsTableUpdateCompanionBuilder = BookTagsCompanion Function({
  Value<String> bookId,
  Value<String> tag,
  Value<int> rowid,
});

final class $$BookTagsTableReferences
    extends BaseReferences<_$TomeToneDatabase, $BookTagsTable, BookTag> {
  $$BookTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('book_tags__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookTagsTableFilterComposer
    extends Composer<_$TomeToneDatabase, $BookTagsTable> {
  $$BookTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookTagsTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $BookTagsTable> {
  $$BookTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookTagsTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $BookTagsTable> {
  $$BookTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookTagsTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $BookTagsTable,
          BookTag,
          $$BookTagsTableFilterComposer,
          $$BookTagsTableOrderingComposer,
          $$BookTagsTableAnnotationComposer,
          $$BookTagsTableCreateCompanionBuilder,
          $$BookTagsTableUpdateCompanionBuilder,
          (BookTag, $$BookTagsTableReferences),
          BookTag,
          PrefetchHooks Function({bool bookId})
        > {
  $$BookTagsTableTableManager(_$TomeToneDatabase db, $BookTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> bookId = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => BookTagsCompanion(bookId: bookId, tag: tag, rowid: rowid),
          createCompanionCallback:
              ({
                required String bookId,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => BookTagsCompanion.insert(
                bookId: bookId,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookTagsTable, BookTag>(table),
                  $$BookTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
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
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$BookTagsTableReferences._bookIdTable(
                          db,
                        ),
                        referencedColumn: $$BookTagsTableReferences
                            ._bookIdTable(db)
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

typedef $$BookTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $BookTagsTable,
      BookTag,
      $$BookTagsTableFilterComposer,
      $$BookTagsTableOrderingComposer,
      $$BookTagsTableAnnotationComposer,
      $$BookTagsTableCreateCompanionBuilder,
      $$BookTagsTableUpdateCompanionBuilder,
      (BookTag, $$BookTagsTableReferences),
      BookTag,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$PlaybackProgressTableCreateCompanionBuilder =
    PlaybackProgressCompanion Function({
      required String bookId,
      required String chapterId,
      required int positionMs,
      required DateTime updatedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$PlaybackProgressTableUpdateCompanionBuilder =
    PlaybackProgressCompanion Function({
      Value<String> bookId,
      Value<String> chapterId,
      Value<int> positionMs,
      Value<DateTime> updatedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

final class $$PlaybackProgressTableReferences
    extends
        BaseReferences<
          _$TomeToneDatabase,
          $PlaybackProgressTable,
          PlaybackProgressData
        > {
  $$PlaybackProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('playback_progress__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$TomeToneDatabase db) =>
      db.chapters.createAlias('playback_progress__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<String>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackProgressTableFilterComposer
    extends Composer<_$TomeToneDatabase, $PlaybackProgressTable> {
  $$PlaybackProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackProgressTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $PlaybackProgressTable> {
  $$PlaybackProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackProgressTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $PlaybackProgressTable> {
  $$PlaybackProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackProgressTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $PlaybackProgressTable,
          PlaybackProgressData,
          $$PlaybackProgressTableFilterComposer,
          $$PlaybackProgressTableOrderingComposer,
          $$PlaybackProgressTableAnnotationComposer,
          $$PlaybackProgressTableCreateCompanionBuilder,
          $$PlaybackProgressTableUpdateCompanionBuilder,
          (PlaybackProgressData, $$PlaybackProgressTableReferences),
          PlaybackProgressData,
          PrefetchHooks Function({bool bookId, bool chapterId})
        > {
  $$PlaybackProgressTableTableManager(
    _$TomeToneDatabase db,
    $PlaybackProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressCompanion(
                bookId: bookId,
                chapterId: chapterId,
                positionMs: positionMs,
                updatedAt: updatedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required String chapterId,
                required int positionMs,
                required DateTime updatedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressCompanion.insert(
                bookId: bookId,
                chapterId: chapterId,
                positionMs: positionMs,
                updatedAt: updatedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaybackProgressTable, PlaybackProgressData>(
                    table,
                  ),
                  $$PlaybackProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
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
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$PlaybackProgressTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$PlaybackProgressTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$PlaybackProgressTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$PlaybackProgressTableReferences
                            ._chapterIdTable(db)
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

typedef $$PlaybackProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $PlaybackProgressTable,
      PlaybackProgressData,
      $$PlaybackProgressTableFilterComposer,
      $$PlaybackProgressTableOrderingComposer,
      $$PlaybackProgressTableAnnotationComposer,
      $$PlaybackProgressTableCreateCompanionBuilder,
      $$PlaybackProgressTableUpdateCompanionBuilder,
      (PlaybackProgressData, $$PlaybackProgressTableReferences),
      PlaybackProgressData,
      PrefetchHooks Function({bool bookId, bool chapterId})
    >;
typedef $$PerBookPrefsTableCreateCompanionBuilder =
    PerBookPrefsCompanion Function({
      required String bookId,
      Value<double> speed,
      Value<int> skipIntroSec,
      Value<int> skipOutroSec,
      Value<String?> rewindOverride,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PerBookPrefsTableUpdateCompanionBuilder =
    PerBookPrefsCompanion Function({
      Value<String> bookId,
      Value<double> speed,
      Value<int> skipIntroSec,
      Value<int> skipOutroSec,
      Value<String?> rewindOverride,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PerBookPrefsTableReferences
    extends
        BaseReferences<_$TomeToneDatabase, $PerBookPrefsTable, PerBookPref> {
  $$PerBookPrefsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('per_book_prefs__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PerBookPrefsTableFilterComposer
    extends Composer<_$TomeToneDatabase, $PerBookPrefsTable> {
  $$PerBookPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipIntroSec => $composableBuilder(
    column: $table.skipIntroSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipOutroSec => $composableBuilder(
    column: $table.skipOutroSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rewindOverride => $composableBuilder(
    column: $table.rewindOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PerBookPrefsTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $PerBookPrefsTable> {
  $$PerBookPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipIntroSec => $composableBuilder(
    column: $table.skipIntroSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipOutroSec => $composableBuilder(
    column: $table.skipOutroSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rewindOverride => $composableBuilder(
    column: $table.rewindOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PerBookPrefsTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $PerBookPrefsTable> {
  $$PerBookPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<int> get skipIntroSec => $composableBuilder(
    column: $table.skipIntroSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skipOutroSec => $composableBuilder(
    column: $table.skipOutroSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rewindOverride => $composableBuilder(
    column: $table.rewindOverride,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PerBookPrefsTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $PerBookPrefsTable,
          PerBookPref,
          $$PerBookPrefsTableFilterComposer,
          $$PerBookPrefsTableOrderingComposer,
          $$PerBookPrefsTableAnnotationComposer,
          $$PerBookPrefsTableCreateCompanionBuilder,
          $$PerBookPrefsTableUpdateCompanionBuilder,
          (PerBookPref, $$PerBookPrefsTableReferences),
          PerBookPref,
          PrefetchHooks Function({bool bookId})
        > {
  $$PerBookPrefsTableTableManager(
    _$TomeToneDatabase db,
    $PerBookPrefsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PerBookPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PerBookPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PerBookPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<int> skipIntroSec = const Value.absent(),
                Value<int> skipOutroSec = const Value.absent(),
                Value<String?> rewindOverride = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PerBookPrefsCompanion(
                bookId: bookId,
                speed: speed,
                skipIntroSec: skipIntroSec,
                skipOutroSec: skipOutroSec,
                rewindOverride: rewindOverride,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                Value<double> speed = const Value.absent(),
                Value<int> skipIntroSec = const Value.absent(),
                Value<int> skipOutroSec = const Value.absent(),
                Value<String?> rewindOverride = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PerBookPrefsCompanion.insert(
                bookId: bookId,
                speed: speed,
                skipIntroSec: skipIntroSec,
                skipOutroSec: skipOutroSec,
                rewindOverride: rewindOverride,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PerBookPrefsTable, PerBookPref>(table),
                  $$PerBookPrefsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
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
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$PerBookPrefsTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$PerBookPrefsTableReferences
                            ._bookIdTable(db)
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

typedef $$PerBookPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $PerBookPrefsTable,
      PerBookPref,
      $$PerBookPrefsTableFilterComposer,
      $$PerBookPrefsTableOrderingComposer,
      $$PerBookPrefsTableAnnotationComposer,
      $$PerBookPrefsTableCreateCompanionBuilder,
      $$PerBookPrefsTableUpdateCompanionBuilder,
      (PerBookPref, $$PerBookPrefsTableReferences),
      PerBookPref,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$ListeningRecordsTableCreateCompanionBuilder =
    ListeningRecordsCompanion Function({
      required String id,
      required String bookId,
      Value<String?> chapterId,
      required DateTime startedAt,
      required int durationMs,
      Value<int> rowid,
    });
typedef $$ListeningRecordsTableUpdateCompanionBuilder =
    ListeningRecordsCompanion Function({
      Value<String> id,
      Value<String> bookId,
      Value<String?> chapterId,
      Value<DateTime> startedAt,
      Value<int> durationMs,
      Value<int> rowid,
    });

final class $$ListeningRecordsTableReferences
    extends
        BaseReferences<
          _$TomeToneDatabase,
          $ListeningRecordsTable,
          ListeningRecord
        > {
  $$ListeningRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('listening_records__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$TomeToneDatabase db) =>
      db.chapters.createAlias('listening_records__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager? get chapterId {
    final $_column = $_itemColumn<String>('chapter_id');
    if ($_column == null) return null;
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ListeningRecordsTableFilterComposer
    extends Composer<_$TomeToneDatabase, $ListeningRecordsTable> {
  $$ListeningRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListeningRecordsTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $ListeningRecordsTable> {
  $$ListeningRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListeningRecordsTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $ListeningRecordsTable> {
  $$ListeningRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListeningRecordsTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $ListeningRecordsTable,
          ListeningRecord,
          $$ListeningRecordsTableFilterComposer,
          $$ListeningRecordsTableOrderingComposer,
          $$ListeningRecordsTableAnnotationComposer,
          $$ListeningRecordsTableCreateCompanionBuilder,
          $$ListeningRecordsTableUpdateCompanionBuilder,
          (ListeningRecord, $$ListeningRecordsTableReferences),
          ListeningRecord,
          PrefetchHooks Function({bool bookId, bool chapterId})
        > {
  $$ListeningRecordsTableTableManager(
    _$TomeToneDatabase db,
    $ListeningRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListeningRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListeningRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String?> chapterId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningRecordsCompanion(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                startedAt: startedAt,
                durationMs: durationMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookId,
                Value<String?> chapterId = const Value.absent(),
                required DateTime startedAt,
                required int durationMs,
                Value<int> rowid = const Value.absent(),
              }) => ListeningRecordsCompanion.insert(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                startedAt: startedAt,
                durationMs: durationMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListeningRecordsTable, ListeningRecord>(table),
                  $$ListeningRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
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
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$ListeningRecordsTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$ListeningRecordsTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$ListeningRecordsTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$ListeningRecordsTableReferences
                            ._chapterIdTable(db)
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

typedef $$ListeningRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $ListeningRecordsTable,
      ListeningRecord,
      $$ListeningRecordsTableFilterComposer,
      $$ListeningRecordsTableOrderingComposer,
      $$ListeningRecordsTableAnnotationComposer,
      $$ListeningRecordsTableCreateCompanionBuilder,
      $$ListeningRecordsTableUpdateCompanionBuilder,
      (ListeningRecord, $$ListeningRecordsTableReferences),
      ListeningRecord,
      PrefetchHooks Function({bool bookId, bool chapterId})
    >;
typedef $$StorageAccountsTableCreateCompanionBuilder =
    StorageAccountsCompanion Function({
      required String id,
      required String providerType,
      required String baseUrl,
      required String credentialRef,
      required String refreshMeta,
      Value<bool> isDefault,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StorageAccountsTableUpdateCompanionBuilder =
    StorageAccountsCompanion Function({
      Value<String> id,
      Value<String> providerType,
      Value<String> baseUrl,
      Value<String> credentialRef,
      Value<String> refreshMeta,
      Value<bool> isDefault,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StorageAccountsTableFilterComposer
    extends Composer<_$TomeToneDatabase, $StorageAccountsTable> {
  $$StorageAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshMeta => $composableBuilder(
    column: $table.refreshMeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StorageAccountsTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $StorageAccountsTable> {
  $$StorageAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshMeta => $composableBuilder(
    column: $table.refreshMeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StorageAccountsTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $StorageAccountsTable> {
  $$StorageAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refreshMeta => $composableBuilder(
    column: $table.refreshMeta,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StorageAccountsTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $StorageAccountsTable,
          StorageAccount,
          $$StorageAccountsTableFilterComposer,
          $$StorageAccountsTableOrderingComposer,
          $$StorageAccountsTableAnnotationComposer,
          $$StorageAccountsTableCreateCompanionBuilder,
          $$StorageAccountsTableUpdateCompanionBuilder,
          (
            StorageAccount,
            BaseReferences<
              _$TomeToneDatabase,
              $StorageAccountsTable,
              StorageAccount
            >,
          ),
          StorageAccount,
          PrefetchHooks Function()
        > {
  $$StorageAccountsTableTableManager(
    _$TomeToneDatabase db,
    $StorageAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StorageAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StorageAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StorageAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerType = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> credentialRef = const Value.absent(),
                Value<String> refreshMeta = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageAccountsCompanion(
                id: id,
                providerType: providerType,
                baseUrl: baseUrl,
                credentialRef: credentialRef,
                refreshMeta: refreshMeta,
                isDefault: isDefault,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerType,
                required String baseUrl,
                required String credentialRef,
                required String refreshMeta,
                Value<bool> isDefault = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StorageAccountsCompanion.insert(
                id: id,
                providerType: providerType,
                baseUrl: baseUrl,
                credentialRef: credentialRef,
                refreshMeta: refreshMeta,
                isDefault: isDefault,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StorageAccountsTable, StorageAccount>(table),
                  BaseReferences<
                    _$TomeToneDatabase,
                    $StorageAccountsTable,
                    StorageAccount
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StorageAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $StorageAccountsTable,
      StorageAccount,
      $$StorageAccountsTableFilterComposer,
      $$StorageAccountsTableOrderingComposer,
      $$StorageAccountsTableAnnotationComposer,
      $$StorageAccountsTableCreateCompanionBuilder,
      $$StorageAccountsTableUpdateCompanionBuilder,
      (
        StorageAccount,
        BaseReferences<
          _$TomeToneDatabase,
          $StorageAccountsTable,
          StorageAccount
        >,
      ),
      StorageAccount,
      PrefetchHooks Function()
    >;
typedef $$AudioCacheEntriesTableCreateCompanionBuilder =
    AudioCacheEntriesCompanion Function({
      required String chapterId,
      required String bookId,
      Value<String?> sourceId,
      required String sourceUrlHash,
      required String filePath,
      Value<String?> contentType,
      required int bytes,
      required String status,
      Value<String?> etag,
      required DateTime createdAt,
      required DateTime lastAccessedAt,
      Value<int> rowid,
    });
typedef $$AudioCacheEntriesTableUpdateCompanionBuilder =
    AudioCacheEntriesCompanion Function({
      Value<String> chapterId,
      Value<String> bookId,
      Value<String?> sourceId,
      Value<String> sourceUrlHash,
      Value<String> filePath,
      Value<String?> contentType,
      Value<int> bytes,
      Value<String> status,
      Value<String?> etag,
      Value<DateTime> createdAt,
      Value<DateTime> lastAccessedAt,
      Value<int> rowid,
    });

final class $$AudioCacheEntriesTableReferences
    extends
        BaseReferences<
          _$TomeToneDatabase,
          $AudioCacheEntriesTable,
          AudioCacheEntry
        > {
  $$AudioCacheEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChaptersTable _chapterIdTable(_$TomeToneDatabase db) =>
      db.chapters.createAlias('audio_cache_entries__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<String>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BooksTable _bookIdTable(_$TomeToneDatabase db) =>
      db.books.createAlias('audio_cache_entries__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BookSourcesTable _sourceIdTable(_$TomeToneDatabase db) => db
      .bookSources
      .createAlias('audio_cache_entries__source_id__book_sources__id');

  $$BookSourcesTableProcessedTableManager? get sourceId {
    final $_column = $_itemColumn<String>('source_id');
    if ($_column == null) return null;
    final manager = $$BookSourcesTableTableManager(
      $_db,
      $_db.bookSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AudioCacheEntriesTableFilterComposer
    extends Composer<_$TomeToneDatabase, $AudioCacheEntriesTable> {
  $$AudioCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceUrlHash => $composableBuilder(
    column: $table.sourceUrlHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookSourcesTableFilterComposer get sourceId {
    final $$BookSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableFilterComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioCacheEntriesTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $AudioCacheEntriesTable> {
  $$AudioCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceUrlHash => $composableBuilder(
    column: $table.sourceUrlHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookSourcesTableOrderingComposer get sourceId {
    final $$BookSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioCacheEntriesTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $AudioCacheEntriesTable> {
  $$AudioCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceUrlHash => $composableBuilder(
    column: $table.sourceUrlHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookSourcesTableAnnotationComposer get sourceId {
    final $$BookSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.bookSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AudioCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $AudioCacheEntriesTable,
          AudioCacheEntry,
          $$AudioCacheEntriesTableFilterComposer,
          $$AudioCacheEntriesTableOrderingComposer,
          $$AudioCacheEntriesTableAnnotationComposer,
          $$AudioCacheEntriesTableCreateCompanionBuilder,
          $$AudioCacheEntriesTableUpdateCompanionBuilder,
          (AudioCacheEntry, $$AudioCacheEntriesTableReferences),
          AudioCacheEntry,
          PrefetchHooks Function({bool chapterId, bool bookId, bool sourceId})
        > {
  $$AudioCacheEntriesTableTableManager(
    _$TomeToneDatabase db,
    $AudioCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> chapterId = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String> sourceUrlHash = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> contentType = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioCacheEntriesCompanion(
                chapterId: chapterId,
                bookId: bookId,
                sourceId: sourceId,
                sourceUrlHash: sourceUrlHash,
                filePath: filePath,
                contentType: contentType,
                bytes: bytes,
                status: status,
                etag: etag,
                createdAt: createdAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String chapterId,
                required String bookId,
                Value<String?> sourceId = const Value.absent(),
                required String sourceUrlHash,
                required String filePath,
                Value<String?> contentType = const Value.absent(),
                required int bytes,
                required String status,
                Value<String?> etag = const Value.absent(),
                required DateTime createdAt,
                required DateTime lastAccessedAt,
                Value<int> rowid = const Value.absent(),
              }) => AudioCacheEntriesCompanion.insert(
                chapterId: chapterId,
                bookId: bookId,
                sourceId: sourceId,
                sourceUrlHash: sourceUrlHash,
                filePath: filePath,
                contentType: contentType,
                bytes: bytes,
                status: status,
                etag: etag,
                createdAt: createdAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AudioCacheEntriesTable, AudioCacheEntry>(table),
                  $$AudioCacheEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({chapterId = false, bookId = false, sourceId = false}) {
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
                        if (chapterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.chapterId,
                            referencedTable: $$AudioCacheEntriesTableReferences
                                ._chapterIdTable(db),
                            referencedColumn: $$AudioCacheEntriesTableReferences
                                ._chapterIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (bookId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.bookId,
                            referencedTable: $$AudioCacheEntriesTableReferences
                                ._bookIdTable(db),
                            referencedColumn: $$AudioCacheEntriesTableReferences
                                ._bookIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: $$AudioCacheEntriesTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: $$AudioCacheEntriesTableReferences
                                ._sourceIdTable(db)
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

typedef $$AudioCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $AudioCacheEntriesTable,
      AudioCacheEntry,
      $$AudioCacheEntriesTableFilterComposer,
      $$AudioCacheEntriesTableOrderingComposer,
      $$AudioCacheEntriesTableAnnotationComposer,
      $$AudioCacheEntriesTableCreateCompanionBuilder,
      $$AudioCacheEntriesTableUpdateCompanionBuilder,
      (AudioCacheEntry, $$AudioCacheEntriesTableReferences),
      AudioCacheEntry,
      PrefetchHooks Function({bool chapterId, bool bookId, bool sourceId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$TomeToneDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$TomeToneDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$TomeToneDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$TomeToneDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$TomeToneDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$TomeToneDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<
                    _$TomeToneDatabase,
                    $AppSettingsTable,
                    AppSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$TomeToneDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$TomeToneDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $TomeToneDatabaseManager {
  final _$TomeToneDatabase _db;
  $TomeToneDatabaseManager(this._db);
  $$LibraryRootsTableTableManager get libraryRoots =>
      $$LibraryRootsTableTableManager(_db, _db.libraryRoots);
  $$BookSourcesTableTableManager get bookSources =>
      $$BookSourcesTableTableManager(_db, _db.bookSources);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$VolumesTableTableManager get volumes =>
      $$VolumesTableTableManager(_db, _db.volumes);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$BookMetadataOverridesTableTableManager get bookMetadataOverrides =>
      $$BookMetadataOverridesTableTableManager(_db, _db.bookMetadataOverrides);
  $$BookTagsTableTableManager get bookTags =>
      $$BookTagsTableTableManager(_db, _db.bookTags);
  $$PlaybackProgressTableTableManager get playbackProgress =>
      $$PlaybackProgressTableTableManager(_db, _db.playbackProgress);
  $$PerBookPrefsTableTableManager get perBookPrefs =>
      $$PerBookPrefsTableTableManager(_db, _db.perBookPrefs);
  $$ListeningRecordsTableTableManager get listeningRecords =>
      $$ListeningRecordsTableTableManager(_db, _db.listeningRecords);
  $$StorageAccountsTableTableManager get storageAccounts =>
      $$StorageAccountsTableTableManager(_db, _db.storageAccounts);
  $$AudioCacheEntriesTableTableManager get audioCacheEntries =>
      $$AudioCacheEntriesTableTableManager(_db, _db.audioCacheEntries);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
