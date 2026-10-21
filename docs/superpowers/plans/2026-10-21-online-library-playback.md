# 在线书源 M1-C：入库、书架、书库与在线播放

> **给实现工程师：** 本计划假设你从零接手，按任务顺序执行。每个任务先写失败测试，再实现，再验证，再提交。不要跳过测试权限闸门。
>
> **测试权限：** 在运行任何 `flutter analyze` 或 `flutter test` 之前，必须先取得用户明确许可。每个任务的验证命令都是待执行步骤，不是自动授权。

**目标：** 在 M1-B 的发现/预览基础上，交付在线书的可写链路：预览页「加入书架 / 立即收听」、`on_shelf` 与多选分类、在线音频解析与流式播放、书架过滤、书库统一书目列表、来源状态展示。完成后用户能把在线书加入书架、在书架/书库看到它，并从详情或书架直接流式播放；本计划**不做**刷新信息/目录、换源、删除和预下载缓存，这些属于 M1-D。

**架构：** 在线书入库走新的 `OnlineLibraryQueries` 领域端口与 `OnlineBookService` 应用服务，不把 Drift 写进 UI；在线音频由 `SourceEngine.resolveAudio` 解析，`OnlineChapterSourceResolver` 负责装配，`PlaybackController` 只通过可注入的按章解析器拿播放源；书库/书架继续通过 `LibraryQueries` 聚合视图渲染，不感知 Drift。书库页面从「书库根卡片」改为统一书目列表，本机根管理移到来源管理页。

**技术栈：** Flutter、Dart 3、Riverpod、Drift、`dart:io` HttpClient、`crypto`（章节绑定键 SHA-256）、现有的 just_audio / PlaybackController。

**设计文档：** `docs/superpowers/specs/2026-10-20-online-book-sources-design.md`

---

## M1 计划系列

| 计划 | 交付 | 依赖 |
|---|---|---|
| **M1-A（已完成）** | schema v3；书源解析/校验/持久化；导入与管理 UI；虚拟在线根 | 无 |
| **M1-B（已完成）** | 规则引擎、发现/搜索/详情预览、五栏导航、书源测试与健康 | M1-A |
| **M1-C（本计划）** | 在线书入库、加入书架、`on_shelf`、书库混排、在线流式播放 | M1-B |
| **M1-D** | 刷新信息/目录、换源、删除护栏、预下载/缓存、整体验收 | M1-C |

**范围边界：**

- 只支持 `bookSourceType == 1` 的 Legado 听书源；不做付费、验证码、DRM 绕过。
- 本计划只做**单段音频流式播放**；HLS 只作为普通 URL 交给引擎，不做分片拼接；多段音频、预下载、缓存 LRU、仅 Wi-Fi、缓存上限、清理入口全部留给 M1-D。
- **打开详情/搜索/发现本身仍不写库**；只有用户点「加入书架」或「立即收听」才 upsert。
- `on_shelf=false` 的在线书**只出现在书库**，不出现在书架；本机书默认 `onShelf=true`。
- 本计划不实现刷新信息/目录、换源、从书库删除、来源删除；这些入口在 M1-C 不显示，或只显示为不可用的占位说明。
- 在线结果行只显示「已在书架 / 已在书库」状态，不显示「加入」按钮；加入动作仍在详情页。
- 本计划不写 `app_settings` / `audio_cache_entries`；表已由 schema v3 建好，M1-D 再接入。
- 本计划中 `chapters.source_uri` 存**原始章 URL（含 URL options）**，保证重启后还能带章节 headers 解析音频；`chapters.file_path` 仍是 `online/<sha256(规范化章 URL)>`，刷新/匹配用 `file_path`。这是对设计表字段语义的明确落地，M1-D 的缓存哈希使用 `source_uri` 原值。

---

## 全局约束

- 任何请求只允许 `http` / `https`；音频 URL 也必须经过 `normalizeNetworkUrl`，禁止 `file/content/intent/javascript/data`。
- 请求头、响应体、书源规则中的会话值不得进入日志、异常文案、测试名或提交。夹具固定使用 `test-session`，绝不使用真实 `x-listening-session`。
- 单元测试与 widget 测试**不得访问真实站点**；音频解析测试只用 fake `SourceHttpClient`，播放测试只用 fake `PlaybackEngine`。
- 在线书身份：`(source_id, root_path)`，其中 `root_path = 规范化 bookUrl`；重复打开/加入必须复用 `books.id`。
- `books.source_type='online'`；`library_root_id` 指向源虚拟根；在线书不走 `mediaSourceResolverForRootProvider`。
- 预览页/详情页/结果行不得显示「加入书架」「立即收听」的禁用占位；只有可执行时才显示。
- 320dp、系统大字号（至少 2.0）、深色模式下不得溢出；长书名/作者/简介最多两行或可滚动。
- 每个任务一个提交；提交信息用 `feat(library): ...` / `feat(playback): ...` / `feat(discovery): ...` / `test(...)`。
- 不运行全量 `dart format`（会改写 20 个既有文件）；只格式化新增/修改文件。
- 任何 `flutter analyze` / `flutter test` 前先向用户申请许可；本计划获批不等于测试许可。

---

## Review Focus（最可能咬人的五处）

1. **首次播放失败留下幽灵书**：点「立即收听」但目录抓取失败时，必须不创建书/章或明确创建为不可播放且不打开播放台；不能留下一条永远打不开的书。
2. **重复入库**：同一 `(source_id, 规范化 bookUrl)` 重复加入/播放必须复用 `books.id`，不重复建卷、章、标签；否则书架会出现两条同名书。
3. **章节 headers 丢失**：`source_uri` 必须保留原始章 URL options，`resolveAudio` 必须把源 header、章 options headers、内容 JSON headers 按后覆盖前合并；否则真实源音频 403。
4. **`on_shelf` 过滤方向**：`onShelf=false` 只从书架消失，必须仍在书库；本机旧书默认 `true`。过滤写反会让用户「加入书架后书不见了」。
5. **在线/本机播放分流**：在线书不能走 `mediaSourceResolverForRootProvider`，本机书不能因为新增在线分支而改变缓存副本/SAF 重试行为；两条路径都要有回归测试。

