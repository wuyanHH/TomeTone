# 更新日志

TomeTone（听卷）所有重要变更记录于此。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)（测试期使用 `0.x.y-beta.N` 预发布后缀）。

> 发布纪律：每次发布必须提供详细更新内容（新增 / 优化 / 修复 / 已知问题 / 升级说明），并同步到 GitHub Release；本文件为发布记录的唯一来源。

## [未发布]

### 新增

- **书库根只读目录浏览**（`lib/ui/pages/library/library_browser_page.dart`）：
  点书库列表里的根卡片即可进入该目录，像文件管理器一样逐层查看文件夹与文件；
  面包屑与返回键都先回上一级，根层才退出。列目录只走 `StorageProvider`，不解析书目、
  不接播放队列，也没有重命名 / 删除 / 新建 —— 浏览本身不修改任何用户文件。
  文件夹在前、文件在后按名称排序；音频文件带独立图标，点击只提示「只读浏览」。
  加载 / 空目录 / 各类 `StorageError` 都有对应中文文案与重试入口。
- **书库根可读位置**（`lib/ui/pages/library/library_root_location.dart`）：
  SAF tree URI 不再以 `content://…` 原样出现，而是翻译成 `内部存储/Audiobooks`、
  `文档/…`、`下载/…`、`存储卡/…` 这类可读位置；本地根保留完整盘符路径。
  未知 provider 与坏编码逐级回退到展示名，绝不抛异常。
- **单行滚动文本**（`lib/ui/widgets/scroll_marquee_text.dart`）：
  放得下时完全静止；路径过长时按「停留 → 滚动 → 停留」循环展示完整内容，
  不换行、不撑高卡片；系统开启「减少动态效果」时退化为省略号静态文本。

### 优化

- **书库根卡片信息层级重排**（`lib/ui/pages/library/library_roots.dart`）：
  名称与可读位置占满整行，位置在名称正下方；「上次扫描」移到卡片底行左侧，
  扫描与 `⋮` 收到底行右侧对齐，二者保持独立手势与 ≥44dp 触控目标。
  扫描按钮改为带雷达图标的描边按钮，仍是卡片上的主要动作，但不再压过书名。
  320dp 窄屏与长名称 / 长路径下不再拥挤或溢出。

### 移除

- `⋮` 菜单里的「查看位置」及对应弹层、复制按钮与测试键：位置已经直接展示在卡片上，
  原始 URI 不再需要单独入口。移除确认弹窗也改用可读位置，不再铺原始来源。

### 测试

- 新增 `test/ui/library_browser_page_test.dart`、`test/ui/library_root_location_test.dart`、
  `test/ui/scroll_marquee_text_test.dart`；同步 `test/ui/library_page_test.dart`
  的卡片、窄屏与进入浏览页用例。`flutter analyze` 无问题，`flutter test` 493 项全部通过。

## [0.2.0-beta.1] - 2026-10-19

首个对外测试版本：包含 0.1.x 开发期的全部内容，以及本轮的品牌图标与启动页。

> 版本号三处一致：`pubspec.yaml` / `AppInfo.version` / 本节标题（由 `test/app_info_test.dart` 守门）。

### 新增

