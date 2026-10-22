# TomeTone 在线听书源 M1-D 实施计划：刷新、换源、预下载缓存与删除护栏

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 TomeTone 在线听书源 M1-D 里程碑：换源底部抽屉与智能对齐、单本与批量非阻塞刷新、静默预下载与 LRU 音频缓存池、分级安全删除护栏，全面提升听书流畅度与现代视觉美感。

**Architecture:** 严格遵循 TomeTone 分层架构。在 contracts/network 定义网络状态感知契约；在 domain/audio 实现音频沙盒 LRU 缓存仓储与预载调度器；在 application/sources 拓展 OnlineBookService 换源事务与两阶段批量刷新编排；在 UI 层提供 Material 3 沉浸式换源抽屉、书库呼吸刷新胶囊、双层缓冲进度条、设置页缓存卡片及防误删弹窗。

**Tech Stack:** Flutter / Dart, Drift (SQLite), Just Audio, Riverpod, Connectivity Plus, Crypto (SHA-256).

**Spec:** `docs/superpowers/specs/2026-10-22-online-m1d-refresh-switch-cache-design.md`

## Global Constraints

- 严格遵循《架构需求文档》的依赖方向：UI -> Application -> Domain -> Contracts；Domain 与 Contracts 严禁反向依赖 UI 或 Flutter SDK。
- 保证离线单测能力：测试中使用 `NativeDatabase.memory()` 与 Mock 对象，纯 Dart 运行，不依赖真实设备网络或外部服务。
- 视觉与可用性：所有新卡片与弹窗必须在 320dp 紧凑窄屏、深色模式与系统 2.0 大字号下自适应且无 RenderFlex 溢出。
- 数据安全铁律：严禁因刷新或换源静默丢失播放进度、书签或手动元数据；严禁在删除操作中默认勾选对本地物理音频文件的删除；SAF 根目录禁用应用内物理删除。

## Review Focus

1. **换源回换原源的唯一键冲突**：当用户从源 A 换到源 B 再换回源 A 时，旧章已存在于数据库中；测试必须证明章节写入采用 upsert 语义，重新激活 `retired = false` 而不抛出 `chapters_binding_unique` 异常。（覆盖于 Task 5）
2. **分页目录中途中断的防丢保护**：当 `nextTocUrl` 抓取到第 2 页失败时（`complete == false`），测试必须证明数据库绝不把消失的章打上 `retired = true` 或 `missing = true`，完好保留原有目录。（覆盖于 Task 4）
3. **未映射成功时的进度防覆盖保护**：换源未能对齐章节时，测试必须证明原 `playback_progress` 完好保留在旧章上，新播放器保持暂停并锁定，防止 10 秒定时器静默写入新源第 1 章覆盖进度。（覆盖于 Task 5）
4. **预下载与当前流式不竞争**：当播放某章且触发预下载时，测试必须证明预下载器只针对未来章节（N+1..N+3）发起后台拉取，当前正在播放的章节保持流式直连，绝不发起双重并发下载。（覆盖于 Task 3）
5. **本地书根目录物理删除防误穿透**：当本地书的 `root_path` 为空或等于根目录时，测试必须证明删除对话框强制禁用「同时删除本地音频目录」复选框，杜绝用户磁盘整库误删。（覆盖于 Task 10）

---

### Task 1: 网络状态感知基础设施 (`NetworkMonitor`)

**Files:**
- Create: `lib/contracts/network/network_monitor.dart`
- Create: `lib/modules/network/network_monitor_impl.dart`
- Create: `test/contracts/network/network_monitor_test.dart`
- Modify: `pubspec.yaml`
- Modify: `lib/app/providers.dart`

**Interfaces:**
- Produces: `abstract class NetworkMonitor { Stream<bool> get isWifiConnectedStream; Future<bool> get isWifiConnected; }`
- Produces: `final networkMonitorProvider = Provider<NetworkMonitor>(...)`

- [ ] **Step 1: Write the failing test for `NetworkMonitor` contract and mock**

