# 听书体验与紧凑布局全景重构实施计划 (Audiobook UI/UX Streamlining Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 全面改造 TomeTone 的视觉层级与听书交互：废除双层标题，书架采用标准 2:3 护封并收敛偏好设置，统一书籍目录详情页与书源预览，重构专业听书播放台，并将发现页书源切换快捷化、设置页二级层级化。

**Architecture:** 
1. 全局 AppBar 紧凑化，剥离冗余的装饰性眉题，统一采用原生 48~56dp 单行导航；
2. 书架展示参数与全局听书偏好纳入 `AppPreferences` 持久化，与单书偏好分层解耦；
3. 将未入库书源预览与书架内页统一收归同一套 `BookDetailPage`，采用“左加/移书架，右主播放”的黄金 CTA 操作区与卷册折叠目录；
4. 播放台回归现代经典人体工学五键控制台与单行辅助工具栏，移除冗余的全书进度条并修复滑条拖拽。

**Tech Stack:** Flutter 3.x, Riverpod 2.x, Drift / SQLite, Just Audio, Shared Preferences.

**Spec:** [`docs/superpowers/specs/2026-10-22-audiobook-ui-ux-streamlining-design.md`](docs/superpowers/specs/2026-10-22-audiobook-ui-ux-streamlining-design.md)

## Global Constraints

- 全局禁用不可收起的双层装饰性眉题（如 `· THE VAULT`、`· DISCOVER`、`· PREFERENCES`）；
- 书架封面固定采用标准 2:3 书籍护封比例，默认不展示进度条；
- 书源预览与详情页统一中，未入库书籍在用户点击加入书架或播放前，**严禁向 SQLite/Drift 写入任何记录**；
- 播放台严禁上下堆叠多根进度条，全书进度降级为单行紧凑文本；
- 严格遵守架构分层与导入边界约束，运行 `dart run tool/ci/check_import_boundaries.dart` 零违规；
- 静态分析 `dart analyze` 零 warning、零 error。

## Review Focus

1. **未持久化书籍在详情页点击章节起播**：预览中的在线书籍点击任意非首章时，必须自动完成入库（`startListening`）并定位到该点击章节起播，不能抛出未入库异常；
2. **移出书架二次确认与本地数据安全**：移出书架仅标记 `onShelf: false`，对于本地书籍与在线书籍严禁物理删除磁盘音频文件；
3. **播放台未知时长或流式音频拖拽**：在音频总时长尚未解析完成前，拖动进度条不应直接 crash 或被禁用，而应基于缓冲或比例安全拖动；
4. **书架右上角列数与显示字段持久化**：用户调整列数（2/3/4/列表）或开关书名/作者/演播后，冷启动重启应用配置仍需生效；
5. **小屏（320dp）极端排布防溢出**：在 320dp 手机或系统特大字号下，顶栏标题、双按钮 CTA 栏与播放台五键控制栏不得发生像素溢出（RenderFlex overflow）。

---

### Task 1: Preferences 模型扩展与全局偏好测试 (Preferences Extension)

**Files:**
- Modify: `lib/app/preferences/app_preferences.dart:10-80`
- Modify: `lib/app/preferences/app_preferences_store.dart:10-120`
- Test: `test/app/preferences/app_preferences_test.dart`

**Interfaces:**
- Produces:
  - `AppPreferences.shelfColumns`: `int` (默认 3，取值范围 2, 3, 4, 1-表示列表)
  - `AppPreferences.shelfShowTitle`: `bool` (默认 true)
  - `AppPreferences.shelfShowAuthor`: `bool` (默认 true)
  - `AppPreferences.shelfShowNarrator`: `bool` (默认 true)
  - `AppPreferences.defaultPlaybackSpeed`: `double` (默认 1.0)
  - `AppPreferences.defaultSkipIntroSeconds`: `int` (默认 0)
  - `AppPreferences.defaultSkipOutroSeconds`: `int` (默认 0)