---

## 开工前检查

- [ ] 工作区干净，分支为 `feat/book-sources`，HEAD 至少包含 M1-B 的 `c02356e`。
- [ ] 已读设计 §4.3–4.6、§6.3、§7.2–7.5、§8.1、§9.6、§10.1。
- [ ] 已读 M1-B 计划与 `.superpowers/sdd/2026-10-21-online-source-discovery/progress.md`，确认测试权限已重新取得。
- [ ] 基线：`flutter analyze` 无问题、`flutter test` 759 项通过（数量以实际为准）；这两条命令必须先获用户许可。
- [ ] 新建 `.superpowers/sdd/2026-10-21-online-library-playback/progress.md`（gitignored，不提交），登记每个任务的测试命令与结果。

---

## 文件地图

**新增（领域/应用）**

- `lib/domain/library/queries/online_library_queries.dart`
- `lib/app/library/online_book_service.dart`
- `lib/app/providers/online_providers.dart`
- `lib/app/playback/online_chapter_source_resolver.dart`
- `lib/app/playback/online_queue_builder.dart`

**新增（UI）**

- `lib/ui/pages/shelf/add_to_shelf_sheet.dart`
- `lib/ui/pages/library/library_book_row.dart`
- `lib/ui/pages/library/library_filter.dart`
- `lib/ui/pages/library/local_roots_section.dart`

**修改（领域/查询）**

- `lib/domain/library/queries/library_views.dart`
- `lib/domain/library/queries/library_queries.dart`
- `lib/domain/sources/discovery/source_models.dart`
- `lib/domain/sources/discovery/source_failure.dart`
- `lib/app/sources/source_engine.dart`
- `lib/app/sources/source_discovery.dart`
- `lib/app/sources/legado/legado_source_engine.dart`
- `pubspec.yaml`（新增 `crypto`）

**修改（播放）**

- `lib/app/policy/chapter_sequencer.dart`
- `lib/app/policy/playback_controller.dart`
- `lib/app/providers/playback_providers.dart`
- `lib/ui/pages/shelf/open_book_action.dart`

**修改（UI）**

- `lib/app/providers/app_providers.dart`（`shelfBooksProvider`）
- `lib/app/providers/source_providers.dart`（按 ID 取源）
- `lib/ui/pages/shelf/shelf_page.dart`
- `lib/ui/pages/shelf/shelf_book_card.dart`
- `lib/ui/pages/shelf/shelf_book_row.dart`
- `lib/ui/pages/shelf/book_detail_page.dart`
- `lib/ui/pages/shelf/chapter_list_sheet.dart`
- `lib/ui/pages/shelf/book_metadata_sheet.dart`（新增 online 保存分支）
- `lib/ui/pages/discovery/online_book_preview_page.dart`
- `lib/ui/pages/discovery/discovery_result_tile.dart`
- `lib/ui/pages/discovery/discovery_page.dart`
- `lib/ui/pages/library/library_page.dart`
- `lib/ui/pages/sources/source_management_page.dart`
- `lib/ui/widgets/network_cover.dart`

**新增测试**

- `test/domain/library/queries/online_library_queries_test.dart`
- `test/app/library/online_book_service_test.dart`
- `test/app/sources/legado_audio_resolve_test.dart`
- `test/app/playback/online_queue_test.dart`
- `test/app/playback/open_book_online_test.dart`
- `test/ui/pages/discovery/online_preview_actions_test.dart`
- `test/ui/book_detail_online_test.dart`
- `test/ui/pages/sources/source_management_local_roots_test.dart`
- `test/ui/library_unified_page_test.dart`
- `test/ui/pages/discovery/discovery_membership_test.dart`

---

### Task 1: 在线书目读模型与聚合查询

**文件：**
- 修改：`lib/domain/library/queries/library_views.dart`
- 修改：`lib/domain/library/queries/library_queries.dart:338-418`
- 测试：`test/domain/library/queries/drift_library_queries_test.dart`

**接口：**
- Consumes: `Books` 的 `onShelf` / `sourceId` / `coverUrl` / `description` / `kind` / `wordCount` / `sourceStatus` / `lastChapter`，`BookSources` 的 `name` / `enabled` / `deletedAt`。
- Produces:
  - `BookSummary` 新字段：`sourceType`（默认 `'local'`）、`String? sourceId`、`bool onShelf`（默认 `true`）、`String? coverUrl`、`String? kind`、`String? wordCount`、`String? sourceStatus`、`String? lastChapter`、`String? sourceName`、`bool? sourceEnabled`、`bool? sourceDeleted`；`bool get isOnline => sourceType == 'online';`
  - `ChapterView` 新字段：`String? sourceUri`、`bool retired`（默认 `false`）、`bool isVip`（默认 `false`）。
  - `BookDetail.chapters` 只返回 `retired=false` 的 active 章；新增 `List<ChapterView> get retiredChapters`。
  - `DriftLibraryQueries._selectSummaries` 左连接 `book_sources`，投影上述字段；本机书 `sourceEnabled/sourceDeleted` 为 `null`。

- [ ] **Step 1: 写失败测试**

在 `drift_library_queries_test.dart` 增加：
- 在线书行返回 `isOnline=true`、`onShelf=false`、`sourceName='听友听书'`、`sourceEnabled=true`、`coverUrl`、`kind`、`wordCount`、`lastChapter`。
- 本机书行 `isOnline=false`、`onShelf=true`、`sourceName=null`。
- `bookDetail` 对 `retired=true` 的章不出现在 `chapters`，只出现在 `retiredChapters`；`isVip` 和 `sourceUri` 保留。
- `source_deleted` 通过 `deletedAt` 映射为 `sourceDeleted=true`。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/domain/library/queries/drift_library_queries_test.dart`（需许可）
Expected: FAIL，找不到新字段/构造参数。

- [ ] **Step 3: 扩展模型与查询**

按 Interfaces 增加字段，构造参数全部可选并给默认值，避免现有测试/调用点大面积改动。SQL 投影用 `LEFT JOIN book_sources s ON s.id = b.source_id`，读取 `s.name`、`s.enabled`、`s.deleted_at`。`BookDetail` 用 `where((c) => !c.retired)` 派生 active 列表。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/domain/library/queries/drift_library_queries_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/domain/library/queries/library_views.dart lib/domain/library/queries/library_queries.dart test/domain/library/queries/drift_library_queries_test.dart
git commit -m "feat(library): expose online book fields"
```

