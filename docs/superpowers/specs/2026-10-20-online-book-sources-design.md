# 在线书源、发现与在线书库

- 日期：2026-10-20
- 状态：设计待实现
- 设计基准：`docs/design-preview/ui-refresh/index.html` · B04–B06（书源 / 发现 / 书源表单）
- 关联文档：`docs/tometone_architecture_requirements.md` §2.4「听书源工坊」、§6 播放、§8 数据模型
- 关联前置：`docs/superpowers/specs/2026-10-20-ui-refresh-shelf-metadata-design.md`（书架、详情、元数据与 sidecar）

## 1. 为什么做

书架与本地元数据已经能回答「我有什么书、这本书讲什么」。下一步要回答「我想听的书从哪里来」：

1. 用户导入「阅读 / Legado」的听书源规则；
2. 在源内发现、搜索，看到封面、作者/演播、集数与简介；
3. 不加入书架也能直接在线听；
4. 加入书架时选择分类；
5. 书库同时管理本地书与书源书，并能刷新列表、目录、信息；
6. 书源失效或内容不完整时，可以换源、刷新或删除，不丢进度。

目标不是「给示例源写一个一次性解析器」，而是**听书源的完整兼容层**。完整兼容是终点，交付按里程碑推进；每个里程碑都可独立使用、独立验收。

## 2. 目标

### 2.1 产品目标

1. 底部导航改为五栏：**书架 / 发现 / 书库 / 纪年 / 设置**。
2. 「发现」是独立 tab：切换书源、浏览该源的发现分类、搜索、查看结果。
3. 在线书详情可直接流式播放，也可加入书架；加入时**多选分类**，分类沿用现有标签体系。
4. 「书库」是本机书与书源书的统一书目总表，来源用标签区分（本地 / 具体书源）；支持按来源、分类、状态筛选。
5. 「书架」只展示主动加入的书；本机书默认加入，但可以从书架移除而不删除书库记录。
6. 书库与在线书详情支持**刷新列表、刷新信息、刷新目录**；刷新不覆盖手动元数据、分类和播放进度。
7. 在线书支持**换源**：选择一组书源，按书名搜索，列出候选，确认后覆盖来源与目录，尽量保留书 ID、分类、进度和手动元数据。
8. 在线播放支持**流式 + 预下载**：默认预下载后 3 章，可在设置中调整（0–10），支持仅 Wi-Fi 与缓存上限。
9. 删除本地书时可选择**删除整个书目录**；必须二次确认，且有书库根 / 其他书的安全护栏。
10. 删除或停用书源时，保留已入库书目和进度；重新启用或重新导入同一 `bookSourceUrl` 可恢复。

### 2.2 兼容目标（终点）

完整兼容 Legado `bookSourceType: 1` 的听书源，包括：

- 导入：JSON 对象 / 数组、URL、本地文件、粘贴、TXT、分享链接；
- 规则语法：Default/JSoup、CSS、XPath、JSONPath、AllInOne 正则、`@js:` / `<js>`；
- 规则操作符：`||`、`&&`、`%%`、`##`、`#####`、列表前置 `-`；
- 请求：GET/POST、相对 URL、请求头、charset、body、bodyJs、timeout、followRedirects、proxy、dnsIp、webView、CookieJar；
- 页面链路：发现、搜索、分页、详情、目录、`nextTocUrl`、正文/音频、`nextContentUrl`；
- JavaScript：Legado 的 `result`、`baseUrl`、`source`、`java.*` 常用桥接；
- 登录：用户主动授权的登录 UI / 登录脚本 / Cookie；
- 音频：单链接与多段链接、请求头透传、HLS 流式播放。

### 2.3 非目标

- 不做普通文本阅读源（`bookSourceType: 0`）与 RSS。
- 不做绕过付费、VIP、验证码、登录保护、反爬、DRM 的能力；遇到此类内容只显示「需要登录/购买，暂不支持」。
- 不内置、不分发书源集合；书源由用户导入。
- 不在 M1 做完整离线下载；M1 只有预下载缓存。
- 不在 M1 做 WebView 动态页、登录、Cookie、代理、TXT/分享链接；这些是后续里程碑。
- 不复制 Legado 源码。Legado 的规则语义按公开文档与测试重建；本仓库当前没有 LICENSE 文件，不能直接引入 GPL 代码。

### 2.4 反目标

- 把示例源硬编码成唯一支持的格式。
- 刷新 / 换源 / 删除时静默丢进度、分类或手动元数据。
- 在 UI 线程做网络或 JS 解析，造成卡顿。
- 把 Cookie、Token、请求头原文写进日志、测试夹具或文档。
- 为了「完整兼容」引入无法测试的巨型分支；每个规则类型必须有合成夹具。

## 3. 关键决策

| 决策 | 结论 |
|---|---|
| 兼容范围 | 只做听书源（`bookSourceType: 1`），但规则语法按完整兼容设计 |
| 交付方式 | 完整兼容为终点，分 M1–M4 里程碑；M1 是可用垂直切片 |
| 在线书身份 | 首次播放或加入书架时写入 `books`，`on_shelf=false` 时只在书库出现，不上书架 |
| 书库 / 书架 | 书库 = 全部书；书架 = `on_shelf=true` 的子集；本机书扫描后默认上架 |
| 分类 | 沿用 `book_tags` 标签；加入书架时多选，可现场新建 |
| 书源与书库根 | 每个在线书源对应一个虚拟 `library_roots`（`type='online'`），复用现有 `books.library_root_id` 外键与唯一索引 |
| 在线章 | `file_path` 用稳定的 `online/<hash>` 绑定键；`source_uri` 存规则求值后的章 URL；`retired` 标记换源后的旧章 |
| 刷新目录 | 只增不删；同源消失的章标记 `missing`，在线书额外 `retired`；不删除进度与统计 |
| 刷新信息 | 只更新非手动的源字段；`book_metadata_overrides` 永远优先 |
| 换源 | 保留 `books.id`；候选确认后替换来源、信息与目录；进度按标题/序号映射，映射失败则回到新书第一章 0 秒并提示 |
| 删除书源 | 软删除，保留虚拟根、书目、章节、进度与缓存；同一 `bookSourceUrl` 重新导入可复活 |
| 删除本地书 | 默认只删记录；勾选后删除**整个书目录**；两次确认；不允许删书库根或含其他书的目录 |
| 在线播放 | 章节音频 URL 播放时解析，不持久化带签名的播放地址；流式 + 本地预下载 |
| 预下载 | 默认 3 章，设置 0–10；仅 Wi-Fi 开关；缓存上限默认 2 GB；HLS 暂不预下载 |
| 发现搜索 | 只搜当前书源；跨源通过「换源」的源多选完成 |
| JS 运行时 | 抽象 `JsRuntime`；优先 QuickJS 方案，M1 先实现示例源需要的同步子集，M2 起补 `java.*` 桥接 |
| 网络明文 | 允许 HTTP 书源但导入/启用时明确警告；HTTPS 优先 |
| 隐私 | 书源请求只在用户启用后发起；请求头/ Cookie 日志脱敏；不内置遥测 |

