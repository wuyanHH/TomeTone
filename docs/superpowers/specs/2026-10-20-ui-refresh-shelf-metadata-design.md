# 书架与元数据重做（UI Refresh Phase 1）

- 日期：2026-10-20
- 状态：已确认（2026-10-20）
- 设计基准：`docs/design-preview/ui-refresh/index.html` · 方向 A「宣纸旧卷」
- 关联需求：书架展示难看、没有分类、没有简介；后续播放台与书源分阶段进行

## 1. 为什么做

现在的书架只有「封面 + 书名 + 一句进度」，用户看不到这本书讲什么、属于哪一类，也无法按收听状态筛选。书籍详情页不存在，点书直接开始播放，想先了解一本书没有入口。

本轮先把「找得到、看得懂」做对：书架重排、分类与简介、书籍详情、元数据编辑。播放台与书源不在这轮范围。

## 2. 目标

1. 书架在 2 列网格与单列信息卡之间切换，两种密度都完整展示：封面、书名、作者/演播、一句简介、收听进度。
2. 支持搜索与筛选：全部 / 在听 / 未听 / 已完，按分类标签、按系列。
3. 新增书籍详情页：封面、完整元数据、分类标签、简介、章节/卷册入口、继续收听。
4. 元数据可编辑：书名、作者、演播者、系列名与序号、简介、分类标签。
5. 元数据双写：SQLite 覆盖层是显示真源；本地可写书根同步一份 `tometone.meta.json`，重装/换设备可重新导入。
6. 保持现有扫描、播放、进度写入行为不变。

## 3. 非目标

- 不改播放台 UI、不做歌词/STT、不做书源配置/发现/搜索；只为书架「已完」筛选补一个播放完成信号（不改变播放行为）。
- 不做在线元数据抓取（书源引擎落地后接入，本轮只留合并顺序）。
- 不写音频标签，不移动/重命名/删除用户的音频文件。
- SAF 根本轮不写书根文件（只读授权），只写 SQLite 覆盖层。
- 不做分页/无限滚动（先全量加载本地摘要；大数据量分页留到后续）。
- 不做封面替换/裁剪。

## 4. 分期与顺序

1. **Phase 1（本设计）**：书架 + 分类/简介 + 详情 + 元数据编辑 + 书根 sidecar。
2. **Phase 2**：播放台视觉重做、控制区聚合、更多播放设置、歌词页（LRC / STT 二选一先做 LRC 导入与空态）。
3. **Phase 3**：书源配置 CRUD、发现页、搜索、加入书库。

Phase 2/3 各自单独出设计，不在本轮开工。

## 5. 页面与交互

### 5.1 书架页

自上而下：

1. **页首**：`我的书架` 标题 + 藏书数量；右侧搜索入口、布局切换（网格/列表）。
2. **搜索**：点开后是单行输入，按书名 / 作者 / 演播者 / 系列名 / 简介做包含匹配，大小写不敏感。
3. **筛选条**：`全部 / 在听 / 未听 / 已完` 状态 chips；`分类` 与 `系列` 各一个下拉/弹层（标签数量多时不铺满一行）。
4. **内容**：
   - 网格：默认 2 列；`>=600dp` 3 列，`>=960dp` 4 列。卡片含封面、快速播放按钮、书名、作者/演播、一句简介、进度条与百分比。
   - 列表：封面缩略图、书名、作者/演播、两行简介、标签、进度，右侧播放按钮。
5. **排序**：默认沿用「最近收听 / 最近加入」；本轮不新增排序菜单。
6. **空态**：无书时沿用现有空态；筛选/搜索无结果时给「清除筛选」入口，而不是整页空态。

### 5.2 书籍详情页

- 顶部返回；右上角 `⋮`：编辑元数据、从书根重新导入（可写根）。
- 大封面、书名、系列名、作者、演播者、状态与总时长。
- 分类标签 chips。
- 简介全文（为空时显示「暂无简介」+ 编辑入口）。
- 两个入口卡：`章节目录`（`第 N / 12 章`，不谎报「已听章数」）与 `卷册`（卷数）。点开底部弹层显示卷/章列表，当前章高亮，缺失章置灰；**点可用章直接打开播放台并从该章开始播放**（缺失章不可点）。
- 底部主按钮：有进度 → `从第 N 章继续收听`；无进度 → `开始收听`。点击后打开播放台。
- 元数据编辑保存后，详情与书架立即刷新。

### 5.3 元数据编辑

底部弹层或全屏页，字段：

- 书名（必填，去首尾空格）
- 作者、演播者、系列名、系列序号
- 简介（多行，建议 2000 字上限）
- 分类标签（可增删的 chips；输入支持中文逗号、英文逗号、顿号分隔）

保存行为：

