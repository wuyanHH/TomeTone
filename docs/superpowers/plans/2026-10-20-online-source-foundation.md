# 在线书源 M1-A：书源基础与导入管理

> **给实现工程师：** 本计划假设你从零接手，按任务顺序执行。每个任务先写失败测试，再实现，再验证，再提交。不要跳过测试权限闸门。
>
> **测试权限：** 在运行任何 `flutter analyze` 或 `flutter test` 之前，必须先取得用户明确许可。每个任务的验证命令都是待执行步骤，不是自动授权。

**目标：** 完成 schema v3、Legado 听书源解析/校验、书源持久化、虚拟书库根、书源导入与管理 UI。完成后用户能导入、编辑、启停、删除书源；发现/搜索/播放/书库混排留给后续计划。

**架构：** 领域层放书源模型、URL 规范化、解析器与查询端口；应用层放 `BookSourceService` 编排；UI 层只调用 service/provider；Drift 行类命名为 `BookSourceRow`，避免与领域模型 `BookSource` 重名。

**技术栈：** Flutter、Dart 3、Riverpod、Drift、`file_picker`（新增）、`dart:io` HttpClient。

**设计文档：** `docs/superpowers/specs/2026-10-20-online-book-sources-design.md`

---

## M1 计划系列

M1 拆成四个可独立交付的计划，每个计划结束时都应能编译、能运行、能演示：

| 计划 | 交付 | 依赖 |
|---|---|---|
| **M1-A（本计划）** | schema v3；书源解析/校验/持久化；书源导入与管理 UI；虚拟在线根 | 无 |
| **M1-B** | 规则引擎（HTTP/JSONPath/模板/JS）、发现/搜索/详情预览、五栏导航 | M1-A |
| **M1-C** | 在线书入库、`on_shelf`、书库混排、加入书架、在线播放 | M1-B |
| **M1-D** | 刷新信息/目录/列表、换源、删除与本地文件护栏、预下载/缓存、验收 | M1-C |

本计划**不**实现发现页、规则求值、播放或刷新。不要在 M1-A 里提前写这些模块的占位实现。

---

## 全局约束

- 只支持 `bookSourceType == 1` 的听书源；`0`（文本源）与 RSS 直接拒绝。
- 网络 URL 只允许 `http` / `https`；`file/content/intent/javascript/data/ftp` 拒绝。
- 真实书源 header / session / Cookie **不得**进入仓库、测试夹具、日志或文档。夹具统一用 `x-listening-session: test-session`。
- 测试不访问真实站点。URL 导入的网络实现只做手动验收，自动测试用 fake loader。
- 书源软删除；删除书源默认保留书目。只有用户勾选「同时删除该源的已存书目」才删除书目。
- 在线书源对应一条虚拟 `library_roots`，`type='online'`；该根不进入本机扫描链路。
- 任何新 UI 必须通过 320dp、大字体、深色模式检查。
- 每个任务一个 commit；commit message 用 `feat(sources): ...` / `feat(ui): ...` / `feat(db): ...`。

---

## 预检：确认测试基线

当前工作树如果只有部分 `test/`，先从主工作树恢复完整测试套件；不要在缺少既有回归测试的情况下开始改 schema。

**验证（取得许可后）：**

```powershell
flutter test
```

如果命令找不到既有测试，停止并向用户确认测试套件位置。不要用「测试文件不存在」当作跳过回归的理由。

---

## Task 1：Schema v3

**Files:**

- Modify: `lib/domain/library/database/tables.dart`
- Modify: `lib/domain/library/database/tometone_database.dart`
- Generated: `lib/domain/library/database/tometone_database.g.dart`（运行 build_runner）
- Create: `test/domain/library/database/schema_v3_test.dart`

**Step 1：写失败测试**

测试至少覆盖：

1. 新库打开后存在 `book_sources`、`audio_cache_entries`、`app_settings` 三张表。
2. `books` 表有 `on_shelf`、`source_id`、`cover_url`、`description`、`kind`、`word_count`、`source_status`、`last_chapter`、`source_updated_at`、`last_refresh_at`、`last_refresh_ok`、`last_refresh_error`。
3. `chapters` 表有 `retired`、`is_vip`。
4. 插入一本旧书（不显式写 `onShelf`）时 `onShelf == true`；新在线书由 service 显式写 `false`。
5. v2 最小库升级到 v3 后，旧书 `onShelf == true`，`sourceId == null`，旧章 `retired == false`、`isVip == false`。

**Step 2：运行测试确认失败**

取得许可后运行：

```powershell
flutter test test/domain/library/database/schema_v3_test.dart
```

**Step 3：实现表与迁移**

在 `tables.dart` 增加：