## 4. 信息架构与导航

### 4.1 五栏

顺序：**书架 / 发现 / 书库 / 纪年 / 设置**。

- 320dp 下仍使用 Material `NavigationBar`，标签两字，禁止换行；大字号下用 `labelBehavior: alwaysShow` 并依赖 Material 的缩放。
- `AppTab` 增加 `discovery`；`AppShell._pageFor` 增加 `DiscoveryPage`。
- 现有「书架空态去书库」的引导改为「去发现找书 / 去书库添加本机目录」两个入口。

### 4.2 发现

自上而下：

1. 页首：`发现` 标题；当前书源卡（图标、名称、分组、健康状态、最近同步、`切换`）。
2. 没有书源时：空态「还没有书源」+ `导入书源` + 简短说明「支持 Legado 听书源 JSON」。
3. 搜索框：提交式搜索；有结果时显示「搜索结果 · 来自 X」与清除按钮。
4. 分类 chips：来自 `exploreUrl` 的组名（示例：热门 / 最新 / 推荐 / 连载 / 评书）；横向滚动。
5. 结果列表：封面、书名、作者/演播、分类/集数、来源、`加入` / `已在书库`。
6. 触底加载下一页；下拉刷新当前分类或搜索结果。
7. 错误态：保留已加载内容，顶部提示「本次加载失败」+ 重试；空结果给「换个关键词」。
8. 结果点击进入在线书详情；`加入` 直接打开分类选择弹层。

### 4.3 书库

书库不再展示「书库根卡片」，而是统一书目列表：

1. 页首：`我的书库` + 总数/本地数/在线数；右侧搜索、刷新、来源管理。
2. 筛选：`全部 / 本地 / 在线` 来源 chips；`分类` 与 `状态` 下拉；搜索框（书名/作者/演播/简介/标签）。
3. 书目行：封面、书名、作者/演播、来源标签、分类、进度、缺失/来源不可用标记；`⋮` 菜单：刷新信息、刷新目录、换源、移出书架、从书库删除。
4. 空态：无书且无来源 → 导入书源 / 添加本机目录；有来源无书 → 去发现找书。
5. 刷新入口：
   - 顶部刷新：刷新全部已启用在线书 + 重扫全部本机根；
   - 来源管理内：按源刷新 / 按根重扫；
   - 单本详情：刷新信息 / 刷新目录。
6. 来源管理页：
   - 网络书源：名称、分组、启用、健康、已存书目数、最近刷新；添加/编辑/测试/删除。
   - 本机目录：现有根管理（添加、扫描、重命名、移除、浏览）。
   - 本机目录的「移除根」仍是现有级联删除语义；网络书源删除是软删除、保留书目。

### 4.4 在线书详情

复用现有详情页的视觉骨架，按 `book.isOnline` 分支：

- 顶部：返回、来源标签（本地 / 书源名）、`⋮`。
- 封面：在线封面用网络缓存；失败回退字标。
- 元数据：书名、作者、演播、分类标签、简介、来源分类/集数/连载状态。
- 来源状态条：`来源正常` / `来源已停用` / `来源已删除` / `本次刷新失败`；提供启用、重试、换源入口。
- 主操作：
  - 未上架：`加入书架`（分类多选）+ `立即收听`。
  - 已上架：`继续收听` / `开始收听`；次操作 `移出书架`。
- 目录：卷/章列表；当前章高亮；缺失/已下架章置灰并标注；点可用章从该章播放。
- `⋮`：刷新信息、刷新目录、换源、编辑信息、移出书架、从书库删除。
- 在线书不写书根 sidecar；元数据编辑只写覆盖层。

### 4.5 本机书详情

保持现有功能，新增：

- `⋮`：移出书架、从书库删除（可选删除整个书目录）、刷新信息（重新读 sidecar / 扫描元数据）、刷新目录（重扫本书目录）。
- 删除目录的二次确认与护栏见 §8.5。

### 4.6 加入书架 / 分类选择

- 底部弹层：`加入书架` 标题 + 书名。
- 已有分类 chips，多选；支持搜索和「新建分类」；允许不选（未分类）。
- 保存后：`on_shelf=true`，写入 `book_tags`；如果在线书尚未抓取目录，先抓取，失败也允许加入，标记「目录待刷新」。
- 已在书库但未上架：直接上架；已在书架：只更新分类。
- 分类沿用标签；不新建分类表。

## 5. 书源导入与管理

### 5.1 导入方式

三种入口共用同一套解析 / 校验 / 预览：

1. **URL**：GET 拉取；支持重定向；超时 20s；响应上限 5 MB；必须是 JSON。
2. **本地文件**：系统文件选择器；`.json`；读取字节后按 UTF-8（带 BOM 兼容）解析。
3. **粘贴**：多行文本框 / 剪贴板；直接解析文本。

TXT、`legado://import/bookSource?...` 分享链接放 M3。

### 5.2 JSON 形态