---

### Task 2: 书架 on_shelf 过滤与在线封面/状态

**文件：**
- 修改：`lib/app/providers/app_providers.dart`
- 修改：`lib/ui/widgets/network_cover.dart`
- 修改：`lib/ui/pages/shelf/shelf_page.dart:167-194`
- 修改：`lib/ui/pages/shelf/shelf_book_card.dart`
- 修改：`lib/ui/pages/shelf/shelf_book_row.dart`
- 测试：`test/ui/shelf_page_test.dart`

**接口：**
- Consumes: Task 1 的 `BookSummary.onShelf` / `isOnline` / `coverUrl` / `sourceName` / `sourceEnabled` / `sourceDeleted`。
- Produces:
  - `final FutureProvider<List<BookSummary>> shelfBooksProvider`：读取 `booksProvider.future`，过滤 `book.onShelf`。
  - `NetworkCover({required String? coverUrl, double size = 64, Map<String,String>? headers, BorderRadius? borderRadius})`；`headers` 透传 `Image.network(headers: ...)`。
  - 书架卡片/列表行对在线书使用 `NetworkCover`，显示来源名与「来源已停用/已删除」标记；本机书保持 `BookCover`。

- [ ] **Step 1: 写失败测试**

在 `shelf_page_test.dart` 增加：
- 两本书，一本 `onShelf=true` 一本 `onShelf=false`，只渲染前者。
- 在线书使用 `NetworkCover`（`find.byType(NetworkCover)`），本机书仍使用 `BookCover`。
- 在线书 `sourceDeleted=true` 显示「来源已删除」；`sourceEnabled=false` 显示「来源已停用」。
- `NetworkCover(headers: {'Referer':'https://e.test/'})` 的 `Image.network` 收到同一 headers（用 widget 检查 `Image.image` 为 `NetworkImage`，必要时拆出 `headers` 读取接口）。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/shelf_page_test.dart`（需许可）
Expected: FAIL，`shelfBooksProvider` 不存在/在线书仍用 `BookCover`。

- [ ] **Step 3: 实现过滤与封面分支**

`ShelfPage` 改 watch `shelfBooksProvider`；重试时同时 `ref.invalidate(booksProvider)`。卡片/行加 `if (book.isOnline)` 分支。`NetworkCover` 增加 `headers`，默认空 map。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/ui/shelf_page_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/app/providers/app_providers.dart lib/ui/widgets/network_cover.dart lib/ui/pages/shelf/shelf_page.dart lib/ui/pages/shelf/shelf_book_card.dart lib/ui/pages/shelf/shelf_book_row.dart test/ui/shelf_page_test.dart
git commit -m "feat(library): filter shelf by on_shelf"
```

---

### Task 3: 在线书入库端口与加入书架服务

**文件：**
- 新增：`lib/domain/library/queries/online_library_queries.dart`
- 新增：`lib/app/library/online_book_service.dart`
- 新增：`lib/app/providers/online_providers.dart`
- 修改：`pubspec.yaml`（加入 `crypto: ^3.0.6`）
- 测试：`test/domain/library/queries/online_library_queries_test.dart`
- 测试：`test/app/library/online_book_service_test.dart`

**接口：**
- Consumes: `BookSource`、`SourceBookSummary`、`SourceBookInfo`、`SourceToc`、`SourceDiscovery`、`IdGenerator`、`TomeToneDatabase`。
- Produces:
  ```dart
  class OnlineBookStatus {
    const OnlineBookStatus({required this.bookId, required this.onShelf});
    final String bookId;
    final bool onShelf;
  }

  class OnlineBookUpsert {
    const OnlineBookUpsert({
      required this.source,
      required this.summary,
      this.info,
      this.toc,
      this.onShelf = false,
      this.tags = const <String>[],
      this.now,
    });
    final BookSource source;
    final SourceBookSummary summary;
    final SourceBookInfo? info;
    final SourceToc? toc;
    final bool onShelf;
    final List<String> tags;
    final DateTime? now;
  }

  abstract interface class OnlineLibraryQueries {
    Future<String> upsertOnlineBook(OnlineBookUpsert upsert);
    Future<void> setBookShelf(String bookId, {required bool onShelf, List<String> tags = const <String>[]});
    Future<void> saveOnlineMetadata(String bookId, BookMetadataDraft metadata);
    Future<Map<String, OnlineBookStatus>> bookStatuses({required String sourceId, required List<String> bookUrls});
  }
  ```
  `DriftOnlineLibraryQueries` 实现；`OnlineBookService`：
  ```dart
  Future<String> addToShelf({required BookSource source, required SourceBookSummary item, SourceBookInfo? info, SourceToc? toc, required List<String> tags});
  Future<String> startListening({required BookSource source, required SourceBookSummary item, SourceBookInfo? info, SourceToc? toc});
  ```
  `addToShelf` 在缺 `info/toc` 时补抓一次，失败仍允许入库；`startListening` 补抓后仍无章则抛 `OnlineBookNotPlayable`，且不写库。

- [ ] **Step 1: 写失败测试**

`online_library_queries_test.dart`：
- `upsertOnlineBook` 新书：`books` 一行、`on_shelf=false`、`source_type='online'`、`root_path=bookUrl`、一本「正文」卷、每章 `file_path='online/'+sha256(url)`、`source_uri=rawUrl`、VIP 标记保留、标签写入。
- 同一 `(sourceId, bookUrl)` 再次 upsert 复用 `books.id`，不重复卷/章/标签。
- `setBookShelf(true, tags)` 写 `on_shelf` 与标签；`false` 只下架不删书。
- `bookStatuses` 按规范化 bookUrl 返回 `bookId/onShelf`。
- `saveOnlineMetadata` 只写 `book_metadata_overrides`，不碰 `book_sources`/`chapters`。

