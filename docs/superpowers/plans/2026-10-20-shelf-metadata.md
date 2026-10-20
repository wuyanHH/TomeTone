# 书架与元数据重做 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把书架重排为「封面 + 书名 + 作者/演播 + 简介 + 进度」的双布局，补齐分类/简介/详情/元数据编辑，并把元数据双写到 SQLite 覆盖层与书根 `tometone.meta.json`。

**Architecture:** 复用已有 `book_metadata_overrides` 表作为显示覆盖层，新增 `book_tags` 与 `playback_progress.finished_at`（schema v2）。书架查询一次性取摘要与标签，筛选在内存完成。新增只读 sidecar 文件端口：本地根可读写，SAF 根只读；应用层 `BookMetadataService` 负责「先写库、再尽力写书根」。详情页新增，点章通过 `openBook(startChapterId:)` 起播。

**Tech Stack:** Flutter 3 / Dart 3.13 / Drift / Riverpod / just_audio；不新增依赖。

**Spec:** `docs/superpowers/specs/2026-10-20-ui-refresh-shelf-metadata-design.md`

**设计基准:** `docs/design-preview/ui-refresh/index.html` · 方向 A「宣纸旧卷」

## Global Constraints

- 只做书架与元数据；播放台 UI、歌词/STT、书源不在本轮。
- 数据库迁移必须增量、非破坏；`schemaVersion` 1 → 2，禁止重建库。
- 绝不移动 / 重命名 / 删除用户音频或封面；sidecar 只新增 / 覆盖 `tometone.meta.json`。
- SAF 根本轮只读：不写任何文件，写请求返回 `unsupported`。
- 元数据合并优先级：手动编辑 > 书根 sidecar > 在线书源（Phase 3）> 目录/文件名推断。
- 重新导入只覆盖 JSON 中实际出现的字段，缺字段不清空手填值。
- 进度百分比按章节位置算；「已完」只由真实播完事件写 `finished_at`。
- UI 使用 `theme_tokens.dart` 的间距 / 圆角 / 动效 token；320dp、系统大字号、深色模式不溢出。
- 中文注释与文案；`flutter analyze` 0 问题；`flutter test` 全绿。
- 每个任务结束提交一次；提交信息用 `feat|fix|test|docs:` 前缀。

## Review Focus

1. **v1 旧库升级**：已有书、覆盖层、播放进度必须在 schema v2 后完整保留，不能触发重建。
2. **sidecar 缺字段重导入**：文件里没有 `author` 时，不能把用户手填的作者清空。
3. **SAF 根保存元数据**：只能写 SQLite，绝不能尝试创建文件；UI 必须出现「来源只读」提示。
4. **筛选/搜索零结果**：显示「清除筛选」空态，不能退回全局空态。
5. **详情页缺失章**：不可点、不能进入播放；正常章点按必须从该章开头起播且不触发微回退。

---

### Task 1: schema v2、迁移与元数据值对象

**Files:**
- Modify: `lib/domain/library/database/tables.dart`
- Modify: `lib/domain/library/database/tometone_database.dart`
- Create: `lib/domain/library/metadata/book_metadata.dart`
- Test: `test/domain/library/database/migration_v2_test.dart`
- Test: `test/domain/library/metadata/book_metadata_test.dart`

**Interfaces:**
- Produces:
  - `BookMetadataOverrides.manualEditedAt`（nullable DateTime）
  - `PlaybackProgress.finishedAt`（nullable DateTime）
  - `BookTags` 表：`bookId`、`tag`，主键 `(bookId, tag)`
  - `class BookMetadataDraft { const BookMetadataDraft({this.title, this.author, this.narrator, this.seriesName, this.seriesIndex, this.description, this.tags = const <String>[]}); bool get isEmpty; BookMetadataDraft normalized(); }`
  - `List<String> normalizeTags(Iterable<String> raw)`

- [ ] **Step 1: 写迁移失败测试**

在 `test/domain/library/database/migration_v2_test.dart` 建一个临时文件数据库，手工建 v1 的 `library_roots` / `books` / `book_metadata_overrides` 表（旧列集合），插入一条书与一条覆盖层，`PRAGMA user_version = 1` 后关闭；再用 `TomeToneDatabase(NativeDatabase(file))` 打开。

断言：

```dart
expect(db.schemaVersion, 2);
final columns = await db.customSelect("PRAGMA table_info('book_metadata_overrides')").get();
expect(columns.map((r) => r.read<String>('name')), contains('manual_edited_at'));
final progressColumns = await db.customSelect("PRAGMA table_info('playback_progress')").get();
expect(progressColumns.map((r) => r.read<String>('name')), contains('finished_at'));
final tables = await db.customSelect("SELECT name FROM sqlite_master WHERE type='table'").get();
expect(tables.map((r) => r.read<String>('name')), contains('book_tags'));
expect(await db.select(db.bookMetadataOverrides).get(), hasLength(1));
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/domain/library/database/migration_v2_test.dart`
Expected: FAIL（schemaVersion 仍为 1 / 缺列 / 缺表）

- [ ] **Step 3: 改表与迁移**