```dart
@DataClassName('BookSourceRow')
@TableIndex(name: 'book_sources_source_url', columns: {#sourceUrl}, unique: true)
@TableIndex(name: 'book_sources_library_root', columns: {#libraryRootId}, unique: true)
@TableIndex(name: 'book_sources_deleted_at', columns: {#deletedAt})
class BookSources extends Table {
  TextColumn get id => text()();
  TextColumn get libraryRootId => text().references(
    LibraryRoots,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get sourceUrl => text()();
  TextColumn get name => text()();
  TextColumn get groupName => text().nullable()();
  IntColumn get sourceType => integer()();
  TextColumn get rawJson => text()();
  TextColumn get headerJson => text().nullable()();
  TextColumn get exploreUrl => text().nullable()();
  TextColumn get searchUrl => text().nullable()();
  TextColumn get jsLib => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  BoolColumn get enabledExplore => boolean().withDefault(const Constant(true))();
  IntColumn get customOrder => integer().withDefault(const Constant(0))();
  IntColumn get concurrentRate => integer().nullable()();
  DateTimeColumn get lastTestAt => dateTime().nullable()();
  BoolColumn get lastTestOk => boolean().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get consecutiveFailures => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
```

`Books` 增列：

| 列 | 类型 | 默认 / 约束 |
|---|---|---|
| `onShelf` | bool | NOT NULL DEFAULT true |
| `sourceId` | text nullable | FK `book_sources.id` ON DELETE SET NULL |
| `coverUrl` | text nullable | |
| `description` | text nullable | |
| `kind` | text nullable | |
| `wordCount` | text nullable | |
| `sourceStatus` | text nullable | |
| `lastChapter` | text nullable | |
| `sourceUpdatedAt` | datetime nullable | |
| `lastRefreshAt` | datetime nullable | |
| `lastRefreshOk` | bool nullable | |
| `lastRefreshError` | text nullable | |

Drift 写法（列顺序按现有 `Books` 表末尾追加）：

```dart
BoolColumn get onShelf => boolean().withDefault(const Constant(true))();
TextColumn get sourceId => text().nullable().references(
  BookSources,
  #id,
  onDelete: KeyAction.setNull,
)();
TextColumn get coverUrl => text().nullable()();
TextColumn get description => text().nullable()();
TextColumn get kind => text().nullable()();
TextColumn get wordCount => text().nullable()();
TextColumn get sourceStatus => text().nullable()();
TextColumn get lastChapter => text().nullable()();
DateTimeColumn get sourceUpdatedAt => dateTime().nullable()();
DateTimeColumn get lastRefreshAt => dateTime().nullable()();
BoolColumn get lastRefreshOk => boolean().nullable()();
TextColumn get lastRefreshError => text().nullable()();
```

`Chapters` 增列：

| 列 | 类型 | 默认 |
|---|---|---|
| `retired` | bool | NOT NULL DEFAULT false |
| `isVip` | bool | NOT NULL DEFAULT false |

```dart
BoolColumn get retired => boolean().withDefault(const Constant(false))();
BoolColumn get isVip => boolean().withDefault(const Constant(false))();
```

新增：

```dart
@DataClassName('AudioCacheEntryRow')
@TableIndex(name: 'audio_cache_book', columns: {#bookId})
@TableIndex(name: 'audio_cache_accessed', columns: {#lastAccessedAt})
class AudioCacheEntries extends Table {
  TextColumn get chapterId => text().references(
    Chapters,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get bookId => text().references(
    Books,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get sourceId => text().nullable().references(
    BookSources,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get sourceUrlHash => text()();
  TextColumn get filePath => text()();
  TextColumn get contentType => text().nullable()();
  IntColumn get bytes => integer()();
  TextColumn get status => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {chapterId};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
```

`@DriftDatabase` 增加 `BookSources`、`AudioCacheEntries`、`AppSettings`；`schemaVersion` 改为 `3`。表顺序把 `BookSources` 放在 `Books` 之前，避免新建库时 `books.source_id` 的 FK 目标尚未建表：

```dart
tables: <Type>[
  LibraryRoots,
  BookSources,
  Books,
  Volumes,
  Chapters,
  BookMetadataOverrides,
  BookTags,
  PlaybackProgress,
  PerBookPrefs,
  ListeningRecords,
  StorageAccounts,
  AudioCacheEntries,
  AppSettings,
],
```

迁移顺序必须是（**保留现有 `from < 2` 分支，不要覆盖**）：

1. `createTable(bookSources)`（先建，`books.source_id` 才有引用目标）。
2. `addColumn(books, books.onShelf)` 及其余 `books` 列。
3. `addColumn(chapters, chapters.retired)`、`addColumn(chapters, chapters.isVip)`。
4. `createTable(audioCacheEntries)`。
5. `createTable(appSettings)`。