`online_book_service_test.dart`：
- 预览数据齐全时 `addToShelf` 不调用 discovery。
- info/toc 缺失时补抓；toc 仍失败允许加入但 `lastRefreshOk=false` 且无章。
- `startListening` 在 toc 仍失败时抛错且 `books` 为空。
- 重复 `startListening` 复用 bookId。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/domain/library/queries/online_library_queries_test.dart test/app/library/online_book_service_test.dart`（需许可）
Expected: FAIL，端口/服务不存在。

- [ ] **Step 3: 实现查询与服务**

在事务内：按 `sourceId + bookUrl` 查重；新建 `BooksCompanion`、`VolumesCompanion`、`ChaptersCompanion`；章节 URL 用 `utf8`+`sha256` 生成 `file_path`，`sourceUri` 存 `chapter.rawUrl`；标签用现有 `normalizeTags`。`OnlineBookService` 只负责“缺数据时补抓”和“是否允许播放”，DB 细节留在查询实现。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/domain/library/queries/online_library_queries_test.dart test/app/library/online_book_service_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/domain/library/queries/online_library_queries.dart lib/app/library/online_book_service.dart lib/app/providers/online_providers.dart pubspec.yaml pubspec.lock test/domain/library/queries/online_library_queries_test.dart test/app/library/online_book_service_test.dart
git commit -m "feat(library): upsert online books"
```

---

### Task 4: 在线音频解析（SourceEngine.resolveAudio）

**文件：**
- 修改：`lib/domain/sources/discovery/source_models.dart`
- 修改：`lib/domain/sources/discovery/source_failure.dart`
- 修改：`lib/app/sources/source_engine.dart`
- 修改：`lib/app/sources/source_discovery.dart`
- 修改：`lib/app/sources/legado/legado_source_engine.dart`
- 修改：所有 `implements SourceEngine` / `implements SourceDiscovery` 的测试 fake
- 测试：`test/app/sources/legado_audio_resolve_test.dart`

**接口：**
- Produces:
  ```dart
  class ResolvedAudio {
    const ResolvedAudio({required this.url, this.headers = const <String,String>{}});
    final String url;
    final Map<String, String> headers;
  }

  enum SourceStage { explore, search, bookInfo, toc, audio, test }

  Future<ResolvedAudio> SourceEngine.resolveAudio(
    BookSource source,
    SourceChapter chapter,
  );
  ```
  音频规则只需要章请求的上下文；不要求 `SourceBookInfo`，避免播放前为了签名参数再抓一次详情。设计文档中的 `info` 参数在 M1-C 收敛为不需要。
- `SourceDiscoveryService.resolveAudio` 委托引擎并归一化错误；`LegadoSourceEngine.resolveAudio`：
  - `chapter.isVip == true` 直接抛 `SourceFailureKind.vipRequired`，不发请求。
  - 用 `chapter.rawUrl` 走 `_fetch(stage: audio, rules: ...)`，`ruleContent.content` 从响应 JSON 求值。
  - 结果支持字符串 URL、`{"url": "...", "headers": {...}}`、字符串数组（取第一段）。
  - URL 按响应最终 URL 解析并 `normalizeNetworkUrl`；headers 合并顺序：源 header → 章 URL options headers → 内容 JSON headers，后者覆盖前者。
  - 清理结果首尾空白与成对引号；非法 URL 抛 `rule`。

- [ ] **Step 1: 写失败测试**

`legado_audio_resolve_test.dart`：
- 字符串 URL：相对地址按章响应最终 URL 解析，返回 `AudioSourceRef` 用的绝对 URL。
- JSON map：`headers` 覆盖源 header 与章 options 同名 header。
- 数组：取第一段。
- `isVip=true` 不发请求，抛 `vipRequired`。
- HTTP 403 -> `authRequired`；非法 scheme -> `rule`；响应非 JSON -> `json`。
- 不把 `x-listening-session` 等 header 写进断言失败信息（测试只断言 map，不打印）。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/app/sources/legado_audio_resolve_test.dart`（需许可）
Expected: FAIL，`resolveAudio`/`ResolvedAudio` 不存在。

- [ ] **Step 3: 实现模型、接口与 Legado 解析**

新增 `ResolvedAudio` 和 `SourceStage.audio`；`_fetch` 已支持 JSON/headers，直接复用。为所有 fake 增加 `resolveAudio`，默认 `throw UnimplementedError('测试未配置音频解析')`，需要音频的测试再覆盖。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/app/sources/legado_audio_resolve_test.dart test/app/sources/source_discovery_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/domain/sources/discovery/source_models.dart lib/domain/sources/discovery/source_failure.dart lib/app/sources/source_engine.dart lib/app/sources/source_discovery.dart lib/app/sources/legado/legado_source_engine.dart test/app/sources test/ui/pages/discovery
git commit -m "feat(sources): resolve chapter audio"
```

---

### Task 5: 按章惰性解析的播放队列

**文件：**
- 修改：`lib/app/policy/chapter_sequencer.dart`
- 修改：`lib/app/policy/playback_controller.dart:337-352`
- 修改：`lib/app/playback/queue_builder.dart`
- 测试：`test/app/policy/chapter_sequencer_test.dart`
- 测试：`test/app/policy/playback_controller_test.dart`
- 测试：`test/app/playback/queue_builder_test.dart`

**接口：**
- Produces:
  ```dart
  class QueueChapter {
    const QueueChapter({
      required this.chapterId,
      required this.volumeId,
      required this.title,
      this.source,
      this.resolveSource,
      this.duration,
    });
    final AudioSourceRef? source;
    final Future<AudioSourceRef?> Function()? resolveSource;
    Future<AudioSourceRef?> resolve();
  }
  ```
  构造时 `source != null || resolveSource != null`；`QueueChapter.resolve()` 优先返回 `source`，否则调用 `resolveSource`。