```dart
// test/contracts/network/network_monitor_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/network/network_monitor.dart';

class TestNetworkMonitor implements NetworkMonitor {
  final _controller = StreamController<bool>.broadcast();
  bool _current = true;

  @override
  Stream<bool> get isWifiConnectedStream => _controller.stream;

  @override
  Future<bool> get isWifiConnected async => _current;

  void emit(bool isWifi) {
    _current = isWifi;
    _controller.add(isWifi);
  }

  void dispose() => _controller.close();
}

void main() {
  test('NetworkMonitor mock reports wifi state and emits changes', () async {
    final monitor = TestNetworkMonitor();
    expect(await monitor.isWifiConnected, isTrue);

    final emitted = <bool>[];
    final sub = monitor.isWifiConnectedStream.listen(emitted.add);

    monitor.emit(false);
    monitor.emit(true);
    await pumpEventQueue();

    expect(emitted, [false, true]);
    expect(await monitor.isWifiConnected, isTrue);
    await sub.cancel();
    monitor.dispose();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/contracts/network/network_monitor_test.dart`
Expected: FAIL with "Target of URI doesn't exist: 'package:tometone/contracts/network/network_monitor.dart'"

- [ ] **Step 3: Add `connectivity_plus` to `pubspec.yaml` and implement `NetworkMonitor`**

Add `connectivity_plus: ^6.1.1` to dependencies.
Create `lib/contracts/network/network_monitor.dart` with pure Dart interface.
Create `lib/modules/network/network_monitor_impl.dart` mapping `ConnectivityResult.wifi` to `bool`.
Expose `networkMonitorProvider` in `lib/app/providers.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/contracts/network/network_monitor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/contracts/network/ lib/modules/network/ lib/app/providers.dart test/contracts/network/
git commit -m "feat(network): introduce NetworkMonitor contract and connectivity_plus implementation"
```

---

### Task 2: 沙盒音频缓存仓储与 LRU 淘汰 (`AudioCacheRepository`)

**Files:**
- Create: `lib/domain/audio/audio_cache_repository.dart`
- Create: `lib/modules/audio/audio_cache_repository_impl.dart`
- Test: `test/domain/audio/audio_cache_repository_test.dart`
- Modify: `lib/app/providers.dart`

**Interfaces:**
- Produces: `abstract class AudioCacheRepository { Future<File?> getCachedAudioFile(String bookId, String chapterId); Future<File> saveAudioCache(String bookId, String chapterId, List<int> bytes); Future<void> clearBookCache(String bookId); Future<int> getTotalCacheSize(); Future<void> enforceCacheLimit({required int maxBytes, Set<String> activeChapterKeys}); Future<void> clearAllCache(); }`

- [ ] **Step 1: Write the failing test for `AudioCacheRepository`**

```dart
// test/domain/audio/audio_cache_repository_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/modules/audio/audio_cache_repository_impl.dart';

void main() {
  late Directory tempDir;
  late AudioCacheRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tometone_audio_cache_test_');
    repository = AudioCacheRepositoryImpl(cacheRoot: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saves and retrieves cached audio file', () async {
    final file = await repository.saveAudioCache('book_1', 'ch_1', [1, 2, 3, 4]);
    expect(await file.exists(), isTrue);

    final cached = await repository.getCachedAudioFile('book_1', 'ch_1');
    expect(cached, isNotNull);
    expect(await cached!.readAsBytes(), [1, 2, 3, 4]);
  });

  test('clearBookCache removes all files for given book', () async {
    await repository.saveAudioCache('book_1', 'ch_1', [1, 2]);
    await repository.saveAudioCache('book_1', 'ch_2', [3, 4]);
    await repository.saveAudioCache('book_2', 'ch_1', [5, 6]);

    await repository.clearBookCache('book_1');

    expect(await repository.getCachedAudioFile('book_1', 'ch_1'), isNull);
    expect(await repository.getCachedAudioFile('book_1', 'ch_2'), isNull);
    expect(await repository.getCachedAudioFile('book_2', 'ch_1'), isNotNull);
  });

  test('enforceCacheLimit evicts oldest unreserved files down to 85% water mark', () async {
    final f1 = await repository.saveAudioCache('b1', 'c1', List.filled(500, 1));
    await Future.delayed(const Duration(milliseconds: 20));
    final f2 = await repository.saveAudioCache('b1', 'c2', List.filled(500, 2));
    await Future.delayed(const Duration(milliseconds: 20));
    final f3 = await repository.saveAudioCache('b1', 'c3', List.filled(500, 3));

    // Total = 1500 bytes. Limit = 1000 bytes. Target = 850 bytes.
    // c1 is oldest, should be deleted first.
    await repository.enforceCacheLimit(maxBytes: 1000, activeChapterKeys: {'b1:c2'});

    expect(await repository.getCachedAudioFile('b1', 'c1'), isNull);
    expect(await repository.getCachedAudioFile('b1', 'c2'), isNotNull);
    expect(await repository.getCachedAudioFile('b1', 'c3'), isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/audio/audio_cache_repository_test.dart`