如果 Drift 的 `addColumn` 不能为 `books.sourceId` 生成 SQLite 可接受的 `REFERENCES` 子句，改用：

```dart
await customStatement(
  'ALTER TABLE books ADD COLUMN source_id TEXT REFERENCES book_sources(id) ON DELETE SET NULL',
);
```

迁移测试要么复用仓库既有的 v2 测试夹具，要么用最小 v2 DDL 建 `library_roots` / `books` / `chapters`，设 `PRAGMA user_version = 2`，再打开 `TomeToneDatabase` 触发升级。不要只测新库建表。

**Step 4：生成 Drift 代码并验证**

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter test test/domain/library/database/schema_v3_test.dart
```

**Step 5：提交**

```powershell
git add lib/domain/library/database test/domain/library/database/schema_v3_test.dart
git commit -m "feat(db): add online source schema v3"
```

---

## Task 2：网络 URL 规范化

**Files:**

- Create: `lib/domain/sources/url_normalizer.dart`
- Create: `test/domain/sources/url_normalizer_test.dart`

**Step 1：写失败测试**

测试函数：

```dart
String normalizeNetworkUrl(String raw, {Uri? baseUrl});
```

覆盖：

- 相对地址按 `baseUrl` 解析。
- `HTTPS://Example.COM:443/a/../b#frag` → `https://example.com/b`。
- `http://example.com:80` → `http://example.com/`。
- 保留 path 大小写与 query 参数顺序。
- 空 path 规范为 `/`；末尾 `/` 不被无条件删除。
- 拒绝 `file:`、`content:`、`javascript:`、`data:`、`ftp:`。
- 非法 URL 抛 `FormatException`。
- 含签名 query 的 URL 不被排序、不被剥离。

**Step 2：运行测试确认失败**

```powershell
flutter test test/domain/sources/url_normalizer_test.dart
```

**Step 3：实现**

规则：

1. `trim`；有 `baseUrl` 时 `baseUrl.resolve(raw)`。
2. scheme / host 小写；去默认端口（80/443）；去 fragment。
3. 解析 `.` / `..`、合并重复 `/`；保留路径大小写；空路径补 `/`；不主动增删末尾 `/`。
4. 保留 query 与参数顺序；不剥离 query。
5. 百分号编码统一；解析失败抛 `FormatException`。
6. 只接受 `http` / `https`。

**Step 4：验证**

```powershell
flutter test test/domain/sources/url_normalizer_test.dart
```

**Step 5：提交**

```powershell
git add lib/domain/sources/url_normalizer.dart test/domain/sources/url_normalizer_test.dart
git commit -m "feat(sources): normalize network urls"
```

---

## Task 3：书源模型与 Legado 解析器

**Files:**

- Create: `lib/domain/sources/book_source.dart`
- Create: `lib/domain/sources/source_import.dart`
- Create: `test/domain/sources/source_import_test.dart`
- Create: `test/fixtures/sources/tingyou/source.json`

**Step 1：定义模型**

`lib/domain/sources/book_source.dart`：

```dart
class BookSource {
  const BookSource({
    required this.id,
    required this.libraryRootId,
    required this.name,
    required this.sourceUrl,
    required this.sourceType,
    required this.rawJson,
    required this.header,
    required this.enabled,
    required this.enabledExplore,
    required this.customOrder,
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.exploreUrl,
    this.searchUrl,
    this.jsLib,
    this.concurrentRate,
    this.deletedAt,
    this.lastTestAt,
    this.lastTestOk,
    this.lastError,
    this.consecutiveFailures = 0,
  });

  final String id;
  final String libraryRootId;
  final String name;
  final String sourceUrl;
  final int sourceType;
  final String rawJson;
  final Map<String, String> header;
  final bool enabled;
  final bool enabledExplore;
  final int customOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? groupName;
  final String? exploreUrl;
  final String? searchUrl;
  final String? jsLib;
  final int? concurrentRate;
  final DateTime? deletedAt;
  final DateTime? lastTestAt;
  final bool? lastTestOk;
  final String? lastError;
  final int consecutiveFailures;

  bool get isDeleted => deletedAt != null;
  bool get isAvailable => !isDeleted && enabled;

  /// 用完整草稿覆盖可编辑字段；`null` 会真正清空分组/规则/并发限制。
  /// `id`、`libraryRootId`、`createdAt`、健康字段与 `deletedAt` 保持不变。
  /// 清空 `deletedAt` 仍走查询端口的 `revive`。
  BookSource applyDraft(BookSourceDraft draft, {required DateTime updatedAt});
}

class BookSourceDraft {
  const BookSourceDraft({
    required this.name,
    required this.sourceUrl,
    required this.sourceType,
    required this.rawJson,
    required this.header,
    this.groupName,
    this.exploreUrl,
    this.searchUrl,
    this.jsLib,
    this.enabled = true,
    this.enabledExplore = true,
    this.customOrder = 0,
    this.concurrentRate,
  });

  final String name;
  final String sourceUrl;
  final int sourceType;
  final String rawJson;
  final Map<String, String> header;
  final String? groupName;
  final String? exploreUrl;
  final String? searchUrl;
  final String? jsLib;
  final bool enabled;
  final bool enabledExplore;
  final int customOrder;
  final int? concurrentRate;
}
```