- [x] **Step 1: 编写 AppPreferences 扩展的失败测试**

在 `test/app/preferences/app_preferences_test.dart` 中编写对书架显示列数、字段显隐开关以及全局默认听书偏好（倍速、跳过片头片尾）的默认值与持久化序列化测试。

- [x] **Step 2: 运行测试验证失败**

运行：`flutter test test/app/preferences/app_preferences_test.dart`
预期：FAIL（字段不存在）

- [x] **Step 3: 实现 `AppPreferences` 与 `AppPreferencesStore` 扩展字段与序列化**

在 `lib/app/preferences/app_preferences.dart` 和 `lib/app/preferences/app_preferences_store.dart` 中添加对应字段、copyWith、toJson/fromJson 及 SharedPreferences 读写逻辑。

- [x] **Step 4: 运行测试验证通过**

运行：`flutter test test/app/preferences/app_preferences_test.dart`
预期：PASS

- [x] **Step 5: 提交代码**

```bash
git add lib/app/preferences/ test/app/preferences/
git commit -m "feat(preferences): add shelf display and audio default preferences"
```

---

### Task 2: 全局顶栏双层标题移除与紧凑 AppBar 规范化 (Global Single-Tier AppBars)

**Files:**
- Modify: `lib/ui/pages/shelf/shelf_page.dart:220-470`
- Modify: `lib/ui/pages/discovery/discovery_page.dart:550-590`
- Modify: `lib/ui/pages/settings/settings_page.dart:110-145`
- Test: `test/ui/shelf_page_test.dart`
- Test: `test/ui/settings_page_test.dart`

**Interfaces:**
- Consumes: `AppPreferences` from Task 1
- Produces: 紧凑标准的单行标题栏，移除所有 `· THE VAULT`、`· DISCOVER`、`· PREFERENCES` 眉题。

- [x] **Step 1: 编写移除双层标题后的页面标题栏断言测试**

在 `test/ui/shelf_page_test.dart` 和 `test/ui/settings_page_test.dart` 中断言：不再渲染 `藏馆 · THE VAULT` 或 `偏好 · PREFERENCES`，主标题与数量或操作栏紧凑并列。

- [x] **Step 2: 运行测试验证失败**

运行：`flutter test test/ui/shelf_page_test.dart test/ui/settings_page_test.dart`
预期：FAIL（原眉题依然存在）

- [x] **Step 3: 改造 `ShelfPage`、`DiscoveryPage` 与 `SettingsPage` 顶栏结构**

- `ShelfPage`: 将 `_ShelfHeader` 替换为单层 48~56dp 题头，标题与计数紧凑排列，保留搜索与布局切换动作；
- `DiscoveryPage`: 移除 `发现 · DISCOVER` 眉题，保留简洁单行 `发现` 标题；
- `SettingsPage`: 移除 `_SettingsHeader` 中的英文眉题与冗余副文本，精简为单行 `系统设置`。

- [x] **Step 4: 运行测试验证通过**

运行：`flutter test test/ui/shelf_page_test.dart test/ui/settings_page_test.dart`
预期：PASS

- [x] **Step 5: 提交代码**

```bash
git add lib/ui/pages/shelf/ lib/ui/pages/discovery/ lib/ui/pages/settings/ test/ui/
git commit -m "refactor(ui): streamline app bars and remove double-tier headers"
```

---

### Task 3: 书架页重构 (2:3 护封比例、隐藏进度、右上角更多菜单设置)

**Files:**
- Modify: `lib/ui/pages/shelf/shelf_page.dart:180-370`
- Modify: `lib/ui/pages/shelf/shelf_book_card.dart:40-200`
- Modify: `lib/ui/pages/shelf/shelf_book_row.dart:40-180`
- Test: `test/ui/shelf_page_test.dart`