Expected: FAIL with compilation errors (classes not found).

- [ ] **Step 3: Implement `AudioCacheRepository` and `AudioCacheRepositoryImpl`**

Create `lib/domain/audio/audio_cache_repository.dart` declaring the abstract contract.
Create `lib/modules/audio/audio_cache_repository_impl.dart` storing audio under `<cacheRoot>/audio_preload/<bookId>/<chapterId>.audio`.
Track `lastModified` and file sizes for LRU ordering.
Provide Riverpod provider `audioCacheRepositoryProvider`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/audio/audio_cache_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/ lib/modules/audio/ lib/app/providers.dart test/domain/audio/
git commit -m "feat(audio): implement AudioCacheRepository with LRU eviction and clear semantics"
```

---

### Task 3: 智能预下载调度器 (`AudioPreloadManager`) 与解析器本地命中

**Files:**
- Create: `lib/app/playback/audio_preload_manager.dart`
- Modify: `lib/app/playback/online_chapter_source_resolver.dart`
- Test: `test/app/playback/audio_preload_manager_test.dart`
- Test: `test/app/playback/online_chapter_source_resolver_test.dart`

**Interfaces:**
- Consumes: `NetworkMonitor`, `AudioCacheRepository`, `SourceEngine`
- Produces: `class AudioPreloadManager { void onPlaybackPositionUpdate({required String bookId, required String currentChapterId, required double progress, required List<ChapterView> upcomingChapters}); Future<void> cancelAll(); }`

- [ ] **Step 1: Write the failing test for `AudioPreloadManager`**

```dart
// test/app/playback/audio_preload_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/playback/audio_preload_manager.dart';
// mock network monitor & mock audio cache
```
Verify:
1. When `progress < 0.5`, no preload triggered.
2. When `progress >= 0.5` and `isWifi == false` (with wifiOnly=true), preload skipped.
3. When `progress >= 0.5` and `isWifi == true`, preloads exactly N upcoming chapters (default N=3).
4. Review Focus 4: Currently playing chapter is NEVER preloaded in the background.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/playback/audio_preload_manager_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `AudioPreloadManager` and update `OnlineChapterSourceResolver`**

In `OnlineChapterSourceResolver.resolve(...)`:
Check `audioCacheRepository.getCachedAudioFile(book.id, chapter.id)`. If exists and size > 0, return `file://${file.path}` directly.
Otherwise resolve audio URL from `SourceEngine`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/app/playback/audio_preload_manager_test.dart test/app/playback/online_chapter_source_resolver_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/app/playback/ test/app/playback/
git commit -m "feat(playback): implement AudioPreloadManager and local cache resolution"
```

---

### Task 4: 单本信息与目录防丢刷新 (`OnlineBookService.refreshBook*`)

**Files:**
- Modify: `lib/domain/library/online_book_service.dart`
- Modify: `lib/domain/library/queries/online_library_queries.dart`
- Modify: `lib/data/drift/drift_online_library_queries.dart`
- Test: `test/domain/library/online_book_service_refresh_test.dart`

**Interfaces:**
- Produces: `Future<void> refreshBookInfo(String bookId)`
- Produces: `Future<TocRefreshResult> refreshBookToc(String bookId)`
- Produces: `class TocRefreshResult { final bool isComplete; final int newChaptersCount; final int updatedChaptersCount; final String? error; }`

- [ ] **Step 1: Write the failing test for single-book refresh and partial failure protection**

```dart
// test/domain/library/online_book_service_refresh_test.dart
// Verify:
// 1. refreshBookInfo updates metadata but preserves book_metadata_overrides.
// 2. refreshBookToc follows nextTocUrl up to 50 pages; on complete==true, missing chapters become retired=true, missing=true.
// 3. Review Focus 2: When nextTocUrl fails mid-way (complete==false), existing chapters are NEVER marked retired/missing, status records partial refresh.
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/library/online_book_service_refresh_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `refreshBookInfo` and `refreshBookToc` in `OnlineBookService`**