**Step 2：定义解析结果与解析器**

`lib/domain/sources/source_import.dart`：

```dart
enum SourceImportErrorCode {
  invalidJson,
  emptyBatch,
  notObject,
  missingName,
  missingUrl,
  invalidUrl,
  unsupportedType,
  invalidHeader,
  missingRule,
  malformedRule,
  noDiscoveryOrSearch,
}

class SourceImportIssue {
  const SourceImportIssue({
    required this.index,
    required this.message,
    this.code,
  });

  final int index;
  final String message;
  final SourceImportErrorCode? code;
}

class SourceImportCandidate {
  const SourceImportCandidate({required this.index, required this.draft});

  final int index;
  final BookSourceDraft draft;
}

class SourceImportParseResult {
  const SourceImportParseResult({
    required this.candidates,
    required this.issues,
  });

  final List<SourceImportCandidate> candidates;
  final List<SourceImportIssue> issues;

  bool get hasCandidates => candidates.isNotEmpty;
  bool get hasIssues => issues.isNotEmpty;
}

class SourceImportParser {
  const SourceImportParser();

  SourceImportParseResult parse(String text);
}
```

**Step 3：校验规则**

`parse` 接受 JSON 对象或数组：

- 对象 → 一个 candidate / issue。
- 数组 → 逐项解析；坏项进 `issues`，好项进 `candidates`。
- 空数组 → `emptyBatch`。
- 非对象项 → `notObject`。
- `bookSourceName` 非空字符串，否则 `missingName`。
- `bookSourceUrl` 非空字符串，且 `normalizeNetworkUrl` 成功，否则 `missingUrl` / `invalidUrl`。
- `bookSourceType` 为 `1` 或数字字符串 `"1"`；`0` / 其他 → `unsupportedType`。
- 至少有一个非空 `searchUrl` 或 `exploreUrl`，否则 `noDiscoveryOrSearch`。
- `header` 可为 JSON 对象或 JSON 字符串；空字符串/空白按空 map；解析后必须是对象；值统一转字符串。失败 → `invalidHeader`。
- `ruleBookInfo` 必须是对象；缺失 → `missingRule`。
- `ruleToc` 必须是对象，且 `chapterList`、`chapterName`、`chapterUrl` 都是非空字符串，否则 `malformedRule`。
- `ruleContent` 必须是对象，且 `content` 是非空字符串，否则 `malformedRule`。
- 有 `searchUrl` 时，`ruleSearch` 必须是对象，且 `bookList`、`name`、`bookUrl` 非空；否则 `malformedRule`。
- 有 `exploreUrl` 时，`ruleExplore` 必须是对象，且 `bookList`、`name`、`bookUrl` 非空；否则 `malformedRule`。
- `bookSourceGroup` → `groupName`；`jsLib` → `jsLib`；`customOrder` → int 或 0；`concurrentRate` → int 或 null。
- `header` 默认空 map；`enabled` / `enabledExplore` 默认 true。
- `rawJson = jsonEncode(item)`；未知字段必须保留在 `rawJson` 中。
- `sourceUrl` 写入规范化后的值，不是原始字符串。

**Step 4：创建脱敏夹具**

`test/fixtures/sources/tingyou/source.json` 至少包含：

```json
{
  "bookSourceName": "听友听书",
  "bookSourceGroup": "听书",
  "bookSourceType": 1,
  "bookSourceUrl": "https://www.tingyou.fm",
  "header": "{\"User-Agent\":\"TomeTone-Test\",\"Referer\":\"https://www.tingyou.fm/\",\"Origin\":\"https://www.tingyou.fm\",\"x-listening-session\":\"test-session\"}",
  "exploreUrl": "热门::https://www.tingyou.fm/listening-api/rank?section=hot&page={{page}}",
  "ruleExplore": {
    "bookList": "$.items[*]",
    "name": "$.title",
    "bookUrl": "$.url"
  },
  "searchUrl": "https://www.tingyou.fm/listening-api/search",
  "ruleSearch": {
    "bookList": "$.items[*]",
    "name": "$.title",
    "bookUrl": "$.url"
  },
  "ruleBookInfo": {
    "name": "$.title",
    "tocUrl": "https://www.tingyou.fm/listening-api/chapters/{{$.id}}"
  },
  "ruleToc": {
    "chapterList": "$.chapters[*]",
    "chapterName": "$.title",
    "chapterUrl": "$.url"
  },
  "ruleContent": {
    "content": "$.play_url"
  }
}
```