**Interfaces:**
- Consumes: Task 1 中的 `shelfColumns`, `shelfShowTitle`, `shelfShowAuthor`, `shelfShowNarrator`
- Produces:
  - `ShelfPage.moreMenuKey`: `Key('shelf-more-menu')`
  - 标准 2:3 书籍封面与可控显示字段
  - 长按卡片调出底部操作栏（移出书架、编辑标签、换源）

- [x] **Step 1: 编写书架更多设置与 2:3 封面排布的组件测试**

测试在 `ShelfPage` 点击右上角 `⋮` 菜单切换列数（2/3/4列）以及切换显示书名/作者字段时的响应渲染；断言卡片上不渲染干扰进度条。

- [x] **Step 2: 运行测试验证失败**

运行：`flutter test test/ui/shelf_page_test.dart`
预期：FAIL（未定义更多菜单与 2:3 比例自适应）

- [x] **Step 3: 实现书架 2:3 封面与更多设置菜单**

- 在 `ShelfPage` 的顶栏添加 `PopupMenuButton` (`ShelfPage.moreMenuKey`)，支持列数切换与字段开关，与 `preferencesProvider` 双向绑定；
- 更新 `SliverGridDelegate` 计算：基于 `columns`（2/3/4）与 2:3 护封比例计算 `childAspectRatio`；
- 更新 `ShelfBookCard`：彻底隐藏进度条等杂项，按设置项动态显示标题/作者/演播；添加 `onLongPress` 触发底部操作栏（移出书架等）。

- [x] **Step 4: 运行测试验证通过**

运行：`flutter test test/ui/shelf_page_test.dart`
预期：PASS

- [x] **Step 5: 提交代码**

```bash
git add lib/ui/pages/shelf/ test/ui/shelf_page_test.dart
git commit -m "feat(shelf): add 2:3 book aspect ratio and more preferences menu"
```

---

### Task 4: 发现页顶栏书源快捷切换与管理 (Discovery Header Quick Switcher)

**Files:**
- Modify: `lib/ui/pages/discovery/discovery_page.dart:40-120,540-620`
- Test: `test/ui/discovery_page_test.dart` (或对应 discovery 测试)

**Interfaces:**
- Produces:
  - `DiscoveryPageKeys.headerSourcePillKey`: `Key('discovery-header-source-pill')`
  - `DiscoveryPageKeys.headerManageKey`: `Key('discovery-header-manage-sources')`
  - 移除原 `DiscoverySourceCard`，纵向空间全部分配给分类与榜单

- [x] **Step 1: 编写发现页顶栏快捷书源胶囊与管理按钮测试**

断言发现页顶部包含书源胶囊切换按钮与管理图标；断言原大卡片 `DiscoveryPageKeys.sourceCardKey` 不再占用 body 区域。

- [x] **Step 2: 运行测试验证失败**

运行：`flutter test test/ui/discovery_page_test.dart`
预期：FAIL

- [x] **Step 3: 改造 `DiscoveryPage` 顶栏与布局**

- 在顶栏 `AppBar` 右侧增加胶囊按钮（显示当前书源名 + 下拉箭头），点击调用已有的 `_openSwitcher()`；
- 紧随其后增加管理书源 `IconButton(icon: Icons.tune_rounded)`，点击调用 `_openManagement()`；
- 移除 `_buildBody()` 上方内嵌的 `DiscoverySourceCard`，让分类榜单直接贴近顶栏展开。

- [x] **Step 4: 运行测试验证通过**

运行：`flutter test test/ui/discovery_page_test.dart`
预期：PASS

- [x] **Step 5: 提交代码**

```bash
git add lib/ui/pages/discovery/
git commit -m "feat(discovery): move source switch and manage into app bar header"
```

---

### Task 5: 设置页二级子页面层级化 (Hierarchical Settings Subpages)

