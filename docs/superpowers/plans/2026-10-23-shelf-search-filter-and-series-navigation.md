# 书架搜索筛选一体化、系列导航与书库职责转型实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现通用搜索筛选一体化折叠组件（`SearchFilterBar`），升级书架顶部系列导航（TabBar 左右手势滑动切页与选择框双模式及偏好管理），并将书库页转型为纯粹的来源与资产管理面板，彻底消除功能冗余。

**Architecture:** 将搜索框与多维筛选项统一封装至 `SearchFilterBar`，采用 `AnimatedSize` 顺滑展开折叠卡片；书架顶部将静态标题升级为由 `AppPreferences` 持久化驱动的系列导航（TabBar + PageView 手势联动，或 Dropdown 模式）；书架收编所有找书过滤能力（含本地/在线渠道），书库页（`LibraryPage`）彻底移除书籍列表，专注本地目录扫描与在线书源资产管理。

**Tech Stack:** Flutter 3, Riverpod, Material 3, AppTheme & Design Tokens (`AppSpacing`, `AppRadii`, `AppDurations`).

**Spec:** `docs/superpowers/specs/2026-10-23-shelf-search-filter-and-series-navigation-design.md`

## Global Constraints

- 所有间距必须使用 `AppSpacing` 常量（如 `xs: 4`, `sm: 8`, `md: 12`, `lg: 16`），禁止硬编码数字。
- 所有圆角必须使用 `AppRadii` 常量（如 `xs: 6`, `sm: 10`, `md: 14`, `pill: 999`）。
- 颜色从 `Theme.of(context).colorScheme` 与 `AppColorPalette` 提取，禁止硬编码十六进制颜色。
- 动效时长和曲线遵循 `AppDurations.standard` 与 `AppDurations.standardCurve`。
- 新增及修改代码必须满足架构分层规范，CI 工具 `dart run tool/ci/check_import_boundaries.dart` 检查无越界。

## Review Focus

1. **系列 Tab 数量为空异常**：用户将所有系列隐藏或书架为空时，`TabBar` / `TabController` 初始化必须有保底项（强制显示「全部」），严禁抛出 `AssertionError`。
2. **打字检索性能与 Tab 抖动**：输入关键词检索时，仅在当前活动视图执行过滤，各系列 Tab 上的总册数徽标保持稳定，严禁在每次按键时重算全量跨系列派生导致界面卡顿或 Tab 宽度抖动。
3. **折叠面板展开不遮挡**：`SearchFilterBar` 展开折叠卡片时必须作为 Sliver/Box 的正常流内组件，顺滑将书籍列表下推，严禁作为模态弹窗或绝对定位浮层导致遮挡列表操作。
4. **左右滑动手势冲突**：`PageView` 的横向滑动手势不能与横向滚动的 TabBar 或 Chip 列表发生死锁，触摸书架主列表区域能够流畅滑入上一/下一系列。
5. **偏好配置升级向后兼容**：旧版本持久化的 `AppPreferences` JSON 反序列化时，缺失新增字段必须安全 fallback 到默认值（`tabs` 模式、显示全部、显示未分类）。

---

### Task 1: 偏好模型与筛选状态扩展 (`AppPreferences` & `ShelfFilterState`)

**Files:**
- Modify: `lib/app/preferences/app_preferences.dart`
- Modify: `lib/ui/pages/shelf/shelf_filter.dart`
- Test: `test/app/preferences/app_preferences_test.dart`
- Test: `test/ui/shelf_filter_test.dart`

**Interfaces:**
- Produces:
  - `enum ShelfSeriesNavMode { tabs, dropdown }`
  - `AppPreferences.shelfSeriesNavMode: ShelfSeriesNavMode` (默认 `tabs`)
  - `AppPreferences.shelfShowAllSeriesTab: bool` (默认 `true`)
  - `AppPreferences.shelfShowUncategorizedSeriesTab: bool` (默认 `true`)
  - `AppPreferences.shelfHiddenSeries: List<String>` (默认 `const []`)
  - `AppPreferences.shelfSeriesOrder: List<String>` (默认 `const []`)
  - `enum ShelfSourceFilter { all, local, online }`
  - `ShelfFilterState.source: ShelfSourceFilter` (默认 `all`)

- [ ] **Step 1: 编写 AppPreferences 与 ShelfFilterState 扩展的失败测试**