- 单个对象或对象数组。
- 数组按批量导入处理：预览每条的名称、URL、类型、重复状态，逐条勾选。
- 保留完整 `raw_json`；编辑时以原始 JSON 为准，表单只改已知字段，未知字段不得丢。
- 必填校验：
  - `bookSourceName` 非空；
  - `bookSourceUrl` 非空且规范化后唯一；
  - `bookSourceType == 1`（缺省按 0 处理并拒绝，文案「只支持听书源」）；
  - `header` 若存在必须是 JSON 对象；
  - 至少有 `searchUrl` 或 `exploreUrl`；
  - 至少有 `ruleBookInfo`、`ruleToc`、`ruleContent` 的可播放链路。
- 规则字段缺失时逐条给警告；不可播放的源拒绝保存，并指出缺哪一段。
- 重复 `bookSourceUrl`：预览中标记「已存在」；提供 `覆盖` / `跳过`；覆盖保留本地 id、启用状态、已存书目关联。
- `enabled` 尊重源 JSON；`enabledExplore` 缺省 true。

### 5.3 书源管理

- 列表：启用 / 停用 / 异常分组；搜索；按 `bookSourceGroup` 筛选。
- 单条：名称、分组、类型 `LEGADO`、已存书目数、最近成功、最近错误、连续失败次数。
- 操作：启用开关、编辑、测试、刷新、删除。
- 编辑：名称、分组、启用、`exploreUrl`、`searchUrl`、请求头、原始 JSON；保存前可测试。
- 测试：优先跑第一个发现分类；没有 `exploreUrl` 时用 `测试` 关键词搜索；报告延迟、结果数、示例书名；失败给出可读原因。
- 删除：软删除 `deleted_at`；保留虚拟根、书目、章节、进度、缓存；发现页不再出现；书库中的书标「来源已删除」；重新导入同一 `bookSourceUrl` 时复活并重新关联。
- 停用：保留数据；未缓存章节不可播放/刷新；已缓存章节允许离线播放；书库标「来源已停用」。

### 5.4 健康与限速

- `concurrentRate` 支持 `1000`（间隔 1s）与 `20/60000`（60s 内 20 次）两种常见形式；未配置时用保守默认（串行 + 300ms 间隔）。
- 请求失败重试：GET 最多 2 次；POST 不自动重试（避免重复副作用），除非明确幂等。
- 连续失败 3 次在来源管理中标黄；不自动停用，由用户决定。
- 错误分类：DNS / 超时 / HTTP 状态 / 编码 / JSON 解析 / 规则解析 / 空结果 / 需要登录 / 需要 VIP。

## 6. 发现、搜索与详情

### 6.1 发现分类

- 解析 `exploreUrl`：按行或 `&&` 分隔；`名称::URL`；URL 中保留 `{{page}}`。
- 没有 `exploreUrl` 或有 `enabledExplore=false`：发现页只显示搜索。
- 分类 chips 使用源内顺序；默认选中第一个；记住上次选择（进程内即可，不落库）。
- 分页：首次 page=1；触底 page+1；返回空列表或不足一页即停止；不同源可能忽略 page，做去重保护。

### 6.2 搜索

- 只搜当前书源。
- 提交后 page=1；触底翻页；空关键词不请求。
- `searchUrl` 支持 `{{key}}`、`{{page}}`、URL 选项（POST / headers / body / charset）。
- 搜索结果字段：`name` 必填，`bookUrl` 必填；`author`、`coverUrl`、`intro`、`kind`、`wordCount`、`lastChapter` 可空。
- `bookUrl` / `coverUrl` 相对地址按当前请求的最终 URL 解析。
- 同一页按规范化 `bookUrl` 去重；跨页重复保留第一次。
- 结果加入状态：
  - `已在书架`：`on_shelf=true`；
  - `已在书库`：记录存在但未上架；
  - `加入`：新书。

### 6.3 在线详情抓取

- 打开详情或加入书架时，按 `bookUrl` 抓 `ruleBookInfo`；字段写入 `books` 的源字段。
- `tocUrl` 缺省时回退 `bookUrl`。
- 目录按 `ruleToc` 抓取；M1 只抓第一页，M2 支持 `nextTocUrl`。
- 章节顺序：按源返回顺序；列表规则前置 `-` 时反转；`chapterIndex` 从 0 连续重排。
- 详情抓取失败：仍允许加入书架，但目录为空，详情显示「目录待刷新」；不允许播放。
- 在线书只有一本逻辑卷「正文」；卷名不伪造。

### 6.4 结果 / 详情字段展示

| 字段 | 来源 | 缺失时 |
|---|---|---|
| 书名 | `ruleBookInfo.name` / 搜索结果 | 必填，缺失则丢弃该条 |
| 作者 | `author` | 隐藏 |
| 演播 | `narrator`（部分源用 `author`） | 隐藏 |
| 封面 | `coverUrl` | 字标兜底 |
| 简介 | `intro` | 「暂无简介」 |
| 分类 | `kind` | 隐藏 |
| 字数/集数 | `wordCount` | 用目录章数 |
| 连载状态 | `lastChapter` / `status` 若有 | 隐藏 |
| 来源 | 书源名 | 必填 |

## 7. 数据模型（schema v3）

### 7.1 新增 `book_sources`

| 列 | 类型 | 说明 |
|---|---|---|
| `id` | TEXT PK | ULID |
| `library_root_id` | TEXT NOT NULL FK → `library_roots.id` | 每个源一个虚拟根；唯一 |
| `source_url` | TEXT NOT NULL UNIQUE | `bookSourceUrl`，规范化后唯一 |
| `name` | TEXT NOT NULL | `bookSourceName` |
| `group_name` | TEXT NULL | `bookSourceGroup` |
| `source_type` | INTEGER NOT NULL | 只接受 1 |
| `enabled` | BOOLEAN NOT NULL | 用户启用状态 |
| `enabled_explore` | BOOLEAN NOT NULL | `enabledExplore` |
| `header_json` | TEXT NULL | 解析后的请求头 JSON |
| `raw_json` | TEXT NOT NULL | 完整源 JSON，编辑/导出的真源 |
| `explore_url` | TEXT NULL | 投影字段 |
| `search_url` | TEXT NULL | 投影字段 |
| `js_lib` | TEXT NULL | 预留 |
| `custom_order` | INTEGER NOT NULL | 排序 |
| `concurrent_rate` | TEXT NULL | 原始限速串 |
| `last_test_at` | DATETIME NULL | |
| `last_test_ok` | BOOLEAN NULL | |
| `last_test_latency_ms` | INTEGER NULL | |
| `last_success_at` | DATETIME NULL | |
| `last_error` | TEXT NULL | 已脱敏 |
| `consecutive_failures` | INTEGER NOT NULL DEFAULT 0 | |
| `deleted_at` | DATETIME NULL | 软删除 |
| `created_at` / `updated_at` | DATETIME NOT NULL | |