在 `tables.dart`：

- `BookMetadataOverrides` 增加 `DateTimeColumn get manualEditedAt => dateTime().nullable()();`
- `PlaybackProgress` 增加 `DateTimeColumn get finishedAt => dateTime().nullable()();`
- 新增 `@TableIndex(name: 'book_tags_tag', columns: {#tag})` 的 `BookTags` 表，字段按 Interfaces。

在 `tometone_database.dart`：

- `@DriftDatabase` 的 `tables` 加入 `BookTags`。
- `schemaVersion => 2`。
- `onUpgrade` 里 `if (from < 2)` 依次 `addColumn(bookMetadataOverrides, bookMetadataOverrides.manualEditedAt)`、`addColumn(playbackProgress, playbackProgress.finishedAt)`、`createTable(bookTags)`。
- 保留现有 `beforeOpen` 的外键开关。

- [ ] **Step 4: 写 `BookMetadataDraft` 与标签归一化测试**

`test/domain/library/metadata/book_metadata_test.dart` 断言：

```dart
expect(normalizeTags([' 武侠 ', '', '武侠', '长篇', '长篇']), ['武侠', '长篇']);
expect(normalizeTags(['A', 'a']), ['A']);
expect(const BookMetadataDraft().normalized().isEmpty, isTrue);
expect(const BookMetadataDraft(author: '  ').normalized().author, isNull);
expect(const BookMetadataDraft(tags: ['武侠']).isEmpty, isFalse);
```

- [ ] **Step 5: 建 `BookMetadataDraft`**

`book_metadata.dart` 实现 Interfaces 中的值对象：

- 所有字符串字段 `trim()`，空串归一化为 `null`。
- `tags` 走 `normalizeTags`：按 `,` / `，` / `、` 拆分，去空、去首尾空格、大小写不敏感去重（保留首次写法）。
- `isEmpty` 为所有字段为空且 tags 为空。

- [ ] **Step 6: 生成代码并跑测试**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/domain/library/database/migration_v2_test.dart test/domain/library/metadata/book_metadata_test.dart
```
Expected: PASS

- [ ] **Step 7: 提交**

```bash
git add lib/domain/library/database lib/domain/library/metadata test/domain/library/database test/domain/library/metadata
git commit -m "feat: add shelf metadata schema v2"
```

---

### Task 2: 摘要查询、标签与元数据写入

**Files:**
- Modify: `lib/domain/library/queries/library_views.dart`
- Modify: `lib/domain/library/queries/library_queries.dart`
- Modify: `lib/app/providers/app_providers.dart`
- Test: `test/domain/library/queries/drift_library_queries_test.dart`
- Test: `test/ui/ui_test_harness.dart`（`testSummary` 补新字段）

**Interfaces:**
- Consumes: `BookMetadataDraft` / `normalizeTags`（Task 1）
- Produces:
  - `BookSummary.description`（`String?`）
  - `BookSummary.tags`（`List<String>`，默认 `const []`）
  - `BookSummary.isFinished`（`bool`，默认 `false`）
  - `BookSummary.metadataEdited`（`bool`，默认 `false`）
  - `BookSummary.progressChapterIndex`（`int?`）
  - `LibraryQueries.listAllBooks()`
  - `LibraryQueries.listBookTags()`
  - `LibraryQueries.saveBookMetadata({required String bookId, required BookMetadataDraft metadata, bool manual = true, bool onlyFillEmpty = false, DateTime? updatedAt})`
  - `LibraryQueries.saveProgress({..., bool finished = false})`

- [ ] **Step 1: 写查询失败测试**

在 `drift_library_queries_test.dart` 增加：

1. 造 61 本书，`listAllBooks()` 返回 61；`listBooks()` 仍受默认 50 限制。
2. 给一本书插入 `book_metadata_overrides(title: '覆盖书名', description: '简介', author: '作者')` 与两条 `book_tags`；断言摘要取覆盖书名、`description == '简介'`、`tags` 有序且完整。
3. 插入 `playback_progress(finishedAt: now)`；断言对应 `isFinished == true`、`progressChapterIndex` 等于当前章节的 `chapterIndex`。
4. 覆盖层 `manualEditedAt` 非空时，摘要 `metadataEdited == true`。
5. `saveBookMetadata(manual: true)` 后覆盖层 `manualEditedAt` 非空、标签被替换。
6. `saveBookMetadata(manual: false, onlyFillEmpty: true)` 在已有手填值时只补空字段；缺失字段不清空。
7. `listBookTags()` 返回去重后的全部标签，并按不区分大小写排序。
8. `saveProgress(finished: true)` 写入 `finishedAt`；随后 `saveProgress(finished: false)` 清空。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/domain/library/queries/drift_library_queries_test.dart`
Expected: FAIL（方法 / 字段不存在）

- [ ] **Step 3: 扩展视图**

`BookSummary` 加五个字段，构造参数给默认值，保持现有调用方编译。`testSummary` 增加同名可选参数并透传。

- [ ] **Step 4: 扩展 SQL**

`_selectSummaries` 的 FROM 增加：