这不是逐字生产源；只覆盖解析器需要的字段。真实源由用户运行时导入。

**Step 5：写测试**

`test/domain/sources/source_import_test.dart` 覆盖：

- 单对象合法 → 1 candidate、0 issue。
- 数组含 1 好 1 坏 → 1 candidate、1 issue，索引正确。
- `header` 为字符串对象、直接对象两种形态都能解析。
- `bookSourceType: 0` → `unsupportedType`。
- 缺 `searchUrl` 且缺 `exploreUrl` → `noDiscoveryOrSearch`。
- `ruleToc` 缺 `chapterUrl` → `malformedRule`。
- 非法 URL → `invalidUrl`。
- 未知字段保留在 `rawJson`。
- `sourceUrl` 已规范化（大小写 / 默认端口 / fragment）。
- 空数组 → `emptyBatch`。

**Step 6：验证并提交**

```powershell
flutter test test/domain/sources/source_import_test.dart
git add lib/domain/sources test/domain/sources test/fixtures/sources
git commit -m "feat(sources): parse legado audio sources"
```

---

## Task 4：书源查询与持久化服务

**Files:**

- Create: `lib/domain/sources/book_source_queries.dart`
- Create: `lib/app/sources/book_source_service.dart`
- Create: `lib/app/providers/source_providers.dart`
- Create: `test/app/sources/book_source_service_test.dart`

**Step 1：查询端口**

`lib/domain/sources/book_source_queries.dart`：

```dart
abstract interface class BookSourceQueries {
  Future<List<BookSource>> listSources({bool includeDeleted = false});
  Future<BookSource?> sourceById(String id);
  Future<BookSource?> sourceByUrl(String sourceUrl);
  Future<int> countBooks(String sourceId);
  Future<void> insertSource(BookSource source);
  Future<void> updateSource(BookSource source);
  Future<void> setEnabled(String sourceId, bool enabled, {DateTime? updatedAt});
  Future<void> revive(String sourceId, {DateTime? updatedAt});
  Future<void> softDelete(
    String sourceId, {
    required bool deleteBooks,
    DateTime? deletedAt,
  });
}
```

同文件实现 `DriftBookSourceQueries`：

- `sourceByUrl` 先 `normalizeNetworkUrl`；查 `sourceUrl.equals(...)`。
- `listSources` 默认 `deletedAt.isNull()`；按 `customOrder`、`name` 排序。
- `countBooks` 查 `books.sourceId`。
- `revive` 清 `deletedAt` 并写 `updatedAt`；不重建根、不重新插入源。
- `softDelete` 在事务中：若 `deleteBooks == true`，先删除该源全部 `books`（依赖 FK 级联删章/进度/标签/偏好/缓存记录），再更新 `deletedAt`；否则只更新 `deletedAt`。
- `headerJson` ↔ `Map<String,String>` 的编解码集中在私有函数，不要散落到 UI。

**Step 2：应用服务**

`lib/app/sources/book_source_service.dart`：

```dart
enum SourceImportStatus { imported, updated, skipped, invalid }

class SourceImportOutcome {
  const SourceImportOutcome({
    required this.status,
    this.sourceId,
    this.name,
    this.message,
  });

  final SourceImportStatus status;
  final String? sourceId;
  final String? name;
  final String? message;
}

class BookSourceListItem {
  const BookSourceListItem({required this.source, required this.bookCount});

  final BookSource source;
  final int bookCount;
}

class BookSourceService {
  BookSourceService({
    required TomeToneDatabase database,
    required BookSourceQueries queries,
    required IdGenerator idGenerator,
    DateTime Function()? clock,
  });

  Future<SourceImportParseResult> parse(String text);
  Future<List<SourceImportOutcome>> importText(
    String text, {
    bool overwrite = false,
  });
  Future<SourceImportOutcome> importCandidate(
    SourceImportCandidate candidate, {
    bool overwrite = false,
  });
  Future<List<BookSourceListItem>> listSources({bool includeDeleted = false});
  Future<BookSource?> getSource(String id);
  Future<void> setEnabled(String id, bool enabled);
  Future<void> updateFromDraft(String id, BookSourceDraft draft);
  Future<int> countBooks(String sourceId);
  Future<void> deleteSource(String id, {bool deleteBooks = false});
}
```