索引：`source_url` 唯一；`library_root_id` 唯一；`deleted_at`；`enabled`。

在线源的虚拟根（`library_roots.type='online'`）**不进入**本机存储链路：

- `LibraryRootService`、`StorageProviderFactory`、扫描器、目录浏览只处理 `local` / `saf` / `webdav`；
- `libraryRootsProvider` 给书架/书库的「本地来源」列表过滤掉 `online`；
- 在线书起播走 `OnlineChapterSourceResolver`，不调用 `mediaSourceResolverForRootProvider`；
- 来源管理页单独列出在线源，不复用本机根的扫描按钮。

### 7.2 `books` 增列

| 列 | 类型 | 说明 |
|---|---|---|
| `on_shelf` | BOOLEAN NOT NULL DEFAULT true | 本地旧书迁移为 true；在线新书默认 false |
| `source_id` | TEXT NULL FK → `book_sources.id` ON DELETE SET NULL | 本地书为 null |
| `cover_url` | TEXT NULL | 在线封面；本地仍用 `cover_path` |
| `description` | TEXT NULL | 源简介；手动覆盖优先 |
| `kind` | TEXT NULL | 源分类 |
| `word_count` | TEXT NULL | 源字数/集数文本 |
| `source_status` | TEXT NULL | 连载/完结等源状态 |
| `last_chapter` | TEXT NULL | 源最新章节 |
| `source_updated_at` | DATETIME NULL | 最近信息刷新 |

`source_type` 对在线书写 `'online'`；`source_uri` 存规范化 `bookUrl`；`library_root_id` 指向该源的虚拟根；`root_path` 用规范化 `bookUrl` 作为书在虚拟根内的唯一键。

### 7.3 `chapters` 增列

| 列 | 类型 | 说明 |
|---|---|---|
| `retired` | BOOLEAN NOT NULL DEFAULT false | 换源/源内下架后的旧章；默认不展示、不进队列 |
| `is_vip` | BOOLEAN NOT NULL DEFAULT false | 源标记需要购买/登录；不解锁，只展示 |

在线章：

- `file_path = 'online/' + sha1(normalizedChapterUrl)`；
- `source_uri = normalizedChapterUrl`；
- `chapter_index` 为当前顺序；
- `duration_ms` 播放解析后回填（可选）；
- `missing=true` 表示源内消失；在线书同时 `retired=true`。

### 7.4 新增 `audio_cache_entries`

| 列 | 类型 | 说明 |
|---|---|---|
| `chapter_id` | TEXT PK FK → `chapters.id` ON DELETE CASCADE | 一章一条 |
| `book_id` | TEXT NOT NULL | 便于按书清理 |
| `source_id` | TEXT NULL | |
| `remote_url` | TEXT NOT NULL | 已解析音频地址；日志脱敏 |
| `file_path` | TEXT NOT NULL | 应用缓存目录内 |
| `bytes` | INTEGER NOT NULL | |
| `status` | TEXT NOT NULL | `downloading` / `complete` / `failed` |
| `etag` | TEXT NULL | 预留 |
| `created_at` / `last_accessed_at` | DATETIME NOT NULL | LRU 淘汰 |

### 7.5 新增 `app_settings`

`key TEXT PK, value TEXT NOT NULL, updated_at DATETIME NOT NULL`。

首批 key：

- `prefetch_chapters` 默认 `3`；
- `prefetch_wifi_only` 默认 `true`；
- `audio_cache_limit_mb` 默认 `2048`；
- `source_consent_v1`；
- `last_discovery_source_id`。

### 7.6 预留表（M2/M3）

- `source_variables(source_id, key, value)`：`source.put/get` / `@put/@get`。
- `source_login_state`：只存安全存储引用，不存密码/Cookie 原文。
- 不在 M1 建，避免空表。

### 7.7 迁移

- v2 → v3 只增列、增表，不删列、不重建。
- 顺序：先建 `book_sources`（依赖 `library_roots`），再给 `books` 加 `source_id` 外键列，再给 `chapters` 加列，最后建缓存与设置表。
- 旧 `books` 全部 `on_shelf=true`、`source_id=null`。
- 旧 `chapters` 默认 `retired=false`、`is_vip=false`。
- 生成代码用 `dart run build_runner build`。
- 必须有 v2 → v3 迁移测试：旧书、章、进度、标签、偏好不丢。

### 7.8 视图扩展

`BookSummary` 增加：

- `bool onShelf`
- `String? sourceId`
- `String? sourceName`
- `String? sourceType`（`local` / `saf` / `online`）
- `bool sourceAvailable`
- `String? coverUrl`
- `String? kind`
- `String? wordCount`
- `String? sourceStatus`
- `String? lastChapter`
- `DateTime? sourceUpdatedAt`
- `bool isOnline`

`BookDetail` 增加源字段与 `retiredChapterCount`；`ChapterView` 增加 `sourceUri`、`isVip`、`retired`。

### 7.9 查询端口

`LibraryQueries` 扩展：

```dart
Future<List<BookSummary>> listBooks({
  bool? onShelf,
  String? sourceId,
  String? tag,
  ShelfStatus? status,
  String? search,
  int limit = 50,
  int offset = 0,
});

Future<int> countBooks({bool? onShelf, String? sourceId, String? tag, String? search});
Future<List<BookSourceView>> listBookSources();
Future<void> setBookShelf(String bookId, {required bool onShelf, List<String>? tags});
Future<void> deleteBookRecord(String bookId);
```