```sql
LEFT JOIN book_metadata_overrides m ON m.book_id = b.id
```

SELECT 用 `COALESCE(m.title, b.title) AS title`、`COALESCE(m.author, b.author)`、`COALESCE(m.narrator, b.narrator)`、`COALESCE(m.series_name, b.series_name)`、`COALESCE(m.series_index, b.series_index)`、`m.description`、`m.manual_edited_at IS NOT NULL AS metadata_edited`、`p.finished_at`、`c.chapter_index AS progress_chapter_index`。

标签单独一条 `SELECT book_id, tag FROM book_tags ORDER BY tag COLLATE NOCASE`，按 book_id 分组后填进摘要。`_selectSummaries` 增加可选 `limit`；`listAllBooks()` 走无 `LIMIT` 的路径。

- [ ] **Step 5: 实现写入**

`saveBookMetadata` 用事务：

- 读现有覆盖层；`manual == true` 时用传入值整体覆盖并写 `manualEditedAt = now`。
- `manual == false && onlyFillEmpty == true` 时只填空字段；若现有 `manualEditedAt != null`，直接 no-op。
- `manual == false && onlyFillEmpty == false` 是「用户确认后的重新导入」：只覆盖传入的非空字段，**不清空** `manualEditedAt`（保守：以后自动导入仍不会碰这本书）。
- 标签：`manual == true` 整体替换（空列表表示清空）；`manual == false` 时空列表视为「未提供」，不清空现有标签；`onlyFillEmpty == true` 仅在现有标签为空时写入。
- `updatedAt` 默认 `DateTime.now().toUtc()`。

`saveProgress` 增加 `finished` 参数，写 `finishedAt: Value(finished ? now : null)`。

- [ ] **Step 6: 切换书架数据源**

`booksProvider` 改为 `ref.watch(libraryQueriesProvider).listAllBooks()`；保持 `ref.invalidate(booksProvider)` 语义不变。

- [ ] **Step 7: 跑测试**

Run: `flutter test test/domain/library/queries/drift_library_queries_test.dart test/ui`
Expected: PASS（现有 UI 测试因默认字段不变仍应通过）

- [ ] **Step 8: 提交**

```bash
git add lib/domain/library/queries lib/app/providers/app_providers.dart test/domain/library/queries test/ui/ui_test_harness.dart
git commit -m "feat: expose shelf metadata in book summaries"
```

---

### Task 3: 播放完成信号与指定章起播

**Files:**
- Modify: `lib/app/policy/playback_controller.dart`
- Modify: `lib/app/providers/playback_providers.dart`
- Test: `test/app/policy/playback_controller_test.dart`
- Test: `test/app/playback/open_book_test.dart`

**Interfaces:**
- Consumes: `LibraryQueries.saveProgress(finished:)`（Task 2）
- Produces:
  - `PlaybackController({..., Future<void> Function(String bookId, String chapterId, Duration position)? onBookFinished})`
  - `openBook({..., String? startChapterId})`

- [ ] **Step 1: 写完成信号失败测试**