在 `test/app/preferences/app_preferences_test.dart` 中增加对系列导航偏好默认值、copyWith、序列化及向后兼容性的测试；在 `test/ui/shelf_filter_test.dart` 中增加对 `ShelfFilterState.source`（本地/在线过滤）的测试。

- [ ] **Step 2: 运行测试验证失败**

运行: `flutter test test/app/preferences/app_preferences_test.dart test/ui/shelf_filter_test.dart`
预期: 编译失败，提示 `ShelfSeriesNavMode`、`shelfSeriesNavMode` 及 `ShelfSourceFilter` 未定义。

- [ ] **Step 3: 实现模型扩展与序列化**

在 `lib/app/preferences/app_preferences.dart` 中定义 `ShelfSeriesNavMode` 枚举，在 `AppPreferences` 中增加对应字段及 `fromJson`/`toJson`/`copyWith`/`==`/`hashCode`；在 `lib/ui/pages/shelf/shelf_filter.dart` 中增加 `ShelfSourceFilter` 枚举并在 `ShelfFilterState` 中加入来源过滤逻辑。

- [ ] **Step 4: 运行测试验证通过**

运行: `flutter test test/app/preferences/app_preferences_test.dart test/ui/shelf_filter_test.dart`
预期: 全部测试 PASS。

- [ ] **Step 5: 提交更改**

```bash
git add lib/app/preferences/app_preferences.dart lib/ui/pages/shelf/shelf_filter.dart test/app/preferences/app_preferences_test.dart test/ui/shelf_filter_test.dart
git commit -m "feat(shelf): add series nav preferences and source filter state"
```

---

### Task 2: 独立通用搜索筛选一体化组件 (`SearchFilterBar`)

**Files:**
- Create: `lib/ui/widgets/search_filter_bar.dart`
- Test: `test/ui/widgets/search_filter_bar_test.dart`

**Interfaces:**
- Produces:
  - `class SearchFilterBar extends StatefulWidget`:
    - `final TextEditingController controller;`
    - `final FocusNode? focusNode;`
    - `final String hintText;`
    - `final ValueChanged<String>? onQueryChanged;`
    - `final int activeFilterCount;`
    - `final WidgetBuilder? filterPanelBuilder;`
    - `final bool initiallyExpanded;`
    - `final ValueChanged<bool>? onExpandChanged;`
  - `class SearchFilterGroup extends StatelessWidget`: 结构化筛选分组标题与内容
  - `class SearchFilterChip extends StatelessWidget`: 样式统一的胶囊筛选按钮

- [ ] **Step 1: 编写 SearchFilterBar 组件的交互与渲染测试**

在 `test/ui/widgets/search_filter_bar_test.dart` 中测试：
1. 搜索框文字输入与清空按钮点击回调；
2. 筛选按钮根据 `activeFilterCount` 是否展示徽标角标及数字；
3. 点击筛选按钮时平滑展开/收起折叠面板；
4. 渲染自定义 `filterPanelBuilder` 内容及 `SearchFilterChip` 选中状态。

- [ ] **Step 2: 运行测试验证失败**

运行: `flutter test test/ui/widgets/search_filter_bar_test.dart`
预期: FAIL（文件或类尚未创建）。

- [ ] **Step 3: 实现 SearchFilterBar 组件**

创建 `lib/ui/widgets/search_filter_bar.dart`：
1. 主输入行：使用 `BoxDecoration` 配合 `AppRadii.pill`，左侧搜索图标，中间 `TextField`（有文字时显示 clear `IconButton`），右侧弱分割线 + 胶囊筛选按钮（含 Badge）；
2. 折叠卡片：使用 `AnimatedSize` 配合 `AppDurations.standard` 和 `AppDurations.standardCurve` 包裹 `filterPanelBuilder`，提供微浅背景色与内边距；
3. 辅助组件：提供 `SearchFilterGroup`（标题 + 内容排布）与 `SearchFilterChip`（符合宣纸/夜色主题的选中高亮胶囊）。

- [ ] **Step 4: 运行测试验证通过**

运行: `flutter test test/ui/widgets/search_filter_bar_test.dart`
预期: PASS。

- [ ] **Step 5: 提交更改**