在线书写入 / 刷新 / 换源放在 `OnlineLibraryService`，不塞进只读查询端口：

```dart
Future<String> upsertOnlineBook({
  required BookSource source,
  required SourceBookInfo info,
  required List<SourceChapter> chapters,
  required bool onShelf,
  List<String> tags = const [],
});

Future<RefreshReport> refreshInfo(String bookId);
Future<RefreshReport> refreshToc(String bookId);
Future<SwitchReport> switchSource({
  required String bookId,
  required List<String> sourceIds,
  required String keyword,
});
```

## 8. 生命周期与刷新语义

### 8.1 在线书首次入库

触发点：在线详情页「立即收听」或「加入书架」。

1. 按 `(source_id, normalized(bookUrl))` 查重；已有则复用 `books.id`。
2. 没有则创建：
   - `books.id` 新 ULID；
   - `library_root_id` = 源的虚拟根；
   - `root_path` = 规范化 `bookUrl`；
   - `source_type='online'`、`source_id`、`source_uri=bookUrl`；
   - `on_shelf=false`；
   - `title` 先用搜索结果 / 源详情；
   - 写入源字段（无手动的字段才写）。
3. 抓详情 + 目录；成功则写章节；失败允许保留书，目录为空。
4. `on_shelf=true` 时写 `book_tags`；未上架时不上书架，但出现在书库。
5. 播放时若还没有章节，先抓目录；仍失败则不允许播放。

### 8.2 刷新信息

- 重新请求 `ruleBookInfo`。
- 更新 `books` 的源字段；`book_metadata_overrides` 有值的字段不动。
- 封面 URL 变化时更新 `cover_url`，旧网络缓存可继续用；不删用户本地封面。
- 成功写 `source_updated_at`、清 `last_error`、重置连续失败；失败写 `last_error`、连续失败 +1，原数据保留。
- 不触碰目录、进度、标签。

### 8.3 刷新目录

- 重新请求 `ruleToc`（M2 支持 `nextTocUrl`）。
- 匹配顺序：
  1. 规范化 `source_uri`（章 URL）相同；
  2. 归一化标题相同（去空白、全半角、大小写）；
  3. 同 `chapter_index` 且标题相似；
  4. 新建。
- 匹配到的章：更新标题、`chapter_index`、`is_vip`、`missing=false`、`retired=false`。
- 新章：插入。
- 本次目录中不存在的旧章：
  - 在线书：`missing=true`、`retired=true`；
  - 本机书：`missing=true`，保留展示。
- 不删除章节记录，避免进度 / 收听记录被级联删除。
- 进度所在章若被 retired：保留进度；详情提示「当前章已从源中移除，可换源或从新章开始」。
- 更新 `books.total_chapters` 为 active（非 retired）章数；`total_duration_ms` 不变（在线时长未知）。
- 失败保留原目录，标记本次失败。

### 8.4 刷新列表（书库批量）

- 对象：某个在线书源下全部 `on_shelf` 与未上架但在书库的书；本机根另走重扫。
- 流程：先信息、后目录；并发默认 2，尊重源 `concurrentRate`。
- UI 进度：总数、完成数、成功/失败数、当前书名；可取消。
- 单本失败：保留原数据，记录错误；不中断其他书。
- 完成：汇总「成功 x / 失败 y」；失败列表可展开、可重试。
- 手动元数据、标签、进度不动。

### 8.5 删除

**从书架移除**

- `on_shelf=false`；保留书、章、进度、标签、缓存。
- SnackBar + 撤销（5s）。

**从书库删除在线书**

- 确认弹窗：书名、来源；说明「会删除书目、目录、进度与缓存，不影响书源」。
- 删除 `books`（级联章节、进度、偏好、标签、缓存记录）；删除缓存文件。
- 收听记录按现有级联语义处理；若后续要保留统计，另立里程碑改造。

**从书库删除本机书**

1. 第一层确认：书名、来源根、路径；复选框 `同时删除整个书目录`（默认不勾）。
2. 不勾：只删 `books` 记录（级联章节、进度、偏好、标签）；提示「下次扫描本机目录时，这本书会重新出现」。
3. 勾选：二次确认，展示绝对路径、文件数、总大小、警告「目录内所有文件都会被永久删除，包括非音频文件」；要求再勾选「我确认删除整个目录」。
4. 护栏：
   - 书根等于书库根 → 禁止删除文件；
   - 目录下还有书库中的其他书 → 禁止删除文件；
   - provider 不支持删除（SAF 只读）→ 禁用并说明；
   - 不跟随符号链接。
5. 书根是单文件（单音频书）时，删除该文件；语义与目录版相同。
6. 先删目录/文件，成功后再删数据库记录；失败保留记录并报错，便于重试。
7. 删除成功后清理缓存、封面；不从书架单独留残影。

**存储删除能力**

现有 `StorageProvider` 契约是只读 + 复制出，不包含删除。本轮增加一个**可选能力**，不强行给所有 provider 加方法：

- `ProviderCapabilities` 增 `supportsDelete`；
- 单独的 `StorageDeletionProvider` 接口提供 `deleteTree(path)`；
- `LocalStorageProvider` 与可写的 SAF 实现该接口；只读 SAF 不实现；
- `LibraryRootService` 在删除前检查能力；UI 用能力决定复选框是否可用；
- 删除后不调用扫描器自动重建；下一次用户重扫才会重新出现。

**删除书源**

- 软删除；见 §5.3。不删除书、章、进度、缓存。
- 重新导入同一 `bookSourceUrl`：清 `deleted_at`、更新 raw、重新启用（尊重新 JSON 的 `enabled`），已存书自动恢复关联。

### 8.6 换源

入口：在线书详情 `⋮` → `换源`。