- `PlaybackController._loadChapter` 改为 `final source = await chapter.resolve(); if (source == null) throw const EngineError(code: EngineErrorCode.sourceNotFound); await _engine.load(source);`。
- 本机 `buildPlaybackQueue` 行为不变，继续把解析好的 `source` 放进 `QueueChapter`。

- [ ] **Step 1: 写失败测试**

- `QueueChapter(source: ...)` 的 `resolve()` 返回 source；只给 `resolveSource` 时调用一次并返回。
- 两者都为空抛 `ArgumentError`。
- `PlaybackController.open` 对惰性章调用 resolver；resolver 返回 null 时 `open` 抛 `EngineError(sourceNotFound)`，不调用引擎 load。
- 本机队列构建仍预解析 source（不改变 SAF 缓存副本测试）。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/app/policy/chapter_sequencer_test.dart test/app/policy/playback_controller_test.dart test/app/playback/queue_builder_test.dart`（需许可）
Expected: FAIL，`resolveSource/resolve` 不存在。

- [ ] **Step 3: 实现惰性解析**

按 Interfaces 改 `QueueChapter` 与 `_loadChapter`。`QueueChapter.resolve()` 不做缓存，重复调用允许；缓存命中由上层 resolver 自己决定。

- [ ] **Step 4: 运行测试确认通过**

Run: 同 Step 2（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/app/policy/chapter_sequencer.dart lib/app/policy/playback_controller.dart lib/app/playback/queue_builder.dart test/app/policy test/app/playback
git commit -m "feat(playback): resolve chapter sources lazily"
```

---

### Task 6: 在线播放分流与 OnlineChapterSourceResolver

**文件：**
- 新增：`lib/app/playback/online_chapter_source_resolver.dart`
- 新增：`lib/app/playback/online_queue_builder.dart`
- 修改：`lib/ui/pages/shelf/open_book_action.dart`
- 修改：`lib/app/providers/playback_providers.dart:106-216`
- 修改：`lib/app/providers/source_providers.dart`
- 测试：`test/app/playback/open_book_online_test.dart`
- 测试：`test/app/playback/online_queue_test.dart`

**接口：**
- Consumes: Task 3 `BookSourceQueries`、Task 4 `SourceDiscovery.resolveAudio`、Task 5 `QueueChapter.resolveSource`。
- Produces:
  ```dart
  class OnlineChapterSourceResolver {
    OnlineChapterSourceResolver({required SourceDiscovery discovery});
    Future<AudioSourceRef?> resolve({
      required BookSource source,
      required ChapterView chapter,
    });
  }

  Future<ChapterSequencer> buildOnlinePlaybackQueue({
    required BookDetail detail,
    required BookSource source,
    required OnlineChapterSourceResolver resolver,
  });
  ```
  `bookSourceByIdProvider = FutureProvider.family<BookSource?, String>`。
- `openBookAndShowPlayer` 分支：
  - `book.isOnline`：`sourceId` 为空 → 「这本书缺少来源」；取源失败/`sourceDeleted` → 「来源已删除」；`sourceEnabled=false` → 「来源已停用」；构造 `OnlineChapterSourceResolver` 和在线队列；不读 `libraryRootsProvider`。
  - 本机书保持现有根/resolver/SAF 重试逻辑。
- `openBook` 增加可选 `Future<ChapterSequencer> Function()? buildQueue`；为空时仍走 `buildPlaybackQueue(resolver: ...)`；SAF 重试只在本地 `resolver != null` 时启用。

- [ ] **Step 1: 写失败测试**

`online_queue_test.dart`：
- 只把 active、非 VIP、非 retired 章放进队列；VIP/retired/missing 跳过。
- 每个 `QueueChapter` 的 `resolve()` 调用 `SourceDiscovery.resolveAudio`，返回 `RemoteUrlSource(uri: url, headers: headers)`。
- 音频解析失败返回 null 的章不出现在队列；全部失败 -> 空队列。

`open_book_online_test.dart`：
- 在线书不调用 `mediaSourceResolverForRootProvider`；`openBookAndShowPlayer` 使用在线队列，fake engine 收到远程 URL/headers。
- 来源删除/停用给对应文案，不打开播放台。
- 本机书仍走 `MediaSourceResolver` 与 SAF 重试；回归测试不改原断言。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/app/playback/online_queue_test.dart test/app/playback/open_book_online_test.dart`（需许可）
Expected: FAIL，在线歌队列/分流不存在。

- [ ] **Step 3: 实现在线 resolver 与分流**

`OnlineChapterSourceResolver.resolve` 用 `chapter.sourceUri!` 找 `SourceChapter` 数据（构造 `SourceChapter(index:..., title:..., rawUrl: sourceUri, url: 规范化去 options, isVip:... )`），调用 `discovery.resolveAudio`；返回 `RemoteUrlSource(uri: resolved.url, headers: resolved.headers)`。`buildOnlinePlaybackQueue` 为每章创建 `QueueChapter(resolveSource: ...)`。

- [ ] **Step 4: 运行测试确认通过**

Run: 同 Step 2（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/app/playback/online_chapter_source_resolver.dart lib/app/playback/online_queue_builder.dart lib/ui/pages/shelf/open_book_action.dart lib/app/providers/playback_providers.dart lib/app/providers/source_providers.dart test/app/playback
git commit -m "feat(playback): play online chapters"
```

---

### Task 7: 预览页「加入书架 / 立即收听」

**文件：**
- 新增：`lib/ui/pages/shelf/add_to_shelf_sheet.dart`
- 修改：`lib/ui/pages/discovery/online_book_preview_page.dart`
- 修改：`lib/app/providers/app_providers.dart`（如有 provider 失效）
- 测试：`test/ui/pages/discovery/online_preview_actions_test.dart`

**接口：**
- Consumes: Task 3 `OnlineBookService`、`onlineBookServiceProvider`、`LibraryQueries.listBookTags`。
- Produces:
  ```dart
  Future<Set<String>?> showAddToShelfSheet(BuildContext context, {required String bookTitle});
  ```
  返回 `null` = 取消；空集合 = 未分类；集合 = 选中的标签（含新建标签）。