- **品牌图标与启动页**（本轮）：
  - 图标：线描展开书 + 书口升起的五根声纹；墨蓝 `#0E2A3B` / 纸白 `#F2F4E9` / 青绿 `#58DCC1`，
    **不跟随**应用内 5 套色盘（图标是系统层固定标识）。
  - 自适应图标三层全用 VectorDrawable（前景 / 背景 / 单色），内容外接 Ø54.0dp、
    距 Ø66dp 安全圆 6.0dp；单色层加粗笔宽以在系统 tint 下仍可辨认；
    API 24–25 回落 5 档 legacy 位图（从画布中央 72dp 区域导出）。
  - 启动页：Android 12+ 走系统闪屏（宣纸底 + 墨盘记印；深色下墨盘由系统按对比度自动隐去），
    API 24–30 走 288dp 记印的 layer-list，两分支同几何。
  - **防白闪**：`NormalTheme.windowBackground` 与 `LaunchTheme` 共用同一张记印
    （Flutter 在 `onCreate` 第一句就切主题，此前该处会露一帧纯白）。
  - **资源门禁** `dart run tool/ci/check_brand_assets.dart`：以精确值校验三层图标、
    位图尺寸与色彩类型、启动页主题、三份 pathData 同构；另有 8 条反向用例
    （`test/ci/brand_asset_gate_test.dart`）防止门禁假绿。
  - 设计稿与验收：`docs/design-preview/icon-v3/`（含 API 36 实测截图）、
    `docs/tometone_icon_splash_verification.md`。
- **工程骨架**：Flutter 应用（Android-only，`com.tometone.app`），分层目录
  `ui / app / domain / contracts / modules / platform`。
- **依赖方向门禁**：`dart run tool/ci/check_import_boundaries.dart`
  强制"UI / 应用 / 领域只依赖契约、模块不依赖业务概念"（《架构需求文档》§5.2）。
- **静态分析门禁**：严格模式（`strict-casts` / `strict-inference` / `strict-raw-types`）
  与扩展 lint 规则集，目标 `flutter analyze` 0 错误 0 警告。
- **Android 平台基线**：`minSdk 24` / `targetSdk 36`，声明
  `FOREGROUND_SERVICE_MEDIA_PLAYBACK` 等前台媒体服务权限（《架构需求文档》2.2）。
- **发布纪律守门测试**：`pubspec.yaml` / `AppInfo` / `CHANGELOG.md` 版本号一致性。
- **换行纪律**：`.gitattributes` 统一源码 LF，避免本地（Windows/CRLF）与 CI 的
  `dart format --set-exit-if-changed` 出现分歧。
- **模块契约层**（Step 1）：
  - `contracts/diagnostics/`：`LogTag` 模块级日志标签、`Redactor` 强制脱敏
    （URL 丢 userinfo/query、敏感请求头、路径只留末段、Token 首尾各 2 字符）。
  - `contracts/playback/`：`PlaybackEngine` 契约（含 8 条规范行为）、
    `AudioSourceRef`（本地 / 远程统一抽象）、`EngineEvent`、`EngineCapabilities`、
    `EngineError` + 11 个错误码、`FakePlaybackEngine`（纯内存 / 零真实定时器，
    时间由 `advance()` 驱动，可注入故障）。
  - `contracts/storage/`：`StorageProvider` 契约（含 5 条规范行为）、
    `StorageEntry` / `StatInfo` / `ProviderCapabilities`、`StorageError` + 11 个错误码、
    `FakeStorageProvider`（可观测存活流数量，用于泄漏体检）。
  - 统一契约测试套件：`test/contracts/playback_engine_conformance.dart` 与
    `storage_provider_conformance.dart`，对 Fake 跑绿；真实实现接入后必须原样跑通。
- **数据层与迁移框架**（Step 2，`lib/domain/library/database/`）：
  - 9 张业务表：`library_roots` / `books` / `volumes` / `chapters` /
    `book_metadata_overrides` / `playback_progress` / `per_book_prefs` /
    `listening_records` / `storage_accounts`（对应 §8.1 / §8.2）。
  - 章节身份按 §8.2 提案落地：**不可变 ULID 主键 + 绑定键
    `library_root_id + NFC 规范化相对路径`**（`chapters` 建唯一索引，重链可 O(log n) 定位）。
  - 迁移纪律：`onCreate` 建表、`onUpgrade` 缺步骤时**显式失败**而非丢库重建（§8.3）；
    每个连接强制 `PRAGMA foreign_keys = ON`，建库时启用 WAL（§2.2）。
  - 时间语义已明确并加测试：drift 按 UTC epoch 秒存储、读回本地 `DateTime`
    （同一瞬时，毫秒截断）。
  - `flutter test` 下用 `NativeDatabase.memory()` 跑通 13 个数据层用例
    （外键 / 唯一绑定键 / 级联 / 缺失保留 / 进度 upsert / 偏好默认值 / 时间语义）。
  - CI 增加"生成代码与提交内容一致"门禁（`build_runner build` + `git diff --exit-code`）。