1. 写 `book_metadata_overrides`（upsert），并把 `manual_edited_at` 置为当前时间。
2. 尝试写书根 `tometone.meta.json`。成功 → 轻提示「已保存到应用与书根」；只读/失败 → 轻提示「已保存到应用内，书根文件未写入」。
3. 不因为 sidecar 写失败而回滚数据库保存。

### 5.4 导航变化

- 点书架卡片 → 书籍详情。
- 卡片上的播放按钮 / 详情页继续按钮 → 播放台。
- 现有「点书直接播放」的行为改为「点卡片进详情」，这是本轮有意的交互变更。

## 6. 数据模型

### 6.1 复用已有表

`book_metadata_overrides` 已在 schema v1 存在，字段包含 title / author / narrator / seriesName / seriesIndex / description / updatedAt。本轮把它真正接进查询与 UI。

### 6.2 新增字段 / 表（schema v2）

1. `book_metadata_overrides.manual_edited_at`（nullable datetime）
   - 非空表示用户手动编辑过；扫描导入 sidecar 时不覆盖手动值。
2. `playback_progress.finished_at`（nullable datetime）
   - 由播放层在「全书播完」时写入；`null` 表示未完成。用于书架「已完」筛选。
   - 重新开始听任意一章时清空。
3. 新表 `book_tags`
   - `book_id` → `books.id`，`ON DELETE CASCADE`
   - `tag`（text）
   - 主键 `(book_id, tag)`；索引 `tag`
   - 标签去首尾空格、去空、去重，大小写按原文保留，匹配时折叠大小写。

### 6.3 迁移

- `schemaVersion` 1 → 2。
- 迁移必须增量、非破坏：
  - `ALTER TABLE book_metadata_overrides ADD COLUMN manual_edited_at INTEGER`
  - `ALTER TABLE playback_progress ADD COLUMN finished_at INTEGER`
  - `CREATE TABLE book_tags (...)`
  - 建索引
- 生成代码用 `dart run build_runner build` 更新。
- 增加 v1 → v2 迁移测试：旧库升级后原有书 / 章 / 进度不丢。

### 6.4 视图扩展

`BookSummary` 增加：

- `String? description`
- `List<String> tags`
- `bool isFinished`（见 6.5）

`BookDetail` 的 `summary` 直接带上述字段；卷/章结构不变。

### 6.5 收听状态与百分比

- 未听：没有 `playback_progress`。
- 在听：有进度且 `finished_at` 为空。
- 已完：`playback_progress.finished_at` 非空。
- 完成信号由播放层给出：`PlaybackController._finished` 置位时（章末无下一章 / 手动下一章到末尾），通过注入的 `markBookFinished` 回调写入 `finished_at`；重新打开并播放任意一章时清空。
- **本轮不接入时长回填**（`LibraryScanner.backfillMetadata` 在生产代码没有调用点）。书架百分比按章节位置计算：`(当前章序号 + 1) / 总章数`，与播放台现有全书进度口径一致；不在本轮新增「读取全部章节时长」的子系统。
- 状态筛选只依赖 `BookSummary`，不额外查库。

### 6.6 写入端口

`LibraryQueries` 增加：

```dart
Future<void> saveBookMetadata({
  required String bookId,
  required BookMetadataDraft metadata,
  DateTime? updatedAt,
});

Future<List<String>> listBookTags();
```

`BookMetadataDraft` 是领域值对象，包含可空字段与 `List<String> tags`；空字符串归一化为 null。

## 7. 书根 sidecar

### 7.1 文件

- 文件名：`tometone.meta.json`
- 位置：书根目录（与音频文件同层），不是书库根，不是应用私有目录。
- 编码：UTF-8，缩进 2 空格。
- 体积上限：256 KB；超过按解析失败处理。

### 7.2 格式

```json
{
  "schema": 1,
  "title": "长夜行舟",
  "author": "沈砚舟",
  "narrator": "顾行舟",
  "seriesName": "山河夜航",
  "seriesIndex": 1,
  "description": "……",
  "tags": ["武侠", "长篇"],
  "updatedAt": "2026-10-20T12:00:00.000Z"
}
```

未知字段忽略；缺失字段视为 null；`schema` 大于当前支持版本时只读不写。

### 7.3 读取与合并

- 扫描建书后读取 sidecar；详情页也提供「从书根重新导入」。
- **导入目标是 `book_metadata_overrides`，不是 `books`**：扫描器继续把 `books.title` 写成目录名，显示层用 `COALESCE(覆盖层, books)` 取值。这样 sidecar 里的书名能覆盖目录名，而不会和「扫描每次重置 title」打架。
- 合并顺序（高 → 低）：
  1. 用户手动编辑（`manual_edited_at` 非空）
  2. 已有 `tometone.meta.json`
  3. 在线书源结果（Phase 3 接入，本轮不实现）
  4. 目录 / 文件名推断