- `OnlineBookPreviewPage` 保存 `SourceBookInfo? _info` / `SourceToc? _toc`；底部按钮：
  - `OutlinedButton 加入书架` -> 打开分类弹层 -> `addToShelf` -> `ref.invalidate(booksProvider)` -> `Navigator.pushReplacement(BookDetailPage(bookId))`。
  - `FilledButton 立即收听` -> `startListening` -> 读 `bookDetailProvider(id).future` -> `openBookAndShowPlayer`；失败用 SnackBar，保持预览页。

- [ ] **Step 1: 写失败测试**

`online_preview_actions_test.dart`：
- 打开预览不写 `books/chapters/book_tags`（M1-B 已有断言，继续保留）。
- 点「加入书架」弹出分类 chips；选两个已有标签 + 新建一个 -> `on_shelf=true`，`book_tags` 三行，预览页被详情页替换。
- 点「立即收听」-> `books=1`、`chapters=N`，fake playback engine 收到在线源，播放台可见。
- 目录抓取失败：加入书架仍成功（书存在、目录为空）；立即收听失败且不写库。
- 同一本书再次加入复用 bookId，不重复标签。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/pages/discovery/online_preview_actions_test.dart`（需许可）
Expected: FAIL，预览页没有按钮/服务不存在。

- [ ] **Step 3: 实现弹层与动作**

分类弹层用 `FilterChip` 多选、搜索过滤、`TextField` + 「新建分类」；保存按钮文案「保存」。动作期间禁用按钮并显示进度，防重复点击。在线书库详情使用 `BookDetailPage`。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/ui/pages/discovery/online_preview_actions_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/ui/pages/shelf/add_to_shelf_sheet.dart lib/ui/pages/discovery/online_book_preview_page.dart test/ui/pages/discovery/online_preview_actions_test.dart
git commit -m "feat(discovery): add online book actions"
```

---

### Task 8: 在线书详情入库态

**文件：**
- 修改：`lib/ui/pages/shelf/book_detail_page.dart`
- 修改：`lib/ui/pages/shelf/chapter_list_sheet.dart`
- 修改：`lib/ui/pages/shelf/book_metadata_sheet.dart`
- 修改：`lib/app/library/book_metadata_service.dart`（`saveOnline`）
- 修改：`lib/app/providers/metadata_providers.dart`（如需要）
- 测试：`test/ui/book_detail_online_test.dart`
- 测试：`test/ui/chapter_list_sheet_test.dart`（如存在则扩展）

**接口：**
- Consumes: Task 1 `BookSummary.isOnline/coverUrl/onShelf/sourceName/sourceEnabled/sourceDeleted`、Task 3 `OnlineLibraryQueries.setBookShelf/saveOnlineMetadata`、`bookSourceByIdProvider`。
- Produces:
  - `BookMetadataService.saveOnline({required BookSummary book, required BookMetadataDraft draft})`：只写覆盖层，不读 `rootUri`，返回 `sidecarStatus=unsupported`。
  - `showBookMetadataSheet(..., required String? rootUri, bool online = false)`；`rootUri == null && online == true` 时走 `saveOnline`，并提示「已保存到应用内」。
  - 在线详情主操作：未上架显示「加入书架」「立即收听」；已上架显示「继续收听/开始收听」+「移出书架」；`移出书架` 调 `setBookShelf(false)` 并刷新详情/书架。
  - 在线详情 `⋮` 只有「编辑信息」；不显示「从书根重新导入」。
  - 章节目录 active 章正常点播；`isVip` 显示锁并禁用；`retiredChapters` 收进「已下架 N 章」可展开分组，不进入播放队列。
  - 在线封面用 `NetworkCover(coverUrl: book.coverUrl, headers: source.header)`。

- [ ] **Step 1: 写失败测试**

`book_detail_online_test.dart`：
- 在线书显示网络封面、来源名、`来源正常/已停用/已删除`。
- 未上架显示两个主操作；点击加入书架写 `on_shelf=true` 和标签。
- 已上架显示「继续收听」与「移出书架」；移出后书架 provider 失效、书库仍在。
- 在线详情菜单只有「编辑信息」；保存只写覆盖层，不写 sidecar。
- VIP 章禁用并显示锁；retired 章在「已下架」分组，不进入队列。
- 320dp + 2.0 + 深色无 overflow。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/book_detail_online_test.dart`（需许可）
Expected: FAIL，详情页仍按本机分支/无在线操作。

- [ ] **Step 3: 实现在线分支**

在 `BookDetailPage` 读取 `BookSource?`；`_BookDetailBody` 增加 `isOnline` 与 `source` 参数。主按钮/菜单按状态分支。在线「立即收听」在 `detail.chapters` 为空时先调 `OnlineBookService.startListening` 补抓目录，仍失败则不打开播放台。`BookMetadataSheet` 增加 online 保存路径。`ChapterListSheet` 扩展 `_SheetEntry.retiredHeader` 与 retired 章分组；VIP 章 `onTap=null` 并用 `Icons.lock_outline`。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/ui/book_detail_online_test.dart test/ui/book_metadata_sheet_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/ui/pages/shelf/book_detail_page.dart lib/ui/pages/shelf/chapter_list_sheet.dart lib/ui/pages/shelf/book_metadata_sheet.dart lib/app/library/book_metadata_service.dart lib/app/providers/metadata_providers.dart test/ui/book_detail_online_test.dart test/ui/book_metadata_sheet_test.dart
git commit -m "feat(library): add online book detail"
```

---

### Task 9: 来源管理页接管本机根

**文件：**
- 新增：`lib/ui/pages/library/local_roots_section.dart`
- 修改：`lib/ui/pages/sources/source_management_page.dart`
- 修改：`lib/ui/pages/library/library_page.dart`（暂时保留旧根逻辑，Task 10 再移除）
- 测试：`test/ui/pages/sources/source_management_local_roots_test.dart`
- 修改：`test/ui/pages/sources/source_management_page_test.dart`