```bash
git add lib/ui/widgets/search_filter_bar.dart test/ui/widgets/search_filter_bar_test.dart
git commit -m "feat(ui): add reusable SearchFilterBar with animated filter panel"
```

---

### Task 3: 书架系列管理抽屉 (`ShelfSeriesManagementSheet`)

**Files:**
- Create: `lib/ui/pages/shelf/shelf_series_management_sheet.dart`
- Test: `test/ui/pages/shelf/shelf_series_management_sheet_test.dart`

**Interfaces:**
- Consumes: `AppPreferences`, `preferencesProvider`, `ShelfSeriesNavMode`
- Produces:
  - `class ShelfSeriesManagementSheet extends ConsumerWidget`:
    - `static Future<void> show(BuildContext context, {required List<String> allAvailableSeries})`

- [ ] **Step 1: 编写系列管理抽屉的组件测试**

测试点包括：
1. 模式切换：通过 `SegmentedButton` 切换 Tab 栏与下拉选择框模式，并通知更新 `AppPreferences`；
2. 基础开关：切换「显示全部」与「显示未分类」；
3. 列表拖拽与显隐：在 `ReorderableListView` 中拖拽调整系列顺序，点击眼睛图标隐藏/显示指定系列；
4. 防空限制：当仅剩最后一个可见项时，禁用隐藏操作并给出提示。

- [ ] **Step 2: 运行测试验证失败**

运行: `flutter test test/ui/pages/shelf/shelf_series_management_sheet_test.dart`
预期: FAIL（类未定义）。

- [ ] **Step 3: 实现 ShelfSeriesManagementSheet**

创建 `lib/ui/pages/shelf/shelf_series_management_sheet.dart`，使用 `showModalBottomSheet` 展现半屏抽屉，整合模式选择器、显隐开关和拖拽排序列表，状态变动通过 `ref.read(preferencesProvider.notifier).replace(newPrefs)` 响应式写入。

- [ ] **Step 4: 运行测试验证通过**

运行: `flutter test test/ui/pages/shelf/shelf_series_management_sheet_test.dart`
预期: PASS。

- [ ] **Step 5: 提交更改**

```bash
git add lib/ui/pages/shelf/shelf_series_management_sheet.dart test/ui/pages/shelf/shelf_series_management_sheet_test.dart
git commit -m "feat(shelf): add ShelfSeriesManagementSheet for series order and visibility"
```

---

### Task 4: 书架页系列导航与 SearchFilterBar 深度联动重构

**Files:**
- Modify: `lib/ui/pages/shelf/shelf_page.dart`
- Test: `test/ui/shelf_page_test.dart`

**Interfaces:**
- Consumes: `SearchFilterBar`, `ShelfSeriesNavMode`, `ShelfSeriesManagementSheet`, `ShelfFilterState`, `ShelfSourceFilter`
- Replaces: 旧的 `_ShelfHeader` 升级为系列导航头部，旧的 `_ShelfToolbar` 替换为一体化 `SearchFilterBar`。

- [ ] **Step 1: 编写书架系列导航与多维筛选联动的失败/回归测试**

在 `test/ui/shelf_page_test.dart` 中添加测试用例：
1. **Tab 模式切页**：点击系列 Tab 或通过 `PageView` 滑动手势切换到对应系列，只展示该系列书籍；
2. **选择框模式**：在下拉模式下点击标题选择系列，成功切换内容；
3. **一体化筛选与角标**：在 `SearchFilterBar` 中点击筛选按钮展开卡片，勾选“在听”和“本地音频”，验证筛选角标显示“2”，且仅过滤当前系列中的对应书籍；
4. **防空兜底**：当隐藏全部系列且书单无系列时，页面安全降级保底展示「全部」，不崩溃；
5. **更多菜单入口**：右上角「⋮」菜单中提供「管理系列」入口，点击弹出管理抽屉。

- [ ] **Step 2: 运行测试验证失败**

运行: `flutter test test/ui/shelf_page_test.dart`
预期: FAIL。

- [ ] **Step 3: 重构 ShelfPage**

在 `lib/ui/pages/shelf/shelf_page.dart` 中：
1. 提取当前可见系列列表 `visibleSeries`（结合偏好过滤与防空保底）；
2. 构造顶部系列导航：
   - 当 `shelfSeriesNavMode == ShelfSeriesNavMode.tabs`：构建带下划线与小徽标的可滚动 `TabBar`，主体配合 `PageView.builder` 实现横向滑动手势联动；
   - 当 `shelfSeriesNavMode == ShelfSeriesNavMode.dropdown`：构建下拉标题按钮（带箭头的选择框），点击唤出系列快速选择器；