Implement TOC paging loop with URL cycle detection and 50-page ceiling.
On `complete == true`: mark missing active chapters `retired = true, missing = true`.
On `complete == false`: only upsert new chapters, keep old active chapters untouched, write `books.last_refresh_ok = false` and desensitized error summary.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/library/online_book_service_refresh_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/library/ lib/data/drift/ test/domain/library/
git commit -m "feat(library): add book info and toc refresh with partial failure protection"
```

---

### Task 5: 在线书平滑换源与章节对齐事务 (`OnlineBookService.switchSource`)

**Files:**
- Modify: `lib/domain/library/online_book_service.dart`
- Modify: `lib/domain/library/queries/online_library_queries.dart`
- Modify: `lib/data/drift/drift_online_library_queries.dart`
- Test: `test/domain/library/online_book_service_switch_source_test.dart`

**Interfaces:**
- Produces: `Future<SwitchSourceResult> switchSource({required String bookId, required String targetSourceId, required String targetBookUrl, String? targetChapterId})`
- Produces: `class SwitchSourceResult { final bool isProgressMapped; final String currentChapterId; final int totalChapters; }`

- [ ] **Step 1: Write the failing test for switch source**

```dart
// test/domain/library/online_book_service_switch_source_test.dart
// Verify:
// 1. Source switch preserves bookId, category, tags, and custom metadata.
// 2. Old chapters are retired (retired=true).
// 3. Chapter title/number alignment maps progress to matching new chapter.
// 4. Review Focus 1: Switching A -> B -> A uses upsert, reactivating retired chapters without violating chapters_binding_unique.
// 5. Review Focus 3: When alignment fails, original progress row is preserved pointing to old chapter, player locked from overwriting.
// 6. Old book audio cache is evicted via AudioCacheRepository.clearBookCache(bookId).
// 7. Blocks merging if target source already contains another book with same title.
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/library/online_book_service_switch_source_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `switchSource` in `OnlineBookService` & Drift queries**

Implement `insertOrUpdate` for chapters with conflict on `(library_root_id, file_path)`.
Preserve progress and trigger `audioCacheRepository.clearBookCache(bookId)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/library/online_book_service_switch_source_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/library/ lib/data/drift/ test/domain/library/
git commit -m "feat(sources): implement atomic switchSource with upsert reactivation and progress protection"
```

---

### Task 6: 书库两阶段非阻塞批量刷新控制器 (`BatchRefreshController`)

**Files:**
- Create: `lib/app/library/batch_refresh_controller.dart`
- Test: `test/app/library/batch_refresh_controller_test.dart`
- Modify: `lib/app/providers.dart`

**Interfaces:**
- Produces: `class BatchRefreshController extends StateNotifier<BatchRefreshState> { Future<void> startBatchRefresh(); void dismiss(); }`
- Produces: `class BatchRefreshState { final bool isRunning; final int totalBooks; final int completedBooks; final int updatedBooks; final int failedBooks; }`

- [ ] **Step 1: Write the failing test for `BatchRefreshController`**

```dart
// test/app/library/batch_refresh_controller_test.dart
// Verify:
// 1. Only on-shelf online books with enabled sources are targeted.
// 2. Two-stage check: Phase 1 checks latestChapterTitle; Phase 2 crawls TOC only if changed.
// 3. State stream updates completedBooks and reports summary on completion.
// 4. Concurrency bounded (max 3 concurrent requests).
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/library/batch_refresh_controller_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `BatchRefreshController`**

Query `shelfBooksProvider` filtering online & enabled.
Implement bounded concurrency queue (`Future.wait` chunks or pool).
Update `BatchRefreshState`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/library/batch_refresh_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/app/library/ lib/app/providers.dart test/app/library/
git commit -m "feat(library): implement two-stage BatchRefreshController with bounded concurrency"
```