- **扫描内核**（Step 3a，`lib/domain/library/scan/`）：
  - `MediaFormat`：8 种格式白名单；忽略非音频、隐藏文件、macOS 资源分叉
    `._xxx.mp3`（SD 卡最常见污染）。
  - `NaturalOrder`：阿拉伯数字与中文序数（一 / 二 / 十 / 百 / 千 / 万 / 两）统一映射为数值；
    前缀分组 **序 → 楔子 → 正文 → 番外**；同键按原始字符串确定性兜底，保证多次扫描顺序稳定。
  - `TopologyBuilder`：`书库根/<书>/…` 推导 书 → 卷 → 章（单卷平铺 / 多卷嵌套 /
    根卷与子卷混排 / 卷内继续嵌套）；`chapterIndex` 为全书连续序号。
  - 37 个扫描用例，覆盖 §2.1 验收语料（`第1章 / 第一章 / 楔子 / 序 / 番外 / 卷三`）。
  - 自审修复：超长数字（毫秒时间戳命名）会 `FormatException` 中断扫描、
    `万万` 类词语导致整数溢出、`bookDepth < 1` 在 release 下无保护。
- **扫描编排与两阶段建库**（Step 3b，`lib/domain/library/scan/library_scanner.dart`）：
  - `scanStructure`（Phase 1）：遍历 `StorageProvider` → 拓扑推导 → **单事务**批量 upsert；
    不读取时长 / 封面，保证首屏可用（`books.total_duration_ms` 保持 0 直到 Phase 2）。
  - 增量与数据安全：按绑定键匹配复用**不可变 ID**；消失文件只置 `missing = true`，
    记录与播放进度全部保留；二次扫描同一棵树**零写入**。
  - `ScanReport` 只统计真实写入；不可读目录计入 `failedPaths` 且不中断整次扫描；
    provider 返回重复条目时按归一化路径去重（否则会撞绑定键唯一索引）。
  - `missing` 章节仍计入 `books.total_chapters`（占位展示），但**不计入**累计时长。
  - `backfillMetadata`（Phase 2）：分批回填时长并重算书累计时长；单章失败不中断，
    连续失败达上限后退出队列 —— 否则坏文件永远排在队首，**饿死**后续所有章节
    （为此在 `chapters` 增加 `metadata_attempts`）。
  - `UlidIdGenerator`：48 位毫秒时间戳 + 80 位随机，字典序即时间序。
  - `PathNormalizer`：NFC 归一化绑定键，NFD/NFC 混写不再产生重复书。
  - 已知规模上限（记录待办）：结构扫描把整本书的章一次性载入内存，
    十万章级数据集需要改为按书分页（M2/M3 性能专项）。
- **封面五级继承**（Step 4，`lib/domain/library/cover/`）：
  - `CoverSource` 枚举的 `rank` 与文档 1–5 级一一对应；Drift 转换器落库为 int，
    未知序号回退字标（旧版本读到新档位不崩溃）。SQL 默认 = 字标兜底。
  - `CoverResolver` 为**纯解析**（不碰文件系统 / 数据库）：
    书 = 书根图 → 首卷反哺 → 首章内嵌 → 字标；卷 = 卷目录图 → 书根图 → 字标。
  - 候选挑选按「名称优先级（`cover` > `folder` > `front` > `poster` > …）
    → 自然顺序」，结果确定，不随目录返回顺序抖动。
  - 扫描 Phase 1 落库 `books.cover_path` / `books.cover_source_type` 与
    `volumes.cover_path`；**只索引目录直接子项**，避免把深层插图误判为封面。
  - 四级（首章内嵌封面）只判定档位、不产出路径 —— 字节抽取属于 Phase 2，
    待接入真实标签解析后再落盘（届时不需要迁移）。
