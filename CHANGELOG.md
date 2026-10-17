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

### 正在计划

- 本地核心（书库扫描、播放、进度、统计），详见《架构需求文档》路线图 M1。