在 `playback_controller_test.dart` 用现有 Fake 引擎跑到最后一章末尾，断言注入的 `onBookFinished` 恰好调用一次，参数是当前 `bookId/chapterId/position`；再 `open` 新章并 flush，断言普通 `writeProgress` 仍以 `finished: false` 写入。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/app/policy/playback_controller_test.dart`
Expected: FAIL（构造参数不存在）

- [ ] **Step 3: 实现完成回调**

- 构造函数新增可选 `onBookFinished`。
- 把 `_finished = true` 的两处（`skipToNext` 末尾、`_onChapterCompleted` 末尾）收敛到私有 `_markFinished()`：置位、暂停、调用 `onBookFinished`。
- 不改变现有 `_writeProgress` 签名。

- [ ] **Step 4: 接线到数据库**

`playbackControllerProvider` 注入：

```dart
onBookFinished: (bookId, chapterId, position) {
  unawaited(
    queries
        .saveProgress(
          bookId: bookId,
          chapterId: chapterId,
          position: position,
          finished: true,
        )
        .catchError((Object _) {}),
  );
},
```

- [ ] **Step 5: 写指定章起播失败测试**

在 `open_book_test.dart` 增加：书已打开时用 `startChapterId` 指定另一章，断言不会走 `alreadyOpen` 短路，`controller.current` 是目标章，位置为 0，`savedPosition == Duration.zero`。

- [ ] **Step 6: 实现 `startChapterId`**

`openBook` 增加参数；非空时：

- 跳过 `alreadyOpen` 短路。
- `startChapterId = 指定章`；若队列里找不到则回落到第一章。
- `savedPosition = Duration.zero`，`interruption = Duration.zero`（不触发微回退）。

- [ ] **Step 7: 跑测试**

Run: `flutter test test/app/policy/playback_controller_test.dart test/app/playback/open_book_test.dart`
Expected: PASS

- [ ] **Step 8: 提交**

```bash
git add lib/app/policy/playback_controller.dart lib/app/providers/playback_providers.dart test/app/policy/playback_controller_test.dart test/app/playback/open_book_test.dart
git commit -m "feat: persist book completion and start playback at chapter"
```

---

### Task 4: sidecar 契约、编解码与本地/SAF 实现

**Files:**
- Create: `lib/contracts/storage/book_metadata_file_store.dart`
- Create: `lib/domain/library/metadata/book_metadata_codec.dart`
- Create: `lib/modules/storage_local/local_book_metadata_file_store.dart`
- Create: `lib/modules/storage_saf/saf_book_metadata_file_store.dart`
- Test: `test/contracts/book_metadata_file_store_test.dart`
- Test: `test/domain/library/metadata/book_metadata_codec_test.dart`
- Test: `test/modules/storage_local/local_book_metadata_file_store_test.dart`
- Test: `test/modules/storage_saf/saf_book_metadata_file_store_test.dart`

**Interfaces:**
- Consumes: `BookMetadataDraft.normalized()`（Task 1）
- Produces:
  - `enum BookMetadataWriteStatus { written, unsupported, failed }`
  - `typedef BookMetadataFileStoreFactory = BookMetadataFileStore Function(String rootUri)`
  - `abstract interface class BookMetadataFileStore { Future<Uint8List?> read(String bookRootPath); Future<BookMetadataWriteStatus> write(String bookRootPath, Uint8List bytes); }`
  - `class BookMetadataCodec { static const int schemaVersion = 1; static Uint8List encode(BookMetadataDraft draft, {required DateTime updatedAt}); static BookMetadataDraft? decode(Uint8List bytes); }`

- [ ] **Step 1: 写编解码失败测试**

`book_metadata_codec_test.dart` 断言：

```dart
final bytes = BookMetadataCodec.encode(
  const BookMetadataDraft(title: '长夜行舟', tags: ['武侠']),
  updatedAt: DateTime.utc(2026, 10, 20),
);
final decoded = BookMetadataCodec.decode(bytes)!;
expect(decoded.title, '长夜行舟');
expect(decoded.tags, ['武侠']);
expect(BookMetadataCodec.decode(Uint8List.fromList([1, 2, 3])), isNull);
expect(BookMetadataCodec.decode(Uint8List.fromList(utf8.encode('{"schema":99}'))), isNull);
```

再断言 JSON 缺字段时对应值为 null，未知字段被忽略。

- [ ] **Step 2: 写本地 store 失败测试**

用临时目录建 `root/books/a/`，写入音频占位文件；断言：

- `write('books/a', bytes)` 后 `tometone.meta.json` 存在且内容一致。
- `read('books/a')` 返回同一字节。
- 写入后音频文件字节未变。
- 超过 256 KB 的 `read` 返回 null（或按 spec 的失败语义）。
- 目标目录不存在时 `write` 返回 `failed`。

- [ ] **Step 3: 写 SAF store 失败测试**

用现有 `SafBridge` 的 fake MethodChannel：

- 读：断言先 `documentUri`（`relativePath: 'books/a/tometone.meta.json'`）再 `readBytes`，返回字节。
- 写：直接返回 `unsupported`，且不调用任何平台写方法。

- [ ] **Step 4: 实现契约与编解码**

- 契约只依赖 `dart:typed_data`，不 import domain。
- Codec 用 `jsonEncode/jsonDecode`，输出 `schema`、字段、`updatedAt` ISO8601；`schema > 1` 返回 null；坏 JSON 返回 null；`decode` 后走 `normalized()`。

- [ ] **Step 5: 实现本地与 SAF store**

- 本地：`join(rootPath, bookRootPath, 'tometone.meta.json')`；写临时文件 `tometone.meta.json.tmp` → `flush` → `rename`；失败清理临时文件并返回 `failed`。
- SAF：读用 `SafBridge.documentUri` + `readBytes`；写返回 `unsupported`。

- [ ] **Step 6: 跑测试**

Run:
```bash
flutter test test/contracts/book_metadata_file_store_test.dart test/domain/library/metadata/book_metadata_codec_test.dart test/modules/storage_local/local_book_metadata_file_store_test.dart test/modules/storage_saf/saf_book_metadata_file_store_test.dart
```
Expected: PASS

- [ ] **Step 7: 提交**

```bash
git add lib/contracts/storage lib/domain/library/metadata lib/modules/storage_local lib/modules/storage_saf test/contracts test/domain/library/metadata test/modules
git commit -m "feat: add book metadata sidecar store"
```

---

### Task 5: 元数据服务、扫描导入与装配

**Files:**
- Create: `lib/app/library/book_metadata_service.dart`
- Create: `lib/app/providers/metadata_providers.dart`
- Modify: `lib/app/library/library_root_service.dart`
- Modify: `lib/app/providers/library_root_providers.dart`
- Modify: `lib/domain/library/scan/library_scanner.dart`
- Modify: `lib/main.dart`
- Test: `test/app/library/book_metadata_service_test.dart`
- Test: `test/app/library/library_root_service_test.dart`
- Test: `test/domain/library/scan/library_scanner_test.dart`

**Interfaces:**
- Consumes: `BookMetadataFileStoreFactory`、`BookMetadataCodec`（Task 4）；`saveBookMetadata`（Task 2）
- Produces:
  - `class MetadataSaveResult { const MetadataSaveResult({required this.sidecarStatus}); final BookMetadataWriteStatus sidecarStatus; }`
  - `class BookMetadataService { BookMetadataService({required LibraryQueries queries, required BookMetadataFileStoreFactory storeFactory, DateTime Function()? clock}); Future<MetadataSaveResult> save({required BookSummary book, required String rootUri, required BookMetadataDraft draft}); Future<BookMetadataDraft?> importFromBookRoot({required BookSummary book, required String rootUri, bool overwriteManual = false}); }`
  - `bookMetadataFileStoreFactoryProvider`（未装配时抛 `UnimplementedError`）
  - `bookMetadataServiceProvider`
  - `LibraryRootService({..., BookMetadataFileStoreFactory? metadataStoreFactory})`
  - `LibraryScanner.scanStructure({..., BookMetadataFileStore? metadataStore})`

- [ ] **Step 1: 写服务失败测试**

`book_metadata_service_test.dart`：

1. `save()` 调用 `saveBookMetadata(manual: true)` 并向可写 store 写入编码字节，返回 `written`。
2. store 返回 `unsupported` 时，数据库仍保存成功，返回 `unsupported`。
3. `importFromBookRoot()` 读到 `title` 但没有 `author` 时，不把手动作者清空；`overwriteManual: false` 时手动覆盖层不变。

- [ ] **Step 2: 写扫描导入失败测试**

`library_scanner_test.dart`：新建书根下放 `tometone.meta.json`（含 title/description/tags），扫描后：

- 书的摘要取 sidecar 的 title，而不是目录名。
- 覆盖层 `manualEditedAt == null`。
- 已存在且 `manualEditedAt != null` 的书，重扫描后字段不变（该场景用已有书 + 第二次扫描验证）。

- [ ] **Step 3: 运行测试确认失败**

Run: `flutter test test/app/library/book_metadata_service_test.dart test/domain/library/scan/library_scanner_test.dart`
Expected: FAIL（服务 / 参数不存在）

- [ ] **Step 4: 实现服务**

`BookMetadataService.save`：

1. `await queries.saveBookMetadata(bookId: book.id, metadata: draft.normalized(), manual: true)`。
2. `final store = storeFactory(rootUri);`
3. `final status = await store.write(book.rootPath, BookMetadataCodec.encode(draft.normalized(), updatedAt: clock()));`
4. 返回 `MetadataSaveResult(sidecarStatus: status)`；数据库异常直接抛出；store 异常折叠成 `failed`。

`importFromBookRoot`：

1. `final bytes = await store.read(book.rootPath);` 为空返回 null。
2. `final draft = BookMetadataCodec.decode(bytes);` 为空返回 null。
3. `await queries.saveBookMetadata(bookId: book.id, metadata: draft, manual: false, onlyFillEmpty: !overwriteManual)`。
4. 返回 draft。

- [ ] **Step 5: 扫描时导入新书 sidecar**

只对**本次新增**的书读 sidecar（`existingBook == null`），避免每次扫描对上千本书做文件 IO；老书走详情页「从书根重新导入」。

`LibraryScanner.scanStructure` 增加 `BookMetadataFileStore? metadataStore`。在构建 plan 时，对 `existingBook == null` 的书：

```dart
final bytes = await metadataStore?.read(bookTopology.rootPath);
final draft = bytes == null ? null : BookMetadataCodec.decode(bytes);
if (draft != null && !draft.isEmpty) {
  plan.metadataOverrides.add((bookId: bookId, metadata: draft));
}
```

事务里插入 `BookMetadataOverridesCompanion.insert(bookId: ..., title: Value(draft.title), ..., updatedAt: now)` 与 `book_tags`。`manualEditedAt` 不写（null）。

`LibraryRootService.scan` 里按根创建 store：

```dart
final store = _metadataStoreFactory?.call(root.uri);
return _scanner.scanStructure(..., metadataStore: store);
```

- [ ] **Step 6: 装配**

- `library_root_providers.dart` 增加 `bookMetadataFileStoreFactoryProvider`，默认抛 `UnimplementedError`；`LibraryRootService` 构造时传入。
- `metadata_providers.dart` 增加 `bookMetadataServiceProvider`，注入 `libraryQueriesProvider` 与工厂。
- `main.dart` 增加：

```dart
BookMetadataFileStore _createMetadataStore(String rootUri) {
  if (rootUri.startsWith('content://')) {
    return SafBookMetadataFileStore(rootUri);
  }
  return LocalBookMetadataFileStore(rootUri);
}
```

并 override `bookMetadataFileStoreFactoryProvider`；`LibraryRootService` 构造参数补上。

- [ ] **Step 7: 跑测试**

Run:
```bash
flutter test test/app/library/book_metadata_service_test.dart test/app/library/library_root_service_test.dart test/domain/library/scan/library_scanner_test.dart
```
Expected: PASS

- [ ] **Step 8: 提交**

```bash
git add lib/app/library lib/app/providers lib/domain/library/scan lib/main.dart test/app/library test/domain/library/scan
git commit -m "feat: import and persist book metadata sidecars"
```

---

### Task 6: 筛选模型与书架页头

**Files:**
- Create: `lib/ui/pages/shelf/shelf_filter.dart`
- Modify: `lib/ui/pages/shelf/shelf_page.dart`
- Test: `test/ui/shelf_page_test.dart`

**Interfaces:**
- Consumes: `BookSummary.description/tags/isFinished/progressChapterIndex`（Task 2）
- Produces:
  - `enum ShelfStatusFilter { all, listening, unlistened, finished }`
  - `enum ShelfLayout { grid, list }`
  - `class ShelfFilterState { const ShelfFilterState({this.query = '', this.status = ShelfStatusFilter.all, this.tag, this.series}); List<BookSummary> apply(List<BookSummary> books); bool get isActive; }`

- [ ] **Step 1: 写筛选失败测试**

在 `shelf_page_test.dart` 造 4 本摘要：在听、未听、已完、无简介。断言：

- `apply([])` 为空。
- 搜索 `作者` / `演播` / 简介关键词都能命中。
- 状态筛选只留对应书。
- 标签 / 系列筛选组合生效。
- `isActive` 在 query / status / tag / series 任一非默认时为 true。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/shelf_page_test.dart`
Expected: FAIL（类型不存在）