3. 使用 `SearchFilterBar` 替代原分散的搜索与筛选，折叠面板内集成「阅读状态（全部/在听/未听/已完）」、「来源渠道（全部/本地/在线）」与「分类标签（Tag）」，并提供「重置」与「收起」；
4. 顶部更多菜单增加「管理系列」条目，呼出 `ShelfSeriesManagementSheet`。

- [ ] **Step 4: 运行测试验证通过**

运行: `flutter test test/ui/shelf_page_test.dart`
预期: 全部测试 PASS。

- [ ] **Step 5: 提交更改**

```bash
git add lib/ui/pages/shelf/shelf_page.dart test/ui/shelf_page_test.dart
git commit -m "refactor(shelf): integrate SearchFilterBar and series navigation with PageView"
```

---

### Task 5: 书库页（`LibraryPage`）纯粹来源与资产管理转型

**Files:**
- Modify: `lib/ui/pages/library/library_page.dart`
- Delete/Modify: 清理 `lib/ui/pages/library/library_filter.dart` 中废弃的书籍列表过滤（已并入书架）
- Test: `test/ui/library_unified_page_test.dart`
- Test: `test/ui/library_page_test.dart`

**Interfaces:**
- Consumes: `libraryRootsProvider`, `bookSourcesProvider`, `batchRefreshControllerProvider`, `booksProvider`（仅读取总数统计）
- Produces: 纯净来源管理面板，包含刷新胶囊、本地目录卡片、在线书源卡片、资产统计。

- [ ] **Step 1: 编写书库页转型为来源管理面板的测试**

在 `test/ui/library_unified_page_test.dart` 和 `test/ui/library_page_test.dart` 中：
1. 验证书库页不再渲染单本书籍卡片及搜索框；
2. 验证顶部展示“我的书库 · 共 N 册 · 本地 X · 在线 Y”的统计汇总；
3. 验证本地扫描目录卡片（包含路径、重新扫描、添加目录）；
4. 验证在线书源卡片（包含书源数量、管理书源、导入新源）；
5. 验证批量刷新胶囊（`LibraryRefreshCapsule`）正常工作。

- [ ] **Step 2: 运行测试验证失败**

运行: `flutter test test/ui/library_unified_page_test.dart test/ui/library_page_test.dart`
预期: FAIL。

- [ ] **Step 3: 重构 LibraryPage 为纯粹来源管理面板**

重构 `lib/ui/pages/library/library_page.dart`：
1. 移除 `TextField` 搜索框和多行书籍筛选 Chip；
2. 移除 `ListView` 中渲染单本书籍 `library_book_row` 的逻辑；
3. 整体布局重塑为模块化卡片流：
   - 资产概览横幅（总册数、本地册数、在线册数）；
   - `LibraryRefreshCapsule` 在线章节更新区；
   - `LocalRootsSection` 本地音频目录管理；
   - 在线书源管理卡片（导入书源入口、跳转书源管理页）。

- [ ] **Step 4: 运行测试验证通过**

运行: `flutter test test/ui/library_unified_page_test.dart test/ui/library_page_test.dart`
预期: PASS。

- [ ] **Step 5: 提交更改**

```bash
git add lib/ui/pages/library/ test/ui/library_unified_page_test.dart test/ui/library_page_test.dart
git commit -m "refactor(library): transform LibraryPage into pure sources and assets hub"
```

---

### Task 6: 全局回归验证与质量门禁 (Full Verification & QA Gate)

**Files:**
- Verification only

- [ ] **Step 1: 运行全量单元测试与 UI 界面测试**

运行: `flutter test`
预期: 所有测试全量通过（0 failure）。

- [ ] **Step 2: 执行代码静态分析**

运行: `flutter analyze`
预期: 无错误、无告警（No issues found）。

- [ ] **Step 3: 执行架构依赖边界合规性检查**

运行: `dart run tool/ci/check_import_boundaries.dart`
预期: 全部模块边界检查通过。

- [ ] **Step 4: 提交最终集成结果**

```bash
git status
# 确认工作树干净
```