**接口：**
- Consumes: 现有 `LibraryRootCard`、`LibraryAddRootSheet`、`showRenameRootDialog`、`showRemoveRootDialog`、`libraryRootServiceProvider`、`libraryScanProvider`、`LibraryRemovalImpact`。
- Produces:
  ```dart
  class LocalRootsSection extends ConsumerStatefulWidget {
    const LocalRootsSection({super.key});
  }
  ```
  该 widget 负责：读取 `libraryRootsProvider`、渲染 `LibraryRootCard`、添加/重命名/移除/扫描、显示一次性 notice。复用 `LibraryRootsKeys`。
- `SourceManagementPage` 改为 `ListView`：
  - 顶部「网络书源」：现有源卡片、启用/测试/编辑/删除/导入。
  - 分隔与标题「本机目录」：`LocalRootsSection`。
  - `SourceManagementKeys.addButtonKey` 仍只打开书源导入；本机目录添加按钮由 `LocalRootsSection` 提供。

- [ ] **Step 1: 写失败测试**

`source_management_local_roots_test.dart`：
- 来源管理页显示本机目录空态；点「添加本机目录」打开现有添加弹层，返回后刷新列表。
- 重命名/移除/扫描沿用现有 `library_page_test` 的关键断言（可搬迁原测试）。
- 网络书源和本机目录可同时显示；在线源为空时仍有本机目录。
- 320dp + 2.0 + 深色无 overflow。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/pages/sources/source_management_local_roots_test.dart test/ui/pages/sources/source_management_page_test.dart`（需许可）
Expected: FAIL，来源管理页没有本机目录。

- [ ] **Step 3: 抽取并嵌入本机根管理**

把 `LibraryPage` 的 `_openAddRootSheet` / `_renameRoot` / `_removeRoot` / `_scan` / `_notice` 逻辑迁到 `LocalRootsSection`。`SourceManagementPage` 使用 `CustomScrollView` 或 `ListView` 组合两个 section；保持 `SourceManagementKeys` 原有键。

- [ ] **Step 4: 运行测试确认通过**

Run: 同 Step 2（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/ui/pages/library/local_roots_section.dart lib/ui/pages/sources/source_management_page.dart test/ui/pages/sources
git commit -m "feat(sources): manage local roots in source page"
```

---

### Task 10: 书库统一书目列表

**文件：**
- 新增：`lib/ui/pages/library/library_book_row.dart`
- 新增：`lib/ui/pages/library/library_filter.dart`
- 修改：`lib/ui/pages/library/library_page.dart`
- 复用：`lib/ui/pages/shelf/shelf_filter.dart` 的 `ShelfStatusFilter`
- 测试：`test/ui/library_unified_page_test.dart`
- 修改：`test/ui/library_page_test.dart`（移除/迁移根管理断言）
- 修改：`test/ui/app_smoke_test.dart`

**接口：**
- Consumes: `booksProvider`（全部书）、Task 1 `BookSummary` 在线字段、`shelfBooksProvider`、`localRootsSection` 入口、`LibraryRootsKeys`。
- Produces:
  ```dart
  enum LibrarySourceFilter { all, local, online }
  class LibraryFilterState {
    const LibraryFilterState({this.source = LibrarySourceFilter.all, this.query = '', this.tag, this.status = ShelfStatusFilter.all});
    LibraryFilterState copyWith(...);
    List<BookSummary> apply(List<BookSummary> books);
  }
  ```
  `LibraryBookRow`：封面（本地/网络）、书名、作者/演播、来源标签、标签、进度、缺失/来源不可用标记；点击进入 `BookDetailPage`。
- `LibraryPage`：
  - 页首「我的书库」+ 总数/本地数/在线数；右侧搜索、来源管理。
  - `全部 / 本地 / 在线` chips；分类下拉；状态下拉；搜索框。
  - 空态：无书且无来源 -> 「还没有书」+「导入书源」「添加本机目录」；有来源无书 -> 「去发现找书」。
  - 不再显示本机根卡片；来源管理页负责根管理。

- [ ] **Step 1: 写失败测试**

`library_unified_page_test.dart`：
- 本地 + 在线书混排；在线书在库但 `onShelf=false` 仍显示；书架不显示。
- 来源 chips 过滤本地/在线；搜索匹配书名/作者/演播/简介/标签；分类下拉过滤。
- 来源已停用/已删除显示标记；目录待刷新显示 `目录待刷新`。
- 无书无来源显示两个入口；有来源无书显示「去发现找书」。
- 点击行进入详情；320dp + 2.0 + 深色无 overflow。
- 更新 `app_smoke_test`：书库页不再显示「还没有书库根」，改由来源管理页测试本机根。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/library_unified_page_test.dart test/ui/app_smoke_test.dart`（需许可）
Expected: FAIL，书库页仍是根卡片。

- [ ] **Step 3: 实现统一列表与筛选**

`LibraryPage` watch `booksProvider`；用 `LibraryFilterState` 做内存筛选；`LibraryBookRow` 按 `book.isOnline` 选封面。移除根卡片相关代码，保留来源管理入口；空态按钮跳发现/打开来源管理。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/ui/library_unified_page_test.dart test/ui/app_smoke_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/ui/pages/library/library_book_row.dart lib/ui/pages/library/library_filter.dart lib/ui/pages/library/library_page.dart test/ui/library_unified_page_test.dart test/ui/library_page_test.dart test/ui/app_smoke_test.dart
git commit -m "feat(library): unify local and online books"
```

---

### Task 11: 发现结果加入状态

**文件：**
- 修改：`lib/ui/pages/discovery/discovery_result_tile.dart`
- 修改：`lib/ui/pages/discovery/discovery_page.dart`
- 测试：`test/ui/pages/discovery/discovery_membership_test.dart`
- 修改：`test/ui/pages/discovery/discovery_search_test.dart`

**接口：**
- Consumes: Task 3 `OnlineLibraryQueries.bookStatuses`、`onlineLibraryQueriesProvider`。
- Produces:
  - `DiscoveryPage` 在首屏/翻页/搜索成功并 setState 后，调用 `bookStatuses(sourceId, items.map(bookUrl))`，保存 `Map<String, OnlineBookStatus> _statuses`。
  - 返回预览/详情后重新查询当前项状态。
  - `DiscoveryResultTile` 增加 `OnlineBookStatus? membership`；显示「已在书架」/「已在书库」chip；仍**不**显示加入按钮。