- [ ] **Step 3: 实现筛选模型**

- 搜索：`toLowerCase()` 后对 title/author/narrator/seriesName/description 做 contains。
- 状态：`listening => hasProgress && !isFinished`；`unlistened => !hasProgress`；`finished => isFinished`。
- 标签 / 系列：按原文比较，标签大小写折叠。
- 组合为 AND。

- [ ] **Step 4: 重排页头**

`shelf_page.dart` 改为 `ConsumerStatefulWidget`，持有 `_filter` 与 `_layout`。页头包含：

- 标题 `我的书架` + 数量。
- 搜索图标 → 展开单行输入；有关键字时显示清除按钮。
- 状态 chips：`全部 / 在听 / 未听 / 已完`。
- `分类` 与 `系列` 下拉/弹层；选项从当前书单派生。
- 布局切换按钮（网格/列表）。

保持现有加载态 / 错误态 / 全局空态。

- [ ] **Step 5: 跑测试**

Run: `flutter test test/ui/shelf_page_test.dart`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add lib/ui/pages/shelf test/ui/shelf_page_test.dart
git commit -m "feat: add shelf search and filters"
```

---

### Task 7: 网格卡片与列表行

**Files:**
- Create: `lib/ui/pages/shelf/shelf_progress.dart`
- Create: `lib/ui/pages/shelf/shelf_book_card.dart`
- Create: `lib/ui/pages/shelf/shelf_book_row.dart`
- Modify: `lib/ui/pages/shelf/shelf_page.dart`
- Test: `test/ui/shelf_page_test.dart`

**Interfaces:**
- Consumes: `BookSummary`（Task 2）；`ShelfLayout`（Task 6）
- Produces:
  - `class ShelfProgress extends StatelessWidget { const ShelfProgress({required this.book, this.compact = false, super.key}); }`
  - `class ShelfBookCard extends ConsumerWidget { const ShelfBookCard({required this.book, required this.onOpen, required this.onPlay, super.key}); }`
  - `class ShelfBookRow extends ConsumerWidget { const ShelfBookRow({required this.book, required this.onOpen, required this.onPlay, super.key}); }`

- [ ] **Step 1: 写卡片失败测试**

断言：

- 卡片显示书名、作者/演播、简介一行、进度百分比。
- 简介为空时显示 `暂无简介`，不出现空行塌陷。
- 点卡片触发 `onOpen`，点播放按钮只触发 `onPlay`。
- 列表行显示两行简介与标签 chips。
- 320dp + `textScaleFactor: 1.6` 无 overflow。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/shelf_page_test.dart`
Expected: FAIL（组件不存在）