1. 弹层列出所有已启用书源（可多选，默认全选）；至少选一个。
2. 关键词默认当前书名；可编辑。
3. 并行搜索（并发 2），按源分组展示候选：封面、书名、作者/演播、集数、来源、匹配度。
4. 候选排序：书名完全相等 > 包含 > 作者相同 > 其他；不自动选。
5. 用户选一个候选 → 预览差异（来源、章节数、标题差异）→ 确认。
6. 目标源已有同书（`source_id + normalized(bookUrl)` 命中另一条 `books`）：M1 直接阻止并提示「目标源已有这本书，请先在书库中打开它」，不创建重复记录；合并两条记录留到后续。
7. 执行：
   - 抓新源详情 + 目录；
   - 在事务中更新 `books` 的源字段、`source_id`、`library_root_id`、`root_path`、`source_uri`；
   - 旧章节全部 `retired=true`（不删，保进度/统计）；
   - 新章节插入；如果同 URL 已存在则复用；
   - 进度映射：标题完全匹配 → 保留位置；同序号 → 保留位置；否则新书第一章 0 秒；
   - 更新 `playback_progress.chapter_id`；
   - 清空本书音频缓存（旧源音频不可复用）；
   - 保留 `books.id`、`on_shelf`、标签、手动元数据、偏好、收听记录。
8. 失败：整体回滚，旧源数据不变；给出错误。
9. 结果提示：`已换到「X」；进度已对齐到第 N 章` 或 `已换源，但未找到对应章节，已从第一章开始`。

## 9. 规则引擎架构

### 9.1 分层

```
contracts/source/         SourceEngine 接口、请求/响应值对象
domain/sources/           BookSource、SourceBookInfo、SourceChapter、候选、报告
modules/source_legado/    规则解析、JSONPath/CSS/XPath/Default、JS、HTTP、Cookie、WebView
app/sources/              书源管理、在线书入库、刷新、换源、预下载编排
ui/pages/discovery/       发现、书源管理、导入表单
ui/pages/library/         书库总表、来源管理
```

`SourceEngine`：

```dart
abstract interface class SourceEngine {
  Future<SourceExplorePage> explore(BookSource source, ExploreCategory category, int page);
  Future<SourceSearchPage> search(BookSource source, String keyword, int page);
  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl);
  Future<List<SourceChapter>> toc(BookSource source, SourceBookInfo info);
  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter, SourceBookInfo info);
  Future<SourceTestResult> test(BookSource source);
}
```

所有方法接收 `BookSource`，不读全局状态；HTTP / JS 运行时通过构造注入，测试可替换。

### 9.2 规则处理管线

1. **URL 选项**：把 `url,{"method":...}` 拆成 URL + 选项；相对 URL 用 `baseUrl` 解析；`{{key}}` / `{{page}}` / `{{...}}` 模板求值。
2. **请求**：统一 `SourceHttpClient`（headers、charset、method、body、timeout、redirects；M2 加 proxy/dns/webView）。
3. **规则求值**：
   - 标记识别：`@js:` / `<js>`、`@css:`、`@XPath:` / `//`、`@Json:` / `$.`、`:` AllInOne、默认 JSoup、`@@`；
   - 组合操作符：`||`、`&&`、`%%`；
   - 净化：`##`、`#####`；
   - 列表反转：前置 `-`；
   - 模板内未标记表达式按 JS 求值。
4. **结果归一化**：字符串、列表、Map；空值/空列表视为失败；相对 URL 解析；HTML 实体解码。
5. **错误包装**：`SourceRuleError(stage, rule, message)`，UI 只显示阶段与可读原因，不显示请求头。

### 9.3 M1 规则子集

必须支持示例源：

- JSONPath：`$.items[*]`、`$.title`、`$.results[*]`、`$.chapters[*]`、`$.play_url`；
- `||` 回退；
- `{{key}}`、`{{page}}`；
- `searchUrl` 的 POST JSON body + headers；
- `@js:`：`baseUrl`、`result`、`String.match`、字符串拼接、属性访问；
- `exploreUrl` 多行 `名称::URL`；
- `chapterUrl` 返回带 URL 选项的字符串；
- `ruleContent.content` 从播放响应取 `play_url`。

M1 不要求 CSS/XPath/Default/正则/完整 JSONPath/`java.*`/Cookie/WebView；但接口必须允许后续插入，不得把 JSONPath 写死在服务层。

### 9.4 JS 运行时

- 抽象 `JsRuntime`：
  ```dart
  Future<Object?> evaluate(String script, JsContext context);
  ```
- `JsContext` 注入：`result`、`baseUrl`、`page`、`key`、`source` 变量、`java` 桥接。
- M1：QuickJS 适配层，支持同步脚本、JSON 对象、字符串/正则/数组常用方法；`java` 先不注入。
- M2：`java.ajax` / `java.getString` / `java.getStringList` / `java.getElements` / `java.setContent` / base64 / md5 / timeFormat / `source.put/get`。
- 并发模型：JS 在独立 worker isolate 运行；`java.ajax` 从 worker 发请求到网络 isolate 并阻塞等待结果，UI isolate 不阻塞。M1 不需要网络桥，先同步求值。
- 包选择先做 spike：优先 `quickjs_engine`（QuickJS-NG，Android/iOS/桌面），备选 `flutter_js`；在 Android 真机验证 isolate 内运行与二进制体积后再定。
- JS 失败：返回 `SourceRuleError`，不把异常抛到 UI 线程；超时 5s 中断（M2）。

### 9.5 HTML / JSON / 正则

- HTML：`package:html` + CSS 选择器；Default/JSoup 规则自写解析器；XPath 用成熟 Dart 包或自写受限实现。
- JSON：优先成熟 JSONPath 包；不足则自写，必须有 `$.a.b[*].c`、数组索引、通配、递归下降、过滤表达式的最小测试集。
- 正则：AllInOne `:` 与 `##` 净化分开实现；正则编译失败按规则错误处理。
- 编码：`charset` 选项支持 UTF-8 / GBK / GB18030；无法识别时按 UTF-8 + replacement。

### 9.6 音频解析

- `ruleContent.content` 结果：
  - 字符串 URL；
  - JSON `{"url": "...", "headers": {...}}`；
  - 字符串数组（多段；M1 取第一段，M2 支持顺序拼接）。