- **播放策略层与编排**（Step 5a/5b，`lib/app/policy/`）：
  - `RewindLadder`：把文档阶梯做成**数据**（<30s→0 / <5min→3 / <30min→8 / 其余 15，
    跨进程重启恒 15 且无视 ΔT）；`targetPosition` 永不为负。每书偏好可整体替换阶梯。
  - `ChapterSequencer`：相邻关系（跨卷连播）+ 上一曲判定（>3s 重播本章、≤3s 回上一章、
    全书首章回 0）；重复 ID 视为调用方错误。
  - `ProgressScheduler`：关键事件立即写、播放中 10s 节流 → 崩溃最多丢 ≤10s。
  - `PerBookPreferences`：倍速 / 片头片尾跳过（**按章**生效）/ 阶梯覆盖；
    跳过值超过时长时收敛，不产生负长度。
  - `SleepTimer`：相对倒计时（最后 10s 线性渐弱 → 暂停）、播完当前章即停、
    `SleepRewind`（回到 N 分钟前，默认 10 分钟）。
  - `PlaybackController`：把上述策略接到 `PlaybackEngine` 上；时间全部走注入时钟，
    因此「暂停 10 分钟 → 回退 8 秒 → 10 秒内撤销」「跨卷连播」「全书完毕」
    「片头片尾」「睡眠三模式」「进度节流」都是**确定性单测**，不依赖真机。
  - 契约补充：`PlaybackEngine.setVolume(0..1)`（睡眠渐弱与 DSP 音量增强所需，
    越界钳制、非有限值抛错）。
- **just_audio 播放引擎**（Step 5c，`lib/modules/playback_just_audio/`）：
  - `JustAudioPlaybackEngine` 实现 `PlaybackEngine`：本地 / 远程源（含请求头）、
    位置 / 时长 / 状态播报、倍速与音量、广播事件、幂等释放。
  - 上游陷阱已记录：`play()` 的 Future 在**播放结束时**才完成（不能 `await`）；
    `paused` 与 `ready` 在 just_audio 里同为 `ready + !playing`，需本地记录
    "是否播放过"才能正确区分。
  - 上游错误无稳定枚举，按消息特征归类为结构化错误码，归类失败落 `decodeFailed`。
  - `android/gradle.properties` 关闭 Kotlin 增量编译：Windows 上
    `:audio_session:compileDebugKotlin` 因增量缓存无法关闭而**稳定失败**（复现 3 次，
    含 `flutter clean` 后仍复现）。
  - `app-debug.apk` 构建通过（含 just_audio 插件；合并清单新增
    `ACCESS_NETWORK_STATE`）。
  - 媒体会话 / 前台服务 / MediaNotification（`audio_service`）留待 Step 5d，
    依赖暂不加入 —— 不预埋"已声明未使用"的配置。