- [ ] **Step 3: 实现卡片**

- 复用 `BookCover` 与 `coverArtProvider`。
- 封面右下角/下方放播放按钮；`InkWell` 只包卡片主体，播放按钮独立。
- 进度：`(progressChapterIndex + 1) / totalChapters`，clamp 0..1；无进度显示 `未听`；已完显示 `已完`。网格与列表共用 `ShelfProgress`，不写两套口径。
- 简介 `maxLines: 1`、`ellipsis`；无简介显示 `暂无简介`。
- 缺失章提示保留现有样式。

- [ ] **Step 4: 实现列表行**

- 封面缩略图 64×64 圆角；正文 title / author·narrator / description 2 行 / tags；右侧播放按钮。
- 进度用同一条 `_ShelfProgress` 组件，避免两套口径。

- [ ] **Step 5: 接入页面**

- 网格：`SliverGrid` 使用 `ShelfBookCard`。
- 列表：`SliverList` 使用 `ShelfBookRow`。
- 布局切换不重建数据，只切 delegate。

- [ ] **Step 6: 跑测试**

Run: `flutter test test/ui/shelf_page_test.dart`
Expected: PASS

- [ ] **Step 7: 提交**

```bash
git add lib/ui/pages/shelf test/ui/shelf_page_test.dart
git commit -m "feat: redesign shelf cards and rows"
```