行为：

- 所有写操作统一把 `updatedAt` 设为 `now`；`createdAt` 不变。
- `importCandidate` 用 `draft.sourceUrl` 查重。
- 新源：事务内创建虚拟根 + `book_sources` 行。
  - 根：`id = idGenerator.next()`，`type = 'online'`，`uri = draft.sourceUrl`，`displayName = draft.name`，`lastScanAt = null`；其余必填时间字段照 `LibraryRootService` 的本地根写法。
  - 源：`id = idGenerator.next()`，`libraryRootId = 根 id`，`createdAt = updatedAt = now`。
- 已存在且未删除：
  - `overwrite == false` → `skipped`，不改任何字段。
  - `overwrite == true` → 更新名称/分组/header/URL 规则/启用状态，保留 `id`、`libraryRootId`、`createdAt`；同步根 `displayName`；状态 `updated`。
- 已存在且已软删除：无论 `overwrite` 与否都复活。先 `updateSource` 写入新字段，再调 `revive` 清 `deletedAt`；保留 `id` / 根；状态 `updated`。不要用 `copyWith(deletedAt: null)`。
- `updateFromDraft`：源 URL 是身份，必须与现有 `sourceUrl` 相同；不同则抛 `ArgumentError`。用 `applyDraft` 覆盖名称/分组/header/规则/启用状态（`null` 真正清空），同步根 `displayName`。
- `deleteSource`：调用 `softDelete`；默认保留书目。`deleteBooks == true` 时删除书目记录；M1-A 不清理音频文件（缓存尚未启用，M1-D 补文件清理）。
- `listSources` 返回 `BookSourceListItem`，包含书目数。
- `importText` 对每个 issue 生成 `invalid` outcome，顺序与输入一致。

**Step 3：Provider**

`lib/app/providers/source_providers.dart`：

```dart
final Provider<BookSourceQueries> bookSourceQueriesProvider = Provider((ref) {
  return DriftBookSourceQueries(ref.watch(databaseProvider));
});

final Provider<BookSourceService> bookSourceServiceProvider = Provider((ref) {
  return BookSourceService(
    database: ref.watch(databaseProvider),
    queries: ref.watch(bookSourceQueriesProvider),
    idGenerator: UlidIdGenerator(),
  );
});
```

**Step 4：测试**

`test/app/sources/book_source_service_test.dart` 用 `NativeDatabase.memory()` + 固定随机/时钟的 `UlidIdGenerator`：

- 导入新源 → `book_sources` 一行、`library_roots` 一行且 `type='online'`、`libraryRootId` 正确。
- 同 URL 再导入、`overwrite=false` → `skipped`，源数量不增。
- 同 URL、`overwrite=true` → `updated`，`id` / `libraryRootId` / `createdAt` 不变，名称更新。
- 软删除后重新导入 → 同一 `id` 复活，`deletedAt == null`。
- `deleteSource(deleteBooks: false)` → 源软删除，书还在。
- `deleteSource(deleteBooks: true)` → 源软删除，书、章、进度被删除。
- `setEnabled` 更新 `enabled`。
- `countBooks` 包含未上架书。
- `updateFromDraft` 改 URL → 抛 `ArgumentError`。
- 虚拟根不出现在本机根列表（需要配合 Task 6 的 `libraryRoots` 过滤；如果本任务先写，测试可断言 `type='online'`，过滤测试放 Task 6）。

**Step 5：验证并提交**

```powershell
flutter test test/app/sources/book_source_service_test.dart
git add lib/domain/sources/book_source_queries.dart lib/app/sources lib/app/providers/source_providers.dart test/app/sources
git commit -m "feat(sources): persist and manage sources"
```

---

## Task 5：URL / 文件导入加载器

**Files:**

- Create: `lib/contracts/sources/source_import_loader.dart`
- Create: `lib/app/sources/io_source_import_loader.dart`
- Modify: `pubspec.yaml`（`file_picker`）
- Modify: `lib/app/providers/source_providers.dart`
- Create: `test/app/sources/source_import_loader_test.dart`（只测 fake 契约与错误分支，不访问网络）

**Step 1：契约**

```dart
class SourceImportFile {
  const SourceImportFile({required this.name, required this.content});

  final String name;
  final String content;
}

abstract interface class SourceImportLoader {
  Future<String> loadFromUrl(String url);
  Future<SourceImportFile?> pickJsonFile();
}
```

**Step 2：实现**

`IoSourceImportLoader`：