- [ ] **Step 1: 写失败测试**

- 搜索结果中 bookUrl 命中 `onShelf=true` 显示「已在书架」；命中 `onShelf=false` 显示「已在书库」；未命中不显示。
- 加入书架后返回发现页，状态从无变「已在书架」。
- 分页新增项也查询状态；旧页状态不丢。
- 320dp + 2.0 + 深色结果行不溢出。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/ui/pages/discovery/discovery_membership_test.dart`（需许可）
Expected: FAIL，结果行没有状态 chip。

- [ ] **Step 3: 实现状态加载与展示**

在 `_loadFirstPage`/`_loadMore` 成功后调用状态查询；用 `_generation` 丢弃过期状态。状态查询失败静默（不影响结果展示），不写源健康。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/ui/pages/discovery/discovery_membership_test.dart test/ui/pages/discovery/discovery_search_test.dart`（需许可）
Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/ui/pages/discovery/discovery_result_tile.dart lib/ui/pages/discovery/discovery_page.dart test/ui/pages/discovery
git commit -m "feat(discovery): show online book membership"
```

---

### Task 12: 端到端夹具与全量门禁

**文件：**
- 新增：`test/fixtures/sources/tingyou/play.json`
- 新增：`test/app/library/online_m1c_fixture_test.dart`
- 修改：`test/fixtures/sources/tingyou/source_m1b.json`（仅补 `ruleContent` 对应夹具说明，如已存在则不动）
- 修改：`README.md`（如已有 M1 状态段落则补一句）
- 不提交：`.superpowers/sdd/2026-10-21-online-library-playback/progress.md`

- [ ] **Step 1: 写端到端失败测试**

`online_m1c_fixture_test.dart` 用真实内存 DB + fake `SourceDiscovery` + fake `PlaybackEngine`：
- 预览 -> 加入书架选标签 -> 书架出现、书库出现、`on_shelf=true`。
- 立即收听 -> 生成 `books/chapters`，fake engine 收到 `RemoteUrlSource`，headers 合并正确。
- 同一本重复加入 -> `books` 仍 1 行，章不重复。
- 打开详情不写库的回归断言保留。
- 来源停用/删除的详情文案与播放拒绝。
- 不在测试中访问真实站点、真实音频 URL 或真实 session。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/app/library/online_m1c_fixture_test.dart`（需许可）
Expected: FAIL，端到端链路尚未接通。

- [ ] **Step 3: 补齐夹具与装配**

新增 `play.json`，例如：
```json
{
  "play_url": "/audio/1.mp3",
  "headers": { "X-Audio": "test-audio" }
}
```
只使用假 `test-session`。在测试里按章节路径路由到该夹具，不请求真实域名。

- [ ] **Step 4: 全量门禁（每步先取得许可）**

```bash
flutter analyze
flutter test
dart run tool/ci/check_import_boundaries.dart
flutter build apk --debug
```

Expected: analyze 无问题；全量测试通过（基线 759，按新增测试数增长）；依赖方向门禁通过；APK 构建成功。记录 APK 体积。

- [ ] **Step 5: 手工冒烟**

1. 导入 M1-B 的本地 HTTP 书源。
2. 发现 -> 搜索/分类 -> 详情预览，确认不写库。
3. 加入书架选分类 -> 书架出现；书库出现；`on_shelf` 正确。
4. 立即收听 -> 播放台打开、音频请求带源 headers；切章。
5. 停用来源 -> 未缓存章节提示「来源不可用」；已入库书仍在书库。
6. 320dp + 2.0 + 深色走发现、详情、书架、书库。
7. 用内存库测试确认打开详情前后 `books/chapters/progress` 不增加。

- [ ] **Step 6: 提交**

```bash
git add test/fixtures/sources/tingyou/play.json test/app/library/online_m1c_fixture_test.dart README.md
git commit -m "test(library): cover online playback flow"
```

---

## 验收清单

- [ ] 预览页「加入书架」可选多个已有/新建分类，保存后 `on_shelf=true`，书架出现。
- [ ] 预览页「立即收听」入库并打开播放台；目录失败时不允许播放，不留下幽灵书。
- [ ] 同一 `(source_id, 规范化 bookUrl)` 重复加入/播放复用 `books.id`，章与标签不重复。
- [ ] 在线播放按章解析音频 URL，headers 合并正确，不持久化解析后的音频 URL。
- [ ] 在线书不走本机根 resolver；本机书 SAF/本地播放行为不变。
- [ ] 书架只显示 `on_shelf=true`；书库显示全部本地+在线书。
- [ ] 书库支持来源筛选、搜索、分类/状态筛选、来源不可用标记。
- [ ] 本机根管理可从来源管理页完成，书库页不再显示根卡片。
- [ ] 发现结果只显示「已在书架/已在书库」，不显示加入按钮。
- [ ] 320dp、2.0 字号、深色模式无 overflow。
- [ ] 无真实站点、真实会话、真实音频 URL 进入测试/仓库。
- [ ] `flutter analyze`、`flutter test`、依赖方向门禁、debug APK 全部通过。

---

## 已知限制 / 后续

- 本计划不做刷新信息/目录、换源、从书库删除、来源删除；这些在 M1-D。
- 本计划不做预下载、缓存 LRU、仅 Wi-Fi、缓存上限与清理；`audio_cache_entries` / `app_settings` 表留给 M1-D 接入。
- 本计划只支持单段音频；HLS 仅作为普通 URL 交给引擎，多段拼接留给 M2。
- 章节级 URL options 通过 `source_uri` 原值保留；M1-D 做缓存哈希时必须使用同一原值，避免签名变化误命中。
- 在线书元数据编辑只写覆盖层；不写书根 sidecar（在线书没有本地书根）。
- 首次启用网络书源的一次性访问说明（设计 §12 的 `source_consent_v1`）仍由 M1-B 的导入 HTTP 警告承担；完整的 app_settings 持久化与原生 consent 流程和 M1-D 一起补。