- **国风主题系统与应用外壳**（Step 6a，`lib/ui/theme/`、`lib/ui/widgets/`、`AppShell`）：
  - 五套国风色盘（琥珀旧卷 / 竹海幽青 / 星夜深蓝 / 暮紫沉香 / 山丹丹红）× 明 / 暗 /
    暗夜 OLED；OLED 版背景纯黑、`surfaceContainerHighest` 亮度 <0.02、强调色降亮度降饱和。
  - `AppTheme.build(palette, brightness, oled)` + 中文排版 TextTheme +
    NavigationBar/Rail、Card、Dialog、Sheet、按钮、输入框组件主题 + `MiniPlayerTheme`。
  - `theme_tokens.dart`：间距 / 圆角 / 尺寸 / 动效时长 token；`AppMotion.resolve()`
    统一读 `MediaQuery.disableAnimations`（减弱动效）。
  - `BookCover`：书脊 + 内框 + 竖排双字的**几何字标**兜底；`FittedBox` 保证任意书名
    不溢出；`Image.file` 读取失败静默回落字标。
  - `AppShell`：`<600dp` 用 `NavigationBar`、`≥600dp` 用 `NavigationRail`；
    MiniPlayer 是**纯槽位**（外壳不读播放数据、不含任何播放策略）。
  - 主题已接入 `TomeToneApp`（明暗跟随系统；色盘与 OLED 参数已就位，供设置页驱动）。
  - 对比度门禁：5 套 × 明/暗/OLED 共 20 组 × 7 对语义色，全部 ≥ WCAG AA 4.5:1
    （用独立 WCAG 相对亮度公式实测，非自证）。
  - 自查修复：`BookCover.coverPath` 必须是**绝对路径** —— 库内 `cover_path` 相对书库根，
    而 `Image.file` 对相对路径不报错、只是静默不显示，会表现成"封面莫名不见"；
    已加 debug assert 与正负例测试。
- **书架 / MiniPlayer / 全屏播放大台**（Step 6b，`lib/ui/pages/`、`lib/ui/widgets/mini_player.dart`）：
  - 书架：`booksProvider` 三态（加载骨架 / 空态引导去设置 / 错误重试）；手机 2 列、
    宽屏 3–4 列；封面走 `absoluteCoverPath` 解析后的五级继承结果；缺失章给克制提示；
    点击 `startBook` 后展开播放台。
  - MiniPlayer：64dp 单条（封面 / 章节标题 / 播放暂停 / 2dp 进度发丝线）；
    无当前章节时不占位（高度真正归零）。
  - 播放大台：Hero 封面、双层时间轴（章节可拖 / 全书只读）、五键下沉控制台、
    0.5–3.0 倍速、睡眠三模式、撤销回退；侧键 56dp / 中央 72dp，
    320dp 窄视口降到 48/64（仍满足 §3.4 的 48dp 下限）。
  - 章节目录可按卷分组、缺失章置灰、当前章高亮，并**真正可跳章**。
  - 交付偏离（已记录）：用 Hero + 淡入/轻缩放代替 Material 3 Container Transform，
    不为此引入 `animations` 包；减弱动效下时长为 0。
  - 接口修正（自查）：移除 UI 侧 `Provider<Ref>` 桥 —— 应用层不该替 UI 保管 Riverpod
    生命周期对象；`startBook` 改为显式接收 `controller` / `currentBook` / `detail` /
    `libraryRootUri`。
  - 新增 `PlaybackController.seekToChapter`：目录跳章不重建会话、不清撤销令牌，
    切章前先落盘旧章进度。
- **本地存储与书库根管理**（Step 6c，`lib/modules/storage_local/`、`lib/app/library/`）：
  - `LocalStorageProvider`：`StorageProvider` 的本地目录实现（作用域 = 单个书库根）。
    **路径安全**：直接拒绝 `..` 段与绝对路径/盘符片段，而不是"解析后判断越界" ——
    越界解析 + 前缀比较在大小写不敏感 / 符号链接 / Windows 短路径下都可能失效；
    `FileSystemException` 一律折算成结构化 `StorageError`。
  - 通过统一契约套件 `storage_provider_conformance`（真实临时目录）。
  - `LibraryRootService`：添加本地根（校验目录存在）与触发 Phase 1 扫描；
    provider 的创建/释放由它负责，扫描器不感知实现。
  - `storageProviderFactoryProvider` 在 `main.dart` 注入 —— 应用层不能 import
    `lib/modules/`（§5.2），工厂注入是唯一合法通路。