**Files:**
- Modify: `lib/ui/pages/settings/settings_page.dart:1-200`
- Create: `lib/ui/pages/settings/subpages/appearance_settings_page.dart`
- Create: `lib/ui/pages/settings/subpages/audio_preference_settings_page.dart`
- Create: `lib/ui/pages/settings/subpages/cache_settings_page.dart`
- Create: `lib/ui/pages/settings/subpages/about_settings_page.dart`
- Test: `test/ui/settings_page_test.dart`
- Test: `test/ui/settings_appearance_test.dart`

**Interfaces:**
- Produces:
  - `SettingsPage` 作为一级导航目录页；
  - `AppearanceSettingsPage`（外观设置二级页）；
  - `AudioPreferenceSettingsPage`（听书偏好二级页，含默认倍速与跳过片头片尾）；
  - `CacheSettingsPage`（存储与缓存二级页）；
  - `AboutSettingsPage`（关于与版本更新二级页）。

- [ ] **Step 1: 编写设置页一级导航与二级页面跳转测试**

在 `test/ui/settings_page_test.dart` 中测试一级菜单 4 个入口项存在，点击后能分别导航至对应二级页面，并且原有测试 Key 依然正常工作。

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/ui/settings_page_test.dart`
预期：FAIL（二级页面尚未创建）

- [ ] **Step 3: 创建 4 个二级设置页面并将 `SettingsPage` 改造为分组卡片入口**

- 创建 `AppearanceSettingsPage`：迁移原有的色彩主题、明暗、OLED 开关；
- 创建 `AudioPreferenceSettingsPage`：展示并修改 Task 1 的全局默认倍速、默认跳过片头/片尾秒数；
- 创建 `CacheSettingsPage`：迁移并展示存储占用与缓存清理；
- 创建 `AboutSettingsPage`：迁移版本号、检查更新、更新历史与开源许可证入口；
- `SettingsPage` 主页面只渲染美观的分组 `ListTile`，带副标与尾部导航箭头。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/ui/settings_page_test.dart test/ui/settings_appearance_test.dart`
预期：PASS

- [ ] **Step 5: 提交代码**

```bash
git add lib/ui/pages/settings/ test/ui/settings_page_test.dart
git commit -m "feat(settings): restructure settings into clean hierarchical subpages"
```

---

### Task 6: 专业听书播放台重构 (单进度文本、滑条拖拽修复、五键控制台、底部工具栏)

**Files:**
- Modify: `lib/ui/pages/player/player_page.dart:410-640`
- Test: `test/ui/player_page_test.dart`

**Interfaces:**
- Produces:
  - 移除 `LinearProgressIndicator` 全书进度条；
  - 进度时间行显示轻量全书百分比文本（如 `全书 38% · 第 32 / 128 章`）；
  - 加粗的 `Slider`（轨高 4~5dp，滑块有效触控热区 48dp，支持平滑 seek）；
  - 人体工学五键控制台：上一章、快退15秒、中心悬浮主播放钮、快进15秒、下一章；
  - 底部工具行：倍速、定时睡眠、目录列表、换源、撤销回退。

- [ ] **Step 1: 编写播放台控制重构与进度条滑动的测试用例**

在 `test/ui/player_page_test.dart` 中断言：
1. 不再渲染全书进度条组件；
2. 进度条滑块支持拖拽触发 seek；
3. 五键控制台和底部工具行按键均存在且可点击。

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/ui/player_page_test.dart`
预期：FAIL

- [ ] **Step 3: 重构 `PlayerPage` 的进度条与控制台布局**

- 移除全书进度条，在时长行中间加入 `全书 ${(bookFraction * 100).round()}%` 紧凑文本；
- 改造 `SliderTheme`：轨高从 2 提升到 5，thumbRadius 设为 8，增强触控热区；解除过于苛刻的拖动禁用条件；
- 重构 `_buildConsole`：横向对称分布 [上一章 48dp] [快退15秒 48dp] [大号中心悬浮播放键 68dp] [快进15秒 48dp] [下一章 48dp]，移除灰色卡片外壳；
- 重构底部辅助行：横向整齐排列 [倍速] [定时睡眠] [目录 ☰] [换源 ⇄] [撤销回退 ↺]。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/ui/player_page_test.dart`
预期：PASS