- 去掉 `##` 净化后的空白与引号。
- 相对地址按章 URL 解析。
- 请求头 = 源全局 header + 章 URL 选项 headers + 内容 JSON headers，后者覆盖前者。
- 不持久化解析后的音频 URL（可能带签名/时效）；只存章 URL。
- `is_vip=true` 的章不自动尝试；显示「需要登录/购买，暂不支持」。

### 9.7 兼容矩阵

| 能力 | M1 | M2 | M3/M4 |
|---|---|---|---|
| JSON 导入（对象/数组、URL/文件/粘贴） | ✅ | | |
| TXT / 分享链接 / 导出 | | | ✅ |
| JSONPath 基础 | ✅ | | |
| JSONPath 完整 | | ✅ | |
| CSS / Default / XPath / AllInOne 正则 | | ✅ | |
| `||` / `{{}}` / `##` | ✅ | 完整 | |
| `&&` / `%%` / `#####` / 反转 | | ✅ | |
| `@js:` 本地脚本 | ✅ | | |
| `<js>` / jsLib / source 变量 | | ✅ | |
| `java.*` 桥接 | | 基础 | 完整 |
| POST / headers / charset | ✅ | | |
| proxy / dns / bodyJs / webView | | | ✅ |
| Cookie / 登录 | | 基础 | 完整 |
| 发现 / 搜索 / 详情 / 目录 / 音频 | ✅ | | |
| 分页 / nextTocUrl / nextContentUrl | 基础 | ✅ | |
| 换源 / 刷新 / 删除 / 预下载 | ✅ | | |
| HLS 流式 | ✅ | | |
| HLS 预下载 / 多段音频 | | | ✅ |
| 完整离线下载 | | | 后续 |

## 10. 播放与预下载

### 10.1 在线播放链路

- 在线书不预构建全量音频源；`ChapterSequencer` 只保存章元数据，播放到某章时由 `OnlineChapterSourceResolver` 解析。
- `PlaybackRequest` / `PlaybackController` 增加可注入的按章解析器；本机书仍走现有 `MediaSourceResolver`，行为不变。
- 解析顺序：
  1. 缓存完整文件 → `LocalFileSource`；
  2. 无缓存 → 调 `SourceEngine.resolveAudio` → `RemoteUrlSource(url, headers)`；
  3. 解析失败 → `EngineError` / 可读提示，保留当前章与进度。
- 请求头透传给 just_audio；不把 header 写入日志。
- 队列跨章连播、上一曲、片头片尾、倍速、睡眠、进度写入沿用现有 `PlaybackController`。
- 在线书 `duration` 未知时允许 `null`；播放器显示「时长未知」而不是 0。

### 10.2 预下载

- 触发：某章开始播放 / 恢复播放后，后台预取后续 N 章（默认 3）。
- N 来自 `app_settings.prefetch_chapters`，范围 0–10；0 关闭。
- 仅 Wi-Fi 开关默认 true；非 Wi-Fi 时跳过预下载，不影响当前流式播放。
- 并发下载 2；单章失败重试 1 次，仍失败标记，不影响其他章。
- 下载到应用缓存目录：`audio_cache/<bookId>/<chapterId>.<ext>`；先写 `.part` 再原子改名。
- HLS（`.m3u8`）不预下载，直接流式。
- 切换章节时先查缓存；缓存命中直接本地播放。
- 缓存上限默认 2048 MB；按 `last_accessed_at` LRU 淘汰；设置页可清理全部缓存。
- 换源、删除书、删除源缓存时清理对应文件与记录。
- 预下载不是「离线下载」：不保证整本可离线，不提供下载管理页（后续里程碑）。

### 10.3 错误与降级

| 场景 | 行为 |
|---|---|
| 无网络、无缓存 | 提示「网络不可用，且这一章没有缓存」+ 重试 |
| 音频 403/404 | 重新解析一次；仍失败提示「音频地址失效，可刷新目录或换源」 |
| 书源停用/删除 | 缓存可播；未缓存提示「来源不可用」+ 去启用/换源 |
| 章被 retired | 当前进度保留；提示从新章开始或换源 |
| VIP/登录 | 显示限制说明，不尝试绕过 |
| 预下载失败 | 不打断播放；该章播到时再重试 |

## 11. UI 细节与无障碍

- 视觉沿用方向 A「宣纸旧卷」；发现页与书源页复用 B04–B06 的结构与信息密度。
- 320dp、字体缩放 2.0、深色模式：所有新页面必须无溢出；结果行、来源卡、分类 chips 可换行/横向滚动。
- 网络封面：固定宽高比 + 字标兜底；加载失败不抖动。
- 所有图标按钮有 tooltip / semantics；删除、刷新、换源有明确文案。
- 加载态用骨架或轻量进度，不用整页转圈盖住已加载内容。
- 错误文案不出现堆栈、URL 查询参数、Cookie、Token。
- 书库大列表：分页 50/100，滚动增量加载；筛选变化重置分页。
- 空态区分：没有来源 / 有来源没书 / 筛选无结果 / 搜索无结果。

## 12. 隐私、安全与合规

- 首次启用/导入网络书源时显示一次性说明：应用会按规则请求该源与音频；用户需确保有权访问；不支持绕过付费、验证码、DRM。
- 不内置书源，不提供书源市场，不自动抓取用户未启用的源。
- 请求头、Cookie、Token 只在内存/安全存储中使用；日志用 `Redactor` 脱敏；测试夹具不含真实 session。
- 书源 `header` 可能含会话标识：导入时原样保存到 `raw_json`/`header_json`，但文档、日志、错误上报不展示。
- HTTP 明文源：允许但显示警告；Android 网络安全配置需允许用户导入的 HTTP 源（具体实现用 network security config，不全局放开无感知）。
- 登录/Cookie（M3）：只支持用户主动授权的登录；凭据放平台安全存储；不实现绕过。
- 删除文件是不可逆操作：默认不勾选、显示路径与大小、二次确认、护栏。

## 13. 测试与验收

> 测试执行需用户明确许可；本设计只定义应写的测试，不代表已授权运行。

### 13.1 单元测试