- **SAF 书库根的播放与封面通路**（`lib/contracts/media/`、`lib/platform/saf/`、`lib/modules/storage_local/`、`lib/modules/storage_saf/`）：
  - 新增契约端口 `MediaSourceResolver`（`resolveAudio` / `readBytes`）与 `LibraryRootKind`：
    本地根拼绝对路径；SAF 根由平台桥按库内相对路径**逐段解析**出
    `content://…/tree/<treeId>/document/<id>` 后交给 just_audio。播放源仍用
    `LocalFileSource` 承载，但注释写明这是「单个可直接打开的 URI」容器的**语义借用**
    —— `content://` 不能走 `fromPath`，否则会被包成 `file://` 而必然打不开。
  - `SafBridge` 新增 `documentUri` / `readBytes` / `copyToCache`（`MainActivity` 侧实现）。
    相对路径按「显示名相等」逐段匹配，不做 URL 编解码；`documentUri` 复用
    `documentIdOf`，**不使用** `DocumentsContract.isTreeUri`（沿用上一轮
    「0 册 0 章」的教训）。
  - 封面：`BookCover` 新增 `coverImage`（优先于 `coverPath`，失败仍回落字标）；
    书架 / 播放台 / 迷你播放器统一走 `coverArtProvider` —— 本地根给绝对路径（省内存），
    SAF 根给字节。SAF 书库根的书封面不再永远显示字标兜底。

### 修复

- **「书库」根列表去噪**（`lib/ui/pages/library/`）：
  - 卡片不再显示内部存储类型（SAF 根此前直接把 `saf` 打在界面上）与原始 URI / 绝对路径；
    需要看来源时走 `⋮ → 查看位置`（弹层展示完整来源、可复制）。
  - 扫描结果不再常驻：成功停留约 6 秒后自动收起，也可手动关闭；失败仍常驻到用户收起
    或下次扫描。去掉「用时 N 毫秒」这种每次都不同的噪音；「忽略 N 个非音频文件」
    只在**没扫到任何音频**时给出 —— 它正好解释了「把书库根指到应用私有目录」这类困惑。
  - 手填路径在移动端不再预填应用私有目录（`Directory.systemTemp.parent`）：那个默认值会
    引导用户加一条只会扫出废文件的根，属于设计缺陷。
  - 两种根的区别只在移除弹窗里体现（系统授权目录会提示一并放弃授权），列表上不再区分。
- **移除系统授权目录时一并放弃持久化读授权**（`lib/contracts/storage/directory_authorization.dart`、
  `lib/platform/saf/`、`lib/app/library/library_root_service.dart`）：
  新增 `DirectoryAuthorization` 端口，`SafBridge` 经通道 `releasePermission` 调
  `releasePersistableUriPermission`；`removeRoot` 在删登记成功后对 SAF 根**尽力**释放
  （本来就没授权 / 系统拒绝都不影响移除）。此前只删登记行、授权留在系统里，
  移除弹窗里「会一并放弃系统授权」的说明会落空。
- **书库点击「打不开」、已打开的书再点没反应**（`lib/app/providers/playback_providers.dart`、
  `lib/app/policy/playback_controller.dart`、`lib/ui/pages/shelf/shelf_page.dart`）：
  - 根因：SAF 书库根**只支持扫描、不支持播放** —— 播放队列把 `content://` tree URI
    拼上相对路径当成本地路径喂给引擎，`load` 必然抛错，又被 `on Object` 统一吞成
    「这本书暂时打不开，请稍后再试」；同一处拼接也让 `Image.file` 永远读不出封面。
  - `openBook` 语义收敛：已是当前书且会话健康 → **只展开播放台**（不重建队列、不重定位、不重播）；
    打开改为原子操作 —— 空队列**零副作用**返回、加载失败**回滚**
    （`currentBook` 置空 + 新增 `PlaybackController.clearSession()`），不再留下
    「幽灵迷你播放器 / `--:--` 时间轴 / 书架仍显示未听」；SAF 直传失败时**只把即将播放的那一章**
    复制到应用私有缓存后重试一次（不整书复制）；失败文案按原因区分
    （根已移除 / 书目不完整 / 无可播章节 / 源不可读 / 未知）。本地根能力不变。
