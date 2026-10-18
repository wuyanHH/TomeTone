# 更新日志

TomeTone（听卷）所有重要变更记录于此。格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)（测试期使用 `0.x.y-beta.N` 预发布后缀）。

> 发布纪律：每次发布必须提供详细更新内容（新增 / 优化 / 修复 / 已知问题 / 升级说明），并同步到 GitHub Release；本文件为发布记录的唯一来源。

## [未发布]

> 当前开发版本：`0.1.0-beta.1`（首个测试版本，尚未发布）

### 新增

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

### 正在计划

- 本地核心（书库扫描、播放、进度、统计），详见《架构需求文档》路线图 M1。