- [ ] **Step 5: 提交代码**

```bash
git add lib/ui/pages/player/player_page.dart test/ui/player_page_test.dart
git commit -m "feat(player): ergonomic 5-key console, single progress text and fixed slider"
```

---

### Task 7: 统一书籍详情与目录页 (Unified Book Catalog Detail Page)

**Files:**
- Modify: `lib/ui/pages/shelf/book_detail_page.dart:1-700`
- Modify: `lib/ui/pages/discovery/discovery_page.dart:280-350`
- Remove: `lib/ui/pages/discovery/online_book_preview_page.dart` (逻辑整合进 `book_detail_page.dart`)
- Test: `test/ui/book_detail_page_test.dart`
- Test: `test/ui/shelf_page_test.dart`

**Interfaces:**
- Produces:
  - `BookDetailPage`: 统一支持已存 `bookId` 或未持久化 `(BookSource source, SourceBookSummary item)`；
  - 头部数据左右排布（左侧 2:3 封面，右侧元数据与书源）；
  - 核心双按钮 CTA 栏：左侧 `[＋ 加入书架 / ✓ 移出书架]` + 右侧 `[▶ 立即试听 / 继续播放]`；
  - 卷册目录支持折叠/展开与正倒序；
  - 移出书架支持二次确认且不删物理文件。

- [ ] **Step 1: 编写统一目录详情页的双态与双按钮 CTA 行为测试**

测试两种场景：
1. 从发现页进入（未入库）：展示 `[+ 加入书架]` 与 `[▶ 立即试听]`，打开前后不写本地数据库；点击 `加入书架` 或点击试听后正确入库；
2. 从书架进入（已入库）：展示 `[✓ 移出书架]` 与 `[▶ 继续播放 第 X 章]`，点击移出书架并确认后更新 `onShelf: false`。

- [ ] **Step 2: 运行测试验证失败**

运行：`flutter test test/ui/book_detail_page_test.dart`
预期：FAIL

- [ ] **Step 3: 实现统一的 `BookDetailPage` 与卷册折叠目录**

- 扩展 `BookDetailPage` 构造函数，支持直接传入 `(source, item)` 未入库参数；未入库时采用只读网络查询渲染，入库后切换 Drift 响应式流；
- 实现横向 CTA 栏：左边 `[加入/移出书架]` 按钮，右边撑满的 `[立即试听/继续播放]` 按钮；
- 目录列表增加卷册分组折叠组件与正倒序切换逻辑；
- 更新 `DiscoveryPage` 中原指向 `OnlineBookPreviewPage` 的跳转，全部统一路由到 `BookDetailPage`。

- [ ] **Step 4: 运行测试验证通过**

运行：`flutter test test/ui/book_detail_page_test.dart test/ui/shelf_page_test.dart`
预期：PASS

- [ ] **Step 5: 提交代码**

```bash
git add lib/ui/pages/shelf/book_detail_page.dart lib/ui/pages/discovery/ test/ui/
git commit -m "feat(book-detail): unify catalog detail page with dual CTA and volume fold"
```

---

### Task 8: 全量质量门禁与端到端验证 (Verification & Quality Gate)

**Files:**
- All modified files across the workspace
- CI boundary checks: `tool/ci/check_import_boundaries.dart`

- [ ] **Step 1: 运行 Dart 静态分析**

运行：`dart analyze`
预期：0 issues found!

- [ ] **Step 2: 运行架构导入边界检查**

运行：`dart run tool/ci/check_import_boundaries.dart`
预期：All boundary rules pass!

- [ ] **Step 3: 运行全量单元与组件测试**

运行：`flutter test`
预期：All test suites pass!

- [ ] **Step 4: 提交所有代码与发版记录**

```bash
git commit -am "chore: pass all quality gates for audiobook ui/ux streamlining"
```