- **播放台封面上两条游离横线**（`lib/ui/widgets/book_cover.dart`）：
  真凶是几何字标「内框」的上下两条边 —— 左右两条因对比弱而看不见，读起来就像两条下划线。
  改为四角角饰（保留「版框」的版式暗示，不再产生长横线），并新增**不依赖字体**的结构断言
  锁死，防止整框回归。
- **切章加载失败不再静默、失败残留不再挂住**（`lib/app/policy/playback_controller.dart`、
  `lib/ui/widgets/mini_player.dart`、`lib/ui/pages/player/player_page.dart`）：
  `skipToNext` / `skipToPrevious` / `seekToChapter` / 章末连播的加载异常收敛为
  `lastError` + 退出播放态，迷你播放器与播放台给出「这一章打不开…」；
  加载**成功即清** `lastError`（否则正常播放时错误提示会一直挂着）；
  带残留错误时点同一本书不再走 `alreadyOpen` 短路，用户可以自然重试恢复。
- **SAF 书库根扫描结果为「0 册 0 章」**（`android/app/src/main/kotlin/com/tometone/app/MainActivity.kt`）：
  `documentIdOf` 用 `DocumentsContract.isTreeUri` 区分 tree URI 与文档 URI，但该 API
  只看路径首段是不是 `tree`，而 `buildDocumentUriUsingTree` 生成的文档 URI
  （`…/tree/<treeId>/document/<docId>`）首段同样是 `tree` —— 被误判为 tree URI 后
  `getTreeDocumentId` 返回的是**树根** id 而非文档自己的 id。后果：列子目录时实际一直
  在列根目录的直接子项，`书库根/<书>` 那层能进、再往下就永远重复同一层，扫描器递归到
  `TopologyBuilder.maxDepth` 后拿不到任何章节（表现为刚添加的 SAF 书库根扫描后
  「没有发现新增或变更 · 0 册 0 章」）。
  改为按路径是否含 `/document/<id>` 段判定（`PATH_DOCUMENT` 未公开，用字面量）。
  真机验证：`Audiobooks/Santi/Vol1/{001,002}.wav` 由「0 册 0 章」变为
  「扫描完成 · 新增 1 册 · 1 卷 · 2 章」，逐层 `docId` 探针确认从
  `primary:Audiobooks` → `primary:Audiobooks/Santi` → `…/Santi/Vol1` 正确递进。
  - 回归盲区（待补）：`test/modules/storage_saf/saf_bridge_test.dart` 用**伪造
    MethodChannel** 跑，绕过了 Android 侧的 URI 构造，因此覆盖不到这个 bug；
    平台通道需要有真机/仪器化层或 URI 构造的纯函数化测试。

### 已知问题

- **release APK 目前用 debug 签名**（`android/app/build.gradle.kts`：
  `signingConfig = signingConfigs.getByName("debug")`）。可安装试玩，但**不能用于正式分发**：
  用 debug key 签名的包，将来换正式 keystore 后无法覆盖升级（签名不一致）。正式发布前必须配置 release keystore。
- **仓库尚未配置 git remote**：本版本只有本地提交与 tag，未上传 GitHub Release。
- 启动页首帧会切换一次底色：启动页用品牌色（纸白 / 墨蓝），首屏用色盘 surface
  （默认 `amberScroll` 昼 `#FBF6EC` / 夜 `#191510`）。属设计取舍，见 `docs/tometone_icon_splash_verification.md` §4.1。
- iOS / 桌面端不在本版本范围内。

### 正在计划

- 本地核心（书库扫描、播放、进度、统计），详见《架构需求文档》路线图 M1。