- `loadFromUrl`：
  - 只接受 `http` / `https`，否则抛 `ArgumentError`。
  - `HttpClient` 超时 15s，最多 5 次重定向。
  - 非 200 抛可读异常（包含状态码，不包含 header）。
  - 响应上限 5 MB；超过即中止。
  - 按 UTF-8 解码，去掉 BOM；解码失败给出「不是 UTF-8 JSON」。
- `pickJsonFile`：
  - `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true)`。
  - 优先用 `bytes`；没有则读 `path`（桌面/移动端）。
  - 上限 5 MB；返回文件名与内容。
  - 用户取消返回 `null`。

在 `source_providers.dart` 增加：

```dart
final Provider<SourceImportLoader> sourceImportLoaderProvider = Provider((ref) {
  return IoSourceImportLoader();
});
```

测试通过 override 注入 fake loader；不要让 widget test 真正打开文件选择器或访问网络。

**Step 3：添加依赖**

```powershell
flutter pub add file_picker
```

使用 `pub add` 取当前兼容版本，不要手写猜测的版本号。提交 `pubspec.yaml` 与 `pubspec.lock`。

**Step 4：提交**

```powershell
git add pubspec.yaml pubspec.lock lib/contracts/sources lib/app/sources/io_source_import_loader.dart lib/app/providers/source_providers.dart
git commit -m "feat(sources): load source json from url or file"
```

---

## Task 6：书源管理页与导入弹层

**Files:**

- Create: `lib/ui/pages/sources/source_management_page.dart`
- Create: `lib/ui/pages/sources/source_import_sheet.dart`
- Create: `lib/ui/pages/sources/source_edit_page.dart`
- Modify: `lib/ui/pages/library/library_page.dart`（右上角入口）
- Modify: `lib/domain/library/queries/library_queries.dart`（`libraryRoots()` 过滤 `type != 'online'`）
- Create: `test/ui/pages/sources/source_management_page_test.dart`
- Create: `test/ui/pages/sources/source_import_sheet_test.dart`
- Create: `test/ui/pages/sources/source_edit_page_test.dart`
- Create: `test/ui/pages/library/library_page_source_entry_test.dart`

**Step 1：过滤在线根**

`DriftLibraryQueries.libraryRoots()` 增加 `type != 'online'` 条件。在线根只通过 `book_sources` 管理，不进入本机根列表、扫描、重扫、存储 provider 链路。

先写测试：插入一条 `type='online'` 根后，`libraryRoots()` 不返回它。

**Step 2：管理页**

`SourceManagementPage`：

- `Scaffold` AppBar：标题 `书源`；`+` 打开导入弹层。
- `FutureBuilder<List<BookSourceListItem>>`；加载中骨架/进度；错误可重试；空态「还没有书源」+ `导入书源`。
- 每个卡片显示：
  - 名称、分组（空显示「未分组」）；
  - `书 N`、启用开关；
  - 健康：`未测试` / `上次测试成功` / `连续失败 N 次`（M1-A 还没有测试动作，默认「未测试」）；
  - `⋮`：编辑、删除。
- 开关调用 `setEnabled`，成功后重新查询；失败 SnackBar，不做乐观更新。
- 删除弹层：
  - 先 `countBooks`；
  - 复选框 `同时删除该源的已存书目`，默认不勾；书数为 0 时隐藏；
  - 勾选后确认文案包含书数；
  - 确认调用 `deleteSource`，刷新列表。

**Step 3：导入弹层**

`SourceImportSheet`：

- `DefaultTabController(length: 3)`：`URL` / `文件` / `粘贴`。
- URL：输入框 + `读取`；调用 `sourceImportLoader.loadFromUrl`；`http(s)` 校验在 loader 层，UI 只展示错误。
- 文件：`选择 JSON 文件`；显示文件名；用户取消不报错。
- 粘贴：多行输入。
- 公共 `覆盖同 URL 书源` 开关，默认关闭。
- 导入按钮：读取到的文本交给 `BookSourceService.importText`；结果列表逐条显示：
  - `已导入` / `已更新` / `已跳过（已存在）` / `失败：<message>`。
- 成功至少一条时返回 `true`，管理页刷新；全部失败返回 `false`。
- 导入中禁用按钮并显示进度；不要整页转圈。
- 错误文案不显示 URL query、header、Cookie。

**Step 4：编辑页**

`SourceEditPage`：

- 名称、分组、启用、发现页启用、原始 JSON（多行）。
- 保存时：
  - `SourceImportParser.parse(rawJson)` 必须恰好 1 个 candidate；否则显示错误；
  - candidate 的 `sourceUrl` 必须等于当前源 URL；不同则提示「书源 URL 是身份，不能在这里修改」；
  - 表单里的名称/分组/启用/发现页启用**优先于** raw JSON 里的同名字段；用表单值覆盖 candidate.draft 的这些字段；
  - 调 `updateFromDraft`。