---

### Task 8: 书架零结果态与详情入口

**Files:**
- Modify: `lib/ui/pages/shelf/shelf_page.dart`
- Create: `lib/ui/pages/shelf/open_book_action.dart`
- Test: `test/ui/shelf_page_test.dart`

**Interfaces:**
- Produces:
  - `Future<void> openBookAndShowPlayer({required BuildContext context, required WidgetRef ref, required BookDetail detail, String? startChapterId});`
  - `Future<void> playBookFromSummary({required BuildContext context, required WidgetRef ref, required BookSummary book});`（先取 `bookDetailProvider(book.id)`，再转调上面的函数）

- [ ] **Step 1: 写零结果态测试**

筛选到无结果时断言出现「没有符合条件的书」与「清除筛选」；点清除后恢复原列表；全局无书时仍是原空态。

- [ ] **Step 2: 写起播动作测试**

- 点播放按钮 → `playBookFromSummary` 被调用，播放台打开。
- 根缺失时 SnackBar 文案不变。
- 卡片 → 详情的导航测试放到 Task 9（页面在 Task 9 才出现）。

- [ ] **Step 3: 实现共享起播动作**

把现有 `_openBook` 里的根解析、resolver、`openBook`、失败 SnackBar、`showPlayerPage` 抽到 `open_book_action.dart`；`startChapterId` 透传。书架与详情页共用。把卡片/列表的 `onPlay` 接到 `playBookFromSummary`，卡片点击仍进详情。

- [ ] **Step 4: 接入零结果态**

`visibleBooks.isEmpty && books.isNotEmpty` 时渲染专用空态；`onClear` 重置 `ShelfFilterState()`。

- [ ] **Step 5: 跑测试**

Run: `flutter test test/ui/shelf_page_test.dart`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add lib/ui/pages/shelf test/ui/shelf_page_test.dart
git commit -m "feat: add empty filter state and shared open action"
```

---

### Task 9: 书籍详情页与章节目录

**Files:**
- Create: `lib/ui/pages/shelf/book_detail_page.dart`
- Create: `lib/ui/pages/shelf/chapter_list_sheet.dart`
- Modify: `lib/ui/pages/shelf/shelf_page.dart`
- Test: `test/ui/book_detail_page_test.dart`

**Interfaces:**
- Consumes: `bookDetailProvider`、`openBookAndShowPlayer`、`BookSummary.description/tags`、`LibraryRootView`
- Produces:
  - `typedef BookOpenAction = Future<void> Function(BookDetail detail, String? startChapterId);`
  - `class BookDetailPage extends ConsumerWidget { const BookDetailPage({required this.bookId, this.onOpen, super.key}); final BookOpenAction? onOpen; }`
  - `Future<void> showChapterListSheet(BuildContext context, {required BookDetail detail, required String? currentChapterId, required ValueChanged<ChapterView> onChapterSelected});`

- [ ] **Step 1: 写详情失败测试**

断言：

- 标题、作者、演播、系列、简介、标签、`第 N / 12 章` 全部显示。
- 简介为空显示 `暂无简介` + 编辑入口。
- 有进度显示「从第 N 章继续收听」；无进度显示「开始收听」。
- 点继续触发注入的 `onOpen`（`BookDetailPage(onOpen: fake)`）。
- 点缺失章不触发 `onOpen`；点正常章传入正确 `chapterId` 与 `detail`。
- 书架点卡片 push 到 `BookDetailPage`，播放按钮仍直接起播。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/book_detail_page_test.dart`
Expected: FAIL（页面不存在）

- [ ] **Step 3: 实现详情页**

- `ref.watch(bookDetailProvider(bookId))` 三态：加载 / 失败重试 / 不存在。
- 大封面、书名、系列、作者/演播、状态、标签 chips、简介、章节目录/卷册入口、底部主按钮。两个入口共用同一个按卷分组的章节弹层；卷册卡展示卷数，章节目录卡展示 `第 N / 12 章`。
- 顶部 `⋮`：`编辑元数据`、`从书根重新导入`（Task 10 接入；先留回调）。
- 通过 `libraryRootsProvider` 找到 `summary.libraryRootId` 对应的 `rootUri`；根缺失时禁用编辑/导入并提示「书库根已移除」。
- 编辑保存后 `ref.invalidate(bookDetailProvider(bookId))` 与 `booksProvider`。

- [ ] **Step 4: 实现章节弹层**

- 按卷分组展示章节；当前章高亮；缺失章置灰且 `onTap: null`。
- 点正常章关闭弹层后调用 `onChapterSelected`。
- 详情页回调里调用 `openBookAndShowPlayer(detail: detail, startChapterId: chapter.id)`。

- [ ] **Step 5: 接入书架导航**

卡片 `onOpen` push `BookDetailPage(bookId: book.id)`；播放按钮走共享起播动作。