---

### Task 7: 换源底部抽屉组件 (`SwitchSourceSheet`) 与独立试听播放器

**Files:**
- Create: `lib/ui/pages/library/switch_source_sheet.dart`
- Create: `lib/ui/pages/library/preview_audio_player.dart`
- Test: `test/ui/pages/library/switch_source_sheet_test.dart`

**Interfaces:**
- Consumes: `SourceEngine`, `OnlineBookService`, `PlaybackController`
- Produces: `Future<bool?> showSwitchSourceSheet(BuildContext context, {required BookSummary book, required ChapterView currentChapter})`

- [ ] **Step 1: Write the failing widget test for `SwitchSourceSheet`**

```dart
// test/ui/pages/library/switch_source_sheet_test.dart
// Verify:
// 1. Displays candidate sources returned from parallel search.
// 2. Candidate card shows latency, health badge, and probe alignment badge when selected.
// 3. Preview audio button pauses main player and plays ephemeral preview audio.
// 4. Closing sheet disposes preview audio player cleanly.
// 5. 320dp narrow layout and dark theme render without overflow.
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/pages/library/switch_source_sheet_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `SwitchSourceSheet` and `PreviewAudioPlayer`**

Build Material 3 BottomSheet (height 60%~75%).
Cards with status chips and preview button.
Call `OnlineBookService.switchSource` on confirm.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/pages/library/switch_source_sheet_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/pages/library/ test/ui/pages/library/
git commit -m "feat(ui): implement SwitchSourceSheet with ephemeral preview player and alignment badges"
```

---

### Task 8: 书库顶部呼吸刷新胶囊 (`LibraryRefreshCapsule`) 与书库接线

**Files:**
- Create: `lib/ui/pages/library/library_refresh_capsule.dart`
- Modify: `lib/ui/pages/library/library_page.dart`
- Test: `test/ui/pages/library/library_refresh_capsule_test.dart`

**Interfaces:**
- Consumes: `batchRefreshControllerProvider`
- Produces: `class LibraryRefreshCapsule extends ConsumerWidget`

- [ ] **Step 1: Write the failing test for `LibraryRefreshCapsule`**

```dart
// test/ui/pages/library/library_refresh_capsule_test.dart
// Verify:
// 1. Hidden when isRunning == false and no recent completion message.
// 2. Displays pulsing indicator and progress text "正在检查 3/8 本在线书更新...".
// 3. Shows dismissible summary capsule on completion ("✓ 2 本书发现新章节").
// 4. 320dp width renders cleanly.
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/pages/library/library_refresh_capsule_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `LibraryRefreshCapsule` and wire into `LibraryPage`**

Insert capsule below AppBar in `LibraryPage`.
Connect top refresh action button to `batchRefreshController.startBatchRefresh()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/pages/library/library_refresh_capsule_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/pages/library/ test/ui/pages/library/
git commit -m "feat(ui): add LibraryRefreshCapsule and integrate non-blocking refresh into LibraryPage"
```

---

### Task 9: 播放器双层流式缓冲轨道与设置页缓存管理卡片

**Files:**
- Create: `lib/ui/player/stream_cache_progress_bar.dart`
- Create: `lib/ui/pages/settings/cache_settings_section.dart`
- Modify: `lib/ui/pages/settings/settings_page.dart`
- Test: `test/ui/player/stream_cache_progress_bar_test.dart`
- Test: `test/ui/pages/settings/cache_settings_section_test.dart`

**Interfaces:**
- Consumes: `AudioCacheRepository`, `NetworkMonitor`, `SettingsRepository`
- Produces: `class StreamCacheProgressBar extends StatelessWidget`
- Produces: `class CacheSettingsSection extends ConsumerWidget`

- [ ] **Step 1: Write the failing tests for progress bar & cache settings**

```dart
// test/ui/player/stream_cache_progress_bar_test.dart & cache_settings_section_test.dart
// Verify:
// 1. StreamCacheProgressBar renders base track, buffered secondary track, and active progress thumb.
// 2. CacheSettingsSection renders wifiOnly switch, preload chapters slider (0-10), and cache clear button.
// 3. 320dp narrow layout and dark theme render cleanly.
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/ui/player/stream_cache_progress_bar_test.dart test/ui/pages/settings/cache_settings_section_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `StreamCacheProgressBar` and `CacheSettingsSection`**