- 不展示/不记录 header 值；header 只保留在原始 JSON 中。

**Step 5：书库入口**

`LibraryPage` 的 `AppBar.actions` 增加：

```dart
IconButton(
  tooltip: '书源',
  icon: const Icon(Icons.rss_feed),
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SourceManagementPage()),
  ),
)
```

放在现有 `+` 之前。测试点击后能看到 `书源` 页面标题。

**Step 6：测试**

- 管理页：空态；导入后出现卡片；开关调用后持久化；删除默认保留书目；勾选删书后书目消失。
- 导入弹层：粘贴合法 JSON → 成功；非法 JSON → 失败文案；重复源 → `已跳过`；`覆盖` 开启 → `已更新`。
- 编辑页：名称修改保存；URL 修改被拒绝；非法 JSON 不保存。
- 书库入口：点击图标打开管理页。
- 320dp / 大字体 / 深色：管理页、导入弹层、编辑页不溢出。
- 所有测试用 fake loader + 内存数据库，不访问网络、不弹系统文件选择器。

**Step 7：验证并提交**

```powershell
flutter test test/ui/pages/sources test/ui/pages/library/library_page_source_entry_test.dart
git add lib/ui/pages/sources lib/ui/pages/library/library_page.dart lib/domain/library/queries/library_queries.dart test/ui/pages
git commit -m "feat(ui): manage online sources"
```

---

## Task 7：最终验证与文档

**Files:**

- Modify: `docs/superpowers/specs/2026-10-20-online-book-sources-design.md`（仅在实现暴露与设计不一致时）
- Optionally: `CHANGELOG.md`

**Step 1：格式化**

```powershell
dart format lib test
```

**Step 2：分析**

取得许可后：

```powershell
flutter analyze
```

**Step 3：测试**

```powershell
flutter test
```

**Step 4：手工冒烟**

在 Android 真机/模拟器：

1. 打开书库 → 点右上角书源。
2. 粘贴夹具 JSON → 导入成功。
3. 再导入同 URL → 默认跳过；开启覆盖 → 更新。
4. 关闭/开启书源。
5. 删除书源：默认保留书目；有书时勾选删书并确认。
6. 确认书库根列表没有 `online` 根。

**Step 5：提交**

```powershell
git add -A
git commit -m "chore(sources): verify source foundation"
```

---

## 完成标准

M1-A 完成时：

- `flutter analyze` 无问题。
- 新增测试与既有测试全部通过（取得许可后）。
- 用户能通过 URL / 文件 / 粘贴导入书源。
- 同 URL 重复导入可跳过或覆盖；软删除后可复活。
- 书源可启停、编辑、删除；删除默认保留书目，勾选才删书。
- 每个在线源有且只有一条 `type='online'` 虚拟根，且不出现在本机根列表。
- 所有真实 header / session 只存在本地书源 JSON 中，不进入仓库、日志、文档或夹具。

## 风险与实现备注

- **Drift `addColumn` + FK**：如果 SQLite 拒绝带 `REFERENCES` 的 `ADD COLUMN`，按 Task 1 的 `customStatement` 方案；必须有 v2→v3 测试。
- **`file_picker` 平台配置**：如果 Android/iOS 首次构建失败，先检查插件要求的最低 SDK/权限；不要为了绕开插件把文件导入删掉。
- **测试基线缺失**：当前工作树如果只有部分 `test/`，先恢复完整测试套件；M1-A 不能在没有回归测试的情况下改 schema。
- **软删除唯一键**：`book_sources.source_url` 唯一索引包含软删除行，这是故意的；重新导入同 URL 必须复活同一行，不能插入第二条。
- **根的唯一性**：`book_sources.library_root_id` 唯一；一个源一条根，根不跨源复用。

## 自查

- **Spec 覆盖（M1-A 范围）**：schema v3、URL 规范化、Legado 解析/校验、书源 CRUD、软删除/复活、虚拟根、URL/文件/粘贴导入、管理 UI、删除书目选项。
- **未覆盖（明确留给后续）**：规则求值、发现/搜索、详情、播放、书库混排、刷新、换源、预下载、缓存文件清理。
- **占位符检查**：本计划没有 TBD/TODO 任务；未实现的能力在「未覆盖」中列明，不在代码里留空壳。
- **类型一致性**：领域模型 `BookSource`；Drift 行 `BookSourceRow`；查询端口 `BookSourceQueries`；应用服务 `BookSourceService`；导入结果 `SourceImportOutcome`；根类型 `'online'`。
- **测试权限**：所有 `flutter analyze` / `flutter test` 命令都受用户许可闸门约束。
