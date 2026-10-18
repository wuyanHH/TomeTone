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

  /// `local` / `saf` / `webdav` / `smb`。
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
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  );
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
          other.updatedAt == this.updatedAt);
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
    DateTime? updatedAt,
  }) => BookMetadataOverride(
    bookId: bookId ?? this.bookId,
    title: title.present ? title.value : this.title,
    author: author.present ? author.value : this.author,
    narrator: narrator.present ? narrator.value : this.narrator,
    seriesName: seriesName.present ? seriesName.value : this.seriesName,
    seriesIndex: seriesIndex.present ? seriesIndex.value : this.seriesIndex,
    description: description.present ? description.value : this.description,
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
          ..write('updatedAt: $updatedAt, ')
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
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    chapterId,
    positionMs,
    updatedAt,
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
  const PlaybackProgressData({
    required this.bookId,
    required this.chapterId,
    required this.positionMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['position_ms'] = Variable<int>(positionMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaybackProgressCompanion toCompanion(bool nullToAbsent) {
    return PlaybackProgressCompanion(
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      positionMs: Value(positionMs),
      updatedAt: Value(updatedAt),
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
    };
  }

  PlaybackProgressData copyWith({
    String? bookId,
    String? chapterId,
    int? positionMs,
    DateTime? updatedAt,
  }) => PlaybackProgressData(
    bookId: bookId ?? this.bookId,
    chapterId: chapterId ?? this.chapterId,
    positionMs: positionMs ?? this.positionMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaybackProgressData copyWithCompanion(PlaybackProgressCompanion data) {
    return PlaybackProgressData(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackProgressData(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, chapterId, positionMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackProgressData &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.positionMs == this.positionMs &&
          other.updatedAt == this.updatedAt);
}

class PlaybackProgressCompanion extends UpdateCompanion<PlaybackProgressData> {
  final Value<String> bookId;
  final Value<String> chapterId;
  final Value<int> positionMs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaybackProgressCompanion({
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackProgressCompanion.insert({
    required String bookId,
    required String chapterId,
    required int positionMs,
    required DateTime updatedAt,
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (positionMs != null) 'position_ms': positionMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackProgressCompanion copyWith({
    Value<String>? bookId,
    Value<String>? chapterId,
    Value<int>? positionMs,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaybackProgressCompanion(
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      positionMs: positionMs ?? this.positionMs,
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
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
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
    return (StringBuffer('PlaybackProgressCompanion(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('positionMs: $positionMs, ')
          ..write('updatedAt: $updatedAt, ')
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

abstract class _$TomeToneDatabase extends GeneratedDatabase {
  _$TomeToneDatabase(QueryExecutor e) : super(e);
  $TomeToneDatabaseManager get managers => $TomeToneDatabaseManager(this);
  late final $LibraryRootsTable libraryRoots = $LibraryRootsTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $VolumesTable volumes = $VolumesTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $BookMetadataOverridesTable bookMetadataOverrides =
      $BookMetadataOverridesTable(this);
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
  late final Index libraryRootsType = Index(
    'library_roots_type',
    'CREATE INDEX library_roots_type ON library_roots (type)',
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    libraryRoots,
    books,
    volumes,
    chapters,
    bookMetadataOverrides,
    playbackProgress,
    perBookPrefs,
    listeningRecords,
    storageAccounts,
    libraryRootsType,
    booksRootPathUnique,
    booksSeries,
    volumesBookPathUnique,
    chaptersBindingUnique,
    chaptersBookIndex,
    chaptersVolumeIndex,
    playbackProgressUpdated,
    listeningRecordsStarted,
    listeningRecordsBook,
    storageAccountsDefault,
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
          PrefetchHooks Function({bool booksRefs, bool chaptersRefs})
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
          prefetchHooksCallback: ({booksRefs = false, chaptersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (booksRefs) db.books,
                if (chaptersRefs) db.chapters,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
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
      PrefetchHooks Function({bool booksRefs, bool chaptersRefs})
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
            bool volumesRefs,
            bool chaptersRefs,
            bool bookMetadataOverridesRefs,
            bool playbackProgressRefs,
            bool perBookPrefsRefs,
            bool listeningRecordsRefs,
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
                volumesRefs = false,
                chaptersRefs = false,
                bookMetadataOverridesRefs = false,
                playbackProgressRefs = false,
                perBookPrefsRefs = false,
                listeningRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (volumesRefs) db.volumes,
                    if (chaptersRefs) db.chapters,
                    if (bookMetadataOverridesRefs) db.bookMetadataOverrides,
                    if (playbackProgressRefs) db.playbackProgress,
                    if (perBookPrefsRefs) db.perBookPrefs,
                    if (listeningRecordsRefs) db.listeningRecords,
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
        bool volumesRefs,
        bool chaptersRefs,
        bool bookMetadataOverridesRefs,
        bool playbackProgressRefs,
        bool perBookPrefsRefs,
        bool listeningRecordsRefs,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playbackProgressRefs) db.playbackProgress,
                    if (listeningRecordsRefs) db.listeningRecords,
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
typedef $$PlaybackProgressTableCreateCompanionBuilder =
    PlaybackProgressCompanion Function({
      required String bookId,
      required String chapterId,
      required int positionMs,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlaybackProgressTableUpdateCompanionBuilder =
    PlaybackProgressCompanion Function({
      Value<String> bookId,
      Value<String> chapterId,
      Value<int> positionMs,
      Value<DateTime> updatedAt,
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
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressCompanion(
                bookId: bookId,
                chapterId: chapterId,
                positionMs: positionMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required String chapterId,
                required int positionMs,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackProgressCompanion.insert(
                bookId: bookId,
                chapterId: chapterId,
                positionMs: positionMs,
                updatedAt: updatedAt,
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

class $TomeToneDatabaseManager {
  final _$TomeToneDatabase _db;
  $TomeToneDatabaseManager(this._db);
  $$LibraryRootsTableTableManager get libraryRoots =>
      $$LibraryRootsTableTableManager(_db, _db.libraryRoots);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$VolumesTableTableManager get volumes =>
      $$VolumesTableTableManager(_db, _db.volumes);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$BookMetadataOverridesTableTableManager get bookMetadataOverrides =>
      $$BookMetadataOverridesTableTableManager(_db, _db.bookMetadataOverrides);
  $$PlaybackProgressTableTableManager get playbackProgress =>
      $$PlaybackProgressTableTableManager(_db, _db.playbackProgress);
  $$PerBookPrefsTableTableManager get perBookPrefs =>
      $$PerBookPrefsTableTableManager(_db, _db.perBookPrefs);
  $$ListeningRecordsTableTableManager get listeningRecords =>
      $$ListeningRecordsTableTableManager(_db, _db.listeningRecords);
  $$StorageAccountsTableTableManager get storageAccounts =>
      $$StorageAccountsTableTableManager(_db, _db.storageAccounts);
}