- [ ] **Step 6: 跑测试**

Run: `flutter test test/ui/book_detail_page_test.dart test/ui/shelf_page_test.dart`
Expected: PASS

- [ ] **Step 7: 提交**

```bash
git add lib/ui/pages/shelf test/ui/book_detail_page_test.dart test/ui/shelf_page_test.dart
git commit -m "feat: add book detail page and chapter picker"
```

---

### Task 10: 元数据编辑弹层与双写

**Files:**
- Create: `lib/ui/pages/shelf/book_metadata_sheet.dart`
- Modify: `lib/ui/pages/shelf/book_detail_page.dart`
- Test: `test/ui/book_metadata_sheet_test.dart`
- Test: `test/ui/book_detail_page_test.dart`

**Interfaces:**
- Consumes: `BookMetadataService`、`BookMetadataDraft`、`MetadataSaveResult`
- Produces:
  - `Future<bool?> showBookMetadataSheet(BuildContext context, {required BookSummary book, required String rootUri, required BookMetadataDraft initial});`

- [ ] **Step 1: 写编辑弹层失败测试**

断言：

- 预填现有书名/作者/演播/系列/简介/标签。
- 空书名提交被拦下，显示 `书名不能为空`。
- 改作者 + 添加标签 + 保存 → 调用 `save(book, rootUri, draft)`，返回 true。
- service 返回 `written` 时 SnackBar `已保存到应用与书根`；返回 `unsupported` 时 `已保存到应用内，书根文件未写入`。
- 标签输入 `武侠，长篇、武侠` 归一化为 `['武侠','长篇']`。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/book_metadata_sheet_test.dart`
Expected: FAIL（弹层不存在）

- [ ] **Step 3: 实现编辑弹层**

- 用 `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)`。
- 表单字段按 spec；简介 `maxLength: 2000`；标签用输入框 + chips，提交时 `normalizeTags`。
- 保存中禁用按钮；异常显示 `保存失败，请稍后再试`，不关闭弹层。
- 成功后 `Navigator.pop(true)`。

- [ ] **Step 4: 接入详情页**

- `⋮ → 编辑元数据` 打开弹层，传入当前 summary 与 rootUri。
- 返回 true 后 invalidate `bookDetailProvider(bookId)` 与 `booksProvider`。
- `⋮ → 从书根重新导入` 调 `BookMetadataService.importFromBookRoot`；`book.metadataEdited == true` 时先弹确认（说明只覆盖文件里实际出现的字段）；成功/失败给 SnackBar。

- [ ] **Step 5: 跑测试**

Run: `flutter test test/ui/book_metadata_sheet_test.dart test/ui/book_detail_page_test.dart`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add lib/ui/pages/shelf test/ui
git commit -m "feat: edit book metadata and sync sidecar"
```

---

### Task 11: 全量验证、文档与 CHANGELOG

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `docs/superpowers/specs/2026-10-20-ui-refresh-shelf-metadata-design.md`（状态改为「已落地」）
- Test: 全量

- [ ] **Step 1: 跑静态分析与全量测试**

Run:
```bash
flutter analyze
flutter test
```
Expected: `No issues found!`；所有测试通过（现有 493 + 新增）。

- [ ] **Step 2: 手工验收清单**

- 320dp + 1.6 倍字体：书架网格 / 列表 / 详情 / 编辑弹层无 overflow。
- 深色模式：卡片、chips、详情、弹层对比度正常。
- 本地根保存 → 书根出现 `tometone.meta.json`；修改后重新扫描元数据还在。
- SAF 根保存 → 只写库，提示「来源只读」，书根无新文件。
- 手动改作者 → 重新扫描不被目录名覆盖。
- 点详情页正常章 → 播放台从该章 0 秒开始；缺失章不可点。

- [ ] **Step 3: 更新 CHANGELOG**

在 `[未发布]` 写清新功能、元数据双写、schema v2 迁移、已知限制（SAF 只读、分页待做、在线抓取待 Phase 3）。

- [ ] **Step 4: 提交**

```bash
git add CHANGELOG.md docs/superpowers/specs/2026-10-20-ui-refresh-shelf-metadata-design.md
git commit -m "docs: record shelf metadata release"
```

---

## Self-Review

- **Spec coverage:** 书架双布局（Task 6/7）、分类与简介（Task 1/2/7）、详情（Task 9）、编辑（Task 10）、双写（Task 4/5）、完成状态（Task 2/3）、章节点播（Task 3/9）均有对应任务。
- **Type consistency:** `BookMetadataDraft`、`BookMetadataFileStore`、`BookMetadataWriteStatus`、`BookSummary` 新字段在各任务 Interfaces 中保持一致；`saveProgress(finished:)` 在 Task 2 定义、Task 3 消费。
- **Review Focus tests:** 迁移在 Task 1；sidecar 缺字段与 SAF 只读在 Task 4/5/10；零结果在 Task 8；缺失章在 Task 9。
- **Out of scope:** 播放台 UI、歌词、书源、分页、在线元数据抓取均未排入本轮。