Implement custom painted or stacked dual-track progress bar.
Add cache management controls to `SettingsPage`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/ui/player/stream_cache_progress_bar_test.dart test/ui/pages/settings/cache_settings_section_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/player/ lib/ui/pages/settings/ test/ui/player/ test/ui/pages/settings/
git commit -m "feat(ui): implement StreamCacheProgressBar and CacheSettingsSection"
```

---

### Task 10: 分级安全删除弹窗 (`SafeDeleteBookDialog`) 与护栏接线

**Files:**
- Create: `lib/ui/pages/library/safe_delete_book_dialog.dart`
- Modify: `lib/ui/pages/library/library_page.dart`
- Modify: `lib/ui/pages/book_detail/book_detail_page.dart`
- Test: `test/ui/pages/library/safe_delete_book_dialog_test.dart`

**Interfaces:**
- Produces: `Future<SafeDeleteResult?> showSafeDeleteBookDialog(BuildContext context, {required BookSummary book, required bool isLocal})`
- Produces: `enum SafeDeleteAction { removeOnly, deleteFiles }`

- [ ] **Step 1: Write the failing test for `SafeDeleteBookDialog`**

```dart
// test/ui/pages/library/safe_delete_book_dialog_test.dart
// Verify:
// 1. Online book dialog offers "移出书架" (default) and "从书库彻底删除".
// 2. Local book dialog defaults to "从书库移除记录", checkbox for "同时删除本地音频目录" is unchecked.
// 3. Review Focus 5: For local book on SAF root or root_path == '', delete files checkbox is strictly disabled.
// 4. Checking delete files triggers a prominent secondary confirmation alert.
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/pages/library/safe_delete_book_dialog_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `SafeDeleteBookDialog` and wire into Library & Detail pages**

Implement SAF check and root directory path guard.
Wire deletion calls in `LibraryPage` and `BookDetailPage` `⋮` menus.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/pages/library/safe_delete_book_dialog_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/pages/library/ lib/ui/pages/book_detail/ test/ui/pages/library/
git commit -m "feat(ui): implement SafeDeleteBookDialog with SAF and root guardrails"
```

---

### Task 11: M1-D 端到端全链路沙盒集成测试套件与全量门禁校验

**Files:**
- Create: `test/app/library/online_m1d_fixture_test.dart`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Write the comprehensive end-to-end fixture test suite**

```dart
// test/app/library/online_m1d_fixture_test.dart
// End-to-end sandbox scenario:
// 1. Import book source.
// 2. Listen to online book, advance progress to 55%, verify preload triggered.
// 3. Trigger switch source, verify chapter alignment, upsert reactivation, cache eviction, and progress continuity.
// 4. Trigger partial TOC refresh failure, verify old chapters preserved without missing/retired corruption.
// 5. Trigger batch library refresh, verify capsule updates.
// 6. Test safe delete guardrails for local and online books.
```

- [ ] **Step 2: Run end-to-end test to verify it passes**

Run: `flutter test test/app/library/online_m1d_fixture_test.dart`
Expected: PASS

- [ ] **Step 3: Run full architectural and quality gates**

Run:
```bash
dart run tool/ci/check_import_boundaries.dart
flutter analyze
flutter test
```
Expected: 0 warnings, 0 boundary violations, all tests green.

- [ ] **Step 4: Record M1-D release in `CHANGELOG.md` and commit**

```bash
git add test/app/library/online_m1d_fixture_test.dart CHANGELOG.md
git commit -m "test(library): add online m1d end-to-end fixture test suite and pass all quality gates"
```