- 手动编辑过的书，扫描不覆盖任何元数据；用户要覆盖时走「重新导入」并二次确认。
- 未手动编辑过的书，sidecar 只填充 `book_metadata_overrides` 里的空字段，不清空已有值。
- **「重新导入」按字段存在性合并**：JSON 里出现的字段才覆盖，未出现的字段保持原值；不因为文件缺字段就把用户手填的作者 / 简介清空。若用户确实要清空，去编辑页手动清。
- 解析失败不写库、不覆盖；记录诊断（不含书籍内容），下次扫描可重试。

### 7.4 写入

- 只对可写根（本地目录）写；SAF 根返回 `unsupported`，UI 提示「当前来源只读」。
- 原子写法：同目录写临时文件 → flush → rename 覆盖目标；失败清理临时文件。
- 只写 `tometone.meta.json`，不触碰音频 / 封面 / 其它文件。
- 写之前若已有同名文件，内容会被新值整体替换（这是用户显式保存的结果）。

### 7.5 端口

新增契约 `BookMetadataFileStore`：

```dart
abstract interface class BookMetadataFileStore {
  Future<BookMetadataSidecar?> read({
    required String rootUri,
    required String bookRootPath,
  });

  Future<SidecarWriteResult> write({
    required String rootUri,
    required String bookRootPath,
    required BookMetadataSidecar metadata,
  });
}
```

- 本地实现：`dart:io`，按 `rootUri + bookRootPath` 拼路径。
- SAF 实现：读走 `SafBridge.documentUri + readBytes`；写返回 `unsupported`。
- 由 `main.dart` 按根 URI 注入工厂，UI / app 不直接依赖 `modules/`。

## 8. 查询与加载

- `booksProvider` 当前调用 `listBooks()`，默认 `limit = 50`，会静默截断书架。本轮改为书架专用的 `listAllBooks()`（无 LIMIT），筛选/搜索在内存完成。
- 保持 `listBooks({limit, offset})` 给未来分页使用。
- 全量加载只取摘要字段；封面仍走现有 `coverArtProvider` 懒加载。
- 标签查询一次取全量 `(book_id, tag)`，组装进摘要，避免每本书一次查询。

## 9. 边界与失败

- 数据库迁移失败：启动即报错，不静默重建库。
- sidecar JSON 损坏：忽略该文件，书仍正常显示；详情页「重新导入」可重试。
- 书根只读 / 文件被占用 / 磁盘满：数据库保存仍成功，UI 明确说明书根未写入。
- 同名标签大小写不同：显示按首次出现的写法，匹配折叠大小写。
- 简介超长：UI 截断展示，存储不截断；上限 2000 字在编辑层校验。
- 320dp、系统大字号、深色模式：网格/列表/详情/编辑弹层都不能溢出。

## 10. 验收

1. v1 → v2 迁移后旧数据完整，`flutter analyze` 0 问题。
2. 书架能切换网格/列表；两种布局都显示简介与状态。
3. 搜索、状态筛选、标签筛选、系列筛选组合可用；无结果可一键清除。「已完」必须由真实的播完事件驱动，不用「停在最后一章」冒充完成。
4. 详情页展示完整元数据；编辑保存后书架与详情立即更新。
5. 本地根保存元数据后生成 `tometone.meta.json`；删除应用数据后重新扫描能恢复元数据（包括书名与目录名不同的情况）。
6. SAF 根保存只写数据库，并出现「来源只读」提示；不产生任何文件写入。
7. 手动编辑过的书重扫描不被覆盖；未编辑的书能从 sidecar 补齐空字段；重新导入不会因文件缺字段而清空手填值。
8. 详情页点可用章能从该章开始播放；缺失章不可点；显式起播不触发微回退。
8. 现有 493 项测试继续通过，并新增迁移、sidecar、筛选、详情、编辑测试。

## 11. 实施拆分

1. **数据层**：schema v2、迁移、`BookTags`、摘要 join、`saveBookMetadata`、`finished_at` 读写、测试。
2. **播放完成信号与指定章起播**：`PlaybackController` 注入 `markBookFinished`，在 `_finished` 置位时落库；开始播放时清空。`openBook` 增加可选 `startChapterId`（详情页点章用），显式起播时不套用微回退；补播放侧测试。
3. **sidecar 层**：契约、本地/ SAF 实现、JSON 编解码、扫描导入、保存导出、测试。
4. **UI 层**：书架页重排、卡片/列表、筛选、详情页、编辑弹层、导航、空态。
5. **收尾**：接入 provider、全量测试、CHANGELOG、真机 320dp / 大字号 / 深色检查。

## 12. 留给 builder 的决定

- 标签编辑的具体控件形态（输入框 + chips，或全屏选择器）。
- 系列筛选用下拉还是弹层；标签很多时的折叠方式。
- 网格/列表选择是否持久化（本轮可只存内存）。
- 章节目录弹层是否复用播放台现有章节 UI，还是新建共享组件。
- sidecar 导入时机（扫描时同步 vs 扫描完成后异步补），以不拖慢首屏为准。