- 书源 JSON 校验：单对象/数组、缺字段、类型非 1、重复 URL、header 非法。
- 模板：`{{key}}`、`{{page}}`、未标记 JS、`{{...}}` 中的 JSONPath。
- URL 选项：GET/POST、body、headers、charset、相对 URL。
- 操作符：`||`、`&&`、`%%`、`##`、`#####`、反转。
- JSONPath：示例源全部路径 + 边界。
- 规则求值：示例源搜索/发现/详情/目录/音频，使用脱敏 fixture。
- JS：示例 `@js:` 的 baseUrl 提取、result.index、字符串拼接；失败/超时。
- 章节 diff：新增、标题变化、URL 变化、消失、重排；进度保留。
- 换源映射：标题匹配、序号匹配、无匹配、回滚。
- 缓存：LRU、上限、失败重试、换源清理。
- 迁移：v2 → v3。

### 13.2 UI 测试

- 五栏导航；320dp / 大字体重未溢出。
- 发现：无源空态、有源分类、搜索、加载更多、错误重试、加入状态。
- 书源导入：URL/文件/粘贴、批量、重复覆盖、校验错误。
- 加入书架：多选分类、新建分类、未分类。
- 书库：本地/在线混排、来源筛选、搜索、刷新进度、删除对话框。
- 详情：在线/本地分支、换源候选、来源不可用、VIP 章。
- 删除：默认不删文件、二次确认、根护栏、SAF 禁用。

### 13.3 集成 / 手工验收

- 用示例「听友听书」源（敏感 header 不入库）跑通：导入 → 发现 → 搜索「诡秘之主」→ 详情 → 直接听 → 预下载 → 加入书架选分类 → 书库刷新信息/目录 → 换源。
- 本地目录：扫描 → 书架 → 书库混排 → 删除记录（文件保留）→ 重扫复现 → 删除整个目录（二次确认）。
- 断网 / 超时 / 403 / 空结果 / 源停用 / 源删除。
- 真机 Android：音频请求头、后台播放、缓存目录、SAF 删除限制。

## 14. 里程碑

### M1：可用垂直切片

- schema v3；书源表、在线书字段、retired、缓存、设置。
- 书源导入（JSON URL/文件/粘贴、批量、重复、校验）。
- 书源管理（列表、启用、编辑、测试、软删除）。
- 发现页（五栏导航、源切换、分类、搜索、结果、基础分页）。
- 在线详情、直接流式播放、加入书架多选分类。
- 书库统一书目列表；书架 `on_shelf` 过滤；移除书架。
- 刷新信息/目录、批量刷新列表、换源、删除（本地目录可选删除 + 二次确认）。
- 预下载 3 章、仅 Wi-Fi、缓存上限、清理。
- 规则引擎 M1 子集（§9.3）；示例源端到端。
- 所有新增 UI 的 320dp / 大字体 / 深色回归。

### M2：规则覆盖

- CSS / Default / XPath / AllInOne 正则；完整 JSONPath；`&&`/`%%`/`#####`/反转。
- `<js>`、jsLib、source 变量、`java.*` 基础桥接。
- CookieJar、TXT 导入/导出、目录分页 `nextTocUrl`、正文分页 `nextContentUrl`。
- 多段音频拼接、HLS 流式完善。
- 兼容性夹具矩阵扩展。

### M3：登录与动态页

- 登录 UI/登录脚本（仅授权内容）、Cookie 持久化、WebView、proxy/dns/bodyJs。
- 分享链接导入、源导出、健康度与限速完善。
- 完整离线下载与下载管理（若路线图确认）。

### M4：完整兼容收口

- 真实源兼容性回归；性能、缓存、错误恢复、无障碍。
- 兼容矩阵逐项验收；文档、变更记录、已知限制。
- 「完整兼容」是持续目标；每个新源暴露的缺口回到对应规则类型补齐。

## 15. 留给实现者的决定

以下是本设计刻意留给实现者的选择，不阻塞产品方向：

1. QuickJS 包最终选型与 isolate 运行方式（先 spike，再定）。
2. JSONPath / XPath / Default 规则用现成包还是自写；以测试矩阵为准。
3. 缓存上限默认值（建议 2 GB）与清理策略细节。
4. 书库分页大小（建议 50/100）与滚动增量策略。
5. 网络封面的磁盘缓存实现（`cached_network_image` 或自写）。
6. 源健康连续失败阈值（建议 3）与是否自动降级。
7. 书源测试用的默认关键词（建议「测试」或源名）。
8. HTTP 明文源的 Android network security config 具体写法。
9. `source_consent_v1` 的文案与首次触发时机。
10. 在线书未上架时是否在书库列表加「未上架」弱标记（建议不加，书库不区分上架状态）。

## 16. 已知限制（M1）

- 只支持 JSON 导入；TXT / 分享链接未做。
- 只支持 JSONPath 与示例所需的 JS 子集；CSS/XPath/Default/正则未做。
- 无登录/Cookie/WebView；需要登录或动态渲染的源不可用。
- 目录只抓第一页；超长目录可能不完整。
- 单段音频；多段/HLS 预下载未做。
- 在线书时长未知，书架进度按章节位置计算。
- 删除本地目录仅支持有删除能力的 provider；SAF 只读根禁用。

## 17. 验收口径

M1 完成的判断：

1. 用户能通过 URL / 文件 / 粘贴导入示例听书源，看到校验结果与重复提示。
2. 在发现页切换源、浏览分类、搜索「诡秘之主」，看到结果并进入详情。
3. 不加入书架即可播放；播放时能预下载后 3 章；切章优先缓存。
4. 加入书架可多选分类；书架与书库的来源标签正确。
5. 书库混排本地与在线书；刷新信息/目录不覆盖手动字段与进度；批量刷新有进度与失败汇总。
6. 换源能列出候选、确认覆盖、保留书 ID / 分类 / 进度（可映射时）。
7. 删除本地书默认保留文件；勾选删除整个目录时二次确认，且有根/其他书/只读护栏。
8. 删除/停用书源后书目与进度保留；重新导入同一 URL 可恢复。
9. `flutter analyze` 无问题；新增测试全部通过；320dp / 大字体 / 深色无溢出。
